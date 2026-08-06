from sqlalchemy.orm import Session
from database import get_db
from models import Student, Teacher, Group, Bank, TestTemplate, TestTemplateQuestion, Question, DifficultyLevel, ExamAssignment, StudentAttempt, AttemptStatus
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

def remove_student_from_group(db: Session, group_id: int, student_id: int, teacher_id: int):
    group = db.query(Group).filter(Group.group_id == group_id, Group.teacher_id == teacher_id).first()
    if not group:
        raise ValueError("Skupina neexistuje nebo nemáte oprávnění")
    
    from models import StudentGroup
    sg = db.query(StudentGroup).filter(StudentGroup.group_id == group_id, StudentGroup.student_id == student_id).first()
    if not sg:
        raise ValueError("Student není v této skupině")
        
    db.delete(sg)
    db.commit()

def delete_group(db: Session, group_id: int, teacher_id: int):
    group = db.query(Group).filter(Group.group_id == group_id, Group.teacher_id == teacher_id).first()
    if not group:
        raise ValueError("Skupina neexistuje nebo nemáte oprávnění")
        
    from models import ExamAssignment, StudentAttempt
    assignments = db.query(ExamAssignment).filter(ExamAssignment.group_id == group_id).all()
    for assignment in assignments:
        has_attempts = db.query(StudentAttempt).filter(StudentAttempt.assignment_id == assignment.assignment_id).count() > 0
        if not has_attempts:
            db.delete(assignment)
        else:
            assignment.group_id = None
            
    db.delete(group)
    db.commit()

def update_group(db: Session, group_id: int, group_data: dict, teacher_id: int):
    group = db.query(Group).filter(Group.group_id == group_id, Group.teacher_id == teacher_id).first()
    if not group:
        raise ValueError("Skupina neexistuje nebo nemáte oprávnění")
    
    if 'name' in group_data and group_data['name'] is not None: 
        group.name = group_data['name']
    if 'description' in group_data: 
        group.description = group_data['description']
        
    db.commit()
    db.refresh(group)
    return group


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
    """Získá všechny banky otázek učitele včetně počtu otázek"""
    from sqlalchemy import func
    from models import Question, Bank
    
    results = db.query(
        Bank,
        func.count(Question.question_id).label("question_count")
    ).outerjoin(
        Question, Bank.bank_id == Question.bank_id
    ).filter(
        Bank.teacher_id == teacher_id
    ).group_by(
        Bank.bank_id
    ).all()
    
    banks = []
    for bank, count in results:
        bank.question_count = count
        banks.append(bank)
        
    return banks

def delete_bank(db: Session, bank_id: int, teacher_id: int):
    from models import Bank, Question, TestTemplateQuestion
    bank = db.query(Bank).filter(Bank.bank_id == bank_id, Bank.teacher_id == teacher_id).first()
    if not bank:
        raise ValueError("Banka neexistuje nebo nemáte oprávnění")
        
    questions = db.query(Question).filter(Question.bank_id == bank_id).all()
    q_ids = [q.question_id for q in questions]
    if q_ids:
        in_templates = db.query(TestTemplateQuestion).filter(TestTemplateQuestion.question_id.in_(q_ids)).count()
        if in_templates > 0:
            raise ValueError("IN_USE")
            
    db.delete(bank)
    db.commit()

def update_bank(db: Session, bank_id: int, bank_data: dict, teacher_id: int):
    from models import Bank
    bank = db.query(Bank).filter(Bank.bank_id == bank_id, Bank.teacher_id == teacher_id).first()
    if not bank:
        raise ValueError("Banka neexistuje nebo nemáte oprávnění")
        
    if 'name' in bank_data: bank.name = bank_data['name']
    if 'description' in bank_data: bank.description = bank_data['description']
    if 'is_public' in bank_data: bank.is_public = bank_data['is_public']
    
    db.commit()
    db.refresh(bank)
    return bank

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


def delete_question(db: Session, question_id: int, bank_id: int, teacher_id: int, force: bool = False):
    """Smaže otázku. Pokud je v testech a force=False, vyhodí chybu."""
    bank = db.query(Bank).filter(Bank.bank_id == bank_id, Bank.teacher_id == teacher_id).first()
    if not bank:
        raise ValueError(f"Banka s ID {bank_id} neexistuje nebo jí nevlastníte")
        
    from models import Question, TestTemplateQuestion
    question = db.query(Question).filter(Question.question_id == question_id, Question.bank_id == bank_id).first()
    if not question:
        raise ValueError("Otázka nenalezena v této bance")
        
    in_templates = db.query(TestTemplateQuestion).filter(TestTemplateQuestion.question_id == question_id).all()
    
    if in_templates and not force:
        raise ValueError("IN_USE")
        
    if in_templates and force:
        for tq in in_templates:
            later_tqs = db.query(TestTemplateQuestion).filter(
                TestTemplateQuestion.template_id == tq.template_id,
                TestTemplateQuestion.position > tq.position
            ).all()
            for ltq in later_tqs:
                ltq.position -= 1
            db.delete(tq)
            
    db.delete(question)
    db.commit()

