# Query Optimization in PostgreSQL

> Learn how to write faster, more efficient SQL queries and understand how PostgreSQL processes them under the hood.

---

## Table of Contents

1. [Why Query Optimization Matters](#1-why-query-optimization-matters)
2. [How the PostgreSQL Query Planner Works](#2-how-the-postgresql-query-planner-works)
3. [Common Slow Query Patterns and Fixes](#3-common-slow-query-patterns-and-fixes)
4. [Index Strategy Guide](#4-index-strategy-guide)
5. [Query Rewriting Techniques](#5-query-rewriting-techniques)
6. [ANALYZE and VACUUM](#6-analyze-and-vacuum)
7. [Connection Pooling](#7-connection-pooling)
8. [Optimization Tips — Before and After SQL](#8-optimization-tips--before-and-after-sql)
9. [Quick Reference Checklist](#9-quick-reference-checklist)

---

## 1. Why Query Optimization Matters

A single poorly-written query can:

| Problem | Impact |
|---|---|
| Full table scan on millions of rows | Response time jumps from **5 ms → 30 seconds** |
| Missing index on a JOIN column | CPU usage spikes; other queries queue up |
| SELECT * returning unused columns | Network bandwidth wasted; more disk I/O |
| Correlated subqueries | Query runs once per row — exponentially slower |
| Unnecessary sorts and aggregations | `work_mem` overflow → disk-based sorts |

**Bottom line:** Even a small optimization can reduce query time by 10×–1000× when your tables grow.

---

## 2. How the PostgreSQL Query Planner Works

Every SQL statement goes through three stages:

```
 SQL Query
    │
    ▼
┌──────────┐     ┌──────────┐     ┌──────────┐
│  PARSER  │ ──▶ │ PLANNER  │ ──▶ │ EXECUTOR │
│          │     │(Optimizer)│     │          │
└──────────┘     └──────────┘     └──────────┘
```

### Stage 1 — Parser
- Checks SQL syntax
- Converts the query into a **parse tree** (internal representation)
- Validates table names, column names, and data types

### Stage 2 — Planner / Optimizer
- Examines **all possible execution plans** (join order, scan type, etc.)
- Estimates cost using **table statistics** (from `pg_statistic`)
- Picks the plan with the **lowest estimated cost**
- Key decisions:
  - **Seq Scan** vs **Index Scan** vs **Bitmap Index Scan**
  - **Nested Loop** vs **Hash Join** vs **Merge Join**
  - Sort method: **in-memory** vs **disk-based**

### Stage 3 — Executor
- Runs the chosen plan step by step
- Returns results to the client

### Why Statistics Matter

The planner relies on table statistics (row count, column distribution, NULL ratio) to estimate costs. If statistics are stale, the planner may choose a bad plan.

```sql
-- Update statistics for a specific table
ANALYZE employees;

-- Update statistics for all tables in the database
ANALYZE;
```

---

## 3. Common Slow Query Patterns and Fixes

### 3.1 — SELECT * (Fetch All Columns)

**Problem:** Reads every column from disk, even ones you don't need. Prevents index-only scans.

```sql
-- ❌ SLOW: Fetches all 20 columns
SELECT * FROM employees WHERE department_id = 5;

-- ✅ FAST: Fetches only what you need
SELECT first_name, last_name, salary FROM employees WHERE department_id = 5;
```

**Why it matters:**
- Wastes I/O and network bandwidth
- If an index covers `(department_id, first_name, last_name, salary)`, PostgreSQL can satisfy the optimized query without touching the table at all (index-only scan)

---

### 3.2 — Missing WHERE Clause

**Problem:** No filter means PostgreSQL reads the **entire table**.

```sql
-- ❌ SLOW: Scans all 10 million rows
SELECT first_name, salary FROM employees;

-- ✅ FAST: Scans only matching rows
SELECT first_name, salary FROM employees WHERE department_id = 3;
```

Always ask: _"Do I really need every row?"_

---

### 3.3 — Functions on Indexed Columns (Breaks the Index)

**Problem:** Wrapping an indexed column in a function prevents PostgreSQL from using the index.

```sql
-- ❌ SLOW: Index on hire_date is IGNORED
SELECT * FROM employees WHERE EXTRACT(YEAR FROM hire_date) = 2024;

-- ✅ FAST: Rewrite as a range — index on hire_date IS USED
SELECT * FROM employees
WHERE hire_date >= '2024-01-01' AND hire_date < '2025-01-01';
```

```sql
-- ❌ SLOW: Index on email is IGNORED
SELECT * FROM customers WHERE LOWER(email) = 'john@example.com';

-- ✅ FIX: Create a functional/expression index
CREATE INDEX idx_customers_email_lower ON customers (LOWER(email));
-- Now LOWER(email) = 'john@example.com' USES the index
```

---

### 3.4 — NOT IN with NULLs

**Problem:** If the subquery returns any NULL, `NOT IN` returns **no rows at all** (because `x NOT IN (..., NULL)` is always unknown/false).

```sql
-- ❌ DANGEROUS: If any manager_id is NULL, returns ZERO rows
SELECT * FROM employees
WHERE department_id NOT IN (SELECT department_id FROM departments WHERE is_active = false);

-- ✅ SAFE & FAST: Use NOT EXISTS instead
SELECT * FROM employees e
WHERE NOT EXISTS (
    SELECT 1 FROM departments d
    WHERE d.department_id = e.department_id AND d.is_active = false
);
```

**Rule of thumb:** Always prefer `NOT EXISTS` over `NOT IN` when NULLs are possible.

---

### 3.5 — OR vs UNION ALL

**Problem:** `OR` conditions on different columns often prevent index usage.

```sql
-- ❌ SLOW: PostgreSQL may do a full table scan
SELECT * FROM orders
WHERE customer_id = 100 OR product_id = 50;

-- ✅ FAST: Each branch can use its own index
SELECT * FROM orders WHERE customer_id = 100
UNION ALL
SELECT * FROM orders WHERE product_id = 50
  AND customer_id != 100;  -- avoid duplicates
```

> **Note:** Use `UNION ALL` (not `UNION`) to avoid a costly deduplication sort. Add a filter to the second query to exclude overlapping rows if needed.

---

### 3.6 — Correlated Subqueries vs JOINs

**Problem:** A correlated subquery runs once for **every row** in the outer query.

```sql
-- ❌ SLOW: Runs the subquery once per employee row
SELECT e.first_name, e.salary,
       (SELECT d.department_name FROM departments d WHERE d.department_id = e.department_id)
FROM employees e;

-- ✅ FAST: Single JOIN — runs once
SELECT e.first_name, e.salary, d.department_name
FROM employees e
JOIN departments d ON d.department_id = e.department_id;
```

| Approach | Rows Scanned (1000 employees, 10 depts) |
|---|---|
| Correlated subquery | 1000 × 10 = **10,000** |
| JOIN | 1000 + 10 = **1,010** |

---

## 4. Index Strategy Guide

### When to Create Indexes

| Scenario | Index Type |
|---|---|
| Exact match lookups (`WHERE id = 5`) | B-tree (default) |
| Range queries (`WHERE date > '2024-01-01'`) | B-tree |
| Pattern matching (`WHERE name LIKE 'Jo%'`) | B-tree (prefix only) |
| Full-text search | GIN on `tsvector` |
| JSONB field queries | GIN |
| Geospatial queries (PostGIS) | GiST |
| Array containment (`@>`, `<@`) | GIN |
| Case-insensitive lookups | Expression index: `LOWER(col)` |

### When NOT to Create Indexes

- **Small tables** (< 1,000 rows) — Seq Scan is faster
- **Columns rarely used in WHERE or JOIN** — Index maintenance cost > benefit
- **Heavily written tables with few reads** — Every INSERT/UPDATE/DELETE must update all indexes
- **Low-cardinality columns** (e.g., boolean, gender) — Index doesn't filter enough rows

### Composite Index Column Order

Put the **most selective column first**:

```sql
-- Good: department_id is very selective (100 departments)
CREATE INDEX idx_emp_dept_salary ON employees (department_id, salary);

-- This index helps:
--   WHERE department_id = 5                      ✅
--   WHERE department_id = 5 AND salary > 50000   ✅
--   WHERE salary > 50000                         ❌ (leftmost column not used)
```

### Covering Indexes (Index-Only Scans)

Include extra columns with `INCLUDE` so PostgreSQL never touches the table:

```sql
CREATE INDEX idx_orders_covering
ON orders (customer_id)
INCLUDE (order_date, total_amount);

-- This query is satisfied entirely from the index:
SELECT order_date, total_amount FROM orders WHERE customer_id = 42;
```

---

## 5. Query Rewriting Techniques

### 5.1 — Replace `HAVING` with `WHERE` (when possible)

```sql
-- ❌ SLOWER: Aggregates ALL rows, then filters
SELECT department_id, COUNT(*) AS cnt
FROM employees
GROUP BY department_id
HAVING department_id IN (1, 2, 3);

-- ✅ FASTER: Filters BEFORE aggregation
SELECT department_id, COUNT(*) AS cnt
FROM employees
WHERE department_id IN (1, 2, 3)
GROUP BY department_id;
```

### 5.2 — Use EXISTS Instead of COUNT for Existence Checks

```sql
-- ❌ SLOWER: Counts ALL matching rows
SELECT CASE WHEN COUNT(*) > 0 THEN 'Yes' ELSE 'No' END
FROM orders WHERE customer_id = 42;

-- ✅ FASTER: Stops at the first matching row
SELECT CASE WHEN EXISTS (SELECT 1 FROM orders WHERE customer_id = 42)
            THEN 'Yes' ELSE 'No' END;
```

### 5.3 — Paginate with Keyset Instead of OFFSET

```sql
-- ❌ SLOW on large offsets: PostgreSQL must scan & discard 100,000 rows
SELECT * FROM products ORDER BY id LIMIT 20 OFFSET 100000;

-- ✅ FAST: Jump directly using the last seen ID
SELECT * FROM products WHERE id > 100000 ORDER BY id LIMIT 20;
```

### 5.4 — Avoid DISTINCT When Possible

```sql
-- ❌ SLOW: Sorts all rows to remove duplicates
SELECT DISTINCT department_id FROM employees;

-- ✅ FAST: If departments table exists, query it directly
SELECT department_id FROM departments;
```

---

## 6. ANALYZE and VACUUM

### ANALYZE

Updates the table statistics used by the query planner. Without fresh statistics, the planner may choose a terrible plan.

```sql
-- Analyze a single table
ANALYZE employees;

-- Analyze the entire database
ANALYZE;

-- Check when a table was last analyzed
SELECT relname, last_analyze, last_autoanalyze
FROM pg_stat_user_tables
WHERE relname = 'employees';
```

### VACUUM

Reclaims storage from dead tuples (rows deleted or updated but not yet cleaned up).

```sql
-- Standard VACUUM: reclaims space, doesn't lock the table
VACUUM employees;

-- VACUUM FULL: rewrites the entire table, reclaims maximum space (locks table!)
VACUUM FULL employees;

-- VACUUM + ANALYZE together
VACUUM ANALYZE employees;
```

| Command | Locks Table? | Reclaims Disk? | Updates Stats? |
|---|---|---|---|
| `VACUUM` | No | Partially | No |
| `VACUUM FULL` | **Yes** | Fully | No |
| `ANALYZE` | No | No | **Yes** |
| `VACUUM ANALYZE` | No | Partially | **Yes** |

### Autovacuum

PostgreSQL runs `autovacuum` automatically in the background. You can tune it:

```sql
-- Check autovacuum status for a table
SELECT relname, n_dead_tup, last_autovacuum
FROM pg_stat_user_tables
WHERE relname = 'orders';
```

---

## 7. Connection Pooling

Opening a new PostgreSQL connection is expensive (~100 ms and significant memory). In production, use a **connection pooler** like:

| Tool | Description |
|---|---|
| **PgBouncer** | Lightweight, most popular, supports transaction/session pooling |
| **Pgpool-II** | Adds load balancing, replication, and connection pooling |
| **Built-in app pooling** | Frameworks like Django, Rails, Spring have built-in pool settings |

**Typical PgBouncer setup:**

```
App (100 connections) → PgBouncer (pool of 20) → PostgreSQL (20 connections)
```

This keeps PostgreSQL connections low and stable.

---

## 8. Optimization Tips — Before and After SQL

### Tip 1: Select Only Needed Columns

```sql
-- ❌ BEFORE
SELECT * FROM orders WHERE status = 'shipped';

-- ✅ AFTER
SELECT order_id, customer_id, total_amount FROM orders WHERE status = 'shipped';
```

### Tip 2: Add an Index for Frequent Lookups

```sql
-- ❌ BEFORE (Seq Scan — slow on 5M rows)
SELECT * FROM customers WHERE email = 'jane@example.com';

-- ✅ AFTER (Index Scan — fast)
CREATE INDEX idx_customers_email ON customers (email);
SELECT * FROM customers WHERE email = 'jane@example.com';
```

### Tip 3: Avoid Functions on Indexed Columns

```sql
-- ❌ BEFORE
SELECT * FROM employees WHERE UPPER(last_name) = 'SMITH';

-- ✅ AFTER (expression index)
CREATE INDEX idx_emp_upper_last ON employees (UPPER(last_name));
SELECT * FROM employees WHERE UPPER(last_name) = 'SMITH';
```

### Tip 4: Replace NOT IN with NOT EXISTS

```sql
-- ❌ BEFORE
SELECT * FROM products WHERE category_id NOT IN (SELECT category_id FROM discontinued);

-- ✅ AFTER
SELECT * FROM products p
WHERE NOT EXISTS (SELECT 1 FROM discontinued d WHERE d.category_id = p.category_id);
```

### Tip 5: Use JOIN Instead of Correlated Subquery

```sql
-- ❌ BEFORE
SELECT o.order_id,
       (SELECT c.name FROM customers c WHERE c.id = o.customer_id)
FROM orders o;

-- ✅ AFTER
SELECT o.order_id, c.name
FROM orders o
JOIN customers c ON c.id = o.customer_id;
```

### Tip 6: Use EXISTS Instead of COUNT for Checking Existence

```sql
-- ❌ BEFORE
SELECT department_id FROM departments d
WHERE (SELECT COUNT(*) FROM employees e WHERE e.department_id = d.department_id) > 0;

-- ✅ AFTER
SELECT department_id FROM departments d
WHERE EXISTS (SELECT 1 FROM employees e WHERE e.department_id = d.department_id);
```

### Tip 7: Use Keyset Pagination Instead of OFFSET

```sql
-- ❌ BEFORE
SELECT * FROM logs ORDER BY created_at DESC LIMIT 50 OFFSET 500000;

-- ✅ AFTER (pass the last seen timestamp from the previous page)
SELECT * FROM logs
WHERE created_at < '2024-06-15 10:30:00'
ORDER BY created_at DESC
LIMIT 50;
```

### Tip 8: Batch Small Queries Into One

```sql
-- ❌ BEFORE (3 round-trips to the database)
SELECT * FROM products WHERE id = 1;
SELECT * FROM products WHERE id = 2;
SELECT * FROM products WHERE id = 3;

-- ✅ AFTER (1 round-trip)
SELECT * FROM products WHERE id IN (1, 2, 3);
```

### Tip 9: Use UNION ALL Instead of UNION When Duplicates Don't Matter

```sql
-- ❌ BEFORE (sorts entire result set to remove duplicates)
SELECT name FROM employees UNION SELECT name FROM contractors;

-- ✅ AFTER (no deduplication sort)
SELECT name FROM employees UNION ALL SELECT name FROM contractors;
```

### Tip 10: Filter Before Aggregating

```sql
-- ❌ BEFORE
SELECT department_id, AVG(salary)
FROM employees
GROUP BY department_id
HAVING department_id != 99;

-- ✅ AFTER
SELECT department_id, AVG(salary)
FROM employees
WHERE department_id != 99
GROUP BY department_id;
```

---

## 9. Quick Reference Checklist

| # | Check | Done? |
|---|---|---|
| 1 | Use specific columns instead of `SELECT *` | ☐ |
| 2 | Every `WHERE` / `JOIN` column has an appropriate index | ☐ |
| 3 | No functions wrapping indexed columns (or expression index exists) | ☐ |
| 4 | `NOT EXISTS` used instead of `NOT IN` | ☐ |
| 5 | JOINs used instead of correlated subqueries | ☐ |
| 6 | `EXPLAIN ANALYZE` run on slow queries | ☐ |
| 7 | `ANALYZE` run after bulk data changes | ☐ |
| 8 | `VACUUM` scheduled or autovacuum properly configured | ☐ |
| 9 | Pagination uses keyset, not large OFFSET | ☐ |
| 10 | Connection pooler in place for production | ☐ |

---

**Next Steps:**
- See `EXPLAIN.sql` to learn how to read query plans
- See `Performance_Tips.md` for server-level tuning and advanced strategies
