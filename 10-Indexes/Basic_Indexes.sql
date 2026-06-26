-- ============================================================
-- Topic:  Basic (Single-Column) Indexes in PostgreSQL
-- File:   Basic_Indexes.sql
-- ============================================================
-- What is an Index?
--
--   Think of a book's index at the back — instead of reading every
--   page to find "PostgreSQL," you flip to the index, find
--   "PostgreSQL → page 42," and jump straight there.
--
--   A database index works the same way. Without an index,
--   PostgreSQL must scan every row in a table (Sequential Scan)
--   to find matching data. With an index, it can jump directly
--   to the relevant rows — dramatically speeding up lookups.
--
-- Key Facts:
--   • PostgreSQL uses B-Tree indexes by default.
--   • Indexes speed up SELECT queries but slow down INSERT/UPDATE/DELETE
--     because the index must also be maintained.
--   • Indexes consume additional disk space.
--   • PostgreSQL automatically creates indexes on PRIMARY KEY
--     and UNIQUE constraint columns.
-- ============================================================
-- Sample table used throughout this file:
--
-- employees table:
-- | employee_id | first_name | last_name | department  | salary | hire_date  | email                    | is_active |
-- |-------------|------------|-----------|-------------|--------|------------|--------------------------|-----------|
-- | 1           | Amit       | Sharma    | Engineering | 75000  | 2021-03-15 | amit.sharma@mail.com     | TRUE      |
-- | 2           | Priya      | Verma     | Marketing   | 55000  | 2022-07-01 | priya.verma@mail.com     | TRUE      |
-- | 3           | Rahul      | Gupta     | Engineering | 82000  | 2020-01-10 | rahul.gupta@mail.com     | TRUE      |
-- | 4           | Sneha      | Patel     | HR          | 48000  | 2023-02-20 | sneha.patel@mail.com     | FALSE     |
-- | 5           | Vikram     | Singh     | Marketing   | 60000  | 2021-11-05 | vikram.singh@mail.com    | TRUE      |
-- | 6           | Ananya     | Das       | Engineering | 70000  | 2022-09-12 | ananya.das@mail.com      | TRUE      |
-- | 7           | Karan      | Mehta     | Sales       | 52000  | 2023-06-01 | karan.mehta@mail.com     | FALSE     |
-- ============================================================

-- Create the sample table (run once)
CREATE TABLE IF NOT EXISTS employees (
    employee_id  SERIAL PRIMARY KEY,
    first_name   VARCHAR(50)  NOT NULL,
    last_name    VARCHAR(50)  NOT NULL,
    department   VARCHAR(50),
    salary       NUMERIC(10,2),
    hire_date    DATE,
    email        VARCHAR(100),
    is_active    BOOLEAN DEFAULT TRUE
);

INSERT INTO employees (first_name, last_name, department, salary, hire_date, email, is_active)
VALUES
    ('Amit',   'Sharma', 'Engineering', 75000, '2021-03-15', 'amit.sharma@mail.com',  TRUE),
    ('Priya',  'Verma',  'Marketing',   55000, '2022-07-01', 'priya.verma@mail.com',  TRUE),
    ('Rahul',  'Gupta',  'Engineering', 82000, '2020-01-10', 'rahul.gupta@mail.com',  TRUE),
    ('Sneha',  'Patel',  'HR',          48000, '2023-02-20', 'sneha.patel@mail.com',  FALSE),
    ('Vikram', 'Singh',  'Marketing',   60000, '2021-11-05', 'vikram.singh@mail.com', TRUE),
    ('Ananya', 'Das',    'Engineering', 70000, '2022-09-12', 'ananya.das@mail.com',   TRUE),
    ('Karan',  'Mehta',  'Sales',       52000, '2023-06-01', 'karan.mehta@mail.com',  FALSE)
ON CONFLICT DO NOTHING;


-- ************************************************************
-- 1. CREATE INDEX — Basic B-Tree Index (default)
-- ************************************************************
-- Syntax:
--   CREATE INDEX index_name ON table_name (column_name);
--
-- PostgreSQL uses B-Tree by default. B-Tree indexes work great
-- for equality (=) and range queries (<, >, BETWEEN, ORDER BY).

CREATE INDEX idx_employees_department
ON employees (department);

-- Now queries filtering by department will be faster:
SELECT first_name, last_name, department
FROM employees
WHERE department = 'Engineering';

-- Expected Output:
-- | first_name | last_name | department  |
-- |------------|-----------|-------------|
-- | Amit       | Sharma    | Engineering |
-- | Rahul      | Gupta     | Engineering |
-- | Ananya     | Das       | Engineering |
--
-- Behind the scenes: PostgreSQL can now use an Index Scan
-- instead of reading every row in the table.


