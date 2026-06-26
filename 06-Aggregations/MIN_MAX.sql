-- ============================================================
-- 🔍 MIN() & MAX() — Finding Extremes in PostgreSQL
-- ============================================================
-- MIN() returns the smallest value in a column.
-- MAX() returns the largest value in a column.
-- Both ignore NULL values and work with numbers, dates,
-- and even text (alphabetical ordering).
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
-- 1️⃣ MIN and MAX for Numbers
-- ============================================================

-- Cheapest and most expensive product prices
SELECT
    MIN(price) AS cheapest_price,
    MAX(price) AS most_expensive_price
FROM orders;

-- Expected Output:
-- | cheapest_price | most_expensive_price |
-- |----------------|----------------------|
-- | 500            | 82000                |

-- Smallest and largest order quantities
SELECT
    MIN(quantity) AS min_quantity,
    MAX(quantity) AS max_quantity
FROM orders;

-- Expected Output:
-- | min_quantity | max_quantity |
-- |-------------|-------------|
-- | 1           | 3           |

-- Range of prices (difference between max and min)
SELECT
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    MAX(price) - MIN(price) AS price_range
FROM orders;

-- Expected Output:
-- | min_price | max_price | price_range |
-- |-----------|-----------|-------------|
-- | 500       | 82000     | 81500       |

-- Smallest and largest order revenue (quantity × price)
SELECT
    MIN(quantity * price) AS min_revenue,
    MAX(quantity * price) AS max_revenue
FROM orders;

-- Expected Output:
-- | min_revenue | max_revenue |
-- |-------------|-------------|
-- | 1500        | 82000       |
-- (Min: 3×500=1500 for Mouse, Max: 1×82000 for Laptop)


-- ============================================================
-- 2️⃣ MIN and MAX for Dates
-- ============================================================

-- Earliest and latest order dates
SELECT
    MIN(order_date) AS first_order,
    MAX(order_date) AS latest_order
FROM orders;

-- Expected Output:
-- | first_order | latest_order |
-- |-------------|--------------|
-- | 2024-01-15  | 2024-03-20   |

-- Date range: how many days between first and last order?
SELECT
    MIN(order_date) AS first_order,
    MAX(order_date) AS latest_order,
    MAX(order_date) - MIN(order_date) AS days_span
FROM orders;

-- Expected Output:
-- | first_order | latest_order | days_span |
-- |-------------|--------------|-----------|
-- | 2024-01-15  | 2024-03-20   | 65        |

-- Earliest order date per customer
SELECT
    customer_name,
    MIN(order_date) AS first_order_date
FROM orders
GROUP BY customer_name
ORDER BY first_order_date;

-- Expected Output:
-- | customer_name | first_order_date |
-- |---------------|------------------|
-- | Amit Sharma   | 2024-01-15       |
-- | Priya Verma   | 2024-01-20       |
-- | Rahul Gupta   | 2024-02-05       |
-- | Sneha Patel   | 2024-02-10       |
-- | Vikram Singh  | 2024-02-15       |
-- | Karan Mehta   | 2024-03-20       |


-- ============================================================
-- 3️⃣ MIN and MAX for Text (Alphabetical Ordering)
-- ============================================================
-- For text columns, MIN returns the alphabetically first value
-- and MAX returns the alphabetically last value.

-- Alphabetically first and last customer names
SELECT
    MIN(customer_name) AS first_alphabetically,
    MAX(customer_name) AS last_alphabetically
FROM orders;

-- Expected Output:
-- | first_alphabetically | last_alphabetically |
-- |----------------------|---------------------|
-- | Amit Sharma          | Vikram Singh        |

-- Alphabetically first and last product names
SELECT
    MIN(product) AS first_product,
    MAX(product) AS last_product
FROM orders;

-- Expected Output:
-- | first_product | last_product |
-- |---------------|--------------|
-- | Bookshelf     | Mouse        |

-- First and last product name per category
SELECT
    category,
    MIN(product) AS first_product,
    MAX(product) AS last_product
FROM orders
GROUP BY category;

-- Expected Output:
-- | category    | first_product | last_product |
-- |-------------|---------------|--------------|
-- | Electronics | Keyboard      | Mouse        |
-- | Furniture   | Bookshelf     | Desk Chair   |


-- ============================================================
-- 4️⃣ MIN and MAX with GROUP BY
-- ============================================================

-- Price range per category
SELECT
    category,
    MIN(price) AS cheapest,
    MAX(price) AS most_expensive,
    MAX(price) - MIN(price) AS price_range
FROM orders
GROUP BY category
ORDER BY price_range DESC;

-- Expected Output:
-- | category    | cheapest | most_expensive | price_range |
-- |-------------|----------|----------------|-------------|
-- | Electronics | 500      | 82000          | 81500       |
-- | Furniture   | 8000     | 12000          | 4000        |

-- Price range per product (meaningful for products ordered multiple times)
SELECT
    product,
    COUNT(*)    AS times_ordered,
    MIN(price)  AS min_price,
    MAX(price)  AS max_price,
    MAX(price) - MIN(price) AS price_variation
