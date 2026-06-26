-- ============================================================
-- CREATE.sql — Schema Creation in PostgreSQL
-- ============================================================
-- Covers: CREATE DATABASE, CREATE SCHEMA, CREATE SEQUENCE,
--         CREATE TABLE with data types, constraints, and defaults
-- ============================================================


-- ************************************************************
-- 1. CREATE DATABASE
-- ************************************************************
-- NOTE: CREATE DATABASE cannot run inside a transaction block.
--       Execute this from psql or a separate connection.

CREATE DATABASE company_db;

-- With additional options
CREATE DATABASE company_db
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0
    CONNECTION LIMIT = 100;

-- Expected: Creates a new database named 'company_db'
-- Verify:   \l   (in psql to list all databases)


-- ************************************************************
-- 2. CREATE SCHEMA
-- ************************************************************
-- Schemas help organize tables into logical groups within a database

CREATE SCHEMA hr;
CREATE SCHEMA sales;
CREATE SCHEMA inventory;

-- Create schema owned by a specific role
CREATE SCHEMA finance AUTHORIZATION postgres;

-- Expected: Creates namespaces — tables can be referenced as hr.employees, sales.orders, etc.
-- Verify:   \dn   (in psql to list schemas)


-- ************************************************************
-- 3. CREATE SEQUENCE
-- ************************************************************
-- Sequences generate unique numeric values (used for custom ID generation)

CREATE SEQUENCE employee_id_seq
    START WITH 1000
    INCREMENT BY 1
    MINVALUE 1000
    MAXVALUE 9999999
    NO CYCLE;

-- Usage: SELECT nextval('employee_id_seq');  →  1000
-- Usage: SELECT nextval('employee_id_seq');  →  1001
-- Usage: SELECT currval('employee_id_seq'); →  1001

-- CYCLE vs NO CYCLE:
--   CYCLE    → wraps around to MINVALUE after reaching MAXVALUE
--   NO CYCLE → raises an error after reaching MAXVALUE (safer for IDs)


-- ************************************************************
-- 4. COMMON PostgreSQL DATA TYPES
-- ************************************************************
/*
  ┌──────────────┬──────────────────────────────────────────────┐
  │ Data Type    │ Description                                  │
  ├──────────────┼──────────────────────────────────────────────┤
  │ SERIAL       │ Auto-incrementing 4-byte integer (1 to 2B)   │
  │ BIGSERIAL    │ Auto-incrementing 8-byte integer             │
  │ INTEGER      │ 4-byte signed integer (-2B to +2B)           │
  │ BIGINT       │ 8-byte signed integer                        │
  │ SMALLINT     │ 2-byte signed integer (-32768 to +32767)     │
  │ NUMERIC(p,s) │ Exact decimal with precision p, scale s      │
  │ REAL         │ 4-byte floating point                        │
  │ BOOLEAN      │ TRUE / FALSE / NULL                          │
  │ VARCHAR(n)   │ Variable-length string up to n characters    │
  │ CHAR(n)      │ Fixed-length string, padded with spaces      │
  │ TEXT         │ Unlimited-length string                       │
  │ DATE         │ Calendar date (YYYY-MM-DD)                   │
  │ TIME         │ Time of day (HH:MI:SS)                       │
  │ TIMESTAMP    │ Date + Time (no timezone)                     │
  │ TIMESTAMPTZ  │ Date + Time (with timezone)                  │
  │ UUID         │ Universally unique identifier                 │
  │ JSON / JSONB │ JSON data (JSONB is binary, faster queries)  │
  └──────────────┴──────────────────────────────────────────────┘
*/


-- ************************************************************
-- 5. CREATE TABLE — Basic Example
-- ************************************************************

