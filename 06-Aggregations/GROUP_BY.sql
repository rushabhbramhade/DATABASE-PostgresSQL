-- ============================================================
-- 📦 GROUP BY — Grouping Results in PostgreSQL
-- ============================================================
-- GROUP BY divides rows into groups based on column values,
-- then applies aggregate functions (COUNT, SUM, AVG, MIN, MAX)
-- to each group independently.
--
-- Think of it as: "For each _____, calculate _____."
--   → "For each category, calculate total revenue."
--   → "For each customer, count the number of orders."
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
-- 1️⃣ Basic GROUP BY — Single column grouping
-- ============================================================

-- Number of orders per category
SELECT
    category,
    COUNT(*) AS order_count
FROM orders
GROUP BY category;

-- Expected Output:
-- | category    | order_count |
-- |-------------|-------------|
-- | Electronics | 6           |
-- | Furniture   | 2           |

-- Total revenue per customer
SELECT
    customer_name,
    SUM(quantity * price) AS total_revenue
FROM orders
GROUP BY customer_name
ORDER BY total_revenue DESC;

-- Expected Output:
-- | customer_name | total_revenue |
-- |---------------|---------------|
-- | Amit Sharma   | 105000        |
-- | Vikram Singh  | 82000         |
-- | Karan Mehta   | 68000         |
-- | Rahul Gupta   | 12000         |
-- | Priya Verma   | 9500          |
-- | Sneha Patel   | 4000          |

-- Orders per product
SELECT
    product,
    COUNT(*) AS times_ordered,
    SUM(quantity) AS total_quantity
FROM orders
GROUP BY product
ORDER BY total_quantity DESC;

-- Expected Output:
-- | product    | times_ordered | total_quantity |
-- |------------|---------------|----------------|
-- | Laptop     | 3             | 3              |
-- | Mouse      | 1             | 3              |
-- | Monitor    | 1             | 2              |
-- | Keyboard   | 1             | 2              |
-- | Desk Chair | 1             | 1              |
-- | Bookshelf  | 1             | 1              |


-- ============================================================
-- 2️⃣ GROUP BY with Multiple Columns
-- ============================================================
-- When you group by multiple columns, each unique COMBINATION
-- of those columns forms a separate group.

-- Orders per customer per category
SELECT
    customer_name,
    category,
    COUNT(*) AS order_count,
    SUM(quantity * price) AS total_revenue
FROM orders
GROUP BY customer_name, category
ORDER BY customer_name, category;

-- Expected Output:
-- | customer_name | category    | order_count | total_revenue |
-- |---------------|-------------|-------------|---------------|
-- | Amit Sharma   | Electronics | 2           | 105000        |
-- | Karan Mehta   | Electronics | 1           | 68000         |
-- | Priya Verma   | Electronics | 1           | 1500          |
-- | Priya Verma   | Furniture   | 1           | 8000          |
-- | Rahul Gupta   | Furniture   | 1           | 12000         |
-- | Sneha Patel   | Electronics | 1           | 4000          |
-- | Vikram Singh  | Electronics | 1           | 82000         |

-- Orders per category per month
SELECT
    category,
    TO_CHAR(order_date, 'YYYY-MM') AS order_month,
    COUNT(*) AS order_count,
    SUM(quantity * price) AS revenue
FROM orders
GROUP BY category, TO_CHAR(order_date, 'YYYY-MM')
ORDER BY category, order_month;

-- Expected Output:
-- | category    | order_month | order_count | revenue |
-- |-------------|-------------|-------------|---------|
-- | Electronics | 2024-01     | 2           | 76500   |
-- | Electronics | 2024-02     | 2           | 86000   |
-- | Electronics | 2024-03     | 2           | 98000   |
-- | Furniture   | 2024-02     | 1           | 12000   |
-- | Furniture   | 2024-03     | 1           | 8000    |

-- Grouping by product and category (shows which category each product belongs to)
SELECT
    category,
    product,
    COUNT(*) AS times_ordered,
    ROUND(AVG(price), 2) AS avg_price
FROM orders
GROUP BY category, product
ORDER BY category, avg_price DESC;

-- Expected Output:
-- | category    | product    | times_ordered | avg_price |
-- |-------------|------------|---------------|-----------|
-- | Electronics | Laptop     | 3             | 75000.00  |
-- | Electronics | Monitor    | 1             | 15000.00  |
-- | Electronics | Keyboard   | 1             | 2000.00   |
-- | Electronics | Mouse      | 1             | 500.00    |
-- | Furniture   | Desk Chair | 1             | 12000.00  |
-- | Furniture   | Bookshelf  | 1             | 8000.00   |


