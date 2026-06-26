-- ============================================================
-- FILE: Views.sql
-- TOPIC: Regular Views in PostgreSQL
-- ============================================================
-- A VIEW is a virtual table based on a stored SELECT query.
-- It does NOT store data physically — every time you query a
-- view, PostgreSQL re-executes the underlying SELECT.
--
-- Think of it as a "saved query" you can reference by name,
-- just like a real table.
--
-- KEY POINTS:
--   • Views simplify complex queries (write once, reuse many times)
--   • Views provide access control (expose only certain columns)
--   • Views do NOT improve performance (re-executed each time)
--   • Some views are updatable (allow INSERT/UPDATE/DELETE)
-- ============================================================


-- ************************************************************
-- SAMPLE TABLES SETUP
-- ************************************************************

CREATE TABLE IF NOT EXISTS departments (
    department_id   SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS employees (
    employee_id   SERIAL PRIMARY KEY,
    first_name    VARCHAR(50)    NOT NULL,
    last_name     VARCHAR(50)    NOT NULL,
    email         VARCHAR(100)   UNIQUE NOT NULL,
    salary        NUMERIC(10,2)  NOT NULL,
    hire_date     DATE           NOT NULL DEFAULT CURRENT_DATE,
    department_id INT REFERENCES departments(department_id),
    manager_id    INT REFERENCES employees(employee_id)
);

CREATE TABLE IF NOT EXISTS orders (
    order_id     SERIAL PRIMARY KEY,
    employee_id  INT REFERENCES employees(employee_id),
    customer     VARCHAR(100)   NOT NULL,
    order_date   DATE           NOT NULL DEFAULT CURRENT_DATE,
    total_amount NUMERIC(10,2)  NOT NULL,
    status       VARCHAR(20)    DEFAULT 'pending'
);

INSERT INTO departments (department_name) VALUES
    ('Engineering'), ('Sales'), ('Human Resources')
ON CONFLICT DO NOTHING;

INSERT INTO employees (first_name, last_name, email, salary, hire_date, department_id, manager_id) VALUES
    ('Alice',  'Johnson',  'alice@company.com',   95000, '2020-03-15', 1, NULL),
    ('Bob',    'Smith',    'bob@company.com',     72000, '2021-06-01', 1, 1),
    ('Carol',  'Williams', 'carol@company.com',   68000, '2022-01-10', 2, 1),
    ('David',  'Brown',    'david@company.com',   55000, '2023-04-20', 2, 3),
    ('Eve',    'Davis',    'eve@company.com',     82000, '2021-09-05', 3, 1)
ON CONFLICT DO NOTHING;

INSERT INTO orders (employee_id, customer, order_date, total_amount, status) VALUES
    (3, 'Acme Corp',     '2025-01-15', 15000.00, 'completed'),
    (3, 'Globex Inc',    '2025-02-20', 23000.00, 'completed'),
    (4, 'Initech',       '2025-03-10',  8500.00, 'pending'),
    (4, 'Umbrella Corp', '2025-04-05', 12000.00, 'shipped'),
    (3, 'Stark Industries','2025-05-18', 45000.00, 'pending'),
    (4, 'Wayne Enterprises','2025-06-01', 9200.00, 'completed')
ON CONFLICT DO NOTHING;


-- ============================================================
-- EXAMPLE 1: CREATE VIEW — Basic View
-- ============================================================
-- Syntax:
--   CREATE VIEW view_name AS
--   SELECT columns FROM table WHERE condition;
-- ============================================================

CREATE VIEW v_active_employees AS
SELECT
    employee_id,
    first_name,
    last_name,
    email,
    salary,
    department_id
FROM employees;

-- Query the view just like a regular table
SELECT * FROM v_active_employees;

-- Expected Output:
-- employee_id | first_name | last_name | email               | salary   | department_id
-- ------------|------------|-----------|---------------------|----------|-------------
-- 1           | Alice      | Johnson   | alice@company.com   | 95000.00 | 1
-- 2           | Bob        | Smith     | bob@company.com     | 72000.00 | 1
-- 3           | Carol      | Williams  | carol@company.com   | 68000.00 | 2
-- 4           | David      | Brown     | david@company.com   | 55000.00 | 2
-- 5           | Eve        | Davis     | eve@company.com     | 82000.00 | 3


-- ============================================================
-- EXAMPLE 2: CREATE OR REPLACE VIEW
-- ============================================================
-- If the view already exists, this updates its definition
-- without needing to DROP it first.
-- Rule: The new query must return the same column names and
--       data types (you CAN add new columns at the end).
-- ============================================================

CREATE OR REPLACE VIEW v_active_employees AS
SELECT
    employee_id,
    first_name || ' ' || last_name AS full_name,
    email,
    salary,
    department_id
FROM employees;

SELECT * FROM v_active_employees;

-- Expected Output:
-- employee_id | full_name       | email               | salary   | department_id
-- ------------|-----------------|---------------------|----------|-------------
-- 1           | Alice Johnson   | alice@company.com   | 95000.00 | 1
-- 2           | Bob Smith       | bob@company.com     | 72000.00 | 1
-- 3           | Carol Williams  | carol@company.com   | 68000.00 | 2
-- 4           | David Brown     | david@company.com   | 55000.00 | 2
-- 5           | Eve Davis       | eve@company.com     | 82000.00 | 3


-- ============================================================
-- EXAMPLE 3: View to Simplify Complex Joins
-- ============================================================
-- Views shine when you have a multi-table JOIN that gets
-- repeated across many reports. Define it once, reuse it.
-- ============================================================

CREATE OR REPLACE VIEW v_employee_orders AS
SELECT
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    d.department_name,
    o.order_id,
    o.customer,
    o.order_date,
    o.total_amount,
    o.status
FROM employees e
JOIN departments d ON e.department_id = d.department_id
JOIN orders o      ON e.employee_id   = o.employee_id;

-- Now any report can query this view instead of re-writing the JOIN
SELECT
    employee_name,
    customer,
    total_amount
FROM v_employee_orders
WHERE status = 'completed'
ORDER BY total_amount DESC;

-- Expected Output:
-- employee_name  | customer    | total_amount
-- ---------------|-------------|------------
-- Carol Williams | Globex Inc  | 23000.00
-- Carol Williams | Acme Corp   | 15000.00
-- David Brown    | Wayne Ent.. |  9200.00


-- ============================================================
-- EXAMPLE 4: View for Access Control
-- ============================================================
-- Problem: HR needs employee names and departments, but
--          should NOT see salary or email (sensitive data).
-- Solution: Create a view that exposes only safe columns,
--           then GRANT access on the view (not the table).
-- ============================================================

CREATE OR REPLACE VIEW v_employee_directory AS
SELECT
    employee_id,
    first_name,
    last_name,
    d.department_name,
    hire_date
FROM employees e
JOIN departments d ON e.department_id = d.department_id;

-- Grant read-only access to a hypothetical 'hr_intern' role
-- GRANT SELECT ON v_employee_directory TO hr_intern;

SELECT * FROM v_employee_directory;

-- Expected Output:
-- employee_id | first_name | last_name | department_name  | hire_date
-- ------------|------------|-----------|------------------|----------
-- 1           | Alice      | Johnson   | Engineering      | 2020-03-15
-- 2           | Bob        | Smith     | Engineering      | 2021-06-01
-- 3           | Carol      | Williams  | Sales            | 2022-01-10
-- 4           | David      | Brown     | Sales            | 2023-04-20
-- 5           | Eve        | Davis     | Human Resources  | 2021-09-05


-- ============================================================
-- EXAMPLE 5: Updatable Views
-- ============================================================
-- A view is "automatically updatable" if it meets ALL of:
--   1. Based on exactly ONE table (no joins)
--   2. No DISTINCT, GROUP BY, HAVING, LIMIT, OFFSET
--   3. No aggregate functions or window functions
--   4. No set operations (UNION, INTERSECT, EXCEPT)
--
-- Through such a view, you can INSERT, UPDATE, and DELETE.
-- ============================================================

CREATE OR REPLACE VIEW v_sales_employees AS
SELECT
    employee_id,
    first_name,
    last_name,
    email,
    salary
FROM employees
WHERE department_id = 2;      -- Sales department only

-- 5a) UPDATE through the view
UPDATE v_sales_employees
SET salary = 60000
WHERE first_name = 'David';

