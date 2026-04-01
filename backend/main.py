from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import timedelta
import os
from database import get_db
import db_layer
from auth import create_access_token, ACCESS_TOKEN_EXPIRE_MINUTES, require_teacher, require_student
from schemas import LoginRequest, CreateStudentRequest, Token

app = FastAPI()

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
