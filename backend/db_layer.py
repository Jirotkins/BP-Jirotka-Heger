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


# --- Exam Assignment Functions (Phase 1) ---

def create_exam_assignment(db: Session, teacher_id: int, group_id: int, template_id: int,
                          activate_from: str = None, activate_to: str = None,
                          time_limit_minutes: int = None, access_password: str = None):
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
        access_password=access_password
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
            (activate_from, activate_to, time_limit_minutes, access_password, is_active)

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
    
    # Ověř, že pokus patří přiřazení učitele
    attempt = get_attempt_details(db, attempt_id, teacher_id)
    
    # Získej přiřazení pro max_points
    assignment = db.query(type(attempt).__table__.c.assignment_id).filter(
        type(attempt).__table__.c.attempt_id == attempt_id
    ).first()
    
    # Vypočti score_percent
    max_points = attempt.max_points or 0
    score_percent = (total_points / max_points * 100) if max_points > 0 else 0
    
    # Updatuj pokus
    attempt.total_points = total_points
    attempt.score_percent = score_percent
    attempt.status = AttemptStatus.GRADED
    attempt.teacher_note = teacher_note
    
    if student_answers:
        attempt.student_answers = student_answers
    
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
