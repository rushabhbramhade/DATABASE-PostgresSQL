# 🛠️ PostgreSQL Commands Reference

> psql shortcuts, admin SQL, backup/restore, configuration, and monitoring — all in one place.

---

## 📑 Table of Contents

- [psql Connection & Startup](#psql-connection--startup)
- [psql Meta-Commands (Backslash Commands)](#psql-meta-commands-backslash-commands)
- [User & Role Management](#user--role-management)
- [Database & Schema Management](#database--schema-management)
- [Permissions (GRANT / REVOKE)](#permissions-grant--revoke)
- [Backup & Restore](#backup--restore)
- [Configuration (postgresql.conf)](#configuration-postgresqlconf)
- [Monitoring & Diagnostics](#monitoring--diagnostics)
- [Maintenance Commands](#maintenance-commands)

---

## psql Connection & Startup

```bash
# Connect to a local database
psql -U postgres                              # connect as user 'postgres'
psql -U myuser -d mydb                        # connect to specific database
psql -h localhost -p 5432 -U myuser -d mydb   # full connection string

# Connect with a URI
psql "postgresql://user:password@host:5432/dbname"
psql "postgresql://user:password@host:5432/dbname?sslmode=require"

# Execute a SQL file
psql -U postgres -d mydb -f script.sql

# Execute a single command
psql -U postgres -d mydb -c "SELECT version();"

# Connect and set output format
psql -U postgres -d mydb --csv                # CSV output
psql -U postgres -d mydb --html               # HTML output

# Set password via environment variable (avoid prompts)
export PGPASSWORD='mypassword'                # Linux/Mac
$env:PGPASSWORD='mypassword'                  # PowerShell
set PGPASSWORD=mypassword                     # Windows CMD
```

---

## psql Meta-Commands (Backslash Commands)

### General

| Command           | Description                                    |
|-------------------|------------------------------------------------|
| `\?`              | Help for psql backslash commands               |
| `\h`              | Help for SQL commands                          |
| `\h CREATE TABLE` | Help for a specific SQL command                |
| `\q`              | Quit psql                                      |
| `\! clear`        | Execute shell command (clear screen)           |
| `\timing`         | Toggle query execution timing on/off           |
| `\x`              | Toggle expanded (vertical) display             |
| `\set AUTOCOMMIT off` | Disable autocommit                        |

### Connection & Database

| Command             | Description                                  |
|---------------------|----------------------------------------------|
| `\c dbname`         | Connect to a different database              |
| `\c dbname user`    | Connect as a different user                  |
| `\conninfo`         | Show current connection info                 |
| `\l` or `\l+`       | List all databases (+ shows size/tablespace)|
| `\password username` | Change a user's password securely           |

### Schema Inspection

| Command             | Description                                  |
|---------------------|----------------------------------------------|
| `\dt`               | List tables in current schema                |
| `\dt+`              | List tables with size and description        |
| `\dt schema.*`      | List tables in a specific schema             |
| `\d tablename`      | Describe table (columns, types, constraints) |
| `\d+ tablename`     | Detailed table info (storage, stats, desc)   |
| `\di`               | List indexes                                 |
| `\di+ tablename`    | Show indexes for a specific table            |
| `\dv`               | List views                                   |
| `\dm`               | List materialized views                      |
| `\ds`               | List sequences                               |
| `\df`               | List functions                               |
| `\df+ funcname`     | Show function source code                    |
| `\dn`               | List schemas                                 |
| `\du` or `\dg`      | List roles/users                             |
| `\dp` or `\z`       | Show access privileges                       |
| `\dx`               | List installed extensions                    |
| `\dT`               | List data types                              |
| `\dT+`              | List data types with details                 |
| `\det`              | List foreign tables                          |
| `\des`              | List foreign servers                         |

### Input/Output

| Command                          | Description                         |
|----------------------------------|-------------------------------------|
| `\i filename.sql`                | Execute SQL from file               |
| `\o output.txt`                  | Send query output to file           |
| `\o`                             | Reset output to terminal            |
| `\copy table TO 'file.csv' CSV HEADER` | Export table to CSV            |
| `\copy table FROM 'file.csv' CSV HEADER` | Import CSV into table        |
| `\echo 'message'`               | Print message to output             |
| `\pset format csv`              | Set output format (csv, html, etc.) |
| `\pset border 2`                | Set table border style              |

### Search & Edit

| Command             | Description                                  |
|---------------------|----------------------------------------------|
| `\e`                | Open last query in editor ($EDITOR)          |
| `\ef funcname`      | Edit function in editor                      |
| `\g`                | Re-execute last query                        |
| `\gx`               | Re-execute last query with expanded output   |
| `\s`                | Show command history                         |
| `\s filename`       | Save command history to file                 |

---

## User & Role Management

```sql
-- Create user/role
CREATE USER appuser WITH PASSWORD 'securepass123';
CREATE ROLE readonly_role NOLOGIN;                      -- role (cannot login)
CREATE ROLE admin WITH LOGIN SUPERUSER PASSWORD 'adminpass';

-- Alter user
ALTER USER appuser WITH PASSWORD 'newpassword';
ALTER USER appuser CREATEDB;                            -- grant create database
ALTER USER appuser VALID UNTIL '2026-01-01';            -- set expiration
ALTER USER appuser CONNECTION LIMIT 10;                 -- max connections
ALTER USER appuser SET search_path = myschema, public;  -- set default schema

-- Drop user
DROP USER IF EXISTS appuser;
REASSIGN OWNED BY appuser TO postgres;                  -- before dropping
DROP OWNED BY appuser;                                  -- drop all objects

-- Role membership (group roles)
GRANT readonly_role TO appuser;                         -- add user to role
REVOKE readonly_role FROM appuser;                      -- remove from role

-- List users and roles
SELECT usename, usesuper, usecreatedb FROM pg_user;
SELECT rolname, rolsuper, rolcanlogin FROM pg_roles;
```

---

## Database & Schema Management

```sql
-- Databases
CREATE DATABASE mydb OWNER appuser ENCODING 'UTF8';
CREATE DATABASE mydb TEMPLATE template0 LC_COLLATE 'en_US.UTF-8';
ALTER DATABASE mydb OWNER TO newowner;
ALTER DATABASE mydb SET timezone TO 'Asia/Kolkata';
DROP DATABASE IF EXISTS mydb;

-- Schemas
CREATE SCHEMA myschema;
CREATE SCHEMA IF NOT EXISTS myschema AUTHORIZATION appuser;
ALTER SCHEMA myschema OWNER TO appuser;
ALTER SCHEMA myschema RENAME TO new_schema;
DROP SCHEMA myschema CASCADE;                           -- drop with all objects
SET search_path TO myschema, public;                    -- set schema search path

-- Show current schema
SHOW search_path;
SELECT current_schema();
```

---

## Permissions (GRANT / REVOKE)

```sql
-- Database-level
GRANT CONNECT ON DATABASE mydb TO appuser;
GRANT ALL PRIVILEGES ON DATABASE mydb TO appuser;
REVOKE CONNECT ON DATABASE mydb FROM appuser;

-- Schema-level
GRANT USAGE ON SCHEMA myschema TO appuser;
GRANT CREATE ON SCHEMA myschema TO appuser;

-- Table-level
GRANT SELECT ON TABLE employees TO appuser;
GRANT SELECT, INSERT, UPDATE ON TABLE employees TO appuser;
GRANT ALL PRIVILEGES ON TABLE employees TO appuser;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_role;
REVOKE DELETE ON TABLE employees FROM appuser;

-- Column-level
GRANT SELECT (name, email) ON TABLE employees TO appuser;
GRANT UPDATE (email) ON TABLE employees TO appuser;

-- Sequence-level
GRANT USAGE ON SEQUENCE employees_id_seq TO appuser;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO appuser;

-- Default privileges (for future tables)
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO readonly_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE ON SEQUENCES TO appuser;

-- Row-Level Security
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
CREATE POLICY emp_policy ON employees
    FOR SELECT USING (department = current_setting('app.department'));
```

---

## Backup & Restore

### pg_dump (Single Database Backup)

```bash
# Plain SQL dump (human-readable)
pg_dump -U postgres mydb > mydb_backup.sql
pg_dump -U postgres -d mydb -f backup.sql

# Custom format (compressed, most flexible for restore)
pg_dump -U postgres -Fc mydb > mydb_backup.dump
pg_dump -U postgres -Fc -d mydb -f mydb_backup.dump

# Directory format (parallel backup)
pg_dump -U postgres -Fd -j 4 mydb -f backup_dir/

# Dump specific tables
pg_dump -U postgres -t employees -t departments mydb > tables_backup.sql

# Dump schema only (no data)
pg_dump -U postgres --schema-only mydb > schema.sql

# Dump data only (no schema)
pg_dump -U postgres --data-only mydb > data.sql

# Dump with compression
pg_dump -U postgres -Z 9 mydb > mydb_backup.sql.gz

# Exclude specific tables
pg_dump -U postgres -T logs -T temp_data mydb > backup.sql
```

### pg_restore (Restore from Custom/Directory Format)

```bash
# Restore from custom format
pg_restore -U postgres -d mydb mydb_backup.dump

# Restore with create database
pg_restore -U postgres -C -d postgres mydb_backup.dump

# Restore specific table
pg_restore -U postgres -t employees -d mydb mydb_backup.dump

# Restore schema only
pg_restore -U postgres --schema-only -d mydb mydb_backup.dump

# Parallel restore (faster)
pg_restore -U postgres -j 4 -d mydb backup_dir/

# Clean (drop objects before recreating)
pg_restore -U postgres --clean -d mydb mydb_backup.dump

# List contents of a dump file
pg_restore -l mydb_backup.dump
```

### pg_dumpall (Full Cluster Backup)

```bash
# Dump all databases + globals (roles, tablespaces)
pg_dumpall -U postgres > full_backup.sql

# Dump only global objects (users, roles)
pg_dumpall -U postgres --globals-only > globals.sql

# Restore full backup
psql -U postgres -f full_backup.sql
```

### Restore from Plain SQL

```bash
# Restore from plain SQL dump
psql -U postgres -d mydb -f mydb_backup.sql

# Restore into a new database
createdb -U postgres newdb
psql -U postgres -d newdb -f mydb_backup.sql
```

---

## Configuration (postgresql.conf)

### Finding Config File

```sql
SHOW config_file;                     -- path to postgresql.conf
SHOW data_directory;                  -- data directory path
SHOW hba_file;                        -- path to pg_hba.conf
```

### Key Settings

| Setting                         | Default     | Description                            |
|---------------------------------|-------------|----------------------------------------|
| `listen_addresses`              | `localhost` | IP addresses to listen on (`'*'` = all)|
| `port`                          | `5432`      | Server port                            |
| `max_connections`               | `100`       | Max concurrent connections             |
| `shared_buffers`                | `128MB`     | Memory for caching (set to 25% of RAM) |
| `effective_cache_size`          | `4GB`       | Planner's memory estimate (50-75% RAM) |
| `work_mem`                      | `4MB`       | Memory per sort/hash operation         |
| `maintenance_work_mem`          | `64MB`      | Memory for VACUUM, CREATE INDEX        |
| `wal_level`                     | `replica`   | WAL detail (`minimal`, `replica`, `logical`) |
| `max_wal_size`                  | `1GB`       | Max WAL size before checkpoint         |
| `checkpoint_completion_target`  | `0.9`       | Spread checkpoint I/O (0.0 to 1.0)    |
| `random_page_cost`              | `4.0`       | Cost of non-sequential disk page fetch |
| `effective_io_concurrency`      | `1`         | Concurrent I/O operations (SSD: 200)   |
| `log_min_duration_statement`    | `-1`        | Log queries slower than N ms (0 = all) |
| `log_statement`                 | `none`      | Log level: `none`, `ddl`, `mod`, `all` |
| `autovacuum`                    | `on`        | Enable automatic vacuuming             |
| `timezone`                      | `UTC`       | Server timezone                        |

### Checking & Reloading Settings

```sql
-- Check a setting
SHOW shared_buffers;
SHOW max_connections;
SELECT name, setting, unit, context FROM pg_settings WHERE name = 'shared_buffers';

-- View all non-default settings
SELECT name, setting, unit, source FROM pg_settings WHERE source != 'default';

-- Reload config without restart (for most settings)
SELECT pg_reload_conf();
-- Or from command line: pg_ctl reload -D /path/to/data

-- Settings requiring restart
SELECT name, setting, pending_restart FROM pg_settings WHERE pending_restart = true;
```

---

## Monitoring & Diagnostics

### Active Connections & Queries

```sql
-- Current active connections
SELECT pid, usename, datname, client_addr, state, query_start, query
FROM pg_stat_activity
WHERE state = 'active'
ORDER BY query_start;

-- Long-running queries (> 5 minutes)
SELECT pid, usename, datname,
    NOW() - query_start AS duration,
    LEFT(query, 100) AS query_snippet
FROM pg_stat_activity
WHERE state = 'active' AND NOW() - query_start > INTERVAL '5 minutes'
ORDER BY duration DESC;

-- Connection count per database
SELECT datname, COUNT(*) AS connections
FROM pg_stat_activity
GROUP BY datname
ORDER BY connections DESC;

-- Connection count per state
SELECT state, COUNT(*) FROM pg_stat_activity GROUP BY state;

-- Kill a specific query
SELECT pg_cancel_backend(pid);        -- graceful cancel
SELECT pg_terminate_backend(pid);     -- force terminate
```

### Table Statistics

```sql
-- Table sizes
SELECT tablename,
    pg_size_pretty(pg_total_relation_size(schemaname || '.' || tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(schemaname || '.' || tablename)) AS table_size,
    pg_size_pretty(pg_indexes_size(schemaname || '.' || tablename)) AS index_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname || '.' || tablename) DESC;

-- Database size
SELECT pg_size_pretty(pg_database_size('mydb'));

-- Row counts and dead tuples
SELECT relname, n_live_tup, n_dead_tup,
    last_vacuum, last_autovacuum, last_analyze
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;
```

### Index Usage

```sql
-- Index usage statistics
SELECT schemaname, tablename, indexname,
    idx_scan AS times_used,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- Unused indexes (candidates for removal)
SELECT schemaname, tablename, indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;

-- Missing indexes (sequential scans on large tables)
SELECT relname, seq_scan, seq_tup_read,
    idx_scan, idx_tup_fetch
FROM pg_stat_user_tables
WHERE seq_scan > 100 AND idx_scan = 0
ORDER BY seq_tup_read DESC;
```

### Lock Monitoring

```sql
-- Current locks
SELECT pl.pid, pa.usename, pl.locktype, pl.mode,
    pl.granted, pa.query
FROM pg_locks pl
JOIN pg_stat_activity pa ON pl.pid = pa.pid
WHERE NOT pl.granted;

-- Blocked queries (waiting for locks)
SELECT blocked_locks.pid AS blocked_pid,
    blocking_locks.pid AS blocking_pid,
    blocked_activity.query AS blocked_query,
    blocking_activity.query AS blocking_query
FROM pg_locks blocked_locks
JOIN pg_locks blocking_locks
    ON blocked_locks.locktype = blocking_locks.locktype
    AND blocked_locks.relation = blocking_locks.relation
    AND blocked_locks.pid != blocking_locks.pid
JOIN pg_stat_activity blocked_activity ON blocked_locks.pid = blocked_activity.pid
JOIN pg_stat_activity blocking_activity ON blocking_locks.pid = blocking_activity.pid
WHERE NOT blocked_locks.granted;
```

### Replication Monitoring

```sql
-- Check replication status (on primary)
SELECT client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn,
    pg_wal_lsn_diff(sent_lsn, replay_lsn) AS replication_lag_bytes
FROM pg_stat_replication;

-- Check if server is primary or replica
SELECT pg_is_in_recovery();   -- false = primary, true = replica
```

---

## Maintenance Commands

```sql
-- Vacuum
VACUUM;                                   -- all tables, reclaim dead tuples
VACUUM VERBOSE employees;                 -- with details
VACUUM ANALYZE employees;                 -- vacuum + update statistics
VACUUM FULL employees;                    -- reclaim disk space (locks table!)

-- Analyze (update planner statistics)
ANALYZE;                                  -- all tables
ANALYZE employees;                        -- specific table
ANALYZE employees(salary, department);    -- specific columns

-- Reindex
REINDEX TABLE employees;                  -- rebuild all indexes on table
REINDEX INDEX idx_emp_name;               -- rebuild specific index
REINDEX DATABASE mydb;                    -- rebuild all indexes in database

-- Cluster (physically reorder table by index)
CLUSTER employees USING idx_emp_name;     -- reorder table by index
CLUSTER;                                  -- re-cluster all previously clustered tables

-- Check table health
SELECT relname, last_vacuum, last_autovacuum, last_analyze, last_autoanalyze
FROM pg_stat_user_tables
ORDER BY last_analyze NULLS FIRST;
```

---

*Keep this reference handy for day-to-day PostgreSQL administration! 🛠️*
