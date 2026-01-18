-- 1. Úklid (volitelné): Smaže staré tabulky, pokud existují, aby se skript dal spustit znovu
DROP TABLE IF EXISTS student_attempts CASCADE;
DROP TABLE IF EXISTS exam_assignments CASCADE;
DROP TABLE IF EXISTS test_templates_questions CASCADE;
DROP TABLE IF EXISTS test_templates CASCADE;
DROP TABLE IF EXISTS answers CASCADE;
DROP TABLE IF EXISTS questions CASCADE;
DROP TABLE IF EXISTS banks CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS groups CASCADE;
DROP TABLE IF EXISTS teachers CASCADE;

-- Smazání typů (ENUM), pokud existují
DROP TYPE IF EXISTS question_type;
DROP TYPE IF EXISTS attempt_status;

-- 2. Vytvoření ENUM typů (výčtové typy pro Postgres)
CREATE TYPE question_type AS ENUM ('SINGLE_CHOICE', 'MULTI_CHOICE', 'OPEN_TEXT');
CREATE TYPE attempt_status AS ENUM ('STARTED', 'SUBMITTED', 'GRADED');

-- 3. Tabulky Uživatelů a Organizace
CREATE TABLE teachers (
    teacher_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE groups (
    group_id SERIAL PRIMARY KEY,
    teacher_id INT REFERENCES teachers(teacher_id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    group_id INT REFERENCES groups(group_id) ON DELETE CASCADE,
    login_code VARCHAR(100) UNIQUE NOT NULL, -- Unikátní kód pro přihlášení
    password_hash VARCHAR(255),            -- Volitelné heslo
    active_flag BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Banka otázek
CREATE TABLE banks (
    bank_id SERIAL PRIMARY KEY,
    teacher_id INT REFERENCES teachers(teacher_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE
);

CREATE TABLE questions (
    question_id SERIAL PRIMARY KEY,
    bank_id INT REFERENCES banks(bank_id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    type question_type NOT NULL DEFAULT 'SINGLE_CHOICE',
    tags TEXT[],             -- PostgreSQL Array pro tagy
    image_url TEXT,          -- Odkaz na obrázek, pokud existuje
    default_points INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pro rychlé vyhledávání v poli tagů
CREATE INDEX idx_questions_tags ON questions USING GIN (tags);

CREATE TABLE answers (
    answer_id SERIAL PRIMARY KEY,
    question_id INT REFERENCES questions(question_id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    order_index INT DEFAULT 0 -- Pro definici pořadí u otázek typu ORDERING
);

-- 5. Definice testů (Šablony)
CREATE TABLE test_templates (
    template_id SERIAL PRIMARY KEY,
    teacher_id INT REFERENCES teachers(teacher_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    settings JSONB DEFAULT '{}', -- Např. {"shuffle": true, "show_results": false}
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE test_templates_questions (
    template_id INT REFERENCES test_templates(template_id) ON DELETE CASCADE,
    question_id INT REFERENCES questions(question_id) ON DELETE CASCADE,
    position INT NOT NULL,
    points_custom INT, -- Pokud je NULL, použije se default_points z tabulky questions
    PRIMARY KEY (template_id, question_id)
);

-- 6. Spuštění a Průběh
CREATE TABLE exam_assignments (
    assignment_id SERIAL PRIMARY KEY,
    template_id INT REFERENCES test_templates(template_id) ON DELETE CASCADE,
    group_id INT REFERENCES groups(group_id) ON DELETE CASCADE,
    activate_from TIMESTAMP,
    activate_to TIMESTAMP,
    time_limit_minutes INT, -- Časový limit v minutách (např. 45)
    access_password VARCHAR(50), -- Volitelné heslo pro spuštění testu
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE student_attempts (
    attempt_id SERIAL PRIMARY KEY,
    assignment_id INT REFERENCES exam_assignments(assignment_id) ON DELETE CASCADE,
    student_id INT REFERENCES students(student_id) ON DELETE CASCADE,
    
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    finished_at TIMESTAMP,
    
    -- TOHLE JE TO NEJDŮLEŽITĚJŠÍ:
    questions_snapshot JSONB NOT NULL, -- Kompletní kopie otázek v momentě testu
    student_answers JSONB DEFAULT '{}', -- Odpovědi žáka { "q_id": "answer" }
    
    total_points DECIMAL(5,2),        -- Získané body
    max_points DECIMAL(5,2),          -- Maximální možné body (ze snapshotu)
    score_percent DECIMAL(5,2),       -- Procentuální úspěšnost
    
    status attempt_status DEFAULT 'STARTED',
    teacher_note TEXT
);