from sqlalchemy.orm import Session
from database import get_db
from models import Student, Teacher
from auth import verify_password, get_password_hash

def get_all_students(db: Session):
    """Metoda pro získání všech studentů z databáze"""
    students = db.query(Student).all()
    return students

def authenticate_teacher(db: Session, email: str, password: str):
    """Ověří učitele podle emailu a hesla"""
    teacher = db.query(Teacher).filter(Teacher.email == email).first()
    if not teacher:
        return None
    if not verify_password(password, teacher.password_hash):
        return None
    return teacher

def authenticate_student(db: Session, login_code: str, password: str):
    """Ověří studenta podle login_code a hesla"""
    student = db.query(Student).filter(Student.login_code == login_code).first()
    if not student:
        return None
    if not student.active_flag:
        return None
    if not verify_password(password, student.password_hash):
        return None
    return student

def create_student(db: Session, login_code: str, password: str, group_id: int = 1):
    """Vytvoří nového studenta s zahashovaným heslem"""
    existing_student = db.query(Student).filter(Student.login_code == login_code).first()
    if existing_student:
        raise ValueError("Login kód už existuje")

    password_hash = get_password_hash(password)
    
    new_student = Student(
        login_code=login_code,
        password_hash=password_hash,
        group_id=group_id,
        active_flag=True
    )
    
    db.add(new_student)
    db.commit()
    db.refresh(new_student)
    
    return new_student

def create_teacher(db: Session, name: str, email: str, password: str):
    """Vytvoří nového učitele s zahashovaným heslem"""
    existing_teacher = db.query(Teacher).filter(Teacher.email == email).first()
    if existing_teacher:
        raise ValueError("Email už existuje")

    password_hash = get_password_hash(password)
    
    new_teacher = Teacher(
        name=name,
        email=email,
        password_hash=password_hash
    )
    
    db.add(new_teacher)
    db.commit()
    db.refresh(new_teacher)
    
    return new_teacher

