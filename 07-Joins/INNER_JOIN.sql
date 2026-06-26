-- ============================================================
-- FILE: INNER_JOIN.sql
-- TOPIC: INNER JOIN in PostgreSQL
-- DESCRIPTION: Returns only the rows that have matching values
--              in BOTH tables. Non-matching rows are excluded.
-- ============================================================

-- ============================================================
-- SAMPLE TABLES USED IN THIS FILE
-- ============================================================
-- employees table:
-- | employee_id | first_name | department_id | salary | manager_id |
-- |-------------|------------|---------------|--------|------------|
-- | 1           | Amit       | 101           | 75000  | NULL       |
-- | 2           | Priya      | 102           | 55000  | 1          |
-- | 3           | Rahul      | 101           | 82000  | 1          |
-- | 4           | Sneha      | 103           | 48000  | 2          |
-- | 5           | Vikram     | NULL          | 60000  | 2          |
--
-- departments table:
-- | department_id | department_name | location    |
-- |---------------|-----------------|-------------|
-- | 101           | Engineering     | Bangalore   |
-- | 102           | Marketing       | Mumbai      |
-- | 103           | HR              | Delhi       |
-- | 104           | Finance         | Hyderabad   |


-- ============================================================
-- VISUAL DIAGRAM: HOW INNER JOIN WORKS
-- ============================================================
--
--   employees table              departments table
--  ┌──────────────────┐        ┌────────────────────────┐
--  │ employee_id = 1  │──┐  ┌──│ department_id = 101    │
--  │ dept_id = 101    │  ├──┤  │ Engineering, Bangalore │
--  │ employee_id = 3  │──┘  │  └────────────────────────┘
--  │ dept_id = 101    │     │  ┌────────────────────────┐
--  ├──────────────────┤     ├──│ department_id = 102    │
--  │ employee_id = 2  │─────┘  │ Marketing, Mumbai      │
--  │ dept_id = 102    │        └────────────────────────┘
--  ├──────────────────┤        ┌────────────────────────┐
--  │ employee_id = 4  │────────│ department_id = 103    │
--  │ dept_id = 103    │        │ HR, Delhi              │
--  ├──────────────────┤        └────────────────────────┘
--  │ employee_id = 5  │  ✗     ┌────────────────────────┐
--  │ dept_id = NULL   │  NO    │ department_id = 104    │  ✗ NO
--  │ (no match)       │  MATCH │ Finance, Hyderabad     │  MATCH
--  └──────────────────┘        │ (no employees)         │
--                              └────────────────────────┘
--
--  RESULT: Only rows with matching department_id appear.
--          Vikram (NULL dept) → EXCLUDED
--          Finance (dept 104, no employees) → EXCLUDED
--


-- ============================================================
-- 1. BASIC INNER JOIN SYNTAX
-- ============================================================
-- The keyword INNER is optional; JOIN alone defaults to INNER JOIN.

SELECT
    e.employee_id,
    e.first_name,
    d.department_name
FROM employees e
INNER JOIN departments d
    ON e.department_id = d.department_id;

-- EXPECTED OUTPUT:
-- | employee_id | first_name | department_name |
-- |-------------|------------|-----------------|
-- | 1           | Amit       | Engineering     |
-- | 2           | Priya      | Marketing       |
-- | 3           | Rahul      | Engineering     |
-- | 4           | Sneha      | HR              |
--
-- NOTE: Vikram is missing (department_id is NULL → no match).
--       Finance is missing (no employee has department_id 104).


-- ============================================================
-- 2. JOIN ON FOREIGN KEY (SELECTING MORE COLUMNS)
-- ============================================================
-- A common pattern: display employee details alongside their
-- department name and office location.

SELECT
    e.employee_id,
    e.first_name,
    e.salary,
    d.department_name,
    d.location
FROM employees e
INNER JOIN departments d
    ON e.department_id = d.department_id;

-- EXPECTED OUTPUT:
-- | employee_id | first_name | salary | department_name | location  |
-- |-------------|------------|--------|-----------------|-----------|
-- | 1           | Amit       | 75000  | Engineering     | Bangalore |
-- | 2           | Priya      | 55000  | Marketing       | Mumbai    |
-- | 3           | Rahul      | 82000  | Engineering     | Bangalore |
-- | 4           | Sneha      | 48000  | HR              | Delhi     |


-- ============================================================
-- 3. INNER JOIN WITH WHERE CLAUSE (FILTERING AFTER JOIN)
-- ============================================================
-- First the JOIN produces matched rows, then WHERE filters them.

SELECT
    e.first_name,
    e.salary,
    d.department_name
