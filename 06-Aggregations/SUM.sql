-- ============================================================
-- 💰 SUM() — Summing Values in PostgreSQL
-- ============================================================
-- The SUM() function returns the total sum of a numeric column.
-- It ignores NULL values and is often used with GROUP BY
-- to calculate totals per category, customer, or time period.
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
-- 1️⃣ Basic SUM — Total of a single column
-- ============================================================

-- Total quantity of all items ordered
SELECT SUM(quantity) AS total_quantity
FROM orders;

-- Expected Output:
-- | total_quantity |
-- |----------------|
-- | 12             |
-- (1 + 3 + 1 + 2 + 1 + 2 + 1 + 1 = 12)

-- Total price across all orders (unit price, not revenue)
SELECT SUM(price) AS total_price
FROM orders;

-- Expected Output:
-- | total_price |
-- |-------------|
-- | 262500      |
-- (75000 + 500 + 12000 + 2000 + 82000 + 15000 + 8000 + 68000 = 262500)


-- ============================================================
-- 2️⃣ SUM with WHERE — Sum only filtered rows
-- ============================================================

-- Total price of Electronics orders only
SELECT SUM(price) AS electronics_total_price
FROM orders
WHERE category = 'Electronics';

-- Expected Output:
-- | electronics_total_price |
-- |-------------------------|
-- | 242500                  |
-- (75000 + 500 + 2000 + 82000 + 15000 + 68000 = 242500)

-- Total quantity ordered in January 2024
SELECT SUM(quantity) AS jan_quantity
FROM orders
WHERE order_date >= '2024-01-01'
  AND order_date < '2024-02-01';

-- Expected Output:
-- | jan_quantity |
-- |--------------|
-- | 4            |
-- (1 + 3 = 4)

-- Total price of Laptop orders
SELECT SUM(price) AS total_laptop_price
FROM orders
WHERE product = 'Laptop';

-- Expected Output:
-- | total_laptop_price |
-- |--------------------|
-- | 225000             |
-- (75000 + 82000 + 68000 = 225000)


-- ============================================================
-- 3️⃣ SUM with GROUP BY — Sum per group
-- ============================================================

-- Total spending by each customer (unit price sum)
SELECT
    customer_name,
    SUM(price) AS total_spent
FROM orders
GROUP BY customer_name
ORDER BY total_spent DESC;

-- Expected Output:
-- | customer_name | total_spent |
-- |---------------|-------------|
-- | Amit Sharma   | 90000       |
-- | Vikram Singh  | 82000       |
-- | Priya Verma   | 8500        |  ← Actually 500 + 8000 = 8500
-- | Karan Mehta   | 68000       |
-- | Rahul Gupta   | 12000       |
-- | Sneha Patel   | 2000        |

-- Total quantity sold per category
SELECT
    category,
    SUM(quantity) AS total_quantity
FROM orders
GROUP BY category
ORDER BY total_quantity DESC;

-- Expected Output:
-- | category    | total_quantity |
-- |-------------|----------------|
-- | Electronics | 10             |
-- | Furniture   | 2              |

-- Total revenue per month
SELECT
    TO_CHAR(order_date, 'YYYY-MM') AS order_month,
    SUM(price) AS monthly_price_total
FROM orders
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY order_month;

-- Expected Output:
-- | order_month | monthly_price_total |
-- |-------------|---------------------|
-- | 2024-01     | 75500               |
-- | 2024-02     | 96000               |
-- | 2024-03     | 91000               |


-- ============================================================
-- 4️⃣ SUM with Expressions — Calculated columns
-- ============================================================
-- You can use expressions inside SUM() to calculate
-- derived values like total revenue (quantity × price).

-- Total revenue (quantity * price) across all orders
SELECT SUM(quantity * price) AS total_revenue
FROM orders;

-- Expected Output:
-- | total_revenue |
-- |---------------|
-- | 299500        |
-- (1×75000 + 3×500 + 1×12000 + 2×2000 + 1×82000 + 2×15000 + 1×8000 + 1×68000)
-- (75000 + 1500 + 12000 + 4000 + 82000 + 30000 + 8000 + 68000 = 280500)

-- Revenue per customer
SELECT
    customer_name,
    SUM(quantity * price) AS customer_revenue
FROM orders
GROUP BY customer_name
ORDER BY customer_revenue DESC;

