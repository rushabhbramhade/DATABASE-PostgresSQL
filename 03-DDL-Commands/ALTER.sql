-- ============================================================
-- ALTER.sql — Schema Modifications in PostgreSQL
-- ============================================================
-- Covers: ALTER TABLE (ADD, DROP, RENAME, MODIFY columns),
--         ALTER constraints, ALTER TABLE RENAME, and
--         real-world schema evolution patterns
-- ============================================================

-- Setup: Assume these tables already exist (from CREATE.sql)
/*
  departments (department_id, department_name, location, created_at)
  employees   (employee_id, first_name, last_name, email, phone,
               hire_date, salary, is_active, department_id, bio, created_at)
  products    (product_id, product_name, category, sku, price, cost,
               stock_quantity, weight_kg, is_available, created_at)
  orders      (order_id, order_date, customer_name, customer_email,
               employee_id, total_amount, status, notes)
*/


-- ************************************************************
-- 1. ALTER TABLE — ADD COLUMN
-- ************************************************************

-- Add a single column
ALTER TABLE employees ADD COLUMN middle_name VARCHAR(50);

-- Expected: A new nullable column 'middle_name' is added at the end
-- Existing rows get NULL for this column

-- Add a column with a default value
ALTER TABLE employees ADD COLUMN employment_type VARCHAR(20) DEFAULT 'full-time';

-- Expected: New column added; all existing rows get 'full-time' as the value

-- Add a column with NOT NULL (requires DEFAULT for existing rows)
ALTER TABLE departments ADD COLUMN budget NUMERIC(15, 2) NOT NULL DEFAULT 0.00;

-- Expected: Column added with 0.00 for all existing rows
-- Without DEFAULT, this would FAIL if the table already has rows

-- Add multiple columns in one statement
ALTER TABLE products
    ADD COLUMN manufacturer  VARCHAR(100),
    ADD COLUMN warranty_months INTEGER DEFAULT 12,
    ADD COLUMN discontinued  BOOLEAN DEFAULT FALSE;


-- ************************************************************
-- 2. ALTER TABLE — DROP COLUMN
-- ************************************************************

-- Drop a single column
ALTER TABLE employees DROP COLUMN bio;

-- Expected: The 'bio' column and all its data are permanently removed
-- WARNING: This is irreversible — data in this column is lost

-- Drop a column only if it exists (prevents errors in scripts)
ALTER TABLE employees DROP COLUMN IF EXISTS middle_name;

-- Expected: Drops the column if it exists; no error if it doesn't

-- Drop a column that has dependencies (views, foreign keys)
ALTER TABLE products DROP COLUMN manufacturer CASCADE;

-- CASCADE drops dependent objects (views, indexes referencing this column)
-- RESTRICT (default) would block the drop if dependencies exist


-- ************************************************************
-- 3. ALTER TABLE — RENAME COLUMN
-- ************************************************************

-- Rename a column
ALTER TABLE employees RENAME COLUMN phone TO phone_number;

-- Expected: Column name changes from 'phone' to 'phone_number'
-- All queries using the old name will break — update your application code!

-- Another example
ALTER TABLE orders RENAME COLUMN customer_name TO client_name;
ALTER TABLE orders RENAME COLUMN customer_email TO client_email;

-- Renaming does NOT affect data, indexes, or constraints on the column


-- ************************************************************
-- 4. ALTER TABLE — ALTER COLUMN (Change Data Type)
-- ************************************************************

-- Change column type (simple compatible conversion)
ALTER TABLE employees ALTER COLUMN phone_number TYPE VARCHAR(30);

-- Expected: Column width expanded from VARCHAR(20) to VARCHAR(30)
-- Expanding VARCHAR is always safe — no data loss

-- Change column type with explicit conversion (USING clause)
ALTER TABLE products ALTER COLUMN stock_quantity TYPE BIGINT;

-- Change a VARCHAR to INTEGER (requires USING for type cast)
-- Example: if a column stores numeric strings like '42'
ALTER TABLE products ALTER COLUMN weight_kg TYPE NUMERIC(8, 2)
    USING weight_kg::NUMERIC(8, 2);

