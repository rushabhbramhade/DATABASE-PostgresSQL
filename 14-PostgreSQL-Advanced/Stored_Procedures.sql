-- ============================================================================
-- STORED PROCEDURES AND FUNCTIONS IN POSTGRESQL
-- ============================================================================
-- PostgreSQL supports two types of callable routines:
--
-- ┌────────────────────┬──────────────────────┬────────────────────────────┐
-- │ Feature            │ FUNCTION             │ PROCEDURE                  │
-- ├────────────────────┼──────────────────────┼────────────────────────────┤
-- │ Returns value?     │ ✓ Yes (required)     │ ✗ No (uses OUT params)     │
-- │ Called with         │ SELECT func()        │ CALL proc()                │
-- │ Use in queries?    │ ✓ Yes (SELECT, WHERE)│ ✗ No                       │
-- │ Transaction control│ ✗ No                 │ ✓ Yes (COMMIT/ROLLBACK)    │
-- │ Introduced in      │ All versions         │ PostgreSQL 11+             │
-- └────────────────────┴──────────────────────┴────────────────────────────┘
--
-- Language: PL/pgSQL (PostgreSQL's procedural language) is the most common,
-- but SQL, Python (PL/Python), Perl, etc. are also supported.
--
-- PL/pgSQL Block Structure:
--   [ DECLARE ]            -- Variable declarations
--     variable_name TYPE;
--   BEGIN                  -- Executable statements
--     ...
--   [ EXCEPTION ]          -- Error handling
--     WHEN ... THEN ...
--   END;
-- ============================================================================


-- ============================================================================
-- SAMPLE TABLE SETUP
-- ============================================================================

DROP TABLE IF EXISTS bank_accounts CASCADE;
DROP TABLE IF EXISTS transfer_log CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS employees CASCADE;

CREATE TABLE bank_accounts (
    account_id    SERIAL PRIMARY KEY,
    holder_name   VARCHAR(100) NOT NULL,
    balance       NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    account_type  VARCHAR(20) DEFAULT 'savings',
    is_active     BOOLEAN DEFAULT TRUE,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE transfer_log (
    log_id        SERIAL PRIMARY KEY,
    from_account  INT,
    to_account    INT,
    amount        NUMERIC(12, 2),
    transferred_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
    product_id    SERIAL PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    category      VARCHAR(50),
    price         NUMERIC(10, 2) NOT NULL,
    stock         INT DEFAULT 0,
    is_active     BOOLEAN DEFAULT TRUE
);

CREATE TABLE employees (
    emp_id        SERIAL PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    department    VARCHAR(50),
    salary        NUMERIC(10, 2),
    hire_date     DATE DEFAULT CURRENT_DATE
);

-- Insert sample data
INSERT INTO bank_accounts (holder_name, balance, account_type) VALUES
('Alice Johnson', 15000.00, 'savings'),
('Bob Smith',      8500.00, 'checking'),
('Charlie Brown',  3200.00, 'savings'),
('Diana Prince',  22000.00, 'checking');

INSERT INTO products (name, category, price, stock) VALUES
('Laptop',     'Electronics', 999.99,  50),
('Headphones', 'Electronics', 149.99, 200),
('Desk Chair', 'Furniture',   299.99,  30),
('Monitor',    'Electronics', 449.99,  75),
('Keyboard',   'Electronics',  79.99, 150);

INSERT INTO employees (name, department, salary, hire_date) VALUES
('Alice',   'Engineering', 95000, '2019-03-15'),
('Bob',     'Engineering', 65000, '2022-01-10'),
('Charlie', 'Sales',       72000, '2020-06-20'),
('Diana',   'Marketing',   68000, '2021-08-05'),
('Eve',     'Sales',       58000, '2023-02-14');


-- ============================================================================
-- EXAMPLE 1: Simple Function — Calculate Tax
-- ============================================================================
-- A function that takes a price and tax rate, returns the total with tax.

CREATE OR REPLACE FUNCTION calculate_tax(
    p_price    NUMERIC,                -- IN parameter (default)
    p_tax_rate NUMERIC DEFAULT 0.18    -- Default 18% tax rate
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_tax_amount NUMERIC;
    v_total      NUMERIC;
BEGIN
    v_tax_amount := p_price * p_tax_rate;
    v_total      := p_price + v_tax_amount;

    RETURN ROUND(v_total, 2);
END;
$$;

-- Usage:
SELECT calculate_tax(1000);           -- Uses default 18% → 1180.00
SELECT calculate_tax(1000, 0.10);     -- Uses 10%         → 1100.00

-- Use in a query:
SELECT
    name,
    price,
    calculate_tax(price)       AS price_with_18pct_tax,
    calculate_tax(price, 0.05) AS price_with_5pct_tax
FROM products;

-- Expected Output:
-- ┌────────────┬────────┬──────────────────────┬────────────────────┐
-- │ name       │ price  │ price_with_18pct_tax │ price_with_5pct_tax│
-- ├────────────┼────────┼──────────────────────┼────────────────────┤
-- │ Laptop     │ 999.99 │ 1179.99              │ 1049.99            │
-- │ Headphones │ 149.99 │ 176.99               │ 157.49             │
-- │ Desk Chair │ 299.99 │ 353.99               │ 314.99             │
-- │ Monitor    │ 449.99 │ 530.99               │ 472.49             │
-- │ Keyboard   │  79.99 │  94.39               │  83.99             │
-- └────────────┴────────┴──────────────────────┴────────────────────┘


-- ============================================================================
-- EXAMPLE 2: Function with IF/ELSE — Salary Grade Calculator
-- ============================================================================

CREATE OR REPLACE FUNCTION get_salary_grade(p_salary NUMERIC)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_salary >= 100000 THEN
        RETURN 'A - Executive';
    ELSIF p_salary >= 80000 THEN
        RETURN 'B - Senior';
    ELSIF p_salary >= 60000 THEN
        RETURN 'C - Mid-Level';
    ELSIF p_salary >= 40000 THEN
        RETURN 'D - Junior';
    ELSE
        RETURN 'E - Entry Level';
    END IF;
END;
$$;

-- Usage:
SELECT
    name,
    department,
    salary,
    get_salary_grade(salary) AS grade
FROM employees;

-- Expected Output:
-- ┌─────────┬─────────────┬────────┬────────────────┐
-- │ name    │ department  │ salary │ grade          │
-- ├─────────┼─────────────┼────────┼────────────────┤
-- │ Alice   │ Engineering │ 95000  │ B - Senior     │
-- │ Bob     │ Engineering │ 65000  │ C - Mid-Level  │
-- │ Charlie │ Sales       │ 72000  │ C - Mid-Level  │
-- │ Diana   │ Marketing   │ 68000  │ C - Mid-Level  │
-- │ Eve     │ Sales       │ 58000  │ D - Junior     │
-- └─────────┴─────────────┴────────┴────────────────┘


-- ============================================================================
-- EXAMPLE 3: Function with OUT Parameters
-- ============================================================================
-- OUT parameters let you return multiple values without a composite type.

CREATE OR REPLACE FUNCTION get_department_stats(
    p_department  IN  VARCHAR,
    p_emp_count   OUT INT,
    p_avg_salary  OUT NUMERIC,
    p_max_salary  OUT NUMERIC,
    p_min_salary  OUT NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT
        COUNT(*),
        ROUND(AVG(salary), 2),
        MAX(salary),
        MIN(salary)
    INTO p_emp_count, p_avg_salary, p_max_salary, p_min_salary
    FROM employees
    WHERE department = p_department;

    -- If no employees found
    IF p_emp_count = 0 THEN
        RAISE NOTICE 'No employees found in department: %', p_department;
    END IF;
END;
$$;

-- Usage: OUT parameters are returned as a record
SELECT * FROM get_department_stats('Engineering');

-- Expected Output:
-- ┌─────────────┬────────────┬────────────┬────────────┐
-- │ p_emp_count │ p_avg_salary│ p_max_salary│ p_min_salary│
-- ├─────────────┼────────────┼────────────┼────────────┤
-- │ 2           │ 80000.00   │ 95000      │ 65000      │
-- └─────────────┴────────────┴────────────┴────────────┘

-- Can also use directly in SELECT:
SELECT (get_department_stats('Sales')).*;


-- ============================================================================
-- EXAMPLE 4: SET-RETURNING FUNCTION — RETURNS TABLE
-- ============================================================================
-- Returns multiple rows as if it were a table. Very useful for reusable queries.

CREATE OR REPLACE FUNCTION get_products_by_price_range(
    p_min_price NUMERIC,
    p_max_price NUMERIC
)
RETURNS TABLE (
    product_name  VARCHAR,
    product_price NUMERIC,
    in_stock      BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
        SELECT
            p.name,
            p.price,
            (p.stock > 0) AS in_stock
        FROM products p
        WHERE p.price BETWEEN p_min_price AND p_max_price
          AND p.is_active = TRUE
        ORDER BY p.price;

    -- Check if no rows returned
    IF NOT FOUND THEN
        RAISE NOTICE 'No products found in price range $% to $%',
                      p_min_price, p_max_price;
    END IF;
END;
$$;

-- Usage — just like querying a table:
SELECT * FROM get_products_by_price_range(100, 500);

-- Expected Output:
-- ┌──────────────┬───────────────┬──────────┐
-- │ product_name │ product_price │ in_stock │
-- ├──────────────┼───────────────┼──────────┤
-- │ Headphones   │ 149.99        │ true     │
-- │ Desk Chair   │ 299.99        │ true     │
-- │ Monitor      │ 449.99        │ true     │
-- └──────────────┴───────────────┴──────────┘

-- Can be used in JOINs, subqueries, etc:
SELECT * FROM get_products_by_price_range(50, 200) WHERE in_stock = TRUE;


-- ============================================================================
-- EXAMPLE 5: STORED PROCEDURE — Money Transfer Between Accounts
-- ============================================================================
-- Procedures (PostgreSQL 11+) support COMMIT/ROLLBACK within the body.
-- Called with CALL, not SELECT.

CREATE OR REPLACE PROCEDURE transfer_money(
    p_from_account INT,
    p_to_account   INT,
    p_amount       NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_from_balance NUMERIC;
    v_from_name    VARCHAR;
    v_to_name      VARCHAR;
BEGIN
    -- Validate amount
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Transfer amount must be positive. Got: %', p_amount;
    END IF;

    -- Check if both accounts exist and get details
    SELECT balance, holder_name INTO v_from_balance, v_from_name
    FROM bank_accounts
    WHERE account_id = p_from_account AND is_active = TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Source account % not found or inactive', p_from_account;
    END IF;

    SELECT holder_name INTO v_to_name
    FROM bank_accounts
    WHERE account_id = p_to_account AND is_active = TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Destination account % not found or inactive', p_to_account;
    END IF;

    -- Check sufficient funds
    IF v_from_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient funds. Account % has $%, tried to transfer $%',
                         p_from_account, v_from_balance, p_amount;
    END IF;

    -- Perform the transfer
    UPDATE bank_accounts SET balance = balance - p_amount
    WHERE account_id = p_from_account;

    UPDATE bank_accounts SET balance = balance + p_amount
    WHERE account_id = p_to_account;

    -- Log the transfer
    INSERT INTO transfer_log (from_account, to_account, amount)
    VALUES (p_from_account, p_to_account, p_amount);

    -- Commit is automatic at the end of the procedure call unless
    -- you explicitly call COMMIT; within the body.

    RAISE NOTICE 'Transfer successful: $% from % (Account %) to % (Account %)',
                  p_amount, v_from_name, p_from_account, v_to_name, p_to_account;
END;
$$;

-- Usage:
CALL transfer_money(1, 3, 2000.00);

-- Verify:
SELECT account_id, holder_name, balance FROM bank_accounts ORDER BY account_id;

-- Expected Output (after transfer):
-- ┌────────────┬───────────────┬──────────┐
-- │ account_id │ holder_name   │ balance  │
-- ├────────────┼───────────────┼──────────┤
-- │ 1          │ Alice Johnson │ 13000.00 │  (was 15000, sent 2000)
-- │ 2          │ Bob Smith     │  8500.00 │
-- │ 3          │ Charlie Brown │  5200.00 │  (was 3200, received 2000)
-- │ 4          │ Diana Prince  │ 22000.00 │
-- └────────────┴───────────────┴──────────┘

-- Check the transfer log:
SELECT * FROM transfer_log;

-- Expected Output:
-- ┌────────┬──────────────┬────────────┬─────────┬────────────────────┐
-- │ log_id │ from_account │ to_account │ amount  │ transferred_at     │
-- ├────────┼──────────────┼────────────┼─────────┼────────────────────┤
-- │ 1      │ 1            │ 3          │ 2000.00 │ 2024-xx-xx ...     │
-- └────────┴──────────────┴────────────┴─────────┴────────────────────┘

-- Test error handling (insufficient funds):
-- CALL transfer_money(3, 1, 50000.00);
-- ERROR: Insufficient funds. Account 3 has $5200.00, tried to transfer $50000.00


-- ============================================================================
-- EXAMPLE 6: Procedure with INOUT Parameter
-- ============================================================================
-- INOUT parameters serve as both input and output.

CREATE OR REPLACE PROCEDURE apply_discount(
    INOUT p_price    NUMERIC,
    IN    p_discount NUMERIC DEFAULT 10   -- discount percentage
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_discount < 0 OR p_discount > 100 THEN
        RAISE EXCEPTION 'Discount must be between 0 and 100. Got: %', p_discount;
    END IF;

    p_price := ROUND(p_price * (1 - p_discount / 100.0), 2);
END;
$$;

-- Usage — CALL returns INOUT value:
CALL apply_discount(999.99, 15);   -- 15% off → returns 849.99
CALL apply_discount(500.00);       -- Default 10% off → returns 450.00


-- ============================================================================
-- EXAMPLE 7: Function with LOOP — Generate a Multiplication Table
-- ============================================================================

CREATE OR REPLACE FUNCTION multiplication_table(p_number INT, p_upto INT DEFAULT 10)
RETURNS TABLE (expression TEXT, result INT)
LANGUAGE plpgsql
AS $$
DECLARE
    i INT;
BEGIN
    FOR i IN 1..p_upto LOOP
        expression := p_number || ' x ' || i;
        result     := p_number * i;
        RETURN NEXT;   -- Add current row to the result set
    END LOOP;
END;
$$;

-- Usage:
SELECT * FROM multiplication_table(7, 5);

-- Expected Output:
-- ┌────────────┬────────┐
-- │ expression │ result │
-- ├────────────┼────────┤
-- │ 7 x 1      │ 7      │
-- │ 7 x 2      │ 14     │
-- │ 7 x 3      │ 21     │
-- │ 7 x 4      │ 28     │
-- │ 7 x 5      │ 35     │
-- └────────────┴────────┘


-- ============================================================================
-- EXAMPLE 8: Function with Exception Handling
-- ============================================================================

CREATE OR REPLACE FUNCTION safe_divide(
    p_numerator   NUMERIC,
    p_denominator NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN ROUND(p_numerator / p_denominator, 4);
EXCEPTION
    WHEN division_by_zero THEN
        RAISE NOTICE 'Division by zero attempted: % / %', p_numerator, p_denominator;
        RETURN NULL;
    WHEN numeric_value_out_of_range THEN
        RAISE NOTICE 'Result out of range for: % / %', p_numerator, p_denominator;
        RETURN NULL;
END;
$$;

-- Usage:
SELECT safe_divide(100, 3);    -- Returns: 33.3333
SELECT safe_divide(100, 0);    -- Returns: NULL (with a NOTICE)
SELECT safe_divide(10, 7);     -- Returns: 1.4286


-- ============================================================================
-- EXAMPLE 9: Trigger Function — Returns TRIGGER
-- ============================================================================
-- Trigger functions are special — they RETURN TRIGGER and have access to
-- NEW and OLD records. They are called automatically, not directly.
-- (See Triggers.sql for full trigger examples)

-- This function will be used as a trigger to auto-update a timestamp
CREATE OR REPLACE FUNCTION update_modified_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- Add an updated_at column to products
ALTER TABLE products ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP;

-- Create the trigger (binds the function to a table event)
CREATE OR REPLACE TRIGGER trg_products_updated
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_timestamp();

-- Now any UPDATE on products will auto-set updated_at
UPDATE products SET price = 929.99 WHERE name = 'Laptop';

SELECT name, price, updated_at FROM products WHERE name = 'Laptop';

-- Expected Output:
-- ┌────────┬────────┬────────────────────────────┐
-- │ name   │ price  │ updated_at                 │
-- ├────────┼────────┼────────────────────────────┤
-- │ Laptop │ 929.99 │ 2024-xx-xx xx:xx:xx.xxxxxx │
-- └────────┴────────┴────────────────────────────┘


-- ============================================================================
-- EXAMPLE 10: Pure SQL Function (No PL/pgSQL)
-- ============================================================================
-- For simple calculations, you can use LANGUAGE SQL — it's simpler and
-- can sometimes be inlined by the query planner for better performance.

CREATE OR REPLACE FUNCTION get_full_price(
    p_price    NUMERIC,
    p_tax_rate NUMERIC DEFAULT 0.18
)
RETURNS NUMERIC
LANGUAGE SQL
IMMUTABLE       -- Same input always gives same output (optimization hint)
AS $$
    SELECT ROUND(p_price * (1 + p_tax_rate), 2);
$$;

-- The IMMUTABLE keyword tells PostgreSQL the function has no side effects
-- and depends only on its arguments — allowing caching and index usage.

SELECT name, price, get_full_price(price) AS with_tax FROM products;


-- ============================================================================
-- DROP FUNCTION / DROP PROCEDURE
-- ============================================================================

-- Drop a function (must match parameter types for overloaded functions)
-- DROP FUNCTION IF EXISTS calculate_tax(NUMERIC, NUMERIC);
-- DROP FUNCTION IF EXISTS get_salary_grade(NUMERIC);

-- Drop a procedure
-- DROP PROCEDURE IF EXISTS transfer_money(INT, INT, NUMERIC);

-- Drop with CASCADE — also drops dependent objects (triggers, etc.)
-- DROP FUNCTION IF EXISTS update_modified_timestamp() CASCADE;

-- List all user-defined functions in current schema:
SELECT
    routine_name,
    routine_type,
    data_type AS return_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_type IN ('FUNCTION', 'PROCEDURE')
ORDER BY routine_type, routine_name;


-- ============================================================================
-- SECURITY: DEFINER vs INVOKER
-- ============================================================================

-- SECURITY INVOKER (default):
--   Function runs with the PRIVILEGES of the USER who calls it.
--   The caller must have permission on the underlying tables.

CREATE OR REPLACE FUNCTION get_my_balance(p_account_id INT)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY INVOKER      -- Caller's permissions apply
AS $$
DECLARE
    v_balance NUMERIC;
BEGIN
    SELECT balance INTO v_balance
    FROM bank_accounts
    WHERE account_id = p_account_id;
    RETURN v_balance;
END;
$$;

-- SECURITY DEFINER:
--   Function runs with the PRIVILEGES of the USER who CREATED it.
--   Useful for granting controlled access without giving direct table access.
--   ⚠️ Use carefully — it can be a security risk if not properly written!

CREATE OR REPLACE FUNCTION admin_get_all_balances()
RETURNS TABLE (holder VARCHAR, balance NUMERIC)
LANGUAGE plpgsql
SECURITY DEFINER      -- Creator's (admin) permissions apply
AS $$
BEGIN
    RETURN QUERY
        SELECT holder_name, ba.balance
        FROM bank_accounts ba
        WHERE ba.is_active = TRUE;
END;
$$;

-- A regular user who can execute admin_get_all_balances() can see balances
-- even if they don't have SELECT permission on bank_accounts directly.

-- Grant execute permission to a role:
-- GRANT EXECUTE ON FUNCTION admin_get_all_balances() TO app_readonly;


-- ============================================================================
-- KEY TAKEAWAYS
-- ============================================================================
-- 1. Use FUNCTIONS when you need to return values and use them in queries
--    (SELECT, WHERE, JOIN). Use PROCEDURES for operations (CALL).
--
-- 2. Parameter types: IN (input, default), OUT (output), INOUT (both).
--
-- 3. PL/pgSQL structure: DECLARE → BEGIN → EXCEPTION → END
--
-- 4. RETURNS TABLE creates set-returning functions (like virtual tables).
--
-- 5. RETURNS TRIGGER is for trigger functions — see Triggers.sql.
--
-- 6. Use LANGUAGE SQL for simple, pure calculations — the planner can
--    inline them. Use LANGUAGE plpgsql for procedural logic.
--
-- 7. Mark functions as IMMUTABLE (no side effects, same result for same
--    input) or STABLE (reads DB but doesn't modify it) for optimization.
--
-- 8. SECURITY DEFINER runs with creator's permissions — powerful but
--    use cautiously. Default is SECURITY INVOKER.
--
-- 9. Always use CREATE OR REPLACE to avoid "function already exists" errors
--    during development.
--
-- 10. Use RAISE NOTICE for debugging and RAISE EXCEPTION to abort with
--     an error message.
-- ============================================================================
