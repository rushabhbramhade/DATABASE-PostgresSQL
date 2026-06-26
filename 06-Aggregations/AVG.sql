-- ============================================================
-- 📈 AVG() — Averaging Values in PostgreSQL
-- ============================================================
-- The AVG() function returns the arithmetic mean of a numeric
-- column. It automatically ignores NULL values, which can
-- lead to unexpected results if you're not careful.
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
-- 1️⃣ Basic AVG — Average of a column
-- ============================================================

-- Average unit price across all orders
SELECT AVG(price) AS avg_price
FROM orders;

-- Expected Output:
-- | avg_price              |
-- |------------------------|
-- | 32812.5000000000000000 |
-- (262500 / 8 = 32812.50)

-- Average quantity per order
SELECT AVG(quantity) AS avg_quantity
FROM orders;

-- Expected Output:
-- | avg_quantity           |
-- |------------------------|
-- | 1.5000000000000000     |
-- (12 / 8 = 1.5)


-- ============================================================
-- 2️⃣ AVG with ROUND() — Clean decimal output
-- ============================================================
-- PostgreSQL AVG returns many decimal places by default.
-- Use ROUND() to control precision.

-- Round to 2 decimal places
SELECT ROUND(AVG(price), 2) AS avg_price
FROM orders;

-- Expected Output:
-- | avg_price |
-- |-----------|
-- | 32812.50  |

-- Round to nearest integer
SELECT ROUND(AVG(price), 0) AS avg_price_rounded
FROM orders;

-- Expected Output:
-- | avg_price_rounded |
-- |-------------------|
-- | 32813             |

-- Average order revenue (quantity × price), rounded
SELECT ROUND(AVG(quantity * price), 2) AS avg_order_revenue
FROM orders;

-- Expected Output:
-- | avg_order_revenue |
-- |-------------------|
-- | 35062.50          |
-- (280500 / 8 = 35062.50)


-- ============================================================
-- 3️⃣ AVG with WHERE — Average of filtered rows
-- ============================================================

-- Average price of Electronics products
SELECT ROUND(AVG(price), 2) AS avg_electronics_price
FROM orders
WHERE category = 'Electronics';

-- Expected Output:
-- | avg_electronics_price |
-- |-----------------------|
-- | 40416.67              |
-- (242500 / 6 = 40416.67)

-- Average price of Furniture products
SELECT ROUND(AVG(price), 2) AS avg_furniture_price
FROM orders
WHERE category = 'Furniture';

-- Expected Output:
-- | avg_furniture_price |
-- |---------------------|
-- | 10000.00            |
-- (20000 / 2 = 10000)

-- Average price of orders placed in 2024 Q1 (Jan-Mar)
SELECT ROUND(AVG(price), 2) AS avg_q1_price
FROM orders
WHERE order_date >= '2024-01-01'
  AND order_date < '2024-04-01';

-- Expected Output:
-- | avg_q1_price |
-- |--------------|
-- | 32812.50     |


-- ============================================================
-- 4️⃣ AVG with GROUP BY — Average per group
-- ============================================================

-- Average price per category
SELECT
    category,
    ROUND(AVG(price), 2) AS avg_price
FROM orders
GROUP BY category
ORDER BY avg_price DESC;

-- Expected Output:
-- | category    | avg_price |
-- |-------------|-----------|
-- | Electronics | 40416.67  |
-- | Furniture   | 10000.00  |

-- Average price per product
SELECT
    product,
    ROUND(AVG(price), 2) AS avg_price,
    COUNT(*)              AS order_count
FROM orders
GROUP BY product
ORDER BY avg_price DESC;

-- Expected Output:
-- | product    | avg_price | order_count |
-- |------------|-----------|-------------|
-- | Laptop     | 75000.00  | 3           |
-- | Monitor    | 15000.00  | 1           |
-- | Desk Chair | 12000.00  | 1           |
-- | Bookshelf  | 8000.00   | 1           |
-- | Keyboard   | 2000.00   | 1           |
-- | Mouse      | 500.00    | 1           |

