-- ============================================================================
-- WINDOW FUNCTIONS IN POSTGRESQL
-- ============================================================================
-- A window function performs a calculation across a SET OF ROWS that are
-- somehow related to the current row — called a "window" or "window frame".
--
-- Unlike GROUP BY (which collapses rows), window functions KEEP every row
-- in the result while adding computed columns alongside them.
--
-- General Syntax:
--   function_name(args) OVER (
--       [PARTITION BY column(s)]       -- divide rows into groups
--       [ORDER BY column(s)]           -- define row ordering within partition
--       [ROWS/RANGE BETWEEN ... ]      -- define the window frame
--   )
--
-- PARTITION BY vs GROUP BY:
-- ┌──────────────────────────┬────────────────────────────────────┐
-- │ GROUP BY                 │ PARTITION BY (Window Functions)    │
-- ├──────────────────────────┼────────────────────────────────────┤
-- │ Collapses rows into one  │ Keeps all individual rows          │
-- │ per group                │                                    │
-- │ Only aggregated columns  │ All columns available + computed   │
-- │ in SELECT                │ window column                      │
-- │ Cannot mix detail &      │ Detail & aggregate side by side    │
-- │ aggregate                │                                    │
-- └──────────────────────────┴────────────────────────────────────┘
-- ============================================================================


-- ============================================================================
-- SAMPLE TABLE SETUP
-- ============================================================================

DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS monthly_sales CASCADE;
DROP TABLE IF EXISTS student_scores CASCADE;

CREATE TABLE employees (
    emp_id       SERIAL PRIMARY KEY,
    name         VARCHAR(50) NOT NULL,
    department   VARCHAR(30) NOT NULL,
    designation  VARCHAR(40),
    salary       NUMERIC(10, 2) NOT NULL,
    hire_date    DATE NOT NULL
);

INSERT INTO employees (name, department, designation, salary, hire_date) VALUES
('Alice Johnson',   'Engineering',  'Senior Developer',   95000,  '2019-03-15'),
('Bob Smith',       'Engineering',  'Junior Developer',   65000,  '2022-01-10'),
('Charlie Brown',   'Engineering',  'Tech Lead',         120000,  '2017-06-20'),
('Diana Prince',    'Engineering',  'Developer',          78000,  '2021-08-05'),
('Eve Williams',    'Marketing',    'Marketing Manager',  88000,  '2018-11-01'),
('Frank Miller',    'Marketing',    'Content Specialist', 55000,  '2023-02-14'),
('Grace Lee',       'Marketing',    'SEO Analyst',        62000,  '2021-05-22'),
('Henry Davis',     'Sales',        'Sales Director',    105000,  '2016-09-30'),
('Ivy Chen',        'Sales',        'Account Executive',  72000,  '2020-04-18'),
('Jack Wilson',     'Sales',        'Sales Rep',          58000,  '2023-07-01'),
('Karen Taylor',    'HR',           'HR Manager',         82000,  '2019-01-08'),
('Leo Martinez',    'HR',           'Recruiter',          56000,  '2022-09-12');

-- Monthly sales data for running totals and time-based analysis
CREATE TABLE monthly_sales (
    sale_id      SERIAL PRIMARY KEY,
    salesperson  VARCHAR(50),
    region       VARCHAR(30),
    sale_month   DATE,
    amount       NUMERIC(12, 2)
);

INSERT INTO monthly_sales (salesperson, region, sale_month, amount) VALUES
('Henry',  'North', '2024-01-01', 15000),
('Henry',  'North', '2024-02-01', 22000),
('Henry',  'North', '2024-03-01', 18000),
('Henry',  'North', '2024-04-01', 25000),
('Henry',  'North', '2024-05-01', 19000),
('Henry',  'North', '2024-06-01', 28000),
('Ivy',    'South', '2024-01-01', 12000),
('Ivy',    'South', '2024-02-01', 14000),
('Ivy',    'South', '2024-03-01', 19000),
('Ivy',    'South', '2024-04-01', 16000),
('Ivy',    'South', '2024-05-01', 21000),
('Ivy',    'South', '2024-06-01', 23000),
('Jack',   'North', '2024-01-01',  9000),
('Jack',   'North', '2024-02-01', 11000),
('Jack',   'North', '2024-03-01', 13000),
('Jack',   'North', '2024-04-01', 10000),
('Jack',   'North', '2024-05-01', 15000),
('Jack',   'North', '2024-06-01', 17000);


