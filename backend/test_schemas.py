"""
Test script for Question/Answer Pydantic schemas validation
Tests all 4 question types without database connection
"""
import sys
sys.path.insert(0, '/c:/Users/heger/Skola/BP-Jirotka-Heger/backend')

from schemas import QuestionCreateRequest, AnswerCreateRequest
from pydantic import ValidationError

print("=" * 70)
print("Test: Pydantic Schema Validation for Questions")
print("=" * 70)

test_count = 0
passed_count = 0

def test(name, should_pass=True):
    def decorator(func):
        def wrapper():
            global test_count, passed_count
            test_count += 1
            print(f"\n[Test {test_count}] {name}")
            try:
                result = func()
                if should_pass:
                    print(f"  [OK] PASS: Successfully created {result.type} question")
                    passed_count += 1
                else:
                    print(f"  [FAIL] FAIL: Should have raised ValidationError")
            except ValidationError as e:
                if not should_pass:
                    print(f"  [OK] PASS: Correctly caught validation error")
                    print(f"    Error: {str(e.errors()[0]['msg'])}")
                    passed_count += 1
                else:
                    print(f"  [FAIL] FAIL: Unexpected ValidationError")
                    print(f"    Error: {str(e)}")
            except Exception as e:
                print(f"  [FAIL] FAIL: Unexpected error: {str(e)}")
        return wrapper
    return decorator

# Test 1: SINGLE_CHOICE with one correct answer (should pass)
@test("SINGLE_CHOICE with correct answer", should_pass=True)
def test_single_choice_valid():
    return QuestionCreateRequest(
        text="What is 2 + 2?",
        type="SINGLE_CHOICE",
        tags=["math"],
        answers=[
            AnswerCreateRequest(text="3", is_correct=False),
            AnswerCreateRequest(text="4", is_correct=True),
            AnswerCreateRequest(text="5", is_correct=False)
        ]
    )
test_single_choice_valid()

# Test 2: SINGLE_CHOICE without correct answer (should fail)
@test("SINGLE_CHOICE without correct answer", should_pass=False)
def test_single_choice_no_correct():
    return QuestionCreateRequest(
        text="Invalid question",
        type="SINGLE_CHOICE",
        answers=[
            AnswerCreateRequest(text="Wrong1", is_correct=False),
            AnswerCreateRequest(text="Wrong2", is_correct=False)
        ]
    )
test_single_choice_no_correct()

# Test 3: SINGLE_CHOICE with no answers (should fail)
@test("SINGLE_CHOICE with no answers", should_pass=False)
def test_single_choice_no_answers():
    return QuestionCreateRequest(
        text="Invalid question",
        type="SINGLE_CHOICE",
        answers=[]
    )
test_single_choice_no_answers()

# Test 4: MULTI_CHOICE with multiple correct answers (should pass)
@test("MULTI_CHOICE with multiple correct answers", should_pass=True)
def test_multi_choice_valid():
    return QuestionCreateRequest(
        text="Which are prime numbers?",
        type="MULTI_CHOICE",
        tags=["math", "primes"],
        default_points=2,
        answers=[
            AnswerCreateRequest(text="2", is_correct=True),
            AnswerCreateRequest(text="3", is_correct=True),
            AnswerCreateRequest(text="4", is_correct=False),
            AnswerCreateRequest(text="5", is_correct=True)
        ]
    )
test_multi_choice_valid()

# Test 5: MULTI_CHOICE without correct answer (should fail)
@test("MULTI_CHOICE without correct answer", should_pass=False)
def test_multi_choice_no_correct():
    return QuestionCreateRequest(
        text="Invalid question",
        type="MULTI_CHOICE",
        answers=[
            AnswerCreateRequest(text="Wrong1", is_correct=False),
            AnswerCreateRequest(text="Wrong2", is_correct=False)
        ]
    )
test_multi_choice_no_correct()

# Test 6: OPEN_TEXT without answers (should pass)
@test("OPEN_TEXT without answers", should_pass=True)
def test_open_text_no_answers():
    return QuestionCreateRequest(
        text="Describe the water cycle",
        type="OPEN_TEXT",
        tags=["science"],
        default_points=5,
        answers=[]
    )
test_open_text_no_answers()

# Test 7: OPEN_TEXT with hints (should pass)
@test("OPEN_TEXT with hints", should_pass=True)
def test_open_text_with_hints():
    return QuestionCreateRequest(
        text="List capitals",
        type="OPEN_TEXT",
        answers=[
            AnswerCreateRequest(text="Paris"),
            AnswerCreateRequest(text="Berlin")
        ]
    )
test_open_text_with_hints()

# Test 8: ORDERING with order_index (should pass)
@test("ORDERING with order_index", should_pass=True)
def test_ordering_valid():
    return QuestionCreateRequest(
        text="Order from smallest to largest",
        type="ORDERING",
        tags=["math"],
        answers=[
            AnswerCreateRequest(text="1", order_index=1, is_correct=True),
            AnswerCreateRequest(text="5", order_index=2, is_correct=True),
            AnswerCreateRequest(text="10", order_index=3, is_correct=True)
        ]
    )
