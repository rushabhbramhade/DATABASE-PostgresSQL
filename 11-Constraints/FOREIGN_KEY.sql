-- ============================================================
-- FOREIGN KEY Constraint in PostgreSQL
-- ============================================================
-- A FOREIGN KEY enforces REFERENTIAL INTEGRITY between two tables.
-- It ensures that a value in the child table always matches
-- an existing value in the parent table's referenced column.
--
-- Terminology:
--   Parent table  = the table being referenced (has the PK/UNIQUE)
--   Child table   = the table containing the FOREIGN KEY
--
-- PostgreSQL checks the FK on INSERT, UPDATE, and DELETE.
-- ============================================================


-- ============================================================
-- Setup: Create Parent Tables
-- ============================================================

DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS enrollments CASCADE;

CREATE TABLE departments (
    dept_id     SERIAL PRIMARY KEY,
    dept_name   VARCHAR(100) NOT NULL,
    location    VARCHAR(100)
);

INSERT INTO departments (dept_name, location)
VALUES
    ('Engineering',     'Building A'),
    ('Human Resources', 'Building B'),
    ('Marketing',       'Building C'),
    ('Finance',         'Building D');


-- ============================================================
-- Example 1: Basic Foreign Key (REFERENCES)
-- ============================================================
-- Each employee must belong to a department that exists.

CREATE TABLE employees (
    emp_id      SERIAL PRIMARY KEY,
    first_name  VARCHAR(50) NOT NULL,
    last_name   VARCHAR(50) NOT NULL,
    email       VARCHAR(100),
    salary      NUMERIC(10, 2),
    dept_id     INT REFERENCES departments(dept_id)   -- FK to departments
);

INSERT INTO employees (first_name, last_name, email, salary, dept_id)
VALUES
    ('Aarav',  'Sharma', 'aarav@company.com',  75000, 1),
    ('Priya',  'Patel',  'priya@company.com',  82000, 2),
    ('Rohan',  'Mehta',  'rohan@company.com',  68000, 1),
    ('Sneha',  'Iyer',   'sneha@company.com',  91000, 3),
    ('Vikram', 'Rao',    'vikram@company.com', 73000, 4);

SELECT e.emp_id, e.first_name, e.last_name, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;

-- Expected Output:
-- emp_id | first_name | last_name |    dept_name
-- -------+------------+-----------+-----------------
--      1 | Aarav      | Sharma    | Engineering
--      2 | Priya      | Patel     | Human Resources
--      3 | Rohan      | Mehta     | Engineering
--      4 | Sneha      | Iyer      | Marketing
--      5 | Vikram     | Rao       | Finance


-- ============================================================
-- Example 2: Attempting to Insert an Invalid Foreign Key
-- ============================================================
-- dept_id = 99 does not exist in departments → INSERT fails.

INSERT INTO employees (first_name, last_name, salary, dept_id)
VALUES ('Ghost', 'Employee', 50000, 99);

-- ERROR:  insert or update on table "employees" violates foreign key
--         constraint "employees_dept_id_fkey"
-- DETAIL: Key (dept_id)=(99) is not present in table "departments".


-- ============================================================
-- Example 3: ON DELETE RESTRICT (Default Behavior)
-- ============================================================
-- You cannot delete a parent row if child rows reference it.
-- RESTRICT is the default — you don't need to write it explicitly.

DROP TABLE IF EXISTS employees CASCADE;

CREATE TABLE employees (
    emp_id      SERIAL PRIMARY KEY,
    first_name  VARCHAR(50) NOT NULL,
    last_name   VARCHAR(50) NOT NULL,
    dept_id     INT,

    CONSTRAINT fk_emp_dept
        FOREIGN KEY (dept_id)
        REFERENCES departments(dept_id)
        ON DELETE RESTRICT                   -- explicit, but this is the default
);

INSERT INTO employees (first_name, last_name, dept_id)
VALUES ('Aarav', 'Sharma', 1);

-- Try to delete Engineering (dept_id = 1) which has employees:
DELETE FROM departments WHERE dept_id = 1;

-- ERROR:  update or delete on table "departments" violates foreign key
--         constraint "fk_emp_dept" on table "employees"
-- DETAIL: Key (dept_id)=(1) is still referenced from table "employees".


-- ============================================================
-- Example 4: ON DELETE CASCADE
-- ============================================================
-- Deleting a parent row automatically deletes all child rows.
-- USE WITH CAUTION — data is permanently removed.

DROP TABLE IF EXISTS employees CASCADE;

