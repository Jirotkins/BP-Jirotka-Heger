from sqlalchemy.orm import Session
from database import get_db
from models import Student, Teacher, Group, Bank, TestTemplate, TestTemplateQuestion, Question, DifficultyLevel
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

def authenticate_student(db: Session, username: str, password: str):
    """Ověří studenta podle emailu nebo login_code a hesla"""
    # Zkusí najít podle login_code nebo emailu
    student = db.query(Student).filter(
        (Student.login_code == username) | (Student.email == username)
    ).first()
    if not student:
        return None
    if not student.active_flag:
        return None
    if not verify_password(password, student.password_hash):
        return None
    return student

def create_student(db: Session, email: str, login_code: str, password: str, group_id: int = None):
    """Vytvoří nového studenta s zahashovaným heslem
    
    Args:
        db: Database session
        email: Email studenta (unikátní)
        login_code: Přihlašovací kód (unikátní)
        password: Heslo
        group_id: Volitelné - přidá studenta do skupiny
    """
    existing_student = db.query(Student).filter(
        (Student.login_code == login_code) | (Student.email == email)
    ).first()
    if existing_student:
        raise ValueError("Login kód nebo email už existuje")

    password_hash = get_password_hash(password)
    
    new_student = Student(
        email=email,
        login_code=login_code,
        password_hash=password_hash,
        active_flag=True
    )
    
    # Pokud je zadán group_id, přidej studenta do skupiny
    if group_id:
        group = db.query(Group).filter(Group.group_id == group_id).first()
        if not group:
            raise ValueError("Skupina neexistuje")
        new_student.groups.append(group)
    
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


def create_student_in_group(db: Session, group_id: int, login_code: str, password: str, email: str = None):
    """Vytvoří studenta v konkrétní skupině
    
    Args:
        db: Database session
        group_id: ID skupiny
        login_code: Přihlašovací kód
        password: Heslo
        email: Email (pokud není zadán, generuje se z login_code)
    """
    existing_student = db.query(Student).filter(
        (Student.login_code == login_code) | (Student.email == email) if email else (Student.login_code == login_code)
    ).first()
    if existing_student:
        raise ValueError("Login kód nebo email už existuje")
    
    # Ověř, že skupina existuje
    group = db.query(Group).filter(Group.group_id == group_id).first()
    if not group:
        raise ValueError("Skupina neexistuje")

    # Pokud email není zadán, generuj ho
    if not email:
        email = f"{login_code}@school.local"

    password_hash = get_password_hash(password)
    
    new_student = Student(
        email=email,
        login_code=login_code,
        password_hash=password_hash,
        active_flag=True
    )
    
    # Přidej studenta do skupiny
    new_student.groups.append(group)
    
    db.add(new_student)
    db.commit()
    db.refresh(new_student)
    
    return new_student


def generate_random_password(length: int = 8) -> str:
    """Vygeneruje náhodné heslo"""
    characters = string.ascii_letters + string.digits
    return ''.join(random.choice(characters) for _ in range(length))


def get_group_students(db: Session, group_id: int, teacher_id: int):
    """Získá všechny studenty v konkrétní skupině - ověří, že skupina patří učiteli"""
    # Ověř, že skupina patří učiteli
    group = db.query(Group).filter(
        Group.group_id == group_id,
        Group.teacher_id == teacher_id
    ).first()
    if not group:
        raise ValueError("Skupina neexistuje nebo nepatří vám")
    
    # Získej všechny studenty prostřednictvím M2M vztahu
    students = group.students
    return students


def create_bulk_students(db: Session, group_id: int, prefix: str, count: int) -> list:
    """Vytvoří více studentů s auto-generovanými kódy, emaily a hesly
    
    Returns: seznam dict s login_code, email a password
    """
    # Ověř, že skupina existuje
    group = db.query(Group).filter(Group.group_id == group_id).first()
    if not group:
        raise ValueError("Skupina neexistuje")
    
    created_students = []
    
    for i in range(1, count + 1):
        login_code = f"{prefix}_{i:02d}"
        email = f"{prefix}_{i:02d}@school.local"
        password = generate_random_password(8)
        
        # Zkontroluj, že login_code a email neexistuje
        existing = db.query(Student).filter(
            (Student.login_code == login_code) | (Student.email == email)
        ).first()
        if existing:
            raise ValueError(f"Login kód nebo email {login_code} / {email} už existuje")
        
        password_hash = get_password_hash(password)
        
        new_student = Student(
            email=email,
            login_code=login_code,
            password_hash=password_hash,
            active_flag=True
        )
        
        # Přidej studenta do skupiny
        new_student.groups.append(group)
        
        db.add(new_student)
        created_students.append({
            "login_code": login_code,
            "email": email,
            "password": password
        })
    
    db.commit()
    return created_students


def create_bank(db: Session, teacher_id: int, name: str, description: str = None, is_public: bool = False):
    """Vytvoří novou banku otázek pro učitele"""
    new_bank = Bank(
        teacher_id=teacher_id,
        name=name,
        description=description,
        is_public=is_public
    )
    
    db.add(new_bank)
    db.commit()
    db.refresh(new_bank)
    
    return new_bank


def get_teacher_banks(db: Session, teacher_id: int):
    """Získá všechny banky otázek učitele"""
    banks = db.query(Bank).filter(Bank.teacher_id == teacher_id).all()
    return banks