def update_question(db: Session, question_id: int, bank_id: int, question_data: dict, teacher_id: int):
    bank = db.query(Bank).filter(Bank.bank_id == bank_id, Bank.teacher_id == teacher_id).first()
    if not bank:
        raise ValueError(f"Banka s ID {bank_id} neexistuje nebo jí nevlastníte")
        
    from models import Question, Answer
    question = db.query(Question).filter(Question.question_id == question_id, Question.bank_id == bank_id).first()
    if not question:
        raise ValueError("Otázka nenalezena v této bance")
        
    if 'text' in question_data: question.text = question_data['text']
    if 'type' in question_data: question.type = question_data['type']
    if 'tags' in question_data: question.tags = question_data['tags']
    if 'image_url' in question_data: question.image_url = question_data['image_url']
    if 'default_points' in question_data: question.default_points = question_data['default_points']
    
    if 'answers' in question_data:
        db.query(Answer).filter(Answer.question_id == question_id).delete()
        for answer_data in question_data['answers']:
            new_answer = Answer(
                question_id=question.question_id,
                text=answer_data.get('text'),
                is_correct=answer_data.get('is_correct', False),
                order_index=answer_data.get('order_index') or 0
            )
            db.add(new_answer)
            
    db.commit()
    db.refresh(question)
    return question


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


# --- Exam Assignment Functions (Phase 1) ---

def create_exam_assignment(db: Session, teacher_id: int, group_id: int, template_id: int,
                           activate_from: str = None, activate_to: str = None,
                           time_limit_minutes: int = None, access_password: str = None,
                           show_immediate_feedback: bool = False):
    """Vytvoří nové přiřazení testu skupině.

    Dva režimy:
    - Naplánovaný: zadej activate_from + activate_to → is_active = True automaticky.
      Test se stane dostupným až když nastane čas (ověřuje se při každém requestu).
    - Manuální: bez časů → is_active = False. Učitel spustí ručně přes /activate.

    Args:
        db: Database session
        teacher_id: ID učitele (vlastníka testu)
        group_id: ID skupiny
        template_id: ID šablony testu
        activate_from: ISO datetime string - kdy se test otevře (volitelné)
        activate_to: ISO datetime string - kdy se test zavře (volitelné)
        time_limit_minutes: Maximální čas na test (volitelné)
        access_password: Heslo pro přístup k testu (volitelné)
        show_immediate_feedback: Zda zobrazit zpětnou vazbu ihned (default False)

    Returns:
        ExamAssignment model instance

    Raises:
        ValueError: Pokud nejsou splněny podmínky
    """
    from models import ExamAssignment
    from datetime import datetime

    # Ověř, že grupa patří učiteli
    group = db.query(Group).filter(
        Group.group_id == group_id,
        Group.teacher_id == teacher_id
    ).first()
    if not group:
        raise ValueError(f"Skupina s ID {group_id} neexistuje nebo nepatří vám")

    # Ověř, že šablona patří učiteli
    template = db.query(TestTemplate).filter(
        TestTemplate.template_id == template_id,
        TestTemplate.teacher_id == teacher_id
    ).first()
    if not template:
        raise ValueError(f"Šablona testu s ID {template_id} neexistuje nebo nepatří vám")

    # Parsuj datumy (pokud jsou zadány)
    activate_from_dt = None
    activate_to_dt = None

    if activate_from is not None and activate_to is not None:
        try:
            activate_from_dt = datetime.fromisoformat(activate_from.replace('Z', '+00:00'))
            activate_to_dt = datetime.fromisoformat(activate_to.replace('Z', '+00:00'))
        except Exception:
            raise ValueError("Neplatný formát data - použijte ISO format (2024-04-27T10:00:00Z)")

        if activate_from_dt >= activate_to_dt:
            raise ValueError("Čas otevření musí být dřív než čas zavření")
    elif activate_from is not None or activate_to is not None:
        raise ValueError("Musí být zadány oba časy (activate_from i activate_to) nebo žádný")

    # Test s časy = napánovaný → is_active = True (stane se dostupným až v okně)
    # Test bez časů = manuální → is_active = False (spustí učitel ručně)
    is_active = activate_from_dt is not None

    # Vytvoř přiřazení
    new_assignment = ExamAssignment(
        template_id=template_id,
        group_id=group_id,
        activate_from=activate_from_dt,
        activate_to=activate_to_dt,
        is_active=is_active,
        time_limit_minutes=time_limit_minutes,
        access_password=access_password,
        show_immediate_feedback=show_immediate_feedback
    )

    db.add(new_assignment)
    db.commit()
    db.refresh(new_assignment)

    return new_assignment


def get_group_assignments(db: Session, group_id: int, teacher_id: int):
    """Získá všechna přiřazení testů pro skupinu
    
    Args:
        db: Database session
        group_id: ID skupiny
        teacher_id: ID učitele (pro ověření vlastnictví)
    
    Returns:
        List of ExamAssignment instances
    
    Raises:
        ValueError: Pokud grupa nepatří učiteli
    """
    from models import ExamAssignment
    
    # Ověř vlastnictví
    group = db.query(Group).filter(
        Group.group_id == group_id,
        Group.teacher_id == teacher_id
    ).first()
    if not group:
        raise ValueError("Skupina neexistuje nebo nepatří vám")
    
    assignments = db.query(ExamAssignment).filter(
        ExamAssignment.group_id == group_id
    ).all()
    
    return assignments


def get_assignment_details(db: Session, assignment_id: int, teacher_id: int):
    """Získá detaily přiřazení testu
    
    Args:
        db: Database session
        assignment_id: ID přiřazení
        teacher_id: ID učitele (pro ověření vlastnictví)
    
    Returns:
        ExamAssignment instance s detaily
    
    Raises:
        ValueError: Pokud přiřazení nepatří učiteli
    """
    from models import ExamAssignment
    
    assignment = db.query(ExamAssignment).filter(
        ExamAssignment.assignment_id == assignment_id
    ).first()
    
    if not assignment:
        raise ValueError("Přiřazení neexistuje")
    
    # Ověř, že přiřazený test patří učiteli
    template = db.query(TestTemplate).filter(
        TestTemplate.template_id == assignment.template_id,
        TestTemplate.teacher_id == teacher_id
    ).first()
    
    if not template:
        raise ValueError("Přiřazení nepatří vám")
    
    return assignment


