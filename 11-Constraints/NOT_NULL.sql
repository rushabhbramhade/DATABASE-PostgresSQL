-- ============================================================
-- NOT NULL Constraint in PostgreSQL
-- ============================================================
-- NOT NULL ensures that a column cannot contain a NULL value.
-- Every INSERT or UPDATE must provide an actual value for that column.
--
-- NULL means "unknown" or "missing" — it is NOT the same as
-- an empty string ('') or zero (0).
--
-- NOT NULL is the simplest constraint but one of the most important
-- for data quality.
-- ============================================================


-- ============================================================
-- Example 1: NOT NULL During Table Creation
-- ============================================================

DROP TABLE IF EXISTS employees CASCADE;

CREATE TABLE employees (
    emp_id      SERIAL PRIMARY KEY,
    first_name  VARCHAR(50)  NOT NULL,        -- required
    last_name   VARCHAR(50)  NOT NULL,        -- required
    email       VARCHAR(100),                 -- optional (NULL allowed)
    salary      NUMERIC(10, 2) NOT NULL,      -- required
    hire_date   DATE NOT NULL DEFAULT CURRENT_DATE
);

INSERT INTO employees (first_name, last_name, email, salary)
VALUES
    ('Aarav',  'Sharma', 'aarav@company.com',  75000),
    ('Priya',  'Patel',  'priya@company.com',  82000),
    ('Rohan',  'Mehta',  NULL,                 68000),  -- email is NULL → allowed
    ('Sneha',  'Iyer',   'sneha@company.com',  91000);

SELECT * FROM employees;

-- Expected Output:
-- emp_id | first_name | last_name |       email         |  salary  | hire_date
-- -------+------------+-----------+---------------------+----------+------------
--      1 | Aarav      | Sharma    | aarav@company.com   | 75000.00 | 2026-06-26
--      2 | Priya      | Patel     | priya@company.com   | 82000.00 | 2026-06-26
--      3 | Rohan      | Mehta     | (NULL)              | 68000.00 | 2026-06-26
--      4 | Sneha      | Iyer      | sneha@company.com   | 91000.00 | 2026-06-26


-- ============================================================
-- Example 2: NOT NULL Violation Errors
-- ============================================================

-- Attempt to insert NULL into first_name:
INSERT INTO employees (first_name, last_name, salary)
VALUES (NULL, 'NoName', 50000);

-- ERROR:  null value in column "first_name" of relation "employees"
--         violates not-null constraint
-- DETAIL: Failing row contains (5, null, NoName, null, 50000.00, 2026-06-26).

-- Attempt to omit salary entirely (no DEFAULT set for salary):
INSERT INTO employees (first_name, last_name)
VALUES ('Missing', 'Salary');

-- ERROR:  null value in column "salary" of relation "employees"
--         violates not-null constraint
-- DETAIL: Failing row contains (6, Missing, Salary, null, null, 2026-06-26).

-- NOT NULL is also enforced on UPDATE:
UPDATE employees SET last_name = NULL WHERE emp_id = 1;

-- ERROR:  null value in column "last_name" of relation "employees"
--         violates not-null constraint


-- ============================================================
-- Example 3: NOT NULL vs DEFAULT — How They Interact
-- ============================================================
-- NOT NULL and DEFAULT serve different purposes:
--
--   NOT NULL  → "This column must NEVER be NULL"
--   DEFAULT   → "If no value is given, use THIS value"
--
-- They work TOGETHER beautifully:

DROP TABLE IF EXISTS products CASCADE;

CREATE TABLE products (
    product_id   SERIAL PRIMARY KEY,
    product_name VARCHAR(150)  NOT NULL,
    category     VARCHAR(50)   NOT NULL DEFAULT 'Uncategorized',
    price        NUMERIC(10,2) NOT NULL,
    stock        INT           NOT NULL DEFAULT 0,
    is_active    BOOLEAN       NOT NULL DEFAULT TRUE
);

-- Insert without specifying category, stock, or is_active:
INSERT INTO products (product_name, price)
VALUES
    ('Laptop Pro 15',  1299.99),
    ('Wireless Mouse',   29.99);

SELECT * FROM products;

-- Expected Output:
-- product_id |  product_name  |    category    |  price  | stock | is_active
-- -----------+----------------+----------------+---------+-------+-----------
--          1 | Laptop Pro 15  | Uncategorized  | 1299.99 |     0 | t
--          2 | Wireless Mouse | Uncategorized  |   29.99 |     0 | t
--
-- DEFAULT fills in the values so NOT NULL is satisfied.

-- However, explicitly passing NULL overrides the DEFAULT:
INSERT INTO products (product_name, category, price)
VALUES ('Bad Product', NULL, 9.99);

-- ERROR:  null value in column "category" of relation "products"
--         violates not-null constraint
--
-- KEY INSIGHT: DEFAULT only applies when the column is OMITTED.
-- Explicitly passing NULL is NOT the same as omitting the column.

