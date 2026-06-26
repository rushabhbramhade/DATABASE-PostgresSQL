-- ============================================================
-- FILE: Materialized_Views.sql
-- TOPIC: Materialized Views in PostgreSQL
-- ============================================================
-- A MATERIALIZED VIEW is a view that physically stores its
-- query results on disk, like a snapshot/cache of the data.
--
-- Unlike regular views (re-executed every time), materialized
-- views return pre-computed results — making them FAST.
--
-- Trade-off: the data can become STALE. You must manually
-- REFRESH it to pick up changes from the base tables.
--
-- ┌──────────────────────┬──────────────────────────────┐
-- │   Regular View       │   Materialized View          │
-- ├──────────────────────┼──────────────────────────────┤
-- │ Virtual table        │ Physical table (cached)      │
-- │ Always up-to-date    │ Stale until refreshed        │
-- │ No disk space used   │ Uses disk space              │
-- │ Can be slow on big   │ Fast reads (pre-computed)    │
-- │   queries            │                              │
-- │ Some are updatable   │ Always read-only             │
-- │ Cannot add indexes   │ CAN add indexes              │
-- └──────────────────────┴──────────────────────────────┘
-- ============================================================


-- ************************************************************
-- SAMPLE TABLES SETUP (same as Views.sql)
-- ************************************************************

