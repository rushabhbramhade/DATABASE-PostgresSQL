-- ============================================================
-- Topic:  Composite & Special Indexes in PostgreSQL
-- File:   Composite_Indexes.sql
-- ============================================================
-- This file covers:
--   • Multi-column (composite) indexes
--   • Leftmost prefix rule — column order matters!
--   • Partial indexes (indexes with a WHERE clause)
--   • Expression indexes (indexing on a function result)
--   • GIN indexes (for JSONB and full-text search)
--   • GiST indexes (for geometric and range types)
-- ============================================================
-- Sample tables used throughout this file:
--
-- orders table:
-- | order_id | customer_id | order_date | status    | total_amount | region |
-- |----------|-------------|------------|-----------|--------------|--------|
-- | 1        | 101         | 2024-01-15 | completed | 250.00       | East   |
-- | 2        | 102         | 2024-01-20 | pending   | 180.50       | West   |
-- | 3        | 101         | 2024-02-10 | completed | 320.00       | East   |
-- | 4        | 103         | 2024-02-14 | cancelled | 95.75        | North  |
-- | 5        | 104         | 2024-03-01 | completed | 450.00       | West   |
-- | 6        | 102         | 2024-03-15 | pending   | 210.25       | East   |
-- | 7        | 105         | 2024-04-01 | completed | 175.00       | South  |
-- | 8        | 101         | 2024-04-10 | completed | 530.00       | East   |
--
-- customers table:
-- | customer_id | first_name | last_name | email                    | city      | preferences (JSONB)                           |
-- |-------------|------------|-----------|--------------------------|-----------|-----------------------------------------------|
-- | 101         | Amit       | Sharma    | amit.sharma@mail.com     | Mumbai    | {"newsletter": true, "theme": "dark"}         |
-- | 102         | Priya      | Verma     | priya.verma@mail.com     | Delhi     | {"newsletter": false, "theme": "light"}       |
-- | 103         | Rahul      | Gupta     | RAHUL.GUPTA@MAIL.COM     | Bangalore | {"newsletter": true, "language": "hindi"}     |
-- | 104         | Sneha      | Patel     | sneha.patel@mail.com     | Mumbai    | {"newsletter": true, "theme": "dark"}         |
-- | 105         | Vikram     | Singh     | Vikram.Singh@Mail.com    | Chennai   | {"newsletter": false}                         |
--
-- articles table (for full-text search):
-- | article_id | title                          | body                                          |
-- |------------|--------------------------------|-----------------------------------------------|
-- | 1          | Introduction to PostgreSQL     | PostgreSQL is a powerful open-source database. |
-- | 2          | Advanced SQL Techniques        | Learn about CTEs, window functions, and more.  |
-- | 3          | PostgreSQL Index Guide         | Indexes speed up queries in PostgreSQL.        |
-- ============================================================

