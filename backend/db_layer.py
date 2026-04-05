from sqlalchemy.orm import Session
from database import get_db
from models import Student, Teacher, Group
from auth import verify_password, get_password_hash
import string
import random

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


def create_group(db: Session, teacher_id: int, name: str, description: str = None):
    """Vytvoří novou skupinu učitele"""
    new_group = Group(
        teacher_id=teacher_id,
        name=name,
        description=description
    )
    
    db.add(new_group)
    db.commit()
    db.refresh(new_group)
    
    return new_group


def get_teacher_groups(db: Session, teacher_id: int):
    """Získá všechny skupiny učitele"""
    groups = db.query(Group).filter(Group.teacher_id == teacher_id).all()
    return groups


def create_student_in_group(db: Session, group_id: int, login_code: str, password: str):
    """Vytvoří studenta v konkrétní skupině"""
    existing_student = db.query(Student).filter(Student.login_code == login_code).first()
    if existing_student:
        raise ValueError("Login kód už existuje")
    
    # Ověř, že skupina existuje
    group = db.query(Group).filter(Group.group_id == group_id).first()
    if not group:
        raise ValueError("Skupina neexistuje")

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


def generate_random_password(length: int = 8) -> str:
    """Vygeneruje náhodné heslo"""
    characters = string.ascii_letters + string.digits
    return ''.join(random.choice(characters) for _ in range(length))


def create_bulk_students(db: Session, group_id: int, prefix: str, count: int) -> list:
    """Vytvoří více studentů s auto-generovanými kódy a hesly
    
    Returns: seznam dict s login_code a password
    """
    # Ověř, že skupina existuje
    group = db.query(Group).filter(Group.group_id == group_id).first()
    if not group:
        raise ValueError("Skupina neexistuje")
    
    created_students = []
    
    for i in range(1, count + 1):
        login_code = f"{prefix}_{i:02d}"
        password = generate_random_password(8)
        
        # Zkontroluj, že login_code neexistuje
        existing = db.query(Student).filter(Student.login_code == login_code).first()
        if existing:
            raise ValueError(f"Login kód {login_code} už existuje")
        
        password_hash = get_password_hash(password)
        
        new_student = Student(
            login_code=login_code,
            password_hash=password_hash,
            group_id=group_id,
            active_flag=True
        )
        
        db.add(new_student)
        created_students.append({
            "login_code": login_code,
            "password": password
        })
    
    db.commit()
    return created_students