-- ============================================================
-- 3️⃣ GROUP BY with HAVING — Filter groups
-- ============================================================
-- HAVING filters groups AFTER aggregation.
-- It's like WHERE, but for aggregate results.

-- Show only categories with more than 2 orders
SELECT
    category,
    COUNT(*) AS order_count
FROM orders
GROUP BY category
HAVING COUNT(*) > 2;

-- Expected Output:
-- | category    | order_count |
-- |-------------|-------------|
-- | Electronics | 6           |

-- Customers with total spending over ₹50,000
SELECT
    customer_name,
    SUM(quantity * price) AS total_spent
FROM orders
GROUP BY customer_name
HAVING SUM(quantity * price) > 50000
ORDER BY total_spent DESC;

-- Expected Output:
-- | customer_name | total_spent |
-- |---------------|-------------|
-- | Amit Sharma   | 105000      |
-- | Vikram Singh  | 82000       |
-- | Karan Mehta   | 68000       |

-- Products ordered more than once with average price above ₹50,000
SELECT
    product,
    COUNT(*) AS times_ordered,
    ROUND(AVG(price), 2) AS avg_price
FROM orders
GROUP BY product
HAVING COUNT(*) > 1
   AND AVG(price) > 50000;

-- Expected Output:
-- | product | times_ordered | avg_price |
-- |---------|---------------|-----------|
-- | Laptop  | 3             | 75000.00  |

-- Months with revenue above ₹90,000
SELECT
    TO_CHAR(order_date, 'YYYY-MM') AS order_month,
    SUM(quantity * price) AS monthly_revenue
FROM orders
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
HAVING SUM(quantity * price) > 90000
ORDER BY order_month;

-- Expected Output:
-- | order_month | monthly_revenue |
-- |-------------|-----------------|
-- | 2024-02     | 98000           |
-- | 2024-03     | 106000          |


-- ============================================================
-- 4️⃣ ⭐ WHERE vs HAVING — When each runs
-- ============================================================
--
-- ┌────────────────────────────────────────────────────────┐
-- │ SQL Execution Order:                                   │
-- │                                                        │
-- │  1. FROM      → Choose the table(s)                    │
-- │  2. WHERE     → Filter individual rows                 │
-- │  3. GROUP BY  → Group the remaining rows               │
-- │  4. HAVING    → Filter the groups                      │
-- │  5. SELECT    → Choose columns and compute expressions │
-- │  6. ORDER BY  → Sort the results                       │
-- │  7. LIMIT     → Restrict number of output rows         │
-- └────────────────────────────────────────────────────────┘
--
-- WHERE  → Filters ROWS before grouping (cannot use aggregates)
-- HAVING → Filters GROUPS after grouping (can use aggregates)

-- Example: Show Electronics categories with more than 1 order
-- WHERE filters rows first, then GROUP BY groups, then HAVING filters groups

SELECT
    category,
    COUNT(*) AS order_count,
    SUM(quantity * price) AS total_revenue
FROM orders
WHERE category = 'Electronics'     -- Step 1: Keep only Electronics rows
GROUP BY category                  -- Step 2: Group the filtered rows
HAVING COUNT(*) > 1;               -- Step 3: Keep groups with >1 order

-- Expected Output:
-- | category    | order_count | total_revenue |
-- |-------------|-------------|---------------|
-- | Electronics | 6           | 260500        |

-- ❌ WRONG: Using aggregate in WHERE
-- SELECT category, COUNT(*)
-- FROM orders
-- WHERE COUNT(*) > 2    -- ERROR! Cannot use aggregate in WHERE
-- GROUP BY category;

-- ✅ CORRECT: Use HAVING for aggregate conditions
SELECT category, COUNT(*)
FROM orders
GROUP BY category
HAVING COUNT(*) > 2;

-- When to use WHERE vs HAVING:
-- ┌──────────────────────────────────────────────────────────────────┐
-- │ Condition Type          │ Use WHERE          │ Use HAVING        │
-- │─────────────────────────│────────────────────│───────────────────│
-- │ Filter by column value  │ WHERE price > 1000 │ ✗ Not ideal       │
-- │ Filter by aggregate     │ ✗ Not allowed      │ HAVING SUM() > X  │
-- │ Filter before grouping  │ ✓ Yes              │ ✗ Too late         │
-- │ Filter after grouping   │ ✗ Too early        │ ✓ Yes              │
-- └──────────────────────────────────────────────────────────────────┘

-- Performance tip: Use WHERE to reduce rows BEFORE grouping.
-- This is more efficient than filtering with HAVING alone.

