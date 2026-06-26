-- ============================================================
-- FILE: RIGHT_JOIN.sql
-- TOPIC: RIGHT JOIN (RIGHT OUTER JOIN) in PostgreSQL
-- DESCRIPTION: Returns ALL rows from the RIGHT table and the
--              matching rows from the LEFT table. If there is
--              no match, NULL values fill the left-side columns.
-- ============================================================

-- ============================================================
-- SAMPLE TABLES USED IN THIS FILE
-- ============================================================
-- employees table (LEFT):
-- | employee_id | first_name | department_id | salary | manager_id |
-- |-------------|------------|---------------|--------|------------|
-- | 1           | Amit       | 101           | 75000  | NULL       |
-- | 2           | Priya      | 102           | 55000  | 1          |
-- | 3           | Rahul      | 101           | 82000  | 1          |
-- | 4           | Sneha      | 103           | 48000  | 2          |
-- | 5           | Vikram     | NULL          | 60000  | 2          |
--
-- departments table (RIGHT):
-- | department_id | department_name | location    |
-- |---------------|-----------------|-------------|
-- | 101           | Engineering     | Bangalore   |
-- | 102           | Marketing       | Mumbai      |
-- | 103           | HR              | Delhi       |
-- | 104           | Finance         | Hyderabad   |


-- ============================================================
-- VISUAL DIAGRAM: HOW RIGHT JOIN WORKS
-- ============================================================
--
--   LEFT TABLE (employees)        RIGHT TABLE (departments)
--  ┌──────────────────────┐      ┌────────────────────────┐
--  │ Amit    dept_id=101  │──────│ 101 Engineering        │  ✔ Match
--  │ Priya   dept_id=102  │──────│ 102 Marketing          │  ✔ Match
--  │ Rahul   dept_id=101  │──────│ 101 Engineering        │  ✔ Match
--  │ Sneha   dept_id=103  │──────│ 103 HR                 │  ✔ Match
--  │ Vikram  dept_id=NULL │  ✗   │                        │
--  │ (NOT included)       │      │ 104 Finance            │  ✔ Kept with NULLs
--  └──────────────────────┘      └────────────────────────┘
--
--  RULE: Every row from the RIGHT table appears in the result.
--        Finance → included (with NULL for employee columns).
--        Vikram  → NOT included (he is on the left side with no match).
--


-- ============================================================
-- 1. BASIC RIGHT JOIN SYNTAX
-- ============================================================

SELECT
    e.employee_id,
    e.first_name,
    d.department_id,
    d.department_name
FROM employees e
RIGHT JOIN departments d
    ON e.department_id = d.department_id;

-- EXPECTED OUTPUT:
-- | employee_id | first_name | department_id | department_name |
-- |-------------|------------|---------------|-----------------|
-- | 1           | Amit       | 101           | Engineering     |
-- | 3           | Rahul      | 101           | Engineering     |
-- | 2           | Priya      | 102           | Marketing       |
-- | 4           | Sneha      | 103           | HR              |
-- | NULL        | NULL       | 104           | Finance         |
--
-- Finance appears with NULL employee info — no employees in dept 104.
-- Vikram does NOT appear — he has no matching department.


-- ============================================================
-- 2. RIGHT JOIN WITH ALL COLUMNS
-- ============================================================

SELECT
    e.employee_id,
    e.first_name,
    e.salary,
    d.department_name,
    d.location
FROM employees e
RIGHT JOIN departments d
    ON e.department_id = d.department_id
ORDER BY d.department_id;

-- EXPECTED OUTPUT:
-- | employee_id | first_name | salary | department_name | location  |
-- |-------------|------------|--------|-----------------|-----------|
-- | 1           | Amit       | 75000  | Engineering     | Bangalore |
-- | 3           | Rahul      | 82000  | Engineering     | Bangalore |
-- | 2           | Priya      | 55000  | Marketing       | Mumbai    |
-- | 4           | Sneha      | 48000  | HR              | Delhi     |
-- | NULL        | NULL       | NULL   | Finance         | Hyderabad |
--
-- employee_id, first_name, and salary are all NULL for Finance.


-- ============================================================
-- 3. FINDING DEPARTMENTS WITH NO EMPLOYEES
-- ============================================================
-- The classic RIGHT JOIN pattern: find unmatched rows from right.

SELECT
    d.department_id,
    d.department_name,
    d.location
FROM employees e
RIGHT JOIN departments d
    ON e.department_id = d.department_id
WHERE e.employee_id IS NULL;

-- EXPECTED OUTPUT:
-- | department_id | department_name | location  |
-- |---------------|-----------------|-----------|
-- | 104           | Finance         | Hyderabad |
--
-- Only Finance has no employees assigned to it.


-- ============================================================
-- 4. RIGHT OUTER JOIN (EXPLICIT SYNTAX)
-- ============================================================
-- RIGHT JOIN and RIGHT OUTER JOIN are identical in PostgreSQL.

SELECT
    e.first_name,
    d.department_name
FROM employees e
RIGHT OUTER JOIN departments d
    ON e.department_id = d.department_id;

-- EXPECTED OUTPUT: (Same as Example 1)
-- | first_name | department_name |
-- |------------|-----------------|
-- | Amit       | Engineering     |
-- | Rahul      | Engineering     |
-- | Priya      | Marketing       |
-- | Sneha      | HR              |
-- | NULL       | Finance         |