-- Expected Output:
-- | customer_name | customer_revenue |
-- |---------------|------------------|
-- | Amit Sharma   | 105000           |  ← (1×75000 + 2×15000)
-- | Vikram Singh  | 82000            |  ← (1×82000)
-- | Karan Mehta   | 68000            |  ← (1×68000)
-- | Rahul Gupta   | 12000            |  ← (1×12000)
-- | Priya Verma   | 9500             |  ← (3×500 + 1×8000)
-- | Sneha Patel   | 4000             |  ← (2×2000)

-- Revenue per category
SELECT
    category,
    SUM(quantity * price) AS category_revenue
FROM orders
GROUP BY category
ORDER BY category_revenue DESC;

-- Expected Output:
-- | category    | category_revenue |
-- |-------------|------------------|
-- | Electronics | 260500           |
-- | Furniture   | 20000            |


-- ============================================================
-- 5️⃣ SUM with CASE — Conditional Sums (Pivoting)
-- ============================================================
-- SUM + CASE lets you create conditional totals in a single
-- query — very useful for reporting and pivot-like results.

-- Revenue split by category in a single row
SELECT
    SUM(CASE WHEN category = 'Electronics' THEN quantity * price ELSE 0 END) AS electronics_revenue,
    SUM(CASE WHEN category = 'Furniture'   THEN quantity * price ELSE 0 END) AS furniture_revenue,
    SUM(quantity * price)                                                     AS total_revenue
FROM orders;

-- Expected Output:
-- | electronics_revenue | furniture_revenue | total_revenue |
-- |---------------------|-------------------|---------------|
-- | 260500              | 20000             | 280500        |

-- Monthly revenue breakdown by category
SELECT
    TO_CHAR(order_date, 'YYYY-MM') AS order_month,
    SUM(CASE WHEN category = 'Electronics' THEN quantity * price ELSE 0 END) AS electronics,
    SUM(CASE WHEN category = 'Furniture'   THEN quantity * price ELSE 0 END) AS furniture,
    SUM(quantity * price)                                                     AS monthly_total
FROM orders
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY order_month;

-- Expected Output:
-- | order_month | electronics | furniture | monthly_total |
-- |-------------|-------------|-----------|---------------|
-- | 2024-01     | 76500       | 0         | 76500         |
-- | 2024-02     | 86000       | 12000     | 98000         |
-- | 2024-03     | 98000       | 8000      | 106000        |

-- Count and sum in a single query using CASE
SELECT
    SUM(CASE WHEN price > 10000 THEN 1 ELSE 0 END)              AS high_value_count,
    SUM(CASE WHEN price > 10000 THEN quantity * price ELSE 0 END) AS high_value_revenue,
    SUM(CASE WHEN price <= 10000 THEN 1 ELSE 0 END)              AS low_value_count,
    SUM(CASE WHEN price <= 10000 THEN quantity * price ELSE 0 END) AS low_value_revenue
FROM orders;

-- Expected Output:
-- | high_value_count | high_value_revenue | low_value_count | low_value_revenue |
-- |------------------|--------------------|-----------------|-------------------|
-- | 5                | 267000             | 3               | 13500             |


-- ============================================================
-- 6️⃣ SUM with HAVING — Filter groups by total
-- ============================================================

-- Customers who spent more than ₹50,000 (by unit price)
SELECT
    customer_name,
    SUM(price) AS total_spent
FROM orders
GROUP BY customer_name
HAVING SUM(price) > 50000
ORDER BY total_spent DESC;

-- Expected Output:
-- | customer_name | total_spent |
-- |---------------|-------------|
-- | Amit Sharma   | 90000       |
-- | Vikram Singh  | 82000       |
-- | Karan Mehta   | 68000       |

-- Categories with total revenue over ₹100,000
SELECT
    category,
    SUM(quantity * price) AS category_revenue
FROM orders
GROUP BY category
HAVING SUM(quantity * price) > 100000;

-- Expected Output:
-- | category    | category_revenue |
-- |-------------|------------------|
-- | Electronics | 260500           |


-- ============================================================
-- 7️⃣ SUM and NULLs — Important Behavior
-- ============================================================
-- SUM() ignores NULL values. If ALL values are NULL,
-- SUM() returns NULL (not 0).

