-- ============================================================
-- FILE: LEFT_JOIN.sql
-- TOPIC: LEFT JOIN (LEFT OUTER JOIN) in PostgreSQL
-- DESCRIPTION: Returns ALL rows from the LEFT table and the
--              matching rows from the RIGHT table. If there is
--              no match, NULL values fill the right-side columns.
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
-- VISUAL DIAGRAM: HOW LEFT JOIN WORKS
-- ============================================================
--
--   LEFT TABLE (employees)        RIGHT TABLE (departments)
--  ┌──────────────────────┐      ┌────────────────────────┐
--  │ Amit    dept_id=101  │──────│ 101 Engineering        │  ✔ Match
--  │ Priya   dept_id=102  │──────│ 102 Marketing          │  ✔ Match
--  │ Rahul   dept_id=101  │──────│ 101 Engineering        │  ✔ Match
--  │ Sneha   dept_id=103  │──────│ 103 HR                 │  ✔ Match
--  │ Vikram  dept_id=NULL │──✗   │                        │  ✔ Kept with NULLs
--  └──────────────────────┘      │ 104 Finance            │  ✗ NOT included
--                                └────────────────────────┘
--
--  RULE: Every row from the LEFT table appears in the result.
--        Vikram → included (with NULL for department columns).
--        Finance → NOT included (it is on the right side).
--


-- ============================================================
-- 1. BASIC LEFT JOIN SYNTAX
-- ============================================================

SELECT
    e.employee_id,
    e.first_name,
    d.department_name
FROM employees e
LEFT JOIN departments d
    ON e.department_id = d.department_id;

-- EXPECTED OUTPUT:
-- | employee_id | first_name | department_name |
-- |-------------|------------|-----------------|
-- | 1           | Amit       | Engineering     |
-- | 2           | Priya      | Marketing       |
-- | 3           | Rahul      | Engineering     |
-- | 4           | Sneha      | HR              |
-- | 5           | Vikram     | NULL            |
--
-- Vikram appears! His department_name is NULL because there is
-- no matching department for his NULL department_id.
-- Finance (dept 104) does NOT appear — it is on the right side.


-- ============================================================
-- 2. LEFT JOIN WITH ALL COLUMNS
-- ============================================================

SELECT
    e.employee_id,
    e.first_name,
    e.salary,
    d.department_name,
    d.location
FROM employees e
LEFT JOIN departments d
    ON e.department_id = d.department_id
ORDER BY e.employee_id;

-- EXPECTED OUTPUT:
-- | employee_id | first_name | salary | department_name | location  |
-- |-------------|------------|--------|-----------------|-----------|
-- | 1           | Amit       | 75000  | Engineering     | Bangalore |
-- | 2           | Priya      | 55000  | Marketing       | Mumbai    |
-- | 3           | Rahul      | 82000  | Engineering     | Bangalore |
-- | 4           | Sneha      | 48000  | HR              | Delhi     |
-- | 5           | Vikram     | 60000  | NULL            | NULL      |
--
-- Both department_name and location are NULL for Vikram.


-- ============================================================
-- 3. FINDING UNMATCHED ROWS (EMPLOYEES WITHOUT A DEPARTMENT)
-- ============================================================
-- This is the most powerful pattern with LEFT JOIN!
-- Filter for rows where the right table's key IS NULL.

SELECT
    e.employee_id,
    e.first_name,
    e.department_id
FROM employees e
LEFT JOIN departments d
    ON e.department_id = d.department_id
WHERE d.department_id IS NULL;

-- EXPECTED OUTPUT:
-- | employee_id | first_name | department_id |
-- |-------------|------------|---------------|
-- | 5           | Vikram     | NULL          |
--
-- This finds employees who do NOT belong to any valid department.
-- The WHERE clause filters to only those rows that had no match.


-- ============================================================
-- 4. LEFT JOIN WITH WHERE CLAUSE (FILTERING AFTER JOIN)
-- ============================================================

SELECT
    e.first_name,
    e.salary,
    d.department_name
FROM employees e
LEFT JOIN departments d
    ON e.department_id = d.department_id
WHERE e.salary >= 55000;

-- EXPECTED OUTPUT:
-- | first_name | salary | department_name |
-- |------------|--------|-----------------|
-- | Amit       | 75000  | Engineering     |
-- | Priya      | 55000  | Marketing       |
-- | Rahul      | 82000  | Engineering     |
-- | Vikram     | 60000  | NULL            |
--
-- Vikram still appears (salary 60000 >= 55000) with NULL dept.
-- Sneha (48000) is excluded by the WHERE clause.


