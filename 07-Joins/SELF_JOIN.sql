-- ============================================================
-- FILE: SELF_JOIN.sql
-- TOPIC: SELF JOIN in PostgreSQL
-- DESCRIPTION: A self join is when a table is joined to ITSELF.
--              There is no special keyword — you use INNER JOIN,
--              LEFT JOIN, etc. with two different aliases for
--              the same table.
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
-- VISUAL DIAGRAM: MANAGER-EMPLOYEE HIERARCHY
-- ============================================================
--
--           Amit (ID=1, manager_id=NULL)     ← Top-level (no manager)
--           /              \
--      Priya (ID=2)     Rahul (ID=3)         ← Report to Amit
--      manager_id=1     manager_id=1
--       /        \
--  Sneha (ID=4)  Vikram (ID=5)               ← Report to Priya
--  manager_id=2  manager_id=2
--
-- The manager_id column references employee_id in the SAME table.
-- This is what makes a self join necessary.
--


-- ============================================================
-- 1. BASIC SELF JOIN — EMPLOYEE WITH THEIR MANAGER'S NAME
-- ============================================================
-- We join the employees table to itself:
--   e = the employee row
--   m = the manager row (looked up via manager_id)

SELECT
    e.employee_id,
    e.first_name AS employee_name,
    e.manager_id,
    m.first_name AS manager_name
FROM employees e
INNER JOIN employees m
    ON e.manager_id = m.employee_id;

-- EXPECTED OUTPUT:
-- | employee_id | employee_name | manager_id | manager_name |
-- |-------------|---------------|------------|--------------|
-- | 2           | Priya         | 1          | Amit         |
-- | 3           | Rahul         | 1          | Amit         |
-- | 4           | Sneha         | 2          | Priya        |
-- | 5           | Vikram        | 2          | Priya        |
--
-- Amit is missing! His manager_id is NULL → no match in INNER JOIN.
-- INNER JOIN excludes rows with no matching manager.


-- ============================================================
-- 2. SELF JOIN WITH LEFT JOIN — INCLUDE TOP-LEVEL MANAGERS
-- ============================================================
-- Use LEFT JOIN to keep employees who have no manager (Amit).

SELECT
    e.employee_id,
    e.first_name AS employee_name,
    COALESCE(m.first_name, 'No Manager (Top Level)') AS manager_name
FROM employees e
LEFT JOIN employees m
    ON e.manager_id = m.employee_id;

-- EXPECTED OUTPUT:
-- | employee_id | employee_name | manager_name            |
-- |-------------|---------------|-------------------------|
-- | 1           | Amit          | No Manager (Top Level)  |
-- | 2           | Priya         | Amit                    |
-- | 3           | Rahul         | Amit                    |
-- | 4           | Sneha         | Priya                   |
-- | 5           | Vikram        | Priya                   |
--
-- Amit now appears with "No Manager (Top Level)" thanks to
-- LEFT JOIN + COALESCE.


-- ============================================================
-- 3. FINDING TOP-LEVEL MANAGERS (EMPLOYEES WITH NO MANAGER)
-- ============================================================

SELECT
    e.employee_id,
    e.first_name AS top_level_manager
FROM employees e
LEFT JOIN employees m
    ON e.manager_id = m.employee_id
WHERE e.manager_id IS NULL;

-- EXPECTED OUTPUT:
-- | employee_id | top_level_manager |
-- |-------------|-------------------|
-- | 1           | Amit              |
--
-- Only Amit has manager_id = NULL → he is the top-level manager.


-- ============================================================
-- 4. FINDING EMPLOYEES WHO SHARE THE SAME DEPARTMENT
-- ============================================================
-- Join the table to itself on department_id, but exclude
-- pairing an employee with themselves (e1.employee_id <> e2.employee_id).
-- Use < instead of <> to avoid duplicate pairs (A,B) and (B,A).

