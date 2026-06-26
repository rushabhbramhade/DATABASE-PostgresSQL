# 📘 Third Normal Form (3NF)

## 📑 Table of Contents

- [Prerequisites](#prerequisites)
- [What is 3NF?](#what-is-3nf)
- [What is a Transitive Dependency?](#what-is-a-transitive-dependency)
- [The Rule of 3NF](#the-rule-of-3nf)
- [Bad Example — Transitive Dependency](#bad-example--transitive-dependency)
- [Good Example — Decomposed Tables](#good-example--decomposed-tables)
- [SQL Examples — The Decomposition](#sql-examples--the-decomposition)
- [Another Example — Orders Table](#another-example--orders-table)
- [Summary: 1NF → 2NF → 3NF Progression](#summary-1nf--2nf--3nf-progression)
- [Key Takeaways](#key-takeaways)

---

## Prerequisites

> ⚠️ **A table MUST be in [2NF](./2NF.md) before it can be evaluated for 3NF.**

Before reading this file, make sure you understand:
- **1NF:** Atomic values, no repeating groups, unique rows
- **2NF:** No partial dependencies on a composite key

**3NF builds on top of 2NF** by eliminating **transitive dependencies**.

---

## What is 3NF?

**Third Normal Form (3NF)** requires that:

1. The table is already in **2NF**, AND
2. No **non-key column** depends on **another non-key column**

In other words, every non-key column must depend **directly** on the primary key — not indirectly through another non-key column.

---

## What is a Transitive Dependency?

A **transitive dependency** is when a non-key column depends on the primary key **indirectly**, through another non-key column.

### The Chain

```
Primary Key → Non-Key Column A → Non-Key Column B
```

Column B doesn't depend on the primary key directly — it depends on Column A, which in turn depends on the primary key. This is a **transitive** (indirect) dependency.

### Visual Example

```
┌──────────────────────────────────────────────────────────┐
│  employees table                                         │
│                                                          │
│  emp_id ──────► emp_name           ✅ Direct dependency   │
│  emp_id ──────► department_id      ✅ Direct dependency   │
│  emp_id ──────► salary             ✅ Direct dependency   │
│                                                          │
│  department_id ──────► department_name  ❌ TRANSITIVE!     │
│  department_id ──────► dept_location    ❌ TRANSITIVE!     │
│                                                          │
│  emp_id → department_id → department_name (indirect!)    │
└──────────────────────────────────────────────────────────┘
```

Here, `department_name` depends on `department_id`, which depends on `emp_id`. So `department_name` has a **transitive dependency** on the primary key `emp_id`.

---

## The Rule of 3NF

| Condition | Requirement |
|-----------|-------------|
| Table must be in 2NF | ✅ In 1NF + no partial dependencies |
| No transitive dependencies | No non-key column should depend on another non-key column |

> **The classic way to remember 3NF:**
>
> *"Every non-key column must provide a fact about the key, the whole key, and nothing but the key — so help me Codd."*
>
> — A play on the courtroom oath, attributed to Bill Kent

| Normal Form | Rule (in the oath) |
|-------------|-------------------|
| **1NF** | "...the key" (every row is uniquely identifiable) |
| **2NF** | "...the whole key" (no partial dependencies) |
| **3NF** | "...nothing but the key" (no transitive dependencies) |

---

## Bad Example — Transitive Dependency

### ❌ `employees` Table (Violates 3NF)

| emp_id | emp_name      | department_id | department_name | dept_location |
|--------|---------------|---------------|-----------------|---------------|
| 1      | Amit Sharma   | D10           | Engineering     | Building A    |
| 2      | Priya Patel   | D10           | Engineering     | Building A    |
| 3      | Ravi Kumar    | D20           | Marketing       | Building B    |
| 4      | Sneha Gupta   | D20           | Marketing       | Building B    |
| 5      | Kiran Desai   | D30           | Finance         | Building C    |

**Primary Key:** `emp_id`

### What's Wrong?

| Column            | Depends On        | Dependency Type       |
|-------------------|-------------------|-----------------------|
| `emp_name`        | `emp_id`          | ✅ Direct              |
| `department_id`   | `emp_id`          | ✅ Direct              |
| `department_name` | `department_id`   | ❌ **Transitive**      |
| `dept_location`   | `department_id`   | ❌ **Transitive**      |

- `department_name` and `dept_location` are facts about the **department**, not about the **employee**.
- `"Engineering"` and `"Building A"` are duplicated for every employee in department D10.

---

## Good Example — Decomposed Tables

We extract the department information into its own table:

### ✅ `employees` table

| emp_id | emp_name      | department_id |
|--------|---------------|---------------|
| 1      | Amit Sharma   | D10           |
| 2      | Priya Patel   | D10           |
| 3      | Ravi Kumar    | D20           |
| 4      | Sneha Gupta   | D20           |
| 5      | Kiran Desai   | D30           |

**Primary Key:** `emp_id`
— Every non-key column (`emp_name`, `department_id`) depends **directly** on `emp_id`.

### ✅ `departments` table

| department_id | department_name | dept_location |
|---------------|-----------------|---------------|
| D10           | Engineering     | Building A    |
| D20           | Marketing       | Building B    |
| D30           | Finance         | Building C    |

**Primary Key:** `department_id`
— `department_name` and `dept_location` depend directly on `department_id`.

### Why This Works

- `"Engineering"` is stored **once**, in the `departments` table.
- The `employees` table stores only a **reference** (`department_id`), linked via a Foreign Key.
- No transitive dependencies remain in either table.

---

## SQL Examples — The Decomposition

### ❌ BEFORE — Single Table (Violates 3NF)

```sql
-- BAD DESIGN: department_name and dept_location transitively depend on emp_id
CREATE TABLE employees_bad (
    emp_id          SERIAL PRIMARY KEY,
    emp_name        VARCHAR(100) NOT NULL,
    department_id   VARCHAR(10),
    department_name VARCHAR(100),
    dept_location   VARCHAR(100)
);

INSERT INTO employees_bad (emp_name, department_id, department_name, dept_location) VALUES
('Amit Sharma', 'D10', 'Engineering', 'Building A'),
('Priya Patel', 'D10', 'Engineering', 'Building A'),
('Ravi Kumar',  'D20', 'Marketing',   'Building B'),
('Sneha Gupta', 'D20', 'Marketing',   'Building B'),
('Kiran Desai', 'D30', 'Finance',     'Building C');

-- Problem: If Engineering moves to Building D, we must update EVERY Engineering row
UPDATE employees_bad
SET dept_location = 'Building D'
WHERE department_id = 'D10';
-- Miss one row? Now you have inconsistent data!
```

### ✅ AFTER — Decomposed Tables (3NF)

```sql
-- Departments table: stores department facts
CREATE TABLE departments (
    department_id   VARCHAR(10) PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    dept_location   VARCHAR(100) NOT NULL
);

-- Employees table: stores employee facts + FK to departments
CREATE TABLE employees (
    emp_id        SERIAL PRIMARY KEY,
    emp_name      VARCHAR(100) NOT NULL,
    department_id VARCHAR(10) REFERENCES departments(department_id)
);

-- Insert departments first (parent table)
INSERT INTO departments (department_id, department_name, dept_location) VALUES
('D10', 'Engineering', 'Building A'),
('D20', 'Marketing',   'Building B'),
('D30', 'Finance',     'Building C');

-- Then insert employees
INSERT INTO employees (emp_name, department_id) VALUES
('Amit Sharma', 'D10'),
('Priya Patel', 'D10'),
('Ravi Kumar',  'D20'),
('Sneha Gupta', 'D20'),
('Kiran Desai', 'D30');
```

### Querying the Normalized Structure

```sql
-- Get employee details with department info
SELECT 
    e.emp_id,
    e.emp_name,
    d.department_name,
    d.dept_location
FROM employees e
JOIN departments d ON e.department_id = d.department_id
ORDER BY e.emp_id;
```

**Expected Output:**

| emp_id | emp_name      | department_name | dept_location |
|--------|---------------|-----------------|---------------|
| 1      | Amit Sharma   | Engineering     | Building A    |
| 2      | Priya Patel   | Engineering     | Building A    |
| 3      | Ravi Kumar    | Marketing       | Building B    |
| 4      | Sneha Gupta   | Marketing       | Building B    |
| 5      | Kiran Desai   | Finance         | Building C    |

```sql
-- Now updating a department location is ONE simple statement
UPDATE departments
SET dept_location = 'Building D'
WHERE department_id = 'D10';
-- Done! All employees in Engineering now reflect 'Building D' automatically.
```

---

## Another Example — Orders Table

### ❌ Before 3NF

```sql
-- order_id → customer_id → customer_name (transitive!)
CREATE TABLE orders_bad (
    order_id      SERIAL PRIMARY KEY,
    order_date    DATE NOT NULL,
    customer_id   INT,
    customer_name VARCHAR(100),  -- depends on customer_id, NOT order_id
    customer_city VARCHAR(100),  -- depends on customer_id, NOT order_id
    total_amount  NUMERIC(10,2)
);
```

### ✅ After 3NF

```sql
CREATE TABLE customers (
    customer_id   SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    customer_city VARCHAR(100)
);

CREATE TABLE orders (
    order_id     SERIAL PRIMARY KEY,
    order_date   DATE NOT NULL,
    customer_id  INT REFERENCES customers(customer_id),
    total_amount NUMERIC(10,2)
);
```

Now `customer_name` and `customer_city` live in `customers`, where they depend directly on `customer_id` (the primary key of that table). No transitive dependency in `orders`.

---

## Summary: 1NF → 2NF → 3NF Progression

Here is the complete picture of how normalization progresses through the first three normal forms:

### The Rules at Each Level

| Normal Form | Rule | What It Eliminates |
|-------------|------|--------------------|
| **1NF** | Atomic values, no repeating groups, unique rows | Multi-valued cells, duplicate structures |
| **2NF** | 1NF + no partial dependencies | Columns depending on part of a composite key |
| **3NF** | 2NF + no transitive dependencies | Non-key columns depending on other non-key columns |

### A Complete Walkthrough

Imagine an **unnormalized** table:

```
student_id | course_id | student_name | student_email     | course_name     | instructor | instructor_email      | grade
-----------+-----------+--------------+-------------------+-----------------+------------+-----------------------+------
101        | CS201     | Amit Sharma  | amit@example.com  | Data Structures | Dr. Rao    | rao@university.edu    | A
101        | CS202     | Amit Sharma  | amit@example.com  | Algorithms      | Dr. Singh  | singh@university.edu  | B+
```

**Step 1 — Apply 1NF:** ✅ Already in 1NF (all values are atomic, rows are unique with composite key `(student_id, course_id)`).

**Step 2 — Apply 2NF:** Remove partial dependencies.
- `student_name`, `student_email` → depend only on `student_id` → move to `students` table
- `course_name`, `instructor`, `instructor_email` → depend only on `course_id` → move to `courses` table
- Result: `students`, `courses`, `enrollments(student_id, course_id, grade)`

**Step 3 — Apply 3NF:** Remove transitive dependencies.
- In the `courses` table: `instructor_email` depends on `instructor`, not on `course_id` directly
- Move `instructor` info to an `instructors` table
- Result: `students`, `courses`, `instructors`, `enrollments`

### Final Schema

```
students(student_id, student_name, student_email)
instructors(instructor_id, instructor_name, instructor_email)
courses(course_id, course_name, instructor_id)
enrollments(student_id, course_id, grade)
```

✅ Every non-key column depends on **the key, the whole key, and nothing but the key**.

---

## Key Takeaways

| ✅ Do                                                | ❌ Don't                                                    |
|-----------------------------------------------------|-------------------------------------------------------------|
| Ensure 2NF before checking for 3NF                 | Skip directly to 3NF without ensuring 1NF and 2NF          |
| Look for non-key → non-key dependencies            | Store department/customer details in transactional tables    |
| Extract transitively dependent columns to new tables | Duplicate lookup data across rows                          |
| Use Foreign Keys to maintain relationships          | Avoid JOINs by stuffing everything into one table           |
| Remember: *"Nothing but the key"*                   | Forget that 3NF is about **direct** dependency on the PK   |

> **The 3NF Rule in One Sentence:** *No non-key column should depend on another non-key column — every fact must be a fact about the primary key directly.*

---

*← [Second Normal Form (2NF)](./2NF.md) | [Boyce-Codd Normal Form (BCNF) →](./BCNF.md)*
