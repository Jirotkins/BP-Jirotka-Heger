--
-- PostgreSQL database dump
--

\restrict csXc7gWRu1KBWY4fV9VAWnMzEb9w7aiQ61VqcJu9ctUonOluPsfGGUGt9Y7GnH5

-- Dumped from database version 15.15
-- Dumped by pg_dump version 15.15

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: teachers; Type: TABLE DATA; Schema: public; Owner: uzivatel
--

INSERT INTO public.teachers VALUES (2, 'Karel Novák', 'karel.novak@skola.cz', '$2b$12$3YJkdTzpJ8x6FbKA/SFFPOMGr.vdNwCmbJCO2Qxtn2WmKf/H4Xdeq', '2026-08-09 15:24:40.905533');


--
-- Data for Name: banks; Type: TABLE DATA; Schema: public; Owner: uzivatel
--

INSERT INTO public.banks VALUES (2, 2, 'Matematika', '{"subject":"Mat","iconIndex":1}', false);


--
-- Data for Name: questions; Type: TABLE DATA; Schema: public; Owner: uzivatel
--

INSERT INTO public.questions VALUES (5, 2, 'Kolik je 5 × 12?', 'SINGLE_CHOICE', NULL, NULL, 1, '2026-08-09 15:27:36.295523');
INSERT INTO public.questions VALUES (6, 2, 'Zadej výsledek rovnice: 3x - 5 = 10', 'SHORT_ANSWER', NULL, NULL, 1, '2026-08-09 15:28:03.091367');
INSERT INTO public.questions VALUES (7, 2, 'Seřaď zlomky od nejmenšího po největší:', 'ORDERING', NULL, NULL, 1, '2026-08-09 15:28:28.895393');
INSERT INTO public.questions VALUES (9, 2, 'Vysvětli vlastními slovy, co je to Pythagorova věta a k čemu se používá.', 'OPEN_TEXT', NULL, NULL, 1, '2026-08-09 15:30:04.177669');
INSERT INTO public.questions VALUES (8, 2, 'Spoj matematické pojmy s jejich vzorci:', 'MATCHING', NULL, NULL, 1, '2026-08-09 15:29:40.794423');


--
-- Data for Name: answers; Type: TABLE DATA; Schema: public; Owner: uzivatel
--

INSERT INTO public.answers VALUES (11, 5, '60', true, 0);
INSERT INTO public.answers VALUES (12, 5, '52', false, 0);
INSERT INTO public.answers VALUES (13, 5, '70', false, 0);
INSERT INTO public.answers VALUES (14, 5, '65', false, 0);
INSERT INTO public.answers VALUES (15, 6, '5', true, 0);
INSERT INTO public.answers VALUES (16, 6, 'pět', true, 0);
INSERT INTO public.answers VALUES (17, 7, '1/8', true, 1);
INSERT INTO public.answers VALUES (18, 7, '1/4', true, 2);
INSERT INTO public.answers VALUES (19, 7, '1/2', true, 3);
INSERT INTO public.answers VALUES (20, 7, '3/4', true, 4);
INSERT INTO public.answers VALUES (24, 8, 'Obsah kruhu|||π * r^2', true, 0);
INSERT INTO public.answers VALUES (25, 8, 'Obvod kruhu|||2 * π * r', true, 0);
INSERT INTO public.answers VALUES (26, 8, 'Obsah čtverce|||a^2', true, 0);


--
-- Data for Name: groups; Type: TABLE DATA; Schema: public; Owner: uzivatel
--

INSERT INTO public.groups VALUES (3, 2, '3.C', '{"subject":"Matematika","icon":"61200"}', '2026-08-09 15:25:14.012348');


--
-- Data for Name: test_templates; Type: TABLE DATA; Schema: public; Owner: uzivatel
--

INSERT INTO public.test_templates VALUES (3, 2, 'TEST V1', '', true, 'MEDIUM', 5, '{}', '[]', '{"shuffle": true, "attempts": "1", "can_go_back": true, "immediate_feedback": false, "show_results_after_submit": true}', '2026-08-09 15:33:03.47627', '2026-08-09 15:33:03.47627');


--
-- Data for Name: exam_assignments; Type: TABLE DATA; Schema: public; Owner: uzivatel
--

INSERT INTO public.exam_assignments (assignment_id, template_id, group_id, activate_from, activate_to, is_active, time_limit_minutes, access_password, show_immediate_feedback, max_attempts, shuffle_questions, can_go_back, show_results_after_submit, created_at) VALUES (2, 3, 3, '2026-08-09 15:33:03', '2026-08-09 15:38:03', true, 5, NULL, false, 1, true, true, true, '2026-08-09 15:33:03.682762');


--
-- Data for Name: students; Type: TABLE DATA; Schema: public; Owner: uzivatel
--

INSERT INTO public.students VALUES (5, 'mat1_01@school.local', 'mat1_01', '$2b$12$CHtvQfu/aJLISjISjzXg.eENGqt6bifj1pZWjf2Yr5Tl8HeffSun.', true, '2026-08-09 15:25:40.412592');
INSERT INTO public.students VALUES (6, 'mat1_02@school.local', 'mat1_02', '$2b$12$njuOrTIei4/bClKKmSKfHuMQ7ciqV8VTIArEzNAGlLVWC8e7h7m8y', true, '2026-08-09 15:25:40.412592');


