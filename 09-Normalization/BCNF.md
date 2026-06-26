# 📘 Boyce-Codd Normal Form (BCNF)

## 📑 Table of Contents

- [Prerequisites](#prerequisites)
- [How BCNF Differs from 3NF](#how-bcnf-differs-from-3nf)
- [The Rule of BCNF](#the-rule-of-bcnf)
- [Example: 3NF ✅ but BCNF ❌](#example-3nf--but-bcnf-)
- [Decomposing into BCNF](#decomposing-into-bcnf)
- [When to Use BCNF vs Stopping at 3NF](#when-to-use-bcnf-vs-stopping-at-3nf)
- [Denormalization — When and Why to Break the Rules](#denormalization--when-and-why-to-break-the-rules)
- [Quick Comparison: 1NF vs 2NF vs 3NF vs BCNF](#quick-comparison-1nf-vs-2nf-vs-3nf-vs-bcnf)
- [Interview Tips](#interview-tips)
- [Key Takeaways](#key-takeaways)

---

## Prerequisites

> ⚠️ **You should understand [1NF](./1NF.md), [2NF](./2NF.md), and [3NF](./3NF.md) before studying BCNF.**

Key terms you need to know:

| Term | Definition |
|------|-----------|
| **Candidate Key** | A minimal set of columns that can uniquely identify every row in the table. A table can have multiple candidate keys. |
| **Primary Key** | The candidate key chosen as the main identifier for the table. |
| **Determinant** | Any column (or set of columns) on which some other column is fully functionally dependent. |
| **Functional Dependency** | Column B is functionally dependent on Column A if knowing A's value uniquely determines B's value. Written as A → B. |

---

## How BCNF Differs from 3NF

Both 3NF and BCNF deal with functional dependencies, but BCNF is **stricter**:

| Normal Form | Rule |
|-------------|------|
| **3NF** | Every non-key column must depend on the key, the whole key, and nothing but the key |
| **BCNF** | Every **determinant** must be a **candidate key** |

### The Key Difference

3NF allows a situation where a non-candidate-key column determines another column, **as long as the dependent column is part of a candidate key**. BCNF does NOT allow this exception.

```
3NF says:  Non-key → Non-key is NOT allowed
           Non-key → Part-of-key is ALLOWED (the exception!)

BCNF says: If X → Y, then X MUST be a candidate key. NO exceptions.
```

> **BCNF is sometimes called 3.5NF** because it's a stricter version of 3NF.

### When Do They Differ?

The difference between 3NF and BCNF only shows up when:
1. The table has **multiple overlapping candidate keys**, AND
2. At least one candidate key is **composite**, AND
3. A non-candidate-key column **determines** part of a candidate key

This is a rare but important scenario.

---

## The Rule of BCNF

> **For every non-trivial functional dependency X → Y in the table, X must be a candidate key (or a superset of a candidate key).**

In other words: the only columns that are "allowed" to determine other columns are candidate keys. If any other column acts as a determinant, the table violates BCNF.

---

## Example: 3NF ✅ but BCNF ❌

### The Scenario: Student-Subject-Professor

A university has these business rules:
- Each **subject** can be taught by **multiple professors**.
- Each **professor** teaches only **one subject**.
- Each **student** can enroll in **multiple subjects**.
- For each subject, a student is assigned to **exactly one professor**.

### ❌ `student_assignments` table

| student_id | subject     | professor    |
|------------|-------------|--------------|
| 101        | Databases   | Dr. Rao      |
| 101        | Algorithms  | Dr. Singh    |
| 102        | Databases   | Dr. Mehta    |
| 102        | Algorithms  | Dr. Singh    |
| 103        | Databases   | Dr. Rao      |

### Analyzing the Dependencies

**Candidate Keys:**
- `(student_id, subject)` → uniquely identifies the professor assigned
- `(student_id, professor)` → uniquely identifies the subject (since each professor teaches only one subject)

**Functional Dependencies:**

| Dependency | Explanation |
|-----------|------------|
| `(student_id, subject) → professor` | For a given student and subject, there's exactly one professor |
| `professor → subject` | Each professor teaches only one subject |
| `(student_id, professor) → subject` | Derived from the above |

### Is it in 3NF?

Let's check: `professor → subject`

- `professor` is **not** a candidate key (it's not `(student_id, subject)` or `(student_id, professor)`)
- But `subject` is **part of** a candidate key `(student_id, subject)`
- 3NF allows a non-key determinant if the dependent attribute is part of a candidate key

✅ **Yes, it satisfies 3NF.**

### Is it in BCNF?

Check: `professor → subject`

- `professor` is a **determinant** (it determines `subject`)
- `professor` is **NOT a candidate key** (alone, it cannot uniquely identify a row)
- BCNF requires **every determinant** to be a candidate key

❌ **No, it violates BCNF.**

---

## Decomposing into BCNF

To fix the BCNF violation, we decompose the table so that every determinant becomes a candidate key in its own table:

### ✅ `professor_subjects` table

| professor  | subject     |
|------------|-------------|
| Dr. Rao    | Databases   |
| Dr. Singh  | Algorithms  |
| Dr. Mehta  | Databases   |

**Primary Key:** `professor`
— The determinant `professor → subject` is now a candidate key in this table. ✅

### ✅ `student_professors` table

| student_id | professor  |
|------------|------------|
| 101        | Dr. Rao    |
| 101        | Dr. Singh  |
| 102        | Dr. Mehta  |
| 102        | Dr. Singh  |
| 103        | Dr. Rao    |

**Primary Key:** `(student_id, professor)`
— Every determinant in this table is a candidate key. ✅

### SQL Implementation

```sql
-- Professor-Subject mapping
CREATE TABLE professor_subjects (
    professor VARCHAR(100) PRIMARY KEY,
    subject   VARCHAR(100) NOT NULL
);

-- Student-Professor assignments
CREATE TABLE student_professors (
    student_id INT,
    professor  VARCHAR(100) REFERENCES professor_subjects(professor),
    PRIMARY KEY (student_id, professor)
);

INSERT INTO professor_subjects (professor, subject) VALUES
('Dr. Rao',   'Databases'),
('Dr. Singh', 'Algorithms'),
('Dr. Mehta', 'Databases');

INSERT INTO student_professors (student_id, professor) VALUES
(101, 'Dr. Rao'),
(101, 'Dr. Singh'),
(102, 'Dr. Mehta'),
(102, 'Dr. Singh'),
(103, 'Dr. Rao');

-- Reconstruct the original view
SELECT 
    sp.student_id,
    ps.subject,
    sp.professor
FROM student_professors sp
JOIN professor_subjects ps ON sp.professor = ps.professor
ORDER BY sp.student_id, ps.subject;
```

**Expected Output:**

| student_id | subject    | professor |
|------------|------------|-----------|
| 101        | Algorithms | Dr. Singh |
| 101        | Databases  | Dr. Rao   |
| 102        | Algorithms | Dr. Singh |
| 102        | Databases  | Dr. Mehta |
| 103        | Databases  | Dr. Rao   |

---

## When to Use BCNF vs Stopping at 3NF

| Factor | Stop at 3NF | Go to BCNF |
|--------|-------------|-------------|
| **Overlapping composite candidate keys?** | No overlapping keys → 3NF = BCNF automatically | Yes → evaluate BCNF |
| **Data anomalies observed?** | No anomalies in practice | Redundancy or update anomalies exist |
| **Dependency preservation** | 3NF guarantees all FDs are preserved | BCNF decomposition may **lose** some FDs |
| **Practical databases** | Most real-world schemas stop at 3NF | Specific tables with overlapping keys |
| **Performance sensitivity** | Additional JOINs are costly | Data integrity is more critical than speed |

### ⚠️ The Trade-off

BCNF decomposition can sometimes make it **impossible to enforce certain functional dependencies** without adding triggers or application logic. This is the main reason many practitioners stop at 3NF.

**Example:** In our decomposition above, we lost the ability to directly enforce that `(student_id, subject)` is unique (a student can't be assigned two professors for the same subject). We'd need an additional constraint or trigger.

---

## Denormalization — When and Why to Break the Rules

**Denormalization** is the intentional introduction of redundancy (violating a normal form) to improve **read performance**.

### When to Denormalize

| Scenario | Why Denormalize |
|----------|----------------|
| **Reporting / Analytics** | Complex JOINs across many tables slow down dashboards |
| **Read-Heavy Workloads** | 95%+ reads, very few writes — redundancy is acceptable |
| **Caching Layers** | Materialized views or summary tables for fast access |
| **Data Warehousing** | Star/snowflake schemas intentionally denormalize for OLAP |
| **Microservices** | Each service owns its data; duplication across services is expected |

### When NOT to Denormalize

| Scenario | Why Stay Normalized |
|----------|-------------------|
| **OLTP Systems** | Frequent inserts/updates — redundancy causes anomalies |
| **Small Tables** | JOINs on small tables are fast; no benefit from redundancy |
| **Rapidly Changing Data** | Keeping redundant copies in sync is expensive and error-prone |
| **Regulatory Compliance** | Financial/medical data needs a single source of truth |

### Denormalization Techniques in PostgreSQL

```sql
-- 1. Materialized View: precomputed JOIN result, refreshable
CREATE MATERIALIZED VIEW employee_details AS
SELECT 
    e.emp_id,
    e.emp_name,
    d.department_name,
    d.dept_location
FROM employees e
JOIN departments d ON e.department_id = d.department_id;

-- Refresh when source data changes
REFRESH MATERIALIZED VIEW employee_details;

-- 2. Computed/Redundant Column: store a derived value
ALTER TABLE orders ADD COLUMN customer_name VARCHAR(100);

-- Keep it in sync with a trigger
CREATE OR REPLACE FUNCTION sync_customer_name()
RETURNS TRIGGER AS $$
BEGIN
    SELECT customer_name INTO NEW.customer_name
    FROM customers WHERE customer_id = NEW.customer_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_customer_name
BEFORE INSERT OR UPDATE ON orders
FOR EACH ROW EXECUTE FUNCTION sync_customer_name();
```

> **Golden Rule:** Normalize first for correctness, then denormalize selectively for performance — and document WHY you broke the rules.

---

## Quick Comparison: 1NF vs 2NF vs 3NF vs BCNF

| Aspect | 1NF | 2NF | 3NF | BCNF |
|--------|-----|-----|-----|------|
| **Core Rule** | Atomic values, unique rows | No partial dependencies | No transitive dependencies | Every determinant is a candidate key |
| **Prerequisite** | — | 1NF | 2NF | 3NF |
| **Eliminates** | Multi-valued cells, repeating groups | Redundancy from composite keys | Non-key → non-key dependencies | All remaining FD anomalies |
| **Applies When** | Always | Composite primary keys exist | Non-key column depends on another non-key | Non-candidate-key column is a determinant |
| **Strictness** | ⭐ | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Common in Practice** | ✅ Always applied | ✅ Always applied | ✅ Usually the target | ⚠️ Applied when needed |
| **Preserves All FDs?** | Yes | Yes | Yes | **Not always** |
| **Real-World Usage** | Every database | Every database | Most production databases | Specialized cases |

### The Progression at a Glance

```
Unnormalized Table
       │
       ▼
   ┌───────┐
   │  1NF  │  Atomic values, no repeating groups, unique rows
   └───┬───┘
       ▼
   ┌───────┐
   │  2NF  │  + No partial dependencies (on composite keys)
   └───┬───┘
       ▼
   ┌───────┐
   │  3NF  │  + No transitive dependencies (non-key → non-key)
   └───┬───┘
       ▼
   ┌───────┐
   │ BCNF  │  + Every determinant is a candidate key
   └───────┘
```

---

## Interview Tips

### 🎯 Commonly Asked Questions

**Q1: What is normalization?**
> Normalization is the process of organizing database tables to minimize redundancy and prevent data anomalies (insertion, update, deletion anomalies).

**Q2: What's the difference between 3NF and BCNF?**
> 3NF allows a non-candidate-key to determine a candidate-key attribute. BCNF does not — it requires every determinant to be a candidate key. BCNF is stricter.

**Q3: Is BCNF always better than 3NF?**
> Not always. BCNF can lose functional dependency preservation, meaning you might need triggers or application logic to enforce some constraints. Most production databases target 3NF.

**Q4: What is denormalization?**
> Intentionally adding redundancy to a normalized schema to improve read performance. Common in analytics, reporting, and data warehouses.

**Q5: Give a quick example where 3NF ≠ BCNF.**
> A table where a professor determines a subject, but professor is not a candidate key. The table can be in 3NF (because the determined attribute is part of a candidate key) but violates BCNF.

### 💡 Tips for Answering

| Tip | Details |
|-----|---------|
| **Use the oath** | *"The key, the whole key, and nothing but the key"* — covers 1NF, 2NF, and 3NF in one sentence |
| **Draw dependency diagrams** | Sketch arrows showing what depends on what — interviewers love visual explanations |
| **Know the anomalies** | Insertion, update, and deletion anomalies are the *why* behind normalization |
| **Mention trade-offs** | Show maturity by discussing when denormalization makes sense |
| **Be precise with terms** | Don't confuse "primary key" with "candidate key" — BCNF questions hinge on this distinction |
| **Give real examples** | Use e-commerce (orders, customers, products) or university (students, courses, professors) scenarios |

### 🔑 Quick Reference Card

```
┌──────────────────────────────────────────────────────┐
│                NORMALIZATION CHEAT SHEET              │
├──────────────────────────────────────────────────────┤
│                                                      │
│  1NF:  Atomic values + unique rows                   │
│  2NF:  1NF + no partial deps on composite keys       │
│  3NF:  2NF + no transitive deps (non-key → non-key)  │
│  BCNF: 3NF + every determinant is a candidate key    │
│                                                      │
│  Denormalize ONLY when:                              │
│    • Performance demands it                          │
│    • Read-heavy workloads                            │
│    • You document the trade-off                      │
│                                                      │
│  The Oath:                                           │
│    "The key, the whole key, nothing but the key"     │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

## Key Takeaways

| ✅ Do | ❌ Don't |
|-------|---------|
| Understand that BCNF is stricter than 3NF | Assume 3NF and BCNF are always the same |
| Check if every determinant is a candidate key | Ignore non-candidate-key determinants |
| Know that BCNF may sacrifice dependency preservation | Always decompose to BCNF without considering trade-offs |
| Denormalize with a clear reason and documentation | Denormalize "because JOINs are slow" without measuring |
| Target 3NF for most production OLTP databases | Over-normalize when performance is critical |
| Use materialized views for read-heavy denormalization | Add redundant columns without sync mechanisms |

> **Final Thought:** Normalization is a *design tool*, not a dogma. Understand the theory deeply so you can make informed decisions about when to apply each level — and when to intentionally break the rules.

---

*← [Third Normal Form (3NF)](./3NF.md)*
