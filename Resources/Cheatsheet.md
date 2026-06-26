# 📝 SQL & PostgreSQL Quick Reference Cheatsheet

> One-liner per command. Copy, paste, conquer.

---

## 📑 Table of Contents

- [SQL Syntax Cheatsheet](#sql-syntax-cheatsheet)
- [PostgreSQL Data Types](#postgresql-data-types)
- [Constraint Syntax Summary](#constraint-syntax-summary)
- [Date & Time Functions](#date--time-functions)
- [String Functions](#string-functions)
- [Aggregate Functions](#aggregate-functions)
- [Window Functions](#window-functions)
- [JSON/JSONB Quick Reference](#jsonjsonb-quick-reference)

---

## SQL Syntax Cheatsheet

### SELECT & Filtering

```sql
SELECT * FROM employees;                                        -- all columns
SELECT name, salary FROM employees;                             -- specific columns
SELECT DISTINCT department FROM employees;                      -- unique values
SELECT * FROM employees WHERE salary > 50000;                   -- filter rows
SELECT * FROM employees WHERE department IN ('HR', 'IT');       -- match list
SELECT * FROM employees WHERE name LIKE 'A%';                  -- pattern match
SELECT * FROM employees WHERE name ILIKE 'a%';                 -- case-insensitive (PG)
SELECT * FROM employees WHERE salary BETWEEN 40000 AND 80000;  -- range
SELECT * FROM employees WHERE manager_id IS NULL;               -- null check
SELECT * FROM employees WHERE NOT (salary < 30000);             -- negation
```

### ORDER BY & LIMIT

```sql
SELECT * FROM employees ORDER BY salary DESC;                   -- descending sort
SELECT * FROM employees ORDER BY department ASC, salary DESC;   -- multi-column sort
SELECT * FROM employees ORDER BY salary DESC LIMIT 10;          -- top 10
SELECT * FROM employees ORDER BY salary OFFSET 10 LIMIT 5;     -- pagination (skip 10, take 5)
SELECT * FROM employees ORDER BY salary FETCH FIRST 10 ROWS ONLY;  -- SQL standard
```

### GROUP BY & HAVING

```sql
SELECT department, COUNT(*) FROM employees GROUP BY department;                    -- group
SELECT department, AVG(salary) FROM employees GROUP BY department HAVING AVG(salary) > 60000;  -- filter groups
SELECT department, COUNT(*), MAX(salary) FROM employees GROUP BY department ORDER BY COUNT(*) DESC;
```

### JOINs

```sql
SELECT * FROM orders o INNER JOIN customers c ON o.cust_id = c.id;    -- inner join
SELECT * FROM orders o LEFT JOIN customers c ON o.cust_id = c.id;     -- left join
SELECT * FROM orders o RIGHT JOIN customers c ON o.cust_id = c.id;    -- right join
SELECT * FROM orders o FULL OUTER JOIN customers c ON o.cust_id = c.id;  -- full outer
SELECT * FROM products CROSS JOIN categories;                          -- cross join
SELECT e.name, m.name AS manager FROM employees e LEFT JOIN employees m ON e.mgr_id = m.id;  -- self join
SELECT * FROM orders NATURAL JOIN customers;                           -- natural join (auto-match columns)
```

### Subqueries

```sql
SELECT * FROM employees WHERE salary > (SELECT AVG(salary) FROM employees);        -- scalar
SELECT * FROM employees WHERE dept_id IN (SELECT id FROM departments WHERE loc = 'NYC');  -- IN
SELECT * FROM orders o WHERE EXISTS (SELECT 1 FROM returns r WHERE r.order_id = o.id);    -- EXISTS
SELECT * FROM (SELECT dept, AVG(salary) AS avg_sal FROM employees GROUP BY dept) sub;     -- derived table
```

### Set Operations

```sql
SELECT city FROM customers UNION SELECT city FROM suppliers;          -- combine, no duplicates
SELECT city FROM customers UNION ALL SELECT city FROM suppliers;      -- combine, keep duplicates
SELECT city FROM customers INTERSECT SELECT city FROM suppliers;      -- common rows
SELECT city FROM customers EXCEPT SELECT city FROM suppliers;         -- in first, not in second
```

### INSERT

```sql
INSERT INTO employees (name, salary) VALUES ('Alice', 70000);                          -- single row
INSERT INTO employees (name, salary) VALUES ('Bob', 60000), ('Carol', 80000);          -- multi-row
INSERT INTO employees (name, salary) SELECT name, salary FROM temp_emp;                -- from query
INSERT INTO employees (name, salary) VALUES ('Dave', 50000) RETURNING id;              -- return id (PG)
INSERT INTO products (name, price) VALUES ('Widget', 9.99) ON CONFLICT (name) DO NOTHING;  -- upsert (PG)
INSERT INTO products (name, price) VALUES ('Widget', 12.99)
    ON CONFLICT (name) DO UPDATE SET price = EXCLUDED.price;                           -- upsert update (PG)
```

### UPDATE

```sql
UPDATE employees SET salary = 75000 WHERE id = 1;                                 -- single column
UPDATE employees SET salary = salary * 1.10, updated_at = NOW() WHERE dept = 'IT';  -- multi-column
UPDATE employees SET salary = salary + 5000 WHERE id = 1 RETURNING *;              -- with returning (PG)
```

### DELETE

```sql
DELETE FROM employees WHERE id = 1;                        -- delete specific row
DELETE FROM employees WHERE hire_date < '2020-01-01';      -- conditional delete
DELETE FROM sessions WHERE expires_at < NOW() RETURNING *; -- return deleted rows (PG)
TRUNCATE TABLE employees;                                  -- delete all rows (fast, no row-level log)
TRUNCATE TABLE employees RESTART IDENTITY CASCADE;         -- reset serial + cascade (PG)
```

### DDL — Tables

```sql
CREATE TABLE employees (id SERIAL PRIMARY KEY, name TEXT NOT NULL, salary NUMERIC);  -- create
ALTER TABLE employees ADD COLUMN email VARCHAR(255);                                 -- add column
ALTER TABLE employees DROP COLUMN email;                                             -- drop column
ALTER TABLE employees ALTER COLUMN salary SET DEFAULT 0;                             -- set default
ALTER TABLE employees RENAME COLUMN name TO full_name;                               -- rename column
ALTER TABLE employees RENAME TO staff;                                               -- rename table
DROP TABLE IF EXISTS employees CASCADE;                                              -- drop table
```

### Views

```sql
CREATE VIEW active_emp AS SELECT * FROM employees WHERE status = 'active';           -- create view
CREATE OR REPLACE VIEW active_emp AS SELECT id, name FROM employees WHERE status = 'active';
DROP VIEW IF EXISTS active_emp;                                                      -- drop view
CREATE MATERIALIZED VIEW mv_sales AS SELECT product, SUM(amount) FROM sales GROUP BY product;
REFRESH MATERIALIZED VIEW mv_sales;                                                  -- refresh mat view
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_sales;                                     -- non-blocking refresh
```

### Indexes

```sql
CREATE INDEX idx_name ON employees(last_name);                          -- b-tree (default)
CREATE INDEX idx_email ON employees(email) WHERE email IS NOT NULL;     -- partial index
CREATE UNIQUE INDEX idx_uniq_email ON employees(email);                 -- unique index
CREATE INDEX idx_gin_data ON events USING GIN (data);                   -- GIN index (JSONB, arrays)
CREATE INDEX idx_brin_date ON logs USING BRIN (created_at);             -- BRIN index (sorted data)
DROP INDEX IF EXISTS idx_name;                                          -- drop index
```

### Transactions

```sql
BEGIN;                                   -- start transaction
SAVEPOINT my_savepoint;                  -- create savepoint
ROLLBACK TO my_savepoint;               -- rollback to savepoint
COMMIT;                                  -- commit transaction
ROLLBACK;                                -- rollback entire transaction
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;  -- set isolation
```

### CTEs & Window Functions

```sql
WITH cte AS (SELECT dept, AVG(salary) AS avg_sal FROM employees GROUP BY dept)
SELECT * FROM cte WHERE avg_sal > 50000;                                        -- CTE

SELECT name, salary, RANK() OVER (ORDER BY salary DESC) FROM employees;         -- window function
SELECT name, dept, salary, AVG(salary) OVER (PARTITION BY dept) FROM employees;  -- partition window
```

---

## PostgreSQL Data Types

### Numeric Types

| Type            | Size     | Range / Description                      |
|-----------------|----------|------------------------------------------|
| `SMALLINT`      | 2 bytes  | -32,768 to 32,767                        |
| `INTEGER`       | 4 bytes  | -2.1 billion to 2.1 billion              |
| `BIGINT`        | 8 bytes  | -9.2 quintillion to 9.2 quintillion      |
| `NUMERIC(p,s)`  | Variable | Exact precision (financial data)         |
| `REAL`          | 4 bytes  | 6 decimal digits precision               |
| `DOUBLE PRECISION` | 8 bytes | 15 decimal digits precision           |
| `SERIAL`        | 4 bytes  | Auto-increment integer (1 to 2.1B)       |
| `BIGSERIAL`     | 8 bytes  | Auto-increment big integer               |

### Character Types

| Type                | Description                              |
|---------------------|------------------------------------------|
| `CHAR(n)`           | Fixed-length, padded with spaces         |
| `VARCHAR(n)`        | Variable-length with limit               |
| `TEXT`              | Variable-length, unlimited               |

### Date/Time Types

| Type             | Description                | Example                    |
|------------------|----------------------------|----------------------------|
| `DATE`           | Date only                  | `'2025-06-26'`             |
| `TIME`           | Time only (no timezone)    | `'14:30:00'`               |
| `TIMETZ`         | Time with timezone         | `'14:30:00+05:30'`         |
| `TIMESTAMP`      | Date + time (no timezone)  | `'2025-06-26 14:30:00'`    |
| `TIMESTAMPTZ`    | Date + time with timezone  | `'2025-06-26 14:30:00+05:30'` |
| `INTERVAL`       | Time span                  | `'2 hours 30 minutes'`     |

### Boolean & Binary

| Type             | Description                              |
|------------------|------------------------------------------|
| `BOOLEAN`        | `TRUE`, `FALSE`, `NULL`                  |
| `BYTEA`          | Binary data (byte array)                 |

### Special PostgreSQL Types

| Type             | Description                              |
|------------------|------------------------------------------|
| `UUID`           | 128-bit universally unique identifier    |
| `JSONB`          | Binary JSON with indexing support        |
| `JSON`           | Text JSON (preserves formatting)         |
| `HSTORE`         | Key-value pairs (requires extension)     |
| `ARRAY`          | Array of any type (`TEXT[]`, `INT[]`)     |
| `INET`           | IPv4 or IPv6 address                     |
| `CIDR`           | IPv4 or IPv6 network                     |
| `MACADDR`        | MAC address                              |
| `MONEY`          | Currency amount (locale-aware)           |
| `TSQUERY`        | Full-text search query                   |
| `TSVECTOR`       | Full-text search document                |
| `INT4RANGE`      | Range of integers                        |
| `DATERANGE`      | Range of dates                           |
| `POINT`          | Geometric point (x, y)                   |
| `ENUM`           | User-defined enumerated type             |

---

## Constraint Syntax Summary

```sql
-- Column-level constraints
CREATE TABLE example (
    id      INT PRIMARY KEY,                                -- primary key
    email   VARCHAR(255) UNIQUE NOT NULL,                   -- unique + not null
    age     INT CHECK (age >= 0 AND age <= 150),            -- check constraint
    role    VARCHAR(20) DEFAULT 'user',                     -- default value
    dept_id INT REFERENCES departments(id)                  -- foreign key
);

-- Table-level constraints
CREATE TABLE order_items (
    order_id   INT REFERENCES orders(id) ON DELETE CASCADE,     -- cascade delete
    product_id INT REFERENCES products(id) ON DELETE SET NULL,  -- set null on delete
    quantity   INT NOT NULL,
    PRIMARY KEY (order_id, product_id),                         -- composite primary key
    UNIQUE (order_id, product_id),                              -- composite unique
    CHECK (quantity > 0)                                        -- table-level check
);

-- Named constraints
ALTER TABLE employees ADD CONSTRAINT chk_salary CHECK (salary > 0);
ALTER TABLE employees ADD CONSTRAINT fk_dept FOREIGN KEY (dept_id) REFERENCES departments(id);
ALTER TABLE employees DROP CONSTRAINT chk_salary;
```

### Foreign Key Actions

| Action          | Behavior on Parent DELETE/UPDATE         |
|-----------------|------------------------------------------|
| `CASCADE`       | Delete/update child rows too             |
| `SET NULL`      | Set FK column to NULL                    |
| `SET DEFAULT`   | Set FK column to its default value       |
| `RESTRICT`      | Prevent if child rows exist              |
| `NO ACTION`     | Same as RESTRICT (default, checked later)|

---

## Date & Time Functions

```sql
SELECT NOW();                                           -- current timestamp with tz
SELECT CURRENT_DATE;                                    -- today's date
SELECT CURRENT_TIME;                                    -- current time
SELECT CURRENT_TIMESTAMP;                               -- same as NOW()

SELECT EXTRACT(YEAR FROM NOW());                        -- extract year → 2025
SELECT EXTRACT(MONTH FROM NOW());                       -- extract month → 6
SELECT EXTRACT(DOW FROM NOW());                         -- day of week (0=Sun, 6=Sat)
SELECT DATE_PART('hour', NOW());                        -- extract hour

SELECT AGE('2025-06-26', '1995-03-15');                 -- interval between dates
SELECT AGE(NOW(), hire_date) FROM employees;            -- age since hire

SELECT DATE_TRUNC('month', NOW());                      -- truncate to month start
SELECT DATE_TRUNC('year', NOW());                       -- truncate to year start

SELECT NOW() + INTERVAL '30 days';                      -- add 30 days
SELECT NOW() - INTERVAL '2 hours';                      -- subtract 2 hours
SELECT NOW() + INTERVAL '1 year 3 months';              -- add complex interval

SELECT TO_CHAR(NOW(), 'YYYY-MM-DD HH24:MI:SS');        -- format timestamp
SELECT TO_CHAR(NOW(), 'Day, DD Mon YYYY');              -- 'Thursday, 26 Jun 2025'
SELECT TO_DATE('26-06-2025', 'DD-MM-YYYY');             -- parse date from string
SELECT TO_TIMESTAMP('2025-06-26 14:30', 'YYYY-MM-DD HH24:MI');  -- parse timestamp

SELECT CURRENT_DATE - hire_date AS days_employed FROM employees;  -- date arithmetic
SELECT MAKE_DATE(2025, 6, 26);                          -- construct date
SELECT MAKE_INTERVAL(years := 1, months := 6);          -- construct interval
```

---

## String Functions

```sql
SELECT LENGTH('PostgreSQL');                             -- 10 (character count)
SELECT CHAR_LENGTH('Hello');                             -- 5
SELECT OCTET_LENGTH('Hello');                            -- 5 (byte count)

SELECT UPPER('hello');                                   -- 'HELLO'
SELECT LOWER('HELLO');                                   -- 'hello'
SELECT INITCAP('hello world');                           -- 'Hello World'

SELECT CONCAT('Hello', ' ', 'World');                    -- 'Hello World'
SELECT 'Hello' || ' ' || 'World';                        -- 'Hello World' (PG concat)
SELECT CONCAT_WS(', ', 'Alice', 'Bob', 'Carol');         -- 'Alice, Bob, Carol'

SELECT SUBSTRING('PostgreSQL' FROM 1 FOR 4);             -- 'Post'
SELECT LEFT('PostgreSQL', 4);                            -- 'Post'
SELECT RIGHT('PostgreSQL', 3);                           -- 'SQL'

SELECT TRIM('  hello  ');                                -- 'hello'
SELECT LTRIM('  hello');                                 -- 'hello'
SELECT RTRIM('hello  ');                                 -- 'hello'
SELECT TRIM(BOTH 'x' FROM 'xxxhelloxxx');                -- 'hello'

SELECT REPLACE('Hello World', 'World', 'PG');            -- 'Hello PG'
SELECT TRANSLATE('hello', 'helo', 'HELO');               -- 'HELLO'

SELECT POSITION('SQL' IN 'PostgreSQL');                  -- 8
SELECT STRPOS('PostgreSQL', 'SQL');                      -- 8 (PG-specific)

SELECT SPLIT_PART('a.b.c', '.', 2);                     -- 'b'
SELECT STRING_AGG(name, ', ') FROM employees;            -- 'Alice, Bob, Carol'
SELECT REPEAT('ha', 3);                                  -- 'hahaha'
SELECT REVERSE('hello');                                 -- 'olleh'
SELECT LPAD('42', 5, '0');                               -- '00042'
SELECT RPAD('hi', 5, '.');                               -- 'hi...'
SELECT MD5('password');                                  -- MD5 hash (32 hex chars)
SELECT REGEXP_REPLACE('abc123', '[0-9]', 'X', 'g');      -- 'abcXXX'
SELECT REGEXP_MATCHES('abc123def456', '[0-9]+', 'g');    -- {'123'}, {'456'}
```

---

## Aggregate Functions

```sql
SELECT COUNT(*) FROM employees;                          -- count all rows
SELECT COUNT(DISTINCT department) FROM employees;        -- count unique values
SELECT COUNT(email) FROM employees;                      -- count non-null emails

SELECT SUM(salary) FROM employees;                       -- total salary
SELECT AVG(salary) FROM employees;                       -- average salary
SELECT MIN(salary) FROM employees;                       -- minimum salary
SELECT MAX(salary) FROM employees;                       -- maximum salary

SELECT ROUND(AVG(salary), 2) FROM employees;             -- rounded average
SELECT CEIL(AVG(salary)) FROM employees;                 -- round up
SELECT FLOOR(AVG(salary)) FROM employees;                -- round down

SELECT BOOL_AND(is_active) FROM employees;               -- true if ALL are true
SELECT BOOL_OR(is_active) FROM employees;                -- true if ANY is true

SELECT ARRAY_AGG(name) FROM employees;                   -- collect into array
SELECT STRING_AGG(name, ', ' ORDER BY name) FROM employees;  -- comma-separated string
SELECT JSON_AGG(name) FROM employees;                    -- collect as JSON array
SELECT JSONB_AGG(row_to_json(e)) FROM employees e;      -- rows as JSON array

SELECT COALESCE(phone, email, 'N/A') FROM contacts;     -- first non-null value
SELECT NULLIF(score, 0) FROM students;                   -- returns null if score = 0
SELECT GREATEST(10, 20, 30);                             -- 30 (max of values)
SELECT LEAST(10, 20, 30);                                -- 10 (min of values)
```

---

## Window Functions

```sql
SELECT name, salary, ROW_NUMBER() OVER (ORDER BY salary DESC) FROM employees;               -- unique row number
SELECT name, salary, RANK() OVER (ORDER BY salary DESC) FROM employees;                     -- rank with gaps
SELECT name, salary, DENSE_RANK() OVER (ORDER BY salary DESC) FROM employees;               -- rank without gaps
SELECT name, salary, NTILE(4) OVER (ORDER BY salary DESC) FROM employees;                   -- divide into 4 groups

SELECT name, salary, LAG(salary) OVER (ORDER BY hire_date) AS prev_salary FROM employees;   -- previous row
SELECT name, salary, LEAD(salary) OVER (ORDER BY hire_date) AS next_salary FROM employees;  -- next row
SELECT name, salary, FIRST_VALUE(salary) OVER (ORDER BY salary DESC) FROM employees;        -- first in window
SELECT name, salary, LAST_VALUE(salary) OVER (ORDER BY salary ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) FROM employees;  -- last in window

SELECT name, dept, salary,
    SUM(salary) OVER (PARTITION BY dept) AS dept_total,                                     -- sum per department
    AVG(salary) OVER (PARTITION BY dept) AS dept_avg                                        -- avg per department
FROM employees;

SELECT name, hire_date, salary,
    SUM(salary) OVER (ORDER BY hire_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS running_3  -- rolling sum
FROM employees;
```

---

## JSON/JSONB Quick Reference

```sql
-- Access operators
SELECT data->'name' FROM users;                          -- get as JSON
SELECT data->>'name' FROM users;                         -- get as TEXT
SELECT data#>'{address,city}' FROM users;                -- nested path (JSON)
SELECT data#>>'{address,city}' FROM users;               -- nested path (TEXT)

-- Containment & existence
SELECT * FROM users WHERE data @> '{"role":"admin"}';    -- contains
SELECT * FROM users WHERE data ? 'email';                -- key exists
SELECT * FROM users WHERE data ?& array['name','email']; -- all keys exist

-- Modify JSONB
SELECT data || '{"verified": true}' FROM users;          -- add/merge key
SELECT data - 'old_key' FROM users;                      -- remove key
SELECT data #- '{address,zip}' FROM users;               -- remove nested key
SELECT jsonb_set(data, '{name}', '"Alice"') FROM users;  -- set specific key

-- Aggregate & expand
SELECT jsonb_each(data) FROM users;                      -- expand to key-value rows
SELECT jsonb_object_keys(data) FROM users;               -- get all keys
SELECT jsonb_array_elements('[1,2,3]'::jsonb);           -- expand array
SELECT jsonb_typeof(data->'age') FROM users;             -- 'number', 'string', etc.
SELECT jsonb_pretty(data) FROM users;                    -- formatted output
```

---

*Keep this cheatsheet bookmarked — it's your SQL Swiss Army knife! 🔧*
