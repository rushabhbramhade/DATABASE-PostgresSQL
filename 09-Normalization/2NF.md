# 📘 Second Normal Form (2NF)

## 📑 Table of Contents

- [Prerequisites](#prerequisites)
- [What is 2NF?](#what-is-2nf)
- [What is a Partial Dependency?](#what-is-a-partial-dependency)
- [The Rule of 2NF](#the-rule-of-2nf)
- [Bad Example — Partial Dependency](#bad-example--partial-dependency)
- [Good Example — Decomposed Tables](#good-example--decomposed-tables)
- [SQL Examples — The Decomposition](#sql-examples--the-decomposition)
- [Why 2NF Matters for Data Consistency](#why-2nf-matters-for-data-consistency)
- [When Does 2NF NOT Apply?](#when-does-2nf-not-apply)
- [Key Takeaways](#key-takeaways)

---

## Prerequisites

> ⚠️ **A table MUST be in [1NF](./1NF.md) before it can be evaluated for 2NF.**

Before reading this file, make sure you understand:
- Atomic values (no comma-separated data)
- No repeating groups
- Every row is uniquely identifiable

**2NF builds on top of 1NF** by addressing a specific problem: **partial dependencies**.

---

## What is 2NF?

**Second Normal Form (2NF)** requires that:

1. The table is already in **1NF**, AND
2. Every **non-key column** depends on the **entire primary key**, not just a part of it.

This rule only comes into play when your table has a **composite primary key** (a primary key made up of two or more columns).

> If your table has a **single-column primary key**, it is automatically in 2NF (as long as it's in 1NF), because there is no "part" of the key for a column to partially depend on.

---

## What is a Partial Dependency?

A **partial dependency** exists when a non-key column depends on **only a part** of a composite primary key, rather than the whole key.

### Visual Explanation

```
Composite Primary Key: (student_id, course_id)

student_name → depends ONLY on student_id        ← ❌ PARTIAL dependency
course_name  → depends ONLY on course_id          ← ❌ PARTIAL dependency
grade        → depends on (student_id, course_id) ← ✅ FULL dependency
```

```
┌─────────────────────────────────────────────────┐
│        Composite Key: (student_id, course_id)   │
│                                                 │
│   student_id ──────► student_name  ❌ PARTIAL    │
│   course_id  ──────► course_name   ❌ PARTIAL    │
│   (student_id, course_id) ──► grade ✅ FULL      │
└─────────────────────────────────────────────────┘
```

---

## The Rule of 2NF

| Condition | Requirement |
|-----------|-------------|
| Table must be in 1NF | ✅ Atomic values, unique rows, no repeating groups |
| No partial dependencies | Every non-key column must depend on the **entire** composite key |

> **In plain English:** If a column can be determined by knowing *just part* of the primary key, it doesn't belong in this table.

---

## Bad Example — Partial Dependency

Consider a `student_courses` table that tracks which students are enrolled in which courses, along with additional information:

### ❌ `student_courses` (Violates 2NF)

| student_id | course_id | student_name  | student_email         | course_name       | grade |
|------------|-----------|---------------|-----------------------|-------------------|-------|
| 101        | CS201     | Amit Sharma   | amit@example.com      | Data Structures   | A     |
| 101        | CS202     | Amit Sharma   | amit@example.com      | Algorithms        | B+    |
| 102        | CS201     | Priya Patel   | priya@example.com     | Data Structures   | A-    |
| 103        | CS202     | Ravi Kumar    | ravi@example.com      | Algorithms        | B     |
| 103        | CS203     | Ravi Kumar    | ravi@example.com      | Databases         | A+    |

**Composite Primary Key:** `(student_id, course_id)`

### What's Wrong?

| Column           | Depends On           | Dependency Type |
|------------------|----------------------|-----------------|
| `student_name`   | `student_id` only    | ❌ **Partial**   |
| `student_email`  | `student_id` only    | ❌ **Partial**   |
| `course_name`    | `course_id` only     | ❌ **Partial**   |
| `grade`          | `(student_id, course_id)` | ✅ Full     |

- `student_name` and `student_email` are repeated every time Amit appears in a new course.
- `course_name` is repeated every time a new student enrolls in "Data Structures".

---

## Good Example — Decomposed Tables

We **decompose** the single table into three tables, each storing data that fully depends on its own primary key:

### ✅ `students` table

| student_id | student_name | student_email     |
|------------|--------------|-------------------|
| 101        | Amit Sharma  | amit@example.com  |
| 102        | Priya Patel  | priya@example.com |
| 103        | Ravi Kumar   | ravi@example.com  |

**Primary Key:** `student_id`
— Both `student_name` and `student_email` fully depend on `student_id`.

### ✅ `courses` table

| course_id | course_name     |
|-----------|-----------------|
| CS201     | Data Structures |
| CS202     | Algorithms      |
| CS203     | Databases       |

**Primary Key:** `course_id`
— `course_name` fully depends on `course_id`.

### ✅ `enrollments` table

| student_id | course_id | grade |
|------------|-----------|-------|
| 101        | CS201     | A     |
| 101        | CS202     | B+    |
| 102        | CS201     | A-    |
| 103        | CS202     | B     |
| 103        | CS203     | A+    |

**Composite Primary Key:** `(student_id, course_id)`
— `grade` fully depends on the combination of both keys.

---

## SQL Examples — The Decomposition

### ❌ BEFORE — Single Table (Violates 2NF)

```sql
-- BAD DESIGN: partial dependencies on composite key
CREATE TABLE student_courses_bad (
    student_id    INT,
    course_id     VARCHAR(10),
    student_name  VARCHAR(100),
    student_email VARCHAR(150),
    course_name   VARCHAR(100),
    grade         CHAR(2),
    PRIMARY KEY (student_id, course_id)
);

INSERT INTO student_courses_bad VALUES
(101, 'CS201', 'Amit Sharma', 'amit@example.com',  'Data Structures', 'A'),
(101, 'CS202', 'Amit Sharma', 'amit@example.com',  'Algorithms',      'B+'),
(102, 'CS201', 'Priya Patel', 'priya@example.com', 'Data Structures', 'A-'),
(103, 'CS202', 'Ravi Kumar',  'ravi@example.com',  'Algorithms',      'B'),
(103, 'CS203', 'Ravi Kumar',  'ravi@example.com',  'Databases',       'A+');
```

**Problems visible in the data:**
- `'Amit Sharma'` and `'amit@example.com'` appear in **2 rows**.
- `'Data Structures'` appears in **2 rows**.
- If Amit changes his email, we must update **every row** he appears in.

### ✅ AFTER — Decomposed Tables (2NF)

```sql
-- Students table: student info depends only on student_id
CREATE TABLE students (
    student_id    SERIAL PRIMARY KEY,
    student_name  VARCHAR(100) NOT NULL,
    student_email VARCHAR(150) UNIQUE NOT NULL
);

-- Courses table: course info depends only on course_id
CREATE TABLE courses (
    course_id   VARCHAR(10) PRIMARY KEY,
    course_name VARCHAR(100) NOT NULL
);

-- Enrollments table: grade depends on the full composite key
CREATE TABLE enrollments (
    student_id INT         REFERENCES students(student_id),
    course_id  VARCHAR(10) REFERENCES courses(course_id),
    grade      CHAR(2),
    PRIMARY KEY (student_id, course_id)
);

-- Insert data
INSERT INTO students (student_id, student_name, student_email) VALUES
(101, 'Amit Sharma', 'amit@example.com'),
(102, 'Priya Patel', 'priya@example.com'),
(103, 'Ravi Kumar',  'ravi@example.com');

INSERT INTO courses (course_id, course_name) VALUES
('CS201', 'Data Structures'),
('CS202', 'Algorithms'),
('CS203', 'Databases');

INSERT INTO enrollments (student_id, course_id, grade) VALUES
(101, 'CS201', 'A'),
(101, 'CS202', 'B+'),
(102, 'CS201', 'A-'),
(103, 'CS202', 'B'),
(103, 'CS203', 'A+');
```

### Querying the Normalized Structure

```sql
-- Get full enrollment details using JOINs
SELECT 
    s.student_name,
    s.student_email,
    c.course_name,
    e.grade
FROM enrollments e
JOIN students s ON e.student_id = s.student_id
JOIN courses c  ON e.course_id  = c.course_id
ORDER BY s.student_name, c.course_name;
```

**Expected Output:**

| student_name | student_email     | course_name     | grade |
|--------------|-------------------|-----------------|-------|
| Amit Sharma  | amit@example.com  | Algorithms      | B+    |
| Amit Sharma  | amit@example.com  | Data Structures | A     |
| Priya Patel  | priya@example.com | Data Structures | A-    |
| Ravi Kumar   | ravi@example.com  | Algorithms      | B     |
| Ravi Kumar   | ravi@example.com  | Databases       | A+    |

```sql
-- Update Amit's email in exactly ONE place
UPDATE students
SET student_email = 'amit.sharma@newmail.com'
WHERE student_id = 101;
-- This change is instantly reflected in all queries — no duplication to fix!
```

---

## Why 2NF Matters for Data Consistency

Without 2NF, your database suffers from **three classic anomalies**:

### 1. Update Anomaly

> Amit's email is stored in every row where he's enrolled. If you update it in one row but forget another, the database becomes **inconsistent**.

```
Row 1: Amit Sharma, amit@example.com,    CS201  ← updated ✅
Row 2: Amit Sharma, amit@OLD_email.com,  CS202  ← forgotten ❌
```

**After 2NF:** Amit's email is stored **once** in `students`. One `UPDATE`, guaranteed consistency.

### 2. Insertion Anomaly

> You cannot add a new course (e.g., `CS204 — Machine Learning`) unless a student is already enrolled in it, because `student_id` is part of the primary key.

**After 2NF:** Just `INSERT INTO courses VALUES ('CS204', 'Machine Learning')` — no student required.

### 3. Deletion Anomaly

> If Priya (the only student in CS201 in some scenario) drops the course, deleting her row also deletes the fact that course CS201 exists.

**After 2NF:** Deleting an enrollment doesn't touch the `courses` table. The course information is preserved independently.

### Summary of Anomalies

| Anomaly     | Without 2NF                                    | With 2NF                                |
|-------------|------------------------------------------------|-----------------------------------------|
| **Update**  | Must update multiple rows; risk inconsistency  | Update once in the source table         |
| **Insert**  | Cannot add independent data without dummy rows | Insert into any table independently     |
| **Delete**  | Removing a row can lose unrelated information  | Each entity is stored independently     |

---

## When Does 2NF NOT Apply?

2NF only addresses **partial dependencies**, which can only exist when you have a **composite primary key**.

| Scenario                        | 2NF Relevant? |
|---------------------------------|---------------|
| Table has a single-column PK    | **No** — automatically in 2NF (if in 1NF) |
| Table has a composite PK        | **Yes** — check for partial dependencies |
| Table uses a surrogate key (SERIAL) with no composite key | **No** — single PK |

---

## Key Takeaways

| ✅ Do                                              | ❌ Don't                                                     |
|---------------------------------------------------|--------------------------------------------------------------|
| Ensure 1NF before checking for 2NF               | Skip 1NF and jump to higher forms                           |
| Identify your composite keys                     | Ignore partial dependencies                                  |
| Move partially dependent columns to their own table | Store student info in an enrollment table                  |
| Use Foreign Keys to maintain relationships        | Duplicate data across rows to avoid JOINs                   |
| Use JOINs to reconstruct the full picture         | Denormalize prematurely for "convenience"                   |

> **The 2NF Rule in One Sentence:** *Every non-key column must depend on the whole key, not just part of the key.*

---

*← [First Normal Form (1NF)](./1NF.md) | [Third Normal Form (3NF) →](./3NF.md)*