FROM employees e
INNER JOIN departments d
    ON e.department_id = d.department_id
WHERE e.salary > 60000;

-- EXPECTED OUTPUT:
-- | first_name | salary | department_name |
-- |------------|--------|-----------------|
-- | Amit       | 75000  | Engineering     |
-- | Rahul      | 82000  | Engineering     |
--
-- Only employees earning more than 60,000 AND having a matching
-- department are returned.


-- ============================================================
-- 4. INNER JOIN WITH MULTIPLE CONDITIONS
-- ============================================================
-- You can add extra conditions in the ON clause using AND.
-- Here we join only when the department matches AND the employee
-- works in Bangalore.

SELECT
    e.first_name,
    d.department_name,
    d.location
FROM employees e
INNER JOIN departments d
    ON e.department_id = d.department_id
    AND d.location = 'Bangalore';

-- EXPECTED OUTPUT:
-- | first_name | department_name | location  |
-- |------------|-----------------|-----------|
-- | Amit       | Engineering     | Bangalore |
-- | Rahul      | Engineering     | Bangalore |
--
-- Only employees in departments located in Bangalore appear.
-- Priya (Mumbai) and Sneha (Delhi) are excluded by the ON clause.


-- ============================================================
-- 5. INNER JOIN WITH ALIASES (SHORT FORM)
-- ============================================================
-- The keyword INNER is optional. Using just JOIN is equivalent.

SELECT
    e.first_name,
    d.department_name
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id;

-- EXPECTED OUTPUT: (Same as Example 1)
-- | first_name | department_name |
-- |------------|-----------------|
-- | Amit       | Engineering     |
-- | Priya      | Marketing       |
-- | Rahul      | Engineering     |
-- | Sneha      | HR              |


-- ============================================================
-- 6. INNER JOIN WITH ORDER BY
-- ============================================================

SELECT
    e.first_name,
    e.salary,
    d.department_name
FROM employees e
INNER JOIN departments d
    ON e.department_id = d.department_id
ORDER BY e.salary DESC;

-- EXPECTED OUTPUT:
-- | first_name | salary | department_name |
-- |------------|--------|-----------------|
-- | Rahul      | 82000  | Engineering     |
-- | Amit       | 75000  | Engineering     |
-- | Priya      | 55000  | Marketing       |
-- | Sneha      | 48000  | HR              |


-- ============================================================
-- 7. INNER JOIN WITH AGGREGATE FUNCTIONS
-- ============================================================
-- Count employees per department (only departments with employees).

SELECT
    d.department_name,
    COUNT(e.employee_id) AS employee_count,
    ROUND(AVG(e.salary), 2) AS avg_salary
FROM employees e
INNER JOIN departments d
    ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY employee_count DESC;

-- EXPECTED OUTPUT:
-- | department_name | employee_count | avg_salary |
-- |-----------------|----------------|------------|
-- | Engineering     | 2              | 78500.00   |
-- | Marketing       | 1              | 55000.00   |
-- | HR              | 1              | 48000.00   |
--
-- Finance is NOT listed because INNER JOIN excludes departments
-- with no matching employees.


-- ============================================================
-- 8. REAL-WORLD USE CASE: EMPLOYEE DIRECTORY WITH DEPARTMENT
-- ============================================================
-- Building a directory that shows each employee's full info
-- alongside their department and location.

SELECT
    e.employee_id AS "ID",
    e.first_name AS "Employee",
    e.salary AS "Salary",
    d.department_name AS "Department",
    d.location AS "Office"
FROM employees e
INNER JOIN departments d
    ON e.department_id = d.department_id
ORDER BY e.employee_id;

-- EXPECTED OUTPUT:
-- | ID | Employee | Salary | Department  | Office    |
-- |----|----------|--------|-------------|-----------|
-- | 1  | Amit     | 75000  | Engineering | Bangalore |
-- | 2  | Priya    | 55000  | Marketing   | Mumbai    |
-- | 3  | Rahul    | 82000  | Engineering | Bangalore |
-- | 4  | Sneha    | 48000  | HR          | Delhi     |


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. INNER JOIN returns ONLY rows with matching values in both tables.
-- 2. Non-matching rows from EITHER side are excluded from the result.
-- 3. Vikram (department_id = NULL) has no match → excluded.
-- 4. Finance (department_id = 104, no employees) has no match → excluded.
-- 5. JOIN and INNER JOIN are identical — INNER is the default.
-- 6. Use ON to specify the join condition (usually a foreign key).
-- 7. WHERE filters rows AFTER the join is performed.
-- 8. Extra conditions can go in the ON clause using AND.
-- 9. INNER JOIN is the most commonly used type of join.
-- ============================================================
