-- ============================================================
-- Topic:  Pattern Matching in PostgreSQL (LIKE, ILIKE, SIMILAR TO, ~)
-- File:   LIKE.sql
-- ============================================================
-- Sample table used throughout this file:
--
-- employees table:
-- | employee_id | first_name | last_name | department  | salary | hire_date  | email                    |
-- |-------------|------------|-----------|-------------|--------|------------|--------------------------|
-- | 1           | Amit       | Sharma    | Engineering | 75000  | 2021-03-15 | amit.sharma@mail.com     |
-- | 2           | Priya      | Verma     | Marketing   | 55000  | 2022-07-01 | priya.verma@mail.com     |
-- | 3           | Rahul      | Gupta     | Engineering | 82000  | 2020-01-10 | rahul.gupta@mail.com     |
-- | 4           | Sneha      | Patel     | HR          | 48000  | 2023-02-20 | sneha.patel@mail.com     |
-- | 5           | Vikram     | Singh     | Marketing   | 60000  | 2021-11-05 | vikram.singh@mail.com    |
-- | 6           | Ananya     | Das       | Engineering | 70000  | 2022-09-12 | ananya.das@mail.com      |
-- | 7           | Karan      | Mehta     | Sales       | 52000  | 2023-06-01 | karan.mehta@mail.com     |
-- ============================================================


-- ************************************************************
-- 1. LIKE with % — matches zero or more characters
-- ************************************************************

-- First names that START with 'A'
SELECT first_name, last_name
FROM employees
WHERE first_name LIKE 'A%';

-- Expected Output:
-- | first_name | last_name |
-- |------------|-----------|
-- | Amit       | Sharma    |
-- | Ananya     | Das       |

-- Last names that END with 'a'
SELECT first_name, last_name
FROM employees
WHERE last_name LIKE '%a';

-- Expected Output:
-- | first_name | last_name |
-- |------------|-----------|
-- | Amit       | Sharma    |
-- | Priya      | Verma     |
-- | Rahul      | Gupta     |
-- | Sneha      | Patel     |  ← 'Patel' does NOT end with 'a', so excluded
-- | Karan      | Mehta     |
-- Actual Output:
-- | first_name | last_name |
-- |------------|-----------|
-- | Amit       | Sharma    |
-- | Priya      | Verma     |
-- | Rahul      | Gupta     |
-- | Karan      | Mehta     |

-- Last names that CONTAIN 'ha' anywhere
SELECT first_name, last_name
FROM employees
WHERE last_name LIKE '%ha%';

-- Expected Output:
-- | first_name | last_name |
-- |------------|-----------|
-- | Amit       | Sharma    |
-- | Karan      | Mehta     |  ← 'Mehta' does NOT contain 'ha', excluded
-- Actual:
-- | first_name | last_name |
-- |------------|-----------|
-- | Amit       | Sharma    |


-- ************************************************************
-- 2. LIKE with _ — matches exactly ONE character
-- ************************************************************

-- First names that are exactly 5 characters long
SELECT first_name
FROM employees
WHERE first_name LIKE '_____';

-- Expected Output:
-- | first_name |
-- |------------|
-- | Priya      |
-- | Rahul      |
-- | Sneha      |
-- | Karan      |

-- First names starting with 'A' followed by exactly 3 characters (4-letter names)
SELECT first_name
FROM employees
WHERE first_name LIKE 'A___';

-- Expected Output:
-- | first_name |
-- |------------|
-- | Amit       |


-- ************************************************************
-- 3. Combining % and _
-- ************************************************************

-- Last names where the second character is 'a'
SELECT first_name, last_name
FROM employees
WHERE last_name LIKE '_a%';

-- Expected Output:
-- | first_name | last_name |
-- |------------|-----------|
-- | Sneha      | Patel     |
-- | Ananya     | Das       |


-- ************************************************************
-- 4. ILIKE — case-insensitive pattern matching (PostgreSQL-specific)
-- ************************************************************

-- Standard LIKE is CASE-SENSITIVE:
SELECT first_name FROM employees WHERE first_name LIKE 'amit%';
-- Expected Output: (empty — 'Amit' starts with uppercase 'A')

-- ILIKE ignores case:
SELECT first_name FROM employees WHERE first_name ILIKE 'amit%';
-- Expected Output:
-- | first_name |
-- |------------|
-- | Amit       |

-- Find departments matching 'engineering' regardless of case
SELECT DISTINCT department FROM employees WHERE department ILIKE 'engineering';
-- Expected Output:
-- | department  |
-- |-------------|
-- | Engineering |


