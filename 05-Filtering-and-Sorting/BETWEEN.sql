-- ============================================================
-- Topic:  BETWEEN — Range Filtering in PostgreSQL
-- File:   BETWEEN.sql
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
-- 1. BETWEEN with numbers
--    → Syntax: column BETWEEN low AND high
--    → INCLUSIVE on both ends: low <= column <= high
-- ************************************************************

SELECT first_name, last_name, salary
FROM employees
WHERE salary BETWEEN 50000 AND 70000;

-- Expected Output:
-- | first_name | last_name | salary |
-- |------------|-----------|--------|
-- | Priya      | Verma     | 55000  |
-- | Vikram     | Singh     | 60000  |
-- | Ananya     | Das       | 70000  |  ← 70000 IS included (inclusive)
-- | Karan      | Mehta     | 52000  |


-- ************************************************************
-- 2. Proving BETWEEN is inclusive on BOTH ends
-- ************************************************************

-- Salary exactly at the boundary values
SELECT first_name, salary
FROM employees
WHERE salary BETWEEN 48000 AND 52000;

-- Expected Output:
-- | first_name | salary |
-- |------------|--------|
-- | Sneha      | 48000  |  ← lower bound included ✓
-- | Karan      | 52000  |  ← upper bound included ✓


-- ************************************************************
-- 3. BETWEEN with dates
--    → Very useful for filtering records in a date range
-- ************************************************************

-- Employees hired in the year 2022 (Jan 1 to Dec 31)
SELECT first_name, last_name, hire_date
FROM employees
WHERE hire_date BETWEEN '2022-01-01' AND '2022-12-31';

-- Expected Output:
-- | first_name | last_name | hire_date  |
-- |------------|-----------|------------|
-- | Priya      | Verma     | 2022-07-01 |
-- | Ananya     | Das       | 2022-09-12 |

-- Employees hired in the first half of any year (Jan–Jun) across 2021–2023
SELECT first_name, hire_date
FROM employees
WHERE hire_date BETWEEN '2021-01-01' AND '2023-06-30'
  AND EXTRACT(MONTH FROM hire_date) BETWEEN 1 AND 6;

-- Expected Output:
-- | first_name | hire_date  |
-- |------------|------------|
-- | Amit       | 2021-03-15 |
-- | Sneha      | 2023-02-20 |
-- | Karan      | 2023-06-01 |


-- ************************************************************
-- 4. NOT BETWEEN — exclude a range
-- ************************************************************

SELECT first_name, salary
FROM employees
WHERE salary NOT BETWEEN 55000 AND 75000;

-- Expected Output (salaries outside the 55K–75K range):
-- | first_name | salary |
-- |------------|--------|
-- | Rahul      | 82000  |
-- | Sneha      | 48000  |
-- | Karan      | 52000  |

-- NOT BETWEEN with dates: employees hired OUTSIDE 2022
SELECT first_name, hire_date
FROM employees
WHERE hire_date NOT BETWEEN '2022-01-01' AND '2022-12-31';

-- Expected Output:
-- | first_name | hire_date  |
-- |------------|------------|
-- | Amit       | 2021-03-15 |
-- | Rahul      | 2020-01-10 |
-- | Sneha      | 2023-02-20 |
-- | Vikram     | 2021-11-05 |
-- | Karan      | 2023-06-01 |


-- ************************************************************
-- 5. BETWEEN vs >= AND <= (equivalent alternatives)
--    → They produce identical results. Use whichever is more readable.
-- ************************************************************

-- Using BETWEEN:
SELECT first_name, salary
FROM employees
WHERE salary BETWEEN 60000 AND 80000;

-- Using >= and <= (identical result):
SELECT first_name, salary
FROM employees
WHERE salary >= 60000
  AND salary <= 80000;

-- Expected Output (both):
-- | first_name | salary |
-- |------------|--------|
-- | Amit       | 75000  |
-- | Vikram     | 60000  |
-- | Ananya     | 70000  |


-- ************************************************************
-- 6. ⚠️ BETWEEN with TIMESTAMP columns — a common pitfall
--    → For DATE columns, BETWEEN '2022-01-01' AND '2022-12-31' works fine.
--    → For TIMESTAMP columns, '2022-12-31' means '2022-12-31 00:00:00',
--      so records on Dec 31 after midnight are EXCLUDED.
--    → Fix: use '2022-12-31 23:59:59' or < '2023-01-01'.
-- ************************************************************

-- Safe pattern for TIMESTAMP columns:
-- SELECT * FROM events
-- WHERE created_at >= '2022-01-01'
--   AND created_at <  '2023-01-01';
--
-- This avoids the midnight boundary issue entirely.


-- ************************************************************
-- 7. BETWEEN with text (alphabetical range)
--    → Rarely used, but BETWEEN works on strings using collation order
-- ************************************************************

-- Last names alphabetically between 'D' and 'P' (inclusive)
SELECT first_name, last_name
FROM employees
WHERE last_name BETWEEN 'D' AND 'P';

-- Expected Output:
-- | first_name | last_name |
-- |------------|-----------|
-- | Rahul      | Gupta     |
-- | Ananya     | Das       |
-- | Karan      | Mehta     |
-- Note: 'Patel' starts with 'P' but 'Patel' > 'P', so it IS included
-- because 'Patel' >= 'D' AND 'Patel' <= 'P...' depends on collation.
-- In practice: 'Patel' > 'P' in most collations, so it is EXCLUDED.


-- ************************************************************
-- 8. Combining BETWEEN with other filters
-- ************************************************************

-- Engineering employees with salary between 65K and 80K
SELECT first_name, department, salary
FROM employees
WHERE department = 'Engineering'
  AND salary BETWEEN 65000 AND 80000;

-- Expected Output:
-- | first_name | department  | salary |
-- |------------|-------------|--------|
-- | Amit       | Engineering | 75000  |
-- | Ananya     | Engineering | 70000  |

-- Employees hired in 2021–2022 who earn more than 60K
SELECT first_name, salary, hire_date
FROM employees
WHERE hire_date BETWEEN '2021-01-01' AND '2022-12-31'
  AND salary > 60000;

-- Expected Output:
-- | first_name | salary | hire_date  |
-- |------------|--------|------------|
-- | Amit       | 75000  | 2021-03-15 |
-- | Ananya     | 70000  | 2022-09-12 |


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. BETWEEN low AND high is INCLUSIVE on both ends.
--    Equivalent to: column >= low AND column <= high.
-- 2. Works with numbers, dates, timestamps, and even text.
-- 3. NOT BETWEEN excludes the specified range.
-- 4. ⚠️ With TIMESTAMP columns, be careful with the upper bound —
--    use < next_day instead of BETWEEN to avoid midnight issues.
-- 5. The lower value must come first: BETWEEN 100 AND 50 returns
--    zero rows (there is no value >= 100 AND <= 50).
-- 6. Combine BETWEEN freely with AND, OR, and other WHERE clauses.
-- ============================================================
