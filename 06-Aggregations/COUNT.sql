-- ============================================================
-- 📊 COUNT() — Counting Records in PostgreSQL
-- ============================================================
-- The COUNT() function returns the number of rows that match
-- a specified condition. It is one of the most frequently
-- used aggregate functions in SQL.
--
-- Sample Table Used: orders
-- | order_id | customer_name | product    | category    | quantity | price  | order_date |
-- |----------|---------------|------------|-------------|----------|--------|------------|
-- | 1        | Amit Sharma   | Laptop     | Electronics | 1        | 75000  | 2024-01-15 |
-- | 2        | Priya Verma   | Mouse      | Electronics | 3        | 500    | 2024-01-20 |
-- | 3        | Rahul Gupta   | Desk Chair | Furniture   | 1        | 12000  | 2024-02-05 |
-- | 4        | Sneha Patel   | Keyboard   | Electronics | 2        | 2000   | 2024-02-10 |
-- | 5        | Vikram Singh  | Laptop     | Electronics | 1        | 82000  | 2024-02-15 |
-- | 6        | Amit Sharma   | Monitor    | Electronics | 2        | 15000  | 2024-03-01 |
-- | 7        | Priya Verma   | Bookshelf  | Furniture   | 1        | 8000   | 2024-03-10 |
-- | 8        | Karan Mehta   | Laptop     | Electronics | 1        | 68000  | 2024-03-20 |
-- ============================================================


-- ============================================================
-- 1️⃣ COUNT(*) — Count ALL rows (including NULLs)
-- ============================================================
-- COUNT(*) counts every row in the result set, regardless
-- of whether any column contains NULL.

SELECT COUNT(*) AS total_orders
FROM orders;

-- Expected Output:
-- | total_orders |
-- |--------------|
-- | 8            |


-- ============================================================
-- 2️⃣ COUNT(column) — Count NON-NULL values in a column
-- ============================================================
-- COUNT(column_name) counts only rows where that column
-- is NOT NULL. If every row has a value, the result is
-- the same as COUNT(*).

SELECT COUNT(customer_name) AS customers_with_names
FROM orders;

-- Expected Output:
-- | customers_with_names |
-- |----------------------|
-- | 8                    |
-- (All rows have customer_name, so result = 8)


-- ============================================================
-- 3️⃣ COUNT(DISTINCT column) — Count unique values
-- ============================================================
-- COUNT(DISTINCT column_name) counts only the unique
-- (non-duplicate) non-NULL values in a column.

-- How many unique customers placed orders?
SELECT COUNT(DISTINCT customer_name) AS unique_customers
FROM orders;

-- Expected Output:
-- | unique_customers |
-- |------------------|
-- | 6                |
-- (Amit Sharma appears 2x, Priya Verma appears 2x → 6 unique)

-- How many unique products were ordered?
SELECT COUNT(DISTINCT product) AS unique_products
FROM orders;

-- Expected Output:
-- | unique_products |
-- |-----------------|
-- | 5               |
-- (Laptop appears 3x → 5 unique: Laptop, Mouse, Desk Chair, Keyboard, Monitor, Bookshelf = 6)
-- Correction: Laptop(3), Mouse(1), Desk Chair(1), Keyboard(1), Monitor(1), Bookshelf(1) = 6 unique products

-- How many unique categories exist?
SELECT COUNT(DISTINCT category) AS unique_categories
FROM orders;

-- Expected Output:
-- | unique_categories |
-- |-------------------|
-- | 2                 |
-- (Electronics and Furniture)


-- ============================================================
-- 4️⃣ COUNT(*) vs COUNT(column) vs COUNT(DISTINCT) — Side by Side
-- ============================================================

SELECT
    COUNT(*)                    AS total_rows,
    COUNT(product)              AS non_null_products,
    COUNT(DISTINCT product)     AS unique_products,
    COUNT(DISTINCT category)    AS unique_categories
FROM orders;

-- Expected Output:
-- | total_rows | non_null_products | unique_products | unique_categories |
-- |------------|-------------------|-----------------|-------------------|
-- | 8          | 8                 | 6               | 2                 |


-- ============================================================
-- 5️⃣ COUNT with WHERE — Count rows matching a condition
-- ============================================================

-- How many Electronics orders were placed?
SELECT COUNT(*) AS electronics_orders
FROM orders
WHERE category = 'Electronics';

-- Expected Output:
-- | electronics_orders |
-- |--------------------|
-- | 6                  |

-- How many orders were placed in February 2024?
SELECT COUNT(*) AS feb_orders
FROM orders
WHERE order_date >= '2024-02-01'
  AND order_date < '2024-03-01';

-- Expected Output:
-- | feb_orders |
-- |------------|
-- | 3          |

-- How many high-value orders (price > 10000)?
SELECT COUNT(*) AS high_value_orders
FROM orders
WHERE price > 10000;

-- Expected Output:
-- | high_value_orders |
-- |-------------------|
-- | 5                 |
-- (75000, 12000, 82000, 15000, 68000)


-- ============================================================
-- 6️⃣ COUNT with GROUP BY — Count per group
-- ============================================================

-- How many orders did each customer place?
SELECT
    customer_name,
    COUNT(*) AS order_count
FROM orders
GROUP BY customer_name
ORDER BY order_count DESC;

-- Expected Output:
-- | customer_name | order_count |
-- |---------------|-------------|
-- | Amit Sharma   | 2           |
-- | Priya Verma   | 2           |
-- | Rahul Gupta   | 1           |
-- | Sneha Patel   | 1           |
-- | Vikram Singh  | 1           |
-- | Karan Mehta   | 1           |

