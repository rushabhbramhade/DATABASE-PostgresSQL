# ACID Properties in PostgreSQL

> The four pillars that guarantee reliable database transactions.

---

## 📑 Table of Contents

1. [What is ACID?](#what-is-acid)
2. [Atomicity — All or Nothing](#1-atomicity--all-or-nothing)
3. [Consistency — Always Valid](#2-consistency--always-valid)
4. [Isolation — No Interference](#3-isolation--no-interference)
5. [Durability — Survives Crashes](#4-durability--survives-crashes)
6. [Real-World Analogy: Bank ATM Scenario](#real-world-analogy-bank-atm-scenario)
7. [PostgreSQL Isolation Levels](#postgresql-isolation-levels)
8. [MVCC — Multi-Version Concurrency Control](#mvcc--multi-version-concurrency-control)
9. [Practical SQL Examples](#practical-sql-examples)
10. [Common Interview Questions](#common-interview-questions)
11. [Quick Reference](#quick-reference)

---

## What is ACID?

**ACID** is a set of four properties that guarantee database transactions are processed **reliably**, even in the face of errors, crashes, or concurrent access.

| Letter | Property      | One-Liner                                  |
|--------|---------------|--------------------------------------------|
| **A**  | Atomicity     | All or nothing — no partial changes         |
| **C**  | Consistency   | Database moves from one valid state to another |
| **I**  | Isolation     | Concurrent transactions don't interfere     |
| **D**  | Durability    | Committed data survives crashes             |

> **Why does it matter?**  
> Without ACID, your bank could debit your account but fail to credit the merchant — and the money would simply vanish.

---

## 1. Atomicity — All or Nothing

### Definition

A transaction is **atomic**: either **all** of its operations succeed and are applied, or **none** of them are. There is no in-between state.

### Real-World Analogy 🏧

> You're at an ATM transferring ₹5,000 from Savings to Checking:
> 1. Debit ₹5,000 from Savings  
> 2. Credit ₹5,000 to Checking
>
> If the ATM crashes after step 1, atomicity ensures step 1 is **undone**. Your money doesn't disappear.

### How PostgreSQL Implements It

- **Write-Ahead Log (WAL):** Every change is written to WAL before being applied. If a crash occurs mid-transaction, PostgreSQL replays the WAL and rolls back incomplete transactions.
- **ROLLBACK:** If any statement fails, the entire transaction is aborted — no partial writes remain.

### SQL Example

```sql
BEGIN;
    UPDATE accounts SET balance = balance - 5000 WHERE id = 1;  -- Debit
    UPDATE accounts SET balance = balance + 5000 WHERE id = 2;  -- Credit
    -- If the credit fails, the debit is also undone
COMMIT;
```

### What Atomicity Prevents

| Scenario                          | Without Atomicity       | With Atomicity          |
|-----------------------------------|-------------------------|-------------------------|
| Server crash mid-transfer         | Money debited, not credited | Both changes rolled back |
| INSERT fails after UPDATE         | UPDATE is saved (wrong) | Everything rolled back   |
| Network timeout during COMMIT     | Partial data written    | Nothing saved            |

---

## 2. Consistency — Always Valid

### Definition

A transaction brings the database from one **valid state** to another valid state. All constraints (PRIMARY KEY, FOREIGN KEY, CHECK, UNIQUE, NOT NULL) are enforced.

### Real-World Analogy 🏧

> The ATM won't let you withdraw ₹10,000 if you only have ₹3,000. The "balance ≥ 0" rule is a **consistency constraint**.
>
> Before the transaction: total money in the bank = ₹1,00,000  
> After the transaction: total money in the bank = ₹1,00,000  
> Money is never created or destroyed.

### How PostgreSQL Implements It

- **Constraints** are checked at statement execution or at COMMIT time (`DEFERRABLE` constraints).
- **Triggers** can enforce complex business rules.
- If any constraint is violated, the transaction is aborted.

### SQL Example

```sql
CREATE TABLE accounts (
    id      SERIAL PRIMARY KEY,
    name    VARCHAR(100) NOT NULL,
    balance NUMERIC(12,2) CHECK (balance >= 0)  -- Consistency rule
);

BEGIN;
    UPDATE accounts SET balance = balance - 10000 WHERE name = 'Alice';
    -- If Alice has only 3000, CHECK constraint fails
    -- ERROR: new row violates check constraint "accounts_balance_check"
    -- Transaction is aborted — database stays consistent
COMMIT;
```

### What Consistency Prevents

- Negative balances (when constrained)
- Orphaned foreign key references
- Duplicate primary keys
- NULL values in required columns

---

## 3. Isolation — No Interference

### Definition

Concurrent transactions execute as if they were running **one at a time** (serially). One transaction cannot see the **intermediate** (uncommitted) changes of another.

### Real-World Analogy 🏧

> Two people are using different ATMs to access the **same** account simultaneously.
> - Person A: Checking balance → Withdrawing ₹5,000
> - Person B: Checking balance → Withdrawing ₹3,000
>
> Isolation ensures they don't both see ₹10,000 and withdraw a total of ₹8,000 when only ₹10,000 exists. Each sees a consistent snapshot.

### How PostgreSQL Implements It

PostgreSQL uses **MVCC** (Multi-Version Concurrency Control) — more on this below. Each transaction works with a **snapshot** of the data, preventing interference without heavy locking.

### Isolation Anomalies

| Anomaly              | Description                                                      |
|----------------------|------------------------------------------------------------------|
| **Dirty Read**       | Reading data written by an uncommitted transaction               |
| **Non-Repeatable Read** | Same query returns different results within one transaction   |
| **Phantom Read**     | New rows appear between two identical queries                    |
| **Serialization Anomaly** | Result differs from any serial execution order              |

> **PostgreSQL never allows dirty reads** — even at the lowest isolation level.

---

## 4. Durability — Survives Crashes

### Definition

Once a transaction is **committed**, the changes are **permanent** — even if the server loses power, crashes, or the OS fails immediately after.

### Real-World Analogy 🏧

> After the ATM prints your receipt and says "Transfer Complete," the money is moved — permanently. Even if the bank's server room catches fire 1 second later, your transaction is safe because it was written to durable storage.

### How PostgreSQL Implements It

1. **WAL (Write-Ahead Log):** Changes are written to the WAL on disk **before** COMMIT returns.
2. **`fsync`:** PostgreSQL calls `fsync()` to force the OS to flush data from memory to physical disk.
3. **Checkpoints:** Periodically, dirty data pages are written to the main data files.
4. **Crash Recovery:** On startup after a crash, PostgreSQL replays the WAL to restore committed transactions and discard uncommitted ones.

### Configuration

```sql
-- These settings control durability (defaults are safe):
SHOW wal_level;          -- 'replica' (default)
SHOW fsync;              -- 'on'  (NEVER turn this off in production!)
SHOW synchronous_commit; -- 'on'  (can set to 'off' for speed at risk of recent data loss)
```

> **⚠️ Warning:** Setting `fsync = off` improves performance but risks data loss on crash. **Never do this in production.**

---

## Real-World Analogy: Bank ATM Scenario

Let's trace a complete ATM withdrawal through all four ACID properties:

```
You insert your card and request ₹2,000 withdrawal
```

| Step | ACID Property | What Happens                                                   |
|------|---------------|----------------------------------------------------------------|
| 1    | **Atomicity** | The ATM starts a transaction: debit account + dispense cash. If the cash tray jams, the debit is reversed. |
| 2    | **Consistency** | The system checks: Does the account have ≥ ₹2,000? Is the card valid? Is the daily limit exceeded? If any check fails, the transaction is rejected. |
| 3    | **Isolation** | While you're withdrawing, your partner is depositing ₹5,000 at another ATM. Neither transaction sees the other's incomplete changes. |
| 4    | **Durability** | The receipt prints "Withdrawal Successful." Even if the bank's server crashes 1ms later, your ₹2,000 debit is permanently recorded. |

---

## PostgreSQL Isolation Levels

PostgreSQL supports **three** usable isolation levels (READ UNCOMMITTED is accepted syntactically but behaves as READ COMMITTED):

### Comparison Table

| Feature                    | READ COMMITTED (Default) | REPEATABLE READ | SERIALIZABLE |
|----------------------------|:------------------------:|:---------------:|:------------:|
| Dirty Reads                | ❌ Never                  | ❌ Never         | ❌ Never      |
| Non-Repeatable Reads       | ⚠️ Possible              | ❌ Prevented     | ❌ Prevented  |
| Phantom Reads              | ⚠️ Possible              | ❌ Prevented*    | ❌ Prevented  |
| Serialization Anomalies    | ⚠️ Possible              | ⚠️ Possible     | ❌ Prevented  |
| Performance                | ⭐⭐⭐ Best               | ⭐⭐ Good        | ⭐ Slowest   |
| Risk of Abort/Retry        | Low                      | Medium           | High          |

*\*PostgreSQL's REPEATABLE READ uses snapshot isolation, which prevents phantoms but may throw serialization errors.*

### Setting the Isolation Level

```sql
-- Method 1: In the BEGIN statement
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    -- your queries here
COMMIT;

-- Method 2: Using SET TRANSACTION (must be first statement after BEGIN)
BEGIN;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    -- your queries here
COMMIT;

-- Method 3: Set default for the entire session
SET default_transaction_isolation = 'repeatable read';
```

### When to Use Each Level

| Use Case                            | Recommended Level    |
|--------------------------------------|----------------------|
| Most OLTP applications               | READ COMMITTED       |
| Financial reports, balance snapshots  | REPEATABLE READ      |
| Bank transfers, inventory management  | SERIALIZABLE         |
| Read-only analytics / reporting       | REPEATABLE READ + READ ONLY |

---

## MVCC — Multi-Version Concurrency Control

### What Is MVCC?

MVCC is PostgreSQL's strategy for handling concurrent access **without locking rows for readers**. Instead of making transactions wait, PostgreSQL keeps **multiple versions** of each row.

### How It Works (Simplified)

```
┌─────────────────────────────────────────────────────────┐
│                    Row: Alice, ₹5000                    │
├─────────────────────────────────────────────────────────┤
│ Version 1: balance = 5000  (created by Txn 100, valid)  │
│ Version 2: balance = 3000  (created by Txn 105, pending)│
└─────────────────────────────────────────────────────────┘

Transaction 110 (READ COMMITTED) reads Version 1
    → sees balance = 5000 (Txn 105 hasn't committed yet)

Transaction 105 commits.

Transaction 110 runs another SELECT
    → now sees balance = 3000 (Txn 105 committed)

Transaction 108 (REPEATABLE READ) started before Txn 105
    → ALWAYS sees balance = 5000 (its snapshot is from Txn < 105)
```

### Key Points

| Concept                | Explanation                                                   |
|------------------------|---------------------------------------------------------------|
| **xmin**               | Transaction ID that created this row version                   |
| **xmax**               | Transaction ID that deleted/updated this row version           |
| **Snapshot**           | The set of transaction IDs visible to the current transaction  |
| **VACUUM**             | Cleans up old row versions no longer visible to any transaction |
| **Readers don't block writers** | SELECT never blocks UPDATE/DELETE, and vice versa     |
| **Writers block writers** | Two transactions updating the same row will conflict        |

### Why MVCC Matters

- **High concurrency**: Reads never block writes.
- **Consistent snapshots**: Each transaction sees a consistent point-in-time view.
- **No dirty reads**: Uncommitted changes are invisible to other transactions.

---

## Practical SQL Examples

### Example 1: Atomicity in Action

```sql
-- Transfer ₹5,000 from Alice to Bob
BEGIN;
    UPDATE accounts SET balance = balance - 5000 WHERE holder_name = 'Alice';
    UPDATE accounts SET balance = balance + 5000 WHERE holder_name = 'Bob';
    
    -- If any UPDATE fails → ROLLBACK undoes EVERYTHING
    -- If both succeed → COMMIT saves EVERYTHING
COMMIT;
```

### Example 2: Consistency — CHECK Constraint Prevents Invalid State

```sql
BEGIN;
    -- Alice has ₹3,000. Try to withdraw ₹10,000:
    UPDATE accounts SET balance = balance - 10000 WHERE holder_name = 'Alice';
    -- ERROR: new row violates check constraint "accounts_balance_check"
    -- Transaction ABORTED — Alice still has ₹3,000
ROLLBACK;
```

### Example 3: Isolation — Two Concurrent Sessions

```sql
-- SESSION A (starts first)                -- SESSION B (starts second)
BEGIN;                                      
UPDATE accounts                             BEGIN;
  SET balance = balance - 1000              SELECT balance FROM accounts
  WHERE holder_name = 'Alice';                WHERE holder_name = 'Alice';
                                            -- Sees: 50000 (A's change is uncommitted)
COMMIT;                                     
                                            SELECT balance FROM accounts
                                              WHERE holder_name = 'Alice';
                                            -- Now sees: 49000 (A committed)
                                            COMMIT;
```

### Example 4: Durability — Crash Recovery

```sql
BEGIN;
    INSERT INTO accounts (holder_name, balance) VALUES ('Eve', 25000);
COMMIT;  -- WAL is flushed to disk at this point

-- If the server crashes NOW, on restart:
-- PostgreSQL replays WAL → Eve's row is restored
-- Any uncommitted transactions are rolled back
```

### Example 5: SAVEPOINT for Partial Atomicity

```sql
BEGIN;
    UPDATE accounts SET balance = balance - 1000 WHERE holder_name = 'Alice';
    
    SAVEPOINT before_bob;
    UPDATE accounts SET balance = balance + 1000 WHERE holder_name = 'Bob';
    -- Oops, Bob's account is frozen
    ROLLBACK TO SAVEPOINT before_bob;
    
    -- Credit Charlie instead
    UPDATE accounts SET balance = balance + 1000 WHERE holder_name = 'Charlie';
COMMIT;
-- Alice: -1000, Charlie: +1000, Bob: unchanged
```

---

## Common Interview Questions

### Q1: What does ACID stand for?

**A:** Atomicity, Consistency, Isolation, Durability — four properties that guarantee reliable transaction processing.

---

### Q2: What is the difference between Atomicity and Consistency?

**A:**
- **Atomicity** = All operations in a transaction succeed or all fail (structural guarantee).
- **Consistency** = The database moves from one valid state to another, respecting all constraints (semantic guarantee).

> Analogy: Atomicity ensures the entire recipe is cooked or not at all. Consistency ensures the dish is edible (meets quality standards).

---

### Q3: Can you have Durability without Atomicity?

**A:** Technically yes — you could write partial changes to disk permanently. But this would be **dangerous** because you'd have incomplete transactions permanently stored. That's why ACID properties work **together**.

---

### Q4: What is a Dirty Read, and does PostgreSQL allow it?

**A:** A dirty read occurs when Transaction B reads data written by Transaction A before A commits. **PostgreSQL never allows dirty reads**, even at the READ COMMITTED level, thanks to MVCC.

---

### Q5: What is the default isolation level in PostgreSQL?

**A:** **READ COMMITTED**. Each statement within a transaction sees only data committed before that statement began.

---

### Q6: What happens if two transactions update the same row?

**A:**
- At **READ COMMITTED**: The second transaction waits for the first to commit, then re-evaluates.
- At **REPEATABLE READ** or **SERIALIZABLE**: The second transaction gets an error: `ERROR: could not serialize access due to concurrent update`.

---

### Q7: How does PostgreSQL achieve Durability?

**A:** Through the **Write-Ahead Log (WAL)**. Before COMMIT returns success, the transaction's changes are written to WAL on disk. On crash recovery, PostgreSQL replays the WAL.

---

### Q8: What is MVCC, and why is it important?

**A:** MVCC (Multi-Version Concurrency Control) keeps multiple versions of each row so that:
- Readers never block writers
- Writers never block readers
- Each transaction sees a consistent snapshot

This gives PostgreSQL high concurrency without heavy locking.

---

### Q9: Explain the difference between REPEATABLE READ and SERIALIZABLE.

**A:**

| Aspect            | REPEATABLE READ                     | SERIALIZABLE                         |
|-------------------|-------------------------------------|--------------------------------------|
| Snapshot           | Taken at first query in transaction | Taken at first query in transaction  |
| Write conflicts    | Detected (causes error)            | Detected (causes error)             |
| Read-write skew    | **NOT detected**                   | Detected (prevents all anomalies)    |
| Performance        | Better                              | Slightly worse (more checking)       |

---

### Q10: What is a "lost update" and how do you prevent it?

**A:** A lost update occurs when two transactions read the same row, compute new values, and write back — the second write overwrites the first. Prevent it with:
1. `SELECT ... FOR UPDATE` (pessimistic locking)
2. SERIALIZABLE isolation level
3. Application-level optimistic locking (version columns)

---

## Quick Reference

### ACID at a Glance

```
┌─────────────┬──────────────────────────────────────────────┐
│  ATOMICITY   │  All changes in a transaction succeed or     │
│              │  all are rolled back. No partial state.      │
├─────────────┼──────────────────────────────────────────────┤
│ CONSISTENCY  │  Constraints, triggers, and rules ensure     │
│              │  the DB is always in a valid state.          │
├─────────────┼──────────────────────────────────────────────┤
│  ISOLATION   │  Concurrent transactions don't see each      │
│              │  other's uncommitted changes (via MVCC).     │
├─────────────┼──────────────────────────────────────────────┤
│ DURABILITY   │  Committed data is written to WAL on disk.   │
│              │  Survives crashes and power failures.        │
└─────────────┴──────────────────────────────────────────────┘
```

### PostgreSQL Mechanisms

| ACID Property | PostgreSQL Mechanism                          |
|---------------|-----------------------------------------------|
| Atomicity     | WAL + ROLLBACK                                |
| Consistency   | Constraints, Triggers, Rules                  |
| Isolation     | MVCC + Snapshot Isolation                     |
| Durability    | WAL + fsync + Checkpoints                     |

---

*End of ACID.md — Part of the PostgreSQL Learning Repository*
