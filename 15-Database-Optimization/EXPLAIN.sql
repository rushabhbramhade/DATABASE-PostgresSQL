-- ============================================================================
-- EXPLAIN — Understanding PostgreSQL Query Execution Plans
-- ============================================================================
-- EXPLAIN shows HOW PostgreSQL will execute your query.
-- EXPLAIN ANALYZE actually RUNS the query and shows real timings.
-- Use these tools to find slow parts of your queries and fix them.
--
-- Sample Tables Used:
--   employees   (employee_id, first_name, last_name, email, salary,
--                department_id, hire_date, manager_id)
--   departments (department_id, department_name, location)
--   orders      (order_id, customer_id, product_id, order_date,
--                total_amount, status)
--   customers   (customer_id, name, email, city, created_at)
--   products    (product_id, product_name, category_id, price, stock_qty)
-- ============================================================================


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  1. BASIC EXPLAIN — Shows the Plan Without Running the Query            ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- EXPLAIN only ESTIMATES — it does NOT execute the query.
-- Safe to run on production, even on DELETE/UPDATE statements.

EXPLAIN
SELECT first_name, salary
FROM employees
WHERE department_id = 5;

-- Expected Output (example):
-- ┌──────────────────────────────────────────────────────────────────────┐
-- │                          QUERY PLAN                                 │
-- ├──────────────────────────────────────────────────────────────────────┤
-- │ Seq Scan on employees  (cost=0.00..35.50 rows=10 width=22)         │
-- │   Filter: (department_id = 5)                                      │
-- └──────────────────────────────────────────────────────────────────────┘
--
-- Reading the output:
--   Seq Scan       → Sequential scan (reads every row in the table)
--   cost=0.00      → Startup cost (time before first row is returned)
--   ..35.50        → Total cost (arbitrary units, not seconds)
--   rows=10        → Estimated number of rows returned
--   width=22       → Average width of each row in bytes
--   Filter:        → Condition applied row-by-row during the scan


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  2. EXPLAIN ANALYZE — Runs the Query and Shows ACTUAL Timings           ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- WARNING: EXPLAIN ANALYZE actually EXECUTES the query.
-- For INSERT/UPDATE/DELETE, wrap in a transaction and ROLLBACK!

EXPLAIN ANALYZE
SELECT first_name, salary
FROM employees
WHERE department_id = 5;

-- Expected Output (example):
-- ┌──────────────────────────────────────────────────────────────────────────────────┐
-- │                              QUERY PLAN                                         │
-- ├──────────────────────────────────────────────────────────────────────────────────┤
-- │ Seq Scan on employees  (cost=0.00..35.50 rows=10 width=22)                     │
-- │                        (actual time=0.015..0.250 rows=12 loops=1)               │
-- │   Filter: (department_id = 5)                                                   │
-- │   Rows Removed by Filter: 988                                                   │
-- │ Planning Time: 0.080 ms                                                         │
-- │ Execution Time: 0.290 ms                                                        │
-- └──────────────────────────────────────────────────────────────────────────────────┘
--
-- New fields from ANALYZE:
--   actual time=0.015..0.250  → Real time in milliseconds (startup..total)
--   rows=12                   → Actual rows returned (vs estimated 10)
--   loops=1                   → How many times this node executed
--   Rows Removed by Filter    → Rows read but discarded (988 wasted reads!)
--   Planning Time              → Time spent choosing the plan
--   Execution Time             → Total wall-clock time to run


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  3. SCAN TYPES — Seq Scan vs Index Scan vs Bitmap Scan                  ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- 3a. Sequential Scan (Seq Scan)
-- Reads the ENTIRE table row by row. Used when no useful index exists
-- or the query returns a large fraction of the table.

EXPLAIN ANALYZE
SELECT * FROM employees;

-- Output:
--   Seq Scan on employees  (cost=0.00..22.00 rows=1000 width=64)
--                          (actual time=0.009..0.180 rows=1000 loops=1)


-- 3b. Index Scan
-- Looks up matching rows using an index, then fetches the full row
-- from the table. Best for highly selective queries (few matching rows).

-- First, create the index:
-- CREATE INDEX idx_employees_dept ON employees (department_id);

EXPLAIN ANALYZE
SELECT first_name, salary
FROM employees
WHERE department_id = 5;

-- Output (with index):
--   Index Scan using idx_employees_dept on employees
--       (cost=0.28..8.30 rows=10 width=22)
--       (actual time=0.020..0.035 rows=12 loops=1)
--     Index Cond: (department_id = 5)
--
-- Key difference: "Index Cond" instead of "Filter"
-- "Index Cond" = rows are found efficiently via the index
-- "Filter"     = rows are found by reading every row and checking


