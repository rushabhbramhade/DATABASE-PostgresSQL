-- ============================================
-- SELECT Statement — SQL Fundamentals
-- ============================================
-- The SELECT statement retrieves data from one or more tables.
-- It is the most frequently used SQL command.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Sample Table: employees
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- | employee_id | first_name | last_name | email                  | department  | salary | hire_date  |
-- |-------------|------------|-----------|------------------------|-------------|--------|------------|
-- | 1           | Amit       | Sharma    | amit.sharma@mail.com   | Engineering | 75000  | 2021-03-15 |
-- | 2           | Priya      | Verma     | priya.verma@mail.com   | Marketing   | 55000  | 2022-07-01 |
-- | 3           | Rahul      | Gupta     | rahul.gupta@mail.com   | Engineering | 82000  | 2020-01-10 |
-- | 4           | Sneha      | Patel     | sneha.patel@mail.com   | HR          | 48000  | 2023-02-20 |
-- | 5           | Vikram     | Singh     | vikram.singh@mail.com  | Marketing   | 60000  | 2021-11-05 |

-- ============================================
-- 1. Select All Columns
-- ============================================
-- Retrieves every column and every row from the table.
-- Use sparingly in production — fetching all columns wastes bandwidth.

SELECT * FROM employees;

-- Expected Output: All 5 rows with all 7 columns.

-- ============================================
-- 2. Select Specific Columns
-- ============================================
-- Best practice: always specify the columns you need.

SELECT first_name, last_name, email
FROM employees;

-- Expected Output:
-- | first_name | last_name | email                  |
-- |------------|-----------|------------------------|
-- | Amit       | Sharma    | amit.sharma@mail.com   |
-- | Priya      | Verma     | priya.verma@mail.com   |
-- | Rahul      | Gupta     | rahul.gupta@mail.com   |
-- | Sneha      | Patel     | sneha.patel@mail.com   |
-- | Vikram     | Singh     | vikram.singh@mail.com  |

-- ============================================
-- 3. Using Column Aliases (AS)
-- ============================================
-- Aliases rename columns in the result set for readability.

SELECT
    first_name AS "First Name",
    last_name  AS "Last Name",
    salary     AS "Annual Salary"
FROM employees;

-- Expected Output:
-- | First Name | Last Name | Annual Salary |
-- |------------|-----------|---------------|
-- | Amit       | Sharma    | 75000         |
-- | Priya      | Verma     | 55000         |
-- | ...        | ...       | ...           |

-- ============================================
-- 4. Arithmetic Expressions in SELECT
-- ============================================
-- You can perform calculations directly in your query.

SELECT
    first_name,
    salary,
    salary * 12 AS annual_income,
    salary * 0.10 AS tax_deduction
FROM employees;

-- Expected Output:
-- | first_name | salary | annual_income | tax_deduction |
-- |------------|--------|---------------|---------------|
-- | Amit       | 75000  | 900000        | 7500.00       |
-- | Priya      | 55000  | 660000        | 5500.00       |

-- ============================================
-- 5. String Concatenation
-- ============================================
-- Use || to join strings together in PostgreSQL.

SELECT
    first_name || ' ' || last_name AS full_name,
    email
FROM employees;

-- Expected Output:
-- | full_name      | email                  |
-- |----------------|------------------------|
-- | Amit Sharma    | amit.sharma@mail.com   |
-- | Priya Verma    | priya.verma@mail.com   |

-- ============================================
-- 6. DISTINCT — Remove Duplicate Values
-- ============================================
-- Returns only unique values in the specified column(s).

SELECT DISTINCT department
FROM employees;

-- Expected Output:
-- | department  |
-- |-------------|
-- | Engineering |
-- | Marketing   |
-- | HR          |

-- ============================================
-- 7. Counting Rows with SELECT
-- ============================================

SELECT COUNT(*) AS total_employees
FROM employees;

-- Expected Output:
-- | total_employees |
-- |-----------------|
-- | 5               |

-- ============================================
-- 8. Using CASE in SELECT
-- ============================================
-- Conditional logic inside a SELECT statement.

SELECT
    first_name,
    salary,
    CASE
        WHEN salary >= 70000 THEN 'Senior'
        WHEN salary >= 50000 THEN 'Mid-Level'
        ELSE 'Junior'
    END AS level
FROM employees;

-- Expected Output:
-- | first_name | salary | level     |
-- |------------|--------|-----------|
-- | Amit       | 75000  | Senior    |
-- | Priya      | 55000  | Mid-Level |
-- | Rahul      | 82000  | Senior    |
-- | Sneha      | 48000  | Junior    |
-- | Vikram     | 60000  | Mid-Level |

-- ============================================
-- 9. Selecting from a Subquery
-- ============================================

SELECT full_name, department
FROM (
    SELECT
        first_name || ' ' || last_name AS full_name,
        department
    FROM employees
) AS emp_names;

-- ============================================
-- Key Takeaways
-- ============================================
-- • Always specify columns instead of using SELECT *
-- • Use aliases (AS) to make output readable
-- • DISTINCT removes duplicates
-- • CASE adds conditional logic inside queries
-- • String concatenation in PostgreSQL uses ||
