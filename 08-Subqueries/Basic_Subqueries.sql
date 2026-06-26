-- ============================================================================
-- FILE:    Basic_Subqueries.sql
-- TOPIC:   Non-Correlated Subqueries in PostgreSQL
-- CHAPTER: 08 - Subqueries
-- ============================================================================
-- A non-correlated (or "simple") subquery is a query nested inside another
-- query that can run INDEPENDENTLY. The inner query executes FIRST, produces
-- a result, and that result is then used by the outer query.
--
-- Key idea: The inner query does NOT reference any column from the outer query.
--
-- HOW TO READ A SUBQUERY (Step-by-Step for Beginners):
--   1. Find the innermost query (inside the deepest parentheses).
--   2. Mentally run that inner query — what result does it return?
--   3. Replace the subquery with that result.
--   4. Now read the outer query as a normal SQL statement.
--   5. If there are multiple levels, repeat from the inside out.
-- ============================================================================


-- ============================================================================
-- SAMPLE TABLES (Run this first to follow along)
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
-- EXAMPLE 1: Subquery in WHERE — Scalar Subquery (Single Value)
-- ============================================================================
-- Goal: Find employees who earn MORE than the company-wide average salary.
--
-- HOW IT EXECUTES:
--   Step 1 → Inner query runs: SELECT AVG(salary) FROM employees  →  72250.00
--   Step 2 → Outer query becomes: SELECT ... WHERE salary > 72250.00
--   Step 3 → PostgreSQL returns rows where salary exceeds that average.
-- ============================================================================

SELECT employee_id,
       first_name,
       last_name,
       department,
       salary
FROM   employees
WHERE  salary > (SELECT AVG(salary) FROM employees);

-- EXPECTED OUTPUT:
-- employee_id | first_name | last_name | department  |  salary
-- ------------+------------+-----------+-------------+----------
--           1 | Alice      | Johnson   | Engineering | 95000.00
--           2 | Bob        | Smith     | Engineering | 88000.00
--
-- WHY? The average salary is 72250.00. Only Alice (95000) and Bob (88000)
--       earn above that amount.


-- ============================================================================
-- EXAMPLE 2: Subquery with IN — Multi-Value Subquery
-- ============================================================================
-- Goal: Find employees who belong to departments that have placed at least
--       one order (i.e., at least one employee in that dept appears in orders).
--
-- HOW IT EXECUTES:
--   Step 1 → Inner query: Find department names of employees who have orders
--            → Result: {'Engineering', 'Sales'}
--   Step 2 → Outer query: SELECT ... WHERE department IN ('Engineering','Sales')
-- ============================================================================

SELECT employee_id,
       first_name,
       last_name,
       department
FROM   employees
WHERE  department IN (
           SELECT DISTINCT e.department
           FROM   employees e
           JOIN   orders o ON e.employee_id = o.employee_id
       );

-- EXPECTED OUTPUT:
-- employee_id | first_name | last_name | department
-- ------------+------------+-----------+-------------
--           1 | Alice      | Johnson   | Engineering
--           2 | Bob        | Smith     | Engineering
--           5 | Eve        | Davis     | Sales
--           6 | Frank      | Wilson    | Sales
--
-- WHY? Engineering has orders from Alice & Bob; Sales has orders from Eve & Frank.
--       HR and Marketing employees have no orders, so they are excluded.


-- ============================================================================
-- EXAMPLE 3: Subquery with NOT IN
-- ============================================================================
-- Goal: Find employees who have NEVER placed any order.
--
-- HOW IT EXECUTES:
--   Step 1 → Inner query: SELECT employee_id FROM orders → {5, 6, 1, 2}
--   Step 2 → Outer query: WHERE employee_id NOT IN (5, 6, 1, 2)
-- ============================================================================

SELECT employee_id,
       first_name,
       last_name,
       department
FROM   employees
WHERE  employee_id NOT IN (
           SELECT employee_id FROM orders
       );