SELECT
    e1.first_name AS employee_1,
    e2.first_name AS employee_2,
    e1.department_id
FROM employees e1
INNER JOIN employees e2
    ON e1.department_id = e2.department_id
    AND e1.employee_id < e2.employee_id;

-- EXPECTED OUTPUT:
-- | employee_1 | employee_2 | department_id |
-- |------------|------------|---------------|
-- | Amit       | Rahul      | 101           |
--
-- Only one pair shares a department: Amit & Rahul (both in 101).
-- Using < avoids duplicates: we get (Amit, Rahul) but not (Rahul, Amit).
-- Vikram is excluded because his department_id is NULL.


-- ============================================================
-- 5. EMPLOYEES EARNING MORE THAN THEIR MANAGER
-- ============================================================

SELECT
    e.first_name AS employee_name,
    e.salary AS employee_salary,
    m.first_name AS manager_name,
    m.salary AS manager_salary,
    e.salary - m.salary AS salary_difference
FROM employees e
INNER JOIN employees m
    ON e.manager_id = m.employee_id
WHERE e.salary > m.salary;

-- EXPECTED OUTPUT:
-- | employee_name | employee_salary | manager_name | manager_salary | salary_difference |
-- |---------------|-----------------|--------------|----------------|-------------------|
-- | Rahul         | 82000           | Amit         | 75000          | 7000              |
-- | Vikram        | 60000           | Priya        | 55000          | 5000              |
--
-- Rahul earns 7,000 more than his manager Amit.
-- Vikram earns 5,000 more than his manager Priya.
-- Priya (55000) does NOT earn more than Amit (75000) → excluded.
-- Sneha (48000) does NOT earn more than Priya (55000) → excluded.


-- ============================================================
-- 6. EMPLOYEES EARNING LESS THAN THEIR MANAGER
-- ============================================================

SELECT
    e.first_name AS employee_name,
    e.salary AS employee_salary,
    m.first_name AS manager_name,
    m.salary AS manager_salary
FROM employees e
INNER JOIN employees m
    ON e.manager_id = m.employee_id
WHERE e.salary < m.salary;

-- EXPECTED OUTPUT:
-- | employee_name | employee_salary | manager_name | manager_salary |
-- |---------------|-----------------|--------------|----------------|
-- | Priya         | 55000           | Amit         | 75000          |
-- | Sneha         | 48000           | Priya        | 55000          |


-- ============================================================
-- 7. FULL ORG CHART — EMPLOYEE, MANAGER, AND DEPARTMENT
-- ============================================================
-- Combine self join with a regular join to departments.

SELECT
    e.employee_id AS "ID",
    e.first_name AS "Employee",
    COALESCE(m.first_name, '-') AS "Manager",
    COALESCE(d.department_name, 'Unassigned') AS "Department",
    e.salary AS "Salary"
FROM employees e
LEFT JOIN employees m
    ON e.manager_id = m.employee_id
LEFT JOIN departments d
    ON e.department_id = d.department_id
ORDER BY e.employee_id;

-- EXPECTED OUTPUT:
-- | ID | Employee | Manager | Department  | Salary |
-- |----|----------|---------|-------------|--------|
-- | 1  | Amit     | -       | Engineering | 75000  |
-- | 2  | Priya    | Amit    | Marketing   | 55000  |
-- | 3  | Rahul    | Amit    | Engineering | 82000  |
-- | 4  | Sneha    | Priya   | HR          | 48000  |
-- | 5  | Vikram   | Priya   | Unassigned  | 60000  |
--
-- This combines a self join (for manager name) with a regular
-- LEFT JOIN to departments (for department name).


-- ============================================================
-- 8. COUNT OF DIRECT REPORTS PER MANAGER
-- ============================================================

SELECT
    m.employee_id AS manager_id,
    m.first_name AS manager_name,
    COUNT(e.employee_id) AS direct_reports
