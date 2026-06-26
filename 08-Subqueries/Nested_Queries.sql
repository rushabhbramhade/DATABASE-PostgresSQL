-- ============================================================================
-- FILE:    Nested_Queries.sql
-- TOPIC:   Multi-Level Nested Subqueries, ALL, ANY/SOME Operators
-- CHAPTER: 08 - Subqueries
-- ============================================================================
-- A nested query is a subquery INSIDE another subquery — two or more levels
-- of nesting. While powerful, deeply nested queries become hard to read.
--
-- This file covers:
--   • 2+ levels of subquery nesting
--   • ALL operator — compare against EVERY value in a set
--   • ANY / SOME operators — compare against AT LEAST ONE value in a set
--   • When to refactor nested queries into CTEs
--
-- TIPS FOR READING COMPLEX NESTED SQL:
--   1. Start from the INNERMOST subquery (deepest parentheses).
--   2. Figure out what that query returns — a single value? A list? A table?
--   3. Replace it mentally with its result.
--   4. Move one level outward, repeat.
--   5. If it's confusing, rewrite each subquery as a CTE (WITH clause).
--   6. Use indentation! Proper formatting makes nesting readable.
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
-- EXAMPLE 1: Two-Level Nesting — Department of the Highest-Paid Employee
-- ============================================================================
-- Goal: Find the department that the highest-paid employee belongs to,
--       then list ALL employees in that department.
--
-- STRUCTURE:
--   Outer query:  SELECT ... FROM employees WHERE department = (Level 1)
--     Level 1:    SELECT department FROM employees WHERE salary = (Level 2)
--       Level 2:  SELECT MAX(salary) FROM employees
--
-- HOW IT EXECUTES (inside → out):
--   Level 2 → SELECT MAX(salary) FROM employees
--             → Result: 95000.00
--
--   Level 1 → SELECT department FROM employees WHERE salary = 95000.00
--             → Result: 'Engineering'
--
--   Outer   → SELECT ... FROM employees WHERE department = 'Engineering'
--             → Returns all Engineering employees.
-- ============================================================================

SELECT employee_id,
       first_name,
       last_name,
       department,
       salary
FROM   employees
WHERE  department = (
           SELECT department
           FROM   employees
           WHERE  salary = (
                      SELECT MAX(salary)
                      FROM   employees
                  )
       );

-- EXPECTED OUTPUT:
-- employee_id | first_name | last_name | department  |  salary
-- ------------+------------+-----------+-------------+----------
--           1 | Alice      | Johnson   | Engineering | 95000.00
--           2 | Bob        | Smith     | Engineering | 88000.00
--
-- All employees in Engineering are returned because Alice (the highest-paid
-- employee company-wide at 95000) belongs to Engineering.


-- ============================================================================
-- EXAMPLE 2: ALL Operator — Greater Than ALL Values in a Set
-- ============================================================================
-- Goal: Find employees who earn more than ALL employees in the HR department.
--       In other words: salary must be higher than the HIGHEST HR salary.
--
-- ALL means: the comparison must be TRUE for EVERY value returned by the
--            subquery. "salary > ALL (...)" is equivalent to
--            "salary > MAX(values in subquery)".
--
-- HOW IT EXECUTES:
--   Step 1 → Subquery: SELECT salary FROM employees WHERE department = 'HR'
--            → Returns: {62000.00, 58000.00}
--   Step 2 → For each outer row, check: salary > 62000 AND salary > 58000
--            (i.e., salary must exceed EVERY value in the set)
--            Effectively: salary > 62000 (the maximum of the set)
--
--   Alice   95000 > ALL(62000, 58000)? YES
--   Bob     88000 > ALL(62000, 58000)? YES
--   Charlie 62000 > ALL(62000, 58000)? NO (62000 is NOT > 62000)
--   Diana   58000 > ALL(62000, 58000)? NO
--   Eve     72000 > ALL(62000, 58000)? YES
--   Frank   67000 > ALL(62000, 58000)? YES
--   Grace   71000 > ALL(62000, 58000)? YES
--   Hank    65000 > ALL(62000, 58000)? YES
-- ============================================================================

SELECT employee_id,
       first_name,
       last_name,
       department,
       salary
FROM   employees
WHERE  salary > ALL (
           SELECT salary
           FROM   employees
           WHERE  department = 'HR'
       );

-- EXPECTED OUTPUT:
-- employee_id | first_name | last_name | department  |  salary
-- ------------+------------+-----------+-------------+----------
--           1 | Alice      | Johnson   | Engineering | 95000.00
--           2 | Bob        | Smith     | Engineering | 88000.00
--           5 | Eve        | Davis     | Sales       | 72000.00
--           6 | Frank      | Wilson    | Sales       | 67000.00
--           7 | Grace      | Martinez  | Marketing   | 71000.00
--           8 | Hank       | Taylor    | Marketing   | 65000.00
--
-- All 6 employees earn above 62000 (the max HR salary).
-- Charlie (62000) is excluded because > requires strictly greater than.


