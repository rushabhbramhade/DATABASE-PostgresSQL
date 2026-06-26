-- ============================================================
-- FILE: CTEs.sql
-- TOPIC: Common Table Expressions (WITH Clause) in PostgreSQL
-- ============================================================
-- A CTE (Common Table Expression) is a temporary, named result
-- set defined within a WITH clause. It exists only for the
-- duration of the single query it belongs to.
--
-- Think of it as an "inline view" or a "query-scoped temp table"
-- that makes complex queries readable and maintainable.
--
-- KEY POINTS:
--   • Defined with the WITH keyword before SELECT/INSERT/UPDATE/DELETE
--   • Exists only for that one statement — not stored anywhere
--   • Multiple CTEs can be chained in one WITH block
--   • Recursive CTEs can traverse hierarchies and generate series
--   • CTEs can wrap data-modifying statements (INSERT/UPDATE/DELETE)
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
-- EXAMPLE 1: Basic CTE Syntax
-- ============================================================
-- Syntax:
--   WITH cte_name AS (
--       SELECT ...
--   )
--   SELECT ... FROM cte_name;
-- ============================================================

WITH high_earners AS (
    SELECT
        employee_id,
        first_name || ' ' || last_name AS full_name,
        salary
    FROM employees
    WHERE salary > 70000
)
SELECT full_name, salary
FROM high_earners
ORDER BY salary DESC;

-- Expected Output:
-- full_name       | salary
-- ----------------|----------
-- Alice Johnson   | 95000.00
-- Eve Davis       | 82000.00
-- Bob Smith       | 72000.00


-- ============================================================
-- EXAMPLE 2: CTE vs Subquery — Readability Comparison
-- ============================================================
-- Goal: Find employees whose salary is above the company average.
-- ============================================================

-- ❌ SUBQUERY VERSION (harder to read when nested deeper)
SELECT
    first_name || ' ' || last_name AS full_name,
    salary,
    salary - (SELECT AVG(salary) FROM employees) AS above_avg_by
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees)
ORDER BY salary DESC;

-- ✅ CTE VERSION (same result, much clearer)
WITH avg_salary AS (
    SELECT AVG(salary) AS company_avg
    FROM employees
)
SELECT
    e.first_name || ' ' || e.last_name AS full_name,
    e.salary,
    ROUND(e.salary - a.company_avg, 2) AS above_avg_by
FROM employees e
CROSS JOIN avg_salary a
WHERE e.salary > a.company_avg
ORDER BY e.salary DESC;

-- Expected Output:
-- full_name      | salary   | above_avg_by
-- ---------------|----------|-------------
-- Alice Johnson  | 95000.00 | 20600.00
-- Eve Davis      | 82000.00 |  7600.00
-- Bob Smith      | 72000.00 | -2400.00  ← (only if > avg; depends on data)

-- Note: Both versions produce the same result.
-- CTEs win when you have 3+ levels of nesting.


-- ============================================================
-- EXAMPLE 3: Multiple CTEs in One Query
-- ============================================================
-- You can define several CTEs separated by commas.
-- Later CTEs can reference earlier ones.
-- ============================================================

WITH
dept_stats AS (
    SELECT
        department_id,
        COUNT(*)              AS emp_count,
        ROUND(AVG(salary), 2) AS avg_salary
    FROM employees
    GROUP BY department_id
),
dept_orders AS (
    SELECT
        e.department_id,
        COUNT(o.order_id)          AS order_count,
        COALESCE(SUM(o.total_amount), 0) AS total_revenue
    FROM employees e
    LEFT JOIN orders o ON e.employee_id = o.employee_id
    GROUP BY e.department_id
)
SELECT
    d.department_name,
    ds.emp_count,
    ds.avg_salary,
    do_.order_count,
    do_.total_revenue
FROM departments d
JOIN dept_stats ds  ON d.department_id = ds.department_id
JOIN dept_orders do_ ON d.department_id = do_.department_id
ORDER BY do_.total_revenue DESC;

-- Expected Output:
-- department_name  | emp_count | avg_salary | order_count | total_revenue
-- -----------------|-----------|------------|-------------|-------------
-- Sales            | 2         | 61500.00   | 6           | 112700.00
-- Engineering      | 2         | 83500.00   | 0           |      0.00
-- Human Resources  | 1         | 82000.00   | 0           |      0.00