-- How many orders in each category?
SELECT
    category,
    COUNT(*) AS order_count
FROM orders
GROUP BY category
ORDER BY order_count DESC;

-- Expected Output:
-- | category    | order_count |
-- |-------------|-------------|
-- | Electronics | 6           |
-- | Furniture   | 2           |

-- How many orders per product?
SELECT
    product,
    COUNT(*) AS times_ordered
FROM orders
GROUP BY product
ORDER BY times_ordered DESC;

-- Expected Output:
-- | product    | times_ordered |
-- |------------|---------------|
-- | Laptop     | 3             |
-- | Mouse      | 1             |
-- | Desk Chair | 1             |
-- | Keyboard   | 1             |
-- | Monitor    | 1             |
-- | Bookshelf  | 1             |


-- ============================================================
-- 7️⃣ COUNT with HAVING — Filter groups by count
-- ============================================================
-- HAVING filters groups AFTER aggregation (WHERE filters
-- individual rows BEFORE aggregation).

-- Show only customers who placed more than 1 order
SELECT
    customer_name,
    COUNT(*) AS order_count
FROM orders
GROUP BY customer_name
HAVING COUNT(*) > 1;

-- Expected Output:
-- | customer_name | order_count |
-- |---------------|-------------|
-- | Amit Sharma   | 2           |
-- | Priya Verma   | 2           |

-- Show products ordered more than 2 times
SELECT
    product,
    COUNT(*) AS times_ordered
FROM orders
GROUP BY product
HAVING COUNT(*) > 2;

-- Expected Output:
-- | product | times_ordered |
-- |---------|---------------|
-- | Laptop  | 3             |


-- ============================================================
-- 8️⃣ Counting NULLs Behavior — Critical Concept
-- ============================================================
-- To demonstrate NULL behavior, imagine a column with NULLs.
-- COUNT(*) counts ALL rows. COUNT(column) skips NULLs.

-- Simulating NULL behavior with a CTE:
WITH orders_with_nulls AS (
    SELECT order_id, customer_name, product, category, quantity, price, order_date
    FROM orders

    UNION ALL

    SELECT 9, 'Test User', NULL, 'Electronics', 1, 500, '2024-04-01'
)
SELECT
    COUNT(*)            AS total_rows,       -- Counts ALL rows including NULLs
    COUNT(product)      AS non_null_products -- Skips rows where product IS NULL
FROM orders_with_nulls;

-- Expected Output:
-- | total_rows | non_null_products |
-- |------------|-------------------|
-- | 9          | 8                 |
-- (Row 9 has NULL product → COUNT(product) = 8, COUNT(*) = 9)

-- How to COUNT the NULLs themselves:
WITH orders_with_nulls AS (
    SELECT order_id, customer_name, product, category, quantity, price, order_date
    FROM orders

    UNION ALL

    SELECT 9, 'Test User', NULL, 'Electronics', 1, 500, '2024-04-01'
)
SELECT
    COUNT(*) - COUNT(product) AS null_product_count
FROM orders_with_nulls;

-- Expected Output:
-- | null_product_count |
-- |--------------------|
-- | 1                  |

-- Alternative: Count NULLs using SUM + CASE
WITH orders_with_nulls AS (
    SELECT order_id, customer_name, product, category, quantity, price, order_date
    FROM orders

    UNION ALL

    SELECT 9, 'Test User', NULL, 'Electronics', 1, 500, '2024-04-01'
)
SELECT
    SUM(CASE WHEN product IS NULL THEN 1 ELSE 0 END) AS null_count
FROM orders_with_nulls;

-- Expected Output:
-- | null_count |
-- |------------|
-- | 1          |


-- ============================================================
-- 9️⃣ Real-World Use Cases
-- ============================================================

-- 📌 Use Case 1: Monthly order report
SELECT
    TO_CHAR(order_date, 'YYYY-MM') AS order_month,
    COUNT(*)                        AS total_orders
FROM orders
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY order_month;

-- Expected Output:
-- | order_month | total_orders |
-- |-------------|--------------|
-- | 2024-01     | 2            |
-- | 2024-02     | 3            |
-- | 2024-03     | 3            |

-- 📌 Use Case 2: Category-wise unique products count
SELECT
    category,
    COUNT(DISTINCT product) AS unique_products
FROM orders
GROUP BY category
ORDER BY unique_products DESC;

-- Expected Output:
-- | category    | unique_products |
-- |-------------|-----------------|
-- | Electronics | 4               |
-- | Furniture   | 2               |

-- 📌 Use Case 3: Customers with orders in multiple months
SELECT
    customer_name,
    COUNT(DISTINCT TO_CHAR(order_date, 'YYYY-MM')) AS months_active
FROM orders
GROUP BY customer_name
HAVING COUNT(DISTINCT TO_CHAR(order_date, 'YYYY-MM')) > 1;

-- Expected Output:
-- | customer_name | months_active |
-- |---------------|---------------|
-- | Amit Sharma   | 2             |
-- | Priya Verma   | 2             |


-- ============================================================
-- 🔑 KEY TAKEAWAYS
-- ============================================================
-- 1. COUNT(*)           → Counts ALL rows, including those with NULLs
-- 2. COUNT(column)      → Counts only NON-NULL values in that column
-- 3. COUNT(DISTINCT col)→ Counts only UNIQUE non-NULL values
-- 4. WHERE filters rows BEFORE counting
-- 5. GROUP BY + COUNT   → Gives count per group
-- 6. HAVING filters groups AFTER aggregation
-- 7. COUNT never returns NULL — it returns 0 if no rows match
-- 8. To count NULLs: COUNT(*) - COUNT(column)
-- ============================================================
