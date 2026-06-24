-- Social media schema
CREATE TABLE users (id SERIAL PRIMARY KEY);
CREATE TABLE posts (id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id));
