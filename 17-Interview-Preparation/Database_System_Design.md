# 🏗️ Database System Design — Interview Guide

> A practical guide to designing database schemas in interviews, common system design scenarios, scaling strategies, and database selection criteria.

---

## 📑 Table of Contents

- [Step-by-Step Schema Design Approach](#step-by-step-schema-design-approach)
- [Common System Design Scenarios](#common-system-design-scenarios)
  - [E-Commerce Platform](#1-e-commerce-platform)
  - [Social Media Platform](#2-social-media-platform)
  - [Chat Application](#3-chat-application)
  - [URL Shortener](#4-url-shortener)
- [Scaling Databases](#scaling-databases)
- [CAP Theorem](#cap-theorem)
- [OLTP vs OLAP](#oltp-vs-olap)
- [Database Selection Criteria](#database-selection-criteria)
- [Tips for Database Interviews](#tips-for-database-interviews)

---

## Step-by-Step Schema Design Approach

When asked to design a database in an interview, follow this structured process:

### Step 1 — Gather Requirements

Ask clarifying questions before writing anything:

- What are the **core features**? (e.g., users can post, comment, like)
- What is the **read/write ratio**? (read-heavy → optimize reads)
- What is the **expected scale**? (thousands vs millions of users)
- Are there **consistency requirements**? (financial data needs strong consistency)
- What **queries** will be most frequent?

### Step 2 — Identify Entities

List the main objects (nouns) in the system:

```
E-Commerce example:
  Users, Products, Categories, Orders, Order_Items, Payments, Reviews, Addresses
```

### Step 3 — Define Relationships

Map how entities relate to each other:

| Relationship     | Example                                |
|------------------|----------------------------------------|
| One-to-One       | User → Profile                         |
| One-to-Many      | User → Orders                          |
| Many-to-Many     | Products ↔ Categories (via junction table) |

### Step 4 — Design the Schema

Create tables with appropriate columns, data types, and constraints:

```sql
CREATE TABLE users (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email       VARCHAR(255) UNIQUE NOT NULL,
    username    VARCHAR(50) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE orders (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     BIGINT NOT NULL REFERENCES users(id),
    status      VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending','confirmed','shipped','delivered','cancelled')),
    total_amount NUMERIC(12,2) NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);
```

### Step 5 — Normalize (then selectively denormalize)

- Apply **3NF** (Third Normal Form) to eliminate redundancy
- Then **denormalize strategically** for performance-critical read paths

| Normal Form | Goal                                | Action                        |
|-------------|-------------------------------------|-------------------------------|
| 1NF         | Atomic values                       | No arrays in cells            |
| 2NF         | No partial dependencies             | Full PK dependency            |
| 3NF         | No transitive dependencies          | No derived/indirect data      |
| Denormalize | Faster reads in specific scenarios  | Add calculated/duplicate cols |

### Step 6 — Add Indexes

Index columns used in `WHERE`, `JOIN`, `ORDER BY`, and `GROUP BY`:

```sql
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
-- Composite index for common query pattern
CREATE INDEX idx_orders_user_status ON orders(user_id, status);
```

### Step 7 — Consider Edge Cases

- **Soft deletes**: Use `deleted_at TIMESTAMPTZ` instead of actual `DELETE`
- **Audit trails**: Add `created_at`, `updated_at`, `created_by` columns
- **Enums vs lookup tables**: Small fixed sets → `CHECK` constraints; larger sets → lookup tables
- **UUIDs vs auto-increment**: UUIDs for distributed systems; auto-increment for simplicity

---

## Common System Design Scenarios

### 1. E-Commerce Platform

**Core entities**: Users, Products, Categories, Cart, Orders, Order_Items, Payments, Reviews, Addresses

```
┌──────────┐    ┌──────────────┐    ┌────────────┐
│  users   │───▶│   orders     │───▶│order_items │
└──────────┘    └──────────────┘    └────────────┘
                       │                   │
                       ▼                   ▼
                ┌──────────────┐    ┌────────────┐
                │  payments    │    │  products  │
                └──────────────┘    └────────────┘
                                          │
                                          ▼
                                   ┌────────────┐
                                   │ categories │
                                   └────────────┘
```

```sql
CREATE TABLE products (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(255) NOT NULL,
    description TEXT,
    price       NUMERIC(10,2) NOT NULL,
    stock_qty   INT NOT NULL DEFAULT 0,
    category_id BIGINT REFERENCES categories(id),
    is_active   BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE order_items (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id    BIGINT NOT NULL REFERENCES orders(id),
    product_id  BIGINT NOT NULL REFERENCES products(id),
    quantity    INT NOT NULL CHECK (quantity > 0),
    unit_price  NUMERIC(10,2) NOT NULL  -- snapshot price at time of order
);
```

**Key design decisions**:
- Store `unit_price` in `order_items` (price snapshot, not a reference to current price)
- Use `stock_qty` with `CHECK (stock_qty >= 0)` to prevent overselling
- Separate `addresses` table (users can have multiple addresses)
- `payments` table with status tracking for payment lifecycle

---

### 2. Social Media Platform

**Core entities**: Users, Posts, Comments, Likes, Followers, Media, Hashtags

```sql
CREATE TABLE posts (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     BIGINT NOT NULL REFERENCES users(id),
    content     TEXT,
    media_urls  TEXT[],            -- PostgreSQL array for multiple media
    visibility  VARCHAR(20) DEFAULT 'public',
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Many-to-Many: followers
CREATE TABLE follows (
    follower_id  BIGINT REFERENCES users(id),
    following_id BIGINT REFERENCES users(id),
    created_at   TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (follower_id, following_id),
    CHECK (follower_id != following_id)  -- can't follow yourself
);

-- Polymorphic likes (can like posts or comments)
CREATE TABLE likes (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     BIGINT NOT NULL REFERENCES users(id),
    target_type VARCHAR(10) NOT NULL CHECK (target_type IN ('post', 'comment')),
    target_id   BIGINT NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, target_type, target_id)  -- one like per user per target
);
```

**Scaling considerations**:
- **Feed generation**: Fan-out on write (precompute feeds) vs fan-out on read (compute on query)
- **Like counts**: Denormalize `like_count` on posts table, update asynchronously
- **Follower counts**: Cache in `users` table, update with triggers or background jobs

---

### 3. Chat Application

**Core entities**: Users, Conversations, Participants, Messages, Read_Receipts

```sql
CREATE TABLE conversations (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    type        VARCHAR(10) NOT NULL CHECK (type IN ('direct', 'group')),
    name        VARCHAR(100),         -- NULL for direct messages
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE participants (
    conversation_id BIGINT REFERENCES conversations(id),
    user_id         BIGINT REFERENCES users(id),
    joined_at       TIMESTAMPTZ DEFAULT NOW(),
    role            VARCHAR(10) DEFAULT 'member',
    PRIMARY KEY (conversation_id, user_id)
);

CREATE TABLE messages (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    conversation_id BIGINT NOT NULL REFERENCES conversations(id),
    sender_id       BIGINT NOT NULL REFERENCES users(id),
    content         TEXT,
    message_type    VARCHAR(10) DEFAULT 'text',  -- text, image, file
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fetching latest messages in a conversation
CREATE INDEX idx_messages_conv_time ON messages(conversation_id, created_at DESC);
```

**Key design decisions**:
- Partition `messages` by `conversation_id` or `created_at` for scalability
- Use WebSockets for real-time delivery (not a DB concern, but mention it)
- Store read receipts separately with `(user_id, conversation_id, last_read_message_id)`

---

### 4. URL Shortener

**Core entities**: URLs, Clicks/Analytics, Users (optional)

```sql
CREATE TABLE short_urls (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    short_code  VARCHAR(10) UNIQUE NOT NULL,
    original_url TEXT NOT NULL,
    user_id     BIGINT REFERENCES users(id),    -- optional: who created it
    expires_at  TIMESTAMPTZ,
    click_count BIGINT DEFAULT 0,               -- denormalized for fast reads
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_short_code ON short_urls(short_code);

CREATE TABLE click_events (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    short_url_id BIGINT NOT NULL REFERENCES short_urls(id),
    ip_address  INET,
    user_agent  TEXT,
    referer     TEXT,
    country     VARCHAR(2),
    clicked_at  TIMESTAMPTZ DEFAULT NOW()
);
```

**Key design decisions**:
- `short_code` generation: Base62 encoding of an auto-increment ID, or pre-generated random codes
- `click_count` denormalized for fast display; `click_events` for detailed analytics
- Partition `click_events` by month for efficient querying and cleanup
- Use **Redis** for caching hot redirects (most URLs follow a power-law distribution)

---

## Scaling Databases

### Vertical vs Horizontal Scaling

| Strategy             | Description                         | Pros                    | Cons                        |
|----------------------|-------------------------------------|-------------------------|-----------------------------|
| **Vertical (Scale Up)** | Bigger server (more CPU, RAM, SSD) | Simple, no code changes | Hardware limits, single point of failure |
| **Horizontal (Scale Out)** | Add more servers             | Near-infinite scale     | Complex, distributed issues |

### Read Replicas

```
                          ┌──────────────────┐
   Writes ──────────────▶ │    PRIMARY       │
                          └────────┬─────────┘
                                   │ WAL Stream
                     ┌─────────────┼─────────────┐
                     ▼             ▼              ▼
              ┌──────────┐  ┌──────────┐   ┌──────────┐
   Reads ───▶ │ Replica 1│  │ Replica 2│   │ Replica 3│
              └──────────┘  └──────────┘   └──────────┘
```

- Route all **writes** to the primary
- Route **reads** to replicas (load balancing)
- Watch for **replication lag** — replicas may be slightly behind

### Sharding (Horizontal Partitioning)

Distributes data across multiple database servers based on a **shard key**.

| Strategy            | How it works                           | Example                    |
|---------------------|----------------------------------------|----------------------------|
| **Range-based**     | Shard by value ranges                  | Users 1–1M → Shard A      |
| **Hash-based**      | Hash the shard key, mod by shard count | `hash(user_id) % 4`       |
| **Directory-based** | Lookup table maps keys to shards       | Flexible but adds latency  |

**Challenges**: Cross-shard queries, rebalancing, distributed transactions, joins across shards.

### Table Partitioning (within a single database)

```sql
-- Partition by range (monthly)
CREATE TABLE events (
    id BIGINT,
    event_date DATE,
    data JSONB
) PARTITION BY RANGE (event_date);

CREATE TABLE events_2025_01 PARTITION OF events
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
```

### Caching Layer

```
Client → Cache (Redis/Memcached) → Database
```

| Pattern              | Description                                      |
|----------------------|--------------------------------------------------|
| **Cache-Aside**      | App checks cache first, loads from DB on miss    |
| **Write-Through**    | Write to cache and DB simultaneously             |
| **Write-Behind**     | Write to cache, async write to DB                |
| **Read-Through**     | Cache automatically loads from DB on miss        |

**What to cache**: Session data, user profiles, product listings, feed data, frequently accessed configs.

---

## CAP Theorem

The CAP theorem states that a distributed system can guarantee at most **two out of three** properties:

```
         Consistency
            /\
           /  \
          /    \
         /  CA  \         ← Traditional RDBMS (PostgreSQL, MySQL)
        /________\
       /          \
      / CP      AP \
     /              \
    Partition       Availability
    Tolerance
```

| Property              | Meaning                                                  |
|-----------------------|----------------------------------------------------------|
| **Consistency (C)**   | Every read receives the most recent write                |
| **Availability (A)** | Every request receives a response (even if not latest)   |
| **Partition Tolerance (P)** | System continues despite network failures          |

**In practice** (since network partitions are inevitable):
- **CP systems**: Favor consistency → PostgreSQL, MongoDB, HBase, Redis
- **AP systems**: Favor availability → Cassandra, DynamoDB, CouchDB

> PostgreSQL is a single-node CP system. With replication, you choose between synchronous (CP) and asynchronous (AP-leaning) replication.

---

## OLTP vs OLAP

| Feature           | OLTP                              | OLAP                                |
|-------------------|-----------------------------------|-------------------------------------|
| **Purpose**       | Day-to-day transactions           | Analytics and reporting             |
| **Queries**       | Simple, frequent (INSERT/UPDATE)  | Complex, aggregation-heavy          |
| **Data**          | Current, operational              | Historical, large datasets          |
| **Normalization** | Highly normalized (3NF)           | Denormalized (star/snowflake schema)|
| **Response time** | Milliseconds                      | Seconds to minutes                  |
| **Users**         | Many concurrent users             | Few analysts                        |
| **Examples**      | PostgreSQL, MySQL, Oracle         | Amazon Redshift, BigQuery, Snowflake|

```
OLTP Database (PostgreSQL)  ───ETL Pipeline──▶  OLAP Data Warehouse (Redshift)
   (real-time operations)                          (analytics & dashboards)
```

### Star Schema (OLAP)

```
            ┌──────────────┐
            │  dim_product │
            └──────┬───────┘
                   │
┌──────────┐  ┌────┴───────┐  ┌──────────────┐
│ dim_time │──│ fact_sales  │──│ dim_customer │
└──────────┘  └────┬───────┘  └──────────────┘
                   │
            ┌──────┴───────┐
            │  dim_store   │
            └──────────────┘
```

---

## Database Selection Criteria

### When to Use Which Database

| Database        | Type         | Best For                                              |
|-----------------|--------------|-------------------------------------------------------|
| **PostgreSQL**  | Relational   | Complex queries, ACID, JSONB, general purpose         |
| **MySQL**       | Relational   | Simple web apps, WordPress, high-read workloads       |
| **MongoDB**     | Document     | Flexible schema, rapid prototyping, nested data       |
| **Redis**       | Key-Value    | Caching, sessions, real-time leaderboards, queues     |
| **Cassandra**   | Wide-Column  | Time-series, IoT, write-heavy at massive scale        |
| **Elasticsearch** | Search     | Full-text search, log analytics, auto-complete        |
| **Neo4j**       | Graph        | Social networks, recommendation engines, fraud detection |
| **DynamoDB**    | Key-Value    | Serverless, predictable low-latency at scale          |
| **ClickHouse**  | Columnar     | Real-time analytics on large datasets                 |
| **TimescaleDB** | Time-Series  | IoT, metrics, time-series (PostgreSQL extension)      |

### Decision Framework

Ask these questions when choosing a database:

```
1. Is data relational with complex JOINs?    → PostgreSQL / MySQL
2. Is schema unpredictable or changing?       → MongoDB
3. Need sub-millisecond reads?                → Redis
4. Write-heavy, time-series workload?         → Cassandra / TimescaleDB
5. Need full-text search?                     → Elasticsearch (+ PostgreSQL)
6. Graph relationships are core?              → Neo4j
7. Need ACID transactions?                    → PostgreSQL / MySQL
8. Global scale with managed infra?           → DynamoDB / Cloud Spanner
```

**Polyglot persistence**: Most real-world systems use **multiple databases**, each for what it does best.

---

## Tips for Database Interviews

### Before the Interview

1. **Practice ER diagrams** — draw them quickly on a whiteboard or paper
2. **Know normalization** — be able to explain 1NF through BCNF
3. **Understand indexing** — when to add, when to avoid
4. **Study common patterns** — e-commerce, social media, messaging

### During the Interview

1. **Start with requirements** — always ask clarifying questions first
2. **Think out loud** — explain your reasoning as you design
3. **Draw the ER diagram** — visualize entities and relationships
4. **Start normalized, then denormalize** — show you understand both
5. **Discuss trade-offs** — every decision has pros and cons
6. **Consider scale** — mention partitioning, caching, replicas
7. **Mention indexes** — show you think about query performance
8. **Address edge cases** — soft deletes, concurrent updates, data consistency

### Common Mistakes to Avoid

| Mistake                                | Better Approach                           |
|----------------------------------------|-------------------------------------------|
| Jumping into schema without requirements | Ask questions first                      |
| Over-normalizing everything            | Denormalize for critical read paths       |
| Ignoring indexes                       | Index columns in WHERE, JOIN, ORDER BY    |
| Not considering scale                  | Discuss scaling strategy, even briefly    |
| Using only one database for everything | Mention polyglot persistence              |
| Storing derived data without reason    | Justify denormalization with read patterns|
| Forgetting timestamps                  | Add `created_at`, `updated_at` to all tables |
| Not discussing data types              | Choose appropriate types (BIGINT vs INT, TIMESTAMPTZ vs TIMESTAMP) |

---

*Design with intention, scale with strategy! 🏗️*