def update_assignment(db: Session, assignment_id: int, teacher_id: int, update_data: dict):
    """Upraví přiřazení testu.

    Args:
        db: Database session
        assignment_id: ID přiřazení
        teacher_id: ID učitele
        update_data: Dictionary s novými hodnotami
            (activate_from, activate_to, time_limit_minutes, access_password, is_active, show_immediate_feedback)

    Returns:
        Updated ExamAssignment instance
    """
    from models import ExamAssignment
    from datetime import datetime

    # Ověř vlastnictví
    assignment = get_assignment_details(db, assignment_id, teacher_id)

    # Updatuj časové pole
    if 'activate_from' in update_data and update_data['activate_from']:
        assignment.activate_from = datetime.fromisoformat(update_data['activate_from'].replace('Z', '+00:00'))

    if 'activate_to' in update_data and update_data['activate_to']:
        assignment.activate_to = datetime.fromisoformat(update_data['activate_to'].replace('Z', '+00:00'))

    if 'time_limit_minutes' in update_data and update_data['time_limit_minutes'] is not None:
        assignment.time_limit_minutes = update_data['time_limit_minutes']

    if 'access_password' in update_data:
        assignment.access_password = update_data['access_password']

    # is_active lze měnit přímo přes PUT (případně přes /activate a /deactivate)
    if 'is_active' in update_data and update_data['is_active'] is not None:
        assignment.is_active = update_data['is_active']
        
    if 'show_immediate_feedback' in update_data and update_data['show_immediate_feedback'] is not None:
        assignment.show_immediate_feedback = update_data['show_immediate_feedback']

    db.commit()
    db.refresh(assignment)
    
    return assignment


def activate_assignment(db: Session, assignment_id: int, teacher_id: int):
    """Manuálně aktivuje přiřazení testu (is_active = True)"""
    assignment = get_assignment_details(db, assignment_id, teacher_id)
    assignment.is_active = True
    db.commit()
    db.refresh(assignment)
    return assignment


def deactivate_assignment(db: Session, assignment_id: int, teacher_id: int):
    """Manuálně deaktivuje přiřazení testu (is_active = False)"""
    assignment = get_assignment_details(db, assignment_id, teacher_id)
    assignment.is_active = False
    db.commit()
    db.refresh(assignment)
    return assignment


def delete_assignment(db: Session, assignment_id: int, teacher_id: int):
    """Smaže přiřazení testu
    
    Args:
        db: Database session
        assignment_id: ID přiřazení
        teacher_id: ID učitele
    
    Returns:
        True pokud se smazalo
    """
    from models import ExamAssignment
    
    # Ověř vlastnictví
    assignment = get_assignment_details(db, assignment_id, teacher_id)
    
    db.delete(assignment)
    db.commit()
    
    return True


def get_assignment_attempts(db: Session, assignment_id: int, teacher_id: int):
    """Získá všechny pokusy v přiřazení testu
    
    Args:
        db: Database session
        assignment_id: ID přiřazení
        teacher_id: ID učitele
    
    Returns:
        List of StudentAttempt instances
    """
    from models import StudentAttempt
    
    # Ověř vlastnictví přiřazení
    assignment = get_assignment_details(db, assignment_id, teacher_id)
    
    # Načti všechny pokusy
    attempts = db.query(StudentAttempt).filter(
        StudentAttempt.assignment_id == assignment_id
    ).all()
    
    return attempts


def get_attempt_details(db: Session, attempt_id: int, teacher_id: int = None):
    """Získá detaily pokusu studenta
    
    Args:
        db: Database session
        attempt_id: ID pokusu
        teacher_id: ID učitele (pro ověření - volitelné, pokud None, vrátí bez ověřování)
    
    Returns:
        StudentAttempt instance
    """
    from models import StudentAttempt
    
    attempt = db.query(StudentAttempt).filter(
        StudentAttempt.attempt_id == attempt_id
    ).first()
    
    if not attempt:
        raise ValueError("Pokus neexistuje")
    
    if teacher_id:
        # Ověř, že přiřazení patří učiteli
        assignment = get_assignment_details(db, attempt.assignment_id, teacher_id)
    
    return attempt


def get_student_attempt_details(db: Session, attempt_id: int, student_id: int):
    """Získá detaily pokusu studenta s ověřením vlastnictví
    
    Args:
        db: Database session
        attempt_id: ID pokusu
        student_id: ID přihlášeného studenta
    
    Returns:
        StudentAttempt instance
    """
    from models import StudentAttempt
    
    attempt = db.query(StudentAttempt).filter(
        StudentAttempt.attempt_id == attempt_id
    ).first()
    
    if not attempt:
        raise ValueError("Pokus neexistuje")
    
    if attempt.student_id != student_id:
        raise ValueError("Nemáte oprávnění k zobrazení tohoto pokusu")
    
    return attempt


def grade_attempt(db: Session, attempt_id: int, teacher_id: int, total_points: float, 
                  student_answers: dict = None, teacher_note: str = None):
    """Ohodnotí pokus studenta (ručně nebo po auto-gradu)
    
    Args:
        db: Database session
        attempt_id: ID pokusu
        teacher_id: ID učitele
        total_points: Celkový počet bodů
        student_answers: Aktualizované odpovědi (JSONB)
        teacher_note: Poznámka učitele
    
    Returns:
        Updated StudentAttempt
    """
    from models import StudentAttempt, AttemptStatus
    from sqlalchemy.orm.attributes import flag_modified
    
    # Ověř, že pokus patří přiřazení učitele
    attempt = get_attempt_details(db, attempt_id, teacher_id)
    
    # Vypočti score_percent bezpečně s přetypováním z Decimal na float
    max_points = float(attempt.max_points) if attempt.max_points else 0.0
    score_percent = (float(total_points) / max_points * 100.0) if max_points > 0 else 0.0
    
    # Updatuj pokus
    attempt.total_points = float(total_points)
    attempt.score_percent = score_percent
    attempt.status = AttemptStatus.GRADED
    attempt.teacher_note = teacher_note
    
    if student_answers is not None:
        attempt.student_answers = student_answers
        flag_modified(attempt, "student_answers")
    
    db.commit()
    db.refresh(attempt)
    
    return attempt


