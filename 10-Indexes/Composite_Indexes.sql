-- Composite index examples
CREATE INDEX idx_employees_dept_salary ON employees(department_id, salary);