-- Create sample tables (run once)
CREATE TABLE IF NOT EXISTS customers (
    customer_id  SERIAL PRIMARY KEY,
    first_name   VARCHAR(50) NOT NULL,
    last_name    VARCHAR(50) NOT NULL,
    email        VARCHAR(100),
    city         VARCHAR(50),
    preferences  JSONB DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS orders (
    order_id     SERIAL PRIMARY KEY,
    customer_id  INTEGER REFERENCES customers(customer_id),
    order_date   DATE NOT NULL,
    status       VARCHAR(20) DEFAULT 'pending',
    total_amount NUMERIC(10,2),
    region       VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS articles (
    article_id   SERIAL PRIMARY KEY,
    title        VARCHAR(200) NOT NULL,
    body         TEXT,
    search_vector TSVECTOR
);

-- Insert sample data
INSERT INTO customers (customer_id, first_name, last_name, email, city, preferences)
VALUES
    (101, 'Amit',   'Sharma', 'amit.sharma@mail.com',  'Mumbai',    '{"newsletter": true, "theme": "dark"}'),
    (102, 'Priya',  'Verma',  'priya.verma@mail.com',  'Delhi',     '{"newsletter": false, "theme": "light"}'),
    (103, 'Rahul',  'Gupta',  'RAHUL.GUPTA@MAIL.COM',  'Bangalore', '{"newsletter": true, "language": "hindi"}'),
    (104, 'Sneha',  'Patel',  'sneha.patel@mail.com',  'Mumbai',    '{"newsletter": true, "theme": "dark"}'),
    (105, 'Vikram', 'Singh',  'Vikram.Singh@Mail.com', 'Chennai',   '{"newsletter": false}')
ON CONFLICT DO NOTHING;

INSERT INTO orders (order_id, customer_id, order_date, status, total_amount, region)
VALUES
    (1, 101, '2024-01-15', 'completed', 250.00, 'East'),
    (2, 102, '2024-01-20', 'pending',   180.50, 'West'),
    (3, 101, '2024-02-10', 'completed', 320.00, 'East'),
    (4, 103, '2024-02-14', 'cancelled',  95.75, 'North'),
    (5, 104, '2024-03-01', 'completed', 450.00, 'West'),
    (6, 102, '2024-03-15', 'pending',   210.25, 'East'),
    (7, 105, '2024-04-01', 'completed', 175.00, 'South'),
    (8, 101, '2024-04-10', 'completed', 530.00, 'East')
ON CONFLICT DO NOTHING;

INSERT INTO articles (article_id, title, body)
VALUES
    (1, 'Introduction to PostgreSQL',  'PostgreSQL is a powerful open-source database.'),
    (2, 'Advanced SQL Techniques',     'Learn about CTEs, window functions, and more.'),
    (3, 'PostgreSQL Index Guide',      'Indexes speed up queries in PostgreSQL.')
ON CONFLICT DO NOTHING;

-- Pre-populate the tsvector column for full-text search
UPDATE articles
SET search_vector = to_tsvector('english', title || ' ' || body);


-- ************************************************************
-- 1. Composite (Multi-Column) Index
-- ************************************************************
-- Syntax:
--   CREATE INDEX idx_name ON table (col1, col2, ...);
--
-- A composite index stores sorted values of MULTIPLE columns
-- together in a single B-Tree structure.
--
-- Use when queries frequently filter on a COMBINATION of columns.

CREATE INDEX idx_orders_customer_date
ON orders (customer_id, order_date);

-- This query benefits fully from the composite index:
SELECT order_id, order_date, total_amount
FROM orders
WHERE customer_id = 101
  AND order_date >= '2024-02-01';

-- Expected Output:
-- | order_id | order_date | total_amount |
-- |----------|------------|--------------|
-- | 3        | 2024-02-10 | 320.00       |
-- | 8        | 2024-04-10 | 530.00       |
--
-- The index can quickly locate all rows for customer_id = 101,
-- then further narrow to the date range — very efficient.


-- ************************************************************
-- 2. Column Order Matters! (Leftmost Prefix Rule)
-- ************************************************************
-- With index (customer_id, order_date), PostgreSQL can use it for:
--   ✅ WHERE customer_id = 101                         (uses first column)
--   ✅ WHERE customer_id = 101 AND order_date > '...'  (uses both columns)
--   ❌ WHERE order_date > '2024-03-01'                  (skips first column!)
--
-- The index is organized by customer_id FIRST, then order_date
-- within each customer_id. Without customer_id in the query,
-- PostgreSQL cannot efficiently navigate the B-Tree.

-- ✅ This uses the composite index (filtering on first column):
EXPLAIN SELECT * FROM orders WHERE customer_id = 101;
-- Expected plan: Index Scan using idx_orders_customer_date

-- ❌ This CANNOT use the composite index (first column missing):
EXPLAIN SELECT * FROM orders WHERE order_date > '2024-03-01';
-- Expected plan: Seq Scan on orders (or a separate index if one exists)

-- Think of it like a phone book sorted by (Last Name, First Name):
--   ✅ You can quickly find all "Sharma"s
--   ✅ You can find "Sharma, Amit" instantly
--   ❌ You CANNOT quickly find all "Amit"s — you'd scan the whole book


-- ************************************************************
-- 3. When Composite Indexes Help vs. When They Don't
-- ************************************************************

-- ─── WHEN THEY HELP ───
-- a) Queries that filter on the first column, or first + subsequent columns:
SELECT * FROM orders
WHERE customer_id = 102 AND order_date = '2024-01-20';

-- b) Queries that filter on the first column and ORDER BY the second:
SELECT * FROM orders
WHERE customer_id = 101
ORDER BY order_date DESC;

-- Expected Output:
-- | order_id | customer_id | order_date | status    | total_amount | region |
-- |----------|-------------|------------|-----------|--------------|--------|
-- | 8        | 101         | 2024-04-10 | completed | 530.00       | East   |
-- | 3        | 101         | 2024-02-10 | completed | 320.00       | East   |
-- | 1        | 101         | 2024-01-15 | completed | 250.00       | East   |

-- ─── WHEN THEY DON'T HELP ───
-- a) Queries on ONLY the second column:
SELECT * FROM orders WHERE order_date > '2024-03-01';
-- → Needs a separate index on (order_date)

-- b) Queries on unrelated columns:
SELECT * FROM orders WHERE region = 'East';
-- → Needs a separate index on (region)

-- c) Queries using OR between indexed columns:
SELECT * FROM orders
WHERE customer_id = 101 OR order_date = '2024-03-01';
-- → The optimizer usually can't combine the composite index for OR;
--   it may use Bitmap Index Scan or fall back to Seq Scan.