-- 3c. Index Only Scan
-- Satisfies the query entirely from the index — never touches the table.
-- Possible when all selected columns are in the index.

-- CREATE INDEX idx_emp_dept_salary ON employees (department_id, salary);

EXPLAIN ANALYZE
SELECT department_id, salary
FROM employees
WHERE department_id = 5;

-- Output:
--   Index Only Scan using idx_emp_dept_salary on employees
--       (cost=0.28..4.50 rows=10 width=12)
--       (actual time=0.018..0.025 rows=12 loops=1)
--     Index Cond: (department_id = 5)
--     Heap Fetches: 0         ← Zero table lookups! Fastest possible scan.


-- 3d. Bitmap Index Scan + Bitmap Heap Scan
-- A two-step process: first builds a bitmap of matching row locations,
-- then fetches them in physical order. Used for medium-selectivity queries.

EXPLAIN ANALYZE
SELECT * FROM orders
WHERE total_amount > 500 AND total_amount < 1000;

-- Output:
--   Bitmap Heap Scan on orders  (cost=12.50..120.30 rows=500 width=48)
--                               (actual time=0.300..1.200 rows=480 loops=1)
--     Recheck Cond: (total_amount > 500 AND total_amount < 1000)
--     Heap Blocks: exact=85
--     ->  Bitmap Index Scan on idx_orders_amount
--             (cost=0.00..12.38 rows=500 width=0)
--             (actual time=0.250..0.250 rows=480 loops=1)
--           Index Cond: (total_amount > 500 AND total_amount < 1000)


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  4. JOIN TYPES — Nested Loop, Hash Join, Merge Join                     ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- 4a. Nested Loop Join
-- For each row in the outer table, scans the inner table.
-- Best when the outer table is small or inner table has an index.

EXPLAIN ANALYZE
SELECT e.first_name, d.department_name
FROM employees e
JOIN departments d ON d.department_id = e.department_id
WHERE e.salary > 90000;

-- Output (example):
--   Nested Loop  (cost=0.28..50.60 rows=5 width=30)
--                (actual time=0.030..0.120 rows=8 loops=1)
--     ->  Seq Scan on employees e  (cost=0.00..35.50 rows=5 width=18)
--           Filter: (salary > 90000)
--     ->  Index Scan using departments_pkey on departments d
--             (cost=0.14..0.16 rows=1 width=20)
--           Index Cond: (department_id = e.department_id)
--
-- The planner chose Nested Loop because the salary filter makes the
-- outer set small (5 rows), and the inner lookup uses a primary key index.


-- 4b. Hash Join
-- Builds a hash table from the smaller table, then probes it with
-- each row from the larger table. Best for larger joins without indexes.

EXPLAIN ANALYZE
SELECT o.order_id, c.name
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id;

-- Output (example):
--   Hash Join  (cost=30.00..250.00 rows=5000 width=28)
--              (actual time=0.500..5.200 rows=5000 loops=1)
--     Hash Cond: (o.customer_id = c.customer_id)
--     ->  Seq Scan on orders o  (cost=0.00..150.00 rows=5000 width=12)
--     ->  Hash  (cost=20.00..20.00 rows=800 width=20)
--           Buckets: 1024  Batches: 1  Memory Usage: 48kB
--           ->  Seq Scan on customers c  (cost=0.00..20.00 rows=800 width=20)
--
-- The smaller table (customers, 800 rows) is hashed in memory.
-- Each order row is then matched using the hash table.


-- 4c. Merge Join
-- Both inputs are sorted on the join key, then merged in one pass.
-- Very efficient when both sides are already sorted (e.g., indexed).

EXPLAIN ANALYZE
SELECT e.first_name, d.department_name
FROM employees e
JOIN departments d ON d.department_id = e.department_id
ORDER BY e.department_id;

-- Output (example):
--   Merge Join  (cost=70.00..90.00 rows=1000 width=30)
--     Merge Cond: (e.department_id = d.department_id)
--     ->  Sort  (cost=60.00..62.50 rows=1000 width=18)
--           Sort Key: e.department_id
--           ->  Seq Scan on employees e
--     ->  Sort  (cost=1.50..1.75 rows=10 width=20)
--           Sort Key: d.department_id
--           ->  Seq Scan on departments d


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  5. EXPLAIN WITH BUFFERS — See I/O Details                              ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- BUFFERS shows how many 8 KB pages were read from cache vs disk.

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders
WHERE customer_id = 42;

