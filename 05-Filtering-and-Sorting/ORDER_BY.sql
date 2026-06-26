-- ============================================================
-- Topic:  Advanced ORDER BY — Sorting in PostgreSQL
-- File:   ORDER_BY.sql
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
-- 1. Basic ORDER BY (ascending is the default)
-- ************************************************************

SELECT first_name, salary
FROM employees
ORDER BY salary;

-- Expected Output (lowest salary first):
-- | first_name | salary |
-- |------------|--------|
-- | Sneha      | 48000  |
-- | Karan      | 52000  |
-- | Priya      | 55000  |
-- | Vikram     | 60000  |
-- | Ananya     | 70000  |
-- | Amit       | 75000  |
-- | Rahul      | 82000  |


-- ************************************************************
-- 2. Explicit ASC and DESC
-- ************************************************************

-- Highest salary first
SELECT first_name, salary
FROM employees
ORDER BY salary DESC;

-- Expected Output:
-- | first_name | salary |
-- |------------|--------|
-- | Rahul      | 82000  |
-- | Amit       | 75000  |
-- | Ananya     | 70000  |
-- | Vikram     | 60000  |
-- | Priya      | 55000  |
-- | Karan      | 52000  |
-- | Sneha      | 48000  |


-- ************************************************************
-- 3. Multi-column sorting
--    → First sorted by department, then by salary within each department
-- ************************************************************

SELECT first_name, department, salary
FROM employees
ORDER BY department ASC, salary DESC;

-- Expected Output:
-- | first_name | department  | salary |
-- |------------|-------------|--------|
-- | Rahul      | Engineering | 82000  |
-- | Amit       | Engineering | 75000  |
-- | Ananya     | Engineering | 70000  |
-- | Sneha      | HR          | 48000  |
-- | Vikram     | Marketing   | 60000  |
-- | Priya      | Marketing   | 55000  |
-- | Karan      | Sales       | 52000  |


-- ************************************************************
-- 4. Mixed ASC/DESC across columns
-- ************************************************************

-- Sort by department ascending, then hire_date descending (newest first)
SELECT first_name, department, hire_date
FROM employees
ORDER BY department ASC, hire_date DESC;

-- Expected Output:
-- | first_name | department  | hire_date  |
-- |------------|-------------|------------|
-- | Ananya     | Engineering | 2022-09-12 |
-- | Amit       | Engineering | 2021-03-15 |
-- | Rahul      | Engineering | 2020-01-10 |
-- | Sneha      | HR          | 2023-02-20 |
-- | Priya      | Marketing   | 2022-07-01 |
-- | Vikram     | Marketing   | 2021-11-05 |
-- | Karan      | Sales       | 2023-06-01 |


-- ************************************************************
-- 5. NULLS FIRST / NULLS LAST (PostgreSQL-specific)
--    → Controls where NULL values appear in the sorted result
--    → Default: ASC → NULLS LAST, DESC → NULLS FIRST
-- ************************************************************

-- To demonstrate, let's imagine a manager_id column with some NULLs.
-- We simulate with a CASE expression:

SELECT first_name,
       CASE WHEN employee_id IN (1, 3, 7) THEN NULL
            ELSE department
       END AS nullable_dept
FROM employees
ORDER BY nullable_dept ASC NULLS FIRST;

-- Expected Output:
-- | first_name | nullable_dept |
-- |------------|---------------|
-- | Amit       | NULL          |  ← NULLs appear FIRST
-- | Rahul      | NULL          |
-- | Karan      | NULL          |
-- | Sneha      | HR            |
-- | Priya      | Marketing     |
-- | Vikram     | Marketing     |
-- | Ananya     | Engineering   |  ← wait, 'E' < 'H' alphabetically
-- Note: 'Engineering' would normally come before 'HR'.
-- Let me correct — Ananya's department is Engineering (not NULL).

