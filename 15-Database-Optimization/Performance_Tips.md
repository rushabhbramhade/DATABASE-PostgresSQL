# Performance Tips for PostgreSQL

> A practical guide to making your PostgreSQL database faster, more efficient, and production-ready.

---

## Table of Contents

1. [Index Wisely](#1-index-wisely)
2. [VACUUM and Autovacuum](#2-vacuum-and-autovacuum)
3. [Connection Pooling with PgBouncer](#3-connection-pooling-with-pgbouncer)
4. [Caching Strategies](#4-caching-strategies)
5. [Partitioning Large Tables](#5-partitioning-large-tables)
6. [Materialized Views for Heavy Reports](#6-materialized-views-for-heavy-reports)
7. [Batch INSERT vs Individual INSERTs](#7-batch-insert-vs-individual-inserts)
8. [COPY vs INSERT for Bulk Loading](#8-copy-vs-insert-for-bulk-loading)
9. [PostgreSQL Configuration Tuning](#9-postgresql-configuration-tuning)
10. [Monitoring Tools](#10-monitoring-tools)
11. [Quick Reference Checklist](#11-quick-reference-checklist)

---

## 1. Index Wisely

### The Golden Rule: Not Too Few, Not Too Many

| Too Few Indexes | Too Many Indexes |
|---|---|
| Queries do full table scans | Every INSERT/UPDATE/DELETE is slower |
| Response time degrades with data growth | Disk usage balloons |
| CPU spikes under load | Autovacuum takes longer |

### When to Add an Index

- Columns frequently in `WHERE` clauses
- Columns used in `JOIN ON` conditions
- Columns used in `ORDER BY` (avoids in-memory sorts)
- Columns used in `DISTINCT` or `GROUP BY`

### When NOT to Add an Index

- Tables with fewer than ~1,000 rows
- Columns with very low cardinality (e.g., `gender`, `is_active`)
- Tables that are write-heavy with rare reads

### Best Practices

```sql
-- 1. Use partial indexes to index only the rows you query
CREATE INDEX idx_orders_pending ON orders (order_date)
WHERE status = 'pending';
-- This index is smaller and faster than indexing all rows

-- 2. Use covering indexes for index-only scans
CREATE INDEX idx_emp_dept_covering ON employees (department_id)
INCLUDE (first_name, salary);

-- 3. Use expression indexes for function-based lookups
CREATE INDEX idx_customers_lower_email ON customers (LOWER(email));

-- 4. Find unused indexes and drop them
SELECT schemaname, relname, indexrelname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;
-- If idx_scan = 0 for weeks, the index is dead weight. Drop it.
```

### Index Types at a Glance

| Type | Best For | Example |
|---|---|---|
| B-tree | Equality, range, sorting (default) | `CREATE INDEX ... ON t(col)` |
| Hash | Exact equality only | `CREATE INDEX ... USING hash ON t(col)` |
| GIN | Full-text, JSONB, arrays | `CREATE INDEX ... USING gin ON t(col)` |
| GiST | Geometry, ranges, nearest-neighbor | `CREATE INDEX ... USING gist ON t(col)` |
| BRIN | Very large, naturally ordered tables | `CREATE INDEX ... USING brin ON t(created_at)` |

---

## 2. VACUUM and Autovacuum

### Why VACUUM Exists

PostgreSQL uses **MVCC** (Multi-Version Concurrency Control). When you UPDATE or DELETE a row, the old version isn't immediately removed — it becomes a **dead tuple**. VACUUM cleans up these dead tuples.

### What Happens Without VACUUM

- Table size grows endlessly (**table bloat**)
- Indexes get bloated too
- Query performance degrades
- Risk of **transaction ID wraparound** (data corruption if left unchecked!)

### VACUUM Commands

```sql
-- Standard VACUUM: reclaims dead tuples, does NOT lock the table
VACUUM orders;

-- VACUUM VERBOSE: shows progress details
VACUUM VERBOSE orders;

-- VACUUM FULL: completely rewrites the table (LOCKS table — use sparingly)
VACUUM FULL orders;

-- VACUUM + ANALYZE: reclaim space AND update statistics
VACUUM ANALYZE orders;
```

### Autovacuum Configuration

Autovacuum runs in the background automatically. Tune these settings in `postgresql.conf`:

| Setting | Default | Recommended | Purpose |
|---|---|---|---|
| `autovacuum` | `on` | `on` | **Never turn this off** |
| `autovacuum_vacuum_threshold` | 50 | 50 | Minimum dead tuples before triggering |
| `autovacuum_vacuum_scale_factor` | 0.2 | 0.05 (for large tables) | Fraction of table size that triggers vacuum |
| `autovacuum_analyze_threshold` | 50 | 50 | Minimum changes before auto-analyze |
| `autovacuum_analyze_scale_factor` | 0.1 | 0.02 (for large tables) | Fraction of table that triggers analyze |

For a table with 10 million rows and default `scale_factor = 0.2`, autovacuum won't trigger until 2 million dead tuples accumulate. Lower the scale factor for large tables:

```sql
-- Per-table autovacuum settings
ALTER TABLE orders SET (
    autovacuum_vacuum_scale_factor = 0.01,    -- trigger at 1% dead tuples
    autovacuum_analyze_scale_factor = 0.005   -- re-analyze at 0.5% changes
);
```

### Monitor Bloat

```sql
-- Check dead tuples and last vacuum time
SELECT relname,
       n_live_tup,
       n_dead_tup,
       ROUND(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 1) AS dead_pct,
       last_vacuum,
       last_autovacuum
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC
LIMIT 10;
```

---

## 3. Connection Pooling with PgBouncer

### The Problem

Each PostgreSQL connection consumes **~5–10 MB of RAM**. With 500 direct connections, that's 2.5–5 GB of RAM just for connections. Forking a new backend process also takes ~100 ms.

### The Solution: PgBouncer

```
┌─────────────┐     ┌──────────┐     ┌────────────┐
│  App Server  │────▶│ PgBouncer│────▶│ PostgreSQL │
│ (200 conns) │     │ (pool:20)│     │ (20 conns) │
└─────────────┘     └──────────┘     └────────────┘
```

### Pooling Modes

| Mode | How It Works | Best For |
|---|---|---|
| **Transaction** | Connection returned to pool after each transaction | Most web apps (recommended) |
| **Session** | Connection held for the entire client session | Apps using session-level features (prepared statements, temp tables) |
| **Statement** | Connection returned after each statement | Simple query routing (rarely used) |

### Basic PgBouncer Configuration (`pgbouncer.ini`)

```ini
[databases]
mydb = host=127.0.0.1 port=5432 dbname=mydb

[pgbouncer]
listen_addr = 0.0.0.0
listen_port = 6432
pool_mode = transaction
max_client_conn = 500
default_pool_size = 25
min_pool_size = 5
reserve_pool_size = 5
```

### Key Metrics to Monitor

```sql
-- Connect to PgBouncer's admin console
-- psql -p 6432 -U admin pgbouncer
-- SHOW POOLS;
-- SHOW STATS;
-- SHOW CLIENTS;
```

---

## 4. Caching Strategies

### Level 1 — PostgreSQL Shared Buffers (Built-in)

PostgreSQL caches frequently accessed table and index pages in `shared_buffers`.

```sql
-- Check cache hit ratio (should be > 99% for OLTP)
SELECT
    SUM(heap_blks_hit) AS cache_hits,
    SUM(heap_blks_read) AS disk_reads,
    ROUND(100.0 * SUM(heap_blks_hit) / NULLIF(SUM(heap_blks_hit) + SUM(heap_blks_read), 0), 2)
        AS cache_hit_ratio
FROM pg_statio_user_tables;
```

| Cache Hit Ratio | Status |
|---|---|
| > 99% | Excellent |
| 95–99% | Good |
| < 95% | Increase `shared_buffers` or investigate query patterns |

### Level 2 — OS Page Cache

The operating system caches file data in RAM. PostgreSQL relies heavily on this. Rule: leave **enough free RAM for the OS cache** after setting `shared_buffers`.

### Level 3 — Application-Level Cache (Redis / Memcached)

For data that doesn't change often, cache query results in your application:

```
App → Check Redis → Cache hit? Return cached result
                  → Cache miss? Query PostgreSQL → Store in Redis → Return
```

**Good candidates for application caching:**
- User profile/session data
- Product catalog listings
- Configuration settings
- Dashboard report data

---

## 5. Partitioning Large Tables

### When to Partition

- Tables exceeding **50–100 million rows**
- Queries almost always filter by a specific column (date, region, status)
- You need to drop old data efficiently (drop a partition instead of DELETE)

### Partitioning Types

| Type | Best For | Example |
|---|---|---|
| **Range** | Time-series data, dates | Monthly partitions for `order_date` |
| **List** | Fixed categories | Partition by `country` or `status` |
| **Hash** | Even distribution | Partition by `user_id` for balanced load |

### Range Partitioning Example (Most Common)

```sql
-- Step 1: Create the partitioned parent table
CREATE TABLE orders (
    order_id    SERIAL,
    customer_id INTEGER NOT NULL,
    order_date  DATE NOT NULL,
    total       NUMERIC(10,2),
    status      VARCHAR(20)
) PARTITION BY RANGE (order_date);

-- Step 2: Create partitions for each month
CREATE TABLE orders_2024_01 PARTITION OF orders
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE orders_2024_02 PARTITION OF orders
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

CREATE TABLE orders_2024_03 PARTITION OF orders
    FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');

-- Step 3: Queries automatically scan only relevant partitions
SELECT * FROM orders WHERE order_date = '2024-02-15';
-- PostgreSQL only scans orders_2024_02 (partition pruning)

-- Step 4: Dropping old data is instant
DROP TABLE orders_2024_01;  -- Instant! No slow DELETE needed.
```

### Partition Pruning Verification

```sql
-- Confirm partition pruning is working
EXPLAIN ANALYZE
SELECT * FROM orders WHERE order_date BETWEEN '2024-02-01' AND '2024-02-28';
-- Should show scans only on orders_2024_02, not all partitions
```

---

## 6. Materialized Views for Heavy Reports

### The Problem

Complex reporting queries with multiple JOINs, aggregations, and subqueries can take minutes.

### The Solution: Materialized Views

A materialized view **pre-computes and stores** the result. Subsequent reads are instant.

```sql
-- Step 1: Create the materialized view
CREATE MATERIALIZED VIEW mv_monthly_sales AS
SELECT
    DATE_TRUNC('month', o.order_date) AS month,
    p.category_id,
    COUNT(*)                          AS total_orders,
    SUM(o.total_amount)               AS total_revenue,
    AVG(o.total_amount)               AS avg_order_value
FROM orders o
JOIN products p ON p.product_id = o.product_id
GROUP BY DATE_TRUNC('month', o.order_date), p.category_id;

-- Step 2: Create an index on the materialized view
CREATE INDEX idx_mv_monthly_sales ON mv_monthly_sales (month, category_id);

-- Step 3: Query it like a regular table (instant!)
SELECT * FROM mv_monthly_sales WHERE month = '2024-06-01';

-- Step 4: Refresh when underlying data changes
REFRESH MATERIALIZED VIEW mv_monthly_sales;

-- Step 5: Refresh without blocking reads (requires a UNIQUE index)
CREATE UNIQUE INDEX idx_mv_monthly_sales_uniq
    ON mv_monthly_sales (month, category_id);
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_monthly_sales;
```

### Regular View vs Materialized View

| Feature | Regular View | Materialized View |
|---|---|---|
| Stores data | No (re-runs query each time) | Yes (cached on disk) |
| Speed | Same as the underlying query | Fast (reads pre-computed data) |
| Auto-updates | Always current | Must call `REFRESH` |
| Best for | Simple abstractions | Heavy reports, dashboards |

---

## 7. Batch INSERT vs Individual INSERTs

### Individual INSERTs (Slow)

```sql
-- ❌ 1000 separate round-trips to the database
INSERT INTO products (name, price) VALUES ('Widget A', 9.99);
INSERT INTO products (name, price) VALUES ('Widget B', 14.99);
INSERT INTO products (name, price) VALUES ('Widget C', 19.99);
-- ... 997 more statements
```

Each INSERT = 1 network round-trip + 1 transaction commit + 1 WAL flush.

### Batch INSERT (Fast)

```sql
-- ✅ Single statement, single round-trip
INSERT INTO products (name, price) VALUES
    ('Widget A', 9.99),
    ('Widget B', 14.99),
    ('Widget C', 19.99),
    -- ... up to ~1000 rows per batch
    ('Widget Z', 29.99);
```

### Wrap in a Transaction (Even Faster)

```sql
-- ✅✅ One transaction for all inserts
BEGIN;
INSERT INTO products (name, price) VALUES ('Widget A', 9.99);
INSERT INTO products (name, price) VALUES ('Widget B', 14.99);
-- ... more inserts
COMMIT;  -- Single WAL flush at the end
```

### Performance Comparison

| Method | 10,000 Rows | Relative Speed |
|---|---|---|
| Individual INSERTs (autocommit) | ~30 seconds | 1× |
| Individual INSERTs (one transaction) | ~2 seconds | 15× |
| Batch INSERT (multi-row VALUES) | ~0.5 seconds | 60× |
| COPY | ~0.1 seconds | 300× |

---

## 8. COPY vs INSERT for Bulk Loading

### COPY — The Fastest Way to Load Data

`COPY` streams data directly into the table using a binary or text protocol. It bypasses the SQL parser entirely.

```sql
-- Load from a CSV file on the SERVER
COPY products (product_name, category_id, price, stock_qty)
FROM '/tmp/products.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

-- Load from a CSV file on the CLIENT (use \copy in psql)
\copy products (product_name, category_id, price, stock_qty)
FROM 'C:/data/products.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ',');

-- Export data to CSV
COPY (SELECT * FROM products WHERE price > 100)
TO '/tmp/expensive_products.csv'
WITH (FORMAT csv, HEADER true);
```

### Tips for Maximum COPY Performance

```sql
-- 1. Drop indexes before loading, re-create after
DROP INDEX idx_products_category;
COPY products FROM '/tmp/products.csv' WITH (FORMAT csv, HEADER true);
CREATE INDEX idx_products_category ON products (category_id);

-- 2. Drop foreign key constraints, add back after loading
ALTER TABLE orders DROP CONSTRAINT fk_customer;
COPY orders FROM '/tmp/orders.csv' WITH (FORMAT csv, HEADER true);
ALTER TABLE orders ADD CONSTRAINT fk_customer
    FOREIGN KEY (customer_id) REFERENCES customers (customer_id);

-- 3. Increase maintenance_work_mem for faster index rebuilds
SET maintenance_work_mem = '1GB';
CREATE INDEX idx_products_category ON products (category_id);

-- 4. Run ANALYZE after bulk loading
ANALYZE products;
```

---

## 9. PostgreSQL Configuration Tuning

### Key Settings in `postgresql.conf`

> These are starting-point recommendations. Always benchmark for your specific workload.

#### Memory Settings

| Setting | Default | Recommendation | Purpose |
|---|---|---|---|
| `shared_buffers` | 128 MB | **25% of total RAM** (e.g., 4 GB for a 16 GB server) | Main cache for table/index pages |
| `effective_cache_size` | 4 GB | **50–75% of total RAM** (e.g., 12 GB for 16 GB) | Hint to planner about total available cache (OS + PG) |
| `work_mem` | 4 MB | **16–64 MB** (depends on concurrency) | Memory for sorts, hashes, per operation per query |
| `maintenance_work_mem` | 64 MB | **512 MB – 2 GB** | Memory for VACUUM, CREATE INDEX, ALTER TABLE |
| `huge_pages` | try | `try` or `on` (Linux) | Use OS huge pages to reduce TLB misses |

> **Warning about `work_mem`:** This is allocated **per sort/hash operation per query**. A complex query with 5 sorts uses up to `5 × work_mem`. If 100 concurrent users run such queries: `100 × 5 × 64 MB = 32 GB`. Set it conservatively for high-concurrency systems.

#### WAL and Checkpoint Settings

| Setting | Default | Recommendation | Purpose |
|---|---|---|---|
| `wal_buffers` | -1 (auto) | `64 MB` | Buffer for WAL writes |
| `checkpoint_completion_target` | 0.9 | `0.9` | Spread checkpoint I/O over time |
| `max_wal_size` | 1 GB | `2–4 GB` | Trigger checkpoint less frequently |
| `min_wal_size` | 80 MB | `512 MB` | Minimum WAL retained |

#### Query Planner Settings

| Setting | Default | Recommendation | Purpose |
|---|---|---|---|
| `random_page_cost` | 4.0 | `1.1` (SSD) / `4.0` (HDD) | Cost of a random page read |
| `effective_io_concurrency` | 1 | `200` (SSD) / `2` (HDD) | Number of concurrent I/O operations |
| `default_statistics_target` | 100 | `200–500` (for complex queries) | Number of histogram buckets for ANALYZE |

### Configuration for Common Server Sizes

| Server RAM | `shared_buffers` | `effective_cache_size` | `work_mem` | `maintenance_work_mem` |
|---|---|---|---|---|
| 4 GB | 1 GB | 3 GB | 8 MB | 256 MB |
| 16 GB | 4 GB | 12 GB | 32 MB | 1 GB |
| 64 GB | 16 GB | 48 GB | 64 MB | 2 GB |
| 128 GB | 32 GB | 96 GB | 128 MB | 2 GB |

### Useful Tool: PGTune

Use [PGTune](https://pgtune.leopard.in.ua/) to auto-generate configuration based on your hardware and workload type.

---

## 10. Monitoring Tools

### Built-in Views and Extensions

#### `pg_stat_statements` — Track Slow Queries

```sql
-- Enable the extension (add to postgresql.conf: shared_preload_libraries = 'pg_stat_statements')
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Find the top 10 slowest queries by total time
SELECT
    LEFT(query, 80) AS short_query,
    calls,
    ROUND(total_exec_time::numeric, 2) AS total_time_ms,
    ROUND(mean_exec_time::numeric, 2) AS avg_time_ms,
    rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
```

#### `pg_stat_user_tables` — Table-Level Stats

```sql
-- Find tables needing VACUUM or with high sequential scans
SELECT
    relname,
    seq_scan,
    idx_scan,
    n_live_tup,
    n_dead_tup,
    last_vacuum,
    last_analyze
FROM pg_stat_user_tables
ORDER BY seq_scan DESC
LIMIT 10;
```

#### `pg_stat_user_indexes` — Index Usage Stats

```sql
-- Find unused indexes (candidates for removal)
SELECT
    schemaname || '.' || relname AS table,
    indexrelname AS index,
    idx_scan AS times_used,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;
```

#### `pg_stat_activity` — Currently Running Queries

```sql
-- Find long-running or blocked queries
SELECT
    pid,
    now() - pg_stat_activity.query_start AS duration,
    state,
    LEFT(query, 100) AS query
FROM pg_stat_activity
WHERE state != 'idle'
  AND (now() - pg_stat_activity.query_start) > interval '5 seconds'
ORDER BY duration DESC;
```

### External Tools

| Tool | Type | Purpose |
|---|---|---|
| **pgBadger** | Log analyzer | Parses PostgreSQL logs → detailed HTML report (slow queries, errors, stats) |
| **pg_stat_monitor** | Extension | Enhanced version of `pg_stat_statements` with histograms |
| **pgHero** | Web dashboard | Real-time dashboard for query stats, index usage, space |
| **Prometheus + Grafana** | Monitoring stack | Metrics collection + beautiful dashboards |
| **pgMustard** | Plan analyzer | Paste EXPLAIN output → visual optimization suggestions |
| **explain.dalibo.com** | Web tool | Visualize EXPLAIN plans as interactive node trees |

---

## 11. Quick Reference Checklist

### Before Going to Production

| # | Check | Notes |
|---|---|---|
| 1 | Run `EXPLAIN ANALYZE` on critical queries | Ensure no unexpected Seq Scans |
| 2 | Indexes exist on all `WHERE` and `JOIN` columns | But not too many |
| 3 | Remove unused indexes | Query `pg_stat_user_indexes` for `idx_scan = 0` |
| 4 | `autovacuum` is enabled and tuned | Lower `scale_factor` for large tables |
| 5 | Connection pooler is in place | PgBouncer in transaction mode |
| 6 | `shared_buffers` set to ~25% of RAM | Not the default 128 MB! |
| 7 | `random_page_cost` = 1.1 for SSDs | Helps planner prefer index scans |
| 8 | `pg_stat_statements` enabled | Essential for finding slow queries |
| 9 | Logging configured for slow queries | `log_min_duration_statement = 500` (ms) |
| 10 | Bulk loads use `COPY`, not individual `INSERT` | 100×–300× faster |

### During Operation

| # | Check | Frequency |
|---|---|---|
| 1 | Review `pg_stat_statements` for new slow queries | Weekly |
| 2 | Check cache hit ratio (> 99%) | Weekly |
| 3 | Monitor dead tuple count and table bloat | Weekly |
| 4 | Review `pg_stat_activity` for blocked queries | Daily |
| 5 | Run `ANALYZE` after major data changes | After ETL / bulk loads |
| 6 | Refresh materialized views | Per your schedule |
| 7 | Check disk space usage for tables and indexes | Weekly |

---

**Next Steps:**
- See `Query_Optimization.md` for query-level optimization patterns
- See `EXPLAIN.sql` for hands-on practice reading query plans
