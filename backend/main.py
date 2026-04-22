from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm, HTTPBearer
from fastapi.openapi.utils import get_openapi
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from datetime import timedelta
import os
import io
import csv
from database import get_db
import db_layer
from auth import create_access_token, ACCESS_TOKEN_EXPIRE_MINUTES, require_teacher, require_student
from schemas import (
    LoginRequest, CreateStudentRequest, CreateTeacherRequest, Token, 
    CreateGroupRequest, CreateSingleStudentRequest, CreateBulkStudentsRequest, 
    CreateBankRequest, QuestionCreateRequest, QuestionResponse, AnswerResponse,
    CreateTestTemplateRequest
)

security = HTTPBearer()

app = FastAPI(
    title="BP-Jirotka-Heger API",
    description="API for creating and managing test for schools",
    version="1.0.0"
)

# Configure JWT Bearer authentication in OpenAPI schema
def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    openapi_schema = get_openapi(
        title="BP-Jirotka-Heger API",
        version="1.0.0",
        description="API for creating and managing test for schools",
        routes=app.routes,
    )
    openapi_schema["components"]["securitySchemes"] = {
        "Bearer": {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT",
        }
    }
    # Add security to protected endpoints
    for path, path_item in openapi_schema["paths"].items():
        if path not in ["/", "/login", "/login/teacher", "/login/student", "/test/create-student", "/test/create-teacher", "/validate/teacher", "/validate/student"]:
            for operation in path_item.values():
                if isinstance(operation, dict):
                    operation["security"] = [{"Bearer": []}]
    
    app.openapi_schema = openapi_schema
    return app.openapi_schema

app.openapi = custom_openapi

@app.get("/")
def read_root():
    return {
        "message": "Ahoj z Dockeru!",
        "db_url": os.getenv("DATABASE_URL") # Jen pro kontrolu, v produkci nevypisovat!
    }