-- Average order revenue per customer
SELECT
    customer_name,
    ROUND(AVG(quantity * price), 2) AS avg_order_revenue
FROM orders
GROUP BY customer_name
ORDER BY avg_order_revenue DESC;

-- Expected Output:
-- | customer_name | avg_order_revenue |
-- |---------------|-------------------|
-- | Vikram Singh  | 82000.00          |
-- | Karan Mehta   | 68000.00          |
-- | Amit Sharma   | 52500.00          |
-- | Rahul Gupta   | 12000.00          |
-- | Priya Verma   | 4750.00           |
-- | Sneha Patel   | 4000.00           |

-- Average price per month
SELECT
    TO_CHAR(order_date, 'YYYY-MM') AS order_month,
    ROUND(AVG(price), 2) AS avg_price
FROM orders
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY order_month;

-- Expected Output:
-- | order_month | avg_price |
-- |-------------|-----------|
-- | 2024-01     | 37750.00  |
-- | 2024-02     | 32000.00  |
-- | 2024-03     | 30333.33  |


-- ============================================================
-- 5️⃣ AVG Ignores NULLs — Critical Behavior
-- ============================================================
-- AVG() only considers non-NULL values. This means the
-- denominator changes depending on how many NULLs exist.

-- Example: AVG skipping NULLs
WITH scores AS (
    SELECT 80 AS score
    UNION ALL SELECT 90
    UNION ALL SELECT NULL
    UNION ALL SELECT 70
)
SELECT
    AVG(score)                    AS avg_ignoring_nulls,
    -- Result: (80 + 90 + 70) / 3 = 80.00
    SUM(score)::NUMERIC / COUNT(*) AS avg_including_nulls
    -- Result: 240 / 4 = 60.00
FROM scores;

-- Expected Output:
-- | avg_ignoring_nulls     | avg_including_nulls    |
-- |------------------------|------------------------|
-- | 80.0000000000000000    | 60.0000000000000000    |

-- ⚠️ The difference: AVG divides by 3 (non-NULL count),
--    but if you want NULLs treated as 0, divide by COUNT(*):

WITH scores AS (
    SELECT 80 AS score
    UNION ALL SELECT 90
    UNION ALL SELECT NULL
    UNION ALL SELECT 70
)
SELECT
    ROUND(AVG(COALESCE(score, 0)), 2) AS avg_nulls_as_zero
    -- COALESCE turns NULL → 0, then AVG divides by 4
FROM scores;

-- Expected Output:
-- | avg_nulls_as_zero |
-- |-------------------|
-- | 60.00             |


-- ============================================================
-- 6️⃣ Comparing Individual Values to the Average
-- ============================================================
-- A common reporting pattern: show each row's value alongside
-- the overall average, and the difference from average.

-- Each order's price compared to overall average
SELECT
    order_id,
    customer_name,
    product,
    price,
    ROUND(AVG(price) OVER (), 2) AS overall_avg_price,
    ROUND(price - AVG(price) OVER (), 2) AS diff_from_avg
FROM orders
ORDER BY diff_from_avg DESC;

-- Expected Output:
-- | order_id | customer_name | product    | price | overall_avg_price | diff_from_avg |
-- |----------|---------------|------------|-------|-------------------|---------------|
-- | 5        | Vikram Singh  | Laptop     | 82000 | 32812.50          | 49187.50      |
-- | 1        | Amit Sharma   | Laptop     | 75000 | 32812.50          | 42187.50      |
-- | 8        | Karan Mehta   | Laptop     | 68000 | 32812.50          | 35187.50      |
-- | 6        | Amit Sharma   | Monitor    | 15000 | 32812.50          | -17812.50     |
-- | 3        | Rahul Gupta   | Desk Chair | 12000 | 32812.50          | -20812.50     |
-- | 7        | Priya Verma   | Bookshelf  | 8000  | 32812.50          | -24812.50     |
-- | 4        | Sneha Patel   | Keyboard   | 2000  | 32812.50          | -30812.50     |
-- | 2        | Priya Verma   | Mouse      | 500   | 32812.50          | -32312.50     |

