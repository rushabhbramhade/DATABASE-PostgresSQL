-- ============================================================
-- FILE: FULL_JOIN.sql
-- TOPIC: FULL OUTER JOIN in PostgreSQL
-- DESCRIPTION: Returns ALL rows from BOTH tables. Matching rows
--              are combined. Non-matching rows from either side
--              appear with NULLs for the other table's columns.
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
-- VISUAL DIAGRAM: HOW FULL OUTER JOIN WORKS
-- ============================================================
--
--   LEFT TABLE (employees)        RIGHT TABLE (departments)
--  ┌──────────────────────┐      ┌────────────────────────┐
--  │ Amit    dept_id=101  │──────│ 101 Engineering        │  ✔ Match
--  │ Priya   dept_id=102  │──────│ 102 Marketing          │  ✔ Match
--  │ Rahul   dept_id=101  │──────│ 101 Engineering        │  ✔ Match
--  │ Sneha   dept_id=103  │──────│ 103 HR                 │  ✔ Match
--  │ Vikram  dept_id=NULL │  ✗   │                        │  ✔ Kept (NULL dept)
--  └──────────────────────┘      │ 104 Finance            │  ✔ Kept (NULL emp)
--                                └────────────────────────┘
--
--  RULE: EVERY row from BOTH tables appears in the result.
--        Vikram  → included (with NULL department info)
--        Finance → included (with NULL employee info)
--        Nothing is lost!
--


-- ============================================================
-- 1. BASIC FULL OUTER JOIN SYNTAX
-- ============================================================

SELECT
    e.employee_id,
    e.first_name,
    d.department_id,
    d.department_name
FROM employees e
FULL OUTER JOIN departments d
    ON e.department_id = d.department_id;

-- EXPECTED OUTPUT:
-- | employee_id | first_name | department_id | department_name |
-- |-------------|------------|---------------|-----------------|
-- | 1           | Amit       | 101           | Engineering     |
-- | 3           | Rahul      | 101           | Engineering     |
-- | 2           | Priya      | 102           | Marketing       |
-- | 4           | Sneha      | 103           | HR              |
-- | 5           | Vikram     | NULL          | NULL            |
-- | NULL        | NULL       | 104           | Finance         |
--
-- Vikram appears with NULL department info (no matching dept).
-- Finance appears with NULL employee info (no employees assigned).


-- ============================================================
-- 2. FULL JOIN WITH ALL COLUMNS
-- ============================================================

SELECT
    e.employee_id,
    e.first_name,
    e.salary,
    d.department_name,
    d.location
FROM employees e
FULL OUTER JOIN departments d
    ON e.department_id = d.department_id
ORDER BY e.employee_id NULLS LAST;

-- EXPECTED OUTPUT:
-- | employee_id | first_name | salary | department_name | location  |
-- |-------------|------------|--------|-----------------|-----------|
-- | 1           | Amit       | 75000  | Engineering     | Bangalore |
-- | 2           | Priya      | 55000  | Marketing       | Mumbai    |
-- | 3           | Rahul      | 82000  | Engineering     | Bangalore |
-- | 4           | Sneha      | 48000  | HR              | Delhi     |
-- | 5           | Vikram     | 60000  | NULL            | NULL      |
-- | NULL        | NULL       | NULL   | Finance         | Hyderabad |
--
-- NULLS LAST puts the Finance row (NULL employee_id) at the bottom.


-- ============================================================
-- 3. FINDING ALL UNMATCHED ROWS FROM BOTH SIDES
-- ============================================================
-- This finds rows that exist in only ONE of the two tables.

SELECT
    e.employee_id,
    e.first_name,
    d.department_id,
    d.department_name
FROM employees e
FULL OUTER JOIN departments d
    ON e.department_id = d.department_id
WHERE e.employee_id IS NULL
   OR d.department_id IS NULL;

-- EXPECTED OUTPUT:
-- | employee_id | first_name | department_id | department_name |
-- |-------------|------------|---------------|-----------------|
-- | 5           | Vikram     | NULL          | NULL            |
-- | NULL        | NULL       | 104           | Finance         |
--
-- Two unmatched rows:
--   Vikram → employee without a department
--   Finance → department without employees


-- ============================================================
-- 4. FINDING ONLY LEFT-SIDE UNMATCHED (EMPLOYEES WITHOUT DEPT)
-- ============================================================

SELECT
    e.employee_id,
    e.first_name
FROM employees e
FULL OUTER JOIN departments d
    ON e.department_id = d.department_id
WHERE d.department_id IS NULL;

-- EXPECTED OUTPUT:
-- | employee_id | first_name |
-- |-------------|------------|
-- | 5           | Vikram     |


-- ============================================================
-- 5. FINDING ONLY RIGHT-SIDE UNMATCHED (DEPTS WITHOUT EMPLOYEES)
-- ============================================================

SELECT
    d.department_id,
    d.department_name,
    d.location
FROM employees e
FULL OUTER JOIN departments d
    ON e.department_id = d.department_id
WHERE e.employee_id IS NULL;

-- EXPECTED OUTPUT:
-- | department_id | department_name | location  |
-- |---------------|-----------------|-----------|
-- | 104           | Finance         | Hyderabad |


-- ============================================================
-- 6. FULL JOIN vs OTHER JOINS — COMPARISON
-- ============================================================

-- INNER JOIN: 4 rows (only matches)
-- LEFT JOIN:  5 rows (all employees + matching depts)
-- RIGHT JOIN: 5 rows (all depts + matching employees)
-- FULL JOIN:  6 rows (everything from both sides)