-- ************************************************************
-- 4. Partial Index (Index with a WHERE clause)
-- ************************************************************
-- A partial index only indexes rows that match a condition.
-- Smaller index → less disk space, faster to scan and maintain.
--
-- Syntax:
--   CREATE INDEX idx_name ON table (column) WHERE condition;

-- Index ONLY pending orders (a small subset):
CREATE INDEX idx_orders_pending
ON orders (customer_id, order_date)
WHERE status = 'pending';

-- This query uses the partial index:
SELECT order_id, customer_id, order_date, total_amount
FROM orders
WHERE status = 'pending'
  AND customer_id = 102;

-- Expected Output:
-- | order_id | customer_id | order_date | total_amount |
-- |----------|-------------|------------|--------------|
-- | 2        | 102         | 2024-01-20 | 180.50       |
-- | 6        | 102         | 2024-03-15 | 210.25       |

-- Why partial indexes are powerful:
--   • If 90% of orders are 'completed', indexing only 'pending'
--     creates a tiny, focused index.
--   • Great for status flags, soft deletes (is_deleted = FALSE),
--     or any column where you only query a specific value.

-- Another practical example — index only active users:
-- CREATE INDEX idx_active_users ON users (email)
-- WHERE is_active = TRUE;
-- → Perfect for login lookups where you never search inactive accounts.


-- ************************************************************
-- 5. Expression Index (Functional Index)
-- ************************************************************
-- You can index the RESULT of an expression or function.
-- The index stores pre-computed values, so queries using the
-- same expression can use the index.
--
-- Syntax:
--   CREATE INDEX idx_name ON table (expression);

-- Problem: emails are stored in mixed case
--   'amit.sharma@mail.com', 'RAHUL.GUPTA@MAIL.COM', 'Vikram.Singh@Mail.com'
-- A plain index on email WON'T help with case-insensitive searches.

CREATE INDEX idx_customers_email_lower
ON customers (LOWER(email));

-- This query uses the expression index:
SELECT customer_id, first_name, email
FROM customers
WHERE LOWER(email) = 'rahul.gupta@mail.com';

-- Expected Output:
-- | customer_id | first_name | email                |
-- |-------------|------------|----------------------|
-- | 103         | Rahul      | RAHUL.GUPTA@MAIL.COM |
--
-- Important: the query's expression must EXACTLY MATCH the
-- index expression. LOWER(email) in both → index is used.
-- Using UPPER(email) or email ILIKE '...' won't use this index.

-- Another example — index on the year extracted from a date:
CREATE INDEX idx_orders_year
ON orders (EXTRACT(YEAR FROM order_date));

SELECT order_id, order_date, total_amount
FROM orders
WHERE EXTRACT(YEAR FROM order_date) = 2024;

-- Expected Output: all 8 rows (all orders are from 2024)


-- ************************************************************
-- 6. Composite Index with Partial + Expression combined
-- ************************************************************
-- You can combine multiple techniques in a single index.

-- Fast lookup for completed orders by region (case-insensitive):
CREATE INDEX idx_orders_completed_region
ON orders (LOWER(region))
WHERE status = 'completed';

SELECT order_id, region, total_amount
FROM orders
WHERE status = 'completed'
  AND LOWER(region) = 'east';

-- Expected Output:
-- | order_id | region | total_amount |
-- |----------|--------|--------------|
-- | 1        | East   | 250.00       |
-- | 3        | East   | 320.00       |
-- | 8        | East   | 530.00       |


-- ************************************************************
-- 7. GIN Index (Generalized Inverted Index)
-- ************************************************************
-- GIN indexes are designed for values that contain multiple
-- elements — like arrays, JSONB documents, and full-text search.
--
-- Think of it as an inverted index: instead of "row → values,"
-- it stores "value → list of rows."

-- ─── 7a. GIN Index on JSONB ───
CREATE INDEX idx_customers_preferences
ON customers USING GIN (preferences);

-- Query: find customers who have newsletter enabled
SELECT customer_id, first_name, preferences
FROM customers
WHERE preferences @> '{"newsletter": true}';

-- Expected Output:
-- | customer_id | first_name | preferences                                 |
-- |-------------|------------|---------------------------------------------|
-- | 101         | Amit       | {"newsletter": true, "theme": "dark"}       |
-- | 103         | Rahul      | {"newsletter": true, "language": "hindi"}   |
-- | 104         | Sneha      | {"newsletter": true, "theme": "dark"}       |

-- The @> operator means "contains" — the GIN index makes this fast
-- even with millions of JSONB documents.

-- Query: find customers with a "theme" key:
SELECT customer_id, first_name, preferences
FROM customers
WHERE preferences ? 'theme';

