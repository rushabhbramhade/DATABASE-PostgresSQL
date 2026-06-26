-- ============================================================
-- Topic:  Index Performance — EXPLAIN, Scan Types & Maintenance
-- File:   Performance_Examples.sql
-- ============================================================
-- This file covers:
--   • EXPLAIN and EXPLAIN ANALYZE — reading query plans
--   • Sequential Scan (Seq Scan) vs Index Scan
--   • Covering indexes (INCLUDE clause)
--   • Index-Only Scan
--   • When PostgreSQL ignores an index
--   • REINDEX, index bloat, and vacuuming
--   • Performance tradeoffs: read speed vs write overhead
-- ============================================================
-- Sample table used throughout this file:
--
-- We'll use a larger "products" table to make performance
-- differences visible. Small tables (< ~1000 rows) often
-- use Seq Scan regardless of indexes.
--
-- products table:
-- | product_id | product_name     | category    | price  | stock_qty | created_at | is_available |
-- |------------|------------------|-------------|--------|-----------|------------|--------------|
-- | 1          | Wireless Mouse   | Electronics | 29.99  | 150       | 2024-01-05 | TRUE         |
-- | 2          | USB-C Cable      | Electronics | 12.50  | 500       | 2024-01-10 | TRUE         |
-- | 3          | Notebook A5      | Stationery  | 5.99   | 1000      | 2024-02-01 | TRUE         |
-- | 4          | Mechanical KB    | Electronics | 89.99  | 75        | 2024-02-15 | TRUE         |
-- | 5          | Desk Lamp        | Furniture   | 45.00  | 200       | 2024-03-01 | FALSE        |
-- | ...        | (many more rows) | ...         | ...    | ...       | ...        | ...          |
-- ============================================================

-- Create sample table
CREATE TABLE IF NOT EXISTS products (
    product_id   SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category     VARCHAR(50),
    price        NUMERIC(10,2),
    stock_qty    INTEGER DEFAULT 0,
    created_at   DATE DEFAULT CURRENT_DATE,
    is_available BOOLEAN DEFAULT TRUE
);

-- Insert enough rows to demonstrate index behavior.
-- PostgreSQL prefers Seq Scan on tiny tables, so we generate data.
INSERT INTO products (product_name, category, price, stock_qty, created_at, is_available)
SELECT
    'Product ' || gs                                              AS product_name,
    (ARRAY['Electronics','Stationery','Furniture','Clothing','Food'])[1 + (gs % 5)]
                                                                   AS category,
    ROUND((RANDOM() * 500 + 1)::NUMERIC, 2)                       AS price,
    (RANDOM() * 1000)::INTEGER                                     AS stock_qty,
    '2023-01-01'::DATE + (gs % 730)                                AS created_at,
    (gs % 10 != 0)                                                 AS is_available
FROM generate_series(1, 100000) gs
ON CONFLICT DO NOTHING;

-- Update planner statistics so EXPLAIN gives realistic plans:
ANALYZE products;


-- ************************************************************
-- 1. EXPLAIN — Understanding the Query Plan
-- ************************************************************
-- EXPLAIN shows what PostgreSQL PLANS to do (without running the query).
-- EXPLAIN ANALYZE actually RUNS the query and shows real timings.
--
-- Key output fields:
--   • Seq Scan       — reads every row (table scan)
--   • Index Scan     — uses an index to find rows, then fetches from table
--   • Index Only Scan — uses an index WITHOUT touching the table
--   • Bitmap Index Scan — builds a bitmap of matching pages, then reads them
--   • cost=X..Y      — estimated startup cost..total cost (arbitrary units)
--   • rows=N         — estimated number of rows returned
--   • actual time    — real execution time (only with ANALYZE)

-- Basic EXPLAIN (no execution):
EXPLAIN
SELECT * FROM products WHERE category = 'Electronics';

