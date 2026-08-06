"""
Integration test suite verifying all 3 requirements from backend_requirements (3).md:
1. awardedPoints stored in questions_snapshot in auto_grade
2. student_name added to attempt detail endpoints
3. SSE attempt_submitted event sent upon test submission
"""
import sys
import os
import json
import time
import threading
import urllib.request
import urllib.error

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from database import SessionLocal
import db_layer
from models import Teacher, Student, Group, Bank, Question, Answer, TestTemplate, ExamAssignment, StudentAttempt, AttemptStatus, QuestionType
from auth import create_access_token

BASE_URL = "http://127.0.0.1:8000"

def api_request(method, path, data=None, headers=None):
    url = f"{BASE_URL}{path}"
    req_headers = {"Content-Type": "application/json"}
    if headers:
        req_headers.update(headers)
    
    body = json.dumps(data).encode("utf-8") if data is not None else None
    req = urllib.request.Request(url, data=body, headers=req_headers, method=method)
    try:
        with urllib.request.urlopen(req) as response:
            res_body = response.read().decode("utf-8")
            return response.status, json.loads(res_body) if res_body else {}
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8")
        try:
            err_json = json.loads(err_body)
        except Exception:
            err_json = {"detail": err_body}
        return e.code, err_json

def run_tests():
    db = SessionLocal()
    print("=" * 70)
    print("INTEGRATION TESTS: BACKEND REQUIREMENTS (3).MD")
    print("=" * 70)
    
    try:
        # 1. Setup Test Teacher
        teacher_email = "teacher_req3@example.com"
        db_teacher = db.query(Teacher).filter(Teacher.email == teacher_email).first()
        if not db_teacher:
            db_teacher = db_layer.create_teacher(db, "Prof. Requirements", teacher_email, "pass123")
        
        teacher_token = create_access_token({"sub": str(db_teacher.teacher_id), "type": "teacher"})
        teacher_headers = {"Authorization": f"Bearer {teacher_token}"}
        
        # 2. Setup Test Student
        student_email = "student_req3@example.com"
        student_code = "stud_req3_01"
        db_student = db.query(Student).filter(Student.login_code == student_code).first()
        if not db_student:
            db_student = db_layer.create_student(db, student_email, student_code, "pass123")
        
        student_token = create_access_token({"sub": str(db_student.student_id), "type": "student"})
        student_headers = {"Authorization": f"Bearer {student_token}"}

        # 3. Setup Group & Bank
        group = db.query(Group).filter(Group.teacher_id == db_teacher.teacher_id, Group.name == "Req3Group").first()
        if not group:
            group = db_layer.create_group(db, db_teacher.teacher_id, "Req3Group", "Group for req3 testing")
        if db_student not in group.students:
            group.students.append(db_student)
        db.commit()

        bank = db.query(Bank).filter(Bank.teacher_id == db_teacher.teacher_id, Bank.name == "Req3Bank").first()
        if not bank:
            bank = db_layer.create_bank(db, db_teacher.teacher_id, "Req3Bank", "Bank for req3 testing", False)

        # 4. Create Questions for all types
        # Q1: SINGLE_CHOICE (1 pt)
        status, q1_res = api_request("POST", f"/banks/{bank.bank_id}/questions", {
            "text": "Jaké je hlavní město Francie?",
            "type": "SINGLE_CHOICE",
            "default_points": 1,
            "answers": [
                {"text": "Paříž", "is_correct": True},
                {"text": "Londýn", "is_correct": False}
            ]
        }, headers=teacher_headers)
        assert status == 200, f"Q1 creation failed: {q1_res}"
        q1_data = q1_res["question"]
        q1_id = q1_data["question_id"]
        q1_correct_ans = [a["answer_id"] for a in q1_data["answers"] if a["is_correct"]][0]

        # Q2: MULTI_CHOICE (2 pts)
        status, q2_res = api_request("POST", f"/banks/{bank.bank_id}/questions", {
            "text": "Vyberte prvočísla:",
            "type": "MULTI_CHOICE",
            "default_points": 2,
            "answers": [
                {"text": "2", "is_correct": True},
                {"text": "3", "is_correct": True},
                {"text": "4", "is_correct": False}
            ]
        }, headers=teacher_headers)
        assert status == 200, f"Q2 creation failed: {q2_res}"
        q2_data = q2_res["question"]
        q2_id = q2_data["question_id"]
        q2_correct_ans = [a["answer_id"] for a in q2_data["answers"] if a["is_correct"]]

        # Q3: SHORT_ANSWER (1 pt)
        status, q3_res = api_request("POST", f"/banks/{bank.bank_id}/questions", {
            "text": "Napište chemickou značku vody:",
            "type": "SHORT_ANSWER",
            "default_points": 1,
            "answers": [
                {"text": "H2O", "is_correct": True}
            ]
        }, headers=teacher_headers)
        assert status == 200, f"Q3 creation failed: {q3_res}"
        q3_id = q3_res["question"]["question_id"]

        # Q4: OPEN_TEXT (5 pts)
        status, q4_res = api_request("POST", f"/banks/{bank.bank_id}/questions", {
            "text": "Vysvětlete fotosyntézu.",
            "type": "OPEN_TEXT",
            "default_points": 5,
            "answers": []
        }, headers=teacher_headers)
        assert status == 200, f"Q4 creation failed: {q4_res}"
        q4_id = q4_res["question"]["question_id"]

        # 5. Create Template & Assignment
        status, tmpl_res = api_request("POST", "/test-templates", {
            "name": "Req3 Test Template",
            "description": "Template for testing requirements 3",
            "difficulty": "EASY",
            "estimated_duration_minutes": 30,
            "questions": [
                {"question_id": q1_id, "position": 1, "points_custom": 1},
                {"question_id": q2_id, "position": 2, "points_custom": 2},
                {"question_id": q3_id, "position": 3, "points_custom": 1},
                {"question_id": q4_id, "position": 4, "points_custom": 5}
            ]
        }, headers=teacher_headers)
        assert status == 200, f"Template creation failed: {tmpl_res}"
        template_id = tmpl_res["template_id"]

        status, assign_res = api_request("POST", f"/groups/{group.group_id}/exam-assignments", {
            "template_id": template_id,
            "time_limit_minutes": 30,
            "show_immediate_feedback": True
        }, headers=teacher_headers)
        assert status == 200, f"Assignment creation failed: {assign_res}"
        assignment_id = assign_res["assignment"]["assignment_id"]

        # Activate assignment
        status, act_res = api_request("POST", f"/exam-assignments/{assignment_id}/activate", headers=teacher_headers)
        assert status == 200, f"Activation failed: {act_res}"

        # 6. Student Starts Attempt
        status, start_res = api_request("POST", f"/api/student/assignments/{assignment_id}/start", headers=student_headers)
        assert status == 200, f"Start attempt failed: {start_res}"
        attempt_id = start_res["attempt_id"]

        # 7. Start SSE Listener for Teacher Assignment Progress
        received_sse_events = []
        sse_stop = threading.Event()

        def sse_listener():
            url = f"{BASE_URL}/api/sse/teacher/assignments/{assignment_id}/progress"
            req = urllib.request.Request(url, headers={"Authorization": f"Bearer {teacher_token}"})
            try:
                with urllib.request.urlopen(req, timeout=5) as resp:
                    for line in resp:
                        if sse_stop.is_set():
                            break
                        decoded = line.decode("utf-8").strip()
                        if decoded.startswith("data:"):
                            raw_data = decoded[5:].strip()
                            try:
                                parsed = json.loads(raw_data)
                                received_sse_events.append(parsed)
                            except Exception:
                                pass
            except Exception:
                pass

        listener_thread = threading.Thread(target=sse_listener, daemon=True)
        listener_thread.start()
        time.sleep(0.5)  # Wait for SSE connection to establish

        # 8. Student Submits Answers
        # Answer Q1 correctly (1 pt), Q2 correctly (2 pts), Q3 wrongly (0 pts), Q4 open text
        student_answers = {
            str(q1_id): q1_correct_ans,
            str(q2_id): q2_correct_ans,
            str(q3_id): "spatna_odpoved",
            str(q4_id): "Fotosyntéza je proces..."
        }

        status, submit_res = api_request("POST", f"/api/student/attempts/{attempt_id}/submit", {
            "answers": student_answers
        }, headers=student_headers)
        assert status == 200, f"Submit attempt failed: {submit_res}"
        print(f"  [OK] Submitted attempt {attempt_id}, total_points: {submit_res['total_points']}")

        # -------------------------------------------------------------
        # Requirement 1: Verify awardedPoints in questions_snapshot
        # -------------------------------------------------------------
        print("\n[REQ 1] Verifying awardedPoints in questions_snapshot...")
        db.expire_all()
        attempt_db = db.query(StudentAttempt).filter(StudentAttempt.attempt_id == attempt_id).first()
        snapshot = attempt_db.questions_snapshot
        
        q1_snap = next(q for q in snapshot if q["question_id"] == q1_id)
        q2_snap = next(q for q in snapshot if q["question_id"] == q2_id)
        q3_snap = next(q for q in snapshot if q["question_id"] == q3_id)
        q4_snap = next(q for q in snapshot if q["question_id"] == q4_id)

        assert "awardedPoints" in q1_snap, "Q1 snapshot missing awardedPoints"
        assert q1_snap["awardedPoints"] == 1, f"Expected Q1 awardedPoints == 1, got {q1_snap['awardedPoints']}"
        print("  [OK] Q1 (SINGLE_CHOICE - correct): awardedPoints = 1")

        assert "awardedPoints" in q2_snap, "Q2 snapshot missing awardedPoints"
        assert q2_snap["awardedPoints"] == 2, f"Expected Q2 awardedPoints == 2, got {q2_snap['awardedPoints']}"
        print("  [OK] Q2 (MULTI_CHOICE - correct): awardedPoints = 2")

        assert "awardedPoints" in q3_snap, "Q3 snapshot missing awardedPoints"
        assert q3_snap["awardedPoints"] == 0, f"Expected Q3 awardedPoints == 0, got {q3_snap['awardedPoints']}"
        print("  [OK] Q3 (SHORT_ANSWER - incorrect): awardedPoints = 0")

        assert "awardedPoints" in q4_snap, "Q4 snapshot missing awardedPoints"
        assert q4_snap["awardedPoints"] == 0, f"Expected Q4 awardedPoints == 0, got {q4_snap['awardedPoints']}"
        print("  [OK] Q4 (OPEN_TEXT - pending): awardedPoints = 0")

        # -------------------------------------------------------------
        # Requirement 2: Verify student_name in attempt detail endpoints
        # -------------------------------------------------------------
        print("\n[REQ 2] Verifying student_name in teacher & student attempt detail endpoints...")
        
        # Teacher endpoint
        status, t_detail_res = api_request("GET", f"/exam-assignments/{assignment_id}/attempts/{attempt_id}", headers=teacher_headers)
        assert status == 200, f"Teacher get attempt detail failed: {t_detail_res}"
        assert "student_name" in t_detail_res, "Teacher detail response missing student_name"
        assert t_detail_res["student_name"] == student_email, f"Expected student_name '{student_email}', got '{t_detail_res.get('student_name')}'"
        print(f"  [OK] Teacher endpoint returns student_name: '{t_detail_res['student_name']}'")

        # Student endpoint
        status, s_detail_res = api_request("GET", f"/api/student/attempts/{attempt_id}", headers=student_headers)
        assert status == 200, f"Student get attempt detail failed: {s_detail_res}"
        assert "student_name" in s_detail_res, "Student detail response missing student_name"
        assert s_detail_res["student_name"] == student_email, f"Expected student_name '{student_email}', got '{s_detail_res.get('student_name')}'"
        print(f"  [OK] Student endpoint returns student_name: '{s_detail_res['student_name']}'")

        # -------------------------------------------------------------
        # Requirement 3: Verify SSE event attempt_submitted
        # -------------------------------------------------------------
        print("\n[REQ 3] Verifying SSE attempt_submitted broadcast event...")
        time.sleep(1.0)
        sse_stop.set()
        
        submitted_event = next((e for e in received_sse_events if e.get("event") == "attempt_submitted"), None)
        assert submitted_event is not None, f"Expected SSE event 'attempt_submitted', received: {received_sse_events}"
        assert submitted_event["attempt_id"] == attempt_id, f"Expected attempt_id {attempt_id}, got {submitted_event.get('attempt_id')}"
        assert submitted_event["student_id"] == db_student.student_id, f"Expected student_id {db_student.student_id}, got {submitted_event.get('student_id')}"
        print(f"  [OK] SSE event received via HTTP stream: {submitted_event}")

        print("\n" + "=" * 70)
        print("ALL TESTS IN test_requirements_3.py PASSED SUCCESSFULLY!")
        print("=" * 70)

    finally:
        db.close()

if __name__ == "__main__":
    run_tests()
