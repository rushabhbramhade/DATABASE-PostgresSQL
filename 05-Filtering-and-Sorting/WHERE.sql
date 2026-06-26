-- ============================================================
-- Topic:  Complex WHERE Clauses in PostgreSQL
-- File:   WHERE.sql
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
-- 1. Basic WHERE with a single condition
-- ************************************************************

SELECT first_name, last_name, department
FROM employees
WHERE department = 'Engineering';

-- Expected Output:
-- | first_name | last_name | department  |
-- |------------|-----------|-------------|
-- | Amit       | Sharma    | Engineering |
-- | Rahul      | Gupta     | Engineering |
-- | Ananya     | Das       | Engineering |


-- ************************************************************
-- 2. Multiple conditions with AND
--    → Both conditions must be TRUE
-- ************************************************************

SELECT first_name, last_name, department, salary
FROM employees
WHERE department = 'Engineering'
  AND salary > 72000;

-- Expected Output:
-- | first_name | last_name | department  | salary |
-- |------------|-----------|-------------|--------|
-- | Amit       | Sharma    | Engineering | 75000  |
-- | Rahul      | Gupta     | Engineering | 82000  |


-- ************************************************************
-- 3. Multiple conditions with OR
--    → At least one condition must be TRUE
-- ************************************************************

SELECT first_name, last_name, department
FROM employees
WHERE department = 'Marketing'
   OR department = 'Sales';

-- Expected Output:
-- | first_name | last_name | department |
-- |------------|-----------|------------|
-- | Priya      | Verma     | Marketing  |
-- | Vikram     | Singh     | Marketing  |
-- | Karan      | Mehta     | Sales      |


-- ************************************************************
-- 4. Using NOT to negate a condition
-- ************************************************************

SELECT first_name, last_name, department
FROM employees
WHERE NOT department = 'Engineering';

-- Expected Output:
-- | first_name | last_name | department |
-- |------------|-----------|------------|
-- | Priya      | Verma     | Marketing  |
-- | Sneha      | Patel     | HR         |
-- | Vikram     | Singh     | Marketing  |
-- | Karan      | Mehta     | Sales      |


-- ************************************************************
-- 5. Parentheses for operator precedence
--    → AND binds tighter than OR. Use parentheses to control logic.
-- ************************************************************

-- WITHOUT parentheses (AND is evaluated first):
-- This finds: (Engineering AND salary > 70000) OR Marketing
SELECT first_name, department, salary
FROM employees
WHERE department = 'Engineering' AND salary > 70000
   OR department = 'Marketing';

-- Expected Output:
-- | first_name | department  | salary |
-- |------------|-------------|--------|
-- | Amit       | Engineering | 75000  |
-- | Priya      | Marketing   | 55000  |
-- | Rahul      | Engineering | 82000  |
-- | Vikram     | Marketing   | 60000  |

-- WITH parentheses (OR is evaluated first):
-- This finds: Engineering AND (salary > 70000 OR Marketing) → only Engineering rows
SELECT first_name, department, salary
FROM employees
WHERE department = 'Engineering'
  AND (salary > 70000 OR department = 'Marketing');

-- Expected Output:
-- | first_name | department  | salary |
-- |------------|-------------|--------|
-- | Amit       | Engineering | 75000  |
-- | Rahul      | Engineering | 82000  |


-- ************************************************************
-- 6. IS NULL / IS NOT NULL
--    → The ONLY correct way to check for NULL values.
--    → Never use = NULL or != NULL (they always return UNKNOWN).
-- ************************************************************

-- Suppose some employees have no email on record:
-- This query finds employees who DO have an email
SELECT first_name, email
FROM employees
WHERE email IS NOT NULL;

-- This query finds employees who DO NOT have an email
SELECT first_name, email
FROM employees
WHERE email IS NULL;

-- Expected Output (for IS NULL with our sample data): empty set
-- (All 7 employees have emails in this dataset.)


-- ************************************************************
-- 7. Date filtering with comparison operators
-- ************************************************************

-- Employees hired after January 1, 2022
SELECT first_name, last_name, hire_date
FROM employees
WHERE hire_date > '2022-01-01';

