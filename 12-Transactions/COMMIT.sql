-- ============================================================
-- COMMIT.sql — Committing Transactions in PostgreSQL
-- ============================================================
-- Topic  : COMMIT, Permanent Changes, Transaction Flow
-- Database: PostgreSQL 15+
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- WHAT DOES COMMIT DO?
-- ────────────────────────────────────────────────────────────
-- COMMIT ends the current transaction and makes ALL changes
-- performed since BEGIN permanent and visible to every session.
--
-- After COMMIT:
--   ✓ Data is written to disk (WAL — Write-Ahead Log)
--   ✓ Locks held by the transaction are released
--   ✓ Other sessions can see the new data
--   ✓ Changes CANNOT be undone (except with new statements)
--
-- Syntax:
--   COMMIT;
--   -- or --
--   END;          -- PostgreSQL alias for COMMIT
--   -- or --
--   COMMIT WORK;  -- SQL-standard form (same effect)

-- ────────────────────────────────────────────────────────────
-- SETUP: Sample tables used throughout examples
-- ────────────────────────────────────────────────────────────

DROP TABLE IF EXISTS transfer_log;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS employees;

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

CREATE TABLE employees (
    employee_id  SERIAL PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    department   VARCHAR(50),
    salary       NUMERIC(10, 2) NOT NULL
);

INSERT INTO accounts (holder_name, balance) VALUES
    ('Alice',   50000.00),
    ('Bob',     30000.00),
    ('Charlie', 15000.00),
    ('Diana',   80000.00);

INSERT INTO employees (name, department, salary) VALUES
    ('Rahul',  'Engineering', 75000),
    ('Priya',  'Marketing',   60000),
    ('Arjun',  'Engineering', 70000),
    ('Sneha',  'HR',          55000);


-- ============================================================
-- EXAMPLE 1: Basic COMMIT — Single Operation
-- ============================================================
-- The simplest transaction: BEGIN → one statement → COMMIT

BEGIN;
    UPDATE employees SET salary = salary + 5000 WHERE name = 'Rahul';
COMMIT;

-- After COMMIT, Rahul's salary is permanently 80000.
-- Even if the server crashes right now, this change is safe.

SELECT name, salary FROM employees WHERE name = 'Rahul';
-- Expected:
-- | name  | salary   |
-- |-------|----------|
-- | Rahul | 80000.00 |


-- ============================================================
-- EXAMPLE 2: COMMIT After Multiple Operations
-- ============================================================
-- Multiple statements inside one transaction — all committed together.

BEGIN;
    -- Give raises to the entire Engineering department
    UPDATE employees SET salary = salary * 1.10
        WHERE department = 'Engineering';

    -- Log the raise action
    INSERT INTO transfer_log (from_account, to_account, amount, status)
        VALUES (0, 0, 0, 'SALARY_RAISE');

    -- Verify before committing
    SELECT name, salary FROM employees WHERE department = 'Engineering';
    -- | name  | salary   |
    -- |-------|----------|
    -- | Rahul | 88000.00 |
    -- | Arjun | 77000.00 |
COMMIT;

-- All three operations (UPDATE, INSERT, SELECT) are now permanent.
-- If any one had failed, we could have used ROLLBACK instead.


-- ============================================================
-- EXAMPLE 3: COMMIT vs. No COMMIT — What Happens?
-- ============================================================
-- Without COMMIT, changes are ONLY visible inside the transaction
-- and are LOST if the session ends or a ROLLBACK occurs.

-- Scenario: Session A starts a transaction but does NOT commit

-- SESSION A:
BEGIN;
    UPDATE accounts SET balance = 99999.99 WHERE holder_name = 'Charlie';
    -- At this point:
    --   • Session A sees Charlie's balance as 99999.99
    --   • Session B (another connection) still sees 15000.00
    --   • The change is NOT on disk yet
ROLLBACK;  -- Discarding — Charlie stays at 15000.00

-- Verify nothing changed
SELECT holder_name, balance FROM accounts WHERE holder_name = 'Charlie';
-- Expected:
-- | holder_name | balance  |
-- |-------------|----------|
-- | Charlie     | 15000.00 |


-- ============================================================
-- EXAMPLE 4: Complete Transaction Flow — BEGIN → Ops → COMMIT
-- ============================================================
-- Creating a new account and funding it in one atomic operation.

BEGIN;
    -- Step 1: Create new account
    INSERT INTO accounts (holder_name, balance)
        VALUES ('Eve', 0.00);

    -- Step 2: Transfer initial deposit from Diana
    UPDATE accounts SET balance = balance - 10000 WHERE holder_name = 'Diana';
    UPDATE accounts SET balance = balance + 10000 WHERE holder_name = 'Eve';

    -- Step 3: Log the transfer
    INSERT INTO transfer_log (from_account, to_account, amount)
        VALUES (
            (SELECT account_id FROM accounts WHERE holder_name = 'Diana'),
            (SELECT account_id FROM accounts WHERE holder_name = 'Eve'),
            10000.00
        );
