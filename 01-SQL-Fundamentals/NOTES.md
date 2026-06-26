# 📘 SQL Fundamentals — Notes

> **Goal**: Understand the four foundational SQL clauses — `SELECT`, `WHERE`, `ORDER BY`, and `LIMIT` — that form the backbone of every SQL query.

---

## 📋 Table of Contents

- [Sample Table](#sample-table)
- [SELECT — Retrieving Data](#select--retrieving-data)
- [WHERE — Filtering Rows](#where--filtering-rows)
- [ORDER BY — Sorting Results](#order-by--sorting-results)
- [LIMIT & OFFSET — Pagination](#limit--offset--pagination)
- [Query Execution Order](#query-execution-order)
- [Real-World Usage](#real-world-usage)
- [Common Mistakes](#common-mistakes)

---

## Sample Table

All examples in this folder use the **employees** table:

| employee_id | first_name | last_name | department  | salary | hire_date  | manager_id |
|-------------|------------|-----------|-------------|--------|------------|------------|
| 1           | Amit       | Sharma    | Engineering | 75000  | 2021-03-15 | NULL       |
| 2           | Priya      | Verma     | Marketing   | 55000  | 2022-07-01 | 1          |
| 3           | Rahul      | Gupta     | Engineering | 82000  | 2020-01-10 | 1          |
| 4           | Sneha      | Patel     | HR          | 48000  | 2023-02-20 | 1          |
| 5           | Vikram     | Singh     | Marketing   | 60000  | 2021-11-05 | 2          |

---

## SELECT — Retrieving Data

**Purpose**: Retrieve data from a table.

### Syntax

```sql
SELECT column1, column2, ...
FROM table_name;
```

### Key Concepts

| Feature               | Syntax                            | Example                                      |
|-----------------------|-----------------------------------|----------------------------------------------|
| All columns           | `SELECT *`                        | `SELECT * FROM employees;`                   |
| Specific columns      | `SELECT col1, col2`              | `SELECT first_name, salary FROM employees;`  |
| Aliases               | `AS alias_name`                  | `SELECT salary AS pay FROM employees;`       |
| Distinct values       | `SELECT DISTINCT col`            | `SELECT DISTINCT department FROM employees;` |
| Expressions           | Math / string operations          | `SELECT salary * 12 AS annual FROM employees;` |
| String concatenation  | `\|\|` operator                   | `SELECT first_name \|\| ' ' \|\| last_name AS full_name FROM employees;` |
| Conditional (CASE)    | `CASE WHEN ... THEN ... END`     | See `SELECT.sql` for full example            |

### Best Practices

- ✅ **Always specify columns** instead of `SELECT *` in production code
- ✅ **Use aliases** to make output more readable
- ✅ **Use DISTINCT** only when you truly need unique values (it adds overhead)

---

## WHERE — Filtering Rows

**Purpose**: Filter rows based on conditions. Only rows where the condition is `TRUE` are included in the result.

### Syntax

```sql
SELECT columns
FROM table_name
WHERE condition;
```

### Operators

| Operator    | Description              | Example                                |
|-------------|--------------------------|----------------------------------------|
| `=`         | Equal to                 | `WHERE department = 'HR'`              |
| `!=` / `<>` | Not equal to            | `WHERE department != 'HR'`             |
| `>`         | Greater than             | `WHERE salary > 60000`                 |
| `<`         | Less than                | `WHERE salary < 60000`                 |
| `>=`        | Greater than or equal    | `WHERE salary >= 60000`                |
| `<=`        | Less than or equal       | `WHERE salary <= 60000`                |

### Logical Operators

| Operator | Description                     | Example                                             |
|----------|---------------------------------|-----------------------------------------------------|
| `AND`    | Both conditions must be true    | `WHERE department = 'Engineering' AND salary > 70000` |
| `OR`     | At least one must be true       | `WHERE department = 'HR' OR department = 'Marketing'` |
| `NOT`    | Negates a condition             | `WHERE NOT department = 'HR'`                        |

### NULL Handling

```sql
-- Correct: use IS NULL / IS NOT NULL
SELECT * FROM employees WHERE manager_id IS NULL;

-- Wrong: = NULL will NOT work
SELECT * FROM employees WHERE manager_id = NULL;  -- Returns nothing!
```

> **Why?** In SQL, `NULL` means *unknown*. Comparing anything to `NULL` with `=` always returns `NULL` (not `TRUE`), so no rows match.

---

## ORDER BY — Sorting Results

**Purpose**: Sort the result set by one or more columns.

### Syntax

```sql
SELECT columns
FROM table_name
ORDER BY column1 [ASC|DESC], column2 [ASC|DESC];
```

### Key Points

- **ASC** (ascending) is the default — smallest to largest, A to Z, oldest to newest
- **DESC** (descending) — largest to smallest, Z to A, newest to oldest
- **Multi-column sorting**: the second column breaks ties in the first

### NULL Handling in ORDER BY

PostgreSQL places NULLs **last** in ascending order and **first** in descending by default. Override with:

```sql
ORDER BY column ASC NULLS FIRST;
ORDER BY column DESC NULLS LAST;
```

---

## LIMIT & OFFSET — Pagination

**Purpose**: Restrict the number of rows returned and skip rows for pagination.

### Syntax

```sql
SELECT columns
FROM table_name
ORDER BY column
LIMIT page_size
OFFSET skip_count;
```

### Pagination Formula

```
Page 1:  LIMIT 10 OFFSET 0
Page 2:  LIMIT 10 OFFSET 10
Page 3:  LIMIT 10 OFFSET 20
...
Page N:  LIMIT page_size OFFSET (N - 1) * page_size
```

### SQL-Standard Alternative

```sql
FETCH FIRST 10 ROWS ONLY        -- Same as LIMIT 10
OFFSET 5 ROWS FETCH FIRST 10 ROWS ONLY  -- Same as LIMIT 10 OFFSET 5
```

### Performance Note

Large `OFFSET` values are slow because PostgreSQL still scans and discards all skipped rows. For large datasets, consider **keyset pagination** (also called "cursor-based pagination"):

```sql
-- Instead of OFFSET, use a WHERE clause on the last seen value
SELECT * FROM employees
WHERE employee_id > 100  -- last seen ID
ORDER BY employee_id
LIMIT 10;
```

---

## Query Execution Order

SQL does **not** execute in the order you write it. The actual execution order is:

```
1. FROM       → Which table(s)?
2. WHERE      → Filter rows
3. GROUP BY   → Group the remaining rows
4. HAVING     → Filter groups
5. SELECT     → Choose columns / compute expressions
6. DISTINCT   → Remove duplicates
7. ORDER BY   → Sort the results
8. LIMIT      → Restrict number of rows returned
```

This is why you **cannot** use a column alias from `SELECT` inside `WHERE` — `WHERE` runs before `SELECT`.

---

## Real-World Usage

| Scenario                             | SQL Pattern                              |
|--------------------------------------|------------------------------------------|
| Display a user profile               | `SELECT specific columns WHERE id = ?`   |
| Search products by category          | `WHERE category = ?`                     |
| Show newest blog posts first         | `ORDER BY created_at DESC`               |
| API pagination (10 items per page)   | `LIMIT 10 OFFSET ?`                      |
| Dashboard: top 5 salespeople         | `ORDER BY total_sales DESC LIMIT 5`      |
| Find unassigned tickets              | `WHERE assignee_id IS NULL`              |

---

## Common Mistakes

| Mistake                                    | Correction                                |
|--------------------------------------------|-------------------------------------------|
| `SELECT * FROM ...` in production          | Specify only needed columns               |
| `WHERE column = NULL`                      | Use `WHERE column IS NULL`                |
| `LIMIT` without `ORDER BY`                | Always pair them for predictable results  |
| Using column alias in WHERE                | Use the original column name or expression |
| Forgetting parentheses with AND/OR         | Always use parentheses for clarity        |

---

## Files in This Folder

| File          | Description                                      |
|---------------|--------------------------------------------------|
| `SELECT.sql`  | SELECT examples with aliases, DISTINCT, CASE     |
| `WHERE.sql`   | WHERE clause with operators, AND/OR/NOT, NULL     |
| `ORDER_BY.sql`| Sorting with ASC/DESC, multi-column, NULL handling |
| `LIMIT.sql`   | LIMIT, OFFSET, pagination, FETCH FIRST            |
| `NOTES.md`    | This file — comprehensive notes                  |
