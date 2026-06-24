-- SELF JOIN examples
SELECT a.first_name, b.first_name FROM employees a JOIN employees b ON a.manager_id = b.id;