-- Demonstrating with a CTE:
WITH sample_data AS (
    SELECT 100 AS amount
    UNION ALL SELECT 200
    UNION ALL SELECT NULL
    UNION ALL SELECT 300
)
SELECT
    SUM(amount) AS total,         -- NULL is skipped
    COUNT(*)    AS total_rows,    -- NULL row is counted
    COUNT(amount) AS non_null_rows
FROM sample_data;

-- Expected Output:
-- | total | total_rows | non_null_rows |
-- |-------|------------|---------------|
-- | 600   | 4          | 3             |

-- Using COALESCE to treat NULLs as 0:
WITH sample_data AS (
    SELECT 100 AS amount
    UNION ALL SELECT NULL
    UNION ALL SELECT 200
)
SELECT
    SUM(COALESCE(amount, 0)) AS safe_total
FROM sample_data;

-- Expected Output:
-- | safe_total |
-- |------------|
-- | 300        |


-- ============================================================
-- 8️⃣ SUM(DISTINCT) — Sum unique values only
-- ============================================================

SELECT
    SUM(price)          AS total_price,
    SUM(DISTINCT price) AS sum_of_unique_prices
FROM orders;

-- Expected Output:
-- | total_price | sum_of_unique_prices |
-- |-------------|----------------------|
-- | 262500      | 262500               |
-- (All prices happen to be unique in our data, so both are equal)


-- ============================================================
-- 9️⃣ Running Totals Preview (Window Function)
-- ============================================================
-- A running total accumulates the sum row by row.
-- This uses SUM() as a WINDOW function (covered in detail later).

SELECT
    order_id,
    customer_name,
    product,
    quantity * price AS order_revenue,
    SUM(quantity * price) OVER (ORDER BY order_date) AS running_total
FROM orders
ORDER BY order_date;

-- Expected Output:
-- | order_id | customer_name | product    | order_revenue | running_total |
-- |----------|---------------|------------|---------------|---------------|
-- | 1        | Amit Sharma   | Laptop     | 75000         | 75000         |
-- | 2        | Priya Verma   | Mouse      | 1500          | 76500         |
-- | 3        | Rahul Gupta   | Desk Chair | 12000         | 88500         |
-- | 4        | Sneha Patel   | Keyboard   | 4000          | 92500         |
-- | 5        | Vikram Singh  | Laptop     | 82000         | 174500        |
-- | 6        | Amit Sharma   | Monitor    | 30000         | 204500        |
-- | 7        | Priya Verma   | Bookshelf  | 8000          | 212500        |
-- | 8        | Karan Mehta   | Laptop     | 68000         | 280500        |

-- Running total per customer (partitioned)
SELECT
    customer_name,
    order_date,
    product,
    quantity * price AS order_revenue,
    SUM(quantity * price) OVER (
        PARTITION BY customer_name
        ORDER BY order_date
    ) AS customer_running_total
FROM orders
ORDER BY customer_name, order_date;

-- Expected Output:
-- | customer_name | order_date | product   | order_revenue | customer_running_total |
-- |---------------|------------|-----------|---------------|------------------------|
-- | Amit Sharma   | 2024-01-15 | Laptop    | 75000         | 75000                  |
-- | Amit Sharma   | 2024-03-01 | Monitor   | 30000         | 105000                 |
-- | Karan Mehta   | 2024-03-20 | Laptop    | 68000         | 68000                  |
-- | Priya Verma   | 2024-01-20 | Mouse     | 1500          | 1500                   |
-- | Priya Verma   | 2024-03-10 | Bookshelf | 8000          | 9500                   |
-- | ... and so on


-- ============================================================
-- 🔑 KEY TAKEAWAYS
-- ============================================================
-- 1. SUM(column)         → Adds up all non-NULL values in the column
-- 2. SUM(expression)     → You can sum calculated values like quantity * price
-- 3. SUM ignores NULLs   → Use COALESCE(col, 0) if you want NULLs treated as 0
-- 4. SUM with GROUP BY   → Gives totals per group (customer, category, month)
-- 5. SUM with CASE       → Conditional sums for pivot-style reports
-- 6. SUM with HAVING     → Filters groups by their total
-- 7. SUM returns NULL if ALL values are NULL (not 0!)
-- 8. SUM() OVER(...)     → Window function for running totals (advanced)
-- 9. SUM(DISTINCT col)   → Sums only unique values
-- ============================================================
