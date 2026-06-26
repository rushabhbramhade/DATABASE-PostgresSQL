-- ============================================================================
-- FILE:    Correlated_Subqueries.sql
-- TOPIC:   Correlated Subqueries in PostgreSQL
-- CHAPTER: 08 - Subqueries
-- ============================================================================
-- A correlated subquery is a subquery that REFERENCES a column from the
-- outer query. Unlike a non-correlated subquery, it CANNOT run independently.
--
-- KEY DIFFERENCE:
--   Non-correlated → Inner query runs ONCE, result reused for all outer rows.
--   Correlated     → Inner query runs ONCE PER ROW of the outer query.
--
-- HOW IT EXECUTES (for every row in the outer query):
--   1. PostgreSQL takes the current row from the outer query.
--   2. It passes the referenced column value INTO the inner query.
--   3. The inner query runs using that value and returns a result.
--   4. The outer query uses that result for the current row.
--   5. Move to the next outer row → repeat from Step 1.
--
-- PERFORMANCE NOTE:
--   Because the inner query runs once per outer row, correlated subqueries
--   can be SLOW on large tables. The optimizer may rewrite them internally,
--   but always consider whether a JOIN or CTE can achieve the same result.
-- ============================================================================


-- ============================================================================
-- SAMPLE TABLES (Same as Basic_Subqueries.sql — skip if already created)
-- ============================================================================

DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS employees;

CREATE TABLE employees (
    employee_id   SERIAL PRIMARY KEY,
    first_name    VARCHAR(50)  NOT NULL,
    last_name     VARCHAR(50)  NOT NULL,
    department    VARCHAR(50)  NOT NULL,
    salary        NUMERIC(10,2) NOT NULL,
    hire_date     DATE         NOT NULL
);

CREATE TABLE orders (
    order_id      SERIAL PRIMARY KEY,
    employee_id   INT          NOT NULL REFERENCES employees(employee_id),
    customer_name VARCHAR(100) NOT NULL,
    order_total   NUMERIC(10,2) NOT NULL,
    order_date    DATE         NOT NULL
);

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES
    ('Alice',   'Johnson',  'Engineering', 95000.00, '2021-03-15'),
    ('Bob',     'Smith',    'Engineering', 88000.00, '2022-07-01'),
    ('Charlie', 'Brown',    'HR',          62000.00, '2020-01-10'),
    ('Diana',   'Lee',      'HR',          58000.00, '2023-06-20'),
    ('Eve',     'Davis',    'Sales',       72000.00, '2019-11-05'),
    ('Frank',   'Wilson',   'Sales',       67000.00, '2021-09-12'),
    ('Grace',   'Martinez', 'Marketing',   71000.00, '2022-02-28'),
    ('Hank',    'Taylor',   'Marketing',   65000.00, '2023-01-15');

INSERT INTO orders (employee_id, customer_name, order_total, order_date)
VALUES
    (5, 'Acme Corp',      15000.00, '2024-01-10'),
    (5, 'Globex Inc',      8500.00, '2024-02-14'),
    (6, 'Initech',        12000.00, '2024-01-22'),
    (6, 'Umbrella Corp',   9200.00, '2024-03-05'),
    (1, 'Wayne Enterprises', 3500.00, '2024-02-20'),
    (2, 'Stark Industries', 4200.00, '2024-03-18');


-- ============================================================================
-- EXAMPLE 1: Classic Correlated Subquery — Salary > Department Average
-- ============================================================================
-- Goal: Find employees whose salary is ABOVE the average salary
--       of their OWN department.
--
-- WHY IT'S CORRELATED:
--   The inner query references "outer_emp.department" — a column from the
--   outer query. The average changes depending on which row is being evaluated.
--
-- HOW IT EXECUTES (row by row):
--   Row: Alice (Engineering) → AVG of Engineering = (95000+88000)/2 = 91500
--        95000 > 91500? YES → include Alice
--   Row: Bob (Engineering)   → AVG of Engineering = 91500
--        88000 > 91500? NO  → exclude Bob
--   Row: Charlie (HR)        → AVG of HR = (62000+58000)/2 = 60000
--        62000 > 60000? YES → include Charlie
--   Row: Diana (HR)          → AVG of HR = 60000
--        58000 > 60000? NO  → exclude Diana
--   ... and so on for every row.
-- ============================================================================

SELECT outer_emp.employee_id,
       outer_emp.first_name,
       outer_emp.last_name,
       outer_emp.department,
       outer_emp.salary
FROM   employees outer_emp
WHERE  outer_emp.salary > (
           SELECT AVG(inner_emp.salary)
           FROM   employees inner_emp
           WHERE  inner_emp.department = outer_emp.department   -- ← correlation!
       );

