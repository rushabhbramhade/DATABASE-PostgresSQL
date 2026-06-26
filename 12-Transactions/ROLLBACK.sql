-- ============================================================
-- ROLLBACK.sql — Rolling Back Transactions in PostgreSQL
-- ============================================================
-- Topic  : ROLLBACK, ROLLBACK TO SAVEPOINT, Error Handling
-- Database: PostgreSQL 15+
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- WHAT DOES ROLLBACK DO?
-- ────────────────────────────────────────────────────────────
-- ROLLBACK discards ALL changes made since the last BEGIN.
-- The database is restored to its state BEFORE the transaction.
--
-- Think of it as the "UNDO" button for your entire transaction.
--
-- When to use ROLLBACK:
--   • An error occurs during the transaction
--   • A business rule check fails (insufficient funds, etc.)
--   • You want to discard exploratory changes (testing queries)
--   • An external service call fails and you need to revert DB changes
--
-- Syntax:
--   ROLLBACK;
--   -- or --
--   ROLLBACK WORK;         -- SQL-standard form
--   -- or --
--   ABORT;                 -- PostgreSQL alias for ROLLBACK
--
-- Partial rollback:
--   ROLLBACK TO SAVEPOINT savepoint_name;

-- ────────────────────────────────────────────────────────────
-- SETUP: Sample tables used throughout examples
-- ────────────────────────────────────────────────────────────

DROP TABLE IF EXISTS transfer_log;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS inventory;
DROP TABLE IF EXISTS order_items;

CREATE TABLE accounts (
    account_id  SERIAL PRIMARY KEY,
    holder_name VARCHAR(100) NOT NULL,
    balance     NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    is_active   BOOLEAN DEFAULT TRUE
);

CREATE TABLE transfer_log (
    log_id        SERIAL PRIMARY KEY,
    from_account  INT NOT NULL,
    to_account    INT NOT NULL,
    amount        NUMERIC(12, 2) NOT NULL,
    transferred_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status        VARCHAR(20) DEFAULT 'SUCCESS'
);

CREATE TABLE inventory (
    item_id    SERIAL PRIMARY KEY,
    item_name  VARCHAR(100) NOT NULL,
    quantity   INT NOT NULL CHECK (quantity >= 0),  -- Cannot go negative
    price      NUMERIC(10, 2) NOT NULL
);