-- Expected Output (before creating an index):
-- Seq Scan on products  (cost=0.00..2137.00 rows=20000 width=52)
--   Filter: ((category)::text = 'Electronics'::text)
--
-- The "Seq Scan" means PostgreSQL is reading ALL 100,000 rows
-- and filtering out non-Electronics rows. This is slow on large tables.

-- EXPLAIN ANALYZE (actually runs the query):
EXPLAIN ANALYZE
SELECT * FROM products WHERE category = 'Electronics';

-- Expected Output (before index):
-- Seq Scan on products  (cost=0.00..2137.00 rows=20000 width=52)
--                       (actual time=0.012..15.432 rows=20000 loops=1)
--   Filter: ((category)::text = 'Electronics'::text)
--   Rows Removed by Filter: 80000
-- Planning Time: 0.085 ms
-- Execution Time: 16.234 ms
--
-- Note "Rows Removed by Filter: 80000" — it read 100K rows to find 20K.

-- EXPLAIN with more detail:
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM products WHERE category = 'Electronics';

-- This adds buffer hit/read info showing I/O patterns:
-- Buffers: shared hit=1137
-- → Tells you if data came from cache (hit) or disk (read).


-- ************************************************************
-- 2. Without Index (Seq Scan) vs With Index (Index Scan)
-- ************************************************************

-- ─── Step 1: Query WITHOUT an index ───
EXPLAIN ANALYZE
SELECT product_id, product_name, price
FROM products
WHERE category = 'Furniture';

-- Expected Plan (NO index):
-- Seq Scan on products  (cost=0.00..2137.00 rows=20000 width=30)
--                       (actual time=0.015..14.567 rows=20000 loops=1)
--   Filter: ((category)::text = 'Furniture'::text)
--   Rows Removed by Filter: 80000
-- Execution Time: ~15 ms

-- ─── Step 2: Create an index ───
CREATE INDEX idx_products_category ON products (category);
ANALYZE products;

-- ─── Step 3: Same query WITH the index ───
EXPLAIN ANALYZE
SELECT product_id, product_name, price
FROM products
WHERE category = 'Furniture';

-- Expected Plan (WITH index):
-- Bitmap Heap Scan on products  (cost=235.00..1425.00 rows=20000 width=30)
--                               (actual time=2.345..8.123 rows=20000 loops=1)
--   Recheck Cond: ((category)::text = 'Furniture'::text)
--   ->  Bitmap Index Scan on idx_products_category  (cost=0.00..230.00 rows=20000 width=0)
--         Index Cond: ((category)::text = 'Furniture'::text)
-- Execution Time: ~9 ms
--
-- Why Bitmap Scan instead of Index Scan?
-- When a large portion of the table matches (20%), PostgreSQL
-- uses Bitmap Scan — it's more efficient than Index Scan for
-- fetching many rows. Index Scan is used for higher selectivity.

-- ─── Step 4: High-selectivity query → Index Scan ───
EXPLAIN ANALYZE
SELECT product_id, product_name, price
FROM products
WHERE category = 'Electronics'
  AND price > 490;

-- Expected Plan (high selectivity):
-- Index Scan using idx_products_category on products
--     (cost=0.29..45.67 rows=200 width=30)
--     (actual time=0.032..0.567 rows=198 loops=1)
--   Index Cond: ((category)::text = 'Electronics'::text)
--   Filter: (price > 490)
-- Execution Time: ~0.8 ms
--
-- Now it's a true Index Scan — only ~200 rows match,
-- so jumping via the index is much faster than scanning everything.


-- ************************************************************
-- 3. Covering Index with INCLUDE clause
-- ************************************************************
-- A covering index includes extra columns that are NOT part of
-- the search key but ARE needed in the query's SELECT list.
-- This enables an "Index-Only Scan" — PostgreSQL reads ONLY
-- the index and never touches the table heap.
--
-- Syntax:
--   CREATE INDEX idx ON table (search_columns) INCLUDE (extra_columns);

CREATE INDEX idx_products_category_covering
ON products (category) INCLUDE (product_name, price);

-- Now the index contains: category (for searching) + product_name, price (for output)

-- Ensure the visibility map is up to date (needed for index-only scans):
VACUUM products;