-- Less efficient (groups ALL rows, then filters):
SELECT category, COUNT(*) AS order_count
FROM orders
GROUP BY category
HAVING category = 'Electronics';

-- More efficient (filters rows FIRST, then groups):
SELECT category, COUNT(*) AS order_count
FROM orders
WHERE category = 'Electronics'
GROUP BY category;

-- Both produce the same result, but WHERE is faster because
-- fewer rows need to be grouped.


-- ============================================================
-- 5️⃣ GROUP BY with ORDER BY — Sorting grouped results
-- ============================================================

-- Categories sorted by revenue (highest first)
SELECT
    category,
    SUM(quantity * price) AS total_revenue
FROM orders
GROUP BY category
ORDER BY total_revenue DESC;

-- Expected Output:
-- | category    | total_revenue |
-- |-------------|---------------|
-- | Electronics | 260500        |
-- | Furniture   | 20000         |

-- Customers sorted by order count, then by name
SELECT
    customer_name,
    COUNT(*) AS order_count,
    SUM(quantity * price) AS total_revenue
FROM orders
GROUP BY customer_name
ORDER BY order_count DESC, customer_name ASC;

-- Expected Output:
-- | customer_name | order_count | total_revenue |
-- |---------------|-------------|---------------|
-- | Amit Sharma   | 2           | 105000        |
-- | Priya Verma   | 2           | 9500          |
-- | Karan Mehta   | 1           | 68000         |
-- | Rahul Gupta   | 1           | 12000         |
-- | Sneha Patel   | 1           | 4000          |
-- | Vikram Singh  | 1           | 82000         |

-- Monthly report sorted by month
SELECT
    TO_CHAR(order_date, 'YYYY-MM') AS order_month,
    COUNT(*) AS orders,
    SUM(quantity * price) AS revenue,
    ROUND(AVG(quantity * price), 2) AS avg_order_value
FROM orders
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY order_month;

-- Expected Output:
-- | order_month | orders | revenue | avg_order_value |
-- |-------------|--------|---------|-----------------|
-- | 2024-01     | 2      | 76500   | 38250.00        |
-- | 2024-02     | 3      | 98000   | 32666.67        |
-- | 2024-03     | 3      | 106000  | 35333.33        |

-- You can ORDER BY an aggregate even if it's not in SELECT
-- (PostgreSQL allows this)
SELECT category
FROM orders
GROUP BY category
ORDER BY COUNT(*) DESC;

-- Expected Output:
-- | category    |
-- |-------------|
-- | Electronics |
-- | Furniture   |


-- ============================================================
-- 6️⃣ ⚠️ Common Mistakes with GROUP BY
-- ============================================================

-- ❌ MISTAKE 1: Selecting a non-aggregated column not in GROUP BY
-- Every column in SELECT must either be in GROUP BY
-- or inside an aggregate function.

-- ❌ This will cause an ERROR:
-- SELECT customer_name, product, COUNT(*)
-- FROM orders
-- GROUP BY customer_name;
-- ERROR: column "orders.product" must appear in the GROUP BY clause
--        or be used in an aggregate function

-- ✅ Fix: Add product to GROUP BY:
SELECT customer_name, product, COUNT(*)
FROM orders
GROUP BY customer_name, product;

-- ✅ Or: Use an aggregate on product:
SELECT customer_name, COUNT(*), STRING_AGG(product, ', ') AS products
FROM orders
GROUP BY customer_name;

-- Expected Output:
-- | customer_name | count | products         |
-- |---------------|-------|------------------|
-- | Amit Sharma   | 2     | Laptop, Monitor  |
-- | Priya Verma   | 2     | Mouse, Bookshelf |
-- | Rahul Gupta   | 1     | Desk Chair       |
-- | Sneha Patel   | 1     | Keyboard         |
-- | Vikram Singh  | 1     | Laptop           |
-- | Karan Mehta   | 1     | Laptop           |


-- ❌ MISTAKE 2: Using column alias in HAVING
-- PostgreSQL does NOT allow aliases in HAVING.

-- ❌ This will cause an ERROR:
-- SELECT category, COUNT(*) AS order_count
-- FROM orders
-- GROUP BY category
-- HAVING order_count > 2;     -- ERROR: column "order_count" does not exist

-- ✅ Fix: Repeat the aggregate expression in HAVING:
SELECT category, COUNT(*) AS order_count
FROM orders
GROUP BY category
HAVING COUNT(*) > 2;


-- ❌ MISTAKE 3: Using WHERE instead of HAVING for aggregates
-- SELECT category, SUM(price)
-- FROM orders
-- GROUP BY category
-- WHERE SUM(price) > 50000;   -- ERROR: WHERE cannot use aggregates

