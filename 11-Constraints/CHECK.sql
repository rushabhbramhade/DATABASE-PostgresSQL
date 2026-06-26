-- ============================================================
-- CHECK Constraint in PostgreSQL
-- ============================================================
-- A CHECK constraint validates that data meets a Boolean condition
-- BEFORE it is inserted or updated. If the condition evaluates to
-- FALSE, the operation is rejected with an error.
--
-- CHECK can reference:
--   • A single column    → column-level CHECK
--   • Multiple columns   → table-level CHECK
--   • PostgreSQL functions (UPPER, LENGTH, etc.)
--
-- NOTE: CHECK conditions must NOT contain subqueries,
--       references to other tables, or volatile functions.
-- ============================================================


-- ============================================================
-- Example 1: CHECK on a Single Column (salary > 0)
-- ============================================================

DROP TABLE IF EXISTS employees CASCADE;

CREATE TABLE employees (
    emp_id      SERIAL PRIMARY KEY,
    first_name  VARCHAR(50) NOT NULL,
    last_name   VARCHAR(50) NOT NULL,
    email       VARCHAR(100),
    salary      NUMERIC(10, 2) CHECK (salary > 0),          -- must be positive
    age         INT CHECK (age >= 18 AND age <= 100)         -- must be 18–100
);

INSERT INTO employees (first_name, last_name, email, salary, age)
VALUES
    ('Aarav',  'Sharma', 'aarav@company.com',  75000, 30),
    ('Priya',  'Patel',  'priya@company.com',  82000, 28),
    ('Rohan',  'Mehta',  'rohan@company.com',  68000, 35);

SELECT * FROM employees;

-- Expected Output:
-- emp_id | first_name | last_name |       email          |  salary  | age
-- -------+------------+-----------+----------------------+----------+-----
--      1 | Aarav      | Sharma    | aarav@company.com    | 75000.00 |  30
--      2 | Priya      | Patel     | priya@company.com    | 82000.00 |  28
--      3 | Rohan      | Mehta     | rohan@company.com    | 68000.00 |  35


-- ============================================================
-- Example 2: CHECK Constraint Violation
-- ============================================================

-- Attempt to insert a negative salary:
INSERT INTO employees (first_name, last_name, salary, age)
VALUES ('Bad', 'Data', -5000, 25);

-- ERROR:  new row for relation "employees" violates check constraint
--         "employees_salary_check"
-- DETAIL: Failing row contains (4, Bad, Data, null, -5000.00, 25).

-- Attempt to insert an invalid age:
INSERT INTO employees (first_name, last_name, salary, age)
VALUES ('Too', 'Young', 50000, 15);

-- ERROR:  new row for relation "employees" violates check constraint
--         "employees_age_check"
-- DETAIL: Failing row contains (5, Too, Young, null, 50000.00, 15).

-- CHECK is also enforced on UPDATE:
UPDATE employees SET salary = -1 WHERE emp_id = 1;

-- ERROR:  new row for relation "employees" violates check constraint
--         "employees_salary_check"


-- ============================================================
-- Example 3: Named CHECK Constraints
-- ============================================================
-- Naming your constraints makes error messages and maintenance easier.

DROP TABLE IF EXISTS products CASCADE;

CREATE TABLE products (
    product_id   SERIAL PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    category     VARCHAR(50) NOT NULL,
    price        NUMERIC(10, 2) NOT NULL,
    stock        INT NOT NULL DEFAULT 0,
    discount     NUMERIC(5, 2) DEFAULT 0,

    CONSTRAINT chk_price_positive
        CHECK (price > 0),

    CONSTRAINT chk_stock_non_negative
        CHECK (stock >= 0),

    CONSTRAINT chk_discount_range
        CHECK (discount >= 0 AND discount <= 100)
);

INSERT INTO products (product_name, category, price, stock, discount)
VALUES
    ('Laptop Pro 15',       'Electronics',  1299.99, 50,  10.00),
    ('Wireless Mouse',      'Accessories',    29.99, 200,  5.00),
    ('USB-C Hub',           'Accessories',    49.99, 150,  0.00),
    ('Mechanical Keyboard', 'Accessories',    89.99, 100, 15.00),
    ('4K Monitor',          'Electronics',   449.99,  30, 20.00);

-- Attempt an invalid discount (over 100%):
INSERT INTO products (product_name, category, price, stock, discount)
VALUES ('Bad Product', 'Test', 10.00, 5, 150);

-- ERROR:  new row for relation "products" violates check constraint
--         "chk_discount_range"
-- DETAIL: Failing row contains (6, Bad Product, Test, 10.00, 5, 150.00).

-- Attempt a negative stock:
INSERT INTO products (product_name, category, price, stock)
VALUES ('Negative Stock', 'Test', 10.00, -5);

-- ERROR:  new row for relation "products" violates check constraint
--         "chk_stock_non_negative"

SELECT * FROM products;

-- Expected Output:
-- product_id |    product_name     |  category   |  price  | stock | discount
-- -----------+---------------------+-------------+---------+-------+----------
--          1 | Laptop Pro 15       | Electronics | 1299.99 |    50 |    10.00
--          2 | Wireless Mouse      | Accessories |   29.99 |   200 |     5.00
--          3 | USB-C Hub           | Accessories |   49.99 |   150 |     0.00
--          4 | Mechanical Keyboard | Accessories |   89.99 |   100 |    15.00
--          5 | 4K Monitor          | Electronics |  449.99 |    30 |    20.00


