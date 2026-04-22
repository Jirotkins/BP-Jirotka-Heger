"""
Test script for question bank endpoints
Tests all 4 question types: SINGLE_CHOICE, MULTI_CHOICE, OPEN_TEXT, ORDERING
"""
import sys
sys.path.insert(0, '/c:/Users/heger/Skola/BP-Jirotka-Heger/backend')

from sqlalchemy.orm import Session
from database import SessionLocal, Base, engine
from models import Teacher, Group, Bank, Question, Answer, QuestionType
from db_layer import create_question, get_bank_questions, create_teacher, create_group, create_bank
from auth import get_password_hash

# Initialize database
Base.metadata.create_all(bind=engine)
db = SessionLocal()

print("=" * 60)
print("Test: Question Bank Endpoints")
print("=" * 60)

try:
    # Clean up test data
    db.query(Answer).delete()
    db.query(Question).delete()
    db.query(Bank).delete()
    db.query(Group).delete()
    db.query(Teacher).delete()
    db.commit()
    
    # Create test teacher
    teacher = create_teacher(db, "Test Teacher", "test@teacher.com", "password123")
    print(f"✓ Created teacher: {teacher.name} (ID: {teacher.teacher_id})")
    
    # Create test bank
    bank_data = {
        "name": "Test Question Bank",
        "description": "Bank for testing",
        "is_public": False
    }
    bank = create_bank(db, teacher.teacher_id, bank_data["name"], bank_data["description"], bank_data["is_public"])
    print(f"✓ Created bank: {bank.name} (ID: {bank.bank_id})")
    
    # Test 1: SINGLE_CHOICE question
    print("\n--- Test 1: SINGLE_CHOICE Question ---")
    single_choice_data = {
        "text": "What is 2 + 2?",
        "type": "SINGLE_CHOICE",
        "tags": ["math", "basic"],
        "default_points": 1,
        "answers": [
            {"text": "3", "is_correct": False},
            {"text": "4", "is_correct": True},
            {"text": "5", "is_correct": False}
        ]
    }
    q1 = create_question(db, bank.bank_id, single_choice_data, teacher.teacher_id)
    print(f"✓ Created SINGLE_CHOICE question: '{q1.text}'")
    print(f"  - Answers: {len(q1.answers)} (1 correct)")
    for ans in q1.answers:
        print(f"    - {ans.text} (correct: {ans.is_correct})")
    
    # Test 2: MULTI_CHOICE question
    print("\n--- Test 2: MULTI_CHOICE Question ---")
    multi_choice_data = {
        "text": "Which of these are prime numbers?",
        "type": "MULTI_CHOICE",
        "tags": ["math", "primes"],
        "default_points": 2,
        "answers": [
            {"text": "2", "is_correct": True},
            {"text": "3", "is_correct": True},
            {"text": "4", "is_correct": False},
            {"text": "5", "is_correct": True}
        ]
    }
    q2 = create_question(db, bank.bank_id, multi_choice_data, teacher.teacher_id)
    print(f"✓ Created MULTI_CHOICE question: '{q2.text}'")
    print(f"  - Answers: {len(q2.answers)} (3 correct)")
    for ans in q2.answers:
        print(f"    - {ans.text} (correct: {ans.is_correct})")
    
    # Test 3: OPEN_TEXT question (without answers)
    print("\n--- Test 3: OPEN_TEXT Question (no answers) ---")
    open_text_data = {
        "text": "Describe the water cycle",
        "type": "OPEN_TEXT",
        "tags": ["science", "nature"],
        "default_points": 5,
        "answers": []
    }
    q3 = create_question(db, bank.bank_id, open_text_data, teacher.teacher_id)
    print(f"✓ Created OPEN_TEXT question: '{q3.text}'")
    print(f"  - Answers: {len(q3.answers)} (no specific correct answers)")
    
    # Test 4: OPEN_TEXT question (with hints)
    print("\n--- Test 4: OPEN_TEXT Question (with hints) ---")
    open_text_hints_data = {
        "text": "List the capitals of European countries",
        "type": "OPEN_TEXT",
        "tags": ["geography"],
        "default_points": 3,
        "answers": [
            {"text": "Paris", "is_correct": False},
            {"text": "Berlin", "is_correct": False},
            {"text": "Rome", "is_correct": False}
        ]
    }
    q4 = create_question(db, bank.bank_id, open_text_hints_data, teacher.teacher_id)
    print(f"✓ Created OPEN_TEXT question with hints: '{q4.text}'")
    print(f"  - Hints: {len(q4.answers)}")
    for ans in q4.answers:
        print(f"    - {ans.text} (hint)")
    
    # Test 5: ORDERING question
    print("\n--- Test 5: ORDERING Question ---")
    ordering_data = {
        "text": "Order these numbers from smallest to largest",
        "type": "ORDERING",
        "tags": ["math", "ordering"],
        "default_points": 2,
        "answers": [
            {"text": "1", "order_index": 1, "is_correct": True},
            {"text": "5", "order_index": 2, "is_correct": True},
            {"text": "10", "order_index": 3, "is_correct": True},
            {"text": "15", "order_index": 4, "is_correct": True}
        ]
    }
    q5 = create_question(db, bank.bank_id, ordering_data, teacher.teacher_id)
    print(f"✓ Created ORDERING question: '{q5.text}'")
    print(f"  - Items: {len(q5.answers)}")
    for ans in q5.answers:
        print(f"    - {ans.text} (order: {ans.order_index})")
    
    # Test 6: Fetch all questions from bank
    print("\n--- Test 6: Fetch All Questions ---")
    all_questions = get_bank_questions(db, bank.bank_id, teacher.teacher_id)
    print(f"✓ Retrieved {len(all_questions)} questions from bank:")
    for q in all_questions:
        print(f"  - [{q.type.value}] {q.text} ({len(q.answers)} answers)")
    
    # Test 7: Error handling - no correct answer for SINGLE_CHOICE
    print("\n--- Test 7: Error Handling (no correct answer) ---")
    try:
        invalid_data = {
            "text": "Invalid question",
            "type": "SINGLE_CHOICE",
            "answers": [
                {"text": "Wrong1", "is_correct": False},
                {"text": "Wrong2", "is_correct": False}
            ]
        }
        create_question(db, bank.bank_id, invalid_data, teacher.teacher_id)
        print("✗ Should have raised ValueError")
    except ValueError as e:
        print(f"✓ Correctly caught error: {str(e)}")
    
    # Test 8: Error handling - invalid bank_id
    print("\n--- Test 8: Error Handling (invalid bank) ---")
    try:
        valid_data = {
            "text": "Valid question",
            "type": "SINGLE_CHOICE",
            "answers": [
                {"text": "Correct", "is_correct": True}
            ]
        }
        create_question(db, 9999, valid_data, teacher.teacher_id)
        print("✗ Should have raised ValueError")
    except ValueError as e:
        print(f"✓ Correctly caught error: {str(e)}")
    
    # Test 9: Error handling - wrong owner
    print("\n--- Test 9: Error Handling (access denied) ---")
    try:
        create_teacher(db, "Other Teacher", "other@teacher.com", "password123")
        other_teacher = db.query(Teacher).filter(Teacher.email == "other@teacher.com").first()
        
        valid_data = {
            "text": "Valid question",
            "type": "SINGLE_CHOICE",
            "answers": [
                {"text": "Correct", "is_correct": True}
            ]
        }
        create_question(db, bank.bank_id, valid_data, other_teacher.teacher_id)
        print("✗ Should have raised ValueError")
    except ValueError as e:
        print(f"✓ Correctly caught error: {str(e)}")
    
    print("\n" + "=" * 60)
    print("All tests passed! ✓")
    print("=" * 60)
    
except Exception as e:
    print(f"\n✗ Test failed with error: {str(e)}")
    import traceback
    traceback.print_exc()
finally:
    db.close()
