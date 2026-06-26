-- ============================================================================
-- INSERT.sql — Data Insertion in PostgreSQL
-- ============================================================================
-- Topic  : INSERT INTO statement and all its variations
-- Tables : employees, products, employees_archive
-- ============================================================================


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- SETUP: Create sample tables for all examples
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

CREATE TABLE IF NOT EXISTS employees (
    employee_id   SERIAL PRIMARY KEY,
    first_name    VARCHAR(50)   NOT NULL,
    last_name     VARCHAR(50)   NOT NULL,
    email         VARCHAR(100)  UNIQUE NOT NULL,
    department    VARCHAR(50)   DEFAULT 'General',
    salary        NUMERIC(10,2) DEFAULT 30000.00,
    hire_date     DATE          DEFAULT CURRENT_DATE,
    is_active     BOOLEAN       DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS products (
    product_id    SERIAL PRIMARY KEY,
    product_name  VARCHAR(100)  NOT NULL,
    category      VARCHAR(50),
    price         NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    stock_qty     INT           DEFAULT 0,
    created_at    TIMESTAMP     DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS employees_archive (
    employee_id   INT,
    first_name    VARCHAR(50),
    last_name     VARCHAR(50),
    email         VARCHAR(100),
    department    VARCHAR(50),
    salary        NUMERIC(10,2)
);


-- ============================================================================
-- 1. Basic INSERT — Specify column list (RECOMMENDED)
-- ============================================================================
-- Always list the columns explicitly. This makes your queries readable,
-- maintainable, and safe against table schema changes.

INSERT INTO employees (first_name, last_name, email, department, salary)
VALUES ('Aarav', 'Sharma', 'aarav.sharma@company.com', 'Engineering', 75000.00);

INSERT INTO employees (first_name, last_name, email, department, salary)
VALUES ('Priya', 'Patel', 'priya.patel@company.com', 'Marketing', 62000.00);

INSERT INTO employees (first_name, last_name, email, department, salary)
VALUES ('Rahul', 'Mehta', 'rahul.mehta@company.com', 'Engineering', 80000.00);

-- Expected result after each INSERT:
-- INSERT 0 1
-- (1 row inserted)

-- Verify:
-- SELECT * FROM employees;
--  employee_id | first_name | last_name |           email            | department  |  salary  | hire_date  | is_active
-- -------------+------------+-----------+----------------------------+-------------+----------+------------+-----------
--            1 | Aarav      | Sharma    | aarav.sharma@company.com   | Engineering | 75000.00 | 2026-06-26 | t
--            2 | Priya      | Patel     | priya.patel@company.com    | Marketing   | 62000.00 | 2026-06-26 | t
--            3 | Rahul      | Mehta     | rahul.mehta@company.com    | Engineering | 80000.00 | 2026-06-26 | t


-- ============================================================================
-- 2. INSERT with All Columns (no column list)
-- ============================================================================
-- You CAN omit the column list, but you MUST provide values for every column
-- in the exact table order. This is fragile — if the table changes, this breaks.

INSERT INTO products
VALUES (DEFAULT, 'Wireless Mouse', 'Electronics', 29.99, 150, NOW());

INSERT INTO products
VALUES (DEFAULT, 'Mechanical Keyboard', 'Electronics', 89.99, 75, NOW());

-- NOTE: Use DEFAULT for SERIAL / auto-generated columns.


-- ============================================================================
-- 3. INSERT Multiple Rows in One Statement
-- ============================================================================
-- Much faster than individual INSERTs — PostgreSQL sends one command to the
-- server instead of many.

INSERT INTO products (product_name, category, price, stock_qty)
VALUES
    ('USB-C Hub',         'Electronics',   45.99,  200),
    ('Standing Desk',     'Furniture',    349.99,   30),
    ('Noise-Cancel Headphones', 'Electronics', 199.99, 85),
    ('Ergonomic Chair',   'Furniture',    499.99,   20),
    ('Monitor Light Bar', 'Accessories',   54.99,  110);

-- Expected: INSERT 0 5   (5 rows inserted in one shot)

-- Verify:
-- SELECT product_id, product_name, category, price, stock_qty FROM products;
--  product_id |      product_name       |  category   |  price  | stock_qty
-- ------------+-------------------------+-------------+---------+-----------
--           1 | Wireless Mouse          | Electronics |   29.99 |       150
--           2 | Mechanical Keyboard     | Electronics |   89.99 |        75
--           3 | USB-C Hub               | Electronics |   45.99 |       200
--           4 | Standing Desk           | Furniture   |  349.99 |        30
--           5 | Noise-Cancel Headphones | Electronics |  199.99 |        85
--           6 | Ergonomic Chair         | Furniture   |  499.99 |        20
--           7 | Monitor Light Bar       | Accessories |   54.99 |       110


-- ============================================================================
-- 4. INSERT with DEFAULT Values
-- ============================================================================
-- Use the keyword DEFAULT to let PostgreSQL fill in the column's default.
-- Or simply omit the column from the column list.

-- Method A: Explicitly write DEFAULT
INSERT INTO employees (first_name, last_name, email, department, salary, hire_date)
VALUES ('Sneha', 'Iyer', 'sneha.iyer@company.com', DEFAULT, DEFAULT, DEFAULT);

-- Result: department = 'General', salary = 30000.00, hire_date = today

-- Method B: Omit columns that have defaults (cleaner approach)
INSERT INTO employees (first_name, last_name, email)
VALUES ('Vikram', 'Singh', 'vikram.singh@company.com');

-- Result: department = 'General', salary = 30000.00, hire_date = today, is_active = true

-- Method C: Insert a row with ALL defaults (requires all non-default columns to be nullable or have defaults)
-- INSERT INTO employees DEFAULT VALUES;
-- ^ This would fail here because first_name, last_name, email are NOT NULL with no defaults.


-- ============================================================================
-- 5. INSERT ... RETURNING (PostgreSQL-Specific)
-- ============================================================================
-- RETURNING lets you get back data from the row that was just inserted,
-- without needing a separate SELECT query. Extremely useful!

-- Return the generated ID
INSERT INTO employees (first_name, last_name, email, department, salary)
VALUES ('Ananya', 'Desai', 'ananya.desai@company.com', 'HR', 58000.00)
RETURNING employee_id;

-- Expected:
--  employee_id
-- -------------
--            6

-- Return multiple columns
INSERT INTO products (product_name, category, price, stock_qty)
VALUES ('Webcam HD', 'Electronics', 69.99, 60)
RETURNING product_id, product_name, created_at;

-- Expected:
--  product_id | product_name |         created_at
-- ------------+--------------+----------------------------
--           8 | Webcam HD    | 2026-06-26 15:30:00.000000

-- Return ALL columns of the inserted row
INSERT INTO employees (first_name, last_name, email, department, salary)
VALUES ('Kiran', 'Rao', 'kiran.rao@company.com', 'Finance', 71000.00)
RETURNING *;

-- Expected:
--  employee_id | first_name | last_name |         email          | department |  salary  | hire_date  | is_active
-- -------------+------------+-----------+------------------------+------------+----------+------------+-----------
--            7 | Kiran      | Rao       | kiran.rao@company.com  | Finance    | 71000.00 | 2026-06-26 | t


-- ============================================================================
-- 6. INSERT ... ON CONFLICT (UPSERT)
-- ============================================================================
-- "UPSERT" = INSERT if the row doesn't exist, UPDATE if it does.
-- Requires a UNIQUE constraint or PRIMARY KEY to detect the conflict.

-- 6a. ON CONFLICT DO NOTHING — silently skip if duplicate exists
INSERT INTO employees (first_name, last_name, email, department, salary)
VALUES ('Aarav', 'Sharma', 'aarav.sharma@company.com', 'Engineering', 75000.00)
ON CONFLICT (email) DO NOTHING;

-- Result: No error, no row inserted (email already exists). INSERT 0 0

-- 6b. ON CONFLICT DO UPDATE — update existing row on conflict
INSERT INTO products (product_name, category, price, stock_qty)
VALUES ('Wireless Mouse', 'Electronics', 24.99, 200)
ON CONFLICT (product_name) DO UPDATE
SET price     = EXCLUDED.price,
    stock_qty = EXCLUDED.stock_qty;

-- NOTE: EXCLUDED refers to the row that was proposed for insertion.
-- This updates the existing "Wireless Mouse" row: price → 24.99, stock_qty → 200

-- ⚠️  For this to work, product_name needs a UNIQUE constraint:
-- ALTER TABLE products ADD CONSTRAINT uq_product_name UNIQUE (product_name);

-- 6c. ON CONFLICT with a WHERE clause (conditional upsert)
INSERT INTO products (product_name, category, price, stock_qty)
VALUES ('Mechanical Keyboard', 'Electronics', 79.99, 100)
ON CONFLICT (product_name) DO UPDATE
SET price     = EXCLUDED.price,
    stock_qty = EXCLUDED.stock_qty
WHERE products.price > EXCLUDED.price;
-- Only update if the new price is LOWER than the existing price

-- 6d. UPSERT with RETURNING — see what happened
INSERT INTO employees (first_name, last_name, email, department, salary)
VALUES ('Priya', 'Patel', 'priya.patel@company.com', 'Marketing', 67000.00)
ON CONFLICT (email) DO UPDATE
SET salary = EXCLUDED.salary
RETURNING employee_id, first_name, salary;

-- Expected (existing row updated):
--  employee_id | first_name |  salary
-- -------------+------------+----------
--            2 | Priya      | 67000.00


-- ============================================================================
-- 7. INSERT from a SELECT (Copy Data Between Tables)
-- ============================================================================
-- Copy data from one table into another using a subquery.

-- 7a. Archive all Engineering department employees
INSERT INTO employees_archive (employee_id, first_name, last_name, email, department, salary)
SELECT employee_id, first_name, last_name, email, department, salary
FROM employees
WHERE department = 'Engineering';

-- Expected: INSERT 0 2 (Aarav and Rahul are in Engineering)

-- Verify:
-- SELECT * FROM employees_archive;
--  employee_id | first_name | last_name |           email          | department  |  salary
-- -------------+------------+-----------+--------------------------+-------------+----------
--            1 | Aarav      | Sharma    | aarav.sharma@company.com | Engineering | 75000.00
--            3 | Rahul      | Mehta     | rahul.mehta@company.com  | Engineering | 80000.00

-- 7b. Insert with transformations during copy
INSERT INTO employees_archive (employee_id, first_name, last_name, email, department, salary)
SELECT employee_id, first_name, last_name, email, department, salary * 1.10
FROM employees
WHERE department = 'HR';

-- This gives a 10% salary raise during the copy

-- 7c. Insert aggregated data into a summary table
-- CREATE TABLE dept_summary (department VARCHAR(50), avg_salary NUMERIC(10,2));
-- INSERT INTO dept_summary (department, avg_salary)
-- SELECT department, AVG(salary)
-- FROM employees
-- GROUP BY department;


-- ============================================================================
-- 8. Common Errors and How to Avoid Them
-- ============================================================================

-- ERROR 1: Violating NOT NULL constraint
-- INSERT INTO employees (first_name, last_name, email)
-- VALUES (NULL, 'Test', 'test@company.com');
-- ERROR: null value in column "first_name" violates not-null constraint

-- ERROR 2: Duplicate value on UNIQUE column
-- INSERT INTO employees (first_name, last_name, email)
-- VALUES ('Test', 'User', 'aarav.sharma@company.com');
-- ERROR: duplicate key value violates unique constraint "employees_email_key"
-- FIX: Use ON CONFLICT to handle duplicates gracefully.

-- ERROR 3: Value too long for column
-- INSERT INTO employees (first_name, last_name, email)
-- VALUES ('A very very very very very very very very very long name', 'X', 'x@company.com');
-- ERROR: value too long for type character varying(50)

-- ERROR 4: CHECK constraint violation
-- INSERT INTO products (product_name, category, price, stock_qty)
-- VALUES ('Bad Product', 'Test', -5.00, 10);
-- ERROR: new row violates check constraint "products_price_check"

-- ERROR 5: Wrong number of VALUES (no column list)
-- INSERT INTO employees VALUES ('Only', 'Two');
-- ERROR: INSERT has more target columns than expressions
-- FIX: Always specify the column list explicitly.

-- ERROR 6: Data type mismatch
-- INSERT INTO employees (first_name, last_name, email, salary)
-- VALUES ('Test', 'User', 'test2@company.com', 'not-a-number');
-- ERROR: invalid input syntax for type numeric: "not-a-number"


-- ============================================================================
-- KEY TAKEAWAYS
-- ============================================================================
--
-- 1. Always list columns explicitly — protects against schema changes
-- 2. Use multi-row INSERT for bulk data — far more efficient than individual INSERTs
-- 3. Use DEFAULT keyword or omit columns to leverage default values
-- 4. RETURNING is a PostgreSQL superpower — get inserted data without extra SELECT
-- 5. ON CONFLICT (UPSERT) prevents duplicate-key errors elegantly
-- 6. INSERT ... SELECT is powerful for copying/transforming data between tables
-- 7. Know your constraints (NOT NULL, UNIQUE, CHECK) to avoid runtime errors
-- 8. Wrap bulk inserts in a transaction for atomicity:
--      BEGIN;
--        INSERT INTO ... ;
--        INSERT INTO ... ;
--      COMMIT;
-- ============================================================================