-- ✅ Fix: Use HAVING:
SELECT category, SUM(price) AS total_price
FROM orders
GROUP BY category
HAVING SUM(price) > 50000;


-- ❌ MISTAKE 4: Forgetting GROUP BY with aggregates
-- SELECT category, COUNT(*)
-- FROM orders;
-- ERROR: column "category" must appear in GROUP BY or aggregate

-- ✅ Fix: Either add GROUP BY or remove the non-aggregate column:
SELECT category, COUNT(*)
FROM orders
GROUP BY category;

-- Or, if you want the total for the whole table:
SELECT COUNT(*)
FROM orders;


-- ============================================================
-- 7️⃣ All Aggregate Functions Combined — Comprehensive Report
-- ============================================================

-- 📌 Complete category-level analytics dashboard
SELECT
    category,
    COUNT(*)                              AS total_orders,
    COUNT(DISTINCT customer_name)         AS unique_customers,
    COUNT(DISTINCT product)               AS unique_products,
    SUM(quantity)                          AS total_items_sold,
    SUM(quantity * price)                  AS total_revenue,
    ROUND(AVG(quantity * price), 2)       AS avg_order_value,
    MIN(price)                            AS cheapest_product,
    MAX(price)                            AS priciest_product,
    MIN(order_date)                       AS first_order,
    MAX(order_date)                       AS last_order
FROM orders
GROUP BY category
ORDER BY total_revenue DESC;

-- Expected Output:
-- | category    | total_orders | unique_customers | unique_products | total_items_sold | total_revenue | avg_order_value | cheapest_product | priciest_product | first_order | last_order |
-- |-------------|-------------|------------------|-----------------|------------------|---------------|-----------------|------------------|------------------|-------------|------------|
-- | Electronics | 6           | 5                | 4               | 10               | 260500        | 43416.67        | 500              | 82000            | 2024-01-15  | 2024-03-20 |
-- | Furniture   | 2           | 2                | 2               | 2                | 20000         | 10000.00        | 8000             | 12000            | 2024-02-05  | 2024-03-10 |

-- 📌 Complete customer-level analytics dashboard
SELECT
    customer_name,
    COUNT(*)                              AS total_orders,
    COUNT(DISTINCT category)              AS categories_shopped,
    SUM(quantity)                          AS items_bought,
    SUM(quantity * price)                  AS total_spent,
    ROUND(AVG(quantity * price), 2)       AS avg_order_value,
    MIN(price)                            AS min_order_price,
    MAX(price)                            AS max_order_price,
    MIN(order_date)                       AS first_order,
    MAX(order_date)                       AS last_order,
    MAX(order_date) - MIN(order_date)     AS customer_lifespan_days
FROM orders
GROUP BY customer_name
ORDER BY total_spent DESC;

-- Expected Output:
-- | customer_name | total_orders | categories_shopped | items_bought | total_spent | avg_order_value | min_order_price | max_order_price | first_order | last_order | customer_lifespan_days |
-- |---------------|-------------|--------------------|--------------| ------------|-----------------|-----------------|-----------------|-------------|------------|------------------------|
-- | Amit Sharma   | 2           | 1                  | 3            | 105000      | 52500.00        | 15000           | 75000           | 2024-01-15  | 2024-03-01 | 46                     |
-- | Vikram Singh  | 1           | 1                  | 1            | 82000       | 82000.00        | 82000           | 82000           | 2024-02-15  | 2024-02-15 | 0                      |
-- | Karan Mehta   | 1           | 1                  | 1            | 68000       | 68000.00        | 68000           | 68000           | 2024-03-20  | 2024-03-20 | 0                      |
-- | Rahul Gupta   | 1           | 1                  | 1            | 12000       | 12000.00        | 12000           | 12000           | 2024-02-05  | 2024-02-05 | 0                      |
-- | Priya Verma   | 2           | 2                  | 4            | 9500        | 4750.00         | 500             | 8000            | 2024-01-20  | 2024-03-10 | 50                     |
-- | Sneha Patel   | 1           | 1                  | 2            | 4000        | 4000.00         | 2000            | 2000            | 2024-02-10  | 2024-02-10 | 0                      |


-- ============================================================
-- 8️⃣ GROUP BY with Expressions
-- ============================================================

-- Group by month using an expression
SELECT
    EXTRACT(MONTH FROM order_date) AS month_number,
    TO_CHAR(order_date, 'Month')   AS month_name,
    COUNT(*)                       AS order_count