-- Expected Output:
-- | customer_id | first_name | preferences                                 |
-- |-------------|------------|---------------------------------------------|
-- | 101         | Amit       | {"newsletter": true, "theme": "dark"}       |
-- | 102         | Priya      | {"newsletter": false, "theme": "light"}     |
-- | 104         | Sneha      | {"newsletter": true, "theme": "dark"}       |

-- ─── 7b. GIN Index for Full-Text Search ───
CREATE INDEX idx_articles_search
ON articles USING GIN (search_vector);

-- Full-text search using the GIN index:
SELECT article_id, title
FROM articles
WHERE search_vector @@ to_tsquery('english', 'PostgreSQL & index');

-- Expected Output:
-- | article_id | title                  |
-- |------------|------------------------|
-- | 3          | PostgreSQL Index Guide  |

-- GIN Summary:
--   • Best for: JSONB containment (@>, ?, ?|, ?&), arrays, full-text search
--   • Slower to build/update than B-Tree, but very fast for lookups
--   • Use jsonb_path_ops for even faster @> queries on JSONB:
--     CREATE INDEX ... USING GIN (preferences jsonb_path_ops);


-- ************************************************************
-- 8. GiST Index (Generalized Search Tree)
-- ************************************************************
-- GiST is a flexible index structure for geometric data, range
-- types, nearest-neighbor searches, and full-text search.
--
-- While GIN and GiST can BOTH index full-text, they differ:
--   GIN  → faster lookups, slower updates, larger size
--   GiST → faster updates, smaller size, slightly slower lookups

-- Example: GiST on full-text (alternative to GIN):
CREATE INDEX idx_articles_search_gist
ON articles USING GIST (search_vector);

-- Example: GiST for range types
CREATE TABLE IF NOT EXISTS reservations (
    reservation_id SERIAL PRIMARY KEY,
    room_number    INTEGER,
    reserved_during TSRANGE  -- timestamp range
);

INSERT INTO reservations (room_number, reserved_during) VALUES
    (101, '[2024-06-01 09:00, 2024-06-01 11:00)'),
    (101, '[2024-06-01 14:00, 2024-06-01 16:00)'),
    (102, '[2024-06-01 10:00, 2024-06-01 12:00)')
ON CONFLICT DO NOTHING;

CREATE INDEX idx_reservations_during
ON reservations USING GIST (reserved_during);

-- Find overlapping reservations for room 101:
SELECT reservation_id, room_number, reserved_during
FROM reservations
WHERE room_number = 101
  AND reserved_during && '[2024-06-01 10:00, 2024-06-01 15:00)';
-- The && operator checks for overlap — the GiST index makes this efficient.

-- Expected Output:
-- | reservation_id | room_number | reserved_during                          |
-- |----------------|-------------|------------------------------------------|
-- | 1              | 101         | [2024-06-01 09:00, 2024-06-01 11:00)     |
-- | 2              | 101         | [2024-06-01 14:00, 2024-06-01 16:00)     |

-- GiST Summary:
--   • Best for: geometric types, range types, nearest-neighbor, full-text
--   • Supports operators like &&, @>, <@, <<, >>
--   • Handles multi-dimensional data that B-Tree cannot


-- ============================================================
-- INDEX TYPE COMPARISON
-- ============================================================
--
-- | Index Type | Best For                              | Operators Supported            |
-- |------------|---------------------------------------|--------------------------------|
-- | B-Tree     | Equality, range, sorting              | =, <, >, <=, >=, BETWEEN      |
-- | GIN        | JSONB, arrays, full-text search        | @>, ?, ?|, ?&, @@              |
-- | GiST       | Geometry, ranges, nearest-neighbor     | &&, @>, <@, <<, >>             |
-- | Hash       | Equality only (rarely used)            | =                              |
-- | BRIN       | Large tables with naturally ordered    | =, <, >, <=, >=               |
--              | data (timestamps, serial IDs)          |                                |
--
-- ============================================================


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. Composite indexes index MULTIPLE columns in a single B-Tree.
--    Column order matters — the leftmost prefix rule applies.
-- 2. Partial indexes (WHERE clause) index only a subset of rows,
--    saving space and speeding up targeted queries.
-- 3. Expression indexes let you index computed values like
--    LOWER(email) for case-insensitive searches.
-- 4. GIN indexes are ideal for JSONB, arrays, and full-text search.
-- 5. GiST indexes handle geometric/range data and nearest-neighbor.
-- 6. Choose the right index type for your data and query patterns —
--    B-Tree is the default, but it's not always the best choice.
-- 7. You can combine techniques (composite + partial + expression)
--    for highly optimized, targeted indexes.
-- ============================================================