def get_results_summary(db: Session, assignment_id: int, teacher_id: int):
    """Generuje shrnutí výsledků pro přiřazení
    
    Args:
        db: Database session
        assignment_id: ID přiřazení
        teacher_id: ID učitele
    
    Returns:
        Dictionary se statistikami
    """
    from models import StudentAttempt, AttemptStatus
    import statistics
    
    # Ověř vlastnictví
    assignment = get_assignment_details(db, assignment_id, teacher_id)
    
    # Načti všechny pokusy
    attempts = db.query(StudentAttempt).filter(
        StudentAttempt.assignment_id == assignment_id
    ).all()
    
    total_attempts = len(attempts)
    submitted_attempts = len([a for a in attempts if a.status in [AttemptStatus.SUBMITTED, AttemptStatus.GRADED]])
    graded_attempts = len([a for a in attempts if a.status == AttemptStatus.GRADED])
    
    # Vypočti statistiky
    graded_scores = [a.score_percent for a in attempts if a.status == AttemptStatus.GRADED and a.score_percent is not None]
    
    result = {
        "assignment_id": assignment_id,
        "total_attempts": total_attempts,
        "submitted_attempts": submitted_attempts,
        "graded_attempts": graded_attempts,
        "avg_score": None,
        "median_score": None,
        "min_score": None,
        "max_score": None,
        "pass_rate": None
    }
    
    if graded_scores:
        result["avg_score"] = round(statistics.mean(graded_scores), 2)
        result["median_score"] = round(statistics.median(graded_scores), 2)
        result["min_score"] = round(min(graded_scores), 2)
        result["max_score"] = round(max(graded_scores), 2)
        result["pass_rate"] = round(len([s for s in graded_scores if s >= 50]) / len(graded_scores) * 100, 2)
    
    return result


# --- Template Questions Management (Option 1 - bez DB změn) ---

def get_template_questions(db: Session, template_id: int, teacher_id: int):
    """Získá všechny otázky v šabloně testu
    
    Args:
        db: Database session
        template_id: ID šablony testu
        teacher_id: ID učitele (pro ověření vlastnictví)
    
    Returns:
        List of association objects s informacemi o otázce a šabloně
    
    Raises:
        ValueError: Pokud šablona nepatří učiteli
    """
    # Ověř vlastnictví šablony
    template = db.query(TestTemplate).filter(
        TestTemplate.template_id == template_id,
        TestTemplate.teacher_id == teacher_id
    ).first()
    if not template:
        raise ValueError("Šablona testu neexistuje nebo nepatří vám")
    
    # Načti všechny association objekty s otázkami
    template_questions = db.query(TestTemplateQuestion, Question).join(
        Question, TestTemplateQuestion.question_id == Question.question_id
    ).filter(
        TestTemplateQuestion.template_id == template_id
    ).order_by(TestTemplateQuestion.position).all()
    
    return template_questions


def update_template_question(db: Session, template_id: int, question_id: int, teacher_id: int, points_custom: int = None):
    """Upraví otázku v šabloně testu (jen points_custom)
    
    Args:
        db: Database session
        template_id: ID šablony testu
        question_id: ID otázky
        teacher_id: ID učitele
        points_custom: Nový počet bodů pro tuto otázku v šabloně
    
    Returns:
        Updated TestTemplateQuestion instance
    
    Raises:
        ValueError: Pokud šablona, otázka nebo vztah neexistuje
    """
    # Ověř vlastnictví šablony
    template = db.query(TestTemplate).filter(
        TestTemplate.template_id == template_id,
        TestTemplate.teacher_id == teacher_id
    ).first()
    if not template:
        raise ValueError("Šablona testu neexistuje nebo nepatří vám")
    
    # Ověř, že otázka existuje
    question = db.query(Question).filter(Question.question_id == question_id).first()
    if not question:
        raise ValueError(f"Otázka s ID {question_id} neexistuje")
    
    # Ověř, že otázka je v šabloně
    template_question = db.query(TestTemplateQuestion).filter(
        TestTemplateQuestion.template_id == template_id,
        TestTemplateQuestion.question_id == question_id
    ).first()
    if not template_question:
        raise ValueError(f"Otázka s ID {question_id} není v šabloně {template_id}")
    
    # Updatuj points_custom
    if points_custom is not None:
        template_question.points_custom = points_custom
    
    db.commit()
    db.refresh(template_question)
    
    return template_question


def delete_template_question(db: Session, template_id: int, question_id: int, teacher_id: int):
    """Odebere otázku ze šablony testu
    
    Args:
        db: Database session
        template_id: ID šablony testu
        question_id: ID otázky
        teacher_id: ID učitele
    
    Returns:
        True pokud se smazalo
    
    Raises:
        ValueError: Pokud šablona nepatří učiteli nebo vztah neexistuje
    """
    # Ověř vlastnictví šablony
    template = db.query(TestTemplate).filter(
        TestTemplate.template_id == template_id,
        TestTemplate.teacher_id == teacher_id
    ).first()
    if not template:
        raise ValueError("Šablona testu neexistuje nebo nepatří vám")
    
    # Ověř, že otázka je v šabloně
    template_question = db.query(TestTemplateQuestion).filter(
        TestTemplateQuestion.template_id == template_id,
        TestTemplateQuestion.question_id == question_id
    ).first()
    if not template_question:
        raise ValueError(f"Otázka s ID {question_id} není v šabloně {template_id}")
    
    # Smaž association
    db.delete(template_question)
    db.commit()
    
    return True