-- Corrected Expected Output:
-- | first_name | nullable_dept |
-- |------------|---------------|
-- | Amit       | NULL          |
-- | Rahul      | NULL          |
-- | Karan      | NULL          |
-- | Ananya     | Engineering   |
-- | Sneha      | HR            |
-- | Priya      | Marketing     |
-- | Vikram     | Marketing     |

-- NULLS LAST (default for ASC, but can be made explicit):
SELECT first_name,
       CASE WHEN employee_id IN (1, 3, 7) THEN NULL
            ELSE department
       END AS nullable_dept
FROM employees
ORDER BY nullable_dept ASC NULLS LAST;

-- Expected Output:
-- | first_name | nullable_dept |
-- |------------|---------------|
-- | Ananya     | Engineering   |
-- | Sneha      | HR            |
-- | Priya      | Marketing     |
-- | Vikram     | Marketing     |
-- | Amit       | NULL          |  ← NULLs at the end
-- | Rahul      | NULL          |
-- | Karan      | NULL          |


-- ************************************************************
-- 6. Sorting by expression
--    → You can ORDER BY computed values, not just raw columns
-- ************************************************************

-- Sort by length of last name (shortest first)
SELECT first_name, last_name, LENGTH(last_name) AS name_length
FROM employees
ORDER BY LENGTH(last_name) ASC;

-- Expected Output:
-- | first_name | last_name | name_length |
-- |------------|-----------|-------------|
-- | Ananya     | Das       | 3           |
-- | Priya      | Verma     | 5           |
-- | Rahul      | Gupta     | 5           |
-- | Sneha      | Patel     | 5           |
-- | Vikram     | Singh     | 5           |
-- | Karan      | Mehta     | 5           |
-- | Amit       | Sharma    | 6           |

-- Sort by years of tenure (oldest hires first)
SELECT first_name, hire_date,
       EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date)) AS years_tenure
FROM employees
ORDER BY hire_date ASC;

-- Expected Output (ordered by earliest hire):
-- | first_name | hire_date  | years_tenure |
-- |------------|------------|--------------|
-- | Rahul      | 2020-01-10 | 6            |
-- | Amit       | 2021-03-15 | 5            |
-- | Vikram     | 2021-11-05 | 4            |
-- | Priya      | 2022-07-01 | 3            |
-- | Ananya     | 2022-09-12 | 3            |
-- | Sneha      | 2023-02-20 | 3            |
-- | Karan      | 2023-06-01 | 3            |


-- ************************************************************
-- 7. Case-insensitive sorting
--    → By default, PostgreSQL sort order depends on collation.
--    → Use LOWER() or UPPER() to force case-insensitive ordering.
-- ************************************************************

-- Suppose some names had mixed case like 'ananya' vs 'Ananya':
-- This ensures consistent alphabetical ordering regardless of case

SELECT first_name, last_name
FROM employees
ORDER BY LOWER(last_name) ASC;

-- Expected Output:
-- | first_name | last_name |
-- |------------|-----------|
-- | Ananya     | Das       |
-- | Rahul      | Gupta     |
-- | Karan      | Mehta     |
-- | Sneha      | Patel     |
-- | Amit       | Sharma    |
-- | Vikram     | Singh     |
-- | Priya      | Verma     |

-- You can also use COLLATE for locale-aware sorting:
SELECT first_name, last_name
FROM employees
ORDER BY last_name COLLATE "en_US";
-- (Exact collation name depends on your PostgreSQL installation)


-- ************************************************************
-- 8. ORDER BY with LIMIT — Top-N queries
-- ************************************************************

-- Top 3 highest-paid employees
SELECT first_name, last_name, salary
FROM employees
ORDER BY salary DESC
LIMIT 3;

-- Expected Output:
-- | first_name | last_name | salary |
-- |------------|-----------|--------|
-- | Rahul      | Gupta     | 82000  |
-- | Amit       | Sharma    | 75000  |
-- | Ananya     | Das       | 70000  |

-- Bottom 2 lowest-paid employees
SELECT first_name, salary
FROM employees
ORDER BY salary ASC
LIMIT 2;

