-- ============================================================================
-- DATABASE TRIGGERS IN POSTGRESQL
-- ============================================================================
-- A trigger is a function that is AUTOMATICALLY executed in response to
-- certain events (INSERT, UPDATE, DELETE, TRUNCATE) on a table or view.
--
-- Triggers are powerful for:
--   • Audit logging (who changed what and when)
--   • Auto-updating timestamps (updated_at columns)
--   • Enforcing complex business rules
--   • Maintaining derived/computed columns
--   • Preventing unauthorized deletions
--   • Cascading changes across tables
--
-- Trigger Classification:
-- ┌──────────────────────┬────────────────────────────────────────────────┐
-- │ BEFORE vs AFTER      │                                                │
-- ├──────────────────────┼────────────────────────────────────────────────┤
-- │ BEFORE               │ Fires BEFORE the operation. Can MODIFY the    │
-- │                      │ new row (NEW) or CANCEL the operation by      │
-- │                      │ returning NULL.                                │
-- │ AFTER                │ Fires AFTER the operation. Row is already     │
-- │                      │ committed. Good for logging and notifications. │
-- ├──────────────────────┼────────────────────────────────────────────────┤
-- │ ROW vs STATEMENT     │                                                │
-- ├──────────────────────┼────────────────────────────────────────────────┤
-- │ FOR EACH ROW         │ Fires once PER ROW affected. Has access to    │
-- │                      │ NEW and OLD records.                           │
-- │ FOR EACH STATEMENT   │ Fires once PER STATEMENT regardless of how    │
-- │                      │ many rows are affected. No NEW/OLD access.    │
-- └──────────────────────┴────────────────────────────────────────────────┘
--
-- NEW and OLD References:
-- ┌───────────────┬──────────────────┬──────────────────┐
-- │ Operation     │ OLD              │ NEW              │
-- ├───────────────┼──────────────────┼──────────────────┤
-- │ INSERT        │ Not available    │ ✓ New row data   │
-- │ UPDATE        │ ✓ Before values  │ ✓ After values   │
-- │ DELETE        │ ✓ Deleted row    │ Not available    │
-- └───────────────┴──────────────────┴──────────────────┘
-- ============================================================================


-- ============================================================================
-- SAMPLE TABLE SETUP
-- ============================================================================

DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;