def create_question(db: Session, bank_id: int, question_data: dict, teacher_id: int):
    """Vytvoří novou otázku v bance otázek učitele
    
    Args:
        db: Database session
        bank_id: ID banky, do které se má otázka přidat
        question_data: Dictionary s daty otázky (text, type, tags, image_url, default_points, answers)
        teacher_id: ID učitele (pro ověření vlastnictví banky)
    
    Returns:
        Question model instance s nabalenou associations
    
    Raises:
        ValueError: Pokud banka neexistuje nebo ji nevlastní učitel
    """
    # Ověříme, že banka existuje a patří učiteli
    bank = db.query(Bank).filter(
        Bank.bank_id == bank_id,
        Bank.teacher_id == teacher_id
    ).first()
    
    if not bank:
        raise ValueError(f"Banka s ID {bank_id} neexistuje nebo jí nevlastníte")
    
    # Importujeme zde aby se vyhnuli circular importům
    from models import Question, Answer, QuestionType
    
    # Vytvoříme otázku
    new_question = Question(
        bank_id=bank_id,
        text=question_data.get('text'),
        type=QuestionType[question_data.get('type')],  # Convert string to enum
        tags=question_data.get('tags'),
        image_url=question_data.get('image_url'),
        default_points=question_data.get('default_points', 1)
    )
    
    db.add(new_question)
    db.flush()  # Aby se generovalo question_id
    
    # Vytvoříme odpovědi
    if question_data.get('answers'):
        for answer_data in question_data.get('answers'):
            new_answer = Answer(
                question_id=new_question.question_id,
                text=answer_data.get('text'),
                is_correct=answer_data.get('is_correct', False),
                order_index=answer_data.get('order_index') or 0
            )
            db.add(new_answer)
    
    db.commit()
    db.refresh(new_question)  # Refresh aby se eager-loadily answers
    
    return new_question


def get_bank_questions(db: Session, bank_id: int, teacher_id: int):
    """Získá všechny otázky z banky otázek
    
    Args:
        db: Database session
        bank_id: ID banky
        teacher_id: ID učitele (pro ověření vlastnictví banky)
    
    Returns:
        List of Question model instances s nabalenou associations
    
    Raises:
        ValueError: Pokud banka neexistuje nebo ji nevlastní učitel
    """
    # Ověříme, že banka existuje a patří učiteli
    bank = db.query(Bank).filter(
        Bank.bank_id == bank_id,
        Bank.teacher_id == teacher_id
    ).first()
    
    if not bank:
        raise ValueError(f"Banka s ID {bank_id} neexistuje nebo jí nevlastníte")
    
    from models import Question
    
    # Získáme všechny otázky s eager-loadovanými odpověďmi
    questions = db.query(Question).filter(
        Question.bank_id == bank_id
    ).all()
    
    return questions


def create_test_template(db: Session, teacher_id: int, template_data: dict):
    """Vytvoří novou šablonu testu s ověřením vlastnictví otázek
    
    Args:
        db: Database session
        teacher_id: ID učitele (vlastníka testu)
        template_data: Dictionary s daty testu obsahující:
            - name: str (povinné)
            - description: str (volitelné)
            - difficulty: str (EASY, MEDIUM, HARD) - volitelné
            - estimated_duration_minutes: int - volitelné
            - tags: list[str] - volitelné
            - learning_objectives: list[str] - volitelné
            - is_active: bool (default True)
            - settings: dict - volitelné
            - questions: list[dict] - otázky [{"question_id": 1, "position": 1, "points_custom": None}, ...]
    
    Returns:
        TestTemplate model instance
    
    Raises:
        ValueError: Pokud otázka není z banky učitele nebo má jiné problémy
    """
    
    # Ověř, že učitel existuje
    teacher = db.query(Teacher).filter(Teacher.teacher_id == teacher_id).first()
    if not teacher:
        raise ValueError("Učitel neexistuje")
    
    # Ověř, že všechny otázky patří do bank učitele
    questions_data = template_data.get('questions', [])
    if questions_data:
        for q_data in questions_data:
            question_id = q_data.get('question_id')
            question = db.query(Question).filter(Question.question_id == question_id).first()
            
            if not question:
                raise ValueError(f"Otázka s ID {question_id} neexistuje")
            
            # Ověř, že banka otázky patří učiteli
            bank = db.query(Bank).filter(
                Bank.bank_id == question.bank_id,
                Bank.teacher_id == teacher_id
            ).first()
            
            if not bank:
                raise ValueError(f"Otázka s ID {question_id} nepatří do vaší banky otázek")
    
    # Vytvoř test template
    difficulty = template_data.get('difficulty')
    if difficulty:
        difficulty = DifficultyLevel[difficulty]
    
    new_template = TestTemplate(
        teacher_id=teacher_id,
        name=template_data.get('name'),
        description=template_data.get('description'),
        is_active=template_data.get('is_active', True),
        difficulty=difficulty,
        estimated_duration_minutes=template_data.get('estimated_duration_minutes'),
        tags=template_data.get('tags') or [],
        learning_objectives=template_data.get('learning_objectives') or [],
        settings=template_data.get('settings') or {}
    )
    
    db.add(new_template)
    db.flush()  # Aby se generovalo template_id
    
    # Přidej otázky do testu
    if questions_data:
        for q_data in questions_data:
            template_question = TestTemplateQuestion(
                template_id=new_template.template_id,
                question_id=q_data.get('question_id'),
                position=q_data.get('position'),
                points_custom=q_data.get('points_custom')
            )
            db.add(template_question)
    
    db.commit()
    db.refresh(new_template)
    
    return new_template


def get_teacher_test_templates(db: Session, teacher_id: int):
    """Získá všechny šablony testů učitele
    
    Args:
        db: Database session
        teacher_id: ID učitele
    
    Returns:
        List of TestTemplate model instances
    """
    templates = db.query(TestTemplate).filter(
        TestTemplate.teacher_id == teacher_id
    ).all()
    
    return templates