-- The USING clause tells PostgreSQL HOW to convert existing data
-- Without USING, incompatible type changes will fail

-- WARNING: Changing to a smaller type can cause data loss!
-- ALTER TABLE employees ALTER COLUMN first_name TYPE VARCHAR(5);
-- → ERROR if any existing value exceeds 5 characters


-- ************************************************************
-- 5. ALTER TABLE — SET / DROP DEFAULT
-- ************************************************************

-- Set a new default value
ALTER TABLE employees ALTER COLUMN is_active SET DEFAULT TRUE;

-- Expected: Future INSERTs without specifying is_active will use TRUE
-- Existing rows are NOT changed

-- Set a default with an expression
ALTER TABLE orders ALTER COLUMN order_date SET DEFAULT NOW();

-- Drop (remove) a default value
ALTER TABLE employees ALTER COLUMN employment_type DROP DEFAULT;

-- Expected: Future INSERTs must explicitly provide employment_type,
--           or it will be NULL


-- ************************************************************
-- 6. ALTER TABLE — SET NOT NULL / DROP NOT NULL
-- ************************************************************

-- Make a column required (NOT NULL)
ALTER TABLE employees ALTER COLUMN phone_number SET NOT NULL;

-- Expected: Fails if any existing row has NULL in phone_number!
-- Fix: UPDATE employees SET phone_number = 'N/A' WHERE phone_number IS NULL;
-- Then: ALTER TABLE employees ALTER COLUMN phone_number SET NOT NULL;

-- Remove NOT NULL constraint (make column optional)
ALTER TABLE employees ALTER COLUMN phone_number DROP NOT NULL;

-- Expected: The column now accepts NULL values


-- ************************************************************
-- 7. ALTER TABLE — ADD CONSTRAINT
-- ************************************************************

-- Add a CHECK constraint
ALTER TABLE employees
    ADD CONSTRAINT chk_employees_salary CHECK (salary >= 0);

-- Add a UNIQUE constraint
ALTER TABLE employees
    ADD CONSTRAINT uq_employees_phone UNIQUE (phone_number);

-- Add a FOREIGN KEY constraint
ALTER TABLE orders
    ADD CONSTRAINT fk_orders_department
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
    ON DELETE SET NULL;

-- Oops — orders doesn't have department_id yet! Add the column first:
ALTER TABLE orders ADD COLUMN department_id INTEGER;

ALTER TABLE orders
    ADD CONSTRAINT fk_orders_department
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
    ON DELETE SET NULL;

-- Add a multi-column UNIQUE constraint
-- (e.g., each employee can belong to a department only once)
-- ALTER TABLE employee_assignments
--     ADD CONSTRAINT uq_emp_dept UNIQUE (employee_id, department_id);

-- Add a PRIMARY KEY to an existing table (table must not already have one)
-- ALTER TABLE some_table ADD CONSTRAINT pk_some_table PRIMARY KEY (id);


-- ************************************************************
-- 8. ALTER TABLE — DROP CONSTRAINT
-- ************************************************************

-- Drop a named constraint
ALTER TABLE employees DROP CONSTRAINT chk_employees_salary;

-- Expected: The CHECK constraint is removed; salary can now be negative

-- Drop a constraint only if it exists
ALTER TABLE employees DROP CONSTRAINT IF EXISTS uq_employees_phone;

-- Drop a foreign key constraint
ALTER TABLE orders DROP CONSTRAINT fk_orders_department;

-- To find constraint names, run:
-- SELECT conname, contype FROM pg_constraint
-- WHERE conrelid = 'employees'::regclass;
--
-- contype: 'p' = primary key, 'f' = foreign key,
--          'c' = check, 'u' = unique


-- ************************************************************
-- 9. ALTER TABLE — RENAME TABLE
-- ************************************************************

-- Rename a table
ALTER TABLE orders RENAME TO customer_orders;

-- Expected: The table 'orders' is now 'customer_orders'
-- Foreign keys referencing this table are updated automatically
-- But application queries using the old name will break!