-- ============================================================
-- EXAMPLE 4: Recursive CTE — Number Sequence
-- ============================================================
-- A recursive CTE has TWO parts joined by UNION ALL:
--   1. BASE CASE (anchor) — runs once, produces initial rows
--   2. RECURSIVE CASE     — runs repeatedly, referencing itself,
--                           until it returns zero new rows
--
-- Syntax:
--   WITH RECURSIVE cte_name AS (
--       -- Base case
--       SELECT ...
--       UNION ALL
--       -- Recursive case (references cte_name)
--       SELECT ... FROM cte_name WHERE ...
--   )
--   SELECT * FROM cte_name;
-- ============================================================

WITH RECURSIVE numbers AS (
    -- Base case: start at 1
    SELECT 1 AS n

    UNION ALL

    -- Recursive case: add 1 until we reach 10
    SELECT n + 1
    FROM numbers
    WHERE n < 10
)
SELECT n FROM numbers;

-- Expected Output:
-- n
-- ---
-- 1
-- 2
-- 3
-- 4
-- 5
-- 6
-- 7
-- 8
-- 9
-- 10


-- ============================================================
-- EXAMPLE 5: Recursive CTE — Employee Hierarchy (Org Chart)
-- ============================================================
-- Our employees table has a manager_id column that creates
-- a tree structure. Recursive CTEs are perfect for traversing it.
--
-- Hierarchy:
--   Alice (CEO, no manager)
--   ├── Bob (reports to Alice)
--   ├── Carol (reports to Alice)
--   │   └── David (reports to Carol)
--   └── Eve (reports to Alice)
-- ============================================================

WITH RECURSIVE org_chart AS (
    -- Base case: start with top-level employees (no manager)
    SELECT
        employee_id,
        first_name || ' ' || last_name AS employee_name,
        manager_id,
        0 AS level,
        first_name || ' ' || last_name AS path
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive case: find each employee's direct reports
    SELECT
        e.employee_id,
        e.first_name || ' ' || e.last_name,
        e.manager_id,
        oc.level + 1,
        oc.path || ' → ' || e.first_name || ' ' || e.last_name
    FROM employees e
    JOIN org_chart oc ON e.manager_id = oc.employee_id
)
SELECT
    REPEAT('  ', level) || employee_name AS org_tree,
    level,
    path
FROM org_chart
ORDER BY path;

-- Expected Output:
-- org_tree            | level | path
-- --------------------|-------|------------------------------------
-- Alice Johnson       | 0     | Alice Johnson
--   Bob Smith         | 1     | Alice Johnson → Bob Smith
--   Carol Williams    | 1     | Alice Johnson → Carol Williams
--     David Brown     | 2     | Alice Johnson → Carol Williams → David Brown
--   Eve Davis         | 1     | Alice Johnson → Eve Davis


-- ============================================================
-- EXAMPLE 6: Recursive CTE — Fibonacci Sequence
-- ============================================================
-- Generating the first 15 Fibonacci numbers using recursion.
-- ============================================================

WITH RECURSIVE fibonacci AS (
    -- Base case: first two Fibonacci numbers
    SELECT
        1 AS position,
        0::BIGINT AS fib_number,
        1::BIGINT AS next_number

    UNION ALL

    -- Recursive case
    SELECT
        position + 1,
        next_number,
        fib_number + next_number
    FROM fibonacci
    WHERE position < 15
)
SELECT position, fib_number
FROM fibonacci;

-- Expected Output:
-- position | fib_number
-- ---------|----------
-- 1        | 0
-- 2        | 1
-- 3        | 1
-- 4        | 2
-- 5        | 3
-- 6        | 5
-- 7        | 8
-- 8        | 13
-- 9        | 21
-- 10       | 34
-- 11       | 55
-- 12       | 89
-- 13       | 144
-- 14       | 233
-- 15       | 377


-- ============================================================
-- EXAMPLE 7: CTE for Data Modification (DELETE with RETURNING)
-- ============================================================
-- CTEs can wrap INSERT, UPDATE, or DELETE statements that use
-- the RETURNING clause. This lets you:
--   • Archive rows before deleting them
--   • Chain modifications (delete → insert into archive)
--   • Report what was changed
-- ============================================================

-- Create an archive table
CREATE TABLE IF NOT EXISTS orders_archive (
    LIKE orders INCLUDING ALL
);

-- Archive completed orders and delete them in ONE statement
WITH archived AS (
    DELETE FROM orders
    WHERE status = 'completed'
    RETURNING *
)
INSERT INTO orders_archive
SELECT * FROM archived;

