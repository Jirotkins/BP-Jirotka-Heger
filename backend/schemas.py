from pydantic import BaseModel, field_validator, model_validator
from datetime import datetime

class LoginRequest(BaseModel):
    username: str  # email pro učitele, login_code pro studenta
    password: str
    is_teacher: bool = True  # True pro učitele, False pro studenta


class CreateStudentRequest(BaseModel):
    email: str
    login_code: str
    password: str
    group_id: int = 1
    
    @field_validator('password')
    @classmethod
    def validate_password_length(cls, v):
        if len(v.encode('utf-8')) > 72:
            raise ValueError("Heslo může mít maximálně 72 bytů")
        return v


class CreateTeacherRequest(BaseModel):
    name: str
    email: str
    password: str
    
    @field_validator('password')
    @classmethod
    def validate_password_length(cls, v):
        if len(v.encode('utf-8')) > 72:
            raise ValueError("Heslo může mít maximálně 72 bytů")
        return v


class Token(BaseModel):
    access_token: str
    token_type: str
    user_type: str
    user_id: int


class CreateGroupRequest(BaseModel):
    name: str
    description: str = None

class CreateSingleStudentRequest(BaseModel):
    email: str = None  # Volitelné - pokud není zadáno, generuje se z login_code
    login_code: str
    password: str
    
    @field_validator('password')
    @classmethod
    def validate_password_length(cls, v):
        if len(v.encode('utf-8')) > 72:
            raise ValueError("Heslo může mít maximálně 72 bytů")
        return v


class CreateBulkStudentsRequest(BaseModel):
    prefix: str
    count: int
    
    @field_validator('count')
    @classmethod
    def validate_count(cls, v):
        if v < 1 or v > 100:
            raise ValueError("Počet studentů musí být mezi 1 a 100")
        return v


class CreateBankRequest(BaseModel):
    name: str
    description: str = None
    is_public: bool = False


# --- Question and Answer Schemas ---

class AnswerCreateRequest(BaseModel):
    """Schema pro vytváření odpovědí na otázky"""
    text: str
    match_text: str | None = None  # Volitelné pro MATCHING typ (pokud není použito 'Pojem|||Definice')
    is_correct: bool = False
    order_index: int | None = None  # Povinné pro ORDERING typ


class AnswerResponse(BaseModel):
    """Schema pro vrácení odpovědí v API"""
    answer_id: int
    text: str
    is_correct: bool
    order_index: int | None = None
    
    class Config:
        from_attributes = True


class QuestionCreateRequest(BaseModel):
    """Schema pro vytváření otázky s validací typu"""
    text: str
    type: str  # SINGLE_CHOICE, MULTI_CHOICE, OPEN_TEXT, ORDERING, MATCHING, SHORT_ANSWER
    tags: list[str] | None = None
    image_url: str | None = None
    default_points: int = 1
    answers: list[AnswerCreateRequest] = []
    
    @field_validator('type')
    @classmethod
    def validate_question_type(cls, v):
        valid_types = ['SINGLE_CHOICE', 'MULTI_CHOICE', 'OPEN_TEXT', 'ORDERING', 'MATCHING', 'SHORT_ANSWER']
        if v not in valid_types:
            raise ValueError(f"Typ otázky musí být jeden z: {', '.join(valid_types)}")
        return v
    
    @field_validator('default_points')
    @classmethod
    def validate_points(cls, v):
        if v < 1:
            raise ValueError("Počet bodů musí být alespoň 1")
        return v
    
    @model_validator(mode='after')
    def validate_answers_by_type(self):
        question_type = self.type
        v = self.answers
        
        # SINGLE_CHOICE a MULTI_CHOICE musí mít alespoň jednu správnou odpověď
        if question_type in ['SINGLE_CHOICE', 'MULTI_CHOICE']:
            if not v or len(v) == 0:
                raise ValueError(f"{question_type} musí obsahovat alespoň jednu odpověď")
            correct_count = sum(1 for a in v if a.is_correct)
            if correct_count == 0:
                raise ValueError(f"{question_type} musí obsahovat alespoň jednu správnou odpověď")
        
        # ORDERING musí mít všechny odpovědi s order_index
        if question_type == 'ORDERING':
            if not v or len(v) == 0:
                raise ValueError("ORDERING musí obsahovat alespoň jednu odpověď")
            if any(a.order_index is None for a in v):
                raise ValueError("ORDERING musí mít order_index pro každou odpověď")
            order_indices = [a.order_index for a in v]
            if len(order_indices) != len(set(order_indices)):
                raise ValueError("ORDERING musí mít unikátní order_index pro každou odpověď")
        
        # MATCHING musí mít alespoň 2 dvojice
        if question_type == 'MATCHING':
            if not v or len(v) < 2:
                raise ValueError("MATCHING musí obsahovat alespoň 2 dvojice pro spojování")
        
        # SHORT_ANSWER musí mít alespoň jednu správnou odpověď
        if question_type == 'SHORT_ANSWER':
            if not v or len(v) == 0:
                raise ValueError("SHORT_ANSWER musí obsahovat alespoň jednu správnou odpověď")
            # Pokud není explicitně označena žádná jako is_correct, považujeme všechny za správné varianty
            has_correct = any(a.is_correct for a in v)
            if not has_correct:
                for a in v:
                    a.is_correct = True
        
        # OPEN_TEXT nemá povinné odpovědi (mohou být hints)
        if question_type == 'OPEN_TEXT':
            # Odpovědi nejsou povinné, ale pokud jsou, jsou to jen hinty
            pass
        
        return self