FROM orders
GROUP BY product
HAVING COUNT(*) > 1
ORDER BY price_variation DESC;

-- Expected Output:
-- | product | times_ordered | min_price | max_price | price_variation |
-- |---------|---------------|-----------|-----------|-----------------|
-- | Laptop  | 3             | 68000     | 82000     | 14000           |

-- Date range per customer (first and last order)
SELECT
    customer_name,
    MIN(order_date) AS first_order,
    MAX(order_date) AS last_order,
    MAX(order_date) - MIN(order_date) AS days_as_customer
FROM orders
GROUP BY customer_name
ORDER BY days_as_customer DESC;

-- Expected Output:
-- | customer_name | first_order | last_order | days_as_customer |
-- |---------------|-------------|------------|------------------|
-- | Amit Sharma   | 2024-01-15  | 2024-03-01 | 46               |
-- | Priya Verma   | 2024-01-20  | 2024-03-10 | 50               |
-- | Rahul Gupta   | 2024-02-05  | 2024-02-05 | 0                |
-- | Sneha Patel   | 2024-02-10  | 2024-02-10 | 0                |
-- | Vikram Singh  | 2024-02-15  | 2024-02-15 | 0                |
-- | Karan Mehta   | 2024-03-20  | 2024-03-20 | 0                |

-- Monthly min and max order values
SELECT
    TO_CHAR(order_date, 'YYYY-MM') AS order_month,
    MIN(quantity * price) AS min_order_value,
    MAX(quantity * price) AS max_order_value
FROM orders
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY order_month;

-- Expected Output:
-- | order_month | min_order_value | max_order_value |
-- |-------------|-----------------|-----------------|
-- | 2024-01     | 1500            | 75000           |
-- | 2024-02     | 4000            | 82000           |
-- | 2024-03     | 8000            | 68000           |


-- ============================================================
-- 5️⃣ MIN/MAX with WHERE — Extremes in filtered data
-- ============================================================

-- Most expensive Electronics product
SELECT MAX(price) AS max_electronics_price
FROM orders
WHERE category = 'Electronics';

-- Expected Output:
-- | max_electronics_price |
-- |-----------------------|
-- | 82000                 |

-- Cheapest Furniture product
SELECT MIN(price) AS min_furniture_price
FROM orders
WHERE category = 'Furniture';

-- Expected Output:
-- | min_furniture_price |
-- |---------------------|
-- | 8000                |

-- Latest order by Amit Sharma
SELECT MAX(order_date) AS last_order_by_amit
FROM orders
WHERE customer_name = 'Amit Sharma';

-- Expected Output:
-- | last_order_by_amit |
-- |--------------------|
-- | 2024-03-01         |


-- ============================================================
-- 6️⃣ Combining MIN/MAX with Other Aggregates
-- ============================================================

-- Complete summary statistics per category
SELECT
    category,
    COUNT(*)               AS total_orders,
    MIN(price)             AS min_price,
    MAX(price)             AS max_price,
    ROUND(AVG(price), 2)   AS avg_price,
    SUM(quantity * price)  AS total_revenue
FROM orders
GROUP BY category
ORDER BY total_revenue DESC;

-- Expected Output:
-- | category    | total_orders | min_price | max_price | avg_price | total_revenue |
-- |-------------|-------------|-----------|-----------|-----------|---------------|
-- | Electronics | 6           | 500       | 82000     | 40416.67  | 260500        |
-- | Furniture   | 2           | 8000      | 12000     | 10000.00  | 20000         |


-- ============================================================
-- 7️⃣ ⭐ Finding the ROW with the MAX/MIN Value
--    (Common Interview Question!)
-- ============================================================
-- MIN/MAX give you the value, but NOT the entire row.
-- Here are multiple approaches to find the full row.

-- ❌ WRONG: This does NOT work — you can't mix aggregate and non-aggregate columns
-- SELECT customer_name, product, MAX(price) FROM orders;  -- ERROR!

-- ✅ Method 1: Subquery
SELECT *
FROM orders
WHERE price = (SELECT MAX(price) FROM orders);

-- Expected Output:
-- | order_id | customer_name | product | category    | quantity | price | order_date |
-- |----------|---------------|---------|-------------|----------|-------|------------|
-- | 5        | Vikram Singh  | Laptop  | Electronics | 1        | 82000 | 2024-02-15 |

-- ✅ Method 2: ORDER BY + LIMIT (simplest, most common)
SELECT *
FROM orders
ORDER BY price DESC
LIMIT 1;

-- Expected Output: Same as above (order_id = 5, Vikram Singh, Laptop, 82000)

-- ✅ Method 3: Using FETCH FIRST (SQL standard syntax)
SELECT *
FROM orders
ORDER BY price DESC
FETCH FIRST 1 ROW ONLY;

-- Expected Output: Same as above

-- ✅ Method 4: Using a CTE with RANK (handles ties!)
WITH ranked_orders AS (
    SELECT *,
        RANK() OVER (ORDER BY price DESC) AS price_rank
    FROM orders
)
SELECT *
FROM ranked_orders
WHERE price_rank = 1;