COMMIT;

-- All four operations committed atomically.
-- If creating the log entry had failed, NOTHING would be saved.

SELECT holder_name, balance FROM accounts ORDER BY account_id;
-- Expected:
-- | holder_name | balance  |
-- |-------------|----------|
-- | Alice       | 50000.00 |
-- | Bob         | 30000.00 |
-- | Charlie     | 15000.00 |
-- | Diana       | 70000.00 |
-- | Eve         | 10000.00 |


-- ============================================================
-- EXAMPLE 5: Real-World — Bank Transfer (Debit + Credit)
-- ============================================================
-- This is the classic example of WHY transactions exist.
-- Transfer ₹5,000 from Alice to Bob.

-- Step-by-step:
--   1. Check if Alice has enough balance
--   2. Debit Alice's account
--   3. Credit Bob's account
--   4. Record the transfer in the log
--   5. COMMIT only if everything succeeds

BEGIN;

    -- Guard: Check sufficient funds (in real apps, use SELECT ... FOR UPDATE)
    -- SELECT balance FROM accounts WHERE holder_name = 'Alice' FOR UPDATE;

    -- Debit sender
    UPDATE accounts
        SET balance = balance - 5000
        WHERE holder_name = 'Alice'
          AND balance >= 5000;       -- Prevents negative balance

    -- Credit receiver
    UPDATE accounts
        SET balance = balance + 5000
        WHERE holder_name = 'Bob';

    -- Record the transfer
    INSERT INTO transfer_log (from_account, to_account, amount)
        VALUES (
            (SELECT account_id FROM accounts WHERE holder_name = 'Alice'),
            (SELECT account_id FROM accounts WHERE holder_name = 'Bob'),
            5000.00
        );

COMMIT;

-- After COMMIT:
-- Alice: 50000 - 5000 = 45000
-- Bob:   30000 + 5000 = 35000

SELECT holder_name, balance FROM accounts
    WHERE holder_name IN ('Alice', 'Bob')
    ORDER BY account_id;
-- Expected:
-- | holder_name | balance  |
-- |-------------|----------|
-- | Alice       | 45000.00 |
-- | Bob         | 35000.00 |

-- Transfer log:
SELECT from_account, to_account, amount, status, transferred_at
    FROM transfer_log
    ORDER BY log_id DESC LIMIT 1;
-- Expected:
-- | from_account | to_account | amount  | status  | transferred_at      |
-- |--------------|------------|---------|---------|---------------------|
-- | 1            | 2          | 5000.00 | SUCCESS | 2026-06-26 ...      |


-- ============================================================
-- EXAMPLE 6: Using END (Alias for COMMIT)
-- ============================================================
-- PostgreSQL accepts END as an alias for COMMIT.
-- Both do exactly the same thing.

BEGIN;
    UPDATE employees SET department = 'Product' WHERE name = 'Priya';
END;  -- Same as COMMIT

SELECT name, department FROM employees WHERE name = 'Priya';
-- Expected:
-- | name  | department |
-- |-------|------------|
-- | Priya | Product    |


-- ============================================================
-- EXAMPLE 7: COMMIT Releases Locks
-- ============================================================
-- While a transaction is open, rows modified by it are locked.
-- Other sessions trying to UPDATE the same rows will WAIT.
-- COMMIT releases those locks immediately.

-- SESSION A:
BEGIN;
    UPDATE accounts SET balance = balance - 100 WHERE holder_name = 'Alice';
    -- Alice's row is now locked. Session B cannot update it.
    -- Session B's UPDATE on Alice will BLOCK until this commits.
COMMIT;
-- Lock released. Session B can now proceed.


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. COMMIT makes all changes since BEGIN permanent and durable.
--    After COMMIT, changes survive server crashes.
--
-- 2. COMMIT, END, and COMMIT WORK are all equivalent in PostgreSQL.
--
-- 3. Until COMMIT is issued, changes are:
--      • Visible only inside the current transaction
--      • NOT written permanently to disk
--      • Lost if the session disconnects
--
-- 4. COMMIT releases all row-level and table-level locks held
--    by the transaction, unblocking other waiting sessions.
--
-- 5. Always pair BEGIN with COMMIT or ROLLBACK.
--    Leaving a transaction open ("idle in transaction") wastes
--    resources and blocks other operations.
--
-- 6. In real-world apps, wrap related operations (debit + credit,
--    insert + log) in a single transaction to guarantee atomicity.