-- ************************************************************
-- 2. Index on a frequently queried column
-- ************************************************************
-- Rule of thumb: create indexes on columns that appear often
-- in WHERE, JOIN, ORDER BY, or GROUP BY clauses.

CREATE INDEX idx_employees_salary
ON employees (salary);

-- Range query — the B-Tree index makes this efficient:
SELECT first_name, last_name, salary
FROM employees
WHERE salary BETWEEN 50000 AND 70000;

-- Expected Output:
-- | first_name | last_name | salary |
-- |------------|-----------|--------|
-- | Priya      | Verma     | 55000  |
-- | Vikram     | Singh     | 60000  |
-- | Ananya     | Das       | 70000  |
-- | Karan      | Mehta     | 52000  |
--
-- ORDER BY also benefits from this index:
SELECT first_name, salary
FROM employees
ORDER BY salary DESC;

-- Expected Output:
-- | first_name | salary |
-- |------------|--------|
-- | Rahul      | 82000  |
-- | Amit       | 75000  |
-- | Ananya     | 70000  |
-- | Vikram     | 60000  |
-- | Priya      | 55000  |
-- | Karan      | 52000  |
-- | Sneha      | 48000  |


-- ************************************************************
-- 3. UNIQUE INDEX
-- ************************************************************
-- A UNIQUE INDEX enforces that no two rows can have the same
-- value in the indexed column(s). It also speeds up lookups.
--
-- Note: Creating a UNIQUE constraint automatically creates
-- a unique index. You can also create one explicitly:

CREATE UNIQUE INDEX idx_employees_email_unique
ON employees (email);

-- This query uses the unique index for a fast lookup:
SELECT employee_id, first_name, email
FROM employees
WHERE email = 'rahul.gupta@mail.com';

-- Expected Output:
-- | employee_id | first_name | email                |
-- |-------------|------------|----------------------|
-- | 3           | Rahul      | rahul.gupta@mail.com |

-- Trying to insert a duplicate email will now FAIL:
-- INSERT INTO employees (first_name, last_name, email)
-- VALUES ('Test', 'User', 'rahul.gupta@mail.com');
-- ERROR: duplicate key value violates unique constraint "idx_employees_email_unique"


-- ************************************************************
-- 4. IF NOT EXISTS — Safely creating indexes
-- ************************************************************
-- Use IF NOT EXISTS to avoid errors when the index already exists.
-- This is especially useful in migration scripts.

CREATE INDEX IF NOT EXISTS idx_employees_hire_date
ON employees (hire_date);

-- Re-running the same command won't cause an error:
CREATE INDEX IF NOT EXISTS idx_employees_hire_date
ON employees (hire_date);
-- NOTICE: relation "idx_employees_hire_date" already exists, skipping

-- Query using the hire_date index:
SELECT first_name, hire_date
FROM employees
WHERE hire_date >= '2022-01-01'
ORDER BY hire_date;

-- Expected Output:
-- | first_name | hire_date  |
-- |------------|------------|
-- | Priya      | 2022-07-01 |
-- | Ananya     | 2022-09-12 |
-- | Sneha      | 2023-02-20 |
-- | Karan      | 2023-06-01 |


-- ************************************************************
-- 5. Viewing existing indexes (pg_indexes system view)
-- ************************************************************
-- PostgreSQL stores index metadata in the pg_indexes catalog view.

-- List all indexes on the employees table:
SELECT
    indexname   AS index_name,
    indexdef    AS index_definition
FROM pg_indexes
WHERE tablename = 'employees'
ORDER BY indexname;

-- Expected Output:
-- | index_name                    | index_definition                                                  |
-- |-------------------------------|-------------------------------------------------------------------|
-- | employees_pkey                | CREATE UNIQUE INDEX employees_pkey ON public.employees ...        |
-- | idx_employees_department      | CREATE INDEX idx_employees_department ON public.employees ...     |
-- | idx_employees_email_unique    | CREATE UNIQUE INDEX idx_employees_email_unique ON public.emp...   |
-- | idx_employees_hire_date       | CREATE INDEX idx_employees_hire_date ON public.employees ...      |
-- | idx_employees_salary          | CREATE INDEX idx_employees_salary ON public.employees ...         |
--
-- Note: "employees_pkey" is the auto-created index for the PRIMARY KEY.

-- You can also check index size:
SELECT
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes
WHERE tablename = 'employees'
ORDER BY indexname;


-- ************************************************************
-- 6. DROP INDEX — Removing an index
-- ************************************************************
-- Syntax:
--   DROP INDEX index_name;
--   DROP INDEX IF EXISTS index_name;

-- Remove the salary index:
DROP INDEX idx_employees_salary;

