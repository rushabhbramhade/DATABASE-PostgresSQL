# 📘 First Normal Form (1NF)

## 📑 Table of Contents

- [What is 1NF?](#what-is-1nf)
- [Rules of 1NF](#rules-of-1nf)
- [Bad Example — Unnormalized Table](#bad-example--unnormalized-table)
- [Good Example — Table in 1NF](#good-example--table-in-1nf)
- [SQL Examples — Before and After](#sql-examples--before-and-after)
- [Anomalies That 1NF Prevents](#anomalies-that-1nf-prevents)
- [Real-World Analogy](#real-world-analogy)
- [Key Takeaways](#key-takeaways)

---

## What is 1NF?

**First Normal Form (1NF)** is the most fundamental level of database normalization. A table is in 1NF when it organizes data in a way that eliminates **repeating groups**, ensures every column holds **atomic (indivisible) values**, and guarantees that **each row is unique**.

> Think of 1NF as the **ground floor** of normalization — you cannot move to 2NF or 3NF without first satisfying 1NF.

---

## Rules of 1NF

A table is in **First Normal Form** if and only if it satisfies **all three** of the following rules:

| #  | Rule                        | Description                                                                 |
|----|-----------------------------|-----------------------------------------------------------------------------|
| 1  | **Atomic Values**           | Each cell must contain a single, indivisible value — no lists, sets, or CSV |
| 2  | **No Repeating Groups**     | No columns like `phone1`, `phone2`, `phone3` to store multiple values       |
| 3  | **Each Row Must Be Unique** | Every row must be uniquely identifiable (typically via a Primary Key)        |

### Rule 1 — Atomic Values

A column value is **atomic** if it cannot be meaningfully broken down further for the purpose of the table.

```
❌  phone_numbers = '9876543210, 9123456789'    -- NOT atomic (comma-separated list)
✅  phone_number  = '9876543210'                 -- Atomic (single value)
```

### Rule 2 — No Repeating Groups

Repeating groups occur when a table has multiple columns storing the same type of data:

```
❌  phone1, phone2, phone3       -- Repeating group of columns
✅  A separate row per phone      -- One value per row
```

### Rule 3 — Each Row Must Be Unique

Every row should be distinguishable from every other row. This is best enforced with a **Primary Key**.

---

## Bad Example — Unnormalized Table

Consider a `contacts` table where each person can have multiple phone numbers stored as a comma-separated string:

| contact_id | name         | phone_numbers                  |
|------------|--------------|--------------------------------|
| 1          | Amit Sharma  | 9876543210, 9123456789         |
| 2          | Priya Patel  | 8765432109                     |
| 3          | Ravi Kumar   | 7654321098, 6543210987, 9988776655 |

### ❌ What's Wrong Here?

1. **`phone_numbers` is NOT atomic** — it stores comma-separated values in a single cell.
2. **Querying is painful** — to find all contacts with phone `9123456789`, you'd need string parsing (`LIKE '%9123456789%'`), which is slow, error-prone, and cannot use indexes.
3. **Updating is fragile** — changing one phone number requires parsing the entire string.
4. **No referential integrity** — PostgreSQL cannot enforce constraints on individual phone numbers inside a CSV string.

---

## Good Example — Table in 1NF

We decompose the data so that **each phone number gets its own row**:

**`contacts` table:**

| contact_id | name         |
|------------|--------------|
| 1          | Amit Sharma  |
| 2          | Priya Patel  |
| 3          | Ravi Kumar   |

**`contact_phones` table:**

| phone_id | contact_id | phone_number |
|----------|------------|--------------|
| 1        | 1          | 9876543210   |
| 2        | 1          | 9123456789   |
| 3        | 2          | 8765432109   |
| 4        | 3          | 7654321098   |
| 5        | 3          | 6543210987   |
| 6        | 3          | 9988776655   |

### ✅ Why This is Better

- Every cell contains exactly **one value** (atomic).
- No repeating groups — phone numbers are rows, not columns.
- Each row is **uniquely identified** by `phone_id`.
- We can easily **query**, **update**, or **delete** individual phone numbers.
- PostgreSQL can **index** `phone_number` for fast lookups.

---

## SQL Examples — Before and After

### ❌ BEFORE — Unnormalized Table (Violates 1NF)

```sql
-- BAD DESIGN: comma-separated phone numbers in a single column
CREATE TABLE contacts_bad (
    contact_id   SERIAL PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    phone_numbers TEXT          -- e.g., '9876543210, 9123456789'
);

INSERT INTO contacts_bad (name, phone_numbers) VALUES
('Amit Sharma', '9876543210, 9123456789'),
('Priya Patel', '8765432109'),
('Ravi Kumar',  '7654321098, 6543210987, 9988776655');

-- Querying for a specific phone number is messy and slow:
SELECT *
FROM contacts_bad
WHERE phone_numbers LIKE '%9123456789%';
-- This cannot use an index and may return false positives!
```

### ✅ AFTER — Normalized Tables (1NF)

```sql
-- GOOD DESIGN: separate tables with atomic values
CREATE TABLE contacts (
    contact_id   SERIAL PRIMARY KEY,
    name         VARCHAR(100) NOT NULL
);

CREATE TABLE contact_phones (
    phone_id     SERIAL PRIMARY KEY,
    contact_id   INT NOT NULL REFERENCES contacts(contact_id),
    phone_number VARCHAR(15) NOT NULL
);

INSERT INTO contacts (name) VALUES
('Amit Sharma'),
('Priya Patel'),
('Ravi Kumar');

INSERT INTO contact_phones (contact_id, phone_number) VALUES
(1, '9876543210'),
(1, '9123456789'),
(2, '8765432109'),
(3, '7654321098'),
(3, '6543210987'),
(3, '9988776655');

-- Clean, efficient query using an index:
SELECT c.name, cp.phone_number
FROM contacts c
JOIN contact_phones cp ON c.contact_id = cp.contact_id
WHERE cp.phone_number = '9123456789';
```

**Expected Output:**

| name        | phone_number |
|-------------|--------------|
| Amit Sharma | 9123456789   |

### More Useful Queries After Normalization

```sql
-- Count how many phone numbers each contact has
SELECT c.name, COUNT(cp.phone_id) AS total_phones
FROM contacts c
JOIN contact_phones cp ON c.contact_id = cp.contact_id
GROUP BY c.name;
```

**Expected Output:**

| name        | total_phones |
|-------------|--------------|
| Amit Sharma | 2            |
| Priya Patel | 1            |
| Ravi Kumar  | 3            |

```sql
-- Delete a specific phone number without touching others
DELETE FROM contact_phones
WHERE contact_id = 3 AND phone_number = '6543210987';
```

---

## Anomalies That 1NF Prevents

When data violates 1NF, several **data anomalies** become inevitable:

| Anomaly             | Description                                                                       | Example                                                              |
|---------------------|-----------------------------------------------------------------------------------|----------------------------------------------------------------------|
| **Insertion Anomaly**  | Cannot add a phone number without complex string manipulation                     | Adding a 4th phone to Ravi requires parsing and rebuilding the CSV   |
| **Update Anomaly**     | Changing one phone number risks corrupting the entire string                      | A typo fix in the CSV could accidentally alter adjacent numbers      |
| **Deletion Anomaly**   | Removing one phone number may require rewriting the whole cell                    | Deleting one number from `'7654321098, 6543210987'` needs string ops |
| **Search Anomaly**     | Cannot efficiently search for a specific value inside a CSV column                | `LIKE '%value%'` is slow and may give false positives                |

---

## Real-World Analogy

### 📬 The Filing Cabinet Analogy

Imagine you manage an **office filing cabinet**:

- **Unnormalized (violates 1NF):** You have one folder per employee, and inside each folder, you've scribbled all their phone numbers on a single sticky note: `"Home: 555-1234, Work: 555-5678, Mom: 555-9999"`. Finding a specific number means reading through every sticky note. Updating one number risks smudging the others.

- **Normalized (1NF):** Each phone number is written on its **own index card** inside the folder, clearly labeled. You can instantly find, add, remove, or update any card without affecting the others.

> **1NF is about giving every piece of data its own clean, findable spot — no cramming multiple values into one place.**

---

## Key Takeaways

| ✅ Do                                        | ❌ Don't                                             |
|----------------------------------------------|------------------------------------------------------|
| Store one value per cell (atomic)            | Store comma-separated or pipe-delimited values       |
| Use separate rows for multi-valued data      | Create columns like `phone1`, `phone2`, `phone3`     |
| Add a Primary Key to every table             | Leave rows without a unique identifier               |
| Use Foreign Keys to relate tables            | Embed related data as strings in a single column     |

> **Remember:** 1NF is the **entry ticket** to proper normalization. Without it, 2NF and 3NF are meaningless. Always start here.

---

*Next: [Second Normal Form (2NF) →](./2NF.md)*