-- Rename it back for consistency
ALTER TABLE customer_orders RENAME TO orders;


-- ************************************************************
-- 10. ALTER TABLE — Real-World Schema Evolution Scenarios
-- ************************************************************

-- ─────────────────────────────────────────────
-- Scenario A: Adding an address to employees
-- ─────────────────────────────────────────────
ALTER TABLE employees
    ADD COLUMN address_line1 VARCHAR(200),
    ADD COLUMN address_line2 VARCHAR(200),
    ADD COLUMN city          VARCHAR(100),
    ADD COLUMN state         VARCHAR(50),
    ADD COLUMN zip_code      VARCHAR(20),
    ADD COLUMN country       VARCHAR(50) DEFAULT 'India';

-- ─────────────────────────────────────────────
-- Scenario B: Splitting full name into parts
-- ─────────────────────────────────────────────
-- Suppose we had a 'full_name' column and want first + last:
-- Step 1: Add new columns
-- ALTER TABLE employees ADD COLUMN first_name VARCHAR(50);
-- ALTER TABLE employees ADD COLUMN last_name VARCHAR(50);
-- Step 2: Migrate data
-- UPDATE employees SET
--     first_name = split_part(full_name, ' ', 1),
--     last_name  = split_part(full_name, ' ', 2);
-- Step 3: Make them NOT NULL
-- ALTER TABLE employees ALTER COLUMN first_name SET NOT NULL;
-- ALTER TABLE employees ALTER COLUMN last_name SET NOT NULL;
-- Step 4: Drop the old column
-- ALTER TABLE employees DROP COLUMN full_name;

-- ─────────────────────────────────────────────
-- Scenario C: Adding soft-delete support
-- ─────────────────────────────────────────────
ALTER TABLE employees ADD COLUMN deleted_at TIMESTAMPTZ;
ALTER TABLE products  ADD COLUMN deleted_at TIMESTAMPTZ;

-- Soft delete: UPDATE employees SET deleted_at = NOW() WHERE employee_id = 5;
-- Query active: SELECT * FROM employees WHERE deleted_at IS NULL;

-- ─────────────────────────────────────────────
-- Scenario D: Adding created/updated timestamps
-- ─────────────────────────────────────────────
ALTER TABLE products ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();

-- Typically paired with a trigger to auto-update on changes:
-- CREATE OR REPLACE FUNCTION update_timestamp()
-- RETURNS TRIGGER AS $$
-- BEGIN
--     NEW.updated_at = NOW();
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;
--
-- CREATE TRIGGER trg_products_updated
--     BEFORE UPDATE ON products
--     FOR EACH ROW
--     EXECUTE FUNCTION update_timestamp();


-- ************************************************************
-- 11. ALTER SCHEMA and ALTER SEQUENCE
-- ************************************************************

-- Rename a schema
ALTER SCHEMA hr RENAME TO human_resources;

-- Rename a sequence
ALTER SEQUENCE employee_id_seq RENAME TO emp_id_seq;

-- Change sequence properties
ALTER SEQUENCE emp_id_seq
    RESTART WITH 2000
    INCREMENT BY 1
    MAXVALUE 9999999;

-- Expected: Next call to nextval('emp_id_seq') returns 2000


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
/*
  1. ADD COLUMN with NOT NULL requires a DEFAULT if the table has existing rows.
  2. DROP COLUMN is permanent — always back up data before dropping columns.
  3. RENAME COLUMN is metadata-only — it's fast but breaks old queries.
  4. Use USING when changing column types to tell PostgreSQL how to convert data.
  5. SET NOT NULL will fail if existing rows contain NULL — clean data first.
  6. Name your constraints (CONSTRAINT chk_...) so they're easy to drop later.
  7. Use IF EXISTS / IF NOT EXISTS in scripts to make them safely re-runnable.
  8. Schema evolution is normal — plan for it with migration scripts.
  9. Soft deletes (deleted_at column) are often better than hard deletes.
 10. Check pg_constraint to find constraint names before dropping them.
*/
