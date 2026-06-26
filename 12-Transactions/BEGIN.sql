-- ============================================================
-- BEGIN.sql — Starting Transactions in PostgreSQL
-- ============================================================
-- Topic  : BEGIN, START TRANSACTION, Isolation Levels, SAVEPOINTs
-- Database: PostgreSQL 15+
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- WHAT IS A TRANSACTION?
-- ────────────────────────────────────────────────────────────
-- A transaction is a sequence of one or more SQL statements
-- that are executed as a SINGLE UNIT OF WORK.
--
-- Either ALL statements succeed (COMMIT) or
-- ALL statements are undone  (ROLLBACK).
--
-- Think of it like an ATM withdrawal:
--   1. Check balance
--   2. Deduct amount
--   3. Dispense cash
-- If step 3 fails, step 2 must be reversed — that's a transaction.

-- ────────────────────────────────────────────────────────────
-- SETUP: Sample tables used throughout examples
-- ────────────────────────────────────────────────────────────

DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS audit_log;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS order_items;

CREATE TABLE accounts (
    account_id   SERIAL PRIMARY KEY,
    holder_name  VARCHAR(100) NOT NULL,
    balance      NUMERIC(12, 2) NOT NULL DEFAULT 0.00
);

CREATE TABLE audit_log (
    log_id      SERIAL PRIMARY KEY,
    action      VARCHAR(200) NOT NULL,
    performed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
    product_id   SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    stock        INT NOT NULL DEFAULT 0,
    price        NUMERIC(10, 2) NOT NULL
);

CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    product_id    INT REFERENCES products(product_id),
    quantity      INT NOT NULL,
    total_price   NUMERIC(10, 2) NOT NULL,
    ordered_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO accounts (holder_name, balance) VALUES
    ('Alice', 5000.00),
    ('Bob',   3000.00),
    ('Charlie', 1500.00);

INSERT INTO products (product_name, stock, price) VALUES
    ('Laptop',     10,  75000.00),
    ('Mouse',      50,    500.00),
    ('Keyboard',   30,   1500.00),
    ('Monitor',    15,  20000.00);


-- ============================================================
-- 1. IMPLICIT TRANSACTIONS (AUTOCOMMIT MODE)
-- ============================================================
-- By default, PostgreSQL runs in AUTOCOMMIT mode.
-- Every individual statement is wrapped in its own transaction
-- and committed automatically if it succeeds.

-- This UPDATE is auto-committed immediately — no BEGIN needed
UPDATE accounts SET balance = balance + 100 WHERE holder_name = 'Alice';

-- Expected: Alice's balance is now 5100.00, permanently saved.
-- You CANNOT undo this without another UPDATE.

SELECT holder_name, balance FROM accounts WHERE holder_name = 'Alice';
-- Output:
-- | holder_name | balance |
-- |-------------|---------|
-- | Alice       | 5100.00 |


-- ============================================================
-- 2. EXPLICIT TRANSACTION WITH BEGIN
-- ============================================================
-- Use BEGIN (or START TRANSACTION) to start a transaction block.
-- Changes are NOT permanent until you issue COMMIT.

-- Syntax:
--   BEGIN;
--   -- or --
--   START TRANSACTION;
--   ... SQL statements ...
--   COMMIT;   -- make permanent
--   -- or --
--   ROLLBACK; -- discard everything

BEGIN;
    UPDATE accounts SET balance = balance - 500 WHERE holder_name = 'Alice';
    UPDATE accounts SET balance = balance + 500 WHERE holder_name = 'Bob';
COMMIT;

-- Both updates happen together or not at all.
-- Expected after COMMIT:
-- | holder_name | balance |
-- |-------------|---------|
-- | Alice       | 4600.00 |
-- | Bob         | 3500.00 |

SELECT holder_name, balance FROM accounts ORDER BY account_id;


-- ============================================================
-- 3. START TRANSACTION (SQL-standard alternative)
-- ============================================================
-- START TRANSACTION is the SQL-standard syntax and behaves
-- exactly the same as BEGIN in PostgreSQL.

