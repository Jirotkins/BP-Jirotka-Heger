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
from schemas import LoginRequest, CreateStudentRequest, CreateTeacherRequest, Token, CreateGroupRequest, CreateSingleStudentRequest, CreateBulkStudentsRequest

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
    return {
        "teacher_id": current_teacher["user_id"],
        "groups": groups
    }

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
            password=student_data.password
        )
        return {
            "success": True,
            "message": "Student vytvořen",
            "student_id": student.student_id,
            "login_code": student.login_code,
            "group_id": student.group_id
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
        writer.writerow(["Login kód", "Heslo"])
        for student in students:
            writer.writerow([student["login_code"], student["password"]])
        
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
            login_code=student_data.login_code,
            password=student_data.password,
            group_id=student_data.group_id
        )
        return {
            "success": True,
            "message": "Student vytvořen",
            "student_id": student.student_id,
            "login_code": student.login_code,
            "group_id": student.group_id
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
