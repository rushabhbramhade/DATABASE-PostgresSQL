-- ============================================================
-- PRIMARY KEY Constraint in PostgreSQL
-- ============================================================
-- A PRIMARY KEY enforces two rules on a column (or set of columns):
--   1. UNIQUENESS  – no two rows can have the same key value.
--   2. NOT NULL    – every row must have a value for the key column(s).
--
-- Every table should have exactly one primary key.
-- PostgreSQL automatically creates a unique B-tree index on
-- the primary key column(s).
-- ============================================================


-- ============================================================
-- Example 1: Single-Column Primary Key
-- ============================================================
-- The simplest and most common form.

DROP TABLE IF EXISTS employees CASCADE;

CREATE TABLE employees (
    emp_id      INT PRIMARY KEY,
    first_name  VARCHAR(50) NOT NULL,
    last_name   VARCHAR(50) NOT NULL,
    email       VARCHAR(100),
    salary      NUMERIC(10, 2)
);

INSERT INTO employees (emp_id, first_name, last_name, email, salary)
VALUES
    (1, 'Aarav',   'Sharma',  'aarav.sharma@company.com',   75000.00),
    (2, 'Priya',   'Patel',   'priya.patel@company.com',    82000.00),
    (3, 'Rohan',   'Mehta',   'rohan.mehta@company.com',    68000.00),
    (4, 'Sneha',   'Iyer',    'sneha.iyer@company.com',     91000.00),
    (5, 'Vikram',  'Rao',     'vikram.rao@company.com',     73000.00);

SELECT * FROM employees;

-- Expected Output:
-- emp_id | first_name | last_name |           email              |  salary
-- -------+------------+-----------+------------------------------+----------
--      1 | Aarav      | Sharma    | aarav.sharma@company.com     | 75000.00
--      2 | Priya      | Patel     | priya.patel@company.com      | 82000.00
--      3 | Rohan      | Mehta     | rohan.mehta@company.com      | 68000.00
--      4 | Sneha      | Iyer      | sneha.iyer@company.com       | 91000.00
--      5 | Vikram     | Rao       | vikram.rao@company.com       | 73000.00


-- ============================================================
-- Example 2: Attempting to Insert a Duplicate Primary Key
-- ============================================================
-- This will FAIL because emp_id = 1 already exists.

INSERT INTO employees (emp_id, first_name, last_name, salary)
VALUES (1, 'Duplicate', 'Entry', 50000.00);

-- ERROR:  duplicate key value violates unique constraint "employees_pkey"
-- DETAIL: Key (emp_id)=(1) already exists.

-- Attempting to insert NULL into a primary key column also fails:

INSERT INTO employees (emp_id, first_name, last_name, salary)
VALUES (NULL, 'No', 'Id', 50000.00);

-- ERROR:  null value in column "emp_id" of relation "employees"
--         violates not-null constraint


-- ============================================================
-- Example 3: Primary Key with SERIAL (Auto-Increment)
-- ============================================================
-- SERIAL is a shortcut that creates an auto-incrementing integer.
-- PostgreSQL creates a sequence behind the scenes.

DROP TABLE IF EXISTS departments CASCADE;

CREATE TABLE departments (
    dept_id     SERIAL PRIMARY KEY,         -- auto-increments: 1, 2, 3, ...
    dept_name   VARCHAR(100) NOT NULL,
    location    VARCHAR(100)
);

-- No need to supply dept_id — it fills itself automatically.
INSERT INTO departments (dept_name, location)
VALUES
    ('Engineering',       'Building A'),
    ('Human Resources',   'Building B'),
    ('Marketing',         'Building C'),
    ('Finance',           'Building D');

SELECT * FROM departments;

-- Expected Output:
-- dept_id |    dept_name     |  location
-- --------+------------------+------------
--       1 | Engineering      | Building A
--       2 | Human Resources  | Building B
--       3 | Marketing        | Building C
--       4 | Finance          | Building D


-- ============================================================
-- Example 4: GENERATED ALWAYS AS IDENTITY (Modern Auto-Increment)
-- ============================================================
-- Recommended over SERIAL in PostgreSQL 10+.
-- The database fully controls the value; manual inserts are blocked
-- unless you use OVERRIDING SYSTEM VALUE.

DROP TABLE IF EXISTS products CASCADE;

CREATE TABLE products (
    product_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    category     VARCHAR(50),
    price        NUMERIC(10, 2) NOT NULL
);

INSERT INTO products (product_name, category, price)
VALUES
    ('Laptop Pro 15',       'Electronics',  1299.99),
    ('Wireless Mouse',      'Accessories',    29.99),
    ('USB-C Hub',           'Accessories',    49.99),
    ('Mechanical Keyboard', 'Accessories',    89.99),
    ('4K Monitor',          'Electronics',   449.99);

SELECT * FROM products;

-- Expected Output:
-- product_id |    product_name     |   category   |  price
-- -----------+---------------------+--------------+----------
--          1 | Laptop Pro 15       | Electronics  |  1299.99
--          2 | Wireless Mouse      | Accessories  |    29.99
--          3 | USB-C Hub           | Accessories  |    49.99
--          4 | Mechanical Keyboard | Accessories  |    89.99
--          5 | 4K Monitor          | Electronics  |   449.99

-- Trying to manually specify an identity column value:
INSERT INTO products (product_id, product_name, category, price)
VALUES (99, 'Manual Entry', 'Test', 9.99);

-- ERROR:  cannot insert a non-DEFAULT value into column "product_id"
-- DETAIL: Column "product_id" is an identity column defined as GENERATED ALWAYS.
-- HINT:   Use OVERRIDING SYSTEM VALUE to override.

-- If you truly need to override it:
INSERT INTO products (product_id, product_name, category, price)
OVERRIDING SYSTEM VALUE
VALUES (99, 'Manual Entry', 'Test', 9.99);