-- EXPECTED OUTPUT:
-- employee_id | first_name | last_name | department
-- ------------+------------+-----------+-----------
--           3 | Charlie    | Brown     | HR
--           4 | Diana      | Lee       | HR
--           7 | Grace      | Martinez  | Marketing
--           8 | Hank       | Taylor    | Marketing
--
-- ⚠️ CAUTION: If the subquery can return NULL values, NOT IN will return
--    no rows at all! Always add WHERE column IS NOT NULL inside, or use
--    NOT EXISTS instead (covered in Correlated_Subqueries.sql).


-- ============================================================================
-- EXAMPLE 4: Subquery in SELECT — Computed Column
-- ============================================================================
-- Goal: Show each employee alongside the company average salary.
--
-- HOW IT EXECUTES:
--   Step 1 → Inner query runs ONCE: AVG(salary) → 72250.00
--   Step 2 → That value appears as a column in every output row.
-- ============================================================================

SELECT employee_id,
       first_name,
       salary,
       (SELECT AVG(salary) FROM employees) AS company_avg,
       salary - (SELECT AVG(salary) FROM employees) AS diff_from_avg
FROM   employees
ORDER BY salary DESC;

-- EXPECTED OUTPUT:
-- employee_id | first_name |  salary  | company_avg |  diff_from_avg
-- ------------+------------+----------+-------------+----------------
--           1 | Alice      | 95000.00 |   72250.00  |    22750.00
--           2 | Bob        | 88000.00 |   72250.00  |    15750.00
--           5 | Eve        | 72000.00 |   72250.00  |     -250.00
--           7 | Grace      | 71000.00 |   72250.00  |    -1250.00
--           6 | Frank      | 67000.00 |   72250.00  |    -5250.00
--           8 | Hank       | 65000.00 |   72250.00  |    -7250.00
--           3 | Charlie    | 62000.00 |   72250.00  |   -10250.00
--           4 | Diana      | 58000.00 |   72250.00  |   -14250.00
--
-- NOTE: A scalar subquery in SELECT must return exactly ONE value.
--       If it returns more than one row, PostgreSQL will throw an error.


-- ============================================================================
-- EXAMPLE 5: Subquery in FROM — Derived Table (Inline View)
-- ============================================================================
-- Goal: Show total order revenue per employee, but only for those whose
--       total exceeds $10,000.
--
-- HOW IT EXECUTES:
--   Step 1 → The subquery in FROM runs first, producing a temporary result
--            set (a "virtual table") with employee_id and total_revenue.
--   Step 2 → The outer query JOINs this derived table to the employees table
--            and filters rows where total_revenue > 10000.
-- ============================================================================

SELECT e.first_name,
       e.last_name,
       e.department,
       rev.total_revenue
FROM   employees e
JOIN   (
           SELECT   employee_id,
                    SUM(order_total) AS total_revenue
           FROM     orders
           GROUP BY employee_id
       ) AS rev ON e.employee_id = rev.employee_id
WHERE  rev.total_revenue > 10000
ORDER BY rev.total_revenue DESC;

-- EXPECTED OUTPUT:
-- first_name | last_name | department |  total_revenue
-- -----------+-----------+------------+----------------
-- Eve        | Davis     | Sales      |       23500.00
-- Frank      | Wilson    | Sales      |       21200.00
--
-- WHY? Eve has orders 15000 + 8500 = 23500; Frank has 12000 + 9200 = 21200.
--       Alice (3500) and Bob (4200) have totals under 10000, so excluded.
--
-- NOTE: A subquery in FROM MUST have an alias (here: "rev"). PostgreSQL
--       will throw an error if you omit the alias.


-- ============================================================================
-- EXAMPLE 6: Subquery with Comparison Operators (MIN / MAX)
-- ============================================================================
-- Goal: Find the employee(s) with the LOWEST salary in the company.
--
-- HOW IT EXECUTES:
--   Step 1 → Inner query: SELECT MIN(salary) FROM employees → 58000.00
--   Step 2 → Outer query: WHERE salary = 58000.00
-- ============================================================================

SELECT employee_id,
       first_name,
       last_name,
       department,
       salary
FROM   employees
WHERE  salary = (SELECT MIN(salary) FROM employees);

