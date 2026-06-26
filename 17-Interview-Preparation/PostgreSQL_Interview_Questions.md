# 🐘 PostgreSQL-Specific Interview Questions & Answers

> 25 commonly asked PostgreSQL interview questions covering JSONB, arrays, MVCC, VACUUM, WAL, partitioning, replication, and more.

---

## 📑 Table of Contents

- [Data Types & Features (Q1–Q8)](#data-types--features)
- [Internals & Architecture (Q9–Q16)](#internals--architecture)
- [Administration & Performance (Q17–Q22)](#administration--performance)
- [PostgreSQL vs Others (Q23–Q25)](#postgresql-vs-others)

---

## Data Types & Features

### Q1. What is JSONB in PostgreSQL? How is it different from JSON?

| Feature        | `JSON`                          | `JSONB`                            |
|----------------|---------------------------------|------------------------------------|
| Storage        | Stores raw text as-is           | Stores binary parsed format        |
| Whitespace     | Preserves whitespace & key order| Does not preserve                  |
| Write speed    | Faster (no parsing overhead)    | Slightly slower                    |
| Read/Query     | Slower (reparsed each time)     | Faster (pre-parsed)               |
| Indexing       | Not supported                   | Supports GIN indexes               |

**Always prefer `JSONB`** unless you need to preserve exact JSON formatting.

```sql
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    data JSONB NOT NULL
);

INSERT INTO events (data) VALUES ('{"type": "click", "page": "/home", "duration": 3.5}');

-- Query a nested key
SELECT data->>'type' AS event_type FROM events;

-- Filter using JSONB containment
SELECT * FROM events WHERE data @> '{"type": "click"}';

-- Create a GIN index for fast JSONB queries
CREATE INDEX idx_events_data ON events USING GIN (data);
```

---

### Q2. What are JSONB operators in PostgreSQL?

| Operator    | Description                          | Example                              |
|-------------|--------------------------------------|--------------------------------------|
| `->`        | Get JSON object by key (as JSON)     | `data->'name'`                       |
| `->>`       | Get JSON object by key (as text)     | `data->>'name'`                      |
| `#>`        | Get nested object by path (as JSON)  | `data#>'{address,city}'`             |
| `#>>`       | Get nested object by path (as text)  | `data#>>'{address,city}'`            |
| `@>`        | Contains (left contains right)       | `data @> '{"role":"admin"}'`         |
| `<@`        | Contained by                         | `'{"role":"admin"}' <@ data`         |
| `?`         | Key exists                           | `data ? 'email'`                     |
| `?&`        | All keys exist                       | `data ?& array['name','email']`      |
| <code>?&#124;</code> | Any key exists              | <code>data ?&#124; array['phone','email']</code> |
| `||`        | Concatenate two JSONB values         | `data || '{"new_key": true}'`        |
| `-`         | Delete a key                         | `data - 'old_key'`                   |

---

### Q3. How do PostgreSQL arrays work?

PostgreSQL supports native array columns for any data type.

```sql
CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    name TEXT,
    skills TEXT[]                -- array of text
);

INSERT INTO students (name, skills) VALUES ('Alice', ARRAY['SQL', 'Python', 'Java']);
INSERT INTO students (name, skills) VALUES ('Bob', '{PostgreSQL,Docker}');  -- alternate syntax

-- Query: find students who know SQL
SELECT * FROM students WHERE 'SQL' = ANY(skills);

-- Query: check if array contains all values
SELECT * FROM students WHERE skills @> ARRAY['SQL', 'Python'];

-- Array functions
SELECT array_length(skills, 1) FROM students;        -- length
SELECT unnest(skills) FROM students WHERE name = 'Alice';  -- expand to rows
SELECT array_append(skills, 'Go') FROM students WHERE name = 'Alice';
```

---

### Q4. What is HSTORE in PostgreSQL?

`HSTORE` is a key-value store data type — like a flat dictionary. It predates JSONB and is useful for simple key-value pairs.

```sql
CREATE EXTENSION IF NOT EXISTS hstore;

CREATE TABLE product_attributes (
    product_id INT,
    attrs HSTORE
);

INSERT INTO product_attributes VALUES (1, 'color => red, size => XL, weight => 250g');

-- Query
SELECT attrs->'color' FROM product_attributes;          -- 'red'
SELECT * FROM product_attributes WHERE attrs ? 'size';  -- has 'size' key
SELECT * FROM product_attributes WHERE attrs @> 'color => red';
```

**HSTORE vs JSONB**: Use JSONB for nested data and standardized JSON. Use HSTORE for simple flat key-value pairs (slightly faster for flat data).

---

### Q5. What is the difference between SERIAL, BIGSERIAL, and IDENTITY?

| Type          | Data Type  | Standard       | Syntax                                  |
|---------------|------------|----------------|-----------------------------------------|
| `SERIAL`      | INTEGER    | PostgreSQL-specific | `id SERIAL PRIMARY KEY`             |
| `BIGSERIAL`   | BIGINT     | PostgreSQL-specific | `id BIGSERIAL PRIMARY KEY`          |
| `IDENTITY`    | Any integer| SQL standard (PG 10+)| `id INT GENERATED ALWAYS AS IDENTITY` |

```sql
-- Old way (SERIAL) — creates a sequence implicitly
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    item TEXT
);

-- Modern way (IDENTITY) — SQL standard, preferred
CREATE TABLE orders (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    item TEXT
);

-- GENERATED BY DEFAULT allows manual override
CREATE TABLE orders (
    id INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    item TEXT
);
```

**Recommendation**: Use `GENERATED ALWAYS AS IDENTITY` for new projects. `SERIAL` is legacy but still widely used.

---

### Q6. What are PostgreSQL sequences?

A sequence is an independent database object that generates auto-incrementing numbers. `SERIAL` creates one implicitly.

```sql
CREATE SEQUENCE order_seq START 1000 INCREMENT 1;

SELECT nextval('order_seq');   -- 1000
SELECT nextval('order_seq');   -- 1001
SELECT currval('order_seq');   -- 1001 (last value in current session)
SELECT setval('order_seq', 2000);  -- reset to 2000

-- Use in INSERT
INSERT INTO orders (id, item) VALUES (nextval('order_seq'), 'Laptop');
```

Sequences are **not rolled back** on transaction failure — gaps are expected and normal.

---

### Q7. What are generated (computed) columns in PostgreSQL?

PostgreSQL 12+ supports stored generated columns whose values are computed from other columns.

```sql
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    price NUMERIC NOT NULL,
    tax_rate NUMERIC NOT NULL DEFAULT 0.18,
    total_price NUMERIC GENERATED ALWAYS AS (price * (1 + tax_rate)) STORED
);

INSERT INTO products (price) VALUES (1000);
SELECT * FROM products;
-- id | price | tax_rate | total_price
--  1 | 1000  | 0.18     | 1180.00
```

> PostgreSQL only supports `STORED` generated columns (physically saved), not `VIRTUAL` (computed on read).

---

### Q8. What is the RETURNING clause?

`RETURNING` lets you get back data from rows affected by `INSERT`, `UPDATE`, or `DELETE` — avoiding an extra `SELECT` query.

```sql
-- Get the auto-generated ID after insert
INSERT INTO employees (name, salary) VALUES ('Alice', 75000)
RETURNING id, name;

-- Get old values after update
UPDATE employees SET salary = salary * 1.10 WHERE department = 'Engineering'
RETURNING id, name, salary AS new_salary;

-- Get deleted rows
DELETE FROM sessions WHERE expires_at < NOW()
RETURNING user_id, session_id;
```

---

## Internals & Architecture

### Q9. What is MVCC in PostgreSQL?

**MVCC (Multi-Version Concurrency Control)** is PostgreSQL's concurrency mechanism. Instead of locking rows for reads, PostgreSQL keeps multiple versions of each row.

- **Readers never block writers, writers never block readers.**
- Each transaction sees a consistent **snapshot** of the database.
- Old row versions are kept until no transaction needs them.
- `xmin` and `xmax` system columns track which transaction created/deleted each row version.

This is why PostgreSQL needs `VACUUM` — to clean up old row versions (dead tuples).

---

### Q10. What is VACUUM and why is it needed?

`VACUUM` reclaims storage occupied by dead tuples (old row versions left by MVCC).

| Command               | Effect                                                  |
|------------------------|---------------------------------------------------------|
| `VACUUM`               | Marks dead tuples as reusable, does NOT return space to OS |
| `VACUUM FULL`          | Rewrites the table, returns space to OS (locks table!)   |
| `VACUUM ANALYZE`       | Vacuum + update query planner statistics                |
| `AUTOVACUUM`           | Background daemon that runs VACUUM automatically         |

```sql
VACUUM VERBOSE employees;        -- manual vacuum with details
VACUUM ANALYZE employees;        -- vacuum + update statistics
VACUUM FULL employees;           -- reclaim space (exclusive lock!)
```

**Best practices**:
- Keep `autovacuum` enabled (it's on by default)
- Monitor `pg_stat_user_tables.n_dead_tup` for dead tuple count
- Tune `autovacuum_vacuum_threshold` and `autovacuum_vacuum_scale_factor` for busy tables

---

### Q11. What is WAL (Write-Ahead Logging)?

WAL ensures **durability** by writing changes to a log file *before* modifying actual data files.

**How it works**:
1. Transaction changes are written to WAL files first
2. WAL is flushed to disk (guaranteeing durability)
3. Actual data files (heap) are updated lazily in the background

**Benefits**:
- Crash recovery — replay WAL to restore committed transactions
- Basis for **replication** — stream WAL to replicas
- Enables **Point-in-Time Recovery (PITR)**

WAL files are stored in `pg_wal/` directory (or `pg_xlog/` in older versions).

---

### Q12. What is the difference between hot standby and streaming replication?

| Concept                 | Description                                             |
|-------------------------|---------------------------------------------------------|
| **Streaming Replication** | Continuously streams WAL records from primary to replica |
| **Hot Standby**           | Allows read-only queries on a streaming replica          |

```
Primary (read/write)  ──WAL stream──▶  Replica (read-only queries)
```

- **Synchronous replication**: Primary waits for replica to confirm WAL write (safer, slower)
- **Asynchronous replication**: Primary doesn't wait (faster, small data loss risk)

---

### Q13. What is table partitioning in PostgreSQL?

Partitioning splits a large table into smaller, manageable pieces while maintaining a single logical table.

| Strategy     | Splits by                  | Example                         |
|--------------|----------------------------|---------------------------------|
| **RANGE**    | Value ranges               | Monthly order tables            |
| **LIST**     | Specific values            | By country or region            |
| **HASH**     | Hash of column value       | Even distribution across parts  |

```sql
-- Range partitioning by date
CREATE TABLE orders (
    id BIGINT,
    order_date DATE NOT NULL,
    amount NUMERIC
) PARTITION BY RANGE (order_date);

CREATE TABLE orders_2025_q1 PARTITION OF orders
    FOR VALUES FROM ('2025-01-01') TO ('2025-04-01');

CREATE TABLE orders_2025_q2 PARTITION OF orders
    FOR VALUES FROM ('2025-04-01') TO ('2025-07-01');
```

**Benefits**: Faster queries (partition pruning), easier data management (drop old partitions), parallel query execution.

---

### Q14. What is the PostgreSQL query planner/optimizer?

PostgreSQL uses a **cost-based optimizer** that evaluates multiple execution plans and chooses the one with the lowest estimated cost.

It considers:
- Available indexes
- Table statistics (row count, data distribution, most common values)
- Join strategies (Nested Loop, Hash Join, Merge Join)
- Sequential scan vs index scan cost

```sql
-- View the query plan
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM orders WHERE customer_id = 42;
```

Key plan node types: `Seq Scan`, `Index Scan`, `Index Only Scan`, `Bitmap Heap Scan`, `Hash Join`, `Merge Join`, `Nested Loop`, `Sort`, `Aggregate`.

---

### Q15. What are PostgreSQL system columns?

Every table has hidden system columns:

| Column   | Description                                        |
|----------|----------------------------------------------------|
| `ctid`   | Physical location of the row (page, offset)        |
| `xmin`   | Transaction ID that inserted the row               |
| `xmax`   | Transaction ID that deleted/updated the row (0 if alive) |
| `cmin`   | Command ID within the inserting transaction         |
| `cmax`   | Command ID within the deleting transaction          |
| `tableoid` | OID of the table (useful with inheritance)       |

```sql
SELECT ctid, xmin, xmax, * FROM employees LIMIT 5;
```

---

### Q16. What are PostgreSQL extensions?

Extensions are pluggable modules that add functionality to PostgreSQL.

| Extension          | Purpose                                  |
|--------------------|------------------------------------------|
| `pg_stat_statements` | Track query performance statistics     |
| `pgcrypto`         | Cryptographic functions (hashing, encryption) |
| `uuid-ossp`        | Generate UUIDs                           |
| `hstore`           | Key-value data type                      |
| `postgis`          | Geographic/spatial data support          |
| `pg_trgm`          | Trigram-based text similarity & search   |
| `citext`           | Case-insensitive text type               |
| `tablefunc`        | Crosstab / pivot table functions         |

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
SELECT * FROM pg_available_extensions ORDER BY name;
```

---

## Administration & Performance

### Q17. What is pg_stat_statements?

`pg_stat_statements` is a PostgreSQL extension that tracks execution statistics of all SQL statements.

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Top 10 slowest queries by total time
SELECT query,
       calls,
       round(total_exec_time::numeric, 2) AS total_time_ms,
       round(mean_exec_time::numeric, 2) AS avg_time_ms,
       rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;

-- Reset statistics
SELECT pg_stat_statements_reset();
```

**Essential for**: Identifying slow queries, finding frequently executed queries, capacity planning, and performance tuning.

---

### Q18. How do you monitor PostgreSQL performance?

**Key system views**:

| View                       | Shows                               |
|----------------------------|--------------------------------------|
| `pg_stat_activity`         | Currently running queries and connections |
| `pg_stat_user_tables`      | Table-level read/write statistics     |
| `pg_stat_user_indexes`     | Index usage statistics               |
| `pg_stat_bgwriter`         | Background writer and checkpoint stats|
| `pg_locks`                 | Current locks in the database         |
| `pg_stat_replication`      | Replication lag and status            |

```sql
-- Find long-running queries
SELECT pid, now() - pg_stat_activity.query_start AS duration, query, state
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY duration DESC;

-- Find unused indexes
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;

-- Check table bloat (dead tuples)
SELECT relname, n_live_tup, n_dead_tup,
       round(n_dead_tup::numeric / GREATEST(n_live_tup, 1) * 100, 2) AS dead_pct
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;
```

---

### Q19. What is connection pooling and why is it important?

PostgreSQL creates a **new OS process for each connection**, which is expensive. Connection pooling maintains a pool of reusable connections.

**Popular poolers**:
- **PgBouncer** — lightweight, most popular
- **Pgpool-II** — also does load balancing and replication
- **Built-in** — application-level pooling (e.g., HikariCP for Java)

**PgBouncer modes**:

| Mode           | Behavior                                    |
|----------------|---------------------------------------------|
| Session        | Connection assigned per session (safest)    |
| Transaction    | Connection assigned per transaction (most efficient) |
| Statement      | Connection assigned per statement (limited) |

---

### Q20. What is EXPLAIN ANALYZE and how do you read it?

`EXPLAIN ANALYZE` actually executes the query and shows the real execution plan with timing.

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM orders o
JOIN customers c ON o.customer_id = c.id
WHERE c.country = 'India';
```

**Reading the output**:
- **Scan types**: `Seq Scan` (full table scan — usually bad for large tables), `Index Scan` (uses index — good)
- **actual time**: `first_row_time..total_time` in milliseconds
- **rows**: actual number of rows processed
- **Buffers**: `shared hit` (from cache) vs `shared read` (from disk)
- **Planning Time / Execution Time**: total planning and execution durations

---

### Q21. What are advisory locks in PostgreSQL?

Advisory locks are application-level locks that PostgreSQL manages but doesn't enforce — your application must check them.

```sql
-- Acquire a lock (non-blocking)
SELECT pg_try_advisory_lock(12345);   -- returns true if acquired

-- Do work...

-- Release the lock
SELECT pg_advisory_unlock(12345);

-- Session-level lock (held until session ends)
SELECT pg_advisory_lock(12345);

-- Transaction-level lock (released at end of transaction)
SELECT pg_advisory_xact_lock(12345);
```

**Use cases**: Preventing duplicate cron jobs, ensuring only one worker processes a task, application-level mutex.

---

### Q22. What is logical replication vs physical replication?

| Feature               | Physical Replication            | Logical Replication              |
|-----------------------|---------------------------------|----------------------------------|
| Replicates            | Entire cluster (byte-level)     | Specific tables/databases        |
| WAL format            | Binary WAL records              | Decoded logical changes          |
| Cross-version         | No (same major version)         | Yes                              |
| Selective             | No (all-or-nothing)             | Yes (per-table publication)      |
| Write on replica      | No                              | Yes (different tables)           |
| Use case              | HA / failover                   | Data distribution / migration    |

```sql
-- Logical Replication setup (Publisher)
CREATE PUBLICATION my_pub FOR TABLE orders, customers;

-- Subscriber
CREATE SUBSCRIPTION my_sub
    CONNECTION 'host=primary dbname=mydb'
    PUBLICATION my_pub;
```

---

## PostgreSQL vs Others

### Q23. PostgreSQL vs MySQL — key differences?

| Feature                | PostgreSQL                        | MySQL                            |
|------------------------|-----------------------------------|----------------------------------|
| SQL compliance         | Highly standards-compliant        | Less strict                      |
| MVCC                   | Native, built-in                  | InnoDB only                      |
| JSON support           | JSONB with indexing               | JSON (no binary format)          |
| Full-text search       | Built-in (`tsvector`)             | Basic (with InnoDB)              |
| Data types             | Arrays, HSTORE, ranges, custom    | More limited                     |
| Window functions       | Full support since v8.4           | Added in v8.0                    |
| Replication            | Streaming + logical               | Binary log replication           |
| Extensions             | Rich extension ecosystem          | Plugin system (more limited)     |
| Partitioning           | Declarative (PG 10+)             | Supported                        |
| License                | PostgreSQL License (permissive)   | GPL (Oracle-owned)               |
| Default isolation      | Read Committed                    | Repeatable Read                  |

---

### Q24. When would you choose PostgreSQL over NoSQL (e.g., MongoDB)?

| Choose PostgreSQL when...                   | Choose MongoDB when...                     |
|---------------------------------------------|--------------------------------------------|
| Data has clear relationships                | Schema changes frequently                  |
| ACID transactions are critical              | Horizontal scaling is a priority           |
| Complex queries and JOINs are needed        | Document-oriented data (deeply nested)     |
| You need JSONB *with* relational features   | Very high write throughput                 |
| Data integrity is paramount                 | Rapid prototyping with flexible schema     |

PostgreSQL's JSONB support means you can have the **best of both worlds** — relational integrity with document flexibility.

---

### Q25. What are the key features that make PostgreSQL stand out?

1. **Extensibility** — Custom types, operators, functions, index methods, extensions
2. **JSONB** — Full document-store capabilities within a relational database
3. **Advanced indexing** — B-tree, Hash, GIN, GiST, BRIN, SP-GiST
4. **Full SQL compliance** — CTEs, window functions, lateral joins, recursive queries
5. **Concurrency (MVCC)** — Readers never block writers
6. **Partitioning** — Declarative range, list, and hash partitioning
7. **Foreign Data Wrappers** — Query external data sources (MySQL, CSV, MongoDB, etc.)
8. **Row-Level Security** — Fine-grained access control per row
9. **Parallel Query** — Automatic parallel execution for large scans and joins
10. **Community & ecosystem** — Active development, excellent documentation, rich extensions

---

*Good luck with your PostgreSQL interviews! 🐘*