-- Verify: archived rows are now in orders_archive
SELECT order_id, customer, status FROM orders_archive;

-- Expected Output:
-- order_id | customer           | status
-- ---------|--------------------|----------
-- 1        | Acme Corp          | completed
-- 2        | Globex Inc         | completed
-- 6        | Wayne Enterprises  | completed

-- Verify: completed orders are gone from the main table
SELECT order_id, customer, status FROM orders;

-- Expected Output (only non-completed remain):
-- order_id | customer           | status
-- ---------|--------------------|--------
-- 3        | Initech            | pending
-- 4        | Umbrella Corp      | shipped
-- 5        | Stark Industries   | pending


-- ============================================================
-- EXAMPLE 8: CTE for UPDATE with Summary Report
-- ============================================================
-- Give a 10% raise to employees in the Sales department and
-- report what changed — all in one statement.
-- ============================================================

WITH salary_updates AS (
    UPDATE employees
    SET salary = salary * 1.10
    WHERE department_id = 2
    RETURNING employee_id, first_name, last_name, salary AS new_salary
)
SELECT
    first_name || ' ' || last_name AS employee,
    new_salary,
    ROUND(new_salary / 1.10, 2) AS old_salary,
    ROUND(new_salary - (new_salary / 1.10), 2) AS raise_amount
FROM salary_updates;

-- Expected Output:
-- employee       | new_salary | old_salary | raise_amount
-- ---------------|------------|------------|-------------
-- Carol Williams | 74800.00   | 68000.00   | 6800.00
-- David Brown    | 60500.00   | 55000.00   | 5500.00


-- ============================================================
-- PERFORMANCE NOTES
-- ============================================================
--
-- PostgreSQL 11 and earlier:
--   CTEs were ALWAYS an "optimization barrier." The CTE query
--   was executed separately, its results materialized into a
--   temp buffer, and the outer query could NOT push filters
--   or optimizations into the CTE. This could hurt performance.
--
-- PostgreSQL 12+ (MAJOR IMPROVEMENT):
--   CTEs are now INLINED by default if:
--     • The CTE is non-recursive
--     • The CTE has no side effects (not a data-modifying CTE)
--     • The CTE is referenced only ONCE in the outer query
--
--   This means the planner can push WHERE clauses, join
--   conditions, and other optimizations INTO the CTE — just
--   like a subquery. Performance is now equivalent.
--
-- To FORCE the old materialized behavior (PostgreSQL 12+):
--   WITH cte_name AS MATERIALIZED (
--       SELECT ...
--   )
--
-- To FORCE inlining (PostgreSQL 12+):
--   WITH cte_name AS NOT MATERIALIZED (
--       SELECT ...
--   )
--
-- ============================================================

-- Example: Explicit materialization hints (PostgreSQL 12+)

-- Force materialization (useful when the CTE is expensive and
-- referenced multiple times — avoid re-computing it)
WITH dept_totals AS MATERIALIZED (
    SELECT department_id, SUM(salary) AS total_salary
    FROM employees
    GROUP BY department_id
)
SELECT * FROM dept_totals WHERE total_salary > 100000;

-- Force inlining (useful when you want the planner to push
-- filters from the outer query into the CTE)
WITH dept_totals AS NOT MATERIALIZED (
    SELECT department_id, SUM(salary) AS total_salary
    FROM employees
    GROUP BY department_id
)
SELECT * FROM dept_totals WHERE total_salary > 100000;

-- Both return the same result, but the execution plan differs.
-- Expected Output:
-- department_id | total_salary
-- --------------|-------------
-- 1             | 167000.00
-- 2             | 135300.00


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. CTEs use the WITH keyword to create temporary named result sets.
-- 2. They make complex queries MUCH more readable than nested subqueries.
-- 3. Multiple CTEs can be chained — later ones can reference earlier ones.
-- 4. Recursive CTEs (WITH RECURSIVE) traverse trees, generate series,
--    and solve hierarchical problems.
-- 5. Data-modifying CTEs (INSERT/UPDATE/DELETE with RETURNING) allow
--    powerful multi-step operations in a single statement.
-- 6. In PostgreSQL 12+, non-recursive CTEs referenced once are
--    automatically inlined — no performance penalty vs subqueries.
-- 7. Use AS MATERIALIZED / AS NOT MATERIALIZED (PG 12+) for
--    explicit control over CTE optimization behavior.
-- 8. Always include a termination condition in recursive CTEs
--    to prevent infinite loops.
-- ============================================================