class CreateTestTemplateRequest(BaseModel):
    """Schema pro vytvoření testu (šablony)"""
    name: str
    description: str = None
    difficulty: str = None  # EASY, MEDIUM, HARD
    estimated_duration_minutes: int = None
    tags: list[str] = None
    learning_objectives: list[str] = None
    is_active: bool = True
    settings: dict = None
    # Otázky: seznam Question IDs a jejich pořadí/bodů
    questions: list[dict] = []  # Formát: [{"question_id": 1, "position": 1, "points_custom": 2}, ...]
    
    @field_validator('name')
    @classmethod
    def validate_name(cls, v):
        if not v or len(v.strip()) == 0:
            raise ValueError("Název testu nemůže být prázdný")
        if len(v) > 255:
            raise ValueError("Název testu nemůže být delší než 255 znaků")
        return v
    
    @field_validator('difficulty')
    @classmethod
    def validate_difficulty(cls, v):
        if v is not None:
            valid_difficulties = ['EASY', 'MEDIUM', 'HARD']
            if v not in valid_difficulties:
                raise ValueError(f"Obtížnost musí být jeden z: {', '.join(valid_difficulties)}")
        return v
    
    @field_validator('estimated_duration_minutes')
    @classmethod
    def validate_duration(cls, v):
        if v is not None and v < 1:
            raise ValueError("Doba trvání musí být alespoň 1 minuta")
        return v
    
    @field_validator('questions')
    @classmethod
    def validate_questions(cls, v):
        # Zkontroluj, že obsahují question_id a position
        for q in v:
            if 'question_id' not in q:
                raise ValueError("Každá otázka musí obsahovat question_id")
            if 'position' not in q:
                raise ValueError("Každá otázka musí obsahovat position")
        
        # Zkontroluj, že jsou unikátní pozice
        positions = [q['position'] for q in v]
        if len(positions) != len(set(positions)):
            raise ValueError("Pozice otázek musí být unikátní")
        
        return v


class QuestionResponse(BaseModel):
    """Schema pro vrácení otázky s odpověďmi"""
    question_id: int
    text: str
    type: str
    tags: list[str] = None
    image_url: str = None
    default_points: int
    answers: list[AnswerResponse] = []
    
    class Config:
        from_attributes = True


# --- Exam Assignment Schemas (Phase 1) ---

class ExamAssignmentCreate(BaseModel):
    """Schema pro vytvoření přiřazení testu skupině.

    Dva režimy:
    - Naplánovaný test: vyplnit activate_from + activate_to → is_active se nastaví na True automaticky
    - Manuální test:    nechat časy prázdné → is_active = False, spustit ručně přes /activate
    """
    template_id: int
    activate_from: str | None = None  # ISO datetime: "2024-04-27T10:00:00Z"
    activate_to: str | None = None    # ISO datetime
    time_limit_minutes: int | None = None
    access_password: str | None = None
    show_immediate_feedback: bool = False

    @field_validator('time_limit_minutes')
    @classmethod
    def validate_time_limit(cls, v):
        if v is not None and v < 1:
            raise ValueError("Čas limit musí být alespoň 1 minuta")
        return v

    @field_validator('activate_to')
    @classmethod
    def validate_time_window(cls, v, info):
        """Pokud jsou zadány oba časy, activate_from musí být dřív než activate_to."""
        activate_from = info.data.get('activate_from')
        if v is not None and activate_from is not None:
            from datetime import datetime
            try:
                dt_from = datetime.fromisoformat(activate_from.replace('Z', '+00:00'))
                dt_to = datetime.fromisoformat(v.replace('Z', '+00:00'))
                if dt_from >= dt_to:
                    raise ValueError("activate_from musí být dřív než activate_to")
            except ValueError as e:
                raise e
        return v


class ExamAssignmentUpdate(BaseModel):
    """Schema pro update přiřazení testu.

    Všechna pole jsou volitelná – posílej jen to, co chceš změnit.
    Ke změně is_active použij dedikované endpointy /activate a /deactivate.
    """
    activate_from: str | None = None
    activate_to: str | None = None
    time_limit_minutes: int | None = None
    access_password: str | None = None
    is_active: bool | None = None
    show_immediate_feedback: bool | None = None


