-- 03_mock_data.sql

-- Šablona: Biologie - Buňka 2 (Aktivní)
INSERT INTO test_templates (teacher_id, name, description, is_active, difficulty, estimated_duration_minutes) 
VALUES (1, 'Biologie - Buňka 2', 'Test z biologie buňky', TRUE, 'MEDIUM', 45);

-- Šablona: Biologie - Buňka 1 (Dokončeno)
INSERT INTO test_templates (teacher_id, name, description, is_active, difficulty, estimated_duration_minutes) 
VALUES (1, 'Biologie - Buňka 1', 'Starší test z biologie', TRUE, 'EASY', 45);

-- Assignment pro Buňka 2 (Aktivní - nyní) - ID bude 2 (pokud existuje assignment 1 z 02_data.sql)
INSERT INTO exam_assignments (template_id, group_id, activate_from, activate_to, time_limit_minutes, is_active) 
VALUES (2, 1, NOW() - INTERVAL '30 minutes', NOW() + INTERVAL '30 minutes', 45, TRUE);

-- Assignment pro Buňka 1 (Dokončeno - v minulosti) - ID bude 3
INSERT INTO exam_assignments (template_id, group_id, activate_from, activate_to, time_limit_minutes, is_active) 
VALUES (3, 1, NOW() - INTERVAL '5 days', NOW() - INTERVAL '4 days 23 hours', 45, TRUE);

-- Pokusy (Student attempts) - 2 odevzdali Buňku 1
INSERT INTO student_attempts (assignment_id, student_id, started_at, finished_at, status, questions_snapshot) 
VALUES 
(3, 1, NOW() - INTERVAL '4 days 23 hours 50 minutes', NOW() - INTERVAL '4 days 23 hours 10 minutes', 'SUBMITTED', '[]'::JSONB),
(3, 2, NOW() - INTERVAL '4 days 23 hours 45 minutes', NOW() - INTERVAL '4 days 23 hours 5 minutes', 'SUBMITTED', '[]'::JSONB);

-- Pokusy (Student attempts) - 1 odevzdal Buňku 2 (Aktivní)
INSERT INTO student_attempts (assignment_id, student_id, started_at, finished_at, status, questions_snapshot) 
VALUES 
(2, 1, NOW() - INTERVAL '20 minutes', NOW() - INTERVAL '5 minutes', 'SUBMITTED', '[]'::JSONB);
