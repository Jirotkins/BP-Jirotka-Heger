-- 1. Vytvoření učitele (Heslo je jen jako text, v reálu by byl hash)
INSERT INTO teachers (name, email, password_hash) 
VALUES ('Jan Novák', 'jan.novak@skola.cz', 'tajne_heslo_hash_123');

-- 2. Vytvoření třídy (pro učitele s ID 1)
INSERT INTO groups (teacher_id, name, description) 
VALUES (1, '3.B', 'Ročník 2023/2024 - Dějepis');

-- 3. Vytvoření studentů (Login kódy, které učitel rozdá)
INSERT INTO students (group_id, login_code, password_hash) VALUES 
(1, '3b_01_adamec', 'hash_pass_01'),
(1, '3b_02_blažková', 'hash_pass_02'),
(1, '3b_03_cyril', 'hash_pass_03');

-- 4. Vytvoření banky otázek
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

-- 7. Šablona testu
INSERT INTO test_templates (teacher_id, name, settings) 
VALUES (1, 'Pololetní písemka', '{"shuffle_questions": true, "show_results_immediately": false}');

-- 8. Přiřazení otázek do šablony (Vybereme otázky 1 a 2)
INSERT INTO test_templates_questions (template_id, question_id, position, points_custom) VALUES 
(1, 1, 1, NULL), -- Použije defaultní body (1)
(1, 2, 2, 4);    -- Override: Tady dáme za otázku 4 body místo 2

-- 9. Naplánování testu (Assignment) pro třídu 3.B
INSERT INTO exam_assignments (template_id, group_id, activate_from, activate_to, time_limit_minutes) 
VALUES (1, 1, NOW() - INTERVAL '1 hour', NOW() + INTERVAL '1 hour', 45);

-- 10. Simulace pokusu studenta (Student ID 1 už test odevzdal)
-- POZOR: Do 'questions_snapshot' vkládáme napevno JSON, v reálu to dělá aplikace
INSERT INTO student_attempts (assignment_id, student_id, started_at, finished_at, status, total_points, max_points, score_percent, questions_snapshot, student_answers) 
VALUES (
    1, 
    1, 
    NOW() - INTERVAL '30 minutes', 
    NOW() - INTERVAL '5 minutes', 
    'GRADED', 
    5, -- Získal 5 bodů
    5, -- Maximum bylo 5 bodů (1 za první + 4 za druhou override)
    100.0, 
    -- Snapshot otázek (zjednodušený příklad):
    '[{"q_id": 1, "text": "Kdy skončila...", "points": 1}, {"q_id": 2, "text": "Státy Osy...", "points": 4}]',
    -- Odpovědi studenta:
    '{"1": [1], "2": [4, 5]}' 
);