FROM employees e
INNER JOIN employees m
    ON e.manager_id = m.employee_id
GROUP BY m.employee_id, m.first_name
ORDER BY direct_reports DESC;

-- EXPECTED OUTPUT:
-- | manager_id | manager_name | direct_reports |
-- |------------|--------------|----------------|
-- | 1          | Amit         | 2              |
-- | 2          | Priya        | 2              |
--
-- Amit manages Priya and Rahul (2 direct reports).
-- Priya manages Sneha and Vikram (2 direct reports).
-- Rahul, Sneha, and Vikram manage nobody → not listed.


-- ============================================================
-- 9. FINDING EMPLOYEES AT THE SAME SALARY LEVEL
-- ============================================================
-- Find pairs of employees earning within 10,000 of each other
-- (excluding self-pairs and duplicate pairs).

SELECT
    e1.first_name AS employee_1,
    e1.salary AS salary_1,
    e2.first_name AS employee_2,
    e2.salary AS salary_2,
    ABS(e1.salary - e2.salary) AS difference
FROM employees e1
INNER JOIN employees e2
    ON e1.employee_id < e2.employee_id
WHERE ABS(e1.salary - e2.salary) <= 10000;

-- EXPECTED OUTPUT:
-- | employee_1 | salary_1 | employee_2 | salary_2 | difference |
-- |------------|----------|------------|----------|------------|
-- | Amit       | 75000    | Rahul      | 82000    | 7000       |
-- | Priya      | 55000    | Vikram     | 60000    | 5000       |
-- | Priya      | 55000    | Sneha      | 48000    | 7000       |
--
-- These pairs have salaries within 10,000 of each other.


-- ============================================================
-- 10. REAL-WORLD USE CASE: MANAGEMENT HIERARCHY REPORT
-- ============================================================
-- HR wants a clean report showing the reporting structure with
-- hierarchy level indicators.

SELECT
    CASE
        WHEN e.manager_id IS NULL THEN '★ '
        ELSE '  └─ '
    END || e.first_name AS "Org Chart",
    e.salary AS "Salary",
    COALESCE(m.first_name, '(CEO)') AS "Reports To",
    CASE
        WHEN e.manager_id IS NULL THEN 'Executive'
        WHEN EXISTS (
            SELECT 1 FROM employees sub WHERE sub.manager_id = e.employee_id
        ) THEN 'Manager'
        ELSE 'Individual Contributor'
    END AS "Role Level"
FROM employees e
LEFT JOIN employees m
    ON e.manager_id = m.employee_id
ORDER BY
    COALESCE(e.manager_id, 0),
    e.employee_id;

-- EXPECTED OUTPUT:
-- | Org Chart    | Salary | Reports To | Role Level              |
-- |--------------|--------|------------|-------------------------|
-- | ★ Amit       | 75000  | (CEO)      | Executive               |
-- | └─ Priya     | 55000  | Amit       | Manager                 |
-- | └─ Rahul     | 82000  | Amit       | Individual Contributor  |
-- | └─ Sneha     | 48000  | Priya      | Individual Contributor  |
-- | └─ Vikram    | 60000  | Priya      | Individual Contributor  |


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. A SELF JOIN joins a table to itself — no special keyword.
-- 2. You MUST use table aliases (e1, e2 or e, m) to distinguish
--    the two "copies" of the table.
-- 3. Common use: manager-employee hierarchies using manager_id
--    that references employee_id in the same table.
-- 4. Use e1.id < e2.id (not <>) to avoid duplicate pairs.
-- 5. Use LEFT JOIN to include rows with no match (e.g., top-level
--    managers with manager_id = NULL).
-- 6. Self joins can be combined with regular joins to other tables.
-- 7. Self joins are useful for:
--    - Hierarchies (manager → employee)
--    - Finding pairs (same department, similar salary)
--    - Comparing rows within the same table
-- ============================================================