def add_template_question(db: Session, template_id: int, question_id: int, teacher_id: int, 
                         position: int, points_custom: int = None):
    """Přidá otázku do šablony testu
    
    Args:
        db: Database session
        template_id: ID šablony testu
        question_id: ID otázky z banky
        teacher_id: ID učitele (pro ověření vlastnictví)
        position: Pořadí otázky v testu
        points_custom: Vlastní body (volitelné, pokud None, použije se default_points)
    
    Returns:
        Created TestTemplateQuestion instance
    
    Raises:
        ValueError: Pokud šablona, otázka neexistuje nebo je již přidána
    """
    # Ověř vlastnictví šablony
    template = db.query(TestTemplate).filter(
        TestTemplate.template_id == template_id,
        TestTemplate.teacher_id == teacher_id
    ).first()
    if not template:
        raise ValueError("Šablona testu neexistuje nebo nepatří vám")
    
    # Ověř, že otázka existuje
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
    
    # Ověř, že otázka není již v šabloně
    existing = db.query(TestTemplateQuestion).filter(
        TestTemplateQuestion.template_id == template_id,
        TestTemplateQuestion.question_id == question_id
    ).first()
    if existing:
        raise ValueError(f"Otázka s ID {question_id} je již v šabloně")
    
    # Ověř, že position není již obsazena
    position_exists = db.query(TestTemplateQuestion).filter(
        TestTemplateQuestion.template_id == template_id,
        TestTemplateQuestion.position == position
    ).first()
    if position_exists:
        raise ValueError(f"Pozice {position} je již obsazena v šabloně")
    
    # Vytvoř association
    new_template_question = TestTemplateQuestion(
        template_id=template_id,
        question_id=question_id,
        position=position,
        points_custom=points_custom
    )
    
    db.add(new_template_question)
    db.commit()
    db.refresh(new_template_question)
    
    return new_template_question


# --- Groups with stats (bod 2) ---

def get_teacher_groups_with_stats(db: Session, teacher_id: int) -> list:
    """Získá všechny skupiny učitele obohacené o statistiky.

    Pro každou skupinu vrací:
    - student_count           -- počet studentů ve skupině
    - active_assignment_count -- počet přiřazení probíhajících právě teď
    - pending_grade_count     -- počet pokusů se statusem SUBMITTED čekajících na opravu

    Args:
        db: Database session
        teacher_id: ID učitele

    Returns:
        List of dict se všemi poli skupiny + statistiky
    """
    from datetime import datetime
    from models import ExamAssignment, StudentAttempt, AttemptStatus

    # PostgreSQL ukládá TIMESTAMP bez timezone -> používáme naive UTC
    now = datetime.utcnow()

    groups = db.query(Group).filter(Group.teacher_id == teacher_id).all()

    result = []
    for group in groups:
        assignments = db.query(ExamAssignment).filter(
            ExamAssignment.group_id == group.group_id
        ).all()

        active_assignment_count = sum(
            1 for a in assignments
            if a.is_active
            and a.activate_from is not None
            and a.activate_to is not None
            and a.activate_from <= now <= a.activate_to
            or (
                a.is_active
                and a.activate_from is None
                and a.activate_to is None
            )
        )

        assignment_ids = [a.assignment_id for a in assignments]
        if assignment_ids:
            pending_grade_count = db.query(StudentAttempt).filter(
                StudentAttempt.assignment_id.in_(assignment_ids),
                StudentAttempt.status == AttemptStatus.SUBMITTED
            ).count()
        else:
            pending_grade_count = 0

        result.append({
            "group_id": group.group_id,
            "name": group.name,
            "description": group.description,
            "created_at": group.created_at,
            "student_count": len(group.students),
            "active_assignment_count": active_assignment_count,
            "pending_grade_count": pending_grade_count,
        })

    return result


# --- Exam assignments overview (bod 3) ---