-- Verify — salary changed in the base table
SELECT employee_id, first_name, salary
FROM employees
WHERE first_name = 'David';

-- Expected Output:
-- employee_id | first_name | salary
-- ------------|------------|--------
-- 4           | David      | 60000.00

-- 5b) INSERT through the view
INSERT INTO v_sales_employees (first_name, last_name, email, salary)
VALUES ('Frank', 'Miller', 'frank@company.com', 61000);

-- Note: department_id will be NULL because it's not in the view.
-- To prevent rows from "disappearing" from the view after insert,
-- use WITH CHECK OPTION (see Example 6).

-- 5c) DELETE through the view
DELETE FROM v_sales_employees WHERE first_name = 'Frank';


-- ============================================================
-- EXAMPLE 6: WITH CHECK OPTION
-- ============================================================
-- Prevents INSERT/UPDATE that would make the row invisible
-- to the view (i.e., violate the view's WHERE clause).
--
-- LOCAL  — checks only this view's WHERE
-- CASCADED (default) — checks this view AND any views it's built on
-- ============================================================

CREATE OR REPLACE VIEW v_sales_employees_safe AS
SELECT
    employee_id,
    first_name,
    last_name,
    email,
    salary,
    department_id
FROM employees
WHERE department_id = 2
WITH CASCADED CHECK OPTION;

-- This will SUCCEED (department_id = 2, matches the view filter)
-- INSERT INTO v_sales_employees_safe
--     (first_name, last_name, email, salary, department_id)
-- VALUES ('Grace', 'Lee', 'grace@company.com', 70000, 2);

-- This will FAIL with an error (department_id = 1 ≠ 2)
-- INSERT INTO v_sales_employees_safe
--     (first_name, last_name, email, salary, department_id)
-- VALUES ('Hank', 'Pym', 'hank@company.com', 90000, 1);
-- ERROR: new row violates check option for view "v_sales_employees_safe"


-- ============================================================
-- EXAMPLE 7: View with Aggregation (Read-Only)
-- ============================================================
-- Views with GROUP BY or aggregates are NOT updatable,
-- but they are extremely useful for dashboards and reports.
-- ============================================================

CREATE OR REPLACE VIEW v_department_salary_stats AS
SELECT
    d.department_name,
    COUNT(*)            AS employee_count,
    ROUND(AVG(e.salary), 2) AS avg_salary,
    MIN(e.salary)       AS min_salary,
    MAX(e.salary)       AS max_salary,
    SUM(e.salary)       AS total_salary
FROM employees e
JOIN departments d ON e.department_id = d.department_id
GROUP BY d.department_name;

SELECT * FROM v_department_salary_stats
ORDER BY avg_salary DESC;

-- Expected Output:
-- department_name  | employee_count | avg_salary | min_salary | max_salary | total_salary
-- -----------------|----------------|------------|------------|------------|-------------
-- Engineering      | 2              | 83500.00   | 72000.00   | 95000.00   | 167000.00
-- Human Resources  | 1              | 82000.00   | 82000.00   | 82000.00   |  82000.00
-- Sales            | 2              | 64000.00   | 60000.00   | 68000.00   | 128000.00


-- ============================================================
-- EXAMPLE 8: Dropping a View
-- ============================================================
-- Syntax:
--   DROP VIEW view_name;
--   DROP VIEW IF EXISTS view_name;
--   DROP VIEW view_name CASCADE;   -- also drops dependent views
-- ============================================================

-- Safe drop (no error if it doesn't exist)
DROP VIEW IF EXISTS v_active_employees;

-- CASCADE example: if view_b depends on view_a,
-- DROP VIEW view_a CASCADE;  will drop BOTH.

-- To see all views in your database:
SELECT table_name
FROM information_schema.views
WHERE table_schema = 'public'
ORDER BY table_name;


-- ============================================================
-- PERFORMANCE NOTE
-- ============================================================
-- Regular views are NOT cached. Every SELECT on a view
-- re-executes the underlying query. For expensive queries
-- that don't need real-time data, consider using a
-- MATERIALIZED VIEW instead (see Materialized_Views.sql).
--
-- However, PostgreSQL's query planner IS smart enough to
-- "flatten" simple views into the outer query, so there is
-- usually NO overhead compared to writing the query inline.
-- ============================================================


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. A VIEW is a named, stored SELECT query — a virtual table.
-- 2. CREATE OR REPLACE lets you modify a view without dropping it.
-- 3. Views simplify complex JOINs and repeated queries.
-- 4. Views provide security by exposing only certain columns.
-- 5. Simple, single-table views are auto-updatable (INSERT/UPDATE/DELETE).
-- 6. WITH CHECK OPTION prevents writes that would escape the view filter.
-- 7. Aggregate views (GROUP BY, COUNT, AVG) are read-only.
-- 8. Views are re-executed every time — they do NOT store data.
-- 9. DROP VIEW IF EXISTS is the safest way to remove a view.
-- ============================================================