START TRANSACTION;
    INSERT INTO audit_log (action) VALUES ('Monthly interest credited');
    UPDATE accounts SET balance = balance * 1.01;  -- 1% interest
COMMIT;

-- Expected: All account balances increased by 1%, audit log entry created.
SELECT holder_name, balance FROM accounts ORDER BY account_id;
-- | holder_name | balance |
-- |-------------|---------|
-- | Alice       | 4646.00 |
-- | Bob         | 3535.00 |
-- | Charlie     | 1515.00 |


-- ============================================================
-- 4. TRANSACTION ISOLATION LEVELS
-- ============================================================
-- Isolation levels control what a transaction can "see" from
-- other concurrent transactions.
--
-- PostgreSQL supports three isolation levels:
-- ┌──────────────────┬──────────────┬──────────────────┬─────────────────┐
-- │ Isolation Level  │ Dirty Read   │ Non-Repeatable   │ Phantom Read    │
-- │                  │              │ Read             │                 │
-- ├──────────────────┼──────────────┼──────────────────┼─────────────────┤
-- │ READ COMMITTED   │ Not possible │ Possible         │ Possible        │
-- │ (default)        │              │                  │                 │
-- ├──────────────────┼──────────────┼──────────────────┼─────────────────┤
-- │ REPEATABLE READ  │ Not possible │ Not possible     │ Not possible *  │
-- │                  │              │                  │ (serialization  │
-- │                  │              │                  │  error instead) │
-- ├──────────────────┼──────────────┼──────────────────┼─────────────────┤
-- │ SERIALIZABLE     │ Not possible │ Not possible     │ Not possible    │
-- │                  │              │                  │ (strictest)     │
-- └──────────────────┴──────────────┴──────────────────┴─────────────────┘
--
-- Note: PostgreSQL does NOT implement READ UNCOMMITTED.
--       If you set it, it behaves as READ COMMITTED.

-- (a) READ COMMITTED (default) — each statement sees only
--     data committed before the statement (not the transaction) began.

BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
    SELECT balance FROM accounts WHERE holder_name = 'Alice';
    -- If another session commits a change to Alice's balance
    -- between these two SELECTs, the second SELECT will see it.
    SELECT balance FROM accounts WHERE holder_name = 'Alice';
COMMIT;


-- (b) REPEATABLE READ — the transaction sees a snapshot
--     taken at the start of the FIRST query in the transaction.

BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    SELECT balance FROM accounts WHERE holder_name = 'Alice';
    -- Even if another session commits a change to Alice's balance,
    -- this SELECT still sees the SAME value as the first one.
    SELECT balance FROM accounts WHERE holder_name = 'Alice';
COMMIT;


-- (c) SERIALIZABLE — strictest level.
--     Transactions behave AS IF they ran one after another.
--     PostgreSQL may throw a serialization error if conflicts occur.

BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    SELECT SUM(balance) FROM accounts;
    -- Any conflicting concurrent write will cause one transaction
    -- to fail with: ERROR: could not serialize access
COMMIT;


-- ============================================================
-- 5. BEGIN WITH ISOLATION LEVEL AND READ-ONLY
-- ============================================================
-- You can combine isolation level with READ ONLY / READ WRITE
-- and DEFERRABLE options.

-- Read-only transaction: prevents accidental writes in reporting queries
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY;
    SELECT holder_name, balance FROM accounts ORDER BY balance DESC;
    -- INSERT/UPDATE/DELETE would raise an error here
COMMIT;

-- Alternative syntax using SET TRANSACTION inside the block
BEGIN;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    SET TRANSACTION READ ONLY;
    SELECT holder_name, balance FROM accounts;
COMMIT;

-- DEFERRABLE: only meaningful with SERIALIZABLE + READ ONLY.
-- The transaction may block briefly to guarantee no serialization errors.
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE READ ONLY DEFERRABLE;
    SELECT COUNT(*), SUM(balance) FROM accounts;
COMMIT;


