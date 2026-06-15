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
    CreateTestTemplateRequest, ExamAssignmentCreate, ExamAssignmentUpdate,
    ExamAssignmentResponse, StudentAttemptResponse, StudentAttemptDetailedResponse,
    GradeAttemptRequest, ResultsSummary, TemplateQuestionResponse, UpdateTemplateQuestionRequest,
    CreateTemplateQuestionRequest
)
from fastapi.middleware.cors import CORSMiddleware

security = HTTPBearer()

# ============================================================
# Metadata pro Swagger tagy (pořadí = pořadí v UI)
# ============================================================
tags_metadata = [
    {
        "name": "Autentizace",
        "description": "Přihlášení učitele nebo studenta, ověření JWT tokenu.",
    },
    {
        "name": "Skupiny a studenti",
        "description": "Správa skupin (tříd) a jejich studentů.",
    },
    {
        "name": "Banky otázek",
        "description": "Správa bank otázek a jednotlivých otázek s odpověďmi.",
    },
    {
        "name": "Šablony testů",
        "description": "Vytváření šablon testů a správa otázek v šabloně.",
    },
    {
        "name": "Přiřazení testů",
        "description": "Přiřazení šablony skupině, plánování a ruční aktivace/deaktivace.",
    },
    {
        "name": "Hodnocení a výsledky",
        "description": "Přehled pokusů studentů, ruční hodnocení a souhrnné statistiky.",
    },
    {
        "name": "Vývojové endpointy",
        "description": "Pomocné endpointy pro vývoj a testování (neprodukční).",
    },
]

app = FastAPI(
    title="BP-Jirotka-Heger API",
    description="API pro tvorbu a správu testů ve školním prostředí.",
    version="1.0.0",
    openapi_tags=tags_metadata,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Povolí dotazy odkudkoliv (pro lokální vývoj)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Configure JWT Bearer authentication in OpenAPI schema
def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    openapi_schema = get_openapi(
        title="BP-Jirotka-Heger API",
        version="1.0.0",
        description="API pro tvorbu a správu testů ve školním prostředí.",
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


# ============================================================
# 🔐 AUTENTIZACE
# ============================================================

@app.get("/", tags=["Autentizace"], include_in_schema=False)
def read_root():
    return {
        "message": "Ahoj z Dockeru!",
        "db_url": os.getenv("DATABASE_URL")  # Jen pro kontrolu, v produkci nevypisovat!
    }


@app.post("/login", response_model=Token, tags=["Autentizace"])
def login(login_data: LoginRequest, db: Session = Depends(get_db)):
    """Jednotný endpoint pro přihlášení učitele nebo studenta.

    - `is_teacher=True` → přihlásí učitele (username = email)
    - `is_teacher=False` → přihlásí studenta (username = login_code)

    Vrací JWT token, který je třeba předat v hlavičce `Authorization: Bearer <token>`.
    """
    if login_data.is_teacher:
        teacher = db_layer.authenticate_teacher(db, login_data.username, login_data.password)
        if not teacher:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Nesprávný email nebo heslo"
            )
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
        student = db_layer.authenticate_student(db, login_data.username, login_data.password)
        if not student:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Nesprávný login kód nebo heslo, nebo účet není aktivní"
            )
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


@app.post("/login/teacher", response_model=Token, tags=["Autentizace"], deprecated=True)
def login_teacher(login_data: LoginRequest, db: Session = Depends(get_db)):
    """[DEPRECATED] Přihlášení učitele – použijte `/login` s `is_teacher=true`."""
    login_data.is_teacher = True
    return login(login_data, db)


@app.post("/login/student", response_model=Token, tags=["Autentizace"], deprecated=True)
def login_student(login_data: LoginRequest, db: Session = Depends(get_db)):
    """[DEPRECATED] Přihlášení studenta – použijte `/login` s `is_teacher=false`."""
    login_data.is_teacher = False
    return login(login_data, db)


@app.get("/validate/teacher", tags=["Autentizace"])
def validate_teacher_token(current_teacher: dict = Depends(require_teacher)):
    """Ověří platnost JWT tokenu pro učitele."""
    return {
        "valid": True,
        "user_type": current_teacher["user_type"],
        "teacher_id": current_teacher["user_id"],
        "message": "Token je platný"
    }