FROM orders
GROUP BY EXTRACT(MONTH FROM order_date), TO_CHAR(order_date, 'Month')
ORDER BY month_number;

-- Expected Output:
-- | month_number | month_name | order_count |
-- |--------------|------------|-------------|
-- | 1            | January    | 2           |
-- | 2            | February   | 3           |
-- | 3            | March      | 3           |

-- Group by price tier using CASE
SELECT
    CASE
        WHEN price < 1000   THEN 'Budget (< ₹1K)'
        WHEN price < 10000  THEN 'Mid-Range (₹1K-10K)'
        WHEN price < 50000  THEN 'Premium (₹10K-50K)'
        ELSE                     'Luxury (₹50K+)'
    END AS price_tier,
    COUNT(*)              AS order_count,
    SUM(quantity * price) AS total_revenue
FROM orders
GROUP BY
    CASE
        WHEN price < 1000   THEN 'Budget (< ₹1K)'
        WHEN price < 10000  THEN 'Mid-Range (₹1K-10K)'
        WHEN price < 50000  THEN 'Premium (₹10K-50K)'
        ELSE                     'Luxury (₹50K+)'
    END
ORDER BY total_revenue DESC;

-- Expected Output:
-- | price_tier           | order_count | total_revenue |
-- |----------------------|-------------|---------------|
-- | Luxury (₹50K+)      | 3           | 225000        |
-- | Premium (₹10K-50K)  | 2           | 42000         |
-- | Mid-Range (₹1K-10K) | 2           | 12000         |
-- | Budget (< ₹1K)      | 1           | 1500          |

-- Group by day of week
SELECT
    TO_CHAR(order_date, 'Day') AS day_of_week,
    EXTRACT(DOW FROM order_date) AS day_number,
    COUNT(*) AS orders
FROM orders
GROUP BY TO_CHAR(order_date, 'Day'), EXTRACT(DOW FROM order_date)
ORDER BY day_number;

-- This shows which days of the week are busiest.


-- ============================================================
-- 9️⃣ GROUP BY with ROLLUP (Bonus: Subtotals)
-- ============================================================
-- ROLLUP creates subtotals and a grand total automatically.

SELECT
    COALESCE(category, '** GRAND TOTAL **') AS category,
    COUNT(*) AS order_count,
    SUM(quantity * price) AS total_revenue
FROM orders
GROUP BY ROLLUP(category)
ORDER BY category NULLS LAST;

-- Expected Output:
-- | category         | order_count | total_revenue |
-- |------------------|-------------|---------------|
-- | Electronics      | 6           | 260500        |
-- | Furniture        | 2           | 20000         |
-- | ** GRAND TOTAL **| 8           | 280500        |

-- Multi-level ROLLUP: Category → Product subtotals
SELECT
    COALESCE(category, '** ALL **') AS category,
    COALESCE(product, '** Subtotal **') AS product,
    COUNT(*) AS order_count,
    SUM(quantity * price) AS revenue
FROM orders
GROUP BY ROLLUP(category, product)
ORDER BY category NULLS LAST, product NULLS LAST;

-- Expected Output:
-- | category    | product        | order_count | revenue |
-- |-------------|----------------|-------------|---------|
-- | Electronics | Keyboard       | 1           | 4000    |
-- | Electronics | Laptop         | 3           | 225000  |
-- | Electronics | Monitor        | 1           | 30000   |
-- | Electronics | Mouse          | 1           | 1500    |
-- | Electronics | ** Subtotal ** | 6           | 260500  |
-- | Furniture   | Bookshelf      | 1           | 8000    |
-- | Furniture   | Desk Chair     | 1           | 12000   |
-- | Furniture   | ** Subtotal ** | 2           | 20000   |
-- | ** ALL **   | ** Subtotal ** | 8           | 280500  |


-- ============================================================
-- 🔑 KEY TAKEAWAYS
-- ============================================================
-- 1. GROUP BY groups rows with identical values in specified columns
-- 2. Every SELECT column must be in GROUP BY or in an aggregate function
-- 3. WHERE filters rows BEFORE grouping; HAVING filters AFTER
-- 4. GROUP BY multiple columns → groups by unique combinations
-- 5. ORDER BY can sort by aggregate values (e.g., ORDER BY COUNT(*) DESC)
-- 6. You can GROUP BY expressions (CASE, EXTRACT, TO_CHAR, etc.)
-- 7. Use ROLLUP for automatic subtotals and grand totals
-- 8. Column aliases CANNOT be used in HAVING (repeat the expression)
-- 9. SQL Execution Order: FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY
-- 10. Performance: Filter with WHERE first to reduce rows before grouping
-- ============================================================