-- ============================================================
-- 5. RIGHT JOIN WITH COALESCE
-- ============================================================
-- Replace NULL employee info with a friendly message.

SELECT
    COALESCE(e.first_name, '-- Vacant --') AS employee,
    COALESCE(e.salary::TEXT, 'N/A') AS salary,
    d.department_name,
    d.location
FROM employees e
RIGHT JOIN departments d
    ON e.department_id = d.department_id
ORDER BY d.department_name;

-- EXPECTED OUTPUT:
-- | employee     | salary | department_name | location  |
-- |--------------|--------|-----------------|-----------|
-- | Amit         | 75000  | Engineering     | Bangalore |
-- | Rahul        | 82000  | Engineering     | Bangalore |
-- | -- Vacant -- | N/A    | Finance         | Hyderabad |
-- | Sneha        | 48000  | HR              | Delhi     |
-- | Priya        | 55000  | Marketing       | Mumbai    |


-- ============================================================
-- 6. RIGHT JOIN WITH AGGREGATE FUNCTIONS
-- ============================================================
-- Count employees in each department, including empty ones.

SELECT
    d.department_name,
    COUNT(e.employee_id) AS employee_count
FROM employees e
RIGHT JOIN departments d
    ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY employee_count DESC;

-- EXPECTED OUTPUT:
-- | department_name | employee_count |
-- |-----------------|----------------|
-- | Engineering     | 2              |
-- | Marketing       | 1              |
-- | HR              | 1              |
-- | Finance         | 0              |
--
-- Finance shows 0 employees. COUNT(e.employee_id) counts only
-- non-NULL values, so NULLs from unmatched rows give 0.


-- ============================================================
-- 7. RIGHT JOIN vs LEFT JOIN — THEY ARE INTERCHANGEABLE
-- ============================================================
-- A RIGHT JOIN is just a LEFT JOIN with the tables swapped!

-- This RIGHT JOIN:
SELECT e.first_name, d.department_name
FROM employees e
RIGHT JOIN departments d
    ON e.department_id = d.department_id;

-- ...is IDENTICAL to this LEFT JOIN (tables are reversed):
SELECT e.first_name, d.department_name
FROM departments d
LEFT JOIN employees e
    ON e.department_id = d.department_id;

-- Both produce the same result:
-- | first_name | department_name |
-- |------------|-----------------|
-- | Amit       | Engineering     |
-- | Rahul      | Engineering     |
-- | Priya      | Marketing       |
-- | Sneha      | HR              |
-- | NULL       | Finance         |
--
-- BEST PRACTICE: Most developers prefer LEFT JOIN with reversed
-- table order over RIGHT JOIN. It reads more naturally and is
-- more widely used in production code.


-- ============================================================
-- 8. RIGHT JOIN WITH WHERE FILTER
-- ============================================================

SELECT
    e.first_name,
    d.department_name,
    d.location
FROM employees e
RIGHT JOIN departments d
    ON e.department_id = d.department_id
WHERE d.location IN ('Bangalore', 'Hyderabad');

-- EXPECTED OUTPUT:
-- | first_name | department_name | location  |
-- |------------|-----------------|-----------|
-- | Amit       | Engineering     | Bangalore |
-- | Rahul      | Engineering     | Bangalore |
-- | NULL       | Finance         | Hyderabad |
--
-- Finance (Hyderabad) still appears even with no employees.


-- ============================================================
-- 9. REAL-WORLD USE CASE: DEPARTMENT STAFFING REPORT
-- ============================================================
-- Management wants to see all departments and whether they have
-- enough staff. Departments with no employees are flagged.

SELECT
    d.department_name AS "Department",
    d.location AS "Location",
    COUNT(e.employee_id) AS "Headcount",
    CASE
        WHEN COUNT(e.employee_id) = 0 THEN 'UNDERSTAFFED - HIRE NEEDED'
        WHEN COUNT(e.employee_id) = 1 THEN 'Low Staffing'
        ELSE 'Adequate'
    END AS "Status"
FROM employees e
RIGHT JOIN departments d
    ON e.department_id = d.department_id
GROUP BY d.department_name, d.location
ORDER BY "Headcount";

-- EXPECTED OUTPUT:
-- | Department  | Location  | Headcount | Status                     |
-- |-------------|-----------|-----------|----------------------------|
-- | Finance     | Hyderabad | 0         | UNDERSTAFFED - HIRE NEEDED |
-- | Marketing   | Mumbai    | 1         | Low Staffing               |
-- | HR          | Delhi     | 1         | Low Staffing               |
-- | Engineering | Bangalore | 2         | Adequate                   |


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. RIGHT JOIN returns ALL rows from the RIGHT table, always.
-- 2. If there is no match in the left table, left-side columns
--    are filled with NULL.
-- 3. Finance (dept 104) → included with NULLs for employee info.
-- 4. Vikram (dept_id = NULL) → NOT included (left side only).
-- 5. RIGHT JOIN + WHERE left.key IS NULL → finds unmatched rows
--    from the right table (e.g., departments with no employees).
-- 6. RIGHT JOIN and RIGHT OUTER JOIN are exactly the same.
-- 7. RIGHT JOIN is RARELY used in practice. You can always
--    rewrite it as a LEFT JOIN by swapping the table order.
-- 8. CONVENTION: Prefer LEFT JOIN over RIGHT JOIN for readability.
-- ============================================================