def get_group_assignments_overview(db: Session, group_id: int, teacher_id: int) -> dict:
    """Vrátí přehled přiřazení testů pro skupinu rozdělený na aktivní / nadcházející / dokončené.

    Každé přiřazení je obohaceno o:
    - template_name   -- název šablony testu
    - submitted_count -- počet pokusů se statusem SUBMITTED nebo GRADED
    - total_students  -- celkový počet studentů ve skupině

    Kategorizace podle aktuálního UTC času:
    - active:   activate_from <= now <= activate_to
    - upcoming: activate_from > now
    - finished: activate_to < now

    Args:
        db: Database session
        group_id: ID skupiny
        teacher_id: ID učitele (pro ověření vlastnictví)

    Returns:
        Dict s klíči group_id, active, upcoming, finished

    Raises:
        ValueError: Pokud skupina nepatří učiteli
    """
    from datetime import datetime
    from models import ExamAssignment, StudentAttempt, AttemptStatus, TestTemplate

    group = db.query(Group).filter(
        Group.group_id == group_id,
        Group.teacher_id == teacher_id
    ).first()
    if not group:
        raise ValueError("Skupina neexistuje nebo nepatří vám")

    total_students = len(group.students)
    # PostgreSQL ukládá TIMESTAMP bez timezone -> používáme naive UTC
    now = datetime.utcnow()

    assignments = db.query(ExamAssignment).filter(
        ExamAssignment.group_id == group_id
    ).all()

    active = []
    upcoming = []
    finished = []

    for a in assignments:
        template = db.query(TestTemplate).filter(
            TestTemplate.template_id == a.template_id
        ).first()
        template_name = template.name if template else None

        submitted_count = db.query(StudentAttempt).filter(
            StudentAttempt.assignment_id == a.assignment_id,
            StudentAttempt.status.in_([AttemptStatus.SUBMITTED, AttemptStatus.GRADED])
        ).count()

        entry = {
            "assignment_id": a.assignment_id,
            "template_name": template_name,
            "activate_from": a.activate_from.isoformat() if a.activate_from else None,
            "activate_to": a.activate_to.isoformat() if a.activate_to else None,
            "is_active": a.is_active,
            "time_limit_minutes": a.time_limit_minutes,
            "submitted_count": submitted_count,
            "total_students": total_students,
        }

        # Test je "aktivní" pokud is_active=True a je v časovém okně (nebo bez časů)
        is_live = a.is_active and (
            (a.activate_from is None and a.activate_to is None)
            or (a.activate_from is not None and a.activate_to is not None
                and a.activate_from <= now <= a.activate_to)
        )

        if is_live:
            active.append(entry)
        elif a.activate_to is not None and a.activate_to < now:
            finished.append(entry)
        else:
            upcoming.append(entry)

    return {
        "group_id": group_id,
        "active": active,
        "upcoming": upcoming,
        "finished": finished,
    }


# --- Student Test Taking API ---
from datetime import datetime, timezone

def get_student_groups(db: Session, student_id: int):
    student = db.query(Student).filter(Student.student_id == student_id).first()
    if not student:
        return []
        
    result = []
    for g in student.groups:
        result.append({
            "group_id": g.group_id,
            "name": g.name,
            "teacher_name": g.teacher.name,
            "description": g.description
        })
    return result

def get_student_assignments(db: Session, student_id: int):
    # Najít všechny skupiny, ve kterých student je
    student = db.query(Student).filter(Student.student_id == student_id).first()
    if not student:
        return []
    
    group_ids = [g.group_id for g in student.groups]
    if not group_ids:
        return []
        
    # Najít všechny assignments pro tyto skupiny
    assignments = db.query(ExamAssignment).filter(ExamAssignment.group_id.in_(group_ids)).all()
    
    result = []
    for a in assignments:
        # Check status from student attempts
        attempt = db.query(StudentAttempt).filter(
            StudentAttempt.assignment_id == a.assignment_id,
            StudentAttempt.student_id == student_id
        ).first()
        
        status = attempt.status.value if attempt else None
        
        # Determine if it requires password
        requires_password = a.access_password is not None and len(a.access_password) > 0
        
        result.append({
            "assignment_id": a.assignment_id,
            "attempt_id": attempt.attempt_id if attempt else None,
            "template_name": a.template.name,
            "description": a.template.description,
            "activate_from": a.activate_from.isoformat() if a.activate_from else None,
            "activate_to": a.activate_to.isoformat() if a.activate_to else None,
            "time_limit_minutes": a.time_limit_minutes,
            "requires_password": requires_password,
            "status": status,
            "group_id": a.group_id,
            "group_name": a.group.name if a.group else None,
            "question_count": len(a.template.question_associations) if a.template else 0
        })
    return result

def start_student_attempt(db: Session, student_id: int, assignment_id: int, password: str = None):
    assignment = db.query(ExamAssignment).filter(ExamAssignment.assignment_id == assignment_id).first()
    if not assignment:
        raise Exception("Přiřazení nenalezeno.")
        
    if not assignment.is_active:
        raise Exception("Test momentálně není aktivní.")
        
    now = datetime.utcnow()
    if assignment.activate_from and now < assignment.activate_from:
        raise Exception("Čas pro test ještě nenastal.")
    if assignment.activate_to and now > assignment.activate_to:
        raise Exception("Čas pro test již vypršel.")
        
    if assignment.access_password and assignment.access_password != password:
        raise Exception("Nesprávné heslo pro přístup k testu.")
        
    # Zkontroluj, jestli už nemá attempt
    existing_attempt = db.query(StudentAttempt).filter(
        StudentAttempt.assignment_id == assignment_id,
        StudentAttempt.student_id == student_id
    ).first()
    
    if existing_attempt:
        existing_attempt.time_limit_minutes = assignment.time_limit_minutes
        return existing_attempt  # Můžeme vrátit existující, pokud už začal
        
    # Vytvořit snapshot otázek
    questions = []
    max_points = 0.0
    
    # Seřadit podle pozice
    template_questions = sorted(assignment.template.question_associations, key=lambda x: x.position)
    
    for tq in template_questions:
        q = tq.question
        # Snapshot formát pro otázku
        q_snap = {
            "question_id": q.question_id,
            "text": q.text,
            "type": q.type.value,
            "image_url": q.image_url,
            "points": tq.points_custom if tq.points_custom is not None else q.default_points,
            "position": tq.position,
            "answers": []
        }
        max_points += q_snap["points"]
        
        # Odpovědi
        for ans in q.answers:
            ans_snap = {
                "answer_id": ans.answer_id,
                "text": ans.text,
                "is_correct": ans.is_correct,
                "order_index": ans.order_index
            }
            q_snap["answers"].append(ans_snap)
            
        questions.append(q_snap)
        
    # Vytvoření pokusu
    new_attempt = StudentAttempt(
        assignment_id=assignment_id,
        student_id=student_id,
        questions_snapshot=questions,
        max_points=max_points,
        status=AttemptStatus.STARTED,
        student_answers={}
    )
    db.add(new_attempt)
    db.commit()
    db.refresh(new_attempt)
    
    new_attempt.time_limit_minutes = assignment.time_limit_minutes
    return new_attempt


