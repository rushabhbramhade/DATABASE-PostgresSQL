-- Nested query examples
SELECT * FROM employees WHERE department_id IN (SELECT id FROM departments WHERE name = 'Engineering');