CREATE TABLE employees (
    emp_id      SERIAL PRIMARY KEY,
    first_name  VARCHAR(50) NOT NULL,
    last_name   VARCHAR(50) NOT NULL,
    dept_id     INT,

    CONSTRAINT fk_emp_dept_cascade
        FOREIGN KEY (dept_id)
        REFERENCES departments(dept_id)
        ON DELETE CASCADE                    -- child rows are deleted too
);

INSERT INTO employees (first_name, last_name, dept_id)
VALUES
    ('Aarav',  'Sharma', 1),
    ('Rohan',  'Mehta',  1),
    ('Priya',  'Patel',  2);

SELECT 'Before DELETE' AS status, count(*) AS employee_count FROM employees;
-- status        | employee_count
-- Before DELETE |              3

-- Delete the Engineering department (dept_id = 1):
DELETE FROM departments WHERE dept_id = 1;

SELECT 'After DELETE' AS status, count(*) AS employee_count FROM employees;
-- status       | employee_count
-- After DELETE |              1
-- Aarav and Rohan (dept_id=1) were automatically deleted.

-- Re-insert Engineering for later examples:
INSERT INTO departments (dept_id, dept_name, location)
OVERRIDING SYSTEM VALUE
VALUES (1, 'Engineering', 'Building A');


-- ============================================================
-- Example 5: ON DELETE SET NULL
-- ============================================================
-- Deleting a parent row sets the FK column in child rows to NULL.
-- The child rows survive, but lose their department reference.

DROP TABLE IF EXISTS employees CASCADE;

CREATE TABLE employees (
    emp_id      SERIAL PRIMARY KEY,
    first_name  VARCHAR(50) NOT NULL,
    last_name   VARCHAR(50) NOT NULL,
    dept_id     INT,                          -- must be nullable for SET NULL

    CONSTRAINT fk_emp_dept_setnull
        FOREIGN KEY (dept_id)
        REFERENCES departments(dept_id)
        ON DELETE SET NULL
);

INSERT INTO employees (first_name, last_name, dept_id)
VALUES
    ('Sneha',  'Iyer',  3),
    ('Vikram', 'Rao',   3),
    ('Priya',  'Patel', 2);

-- Delete the Marketing department (dept_id = 3):
DELETE FROM departments WHERE dept_id = 3;

SELECT emp_id, first_name, last_name, dept_id FROM employees ORDER BY emp_id;

-- Expected Output:
-- emp_id | first_name | last_name | dept_id
-- -------+------------+-----------+---------
--      1 | Sneha      | Iyer      |  (NULL)    ← was dept_id = 3
--      2 | Vikram     | Rao       |  (NULL)    ← was dept_id = 3
--      3 | Priya      | Patel     |       2    ← unchanged

-- Re-insert Marketing for later examples:
INSERT INTO departments (dept_id, dept_name, location)
OVERRIDING SYSTEM VALUE
VALUES (3, 'Marketing', 'Building C');


-- ============================================================
-- Example 6: ON UPDATE CASCADE
-- ============================================================
-- If the parent key value changes, the FK in child rows updates too.

DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS enrollments CASCADE;

CREATE TABLE students (
    student_code VARCHAR(10) PRIMARY KEY,     -- natural key, might change
    full_name    VARCHAR(100) NOT NULL,
    major        VARCHAR(50)
);

CREATE TABLE enrollments (
    enrollment_id  SERIAL PRIMARY KEY,
    student_code   VARCHAR(10),
    course_name    VARCHAR(100) NOT NULL,

    CONSTRAINT fk_enrollment_student
        FOREIGN KEY (student_code)
        REFERENCES students(student_code)
        ON UPDATE CASCADE                     -- child follows parent's update
        ON DELETE CASCADE
);

INSERT INTO students VALUES
    ('STU001', 'Ananya Gupta',  'Computer Science'),
    ('STU002', 'Karthik Nair',  'Mathematics');

INSERT INTO enrollments (student_code, course_name) VALUES
    ('STU001', 'Database Systems'),
    ('STU001', 'Data Structures'),
    ('STU002', 'Linear Algebra');

-- Suppose we change Ananya's student code:
UPDATE students SET student_code = 'CS-001' WHERE student_code = 'STU001';

SELECT * FROM enrollments;

-- Expected Output:
-- enrollment_id | student_code |   course_name
-- --------------+--------------+------------------
--             1 | CS-001       | Database Systems    ← automatically updated!
--             2 | CS-001       | Data Structures     ← automatically updated!
--             3 | STU002       | Linear Algebra


-- ============================================================
-- Example 7: Self-Referencing Foreign Key (Manager Hierarchy)
-- ============================================================
-- An employee's manager is also an employee in the same table.

DROP TABLE IF EXISTS employees CASCADE;