-- EXPECTED OUTPUT:
-- employee_id | first_name | last_name | department |  salary
-- ------------+------------+-----------+------------+----------
--           4 | Diana      | Lee       | HR         | 58000.00


-- ============================================================================
-- EXAMPLE 7: Subquery to Filter by Aggregated Condition
-- ============================================================================
-- Goal: Find departments where the average salary is above 70000.
--       Then list all employees in those departments.
--
-- HOW IT EXECUTES:
--   Step 1 → Inner query groups by department, filters HAVING AVG > 70000
--            → Result: {'Engineering'}  (avg = 91500)
--            Note: Sales avg = 69500, HR avg = 60000, Marketing avg = 68000
--   Step 2 → Outer query: WHERE department IN ('Engineering')
-- ============================================================================

SELECT employee_id,
       first_name,
       last_name,
       department,
       salary
FROM   employees
WHERE  department IN (
           SELECT   department
           FROM     employees
           GROUP BY department
           HAVING   AVG(salary) > 70000
       );

-- EXPECTED OUTPUT:
-- employee_id | first_name | last_name | department  |  salary
-- ------------+------------+-----------+-------------+----------
--           1 | Alice      | Johnson   | Engineering | 95000.00
--           2 | Bob        | Smith     | Engineering | 88000.00


-- ============================================================================
-- EXAMPLE 8: Subquery in FROM with Multiple Aggregations
-- ============================================================================
-- Goal: Show a department-level summary alongside each department's share
--       of total company salary.
--
-- HOW IT EXECUTES:
--   Step 1 → Derived table "dept_stats" computes per-department aggregates.
--   Step 2 → Scalar subquery in SELECT computes company-wide total salary.
--   Step 3 → The outer query calculates each department's percentage share.
-- ============================================================================

SELECT dept_stats.department,
       dept_stats.emp_count,
       dept_stats.avg_salary,
       dept_stats.total_salary,
       (SELECT SUM(salary) FROM employees) AS company_total,
       ROUND(
           dept_stats.total_salary / (SELECT SUM(salary) FROM employees) * 100,
           1
       ) AS pct_of_total
FROM   (
           SELECT   department,
                    COUNT(*)            AS emp_count,
                    ROUND(AVG(salary),2) AS avg_salary,
                    SUM(salary)         AS total_salary
           FROM     employees
           GROUP BY department
       ) AS dept_stats
ORDER BY dept_stats.total_salary DESC;

-- EXPECTED OUTPUT:
-- department  | emp_count | avg_salary | total_salary | company_total | pct_of_total
-- ------------+-----------+------------+--------------+---------------+--------------
-- Engineering |         2 |   91500.00 |    183000.00 |     578000.00 |         31.7
-- Sales       |         2 |   69500.00 |    139000.00 |     578000.00 |         24.0
-- Marketing   |         2 |   68000.00 |    136000.00 |     578000.00 |         23.5
-- HR          |         2 |   60000.00 |    120000.00 |     578000.00 |         20.8


-- ============================================================================
-- KEY TAKEAWAYS
-- ============================================================================
-- 1. A non-correlated subquery runs INDEPENDENTLY of the outer query.
--    It executes ONCE, and its result is fed to the outer query.
--
-- 2. WHERE clause subqueries can use =, >, <, IN, NOT IN, etc.
--    • Scalar subqueries (return 1 value) → use with =, >, <, >=, <=
--    • Multi-row subqueries (return a list) → use with IN, NOT IN, ANY, ALL
--
-- 3. SELECT clause subqueries must return exactly ONE value (scalar).
--
-- 4. FROM clause subqueries (derived tables) MUST have an alias.
--
-- 5. Reading tip: Always start from the INNERMOST subquery and work outward.
--
-- 6. NOT IN pitfall: If the subquery returns any NULL, NOT IN returns no rows.
--    Prefer NOT EXISTS for safety (see Correlated_Subqueries.sql).
--
-- 7. When subqueries get complex, consider refactoring to CTEs (WITH clause)
--    for readability — covered in Chapter 13.
-- ============================================================================
