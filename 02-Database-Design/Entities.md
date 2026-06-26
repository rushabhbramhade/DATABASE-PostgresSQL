# Database Entities

## Table of Contents

- [What is an Entity?](#what-is-an-entity)
- [Entity vs Table](#entity-vs-table)
- [Strong Entities vs Weak Entities](#strong-entities-vs-weak-entities)
  - [Strong Entity](#strong-entity)
  - [Weak Entity](#weak-entity)
  - [Comparison Table](#comparison-table)
- [Types of Attributes](#types-of-attributes)
  - [Simple Attribute](#1-simple-attribute)
  - [Composite Attribute](#2-composite-attribute)
  - [Derived Attribute](#3-derived-attribute)
  - [Multi-valued Attribute](#4-multi-valued-attribute)
  - [Key Attribute](#5-key-attribute)
  - [Attribute Summary](#attribute-summary)
- [Types of Keys](#types-of-keys)
  - [Primary Key](#1-primary-key)
  - [Candidate Key](#2-candidate-key)
  - [Super Key](#3-super-key)
  - [Composite Key](#4-composite-key)
  - [Foreign Key](#5-foreign-key)
  - [Alternate Key](#6-alternate-key)
  - [Key Hierarchy Diagram](#key-hierarchy-diagram)
- [Practical Examples](#practical-examples)
  - [Students Table](#example-1-students-table)
  - [Courses Table](#example-2-courses-table)
  - [Employees Table](#example-3-employees-table)
  - [Weak Entity Example](#example-4-weak-entity--order_items)
- [How to Identify Entities from Business Requirements](#how-to-identify-entities-from-business-requirements)
- [Common Mistakes](#common-mistakes)
- [Key Takeaways](#key-takeaways)

---

## What is an Entity?

An **entity** is any real-world object, concept, or thing about which we want to store data in a database. In relational databases, each entity is represented as a **table**.

**Examples of entities:**
- A **student** enrolled in a university
- An **employee** working at a company
- A **product** sold in an online store
- An **order** placed by a customer
- A **hospital patient** admitted for treatment

> **Rule of thumb:** If you can describe something with a set of properties (attributes), and you need to track multiple instances of it, it's probably an entity.

---

## Entity vs Table

While "entity" and "table" are often used interchangeably, they exist at different levels of abstraction:

| Concept | Level | Description |
|---------|-------|-------------|
| **Entity** | Conceptual / Logical | A real-world thing we want to model |
| **Table** | Physical | The actual SQL implementation of an entity |
| **Entity Set** | Conceptual | A collection of all entities of the same type |
| **Row / Tuple** | Physical | A single instance of an entity |
| **Attribute** | Conceptual | A property of an entity |
| **Column / Field** | Physical | The SQL implementation of an attribute |

```
Conceptual Level:     Entity "Student"  →  Attributes: name, email, dob
                                ↓
Physical Level:       TABLE students    →  Columns: name, email, dob
```

---

## Strong Entities vs Weak Entities

### Strong Entity

A **strong entity** can exist independently. It has its own **primary key** that uniquely identifies each instance without depending on any other entity.

**Characteristics:**
- Has a primary key that is self-sufficient
- Drawn as a **single rectangle** in ERD
- Exists on its own — doesn't depend on another entity for identification

**Examples:**

```sql
-- STUDENT is a strong entity: student_id uniquely identifies each student
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name  VARCHAR(50) NOT NULL,
    email      VARCHAR(100) UNIQUE NOT NULL,
    dob        DATE
);

-- DEPARTMENT is a strong entity: department_id is self-sufficient
CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    dept_name     VARCHAR(100) NOT NULL,
    location      VARCHAR(100)
);
```

### Weak Entity

A **weak entity** cannot be uniquely identified by its own attributes alone. It depends on a **strong entity** (called its **owner** or **identifying entity**) for its existence and identification.

**Characteristics:**
- Does not have a full primary key of its own — uses a **partial key** (discriminator)
- Its primary key is a **composite** of the owner's PK + its own partial key
- Drawn as a **double rectangle** in ERD (Chen notation)
- If the owner entity is deleted, the weak entity's records lose meaning

**Examples:**

```sql
-- ORDER is a strong entity
CREATE TABLE orders (
    order_id   SERIAL PRIMARY KEY,
    order_date DATE NOT NULL,
    customer_id INT NOT NULL
);

-- ORDER_ITEM is a weak entity: it depends on ORDER for identification
-- The partial key is item_number (meaningful only within a specific order)
CREATE TABLE order_items (
    order_id    INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    item_number INT NOT NULL,             -- partial key / discriminator
    product_id  INT NOT NULL,
    quantity    INT NOT NULL,
    unit_price  DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (order_id, item_number)   -- composite PK = owner PK + partial key
);
```

```sql
-- BUILDING is a strong entity
CREATE TABLE buildings (
    building_id   SERIAL PRIMARY KEY,
    building_name VARCHAR(100) NOT NULL
);

-- ROOM is a weak entity: "Room 101" has no meaning without knowing the building
CREATE TABLE rooms (
    building_id  INT NOT NULL REFERENCES buildings(building_id) ON DELETE CASCADE,
    room_number  VARCHAR(10) NOT NULL,   -- partial key
    capacity     INT,
    PRIMARY KEY (building_id, room_number)
);
```

### Comparison Table

| Feature | Strong Entity | Weak Entity |
|---------|--------------|-------------|
| **Independent existence** | ✅ Yes | ❌ No — depends on owner entity |
| **Primary key** | Own PK | Composite PK (owner PK + partial key) |
| **ERD symbol (Chen)** | Single rectangle | Double rectangle |
| **Deletion behavior** | Can be deleted independently | Deleted when owner is deleted (CASCADE) |
| **Examples** | `students`, `departments`, `products` | `order_items`, `rooms`, `dependents` |

---

## Types of Attributes

### 1. Simple Attribute

An attribute that **cannot be divided** into smaller meaningful components.

```sql
-- first_name, salary, and hire_date are all simple attributes
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name  VARCHAR(50),    -- simple: cannot be divided further
    salary      DECIMAL(10,2),  -- simple: a single numeric value
    hire_date   DATE            -- simple: a single date value
);
```

### 2. Composite Attribute

An attribute that **can be broken down** into smaller sub-attributes.

```
full_name → first_name + middle_name + last_name
address   → street + city + state + zip_code + country
```

> **Best Practice:** In relational databases, always store composite attributes as **separate columns** rather than a single column. This enables searching and filtering on individual parts.

```sql
-- ❌ Bad: storing address as a single column
CREATE TABLE customers_bad (
    customer_id SERIAL PRIMARY KEY,
    full_address TEXT   -- "123 Main St, New York, NY, 10001"
);

-- ✅ Good: breaking address into sub-attributes
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name  VARCHAR(50),
    last_name   VARCHAR(50),
    street      VARCHAR(200),
    city        VARCHAR(100),
    state       VARCHAR(50),
    zip_code    VARCHAR(10),
    country     VARCHAR(50) DEFAULT 'USA'
);
```

### 3. Derived Attribute

An attribute whose value is **computed from other attributes** — it is not stored directly.

```
age           → derived from date_of_birth
total_price   → derived from unit_price × quantity
years_employed → derived from hire_date
```

```sql
-- age is NOT stored as a column — it is derived from dob
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name  VARCHAR(50) NOT NULL,
    dob        DATE NOT NULL
);

-- Deriving age at query time:
SELECT
    first_name,
    last_name,
    dob,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, dob)) AS age   -- derived attribute
FROM students;
```

> **Why not store derived attributes?** Storing `age` as a column means it becomes outdated the next day. Computing it dynamically ensures it is always accurate.

### 4. Multi-valued Attribute

An attribute that can hold **multiple values** for a single entity instance.

```
phone_numbers → a person can have multiple phone numbers
skills        → an employee can have multiple skills
email_addresses → a student can have personal + university email
```

> **Important:** Relational databases do not natively support multi-valued attributes in a single column (1NF violation). The solution is to create a **separate table**.

```sql
-- ❌ Bad: storing multiple phone numbers in one column
CREATE TABLE employees_bad (
    employee_id SERIAL PRIMARY KEY,
    name        VARCHAR(100),
    phones      TEXT   -- "555-0101, 555-0102, 555-0103"  ← violates 1NF
);

-- ✅ Good: separate table for phone numbers
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL
);

CREATE TABLE employee_phones (
    phone_id    SERIAL PRIMARY KEY,
    employee_id INT NOT NULL REFERENCES employees(employee_id) ON DELETE CASCADE,
    phone_type  VARCHAR(20),     -- 'mobile', 'home', 'work'
    phone_number VARCHAR(20) NOT NULL
);
```

### 5. Key Attribute

An attribute (or combination of attributes) that **uniquely identifies** each entity instance. See the [Types of Keys](#types-of-keys) section below for a deep dive.

### Attribute Summary

| Type | Can Be Divided? | Stored Directly? | Multiple Values? | Example |
|------|:-:|:-:|:-:|---------|
| **Simple** | ❌ | ✅ | ❌ | `first_name`, `salary` |
| **Composite** | ✅ | ✅ (as sub-parts) | ❌ | `address` → `street`, `city`, `zip` |
| **Derived** | ❌ | ❌ (computed) | ❌ | `age` from `dob` |
| **Multi-valued** | ❌ | ❌ (separate table) | ✅ | `phone_numbers`, `skills` |
| **Key** | Depends | ✅ | ❌ | `student_id`, `email` |

---

## Types of Keys

### 1. Primary Key

The **primary key (PK)** uniquely identifies each row in a table. Every table must have exactly one primary key.

**Rules:**
- Must be **unique** across all rows
- Cannot be **NULL**
- Should be **immutable** (value should not change)
- Ideally a **single column** (surrogate key like `SERIAL`)

```sql
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,      -- surrogate primary key
    first_name VARCHAR(50) NOT NULL,
    email      VARCHAR(100) UNIQUE NOT NULL
);
```

### 2. Candidate Key

A **candidate key** is any column (or combination of columns) that _could_ serve as the primary key — it uniquely identifies each row and has no unnecessary columns.

> A table can have **multiple candidate keys**, but only one is chosen as the primary key.

```sql
-- In this table, both student_id AND email are candidate keys
-- because both uniquely identify each student
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,            -- chosen as PK
    email      VARCHAR(100) UNIQUE NOT NULL,   -- also a candidate key (becomes alternate key)
    first_name VARCHAR(50),
    last_name  VARCHAR(50)
);
```

**Candidate keys in `students`:**
- `student_id` → chosen as **Primary Key**
- `email` → becomes an **Alternate Key**

### 3. Super Key

A **super key** is any set of columns that uniquely identifies a row — it may contain **extra (unnecessary) columns** beyond what's minimally needed.

> Every candidate key is a super key, but not every super key is a candidate key.

```sql
-- For the students table:
-- Super keys include:
--   {student_id}                    ← also a candidate key (minimal)
--   {email}                         ← also a candidate key (minimal)
--   {student_id, email}             ← super key (not minimal — student_id alone is enough)
--   {student_id, first_name}        ← super key (not minimal)
--   {student_id, first_name, email} ← super key (not minimal)
```

**Key hierarchy:**

```
Super Key  ⊇  Candidate Key  ⊇  Primary Key
  (broad)       (minimal)        (chosen one)
```

### 4. Composite Key

A **composite key** is a primary key made up of **two or more columns** together.

> Used when no single column uniquely identifies a row — common in junction tables and weak entities.

```sql
-- The enrollment table uses a composite primary key
CREATE TABLE enrollments (
    student_id INT NOT NULL REFERENCES students(student_id),
    course_id  INT NOT NULL REFERENCES courses(course_id),
    enrolled_on DATE DEFAULT CURRENT_DATE,
    grade      CHAR(2),
    PRIMARY KEY (student_id, course_id)  -- composite key: both columns together form the PK
);
```

| student_id | course_id | enrolled_on | grade |
|:---:|:---:|:---:|:---:|
| 1 | 101 | 2025-01-15 | A |
| 1 | 102 | 2025-01-15 | B+ |
| 2 | 101 | 2025-01-16 | A- |

- `student_id = 1` alone doesn't identify a unique row (appears twice)
- `course_id = 101` alone doesn't identify a unique row (appears twice)
- `(student_id = 1, course_id = 101)` uniquely identifies exactly one row ✅

### 5. Foreign Key

A **foreign key (FK)** is a column that references the primary key of another table, creating a link between the two.

```sql
CREATE TABLE courses (
    course_id   SERIAL PRIMARY KEY,
    course_name VARCHAR(100) NOT NULL,
    credits     INT NOT NULL CHECK (credits BETWEEN 1 AND 6)
);

CREATE TABLE enrollments (
    enrollment_id SERIAL PRIMARY KEY,
    student_id    INT NOT NULL REFERENCES students(student_id),    -- FK → students
    course_id     INT NOT NULL REFERENCES courses(course_id),      -- FK → courses
    grade         CHAR(2)
);
```

### 6. Alternate Key

An **alternate key** is any candidate key that was **not chosen** as the primary key. It is enforced using a `UNIQUE` constraint.

```sql
CREATE TABLE employees (
    employee_id  SERIAL PRIMARY KEY,              -- PK (chosen from candidates)
    ssn          VARCHAR(11) UNIQUE NOT NULL,      -- alternate key
    email        VARCHAR(100) UNIQUE NOT NULL,     -- alternate key
    name         VARCHAR(100)
);
-- employee_id, ssn, and email are all candidate keys
-- employee_id is the PK; ssn and email are alternate keys
```

### Key Hierarchy Diagram

```
┌─────────────────────────────────────────────┐
│                 SUPER KEYS                  │
│  {id}, {email}, {id,email}, {id,name}, ...  │
│                                             │
│    ┌───────────────────────────────────┐    │
│    │         CANDIDATE KEYS            │    │
│    │      {id}, {email}                │    │
│    │                                   │    │
│    │   ┌────────────────────┐          │    │
│    │   │   PRIMARY KEY      │          │    │
│    │   │     {id}           │          │    │
│    │   └────────────────────┘          │    │
│    │                                   │    │
│    │   ┌────────────────────┐          │    │
│    │   │  ALTERNATE KEYS    │          │    │
│    │   │    {email}         │          │    │
│    │   └────────────────────┘          │    │
│    └───────────────────────────────────┘    │
└─────────────────────────────────────────────┘
```

---

## Practical Examples

### Example 1: Students Table

```sql
CREATE TABLE students (
    student_id  SERIAL PRIMARY KEY,             -- PK, simple attribute, key attribute
    first_name  VARCHAR(50) NOT NULL,           -- simple attribute
    last_name   VARCHAR(50) NOT NULL,           -- simple attribute
    email       VARCHAR(100) UNIQUE NOT NULL,   -- alternate key, simple attribute
    dob         DATE,                           -- simple attribute
    -- age is a DERIVED attribute (computed from dob, not stored)
    gpa         DECIMAL(3,2) CHECK (gpa BETWEEN 0.00 AND 4.00)
);

-- Multi-valued attribute: stored in a separate table
CREATE TABLE student_phones (
    phone_id    SERIAL PRIMARY KEY,
    student_id  INT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    phone_type  VARCHAR(20) DEFAULT 'mobile',
    phone_number VARCHAR(20) NOT NULL
);
```

### Example 2: Courses Table

```sql
CREATE TABLE courses (
    course_id   SERIAL PRIMARY KEY,
    course_code VARCHAR(10) UNIQUE NOT NULL,    -- alternate key (e.g., 'CS101')
    course_name VARCHAR(150) NOT NULL,
    credits     INT NOT NULL CHECK (credits BETWEEN 1 AND 6),
    department  VARCHAR(100)
);

-- Query using derived attribute
SELECT
    course_code,
    course_name,
    credits,
    credits * 15 AS total_hours    -- derived: total lecture hours per semester
FROM courses;
```

### Example 3: Employees Table

```sql
CREATE TABLE employees (
    employee_id   SERIAL PRIMARY KEY,
    first_name    VARCHAR(50) NOT NULL,
    last_name     VARCHAR(50) NOT NULL,
    email         VARCHAR(100) UNIQUE NOT NULL,
    -- Composite attribute (address) stored as sub-parts:
    street        VARCHAR(200),
    city          VARCHAR(100),
    state         VARCHAR(50),
    zip_code      VARCHAR(10),
    country       VARCHAR(50) DEFAULT 'USA',
    hire_date     DATE NOT NULL DEFAULT CURRENT_DATE,
    salary        DECIMAL(10,2) CHECK (salary > 0),
    department_id INT REFERENCES departments(department_id)
);

-- Derived attributes in queries
SELECT
    first_name || ' ' || last_name AS full_name,                  -- derived
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date)) AS years_employed,  -- derived
    salary * 12 AS annual_salary                                  -- derived
FROM employees;
```

### Example 4: Weak Entity — order_items

```sql
CREATE TABLE orders (
    order_id     SERIAL PRIMARY KEY,    -- strong entity with own PK
    customer_id  INT NOT NULL,
    order_date   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2)
);

-- Weak entity: depends on orders for identification
CREATE TABLE order_items (
    order_id    INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    line_number INT NOT NULL,                -- partial key (discriminator)
    product_id  INT NOT NULL,
    quantity    INT NOT NULL CHECK (quantity > 0),
    unit_price  DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (order_id, line_number)       -- composite PK
);

-- line_number 1 can exist in order 100 AND order 200
-- But (order_id=100, line_number=1) is globally unique
```

---

## How to Identify Entities from Business Requirements

### The Process

```
Business Requirements (text)
         ↓
    Extract Nouns         →  Potential entities
    Extract Verbs         →  Potential relationships
    Extract Adjectives    →  Potential attributes
         ↓
    Filter and Refine
         ↓
    Final Entity List
```

### Step-by-Step Method

**1. Read the requirement and underline all nouns:**

> _"A **hospital** manages **patients** who visit **doctors**. Each **patient** can have multiple **appointments**. **Doctors** belong to **departments** and can write **prescriptions** for **patients**."_

**2. List candidate entities from nouns:**

| Noun | Entity? | Reasoning |
|------|---------|-----------|
| Hospital | ❌ Probably not | If there's only one hospital, it's the system itself, not an entity |
| Patients | ✅ Yes | Multiple instances, clear attributes (name, dob, etc.) |
| Doctors | ✅ Yes | Multiple instances, clear attributes (name, specialty) |
| Appointments | ✅ Yes | Multiple instances, has date/time, links patient to doctor |
| Departments | ✅ Yes | Multiple instances (Cardiology, Neurology, etc.) |
| Prescriptions | ✅ Yes | Multiple instances, links to patient and doctor |

**3. Identify relationships (from verbs):**
- Patients **visit** doctors → M:N (via appointments)
- Doctors **belong to** departments → N:1
- Doctors **write** prescriptions → 1:N
- Prescriptions **are for** patients → N:1

**4. Add attributes for each entity:**

| Entity | Attributes |
|--------|-----------|
| patients | patient_id (PK), first_name, last_name, dob, phone, email |
| doctors | doctor_id (PK), first_name, last_name, specialty, department_id (FK) |
| departments | department_id (PK), dept_name, floor |
| appointments | appointment_id (PK), patient_id (FK), doctor_id (FK), date_time, status |
| prescriptions | prescription_id (PK), doctor_id (FK), patient_id (FK), medication, dosage, date_issued |

### Quick Checklist for Entity Identification

| Question | If Yes → |
|----------|----------|
| Does it have multiple instances? | Likely an entity |
| Can you describe it with attributes? | Likely an entity |
| Does it need to be tracked over time? | Likely an entity |
| Is it just a property of another entity? | Probably an attribute, not an entity |
| Does it represent a relationship between two entities? | Might be a junction table |

---

## Common Mistakes

| Mistake | Problem | Fix |
|---------|---------|-----|
| Storing derived attributes | Data becomes stale, wastes storage | Compute at query time using SQL expressions |
| Multi-valued attributes in one column | Violates 1NF, impossible to query properly | Create a separate table |
| No primary key defined | Cannot uniquely identify rows | Always define a PK |
| Using natural keys as PK | Can change over time (email, SSN) | Prefer surrogate keys (`SERIAL`) |
| Confusing entity with attribute | Leads to denormalized schema | Ask: "Does this thing have its own attributes?" |
| Forgetting weak entity dependencies | Orphan records when parent is deleted | Use `ON DELETE CASCADE` |

---

## Key Takeaways

1. **Entities** are real-world objects modeled as tables — identify them by extracting nouns from business requirements
2. **Strong entities** have independent primary keys; **weak entities** depend on an owner entity for identification
3. **Composite attributes** should be broken into separate columns for searchability
4. **Derived attributes** should be computed at query time, not stored
5. **Multi-valued attributes** must be stored in separate tables to maintain First Normal Form
6. **Primary Key** = the chosen candidate key; **Super Key** ⊇ **Candidate Key** ⊇ **Primary Key**
7. **Composite keys** combine two or more columns — common in junction tables and weak entities
8. Always ask: _"Can this concept have multiple instances with their own attributes?"_ — if yes, it's an entity
