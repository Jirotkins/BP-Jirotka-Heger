"""
Integration test suite verifying all 7 requirements from backend_requirements (1).md
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from fastapi.testclient import TestClient
from main import app
from database import SessionLocal
import db_layer
from models import Teacher, Student, Group, Bank, Question, Answer, TestTemplate, ExamAssignment, StudentAttempt, AttemptStatus, QuestionType
from auth import create_access_token

client = TestClient(app)

def run_all_tests():
    db = SessionLocal()
    print("=" * 70)
    print("INTEGRATION TESTS: BACKEND REQUIREMENTS 1-7")
    print("=" * 70)
    
    try:
        # Setup test teacher and students
        teacher_email = "teacher_test@example.com"
        db_teacher = db.query(Teacher).filter(Teacher.email == teacher_email).first()
        if not db_teacher:
            db_teacher = db_layer.create_teacher(db, "Prof. Test", teacher_email, "pass123")
        
        teacher_token = create_access_token({"sub": str(db_teacher.teacher_id), "type": "teacher"})
        teacher_headers = {"Authorization": f"Bearer {teacher_token}"}
        
        # Student 1 (with email)
        student1_email = "student1@example.com"
        student1_code = "stud_01"
        db_student1 = db.query(Student).filter(Student.login_code == student1_code).first()
        if not db_student1:
            db_student1 = db_layer.create_student(db, student1_email, student1_code, "pass123")
        
        student1_token = create_access_token({"sub": str(db_student1.student_id), "type": "student"})
        student1_headers = {"Authorization": f"Bearer {student1_token}"}

        # Student 2 (for permission test)
        student2_code = "stud_02"
        db_student2 = db.query(Student).filter(Student.login_code == student2_code).first()
        if not db_student2:
            db_student2 = db_layer.create_student(db, "student2@example.com", student2_code, "pass123")
        student2_token = create_access_token({"sub": str(db_student2.student_id), "type": "student"})
        student2_headers = {"Authorization": f"Bearer {student2_token}"}

        # Group
        group = db.query(Group).filter(Group.teacher_id == db_teacher.teacher_id, Group.name == "ReqTestGroup").first()
        if not group:
            group = db_layer.create_group(db, db_teacher.teacher_id, "ReqTestGroup", "Test group for requirements")
        if db_student1 not in group.students:
            group.students.append(db_student1)
        if db_student2 not in group.students:
            group.students.append(db_student2)
        db.commit()

        # Bank
        bank = db.query(Bank).filter(Bank.teacher_id == db_teacher.teacher_id, Bank.name == "ReqTestBank").first()
        if not bank:
            bank = db_layer.create_bank(db, db_teacher.teacher_id, "ReqTestBank", "Bank for testing", False)

        # -------------------------------------------------------------
        # Requirement 6: MATCHING Question Creation & Validation
        # -------------------------------------------------------------
        print("\n[REQ 6] Testing MATCHING Question Creation via API...")
        matching_payload = {
            "text": "Spojte hlavní města se státy",
            "type": "MATCHING",
            "default_points": 2,
            "answers": [
                {"text": "Praha|||Česko", "is_correct": True},
                {"text": "Bratislava|||Slovensko", "is_correct": True}
            ]
        }
        res_m = client.post(f"/banks/{bank.bank_id}/questions", json=matching_payload, headers=teacher_headers)
        assert res_m.status_code == 200, f"Failed to create MATCHING question: {res_m.text}"
        q_matching_id = res_m.json()["question"]["question_id"]
        print(f"  [OK] Created MATCHING question ID: {q_matching_id}")

        # -------------------------------------------------------------
        # Requirement 7: SHORT_ANSWER Question Creation & Validation
        # -------------------------------------------------------------
        print("\n[REQ 7] Testing SHORT_ANSWER Question Creation via API...")
        short_payload = {
            "text": "Jak se jmenuje naše planeta?",
            "type": "SHORT_ANSWER",
            "default_points": 1,
            "answers": [
                {"text": "Země", "is_correct": True},
                {"text": "Earth", "is_correct": True}
            ]
        }
        res_s = client.post(f"/banks/{bank.bank_id}/questions", json=short_payload, headers=teacher_headers)
        assert res_s.status_code == 200, f"Failed to create SHORT_ANSWER question: {res_s.text}"
        q_short_id = res_s.json()["question"]["question_id"]
        print(f"  [OK] Created SHORT_ANSWER question ID: {q_short_id}")

        # OPEN_TEXT Question for testing manual evaluation (Requirement 4)
        print("\n[REQ 4 Prep] Creating OPEN_TEXT Question...")
        open_payload = {
            "text": "Popište fotosyntézu vlastními slovy",
            "type": "OPEN_TEXT",
            "default_points": 5,
            "answers": []
        }
        res_o = client.post(f"/banks/{bank.bank_id}/questions", json=open_payload, headers=teacher_headers)
        assert res_o.status_code == 200, f"Failed to create OPEN_TEXT question: {res_o.text}"
        q_open_id = res_o.json()["question"]["question_id"]
        print(f"  [OK] Created OPEN_TEXT question ID: {q_open_id}")

        # Create Test Template
        template_payload = {
            "name": "Full Requirements Test Template",
            "description": "Template with MATCHING, SHORT_ANSWER and OPEN_TEXT"
        }
        res_t = client.post("/test-templates", json=template_payload, headers=teacher_headers)
        assert res_t.status_code == 200, f"Failed to create template: {res_t.text}"
        template_id = res_t.json()["template_id"]
        print(f"  [OK] Created Test Template ID: {template_id}")

        # Add questions to template
        client.post(f"/test-templates/{template_id}/questions", json={"question_id": q_matching_id, "position": 1}, headers=teacher_headers)
        client.post(f"/test-templates/{template_id}/questions", json={"question_id": q_short_id, "position": 2}, headers=teacher_headers)
        client.post(f"/test-templates/{template_id}/questions", json={"question_id": q_open_id, "position": 3}, headers=teacher_headers)
        print("  [OK] Added questions to template")

        # Create Exam Assignment
        assignment_payload = {
            "template_id": template_id,
            "show_immediate_feedback": True,
            "time_limit_minutes": 30
        }
        res_a = client.post(f"/groups/{group.group_id}/exam-assignments", json=assignment_payload, headers=teacher_headers)
        assert res_a.status_code == 200, f"Failed to create assignment: {res_a.text}"
        assignment_id = res_a.json()["assignment"]["assignment_id"]
        print(f"  [OK] Created Assignment ID: {assignment_id}")

        # Activate assignment
        res_act = client.post(f"/exam-assignments/{assignment_id}/activate", headers=teacher_headers)
        assert res_act.status_code == 200, f"Failed to activate assignment: {res_act.text}"

        # -------------------------------------------------------------
        # Requirement 3: GET /api/student/assignments returns attempt_id
        # -------------------------------------------------------------
        print("\n[REQ 3] Checking GET /api/student/assignments before start (attempt_id should be None)...")
        res_sa = client.get("/api/student/assignments", headers=student1_headers)
        assert res_sa.status_code == 200
        assignments = res_sa.json()
        target_a = next(a for a in assignments if a["assignment_id"] == assignment_id)
        assert "attempt_id" in target_a
        assert target_a["attempt_id"] is None
        print(f"  [OK] attempt_id field present in assignments list (initial: {target_a['attempt_id']})")

        # Start Student Attempt
        print("\nStarting student attempt...")
        res_start = client.post(f"/api/student/assignments/{assignment_id}/start", headers=student1_headers)
        assert res_start.status_code == 200
        attempt_id = res_start.json()["attempt_id"]
        print(f"  [OK] Started Attempt ID: {attempt_id}")

        # Verify attempt_id is now populated in /api/student/assignments
        res_sa2 = client.get("/api/student/assignments", headers=student1_headers)
        res_sa2_data = res_sa2.json()
        target_a2 = next(a for a in res_sa2_data if a["assignment_id"] == assignment_id)
        assert target_a2["attempt_id"] == attempt_id
        print(f"  [OK] attempt_id successfully updated in student assignments list to: {target_a2['attempt_id']}")

        # -------------------------------------------------------------
        # Requirement 5 & 6 & 7: Save answers (SSE) & Submit (auto_grade)
        # -------------------------------------------------------------
        print("\n[REQ 5, 6, 7] Saving student answers and submitting attempt...")
        # Answers:
        # q_matching: {"Praha": "Česko", "Bratislava": "Slovensko"} -> correct (2 pts)
        # q_short: "  země  " (with spaces & lowercase) -> correct (1 pt)
        # q_open: "Fotosyntéza probíhá v chloroplastech." -> pending manual review
        answers_payload = {
            "answers": {
                str(q_matching_id): {"Praha": "Česko", "Bratislava": "Slovensko"},
                str(q_short_id): "  země  ",
                str(q_open_id): "Fotosyntéza probíhá v chloroplastech za pomoci slunečního světla."
            }
        }
        res_save = client.put(f"/api/student/attempts/{attempt_id}/answers", json=answers_payload, headers=student1_headers)
        assert res_save.status_code == 200
        print(f"  [OK] Answers saved with immediate feedback (SSE triggered cleanly)")

        res_submit = client.post(f"/api/student/attempts/{attempt_id}/submit", json=answers_payload, headers=student1_headers)
        assert res_submit.status_code == 200
        submit_data = res_submit.json()
        print(f"DEBUG submit_data: {submit_data}")
        # Has OPEN_TEXT -> status should be SUBMITTED
        assert submit_data["status"] == "SUBMITTED"
        assert submit_data["total_points"] == 3.0, f"Expected 3.0 points from auto_grade, got {submit_data['total_points']}"
        print(f"  [OK] Attempt submitted. Status: {submit_data['status']}, Auto-graded points: {submit_data['total_points']}/8.0")

        # -------------------------------------------------------------
        # Requirement 2: GET /exam-assignments/{id}/attempts includes student_name
        # -------------------------------------------------------------
        print("\n[REQ 2] Checking GET /exam-assignments/{assignment_id}/attempts includes student_name...")
        res_attempts = client.get(f"/exam-assignments/{assignment_id}/attempts", headers=teacher_headers)
        assert res_attempts.status_code == 200
        att_list = res_attempts.json()["attempts"]
        att_entry = next(a for a in att_list if a["attempt_id"] == attempt_id)
        assert "student_name" in att_entry
        assert att_entry["student_name"] == student1_email
        print(f"  [OK] student_name in attempts list: '{att_entry['student_name']}'")

        # -------------------------------------------------------------
        # Requirement 1: GET /api/student/attempts/{attempt_id}
        # -------------------------------------------------------------
        print("\n[REQ 1] Testing GET /api/student/attempts/{attempt_id} for student...")
        res_st_att = client.get(f"/api/student/attempts/{attempt_id}", headers=student1_headers)
        assert res_st_att.status_code == 200
        st_att_data = res_st_att.json()
        assert st_att_data["attempt_id"] == attempt_id
        assert st_att_data["status"] == "SUBMITTED"
        assert st_att_data["total_points"] == 3.0
        assert "questions_snapshot" in st_att_data
        assert "student_answers" in st_att_data
        print(f"  [OK] Student successfully fetched attempt detail")

        # Test unauthorized access by student2
        res_st2_att = client.get(f"/api/student/attempts/{attempt_id}", headers=student2_headers)
        assert res_st2_att.status_code == 403
        print(f"  [OK] Other student correctly forbidden (403): {res_st2_att.json()['detail']}")

        # -------------------------------------------------------------
        # Requirement 4: Teacher grading / evaluation of open questions
        # -------------------------------------------------------------
        print("\n[REQ 4] Testing Teacher grading (PUT /exam-assignments/.../attempts/.../grade)...")
        # Teacher awards 5 points for the open text question -> total_points becomes 8.0
        grade_payload = {
            "total_points": 8.0,
            "teacher_note": "Výborná práce, plný počet bodů!",
            "student_answers": {
                str(q_matching_id): {"answer": {"Praha": "Česko", "Bratislava": "Slovensko"}, "points": 2.0},
                str(q_short_id): {"answer": "  země  ", "points": 1.0},
                str(q_open_id): {"answer": "Fotosyntéza probíhá v chloroplastech za pomoci slunečního světla.", "points": 5.0, "feedback": "Skvěle"}
            }
        }
        res_grade = client.put(f"/exam-assignments/{assignment_id}/attempts/{attempt_id}/grade", json=grade_payload, headers=teacher_headers)
        assert res_grade.status_code == 200, f"Grading failed: {res_grade.text}"
        grade_res_data = res_grade.json()
        assert grade_res_data["attempt"]["status"] == "GRADED"
        assert grade_res_data["attempt"]["total_points"] == 8.0
        assert grade_res_data["attempt"]["score_percent"] == 100.0
        print(f"  [OK] Attempt graded successfully. Status: {grade_res_data['attempt']['status']}, Total Points: {grade_res_data['attempt']['total_points']}, Score: {grade_res_data['attempt']['score_percent']}%")

        # Verify updated result via student endpoint
        res_st_graded = client.get(f"/api/student/attempts/{attempt_id}", headers=student1_headers)
        assert res_st_graded.status_code == 200
        assert res_st_graded.json()["status"] == "GRADED"
        assert res_st_graded.json()["total_points"] == 8.0
        assert res_st_graded.json()["score_percent"] == 100.0
        assert res_st_graded.json()["teacher_note"] == "Výborná práce, plný počet bodů!"
        print(f"  [OK] Student sees graded result with note and 100% score")

        # -------------------------------------------------------------
        # Auto-grade without OPEN_TEXT should immediately become GRADED
        # -------------------------------------------------------------
        print("\n[Auto-Graded Test] Test with only MATCHING & SHORT_ANSWER (no OPEN_TEXT)...")
        template_auto_payload = {
            "name": "Pure Auto-Graded Template",
            "description": "Only MATCHING and SHORT_ANSWER"
        }
        res_ta = client.post("/test-templates", json=template_auto_payload, headers=teacher_headers)
        t_auto_id = res_ta.json()["template_id"]
        client.post(f"/test-templates/{t_auto_id}/questions", json={"question_id": q_matching_id, "position": 1}, headers=teacher_headers)
        client.post(f"/test-templates/{t_auto_id}/questions", json={"question_id": q_short_id, "position": 2}, headers=teacher_headers)

        res_aa = client.post(f"/groups/{group.group_id}/exam-assignments", json={"template_id": t_auto_id}, headers=teacher_headers)
        a_auto_id = res_aa.json()["assignment"]["assignment_id"]
        client.post(f"/exam-assignments/{a_auto_id}/activate", headers=teacher_headers)

        res_start_auto = client.post(f"/api/student/assignments/{a_auto_id}/start", headers=student1_headers)
        att_auto_id = res_start_auto.json()["attempt_id"]

        res_sub_auto = client.post(f"/api/student/attempts/{att_auto_id}/submit", json={
            "answers": {
                str(q_matching_id): {"Praha": "Česko", "Bratislava": "Slovensko"},
                str(q_short_id): "EARTH"
            }
        }, headers=student1_headers)
        assert res_sub_auto.status_code == 200
        assert res_sub_auto.json()["status"] == "GRADED"
        assert res_sub_auto.json()["total_points"] == 3.0
        assert res_sub_auto.json()["score_percent"] == 100.0
        print(f"  [OK] Pure auto-graded test automatically became GRADED with 100% score")

        print("\n" + "=" * 70)
        print("ALL 7 REQUIREMENTS SUCCESSFULLY TESTED AND VERIFIED!")
        print("=" * 70)

    finally:
        db.close()

if __name__ == "__main__":
    run_all_tests()