-- Compare each order to its category's average
SELECT
    order_id,
    product,
    category,
    price,
    ROUND(AVG(price) OVER (PARTITION BY category), 2) AS category_avg,
    ROUND(price - AVG(price) OVER (PARTITION BY category), 2) AS diff_from_category_avg
FROM orders
ORDER BY category, diff_from_category_avg DESC;

-- Expected Output:
-- | order_id | product    | category    | price | category_avg | diff_from_category_avg |
-- |----------|------------|-------------|-------|--------------|------------------------|
-- | 5        | Laptop     | Electronics | 82000 | 40416.67     | 41583.33               |
-- | 1        | Laptop     | Electronics | 75000 | 40416.67     | 34583.33               |
-- | 8        | Laptop     | Electronics | 68000 | 40416.67     | 27583.33               |
-- | 6        | Monitor    | Electronics | 15000 | 40416.67     | -25416.67              |
-- | 4        | Keyboard   | Electronics | 2000  | 40416.67     | -38416.67              |
-- | 2        | Mouse      | Electronics | 500   | 40416.67     | -39916.67              |
-- | 3        | Desk Chair | Furniture   | 12000 | 10000.00     | 2000.00                |
-- | 7        | Bookshelf  | Furniture   | 8000  | 10000.00     | -2000.00               |

-- Find orders with price above their category's average
SELECT
    order_id,
    product,
    category,
    price
FROM orders o
WHERE price > (
    SELECT AVG(price)
    FROM orders
    WHERE category = o.category
);

-- Expected Output:
-- | order_id | product    | category    | price |
-- |----------|------------|-------------|-------|
-- | 1        | Laptop     | Electronics | 75000 |
-- | 5        | Laptop     | Electronics | 82000 |
-- | 8        | Laptop     | Electronics | 68000 |
-- | 3        | Desk Chair | Furniture   | 12000 |


-- ============================================================
-- 7️⃣ Weighted Averages — When each value has different weight
-- ============================================================
-- A weighted average considers the "importance" (weight)
-- of each value. Formula: SUM(value × weight) / SUM(weight)
--
-- Example: The average price of products should consider
-- quantity (how many were ordered). A product ordered 3 times
-- should "count" 3 times more than one ordered once.

-- Weighted average price (weighted by quantity)
SELECT
    ROUND(
        SUM(price * quantity)::NUMERIC / SUM(quantity),
        2
    ) AS weighted_avg_price
FROM orders;

-- Expected Output:
-- | weighted_avg_price |
-- |--------------------|
-- | 23375.00           |
-- (280500 / 12 = 23375.00)

-- Compare: simple vs weighted average
SELECT
    ROUND(AVG(price), 2) AS simple_avg,
    ROUND(SUM(price * quantity)::NUMERIC / SUM(quantity), 2) AS weighted_avg
FROM orders;

-- Expected Output:
-- | simple_avg | weighted_avg |
-- |------------|--------------|
-- | 32812.50   | 23375.00     |
-- (Weighted is lower because cheaper items were ordered in higher quantities)

-- Weighted average price per category
SELECT
    category,
    ROUND(AVG(price), 2) AS simple_avg,
    ROUND(
        SUM(price * quantity)::NUMERIC / SUM(quantity),
        2
    ) AS weighted_avg
FROM orders
GROUP BY category
ORDER BY category;

-- Expected Output:
-- | category    | simple_avg | weighted_avg |
-- |-------------|------------|--------------|
-- | Electronics | 40416.67   | 26050.00     |
-- | Furniture   | 10000.00   | 10000.00     |
-- (Furniture stays same because both items have quantity = 1)


