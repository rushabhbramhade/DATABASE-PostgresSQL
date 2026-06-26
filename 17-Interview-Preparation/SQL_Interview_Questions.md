# 📋 SQL Interview Questions & Answers

> A comprehensive collection of 35+ commonly asked SQL interview questions organized by difficulty level.
> Each answer is concise (2–4 lines) with SQL snippets where helpful.

---

## 📑 Table of Contents

- [🟢 Basic Level (1–12)](#-basic-level)
- [🟡 Intermediate Level (13–24)](#-intermediate-level)
- [🔴 Advanced Level (25–35)](#-advanced-level)
- [💡 Quick Tips for SQL Interviews](#-quick-tips-for-sql-interviews)

---

## 🟢 Basic Level

### Q1. What is SQL?

SQL (Structured Query Language) is the standard language used to communicate with relational databases. It allows you to create, read, update, and delete data (CRUD operations), as well as manage database structures and control access permissions.

---

### Q2. What are the different sub-languages of SQL?

| Sub-Language | Full Form                    | Key Commands                          |
|--------------|------------------------------|---------------------------------------|
| **DDL**      | Data Definition Language     | `CREATE`, `ALTER`, `DROP`, `TRUNCATE` |
| **DML**      | Data Manipulation Language   | `SELECT`, `INSERT`, `UPDATE`, `DELETE`|
| **DCL**      | Data Control Language        | `GRANT`, `REVOKE`                     |
| **TCL**      | Transaction Control Language | `COMMIT`, `ROLLBACK`, `SAVEPOINT`     |

---

### Q3. What is the difference between PRIMARY KEY and UNIQUE KEY?

| Feature         | PRIMARY KEY                     | UNIQUE KEY                        |
|-----------------|---------------------------------|-----------------------------------|
| NULL values     | Not allowed                     | Allows one NULL (in most RDBMS)   |
| Per table       | Only one per table              | Multiple allowed per table        |
| Clustered index | Creates clustered index (default) | Creates non-clustered index     |
| Purpose         | Uniquely identifies each row    | Enforces uniqueness on a column   |

---

### Q4. What is the difference between DELETE, TRUNCATE, and DROP?

| Command    | Type | Removes          | Rollback? | WHERE clause? |
|------------|------|------------------|-----------|---------------|
| `DELETE`   | DML  | Specific rows    | Yes       | Yes           |
| `TRUNCATE` | DDL  | All rows         | No*       | No            |
| `DROP`     | DDL  | Entire table     | No        | No            |

> *In PostgreSQL, `TRUNCATE` can be rolled back inside a transaction.

---

### Q5. What is a NULL value in SQL?

`NULL` represents the absence of a value — it is not zero, not an empty string, and not `FALSE`. You cannot compare `NULL` using `=`; instead use `IS NULL` or `IS NOT NULL`.

```sql
SELECT * FROM employees WHERE manager_id IS NULL;
```

---

### Q6. What is the difference between WHERE and HAVING?

- **WHERE** filters rows *before* aggregation (works on individual rows).
- **HAVING** filters groups *after* aggregation (works on aggregated results).

```sql
-- WHERE: filter rows before grouping
SELECT department, COUNT(*) FROM employees
WHERE salary > 40000
GROUP BY department;

-- HAVING: filter groups after grouping
SELECT department, COUNT(*) FROM employees
GROUP BY department
HAVING COUNT(*) > 5;
```

---

### Q7. What are constraints in SQL?

Constraints enforce rules on data in a table to ensure accuracy and integrity.

| Constraint      | Purpose                                      |
|-----------------|----------------------------------------------|
| `NOT NULL`      | Column cannot have NULL values               |
| `UNIQUE`        | All values in a column must be distinct       |
| `PRIMARY KEY`   | Unique + Not Null identifier for each row     |
| `FOREIGN KEY`   | Links to a primary key in another table       |
| `CHECK`         | Ensures values satisfy a condition            |
| `DEFAULT`       | Sets a default value if none is provided      |

---

### Q8. What is normalization? Name the normal forms.

Normalization is the process of organizing data to reduce redundancy and improve data integrity.

| Normal Form | Rule                                                              |
|-------------|-------------------------------------------------------------------|
| **1NF**     | Atomic values only, no repeating groups                           |
| **2NF**     | 1NF + no partial dependency (all non-key columns depend on full PK)|
| **3NF**     | 2NF + no transitive dependency                                    |
| **BCNF**    | 3NF + every determinant is a candidate key                        |

---

### Q9. What is the difference between CHAR and VARCHAR?

- **CHAR(n)**: Fixed-length string, always stores exactly `n` characters (padded with spaces).
- **VARCHAR(n)**: Variable-length string, stores up to `n` characters (no padding).

Use `CHAR` for fixed-length data like country codes (`'US'`, `'IN'`). Use `VARCHAR` for variable-length data like names.

---

### Q10. What is an alias in SQL?

An alias provides a temporary name for a table or column, making queries more readable. It exists only for the duration of that query.

```sql
SELECT e.first_name AS "Employee Name", d.name AS "Department"
FROM employees AS e
JOIN departments AS d ON e.dept_id = d.id;
```

---

### Q11. What are aggregate functions?

Aggregate functions perform calculations on a set of rows and return a single value.

| Function   | Description              | Example                    |
|------------|--------------------------|----------------------------|
| `COUNT()`  | Number of rows           | `COUNT(*)`                 |
| `SUM()`    | Total of numeric column  | `SUM(salary)`              |
| `AVG()`    | Average value            | `AVG(salary)`              |
| `MIN()`    | Minimum value            | `MIN(hire_date)`           |
| `MAX()`    | Maximum value            | `MAX(salary)`              |

---

### Q12. What is the order of execution of a SQL query?

SQL does **not** execute in the order you write it. The logical execution order is:

```
1. FROM / JOIN     → Identify tables
2. WHERE           → Filter rows
3. GROUP BY        → Group rows
4. HAVING          → Filter groups
5. SELECT          → Choose columns
6. DISTINCT        → Remove duplicates
7. ORDER BY        → Sort results
8. LIMIT / OFFSET  → Restrict output
```

---

## 🟡 Intermediate Level

### Q13. Explain all types of JOINs with examples.

| JOIN Type          | Description                                            |
|--------------------|--------------------------------------------------------|
| `INNER JOIN`       | Returns only matching rows from both tables            |
| `LEFT JOIN`        | All rows from left table + matching from right         |
| `RIGHT JOIN`       | All rows from right table + matching from left         |
| `FULL OUTER JOIN`  | All rows from both tables, NULLs where no match        |
| `CROSS JOIN`       | Cartesian product — every row × every row              |
| `SELF JOIN`        | A table joined with itself                             |

```sql
-- INNER JOIN: employees with their departments
SELECT e.name, d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.id;

-- LEFT JOIN: all employees, even those without a department
SELECT e.name, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.id;

-- SELF JOIN: find each employee's manager
SELECT e.name AS employee, m.name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id;
```

---

### Q14. What is the difference between UNION and UNION ALL?

- **UNION**: Combines results from two queries and removes duplicates (slower).
- **UNION ALL**: Combines results and keeps all rows including duplicates (faster).

```sql
SELECT city FROM customers
UNION
SELECT city FROM suppliers;       -- distinct cities only

SELECT city FROM customers
UNION ALL
SELECT city FROM suppliers;       -- all cities, duplicates included
```

Both queries must have the same number of columns with compatible data types.

---

### Q15. What is a subquery? What are its types?

A subquery is a query nested inside another query. Types:

| Type                    | Location        | Example Use Case                        |
|-------------------------|-----------------|-----------------------------------------|
| **Scalar subquery**     | SELECT / WHERE  | Returns a single value                  |
| **Row subquery**        | WHERE           | Returns a single row                    |
| **Table subquery**      | FROM            | Returns a result set (derived table)    |
| **Correlated subquery** | WHERE / SELECT  | References outer query, runs per row    |

```sql
-- Scalar subquery: employees earning above average
SELECT name, salary FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- Correlated subquery: employees earning max in their dept
SELECT name, salary, dept_id FROM employees e
WHERE salary = (
    SELECT MAX(salary) FROM employees WHERE dept_id = e.dept_id
);
```

---

### Q16. When should you use a subquery vs a JOIN?

| Use Case                          | Prefer     |
|-----------------------------------|------------|
| Checking existence                | Subquery (`EXISTS`) |
| Comparing against an aggregate    | Subquery   |
| Combining columns from two tables | JOIN       |
| Performance-critical queries      | JOIN (usually faster) |
| Readability for simple filters    | Subquery   |

In general, JOINs are more efficient because the optimizer can better plan execution. Use subqueries when logic is cleaner or when using `EXISTS`/`IN`.

---

### Q17. What is GROUP BY? Can you use it without an aggregate function?

`GROUP BY` groups rows sharing the same values into summary rows. It is typically used with aggregate functions. You *can* use it without aggregates — it acts like `DISTINCT` in that case.

```sql
-- With aggregate: count employees per department
SELECT department, COUNT(*) AS emp_count
FROM employees
GROUP BY department;

-- Without aggregate: same as SELECT DISTINCT department
SELECT department
FROM employees
GROUP BY department;
```

---

### Q18. What is the difference between IN, EXISTS, and JOIN?

```sql
-- IN: checks against a list of values (loads entire subquery result)
SELECT * FROM orders WHERE customer_id IN (SELECT id FROM customers WHERE country = 'India');

-- EXISTS: checks for existence (stops at first match, often faster)
SELECT * FROM orders o WHERE EXISTS (SELECT 1 FROM customers c WHERE c.id = o.customer_id AND c.country = 'India');

-- JOIN: combines tables (best when you need columns from both)
SELECT o.* FROM orders o JOIN customers c ON o.customer_id = c.id WHERE c.country = 'India';
```

- Use `EXISTS` for large subquery results (more efficient).
- Use `IN` for small, known lists.
- Use `JOIN` when you need data from both tables.

---

### Q19. What is a view? What are its advantages?

A view is a virtual table based on a stored SQL query. It does not store data itself — it fetches data dynamically when queried.

```sql
CREATE VIEW active_employees AS
SELECT id, name, department FROM employees WHERE status = 'active';

SELECT * FROM active_employees;  -- queries the underlying table
```

**Advantages**: Simplifies complex queries, provides data abstraction, enhances security by restricting column access, and promotes code reuse.

---

### Q20. What is the difference between a view and a materialized view?

| Feature            | View                        | Materialized View             |
|--------------------|-----------------------------|-------------------------------|
| Data storage       | No (virtual)                | Yes (physical snapshot)       |
| Performance        | Slower (runs query each time)| Faster (pre-computed)         |
| Freshness          | Always current              | Stale until refreshed         |
| Refresh needed     | No                          | Yes (`REFRESH MATERIALIZED VIEW`) |

---

### Q21. What is an index? What types exist?

An index is a data structure that speeds up data retrieval at the cost of additional storage and slower writes.

| Index Type       | Description                                      |
|------------------|--------------------------------------------------|
| **B-tree**       | Default, good for equality and range queries      |
| **Hash**         | Good for equality comparisons only               |
| **GIN**          | For full-text search, arrays, JSONB              |
| **GiST**         | For geometric data, full-text search             |
| **BRIN**         | For very large tables with naturally ordered data |

```sql
CREATE INDEX idx_emp_name ON employees(last_name);
CREATE INDEX idx_emp_dept_sal ON employees(department, salary);  -- composite
```

---

### Q22. What are ACID properties?

| Property        | Meaning                                                         |
|-----------------|-----------------------------------------------------------------|
| **Atomicity**   | All operations in a transaction succeed or all fail             |
| **Consistency** | Database moves from one valid state to another                  |
| **Isolation**   | Concurrent transactions don't interfere with each other         |
| **Durability**  | Committed data survives system crashes                          |

---

### Q23. What are transaction isolation levels?

| Level              | Dirty Read | Non-Repeatable Read | Phantom Read |
|--------------------|------------|---------------------|--------------|
| Read Uncommitted   | ✅ Possible | ✅ Possible          | ✅ Possible   |
| Read Committed     | ❌ No       | ✅ Possible          | ✅ Possible   |
| Repeatable Read    | ❌ No       | ❌ No                | ✅ Possible*  |
| Serializable       | ❌ No       | ❌ No                | ❌ No         |

> *PostgreSQL's Repeatable Read also prevents phantom reads, unlike the SQL standard.

---

### Q24. What is the difference between COALESCE and NULLIF?

```sql
-- COALESCE: returns the first non-NULL value
SELECT COALESCE(phone, email, 'No Contact') AS contact FROM customers;

-- NULLIF: returns NULL if both arguments are equal
SELECT NULLIF(actual_price, 0) AS safe_price FROM products;
-- useful to avoid division by zero: revenue / NULLIF(quantity, 0)
```

---

## 🔴 Advanced Level

### Q25. What are window functions? How do they differ from GROUP BY?

Window functions perform calculations across a set of rows related to the current row, **without collapsing rows** (unlike `GROUP BY`).

```sql
-- GROUP BY collapses: one row per department
SELECT department, AVG(salary) FROM employees GROUP BY department;

-- Window function preserves all rows
SELECT name, department, salary,
       AVG(salary) OVER (PARTITION BY department) AS dept_avg,
       RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rank
FROM employees;
```

Common window functions: `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`, `LEAD()`, `LAG()`, `NTILE()`, `SUM() OVER()`, `AVG() OVER()`.

---

### Q26. Explain ROW_NUMBER vs RANK vs DENSE_RANK.

Given salaries: 100, 100, 90, 80:

| Function         | Result         | Behavior                        |
|------------------|----------------|---------------------------------|
| `ROW_NUMBER()`   | 1, 2, 3, 4    | Unique number, no ties          |
| `RANK()`         | 1, 1, 3, 4    | Same rank for ties, gaps after  |
| `DENSE_RANK()`   | 1, 1, 2, 3    | Same rank for ties, no gaps     |

```sql
SELECT name, salary,
    ROW_NUMBER() OVER (ORDER BY salary DESC) AS row_num,
    RANK()       OVER (ORDER BY salary DESC) AS rnk,
    DENSE_RANK() OVER (ORDER BY salary DESC) AS dense_rnk
FROM employees;
```

---

### Q27. What is a CTE (Common Table Expression)?

A CTE is a temporary named result set defined with `WITH` that exists only for the duration of a single query. It improves readability and allows recursive queries.

```sql
-- Simple CTE
WITH high_earners AS (
    SELECT name, salary, department
    FROM employees
    WHERE salary > 80000
)
SELECT department, COUNT(*) AS count
FROM high_earners
GROUP BY department;

-- Recursive CTE: employee hierarchy
WITH RECURSIVE org_chart AS (
    SELECT id, name, manager_id, 1 AS level
    FROM employees WHERE manager_id IS NULL
    UNION ALL
    SELECT e.id, e.name, e.manager_id, oc.level + 1
    FROM employees e
    JOIN org_chart oc ON e.manager_id = oc.id
)
SELECT * FROM org_chart;
```

---

### Q28. CTE vs Subquery vs Temp Table — when to use which?

| Feature          | CTE                      | Subquery              | Temp Table            |
|------------------|--------------------------|------------------------|----------------------|
| Scope            | Single query             | Single query           | Session / transaction|
| Reusable         | Yes (within the query)   | No                     | Yes                  |
| Recursive        | Yes                      | No                     | No                   |
| Materialized     | Optimizer decides*       | Inline                 | Always               |
| Performance      | Good for readability     | Good for simple cases  | Best for large data  |

> *In PostgreSQL 12+, you can force with `MATERIALIZED` / `NOT MATERIALIZED`.

---

### Q29. How do you optimize a slow SQL query?

**Step-by-step approach**:

1. **Use `EXPLAIN ANALYZE`** to see the execution plan and actual timings
2. **Add appropriate indexes** on columns used in WHERE, JOIN, ORDER BY
3. **Avoid `SELECT *`** — select only needed columns
4. **Rewrite subqueries as JOINs** where possible
5. **Use `EXISTS` instead of `IN`** for large datasets
6. **Partition large tables** to reduce scan scope
7. **Avoid functions on indexed columns** in WHERE (breaks index usage)
8. **Use `LIMIT`** for large result sets
9. **Check for missing statistics** — run `ANALYZE`
10. **Use connection pooling** for high-concurrency workloads

```sql
-- Bad: function on indexed column prevents index use
SELECT * FROM orders WHERE EXTRACT(YEAR FROM order_date) = 2025;

-- Good: use range comparison
SELECT * FROM orders WHERE order_date >= '2025-01-01' AND order_date < '2026-01-01';
```

---

### Q30. What is a deadlock and how do you prevent it?

A deadlock occurs when two or more transactions wait for each other to release locks, creating a circular dependency. Neither can proceed.

**Prevention strategies**:
- Access tables in a **consistent order** across all transactions
- Keep transactions **short and fast**
- Use **appropriate isolation levels**
- Use `SELECT ... FOR UPDATE NOWAIT` to fail fast instead of waiting
- Set `lock_timeout` to avoid indefinite waiting

---

### Q31. What is the difference between clustered and non-clustered indexes?

| Feature              | Clustered Index                    | Non-Clustered Index              |
|----------------------|------------------------------------|----------------------------------|
| Data ordering        | Physically reorders table data     | Separate structure pointing to data |
| Per table            | Only one                           | Multiple allowed                 |
| Speed (range queries)| Faster                             | Slower (extra lookup)            |
| PostgreSQL note      | No true clustered index; use `CLUSTER` command to reorder once |

---

### Q32. What is database denormalization and when would you use it?

Denormalization intentionally adds redundancy to a normalized database to improve **read performance**. Common in data warehouses, reporting systems, and read-heavy applications.

**Examples**: Storing a calculated `total_amount` in the orders table, duplicating `customer_name` to avoid JOINs.

**Trade-offs**: Faster reads but slower writes, more storage, risk of data inconsistency.

---

### Q33. Explain the concept of query execution plans.

An execution plan shows how the database engine will execute a query — which indexes it will use, the join strategy, and estimated costs.

```sql
EXPLAIN ANALYZE
SELECT e.name, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.id
WHERE e.salary > 50000;
```

**Key things to look for**:
- **Seq Scan** vs **Index Scan** (prefer index scans)
- **Nested Loop** vs **Hash Join** vs **Merge Join**
- **Actual rows** vs **estimated rows** (large differences indicate stale statistics)
- **Total cost** and **execution time**

---

### Q34. What are stored procedures and functions? How do they differ?

| Feature              | Function                        | Stored Procedure                  |
|----------------------|---------------------------------|-----------------------------------|
| Return value         | Must return a value             | May or may not return             |
| Use in SQL           | Can be used in SELECT           | Called with `CALL`                |
| Transaction control  | Cannot COMMIT/ROLLBACK inside   | Can COMMIT/ROLLBACK inside        |
| Side effects         | Should be side-effect free      | Can have side effects             |

```sql
-- Function
CREATE FUNCTION get_emp_count(dept TEXT) RETURNS INT AS $$
    SELECT COUNT(*) FROM employees WHERE department = dept;
$$ LANGUAGE SQL;

-- Stored Procedure (PostgreSQL 11+)
CREATE PROCEDURE give_raise(dept TEXT, amount NUMERIC) AS $$
    UPDATE employees SET salary = salary + amount WHERE department = dept;
$$ LANGUAGE SQL;

CALL give_raise('Engineering', 5000);
```

---

### Q35. What is a pivot table in SQL?

A pivot table transforms rows into columns. PostgreSQL doesn't have a native `PIVOT` keyword, but you can achieve it with `CASE` + `GROUP BY` or the `crosstab()` function.

```sql
-- Using CASE + GROUP BY
SELECT department,
    COUNT(CASE WHEN gender = 'M' THEN 1 END) AS male_count,
    COUNT(CASE WHEN gender = 'F' THEN 1 END) AS female_count
FROM employees
GROUP BY department;
```

| department  | male_count | female_count |
|-------------|------------|--------------|
| Engineering | 12         | 8            |
| Marketing   | 5          | 10           |

---

## 💡 Quick Tips for SQL Interviews

1. **Think out loud** — explain your approach before writing the query
2. **Start simple** — get a working query first, then optimize
3. **Clarify assumptions** — ask about NULLs, duplicates, and edge cases
4. **Know the execution order** — FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY
5. **Practice window functions** — they appear in 70%+ of advanced SQL interviews
6. **Know EXPLAIN ANALYZE** — interviewers love query optimization questions
7. **Understand trade-offs** — normalization vs denormalization, index benefits vs costs
8. **Write clean SQL** — use aliases, proper indentation, and uppercase keywords

---

*Happy Interviewing! 🎯*
