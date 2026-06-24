-- CTE examples
WITH high_salary_employees AS (SELECT * FROM employees WHERE salary > 100000)
SELECT * FROM high_salary_employees;
