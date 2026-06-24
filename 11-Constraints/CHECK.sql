-- CHECK constraint examples
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    age INT CHECK (age >= 18)
);