-- ============================================================================
-- EXAMPLE 3: ANY / SOME Operator — Greater Than At Least One Value
-- ============================================================================
-- Goal: Find employees who earn more than ANY (at least one) employee
--       in the Sales department.
--
-- ANY means: the comparison must be TRUE for AT LEAST ONE value in the set.
-- SOME is a synonym for ANY — they work identically in PostgreSQL.
--
-- "salary > ANY (...)" is equivalent to "salary > MIN(values in subquery)".
--
-- HOW IT EXECUTES:
--   Step 1 → Subquery: SELECT salary FROM employees WHERE department = 'Sales'
--            → Returns: {72000.00, 67000.00}
--   Step 2 → For each outer row, check: salary > 72000 OR salary > 67000
--            Effectively: salary > 67000 (the minimum of the set)
--
--   Alice   95000 > ANY(72000, 67000)? YES (> both)
--   Bob     88000 > ANY(72000, 67000)? YES (> both)
--   Charlie 62000 > ANY(72000, 67000)? NO  (< both)
--   Diana   58000 > ANY(72000, 67000)? NO  (< both)
--   Eve     72000 > ANY(72000, 67000)? YES (> 67000)
--   Frank   67000 > ANY(72000, 67000)? NO  (67000 is NOT > 67000)
--   Grace   71000 > ANY(72000, 67000)? YES (> 67000)
--   Hank    65000 > ANY(72000, 67000)? NO  (< both)
-- ============================================================================

SELECT employee_id,
       first_name,
       last_name,
       department,
       salary
FROM   employees
WHERE  salary > ANY (
           SELECT salary
           FROM   employees
           WHERE  department = 'Sales'
       );

-- EXPECTED OUTPUT:
-- employee_id | first_name | last_name | department  |  salary
-- ------------+------------+-----------+-------------+----------
--           1 | Alice      | Johnson   | Engineering | 95000.00
--           2 | Bob        | Smith     | Engineering | 88000.00
--           5 | Eve        | Davis     | Sales       | 72000.00
--           7 | Grace      | Martinez  | Marketing   | 71000.00
--
-- These employees earn more than at least one Sales employee (67000).

-- ── SOME is identical to ANY ──
SELECT employee_id, first_name, salary
FROM   employees
WHERE  salary > SOME (
           SELECT salary FROM employees WHERE department = 'Sales'
       );
-- Returns the same 4 rows.


-- ============================================================================
-- EXAMPLE 4: Three-Level Nesting — Employees in the Department with
--            the Most Orders
-- ============================================================================
-- Goal: Find all employees who belong to the department that has generated
--       the highest number of orders.
--
-- STRUCTURE:
--   Outer:   SELECT ... FROM employees WHERE department = (Level 1)
--     L1:    SELECT department ... WHERE order_count = (Level 2)
--       L2:  SELECT MAX(order_count) FROM (aggregated subquery)
--
-- HOW IT EXECUTES (inside → out):
--   Level 2 (innermost aggregation):
--     First, compute order counts per department:
--       Engineering: 2 orders (Alice 1 + Bob 1)
--       Sales:       4 orders (Eve 2 + Frank 2)
--     Then MAX(order_count) → 4
--
--   Level 1:
--     Which department has exactly 4 orders? → 'Sales'
--
--   Outer:
--     SELECT ... WHERE department = 'Sales' → Eve and Frank
-- ============================================================================

SELECT employee_id,
       first_name,
       last_name,
       department,
       salary
FROM   employees
WHERE  department = (
           SELECT dept_orders.department
           FROM   (
                      SELECT   e.department,
                               COUNT(o.order_id) AS order_count
                      FROM     employees e
                      JOIN     orders o ON e.employee_id = o.employee_id
                      GROUP BY e.department
                  ) AS dept_orders
           WHERE  dept_orders.order_count = (
                      SELECT MAX(dept_orders2.order_count)
                      FROM   (
                                 SELECT   e2.department,
                                          COUNT(o2.order_id) AS order_count
                                 FROM     employees e2
                                 JOIN     orders o2 ON e2.employee_id = o2.employee_id
                                 GROUP BY e2.department
                             ) AS dept_orders2
                  )
       );

-- EXPECTED OUTPUT:
-- employee_id | first_name | last_name | department |  salary
-- ------------+------------+-----------+------------+----------
--           5 | Eve        | Davis     | Sales      | 72000.00
--           6 | Frank      | Wilson    | Sales      | 67000.00
--
-- Sales has the most orders (4), so both Sales employees are returned.

-- ── See how hard that was to read? Let's refactor to a CTE below. ──


-- ============================================================================
-- EXAMPLE 5: ALL with Nested Aggregation — Salary Above Every Department Avg
-- ============================================================================
-- Goal: Find employees whose salary is greater than the average salary
--       of EVERY department (i.e., higher than the highest department average).
--
-- HOW IT EXECUTES:
--   Step 1 → Subquery computes average salary per department:
--            Engineering: 91500, Sales: 69500, Marketing: 68000, HR: 60000
--   Step 2 → salary > ALL(91500, 69500, 68000, 60000)
--            → salary must be > 91500 (the max of the averages)
-- ============================================================================

