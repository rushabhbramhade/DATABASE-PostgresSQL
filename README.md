<div align="center">

# 🐘 PostgreSQL & Relational Database Learning Repository

### A structured, hands-on path from SQL fundamentals to production-grade PostgreSQL

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-336791?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![SQL](https://img.shields.io/badge/SQL-4169E1?style=for-the-badge)](https://en.wikipedia.org/wiki/SQL)



</div>

## 🗒 Table of Contents

- [About the Repository](#about-the-repository)
- [Learning Objectives](#learning-objectives)
- [Learning Roadmap](#learning-roadmap)
- [Quick Start](#quick-start)
- [Repository Structure](#repository-structure)
- [Real-World Schema Designs](#real-world-schema-designs)
- [Tools and Technologies](#tools-and-technologies)
- [Resources and Further Reading](#resources-and-further-reading)
- [Who This Is For](#who-this-is-for)
- [Progress Tracker](#progress-tracker)
- [Contributing](#contributing)
- [Author](#author)


## 📖 About the Repository

This repository is a **structured, hands-on learning resource** for mastering relational databases, SQL, and PostgreSQL — from complete basics to advanced, production-level concepts.

It started as a way to organize my own learning journey, and grew into a set of practical examples, annotated SQL scripts, and real-world database designs that mirror what you'd actually build in production software.

Whether you're a student, backend developer, data engineer, or AI engineer, this repository gives you a clear, ordered path to strong database fundamentals — backed by runnable code, not just theory.

## 🎯 Learning Objectives

By working through this repository, you'll build a solid, practical understanding of:

- ✅ Core SQL fundamentals and query writing
- ✅ Relational database design principles and ER modeling
- ✅ Entity relationships and cardinality
- ✅ Database normalization, from 1NF to BCNF
- ✅ PostgreSQL-specific features and extensions
- ✅ Query optimization and performance tuning
- ✅ Transaction management and ACID properties
- ✅ Indexing strategies for faster queries
- ✅ Designing production-grade, real-world schemas

## 🧭 Learning Roadmap

Work through the folders in order — each one builds on the concepts from the last.

| Step | Topic | Key Concepts |
|------|-------|---------------|
| 01 | [SQL Fundamentals](./01-SQL-Fundamentals) | SELECT, WHERE, ORDER BY, LIMIT |
| 02 | [Database Design](./02-Database-Design) | ER diagrams, entities, relationships |
| 03 | [DDL Commands](./03-DDL-Commands) | CREATE, ALTER, DROP, TRUNCATE |
| 04 | [DML Commands](./04-DML-Commands) | INSERT, UPDATE, DELETE |
| 05 | [Filtering & Sorting](./05-Filtering-and-Sorting) | LIKE, IN, BETWEEN, ORDER BY |
| 06 | [Aggregations](./06-Aggregations) | COUNT, SUM, AVG, GROUP BY, HAVING |
| 07 | [Joins](./07-Joins) | INNER, LEFT, RIGHT, FULL, SELF joins |
| 08 | [Subqueries](./08-Subqueries) | Basic, correlated, nested queries |
| 09 | [Normalization](./09-Normalization) | 1NF, 2NF, 3NF, BCNF |
| 10 | [Indexing](./10-Indexes) | Single-column, composite, performance examples |
| 11 | [Constraints](./11-Constraints) | PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK |
| 12 | [Transactions](./12-Transactions) | BEGIN, COMMIT, ROLLBACK, ACID |
| 13 | [Views & CTEs](./13-Views-and-CTEs) | Views, materialized views, CTEs |
| 14 | [PostgreSQL Advanced](./14-PostgreSQL-Advanced) | JSONB, window functions, triggers, stored procedures |
| 15 | [Database Optimization](./15-Database-Optimization) | EXPLAIN, query optimization, performance tips |
| 16 | [Real-World Schemas](./16-Real-World-Schemas) | E-commerce, Hospital, Social Media, AI SaaS |
| 17 | [Interview Preparation](./17-Interview-Preparation) | SQL & PostgreSQL interview questions, system design |

## ⚡ Quick Start

This repo just needs PostgreSQL itself — every example is run with `psql`, PostgreSQL's built-in command-line client.

**1. Clone the repository**

```bash
git clone https://github.com/rushabhbramhade/DATABASE-PostgresSQL.git
cd DATABASE-PostgresSQL
```

**2. Connect with psql**

```bash
psql -U postgres
```

**3. Run any script in the repo**

```bash
psql -U postgres -d postgres -f 01-SQL-Fundamentals/SELECT.sql
```

Don't have PostgreSQL installed yet? Grab it from the [official downloads page](https://www.postgresql.org/download/).

## 🗂 Repository Structure

```
DATABASE-PostgresSQL/
│
├── README.md                          # This file
├── .gitignore
│
├── 01-SQL-Fundamentals/               # Start here — SQL basics
│   ├── SELECT.sql
│   ├── WHERE.sql
│   ├── ORDER_BY.sql
│   ├── LIMIT.sql
│   └── NOTES.md
│
├── 02-Database-Design/                # Designing databases
│   ├── ERD.md
│   ├── Entities.md
│   ├── Relationships.md
│   └── Constraints.md
│
├── 03-DDL-Commands/                    # Data Definition Language
│   ├── CREATE.sql
│   ├── ALTER.sql
│   ├── DROP.sql
│   └── TRUNCATE.sql
│
├── 04-DML-Commands/                    # Data Manipulation Language
│   ├── INSERT.sql
│   ├── UPDATE.sql
│   ├── DELETE.sql
│   └── NOTES.md
│
├── 05-Filtering-and-Sorting/           # Advanced filtering & sorting
│   ├── WHERE.sql
│   ├── LIKE.sql
│   ├── IN.sql
│   ├── BETWEEN.sql
│   └── ORDER_BY.sql
│
├── 06-Aggregations/                    # Aggregating data
│   ├── COUNT.sql
│   ├── SUM.sql
│   ├── AVG.sql
│   ├── MIN_MAX.sql
│   └── GROUP_BY.sql
│
├── 07-Joins/                           # Combining tables
│   ├── INNER_JOIN.sql
│   ├── LEFT_JOIN.sql
│   ├── RIGHT_JOIN.sql
│   ├── FULL_JOIN.sql
│   └── SELF_JOIN.sql
│
├── 08-Subqueries/                      # Subqueries & nested queries
│   ├── Basic_Subqueries.sql
│   ├── Correlated_Subqueries.sql
│   └── Nested_Queries.sql
│
├── 09-Normalization/                   # Normalization principles
│   ├── 1NF.md
│   ├── 2NF.md
│   ├── 3NF.md
│   └── BCNF.md
│
├── 10-Indexes/                         # Indexing for performance
│   ├── Basic_Indexes.sql
│   ├── Composite_Indexes.sql
│   └── Performance_Examples.sql
│
├── 11-Constraints/                     # Database constraints
│   ├── PRIMARY_KEY.sql
│   ├── FOREIGN_KEY.sql
│   ├── UNIQUE.sql
│   ├── CHECK.sql
│   └── NOT_NULL.sql
│
├── 12-Transactions/                     # Transaction management
│   ├── BEGIN.sql
│   ├── COMMIT.sql
│   ├── ROLLBACK.sql
│   └── ACID.md
│
├── 13-Views-and-CTEs/                  # Views & Common Table Expressions
│   ├── Views.sql
│   ├── Materialized_Views.sql
│   └── CTEs.sql
│
├── 14-PostgreSQL-Advanced/             # Advanced PostgreSQL features
│   ├── JSONB.sql
│   ├── Window_Functions.sql
│   ├── Stored_Procedures.sql
│   └── Triggers.sql
│
├── 15-Database-Optimization/           # Optimization & tuning
│   ├── Query_Optimization.md
│   ├── EXPLAIN.sql
│   └── Performance_Tips.md
│
├── 16-Real-World-Schemas/              # Production-ready schema designs
│   ├── Ecommerce/
│   │   ├── schema.sql
│   │   └── README.md
│   ├── Hospital/
│   │   ├── schema.sql
│   │   └── README.md
│   ├── Social-Media/
│   │   ├── schema.sql
│   │   └── README.md
│   └── AI-SaaS/
│       ├── schema.sql
│       └── README.md
│
├── 17-Interview-Preparation/           # Interview prep resources
│   ├── SQL_Interview_Questions.md
│   ├── PostgreSQL_Interview_Questions.md
│   └── Database_System_Design.md
│
└── Resources/                          # Additional learning resources
    ├── Cheatsheet.md
    ├── PostgreSQL_Commands.md
    └── Useful_Links.md
```

## 🏗 Real-World Schema Designs

Production-ready, fully commented PostgreSQL schemas for common real-world systems:

- **[E-Commerce System](./16-Real-World-Schemas/Ecommerce)** — customers, products, orders, payments, and inventory
- **[Hospital Management System](./16-Real-World-Schemas/Hospital)** — patients, doctors, appointments, medical records
- **[Social Media Platform](./16-Real-World-Schemas/Social-Media)** — users, posts, comments, likes, followers
- **[AI SaaS Application](./16-Real-World-Schemas/AI-SaaS)** — users, API keys, model runs, billing

Each folder contains a `schema.sql` you can run directly, plus a `README.md` walking through the design decisions.

## 🧰 Tools and Technologies

| Tool | Why it's here |
|---|---|
| [PostgreSQL](https://www.postgresql.org/) | The database every script in this repo is written for and tested against |
| [psql](https://www.postgresql.org/docs/current/app-psql.html) | PostgreSQL's built-in command-line client, used to run all the scripts |

## 📚 Resources and Further Reading

**Books**
- [SQL Antipatterns: Avoiding the Pitfalls of Database Programming](https://pragprog.com/titles/bksqla/sql-antipatterns/) — Bill Karwin
- [Database System Concepts](https://www.db-book.com/) — Abraham Silberschatz, Henry F. Korth, S. Sudarshan
- [PostgreSQL: Up and Running](https://www.oreilly.com/library/view/postgresql-up-and/9781491963401/) — Regina O. Obe & Leo S. Hsu

**Official Documentation**
- [PostgreSQL Official Documentation](https://www.postgresql.org/docs/)

**Courses**
- [SQL for Data Analysis — Udacity](https://www.udacity.com/course/sql-for-data-analysis--ud198)
- [PostgreSQL for Everybody — Coursera (University of Michigan)](https://www.coursera.org/specializations/postgresql-for-everybody)

## 🎓 Who This Is For

- 🎓 **Students** learning databases and SQL for the first time
- 🚀 **Backend developers** strengthening their database fundamentals
- 📊 **Data engineers** working with PostgreSQL and ETL pipelines
- 🤖 **AI engineers** building applications that store and retrieve data
- 💻 **Software engineers** preparing for interviews and system design rounds

## ✅ Progress Tracker

A simple way to track your own progress through the roadmap:

- [x] SQL Fundamentals
- [ ] Database Design
- [ ] DDL Commands
- [ ] DML Commands
- [ ] Filtering & Sorting
- [ ] Aggregations
- [ ] Joins
- [ ] Subqueries
- [ ] Normalization
- [ ] Indexing
- [ ] Constraints
- [ ] Transactions
- [ ] Views & CTEs
- [ ] PostgreSQL Advanced Features
- [ ] Database Optimization
- [ ] Real-World Schemas
- [ ] Interview Preparation

## 🤝 Contributing

Contributions are welcome and encouraged:

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/AmazingFeature`
3. Commit your changes: `git commit -m 'Add some AmazingFeature'`
4. Push to the branch: `git push origin feature/AmazingFeature`
5. Open a Pull Request

Found a bug, or have a suggestion? Feel free to open an issue.

## 👨‍💻 Author

**Rushabh Bramhade**

[![GitHub](https://img.shields.io/badge/GitHub-rushabhbramhade-181717?style=flat-square&logo=github&logoColor=white)](https://github.com/rushabhbramhade)