from sse_manager import sse_manager

def save_student_answers(db: Session, student_id: int, attempt_id: int, answers_dict: dict):
    attempt = db.query(StudentAttempt).filter(
        StudentAttempt.attempt_id == attempt_id,
        StudentAttempt.student_id == student_id
    ).first()
    
    if not attempt:
        raise Exception("Pokus nenalezen.")
        
    if attempt.status != AttemptStatus.STARTED:
        raise Exception("Nelze ukládat odpovědi k odevzdanému testu.")
        
    attempt.student_answers = answers_dict
    db.commit()
    db.refresh(attempt)
    
    # 1. Notifikace pro učitele
    teacher_channel = f"teacher_assignment_{attempt.assignment_id}"
    sse_manager.sync_publish(teacher_channel, {
        "event": "progress_update",
        "attempt_id": attempt_id,
        "student_id": student_id,
        "answers_count": len(answers_dict)
    })
    
    # 2. Zpětná vazba pro studenta (pokud je zapnutá)
    assignment = attempt.assignment
    if assignment.show_immediate_feedback:
        feedback_detail = {}
        for q_snap in attempt.questions_snapshot:
            q_id = str(q_snap["question_id"])
            q_id_int = q_snap["question_id"]
            ans_data = answers_dict.get(q_id) if q_id in answers_dict else answers_dict.get(q_id_int)
            
            if ans_data is None:
                continue
                
            q_type = q_snap["type"]
            if q_type == "OPEN_TEXT":
                feedback_detail[q_id] = "pending"
                continue
                
            correct_answers = [a for a in q_snap["answers"] if a.get("is_correct", False)]
            is_correct = False
            
            if q_type == "SINGLE_CHOICE":
                if len(correct_answers) > 0 and str(correct_answers[0]["answer_id"]) == str(ans_data):
                    is_correct = True
            elif q_type == "MULTI_CHOICE":
                if isinstance(ans_data, list):
                    correct_ids = set(str(a["answer_id"]) for a in correct_answers)
                    selected_ids = set(str(ans) for ans in ans_data)
                    if correct_ids == selected_ids:
                        is_correct = True
            elif q_type == "ORDERING":
                if isinstance(ans_data, list):
                    sorted_correct = sorted(q_snap["answers"], key=lambda x: x.get("order_index", 0))
                    if len(ans_data) > 0 and isinstance(ans_data[0], str) and not ans_data[0].isdigit():
                        correct_ordered = [a["text"] for a in sorted_correct]
                    else:
                        correct_ordered = [str(a["answer_id"]) for a in sorted_correct]
                    selected_ordered = [str(ans) if isinstance(ans, int) or str(ans).isdigit() else ans for ans in ans_data]
                    if correct_ordered == selected_ordered:
                        is_correct = True
            elif q_type == "SHORT_ANSWER":
                if ans_data is not None and isinstance(ans_data, str):
                    ans_clean = ans_data.strip().lower()
                    correct_texts = [a["text"].strip().lower() for a in correct_answers] if correct_answers else [a["text"].strip().lower() for a in q_snap["answers"]]
                    if ans_clean in correct_texts:
                        is_correct = True
            elif q_type == "MATCHING":
                correct_pairs = {}
                for a in q_snap["answers"]:
                    if "|||" in a.get("text", ""):
                        left, right = a["text"].split("|||", 1)
                        correct_pairs[left.strip().lower()] = right.strip().lower()
                    elif a.get("match_text"):
                        correct_pairs[a["text"].strip().lower()] = a["match_text"].strip().lower()
                
                if ans_data and isinstance(ans_data, dict) and correct_pairs:
                    all_match = True
                    for k, v in correct_pairs.items():
                        student_v = None
                        for sk, sv in ans_data.items():
                            if str(sk).strip().lower() == k:
                                student_v = str(sv).strip().lower()
                                break
                        if student_v != v:
                            all_match = False
                            break
                    if all_match:
                        is_correct = True
                elif ans_data and isinstance(ans_data, list) and correct_pairs:
                    student_dict = {}
                    for item in ans_data:
                        if isinstance(item, (list, tuple)) and len(item) == 2:
                            student_dict[str(item[0]).strip().lower()] = str(item[1]).strip().lower()
                        elif isinstance(item, dict) and "left" in item and "right" in item:
                            student_dict[str(item["left"]).strip().lower()] = str(item["right"]).strip().lower()
                    if correct_pairs and all(student_dict.get(k) == v for k, v in correct_pairs.items()):
                        is_correct = True
                        
            feedback_detail[q_id] = "correct" if is_correct else "incorrect"
            
        student_channel = f"student_attempt_{attempt_id}"
        sse_manager.sync_publish(student_channel, {
            "event": "immediate_feedback",
            "feedback": feedback_detail
        })
        
    return attempt