CREATE TABLE order_items (
    order_id   SERIAL PRIMARY KEY,
    item_id    INT REFERENCES inventory(item_id),
    qty        INT NOT NULL,
    total      NUMERIC(10, 2) NOT NULL,
    ordered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO accounts (holder_name, balance, is_active) VALUES
    ('Alice',   50000.00, TRUE),
    ('Bob',     30000.00, TRUE),
    ('Charlie', 15000.00, TRUE),
    ('Diana',    2000.00, FALSE);  -- Inactive/frozen account

INSERT INTO inventory (item_name, quantity, price) VALUES
    ('Laptop',    10,  75000.00),
    ('Mouse',     50,    500.00),
    ('Keyboard',   3,   1500.00),
    ('Headphones', 0,   2000.00);  -- Out of stock


-- ============================================================
-- EXAMPLE 1: Basic ROLLBACK — Discard All Changes
-- ============================================================

-- Check balance before
SELECT holder_name, balance FROM accounts WHERE holder_name = 'Alice';
-- | holder_name | balance  |
-- |-------------|----------|
-- | Alice       | 50000.00 |

BEGIN;
    UPDATE accounts SET balance = 0 WHERE holder_name = 'Alice';
    -- Alice's balance is 0 inside this transaction
    SELECT balance FROM accounts WHERE holder_name = 'Alice';
    -- | balance |
    -- |---------|
    -- | 0.00    |
ROLLBACK;

-- After ROLLBACK, Alice's balance is restored
SELECT holder_name, balance FROM accounts WHERE holder_name = 'Alice';
-- Expected:
-- | holder_name | balance  |
-- |-------------|----------|
-- | Alice       | 50000.00 |  ← unchanged!


-- ============================================================
-- EXAMPLE 2: ROLLBACK on Business Rule Failure
-- ============================================================
-- Transfer ₹60,000 from Alice (who has only ₹50,000).
-- We detect insufficient funds and ROLLBACK.

BEGIN;
    -- Step 1: Check balance
    -- In a real application, this logic runs in application code (Python, Java, etc.)
    -- Here we demonstrate the concept:

    -- Debit Alice
    UPDATE accounts SET balance = balance - 60000
        WHERE holder_name = 'Alice';

    -- At this point, Alice's balance is -10000 (negative!)
    -- Our business rule says: balance must stay >= 0
    -- So we ROLLBACK the entire transaction

    -- In real code: IF alice_balance < 0 THEN ROLLBACK
ROLLBACK;

-- Alice's balance is still 50000.00
SELECT holder_name, balance FROM accounts WHERE holder_name = 'Alice';
-- Expected:
-- | holder_name | balance  |
-- |-------------|----------|
-- | Alice       | 50000.00 |


-- ============================================================
-- EXAMPLE 3: ROLLBACK TO SAVEPOINT — Partial Rollback
-- ============================================================
-- Process a multi-item order. If one item fails (out of stock),
-- rollback only that item, keep the rest.

BEGIN;
    -- Item 1: Order 2 Laptops (stock = 10, OK)
    SAVEPOINT item_1;
    UPDATE inventory SET quantity = quantity - 2 WHERE item_id = 1;
    INSERT INTO order_items (item_id, qty, total) VALUES (1, 2, 150000.00);

    -- Item 2: Order 5 Mice (stock = 50, OK)
    SAVEPOINT item_2;
    UPDATE inventory SET quantity = quantity - 5 WHERE item_id = 2;
    INSERT INTO order_items (item_id, qty, total) VALUES (2, 5, 2500.00);

    -- Item 3: Order 1 Headphones (stock = 0, FAIL!)
    SAVEPOINT item_3;
    -- This UPDATE would violate CHECK (quantity >= 0) if we try:
    -- UPDATE inventory SET quantity = quantity - 1 WHERE item_id = 4;
    -- Instead, we detect it beforehand and rollback this part:
    ROLLBACK TO SAVEPOINT item_3;

    -- Items 1 and 2 are still intact!
    -- Commit the successful items
COMMIT;

SELECT item_name, quantity FROM inventory ORDER BY item_id;
-- Expected:
-- | item_name  | quantity |
-- |------------|----------|
-- | Laptop     |        8 |  ← reduced by 2
-- | Mouse      |       45 |  ← reduced by 5
-- | Keyboard   |        3 |  ← unchanged
-- | Headphones |        0 |  ← unchanged (order failed)


-- ============================================================
-- EXAMPLE 4: Automatic ROLLBACK on Error
-- ============================================================
-- In PostgreSQL, if a statement causes an ERROR inside a
-- transaction, the entire transaction enters an ABORTED state.
-- You MUST issue ROLLBACK before you can do anything else.
-- (No further statements will succeed until ROLLBACK.)

BEGIN;
    UPDATE accounts SET balance = balance + 1000 WHERE holder_name = 'Bob';

    -- This will fail: violates CHECK constraint (quantity >= 0)
    UPDATE inventory SET quantity = quantity - 100 WHERE item_name = 'Keyboard';
    -- ERROR: new row for relation "inventory" violates check constraint
    -- "inventory_quantity_check"

    -- Now the transaction is in ABORTED state.
    -- Even a simple SELECT will fail:
    -- SELECT * FROM accounts;
    -- ERROR: current transaction is aborted, commands ignored until
    -- end of transaction block

ROLLBACK;  -- This is the ONLY command that works in aborted state

-- Bob's balance is unchanged — the entire transaction was discarded
SELECT holder_name, balance FROM accounts WHERE holder_name = 'Bob';
-- Expected:
-- | holder_name | balance  |
-- |-------------|----------|
-- | Bob         | 30000.00 |


-- ============================================================
-- EXAMPLE 5: SAVEPOINT Rescues a Transaction from Errors
-- ============================================================
-- Unlike Example 4, using a SAVEPOINT lets you recover from
-- errors without losing the entire transaction.

BEGIN;
    UPDATE accounts SET balance = balance + 1000 WHERE holder_name = 'Bob';

    SAVEPOINT before_risky_operation;

    -- This will fail (CHECK constraint violation)
    UPDATE inventory SET quantity = quantity - 100 WHERE item_name = 'Keyboard';
    -- ERROR: violates check constraint

    -- Recover using the savepoint (this WORKS even after an error!)
    ROLLBACK TO SAVEPOINT before_risky_operation;

    -- Transaction is alive again! Bob's +1000 is still pending.
    UPDATE accounts SET balance = balance + 500 WHERE holder_name = 'Charlie';

COMMIT;

-- Bob got +1000, Charlie got +500, inventory is unchanged
SELECT holder_name, balance FROM accounts
    WHERE holder_name IN ('Bob', 'Charlie')
    ORDER BY account_id;
-- Expected:
-- | holder_name | balance  |
-- |-------------|----------|
-- | Bob         | 31000.00 |
-- | Charlie     | 15500.00 |


-- ============================================================
-- EXAMPLE 6: Complete Example — Failed Transfer Rolls Back
-- ============================================================
-- Transfer ₹5,000 from Alice to Diana.
-- Diana's account is INACTIVE → transfer must fail → ROLLBACK all.

BEGIN;
    -- Step 1: Debit Alice
    UPDATE accounts SET balance = balance - 5000
        WHERE holder_name = 'Alice' AND is_active = TRUE;
    -- Rows affected: 1 (Alice is active)

    -- Step 2: Credit Diana
    UPDATE accounts SET balance = balance + 5000
        WHERE holder_name = 'Diana' AND is_active = TRUE;
    -- Rows affected: 0 (Diana is INACTIVE!)

    -- Step 3: In application code, check rows affected.
    -- If credit didn't update any rows → account frozen → ROLLBACK
    --
    -- Pseudo-code:
    --   IF rows_affected_by_credit == 0 THEN
    --       ROLLBACK;
    --       RAISE 'Recipient account is inactive';
    --   END IF;

ROLLBACK;  -- Entire transfer cancelled

-- Verify: both balances unchanged
SELECT holder_name, balance, is_active FROM accounts
    WHERE holder_name IN ('Alice', 'Diana')
    ORDER BY account_id;
-- Expected:
-- | holder_name | balance  | is_active |
-- |-------------|----------|-----------|
-- | Alice       | 50000.00 | true      |
-- | Diana       |  2000.00 | false     |


-- ============================================================
-- EXAMPLE 7: RELEASE SAVEPOINT — Cleaning Up Savepoints
-- ============================================================
-- RELEASE SAVEPOINT removes the savepoint marker but does NOT
-- commit or rollback. It merges the savepoint's changes into
-- the parent transaction.
--
-- After RELEASE, you can no longer ROLLBACK TO that savepoint.

BEGIN;
    SAVEPOINT sp1;
    INSERT INTO transfer_log (from_account, to_account, amount, status)
        VALUES (1, 2, 1000, 'PENDING');

    -- Everything looks good — release the savepoint
    RELEASE SAVEPOINT sp1;

    -- Now sp1 no longer exists.
    -- ROLLBACK TO SAVEPOINT sp1;  -- Would cause ERROR: savepoint "sp1" does not exist

    -- Update the status
    UPDATE transfer_log SET status = 'SUCCESS'
        WHERE status = 'PENDING' AND from_account = 1 AND to_account = 2;

COMMIT;

SELECT * FROM transfer_log WHERE from_account = 1 AND to_account = 2 ORDER BY log_id DESC LIMIT 1;
-- Expected:
-- | log_id | from_account | to_account | amount  | ... | status  |
-- |--------|--------------|------------|---------|-----|---------|
-- | ...    | 1            | 2          | 1000.00 | ... | SUCCESS |


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. ROLLBACK discards ALL changes made since BEGIN.
--    The database returns to its pre-transaction state.
--
-- 2. ROLLBACK, ROLLBACK WORK, and ABORT are all equivalent.
--
-- 3. In PostgreSQL, ANY error inside a transaction puts it
--    in an ABORTED state. The only way out is ROLLBACK
--    (or ROLLBACK TO SAVEPOINT if one was set).
--
-- 4. ROLLBACK TO SAVEPOINT undoes changes back to the savepoint
--    but keeps the transaction alive. This enables partial rollback.
--
-- 5. RELEASE SAVEPOINT removes the marker without committing
--    or rolling back — the changes merge into the parent transaction.
--
-- 6. Common patterns:
--    • Check business rules → ROLLBACK if violated
--    • Wrap risky operations in SAVEPOINTs → recover on error
--    • Application code checks affected rows → ROLLBACK if 0
--
-- 7. If a session disconnects without COMMIT or ROLLBACK,
--    PostgreSQL automatically rolls back the open transaction.
