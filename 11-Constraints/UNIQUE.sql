-- ============================================================
-- UNIQUE Constraint in PostgreSQL
-- ============================================================
-- A UNIQUE constraint guarantees that all values in a column
-- (or combination of columns) are distinct across every row.
--
-- Key differences from PRIMARY KEY:
--   ┌──────────────────┬──────────────┬──────────────┐
--   │     Feature      │ PRIMARY KEY  │   UNIQUE     │
--   ├──────────────────┼──────────────┼──────────────┤
--   │ Allows NULLs?    │     No       │ Yes (one*)   │
--   │ Per table limit? │ Exactly one  │ Many allowed │
--   │ Creates index?   │     Yes      │     Yes      │
--   └──────────────────┴──────────────┴──────────────┘
--   * PostgreSQL treats each NULL as distinct, so a UNIQUE column
--     can actually hold MULTIPLE NULLs (this is standard SQL behavior).
-- ============================================================


-- ============================================================
-- Example 1: UNIQUE on a Single Column
-- ============================================================
-- Every employee must have a unique email address.

DROP TABLE IF EXISTS employees CASCADE;

CREATE TABLE employees (
    emp_id      SERIAL PRIMARY KEY,
    first_name  VARCHAR(50) NOT NULL,
    last_name   VARCHAR(50) NOT NULL,
    email       VARCHAR(100) UNIQUE,          -- no two employees share an email
    salary      NUMERIC(10, 2)
);

INSERT INTO employees (first_name, last_name, email, salary)
VALUES
    ('Aarav',  'Sharma', 'aarav.sharma@company.com',  75000),
    ('Priya',  'Patel',  'priya.patel@company.com',   82000),
    ('Rohan',  'Mehta',  'rohan.mehta@company.com',    68000);

-- Try to insert a duplicate email:
INSERT INTO employees (first_name, last_name, email, salary)
VALUES ('Sneha', 'Iyer', 'aarav.sharma@company.com', 91000);

-- ERROR:  duplicate key value violates unique constraint "employees_email_key"
-- DETAIL: Key (email)=(aarav.sharma@company.com) already exists.

SELECT * FROM employees;

-- Expected Output:
-- emp_id | first_name | last_name |           email              |  salary
-- -------+------------+-----------+------------------------------+----------
--      1 | Aarav      | Sharma    | aarav.sharma@company.com     | 75000.00
--      2 | Priya      | Patel     | priya.patel@company.com      | 82000.00
--      3 | Rohan      | Mehta     | rohan.mehta@company.com      | 68000.00


-- ============================================================
-- Example 2: UNIQUE Allows Multiple NULLs
-- ============================================================
-- In PostgreSQL, NULL ≠ NULL, so UNIQUE columns accept many NULLs.

INSERT INTO employees (first_name, last_name, email, salary)
VALUES
    ('Sneha',  'Iyer', NULL, 91000),     -- email is NULL → OK
    ('Vikram', 'Rao',  NULL, 73000);     -- another NULL  → also OK!

SELECT emp_id, first_name, last_name, email FROM employees;

-- Expected Output:
-- emp_id | first_name | last_name |           email
-- -------+------------+-----------+------------------------------
--      1 | Aarav      | Sharma    | aarav.sharma@company.com
--      2 | Priya      | Patel     | priya.patel@company.com
--      3 | Rohan      | Mehta     | rohan.mehta@company.com
--      4 | Sneha      | Iyer      | (NULL)
--      5 | Vikram     | Rao       | (NULL)
--
-- Two NULLs co-exist — this would NOT be allowed with PRIMARY KEY.


-- ============================================================
-- Example 3: UNIQUE on Multiple Columns (Composite UNIQUE)
-- ============================================================
-- A product name must be unique WITHIN its category, but the same
-- name can appear in different categories.

DROP TABLE IF EXISTS products CASCADE;

CREATE TABLE products (
    product_id   SERIAL PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    category     VARCHAR(50) NOT NULL,
    price        NUMERIC(10, 2) NOT NULL,

    CONSTRAINT uq_product_name_category
        UNIQUE (product_name, category)
);

INSERT INTO products (product_name, category, price)
VALUES
    ('Pro 15',  'Laptops',      1299.99),
    ('Pro 15',  'Headphones',    249.99),   -- same name, different category → OK
    ('Air',     'Laptops',       999.99);