-- ============================================================
-- 5. LEFT JOIN vs INNER JOIN — SIDE-BY-SIDE COMPARISON
-- ============================================================

-- INNER JOIN: Vikram excluded (4 rows)
SELECT e.first_name, d.department_name
FROM employees e
INNER JOIN departments d ON e.department_id = d.department_id;

-- LEFT JOIN: Vikram included with NULL (5 rows)
SELECT e.first_name, d.department_name
FROM employees e
LEFT JOIN departments d ON e.department_id = d.department_id;

-- INNER JOIN result:                LEFT JOIN result:
-- | first_name | department_name |  | first_name | department_name |
-- |------------|-----------------|  |------------|-----------------|
-- | Amit       | Engineering     |  | Amit       | Engineering     |
-- | Priya      | Marketing       |  | Priya      | Marketing       |
-- | Rahul      | Engineering     |  | Rahul      | Engineering     |
-- | Sneha      | HR              |  | Sneha      | HR              |
--                                   | Vikram     | NULL            | ← extra row


-- ============================================================
-- 6. LEFT JOIN WITH COALESCE (REPLACING NULLs)
-- ============================================================
-- COALESCE replaces NULL with a default value for cleaner output.

SELECT
    e.first_name,
    COALESCE(d.department_name, 'Unassigned') AS department,
    COALESCE(d.location, 'N/A') AS office_location
FROM employees e
LEFT JOIN departments d
    ON e.department_id = d.department_id;

-- EXPECTED OUTPUT:
-- | first_name | department  | office_location |
-- |------------|-------------|-----------------|
-- | Amit       | Engineering | Bangalore       |
-- | Priya      | Marketing   | Mumbai          |
-- | Rahul      | Engineering | Bangalore       |
-- | Sneha      | HR          | Delhi           |
-- | Vikram     | Unassigned  | N/A             |


-- ============================================================
-- 7. LEFT JOIN WITH AGGREGATE FUNCTIONS
-- ============================================================
-- Count employees per department, including Vikram under NULL.

SELECT
    COALESCE(d.department_name, 'No Department') AS department,
    COUNT(e.employee_id) AS employee_count
FROM employees e
LEFT JOIN departments d
    ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY employee_count DESC;

-- EXPECTED OUTPUT:
-- | department    | employee_count |
-- |---------------|----------------|
-- | Engineering   | 2              |
-- | Marketing     | 1              |
-- | HR            | 1              |
-- | No Department | 1              |
--
-- "No Department" captures Vikram. Finance is still absent
-- because LEFT JOIN preserves the left table, not the right.


-- ============================================================
-- 8. LEFT OUTER JOIN (EXPLICIT SYNTAX)
-- ============================================================
-- LEFT JOIN and LEFT OUTER JOIN are identical in PostgreSQL.

SELECT
    e.first_name,
    d.department_name
FROM employees e
LEFT OUTER JOIN departments d
    ON e.department_id = d.department_id;

-- EXPECTED OUTPUT: (Same as Example 1)
-- | first_name | department_name |
-- |------------|-----------------|
-- | Amit       | Engineering     |
-- | Priya      | Marketing       |
-- | Rahul      | Engineering     |
-- | Sneha      | HR              |
-- | Vikram     | NULL            |


-- ============================================================
-- 9. REAL-WORLD USE CASE: FINDING EMPLOYEES WITHOUT DEPARTMENTS
-- ============================================================
-- HR wants to identify employees not assigned to any department
-- so they can be placed into a team.

SELECT
    e.employee_id AS "ID",
    e.first_name AS "Employee",
    e.salary AS "Salary",
    'Not Assigned' AS "Status"
FROM employees e
LEFT JOIN departments d
    ON e.department_id = d.department_id
WHERE d.department_id IS NULL;

-- EXPECTED OUTPUT:
-- | ID | Employee | Salary | Status       |
-- |----|----------|--------|--------------|
-- | 5  | Vikram   | 60000  | Not Assigned |
--
-- Vikram is the only employee without a department assignment.


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. LEFT JOIN returns ALL rows from the LEFT table, always.
-- 2. If there is no match in the right table, right-side columns
--    are filled with NULL.
-- 3. Vikram (dept_id = NULL) → included with NULLs for dept info.
-- 4. Finance (dept 104) → NOT included (right side only).
-- 5. LEFT JOIN + WHERE right.key IS NULL → finds unmatched rows.
-- 6. Use COALESCE() to replace NULLs with user-friendly defaults.
-- 7. LEFT JOIN and LEFT OUTER JOIN are exactly the same.
-- 8. LEFT JOIN is essential for "find missing" queries — employees
--    without orders, students without grades, etc.
-- ============================================================