EXPLAIN ANALYZE
SELECT product_name, price
FROM products
WHERE category = 'Stationery';

-- Expected Plan:
-- Index Only Scan using idx_products_category_covering on products
--     (cost=0.42..534.42 rows=20000 width=22)
--     (actual time=0.028..4.123 rows=20000 loops=1)
--   Index Cond: (category = 'Stationery'::text)
--   Heap Fetches: 0
-- Execution Time: ~5 ms
--
-- Key indicator: "Heap Fetches: 0"
-- PostgreSQL answered the entire query from the index alone!
-- This is the fastest scan type — no table access at all.
--
-- Without INCLUDE, the index has only 'category', so PostgreSQL
-- must visit the table to get product_name and price (Index Scan,
-- not Index Only Scan).


-- ************************************************************
-- 4. Index-Only Scan — Deep Dive
-- ************************************************************
-- Requirements for an Index-Only Scan:
--   1. ALL columns in SELECT must be in the index (key + INCLUDE)
--   2. ALL columns in WHERE must be in the index key
--   3. The table must be recently VACUUMed (visibility map must be current)
--
-- If these conditions aren't met, PostgreSQL falls back to
-- a regular Index Scan (which still reads the table).

-- ✅ Index-Only Scan (all needed columns are in the covering index):
EXPLAIN ANALYZE
SELECT category, price
FROM products
WHERE category = 'Food';

-- Expected: Index Only Scan using idx_products_category_covering
-- Heap Fetches: 0 (if recently vacuumed)

-- ❌ Regular Index Scan (stock_qty is NOT in the index):
EXPLAIN ANALYZE
SELECT product_name, price, stock_qty
FROM products
WHERE category = 'Food';

-- Expected: Index Scan using idx_products_category (or Bitmap Heap Scan)
-- PostgreSQL must access the table to get stock_qty.

-- Tip: After heavy INSERT/UPDATE/DELETE, run VACUUM to update
-- the visibility map. Without it, even a covering index will
-- show "Heap Fetches: N" because PostgreSQL must check if each
-- tuple is visible to the current transaction.


-- ************************************************************
-- 5. When PostgreSQL IGNORES an Index
-- ************************************************************
-- PostgreSQL's query planner is smart. It may CHOOSE NOT to use
-- an index even if one exists. Here's when and why:

-- ─── 5a. Low selectivity — too many rows match ───
-- If the query returns a large % of the table, Seq Scan is faster.
CREATE INDEX idx_products_available ON products (is_available);
ANALYZE products;

EXPLAIN ANALYZE
SELECT * FROM products WHERE is_available = TRUE;

-- Expected: Seq Scan (not Index Scan)
-- ~90% of rows have is_available = TRUE.
-- Reading the whole table sequentially is faster than bouncing
-- between the index and the table for 90,000 rows.

-- ─── 5b. Function on indexed column prevents index use ───
CREATE INDEX idx_products_name ON products (product_name);

EXPLAIN ANALYZE
SELECT * FROM products WHERE UPPER(product_name) = 'PRODUCT 500';

-- Expected: Seq Scan on products
-- The index is on product_name, but the query uses UPPER(product_name).
-- PostgreSQL doesn't know that UPPER('Product 500') = 'PRODUCT 500'.
-- Fix: Create an expression index ON (UPPER(product_name)).

-- ─── 5c. Using != or NOT IN ───
EXPLAIN ANALYZE
SELECT * FROM products WHERE category != 'Electronics';

-- Expected: Seq Scan
-- != typically matches most rows, so an index isn't helpful.

-- ─── 5d. LIKE with leading wildcard ───
EXPLAIN ANALYZE
SELECT * FROM products WHERE product_name LIKE '%500';

-- Expected: Seq Scan
-- B-Tree indexes require a known prefix. '%500' could start
-- with anything, so the index can't be used.
-- Fix: Use pg_trgm extension with a GIN index for pattern matching.

