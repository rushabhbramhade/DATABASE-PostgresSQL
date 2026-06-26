-- ============================================================
-- DROP.sql — Removing Database Objects in PostgreSQL
-- ============================================================
-- Covers: DROP TABLE, DROP DATABASE, DROP SCHEMA, DROP INDEX,
--         DROP SEQUENCE, DROP VIEW, IF EXISTS, CASCADE vs RESTRICT,
--         and DROP vs TRUNCATE comparison
-- ============================================================

-- ⚠️  WARNING: DROP statements permanently destroy objects and data.
--     There is NO UNDO. Always double-check before running DROP.
--     Consider taking a backup first:  pg_dump dbname > backup.sql


-- ************************************************************
-- 1. DROP TABLE — Basic Usage
-- ************************************************************

-- Drop a single table
DROP TABLE temp_import;

-- Expected: The table 'temp_import' and ALL its data are permanently removed.
-- This also removes:
--   • All rows in the table
--   • Indexes on the table
--   • Triggers on the table
--   • Rules on the table
--   • Sequences owned by SERIAL columns (if owned by the table)

-- ERROR scenario:
-- DROP TABLE non_existent_table;
-- → ERROR: table "non_existent_table" does not exist


-- ************************************************************
-- 2. DROP TABLE IF EXISTS
-- ************************************************************
-- Prevents errors when the table might not exist — essential for scripts

DROP TABLE IF EXISTS temp_import;

-- Expected: Drops the table if it exists; prints NOTICE if it doesn't:
--   NOTICE: table "temp_import" does not exist, skipping

-- Drop multiple tables at once
DROP TABLE IF EXISTS temp_staging, temp_errors, temp_log;

-- Expected: Each table is checked individually; missing ones are skipped


-- ************************************************************
-- 3. DROP TABLE CASCADE — Removing Dependent Objects
-- ************************************************************
-- CASCADE automatically removes objects that depend on the table

-- Setup: Let's assume we have this scenario
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    name        VARCHAR(50) NOT NULL
);

CREATE TABLE items (
    item_id     SERIAL PRIMARY KEY,
    name        VARCHAR(100),
    category_id INTEGER REFERENCES categories(category_id)
);

CREATE VIEW active_items AS
    SELECT i.item_id, i.name, c.name AS category
    FROM items i
    JOIN categories c ON i.category_id = c.category_id;

-- Try to drop categories (has dependent objects):
-- DROP TABLE categories;
-- → ERROR: cannot drop table "categories" because other objects depend on it
-- DETAIL: constraint on table "items" depends on table "categories"
--          view "active_items" depends on table "categories"

-- Solution: Use CASCADE
DROP TABLE categories CASCADE;

-- Expected:
-- • The 'categories' table is dropped
-- • The foreign key constraint on 'items.category_id' is removed
-- • The view 'active_items' is also dropped
-- NOTICE: drop cascades to constraint items_category_id_fkey on table items
-- NOTICE: drop cascades to view active_items

-- ⚠️  CASCADE can have far-reaching effects — always review dependent
--     objects before using it!


-- ************************************************************
-- 4. DROP TABLE RESTRICT (Default Behavior)
-- ************************************************************
-- RESTRICT refuses to drop if any dependent objects exist

DROP TABLE items RESTRICT;

-- This is the DEFAULT — same as writing just DROP TABLE items;
-- If 'items' has dependent views, FKs from other tables, etc., it will fail.
-- RESTRICT is safer — it forces you to handle dependencies explicitly.


-- ************************************************************
-- 5. DROP DATABASE
-- ************************************************************
-- NOTE: Cannot be run while connected to the target database.
--       Connect to 'postgres' or another database first.

-- Drop a database
DROP DATABASE company_db;

-- With IF EXISTS
DROP DATABASE IF EXISTS test_db;

-- With FORCE (PostgreSQL 13+): terminates active connections first
DROP DATABASE IF EXISTS old_project_db WITH (FORCE);

-- Expected: The entire database and ALL its contents are destroyed.
-- This includes ALL schemas, tables, views, functions, data — everything.
-- ⚠️  This is the most destructive command in PostgreSQL.

-- IMPORTANT: You cannot drop a database you are currently connected to.
-- ERROR: cannot drop the currently open database


-- ************************************************************
-- 6. DROP SCHEMA
-- ************************************************************

-- Drop an empty schema
DROP SCHEMA sales;

-- Expected: Works only if the schema contains no objects
-- ERROR if schema has tables: "cannot drop schema ... because other objects depend on it"

-- Drop a schema with all its contents
DROP SCHEMA inventory CASCADE;

-- Expected: Drops the schema AND all tables, views, functions inside it
-- ⚠️  Very destructive — everything in the schema is gone

-- Safe version
DROP SCHEMA IF EXISTS temp_schema CASCADE;


-- ************************************************************
-- 7. DROP INDEX
-- ************************************************************

-- First, create an index to drop
CREATE INDEX idx_employees_email ON employees(email);
CREATE INDEX idx_employees_hire_date ON employees(hire_date);
CREATE INDEX idx_orders_status ON orders(status);

-- Drop a specific index
DROP INDEX idx_employees_hire_date;

-- Expected: The index is removed; queries on hire_date may become slower
-- The underlying data is NOT affected