CREATE TABLE departments (
    department_id   SERIAL PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    location        VARCHAR(100),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Expected: Creates a table with 4 columns
-- SERIAL automatically creates a sequence for department_id
-- department_id: 1, 2, 3, ... (auto-generated)


-- ************************************************************
-- 6. CREATE TABLE — With Various Data Types and Inline Constraints
-- ************************************************************

CREATE TABLE employees (
    employee_id     SERIAL PRIMARY KEY,                         -- Auto-increment PK
    first_name      VARCHAR(50) NOT NULL,                       -- Required string
    last_name       VARCHAR(50) NOT NULL,                       -- Required string
    email           VARCHAR(100) NOT NULL UNIQUE,               -- Must be unique
    phone           VARCHAR(20),                                -- Optional
    hire_date       DATE NOT NULL DEFAULT CURRENT_DATE,         -- Defaults to today
    salary          NUMERIC(10, 2) CHECK (salary > 0),         -- Must be positive
    is_active       BOOLEAN DEFAULT TRUE,                       -- Defaults to TRUE
    department_id   INTEGER REFERENCES departments(department_id), -- FK inline
    bio             TEXT,                                        -- Unlimited text
    created_at      TIMESTAMPTZ DEFAULT NOW()                   -- Timestamp with TZ
);

-- Expected:
-- employee_id auto-increments: 1, 2, 3, ...
-- email must be unique across all rows
-- salary must be positive (CHECK constraint)
-- department_id references the departments table


-- ************************************************************
-- 7. CREATE TABLE — With Table-Level Constraints
-- ************************************************************
-- Table-level constraints are defined after all columns.
-- Use this style for multi-column constraints or named constraints.

CREATE TABLE products (
    product_id      SERIAL,
    product_name    VARCHAR(150) NOT NULL,
    category        VARCHAR(50) NOT NULL,
    sku             VARCHAR(30) NOT NULL,
    price           NUMERIC(10, 2) NOT NULL,
    cost            NUMERIC(10, 2),
    stock_quantity  INTEGER DEFAULT 0,
    weight_kg       REAL,
    is_available    BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Table-level constraints (named for easy reference)
    CONSTRAINT pk_products            PRIMARY KEY (product_id),
    CONSTRAINT uq_products_sku        UNIQUE (sku),
    CONSTRAINT chk_products_price     CHECK (price >= 0),
    CONSTRAINT chk_products_cost      CHECK (cost >= 0),
    CONSTRAINT chk_price_above_cost   CHECK (price >= cost)
);

-- Expected:
-- Named constraints make error messages clearer:
--   ERROR: new row violates check constraint "chk_products_price"
-- Multi-column CHECK: price must always be >= cost


-- ************************************************************
-- 8. CREATE TABLE — With Foreign Keys (Table-Level)
-- ************************************************************

CREATE TABLE orders (
    order_id        SERIAL PRIMARY KEY,
    order_date      TIMESTAMP NOT NULL DEFAULT NOW(),
    customer_name   VARCHAR(100) NOT NULL,
    customer_email  VARCHAR(100),
    employee_id     INTEGER,
    total_amount    NUMERIC(12, 2) DEFAULT 0.00,
    status          VARCHAR(20) DEFAULT 'pending'
                    CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
    notes           TEXT,

    CONSTRAINT fk_orders_employee
        FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- Foreign Key Actions:
--   ON DELETE SET NULL   → if the employee is deleted, set employee_id to NULL
--   ON DELETE CASCADE    → if the parent row is deleted, delete child rows too
--   ON DELETE RESTRICT   → prevent deletion if child rows exist (default behavior)
--   ON UPDATE CASCADE    → if the parent key changes, update child rows too


-- ************************************************************
-- 9. CREATE TABLE — Order Details (Composite Primary Key)
-- ************************************************************

CREATE TABLE order_details (
    order_id        INTEGER NOT NULL,
    product_id      INTEGER NOT NULL,
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC(10, 2) NOT NULL,
    discount        NUMERIC(4, 2) DEFAULT 0.00 CHECK (discount >= 0 AND discount <= 100),

    -- Composite primary key: combination of order_id + product_id must be unique
    PRIMARY KEY (order_id, product_id),

    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT
);

-- Expected: Each order can have multiple products, but no duplicate product per order


-- ************************************************************
-- 10. CREATE TABLE IF NOT EXISTS
-- ************************************************************
-- Prevents errors if the table already exists — very useful in scripts

CREATE TABLE IF NOT EXISTS audit_log (
    log_id          BIGSERIAL PRIMARY KEY,
    table_name      VARCHAR(50) NOT NULL,
    operation       VARCHAR(10) NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    old_data        JSONB,
    new_data        JSONB,
    changed_by      VARCHAR(50),
    changed_at      TIMESTAMPTZ DEFAULT NOW()
);

-- If the table already exists: no error, no changes — silently skipped
-- If the table does not exist: creates it normally
-- This is safe to run multiple times in migration scripts


-- ************************************************************
-- 11. CREATE TABLE — With DEFAULT Values
-- ************************************************************

CREATE TABLE students (
    student_id      SERIAL PRIMARY KEY,
    first_name      VARCHAR(50) NOT NULL,
    last_name       VARCHAR(50) NOT NULL,
    enrollment_date DATE DEFAULT CURRENT_DATE,
    gpa             NUMERIC(3, 2) DEFAULT 0.00,
    credits_earned  INTEGER DEFAULT 0,
    status          VARCHAR(20) DEFAULT 'enrolled',
    is_international BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- When inserting without specifying these columns, defaults kick in:
-- INSERT INTO students (first_name, last_name) VALUES ('Aarav', 'Sharma');
--
-- Result:
-- student_id: 1 (auto)
-- enrollment_date: 2026-06-26 (today)
-- gpa: 0.00
-- credits_earned: 0
-- status: 'enrolled'
-- is_international: FALSE


-- ************************************************************
-- 12. CREATE TABLE — In a Specific Schema
-- ************************************************************

CREATE TABLE hr.employee_reviews (
    review_id       SERIAL PRIMARY KEY,
    employee_id     INTEGER NOT NULL,
    review_date     DATE NOT NULL DEFAULT CURRENT_DATE,
    reviewer_name   VARCHAR(100),
    rating          SMALLINT CHECK (rating BETWEEN 1 AND 5),
    comments        TEXT
);

-- This table lives in the 'hr' schema
-- Access it as: SELECT * FROM hr.employee_reviews;


-- ************************************************************
-- 13. CREATE TABLE — Using a Custom Sequence
-- ************************************************************

CREATE SEQUENCE custom_order_seq START WITH 5000 INCREMENT BY 1;

CREATE TABLE special_orders (
    order_id        INTEGER PRIMARY KEY DEFAULT nextval('custom_order_seq'),
    description     TEXT NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- order_id will start at 5000 instead of 1
-- INSERT INTO special_orders (description) VALUES ('Custom widget');
-- → order_id = 5000


-- ************************************************************
-- 14. CREATE TABLE — With UUID Primary Key
-- ************************************************************

-- PostgreSQL has built-in gen_random_uuid() (v13+)
CREATE TABLE sessions (
    session_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_email      VARCHAR(100) NOT NULL,
    token           TEXT NOT NULL,
    expires_at      TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- session_id auto-generates a UUID like: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
-- UUIDs are great for distributed systems where sequential IDs conflict


-- ************************************************************
-- 15. CREATE TABLE — Temporary Table
-- ************************************************************

-- Temporary tables exist only for the duration of the session/transaction
CREATE TEMPORARY TABLE temp_import (
    row_num     SERIAL,
    raw_data    TEXT,
    imported_at TIMESTAMP DEFAULT NOW()
);

-- Useful for staging data during ETL or bulk imports
-- Automatically dropped when the session ends


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
/*
  1. SERIAL / BIGSERIAL auto-generate IDs — no need to insert values manually.
  2. Use VARCHAR(n) for bounded strings, TEXT for unlimited text.
  3. NUMERIC(p, s) is exact — use it for money/prices, not REAL/FLOAT.
  4. Name your constraints (CONSTRAINT chk_...) for clearer error messages.
  5. Use IF NOT EXISTS for safe, repeatable migration scripts.
  6. DEFAULT values reduce boilerplate in INSERT statements.
  7. Foreign keys enforce referential integrity — always specify ON DELETE behavior.
  8. Schemas (hr, sales) organize tables like folders organize files.
  9. TIMESTAMPTZ is preferred over TIMESTAMP for timezone-aware applications.
 10. Temporary tables are perfect for staging data — they auto-cleanup.
*/