-- Comparison table:
-- | Join Type  | Amit | Priya | Rahul | Sneha | Vikram | Finance |
-- |------------|------|-------|-------|-------|--------|---------|
-- | INNER JOIN |  ✔   |  ✔    |  ✔    |  ✔    |  ✗     |  ✗      |
-- | LEFT JOIN  |  ✔   |  ✔    |  ✔    |  ✔    |  ✔     |  ✗      |
-- | RIGHT JOIN |  ✔   |  ✔    |  ✔    |  ✔    |  ✗     |  ✔      |
-- | FULL JOIN  |  ✔   |  ✔    |  ✔    |  ✔    |  ✔     |  ✔      |


-- ============================================================
-- 7. FULL JOIN WITH COALESCE (CLEAN OUTPUT)
-- ============================================================

SELECT
    COALESCE(e.first_name, '-- No Employee --') AS employee,
    COALESCE(e.salary::TEXT, 'N/A') AS salary,
    COALESCE(d.department_name, '-- No Department --') AS department,
    COALESCE(d.location, 'N/A') AS location
FROM employees e
FULL OUTER JOIN departments d
    ON e.department_id = d.department_id
ORDER BY e.employee_id NULLS LAST;

-- EXPECTED OUTPUT:
-- | employee         | salary | department       | location  |
-- |------------------|--------|------------------|-----------|
-- | Amit             | 75000  | Engineering      | Bangalore |
-- | Priya            | 55000  | Marketing        | Mumbai    |
-- | Rahul            | 82000  | Engineering      | Bangalore |
-- | Sneha            | 48000  | HR               | Delhi     |
-- | Vikram           | 60000  | -- No Department -- | N/A    |
-- | -- No Employee --| N/A    | Finance          | Hyderabad |


-- ============================================================
-- 8. FULL JOIN WITH AGGREGATE FUNCTIONS
-- ============================================================
-- Summarize all departments including those with no employees,
-- and capture unassigned employees under "No Department".

SELECT
    COALESCE(d.department_name, 'No Department') AS department,
    COUNT(e.employee_id) AS employee_count,
    COALESCE(SUM(e.salary), 0) AS total_salary
FROM employees e
FULL OUTER JOIN departments d
    ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY total_salary DESC;

-- EXPECTED OUTPUT:
-- | department    | employee_count | total_salary |
-- |---------------|----------------|--------------|
-- | Engineering   | 2              | 157000       |
-- | Vikram (None) | 1              | 60000        |
-- | Marketing     | 1              | 55000        |
-- | HR            | 1              | 48000        |
-- | Finance       | 0              | 0            |


-- ============================================================
-- 9. FULL JOIN (SHORT SYNTAX)
-- ============================================================
-- FULL JOIN and FULL OUTER JOIN are identical in PostgreSQL.

SELECT
    e.first_name,
    d.department_name
FROM employees e
FULL JOIN departments d
    ON e.department_id = d.department_id;

-- EXPECTED OUTPUT: (Same as Example 1)
-- | first_name | department_name |
-- |------------|-----------------|
-- | Amit       | Engineering     |
-- | Rahul      | Engineering     |
-- | Priya      | Marketing       |
-- | Sneha      | HR              |
-- | Vikram     | NULL            |
-- | NULL       | Finance         |


-- ============================================================
-- 10. REAL-WORLD USE CASE: DATA RECONCILIATION REPORT
-- ============================================================
-- Finance team needs to reconcile employee assignments with
-- department records. Flag mismatches from both sides.

SELECT
    COALESCE(e.employee_id::TEXT, '-') AS "Emp ID",
    COALESCE(e.first_name, '-') AS "Employee",
    COALESCE(d.department_name, '-') AS "Department",
    CASE
        WHEN e.employee_id IS NOT NULL AND d.department_id IS NOT NULL
            THEN 'Matched'
        WHEN e.employee_id IS NOT NULL AND d.department_id IS NULL
            THEN 'Employee has no department'
        WHEN e.employee_id IS NULL AND d.department_id IS NOT NULL
            THEN 'Department has no employees'
    END AS "Reconciliation Status"
FROM employees e
FULL OUTER JOIN departments d
    ON e.department_id = d.department_id
ORDER BY
    CASE
        WHEN e.employee_id IS NOT NULL AND d.department_id IS NOT NULL THEN 1
        WHEN e.employee_id IS NOT NULL THEN 2
        ELSE 3
    END;

-- EXPECTED OUTPUT:
-- | Emp ID | Employee | Department  | Reconciliation Status        |
-- |--------|----------|-------------|------------------------------|
-- | 1      | Amit     | Engineering | Matched                      |
-- | 3      | Rahul    | Engineering | Matched                      |
-- | 2      | Priya    | Marketing   | Matched                      |
-- | 4      | Sneha    | HR          | Matched                      |
-- | 5      | Vikram   | -           | Employee has no department    |
-- | -      | -        | Finance     | Department has no employees   |


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. FULL OUTER JOIN returns ALL rows from BOTH tables.
-- 2. Matched rows are combined normally.
-- 3. Unmatched rows from either side appear with NULLs.
-- 4. Vikram (no dept) → included with NULL department info.
-- 5. Finance (no employees) → included with NULL employee info.
-- 6. FULL JOIN and FULL OUTER JOIN are identical syntax.
-- 7. Use WHERE left.key IS NULL OR right.key IS NULL to find
--    all unmatched rows from both sides.
-- 8. Perfect for reconciliation reports where you need to find
--    gaps, mismatches, or orphaned records in both datasets.
-- 9. FULL OUTER JOIN = LEFT JOIN ∪ RIGHT JOIN (union of both).
-- ============================================================