-- Safe removal (no error if index doesn't exist):
DROP INDEX IF EXISTS idx_employees_salary;
-- NOTICE: index "idx_employees_salary" does not exist, skipping

-- Verify it's gone:
SELECT indexname
FROM pg_indexes
WHERE tablename = 'employees'
  AND indexname = 'idx_employees_salary';
-- Expected Output: (empty — 0 rows)


-- ************************************************************
-- 7. CREATE INDEX CONCURRENTLY — Non-blocking index creation
-- ************************************************************
-- By default, CREATE INDEX locks the table against writes.
-- In production, use CONCURRENTLY to avoid blocking:

CREATE INDEX CONCURRENTLY idx_employees_last_name
ON employees (last_name);

-- Important notes on CONCURRENTLY:
--   • Takes longer to build than a regular CREATE INDEX
--   • Does NOT lock the table for writes during creation
--   • Cannot be run inside a transaction block (BEGIN...COMMIT)
--   • If it fails, it leaves an INVALID index that must be dropped

-- Query using the new index:
SELECT employee_id, first_name, last_name
FROM employees
WHERE last_name = 'Gupta';

-- Expected Output:
-- | employee_id | first_name | last_name |
-- |-------------|------------|-----------|
-- | 3           | Rahul      | Gupta     |


-- ************************************************************
-- 8. Automatic indexes — PRIMARY KEY and UNIQUE constraints
-- ************************************************************
-- PostgreSQL automatically creates indexes for:
--   1. PRIMARY KEY columns  → unique B-Tree index
--   2. UNIQUE constraints   → unique B-Tree index
--
-- You do NOT need to manually create indexes on these columns.

-- Demonstrate: the PK index already allows fast lookups:
SELECT *
FROM employees
WHERE employee_id = 5;

-- Expected Output:
-- | employee_id | first_name | last_name | department | salary | hire_date  | email                 | is_active |
-- |-------------|------------|-----------|------------|--------|------------|-----------------------|-----------|
-- | 5           | Vikram     | Singh     | Marketing  | 60000  | 2021-11-05 | vikram.singh@mail.com | TRUE      |
--
-- EXPLAIN would show: "Index Scan using employees_pkey"

-- Another example with a UNIQUE constraint on a new table:
CREATE TABLE products (
    product_id   SERIAL PRIMARY KEY,
    product_code VARCHAR(20) UNIQUE,       -- auto-creates a unique index
    product_name VARCHAR(100) NOT NULL,
    price        NUMERIC(10,2)
);

-- Check auto-created indexes:
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'products';

-- Expected Output:
-- | indexname              | indexdef                                                         |
-- |------------------------|------------------------------------------------------------------|
-- | products_pkey          | CREATE UNIQUE INDEX products_pkey ON public.products ...          |
-- | products_product_code_key | CREATE UNIQUE INDEX products_product_code_key ON public.pro... |


-- ============================================================
-- WHEN NOT TO CREATE INDEXES
-- ============================================================
--
-- Indexes are NOT always helpful. Avoid them when:
--
-- 1. SMALL TABLES (< ~1,000 rows)
--    → A sequential scan is just as fast or faster.
--    → The overhead of maintaining the index isn't worth it.
--
-- 2. FREQUENTLY UPDATED COLUMNS
--    → Every INSERT, UPDATE, or DELETE must also update the index.
--    → If the column changes constantly, the index slows writes.
--    → Example: a "last_login" timestamp updated on every request.
--
-- 3. LOW-SELECTIVITY (LOW-CARDINALITY) COLUMNS
--    → Columns with very few distinct values (e.g., gender, is_active)
--    → An index on a boolean column rarely helps because ~50% of
--      rows match each value — PostgreSQL prefers a Seq Scan.
--    → Exception: partial indexes can help here (see Composite_Indexes.sql).
--
-- 4. COLUMNS NOT USED IN WHERE/JOIN/ORDER BY
--    → If no queries filter or sort on the column, an index is wasted space.
--
-- 5. WRITE-HEAVY TABLES WITH RARE READS
--    → Logging tables, audit trails — mostly INSERT, rarely SELECT.
--    → Indexes slow down every write with no read benefit.
--
-- ============================================================


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. An index is a data structure (default: B-Tree) that speeds up
--    data retrieval — like a book index speeds up finding topics.
-- 2. CREATE INDEX idx_name ON table(column); — basic syntax.
-- 3. UNIQUE INDEX enforces uniqueness AND speeds up lookups.
-- 4. PRIMARY KEY and UNIQUE constraints auto-create indexes.
-- 5. Use IF NOT EXISTS and CONCURRENTLY for production safety.
-- 6. Query pg_indexes to see all indexes on a table.
-- 7. DROP INDEX removes an index; use IF EXISTS for safety.
-- 8. Don't over-index! Avoid indexes on small tables, boolean
--    columns, rarely-queried columns, and write-heavy tables.
-- ============================================================
