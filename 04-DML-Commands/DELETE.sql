-- ============================================================================
-- DELETE.sql — Removing Data from PostgreSQL Tables
-- ============================================================================
-- Topic  : DELETE statement and all its variations
-- Tables : employees, products, departments, order_items, orders
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

CREATE TABLE IF NOT EXISTS orders (
    order_id      SERIAL PRIMARY KEY,
    customer_name VARCHAR(100),
    order_date    DATE DEFAULT CURRENT_DATE,
    status        VARCHAR(20) DEFAULT 'pending'
);

CREATE TABLE IF NOT EXISTS order_items (
    item_id       SERIAL PRIMARY KEY,
    order_id      INT REFERENCES orders(order_id),
    product_id    INT REFERENCES products(product_id),
    quantity      INT,
    unit_price    NUMERIC(10,2)
);

-- Sample data
INSERT INTO employees (first_name, last_name, email, department, salary, hire_date, is_active)
VALUES
    ('Aarav',   'Sharma', 'aarav@company.com',   'Engineering', 75000, '2023-03-15', TRUE),
    ('Priya',   'Patel',  'priya@company.com',   'Marketing',   62000, '2022-07-01', TRUE),
    ('Rahul',   'Mehta',  'rahul@company.com',   'Engineering', 80000, '2021-11-20', TRUE),
    ('Sneha',   'Iyer',   'sneha@company.com',   'HR',          55000, '2024-01-10', TRUE),
    ('Vikram',  'Singh',  'vikram@company.com',  'Finance',     70000, '2023-09-05', TRUE),
    ('Deepak',  'Kumar',  'deepak@company.com',  'Marketing',   45000, '2020-06-01', FALSE),
    ('Meera',   'Nair',   'meera@company.com',   'HR',          48000, '2019-03-22', FALSE)
ON CONFLICT (email) DO NOTHING;

INSERT INTO orders (customer_name, order_date, status)
VALUES
    ('Alice Johnson',  '2026-01-15', 'completed'),
    ('Bob Williams',   '2026-03-20', 'cancelled'),
    ('Carol Davis',    '2026-05-10', 'pending'),
    ('Dave Brown',     '2026-06-01', 'cancelled')
ON CONFLICT DO NOTHING;

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (2, 1, 3, 29.99), (4, 2, 1, 89.99)
ON CONFLICT DO NOTHING;


-- ============================================================================
-- 1. DELETE with WHERE — Remove Specific Rows
-- ============================================================================
-- This is the STANDARD and SAFE way to delete data.

-- BEFORE:
-- SELECT employee_id, first_name, is_active FROM employees WHERE is_active = FALSE;
--  employee_id | first_name | is_active
-- -------------+------------+-----------
--            6 | Deepak     | f
--            7 | Meera      | f

DELETE FROM employees
WHERE is_active = FALSE;

-- Expected: DELETE 2  (2 rows removed)

-- AFTER:
-- SELECT employee_id, first_name, is_active FROM employees;
--  employee_id | first_name | is_active
-- -------------+------------+-----------
--            1 | Aarav      | t
--            2 | Priya      | t
--            3 | Rahul      | t
--            4 | Sneha      | t
--            5 | Vikram     | t

-- Delete with multiple conditions
DELETE FROM products
WHERE category = 'Electronics' AND stock_qty = 0;

-- Delete using comparison operators
DELETE FROM employees
WHERE hire_date < '2022-01-01';
-- Removes employees hired before 2022

-- Delete using pattern matching
DELETE FROM employees
WHERE email LIKE '%@olddomain.com';


-- ============================================================================
-- 2. ⚠️  DELETE All Rows — DANGEROUS!
-- ============================================================================
-- Omitting WHERE removes EVERY row from the table.
-- The table structure remains, but all data is gone.

-- ❌ DANGER — This wipes the entire table:
-- DELETE FROM products;

-- Expected: DELETE <N>  (all rows removed)
-- The table still exists but is empty.
-- SERIAL counters do NOT reset (next insert gets the next ID, not 1).

-- ✅ SAFE ALTERNATIVE: Always add WHERE
-- DELETE FROM products WHERE category = 'Discontinued';