-- Expected Output: Returns ALL rows tied for the highest price
-- | order_id | customer_name | product | category    | quantity | price | order_date | price_rank |
-- |----------|---------------|---------|-------------|----------|-------|------------|------------|
-- | 5        | Vikram Singh  | Laptop  | Electronics | 1        | 82000 | 2024-02-15 | 1          |

-- ✅ Method 5: Most expensive order PER CATEGORY (very common!)
-- Find the order with the highest price in each category
WITH ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY price DESC) AS rn
    FROM orders
)
SELECT
    order_id, customer_name, product, category, quantity, price, order_date
FROM ranked
WHERE rn = 1;

-- Expected Output:
-- | order_id | customer_name | product    | category    | quantity | price | order_date |
-- |----------|---------------|------------|-------------|----------|-------|------------|
-- | 5        | Vikram Singh  | Laptop     | Electronics | 1        | 82000 | 2024-02-15 |
-- | 3        | Rahul Gupta   | Desk Chair | Furniture   | 1        | 12000 | 2024-02-05 |

-- Cheapest order per category
WITH ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY price ASC) AS rn
    FROM orders
)
SELECT
    order_id, customer_name, product, category, quantity, price, order_date
FROM ranked
WHERE rn = 1;

-- Expected Output:
-- | order_id | customer_name | product   | category    | quantity | price | order_date |
-- |----------|---------------|-----------|-------------|----------|-------|------------|
-- | 2        | Priya Verma   | Mouse     | Electronics | 3        | 500   | 2024-01-20 |
-- | 7        | Priya Verma   | Bookshelf | Furniture   | 1        | 8000  | 2024-03-10 |


-- ============================================================
-- 8️⃣ MIN/MAX with HAVING
-- ============================================================

-- Categories where the most expensive item costs over ₹50,000
SELECT
    category,
    MAX(price) AS max_price
FROM orders
GROUP BY category
HAVING MAX(price) > 50000;

-- Expected Output:
-- | category    | max_price |
-- |-------------|-----------|
-- | Electronics | 82000     |

-- Customers whose cheapest order was still above ₹5,000
SELECT
    customer_name,
    MIN(price) AS cheapest_order
FROM orders
GROUP BY customer_name
HAVING MIN(price) > 5000
ORDER BY cheapest_order DESC;

-- Expected Output:
-- | customer_name | cheapest_order |
-- |---------------|----------------|
-- | Vikram Singh  | 82000          |
-- | Karan Mehta   | 68000          |
-- | Amit Sharma   | 15000          |
-- | Rahul Gupta   | 12000          |
-- | Priya Verma   | 500            |  ← Excluded! (500 < 5000)
-- | Sneha Patel   | 2000           |  ← Excluded! (2000 < 5000)

-- Corrected Expected Output (HAVING MIN(price) > 5000):
-- | customer_name | cheapest_order |
-- |---------------|----------------|
-- | Vikram Singh  | 82000          |
-- | Karan Mehta   | 68000          |
-- | Amit Sharma   | 15000          |
-- | Rahul Gupta   | 12000          |


-- ============================================================
-- 9️⃣ MIN/MAX and NULLs
-- ============================================================
-- Both MIN() and MAX() ignore NULL values entirely.

WITH sample AS (
    SELECT NULL::INT AS val
    UNION ALL SELECT 10
    UNION ALL SELECT 5
    UNION ALL SELECT NULL
    UNION ALL SELECT 20
)
SELECT
    MIN(val) AS min_val,  -- 5 (NULLs ignored)
    MAX(val) AS max_val   -- 20 (NULLs ignored)
FROM sample;

-- Expected Output:
-- | min_val | max_val |
-- |---------|---------|
-- | 5       | 20      |

-- If ALL values are NULL, MIN/MAX returns NULL
WITH all_nulls AS (
    SELECT NULL::INT AS val
    UNION ALL SELECT NULL
)
SELECT
    MIN(val) AS min_val,
    MAX(val) AS max_val
FROM all_nulls;

-- Expected Output:
-- | min_val | max_val |
-- |---------|---------|
-- | NULL    | NULL    |


-- ============================================================
-- 🔑 KEY TAKEAWAYS
-- ============================================================
-- 1. MIN(col) → Returns the smallest value; MAX(col) → the largest
-- 2. Both work with numbers, dates, and text (alphabetical order)
-- 3. Both IGNORE NULLs (return NULL only if ALL values are NULL)
-- 4. MIN/MAX with GROUP BY → Extremes per group
-- 5. To find the FULL ROW with max/min value:
--    a) Subquery:       WHERE price = (SELECT MAX(price)...)
--    b) ORDER BY+LIMIT: ORDER BY price DESC LIMIT 1
--    c) Window Function: ROW_NUMBER() / RANK() for ties
-- 6. Per-group max row → PARTITION BY + ROW_NUMBER() (interview favorite!)
-- 7. MAX(date) → Latest date; MIN(date) → Earliest date
-- 8. Price range = MAX(price) - MIN(price)
-- ============================================================