-- Expected Output:
-- | first_name | salary |
-- |------------|--------|
-- | Sneha      | 48000  |
-- | Karan      | 52000  |

-- Most recently hired employee
SELECT first_name, hire_date
FROM employees
ORDER BY hire_date DESC
LIMIT 1;

-- Expected Output:
-- | first_name | hire_date  |
-- |------------|------------|
-- | Karan      | 2023-06-01 |


-- ************************************************************
-- 9. LIMIT with OFFSET — pagination
-- ************************************************************

-- Page 1: first 3 employees by name
SELECT first_name, last_name
FROM employees
ORDER BY first_name ASC
LIMIT 3 OFFSET 0;

-- Expected Output:
-- | first_name | last_name |
-- |------------|-----------|
-- | Amit       | Sharma    |
-- | Ananya     | Das       |
-- | Karan      | Mehta     |

-- Page 2: next 3 employees
SELECT first_name, last_name
FROM employees
ORDER BY first_name ASC
LIMIT 3 OFFSET 3;

-- Expected Output:
-- | first_name | last_name |
-- |------------|-----------|
-- | Priya      | Verma     |
-- | Rahul      | Gupta     |
-- | Sneha      | Patel     |


-- ************************************************************
-- 10. ORDER BY column position (ordinal number)
--     → You can refer to SELECT-list columns by their position (1-based)
--     → Useful in quick queries, but avoid in production code
-- ************************************************************

SELECT first_name, department, salary
FROM employees
ORDER BY 2 ASC, 3 DESC;
-- 2 = department (ASC), 3 = salary (DESC)

-- Expected Output (same as Example 3):
-- | first_name | department  | salary |
-- |------------|-------------|--------|
-- | Rahul      | Engineering | 82000  |
-- | Amit       | Engineering | 75000  |
-- | Ananya     | Engineering | 70000  |
-- | Sneha      | HR          | 48000  |
-- | Vikram     | Marketing   | 60000  |
-- | Priya      | Marketing   | 55000  |
-- | Karan      | Sales       | 52000  |


-- ************************************************************
-- 11. Custom sort order with CASE
--     → Define your own priority order that isn't alphabetical
-- ************************************************************

-- Sort departments in a custom business priority order
SELECT first_name, department, salary
FROM employees
ORDER BY
    CASE department
        WHEN 'Engineering' THEN 1
        WHEN 'Sales'       THEN 2
        WHEN 'Marketing'   THEN 3
        WHEN 'HR'          THEN 4
        ELSE 5
    END ASC,
    salary DESC;

-- Expected Output:
-- | first_name | department  | salary |
-- |------------|-------------|--------|
-- | Rahul      | Engineering | 82000  |
-- | Amit       | Engineering | 75000  |
-- | Ananya     | Engineering | 70000  |
-- | Karan      | Sales       | 52000  |
-- | Vikram     | Marketing   | 60000  |
-- | Priya      | Marketing   | 55000  |
-- | Sneha      | HR          | 48000  |


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1.  ORDER BY defaults to ASC (ascending). Use DESC for descending.
-- 2.  Multi-column sorting: rows are sorted by the first column,
--     then ties are broken by the second column, and so on.
-- 3.  Mix ASC and DESC freely across columns.
-- 4.  NULLS FIRST / NULLS LAST controls NULL placement
--     (default: ASC → NULLS LAST, DESC → NULLS FIRST).
-- 5.  You can sort by expressions: LENGTH(), LOWER(), EXTRACT(), etc.
-- 6.  LOWER(column) ensures case-insensitive alphabetical ordering.
-- 7.  LIMIT N returns only the top-N rows after sorting.
-- 8.  LIMIT + OFFSET enables pagination.
-- 9.  ORDER BY column_position (e.g., ORDER BY 2) works but is
--     fragile — prefer column names in production code.
-- 10. Use CASE in ORDER BY for custom sort priorities.
-- ============================================================