CREATE TABLE employees (
    emp_id       SERIAL PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    department   VARCHAR(50),
    salary       NUMERIC(10, 2) NOT NULL,
    email        VARCHAR(100),
    is_active    BOOLEAN DEFAULT TRUE,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders (
    order_id     SERIAL PRIMARY KEY,
    customer     VARCHAR(100) NOT NULL,
    product      VARCHAR(100),
    quantity     INT NOT NULL CHECK (quantity > 0),
    unit_price   NUMERIC(10, 2) NOT NULL,
    total_price  NUMERIC(12, 2),      -- auto-calculated by trigger
    status       VARCHAR(20) DEFAULT 'pending',
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE inventory (
    item_id      SERIAL PRIMARY KEY,
    product_name VARCHAR(100) UNIQUE NOT NULL,
    stock        INT NOT NULL DEFAULT 0,
    reorder_level INT DEFAULT 10,
    last_restocked TIMESTAMP
);

-- Audit log to track ALL changes across tables
CREATE TABLE audit_log (
    log_id        SERIAL PRIMARY KEY,
    table_name    VARCHAR(50) NOT NULL,
    operation     VARCHAR(10) NOT NULL,   -- INSERT, UPDATE, DELETE
    record_id     INT,
    old_data      JSONB,
    new_data      JSONB,
    changed_by    VARCHAR(50) DEFAULT CURRENT_USER,
    changed_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO employees (name, department, salary, email) VALUES
('Alice Johnson',  'Engineering', 95000, 'alice@company.com'),
('Bob Smith',      'Marketing',   68000, 'bob@company.com'),
('Charlie Brown',  'Engineering', 82000, 'charlie@company.com'),
('Diana Prince',   'Sales',       75000, 'diana@company.com'),
('Eve Williams',   'HR',          70000, 'eve@company.com');

INSERT INTO inventory (product_name, stock, reorder_level) VALUES
('Laptop',     50, 10),
('Headphones', 200, 25),
('Monitor',    30, 5),
('Keyboard',   150, 20);


-- ============================================================================
-- EXAMPLE 1: Auto-Update Timestamp Trigger (updated_at)
-- ============================================================================
-- One of the most common triggers — automatically sets updated_at to NOW()
-- whenever a row is modified.

-- Step 1: Create the trigger function
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;   -- Must return NEW for BEFORE triggers
END;
$$;

-- Step 2: Attach the trigger to the employees table
CREATE OR REPLACE TRIGGER trg_employees_updated_at
    BEFORE UPDATE ON employees
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

-- Step 3: Attach the same trigger function to orders table (reusable!)
CREATE OR REPLACE TRIGGER trg_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

-- Test it:
UPDATE employees SET salary = 98000 WHERE name = 'Alice Johnson';

SELECT name, salary, created_at, updated_at
FROM employees
WHERE name = 'Alice Johnson';

-- Expected Output:
-- ┌───────────────┬────────┬─────────────────────┬─────────────────────┐
-- │ name          │ salary │ created_at           │ updated_at          │
-- ├───────────────┼────────┼─────────────────────┼─────────────────────┤
-- │ Alice Johnson │ 98000  │ 2024-xx-xx (orig)   │ 2024-xx-xx (NOW!)   │
-- └───────────────┴────────┴─────────────────────┴─────────────────────┘
-- Notice: created_at stays the same, updated_at changed to current time.


-- ============================================================================
-- EXAMPLE 2: Comprehensive Audit Log Trigger
-- ============================================================================
-- Tracks every INSERT, UPDATE, and DELETE with full before/after data.

CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, operation, record_id, new_data)
        VALUES (TG_TABLE_NAME, 'INSERT', NEW.emp_id, to_jsonb(NEW));
        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, operation, record_id, old_data, new_data)
        VALUES (TG_TABLE_NAME, 'UPDATE', NEW.emp_id, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (table_name, operation, record_id, old_data)
        VALUES (TG_TABLE_NAME, 'DELETE', OLD.emp_id, to_jsonb(OLD));
        RETURN OLD;
    END IF;
END;
$$;

-- Attach to employees table — fires on all three operations
CREATE OR REPLACE TRIGGER trg_employees_audit
    AFTER INSERT OR UPDATE OR DELETE ON employees
    FOR EACH ROW
    EXECUTE FUNCTION audit_trigger_func();

-- Trigger variables available inside the function:
-- TG_TABLE_NAME  — name of the table that caused the trigger
-- TG_OP          — operation: 'INSERT', 'UPDATE', or 'DELETE'
-- TG_WHEN        — timing: 'BEFORE' or 'AFTER'
-- TG_LEVEL       — level: 'ROW' or 'STATEMENT'

-- Test: Update a salary (triggers both audit AND updated_at triggers)
UPDATE employees SET salary = 90000, department = 'Sales'
WHERE name = 'Bob Smith';

-- Test: Insert a new employee
INSERT INTO employees (name, department, salary, email)
VALUES ('Frank Miller', 'Engineering', 72000, 'frank@company.com');

-- Test: Delete an employee
DELETE FROM employees WHERE name = 'Frank Miller';

-- View the audit log:
SELECT
    log_id,
    table_name,
    operation,
    record_id,
    old_data ->> 'salary' AS old_salary,
    new_data ->> 'salary' AS new_salary,
    changed_by,
    changed_at
FROM audit_log
ORDER BY log_id;

-- Expected Output:
-- ┌────────┬────────────┬───────────┬───────────┬────────────┬────────────┬────────────┐
-- │ log_id │ table_name │ operation │ record_id │ old_salary │ new_salary │ changed_by │
-- ├────────┼────────────┼───────────┼───────────┼────────────┼────────────┼────────────┤
-- │ 1      │ employees  │ UPDATE    │ 2         │ 68000.00   │ 90000.00   │ postgres   │
-- │ 2      │ employees  │ INSERT    │ 6         │ NULL       │ 72000.00   │ postgres   │
-- │ 3      │ employees  │ DELETE    │ 6         │ 72000.00   │ NULL       │ postgres   │
-- └────────┴────────────┴───────────┴───────────┴────────────┴────────────┴────────────┘


-- ============================================================================
-- EXAMPLE 3: Prevent Deletion Trigger
-- ============================================================================
-- Prevents deleting employees — soft-deletes by setting is_active = FALSE instead.

CREATE OR REPLACE FUNCTION prevent_employee_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Instead of deleting, mark as inactive
    UPDATE employees
    SET is_active = FALSE, updated_at = CURRENT_TIMESTAMP
    WHERE emp_id = OLD.emp_id;

    RAISE NOTICE 'Employee "%" (ID: %) was deactivated instead of deleted.',
                  OLD.name, OLD.emp_id;

    -- Return NULL to CANCEL the original DELETE operation
    RETURN NULL;
END;
$$;

CREATE OR REPLACE TRIGGER trg_prevent_employee_delete
    BEFORE DELETE ON employees
    FOR EACH ROW
    EXECUTE FUNCTION prevent_employee_delete();

-- Test: Try to delete an employee
DELETE FROM employees WHERE name = 'Eve Williams';

-- The row is NOT deleted — it's just deactivated:
SELECT name, is_active FROM employees WHERE name = 'Eve Williams';

-- Expected Output:
-- ┌───────────────┬───────────┐
-- │ name          │ is_active │
-- ├───────────────┼───────────┤
-- │ Eve Williams  │ false     │
-- └───────────────┴───────────┘
-- NOTICE: Employee "Eve Williams" (ID: 5) was deactivated instead of deleted.

-- NOTE: Since this BEFORE trigger returns NULL, the DELETE is cancelled and
-- the AFTER audit trigger for DELETE will NOT fire.


-- ============================================================================
-- EXAMPLE 4: Auto-Calculate Total Price on Orders
-- ============================================================================
-- Automatically computes total_price = quantity × unit_price on INSERT/UPDATE.

CREATE OR REPLACE FUNCTION calculate_order_total()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.total_price := NEW.quantity * NEW.unit_price;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_order_total
    BEFORE INSERT OR UPDATE OF quantity, unit_price ON orders
    FOR EACH ROW
    EXECUTE FUNCTION calculate_order_total();

-- Note: "UPDATE OF quantity, unit_price" means this trigger only fires
-- when those specific columns are modified — not on every UPDATE.

-- Test: Insert orders (total_price is auto-calculated)
INSERT INTO orders (customer, product, quantity, unit_price) VALUES
('John Doe',    'Laptop',     2, 999.99),
('Jane Smith',  'Headphones', 5, 149.99),
('Mike Johnson', 'Monitor',   1, 449.99);

SELECT order_id, customer, product, quantity, unit_price, total_price
FROM orders;

-- Expected Output:
-- ┌──────────┬──────────────┬────────────┬──────────┬────────────┬─────────────┐
-- │ order_id │ customer     │ product    │ quantity │ unit_price │ total_price │
-- ├──────────┼──────────────┼────────────┼──────────┼────────────┼─────────────┤
-- │ 1        │ John Doe     │ Laptop     │ 2        │ 999.99     │ 1999.98     │
-- │ 2        │ Jane Smith   │ Headphones │ 5        │ 149.99     │ 749.95      │
-- │ 3        │ Mike Johnson │ Monitor    │ 1        │ 449.99     │ 449.99      │
-- └──────────┴──────────────┴────────────┴──────────┴────────────┴─────────────┘

-- Update quantity — total auto-recalculates:
UPDATE orders SET quantity = 3 WHERE order_id = 1;

SELECT order_id, quantity, unit_price, total_price FROM orders WHERE order_id = 1;

-- Expected Output:
-- ┌──────────┬──────────┬────────────┬─────────────┐
-- │ order_id │ quantity │ unit_price │ total_price │
-- ├──────────┼──────────┼────────────┼─────────────┤
-- │ 1        │ 3        │ 999.99     │ 2999.97     │
-- └──────────┴──────────┴────────────┴─────────────┘


-- ============================================================================
-- EXAMPLE 5: Inventory Stock Alert Trigger
-- ============================================================================
-- Raises a warning when stock falls below the reorder level.

CREATE OR REPLACE FUNCTION check_stock_level()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.stock < NEW.reorder_level THEN
        RAISE WARNING '⚠️ LOW STOCK ALERT: "%" has only % units left (reorder level: %). '
                      'Please reorder!',
                      NEW.product_name, NEW.stock, NEW.reorder_level;
    END IF;

    IF NEW.stock = 0 THEN
        RAISE WARNING '🚨 OUT OF STOCK: "%" is completely out of stock!',
                      NEW.product_name;
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_stock_alert
    AFTER UPDATE OF stock ON inventory
    FOR EACH ROW
    EXECUTE FUNCTION check_stock_level();

-- Test: Reduce stock below reorder level
UPDATE inventory SET stock = 8 WHERE product_name = 'Laptop';
-- WARNING:  ⚠️ LOW STOCK ALERT: "Laptop" has only 8 units left (reorder level: 10). Please reorder!

UPDATE inventory SET stock = 0 WHERE product_name = 'Monitor';
-- WARNING:  ⚠️ LOW STOCK ALERT: "Monitor" has only 0 units left (reorder level: 5). Please reorder!
-- WARNING:  🚨 OUT OF STOCK: "Monitor" is completely out of stock!


-- ============================================================================
-- EXAMPLE 6: Email Validation Trigger
-- ============================================================================
-- Validates email format and normalizes it to lowercase before INSERT/UPDATE.

CREATE OR REPLACE FUNCTION validate_employee_email()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Normalize email to lowercase
    NEW.email := LOWER(TRIM(NEW.email));

    -- Basic email validation
    IF NEW.email IS NOT NULL AND NEW.email !~ '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' THEN
        RAISE EXCEPTION 'Invalid email address: "%". Email must be in format user@domain.com',
                         NEW.email;
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_validate_email
    BEFORE INSERT OR UPDATE OF email ON employees
    FOR EACH ROW
    EXECUTE FUNCTION validate_employee_email();

-- Test: Valid email (gets lowercased)
UPDATE employees SET email = 'ALICE.J@Company.COM' WHERE name = 'Alice Johnson';

SELECT name, email FROM employees WHERE name = 'Alice Johnson';
-- Expected: email = 'alice.j@company.com' (lowercased)

-- Test: Invalid email (raises error)
-- UPDATE employees SET email = 'not-an-email' WHERE name = 'Alice Johnson';
-- ERROR: Invalid email address: "not-an-email". Email must be in format user@domain.com


-- ============================================================================
-- EXAMPLE 7: STATEMENT-Level Trigger — Log Bulk Operations
-- ============================================================================
-- A statement-level trigger fires ONCE per SQL statement, regardless of
-- how many rows are affected. Useful for logging operations.

CREATE OR REPLACE FUNCTION log_bulk_operation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE '[%] % operation completed on table "%" by user "%"',
                  CURRENT_TIMESTAMP, TG_OP, TG_TABLE_NAME, CURRENT_USER;
    RETURN NULL;  -- Statement-level triggers ignore return value
END;
$$;

CREATE OR REPLACE TRIGGER trg_orders_statement_log
    AFTER INSERT OR UPDATE OR DELETE ON orders
    FOR EACH STATEMENT
    EXECUTE FUNCTION log_bulk_operation();

-- Test: This fires ONCE even though multiple rows are inserted
INSERT INTO orders (customer, product, quantity, unit_price) VALUES
('Customer A', 'Keyboard', 10, 79.99),
('Customer B', 'Keyboard', 5,  79.99);

-- NOTICE: [2024-xx-xx] INSERT operation completed on table "orders" by user "postgres"
-- (Only ONE notice, not two — because it's STATEMENT level)


-- ============================================================================
-- EXAMPLE 8: Conditional Trigger with WHEN Clause
-- ============================================================================
-- The WHEN clause adds a condition — the trigger only fires if it's true.
-- This is more efficient than checking inside the trigger function body.

CREATE OR REPLACE FUNCTION log_salary_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_change    NUMERIC;
    v_pct_change NUMERIC;
BEGIN
    v_change     := NEW.salary - OLD.salary;
    v_pct_change := ROUND((v_change / OLD.salary) * 100, 1);

    RAISE NOTICE 'Salary change for %: $% → $% (% by $%, %)',
                  NEW.name, OLD.salary, NEW.salary,
                  CASE WHEN v_change > 0 THEN 'increased' ELSE 'decreased' END,
                  ABS(v_change),
                  v_pct_change || '%';

    -- Prevent salary decreases of more than 20%
    IF v_pct_change < -20 THEN
        RAISE EXCEPTION 'Salary decrease of % exceeds maximum allowed 20%% reduction for employee %.',
                         v_pct_change || '%', NEW.name;
    END IF;

    RETURN NEW;
END;
$$;

-- Trigger fires ONLY when salary actually changes
CREATE OR REPLACE TRIGGER trg_salary_change
    BEFORE UPDATE ON employees
    FOR EACH ROW
    WHEN (OLD.salary IS DISTINCT FROM NEW.salary)    -- ← Conditional!
    EXECUTE FUNCTION log_salary_change();

-- Test: Change salary (trigger fires)
UPDATE employees SET salary = 100000 WHERE name = 'Charlie Brown';
-- NOTICE: Salary change for Charlie Brown: $82000 → $100000 (increased by $18000, 22.0%)

-- Test: Change department only — trigger does NOT fire (salary unchanged)
UPDATE employees SET department = 'DevOps' WHERE name = 'Charlie Brown';
-- (No notice — the WHEN condition prevents firing)

-- Test: Excessive salary decrease
-- UPDATE employees SET salary = 50000 WHERE name = 'Charlie Brown';
-- ERROR: Salary decrease of -50.0% exceeds maximum allowed 20% reduction


-- ============================================================================
-- DROPPING TRIGGERS
-- ============================================================================

-- Drop a specific trigger from a table
-- DROP TRIGGER IF EXISTS trg_employees_updated_at ON employees;

-- Drop the trigger function (CASCADE also drops dependent triggers)
-- DROP FUNCTION IF EXISTS set_updated_at() CASCADE;

-- List all triggers on a specific table:
SELECT
    trigger_name,
    event_manipulation AS event,
    action_timing AS timing,
    action_orientation AS level
FROM information_schema.triggers
WHERE event_object_table = 'employees'
ORDER BY trigger_name;

-- Expected Output:
-- ┌─────────────────────────────┬────────┬────────┬───────────┐
-- │ trigger_name                │ event  │ timing │ level     │
-- ├─────────────────────────────┼────────┼────────┼───────────┤
-- │ trg_employees_audit         │ INSERT │ AFTER  │ ROW       │
-- │ trg_employees_audit         │ UPDATE │ AFTER  │ ROW       │
-- │ trg_employees_audit         │ DELETE │ AFTER  │ ROW       │
-- │ trg_employees_updated_at    │ UPDATE │ BEFORE │ ROW       │
-- │ trg_prevent_employee_delete │ DELETE │ BEFORE │ ROW       │
-- │ trg_salary_change           │ UPDATE │ BEFORE │ ROW       │
-- │ trg_validate_email          │ INSERT │ BEFORE │ ROW       │
-- │ trg_validate_email          │ UPDATE │ BEFORE │ ROW       │
-- └─────────────────────────────┴────────┴────────┴───────────┘

-- List all triggers across all tables in the current schema:
SELECT
    event_object_table AS table_name,
    trigger_name,
    event_manipulation AS event,
    action_timing AS timing
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;


-- ============================================================================
-- KEY TAKEAWAYS
-- ============================================================================
-- 1. Triggers execute AUTOMATICALLY — no manual invocation needed.
--    They respond to INSERT, UPDATE, DELETE (and TRUNCATE for statement-level).
--
-- 2. Trigger functions must:
--    - RETURN TRIGGER
--    - Use LANGUAGE plpgsql
--    - Return NEW (for BEFORE INSERT/UPDATE), OLD (for BEFORE DELETE),
--      or NULL (to cancel the operation)
--
-- 3. BEFORE triggers can MODIFY data (change NEW values) or CANCEL operations
--    (return NULL). AFTER triggers can only observe and react.
--
-- 4. ROW-level triggers fire per row and have access to NEW/OLD.
--    STATEMENT-level triggers fire once per statement — no NEW/OLD access.
--
-- 5. The WHEN clause is more efficient than checking conditions inside
--    the function body — PostgreSQL skips the function call entirely.
--
-- 6. Trigger functions are reusable — one function can be attached to
--    multiple tables (e.g., set_updated_at on employees AND orders).
--
-- 7. Trigger execution order: BEFORE triggers → actual operation → AFTER
--    triggers. Multiple triggers on the same event fire alphabetically.
--
-- 8. Common use cases:
--    - Audit trails (who changed what, when)
--    - Auto-updating timestamps (updated_at)
--    - Data validation and normalization
--    - Computed/derived columns
--    - Soft deletes (prevent deletion, set is_active = false)
--    - Inventory alerts and business rules
--
-- 9. ⚠️ Be careful with trigger cascades — a trigger that modifies another
--    table can fire triggers on that table, causing unexpected chains.
-- ============================================================================