-- ============================================================================
-- EXAMPLE 1: ROW_NUMBER() — Unique Sequential Number
-- ============================================================================
-- Assigns a unique, consecutive integer to each row within its partition.
-- No ties — even identical values get different numbers.

SELECT
    name,
    department,
    salary,
    ROW_NUMBER() OVER (ORDER BY salary DESC) AS overall_rank,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS dept_rank
FROM employees;

-- Expected Output:
-- ┌─────────────────┬─────────────┬──────────┬──────────────┬───────────┐
-- │ name            │ department  │ salary   │ overall_rank │ dept_rank │
-- ├─────────────────┼─────────────┼──────────┼──────────────┼───────────┤
-- │ Charlie Brown   │ Engineering │ 120000   │ 1            │ 1         │
-- │ Henry Davis     │ Sales       │ 105000   │ 2            │ 1         │
-- │ Alice Johnson   │ Engineering │  95000   │ 3            │ 2         │
-- │ Eve Williams    │ Marketing   │  88000   │ 4            │ 1         │
-- │ Karen Taylor    │ HR          │  82000   │ 5            │ 1         │
-- │ Diana Prince    │ Engineering │  78000   │ 6            │ 3         │
-- │ Ivy Chen        │ Sales       │  72000   │ 7            │ 2         │
-- │ Bob Smith       │ Engineering │  65000   │ 8            │ 4         │
-- │ Grace Lee       │ Marketing   │  62000   │ 9            │ 2         │
-- │ Jack Wilson     │ Sales       │  58000   │ 10           │ 3         │
-- │ Leo Martinez    │ HR          │  56000   │ 11           │ 2         │
-- │ Frank Miller    │ Marketing   │  55000   │ 12           │ 3         │
-- └─────────────────┴─────────────┴──────────┴──────────────┴───────────┘


-- ============================================================================
-- EXAMPLE 2: RANK() vs DENSE_RANK() — Handling Ties
-- ============================================================================
-- RANK()       — Ties get the same rank, then SKIPS numbers (1, 2, 2, 4)
-- DENSE_RANK() — Ties get the same rank, NO skipping       (1, 2, 2, 3)

-- Let's add a duplicate salary to illustrate
UPDATE employees SET salary = 78000 WHERE name = 'Ivy Chen';

SELECT
    name,
    department,
    salary,
    RANK()       OVER (ORDER BY salary DESC) AS rank_with_gaps,
    DENSE_RANK() OVER (ORDER BY salary DESC) AS rank_no_gaps
FROM employees;

-- Expected Output (notice salary 78000 appears twice):
-- ┌─────────────────┬─────────────┬──────────┬────────────────┬──────────────┐
-- │ name            │ department  │ salary   │ rank_with_gaps │ rank_no_gaps │
-- ├─────────────────┼─────────────┼──────────┼────────────────┼──────────────┤
-- │ Charlie Brown   │ Engineering │ 120000   │ 1              │ 1            │
-- │ Henry Davis     │ Sales       │ 105000   │ 2              │ 2            │
-- │ Alice Johnson   │ Engineering │  95000   │ 3              │ 3            │
-- │ Eve Williams    │ Marketing   │  88000   │ 4              │ 4            │
-- │ Karen Taylor    │ HR          │  82000   │ 5              │ 5            │
-- │ Diana Prince    │ Engineering │  78000   │ 6              │ 6            │
-- │ Ivy Chen        │ Sales       │  78000   │ 6              │ 6            │  ← tie
-- │ Bob Smith       │ Engineering │  65000   │ 8              │ 7            │  ← 8 vs 7
-- │ Grace Lee       │ Marketing   │  62000   │ 9              │ 8            │
-- │ Jack Wilson     │ Sales       │  58000   │ 10             │ 9            │
-- │ Leo Martinez    │ HR          │  56000   │ 11             │ 10           │
-- │ Frank Miller    │ Marketing   │  55000   │ 12             │ 11           │
-- └─────────────────┴─────────────┴──────────┴────────────────┴──────────────┘

