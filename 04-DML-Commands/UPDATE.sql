-- ============================================================================
-- UPDATE.sql — Modifying Existing Data in PostgreSQL
-- ============================================================================
-- Topic  : UPDATE statement and all its variations
-- Tables : employees, products, departments
-- ============================================================================


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- SETUP: Ensure tables exist and have sample data
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

CREATE TABLE IF NOT EXISTS departments (
    dept_id       SERIAL PRIMARY KEY,
    dept_name     VARCHAR(50) UNIQUE NOT NULL,
    budget        NUMERIC(12,2),
    salary_bonus  NUMERIC(10,2) DEFAULT 0
);

-- Sample data (run only if tables are empty)
INSERT INTO employees (first_name, last_name, email, department, salary, hire_date)
VALUES
    ('Aarav',  'Sharma', 'aarav@company.com',  'Engineering', 75000.00, '2023-03-15'),
    ('Priya',  'Patel',  'priya@company.com',  'Marketing',   62000.00, '2022-07-01'),
    ('Rahul',  'Mehta',  'rahul@company.com',  'Engineering', 80000.00, '2021-11-20'),
    ('Sneha',  'Iyer',   'sneha@company.com',  'HR',          55000.00, '2024-01-10'),
    ('Vikram', 'Singh',  'vikram@company.com', 'Finance',     70000.00, '2023-09-05')
ON CONFLICT (email) DO NOTHING;

INSERT INTO products (product_name, category, price, stock_qty)
VALUES
    ('Wireless Mouse',      'Electronics', 29.99,  150),
    ('Mechanical Keyboard', 'Electronics', 89.99,   75),
    ('Standing Desk',       'Furniture',  349.99,   30),
    ('Ergonomic Chair',     'Furniture',  499.99,   20),
    ('USB-C Hub',           'Electronics', 45.99,  200)
ON CONFLICT DO NOTHING;

INSERT INTO departments (dept_name, budget, salary_bonus)
VALUES
    ('Engineering', 500000, 5000.00),
    ('Marketing',   200000, 3000.00),
    ('HR',          150000, 2000.00),
    ('Finance',     300000, 4000.00)
ON CONFLICT (dept_name) DO NOTHING;


-- ============================================================================
-- 1. UPDATE a Single Column
-- ============================================================================

-- BEFORE:
-- SELECT employee_id, first_name, salary FROM employees WHERE employee_id = 1;
--  employee_id | first_name |  salary
-- -------------+------------+----------
--            1 | Aarav      | 75000.00

UPDATE employees
SET salary = 82000.00
WHERE employee_id = 1;

-- AFTER:
-- SELECT employee_id, first_name, salary FROM employees WHERE employee_id = 1;
--  employee_id | first_name |  salary
-- -------------+------------+----------
--            1 | Aarav      | 82000.00


-- ============================================================================
-- 2. UPDATE Multiple Columns at Once
-- ============================================================================

-- BEFORE:
-- SELECT employee_id, first_name, department, salary FROM employees WHERE employee_id = 4;
--  employee_id | first_name | department |  salary
-- -------------+------------+------------+----------
--            4 | Sneha      | HR         | 55000.00

UPDATE employees
SET department = 'Engineering',
    salary     = 68000.00
WHERE employee_id = 4;

-- AFTER:
-- SELECT employee_id, first_name, department, salary FROM employees WHERE employee_id = 4;
--  employee_id | first_name | department  |  salary
-- -------------+------------+-------------+----------
--            4 | Sneha      | Engineering | 68000.00


-- ============================================================================
-- 3. UPDATE with WHERE — Filtering Which Rows to Change
-- ============================================================================

-- ⚠️  GOLDEN RULE: Always use WHERE unless you intentionally want to update
--    every single row in the table!

-- Update all employees in Engineering — give them a 10% raise
-- BEFORE:
-- SELECT first_name, department, salary FROM employees WHERE department = 'Engineering';
--  first_name | department  |  salary
-- ------------+-------------+----------
--  Aarav      | Engineering | 82000.00
--  Rahul      | Engineering | 80000.00
--  Sneha      | Engineering | 68000.00

UPDATE employees
SET salary = salary * 1.10
WHERE department = 'Engineering';

-- AFTER:
-- SELECT first_name, department, salary FROM employees WHERE department = 'Engineering';
--  first_name | department  |  salary
-- ------------+-------------+----------
--  Aarav      | Engineering | 90200.00
--  Rahul      | Engineering | 88000.00
--  Sneha      | Engineering | 74800.00

-- Update with multiple conditions
UPDATE products
SET price = price * 0.90
WHERE category = 'Electronics' AND stock_qty > 100;
-- Applies a 10% discount to electronics with high stock (Wireless Mouse, USB-C Hub)


-- ============================================================================
-- 4. UPDATE with Expressions and Functions
-- ============================================================================

-- Use built-in functions in the SET clause
UPDATE employees
SET email = LOWER(first_name || '.' || last_name || '@newdomain.com')
WHERE employee_id = 2;

-- AFTER:
-- SELECT email FROM employees WHERE employee_id = 2;
--           email
-- -------------------------
--  priya.patel@newdomain.com

-- Update dates using intervals
UPDATE employees
SET hire_date = hire_date + INTERVAL '1 year'
WHERE hire_date < '2022-01-01';
-- Shifts hire_date forward by 1 year for early hires

-- Round salaries to the nearest thousand
UPDATE employees
SET salary = ROUND(salary, -3)
WHERE department = 'Engineering';