-- ============================================================
-- Example 5: Composite Primary Key (Multi-Column)
-- ============================================================
-- A composite primary key uses TWO OR MORE columns together
-- as the unique identifier. Common in junction/bridge tables.

DROP TABLE IF EXISTS student_courses CASCADE;
DROP TABLE IF EXISTS students CASCADE;

CREATE TABLE students (
    student_id  SERIAL PRIMARY KEY,
    full_name   VARCHAR(100) NOT NULL,
    major       VARCHAR(50)
);

-- This table tracks which student enrolled in which course in which semester.
-- The combination of (student_id, course_code, semester) must be unique.
CREATE TABLE student_courses (
    student_id   INT NOT NULL,
    course_code  VARCHAR(10) NOT NULL,
    semester     VARCHAR(20) NOT NULL,
    grade        CHAR(2),

    PRIMARY KEY (student_id, course_code, semester)
);

INSERT INTO students (full_name, major)
VALUES
    ('Ananya Gupta',    'Computer Science'),
    ('Karthik Nair',    'Mathematics'),
    ('Divya Menon',     'Physics');

INSERT INTO student_courses (student_id, course_code, semester, grade)
VALUES
    (1, 'CS101', 'Fall 2025',   'A'),
    (1, 'CS102', 'Fall 2025',   'B+'),
    (1, 'CS101', 'Spring 2026', 'A'),   -- same student, same course, different semester → OK
    (2, 'MA201', 'Fall 2025',   'A-'),
    (3, 'PH101', 'Fall 2025',   'B');

SELECT * FROM student_courses;

-- Expected Output:
-- student_id | course_code |   semester    | grade
-- -----------+-------------+---------------+-------
--          1 | CS101       | Fall 2025     | A
--          1 | CS102       | Fall 2025     | B+
--          1 | CS101       | Spring 2026   | A
--          2 | MA201       | Fall 2025     | A-
--          3 | PH101       | Fall 2025     | B

-- Attempting to enroll the same student in the same course in the same semester:
INSERT INTO student_courses (student_id, course_code, semester, grade)
VALUES (1, 'CS101', 'Fall 2025', 'C');

-- ERROR:  duplicate key value violates unique constraint "student_courses_pkey"
-- DETAIL: Key (student_id, course_code, semester)=(1, CS101, Fall 2025) already exists.


-- ============================================================
-- Example 6: Naming Primary Key Constraints
-- ============================================================
-- By default, PostgreSQL names PK constraints as "<table>_pkey".
-- You can give a custom name with CONSTRAINT for clarity.

DROP TABLE IF EXISTS invoices;

CREATE TABLE invoices (
    invoice_id    SERIAL,
    invoice_date  DATE NOT NULL DEFAULT CURRENT_DATE,
    customer_name VARCHAR(100) NOT NULL,
    total_amount  NUMERIC(12, 2) NOT NULL,

    CONSTRAINT pk_invoices PRIMARY KEY (invoice_id)
);

-- The constraint is now named "pk_invoices" instead of "invoices_pkey".
-- This is helpful when reading error messages or managing constraints.

INSERT INTO invoices (customer_name, total_amount)
VALUES
    ('Meera Joshi',   2500.00),
    ('Arjun Desai',   4800.50),
    ('Ritu Singh',    1200.75);

SELECT * FROM invoices;


-- ============================================================
-- Example 7: Natural Key vs Surrogate Key
-- ============================================================

-- NATURAL KEY: Uses a real-world attribute as the primary key.
-- Pros: Meaningful, no extra column needed.
-- Cons: Can change (e.g., email), may be long, not always truly unique.

DROP TABLE IF EXISTS countries;

CREATE TABLE countries (
    country_code  CHAR(3) PRIMARY KEY,    -- ISO 3166-1 alpha-3 code
    country_name  VARCHAR(100) NOT NULL,
    population    BIGINT
);

INSERT INTO countries VALUES
    ('IND', 'India',          1420000000),
    ('USA', 'United States',   335000000),
    ('JPN', 'Japan',           125000000);

-- SURROGATE KEY: Uses an artificial auto-generated value.
-- Pros: Stable, compact, never changes.
-- Cons: Meaningless to humans, extra column.

DROP TABLE IF EXISTS countries_v2;

CREATE TABLE countries_v2 (
    id            SERIAL PRIMARY KEY,     -- surrogate key
    country_code  CHAR(3) UNIQUE NOT NULL,
    country_name  VARCHAR(100) NOT NULL,
    population    BIGINT
);

INSERT INTO countries_v2 (country_code, country_name, population) VALUES
    ('IND', 'India',          1420000000),
    ('USA', 'United States',   335000000),
    ('JPN', 'Japan',           125000000);

-- ┌───────────────────────────────────────────────────────────┐
-- │  GUIDELINE: Use surrogate keys (SERIAL / IDENTITY)       │
-- │  for most tables. Use natural keys only when the value    │
-- │  is guaranteed stable (e.g., ISO codes, SSN — with care).│
-- └───────────────────────────────────────────────────────────┘


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. A PRIMARY KEY = UNIQUE + NOT NULL. Every table should have one.
-- 2. Use SERIAL or GENERATED ALWAYS AS IDENTITY for auto-incrementing keys.
-- 3. GENERATED ALWAYS AS IDENTITY (PG 10+) is preferred over SERIAL.
-- 4. Composite primary keys use multiple columns — common in junction tables.
-- 5. Name your constraints (CONSTRAINT pk_xxx PRIMARY KEY (...)) for clarity.
-- 6. Duplicate or NULL inserts into a PK column produce clear error messages.
-- 7. Prefer surrogate keys for most tables; use natural keys only when stable.