-- ============================================================
-- 6. SAVEPOINTs WITHIN TRANSACTIONS
-- ============================================================
-- SAVEPOINTs allow you to set intermediate markers within a
-- transaction. You can ROLLBACK TO a savepoint without
-- discarding the entire transaction.
--
-- Syntax:
--   SAVEPOINT savepoint_name;
--   ROLLBACK TO SAVEPOINT savepoint_name;
--   RELEASE SAVEPOINT savepoint_name;  -- optional cleanup

BEGIN;
    -- Step 1: Deduct from Alice
    UPDATE accounts SET balance = balance - 1000 WHERE holder_name = 'Alice';

    SAVEPOINT after_debit;

    -- Step 2: Try to credit an account that might fail
    UPDATE accounts SET balance = balance + 1000 WHERE holder_name = 'Bob';

    -- Suppose we realize Bob's account is frozen — rollback only step 2
    ROLLBACK TO SAVEPOINT after_debit;

    -- Step 3: Credit Charlie instead
    UPDATE accounts SET balance = balance + 1000 WHERE holder_name = 'Charlie';

COMMIT;

-- Result: Alice was debited 1000, Charlie was credited 1000.
-- Bob's balance is UNCHANGED because we rolled back to the savepoint.

SELECT holder_name, balance FROM accounts ORDER BY account_id;
-- Expected (approximate, depends on prior examples):
-- | holder_name | balance |
-- |-------------|---------|
-- | Alice       | 3646.00 |
-- | Bob         | 3535.00 |
-- | Charlie     | 2515.00 |


-- ============================================================
-- 7. NESTED SAVEPOINTs — Multi-step Order Processing
-- ============================================================
-- SAVEPOINTs can be nested. Each one creates a new rollback marker.

BEGIN;
    -- Step A: Place order for Laptop (product_id = 1)
    SAVEPOINT order_start;

    UPDATE products SET stock = stock - 1 WHERE product_id = 1 AND stock >= 1;
    INSERT INTO order_items (product_id, quantity, total_price)
        VALUES (1, 1, 75000.00);

    SAVEPOINT laptop_ordered;

    -- Step B: Also order 2 Monitors (product_id = 4)
    UPDATE products SET stock = stock - 2 WHERE product_id = 4 AND stock >= 2;
    INSERT INTO order_items (product_id, quantity, total_price)
        VALUES (4, 2, 40000.00);

    SAVEPOINT monitor_ordered;

    -- Step C: Try to order 100 Mice — but only 50 in stock!
    -- We detect insufficient stock and rollback just this part
    ROLLBACK TO SAVEPOINT monitor_ordered;

    -- Steps A and B are still intact
    INSERT INTO audit_log (action)
        VALUES ('Order placed: 1 Laptop + 2 Monitors (Mice skipped — stock low)');

COMMIT;

-- Expected: Laptop stock 9, Monitor stock 13, Mouse stock unchanged at 50
SELECT product_name, stock FROM products ORDER BY product_id;
-- | product_name | stock |
-- |--------------|-------|
-- | Laptop       |     9 |
-- | Mouse        |    50 |
-- | Keyboard     |    30 |
-- | Monitor      |    13 |


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. PostgreSQL runs in AUTOCOMMIT mode by default — each statement
--    is its own transaction unless you explicitly use BEGIN.
--
-- 2. BEGIN (or START TRANSACTION) opens a transaction block.
--    Nothing is permanent until COMMIT.
--
-- 3. There are three usable isolation levels in PostgreSQL:
--    READ COMMITTED (default), REPEATABLE READ, and SERIALIZABLE.
--
-- 4. SAVEPOINTs let you create rollback markers inside a transaction
--    so you can undo part of the work without losing everything.
--
-- 5. Use READ ONLY transactions for reports to prevent accidental writes.
--
-- 6. DEFERRABLE only matters for SERIALIZABLE + READ ONLY transactions
--    (it trades startup latency for guaranteed no serialization errors).
--
-- 7. Always pair BEGIN with either COMMIT or ROLLBACK. Leaving a
--    transaction open locks resources and blocks other sessions.