--
-- Data for Name: student_attempts; Type: TABLE DATA; Schema: public; Owner: uzivatel
--

INSERT INTO public.student_attempts VALUES (2, 2, 5, '2026-08-09 15:34:08.163114', '2026-08-09 15:35:02.928763', '[{"text": "Kolik je 5 × 12?", "type": "SINGLE_CHOICE", "points": 1, "answers": [{"text": "60", "answer_id": 11, "is_correct": true, "order_index": 0}, {"text": "52", "answer_id": 12, "is_correct": false, "order_index": 0}, {"text": "70", "answer_id": 13, "is_correct": false, "order_index": 0}, {"text": "65", "answer_id": 14, "is_correct": false, "order_index": 0}], "position": 1, "image_url": null, "question_id": 5, "awardedPoints": 1}, {"text": "Zadej výsledek rovnice: 3x - 5 = 10", "type": "SHORT_ANSWER", "points": 1, "answers": [{"text": "5", "answer_id": 15, "is_correct": true, "order_index": 0}, {"text": "pět", "answer_id": 16, "is_correct": true, "order_index": 0}], "position": 2, "image_url": null, "question_id": 6, "awardedPoints": 1}, {"text": "Seřaď zlomky od nejmenšího po největší:", "type": "ORDERING", "points": 1, "answers": [{"text": "1/8", "answer_id": 17, "is_correct": true, "order_index": 1}, {"text": "1/4", "answer_id": 18, "is_correct": true, "order_index": 2}, {"text": "1/2", "answer_id": 19, "is_correct": true, "order_index": 3}, {"text": "3/4", "answer_id": 20, "is_correct": true, "order_index": 4}], "position": 3, "image_url": null, "question_id": 7, "awardedPoints": 1}, {"text": "Spoj matematické pojmy s jejich vzorci:", "type": "MATCHING", "points": 1, "answers": [{"text": "Obsah kruhu|||π * r^2", "answer_id": 21, "is_correct": true, "order_index": 0}, {"text": "Obvod kruhu|||2 * π * r", "answer_id": 22, "is_correct": true, "order_index": 0}, {"text": "Obsah čtverce|||a^2", "answer_id": 23, "is_correct": true, "order_index": 0}], "position": 4, "image_url": null, "question_id": 8, "awardedPoints": 1}]', '{"5": 11, "6": "5", "7": ["17", "18", "19", "20"], "8": {"obsah kruhu": "π * r^2", "obvod kruhu": "2 * π * r", "obsah čtverce": "a^2"}}', '{"5": "correct", "6": "correct", "7": "correct", "8": "correct"}', 4.0, 4.0);


--
-- Data for Name: student_groups; Type: TABLE DATA; Schema: public; Owner: uzivatel
--

INSERT INTO public.student_groups VALUES (5, 3, '2026-08-09 15:25:40.412592');
INSERT INTO public.student_groups VALUES (6, 3, '2026-08-09 15:25:40.412592');


--
-- Data for Name: test_templates_questions; Type: TABLE DATA; Schema: public; Owner: uzivatel
--

INSERT INTO public.test_templates_questions VALUES (3, 5, 1, NULL);
INSERT INTO public.test_templates_questions VALUES (3, 6, 2, NULL);
INSERT INTO public.test_templates_questions VALUES (3, 7, 3, NULL);
INSERT INTO public.test_templates_questions VALUES (3, 8, 4, NULL);
INSERT INTO public.test_templates_questions VALUES (3, 9, 5, NULL);


--
-- Name: answers_answer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: uzivatel
--

SELECT pg_catalog.setval('public.answers_answer_id_seq', 26, true);


--
-- Name: banks_bank_id_seq; Type: SEQUENCE SET; Schema: public; Owner: uzivatel
--

SELECT pg_catalog.setval('public.banks_bank_id_seq', 2, true);


--
-- Name: exam_assignments_assignment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: uzivatel
--

SELECT pg_catalog.setval('public.exam_assignments_assignment_id_seq', 2, true);


--
-- Name: groups_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: uzivatel
--

SELECT pg_catalog.setval('public.groups_group_id_seq', 3, true);


--
-- Name: questions_question_id_seq; Type: SEQUENCE SET; Schema: public; Owner: uzivatel
--

SELECT pg_catalog.setval('public.questions_question_id_seq', 9, true);


--
-- Name: student_attempts_attempt_id_seq; Type: SEQUENCE SET; Schema: public; Owner: uzivatel
--

SELECT pg_catalog.setval('public.student_attempts_attempt_id_seq', 2, true);


--
-- Name: students_student_id_seq; Type: SEQUENCE SET; Schema: public; Owner: uzivatel
--

SELECT pg_catalog.setval('public.students_student_id_seq', 6, true);


--
-- Name: teachers_teacher_id_seq; Type: SEQUENCE SET; Schema: public; Owner: uzivatel
--

SELECT pg_catalog.setval('public.teachers_teacher_id_seq', 2, true);


--
-- Name: test_templates_template_id_seq; Type: SEQUENCE SET; Schema: public; Owner: uzivatel
--

SELECT pg_catalog.setval('public.test_templates_template_id_seq', 3, true);


--
-- PostgreSQL database dump complete
--

\unrestrict csXc7gWRu1KBWY4fV9VAWnMzEb9w7aiQ61VqcJu9ctUonOluPsfGGUGt9Y7GnH5