-- ************************************************************
-- 5. NOT LIKE — exclude matching patterns
-- ************************************************************

-- Employees whose email does NOT contain 'singh'
SELECT first_name, email
FROM employees
WHERE email NOT LIKE '%singh%';

-- Expected Output:
-- | first_name | email                    |
-- |------------|--------------------------|
-- | Amit       | amit.sharma@mail.com     |
-- | Priya      | priya.verma@mail.com     |
-- | Rahul      | rahul.gupta@mail.com     |
-- | Sneha      | sneha.patel@mail.com     |
-- | Ananya     | ananya.das@mail.com      |
-- | Karan      | karan.mehta@mail.com     |

-- NOT ILIKE (case-insensitive negation)
SELECT first_name FROM employees WHERE first_name NOT ILIKE 'a%';
-- Expected Output:
-- | first_name |
-- |------------|
-- | Priya      |
-- | Rahul      |
-- | Sneha      |
-- | Vikram     |
-- | Karan      |


-- ************************************************************
-- 6. SIMILAR TO — SQL-standard regex-like patterns
--    Supports: | (alternation), * (zero or more), + (one or more),
--              ? (optional), {n} (repeat), [] (character class)
--    Still anchored to the full string like LIKE.
-- ************************************************************

-- First names starting with 'A' or 'K'
SELECT first_name
FROM employees
WHERE first_name SIMILAR TO '(A|K)%';

-- Expected Output:
-- | first_name |
-- |------------|
-- | Amit       |
-- | Ananya     |
-- | Karan      |

-- Departments that are exactly 'HR' or 'Sales'
SELECT DISTINCT department
FROM employees
WHERE department SIMILAR TO 'HR|Sales';

-- Expected Output:
-- | department |
-- |------------|
-- | HR         |
-- | Sales      |


-- ************************************************************
-- 7. POSIX Regular Expressions with ~ operator (PostgreSQL-specific)
--    ~   = case-sensitive regex match
--    ~*  = case-insensitive regex match
--    !~  = does NOT match (case-sensitive)
--    !~* = does NOT match (case-insensitive)
-- ************************************************************

-- First names starting with a vowel (case-sensitive)
SELECT first_name
FROM employees
WHERE first_name ~ '^[AEIOUaeiou]';

-- Expected Output:
-- | first_name |
-- |------------|
-- | Amit       |
-- | Ananya     |

-- First names that end with 'a' or 'l' (case-insensitive)
SELECT first_name
FROM employees
WHERE first_name ~* '[al]$';

-- Expected Output:
-- | first_name |
-- |------------|
-- | Priya      |
-- | Rahul      |
-- | Sneha      |

-- Email addresses matching a basic pattern: word.word@word.word
SELECT email
FROM employees
WHERE email ~ '^[a-z]+\.[a-z]+@[a-z]+\.[a-z]+$';

-- Expected Output: all 7 emails match this pattern


-- ************************************************************
-- 8. Practical: search by email domain
-- ************************************************************

-- All employees with @mail.com email
SELECT first_name, email
FROM employees
WHERE email LIKE '%@mail.com';

-- Expected Output: all 7 rows (everyone has @mail.com)

-- Suppose you want to find @gmail.com addresses:
SELECT first_name, email
FROM employees
WHERE email LIKE '%@gmail.com';

-- Expected Output: (empty — no one has @gmail.com)


-- ************************************************************
-- 9. Practical: name patterns
-- ************************************************************

-- Employees whose first OR last name contains 'an' (case-insensitive)
SELECT first_name, last_name
FROM employees
WHERE first_name ILIKE '%an%'
   OR last_name ILIKE '%an%';

-- Expected Output:
-- | first_name | last_name |
-- |------------|-----------|
-- | Ananya     | Das       |
-- | Karan      | Mehta     |

-- Employees with a 6+ character last name
SELECT first_name, last_name
FROM employees
WHERE last_name ~ '.{6,}';

-- Expected Output:
-- | first_name | last_name |
-- |------------|-----------|
-- | Amit       | Sharma    |


-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. LIKE is case-sensitive; use ILIKE for case-insensitive matching.
-- 2. %  = any sequence of characters (including none).
-- 3. _  = exactly one character.
-- 4. NOT LIKE / NOT ILIKE excludes matching rows.
-- 5. SIMILAR TO adds SQL-standard regex features (|, +, *, ?, []).
-- 6. The ~ operator uses full POSIX regular expressions.
--    ~  = case-sensitive, ~* = case-insensitive.
-- 7. For simple prefix/suffix/contains searches, LIKE/ILIKE is fastest.
--    For complex patterns, use ~ (regex).
-- ============================================================
