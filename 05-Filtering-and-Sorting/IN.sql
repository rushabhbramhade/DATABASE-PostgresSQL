-- ============================================================
-- Topic:  IN Operator — Set-Based Filtering in PostgreSQL
-- File:   IN.sql
-- ============================================================
-- Sample table used throughout this file:
--
-- employees table:
-- | employee_id | first_name | last_name | department  | salary | hire_date  | email                    |
-- |-------------|------------|-----------|-------------|--------|------------|--------------------------|
-- | 1           | Amit       | Sharma    | Engineering | 75000  | 2021-03-15 | amit.sharma@mail.com     |
-- | 2           | Priya      | Verma     | Marketing   | 55000  | 2022-07-01 | priya.verma@mail.com     |
-- | 3           | Rahul      | Gupta     | Engineering | 82000  | 2020-01-10 | rahul.gupta@mail.com     |
-- | 4           | Sneha      | Patel     | HR          | 48000  | 2023-02-20 | sneha.patel@mail.com     |
-- | 5           | Vikram     | Singh     | Marketing   | 60000  | 2021-11-05 | vikram.singh@mail.com    |
-- | 6           | Ananya     | Das       | Engineering | 70000  | 2022-09-12 | ananya.das@mail.com      |
-- | 7           | Karan      | Mehta     | Sales       | 52000  | 2023-06-01 | karan.mehta@mail.com     |
-- ============================================================


-- ************************************************************
-- 1. IN with a list of values
--    → Returns rows where the column matches ANY value in the list
-- ************************************************************

SELECT first_name, last_name, department
FROM employees
WHERE department IN ('Engineering', 'Marketing');

-- Expected Output:
-- | first_name | last_name | department  |
-- |------------|-----------|-------------|
-- | Amit       | Sharma    | Engineering |
-- | Priya      | Verma     | Marketing   |
-- | Rahul      | Gupta     | Engineering |
-- | Vikram     | Singh     | Marketing   |
-- | Ananya     | Das       | Engineering |

-- IN with numeric values
SELECT first_name, salary
FROM employees
WHERE salary IN (48000, 55000, 82000);

-- Expected Output:
-- | first_name | salary |
-- |------------|--------|
-- | Priya      | 55000  |
-- | Rahul      | 82000  |
-- | Sneha      | 48000  |


-- ************************************************************
-- 2. NOT IN — exclude rows matching any value in the list
-- ************************************************************

SELECT first_name, department
FROM employees
WHERE department NOT IN ('Engineering', 'HR');

-- Expected Output:
-- | first_name | department |
-- |------------|------------|
-- | Priya      | Marketing  |
-- | Vikram     | Marketing  |
-- | Karan      | Sales      |


-- ************************************************************
-- 3. IN with a subquery
--    → Dynamically build the list from another query
-- ************************************************************

-- Find employees in departments that have more than one employee
SELECT first_name, last_name, department
FROM employees
WHERE department IN (
    SELECT department
    FROM employees
    GROUP BY department
    HAVING COUNT(*) > 1
);

-- Expected Output:
-- | first_name | last_name | department  |
-- |------------|-----------|-------------|
-- | Amit       | Sharma    | Engineering |
-- | Priya      | Verma     | Marketing   |
-- | Rahul      | Gupta     | Engineering |
-- | Vikram     | Singh     | Marketing   |
-- | Ananya     | Das       | Engineering |

-- Find employees whose salary matches the highest salary in any department
SELECT first_name, salary, department
FROM employees
WHERE salary IN (
    SELECT MAX(salary)
    FROM employees
    GROUP BY department
);

-- Expected Output:
-- | first_name | salary | department  |
-- |------------|--------|-------------|
-- | Rahul      | 82000  | Engineering |
-- | Vikram     | 60000  | Marketing   |
-- | Sneha      | 48000  | HR          |
-- | Karan      | 52000  | Sales       |


-- ************************************************************
-- 4. Comparing IN vs multiple OR conditions
--    → IN is cleaner syntax; PostgreSQL optimizes both the same way
-- ************************************************************

-- Using OR (verbose):
SELECT first_name, department
FROM employees
WHERE department = 'Engineering'
   OR department = 'Marketing'
   OR department = 'Sales';

-- Using IN (cleaner, same result):
SELECT first_name, department
FROM employees
WHERE department IN ('Engineering', 'Marketing', 'Sales');

-- Expected Output (both queries):
-- | first_name | department  |
-- |------------|-------------|
-- | Amit       | Engineering |
-- | Priya      | Marketing   |
-- | Rahul      | Engineering |
-- | Vikram     | Marketing   |
-- | Ananya     | Engineering |
-- | Karan      | Sales       |


-- ************************************************************
-- 5. ⚠️ The NULL gotcha with NOT IN
--    → If the list contains NULL, NOT IN returns NO rows at all!
--    → This is because NULL comparisons yield UNKNOWN, and
--      NOT UNKNOWN = UNKNOWN → the row is excluded.
-- ************************************************************

-- ⛔ DANGEROUS: NOT IN with a NULL in the list
SELECT first_name, department
FROM employees
WHERE department NOT IN ('Engineering', NULL);

-- Expected Output: EMPTY SET (0 rows!)
-- Reason: For each row, PostgreSQL evaluates:
--   department != 'Engineering' AND department != NULL
--   The second comparison is always UNKNOWN, making the whole AND → UNKNOWN.
--   UNKNOWN rows are filtered out.

-- ✅ SAFE ALTERNATIVE 1: Filter out NULLs explicitly
SELECT first_name, department
FROM employees
WHERE department NOT IN (
    SELECT department FROM employees WHERE department IS NOT NULL
);

-- ✅ SAFE ALTERNATIVE 2: Use NOT EXISTS instead of NOT IN
SELECT e.first_name, e.department
FROM employees e
WHERE NOT EXISTS (
    SELECT 1
    FROM (VALUES ('Engineering')) AS excluded(dept)
    WHERE excluded.dept = e.department
);

-- Expected Output:
-- | first_name | department |
-- |------------|------------|
-- | Priya      | Marketing  |
-- | Sneha      | HR         |
-- | Vikram     | Marketing  |
-- | Karan      | Sales      |


-- ************************************************************
-- 6. IN with expressions and type casting
-- ************************************************************

-- Employee IDs in a specific set (integer list)
SELECT employee_id, first_name
FROM employees
WHERE employee_id IN (1, 3, 5, 7);

-- Expected Output:
-- | employee_id | first_name |
-- |-------------|------------|
-- | 1           | Amit       |
-- | 3           | Rahul      |
-- | 5           | Vikram     |
-- | 7           | Karan      |

-- Hire year in a set of years
SELECT first_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) IN (2021, 2023);

-- Expected Output:
-- | first_name | hire_date  |
-- |------------|------------|
-- | Amit       | 2021-03-15 |
-- | Sneha      | 2023-02-20 |
-- | Vikram     | 2021-11-05 |
-- | Karan      | 2023-06-01 |


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. IN (value1, value2, ...) checks if a column matches ANY value.
-- 2. NOT IN excludes rows matching any value in the list.
-- 3. IN can take a subquery to dynamically build the value list.
-- 4. IN is equivalent to multiple OR conditions but much cleaner.
-- 5. ⚠️ NEVER use NOT IN with a list that may contain NULL —
--    it silently returns zero rows. Use NOT EXISTS instead.
-- 6. IN works with all data types: text, numbers, dates, etc.
-- ============================================================
