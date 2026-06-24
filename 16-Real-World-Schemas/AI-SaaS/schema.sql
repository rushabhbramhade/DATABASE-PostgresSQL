-- AI SaaS schema
CREATE TABLE users (id SERIAL PRIMARY KEY);
CREATE TABLE api_keys (id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id));