-- Restore Ivy's original salary
UPDATE employees SET salary = 72000 WHERE name = 'Ivy Chen';


-- ============================================================================
-- EXAMPLE 3: NTILE(n) — Divide Rows Into Equal Buckets
-- ============================================================================
-- Useful for percentiles, quartiles, or distributing work evenly.

SELECT
    name,
    salary,
    NTILE(4) OVER (ORDER BY salary DESC) AS salary_quartile,
    NTILE(3) OVER (ORDER BY salary DESC) AS salary_tertile
FROM employees;

-- Expected Output:
-- ┌─────────────────┬──────────┬──────────────────┬────────────────┐
-- │ name            │ salary   │ salary_quartile  │ salary_tertile │
-- ├─────────────────┼──────────┼──────────────────┼────────────────┤
-- │ Charlie Brown   │ 120000   │ 1                │ 1              │
-- │ Henry Davis     │ 105000   │ 1                │ 1              │
-- │ Alice Johnson   │  95000   │ 1                │ 1              │
-- │ Eve Williams    │  88000   │ 2                │ 1              │
-- │ Karen Taylor    │  82000   │ 2                │ 2              │
-- │ Diana Prince    │  78000   │ 2                │ 2              │
-- │ Ivy Chen        │  72000   │ 3                │ 2              │
-- │ Bob Smith       │  65000   │ 3                │ 2              │
-- │ Grace Lee       │  62000   │ 3                │ 3              │
-- │ Jack Wilson     │  58000   │ 4                │ 3              │
-- │ Leo Martinez    │  56000   │ 4                │ 3              │
-- │ Frank Miller    │  55000   │ 4                │ 3              │
-- └─────────────────┴──────────┴──────────────────┴────────────────┘

-- Practical: Label employees as Top 25%, Upper Middle, Lower Middle, Bottom 25%
SELECT
    name,
    salary,
    CASE NTILE(4) OVER (ORDER BY salary DESC)
        WHEN 1 THEN 'Top 25%'
        WHEN 2 THEN 'Upper Middle'
        WHEN 3 THEN 'Lower Middle'
        WHEN 4 THEN 'Bottom 25%'
    END AS salary_band
FROM employees;


-- ============================================================================
-- EXAMPLE 4: LAG() and LEAD() — Access Previous/Next Row
-- ============================================================================
-- LAG(column, offset, default)  — looks BACKWARD
-- LEAD(column, offset, default) — looks FORWARD

SELECT
    name,
    department,
    salary,
    LAG(salary, 1)  OVER (ORDER BY salary DESC) AS higher_salary,
    LEAD(salary, 1) OVER (ORDER BY salary DESC) AS lower_salary,
    salary - LEAD(salary, 1) OVER (ORDER BY salary DESC) AS gap_to_next
FROM employees;

-- Expected Output:
-- ┌─────────────────┬─────────────┬────────┬───────────────┬──────────────┬─────────────┐
-- │ name            │ department  │ salary │ higher_salary │ lower_salary │ gap_to_next │
-- ├─────────────────┼─────────────┼────────┼───────────────┼──────────────┼─────────────┤
-- │ Charlie Brown   │ Engineering │ 120000 │ NULL          │ 105000       │ 15000       │
-- │ Henry Davis     │ Sales       │ 105000 │ 120000        │ 95000        │ 10000       │
-- │ Alice Johnson   │ Engineering │  95000 │ 105000        │ 88000        │  7000       │
-- │ ...             │ ...         │ ...    │ ...           │ ...          │ ...         │
-- │ Frank Miller    │ Marketing   │  55000 │ 56000         │ NULL         │ NULL        │
-- └─────────────────┴─────────────┴────────┴───────────────┴──────────────┴─────────────┘