-- ─── 5e. Type mismatch / implicit casting ───
-- If the column is VARCHAR but you compare with an INTEGER,
-- PostgreSQL may cast the column, preventing index use.

-- ─── Summary: Reasons PostgreSQL Ignores Indexes ───
-- | Reason                        | Solution                                |
-- |-------------------------------|-----------------------------------------|
-- | Low selectivity (many matches)| Accept Seq Scan — it's actually faster  |
-- | Function on column            | Expression index: INDEX ON (func(col))  |
-- | Leading wildcard LIKE         | pg_trgm GIN index                       |
-- | != or NOT IN                  | Restructure query if possible            |
-- | Type mismatch                 | Ensure matching types in comparisons     |
-- | Table not analyzed            | Run ANALYZE                             |
-- | Stale statistics              | Run ANALYZE or enable autovacuum        |


-- ************************************************************
-- 6. REINDEX — Rebuilding Indexes
-- ************************************************************
-- Over time, indexes can become "bloated" — they contain dead
-- entries from deleted/updated rows. REINDEX rebuilds them cleanly.
--
-- Syntax:
--   REINDEX INDEX index_name;        -- single index
--   REINDEX TABLE table_name;        -- all indexes on a table
--   REINDEX DATABASE database_name;  -- all indexes in the database

-- Rebuild a specific index:
REINDEX INDEX idx_products_category;

-- Rebuild ALL indexes on the products table:
REINDEX TABLE products;

-- Non-blocking rebuild (PostgreSQL 12+):
REINDEX (CONCURRENTLY) TABLE products;
-- Like CREATE INDEX CONCURRENTLY, this doesn't lock the table.

-- Check index size before and after REINDEX to see bloat reduction:
SELECT
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes
WHERE tablename = 'products'
ORDER BY pg_relation_size(indexname::regclass) DESC;

-- Expected Output (example):
-- | indexname                          | index_size |
-- |------------------------------------|------------|
-- | idx_products_category_covering     | 3576 kB    |
-- | idx_products_category              | 792 kB     |
-- | products_pkey                      | 2208 kB    |
-- | idx_products_name                  | 4152 kB    |
-- | idx_products_available             | 272 kB     |


-- ************************************************************
-- 7. Index Bloat — Detection and Prevention
-- ************************************************************
-- Index bloat happens when:
--   • Many rows are deleted or updated
--   • Dead tuples remain in the index until VACUUM cleans them
--   • The index grows larger than necessary
--
-- Detection: compare actual index size to expected size:

SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size,
    idx_scan AS times_index_used,
    idx_tup_read AS tuples_read_from_index,
    idx_tup_fetch AS tuples_fetched_from_table
FROM pg_stat_user_indexes
WHERE tablename = 'products'
ORDER BY idx_scan DESC;

-- This shows how often each index is actually used.
-- If times_index_used = 0, the index is dead weight — consider dropping it.

-- Prevention:
--   • Ensure autovacuum is enabled and properly tuned
--   • Run VACUUM ANALYZE periodically on busy tables
--   • Use REINDEX CONCURRENTLY after heavy bulk operations
VACUUM ANALYZE products;


-- ************************************************************
-- 8. Performance Tradeoffs: Read Speed vs Write Overhead
-- ************************************************************
-- Every index speeds up reads but slows down writes.
-- Here's a practical demonstration of the tradeoff.

-- ─── Measure INSERT speed WITHOUT extra indexes ───
-- First, drop non-essential indexes to measure baseline write speed:
DROP INDEX IF EXISTS idx_products_category;
DROP INDEX IF EXISTS idx_products_category_covering;
DROP INDEX IF EXISTS idx_products_name;
DROP INDEX IF EXISTS idx_products_available;

EXPLAIN ANALYZE
INSERT INTO products (product_name, category, price, stock_qty)
SELECT
    'Bulk Product ' || gs,
    'Clothing',
    ROUND((RANDOM() * 100)::NUMERIC, 2),
    (RANDOM() * 500)::INTEGER
FROM generate_series(1, 10000) gs;

