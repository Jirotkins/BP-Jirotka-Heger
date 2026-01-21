from sqlalchemy import Column, Integer, String, Boolean, Text, ForeignKey, DateTime, DECIMAL, Enum
from sqlalchemy.orm import relationship, Mapped, mapped_column
from sqlalchemy.dialects.postgresql import ARRAY, JSONB
from sqlalchemy.sql import func
import enum
from database import Base

# --- ENUMS (Výčtové typy) ---
class QuestionType(enum.Enum):
    SINGLE_CHOICE = "SINGLE_CHOICE"
    MULTI_CHOICE = "MULTI_CHOICE"
    OPEN_TEXT = "OPEN_TEXT"
    ORDERING = "ORDERING"

class AttemptStatus(enum.Enum):
    STARTED = "STARTED"
    SUBMITTED = "SUBMITTED"
    GRADED = "GRADED"

# --- MODELY ---

class Teacher(Base):
    __tablename__ = "teachers"

    teacher_id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, nullable=False)
    password_hash = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Vztahy
    groups = relationship("Group", back_populates="teacher", cascade="all, delete-orphan")
    banks = relationship("Bank", back_populates="teacher", cascade="all, delete-orphan")
    test_templates = relationship("TestTemplate", back_populates="teacher")


class Group(Base):
    __tablename__ = "groups"

    group_id = Column(Integer, primary_key=True, index=True)
    teacher_id = Column(Integer, ForeignKey("teachers.teacher_id"))
    name = Column(String, nullable=False)
    description = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Vztahy
    teacher = relationship("Teacher", back_populates="groups")
    students = relationship("Student", back_populates="group", cascade="all, delete-orphan")
    assignments = relationship("ExamAssignment", back_populates="group")


class Student(Base):
    __tablename__ = "students"

    student_id = Column(Integer, primary_key=True, index=True)
    group_id = Column(Integer, ForeignKey("groups.group_id"))
    login_code = Column(String, unique=True, nullable=False)
    password_hash = Column(String)
    active_flag = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Vztahy
    group = relationship("Group", back_populates="students")
    attempts = relationship("StudentAttempt", back_populates="student")


class Bank(Base):
    __tablename__ = "banks"

    bank_id = Column(Integer, primary_key=True, index=True)
    teacher_id = Column(Integer, ForeignKey("teachers.teacher_id"))
    name = Column(String, nullable=False)
    description = Column(Text)
    is_public = Column(Boolean, default=False)

    # Vztahy
    teacher = relationship("Teacher", back_populates="banks")
    questions = relationship("Question", back_populates="bank", cascade="all, delete-orphan")


class Question(Base):
    __tablename__ = "questions"

    question_id = Column(Integer, primary_key=True, index=True)
    bank_id = Column(Integer, ForeignKey("banks.bank_id"))
    text = Column(Text, nullable=False)
    type = Column(Enum(QuestionType), default=QuestionType.SINGLE_CHOICE)
    tags = Column(ARRAY(String))  # Postgres Array
    image_url = Column(String)
    default_points = Column(Integer, default=1)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Vztahy
    bank = relationship("Bank", back_populates="questions")
    answers = relationship("Answer", back_populates="question", cascade="all, delete-orphan")
    template_associations = relationship("TestTemplateQuestion", back_populates="question")


class Answer(Base):
    __tablename__ = "answers"

    answer_id = Column(Integer, primary_key=True, index=True)
    question_id = Column(Integer, ForeignKey("questions.question_id"))
    text = Column(Text, nullable=False)
    is_correct = Column(Boolean, default=False)
    order_index = Column(Integer, default=0)

    # Vztahy
    question = relationship("Question", back_populates="answers")


class TestTemplate(Base):
    __tablename__ = "test_templates"

    template_id = Column(Integer, primary_key=True, index=True)
    teacher_id = Column(Integer, ForeignKey("teachers.teacher_id"))
    name = Column(String, nullable=False)
    settings = Column(JSONB, default={})  # Postgres JSONB
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Vztahy
    teacher = relationship("Teacher", back_populates="test_templates")
    question_associations = relationship("TestTemplateQuestion", back_populates="template", cascade="all, delete-orphan")
    assignments = relationship("ExamAssignment", back_populates="template")


# Vazební tabulka M:N s dodatečnými sloupci (Association Object)
class TestTemplateQuestion(Base):
    __tablename__ = "test_templates_questions"

    template_id = Column(Integer, ForeignKey("test_templates.template_id"), primary_key=True)
    question_id = Column(Integer, ForeignKey("questions.question_id"), primary_key=True)
    position = Column(Integer, nullable=False)
    points_custom = Column(Integer, nullable=True)

    # Vztahy
    template = relationship("TestTemplate", back_populates="question_associations")
    question = relationship("Question", back_populates="template_associations")


class ExamAssignment(Base):
    __tablename__ = "exam_assignments"

    assignment_id = Column(Integer, primary_key=True, index=True)
    template_id = Column(Integer, ForeignKey("test_templates.template_id"))
    group_id = Column(Integer, ForeignKey("groups.group_id"))
    activate_from = Column(DateTime(timezone=True))
    activate_to = Column(DateTime(timezone=True))
    time_limit_minutes = Column(Integer)
    access_password = Column(String)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Vztahy
    template = relationship("TestTemplate", back_populates="assignments")
    group = relationship("Group", back_populates="assignments")
    attempts = relationship("StudentAttempt", back_populates="assignment")


class StudentAttempt(Base):
    __tablename__ = "student_attempts"

    attempt_id = Column(Integer, primary_key=True, index=True)
    assignment_id = Column(Integer, ForeignKey("exam_assignments.assignment_id"))
    student_id = Column(Integer, ForeignKey("students.student_id"))
    
    started_at = Column(DateTime(timezone=True), server_default=func.now())
    finished_at = Column(DateTime(timezone=True))
    
    # JSONB sloupce pro snapshoty
    questions_snapshot = Column(JSONB, nullable=False)
    student_answers = Column(JSONB, default={})
    
    total_points = Column(DECIMAL(5, 2))
    max_points = Column(DECIMAL(5, 2))
    score_percent = Column(DECIMAL(5, 2))
    
    status = Column(Enum(AttemptStatus), default=AttemptStatus.STARTED)
    teacher_note = Column(Text)

    # Vztahy
    assignment = relationship("ExamAssignment", back_populates="attempts")
    student = relationship("Student", back_populates="attempts")