def auto_grade(questions_snapshot: list, student_answers: dict):
    total_points = 0.0
    has_open_text = False
    
    for q_snap in questions_snapshot:
        q_id = str(q_snap["question_id"])
        q_id_int = q_snap["question_id"]
        # Odpověď může být uložena pod string klíčem z JSON, zkusíme obojí
        ans_data = student_answers.get(q_id) if q_id in student_answers else student_answers.get(q_id_int)
        
        q_type = q_snap["type"]
        points = q_snap["points"]
        
        if q_type == "OPEN_TEXT":
            has_open_text = True
            q_snap["awardedPoints"] = 0
            continue
            
        if ans_data is None:
            q_snap["awardedPoints"] = 0
            continue
            
        correct_answers = [a for a in q_snap["answers"] if a.get("is_correct", False)]
        
        if q_type == "SINGLE_CHOICE":
            # ans_data by mohl být answer_id (int) nebo string
            if len(correct_answers) > 0 and str(correct_answers[0]["answer_id"]) == str(ans_data):
                total_points += points
                q_snap["awardedPoints"] = points
            else:
                q_snap["awardedPoints"] = 0
                
        elif q_type == "MULTI_CHOICE":
            if isinstance(ans_data, list):
                correct_ids = set(str(a["answer_id"]) for a in correct_answers)
                selected_ids = set(str(ans) for ans in ans_data)
                # Vše nebo nic
                if correct_ids == selected_ids:
                    total_points += points
                    q_snap["awardedPoints"] = points
                else:
                    q_snap["awardedPoints"] = 0
            else:
                q_snap["awardedPoints"] = 0
                    
        elif q_type == "ORDERING":
            if isinstance(ans_data, list):
                # Seřadit správné odpovědi podle order_index
                sorted_correct = sorted(q_snap["answers"], key=lambda x: x.get("order_index", 0))
                if len(ans_data) > 0 and isinstance(ans_data[0], str) and not ans_data[0].isdigit():
                    correct_ordered = [a["text"] for a in sorted_correct]
                else:
                    correct_ordered = [str(a["answer_id"]) for a in sorted_correct]
                selected_ordered = [str(ans) if isinstance(ans, int) or str(ans).isdigit() else ans for ans in ans_data]
                
                # Vše nebo nic
                if correct_ordered == selected_ordered:
                    total_points += points
                    q_snap["awardedPoints"] = points
                else:
                    q_snap["awardedPoints"] = 0
            else:
                q_snap["awardedPoints"] = 0

        elif q_type == "SHORT_ANSWER":
            if ans_data is not None and isinstance(ans_data, str):
                ans_clean = ans_data.strip().lower()
                correct_texts = [a["text"].strip().lower() for a in correct_answers] if correct_answers else [a["text"].strip().lower() for a in q_snap["answers"]]
                if ans_clean in correct_texts:
                    total_points += points
                    q_snap["awardedPoints"] = points
                else:
                    q_snap["awardedPoints"] = 0
            else:
                q_snap["awardedPoints"] = 0

        elif q_type == "MATCHING":
            correct_pairs = {}
            for a in q_snap["answers"]:
                if "|||" in a.get("text", ""):
                    left, right = a["text"].split("|||", 1)
                    correct_pairs[left.strip().lower()] = right.strip().lower()
                elif a.get("match_text"):
                    correct_pairs[a["text"].strip().lower()] = a["match_text"].strip().lower()
            
            is_matching_correct = False
            if ans_data and isinstance(ans_data, dict) and correct_pairs:
                all_match = True
                for k, v in correct_pairs.items():
                    student_v = None
                    for sk, sv in ans_data.items():
                        if str(sk).strip().lower() == k:
                            student_v = str(sv).strip().lower()
                            break
                    if student_v != v:
                        all_match = False
                        break
                if all_match:
                    is_matching_correct = True
            elif ans_data and isinstance(ans_data, list) and correct_pairs:
                student_dict = {}
                for item in ans_data:
                    if isinstance(item, (list, tuple)) and len(item) == 2:
                        student_dict[str(item[0]).strip().lower()] = str(item[1]).strip().lower()
                    elif isinstance(item, dict) and "left" in item and "right" in item:
                        student_dict[str(item["left"]).strip().lower()] = str(item["right"]).strip().lower()
                if correct_pairs and all(student_dict.get(k) == v for k, v in correct_pairs.items()):
                    is_matching_correct = True
            
            if is_matching_correct:
                total_points += points
                q_snap["awardedPoints"] = points
            else:
                q_snap["awardedPoints"] = 0
                    
    return total_points, has_open_text


def submit_student_attempt(db: Session, student_id: int, attempt_id: int, final_answers: dict = None):
    from sqlalchemy.orm.attributes import flag_modified

    attempt = db.query(StudentAttempt).filter(
        StudentAttempt.attempt_id == attempt_id,
        StudentAttempt.student_id == student_id
    ).first()
    
    if not attempt:
        raise Exception("Pokus nenalezen.")
        
    if attempt.status != AttemptStatus.STARTED:
        raise Exception("Tento pokus již byl odevzdán.")
        
    if final_answers is not None:
        attempt.student_answers = final_answers
        
    # Zastavení času
    now = datetime.utcnow()
    
    # Auto grade
    total_points, has_open_text = auto_grade(attempt.questions_snapshot, attempt.student_answers)
    flag_modified(attempt, "questions_snapshot")
    if final_answers is not None:
        flag_modified(attempt, "student_answers")
    
    attempt.total_points = total_points
    if attempt.max_points and attempt.max_points > 0:
        attempt.score_percent = (float(total_points) / float(attempt.max_points)) * 100.0
    else:
        attempt.score_percent = 0.0
        
    if has_open_text:
        attempt.status = AttemptStatus.SUBMITTED
    else:
        attempt.status = AttemptStatus.GRADED
        
    attempt.finished_at = now
    
    db.commit()
    db.refresh(attempt)

    # SSE notifikace pro učitele o odevzdání pokusu
    teacher_channel = f"teacher_assignment_{attempt.assignment_id}"
    sse_manager.sync_publish(teacher_channel, {
        "event": "attempt_submitted",
        "attempt_id": attempt_id,
        "student_id": student_id,
        "status": attempt.status.value,
        "score_percent": float(attempt.score_percent) if attempt.score_percent is not None else None
    })

    return attempt