class ExamAssignmentResponse(BaseModel):
    """Schema pro vrácení přiřazení testu"""
    assignment_id: int
    template_id: int
    group_id: int
    activate_from: str | None = None
    activate_to: str | None = None
    is_active: bool
    time_limit_minutes: int | None = None
    access_password: str | None = None
    show_immediate_feedback: bool = False
    created_at: str

    class Config:
        from_attributes = True


class StudentAnswerSnapshot(BaseModel):
    """Snapshot studentovy odpovědi"""
    question_id: int
    answered_at: str = None
    answer_data: dict = None  # Formát zavisle na typu otázky


class StudentAttemptResponse(BaseModel):
    """Schema pro vrácení pokusu studenta"""
    attempt_id: int
    assignment_id: int
    student_id: int
    student_name: str | None = None
    started_at: datetime
    finished_at: datetime | None = None
    status: str  # STARTED, SUBMITTED, GRADED
    total_points: float = None
    max_points: float = None
    score_percent: float = None
    teacher_note: str = None
    
    class Config:
        from_attributes = True


class StudentAttemptDetailedResponse(BaseModel):
    """Detailní info o pokusu - s otázkami a odpověďmi"""
    attempt_id: int
    assignment_id: int
    student_id: int
    started_at: datetime
    finished_at: datetime | None = None
    status: str
    total_points: float = None
    max_points: float = None
    score_percent: float = None
    teacher_note: str = None
    questions_snapshot: dict  # JSONB - snapshot otázek
    student_answers: dict = None  # JSONB - odpovědi studenta
    
    class Config:
        from_attributes = True


class GradeAttemptRequest(BaseModel):
    """Schema pro hodnocení pokusu učitelem"""
    student_answers: dict | list | None = None  # Aktualizované odpovědi s body
    total_points: float
    teacher_note: str | None = None


class ResultsSummary(BaseModel):
    """Shrnutí výsledků testování pro skupinu"""
    assignment_id: int
    total_attempts: int
    submitted_attempts: int
    graded_attempts: int
    avg_score: float = None
    median_score: float = None
    min_score: float = None
    max_score: float = None
    pass_rate: float = None  # % studentů s > 50 bodů


# --- Test Template Questions Management Schemas ---

class TemplateQuestionResponse(BaseModel):
    """Otázka v šabloně testu - s info z template a question"""
    question_id: int
    position: int
    points_custom: int = None
    text: str
    type: str
    default_points: int
    tags: list[str] = None
    image_url: str = None
    answers: list[AnswerResponse] = []
    
    class Config:
        from_attributes = True


class UpdateTemplateQuestionRequest(BaseModel):
    """Schema pro update otázky v šabloně"""
    points_custom: int = None  # Vlastní body pro tuto šablonu
    
    @field_validator('points_custom')
    @classmethod
    def validate_points(cls, v):
        if v is not None and v < 0:
            raise ValueError("Počet bodů nemůže být negativní")
        return v


class CreateTemplateQuestionRequest(BaseModel):
    """Schema pro přidání otázky do šablony testu"""
    question_id: int  # ID otázky z banky
    position: int  # Pořadí v testu
    points_custom: int = None  # Volitelné: vlastní body (pokud None, použije se default_points)
    
    @field_validator('position')
    @classmethod
    def validate_position(cls, v):
        if v < 1:
            raise ValueError("Pořadí otázky musí být alespoň 1")
        return v
    
    @field_validator('points_custom')
    @classmethod
    def validate_points(cls, v):
        if v is not None and v < 0:
            raise ValueError("Počet bodů nemůže být negativní")
        return v


# --- Student API Schemas ---

from typing import Any

class StudentAssignmentResponse(BaseModel):
    """Schema pro vrácení přiřazených testů studentovi"""
    assignment_id: int
    attempt_id: int | None = None
    template_name: str
    description: str | None = None
    activate_from: str | None = None
    activate_to: str | None = None
    time_limit_minutes: int | None = None
    requires_password: bool
    status: str | None = None  # None, STARTED, SUBMITTED, GRADED
    group_id: int | None = None
    group_name: str | None = None
    question_count: int | None = None
    
    class Config:
        from_attributes = True


class StartAttemptRequest(BaseModel):
    access_password: str | None = None


class StartAttemptResponse(BaseModel):
    attempt_id: int
    started_at: datetime
    time_limit_minutes: int | None = None
    questions_snapshot: list[dict]
    
    class Config:
        from_attributes = True


class SaveAnswersRequest(BaseModel):
    """Průběžné uložení odpovědí"""
    answers: dict[int, Any]  # question_id -> answer_data


class SubmitAttemptResponse(BaseModel):
    attempt_id: int
    status: str
    total_points: float | None = None
    max_points: float | None = None
    score_percent: float | None = None