-- Try to duplicate the (name, category) pair:
INSERT INTO products (product_name, category, price)
VALUES ('Pro 15', 'Laptops', 1399.99);

-- ERROR:  duplicate key value violates unique constraint "uq_product_name_category"
-- DETAIL: Key (product_name, category)=(Pro 15, Laptops) already exists.

SELECT * FROM products;

-- Expected Output:
-- product_id | product_name | category   |  price
-- -----------+--------------+------------+----------
--          1 | Pro 15       | Laptops    |  1299.99
--          2 | Pro 15       | Headphones |   249.99
--          3 | Air          | Laptops    |   999.99


-- ============================================================
-- Example 4: Adding a UNIQUE Constraint to an Existing Table
-- ============================================================

DROP TABLE IF EXISTS students CASCADE;

CREATE TABLE students (
    student_id   SERIAL PRIMARY KEY,
    full_name    VARCHAR(100) NOT NULL,
    roll_number  VARCHAR(20),
    email        VARCHAR(100)
);

INSERT INTO students (full_name, roll_number, email)
VALUES
    ('Ananya Gupta',  'ROLL-001', 'ananya@university.edu'),
    ('Karthik Nair',  'ROLL-002', 'karthik@university.edu'),
    ('Divya Menon',   'ROLL-003', 'divya@university.edu');

-- Add UNIQUE on roll_number after the table already has data:
ALTER TABLE students
    ADD CONSTRAINT uq_students_roll UNIQUE (roll_number);

-- Add UNIQUE on email too:
ALTER TABLE students
    ADD CONSTRAINT uq_students_email UNIQUE (email);

-- Verify: both constraints now exist
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'students' AND constraint_type = 'UNIQUE';

-- Expected Output:
-- constraint_name     | constraint_type
-- --------------------+----------------
-- uq_students_roll    | UNIQUE
-- uq_students_email   | UNIQUE

-- Test the new constraint:
INSERT INTO students (full_name, roll_number, email)
VALUES ('Duplicate', 'ROLL-001', 'new@university.edu');

-- ERROR:  duplicate key value violates unique constraint "uq_students_roll"
-- DETAIL: Key (roll_number)=(ROLL-001) already exists.

-- Dropping a UNIQUE constraint:
ALTER TABLE students
    DROP CONSTRAINT uq_students_email;


-- ============================================================
-- Example 5: UNIQUE vs PRIMARY KEY — Side-by-Side Comparison
-- ============================================================

DROP TABLE IF EXISTS departments CASCADE;

CREATE TABLE departments (
    dept_id     SERIAL PRIMARY KEY,           -- ONE primary key per table
    dept_name   VARCHAR(100) UNIQUE NOT NULL,  -- UNIQUE #1: no duplicate names
    dept_code   CHAR(5) UNIQUE NOT NULL        -- UNIQUE #2: no duplicate codes
);

INSERT INTO departments (dept_name, dept_code) VALUES
    ('Engineering',     'ENG'),
    ('Human Resources', 'HR'),
    ('Marketing',       'MKT');

-- dept_id is the PK    → cannot be NULL, must be unique
-- dept_name is UNIQUE  → can be NULL (if we hadn't added NOT NULL), must be unique
-- dept_code is UNIQUE  → same as above
-- A table can have MANY UNIQUE constraints but only ONE PRIMARY KEY.

SELECT * FROM departments;

-- Expected Output:
-- dept_id |    dept_name     | dept_code
-- --------+------------------+-----------
--       1 | Engineering      | ENG
--       2 | Human Resources  | HR
--       3 | Marketing        | MKT


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. UNIQUE ensures no duplicate values in a column or column-set.
-- 2. Unlike PRIMARY KEY, a UNIQUE column CAN hold NULL values.
-- 3. PostgreSQL treats NULLs as distinct → multiple NULLs are allowed.
-- 4. A table can have many UNIQUE constraints but only one PRIMARY KEY.
-- 5. Composite UNIQUE enforces uniqueness on the combination of columns.
-- 6. Use ALTER TABLE ADD CONSTRAINT to add UNIQUE to existing tables.
-- 7. Name your constraints (CONSTRAINT uq_xxx UNIQUE (...)) for clarity.