-- ┌──────────────────────────────────────────────────────────────┐
-- │ Scenario                     │ DEFAULT alone │ NOT NULL + DEFAULT │
-- ├──────────────────────────────┼───────────────┼────────────────────┤
-- │ Column omitted in INSERT     │ Uses default  │ Uses default       │
-- │ Column explicitly set NULL   │ Stores NULL   │ ERROR! Blocked     │
-- │ Column given a real value    │ Uses value    │ Uses value         │
-- └──────────────────────────────┴───────────────┴────────────────────┘


-- ============================================================
-- Example 4: Adding NOT NULL to an Existing Column (ALTER TABLE)
-- ============================================================

DROP TABLE IF EXISTS students CASCADE;

CREATE TABLE students (
    student_id   SERIAL PRIMARY KEY,
    full_name    VARCHAR(100),                -- currently allows NULL
    email        VARCHAR(100),                -- currently allows NULL
    major        VARCHAR(50)
);

INSERT INTO students (full_name, email, major)
VALUES
    ('Ananya Gupta',  'ananya@uni.edu',  'Computer Science'),
    ('Karthik Nair',  'karthik@uni.edu', 'Mathematics'),
    ('Divya Menon',   'divya@uni.edu',   NULL);

-- Step 1: Before adding NOT NULL, ensure no NULLs exist in the column.
-- Check for NULLs in full_name:
SELECT * FROM students WHERE full_name IS NULL;
-- (0 rows — safe to proceed)

-- Step 2: Add NOT NULL constraint
ALTER TABLE students
    ALTER COLUMN full_name SET NOT NULL;

-- Now full_name cannot be NULL:
INSERT INTO students (full_name, email) VALUES (NULL, 'test@uni.edu');

-- ERROR:  null value in column "full_name" of relation "students"
--         violates not-null constraint

-- What if the column already has NULLs? You must fix them first!
-- Check email column:
ALTER TABLE students
    ALTER COLUMN email SET NOT NULL;

-- If any row has email = NULL, you'd get:
-- ERROR:  column "email" of relation "students" contains null values

-- Fix: Update NULLs first, then add the constraint:
UPDATE students SET email = 'unknown@uni.edu' WHERE email IS NULL;

ALTER TABLE students
    ALTER COLUMN email SET NOT NULL;    -- now succeeds

-- Removing NOT NULL:
ALTER TABLE students
    ALTER COLUMN email DROP NOT NULL;


-- ============================================================
-- Example 5: When to Use NOT NULL — Practical Guidelines
-- ============================================================

DROP TABLE IF EXISTS departments CASCADE;

CREATE TABLE departments (
    dept_id      SERIAL PRIMARY KEY,
    dept_name    VARCHAR(100) NOT NULL,    -- ✅ Always use: name is mandatory
    dept_code    CHAR(5)      NOT NULL,    -- ✅ Always use: code is mandatory
    manager_name VARCHAR(100),             -- ❌ Skip: new dept may not have a manager yet
    budget       NUMERIC(15, 2),           -- ❌ Skip: budget may be unknown initially
    created_at   TIMESTAMP NOT NULL DEFAULT NOW()  -- ✅ Combine with DEFAULT
);

INSERT INTO departments (dept_name, dept_code)
VALUES
    ('Engineering',     'ENG'),
    ('Human Resources', 'HR'),
    ('Marketing',       'MKT');

SELECT * FROM departments;

-- Expected Output:
-- dept_id |    dept_name     | dept_code | manager_name | budget |        created_at
-- --------+------------------+-----------+--------------+--------+-------------------------
--       1 | Engineering      | ENG       | (NULL)       | (NULL) | 2026-06-26 15:24:05.123
--       2 | Human Resources  | HR        | (NULL)       | (NULL) | 2026-06-26 15:24:05.123
--       3 | Marketing        | MKT       | (NULL)       | (NULL) | 2026-06-26 15:24:05.123

-- ┌─────────────────────────────────────────────────────────────────┐
-- │  WHEN TO USE NOT NULL — QUICK GUIDE                            │
-- │                                                                │
-- │  ✅ USE NOT NULL when:                                         │
-- │    • The column is essential (names, IDs, codes, dates)        │
-- │    • Missing data would break business logic                   │
-- │    • You always know the value at INSERT time                  │
-- │    • Combined with DEFAULT for timestamps, booleans, counters  │
-- │                                                                │
-- │  ❌ SKIP NOT NULL when:                                        │
-- │    • The value is genuinely optional (middle name, nickname)   │
-- │    • The value may not be known yet (end_date, manager)        │
-- │    • NULL has a meaningful business meaning ("not applicable") │
-- └─────────────────────────────────────────────────────────────────┘


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. NOT NULL prevents a column from storing NULL values.
-- 2. Use NOT NULL on columns that are essential to every row.
-- 3. NOT NULL + DEFAULT = safe combination; DEFAULT fills the value
--    when the column is omitted, but explicit NULL is still blocked.
-- 4. To add NOT NULL to an existing column:
--    a) First UPDATE any existing NULL values.
--    b) Then ALTER TABLE ... ALTER COLUMN ... SET NOT NULL.
-- 5. To remove NOT NULL: ALTER TABLE ... ALTER COLUMN ... DROP NOT NULL.
-- 6. PRIMARY KEY columns are implicitly NOT NULL — no need to add it.
-- 7. NOT NULL is a simple but critical guard for data integrity.