@app.get("/students")
def read_students(
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Endpoint pro zobrazení všech studentů - pouze pro učitele"""
    students = db_layer.get_all_students(db)
    return students

@app.post("/groups")
def create_group(
    group_data: CreateGroupRequest,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Endpoint pro vytvoření skupiny - pouze pro učitele"""
    try:
        group = db_layer.create_group(
            db=db,
            teacher_id=current_teacher["user_id"],
            name=group_data.name,
            description=group_data.description
        )
        return {
            "success": True,
            "message": "Skupina vytvořena",
            "group_id": group.group_id,
            "teacher_id": group.teacher_id,
            "name": group.name,
            "description": group.description
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Chyba při vytváření skupiny: {str(e)}"
        )

@app.get("/groups")
def get_groups(
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Endpoint pro zobrazení všech skupin učitele - pouze pro učitele"""
    groups = db_layer.get_teacher_groups(db, current_teacher["user_id"])
    
    # Přidej počet studentů do každé skupiny
    groups_with_count = [
        {
            "group_id": group.group_id,
            "name": group.name,
            "description": group.description,
            "created_at": group.created_at,
            "student_count": len(group.students)
        }
        for group in groups
    ]
    
    return {
        "teacher_id": current_teacher["user_id"],
        "group_count": len(groups_with_count),
        "groups": groups_with_count
    }

@app.get("/groups/{group_id}/students")
def get_group_students(
    group_id: int,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Endpoint pro zobrazení všech studentů ve skupině - pouze pro učitele"""
    try:
        students = db_layer.get_group_students(
            db=db,
            group_id=group_id,
            teacher_id=current_teacher["user_id"]
        )
        return {
            "group_id": group_id,
            "teacher_id": current_teacher["user_id"],
            "student_count": len(students),
            "students": students
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Chyba při získávání studentů: {str(e)}"
        )

@app.post("/groups/{group_id}/students")
def add_single_student(
    group_id: int,
    student_data: CreateSingleStudentRequest,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Přidat jednoho studenta do skupiny - pouze pro učitele"""
    try:
        # Ověř, že grupa patří učiteli
        group = db.query(db_layer.Group).filter(
            db_layer.Group.group_id == group_id,
            db_layer.Group.teacher_id == current_teacher["user_id"]
        ).first()
        if not group:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Tato skupina nepatří vám"
            )
        
        student = db_layer.create_student_in_group(
            db=db,
            group_id=group_id,
            login_code=student_data.login_code,
            password=student_data.password,
            email=student_data.email
        )
        return {
            "success": True,
            "message": "Student vytvořen",
            "student_id": student.student_id,
            "email": student.email,
            "login_code": student.login_code,
            "group_id": group_id
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Chyba při vytváření studenta: {str(e)}"
        )

@app.post("/groups/{group_id}/students/bulk")
def add_bulk_students(
    group_id: int,
    students_data: CreateBulkStudentsRequest,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Přidat více studentů do skupiny najednou - vrátí CSV - pouze pro učitele"""
    try:
        # Ověř, že grupa patří učiteli
        from models import Group
        group = db.query(Group).filter(
            Group.group_id == group_id,
            Group.teacher_id == current_teacher["user_id"]
        ).first()
        if not group:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Tato skupina nepatří vám"
            )
        
        # Vytvoř studenty
        students = db_layer.create_bulk_students(
            db=db,
            group_id=group_id,
            prefix=students_data.prefix,
            count=students_data.count
        )
        
        # Vytvoř CSV
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(["Email", "Login kód", "Heslo"])
        for student in students:
            writer.writerow([student["email"], student["login_code"], student["password"]])
        
        output.seek(0)
        
        return StreamingResponse(
            iter([output.getvalue()]),
            media_type="text/csv",
            headers={"Content-Disposition": f"attachment; filename=students_{students_data.prefix}.csv"}
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Chyba při vytváření studentů: {str(e)}"
        )

@app.post("/banks")
def create_bank(
    bank_data: CreateBankRequest,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Endpoint pro vytvoření banky otázek - pouze pro učitele"""
    try:
        bank = db_layer.create_bank(
            db=db,
            teacher_id=current_teacher["user_id"],
            name=bank_data.name,
            description=bank_data.description,
            is_public=bank_data.is_public
        )
        return {
            "success": True,
            "message": "Banka otázek vytvořena",
            "bank_id": bank.bank_id,
            "teacher_id": bank.teacher_id,
            "name": bank.name,
            "description": bank.description,
            "is_public": bank.is_public
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Chyba při vytváření banky: {str(e)}"
        )

@app.get("/banks")
def get_banks(
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Endpoint pro zobrazení všech bank otázek učitele - pouze pro učitele"""
    banks = db_layer.get_teacher_banks(db, current_teacher["user_id"])
    return {
        "teacher_id": current_teacher["user_id"],
        "bank_count": len(banks),
        "banks": banks
    }


@app.post("/banks/{bank_id}/questions")
def create_question(
    bank_id: int,
    question_data: QuestionCreateRequest,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Endpoint pro vytvoření nové otázky v bance - pouze pro učitele
    
    Podporované typy otázek:
    - SINGLE_CHOICE: Vyžaduje alespoň jednu správnou odpověď
    - MULTI_CHOICE: Vyžaduje alespoň jednu správnou odpověď
    - OPEN_TEXT: Odpovědi jsou volitelné (mohou být hinty)
    - ORDERING: Vyžaduje všechny odpovědi s order_index
    
    ## SINGLE_CHOICE Příklad:
    ```json
    {
        "text": "Kolik je 2 + 2?",
        "type": "SINGLE_CHOICE",
        "tags": ["matematika", "základní"],
        "image_url": null,
        "default_points": 1,
        "answers": [
            {"text": "3", "is_correct": false},
            {"text": "4", "is_correct": true},
            {"text": "5", "is_correct": false}
        ]
    }
    ```
    
    ## MULTI_CHOICE Příklad:
    ```json
    {
        "text": "Která čísla jsou prvočísla?",
        "type": "MULTI_CHOICE",
        "tags": ["matematika"],
        "image_url": null,
        "default_points": 2,
        "answers": [
            {"text": "2", "is_correct": true},
            {"text": "3", "is_correct": true},
            {"text": "4", "is_correct": false},
            {"text": "5", "is_correct": true}
        ]
    }
    ```
    
    ## OPEN_TEXT Příklad (bez odpovědí):
    ```json
    {
        "text": "Popište vodní cyklus",
        "type": "OPEN_TEXT",
        "tags": ["věda"],
        "image_url": null,
        "default_points": 5,
        "answers": []
    }
    ```
    
    ## OPEN_TEXT Příklad (s hinty):
    ```json
    {
        "text": "Jmenujte evropské hlavní města",
        "type": "OPEN_TEXT",
        "tags": ["geografie"],
        "image_url": null,
        "default_points": 3,
        "answers": [
            {"text": "Praha"},
            {"text": "Paříž"},
            {"text": "Berlín"}
        ]
    }
    ```
    
    ## ORDERING Příklad:
    ```json
    {
        "text": "Seřaďte čísla od nejmenšího k největšímu",
        "type": "ORDERING",
        "tags": ["matematika"],
        "image_url": null,
        "default_points": 2,
        "answers": [
            {"text": "1", "order_index": 1, "is_correct": true},
            {"text": "5", "order_index": 2, "is_correct": true},
            {"text": "10", "order_index": 3, "is_correct": true},
            {"text": "15", "order_index": 4, "is_correct": true}
        ]
    }
    ```
    """
    try:
        # Konvertujeme QuestionCreateRequest na dictionary
        question_dict = {
            "text": question_data.text,
            "type": question_data.type,
            "tags": question_data.tags,
            "image_url": question_data.image_url,
            "default_points": question_data.default_points,
            "answers": [
                {
                    "text": a.text,
                    "is_correct": a.is_correct,
                    "order_index": a.order_index
                }
                for a in question_data.answers
            ]
        }
        
        # Vytvoříme otázku v databázi
        created_question = db_layer.create_question(
            db=db,
            bank_id=bank_id,
            question_data=question_dict,
            teacher_id=current_teacher["user_id"]
        )
        
        # Konvertujeme na response formát
        # Seřadíme odpovědi podle order_index
        sorted_answers = sorted(created_question.answers, key=lambda a: a.order_index)
        
        response_answers = [
            {
                "answer_id": answer.answer_id,
                "text": answer.text,
                "is_correct": answer.is_correct,
                "order_index": answer.order_index
            }
            for answer in sorted_answers
        ]
        
        return {
            "success": True,
            "message": "Otázka vytvořena",
            "question": {
                "question_id": created_question.question_id,
                "text": created_question.text,
                "type": created_question.type.value,
                "tags": created_question.tags,
                "image_url": created_question.image_url,
                "default_points": created_question.default_points,
                "answers": response_answers
            }
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND if "neexistuje" in str(e) else status.HTTP_403_FORBIDDEN,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Chyba při vytváření otázky: {str(e)}"
        )


@app.get("/banks/{bank_id}/questions")
def get_questions(
    bank_id: int,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Endpoint pro zobrazení všech otázek v bance - pouze pro učitele
    
    Vrací otázky s kompletními odpověďmi včetně is_correct flagů.
    """
    try:
        # Získáme všechny otázky z banky
        questions = db_layer.get_bank_questions(
            db=db,
            bank_id=bank_id,
            teacher_id=current_teacher["user_id"]
        )
        
        # Konvertujeme na response formát
        response_questions = []
        for question in questions:
            # Seřadíme odpovědi podle order_index
            sorted_answers = sorted(question.answers, key=lambda a: a.order_index)
            
            response_answers = [
                {
                    "answer_id": answer.answer_id,
                    "text": answer.text,
                    "is_correct": answer.is_correct,
                    "order_index": answer.order_index
                }
                for answer in sorted_answers
            ]
            
            response_questions.append({
                "question_id": question.question_id,
                "text": question.text,
                "type": question.type.value,
                "tags": question.tags,
                "image_url": question.image_url,
                "default_points": question.default_points,
                "answers": response_answers
            })
        
        return {
            "bank_id": bank_id,
            "teacher_id": current_teacher["user_id"],
            "question_count": len(response_questions),
            "questions": response_questions
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND if "neexistuje" in str(e) else status.HTTP_403_FORBIDDEN,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Chyba při získávání otázek: {str(e)}"
        )

@app.post("/test-templates")
def create_test_template(
    template_data: CreateTestTemplateRequest,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Vytvoří novou šablonu testu - pouze pro učitele
    
    Validace:
    - Všechny otázky MUSÍ patřit do bank učitele (ověřuje se vlastnictví)
    - Pokud se přidávají otázky, musí mít unikátní position
    
    ```json
    {
        "name": "Základy SQL",
        "description": "Test pro začátečníky",
        "difficulty": "EASY",
        "estimated_duration_minutes": 30,
        "tags": ["sql", "začátečníci"],
        "learning_objectives": ["Pochopit SELECT", "Pochopit WHERE"],
        "is_active": true,
        "settings": {"shuffle": true, "show_results_after_submit": false},
        "questions": [
            {"question_id": 1, "position": 1, "points_custom": 2},
            {"question_id": 2, "position": 2, "points_custom": null}
        ]
    }
    ```
    """
    try:
        # Zkontroluj vlastnictví otázek
        questions_data = template_data.questions if template_data.questions else []
        
        # Konvertuj na dict pro db_layer
        template_dict = {
            "name": template_data.name,
            "description": template_data.description,
            "difficulty": template_data.difficulty,
            "estimated_duration_minutes": template_data.estimated_duration_minutes,
            "tags": template_data.tags or [],
            "learning_objectives": template_data.learning_objectives or [],
            "is_active": template_data.is_active,
            "settings": template_data.settings or {},
            "questions": questions_data
        }
        
        # Vytvoř test v db
        test_template = db_layer.create_test_template(
            db=db,
            teacher_id=current_teacher["user_id"],
            template_data=template_dict
        )
        
        return {
            "success": True,
            "message": "Šablona testu vytvořena",
            "template_id": test_template.template_id,
            "teacher_id": test_template.teacher_id,
            "name": test_template.name,
            "description": test_template.description,
            "difficulty": test_template.difficulty.value if test_template.difficulty else None,
            "is_active": test_template.is_active,
            "estimated_duration_minutes": test_template.estimated_duration_minutes,
            "question_count": len(test_template.question_associations)
        }
    
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Chyba při vytváření šablony testu: {str(e)}"
        )

@app.get("/test-templates")
def get_test_templates(
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Endpoint pro zobrazení všech testů učitele - pouze pro učitele"""
    try:
        templates = db_layer.get_teacher_test_templates(db, current_teacher["user_id"])
        
        templates_list = []
        for template in templates:
            templates_list.append({
                "template_id": template.template_id,
                "name": template.name,
                "description": template.description,
                "difficulty": template.difficulty.value if template.difficulty else None,
                "is_active": template.is_active,
                "estimated_duration_minutes": template.estimated_duration_minutes,
                "tags": template.tags,
                "question_count": len(template.question_associations),
                "created_at": template.created_at,
                "updated_at": template.updated_at
            })
        
        return {
            "teacher_id": current_teacher["user_id"],
            "template_count": len(templates_list),
            "templates": templates_list
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Chyba při získávání šablon testů: {str(e)}"
        )

@app.post("/login", response_model=Token)
def login(login_data: LoginRequest, db: Session = Depends(get_db)):
    """Jednotný endpoint pro přihlášení učitele nebo studenta
    
    Args:
        login_data: Přihlašovací údaje obsahující username, password a is_teacher flag
        - is_teacher=True: authenticate_teacher (username = email)
        - is_teacher=False: authenticate_student (username = login_code)
    """
    if login_data.is_teacher:
        # Přihlášení učitele
        teacher = db_layer.authenticate_teacher(db, login_data.username, login_data.password)
        if not teacher:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Nesprávný email nebo heslo"
            )
        
        # Vytvoření JWT tokenu
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": str(teacher.teacher_id), "type": "teacher"},
            expires_delta=access_token_expires
        )
        
        return {
            "access_token": access_token,
            "token_type": "bearer",
            "user_type": "teacher",
            "user_id": teacher.teacher_id
        }
    else:
        # Přihlášení studenta
        student = db_layer.authenticate_student(db, login_data.username, login_data.password)
        if not student:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Nesprávný login kód nebo heslo, nebo účet není aktivní"
            )
        
        # Vytvoření JWT tokenu
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": str(student.student_id), "type": "student"},
            expires_delta=access_token_expires
        )
        
        return {
            "access_token": access_token,
            "token_type": "bearer",
            "user_type": "student",
            "user_id": student.student_id
        }

@app.post("/login/teacher", response_model=Token)
def login_teacher(login_data: LoginRequest, db: Session = Depends(get_db)):
    """[DEPRECATED] Přihlášení učitele - použijte /login s is_teacher=true"""
    login_data.is_teacher = True
    return login(login_data, db)

@app.post("/login/student", response_model=Token)
def login_student(login_data: LoginRequest, db: Session = Depends(get_db)):
    """[DEPRECATED] Přihlášení studenta - použijte /login s is_teacher=false"""
    login_data.is_teacher = False
    return login(login_data, db)

@app.post("/test/create-student")
def test_create_student(student_data: CreateStudentRequest, db: Session = Depends(get_db)):
    """Test endpoint pro vytvoření studenta se správně zahashovaným heslem"""
    try:
        student = db_layer.create_student(
            db=db,
            email=student_data.email,
            login_code=student_data.login_code,
            password=student_data.password,
            group_id=student_data.group_id
        )
        
        # Vrať skupiny, do kterých student patří
        group_ids = [g.group_id for g in student.groups]
        
        return {
            "success": True,
            "message": "Student vytvořen",
            "student_id": student.student_id,
            "email": student.email,
            "login_code": student.login_code,
            "group_ids": group_ids
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Chyba při vytváření studenta: {str(e)}"
        )

@app.post("/test/create-teacher")
def test_create_teacher(teacher_data: CreateTeacherRequest, db: Session = Depends(get_db)):
    """Endpoint pro vytvoření nového učitele se správně zahashovaným heslem"""
    try:
        teacher = db_layer.create_teacher(
            db=db,
            name=teacher_data.name,
            email=teacher_data.email,
            password=teacher_data.password
        )
        return {
            "success": True,
            "message": "Učitel vytvořen",
            "teacher_id": teacher.teacher_id,
            "name": teacher.name,
            "email": teacher.email
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Chyba při vytváření učitele: {str(e)}"
        )

@app.get("/validate/teacher")
def validate_teacher_token(current_teacher: dict = Depends(require_teacher)):
    """Ověří platnost JWT tokenu pro učitele"""
    return {
        "valid": True,
        "user_type": current_teacher["user_type"],
        "teacher_id": current_teacher["user_id"],
        "message": "Token je platný"
    }

@app.get("/validate/student")
def validate_student_token(current_student: dict = Depends(require_student)):
    """Ověří platnost JWT tokenu pro studenta"""
    return {
        "valid": True,
        "user_type": current_student["user_type"],
        "student_id": current_student["user_id"],
        "message": "Token je platný"
    }
