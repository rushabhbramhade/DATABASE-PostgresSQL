-- Window Functions examples
SELECT first_name, salary, ROW_NUMBER() OVER (ORDER BY salary DESC) FROM employees;