test_ordering_valid()

# Test 9: ORDERING without order_index (should fail)
@test("ORDERING without order_index", should_pass=False)
def test_ordering_no_order_index():
    return QuestionCreateRequest(
        text="Order items",
        type="ORDERING",
        answers=[
            AnswerCreateRequest(text="A", is_correct=True),
            AnswerCreateRequest(text="B", is_correct=True)
        ]
    )
test_ordering_no_order_index()

# Test 10: ORDERING with duplicate order_index (should fail)
@test("ORDERING with duplicate order_index", should_pass=False)
def test_ordering_duplicate_order_index():
    return QuestionCreateRequest(
        text="Order items",
        type="ORDERING",
        answers=[
            AnswerCreateRequest(text="A", order_index=1, is_correct=True),
            AnswerCreateRequest(text="B", order_index=1, is_correct=True)
        ]
    )
test_ordering_duplicate_order_index()

# Test 11: Invalid question type (should fail)
@test("Invalid question type", should_pass=False)
def test_invalid_type():
    return QuestionCreateRequest(
        text="Question",
        type="INVALID_TYPE",
        answers=[AnswerCreateRequest(text="A", is_correct=True)]
    )
test_invalid_type()

# Test 12: Invalid default_points (should fail)
@test("Invalid default_points (0 points)", should_pass=False)
def test_invalid_points():
    return QuestionCreateRequest(
        text="Question",
        type="SINGLE_CHOICE",
        default_points=0,
        answers=[AnswerCreateRequest(text="A", is_correct=True)]
    )
test_invalid_points()

# Test 13: Valid question with tags and image_url
@test("Complete MULTI_CHOICE with all fields", should_pass=True)
def test_complete_question():
    return QuestionCreateRequest(
        text="Full example",
        type="MULTI_CHOICE",
        tags=["tag1", "tag2", "tag3"],
        image_url="https://example.com/image.jpg",
        default_points=3,
        answers=[
            AnswerCreateRequest(text="Option 1", is_correct=True),
            AnswerCreateRequest(text="Option 2", is_correct=False),
            AnswerCreateRequest(text="Option 3", is_correct=True)
        ]
    )
test_complete_question()

# Test 14: Question without answers (defaults to empty list)
@test("SINGLE_CHOICE created with default empty answers", should_pass=False)
def test_answers_default():
    return QuestionCreateRequest(
        text="Question without answers field",
        type="SINGLE_CHOICE"
    )
test_answers_default()

# Test 15: Valid MATCHING with ||| pairs
@test("MATCHING with delimiter ||| pairs", should_pass=True)
def test_matching_valid_delimiter():
    return QuestionCreateRequest(
        text="Přiřaďte pojmy k definicím",
        type="MATCHING",
        answers=[
            AnswerCreateRequest(text="Rychlost|||v", is_correct=True),
            AnswerCreateRequest(text="Hmotnost|||m", is_correct=True)
        ]
    )
test_matching_valid_delimiter()

# Test 16: Valid MATCHING with match_text field
@test("MATCHING with match_text field", should_pass=True)
def test_matching_valid_match_text():
    return QuestionCreateRequest(
        text="Přiřaďte pojmy k definicím",
        type="MATCHING",
        answers=[
            AnswerCreateRequest(text="Rychlost", match_text="v", is_correct=True),
            AnswerCreateRequest(text="Hmotnost", match_text="m", is_correct=True)
        ]
    )
test_matching_valid_match_text()

# Test 17: MATCHING with less than 2 pairs (should fail)
@test("MATCHING with only 1 pair (should fail)", should_pass=False)
def test_matching_invalid_count():
    return QuestionCreateRequest(
        text="Přiřaďte",
        type="MATCHING",
        answers=[
            AnswerCreateRequest(text="Rychlost|||v", is_correct=True)
        ]
    )
test_matching_invalid_count()

# Test 18: Valid SHORT_ANSWER
@test("SHORT_ANSWER with correct variant", should_pass=True)
def test_short_answer_valid():
    return QuestionCreateRequest(
        text="Jaké je hlavní město ČR?",
        type="SHORT_ANSWER",
        answers=[
            AnswerCreateRequest(text="Praha", is_correct=True),
            AnswerCreateRequest(text="Prague", is_correct=True)
        ]
    )
test_short_answer_valid()

# Test 19: SHORT_ANSWER with no answers (should fail)
@test("SHORT_ANSWER without answers (should fail)", should_pass=False)
def test_short_answer_invalid():
    return QuestionCreateRequest(
        text="Jaké je hlavní město?",
        type="SHORT_ANSWER",
        answers=[]
    )
test_short_answer_invalid()

# Summary
print("\n" + "=" * 70)
print(f"Test Results: {passed_count}/{test_count} tests passed")
print("=" * 70)

if passed_count == test_count:
    print("[OK] All validation tests passed!")
else:
    print(f"[FAIL] {test_count - passed_count} test(s) failed")