-- ============================================================================
-- 3. DELETE with Subquery
-- ============================================================================

-- Delete employees who earn less than the company average
DELETE FROM employees
WHERE salary < (SELECT AVG(salary) FROM employees);

-- Expected: Removes employees whose salary is below average

-- Delete products that have never been ordered
DELETE FROM products
WHERE product_id NOT IN (
    SELECT DISTINCT product_id
    FROM order_items
    WHERE product_id IS NOT NULL
);

-- Delete using EXISTS (often faster than NOT IN for large datasets)
DELETE FROM products p
WHERE NOT EXISTS (
    SELECT 1
    FROM order_items oi
    WHERE oi.product_id = p.product_id
);

-- Delete the oldest order
DELETE FROM orders
WHERE order_date = (SELECT MIN(order_date) FROM orders);


-- ============================================================================
-- 4. DELETE with JOIN — PostgreSQL USING Syntax
-- ============================================================================
-- PostgreSQL uses USING instead of JOIN inside DELETE statements.
-- This lets you reference another table to decide which rows to delete.

-- Delete all order items that belong to cancelled orders
-- BEFORE:
-- SELECT oi.item_id, oi.order_id, o.status
-- FROM order_items oi JOIN orders o ON oi.order_id = o.order_id;
--  item_id | order_id |  status
-- ---------+----------+-----------
--        1 |        2 | cancelled
--        2 |        4 | cancelled

DELETE FROM order_items
USING orders
WHERE order_items.order_id = orders.order_id
  AND orders.status = 'cancelled';

-- Expected: DELETE 2 (items from cancelled orders removed)

-- Delete employees from departments with low budgets
-- CREATE TABLE departments (dept_name VARCHAR(50), budget NUMERIC(12,2));
-- DELETE FROM employees
-- USING departments
-- WHERE employees.department = departments.dept_name
--   AND departments.budget < 100000;

-- Multi-table USING (reference multiple tables)
-- DELETE FROM order_items
-- USING orders, products
-- WHERE order_items.order_id = orders.order_id
--   AND order_items.product_id = products.product_id
--   AND orders.status = 'cancelled'
--   AND products.category = 'Electronics';


-- ============================================================================
-- 5. DELETE ... RETURNING (PostgreSQL-Specific)
-- ============================================================================
-- See exactly what was deleted. Great for auditing and logging.

-- Delete and return the deleted rows
DELETE FROM orders
WHERE status = 'cancelled'
RETURNING *;

-- Expected:
--  order_id | customer_name  | order_date |  status
-- ----------+----------------+------------+-----------
--         2 | Bob Williams   | 2026-03-20 | cancelled
--         4 | Dave Brown     | 2026-06-01 | cancelled

-- Return only specific columns
DELETE FROM employees
WHERE employee_id = 5
RETURNING employee_id, first_name || ' ' || last_name AS full_name, email;

-- Expected:
--  employee_id |   full_name   |       email
-- -------------+---------------+--------------------
--            5 | Vikram Singh  | vikram@company.com

-- Use RETURNING with a CTE to archive before deleting
WITH deleted_rows AS (
    DELETE FROM employees
    WHERE is_active = FALSE
    RETURNING *
)
INSERT INTO employees_archive
SELECT employee_id, first_name, last_name, email, department, salary
FROM deleted_rows;

-- This is a powerful "move rows" pattern:
-- 1. Delete from the active table
-- 2. Insert the deleted rows into an archive table
-- All in a single atomic operation!


-- ============================================================================
-- 6. DELETE vs TRUNCATE — Comparison
-- ============================================================================

