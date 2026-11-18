-- ════════════════════════════════════════════════════════════
-- UCES — University Course Evaluation System
-- PostgreSQL 15 Database Schema
-- Fall 2024–2025
-- ════════════════════════════════════════════════════════════

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─────────────────────────────────────────
-- 1. DEPARTMENTS
--    Stores academic departments.
--    Referenced by users and courses.
-- ─────────────────────────────────────────
CREATE TABLE departments (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(120) NOT NULL,
    code        VARCHAR(20)  NOT NULL UNIQUE,  -- e.g. 'CS', 'MATH', 'NET'
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

INSERT INTO departments (name, code) VALUES
    ('Computer Science',  'CS'),
    ('Networks',          'NET'),
    ('Mathematics',       'MATH'),
    ('Academic Affairs',  'AA'),
    ('Software Engineering', 'SE');


-- ─────────────────────────────────────────
-- 2. USERS
--    All system participants across roles.
--    role: 'student' | 'instructor' | 'dept_head' | 'admin'
-- ─────────────────────────────────────────
CREATE TYPE user_role AS ENUM ('student', 'instructor', 'dept_head', 'admin');

CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name       VARCHAR(150) NOT NULL,
    email           VARCHAR(200) NOT NULL UNIQUE,
    password_hash   TEXT         NOT NULL,           -- bcrypt, cost 12
    role            user_role    NOT NULL DEFAULT 'student',
    department_id   UUID         REFERENCES departments(id) ON DELETE SET NULL,
    student_year    SMALLINT     CHECK (student_year BETWEEN 1 AND 6),  -- students only
    title           VARCHAR(100),                    -- instructors/admins
    is_active       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email    ON users(email);
CREATE INDEX idx_users_role     ON users(role);
CREATE INDEX idx_users_dept     ON users(department_id);

-- Sample data aligned with prototype
INSERT INTO users (full_name, email, password_hash, role, student_year) VALUES
    ('Ahmad Al-Zahrawi',  'ahmad@university.edu',  '$2b$12$placeholder', 'student',    3),
    ('Mariam Al-Khalidi', 'mariam@university.edu', '$2b$12$placeholder', 'student',    2),
    ('Yusuf Al-Tamimi',   'yusuf@university.edu',  '$2b$12$placeholder', 'student',    3);

INSERT INTO users (full_name, email, password_hash, role, title) VALUES
    ('Dr. Khalid Nasser',   'k.nasser@university.edu',   '$2b$12$placeholder', 'instructor', 'Associate Professor'),
    ('Dr. Sara Al-Mansouri','s.mansouri@university.edu',  '$2b$12$placeholder', 'instructor', 'Assistant Professor'),
    ('Dr. Layla Hamdan',    'l.hamdan@university.edu',    '$2b$12$placeholder', 'instructor', 'Associate Professor'),
    ('Dr. Omar Bishara',    'o.bishara@university.edu',   '$2b$12$placeholder', 'instructor', 'Lecturer'),
    ('Dr. Fatima Al-Sayed', 'f.sayed@university.edu',     '$2b$12$placeholder', 'instructor', 'Assistant Professor'),
    ('Dr. Reem Qasim',      'r.qasim@university.edu',     '$2b$12$placeholder', 'instructor', 'Lecturer'),
    ('Prof. Walid Masri',   'w.masri@university.edu',     '$2b$12$placeholder', 'dept_head',  'Department Head'),
    ('Dr. Nadia Al-Farsi',  'nadia@university.edu',       '$2b$12$placeholder', 'admin',      'Academic Affairs Director');


-- ─────────────────────────────────────────
-- 3. SEMESTERS
--    Academic period records.
-- ─────────────────────────────────────────
CREATE TABLE semesters (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    label       VARCHAR(50)  NOT NULL UNIQUE,   -- e.g. 'Fall 2024-2025'
    start_date  DATE         NOT NULL,
    end_date    DATE         NOT NULL,
    is_current  BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CONSTRAINT  chk_semester_dates CHECK (end_date > start_date)
);

INSERT INTO semesters (label, start_date, end_date, is_current) VALUES
    ('Fall 2024-2025',   '2024-09-01', '2025-01-15', TRUE),
    ('Spring 2024',      '2024-02-01', '2024-06-20', FALSE),
    ('Fall 2023-2024',   '2023-09-01', '2024-01-15', FALSE);


-- ─────────────────────────────────────────
-- 4. COURSES
--    University courses offered per department.
--    category: 'Core' | 'Elective' | 'Foundation'
-- ─────────────────────────────────────────
CREATE TYPE course_category AS ENUM ('Core', 'Elective', 'Foundation');

CREATE TABLE courses (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code            VARCHAR(20)     NOT NULL UNIQUE,  -- e.g. 'CS301'
    title           VARCHAR(200)    NOT NULL,
    department_id   UUID            NOT NULL REFERENCES departments(id),
    instructor_id   UUID            NOT NULL REFERENCES users(id),
    credits         SMALLINT        NOT NULL CHECK (credits BETWEEN 1 AND 6),
    category        course_category NOT NULL DEFAULT 'Core',
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_courses_dept       ON courses(department_id);
CREATE INDEX idx_courses_instructor ON courses(instructor_id);

-- Courses matching the prototype (IDs referenced symbolically)
-- CS301, CS240, DB250, NET180, AI350, MATH201
-- (instructor_id values would reference the users table by actual UUID)


-- ─────────────────────────────────────────
-- 5. ENROLLMENTS
--    Links students to courses for a given semester.
--    Unique constraint prevents duplicate enrollments.
-- ─────────────────────────────────────────
CREATE TABLE enrollments (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id  UUID        NOT NULL REFERENCES users(id)    ON DELETE CASCADE,
    course_id   UUID        NOT NULL REFERENCES courses(id)  ON DELETE CASCADE,
    semester_id UUID        NOT NULL REFERENCES semesters(id),
    enrolled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT  uq_enrollment UNIQUE (student_id, course_id, semester_id)
);

CREATE INDEX idx_enrollments_student  ON enrollments(student_id);
CREATE INDEX idx_enrollments_course   ON enrollments(course_id);
CREATE INDEX idx_enrollments_semester ON enrollments(semester_id);


-- ─────────────────────────────────────────
-- 6. EVALUATION_WINDOWS
--    Defines the open/close period for evaluations
--    per course per semester. Admins control is_active.
-- ─────────────────────────────────────────
CREATE TABLE evaluation_windows (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id   UUID        NOT NULL REFERENCES courses(id)   ON DELETE CASCADE,
    semester_id UUID        NOT NULL REFERENCES semesters(id) ON DELETE CASCADE,
    opens_at    TIMESTAMPTZ NOT NULL,
    closes_at   TIMESTAMPTZ NOT NULL,
    is_active   BOOLEAN     NOT NULL DEFAULT TRUE,
    created_by  UUID        REFERENCES users(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT  uq_window       UNIQUE (course_id, semester_id),
    CONSTRAINT  chk_window_dates CHECK (closes_at > opens_at)
);

CREATE INDEX idx_windows_course   ON evaluation_windows(course_id);
CREATE INDEX idx_windows_semester ON evaluation_windows(semester_id);
CREATE INDEX idx_windows_active   ON evaluation_windows(is_active);


-- ─────────────────────────────────────────
-- 7. EVALUATION_RESPONSES
--    One row per anonymous submission.
--    anonymous_token = HMAC-SHA256(studentId:windowId, SERVER_SECRET)
--    — prevents double-submission without linking identity to answers.
-- ─────────────────────────────────────────
CREATE TABLE evaluation_responses (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    window_id        UUID        NOT NULL REFERENCES evaluation_windows(id) ON DELETE CASCADE,
    anonymous_token  CHAR(64)    NOT NULL,   -- SHA-256 hex = 64 chars
    instructor_score SMALLINT    NOT NULL CHECK (instructor_score  BETWEEN 1 AND 5),
    content_score    SMALLINT    NOT NULL CHECK (content_score     BETWEEN 1 AND 5),
    assignments_score SMALLINT   NOT NULL CHECK (assignments_score BETWEEN 1 AND 5),
    resources_score  SMALLINT    NOT NULL CHECK (resources_score   BETWEEN 1 AND 5),
    overall_score    SMALLINT    NOT NULL CHECK (overall_score     BETWEEN 1 AND 5),
    comment_text     TEXT,                   -- optional, anonymised
    submitted_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_response_token UNIQUE (window_id, anonymous_token)
);

CREATE INDEX idx_responses_window  ON evaluation_responses(window_id);
CREATE INDEX idx_responses_submitted ON evaluation_responses(submitted_at);

-- ════════════════════════════════════════════════════════════
-- VIEWS
-- ════════════════════════════════════════════════════════════

-- Course aggregate scores view (used by admin dashboard)
CREATE OR REPLACE VIEW vw_course_averages AS
SELECT
    c.id                                          AS course_id,
    c.code,
    c.title,
    s.label                                       AS semester,
    COUNT(r.id)                                   AS response_count,
    ROUND(AVG(r.instructor_score)::numeric, 2)    AS avg_instructor,
    ROUND(AVG(r.content_score)::numeric, 2)       AS avg_content,
    ROUND(AVG(r.assignments_score)::numeric, 2)   AS avg_assignments,
    ROUND(AVG(r.resources_score)::numeric, 2)     AS avg_resources,
    ROUND(AVG(r.overall_score)::numeric, 2)       AS avg_overall,
    ROUND(AVG(
        (r.instructor_score + r.content_score +
         r.assignments_score + r.resources_score + r.overall_score) / 5.0
    )::numeric, 2)                                AS avg_total
FROM courses c
JOIN evaluation_windows ew ON ew.course_id   = c.id
JOIN semesters          s  ON s.id           = ew.semester_id
LEFT JOIN evaluation_responses r ON r.window_id = ew.id
GROUP BY c.id, c.code, c.title, s.label;


-- Participation rate view (used by admin dashboard)
CREATE OR REPLACE VIEW vw_participation AS
SELECT
    s.id                                            AS semester_id,
    s.label                                         AS semester,
    COUNT(DISTINCT ew.id)                           AS total_windows,
    COUNT(DISTINCT ew.id) FILTER (WHERE ew.is_active) AS open_windows,
    COUNT(r.id)                                     AS total_responses,
    ROUND(
        COUNT(r.id) * 100.0 /
        NULLIF(COUNT(DISTINCT e.id), 0), 1
    )                                               AS participation_pct
FROM semesters s
JOIN evaluation_windows ew ON ew.semester_id = s.id
LEFT JOIN enrollments   e  ON e.semester_id  = s.id AND e.course_id = ew.course_id
LEFT JOIN evaluation_responses r ON r.window_id = ew.id
GROUP BY s.id, s.label;

-- ════════════════════════════════════════════════════════════
-- ERD SUMMARY (text representation)
-- ════════════════════════════════════════════════════════════
--
--  departments ──< users (department_id)
--  departments ──< courses (department_id)
--  users ────────< courses (instructor_id)
--  users ────────< enrollments (student_id)
--  courses ──────< enrollments (course_id)
--  semesters ────< enrollments (semester_id)
--  courses ──────< evaluation_windows (course_id)
--  semesters ────< evaluation_windows (semester_id)
--  evaluation_windows ──< evaluation_responses (window_id)
--
-- ════════════════════════════════════════════════════════════