@app.get("/validate/student", tags=["Autentizace"])
def validate_student_token(current_student: dict = Depends(require_student)):
    """Ověří platnost JWT tokenu pro studenta."""
    return {
        "valid": True,
        "user_type": current_student["user_type"],
        "student_id": current_student["user_id"],
        "message": "Token je platný"
    }


# ============================================================
# 👩‍🏫 SKUPINY A STUDENTI
# ============================================================

@app.post("/groups", tags=["Skupiny a studenti"])
def create_group(
    group_data: CreateGroupRequest,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Vytvoří novou skupinu (třídu) pro přihlášeného učitele."""
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


@app.get("/groups", tags=["Skupiny a studenti"])
def get_groups(
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Vrátí všechny skupiny přihlášeného učitele obohacené o statistiky.

    Pro každou skupinu vrací:
    - `student_count` – počet studentů
    - `active_assignment_count` – počet právě probíhajících testů
    - `pending_grade_count` – počet pokusů čekajících na opravu (status SUBMITTED)
    """
    groups_with_stats = db_layer.get_teacher_groups_with_stats(db, current_teacher["user_id"])
    return {
        "teacher_id": current_teacher["user_id"],
        "group_count": len(groups_with_stats),
        "groups": groups_with_stats
    }


@app.get("/groups/{group_id}/students", tags=["Skupiny a studenti"])
def get_group_students(
    group_id: int,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Vrátí seznam všech studentů ve skupině."""
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
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Chyba při získávání studentů: {str(e)}"
        )


@app.post("/groups/{group_id}/students", tags=["Skupiny a studenti"])
def add_single_student(
    group_id: int,
    student_data: CreateSingleStudentRequest,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Přidá jednoho studenta do skupiny."""
    try:
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
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Chyba při vytváření studenta: {str(e)}"
        )


@app.post("/groups/{group_id}/students/bulk", tags=["Skupiny a studenti"])
def add_bulk_students(
    group_id: int,
    students_data: CreateBulkStudentsRequest,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Hromadně přidá studenty do skupiny a vrátí CSV soubor s přihlašovacími údaji."""
    try:
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

        students = db_layer.create_bulk_students(
            db=db,
            group_id=group_id,
            prefix=students_data.prefix,
            count=students_data.count
        )

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
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Chyba při vytváření studentů: {str(e)}"
        )


# ============================================================
# 📚 BANKY OTÁZEK
# ============================================================

@app.post("/banks", tags=["Banky otázek"])
def create_bank(
    bank_data: CreateBankRequest,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Vytvoří novou banku otázek pro přihlášeného učitele."""
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


@app.get("/banks", tags=["Banky otázek"])
def get_banks(
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Vrátí všechny banky otázek přihlášeného učitele."""
    banks = db_layer.get_teacher_banks(db, current_teacher["user_id"])
    return {
        "teacher_id": current_teacher["user_id"],
        "bank_count": len(banks),
        "banks": banks
    }


@app.post("/banks/{bank_id}/questions", tags=["Banky otázek"])
def create_question(
    bank_id: int,
    question_data: QuestionCreateRequest,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Vytvoří novou otázku v bance otázek.

    Podporované typy otázek:
    - `SINGLE_CHOICE` – jedna správná odpověď
    - `MULTI_CHOICE` – více správných odpovědí
    - `OPEN_TEXT` – volná odpověď (odpovědi jsou volitelné hinty)
    - `ORDERING` – seřazení položek (každá odpověď musí mít `order_index`)

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
            {"text": "10", "order_index": 3, "is_correct": true}
        ]
    }
    ```
    """
    try:
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

        created_question = db_layer.create_question(
            db=db,
            bank_id=bank_id,
            question_data=question_dict,
            teacher_id=current_teacher["user_id"]
        )

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


@app.get("/banks/{bank_id}/questions", tags=["Banky otázek"])
def get_questions(
    bank_id: int,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Vrátí všechny otázky v bance včetně odpovědí a `is_correct` flagů."""
    try:
        questions = db_layer.get_bank_questions(
            db=db,
            bank_id=bank_id,
            teacher_id=current_teacher["user_id"]
        )

        response_questions = []
        for question in questions:
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


# ============================================================
# 📝 ŠABLONY TESTŮ
# ============================================================

@app.post("/test-templates", tags=["Šablony testů"])
def create_test_template(
    template_data: CreateTestTemplateRequest,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Vytvoří novou šablonu testu.

    Všechny otázky musí patřit do bank přihlášeného učitele.
    Pokud se přidávají otázky, musí mít unikátní `position`.

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
        questions_data = template_data.questions if template_data.questions else []

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
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Chyba při vytváření šablony testu: {str(e)}"
        )


@app.get("/test-templates", tags=["Šablony testů"])
def get_test_templates(
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Vrátí všechny šablony testů přihlášeného učitele."""
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


@app.get("/test-templates/{template_id}/questions", tags=["Šablony testů"])
def get_template_questions(
    template_id: int,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Vrátí všechny otázky v šabloně testu.

    Každá otázka obsahuje informace ze šablony (`position`, `points_custom`)
    i z banky (`text`, `type`, `answers`, atd.).
    """
    try:
        template_questions = db_layer.get_template_questions(
            db=db,
            template_id=template_id,
            teacher_id=current_teacher["user_id"]
        )

        response_questions = []
        for template_q, question in template_questions:
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
                "position": template_q.position,
                "points_custom": template_q.points_custom,
                "text": question.text,
                "type": question.type.value,
                "default_points": question.default_points,
                "tags": question.tags,
                "image_url": question.image_url,
                "answers": response_answers
            })

        return {
            "template_id": template_id,
            "question_count": len(response_questions),
            "questions": response_questions
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN if "nepatří" in str(e) else status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Chyba: {str(e)}"
        )


@app.post("/test-templates/{template_id}/questions", tags=["Šablony testů"])
def add_template_question(
    template_id: int,
    question_data: CreateTemplateQuestionRequest,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Přidá otázku do šablony testu.

    Otázka musí existovat v bance učitele a nesmí být v šabloně již přidána.

    ```json
    {
        "question_id": 5,
        "position": 1,
        "points_custom": 10
    }
    ```
    """
    try:
        template_question = db_layer.add_template_question(
            db=db,
            template_id=template_id,
            question_id=question_data.question_id,
            teacher_id=current_teacher["user_id"],
            position=question_data.position,
            points_custom=question_data.points_custom
        )
        return {
            "success": True,
            "message": "Otázka přidána do šablony",
            "template_question": {
                "question_id": template_question.question_id,
                "position": template_question.position,
                "points_custom": template_question.points_custom
            }
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN if "nepatří" in str(e) else status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Chyba: {str(e)}"
        )


@app.put("/test-templates/{template_id}/questions/{question_id}", tags=["Šablony testů"])
def update_template_question(
    template_id: int,
    question_id: int,
    update_data: UpdateTemplateQuestionRequest,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Upraví počet bodů otázky v šabloně testu (`points_custom`).

    Původní otázka v bance zůstane beze změn.

    ```json
    { "points_custom": 5 }
    ```
    """
    try:
        template_question = db_layer.update_template_question(
            db=db,
            template_id=template_id,
            question_id=question_id,
            teacher_id=current_teacher["user_id"],
            points_custom=update_data.points_custom
        )
        return {
            "success": True,
            "message": "Otázka v šabloně aktualizována",
            "template_question": {
                "question_id": template_question.question_id,
                "position": template_question.position,
                "points_custom": template_question.points_custom
            }
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN if "nepatří" in str(e) else status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Chyba: {str(e)}"
        )


@app.delete("/test-templates/{template_id}/questions/{question_id}", tags=["Šablony testů"])
def delete_template_question(
    template_id: int,
    question_id: int,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Odebere otázku ze šablony testu.

    Otázka se pouze odebere ze šablony – v bance zůstane zachována.
    """
    try:
        db_layer.delete_template_question(
            db=db,
            template_id=template_id,
            question_id=question_id,
            teacher_id=current_teacher["user_id"]
        )
        return {
            "success": True,
            "message": "Otázka byla odebrána ze šablony"
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN if "nepatří" in str(e) else status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Chyba: {str(e)}"
        )


# ============================================================
# 📋 PŘIŘAZENÍ TESTŮ
# ============================================================

@app.post("/groups/{group_id}/exam-assignments", tags=["Přiřazení testů"])
def create_exam_assignment(
    group_id: int,
    assignment_data: ExamAssignmentCreate,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Přiřadí šablonu testu skupině.

    **Dva režimy:**
    - **Naplánovaný test** – vyplň `activate_from` + `activate_to`.
      Test se automaticky stane dostupným v daném časovém okně (`is_active` se nastaví na `true`).
    - **Manuální test** – časy nech prázdné. `is_active = false`, spusť ručně přes `/activate`.

    ```json
    {
        "template_id": 1,
        "activate_from": "2024-04-27T10:00:00Z",
        "activate_to": "2024-04-27T12:00:00Z",
        "time_limit_minutes": 60,
        "access_password": "heslo123"
    }
    ```
    """
    try:
        assignment = db_layer.create_exam_assignment(
            db=db,
            teacher_id=current_teacher["user_id"],
            group_id=group_id,
            template_id=assignment_data.template_id,
            activate_from=assignment_data.activate_from,
            activate_to=assignment_data.activate_to,
            time_limit_minutes=assignment_data.time_limit_minutes,
            access_password=assignment_data.access_password
        )
        return {
            "success": True,
            "message": "Přiřazení testu vytvořeno",
            "assignment": {
                "assignment_id": assignment.assignment_id,
                "template_id": assignment.template_id,
                "group_id": assignment.group_id,
                "activate_from": assignment.activate_from.isoformat() if assignment.activate_from else None,
                "activate_to": assignment.activate_to.isoformat() if assignment.activate_to else None,
                "is_active": assignment.is_active,
                "time_limit_minutes": assignment.time_limit_minutes,
                "created_at": assignment.created_at.isoformat()
            }
        }
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Chyba při vytváření přiřazení: {str(e)}"
        )


@app.get("/groups/{group_id}/exam-assignments/overview", tags=["Přiřazení testů"])
def get_group_assignments_overview(
    group_id: int,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Vrátí přehled testů skupiny rozdělený na **aktivní / nadcházející / dokončené**.

    Test je **aktivní** pokud `is_active = true` a (žádné časy NEBO `activate_from <= now <= activate_to`).

    Každý záznam obsahuje `template_name`, `submitted_count`, `total_students`.
    """
    try:
        overview = db_layer.get_group_assignments_overview(
            db=db,
            group_id=group_id,
            teacher_id=current_teacher["user_id"]
        )
        return overview
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Chyba při získávání přehledu testů: {str(e)}"
        )


@app.get("/groups/{group_id}/exam-assignments", tags=["Přiřazení testů"])
def get_group_assignments(
    group_id: int,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Vrátí všechna přiřazení testů pro skupinu (bez kategorizace)."""
    try:
        assignments = db_layer.get_group_assignments(
            db=db,
            group_id=group_id,
            teacher_id=current_teacher["user_id"]
        )

        assignment_list = []
        for a in assignments:
            assignment_list.append({
                "assignment_id": a.assignment_id,
                "template_id": a.template_id,
                "group_id": a.group_id,
                "activate_from": a.activate_from.isoformat() if a.activate_from else None,
                "activate_to": a.activate_to.isoformat() if a.activate_to else None,
                "is_active": a.is_active,
                "time_limit_minutes": a.time_limit_minutes,
                "created_at": a.created_at.isoformat(),
                "attempt_count": len(a.attempts)
            })

        return {
            "group_id": group_id,
            "assignment_count": len(assignment_list),
            "assignments": assignment_list
        }
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Chyba při získávání přiřazení: {str(e)}"
        )


@app.get("/exam-assignments/{assignment_id}", tags=["Přiřazení testů"])
def get_assignment(
    assignment_id: int,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Vrátí detail konkrétního přiřazení testu."""
    try:
        assignment = db_layer.get_assignment_details(
            db=db,
            assignment_id=assignment_id,
            teacher_id=current_teacher["user_id"]
        )
        return {
            "assignment_id": assignment.assignment_id,
            "template_id": assignment.template_id,
            "group_id": assignment.group_id,
            "activate_from": assignment.activate_from.isoformat() if assignment.activate_from else None,
            "activate_to": assignment.activate_to.isoformat() if assignment.activate_to else None,
            "is_active": assignment.is_active,
            "time_limit_minutes": assignment.time_limit_minutes,
            "created_at": assignment.created_at.isoformat(),
            "attempt_count": len(assignment.attempts)
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN if "nepatří" in str(e) else status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Chyba: {str(e)}")


@app.put("/exam-assignments/{assignment_id}", tags=["Přiřazení testů"])
def update_assignment(
    assignment_id: int,
    update_data: ExamAssignmentUpdate,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Upraví nastavení přiřazení testu (časy, heslo, is_active).

    Ke změně `is_active` doporučujeme dedikované endpointy `/activate` a `/deactivate`.
    """
    try:
        update_dict = {
            k: v for k, v in update_data.dict().items()
            if v is not None
        }

        assignment = db_layer.update_assignment(
            db=db,
            assignment_id=assignment_id,
            teacher_id=current_teacher["user_id"],
            update_data=update_dict
        )
        return {
            "success": True,
            "message": "Přiřazení aktualizováno",
            "assignment": {
                "assignment_id": assignment.assignment_id,
                "template_id": assignment.template_id,
                "group_id": assignment.group_id,
                "activate_from": assignment.activate_from.isoformat() if assignment.activate_from else None,
                "activate_to": assignment.activate_to.isoformat() if assignment.activate_to else None,
                "is_active": assignment.is_active,
                "time_limit_minutes": assignment.time_limit_minutes
            }
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN if "nepatří" in str(e) else status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Chyba: {str(e)}")


@app.delete("/exam-assignments/{assignment_id}", tags=["Přiřazení testů"])
def delete_assignment(
    assignment_id: int,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Smaže přiřazení testu včetně všech pokusů studentů."""
    try:
        db_layer.delete_assignment(
            db=db,
            assignment_id=assignment_id,
            teacher_id=current_teacher["user_id"]
        )
        return {
            "success": True,
            "message": "Přiřazení smazáno"
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN if "nepatří" in str(e) else status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Chyba: {str(e)}")


@app.post("/exam-assignments/{assignment_id}/activate", tags=["Přiřazení testů"])
def activate_assignment(
    assignment_id: int,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Manuálně aktivuje přiřazení testu (`is_active = true`).

    - **Test bez časů** → stane se okamžitě dostupným pro studenty.
    - **Test s časy** → bude dostupný až v nastaveném časovém okně.
    """
    try:
        assignment = db_layer.activate_assignment(
            db=db,
            assignment_id=assignment_id,
            teacher_id=current_teacher["user_id"]
        )
        return {
            "success": True,
            "message": "Test byl aktivován",
            "assignment_id": assignment.assignment_id,
            "is_active": assignment.is_active
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN if "nepatří" in str(e) else status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Chyba: {str(e)}")


@app.post("/exam-assignments/{assignment_id}/deactivate", tags=["Přiřazení testů"])
def deactivate_assignment(
    assignment_id: int,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Manuálně deaktivuje přiřazení testu (`is_active = false`).

    Test okamžitě přestane být dostupný pro studenty,
    bez ohledu na nastavené časové okno.
    """
    try:
        assignment = db_layer.deactivate_assignment(
            db=db,
            assignment_id=assignment_id,
            teacher_id=current_teacher["user_id"]
        )
        return {
            "success": True,
            "message": "Test byl deaktivován",
            "assignment_id": assignment.assignment_id,
            "is_active": assignment.is_active
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN if "nepatří" in str(e) else status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Chyba: {str(e)}")


# ============================================================
# 📊 HODNOCENÍ A VÝSLEDKY
# ============================================================

@app.get("/exam-assignments/{assignment_id}/attempts", tags=["Hodnocení a výsledky"])
def get_attempts(
    assignment_id: int,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Vrátí seznam všech pokusů studentů v daném přiřazení."""
    try:
        attempts = db_layer.get_assignment_attempts(
            db=db,
            assignment_id=assignment_id,
            teacher_id=current_teacher["user_id"]
        )

        attempt_list = []
        for a in attempts:
            attempt_list.append({
                "attempt_id": a.attempt_id,
                "student_id": a.student_id,
                "started_at": a.started_at.isoformat(),
                "finished_at": a.finished_at.isoformat() if a.finished_at else None,
                "status": a.status.value,
                "total_points": float(a.total_points) if a.total_points else None,
                "max_points": float(a.max_points) if a.max_points else None,
                "score_percent": float(a.score_percent) if a.score_percent else None
            })

        return {
            "assignment_id": assignment_id,
            "attempt_count": len(attempt_list),
            "attempts": attempt_list
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN if "nepatří" in str(e) else status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Chyba: {str(e)}")


@app.get("/exam-assignments/{assignment_id}/attempts/{attempt_id}", tags=["Hodnocení a výsledky"])
def get_attempt_detail(
    assignment_id: int,
    attempt_id: int,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Vrátí detailní informace o pokusu studenta včetně snapshotů otázek a odpovědí."""
    try:
        attempt = db_layer.get_attempt_details(
            db=db,
            attempt_id=attempt_id,
            teacher_id=current_teacher["user_id"]
        )

        if attempt.assignment_id != assignment_id:
            raise ValueError("Pokus nepatří do tohoto přiřazení")

        return {
            "attempt_id": attempt.attempt_id,
            "assignment_id": attempt.assignment_id,
            "student_id": attempt.student_id,
            "started_at": attempt.started_at.isoformat(),
            "finished_at": attempt.finished_at.isoformat() if attempt.finished_at else None,
            "status": attempt.status.value,
            "total_points": float(attempt.total_points) if attempt.total_points else None,
            "max_points": float(attempt.max_points) if attempt.max_points else None,
            "score_percent": float(attempt.score_percent) if attempt.score_percent else None,
            "teacher_note": attempt.teacher_note,
            "questions_snapshot": attempt.questions_snapshot,
            "student_answers": attempt.student_answers or {}
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN if "nepatří" in str(e) else status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Chyba: {str(e)}")


@app.put("/exam-assignments/{assignment_id}/attempts/{attempt_id}/grade", tags=["Hodnocení a výsledky"])
def grade_attempt(
    assignment_id: int,
    attempt_id: int,
    grade_data: GradeAttemptRequest,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Ohodnotí pokus studenta (manuální hodnocení).

    ```json
    {
        "student_answers": {
            "question_1": {"answer": "správná odpověď", "points": 5},
            "question_2": {"answer": "výborné", "points": 10}
        },
        "total_points": 15,
        "teacher_note": "Velmi dobře"
    }
    ```
    """
    try:
        attempt = db_layer.get_attempt_details(
            db=db,
            attempt_id=attempt_id,
            teacher_id=current_teacher["user_id"]
        )

        if attempt.assignment_id != assignment_id:
            raise ValueError("Pokus nepatří do tohoto přiřazení")

        graded_attempt = db_layer.grade_attempt(
            db=db,
            attempt_id=attempt_id,
            teacher_id=current_teacher["user_id"],
            total_points=grade_data.total_points,
            student_answers=grade_data.student_answers,
            teacher_note=grade_data.teacher_note
        )

        return {
            "success": True,
            "message": "Pokus ohodnocen",
            "attempt": {
                "attempt_id": graded_attempt.attempt_id,
                "status": graded_attempt.status.value,
                "total_points": float(graded_attempt.total_points) if graded_attempt.total_points else None,
                "score_percent": float(graded_attempt.score_percent) if graded_attempt.score_percent else None,
                "teacher_note": graded_attempt.teacher_note
            }
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN if "nepatří" in str(e) else status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Chyba: {str(e)}")


@app.get("/exam-assignments/{assignment_id}/results-summary", tags=["Hodnocení a výsledky"])
def get_results_summary(
    assignment_id: int,
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Vrátí statistické shrnutí výsledků přiřazení (průměr, medián, pass rate atd.)."""
    try:
        summary = db_layer.get_results_summary(
            db=db,
            assignment_id=assignment_id,
            teacher_id=current_teacher["user_id"]
        )
        return summary
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN if "nepatří" in str(e) else status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Chyba: {str(e)}")


# ============================================================
# 🔧 VÝVOJOVÉ ENDPOINTY (neprodukční)
# ============================================================

@app.get("/students", tags=["Vývojové endpointy"])
def read_students(
    current_teacher: dict = Depends(require_teacher),
    db: Session = Depends(get_db)
):
    """Vrátí seznam všech studentů v systému (pouze pro vývoj/admin)."""
    students = db_layer.get_all_students(db)
    return students


@app.post("/test/create-teacher", tags=["Vývojové endpointy"])
def test_create_teacher(teacher_data: CreateTeacherRequest, db: Session = Depends(get_db)):
    """Vytvoří nového učitele – používat pouze pro testování."""
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
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Chyba při vytváření učitele: {str(e)}"
        )


@app.post("/test/create-student", tags=["Vývojové endpointy"])
def test_create_student(student_data: CreateStudentRequest, db: Session = Depends(get_db)):
    """Vytvoří nového studenta – používat pouze pro testování."""
    try:
        student = db_layer.create_student(
            db=db,
            email=student_data.email,
            login_code=student_data.login_code,
            password=student_data.password,
            group_id=student_data.group_id
        )

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