-- Drop with IF EXISTS
DROP INDEX IF EXISTS idx_employees_hire_date;

-- Drop concurrently (doesn't lock the table — good for production)
DROP INDEX CONCURRENTLY IF EXISTS idx_orders_status;

-- Note: DROP INDEX CONCURRENTLY cannot run inside a transaction block


-- ************************************************************
-- 8. DROP SEQUENCE
-- ************************************************************

DROP SEQUENCE IF EXISTS custom_order_seq;

-- Expected: The sequence is removed
-- WARNING: Any table column using this sequence via DEFAULT nextval(...)
--          will fail on future INSERTs

-- Drop with CASCADE (removes defaults referencing this sequence)
DROP SEQUENCE IF EXISTS custom_order_seq CASCADE;


-- ************************************************************
-- 9. DROP VIEW
-- ************************************************************

-- Assume we have a view
CREATE VIEW high_salary_employees AS
    SELECT employee_id, first_name, last_name, salary
    FROM employees
    WHERE salary > 80000;

-- Drop the view
DROP VIEW high_salary_employees;

-- Drop with IF EXISTS
DROP VIEW IF EXISTS high_salary_employees;

-- Views can also depend on other views — use CASCADE if needed
-- DROP VIEW parent_view CASCADE;


-- ************************************************************
-- 10. DROP vs TRUNCATE — When to Use Which
-- ************************************************************
/*
  ┌────────────────────┬─────────────────────────┬─────────────────────────┐
  │ Feature            │ DROP TABLE              │ TRUNCATE TABLE          │
  ├────────────────────┼─────────────────────────┼─────────────────────────┤
  │ What it removes    │ Table structure + data   │ Data only               │
  │ Table still exists │ ❌ No                    │ ✅ Yes                  │
  │ Columns/indexes    │ Removed                  │ Preserved               │
  │ Constraints        │ Removed                  │ Preserved               │
  │ Foreign keys       │ Removed / error          │ Error (unless CASCADE)  │
  │ Sequences (SERIAL) │ Removed (if owned)       │ Optional RESTART        │
  │ Can ROLLBACK?      │ ✅ Yes (in transaction)  │ ✅ Yes (in transaction) │
  │ Speed              │ Fast                     │ Very fast               │
  │ Use case           │ Remove table permanently │ Clear data, keep table  │
  └────────────────────┴─────────────────────────┴─────────────────────────┘

  Use DROP when:   You no longer need the table at all
  Use TRUNCATE when: You want to clear data but keep the table structure
*/


-- ************************************************************
-- 11. Safe Dropping Pattern — Check Before You Drop
-- ************************************************************

-- List all dependent objects before dropping
-- (Useful for production databases)

-- Find what depends on the 'employees' table:
SELECT
    dependent_ns.nspname  AS dependent_schema,
    dependent_view.relname AS dependent_view,
    source_ns.nspname     AS source_schema,
    source_table.relname  AS source_table
FROM pg_depend
JOIN pg_rewrite ON pg_depend.objid = pg_rewrite.oid
JOIN pg_class AS dependent_view ON pg_rewrite.ev_class = dependent_view.oid
JOIN pg_class AS source_table ON pg_depend.refobjid = source_table.oid
JOIN pg_namespace AS dependent_ns ON dependent_view.relnamespace = dependent_ns.oid
JOIN pg_namespace AS source_ns ON source_table.relnamespace = source_ns.oid
WHERE source_table.relname = 'employees'
  AND source_ns.nspname = 'public'
  AND dependent_view.relname != source_table.relname;

-- Always check dependencies before using CASCADE!


-- ************************************************************
-- 12. Cleanup Script Example
-- ************************************************************
-- A safe cleanup script for a development/test environment

-- Drop views first (they depend on tables)
DROP VIEW IF EXISTS high_salary_employees CASCADE;
DROP VIEW IF EXISTS active_items CASCADE;

-- Drop child tables (ones with foreign keys pointing to other tables)
DROP TABLE IF EXISTS order_details;
DROP TABLE IF EXISTS orders;

-- Drop parent tables
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;

-- Drop schemas
DROP SCHEMA IF EXISTS hr CASCADE;
DROP SCHEMA IF EXISTS sales CASCADE;
DROP SCHEMA IF EXISTS inventory CASCADE;

-- Drop sequences
DROP SEQUENCE IF EXISTS employee_id_seq;
DROP SEQUENCE IF EXISTS custom_order_seq;

-- Expected: Clean removal in the correct dependency order


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
/*
  1. DROP is permanent — there is NO UNDO outside of a transaction.
  2. Always use IF EXISTS in scripts to prevent errors on missing objects.
  3. CASCADE removes dependent objects — powerful but dangerous.
  4. RESTRICT (default) prevents drops when dependencies exist — safer.
  5. DROP DATABASE cannot be run while connected to that database.
  6. DROP INDEX CONCURRENTLY avoids locking tables in production.
  7. Use DROP to remove objects entirely; use TRUNCATE to clear data only.
  8. Drop in dependency order: views → child tables → parent tables → schemas.
  9. Check pg_depend to find dependencies before using CASCADE.
 10. Always back up before dropping anything in production!
*/
