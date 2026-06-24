-- Ecommerce schema
CREATE TABLE customers (id SERIAL PRIMARY KEY);
CREATE TABLE orders (id SERIAL PRIMARY KEY, customer_id INT REFERENCES customers(id));