-- ============================================================================
-- 5. UPDATE with Subquery
-- ============================================================================

-- Set salary to the department average for a specific employee
UPDATE employees
SET salary = (
    SELECT AVG(salary)
    FROM employees
    WHERE department = 'Engineering'
)
WHERE employee_id = 4;

-- Update stock to zero for the most expensive product
UPDATE products
SET stock_qty = 0
WHERE price = (SELECT MAX(price) FROM products);

-- Update department based on a lookup
UPDATE employees
SET department = 'Marketing'
WHERE employee_id IN (
    SELECT employee_id
    FROM employees
    WHERE salary < 60000
);


-- ============================================================================
-- 6. UPDATE with JOIN (PostgreSQL FROM Syntax)
-- ============================================================================
-- PostgreSQL uses FROM instead of standard SQL JOIN inside UPDATE.
-- This lets you reference another table to drive the update.

-- Give every employee a department-specific bonus from the departments table
-- BEFORE:
-- SELECT e.first_name, e.department, e.salary, d.salary_bonus
-- FROM employees e JOIN departments d ON e.department = d.dept_name;

UPDATE employees
SET salary = employees.salary + d.salary_bonus
FROM departments d
WHERE employees.department = d.dept_name;

-- AFTER: Each employee's salary is increased by their department's bonus
-- Aarav (Engineering): salary + 5000
-- Priya (Marketing):   salary + 3000
-- Rahul (Engineering):  salary + 5000  ... etc.

-- Another example: Update product prices based on a category discount table
-- CREATE TABLE category_discounts (category VARCHAR(50), discount NUMERIC(3,2));
-- INSERT INTO category_discounts VALUES ('Furniture', 0.15);
--
-- UPDATE products
-- SET price = products.price * (1 - cd.discount)
-- FROM category_discounts cd
-- WHERE products.category = cd.category;


-- ============================================================================
-- 7. UPDATE ... RETURNING (PostgreSQL-Specific)
-- ============================================================================
-- See the updated values immediately without a separate SELECT.

UPDATE employees
SET salary = salary + 2000
WHERE department = 'Finance'
RETURNING employee_id, first_name, last_name, salary AS new_salary;

-- Expected:
--  employee_id | first_name | last_name | new_salary
-- -------------+------------+-----------+------------
--            5 | Vikram     | Singh     |   76000.00

-- Return old and new values using a CTE (advanced technique)
WITH updated AS (
    UPDATE products
    SET price = price * 0.95
    WHERE category = 'Furniture'
    RETURNING product_id, product_name, price AS new_price
)
SELECT u.product_id, u.product_name, u.new_price
FROM updated u;

-- Expected:
--  product_id |  product_name   | new_price
-- ------------+-----------------+-----------
--           3 | Standing Desk   |    332.49
--           4 | Ergonomic Chair |    474.99


-- ============================================================================
-- 8. ⚠️  SAFETY: UPDATE Without WHERE — Updating ALL Rows
-- ============================================================================
-- This is DANGEROUS in production! It modifies every row in the table.

-- ❌ BAD — This gives EVERYONE a raise (probably not what you want):
-- UPDATE employees SET salary = salary * 1.05;

-- ✅ SAFE — Always scope your update:
-- UPDATE employees SET salary = salary * 1.05 WHERE department = 'Engineering';

-- BEST PRACTICE: Test with SELECT first!
-- Step 1: Preview which rows will be affected
SELECT employee_id, first_name, salary, salary * 1.05 AS projected_salary
FROM employees
WHERE department = 'Engineering';

-- Step 2: If the SELECT looks correct, run the UPDATE
UPDATE employees
SET salary = salary * 1.05
WHERE department = 'Engineering';

-- Step 3: Use transactions for extra safety
BEGIN;
    UPDATE employees SET is_active = FALSE WHERE hire_date < '2022-01-01';
    -- Check: SELECT * FROM employees WHERE is_active = FALSE;
    -- If wrong: ROLLBACK;
    -- If correct: COMMIT;
COMMIT;


-- ============================================================================
-- 9. Conditional UPDATE with CASE
-- ============================================================================

-- Give raises based on salary brackets
UPDATE employees
SET salary = CASE
    WHEN salary < 60000  THEN salary * 1.15   -- 15% raise for lower salaries
    WHEN salary < 80000  THEN salary * 1.10   -- 10% raise for mid-range
    ELSE salary * 1.05                         --  5% raise for higher salaries
END
WHERE is_active = TRUE;

-- BEFORE/AFTER example:
--  first_name | old_salary | new_salary
-- ------------+------------+------------
--  Sneha      |  55000.00  |  63250.00  (15% raise)
--  Priya      |  62000.00  |  68200.00  (10% raise)
--  Rahul      |  88000.00  |  92400.00  ( 5% raise)


-- ============================================================================
-- KEY TAKEAWAYS
-- ============================================================================
--
-- 1. ALWAYS use WHERE — an UPDATE without WHERE changes EVERY row
-- 2. Test with SELECT first — preview the rows before modifying them
-- 3. Use transactions (BEGIN/COMMIT/ROLLBACK) for safe, reversible changes
-- 4. PostgreSQL uses FROM for joins in UPDATE (not standard JOIN syntax)
-- 5. RETURNING gives you immediate feedback on what changed
-- 6. Use CASE for conditional updates within a single statement
-- 7. Expressions like salary * 1.10 are evaluated per-row
-- 8. Subqueries in SET let you compute values from other tables/rows
-- 9. UPDATE returns the count of affected rows — always check it!
-- ============================================================================
