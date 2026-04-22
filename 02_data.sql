-- 1. Vytvoření učitele (Heslo je jen jako text, v reálu by byl hash)
INSERT INTO teachers (name, email, password_hash) 
VALUES ('Jan Novák', 'jan.novak@skola.cz', 'tajne_heslo_hash_123');

-- 2. Vytvoření tříd (pro učitele s ID 1)
INSERT INTO groups (teacher_id, name, description) 
VALUES 
(1, '3.B', 'Ročník 2023/2024 - Dějepis'),
(1, '3.C', 'Ročník 2023/2024 - Dějepis - druhá skupina');

-- 3. Vytvoření studentů (bez group_id - nyní se propojují přes student_groups)
INSERT INTO students (email, login_code, password_hash) VALUES 
('adamec@student.cz', '3b_01_adamec', 'hash_pass_01'),
('blazkova@student.cz', '3b_02_blažková', 'hash_pass_02'),
('cyril@student.cz', '3b_03_cyril', 'hash_pass_03'),
('divak@student.cz', '3c_01_divak', 'hash_pass_04');  -- Student v jiné skupině

-- 4. Propojení studentů se skupinami (many-to-many)
INSERT INTO student_groups (student_id, group_id) VALUES 
(1, 1),  -- Adamec do skupiny 3.B
(2, 1),  -- Blažková do skupiny 3.B
(3, 1),  -- Cyril do skupiny 3.B
(4, 2),  -- Divák do skupiny 3.C
(1, 2);  -- Adamec je zároveň v 3.C (příklad many-to-many)

-- 5. Vytvoření banky otázek
INSERT INTO banks (teacher_id, name, description) 
VALUES (1, 'Dějepis - 2. světová válka', 'Otázky pro pololetní opakování');

-- 5. Vytvoření otázek (Využíváme různé typy)
INSERT INTO questions (bank_id, text, type, tags, default_points) VALUES 
(1, 'Kdy skončila 2. světová válka v Evropě?', 'SINGLE_CHOICE', ARRAY['datum', '2.sv.v.'], 1),
(1, 'Vyberte všechny státy Osy:', 'MULTI_CHOICE', ARRAY['státy', 'aliances'], 2),
(1, 'Seřaďte události chronologicky:', 'ORDERING', ARRAY['chronologie'], 3),
(1, 'Popište stručně význam bitvy u Stalingradu.', 'OPEN_TEXT', ARRAY['východní fronta'], 5);

-- 6. Odpovědi k otázkám (Vazba na ID otázek 1, 2, 3 - předpokládáme ID sekvenci od 1)
-- Otázka 1 (Konec války)
INSERT INTO answers (question_id, text, is_correct) VALUES 
(1, '8. května 1945', TRUE),
(1, '11. listopadu 1918', FALSE),
(1, '1. září 1939', FALSE);

-- Otázka 2 (Státy Osy)
INSERT INTO answers (question_id, text, is_correct) VALUES 
(2, 'Německo', TRUE),
(2, 'Japonsko', TRUE),
(2, 'Francie', FALSE),
(2, 'USA', FALSE);

-- Otázka 3 (Seřazování - využijeme order_index pro správné pořadí)
INSERT INTO answers (question_id, text, order_index) VALUES 
(3, 'Napadení Polska', 1),
(3, 'Útok na Pearl Harbor', 2),
(3, 'Vylodění v Normandii', 3);

-- 7. Šablony testů (s novými metadaty: difficulty, tags, learning_objectives)
-- Šablona 1: Základní test (EASY)
INSERT INTO test_templates (teacher_id, name, description, is_active, difficulty, estimated_duration_minutes, tags, learning_objectives, settings) 
VALUES (
    1, 
    'Pololetní písemka - Evropa',
    'Základní test na otázky týkající se konce 2. světové války v Evropě',
    TRUE,
    'EASY',
    45,
    ARRAY['2.sv.v.', 'Evropa', 'základní'],
    '["Znát datum konce války", "Rozeznat státy Osy", "Pochopit důležité bitvy"]'::JSONB,
    '{"shuffle_questions": true, "show_results_immediately": false}'::JSONB
);

-- Šablona 2: Pokročilý test (MEDIUM)
INSERT INTO test_templates (teacher_id, name, description, is_active, difficulty, estimated_duration_minutes, tags, learning_objectives, settings) 
VALUES (
    1, 
    'Test komprehenze - 2. sv. válka',
    'Pokročilejší test vyžadující hluboké pochopení',
    TRUE,
    'MEDIUM',
    60,
    ARRAY['2.sv.v.', 'pokročilý', 'analýza'],
    '["Analyzovat příčiny porážky", "Pochopit strategii jednotlivých stran", "Evaluovat historické rozhodnutí"]'::JSONB,
    '{"shuffle_questions": true, "show_results_immediately": false, "allow_multiple_attempts": false}'::JSONB
);

-- 8. Přiřazení otázek do šablony (Vybereme otázky 1 a 2 pro šablonu 1)
INSERT INTO test_templates_questions (template_id, question_id, position, points_custom) VALUES 
(1, 1, 1, NULL),  -- Použije defaultní body (1)
(1, 2, 2, 4);     -- Override: Za otázku 4 body místo 2

-- 9. Naplánování testu (Assignment) pro třídu 3.B
INSERT INTO exam_assignments (template_id, group_id, activate_from, activate_to, time_limit_minutes) 
VALUES (1, 1, NOW() - INTERVAL '1 hour', NOW() + INTERVAL '1 hour', 45);

-- 10. Simulace pokusu studenta (Student ID 1 - Adamec - už test odevzdal)
-- POZOR: Do 'questions_snapshot' vkládáme snapshoty otázek, v reálu to dělá aplikace
INSERT INTO student_attempts (assignment_id, student_id, started_at, finished_at, status, total_points, max_points, score_percent, questions_snapshot, student_answers) 
VALUES (
    1, 
    1, 
    NOW() - INTERVAL '30 minutes', 
    NOW() - INTERVAL '5 minutes', 
    'GRADED', 
    5,     -- Získal 5 bodů
    5,     -- Maximum bylo 5 bodů (1 za první + 4 za druhou override)
    100.0, 
    -- Snapshot otázek v momentě testu (zachovává obsah otázky):
    '[{"q_id": 1, "text": "Kdy skončila...", "points": 1}, {"q_id": 2, "text": "Státy Osy...", "points": 4}]'::JSONB,
    -- Odpovědi studenta (ID vybraných odpovědí):
    '{"1": [1], "2": [4, 5]}'::JSONB
);