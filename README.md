# PostgreSQL & Relational Database Learning Repository

<div align="center">
  <img src="https://coresg-normal.trae.ai/api/ide/v1/text-to-image?prompt=Modern%20PostgreSQL%20database%20logo%20with%20relational%20tables%20and%20connections%20in%20clean%20professional%20design&image_size=square_hd" alt="PostgreSQL Database" width="200" height="200">
</div>

<div align="center">

![GitHub last commit](https://img.shields.io/github/last-commit/rushabhbramhade/DATABASE-PostgresSQL)
![GitHub repo size](https://img.shields.io/github/repo-size/rushabhbramhade/DATABASE-PostgresSQL)
![GitHub stars](https://img.shields.io/github/stars/rushabhbramhade/DATABASE-PostgresSQL?style=social)
![GitHub forks](https://img.shields.io/github/forks/rushabhbramhade/DATABASE-PostgresSQL?style=social)

</div>

---

## 📖 About This Repository

This repository is a **structured, hands-on learning resource** designed to help you master relational databases, SQL, and PostgreSQL from complete basics to advanced production-level concepts.

I created this repository to organize my own learning journey and share practical examples, code snippets, and real-world database designs that are applicable to modern software development.

Whether you're a student, backend developer, data engineer, or AI engineer, this repository provides a clear roadmap to build strong database fundamentals and practical skills.

---

## 🎯 Learning Objectives

By working through this repository, you will gain a deep understanding of:

- ✅ Core SQL fundamentals and query writing
- ✅ Relational database design principles and ER modeling
- ✅ Entity relationships and cardinality
- ✅ Database normalization from 1NF to BCNF
- ✅ PostgreSQL-specific features and extensions
- ✅ Query optimization and performance tuning
- ✅ Transaction management and ACID properties
- ✅ Indexing strategies for better performance
- ✅ Designing production-grade real-world schemas

---

## 🛣️ Learning Roadmap

Follow this structured path to progress from beginner to advanced:

| Step | Topic | Key Concepts |
|------|-------|--------------|
| 01 | **SQL Fundamentals** | SELECT, WHERE, ORDER BY, LIMIT |
| 02 | **Database Design** | ER Diagrams, Entities, Relationships |
| 03 | **DDL Commands** | CREATE, ALTER, DROP, TRUNCATE |
| 04 | **DML Commands** | INSERT, UPDATE, DELETE |
| 05 | **Filtering & Sorting** | LIKE, IN, BETWEEN, ORDER BY |
| 06 | **Aggregations** | COUNT, SUM, AVG, GROUP BY, HAVING |
| 07 | **Joins** | INNER, LEFT, RIGHT, FULL, SELF JOINs |
| 08 | **Subqueries** | Basic, Correlated, Nested Queries |
| 09 | **Normalization** | 1NF, 2NF, 3NF, BCNF |
| 10 | **Constraints** | PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK |
| 11 | **Indexing** | Basic, Composite, Performance Examples |
| 12 | **Transactions** | BEGIN, COMMIT, ROLLBACK, ACID |
| 13 | **Views & CTEs** | Views, Materialized Views, CTEs |
| 14 | **PostgreSQL Advanced** | JSONB, Window Functions, Triggers, Stored Procedures |
| 15 | **Database Optimization** | EXPLAIN, Query Optimization, Performance Tips |
| 16 | **Real World Schemas** | E-commerce, Hospital, Social Media, AI SaaS |
| 17 | **Interview Preparation** | SQL & PostgreSQL Interview Questions, System Design |

---

## 📂 Repository Structure

```
DATABASE-PostgreSQL/
│
├── README.md                          # This file - your guide!
├── .gitignore                         # Git ignore rules
│
├── 01-SQL-Fundamentals/               # Start here - SQL basics
│   ├── SELECT.sql                     # SELECT queries
│   ├── WHERE.sql                      # Filtering with WHERE
│   ├── ORDER_BY.sql                   # Sorting results
│   ├── LIMIT.sql                      # Limiting results
│   └── NOTES.md                       # Fundamentals notes
│
├── 02-Database-Design/                # Designing databases
│   ├── ERD.md                         # Entity-Relationship Diagrams
│   ├── Entities.md                    # Database entities
│   ├── Relationships.md               # One-to-one, one-to-many, many-to-many
│   └── Constraints.md                 # Database constraints
│
├── 03-DDL-Commands/                   # Data Definition Language
│   ├── CREATE.sql                     # Creating tables & databases
│   ├── ALTER.sql                      # Modifying schema
│   ├── DROP.sql                       # Deleting objects
│   └── TRUNCATE.sql                   # Removing all data
│
├── 04-DML-Commands/                   # Data Manipulation Language
│   ├── INSERT.sql                     # Adding data
│   ├── UPDATE.sql                     # Modifying existing data
│   ├── DELETE.sql                     # Removing data
│   └── NOTES.md                       # DML notes
│
├── 05-Filtering-and-Sorting/          # Advanced filtering & sorting
│   ├── WHERE.sql                      # Complex WHERE clauses
│   ├── LIKE.sql                       # Pattern matching
│   ├── IN.sql                         # IN operator
│   ├── BETWEEN.sql                    # Range queries
│   └── ORDER_BY.sql                   # Multi-column sorting
│
├── 06-Aggregations/                   # Aggregating data
│   ├── COUNT.sql                      # Counting records
│   ├── SUM.sql                        # Summing values
│   ├── AVG.sql                        # Averaging values
│   ├── MIN_MAX.sql                    # Min & max values
│   └── GROUP_BY.sql                   # Grouping aggregations
│
├── 07-Joins/                          # Combining tables
│   ├── INNER_JOIN.sql                 # Inner joins
│   ├── LEFT_JOIN.sql                  # Left joins
│   ├── RIGHT_JOIN.sql                 # Right joins
│   ├── FULL_JOIN.sql                  # Full outer joins
│   └── SELF_JOIN.sql                  # Self joins
│
├── 08-Subqueries/                     # Subqueries & nested queries
│   ├── Basic_Subqueries.sql           # Basic subqueries
│   ├── Correlated_Subqueries.sql      # Correlated subqueries
│   └── Nested_Queries.sql             # Nested queries
│
├── 09-Normalization/                  # Normalization principles
│   ├── 1NF.md                         # First Normal Form
│   ├── 2NF.md                         # Second Normal Form
│   ├── 3NF.md                         # Third Normal Form
│   └── BCNF.md                        # Boyce-Codd Normal Form
│
├── 10-Indexes/                        # Indexing for performance
│   ├── Basic_Indexes.sql              # Single-column indexes
│   ├── Composite_Indexes.sql          # Multi-column indexes
│   └── Performance_Examples.sql       # Performance examples
│
├── 11-Constraints/                    # Database constraints
│   ├── PRIMARY_KEY.sql                # Primary keys
│   ├── FOREIGN_KEY.sql                # Foreign keys
│   ├── UNIQUE.sql                     # Unique constraints
│   ├── CHECK.sql                      # Check constraints
│   └── NOT_NULL.sql                   # Not null constraints
│
├── 12-Transactions/                   # Transaction management
│   ├── BEGIN.sql                      # Starting transactions
│   ├── COMMIT.sql                     # Committing changes
│   ├── ROLLBACK.sql                   # Rolling back changes
│   └── ACID.md                        # ACID properties explained
│
├── 13-Views-and-CTEs/                 # Views & Common Table Expressions
│   ├── Views.sql                      # Creating & using views
│   ├── Materialized_Views.sql         # Materialized views
│   └── CTEs.sql                       # Common Table Expressions
│
├── 14-PostgreSQL-Advanced/            # Advanced PostgreSQL features
│   ├── JSONB.sql                      # JSONB data type & queries
│   ├── Window_Functions.sql           # Window functions (ROW_NUMBER, RANK, etc.)
│   ├── Stored_Procedures.sql          # Stored procedures
│   └── Triggers.sql                   # Database triggers
│
├── 15-Database-Optimization/          # Optimization & tuning
│   ├── Query_Optimization.md          # Query optimization techniques
│   ├── EXPLAIN.sql                    # Using EXPLAIN to analyze queries
│   └── Performance_Tips.md            # Performance tuning tips
│
├── 16-Real-World-Schemas/             # Production-ready schema designs
│   ├── Ecommerce/                     # E-commerce system schema
│   │   ├── schema.sql                 # E-commerce database schema
│   │   └── README.md                  # E-commerce schema documentation
│   │
│   ├── Hospital/                      # Hospital management system
│   │   ├── schema.sql                 # Hospital database schema
│   │   └── README.md                  # Hospital schema documentation
│   │
│   ├── Social-Media/                  # Social media platform
│   │   ├── schema.sql                 # Social media database schema
│   │   └── README.md                  # Social media schema documentation
│   │
│   └── AI-SaaS/                       # AI SaaS application
│       ├── schema.sql                 # AI SaaS database schema
│       └── README.md                  # AI SaaS schema documentation
│
├── 17-Interview-Preparation/          # Interview prep resources
│   ├── SQL_Interview_Questions.md     # Common SQL interview questions
│   ├── PostgreSQL_Interview_Questions.md  # PostgreSQL-specific questions
│   └── Database_System_Design.md      # Database system design concepts
│
└── Resources/                         # Additional learning resources
    ├── Cheatsheet.md                  # SQL & PostgreSQL cheat sheet
    ├── PostgreSQL_Commands.md         # Useful PostgreSQL commands
    └── Useful_Links.md                # Links to books, docs, and courses
```

---

## 📚 Topics Covered

### SQL Fundamentals
- SELECT statements and retrieving data
- Filtering results with WHERE clauses
- Sorting query results with ORDER BY
- Limiting and paginating results

### Database Design
- Entity-Relationship Diagrams (ERDs)
- Database entities and attributes
- Relationships (one-to-one, one-to-many, many-to-many)
- Constraints (primary keys, foreign keys, etc.)

### PostgreSQL Specific Features
- JSONB for semi-structured data
- Window Functions (ROW_NUMBER, RANK, DENSE_RANK)
- Views and Materialized Views
- Triggers for automated database actions
- Stored Procedures for complex logic

---

## 🏗️ Real-World Database Designs

This repository includes production-ready database schemas for common real-world applications:

- **E-Commerce System**: Customers, products, orders, payments, and inventory
- **Hospital Management System**: Patients, doctors, appointments, medical records
- **Social Media Platform**: Users, posts, comments, likes, followers
- **AI SaaS Application**: Users, API keys, model runs, billing information

---

## 🛠️ Tools & Technologies

To get the most out of this repository, you should be familiar with or use the following tools:

- **PostgreSQL**: The world's most advanced open source relational database
- **pgAdmin**: The most popular PostgreSQL administration tool
- **SQL**: Standard Query Language for relational databases
- **Docker**: For running PostgreSQL in a containerized environment (optional but recommended)
- **DBeaver**: Multi-platform database administration tool (great alternative to pgAdmin)

---

## 📖 Resources

### Books
- "SQL Antipatterns" by Bill Karwin
- "Database System Concepts" by Abraham Silberschatz, Henry F. Korth, S. Sudarshan
- "PostgreSQL Up and Running" by Regina O. Obe and Leo S. Hsu

### Documentation
- [PostgreSQL Official Documentation](https://www.postgresql.org/docs/)

### Courses
- "SQL for Data Analysis" on Udacity
- "PostgreSQL for Everyone" on Coursera

---

## 🎯 Target Audience

This repository is perfect for:

- 🎓 **Students**: Learning databases and SQL for the first time
- 🚀 **Backend Developers**: Looking to strengthen their database skills
- 📊 **Data Engineers**: Working with PostgreSQL and ETL pipelines
- 🤖 **AI Engineers**: Building applications that use databases for storing and retrieving data
- 💻 **Software Engineers**: Preparing for technical interviews and system design

---

## 🚀 Progress Tracker

Track your learning journey!

- [x] SQL Fundamentals
- [ ] Database Design
- [ ] DDL Commands
- [ ] DML Commands
- [ ] Filtering & Sorting
- [ ] Aggregations
- [ ] Joins
- [ ] Subqueries
- [ ] Normalization
- [ ] Constraints
- [ ] Indexing
- [ ] Transactions
- [ ] Views & CTEs
- [ ] PostgreSQL Advanced Features
- [ ] Database Optimization
- [ ] Real World Schemas
- [ ] Interview Preparation

---

## 🤝 Contributions

Contributions are welcome and encouraged! Here's how you can help:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

Feel free to open issues for suggestions, improvements, or bugs you find!

---

## 📜 License

This project is open-source and available under the MIT License.

---

## 👨‍💻 Author

**Rushabh Bramhade**

- GitHub: [@rushabhbramhade](https://github.com/rushabhbramhade)

---

<div align="center">
Made with ❤️ by Rushabh Bramhade
</div>
