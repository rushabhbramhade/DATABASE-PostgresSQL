# 📝 DML Commands — Comprehensive Notes

## Table of Contents

- [What is DML?](#what-is-dml)
- [INSERT — Adding Data](#insert--adding-data)
- [UPDATE — Modifying Data](#update--modifying-data)
- [DELETE — Removing Data](#delete--removing-data)
- [RETURNING Clause](#returning-clause)
- [UPSERT — INSERT ON CONFLICT](#upsert--insert-on-conflict)
- [Transaction Safety with DML](#transaction-safety-with-dml)
- [Common Mistakes](#common-mistakes)
- [Real-World Usage Patterns](#real-world-usage-patterns)
- [Quick Reference Cheat Sheet](#quick-reference-cheat-sheet)

---

## What is DML?

**DML** stands for **Data Manipulation Language**. These are SQL commands used to **read, insert, update, and delete** data inside database tables.

| Command    | Purpose                          | Modifies Data? |
|------------|----------------------------------|:--------------:|
| `SELECT`   | Read / retrieve data             | ❌ No          |
| `INSERT`   | Add new rows                     | ✅ Yes         |
| `UPDATE`   | Modify existing rows             | ✅ Yes         |
| `DELETE`   | Remove existing rows             | ✅ Yes         |

> **Note:** `SELECT` is technically DML (it manipulates/queries data), but many references group it separately as **DQL (Data Query Language)**. This module focuses on the write operations: INSERT, UPDATE, and DELETE.

### DML vs DDL vs DCL

| Category | Full Form                  | Commands                          | What It Does              |
|----------|----------------------------|-----------------------------------|---------------------------|
| **DDL**  | Data Definition Language   | CREATE, ALTER, DROP, TRUNCATE     | Defines table structure   |
| **DML**  | Data Manipulation Language | INSERT, UPDATE, DELETE, SELECT    | Works with actual data    |
| **DCL**  | Data Control Language      | GRANT, REVOKE                     | Controls permissions      |
| **TCL**  | Transaction Control Language | BEGIN, COMMIT, ROLLBACK, SAVEPOINT | Manages transactions    |

---

## INSERT — Adding Data

### Basic Syntax

```sql
INSERT INTO table_name (column1, column2, column3)
VALUES (value1, value2, value3);
```

### Key Variations

#### 1. With Explicit Column List (Recommended ✅)
```sql
INSERT INTO employees (first_name, last_name, email, salary)
VALUES ('Aarav', 'Sharma', 'aarav@company.com', 75000);
```

#### 2. Without Column List (Fragile ❌)
```sql
-- Must provide ALL columns in exact table order
INSERT INTO employees
VALUES (DEFAULT, 'Aarav', 'Sharma', 'aarav@company.com', 'Engineering', 75000, CURRENT_DATE, TRUE);
```

#### 3. Multiple Rows in One Statement
```sql
INSERT INTO products (product_name, category, price)
VALUES
    ('Wireless Mouse',      'Electronics', 29.99),
    ('Mechanical Keyboard', 'Electronics', 89.99),
    ('Standing Desk',       'Furniture',  349.99);
```
> **Performance tip:** Multi-row INSERT is significantly faster than separate INSERT statements because it sends one command to the server instead of many.

#### 4. With DEFAULT Values
```sql
-- Explicitly use DEFAULT keyword
INSERT INTO employees (first_name, last_name, email, department)
VALUES ('Sneha', 'Iyer', 'sneha@company.com', DEFAULT);

-- Or simply omit the column (same result)
INSERT INTO employees (first_name, last_name, email)
VALUES ('Sneha', 'Iyer', 'sneha@company.com');
```

#### 5. INSERT from SELECT
```sql
INSERT INTO employees_archive (employee_id, first_name, last_name, email)
SELECT employee_id, first_name, last_name, email
FROM employees
WHERE is_active = FALSE;
```

---

## UPDATE — Modifying Data

### Basic Syntax

```sql
UPDATE table_name
SET column1 = new_value1,
    column2 = new_value2
WHERE condition;
```

> ⚠️ **ALWAYS include a WHERE clause** unless you intentionally want to update every row.

### Key Variations

#### 1. Single Column
```sql
UPDATE employees SET salary = 82000 WHERE employee_id = 1;
```

#### 2. Multiple Columns
```sql
UPDATE employees
SET department = 'Engineering',
    salary     = 68000
WHERE employee_id = 4;
```

#### 3. With Expressions
```sql
-- 10% raise for all engineers
UPDATE employees
SET salary = salary * 1.10
WHERE department = 'Engineering';
```

#### 4. With Subquery
```sql
UPDATE employees
SET salary = (SELECT AVG(salary) FROM employees WHERE department = 'Engineering')
WHERE employee_id = 4;
```

#### 5. With JOIN (PostgreSQL FROM Syntax)
```sql
-- PostgreSQL uses FROM instead of JOIN inside UPDATE
UPDATE employees
SET salary = employees.salary + d.salary_bonus
FROM departments d
WHERE employees.department = d.dept_name;
```

> **Important:** Standard SQL uses `UPDATE ... SET ... FROM ... JOIN`. PostgreSQL uses `UPDATE ... SET ... FROM ... WHERE` (the join condition goes in WHERE).

#### 6. Conditional UPDATE with CASE
```sql
UPDATE employees
SET salary = CASE
    WHEN salary < 60000  THEN salary * 1.15
    WHEN salary < 80000  THEN salary * 1.10
    ELSE salary * 1.05
END
WHERE is_active = TRUE;
```

---

## DELETE — Removing Data

### Basic Syntax

```sql
DELETE FROM table_name
WHERE condition;
```

> ⚠️ **Without WHERE, ALL rows are deleted!**

### Key Variations

#### 1. Delete Specific Rows
```sql
DELETE FROM employees WHERE is_active = FALSE;
DELETE FROM orders WHERE status = 'cancelled' AND order_date < '2025-01-01';
```

#### 2. Delete with Subquery
```sql
DELETE FROM products
WHERE product_id NOT IN (
    SELECT DISTINCT product_id FROM order_items WHERE product_id IS NOT NULL
);
```

#### 3. Delete with JOIN (PostgreSQL USING Syntax)
```sql
-- PostgreSQL uses USING instead of JOIN inside DELETE
DELETE FROM order_items
USING orders
WHERE order_items.order_id = orders.order_id
  AND orders.status = 'cancelled';
```

#### 4. DELETE vs TRUNCATE

| Feature              | DELETE                     | TRUNCATE                        |
|----------------------|----------------------------|---------------------------------|
| Removes              | Specific rows (WHERE)      | ALL rows only                   |
| Speed                | Slower (row-by-row)        | Much faster (deallocates pages) |
| WHERE clause         | ✅ Yes                     | ❌ No                           |
| RETURNING clause     | ✅ Yes                     | ❌ No                           |
| Fires row triggers   | ✅ Yes                     | ❌ No                           |
| Resets SERIAL IDs    | ❌ No                      | ✅ With RESTART IDENTITY        |
| Can ROLLBACK (in PG) | ✅ Yes                     | ✅ Yes                          |
| Frees disk space     | ❌ Not immediately (VACUUM)| ✅ Immediately                  |

```sql
-- TRUNCATE: fast full-table wipe with ID reset
TRUNCATE TABLE products RESTART IDENTITY;

-- TRUNCATE with CASCADE (removes referencing rows too)
TRUNCATE TABLE orders CASCADE;
```

---

## RETURNING Clause

The `RETURNING` clause is a **PostgreSQL-specific** feature that returns data from rows affected by INSERT, UPDATE, or DELETE — eliminating the need for a separate SELECT.

### Syntax

```sql
INSERT INTO ... VALUES (...) RETURNING column1, column2;
UPDATE ... SET ... WHERE ... RETURNING *;
DELETE FROM ... WHERE ... RETURNING column1, column2;
```

### Examples

```sql
-- Get the auto-generated ID after insert
INSERT INTO employees (first_name, last_name, email)
VALUES ('Kiran', 'Rao', 'kiran@company.com')
RETURNING employee_id;
-- Result: employee_id = 7

-- See updated salary values
UPDATE employees SET salary = salary * 1.10
WHERE department = 'Engineering'
RETURNING employee_id, first_name, salary AS new_salary;

-- Capture deleted rows for auditing
DELETE FROM orders WHERE status = 'cancelled'
RETURNING *;
```

### Archive-and-Delete Pattern (CTE + RETURNING)

```sql
WITH deleted AS (
    DELETE FROM employees
    WHERE is_active = FALSE
    RETURNING *
)
INSERT INTO employees_archive
SELECT employee_id, first_name, last_name, email, department, salary
FROM deleted;
```

This atomically moves rows from the active table to an archive in a single statement.

---

## UPSERT — INSERT ON CONFLICT

**UPSERT** = **UP**date + in**SERT**. Insert a row if it doesn't exist; update it if it does.

### Syntax

```sql
INSERT INTO table_name (columns)
VALUES (values)
ON CONFLICT (conflict_column)
DO NOTHING | DO UPDATE SET column = value;
```

> The conflict column must have a **UNIQUE constraint** or be a **PRIMARY KEY**.

### DO NOTHING — Skip Duplicates

```sql
INSERT INTO employees (first_name, last_name, email)
VALUES ('Aarav', 'Sharma', 'aarav@company.com')
ON CONFLICT (email) DO NOTHING;
-- Silently skips if email already exists
```

### DO UPDATE — Update on Conflict

```sql
INSERT INTO products (product_name, category, price, stock_qty)
VALUES ('Wireless Mouse', 'Electronics', 24.99, 200)
ON CONFLICT (product_name) DO UPDATE
SET price     = EXCLUDED.price,
    stock_qty = EXCLUDED.stock_qty;
```

> `EXCLUDED` is a special table that refers to the row that was proposed for insertion but caused a conflict.

### Conditional UPSERT

```sql
INSERT INTO products (product_name, category, price)
VALUES ('Keyboard', 'Electronics', 79.99)
ON CONFLICT (product_name) DO UPDATE
SET price = EXCLUDED.price
WHERE products.price > EXCLUDED.price;
-- Only update if the new price is lower
```

### Common Use Cases
- **Idempotent imports** — re-running the same CSV import won't create duplicates
- **Configuration tables** — insert default, update if exists
- **Inventory syncing** — update stock counts from external feeds
- **User profiles** — create on first login, update on subsequent logins

---

## Transaction Safety with DML

DML statements should be wrapped in **transactions** to ensure atomicity — either all changes succeed, or none do.

### Basic Transaction Flow

```sql
BEGIN;                                          -- Start transaction
    INSERT INTO orders (...) VALUES (...);      -- Step 1
    INSERT INTO order_items (...) VALUES (...); -- Step 2
    UPDATE products SET stock_qty = stock_qty - 1 WHERE ...; -- Step 3
COMMIT;                                         -- All succeed → save
```

### Rollback on Error

```sql
BEGIN;
    DELETE FROM employees WHERE department = 'Temp';
    -- Oops, deleted wrong rows!
ROLLBACK;                                       -- Undo everything
```

### Savepoints — Partial Rollback

```sql
BEGIN;
    INSERT INTO employees (...) VALUES (...);
    SAVEPOINT before_update;

    UPDATE employees SET salary = 0;  -- Mistake!
    ROLLBACK TO before_update;        -- Undo only the UPDATE

    UPDATE employees SET salary = salary * 1.10;  -- Correct version
COMMIT;
```

### Transaction Safety Rules

| Rule | Explanation |
|------|-------------|
| Always use `BEGIN` / `COMMIT` | Groups multiple DML into one atomic operation |
| Use `ROLLBACK` on errors | Undoes all changes since `BEGIN` |
| Use `SAVEPOINT` for complex flows | Allows partial rollback within a transaction |
| Keep transactions short | Long transactions lock rows and block other users |
| Never leave transactions open | An uncommitted transaction holds locks indefinitely |

---

## Common Mistakes

| # | Mistake | What Happens | Fix |
|---|---------|-------------|-----|
| 1 | `UPDATE` without `WHERE` | Every row in the table is modified | Always add a `WHERE` clause |
| 2 | `DELETE` without `WHERE` | Every row in the table is removed | Always add a `WHERE` clause |
| 3 | Omitting column list in `INSERT` | Breaks if table schema changes | Always list columns explicitly |
| 4 | Inserting duplicate into UNIQUE column | `ERROR: duplicate key` | Use `ON CONFLICT DO NOTHING` or `DO UPDATE` |
| 5 | Forgetting `COMMIT` after `BEGIN` | Changes are invisible to others; locks held | Always pair `BEGIN` with `COMMIT` or `ROLLBACK` |
| 6 | Deleting parent before child rows | `ERROR: violates foreign key constraint` | Delete children first, or use `ON DELETE CASCADE` |
| 7 | Using `NOT IN` with NULLs | Subquery with NULL returns no matches | Use `NOT EXISTS` instead |
| 8 | Not testing with `SELECT` first | Accidentally modify wrong rows | Preview with `SELECT` using the same `WHERE` |
| 9 | Data type mismatch in VALUES | `ERROR: invalid input syntax` | Ensure values match column types |
| 10 | Using `TRUNCATE` when `DELETE` is needed | Cannot filter rows; cannot use RETURNING | Use `DELETE` when you need `WHERE` or `RETURNING` |

---

## Real-World Usage Patterns

### 1. User Registration (INSERT + RETURNING)
```sql
INSERT INTO users (username, email, password_hash, created_at)
VALUES ('john_doe', 'john@example.com', '$2b$12$...hash...', NOW())
RETURNING user_id, username, created_at;
-- App gets the new user_id immediately for the session
```

### 2. Shopping Cart Checkout (Transaction)
```sql
BEGIN;
    -- Create the order
    INSERT INTO orders (customer_id, total_amount)
    VALUES (42, 159.97)
    RETURNING order_id INTO v_order_id;

    -- Add items
    INSERT INTO order_items (order_id, product_id, quantity, unit_price)
    VALUES (v_order_id, 101, 2, 29.99),
           (v_order_id, 205, 1, 99.99);

    -- Reduce stock
    UPDATE products SET stock_qty = stock_qty - 2 WHERE product_id = 101;
    UPDATE products SET stock_qty = stock_qty - 1 WHERE product_id = 205;
COMMIT;
```

### 3. Daily Data Sync (UPSERT)
```sql
-- External system sends product data daily
INSERT INTO products (sku, product_name, price, stock_qty)
VALUES ('SKU-001', 'Widget', 19.99, 500)
ON CONFLICT (sku) DO UPDATE
SET price     = EXCLUDED.price,
    stock_qty = EXCLUDED.stock_qty;
-- First run: inserts. Subsequent runs: updates.
```

### 4. Soft Delete Pattern
```sql
-- Instead of hard delete:
-- DELETE FROM employees WHERE employee_id = 3;

-- Use soft delete:
UPDATE employees
SET is_active   = FALSE,
    deleted_at  = NOW()
WHERE employee_id = 3;

-- Query only active records:
SELECT * FROM employees WHERE is_active = TRUE;
-- Or create a view:
-- CREATE VIEW active_employees AS
-- SELECT * FROM employees WHERE is_active = TRUE;
```

### 5. Archive and Purge (CTE + DELETE + INSERT)
```sql
WITH archived AS (
    DELETE FROM orders
    WHERE status = 'completed' AND order_date < CURRENT_DATE - INTERVAL '2 years'
    RETURNING *
)
INSERT INTO orders_archive
SELECT * FROM archived;
-- Moves old completed orders to archive in one atomic operation
```

### 6. Bulk Update from CSV (Staging Table Pattern)
```sql
-- Step 1: Load CSV into a temporary staging table
CREATE TEMP TABLE staging_prices (sku VARCHAR(50), new_price NUMERIC(10,2));
COPY staging_prices FROM '/path/to/prices.csv' CSV HEADER;

-- Step 2: Update the main table from staging
UPDATE products
SET price = s.new_price
FROM staging_prices s
WHERE products.sku = s.sku;

-- Step 3: Clean up
DROP TABLE staging_prices;
```

---

## Quick Reference Cheat Sheet

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         DML COMMANDS — QUICK REFERENCE                      │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  INSERT INTO table (col1, col2) VALUES (val1, val2);                        │
│  INSERT INTO table (col1, col2) VALUES (...), (...), (...);                 │
│  INSERT INTO table (col1) VALUES (val) RETURNING col1;                      │
│  INSERT INTO table (col1) VALUES (val) ON CONFLICT (col1) DO NOTHING;       │
│  INSERT INTO table (col1) VALUES (val) ON CONFLICT (col1)                   │
│      DO UPDATE SET col1 = EXCLUDED.col1;                                    │
│  INSERT INTO table1 SELECT ... FROM table2;                                 │
│                                                                              │
│  UPDATE table SET col = val WHERE condition;                                │
│  UPDATE table SET col = val FROM other_table WHERE join_condition;           │
│  UPDATE table SET col = val WHERE condition RETURNING *;                    │
│                                                                              │
│  DELETE FROM table WHERE condition;                                         │
│  DELETE FROM table USING other_table WHERE join_condition;                   │
│  DELETE FROM table WHERE condition RETURNING *;                             │
│                                                                              │
│  TRUNCATE TABLE table RESTART IDENTITY;                                     │
│  TRUNCATE TABLE table CASCADE;                                              │
│                                                                              │
├──────────────────────────────────────────────────────────────────────────────┤
│  ⚠️  Always use WHERE with UPDATE and DELETE                                │
│  ⚠️  Always test with SELECT first                                          │
│  ⚠️  Always wrap multi-step changes in BEGIN / COMMIT                       │
│  💡 Use RETURNING to avoid extra SELECT queries                             │
│  💡 Use ON CONFLICT for idempotent inserts                                  │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

*Part of the [PostgreSQL Learning Repository](../README.md) — Module 04: DML Commands*