CREATE TABLE employees (
    emp_id      SERIAL PRIMARY KEY,
    first_name  VARCHAR(50) NOT NULL,
    last_name   VARCHAR(50) NOT NULL,
    job_title   VARCHAR(50),
    manager_id  INT,                          -- points back to this same table

    CONSTRAINT fk_manager
        FOREIGN KEY (manager_id)
        REFERENCES employees(emp_id)
        ON DELETE SET NULL
);

-- Insert the CEO first (no manager):
INSERT INTO employees (first_name, last_name, job_title, manager_id)
VALUES ('Meera', 'Joshi', 'CEO', NULL);

-- Now insert employees who report to the CEO (emp_id = 1):
INSERT INTO employees (first_name, last_name, job_title, manager_id)
VALUES
    ('Arjun',  'Desai',   'VP Engineering',   1),
    ('Ritu',   'Singh',   'VP Marketing',     1);

-- Insert employees who report to VP Engineering (emp_id = 2):
INSERT INTO employees (first_name, last_name, job_title, manager_id)
VALUES
    ('Aarav',  'Sharma',  'Senior Developer', 2),
    ('Priya',  'Patel',   'Junior Developer', 2);

-- Query: Show each employee with their manager's name
SELECT
    e.emp_id,
    e.first_name || ' ' || e.last_name  AS employee,
    e.job_title,
    m.first_name || ' ' || m.last_name  AS reports_to
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id
ORDER BY e.emp_id;

-- Expected Output:
-- emp_id |   employee     |    job_title      |  reports_to
-- -------+----------------+-------------------+--------------
--      1 | Meera Joshi    | CEO               | (NULL)
--      2 | Arjun Desai    | VP Engineering    | Meera Joshi
--      3 | Ritu Singh     | VP Marketing      | Meera Joshi
--      4 | Aarav Sharma   | Senior Developer  | Arjun Desai
--      5 | Priya Patel    | Junior Developer  | Arjun Desai

-- Self-referencing FK still enforces integrity:
INSERT INTO employees (first_name, last_name, job_title, manager_id)
VALUES ('Ghost', 'Person', 'Intern', 999);

-- ERROR:  insert or update on table "employees" violates foreign key
--         constraint "fk_manager"
-- DETAIL: Key (manager_id)=(999) is not present in table "employees".


-- ============================================================
-- Example 8: Named Foreign Key with Products & Orders
-- ============================================================
-- A complete order system showing multiple FKs in one table.

DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;

CREATE TABLE products (
    product_id   SERIAL PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    price        NUMERIC(10, 2) NOT NULL
);

CREATE TABLE orders (
    order_id     SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    order_date   DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE order_items (
    item_id      SERIAL PRIMARY KEY,
    order_id     INT NOT NULL,
    product_id   INT NOT NULL,
    quantity     INT NOT NULL DEFAULT 1,

    CONSTRAINT fk_orderitem_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_orderitem_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE RESTRICT
);

INSERT INTO products (product_name, price) VALUES
    ('Laptop Pro 15',       1299.99),
    ('Wireless Mouse',        29.99),
    ('USB-C Hub',             49.99);

INSERT INTO orders (customer_name) VALUES
    ('Ananya Gupta'),
    ('Karthik Nair');

INSERT INTO order_items (order_id, product_id, quantity) VALUES
    (1, 1, 1),   -- Ananya orders 1 Laptop
    (1, 2, 2),   -- Ananya orders 2 Mice
    (2, 3, 1);   -- Karthik orders 1 USB-C Hub

-- Delete order 1 → CASCADE removes its items automatically
DELETE FROM orders WHERE order_id = 1;

SELECT * FROM order_items;
-- Only Karthik's order item remains:
-- item_id | order_id | product_id | quantity
-- --------+----------+------------+---------
--       3 |        2 |          3 |       1

-- Try to delete a product that is still referenced:
DELETE FROM products WHERE product_id = 3;
-- ERROR:  update or delete on table "products" violates foreign key
--         constraint "fk_orderitem_product" on table "order_items"


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. FOREIGN KEY ensures every child value exists in the parent table.
-- 2. ON DELETE RESTRICT (default) — blocks parent deletion if children exist.
-- 3. ON DELETE CASCADE  — deletes child rows when the parent is deleted.
-- 4. ON DELETE SET NULL — sets child FK to NULL when the parent is deleted.
-- 5. ON UPDATE CASCADE  — updates child FK when the parent key changes.
-- 6. Self-referencing FKs model hierarchies (employee → manager).
-- 7. Always name your FK constraints for readable error messages.
-- 8. The FK column's data type must match the referenced column's data type.