-- ============================================================
-- Example 4: CHECK with Multiple Columns (Table-Level)
-- ============================================================
-- A table-level CHECK can reference more than one column.
-- Example: end_date must be after start_date.

DROP TABLE IF EXISTS students CASCADE;

CREATE TABLE students (
    student_id      SERIAL PRIMARY KEY,
    full_name       VARCHAR(100) NOT NULL,
    enrollment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    graduation_date DATE,

    CONSTRAINT chk_graduation_after_enrollment
        CHECK (graduation_date IS NULL OR graduation_date > enrollment_date)
);

INSERT INTO students (full_name, enrollment_date, graduation_date)
VALUES
    ('Ananya Gupta',  '2022-08-01', '2026-05-15'),   -- valid
    ('Karthik Nair',  '2023-08-01', NULL),            -- still enrolled, no grad date
    ('Divya Menon',   '2021-08-01', '2025-05-15');    -- valid

-- Attempt: graduation before enrollment:
INSERT INTO students (full_name, enrollment_date, graduation_date)
VALUES ('Bad Date', '2024-01-01', '2020-06-01');

-- ERROR:  new row for relation "students" violates check constraint
--         "chk_graduation_after_enrollment"

SELECT * FROM students;

-- Expected Output:
-- student_id |   full_name    | enrollment_date | graduation_date
-- -----------+----------------+-----------------+-----------------
--          1 | Ananya Gupta   | 2022-08-01      | 2026-05-15
--          2 | Karthik Nair   | 2023-08-01      | (NULL)
--          3 | Divya Menon    | 2021-08-01      | 2025-05-15


-- ============================================================
-- Example 5: CHECK with Functions
-- ============================================================
-- You can use immutable PostgreSQL functions inside CHECK.

DROP TABLE IF EXISTS departments CASCADE;

CREATE TABLE departments (
    dept_id     SERIAL PRIMARY KEY,
    dept_name   VARCHAR(100) NOT NULL,
    dept_code   CHAR(5) NOT NULL,
    budget      NUMERIC(15, 2),

    -- Dept code must be all uppercase letters
    CONSTRAINT chk_dept_code_upper
        CHECK (dept_code = UPPER(dept_code)),

    -- Dept name must be at least 2 characters long
    CONSTRAINT chk_dept_name_length
        CHECK (LENGTH(TRIM(dept_name)) >= 2),

    -- Budget must be at least 10,000 if provided
    CONSTRAINT chk_minimum_budget
        CHECK (budget IS NULL OR budget >= 10000)
);

INSERT INTO departments (dept_name, dept_code, budget) VALUES
    ('Engineering',     'ENG',   5000000),
    ('Human Resources', 'HR',    1200000),
    ('Marketing',       'MKT',    800000);

-- Attempt a lowercase dept_code:
INSERT INTO departments (dept_name, dept_code, budget)
VALUES ('Finance', 'fin', 900000);

-- ERROR:  new row for relation "departments" violates check constraint
--         "chk_dept_code_upper"

-- Attempt a single-character name:
INSERT INTO departments (dept_name, dept_code, budget)
VALUES ('X', 'XYZ', 100000);

-- ERROR:  new row for relation "departments" violates check constraint
--         "chk_dept_name_length"

-- Attempt a budget too small:
INSERT INTO departments (dept_name, dept_code, budget)
VALUES ('Finance', 'FIN', 5000);

-- ERROR:  new row for relation "departments" violates check constraint
--         "chk_minimum_budget"

SELECT * FROM departments;

-- Expected Output:
-- dept_id |    dept_name     | dept_code |   budget
-- --------+------------------+-----------+------------
--       1 | Engineering      | ENG       | 5000000.00
--       2 | Human Resources  | HR        | 1200000.00
--       3 | Marketing        | MKT       |  800000.00


-- ============================================================
-- Example 6: Adding & Dropping CHECK on an Existing Table
-- ============================================================

-- Add a CHECK constraint to the employees table:
ALTER TABLE employees
    ADD CONSTRAINT chk_email_format
    CHECK (email IS NULL OR email LIKE '%@%.%');

-- Test it:
INSERT INTO employees (first_name, last_name, salary, age, email)
VALUES ('Bad', 'Email', 50000, 25, 'not-an-email');

-- ERROR:  new row for relation "employees" violates check constraint
--         "chk_email_format"

-- Valid email passes:
INSERT INTO employees (first_name, last_name, salary, age, email)
VALUES ('Sneha', 'Iyer', 91000, 26, 'sneha.iyer@company.com');

-- Drop a CHECK constraint:
ALTER TABLE employees
    DROP CONSTRAINT chk_email_format;


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. CHECK validates data against a Boolean condition before INSERT/UPDATE.
-- 2. Column-level CHECK references one column; table-level can reference many.
-- 3. Name your CHECK constraints (CONSTRAINT chk_xxx CHECK (...)) for clarity.
-- 4. You can use immutable functions: UPPER(), LENGTH(), TRIM(), etc.
-- 5. CHECK cannot use subqueries or reference other tables (use triggers for that).
-- 6. NULL values are treated as "unknown" — CHECK passes if the result is NULL
--    (i.e., CHECK (salary > 0) will allow NULL salary; add NOT NULL separately).
-- 7. Use ALTER TABLE ADD/DROP CONSTRAINT to manage CHECK on existing tables.