-- Expected: Insert on products
--           actual time=0.100..55.432 rows=10000
-- Execution Time: ~55 ms  (just the PK index to maintain)

-- ─── Recreate all indexes ───
CREATE INDEX idx_products_category ON products (category);
CREATE INDEX idx_products_name ON products (product_name);
CREATE INDEX idx_products_available ON products (is_available);
CREATE INDEX idx_products_category_covering
ON products (category) INCLUDE (product_name, price);
ANALYZE products;

-- ─── Measure INSERT speed WITH extra indexes ───
EXPLAIN ANALYZE
INSERT INTO products (product_name, category, price, stock_qty)
SELECT
    'Indexed Bulk ' || gs,
    'Electronics',
    ROUND((RANDOM() * 100)::NUMERIC, 2),
    (RANDOM() * 500)::INTEGER
FROM generate_series(1, 10000) gs;

-- Expected: Insert on products
--           actual time=0.200..120.567 rows=10000
-- Execution Time: ~120 ms  (4 extra indexes to maintain!)
--
-- ~2x slower! Each INSERT now updates 5 indexes (PK + 4 extra).
-- This is why over-indexing is dangerous on write-heavy tables.

-- ─── The Tradeoff Rule ───
-- | More Indexes → | Faster SELECTs | Slower INSERTs/UPDATEs/DELETEs |
-- |                | Faster JOINs   | More disk space consumed       |
-- |                | Faster ORDER BY| Longer VACUUM times            |
--
-- | Fewer Indexes →| Slower SELECTs | Faster writes                  |
-- |                |                | Less disk space                 |
-- |                |                | Simpler maintenance             |


-- ============================================================
-- SCAN TYPE REFERENCE
-- ============================================================
--
-- | Scan Type          | What It Does                                         | When Used                           |
-- |--------------------|------------------------------------------------------|-------------------------------------|
-- | Seq Scan           | Reads every row in the table                         | No index, or low selectivity        |
-- | Index Scan         | Uses index to find rows, fetches data from table     | High selectivity, index exists      |
-- | Index Only Scan    | Reads only the index, never touches the table        | Covering index + recent VACUUM      |
-- | Bitmap Index Scan  | Builds a bitmap of matching pages, then reads them   | Medium selectivity, many matches    |
-- | Bitmap Heap Scan   | Second step of Bitmap scan — reads actual table pages | Always paired with Bitmap Index Scan|
--
-- ============================================================


-- ============================================================
-- MAINTENANCE CHECKLIST
-- ============================================================
--
-- 1. Run ANALYZE after bulk data loads to update planner statistics.
-- 2. Run VACUUM regularly (or rely on autovacuum) to reclaim space
--    and update the visibility map for index-only scans.
-- 3. Use REINDEX (CONCURRENTLY) after heavy UPDATE/DELETE cycles
--    to reduce index bloat.
-- 4. Monitor unused indexes via pg_stat_user_indexes — drop them!
-- 5. Don't create indexes "just in case" — each one has a cost.
-- 6. Use EXPLAIN ANALYZE to verify your indexes are actually used.
--
-- ============================================================


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. EXPLAIN shows the planned execution strategy;
--    EXPLAIN ANALYZE shows actual execution with real timings.
-- 2. Seq Scan reads every row — it's the baseline (no index).
--    Index Scan uses the index — much faster for selective queries.
-- 3. Covering indexes (INCLUDE clause) enable Index-Only Scans,
--    the fastest scan type — no table access needed.
-- 4. PostgreSQL may IGNORE your index if selectivity is low,
--    a function wraps the column, or statistics are stale.
-- 5. REINDEX rebuilds bloated indexes; VACUUM updates visibility.
-- 6. Every index speeds up reads but slows down writes.
--    Find the right balance for your workload.
-- 7. Monitor index usage with pg_stat_user_indexes and drop
--    unused indexes to reduce write overhead and disk usage.
-- 8. Always run ANALYZE after bulk data loads so the planner
--    has accurate statistics for choosing the right plan.
-- ============================================================
