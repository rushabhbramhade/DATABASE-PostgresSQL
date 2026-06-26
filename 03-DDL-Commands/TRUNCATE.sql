-- ============================================================
-- TRUNCATE.sql — Removing All Data from Tables in PostgreSQL
-- ============================================================
-- Covers: TRUNCATE TABLE, CASCADE, RESTART IDENTITY,
--         CONTINUE IDENTITY, TRUNCATE vs DELETE comparison,
--         and practical development/testing use cases
-- ============================================================


-- ************************************************************
-- SETUP: Sample Tables for Demonstration
-- ************************************************************

CREATE TABLE IF NOT EXISTS departments (
    department_id   SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    location        VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS employees (
    employee_id   SERIAL PRIMARY KEY,
    first_name    VARCHAR(50) NOT NULL,
    last_name     VARCHAR(50) NOT NULL,
    email         VARCHAR(100) UNIQUE,
    salary        NUMERIC(10, 2),
    department_id INTEGER REFERENCES departments(department_id)
);

CREATE TABLE IF NOT EXISTS orders (
    order_id      SERIAL PRIMARY KEY,
    employee_id   INTEGER REFERENCES employees(employee_id),
    order_date    DATE DEFAULT CURRENT_DATE,
    total_amount  NUMERIC(12, 2)
);

-- Insert sample data
INSERT INTO departments (department_name, location) VALUES
    ('Engineering', 'Building A'),
    ('Marketing', 'Building B'),
    ('Sales', 'Building C');

INSERT INTO employees (first_name, last_name, email, salary, department_id) VALUES
    ('Aarav',  'Sharma',  'aarav@example.com',  85000, 1),
    ('Priya',  'Patel',   'priya@example.com',  72000, 2),
    ('Rohan',  'Gupta',   'rohan@example.com',  68000, 1),
    ('Sneha',  'Reddy',   'sneha@example.com',  91000, 3),
    ('Vikram', 'Singh',   'vikram@example.com', 78000, 2);

INSERT INTO orders (employee_id, order_date, total_amount) VALUES
    (1, '2026-01-15', 1500.00),
    (1, '2026-02-20', 2300.00),
    (4, '2026-03-10', 890.00),
    (2, '2026-04-05', 4200.00);

-- Verify data:
-- SELECT COUNT(*) FROM departments;  →  3
-- SELECT COUNT(*) FROM employees;    →  5
-- SELECT COUNT(*) FROM orders;       →  4


-- ************************************************************
-- 1. TRUNCATE TABLE — Basic Usage
-- ************************************************************

TRUNCATE TABLE departments;

-- ⚠️  This will FAIL because employees has a FK referencing departments!
-- ERROR: cannot truncate a table referenced in a foreign key constraint
-- DETAIL: Table "employees" references "departments".

-- To truncate a table with FKs pointing to it, use CASCADE (see section 3)


-- Truncate a table with no dependents
CREATE TABLE IF NOT EXISTS logs (
    log_id    SERIAL PRIMARY KEY,
    message   TEXT,
    log_date  TIMESTAMP DEFAULT NOW()
);

INSERT INTO logs (message) VALUES ('App started'), ('User logged in'), ('Error occurred');

-- Before: SELECT COUNT(*) FROM logs;  →  3
TRUNCATE TABLE logs;
-- After:  SELECT COUNT(*) FROM logs;  →  0

-- The table structure, columns, indexes, and constraints all remain intact.
-- Only the DATA is removed.


-- ************************************************************
-- 2. TRUNCATE vs DELETE — Key Differences
-- ************************************************************
/*
  ┌──────────────────────────┬──────────────────────┬──────────────────────┐
  │ Feature                  │ DELETE               │ TRUNCATE             │
  ├──────────────────────────┼──────────────────────┼──────────────────────┤
  │ Removes                  │ Rows (with WHERE)    │ ALL rows (no WHERE)  │
  │ Can filter rows?         │ ✅ Yes (WHERE)       │ ❌ No                │
  │ Speed (large tables)     │ Slow (row by row)    │ Very fast            │
  │ How it works             │ Deletes each row     │ Deallocates pages    │
  │ Fires row triggers?      │ ✅ Yes               │ ❌ No                │
  │ Fires statement triggers?│ ✅ Yes               │ ✅ Yes (BEFORE/AFTER)│
  │ WAL logging              │ Logs every row       │ Minimal logging      │
  │ MVCC dead tuples?        │ ✅ Yes (needs VACUUM)│ ❌ No                │
  │ Resets SERIAL/IDENTITY?  │ ❌ No                │ Optional (RESTART)   │
  │ Can be rolled back?      │ ✅ Yes               │ ✅ Yes (PostgreSQL!) │
  │ Supports RETURNING?      │ ✅ Yes               │ ❌ No                │
  │ Respects FK constraints? │ ✅ Yes               │ ✅ Yes (or CASCADE)  │
  │ Table locks              │ ROW EXCLUSIVE        │ ACCESS EXCLUSIVE     │
  └──────────────────────────┴──────────────────────┴──────────────────────┘

  NOTE: In PostgreSQL, TRUNCATE IS transactional (can be rolled back).
        This is different from MySQL/SQL Server where TRUNCATE may not
        be fully transactional.
*/

-- Speed comparison example:
-- Table with 1 million rows:
--   DELETE FROM big_table;     →  ~30 seconds (row-by-row, WAL logging)
--   TRUNCATE TABLE big_table;  →  ~0.01 seconds (instant, no row processing)


-- ************************************************************
-- 3. TRUNCATE with CASCADE
-- ************************************************************
-- CASCADE also truncates tables that have FK references to this table

-- This works even though employees references departments:
TRUNCATE TABLE departments CASCADE;

-- Expected:
-- NOTICE: truncate cascades to table "employees"
-- NOTICE: truncate cascades to table "orders"
--
-- ALL THREE tables are emptied:
-- departments → 0 rows (directly truncated)
-- employees   → 0 rows (cascaded because FK references departments)
-- orders      → 0 rows (cascaded because FK references employees)

-- ⚠️  CASCADE can clear more tables than you expect!
--     Always check the FK chain before using CASCADE.

-- Re-insert sample data for further examples
INSERT INTO departments (department_name, location) VALUES
    ('Engineering', 'Building A'),
    ('Marketing', 'Building B');

INSERT INTO employees (first_name, last_name, email, salary, department_id) VALUES
    ('Aarav', 'Sharma', 'aarav@example.com', 85000, 1),
    ('Priya', 'Patel',  'priya@example.com', 72000, 2);


-- ************************************************************
-- 4. TRUNCATE with RESTART IDENTITY
-- ************************************************************
-- Resets SERIAL / IDENTITY counters back to their starting value

-- Before truncate:
-- SELECT MAX(employee_id) FROM employees;  →  7 (or whatever the current max is)

TRUNCATE TABLE employees CASCADE;

-- After truncate without RESTART: next INSERT gives employee_id = 8 (continues)

-- Re-insert data
INSERT INTO departments (department_name, location) VALUES
    ('Engineering', 'Building A');

INSERT INTO employees (first_name, last_name, email, salary, department_id) VALUES
    ('Aarav', 'Sharma', 'aarav@example.com', 85000, 1);

-- Now truncate WITH RESTART IDENTITY:
TRUNCATE TABLE employees RESTART IDENTITY CASCADE;

-- After truncate with RESTART: next INSERT gives employee_id = 1 (reset!)
INSERT INTO employees (first_name, last_name, email, salary, department_id) VALUES
    ('New', 'Employee', 'new@example.com', 50000, 1);

-- SELECT * FROM employees;
-- employee_id | first_name | last_name | email             | salary  | department_id
-- ----------- | ---------- | --------- | ----------------- | ------- | -------------
-- 1           | New        | Employee  | new@example.com   | 50000   | 1

-- RESTART IDENTITY is great for testing — gives clean, predictable IDs


-- ************************************************************
-- 5. TRUNCATE with CONTINUE IDENTITY (Default)
-- ************************************************************
-- Keeps the sequence counter at its current value

TRUNCATE TABLE logs CONTINUE IDENTITY;

-- This is the DEFAULT behavior — same as just writing TRUNCATE TABLE logs;
-- The next INSERT will use the next sequence value (not reset to 1)


-- ************************************************************
-- 6. TRUNCATE Multiple Tables at Once
-- ************************************************************

-- Truncate several tables in one command
TRUNCATE TABLE employees, departments, orders RESTART IDENTITY;

-- Expected: All three tables are emptied in a single operation
-- All their SERIAL sequences are reset to initial values
-- This is atomic — either all tables are truncated or none are


-- ************************************************************
-- 7. TRUNCATE Inside a Transaction (Rollback Support)
-- ************************************************************
-- PostgreSQL supports ROLLBACK for TRUNCATE — a major safety feature!

BEGIN;

-- Check before
SELECT COUNT(*) FROM employees;  -- Suppose this returns 5

TRUNCATE TABLE employees CASCADE;

-- Check after truncate
SELECT COUNT(*) FROM employees;  -- Returns 0

-- Oops! We didn't mean to do that!
ROLLBACK;

-- Check after rollback
SELECT COUNT(*) FROM employees;  -- Returns 5 again! Data is restored!

-- This is PostgreSQL-specific — many other databases cannot rollback TRUNCATE


-- ************************************************************
-- 8. When to Use TRUNCATE — Development & Testing Scenarios
-- ************************************************************

-- ─────────────────────────────────────────────
-- Scenario A: Resetting a test database
-- ─────────────────────────────────────────────
-- After running integration tests, clean up all test data:

-- Truncate in FK-safe order (children first, then parents)
TRUNCATE TABLE orders RESTART IDENTITY;
TRUNCATE TABLE employees RESTART IDENTITY;
TRUNCATE TABLE departments RESTART IDENTITY;

-- Or use CASCADE on the parent table:
TRUNCATE TABLE departments RESTART IDENTITY CASCADE;

-- ─────────────────────────────────────────────
-- Scenario B: Refreshing staging data
-- ─────────────────────────────────────────────
-- Clear staging tables before loading fresh data from production:

CREATE TABLE IF NOT EXISTS staging_customers (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(100),
    email      VARCHAR(100),
    imported_at TIMESTAMP DEFAULT NOW()
);

-- Clear old staging data
TRUNCATE TABLE staging_customers RESTART IDENTITY;

-- Load fresh data
-- COPY staging_customers (name, email) FROM '/path/to/export.csv' CSV HEADER;

-- ─────────────────────────────────────────────
-- Scenario C: Clearing log/audit tables
-- ─────────────────────────────────────────────
-- Periodically clear large log tables that don't need historical data:

TRUNCATE TABLE logs RESTART IDENTITY;

-- Much faster than DELETE for tables with millions of log entries

-- ─────────────────────────────────────────────
-- Scenario D: Resetting demo environment
-- ─────────────────────────────────────────────
BEGIN;
    TRUNCATE TABLE orders, employees, departments RESTART IDENTITY CASCADE;

    -- Re-seed with demo data
    INSERT INTO departments (department_name, location) VALUES
        ('Engineering', 'Floor 3'),
        ('Marketing', 'Floor 2'),
        ('HR', 'Floor 1');

    INSERT INTO employees (first_name, last_name, email, salary, department_id) VALUES
        ('Demo', 'User1', 'demo1@example.com', 75000, 1),
        ('Demo', 'User2', 'demo2@example.com', 65000, 2),
        ('Demo', 'User3', 'demo3@example.com', 70000, 3);
COMMIT;


-- ************************************************************
-- 9. When NOT to Use TRUNCATE
-- ************************************************************
/*
  ❌ Don't use TRUNCATE when:

  1. You need to delete SPECIFIC rows    → Use DELETE with WHERE
  2. You need RETURNING clause           → Use DELETE ... RETURNING *
  3. You need row-level triggers to fire  → Use DELETE
  4. Other sessions need to read the table → TRUNCATE locks exclusively
  5. You need to keep some data           → Use DELETE with WHERE

  ✅ Use TRUNCATE when:

  1. You want to remove ALL rows quickly
  2. You're resetting test/dev data
  3. You want to reset SERIAL sequences (RESTART IDENTITY)
  4. You're clearing staging/temp tables
  5. You don't need row-level trigger execution
*/


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
/*
  1. TRUNCATE removes ALL rows instantly — much faster than DELETE.
  2. TRUNCATE is transactional in PostgreSQL — you CAN rollback!
  3. Use RESTART IDENTITY to reset SERIAL counters back to 1.
  4. Use CASCADE to truncate tables in an FK dependency chain.
  5. TRUNCATE acquires an ACCESS EXCLUSIVE lock — blocks all other access.
  6. Row-level triggers do NOT fire with TRUNCATE (statement-level do).
  7. TRUNCATE does not generate dead tuples — no VACUUM needed after.
  8. For selective deletion, always use DELETE with WHERE instead.
  9. TRUNCATE multiple tables in one command for atomic cleanup.
 10. Perfect for test resets, staging refreshes, and log cleanup.
*/
