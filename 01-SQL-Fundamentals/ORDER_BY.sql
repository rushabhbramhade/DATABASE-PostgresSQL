-- ============================================
-- ORDER BY Clause — SQL Fundamentals
-- ============================================
-- ORDER BY sorts the result set by one or more columns.
-- Default sort order is ASC (ascending). Use DESC for descending.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Sample Table: employees
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- | employee_id | first_name | last_name | department  | salary | hire_date  |
-- |-------------|------------|-----------|-------------|--------|------------|
-- | 1           | Amit       | Sharma    | Engineering | 75000  | 2021-03-15 |
-- | 2           | Priya      | Verma     | Marketing   | 55000  | 2022-07-01 |
-- | 3           | Rahul      | Gupta     | Engineering | 82000  | 2020-01-10 |
-- | 4           | Sneha      | Patel     | HR          | 48000  | 2023-02-20 |
-- | 5           | Vikram     | Singh     | Marketing   | 60000  | 2021-11-05 |

-- ============================================
-- 1. Sort by a Single Column (Ascending)
-- ============================================

SELECT first_name, salary
FROM employees
ORDER BY salary ASC;

-- Expected Output:
-- | first_name | salary |
-- |------------|--------|
-- | Sneha      | 48000  |
-- | Priya      | 55000  |
-- | Vikram     | 60000  |
-- | Amit       | 75000  |
-- | Rahul      | 82000  |

-- ============================================
-- 2. Sort by a Single Column (Descending)
-- ============================================

SELECT first_name, salary
FROM employees
ORDER BY salary DESC;

-- Expected Output:
-- | first_name | salary |
-- |------------|--------|
-- | Rahul      | 82000  |
-- | Amit       | 75000  |
-- | Vikram     | 60000  |
-- | Priya      | 55000  |
-- | Sneha      | 48000  |

-- ============================================
-- 3. Sort by Multiple Columns
-- ============================================
-- First sorts by department, then by salary within each department.

SELECT first_name, department, salary
FROM employees
ORDER BY department ASC, salary DESC;

-- Expected Output:
-- | first_name | department  | salary |
-- |------------|-------------|--------|
-- | Rahul      | Engineering | 82000  |
-- | Amit       | Engineering | 75000  |
-- | Sneha      | HR          | 48000  |
-- | Vikram     | Marketing   | 60000  |
-- | Priya      | Marketing   | 55000  |

-- ============================================
-- 4. Sort by Column Position (Index)
-- ============================================
-- You can reference columns by their position in the SELECT list.
-- 1 = first column, 2 = second column, etc.

SELECT first_name, salary
FROM employees
ORDER BY 2 DESC;   -- Sorts by salary (2nd column)

-- ============================================
-- 5. Sort by an Expression
-- ============================================

SELECT first_name, salary, salary * 12 AS annual_income
FROM employees
ORDER BY salary * 12 DESC;

-- ============================================
-- 6. Sort Alphabetically by Text
-- ============================================

SELECT first_name, last_name
FROM employees
ORDER BY last_name ASC;

-- Expected Output:
-- | first_name | last_name |
-- |------------|-----------|
-- | Rahul      | Gupta     |
-- | Sneha      | Patel     |
-- | Amit       | Sharma    |
-- | Vikram     | Singh     |
-- | Priya      | Verma     |

-- ============================================
-- 7. Sort by Date
-- ============================================

SELECT first_name, hire_date
FROM employees
ORDER BY hire_date ASC;

-- Returns employees from earliest hire to most recent.

-- ============================================
-- 8. Handling NULLs in ORDER BY
-- ============================================
-- PostgreSQL puts NULLs last in ASC, first in DESC by default.
-- Override with NULLS FIRST or NULLS LAST.

SELECT first_name, manager_id
FROM employees
ORDER BY manager_id ASC NULLS FIRST;

SELECT first_name, manager_id
FROM employees
ORDER BY manager_id ASC NULLS LAST;

-- ============================================
-- 9. ORDER BY with WHERE
-- ============================================

SELECT first_name, department, salary
FROM employees
WHERE department = 'Engineering'
ORDER BY salary DESC;

-- Expected Output:
-- | first_name | department  | salary |
-- |------------|-------------|--------|
-- | Rahul      | Engineering | 82000  |
-- | Amit       | Engineering | 75000  |

-- ============================================
-- Key Takeaways
-- ============================================
-- • ORDER BY sorts results; default is ASC
-- • Use DESC for largest/newest first
-- • Multi-column sorting applies left to right
-- • NULLS FIRST / NULLS LAST controls NULL placement
-- • ORDER BY runs AFTER WHERE filtering
-- • Avoid ORDER BY column-position in production (fragile)