-- ┌─────────────────────┬──────────────────────────────┬──────────────────────────────┐
-- │     Feature         │          DELETE               │         TRUNCATE             │
-- ├─────────────────────┼──────────────────────────────┼──────────────────────────────┤
-- │ Removes             │ Specific rows (with WHERE)   │ ALL rows (no WHERE allowed)  │
-- │ Speed               │ Slower (row-by-row logging)  │ Much faster (deallocates)    │
-- │ WHERE clause        │ ✅ Supported                 │ ❌ Not supported             │
-- │ RETURNING clause    │ ✅ Supported                 │ ❌ Not supported             │
-- │ Transaction safe    │ ✅ Can ROLLBACK              │ ✅ Can ROLLBACK in PG        │
-- │ Fires triggers      │ ✅ Yes (row-level triggers)  │ ❌ No (only statement-level) │
-- │ Resets SERIAL/IDENTITY│ ❌ No                      │ ✅ With RESTART IDENTITY     │
-- │ Frees disk space    │ ❌ Not immediately           │ ✅ Immediately               │
-- │ Foreign key checks  │ ✅ Row by row                │ ❌ Fails if referenced       │
-- └─────────────────────┴──────────────────────────────┴──────────────────────────────┘

-- TRUNCATE examples:

-- Remove all rows and reset the ID counter
TRUNCATE TABLE products RESTART IDENTITY;

-- Truncate multiple tables at once
-- TRUNCATE TABLE orders, order_items RESTART IDENTITY;

-- Truncate with CASCADE (also truncates tables that reference this one)
-- TRUNCATE TABLE orders CASCADE;
-- ⚠️  Use CASCADE with extreme caution!

-- When to use each:
-- DELETE  → Remove specific rows, need triggers, need RETURNING
-- TRUNCATE → Wipe an entire table fast, reset IDs, re-seed test data


-- ============================================================================
-- 7. Safety Best Practices
-- ============================================================================

-- PRACTICE 1: Always preview with SELECT before DELETE
SELECT * FROM employees WHERE hire_date < '2022-01-01';
-- Check the rows, then:
-- DELETE FROM employees WHERE hire_date < '2022-01-01';

-- PRACTICE 2: Use transactions
BEGIN;
    DELETE FROM employees WHERE department = 'Temp';
    -- Verify: SELECT COUNT(*) FROM employees;
    -- If wrong: ROLLBACK;
    -- If correct: COMMIT;
COMMIT;

-- PRACTICE 3: Use RETURNING to log what was deleted
DELETE FROM products WHERE stock_qty = 0 RETURNING product_id, product_name;

-- PRACTICE 4: Soft delete instead of hard delete
-- Instead of actually deleting, mark rows as inactive:
-- UPDATE employees SET is_active = FALSE WHERE employee_id = 3;
-- Then filter with: SELECT * FROM employees WHERE is_active = TRUE;

-- PRACTICE 5: Limit deletes to avoid accidents (PostgreSQL supports this via CTE)
WITH rows_to_delete AS (
    SELECT employee_id
    FROM employees
    WHERE department = 'Marketing'
    LIMIT 1
)
DELETE FROM employees
WHERE employee_id IN (SELECT employee_id FROM rows_to_delete);
-- Deletes only 1 row from Marketing, even if many match

-- PRACTICE 6: Handle foreign key constraints
-- Option A: Delete child rows first, then parent
-- DELETE FROM order_items WHERE order_id = 5;
-- DELETE FROM orders WHERE order_id = 5;
--
-- Option B: Use ON DELETE CASCADE in table design
-- CREATE TABLE order_items (
--     ...
--     order_id INT REFERENCES orders(order_id) ON DELETE CASCADE
-- );
-- Now: DELETE FROM orders WHERE order_id = 5;
--      → Automatically deletes related order_items too


-- ============================================================================
-- KEY TAKEAWAYS
-- ============================================================================
--
-- 1. ALWAYS use WHERE in DELETE — without it, you lose all data in the table
-- 2. Preview with SELECT first — see exactly which rows will be removed
-- 3. Use RETURNING to capture/audit deleted data
-- 4. PostgreSQL uses USING (not JOIN) for multi-table deletes
-- 5. Wrap deletes in BEGIN/COMMIT transactions for safety
-- 6. Consider soft deletes (is_active = FALSE) over hard deletes
-- 7. Use TRUNCATE for fast, full-table wipes with ID reset
-- 8. The CTE + DELETE + INSERT pattern is perfect for archiving rows
-- 9. Mind foreign keys — delete child rows first or use ON DELETE CASCADE
-- ============================================================================
