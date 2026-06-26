# Database Constraints

## Table of Contents

- [What are Constraints?](#what-are-constraints)
- [How Constraints Enforce Data Integrity](#how-constraints-enforce-data-integrity)
- [PRIMARY KEY](#primary-key)
- [FOREIGN KEY](#foreign-key)
  - [Referential Actions (ON DELETE / ON UPDATE)](#referential-actions-on-delete--on-update)
  - [CASCADE](#cascade)
  - [SET NULL](#set-null)
  - [SET DEFAULT](#set-default)
  - [RESTRICT / NO ACTION](#restrict--no-action)
  - [Comparison Table](#which-action-should-you-use)
- [UNIQUE](#unique)
- [NOT NULL](#not-null)
- [CHECK](#check)
- [DEFAULT](#default)
- [Combining Multiple Constraints](#combining-multiple-constraints)
- [Named Constraints](#named-constraints)
- [Adding and Removing Constraints (ALTER TABLE)](#adding-and-removing-constraints-alter-table)
- [Common Mistakes with Constraints](#common-mistakes-with-constraints)
- [Quick Reference Table](#quick-reference-table)
- [Key Takeaways](#key-takeaways)

---

## What are Constraints?

**Constraints** are rules enforced on table columns to ensure the **accuracy, consistency, and reliability** of the data in a database. They prevent invalid data from being inserted, updated, or deleted.

Think of constraints as **guardrails** for your data — they automatically reject operations that would break your data rules.

```
Without constraints:
  INSERT INTO employees (salary) VALUES (-50000);  ← Bad data gets in!

With constraints:
  salary DECIMAL(10,2) CHECK (salary > 0)
  INSERT INTO employees (salary) VALUES (-50000);  ← REJECTED by PostgreSQL
```

---

## How Constraints Enforce Data Integrity

| Integrity Type | Constraint | What It Protects |
|----------------|------------|------------------|
| **Entity Integrity** | `PRIMARY KEY` | Every row is uniquely identifiable |
| **Referential Integrity** | `FOREIGN KEY` | Relationships between tables remain valid |
| **Domain Integrity** | `CHECK`, `NOT NULL`, `DEFAULT` | Column values stay within valid ranges |
| **Uniqueness** | `UNIQUE` | No duplicate values in specified columns |

---

## PRIMARY KEY

A **PRIMARY KEY** constraint uniquely identifies each row in a table. It combines two rules: `UNIQUE` + `NOT NULL`.

### Rules

- Every table should have exactly **one** primary key
- Primary key values must be **unique** and **cannot be NULL**
- Can be a **single column** or **multiple columns** (composite PK)
- PostgreSQL automatically creates an **index** on the primary key

### Syntax Options

```sql
-- Option 1: Inline (single column)
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    name       VARCHAR(100) NOT NULL
);

-- Option 2: Table-level (useful for composite keys)
CREATE TABLE enrollments (
    student_id INT NOT NULL,
    course_id  INT NOT NULL,
    grade      CHAR(2),
    PRIMARY KEY (student_id, course_id)
);
```

### Example

```sql
CREATE TABLE products (
    product_id   SERIAL PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    price        DECIMAL(10,2)
);

-- ✅ This works:
INSERT INTO products (product_name, price) VALUES ('Laptop', 999.99);
INSERT INTO products (product_name, price) VALUES ('Mouse', 29.99);

-- ❌ This FAILS — duplicate primary key:
INSERT INTO products (product_id, product_name, price) VALUES (1, 'Keyboard', 49.99);
-- ERROR: duplicate key value violates unique constraint "products_pkey"

-- ❌ This FAILS — NULL primary key:
INSERT INTO products (product_id, product_name, price) VALUES (NULL, 'Monitor', 299.99);
-- ERROR: null value in column "product_id" violates not-null constraint
```

### SERIAL vs INTEGER for Primary Keys

| Approach | Syntax | Behavior |
|----------|--------|----------|
| `SERIAL` | `id SERIAL PRIMARY KEY` | Auto-generates sequential integers (1, 2, 3, ...) |
| `GENERATED ALWAYS` | `id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY` | Modern PostgreSQL approach (SQL standard) |
| `UUID` | `id UUID DEFAULT gen_random_uuid() PRIMARY KEY` | Globally unique, good for distributed systems |

```sql
-- Modern PostgreSQL recommended approach:
CREATE TABLE orders (
    order_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## FOREIGN KEY

A **FOREIGN KEY** constraint creates a link between two tables by referencing the primary key (or a unique column) of another table.

### What It Enforces

- You **cannot insert** a value in the FK column that doesn't exist in the referenced table
- You **cannot delete** a row from the parent table if child rows reference it (default behavior)
- Maintains **referential integrity** — every reference points to a valid row

### Syntax

```sql
-- Inline syntax:
CREATE TABLE orders (
    order_id    SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    order_date  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table-level syntax (more explicit):
CREATE TABLE orders (
    order_id    SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
```

### Example

```sql
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL
);

CREATE TABLE orders (
    order_id    SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    total       DECIMAL(10,2)
);

INSERT INTO customers (name) VALUES ('Alice'), ('Bob');

-- ✅ Works: customer_id 1 exists
INSERT INTO orders (customer_id, total) VALUES (1, 150.00);

-- ❌ FAILS: customer_id 999 does not exist
INSERT INTO orders (customer_id, total) VALUES (999, 50.00);
-- ERROR: insert or update on table "orders" violates foreign key constraint
-- Detail: Key (customer_id)=(999) is not present in table "customers".
```

---

### Referential Actions (ON DELETE / ON UPDATE)

When a referenced row in the parent table is deleted or updated, PostgreSQL needs to know what to do with the child rows. This is controlled by **referential actions**.

```sql
FOREIGN KEY (column) REFERENCES parent_table(column)
    ON DELETE <action>
    ON UPDATE <action>
```

---

### CASCADE

**`ON DELETE CASCADE`** — When a parent row is deleted, **automatically delete** all child rows that reference it.

```sql
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    dept_name     VARCHAR(100) NOT NULL
);

CREATE TABLE employees (
    employee_id   SERIAL PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    department_id INT REFERENCES departments(department_id) ON DELETE CASCADE
);

INSERT INTO departments (dept_name) VALUES ('Engineering'), ('Marketing');
INSERT INTO employees (name, department_id) VALUES
    ('Alice', 1), ('Bob', 1), ('Charlie', 2);

-- Delete the Engineering department:
DELETE FROM departments WHERE department_id = 1;

-- Result: Alice and Bob are AUTOMATICALLY deleted from employees
-- Only Charlie remains (Marketing department)
SELECT * FROM employees;
```

| employee_id | name | department_id |
|:---:|:---:|:---:|
| 3 | Charlie | 2 |

> **Use CASCADE when:** Child data has no meaning without the parent (order items without an order, comments without a post).

---

### SET NULL

**`ON DELETE SET NULL`** — When a parent row is deleted, **set the FK column to NULL** in child rows.

```sql
CREATE TABLE managers (
    manager_id SERIAL PRIMARY KEY,
    name       VARCHAR(100) NOT NULL
);

CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    manager_id  INT REFERENCES managers(manager_id) ON DELETE SET NULL
    --          Note: column must allow NULLs (no NOT NULL constraint)
);

INSERT INTO managers (name) VALUES ('Sarah'), ('Mike');
INSERT INTO employees (name, manager_id) VALUES
    ('Alice', 1), ('Bob', 1), ('Charlie', 2);

-- Delete manager Sarah:
DELETE FROM managers WHERE manager_id = 1;

-- Result: Alice and Bob still exist, but their manager_id is now NULL
SELECT * FROM employees;
```

| employee_id | name | manager_id |
|:---:|:---:|:---:|
| 1 | Alice | NULL |
| 2 | Bob | NULL |
| 3 | Charlie | 2 |

> **Use SET NULL when:** The child data is still valid on its own, but the specific association is gone (employee without a manager is still an employee).

---

### SET DEFAULT

**`ON DELETE SET DEFAULT`** — When a parent row is deleted, **set the FK column to its DEFAULT value**.

```sql
CREATE TABLE statuses (
    status_id SERIAL PRIMARY KEY,
    status_name VARCHAR(50) NOT NULL
);

INSERT INTO statuses (status_name) VALUES ('Active'), ('Inactive'), ('Unassigned');

CREATE TABLE tasks (
    task_id   SERIAL PRIMARY KEY,
    title     VARCHAR(200) NOT NULL,
    status_id INT DEFAULT 3 REFERENCES statuses(status_id) ON DELETE SET DEFAULT
    --            ^^^^^^^^^
    --            Default value MUST exist in the parent table
);

INSERT INTO tasks (title, status_id) VALUES ('Build API', 1), ('Write Docs', 1);

-- Delete 'Active' status:
DELETE FROM statuses WHERE status_id = 1;

-- Result: tasks now have status_id = 3 (Unassigned)
SELECT t.title, s.status_name
FROM tasks t
JOIN statuses s ON t.status_id = s.status_id;
```

| title | status_name |
|:---:|:---:|
| Build API | Unassigned |
| Write Docs | Unassigned |

> **Use SET DEFAULT when:** You have a sensible fallback value (e.g., "Unassigned" status, "General" category).

---

### RESTRICT / NO ACTION

**`ON DELETE RESTRICT`** — **Prevent** the parent row from being deleted if any child rows reference it.

**`ON DELETE NO ACTION`** — Same as `RESTRICT` in most cases (this is the **default** behavior in PostgreSQL).

```sql
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL
);

CREATE TABLE products (
    product_id   SERIAL PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    category_id  INT REFERENCES categories(category_id) ON DELETE RESTRICT
);

INSERT INTO categories (category_name) VALUES ('Electronics'), ('Books');
INSERT INTO products (product_name, category_id) VALUES ('Laptop', 1), ('Phone', 1);

-- ❌ This FAILS — products still reference this category:
DELETE FROM categories WHERE category_id = 1;
-- ERROR: update or delete on table "categories" violates foreign key constraint
-- Detail: Key (category_id)=(1) is still referenced from table "products".

-- ✅ Must delete products first, then the category:
DELETE FROM products WHERE category_id = 1;
DELETE FROM categories WHERE category_id = 1;
```

> **Use RESTRICT when:** Parent data should never be deleted while it's in use (don't delete a category that still has products).

---

### Which Action Should You Use?

| Action | Behavior | Best For |
|--------|----------|----------|
| `CASCADE` | Delete child rows automatically | Order items, comments, dependent records |
| `SET NULL` | Set FK to NULL | Optional relationships (employee's manager) |
| `SET DEFAULT` | Set FK to default value | Fallback category or status |
| `RESTRICT` | Block the delete entirely | Protect critical references (don't delete active categories) |
| `NO ACTION` | Same as RESTRICT (default) | Default safe behavior |

### Decision Flowchart

```
Parent row is being deleted. What should happen to child rows?

    ├── Child data is meaningless without parent?
    │       → ON DELETE CASCADE
    │
    ├── Child data is still valid, but association is optional?
    │       → ON DELETE SET NULL
    │
    ├── There's a sensible default to fall back to?
    │       → ON DELETE SET DEFAULT
    │
    └── Deletion should be blocked entirely?
            → ON DELETE RESTRICT (or NO ACTION)
```

---

## UNIQUE

A **UNIQUE** constraint ensures that all values in a column (or combination of columns) are distinct across all rows.

### Differences from PRIMARY KEY

| Feature | PRIMARY KEY | UNIQUE |
|---------|:-----------:|:------:|
| Allows NULL? | ❌ No | ✅ Yes (one NULL allowed) |
| Per table limit | Exactly 1 | Unlimited |
| Creates index? | ✅ Yes | ✅ Yes |

### Syntax

```sql
-- Inline:
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    email       VARCHAR(100) UNIQUE NOT NULL,
    phone       VARCHAR(20) UNIQUE
);

-- Table-level (for multi-column uniqueness):
CREATE TABLE employee_assignments (
    employee_id   INT NOT NULL,
    project_id    INT NOT NULL,
    assigned_date DATE,
    UNIQUE (employee_id, project_id)   -- combination must be unique
);
```

### Example

```sql
CREATE TABLE users (
    user_id  SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email    VARCHAR(100) UNIQUE NOT NULL
);

INSERT INTO users (username, email) VALUES ('alice', 'alice@example.com');

-- ❌ FAILS — duplicate username:
INSERT INTO users (username, email) VALUES ('alice', 'alice2@example.com');
-- ERROR: duplicate key value violates unique constraint "users_username_key"

-- ❌ FAILS — duplicate email:
INSERT INTO users (username, email) VALUES ('alice2', 'alice@example.com');
-- ERROR: duplicate key value violates unique constraint "users_email_key"

-- ✅ Works — both are unique:
INSERT INTO users (username, email) VALUES ('bob', 'bob@example.com');
```

### Multi-Column UNIQUE

```sql
-- A teacher can teach the same course in different semesters
-- But NOT the same course in the same semester twice
CREATE TABLE teaching_assignments (
    assignment_id SERIAL PRIMARY KEY,
    teacher_id    INT NOT NULL,
    course_id     INT NOT NULL,
    semester      VARCHAR(20) NOT NULL,
    UNIQUE (teacher_id, course_id, semester)
);

-- ✅ Works:
INSERT INTO teaching_assignments (teacher_id, course_id, semester)
VALUES (1, 101, 'Fall 2025');

-- ✅ Works (different semester):
INSERT INTO teaching_assignments (teacher_id, course_id, semester)
VALUES (1, 101, 'Spring 2026');

-- ❌ FAILS (same combination):
INSERT INTO teaching_assignments (teacher_id, course_id, semester)
VALUES (1, 101, 'Fall 2025');
-- ERROR: duplicate key value violates unique constraint
```

---

## NOT NULL

A **NOT NULL** constraint ensures that a column **cannot contain NULL values**. Every row must have a value for this column.

### Syntax

```sql
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name  VARCHAR(50) NOT NULL,     -- required
    last_name   VARCHAR(50) NOT NULL,     -- required
    middle_name VARCHAR(50),              -- optional (NULL allowed)
    email       VARCHAR(100) NOT NULL,    -- required
    phone       VARCHAR(20)              -- optional (NULL allowed)
);
```

### Example

```sql
-- ✅ Works — all NOT NULL fields provided:
INSERT INTO employees (first_name, last_name, email)
VALUES ('Alice', 'Johnson', 'alice@company.com');

-- ✅ Works — optional fields left as NULL:
INSERT INTO employees (first_name, last_name, email, phone)
VALUES ('Bob', 'Smith', 'bob@company.com', NULL);

-- ❌ FAILS — missing required field:
INSERT INTO employees (first_name, last_name)
VALUES ('Charlie', 'Brown');
-- ERROR: null value in column "email" of relation "employees" violates not-null constraint

-- ❌ FAILS — explicit NULL for NOT NULL column:
INSERT INTO employees (first_name, last_name, email)
VALUES (NULL, 'Davis', 'davis@company.com');
-- ERROR: null value in column "first_name" violates not-null constraint
```

### When to Use NOT NULL

| Use NOT NULL When | Allow NULL When |
|-------------------|-----------------|
| The field is essential (name, email) | The field is truly optional (middle name, fax) |
| Missing data would break business logic | Not all entities have this property |
| The column is part of a foreign key | It's a self-referencing FK (manager_id for CEO) |

> **Best Practice:** Default to `NOT NULL` and only allow `NULL` when there's a genuine reason. This prevents accidental missing data.

---

## CHECK

A **CHECK** constraint validates that column values satisfy a specific **Boolean condition**.

### Syntax

```sql
-- Inline:
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    price      DECIMAL(10,2) CHECK (price > 0),
    quantity   INT CHECK (quantity >= 0)
);

-- Table-level (can reference multiple columns):
CREATE TABLE events (
    event_id   SERIAL PRIMARY KEY,
    start_date DATE NOT NULL,
    end_date   DATE NOT NULL,
    CHECK (end_date >= start_date)    -- multi-column check
);
```

### Common CHECK Patterns

```sql
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name  VARCHAR(50) NOT NULL,
    email       VARCHAR(100) NOT NULL,
    salary      DECIMAL(10,2) NOT NULL,
    age         INT,
    status      VARCHAR(20),

    -- Numeric range
    CHECK (salary BETWEEN 30000 AND 500000),

    -- Minimum value
    CHECK (age >= 18),

    -- Allowed values (enum-like)
    CHECK (status IN ('active', 'inactive', 'on_leave', 'terminated')),

    -- String pattern
    CHECK (email LIKE '%@%.%'),

    -- String length
    CHECK (LENGTH(first_name) >= 2)
);
```

### Examples

```sql
CREATE TABLE hospital_patients (
    patient_id   SERIAL PRIMARY KEY,
    first_name   VARCHAR(50) NOT NULL,
    last_name    VARCHAR(50) NOT NULL,
    age          INT CHECK (age BETWEEN 0 AND 150),
    blood_type   VARCHAR(3) CHECK (blood_type IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
    weight_kg    DECIMAL(5,2) CHECK (weight_kg > 0),
    admission    DATE NOT NULL,
    discharge    DATE,
    CHECK (discharge IS NULL OR discharge >= admission)
);

-- ✅ Works:
INSERT INTO hospital_patients (first_name, last_name, age, blood_type, weight_kg, admission)
VALUES ('Alice', 'Johnson', 35, 'A+', 62.5, '2025-06-01');

-- ❌ FAILS — invalid age:
INSERT INTO hospital_patients (first_name, last_name, age, blood_type, weight_kg, admission)
VALUES ('Bob', 'Smith', -5, 'B+', 80.0, '2025-06-01');
-- ERROR: new row violates check constraint "hospital_patients_age_check"

-- ❌ FAILS — invalid blood type:
INSERT INTO hospital_patients (first_name, last_name, age, blood_type, weight_kg, admission)
VALUES ('Charlie', 'Brown', 40, 'X+', 75.0, '2025-06-01');
-- ERROR: new row violates check constraint "hospital_patients_blood_type_check"

-- ❌ FAILS — discharge before admission:
INSERT INTO hospital_patients (first_name, last_name, age, blood_type, weight_kg, admission, discharge)
VALUES ('Diana', 'Prince', 30, 'O+', 65.0, '2025-06-15', '2025-06-10');
-- ERROR: new row violates check constraint "hospital_patients_check"
```

---

## DEFAULT

A **DEFAULT** constraint provides an automatic value for a column when no value is specified during insertion.

### Syntax

```sql
CREATE TABLE orders (
    order_id     SERIAL PRIMARY KEY,
    status       VARCHAR(20) DEFAULT 'pending',
    order_date   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    priority     INT DEFAULT 0,
    is_express   BOOLEAN DEFAULT FALSE,
    notes        TEXT DEFAULT ''
);
```

### Common DEFAULT Values

| Data Type | Common Defaults | Example |
|-----------|-----------------|---------|
| `VARCHAR` | `'pending'`, `'active'`, `'unknown'` | `status VARCHAR(20) DEFAULT 'pending'` |
| `INT` | `0`, `1` | `quantity INT DEFAULT 0` |
| `DECIMAL` | `0.00` | `discount DECIMAL(5,2) DEFAULT 0.00` |
| `BOOLEAN` | `TRUE`, `FALSE` | `is_active BOOLEAN DEFAULT TRUE` |
| `DATE` | `CURRENT_DATE` | `created_on DATE DEFAULT CURRENT_DATE` |
| `TIMESTAMP` | `CURRENT_TIMESTAMP`, `NOW()` | `created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP` |
| `UUID` | `gen_random_uuid()` | `id UUID DEFAULT gen_random_uuid()` |
| `TEXT` | `''` | `notes TEXT DEFAULT ''` |

### Example

```sql
CREATE TABLE blog_posts (
    post_id      SERIAL PRIMARY KEY,
    title        VARCHAR(200) NOT NULL,
    content      TEXT NOT NULL,
    status       VARCHAR(20) DEFAULT 'draft',
    view_count   INT DEFAULT 0,
    is_featured  BOOLEAN DEFAULT FALSE,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    published_at TIMESTAMP   -- NULL by default (not published yet)
);

-- DEFAULT values are used when columns are omitted:
INSERT INTO blog_posts (title, content)
VALUES ('My First Post', 'Hello world!');

SELECT * FROM blog_posts;
```

**Expected Output:**

| post_id | title | content | status | view_count | is_featured | created_at | published_at |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 1 | My First Post | Hello world! | draft | 0 | false | 2025-06-26 15:30:00 | NULL |

```sql
-- You can override DEFAULT by specifying a value:
INSERT INTO blog_posts (title, content, status, is_featured)
VALUES ('Breaking News', 'Important update...', 'published', TRUE);
```

### DEFAULT with NOT NULL

```sql
-- Combining DEFAULT with NOT NULL ensures a column always has a value
CREATE TABLE user_settings (
    setting_id SERIAL PRIMARY KEY,
    user_id    INT NOT NULL REFERENCES users(user_id),
    theme      VARCHAR(20) NOT NULL DEFAULT 'light',      -- always has a value
    language   VARCHAR(10) NOT NULL DEFAULT 'en',          -- always has a value
    timezone   VARCHAR(50) NOT NULL DEFAULT 'UTC'          -- always has a value
);

-- Even if no values are provided, defaults kick in:
INSERT INTO user_settings (user_id) VALUES (1);
-- Result: theme='light', language='en', timezone='UTC'

-- ❌ This would still fail (NOT NULL, no DEFAULT):
-- INSERT INTO user_settings DEFAULT VALUES;
-- ERROR: null value in column "user_id" violates not-null constraint
```

---

## Combining Multiple Constraints

Columns often have multiple constraints working together:

```sql
CREATE TABLE employees (
    -- SERIAL + PRIMARY KEY: auto-increment, unique, not null
    employee_id   SERIAL PRIMARY KEY,

    -- NOT NULL + CHECK: required and must meet length requirement
    first_name    VARCHAR(50) NOT NULL CHECK (LENGTH(first_name) >= 2),

    -- UNIQUE + NOT NULL: required and must be unique across all rows
    email         VARCHAR(100) UNIQUE NOT NULL,

    -- NOT NULL + CHECK + DEFAULT: required, validated, with fallback
    salary        DECIMAL(10,2) NOT NULL CHECK (salary >= 30000) DEFAULT 30000,

    -- FK + NOT NULL: required relationship (total participation)
    department_id INT NOT NULL REFERENCES departments(department_id) ON DELETE RESTRICT,

    -- CHECK + DEFAULT: validated with a default
    status        VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'on_leave')),

    -- DEFAULT only: optional with automatic timestamp
    hire_date     DATE NOT NULL DEFAULT CURRENT_DATE,

    -- CHECK across columns (table-level)
    termination_date DATE,
    CHECK (termination_date IS NULL OR termination_date > hire_date)
);
```

---

## Named Constraints

By default, PostgreSQL generates constraint names automatically. Naming them explicitly makes error messages and maintenance much easier.

### Syntax

```sql
CREATE TABLE products (
    product_id   SERIAL,
    product_name VARCHAR(200) NOT NULL,
    price        DECIMAL(10,2) NOT NULL,
    quantity     INT NOT NULL,
    category_id  INT NOT NULL,

    -- Named constraints
    CONSTRAINT pk_products          PRIMARY KEY (product_id),
    CONSTRAINT uq_product_name     UNIQUE (product_name),
    CONSTRAINT chk_price_positive  CHECK (price > 0),
    CONSTRAINT chk_quantity_valid   CHECK (quantity >= 0),
    CONSTRAINT fk_product_category FOREIGN KEY (category_id)
                                   REFERENCES categories(category_id)
                                   ON DELETE RESTRICT
);
```

### Benefits of Named Constraints

| Benefit | Example |
|---------|---------|
| **Clearer error messages** | `violates constraint "chk_price_positive"` instead of `"products_price_check"` |
| **Easier to drop/modify** | `ALTER TABLE products DROP CONSTRAINT chk_price_positive;` |
| **Self-documenting** | Constraint name explains the rule |
| **Consistent naming** | Use a convention: `pk_`, `fk_`, `uq_`, `chk_` prefixes |

---

## Adding and Removing Constraints (ALTER TABLE)

### Adding Constraints to Existing Tables

```sql
-- Add NOT NULL
ALTER TABLE employees ALTER COLUMN phone SET NOT NULL;

-- Add DEFAULT
ALTER TABLE employees ALTER COLUMN status SET DEFAULT 'active';

-- Add CHECK
ALTER TABLE employees ADD CONSTRAINT chk_salary_range
    CHECK (salary BETWEEN 30000 AND 500000);

-- Add UNIQUE
ALTER TABLE employees ADD CONSTRAINT uq_employee_email
    UNIQUE (email);

-- Add FOREIGN KEY
ALTER TABLE employees ADD CONSTRAINT fk_emp_department
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
    ON DELETE SET NULL;

-- Add PRIMARY KEY (table must not already have one)
ALTER TABLE logs ADD CONSTRAINT pk_logs PRIMARY KEY (log_id);
```

### Removing Constraints

```sql
-- Drop a named constraint
ALTER TABLE employees DROP CONSTRAINT chk_salary_range;

-- Drop NOT NULL
ALTER TABLE employees ALTER COLUMN phone DROP NOT NULL;

-- Drop DEFAULT
ALTER TABLE employees ALTER COLUMN status DROP DEFAULT;

-- Drop PRIMARY KEY (drops the constraint and associated index)
ALTER TABLE logs DROP CONSTRAINT pk_logs;
```

### Modifying a Constraint

You cannot directly modify a constraint — you must **drop and re-create** it:

```sql
-- Change salary check from 30000-500000 to 25000-600000:
ALTER TABLE employees DROP CONSTRAINT chk_salary_range;
ALTER TABLE employees ADD CONSTRAINT chk_salary_range
    CHECK (salary BETWEEN 25000 AND 600000);
```

---

## Common Mistakes with Constraints

### 1. Forgetting NOT NULL on Foreign Keys

```sql
-- ❌ Bad: allows orders without a customer (NULL customer_id)
CREATE TABLE orders (
    order_id    SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id)  -- allows NULL!
);

-- ✅ Good: every order MUST have a customer
CREATE TABLE orders (
    order_id    SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id)
);
```

### 2. Using ON DELETE CASCADE Carelessly

```sql
-- ❌ Dangerous: deleting a customer deletes ALL their order history
CREATE TABLE orders (
    order_id    SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id) ON DELETE CASCADE
);

-- ✅ Safer: prevent deletion if orders exist
CREATE TABLE orders (
    order_id    SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id) ON DELETE RESTRICT
);
-- Consider soft-deletes instead: UPDATE customers SET is_active = FALSE
```

### 3. Not Handling SET NULL with NOT NULL

```sql
-- ❌ This will FAIL at runtime:
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    manager_id  INT NOT NULL REFERENCES managers(manager_id) ON DELETE SET NULL
    --              ^^^^^^^^                                       ^^^^^^^^
    --              NOT NULL conflicts with SET NULL!
);
-- When a manager is deleted, PostgreSQL tries to SET NULL,
-- but NOT NULL prevents it → ERROR!

-- ✅ Fix: remove NOT NULL if using SET NULL
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    manager_id  INT REFERENCES managers(manager_id) ON DELETE SET NULL
);
```

### 4. CHECK Constraints That Allow NULL

```sql
-- ⚠️ Surprising: CHECK constraints pass when the value is NULL
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    price      DECIMAL(10,2) CHECK (price > 0)
);

-- This SUCCEEDS! (NULL passes the CHECK because NULL > 0 is UNKNOWN, not FALSE)
INSERT INTO products (price) VALUES (NULL);

-- ✅ Fix: combine CHECK with NOT NULL
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    price      DECIMAL(10,2) NOT NULL CHECK (price > 0)
);
```

### 5. Overly Restrictive CHECK Constraints

```sql
-- ❌ Too restrictive: will reject valid future salaries
CHECK (salary BETWEEN 30000 AND 100000)

-- ✅ Better: allow growth with a reasonable upper bound
CHECK (salary BETWEEN 0 AND 10000000)

-- ❌ Too restrictive: email format evolves
CHECK (email ~ '^[a-z]+@[a-z]+\.[a-z]+$')

-- ✅ Better: basic format check only
CHECK (email LIKE '%@%.%')
```

### 6. Circular Foreign Key Dependencies

```sql
-- ❌ Problem: Table A references Table B, and Table B references Table A
-- Neither table can be created first!

-- ✅ Fix: create tables without FKs first, then add FKs via ALTER TABLE
CREATE TABLE table_a (id SERIAL PRIMARY KEY, b_id INT);
CREATE TABLE table_b (id SERIAL PRIMARY KEY, a_id INT);
ALTER TABLE table_a ADD FOREIGN KEY (b_id) REFERENCES table_b(id);
ALTER TABLE table_b ADD FOREIGN KEY (a_id) REFERENCES table_a(id);
```

---

## Quick Reference Table

| Constraint | Purpose | Allows NULL? | Multiple Per Table? | Creates Index? |
|------------|---------|:---:|:---:|:---:|
| `PRIMARY KEY` | Unique row identifier | ❌ | ❌ (exactly 1) | ✅ |
| `FOREIGN KEY` | Link to parent table | ✅ (unless NOT NULL) | ✅ | ❌ (manual recommended) |
| `UNIQUE` | No duplicate values | ✅ (one NULL) | ✅ | ✅ |
| `NOT NULL` | No missing values | ❌ (that's the point) | ✅ | ❌ |
| `CHECK` | Custom validation rule | ✅ (NULL passes) | ✅ | ❌ |
| `DEFAULT` | Auto-fill missing values | N/A | ✅ | ❌ |

---

## Key Takeaways

1. **PRIMARY KEY** = `UNIQUE` + `NOT NULL` — every table needs one
2. **FOREIGN KEY** creates relationships between tables and enforces referential integrity
3. **ON DELETE CASCADE** auto-deletes children; **RESTRICT** blocks deletion; **SET NULL** clears the reference
4. **UNIQUE** allows one `NULL`; use `UNIQUE NOT NULL` for truly no-duplicates columns
5. **NOT NULL** should be your default — only allow `NULL` when there's a genuine reason
6. **CHECK** validates data against custom rules — but remember that `NULL` passes CHECK
7. **DEFAULT** provides automatic values — combine with `NOT NULL` to guarantee a value always exists
8. **Name your constraints** — it makes error messages readable and maintenance easier
9. **Don't mix `NOT NULL` with `ON DELETE SET NULL`** — they conflict
10. **Think about referential actions early** — the right `ON DELETE` choice depends on your business rules