-- Expected Output:
-- | first_name | last_name | hire_date  |
-- |------------|-----------|------------|
-- | Priya      | Verma     | 2022-07-01 |
-- | Sneha      | Patel     | 2023-02-20 |
-- | Ananya     | Das       | 2022-09-12 |
-- | Karan      | Mehta     | 2023-06-01 |

-- Employees hired in or before the year 2021
SELECT first_name, last_name, hire_date
FROM employees
WHERE hire_date <= '2021-12-31';

-- Expected Output:
-- | first_name | last_name | hire_date  |
-- |------------|-----------|------------|
-- | Amit       | Sharma    | 2021-03-15 |
-- | Rahul      | Gupta     | 2020-01-10 |
-- | Vikram     | Singh     | 2021-11-05 |


-- ************************************************************
-- 8. EXTRACT() for filtering by date parts
--    → Pull out YEAR, MONTH, DAY, DOW (day of week), etc.
-- ************************************************************

-- Employees hired in the year 2022
SELECT first_name, last_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2022;

-- Expected Output:
-- | first_name | last_name | hire_date  |
-- |------------|-----------|------------|
-- | Priya      | Verma     | 2022-07-01 |
-- | Ananya     | Das       | 2022-09-12 |

-- Employees hired in Q1 (January–March) of any year
SELECT first_name, last_name, hire_date
FROM employees
WHERE EXTRACT(MONTH FROM hire_date) BETWEEN 1 AND 3;

-- Expected Output:
-- | first_name | last_name | hire_date  |
-- |------------|-----------|------------|
-- | Amit       | Sharma    | 2021-03-15 |
-- | Rahul      | Gupta     | 2020-01-10 |
-- | Sneha      | Patel     | 2023-02-20 |


-- ************************************************************
-- 9. Combining text and numeric filters
-- ************************************************************

-- Engineering employees earning between 70K and 80K
SELECT first_name, last_name, department, salary
FROM employees
WHERE department = 'Engineering'
  AND salary >= 70000
  AND salary <= 80000;

-- Expected Output:
-- | first_name | last_name | department  | salary |
-- |------------|-----------|-------------|--------|
-- | Amit       | Sharma    | Engineering | 75000  |
-- | Ananya     | Das       | Engineering | 70000  |

-- High earners in non-Engineering departments
SELECT first_name, department, salary
FROM employees
WHERE department != 'Engineering'
  AND salary > 50000;

-- Expected Output:
-- | first_name | department | salary |
-- |------------|------------|--------|
-- | Priya      | Marketing  | 55000  |
-- | Vikram     | Marketing  | 60000  |
-- | Karan      | Sales      | 52000  |


-- ************************************************************
-- 10. Real-world combo: multiple AND/OR/NOT together
-- ************************************************************

-- Find employees who are:
--   (a) in Engineering OR Marketing, AND
--   (b) earn more than 55000, AND
--   (c) were NOT hired in 2023
SELECT first_name, department, salary, hire_date
FROM employees
WHERE (department = 'Engineering' OR department = 'Marketing')
  AND salary > 55000
  AND EXTRACT(YEAR FROM hire_date) != 2023;

-- Expected Output:
-- | first_name | department  | salary | hire_date  |
-- |------------|-------------|--------|------------|
-- | Amit       | Engineering | 75000  | 2021-03-15 |
-- | Rahul      | Engineering | 82000  | 2020-01-10 |
-- | Vikram     | Marketing   | 60000  | 2021-11-05 |
-- | Ananya     | Engineering | 70000  | 2022-09-12 |


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. WHERE filters rows BEFORE they appear in the result set.
-- 2. AND requires ALL conditions to be true; OR requires at least ONE.
-- 3. NOT negates a condition.
-- 4. Always use parentheses when mixing AND and OR — AND binds first.
-- 5. Use IS NULL / IS NOT NULL to test for missing values (never = NULL).
-- 6. Date columns support standard comparison operators (>, <, >=, <=, =).
-- 7. EXTRACT(part FROM date) lets you filter by year, month, day, etc.
-- 8. Combine text, numeric, and date filters freely in a single WHERE.
-- ============================================================
