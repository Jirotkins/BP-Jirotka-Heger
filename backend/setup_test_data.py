#!/usr/bin/env python3
"""
Setup script - vytvoří test data
"""

import requests
import json

BASE_URL = "http://localhost:8000"

# Create a teacher
print("Creating test teacher...")
teacher_data = {
    "name": "Test Teacher",
    "email": "teacher@test.com",
    "password": "test1234"
}
resp = requests.post(f"{BASE_URL}/test/create-teacher", json=teacher_data)
if resp.status_code == 200:
    teacher_info = resp.json()
    print(f"✅ Teacher created: {teacher_info}")
else:
    print(f"❌ Failed: {resp.status_code}")
    print(resp.text)

# Login and get token
print("\nLogging in as teacher...")
login_data = {
    "username": "teacher@test.com",
    "password": "test1234",
    "is_teacher": True
}
resp = requests.post(f"{BASE_URL}/login", json=login_data)
if resp.status_code == 200:
    token_info = resp.json()
    teacher_token = token_info["access_token"]
    teacher_id = token_info["user_id"]
    print(f"✅ Teacher logged in (ID: {teacher_id})")
else:
    print(f"❌ Failed: {resp.status_code}")
    print(resp.text)
    exit(1)

# Create a group
print("\nCreating test group...")
headers = {"Authorization": f"Bearer {teacher_token}"}
group_data = {
    "name": "Test Group 1",
    "description": "Group for Phase 1 testing"
}
resp = requests.post(f"{BASE_URL}/groups", json=group_data, headers=headers)
if resp.status_code == 200:
    group_info = resp.json()
    group_id = group_info["group_id"]
    print(f"✅ Group created (ID: {group_id})")
else:
    print(f"❌ Failed: {resp.status_code}")
    print(resp.text)
    exit(1)

# Create a question bank
print("\nCreating test question bank...")
bank_data = {
    "name": "Test Bank 1",
    "description": "Test bank for Phase 1",
    "is_public": False
}
resp = requests.post(f"{BASE_URL}/banks", json=bank_data, headers=headers)
if resp.status_code == 200:
    bank_info = resp.json()
    bank_id = bank_info["bank_id"]
    print(f"✅ Bank created (ID: {bank_id})")
else:
    print(f"❌ Failed: {resp.status_code}")
    print(resp.text)
    exit(1)

# Create a test question
print("\nCreating test question...")
question_data = {
    "text": "What is 2+2?",
    "type": "SINGLE_CHOICE",
    "tags": ["math"],
    "default_points": 1,
    "answers": [
        {"text": "3", "is_correct": False},
        {"text": "4", "is_correct": True},
        {"text": "5", "is_correct": False}
    ]
}
resp = requests.post(f"{BASE_URL}/banks/{bank_id}/questions", json=question_data, headers=headers)
if resp.status_code == 200:
    question_info = resp.json()
    question_id = question_info["question"]["question_id"]
    print(f"✅ Question created (ID: {question_id})")
else:
    print(f"❌ Failed: {resp.status_code}")
    print(resp.text)
    exit(1)

# Create a test template
print("\nCreating test template...")
template_data = {
    "name": "Test Template 1",
    "description": "Test template for Phase 1",
    "difficulty": "EASY",
    "estimated_duration_minutes": 30,
    "is_active": True,
    "questions": [
        {"question_id": question_id, "position": 1, "points_custom": 1}
    ]
}
resp = requests.post(f"{BASE_URL}/test-templates", json=template_data, headers=headers)
if resp.status_code == 200:
    template_info = resp.json()
    template_id = template_info["template_id"]
    print(f"✅ Template created (ID: {template_id})")
else:
    print(f"❌ Failed: {resp.status_code}")
    print(resp.text)
    exit(1)

# Create students and add to group
print("\nCreating test students...")
for i in range(3):
    student_data = {
        "email": f"student{i}@test.com",
        "login_code": f"student_{i:02d}",
        "password": "test1234",
        "group_id": group_id
    }
    resp = requests.post(f"{BASE_URL}/test/create-student", json=student_data)
    if resp.status_code == 200:
        print(f"✅ Student {i} created")
    else:
        print(f"❌ Failed: {resp.status_code}")
        print(resp.text)

print("\n" + "="*70)
print("TEST DATA CREATED SUCCESSFULLY!")
print("="*70)
print(f"\nTest credentials:")
print(f"  Teacher email: teacher@test.com")
print(f"  Teacher password: test1234")
print(f"  Group ID: {group_id}")
print(f"  Template ID: {template_id}")
print(f"  Question ID: {question_id}")
print("="*70)