-- LAG within department — compare salary with the person hired before you
SELECT
    name,
    department,
    hire_date,
    salary,
    LAG(salary) OVER (PARTITION BY department ORDER BY hire_date) AS prev_hire_salary,
    salary - LAG(salary) OVER (PARTITION BY department ORDER BY hire_date) AS salary_diff
FROM employees
ORDER BY department, hire_date;


-- ============================================================================
-- EXAMPLE 5: FIRST_VALUE() and LAST_VALUE()
-- ============================================================================
-- Returns the first/last value in the window frame.
-- IMPORTANT: LAST_VALUE() needs a proper frame definition to work as expected!

SELECT
    name,
    department,
    salary,
    FIRST_VALUE(name) OVER (
        PARTITION BY department ORDER BY salary DESC
    ) AS highest_paid,
    LAST_VALUE(name) OVER (
        PARTITION BY department ORDER BY salary DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING  -- ← Required!
    ) AS lowest_paid
FROM employees;

-- Expected Output:
-- ┌─────────────────┬─────────────┬────────┬───────────────┬──────────────┐
-- │ name            │ department  │ salary │ highest_paid  │ lowest_paid  │
-- ├─────────────────┼─────────────┼────────┼───────────────┼──────────────┤
-- │ Charlie Brown   │ Engineering │ 120000 │ Charlie Brown │ Bob Smith    │
-- │ Alice Johnson   │ Engineering │  95000 │ Charlie Brown │ Bob Smith    │
-- │ Diana Prince    │ Engineering │  78000 │ Charlie Brown │ Bob Smith    │
-- │ Bob Smith       │ Engineering │  65000 │ Charlie Brown │ Bob Smith    │
-- │ Karen Taylor    │ HR          │  82000 │ Karen Taylor  │ Leo Martinez │
-- │ Leo Martinez    │ HR          │  56000 │ Karen Taylor  │ Leo Martinez │
-- │ Eve Williams    │ Marketing   │  88000 │ Eve Williams  │ Frank Miller │
-- │ Grace Lee       │ Marketing   │  62000 │ Eve Williams  │ Frank Miller │
-- │ Frank Miller    │ Marketing   │  55000 │ Eve Williams  │ Frank Miller │
-- │ Henry Davis     │ Sales       │ 105000 │ Henry Davis   │ Jack Wilson  │
-- │ Ivy Chen        │ Sales       │  72000 │ Henry Davis   │ Jack Wilson  │
-- │ Jack Wilson     │ Sales       │  58000 │ Henry Davis   │ Jack Wilson  │
-- └─────────────────┴─────────────┴────────┴───────────────┴──────────────┘

-- NOTE: Without "ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING",
-- LAST_VALUE() only considers rows up to the CURRENT row (the default frame),
-- which means it just returns the current row's value — NOT what you want!


-- ============================================================================
-- EXAMPLE 6: Running Aggregates — SUM() OVER, AVG() OVER, COUNT() OVER
-- ============================================================================

-- Running total of sales by salesperson
SELECT
    salesperson,
    sale_month,
    amount,
    SUM(amount) OVER (
        PARTITION BY salesperson ORDER BY sale_month
    ) AS running_total,
    AVG(amount) OVER (
        PARTITION BY salesperson ORDER BY sale_month
    ) AS running_avg,
    COUNT(*) OVER (
        PARTITION BY salesperson ORDER BY sale_month
    ) AS sale_number
FROM monthly_sales
ORDER BY salesperson, sale_month;