-- EXPECTED OUTPUT:
-- employee_id | first_name | last_name | department  |  salary
-- ------------+------------+-----------+-------------+----------
--           1 | Alice      | Johnson   | Engineering | 95000.00
--           3 | Charlie    | Brown     | HR          | 62000.00
--           5 | Eve        | Davis     | Sales       | 72000.00
--           7 | Grace      | Martinez  | Marketing   | 71000.00
--
-- Each of these employees earns more than their department's average.


-- ============================================================================
-- EXAMPLE 2: EXISTS — Find Employees Who Have Placed Orders
-- ============================================================================
-- Goal: List employees who have at least one entry in the orders table.
--
-- HOW EXISTS WORKS:
--   For each outer row, the inner query checks if ANY matching row exists.
--   It returns TRUE or FALSE — it does NOT return data.
--   EXISTS stops at the FIRST match (short-circuit), making it efficient.
--
-- HOW IT EXECUTES:
--   Row: Alice (id=1) → Is there any order with employee_id = 1? YES → include
--   Row: Bob (id=2)   → Is there any order with employee_id = 2? YES → include
--   Row: Charlie (id=3) → employee_id = 3 in orders? NO → exclude
--   Row: Diana (id=4)   → employee_id = 4 in orders? NO → exclude
--   Row: Eve (id=5)     → employee_id = 5 in orders? YES → include
--   Row: Frank (id=6)   → employee_id = 6 in orders? YES → include
--   Row: Grace (id=7)   → employee_id = 7 in orders? NO → exclude
--   Row: Hank (id=8)    → employee_id = 8 in orders? NO → exclude
-- ============================================================================

SELECT e.employee_id,
       e.first_name,
       e.last_name,
       e.department
FROM   employees e
WHERE  EXISTS (
           SELECT 1
           FROM   orders o
           WHERE  o.employee_id = e.employee_id   -- ← correlation!
       );

-- EXPECTED OUTPUT:
-- employee_id | first_name | last_name | department
-- ------------+------------+-----------+-------------
--           1 | Alice      | Johnson   | Engineering
--           2 | Bob        | Smith     | Engineering
--           5 | Eve        | Davis     | Sales
--           6 | Frank      | Wilson    | Sales
--
-- TIP: "SELECT 1" is a convention — EXISTS only checks for row existence,
--      it ignores what columns you select. SELECT * would work too.


-- ============================================================================
-- EXAMPLE 3: NOT EXISTS — Find Employees WITHOUT Orders
-- ============================================================================
-- Goal: List employees who have NEVER placed an order.
--
-- NOT EXISTS is the safe alternative to NOT IN.
-- It handles NULLs correctly (NOT IN does not — see Basic_Subqueries.sql).
--
-- HOW IT EXECUTES:
--   Exactly like EXISTS, but inverted: returns TRUE when no matching row found.
-- ============================================================================

SELECT e.employee_id,
       e.first_name,
       e.last_name,
       e.department
FROM   employees e
WHERE  NOT EXISTS (
           SELECT 1
           FROM   orders o
           WHERE  o.employee_id = e.employee_id   -- ← correlation!
       );

