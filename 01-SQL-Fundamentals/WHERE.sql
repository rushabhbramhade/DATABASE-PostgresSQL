-- ============================================
-- WHERE Clause — SQL Fundamentals
-- ============================================
-- The WHERE clause filters rows based on a condition.
-- Only rows that satisfy the condition are returned.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Sample Table: employees
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- | employee_id | first_name | last_name | department  | salary | hire_date  | manager_id |
-- |-------------|------------|-----------|-------------|--------|------------|------------|
-- | 1           | Amit       | Sharma    | Engineering | 75000  | 2021-03-15 | NULL       |
-- | 2           | Priya      | Verma     | Marketing   | 55000  | 2022-07-01 | 1          |
-- | 3           | Rahul      | Gupta     | Engineering | 82000  | 2020-01-10 | 1          |
-- | 4           | Sneha      | Patel     | HR          | 48000  | 2023-02-20 | 1          |
-- | 5           | Vikram     | Singh     | Marketing   | 60000  | 2021-11-05 | 2          |

-- ============================================
-- 1. Comparison Operators
-- ============================================

-- Equal to
SELECT * FROM employees WHERE department = 'Engineering';

-- Not equal to
SELECT * FROM employees WHERE department != 'HR';
SELECT * FROM employees WHERE department <> 'HR';  -- Same result

-- Greater than
SELECT first_name, salary FROM employees WHERE salary > 60000;

-- Less than or equal to
SELECT first_name, salary FROM employees WHERE salary <= 55000;

-- Expected Output (salary > 60000):
-- | first_name | salary |
-- |------------|--------|
-- | Amit       | 75000  |
-- | Rahul      | 82000  |

-- ============================================
-- 2. Logical Operators — AND, OR, NOT
-- ============================================

-- AND: both conditions must be true
SELECT first_name, department, salary
FROM employees
WHERE department = 'Engineering' AND salary > 70000;

-- OR: at least one condition must be true
SELECT first_name, department, salary
FROM employees
WHERE department = 'Engineering' OR department = 'Marketing';

-- NOT: negates a condition
SELECT first_name, department
FROM employees
WHERE NOT department = 'HR';

-- ============================================
-- 3. Combining AND and OR (use parentheses!)
-- ============================================
-- Parentheses control evaluation order — always use them for clarity.

SELECT first_name, department, salary
FROM employees
WHERE (department = 'Engineering' OR department = 'Marketing')
  AND salary > 55000;

-- Expected Output:
-- | first_name | department  | salary |
-- |------------|-------------|--------|
-- | Amit       | Engineering | 75000  |
-- | Rahul      | Engineering | 82000  |
-- | Vikram     | Marketing   | 60000  |

-- ============================================
-- 4. IS NULL and IS NOT NULL
-- ============================================
-- NULL means "unknown" or "missing". You cannot use = to compare NULL.

-- Find employees with no manager
SELECT first_name FROM employees WHERE manager_id IS NULL;

-- Find employees who have a manager
SELECT first_name FROM employees WHERE manager_id IS NOT NULL;

-- WRONG: This will not work as expected!
-- SELECT * FROM employees WHERE manager_id = NULL;

-- ============================================
-- 5. WHERE with Dates
-- ============================================

-- Hired after 2022
SELECT first_name, hire_date
FROM employees
WHERE hire_date > '2022-01-01';

-- Hired in a specific year using EXTRACT
SELECT first_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2021;

-- Expected Output (year = 2021):
-- | first_name | hire_date  |
-- |------------|------------|
-- | Amit       | 2021-03-15 |
-- | Vikram     | 2021-11-05 |

-- ============================================
-- 6. WHERE with Text Functions
-- ============================================

-- Case-insensitive comparison using LOWER()
SELECT * FROM employees
WHERE LOWER(department) = 'engineering';

-- Check string length
SELECT first_name FROM employees
WHERE LENGTH(first_name) > 5;

-- ============================================
-- Key Takeaways
-- ============================================
-- • WHERE filters rows BEFORE they appear in results
-- • Use AND / OR / NOT for compound conditions
-- • Always use parentheses for complex conditions
-- • Use IS NULL (not = NULL) to check for missing values
-- • Date comparisons work with standard 'YYYY-MM-DD' format
-- • EXTRACT() pulls parts (YEAR, MONTH, DAY) from dates