-- Expected Output (Henry's rows):
-- ┌─────────────┬────────────┬────────┬───────────────┬─────────────┬─────────────┐
-- │ salesperson │ sale_month │ amount │ running_total │ running_avg │ sale_number │
-- ├─────────────┼────────────┼────────┼───────────────┼─────────────┼─────────────┤
-- │ Henry       │ 2024-01-01 │ 15000  │ 15000         │ 15000.00    │ 1           │
-- │ Henry       │ 2024-02-01 │ 22000  │ 37000         │ 18500.00    │ 2           │
-- │ Henry       │ 2024-03-01 │ 18000  │ 55000         │ 18333.33    │ 3           │
-- │ Henry       │ 2024-04-01 │ 25000  │ 80000         │ 20000.00    │ 4           │
-- │ Henry       │ 2024-05-01 │ 19000  │ 99000         │ 19800.00    │ 5           │
-- │ Henry       │ 2024-06-01 │ 28000  │ 127000        │ 21166.67    │ 6           │
-- └─────────────┴────────────┴────────┴───────────────┴─────────────┴─────────────┘

-- Percentage of department total (no ORDER BY = entire partition as frame)
SELECT
    name,
    department,
    salary,
    SUM(salary) OVER (PARTITION BY department) AS dept_total,
    ROUND(salary * 100.0 / SUM(salary) OVER (PARTITION BY department), 1) AS pct_of_dept
FROM employees
ORDER BY department, salary DESC;


-- ============================================================================
-- EXAMPLE 7: Window Frame Specification (ROWS BETWEEN)
-- ============================================================================
-- The window frame defines which rows relative to the current row are
-- included in the calculation.
--
-- Frame options:
--   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW     (default with ORDER BY)
--   ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
--   ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING  (entire partition)
--   ROWS BETWEEN 2 PRECEDING AND 1 FOLLOWING              (sliding window)
--   ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING              (just the previous row)

-- 3-month moving average of sales
SELECT
    salesperson,
    sale_month,
    amount,
    ROUND(AVG(amount) OVER (
        PARTITION BY salesperson
        ORDER BY sale_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_3m,
    SUM(amount) OVER (
        PARTITION BY salesperson
        ORDER BY sale_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_sum_3m
FROM monthly_sales
WHERE salesperson = 'Henry'
ORDER BY sale_month;

-- Expected Output:
-- ┌─────────────┬────────────┬────────┬───────────────┬───────────────┐
-- │ salesperson │ sale_month │ amount │ moving_avg_3m │ moving_sum_3m │
-- ├─────────────┼────────────┼────────┼───────────────┼───────────────┤
-- │ Henry       │ 2024-01-01 │ 15000  │ 15000.00      │ 15000         │  (only 1 row)
-- │ Henry       │ 2024-02-01 │ 22000  │ 18500.00      │ 37000         │  (2 rows)
-- │ Henry       │ 2024-03-01 │ 18000  │ 18333.33      │ 55000         │  (3 rows)
-- │ Henry       │ 2024-04-01 │ 25000  │ 21666.67      │ 65000         │  (3 rows)
-- │ Henry       │ 2024-05-01 │ 19000  │ 20666.67      │ 62000         │  (3 rows)
-- │ Henry       │ 2024-06-01 │ 28000  │ 24000.00      │ 72000         │  (3 rows)
-- └─────────────┴────────────┴────────┴───────────────┴───────────────┘


-- ============================================================================
-- EXAMPLE 8: Top-N Per Group (Classic Interview Question)
-- ============================================================================
-- Find the top 2 highest-paid employees in each department

SELECT * FROM (
    SELECT
        name,
        department,
        salary,
        ROW_NUMBER() OVER (
            PARTITION BY department ORDER BY salary DESC
        ) AS dept_rank
    FROM employees
) ranked
WHERE dept_rank <= 2;

-- Expected Output:
-- ┌─────────────────┬─────────────┬────────┬───────────┐
-- │ name            │ department  │ salary │ dept_rank │
-- ├─────────────────┼─────────────┼────────┼───────────┤
-- │ Charlie Brown   │ Engineering │ 120000 │ 1         │
-- │ Alice Johnson   │ Engineering │  95000 │ 2         │
-- │ Karen Taylor    │ HR          │  82000 │ 1         │
-- │ Leo Martinez    │ HR          │  56000 │ 2         │
-- │ Eve Williams    │ Marketing   │  88000 │ 1         │
-- │ Grace Lee       │ Marketing   │  62000 │ 2         │
-- │ Henry Davis     │ Sales       │ 105000 │ 1         │
-- │ Ivy Chen        │ Sales       │  72000 │ 2         │
-- └─────────────────┴─────────────┴────────┴───────────┘


-- ============================================================================
-- EXAMPLE 9: Month-Over-Month Comparison with LAG()
-- ============================================================================

SELECT
    salesperson,
    sale_month,
    amount AS current_month,
    LAG(amount) OVER (PARTITION BY salesperson ORDER BY sale_month) AS prev_month,
    amount - LAG(amount) OVER (PARTITION BY salesperson ORDER BY sale_month) AS change,
    CASE
        WHEN LAG(amount) OVER (PARTITION BY salesperson ORDER BY sale_month) IS NULL
            THEN 'N/A'
        WHEN amount > LAG(amount) OVER (PARTITION BY salesperson ORDER BY sale_month)
            THEN '↑ Up'
        WHEN amount < LAG(amount) OVER (PARTITION BY salesperson ORDER BY sale_month)
            THEN '↓ Down'
        ELSE '→ Same'
    END AS trend
FROM monthly_sales
WHERE salesperson = 'Ivy'
ORDER BY sale_month;

-- Expected Output:
-- ┌─────────────┬────────────┬───────────────┬────────────┬────────┬────────┐
-- │ salesperson │ sale_month │ current_month │ prev_month │ change │ trend  │
-- ├─────────────┼────────────┼───────────────┼────────────┼────────┼────────┤
-- │ Ivy         │ 2024-01-01 │ 12000         │ NULL       │ NULL   │ N/A    │
-- │ Ivy         │ 2024-02-01 │ 14000         │ 12000      │  2000  │ ↑ Up   │
-- │ Ivy         │ 2024-03-01 │ 19000         │ 14000      │  5000  │ ↑ Up   │
-- │ Ivy         │ 2024-04-01 │ 16000         │ 19000      │ -3000  │ ↓ Down │
-- │ Ivy         │ 2024-05-01 │ 21000         │ 16000      │  5000  │ ↑ Up   │
-- │ Ivy         │ 2024-06-01 │ 23000         │ 21000      │  2000  │ ↑ Up   │
-- └─────────────┴────────────┴───────────────┴────────────┴────────┴────────┘


-- ============================================================================
-- EXAMPLE 10: Named Window with WINDOW Clause
-- ============================================================================
-- Avoid repeating the same OVER clause by defining a named window.

SELECT
    salesperson,
    sale_month,
    amount,
    SUM(amount)   OVER w AS running_total,
    AVG(amount)   OVER w AS running_avg,
    MIN(amount)   OVER w AS running_min,
    MAX(amount)   OVER w AS running_max
FROM monthly_sales
WHERE salesperson = 'Henry'
WINDOW w AS (PARTITION BY salesperson ORDER BY sale_month)
ORDER BY sale_month;

-- This is much cleaner than repeating:
--   OVER (PARTITION BY salesperson ORDER BY sale_month)
-- four times!


-- ============================================================================
-- EXAMPLE 11: PERCENT_RANK() and CUME_DIST()
-- ============================================================================
-- PERCENT_RANK() — Relative rank as a fraction: (rank - 1) / (total - 1)
-- CUME_DIST()    — Cumulative distribution: rows at or below / total rows

SELECT
    name,
    salary,
    RANK() OVER (ORDER BY salary) AS rank,
    ROUND(PERCENT_RANK() OVER (ORDER BY salary)::NUMERIC, 3) AS percent_rank,
    ROUND(CUME_DIST()    OVER (ORDER BY salary)::NUMERIC, 3) AS cume_dist
FROM employees;

-- Expected Output:
-- ┌─────────────────┬────────┬──────┬──────────────┬───────────┐
-- │ name            │ salary │ rank │ percent_rank │ cume_dist │
-- ├─────────────────┼────────┼──────┼──────────────┼───────────┤
-- │ Frank Miller    │  55000 │ 1    │ 0.000        │ 0.083     │
-- │ Leo Martinez    │  56000 │ 2    │ 0.091        │ 0.167     │
-- │ Jack Wilson     │  58000 │ 3    │ 0.182        │ 0.250     │
-- │ Grace Lee       │  62000 │ 4    │ 0.273        │ 0.333     │
-- │ Bob Smith       │  65000 │ 5    │ 0.364        │ 0.417     │
-- │ Ivy Chen        │  72000 │ 6    │ 0.455        │ 0.500     │
-- │ Diana Prince    │  78000 │ 7    │ 0.545        │ 0.583     │
-- │ Karen Taylor    │  82000 │ 8    │ 0.636        │ 0.667     │
-- │ Eve Williams    │  88000 │ 9    │ 0.727        │ 0.750     │
-- │ Alice Johnson   │  95000 │ 10   │ 0.818        │ 0.833     │
-- │ Henry Davis     │ 105000 │ 11   │ 0.909        │ 0.917     │
-- │ Charlie Brown   │ 120000 │ 12   │ 1.000        │ 1.000     │
-- └─────────────────┴────────┴──────┴──────────────┴───────────┘


-- ============================================================================
-- EXAMPLE 12: NTH_VALUE() — Access the N-th Row
-- ============================================================================

SELECT
    name,
    department,
    salary,
    NTH_VALUE(name, 1) OVER w AS "1st_highest",
    NTH_VALUE(name, 2) OVER w AS "2nd_highest",
    NTH_VALUE(name, 3) OVER w AS "3rd_highest"
FROM employees
WINDOW w AS (
    PARTITION BY department
    ORDER BY salary DESC
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
)
ORDER BY department, salary DESC;

-- Expected Output (Engineering):
-- ┌─────────────────┬─────────────┬────────┬──────────────┬──────────────┬──────────────┐
-- │ name            │ department  │ salary │ 1st_highest  │ 2nd_highest  │ 3rd_highest  │
-- ├─────────────────┼─────────────┼────────┼──────────────┼──────────────┼──────────────┤
-- │ Charlie Brown   │ Engineering │ 120000 │ Charlie Brown│ Alice Johnson│ Diana Prince │
-- │ Alice Johnson   │ Engineering │  95000 │ Charlie Brown│ Alice Johnson│ Diana Prince │
-- │ Diana Prince    │ Engineering │  78000 │ Charlie Brown│ Alice Johnson│ Diana Prince │
-- │ Bob Smith       │ Engineering │  65000 │ Charlie Brown│ Alice Johnson│ Diana Prince │
-- └─────────────────┴─────────────┴────────┴──────────────┴──────────────┴──────────────┘


-- ============================================================================
-- EXAMPLE 13: Real-World — Employee Salary vs Department Average
-- ============================================================================

SELECT
    name,
    department,
    salary,
    ROUND(AVG(salary) OVER (PARTITION BY department), 2) AS dept_avg,
    salary - ROUND(AVG(salary) OVER (PARTITION BY department), 2) AS diff_from_avg,
    CASE
        WHEN salary > AVG(salary) OVER (PARTITION BY department) THEN 'Above Average'
        WHEN salary < AVG(salary) OVER (PARTITION BY department) THEN 'Below Average'
        ELSE 'At Average'
    END AS comparison
FROM employees
ORDER BY department, salary DESC;

-- Expected Output:
-- ┌─────────────────┬─────────────┬────────┬──────────┬───────────────┬───────────────┐
-- │ name            │ department  │ salary │ dept_avg │ diff_from_avg │ comparison    │
-- ├─────────────────┼─────────────┼────────┼──────────┼───────────────┼───────────────┤
-- │ Charlie Brown   │ Engineering │ 120000 │ 89500.00 │  30500.00     │ Above Average │
-- │ Alice Johnson   │ Engineering │  95000 │ 89500.00 │   5500.00     │ Above Average │
-- │ Diana Prince    │ Engineering │  78000 │ 89500.00 │ -11500.00     │ Below Average │
-- │ Bob Smith       │ Engineering │  65000 │ 89500.00 │ -24500.00     │ Below Average │
-- │ Karen Taylor    │ HR          │  82000 │ 69000.00 │  13000.00     │ Above Average │
-- │ Leo Martinez    │ HR          │  56000 │ 69000.00 │ -13000.00     │ Below Average │
-- │ ...             │ ...         │ ...    │ ...      │ ...           │ ...           │
-- └─────────────────┴─────────────┴────────┴──────────┴───────────────┴───────────────┘


-- ============================================================================
-- EXAMPLE 14: Real-World — Cumulative Revenue & Contribution per Region
-- ============================================================================

SELECT
    region,
    salesperson,
    SUM(amount) AS total_sales,
    SUM(SUM(amount)) OVER (PARTITION BY region ORDER BY SUM(amount) DESC) AS cumulative,
    ROUND(
        SUM(amount) * 100.0 / SUM(SUM(amount)) OVER (PARTITION BY region), 1
    ) AS pct_contribution
FROM monthly_sales
GROUP BY region, salesperson
ORDER BY region, total_sales DESC;

-- Expected Output:
-- ┌────────┬─────────────┬─────────────┬────────────┬──────────────────┐
-- │ region │ salesperson │ total_sales │ cumulative │ pct_contribution │
-- ├────────┼─────────────┼─────────────┼────────────┼──────────────────┤
-- │ North  │ Henry       │ 127000      │ 127000     │ 62.9             │
-- │ North  │ Jack        │  75000      │ 202000     │ 37.1             │
-- │ South  │ Ivy         │ 105000      │ 105000     │ 100.0            │
-- └────────┴─────────────┴─────────────┴────────────┴──────────────────┘


-- ============================================================================
-- KEY TAKEAWAYS
-- ============================================================================
-- 1. Window functions let you compute values ACROSS RELATED ROWS without
--    collapsing the result set (unlike GROUP BY).
--
-- 2. The key window functions:
--    ┌─────────────────┬────────────────────────────────────────────┐
--    │ Function        │ Purpose                                    │
--    ├─────────────────┼────────────────────────────────────────────┤
--    │ ROW_NUMBER()    │ Unique sequential number (no ties)         │
--    │ RANK()          │ Ranking with gaps on ties                  │
--    │ DENSE_RANK()    │ Ranking without gaps                       │
--    │ NTILE(n)        │ Divide into n equal buckets                │
--    │ LAG(col, n)     │ Value from n rows BEFORE                   │
--    │ LEAD(col, n)    │ Value from n rows AFTER                    │
--    │ FIRST_VALUE()   │ First value in the window frame            │
--    │ LAST_VALUE()    │ Last value (needs full frame!)             │
--    │ NTH_VALUE(c, n) │ N-th value in the frame                   │
--    │ PERCENT_RANK()  │ Relative rank as 0-1 fraction              │
--    │ CUME_DIST()     │ Cumulative distribution fraction           │
--    │ SUM/AVG/COUNT() │ Running aggregates when used with OVER     │
--    └─────────────────┴────────────────────────────────────────────┘
--
-- 3. PARTITION BY divides data into groups; ORDER BY defines row order.
--
-- 4. The default frame with ORDER BY is:
--    RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
--    — be explicit with ROWS BETWEEN for LAST_VALUE() and sliding windows.
--
-- 5. Use the WINDOW clause to name and reuse window definitions.
--
-- 6. Common real-world uses: running totals, rankings, top-N per group,
--    period-over-period comparisons, moving averages, percentiles.
-- ============================================================================
