-- ============================================
-- LIMIT & OFFSET — SQL Fundamentals
-- ============================================
-- LIMIT restricts the number of rows returned.
-- OFFSET skips a specified number of rows before returning results.
-- Together, they enable pagination.

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
-- 1. Basic LIMIT
-- ============================================
-- Return only the first 3 rows.

SELECT * FROM employees LIMIT 3;

-- Expected Output: First 3 rows (order depends on storage unless ORDER BY is used).

-- ============================================
-- 2. Top-N Query — LIMIT with ORDER BY
-- ============================================
-- Get the top 3 highest-paid employees.

SELECT first_name, salary
FROM employees
ORDER BY salary DESC
LIMIT 3;

-- Expected Output:
-- | first_name | salary |
-- |------------|--------|
-- | Rahul      | 82000  |
-- | Amit       | 75000  |
-- | Vikram     | 60000  |

-- ============================================
-- 3. OFFSET — Skip Rows
-- ============================================
-- Skip the first 2 rows and return the rest.

SELECT first_name, salary
FROM employees
ORDER BY salary DESC
OFFSET 2;

-- Expected Output:
-- | first_name | salary |
-- |------------|--------|
-- | Vikram     | 60000  |
-- | Priya      | 55000  |
-- | Sneha      | 48000  |

-- ============================================
-- 4. Pagination — LIMIT + OFFSET Together
-- ============================================
-- Page 1: show first 2 results
SELECT first_name, salary
FROM employees
ORDER BY employee_id
LIMIT 2 OFFSET 0;

-- Page 2: skip first 2, show next 2
SELECT first_name, salary
FROM employees
ORDER BY employee_id
LIMIT 2 OFFSET 2;

-- Page 3: skip first 4, show next 2
SELECT first_name, salary
FROM employees
ORDER BY employee_id
LIMIT 2 OFFSET 4;

-- Formula: OFFSET = (page_number - 1) * page_size

-- ============================================
-- 5. Get the Single Highest/Lowest Value
-- ============================================

-- Highest salary
SELECT first_name, salary
FROM employees
ORDER BY salary DESC
LIMIT 1;

-- Most recent hire
SELECT first_name, hire_date
FROM employees
ORDER BY hire_date DESC
LIMIT 1;

-- ============================================
-- 6. FETCH FIRST (SQL Standard Alternative)
-- ============================================
-- PostgreSQL also supports the SQL-standard FETCH syntax.

SELECT first_name, salary
FROM employees
ORDER BY salary DESC
FETCH FIRST 3 ROWS ONLY;

-- This is equivalent to LIMIT 3.

-- With OFFSET:
SELECT first_name, salary
FROM employees
ORDER BY salary DESC
OFFSET 2 ROWS
FETCH FIRST 2 ROWS ONLY;

-- ============================================
-- 7. LIMIT with WHERE
-- ============================================

SELECT first_name, salary
FROM employees
WHERE department = 'Marketing'
ORDER BY salary DESC
LIMIT 1;

-- Expected Output:
-- | first_name | salary |
-- |------------|--------|
-- | Vikram     | 60000  |

-- ============================================
-- Key Takeaways
-- ============================================
-- • LIMIT restricts how many rows are returned
-- • Always use ORDER BY with LIMIT for predictable results
-- • OFFSET skips rows — great for pagination
-- • Pagination formula: OFFSET = (page - 1) * page_size
-- • FETCH FIRST N ROWS ONLY is the SQL-standard equivalent
-- • Large OFFSET values can be slow — consider keyset pagination for big datasets