SELECT employee_id,
       first_name,
       department,
       salary
FROM   employees
WHERE  salary > ALL (
           SELECT AVG(salary)
           FROM   employees
           GROUP BY department
       );

-- EXPECTED OUTPUT:
-- employee_id | first_name | department  |  salary
-- ------------+------------+-------------+----------
--           1 | Alice      | Engineering | 95000.00
--
-- Only Alice (95000) earns more than every department's average.
-- The highest department average is Engineering at 91500.


-- ============================================================================
-- EXAMPLE 6: Combining ALL with NOT IN and Nesting
-- ============================================================================
-- Goal: Find employees who earn more than ALL employees who have
--       never placed an order.
--
-- HOW IT EXECUTES:
--   Level 2 → Employees without orders: Charlie(62000), Diana(58000),
--             Grace(71000), Hank(65000)
--   Level 1 → salary > ALL(62000, 58000, 71000, 65000)
--             → salary must be > 71000 (the max among those without orders)
-- ============================================================================

SELECT employee_id,
       first_name,
       department,
       salary
FROM   employees
WHERE  salary > ALL (
           SELECT salary
           FROM   employees
           WHERE  employee_id NOT IN (
                      SELECT employee_id FROM orders
                  )
       );

-- EXPECTED OUTPUT:
-- employee_id | first_name | department  |  salary
-- ------------+------------+-------------+----------
--           1 | Alice      | Engineering | 95000.00
--           2 | Bob        | Smith       | 88000.00
--           5 | Eve        | Sales       | 72000.00
--
-- These three earn above 71000 (Grace's salary — the highest among
-- employees without orders).


-- ============================================================================
-- REFACTORING: Rewriting Example 4 as a CTE (Recommended!)
-- ============================================================================
-- The same logic from Example 4, but using WITH (CTE) for clarity.
-- Compare readability — CTEs name each logical step.
-- ============================================================================

WITH dept_order_counts AS (
    SELECT   e.department,
             COUNT(o.order_id) AS order_count
    FROM     employees e
    JOIN     orders o ON e.employee_id = o.employee_id
    GROUP BY e.department
),
top_department AS (
    SELECT department
    FROM   dept_order_counts
    WHERE  order_count = (SELECT MAX(order_count) FROM dept_order_counts)
)
SELECT e.employee_id,
       e.first_name,
       e.last_name,
       e.department,
       e.salary
FROM   employees e
WHERE  e.department = (SELECT department FROM top_department);

-- EXPECTED OUTPUT: Same as Example 4
-- employee_id | first_name | last_name | department |  salary
-- ------------+------------+-----------+------------+----------
--           5 | Eve        | Davis     | Sales      | 72000.00
--           6 | Frank      | Wilson    | Sales      | 67000.00
--
-- Much easier to read! Each CTE has a meaningful name that describes
-- what it computes.


-- ============================================================================
-- QUICK REFERENCE: ALL vs. ANY/SOME
-- ============================================================================
--
--  Operator       Meaning                           Equivalent To
--  ─────────────  ────────────────────────────────   ─────────────────────
--  > ALL (set)    Greater than EVERY value           > MAX(set)
--  < ALL (set)    Less than EVERY value              < MIN(set)
--  = ALL (set)    Equal to EVERY value               Only if all same
--  > ANY (set)    Greater than at least ONE value    > MIN(set)
--  < ANY (set)    Less than at least ONE value       < MAX(set)
--  = ANY (set)    Equal to at least ONE value        Same as IN
--
--  SOME is a synonym for ANY — they are 100% interchangeable.
--
--  Edge case: If the subquery returns an EMPTY set:
--    > ALL (empty) → TRUE  (vacuously true — no value to violate it)
--    > ANY (empty) → FALSE (no value to satisfy it)
--
-- ============================================================================


-- ============================================================================
-- KEY TAKEAWAYS
-- ============================================================================
-- 1. Multi-level nesting: subqueries can be nested 2, 3, or more levels deep.
--    Always read from the INNERMOST query outward.
--
-- 2. ALL → the condition must hold for EVERY value in the subquery result.
--    ANY/SOME → the condition must hold for AT LEAST ONE value.
--
-- 3. Deeply nested queries are hard to read and maintain. When nesting
--    exceeds 2 levels, consider refactoring to CTEs (WITH clause):
--    • Name each logical step
--    • Easier to debug (run each CTE independently)
--    • Same performance in most cases (PostgreSQL may inline CTEs)
--
-- 4. ALL with an empty subquery returns TRUE (vacuous truth).
--    ANY with an empty subquery returns FALSE.
--
-- 5. "= ANY (subquery)" is functionally identical to "IN (subquery)".
--
-- 6. When writing nested queries:
--    • Use consistent indentation (2-4 spaces per level)
--    • Give aliases to derived tables
--    • Add comments explaining what each level returns
--    • Test each subquery level independently before combining
-- ============================================================================