CREATE TABLE IF NOT EXISTS departments (
    department_id   SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS employees (
    employee_id   SERIAL PRIMARY KEY,
    first_name    VARCHAR(50)    NOT NULL,
    last_name     VARCHAR(50)    NOT NULL,
    email         VARCHAR(100)   UNIQUE NOT NULL,
    salary        NUMERIC(10,2)  NOT NULL,
    hire_date     DATE           NOT NULL DEFAULT CURRENT_DATE,
    department_id INT REFERENCES departments(department_id),
    manager_id    INT REFERENCES employees(employee_id)
);

CREATE TABLE IF NOT EXISTS orders (
    order_id     SERIAL PRIMARY KEY,
    employee_id  INT REFERENCES employees(employee_id),
    customer     VARCHAR(100)   NOT NULL,
    order_date   DATE           NOT NULL DEFAULT CURRENT_DATE,
    total_amount NUMERIC(10,2)  NOT NULL,
    status       VARCHAR(20)    DEFAULT 'pending'
);

INSERT INTO departments (department_name) VALUES
    ('Engineering'), ('Sales'), ('Human Resources')
ON CONFLICT DO NOTHING;

INSERT INTO employees (first_name, last_name, email, salary, hire_date, department_id, manager_id) VALUES
    ('Alice',  'Johnson',  'alice@company.com',   95000, '2020-03-15', 1, NULL),
    ('Bob',    'Smith',    'bob@company.com',     72000, '2021-06-01', 1, 1),
    ('Carol',  'Williams', 'carol@company.com',   68000, '2022-01-10', 2, 1),
    ('David',  'Brown',    'david@company.com',   55000, '2023-04-20', 2, 3),
    ('Eve',    'Davis',    'eve@company.com',     82000, '2021-09-05', 3, 1)
ON CONFLICT DO NOTHING;

INSERT INTO orders (employee_id, customer, order_date, total_amount, status) VALUES
    (3, 'Acme Corp',     '2025-01-15', 15000.00, 'completed'),
    (3, 'Globex Inc',    '2025-02-20', 23000.00, 'completed'),
    (4, 'Initech',       '2025-03-10',  8500.00, 'pending'),
    (4, 'Umbrella Corp', '2025-04-05', 12000.00, 'shipped'),
    (3, 'Stark Industries','2025-05-18', 45000.00, 'pending'),
    (4, 'Wayne Enterprises','2025-06-01', 9200.00, 'completed')
ON CONFLICT DO NOTHING;


-- ============================================================
-- EXAMPLE 1: CREATE MATERIALIZED VIEW — Basic Syntax
-- ============================================================
-- Syntax:
--   CREATE MATERIALIZED VIEW mv_name AS
--   SELECT ... FROM ... WHERE ...
--   WITH [NO] DATA;
--
--   WITH DATA     → executes the query and stores results NOW
--   WITH NO DATA  → creates the view definition only, no data
--                   (must REFRESH before you can query it)
-- ============================================================

CREATE MATERIALIZED VIEW mv_sales_summary AS
SELECT
    e.employee_id,
    e.first_name || ' ' || e.last_name AS employee_name,
    COUNT(o.order_id)                  AS total_orders,
    SUM(o.total_amount)                AS total_revenue,
    ROUND(AVG(o.total_amount), 2)      AS avg_order_value
FROM employees e
JOIN orders o ON e.employee_id = o.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name
WITH DATA;

-- Query it — fast, reads from stored snapshot
SELECT * FROM mv_sales_summary
ORDER BY total_revenue DESC;

-- Expected Output:
-- employee_id | employee_name  | total_orders | total_revenue | avg_order_value
-- ------------|----------------|--------------|---------------|----------------
-- 3           | Carol Williams | 3            | 83000.00      | 27666.67
-- 4           | David Brown    | 3            | 29700.00      |  9900.00


-- ============================================================
-- EXAMPLE 2: CREATE MATERIALIZED VIEW WITH NO DATA
-- ============================================================
-- Useful when you want to define the view now but populate
-- it later (e.g., during off-peak hours).
-- ============================================================

CREATE MATERIALIZED VIEW mv_monthly_revenue AS
SELECT
    DATE_TRUNC('month', order_date)::DATE AS month,
    COUNT(*)                              AS order_count,
    SUM(total_amount)                     AS revenue
FROM orders
GROUP BY DATE_TRUNC('month', order_date)
WITH NO DATA;

-- Querying before refresh will fail:
-- SELECT * FROM mv_monthly_revenue;
-- ERROR: materialized view "mv_monthly_revenue" has not been populated
-- HINT: Use the REFRESH MATERIALIZED VIEW command.

-- Populate it now
REFRESH MATERIALIZED VIEW mv_monthly_revenue;

SELECT * FROM mv_monthly_revenue
ORDER BY month;

-- Expected Output:
-- month      | order_count | revenue
-- -----------|-------------|----------
-- 2025-01-01 | 1           | 15000.00
-- 2025-02-01 | 1           | 23000.00
-- 2025-03-01 | 1           |  8500.00
-- 2025-04-01 | 1           | 12000.00
-- 2025-05-01 | 1           | 45000.00
-- 2025-06-01 | 1           |  9200.00


-- ============================================================
-- EXAMPLE 3: REFRESH MATERIALIZED VIEW
-- ============================================================
-- When base table data changes, the materialized view becomes
-- stale. Use REFRESH to re-execute the query and update it.
--
-- Standard refresh LOCKS the view — readers are blocked.
-- ============================================================

-- Simulate a data change
INSERT INTO orders (employee_id, customer, order_date, total_amount, status)
VALUES (3, 'Oscorp', '2025-06-20', 18000.00, 'pending');

-- The materialized view still shows OLD data
SELECT * FROM mv_sales_summary ORDER BY employee_id;
-- (Carol still shows total_revenue = 83000, not 101000)

-- Refresh to pick up the new order
REFRESH MATERIALIZED VIEW mv_sales_summary;

SELECT * FROM mv_sales_summary ORDER BY employee_id;

-- Expected Output (after refresh):
-- employee_id | employee_name  | total_orders | total_revenue | avg_order_value
-- ------------|----------------|--------------|---------------|----------------
-- 3           | Carol Williams | 4            | 101000.00     | 25250.00
-- 4           | David Brown    | 3            |  29700.00     |  9900.00


-- ============================================================
-- EXAMPLE 4: REFRESH CONCURRENTLY + Unique Index
-- ============================================================
-- REFRESH ... CONCURRENTLY allows readers to continue querying
-- the OLD data while the refresh runs in the background.
-- Once complete, the new data replaces the old atomically.
--
-- REQUIREMENT: The materialized view MUST have a UNIQUE INDEX
--              for CONCURRENTLY to work.
-- ============================================================

-- Step 1: Create a unique index on the materialized view
CREATE UNIQUE INDEX idx_mv_sales_summary_emp
ON mv_sales_summary (employee_id);

-- Step 2: Now concurrent refresh is possible
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_sales_summary;

-- Readers were never blocked! They saw old data during refresh,
-- then seamlessly see new data after it completes.

-- Verify
SELECT * FROM mv_sales_summary ORDER BY total_revenue DESC;

-- Expected Output: same as Example 3's refreshed result


-- ============================================================
-- EXAMPLE 5: Creating Indexes on Materialized Views
-- ============================================================
-- Because materialized views store data physically, you can
-- create indexes on them — just like regular tables.
-- This is a HUGE advantage over regular views.
-- ============================================================

-- Index for fast lookups by employee name
CREATE INDEX idx_mv_sales_emp_name
ON mv_sales_summary (employee_name);

-- Index for filtering by revenue range
CREATE INDEX idx_mv_sales_revenue
ON mv_sales_summary (total_revenue);

-- Now this query uses the index for fast lookup
SELECT employee_name, total_revenue
FROM mv_sales_summary
WHERE total_revenue > 50000;

-- Expected Output:
-- employee_name  | total_revenue
-- ---------------|-------------
-- Carol Williams | 101000.00

-- Check the query plan to confirm index usage
EXPLAIN SELECT * FROM mv_sales_summary WHERE total_revenue > 50000;


-- ============================================================
-- EXAMPLE 6: Dashboard-Style Materialized View
-- ============================================================
-- Real-world scenario: an executive dashboard that shows
-- department performance. The underlying query is expensive,
-- but the dashboard only needs data refreshed once per hour.
-- ============================================================

CREATE MATERIALIZED VIEW mv_department_dashboard AS
SELECT
    d.department_name,
    COUNT(DISTINCT e.employee_id)   AS headcount,
    ROUND(AVG(e.salary), 2)        AS avg_salary,
    COUNT(o.order_id)               AS orders_handled,
    COALESCE(SUM(o.total_amount), 0) AS revenue_generated,
    CASE
        WHEN COUNT(o.order_id) > 0
        THEN ROUND(SUM(o.total_amount) / COUNT(o.order_id), 2)
        ELSE 0
    END AS avg_order_value
FROM departments d
LEFT JOIN employees e ON d.department_id = e.department_id
LEFT JOIN orders o    ON e.employee_id   = o.employee_id
GROUP BY d.department_name
WITH DATA;

CREATE UNIQUE INDEX idx_mv_dept_dash_name
ON mv_department_dashboard (department_name);

SELECT * FROM mv_department_dashboard
ORDER BY revenue_generated DESC;

-- Expected Output:
-- department_name  | headcount | avg_salary | orders_handled | revenue_generated | avg_order_value
-- -----------------|-----------|------------|----------------|-------------------|----------------
-- Sales            | 2         | 61500.00   | 7              | 130700.00         | 18671.43
-- Engineering      | 2         | 83500.00   | 0              |      0.00         |     0.00
-- Human Resources  | 1         | 82000.00   | 0              |      0.00         |     0.00


-- ============================================================
-- STALENESS AND REFRESH STRATEGIES
-- ============================================================
-- PostgreSQL does NOT auto-refresh materialized views.
-- You must choose a strategy:
--
-- 1. SCHEDULED REFRESH (most common)
--    Use pg_cron or an external cron job:
--      SELECT cron.schedule(
--          'refresh_dashboard',
--          '0 * * * *',  -- every hour
--          'REFRESH MATERIALIZED VIEW CONCURRENTLY mv_department_dashboard'
--      );
--
-- 2. TRIGGER-BASED REFRESH
--    Create a trigger on the base table that calls REFRESH
--    after INSERT/UPDATE/DELETE. Use cautiously — refreshing
--    on every write can be expensive.
--
-- 3. APPLICATION-LEVEL REFRESH
--    Refresh from your app code after batch imports or
--    significant data changes.
--
-- 4. LAZY REFRESH
--    Track a "last_refreshed" timestamp and refresh only
--    when a user queries the view and the data is older
--    than a threshold.
-- ============================================================


-- ============================================================
-- DROPPING A MATERIALIZED VIEW
-- ============================================================

DROP MATERIALIZED VIEW IF EXISTS mv_monthly_revenue;

-- To see all materialized views in your database:
SELECT matviewname, matviewowner
FROM pg_matviews
WHERE schemaname = 'public';


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. Materialized views STORE query results physically on disk.
-- 2. They are FAST for reads but can become STALE.
-- 3. Use REFRESH MATERIALIZED VIEW to update the stored data.
-- 4. Use REFRESH ... CONCURRENTLY to avoid blocking readers
--    (requires a UNIQUE INDEX on the materialized view).
-- 5. You CAN create indexes on materialized views — big win!
-- 6. Use them for dashboards, reports, analytics, and any
--    expensive query whose results don't need to be real-time.
-- 7. WITH NO DATA creates the definition without populating it.
-- 8. PostgreSQL does NOT auto-refresh — you need pg_cron,
--    triggers, or app-level logic to keep data fresh.
-- 9. Materialized views are always READ-ONLY (no INSERT/UPDATE).
-- ============================================================