-- Output (example):
--   Index Scan using idx_orders_customer on orders
--       (cost=0.29..8.31 rows=5 width=48)
--       (actual time=0.020..0.040 rows=5 loops=1)
--     Index Cond: (customer_id = 42)
--     Buffers: shared hit=4          ← 4 pages read from shared_buffers (cache)
--   Planning Time: 0.060 ms
--   Execution Time: 0.065 ms
--
-- Buffer terminology:
--   shared hit    → Pages found in PostgreSQL's shared buffer cache (fast)
--   shared read   → Pages read from OS disk cache or disk (slower)
--   shared written → Dirty pages written to disk during the query
--   temp read/written → Temp files used (means work_mem was too small!)


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  6. EXPLAIN FORMAT JSON — Machine-Readable Output                       ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- JSON format is useful for programmatic analysis or pasting into
-- visualization tools like https://explain.dalibo.com/

EXPLAIN (ANALYZE, FORMAT JSON)
SELECT e.first_name, d.department_name
FROM employees e
JOIN departments d ON d.department_id = e.department_id
WHERE e.salary > 60000;

-- Output is a JSON array with nested plan nodes:
-- [
--   {
--     "Plan": {
--       "Node Type": "Hash Join",
--       "Hash Cond": "(e.department_id = d.department_id)",
--       "Startup Cost": 1.23,
--       "Total Cost": 45.67,
--       "Plan Rows": 100,
--       "Actual Startup Time": 0.050,
--       "Actual Total Time": 1.200,
--       "Actual Rows": 95,
--       "Plans": [ ... ]        ← Child nodes
--     },
--     "Planning Time": 0.100,
--     "Execution Time": 1.350
--   }
-- ]
--
-- Other format options: FORMAT TEXT (default), FORMAT YAML, FORMAT XML


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  7. EXPLAIN for Subqueries                                              ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- Subqueries appear as "SubPlan" nodes in the plan.

EXPLAIN ANALYZE
SELECT e.first_name, e.salary
FROM employees e
WHERE e.salary > (SELECT AVG(salary) FROM employees);

-- Output (example):
--   Seq Scan on employees e  (cost=25.00..60.50 rows=333 width=22)
--                            (actual time=0.300..0.600 rows=340 loops=1)
--     Filter: (salary > $0)
--     Rows Removed by Filter: 660
--     InitPlan 1 (returns $0)
--       ->  Aggregate  (cost=22.50..22.51 rows=1 width=8)
--                      (actual time=0.250..0.250 rows=1 loops=1)
--             ->  Seq Scan on employees  (cost=0.00..20.00 rows=1000 width=8)
--
-- "InitPlan" = subquery that runs ONCE and its result ($0) is reused.
-- This is fine — PostgreSQL was smart enough to NOT make it correlated.


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  8. EXPLAIN for Aggregations                                            ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

EXPLAIN ANALYZE
SELECT department_id, COUNT(*) AS emp_count, AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id
ORDER BY avg_salary DESC;

-- Output (example):
--   Sort  (cost=40.00..40.25 rows=10 width=44)
--         (actual time=0.500..0.510 rows=10 loops=1)
--     Sort Key: (avg(salary)) DESC
--     Sort Method: quicksort  Memory: 25kB
--     ->  HashAggregate  (cost=35.00..37.50 rows=10 width=44)
--                        (actual time=0.400..0.420 rows=10 loops=1)
--           Group Key: department_id
--           Batches: 1  Memory Usage: 24kB
--           ->  Seq Scan on employees  (cost=0.00..22.00 rows=1000 width=12)
--                                      (actual time=0.010..0.150 rows=1000 loops=1)
--
-- Node breakdown:
--   1. Seq Scan: Read all 1000 employees
--   2. HashAggregate: Group by department_id, compute COUNT and AVG
--   3. Sort: Order results by avg_salary DESC


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  9. EXPLAIN for CTEs (Common Table Expressions)                         ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- In PostgreSQL 12+, simple CTEs can be inlined into the main query.
-- Use MATERIALIZED to force separate execution (useful for debugging).

EXPLAIN ANALYZE
WITH high_earners AS (
    SELECT employee_id, first_name, salary, department_id
    FROM employees
    WHERE salary > 80000
)
SELECT h.first_name, d.department_name
FROM high_earners h
JOIN departments d ON d.department_id = h.department_id;

