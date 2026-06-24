-- Materialized Views examples
CREATE MATERIALIZED VIEW active_employees AS SELECT * FROM employees WHERE active = true;
