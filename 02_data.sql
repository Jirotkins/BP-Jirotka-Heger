-- 02_data.sql
-- Tento soubor vkládá testovací data BEZ explicitních primárních klíčů.
-- Databáze si sama vygeneruje ID od 1.

-- Učitelé
INSERT INTO public.teachers (name, email, password_hash) VALUES 
('Karel Novák', 'karel.novak@skola.cz', '$2b$12$3YJkdTzpJ8x6FbKA/SFFPOMGr.vdNwCmbJCO2Qxtn2WmKf/H4Xdeq');

-- Banky otázek (odkazuje na teacher_id = 1)
INSERT INTO public.banks (teacher_id, name, description, is_public) VALUES 
(1, 'Matematika', '{"subject":"Mat","iconIndex":1}', false);

-- Skupiny (odkazuje na teacher_id = 1)
INSERT INTO public.groups (teacher_id, name, description) VALUES 
(1, '3.C', '{"subject":"Matematika","icon":"61200"}');

-- Otázky (odkazuje na bank_id = 1)
INSERT INTO public.questions (bank_id, text, type, default_points) VALUES 
(1, 'Kolik je 5 × 12?', 'SINGLE_CHOICE', 1),
(1, 'Zadej výsledek rovnice: 3x - 5 = 10', 'SHORT_ANSWER', 1),
(1, 'Seřaď zlomky od nejmenšího po největší:', 'ORDERING', 1),
(1, 'Spoj matematické pojmy s jejich vzorci:', 'MATCHING', 1),
(1, 'Vysvětli vlastními slovy, co je to Pythagorova věta a k čemu se používá.', 'OPEN_TEXT', 1);

-- Odpovědi (odkazují na question_id = 1..5)
INSERT INTO public.answers (question_id, text, is_correct, order_index) VALUES 
(1, '60', true, 0),
(1, '52', false, 0),
(1, '70', false, 0),
(1, '65', false, 0),

(2, '5', true, 0),
(2, 'pět', true, 0),

(3, '1/8', true, 1),
(3, '1/4', true, 2),
(3, '1/2', true, 3),
(3, '3/4', true, 4),

(4, 'Obsah kruhu|||π * r^2', true, 0),
(4, 'Obvod kruhu|||2 * π * r', true, 0),
(4, 'Obsah čtverce|||a^2', true, 0);

-- Studenti
INSERT INTO public.students (email, login_code, password_hash, active_flag) VALUES 
('mat1_01@school.local', 'mat1_01', '$2b$12$CHtvQfu/aJLISjISjzXg.eENGqt6bifj1pZWjf2Yr5Tl8HeffSun.', true),
('mat1_02@school.local', 'mat1_02', '$2b$12$njuOrTIei4/bClKKmSKfHuMQ7ciqV8VTIArEzNAGlLVWC8e7h7m8y', true);

-- Přiřazení studentů do skupiny (odkazuje na student_id = 1, 2 a group_id = 1)
INSERT INTO public.student_groups (student_id, group_id) VALUES 
(1, 1),
(2, 1);

-- Šablony testů (odkazuje na teacher_id = 1)
INSERT INTO public.test_templates (teacher_id, name, description, is_active, difficulty, estimated_duration_minutes, tags, learning_objectives, settings) VALUES 
(1, 'TEST V1', '', true, 'MEDIUM', 5, '{}', '[]', '{"shuffle": true, "attempts": "1", "can_go_back": true, "immediate_feedback": false, "show_results_after_submit": true}');

-- Přiřazení otázek do testu (odkazuje na template_id = 1 a question_id = 1..5)
INSERT INTO public.test_templates_questions (template_id, question_id, position) VALUES 
(1, 1, 1),
(1, 2, 2),
(1, 3, 3),
(1, 4, 4),
(1, 5, 5);

-- Zadání testu (odkazuje na template_id = 1 a group_id = 1)
INSERT INTO public.exam_assignments (template_id, group_id, activate_from, activate_to, is_active, time_limit_minutes, show_immediate_feedback, max_attempts, shuffle_questions, can_go_back, show_results_after_submit) VALUES 
(1, 1, '2026-08-09 15:33:03', '2026-08-09 15:38:03', true, 5, false, 1, true, true, true);