-- Output (example — CTE is inlined in PG 12+):
--   Hash Join  (cost=1.23..38.00 rows=20 width=30)
--              (actual time=0.050..0.300 rows=18 loops=1)
--     Hash Cond: (e.department_id = d.department_id)
--     ->  Seq Scan on employees e  (cost=0.00..35.50 rows=20 width=18)
--           Filter: (salary > 80000)
--     ->  Hash  (cost=1.10..1.10 rows=10 width=20)
--           ->  Seq Scan on departments d
--
-- The CTE was "inlined" — the planner merged it into the main query.
-- If it appears as "CTE Scan", the CTE was materialized separately.


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  10. IDENTIFYING BOTTLENECKS — What to Look For                         ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- Use this checklist when reading EXPLAIN ANALYZE output:

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │  RED FLAG                         │  WHAT IT MEANS / FIX               │
-- ├──────────────────────────────────────────────────────────────────────────┤
-- │  Seq Scan on a large table        │  Missing index? Add one.           │
-- │  rows=1000 (est) vs rows=100000   │  Stale stats. Run ANALYZE.        │
-- │  Rows Removed by Filter: 999000   │  Index would avoid reading these. │
-- │  Sort Method: external merge Disk │  work_mem too small. Increase it. │
-- │  Nested Loop with high loops=     │  Consider Hash Join or add index. │
-- │  Buffers: shared read=50000       │  Cold cache or table too large.   │
-- │  Buffers: temp read/written       │  work_mem overflow → disk sorts.  │
-- │  SubPlan (not InitPlan)           │  Correlated subquery! Rewrite.    │
-- │  Actual rows >> Estimated rows    │  Bad stats → bad plan. ANALYZE!   │
-- └──────────────────────────────────────────────────────────────────────────┘


-- PRACTICAL EXAMPLE: Finding a bottleneck and fixing it

-- Step 1: Run the slow query with EXPLAIN ANALYZE
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.name, SUM(o.total_amount) AS total_spent
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE c.city = 'Mumbai'
GROUP BY c.name
ORDER BY total_spent DESC;

-- Step 2: Look at the plan (hypothetical output)
--   Sort  (cost=500.00..500.50 rows=200 width=40)
--         (actual time=120.000..120.050 rows=180 loops=1)
--     Sort Key: (sum(o.total_amount)) DESC
--     ->  HashAggregate  (cost=480.00..490.00 rows=200 width=40)
--           ->  Hash Join  (cost=50.00..450.00 rows=2000 width=24)
--                 Hash Cond: (o.customer_id = c.customer_id)
--                 ->  Seq Scan on orders o                      ← BOTTLENECK
--                       (actual time=0.010..100.000 rows=500000 loops=1)
--                       Buffers: shared read=8000               ← Lots of I/O
--                 ->  Hash  (cost=40.00..40.00 rows=200 width=20)
--                       ->  Seq Scan on customers c
--                             Filter: (city = 'Mumbai')

-- Step 3: The bottleneck is the Seq Scan on orders (500K rows, 8000 pages).
--         An index on orders(customer_id) would let PostgreSQL use an
--         Index Scan or Bitmap Scan to read only the matching rows.

-- Step 4: Fix it!
-- CREATE INDEX idx_orders_customer_id ON orders (customer_id);

-- Step 5: Re-run EXPLAIN ANALYZE to confirm the improvement.


-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║  EXPLAIN FOR DESTRUCTIVE STATEMENTS — Use a Transaction!                ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝

-- EXPLAIN ANALYZE on UPDATE/DELETE will actually modify data!
-- Always wrap in a transaction and ROLLBACK:

BEGIN;
EXPLAIN ANALYZE
UPDATE employees SET salary = salary * 1.10 WHERE department_id = 5;
ROLLBACK;  -- Undo the changes, keep the plan output


-- ============================================================================
-- KEY TAKEAWAYS
-- ============================================================================
-- 1. Use EXPLAIN to see the plan; use EXPLAIN ANALYZE to see actual timings.
-- 2. Add BUFFERS to see I/O details (cache hits vs disk reads).
-- 3. Seq Scan on large tables = likely missing index.
-- 4. Big gap between estimated rows and actual rows = run ANALYZE.
-- 5. "Rows Removed by Filter" = wasted work; an index could eliminate it.
-- 6. "Sort Method: external merge Disk" = increase work_mem.
-- 7. Use FORMAT JSON for tools like explain.dalibo.com or pgMustard.
-- 8. Always wrap destructive EXPLAIN ANALYZE in BEGIN / ROLLBACK.
-- ============================================================================