-- ============================================================
-- 8️⃣ AVG with HAVING — Filter groups by average
-- ============================================================

-- Categories with average price above ₹20,000
SELECT
    category,
    ROUND(AVG(price), 2) AS avg_price
FROM orders
GROUP BY category
HAVING AVG(price) > 20000;

-- Expected Output:
-- | category    | avg_price |
-- |-------------|-----------|
-- | Electronics | 40416.67  |

-- Products with average price above ₹50,000
-- (only products ordered more than once could differ)
SELECT
    product,
    COUNT(*)              AS times_ordered,
    ROUND(AVG(price), 2) AS avg_price
FROM orders
GROUP BY product
HAVING AVG(price) > 50000
ORDER BY avg_price DESC;

-- Expected Output:
-- | product | times_ordered | avg_price |
-- |---------|---------------|-----------|
-- | Laptop  | 3             | 75000.00  |


-- ============================================================
-- 9️⃣ Practical Real-World Examples
-- ============================================================

-- 📌 Dashboard: Category summary with all stats
SELECT
    category,
    COUNT(*)                              AS total_orders,
    SUM(quantity)                          AS total_items,
    ROUND(AVG(price), 2)                  AS avg_unit_price,
    ROUND(AVG(quantity * price), 2)       AS avg_order_value,
    SUM(quantity * price)                  AS total_revenue
FROM orders
GROUP BY category
ORDER BY total_revenue DESC;

-- Expected Output:
-- | category    | total_orders | total_items | avg_unit_price | avg_order_value | total_revenue |
-- |-------------|-------------|-------------|----------------|-----------------|---------------|
-- | Electronics | 6           | 10          | 40416.67       | 43416.67        | 260500        |
-- | Furniture   | 2           | 2           | 10000.00       | 10000.00        | 20000         |

-- 📌 Identify "above average" customers
WITH customer_totals AS (
    SELECT
        customer_name,
        SUM(quantity * price) AS total_revenue
    FROM orders
    GROUP BY customer_name
)
SELECT
    customer_name,
    total_revenue,
    ROUND((SELECT AVG(total_revenue) FROM customer_totals), 2) AS avg_customer_revenue,
    CASE
        WHEN total_revenue > (SELECT AVG(total_revenue) FROM customer_totals)
        THEN 'Above Average'
        ELSE 'Below Average'
    END AS performance
FROM customer_totals
ORDER BY total_revenue DESC;

-- Expected Output:
-- | customer_name | total_revenue | avg_customer_revenue | performance   |
-- |---------------|---------------|----------------------|---------------|
-- | Amit Sharma   | 105000        | 46750.00             | Above Average |
-- | Vikram Singh  | 82000         | 46750.00             | Above Average |
-- | Karan Mehta   | 68000         | 46750.00             | Above Average |
-- | Rahul Gupta   | 12000         | 46750.00             | Below Average |
-- | Priya Verma   | 9500          | 46750.00             | Below Average |
-- | Sneha Patel   | 4000          | 46750.00             | Below Average |


-- ============================================================
-- 🔑 KEY TAKEAWAYS
-- ============================================================
-- 1. AVG(column)           → Returns the arithmetic mean of non-NULL values
-- 2. AVG ignores NULLs     → The denominator only counts non-NULL rows
-- 3. Use ROUND(AVG(...), N)→ To control decimal places in output
-- 4. AVG with GROUP BY     → Gives average per group
-- 5. AVG with HAVING       → Filters groups by their average
-- 6. Window: AVG() OVER()  → Compare individual rows to averages
-- 7. Weighted Average      → SUM(value * weight) / SUM(weight)
-- 8. COALESCE(col, 0)      → Use before AVG if NULLs should count as zero
-- 9. AVG returns NULL if ALL values are NULL
-- ============================================================