-- EXPECTED OUTPUT:
-- employee_id | first_name | last_name | department
-- ------------+------------+-----------+-----------
--           3 | Charlie    | Brown     | HR
--           4 | Diana      | Lee       | HR
--           7 | Grace      | Martinez  | Marketing
--           8 | Hank       | Taylor    | Marketing
--
-- BEST PRACTICE: Prefer NOT EXISTS over NOT IN when the subquery column
-- might contain NULLs. NOT EXISTS is also often faster because it
-- short-circuits once it finds (or doesn't find) a match.


-- ============================================================================
-- EXAMPLE 4: Correlated Subquery in SELECT — Per-Row Calculation
-- ============================================================================
-- Goal: For each employee, show how many orders they have placed
--       and their total order revenue.
--
-- HOW IT EXECUTES:
--   For each outer row, the subquery counts orders WHERE employee_id matches.
--   Row: Alice (id=1) → COUNT where employee_id=1 → 1 order,  SUM → 3500
--   Row: Bob (id=2)   → COUNT where employee_id=2 → 1 order,  SUM → 4200
--   Row: Charlie (id=3) → COUNT → 0 orders, SUM → NULL (COALESCE → 0)
--   ... and so on.
-- ============================================================================

SELECT e.employee_id,
       e.first_name,
       e.department,
       (
           SELECT COUNT(*)
           FROM   orders o
           WHERE  o.employee_id = e.employee_id
       ) AS order_count,
       (
           SELECT COALESCE(SUM(o.order_total), 0)
           FROM   orders o
           WHERE  o.employee_id = e.employee_id
       ) AS total_revenue
FROM   employees e
ORDER BY total_revenue DESC;

-- EXPECTED OUTPUT:
-- employee_id | first_name | department  | order_count | total_revenue
-- ------------+------------+-------------+-------------+--------------
--           5 | Eve        | Sales       |           2 |     23500.00
--           6 | Frank      | Sales       |           2 |     21200.00
--           2 | Bob        | Engineering |           1 |      4200.00
--           1 | Alice      | Engineering |           1 |      3500.00
--           3 | Charlie    | HR          |           0 |         0.00
--           4 | Diana      | HR          |           0 |         0.00
--           7 | Grace      | Marketing   |           0 |         0.00
--           8 | Hank       | Marketing   |           0 |         0.00


-- ============================================================================
-- EXAMPLE 5: EXISTS with Additional Conditions
-- ============================================================================
-- Goal: Find employees who have placed at least one order worth over $10,000.
--
-- HOW IT EXECUTES:
--   For each employee, check if any order with that employee_id has
--   order_total > 10000.
-- ============================================================================

SELECT e.employee_id,
       e.first_name,
       e.last_name,
       e.department
FROM   employees e
WHERE  EXISTS (
           SELECT 1
           FROM   orders o
           WHERE  o.employee_id = e.employee_id
             AND  o.order_total > 10000              -- ← additional filter
       );

-- EXPECTED OUTPUT:
-- employee_id | first_name | last_name | department
-- ------------+------------+-----------+-----------
--           5 | Eve        | Davis     | Sales
--           6 | Frank      | Wilson    | Sales
--
-- WHY? Eve has a 15000 order, Frank has a 12000 order. Alice's 3500 and
--       Bob's 4200 orders don't exceed 10000.


-- ============================================================================
-- EXAMPLE 6: Correlated Subquery to Find Department Maximum
-- ============================================================================
-- Goal: Find the highest-paid employee in each department.
--       (This is a classic pattern — often replaced by window functions.)
--
-- HOW IT EXECUTES:
--   Row: Alice (Engineering, 95000)
--        → MAX salary in Engineering = 95000
--        → 95000 = 95000? YES → include
--   Row: Bob (Engineering, 88000)
--        → MAX salary in Engineering = 95000
--        → 88000 = 95000? NO → exclude
--   ... and so on per row.
-- ============================================================================

SELECT e.employee_id,
       e.first_name,
       e.department,
       e.salary
FROM   employees e
WHERE  e.salary = (
           SELECT MAX(inner_e.salary)
           FROM   employees inner_e
           WHERE  inner_e.department = e.department   -- ← correlation!
       );

-- EXPECTED OUTPUT:
-- employee_id | first_name | department  |  salary
-- ------------+------------+-------------+----------
--           1 | Alice      | Engineering | 95000.00
--           3 | Charlie    | HR          | 62000.00
--           5 | Eve        | Sales       | 72000.00
--           7 | Grace      | Marketing   | 71000.00


-- ============================================================================
-- COMPARISON: Correlated Subquery vs. JOIN (Same Result)
-- ============================================================================
-- The EXISTS query from Example 2 can be rewritten as a JOIN.
-- Both produce the same result, but performance may differ.

-- ── Method A: Correlated Subquery (EXISTS) ──
SELECT e.employee_id, e.first_name, e.department
FROM   employees e
WHERE  EXISTS (
           SELECT 1 FROM orders o WHERE o.employee_id = e.employee_id
       );

-- ── Method B: JOIN (often preferred for readability and performance) ──
SELECT DISTINCT e.employee_id, e.first_name, e.department
FROM   employees e
JOIN   orders o ON e.employee_id = o.employee_id;

-- Both return the same 4 rows: Alice, Bob, Eve, Frank.
--
-- WHEN TO USE WHICH:
-- • EXISTS  → when you only need to CHECK for existence (yes/no).
--             No risk of duplicate rows. Short-circuits on first match.
-- • JOIN   → when you also need columns FROM the joined table.
--             Requires DISTINCT if employees have multiple orders.
-- • NOT EXISTS → safer than NOT IN for finding "missing" rows.
--                Always handles NULLs correctly.


-- ============================================================================
-- KEY TAKEAWAYS
-- ============================================================================
-- 1. A correlated subquery REFERENCES a column from the outer query.
--    It runs ONCE PER OUTER ROW (conceptually — the optimizer may improve this).
--
-- 2. EXISTS / NOT EXISTS are the most common correlated subquery patterns.
--    EXISTS returns TRUE/FALSE — it does not return actual data.
--
-- 3. NOT EXISTS is safer than NOT IN for NULL handling.
--
-- 4. Correlated subqueries in SELECT compute a per-row value, like a
--    "lookup" for each row.
--
-- 5. Performance: On large tables, correlated subqueries can be slow.
--    Consider rewriting as:
--    • JOIN (when you need data from both tables)
--    • Window functions (for ranking, running totals, per-group aggregates)
--    • CTEs or derived tables (for readability)
--
-- 6. The PostgreSQL optimizer is smart — it may internally convert a
--    correlated subquery to a JOIN. Use EXPLAIN ANALYZE to see the
--    actual execution plan.
-- ============================================================================
