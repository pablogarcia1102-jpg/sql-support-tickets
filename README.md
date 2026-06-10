# Support Engineer - SQL Investigations & Data Quality

## Overview
This repository simulates a Tier-1/Tier-2 Technical Support and Data Operations environment. It contains practical investigations and data quality audits executed directly on a relational database (PostgreSQL) to resolve mock internal escalation tickets.

The focus of these queries is to demonstrate the ability to investigate technical issues, validate system behavior, and ensure accurate resolution of reported product and data issues using advanced SQL.

## Tech Stack & Tools
* **Database:** PostgreSQL (Hosted on Remote Linux VPS)
* **Techniques:** CTEs (Common Table Expressions), Complex JOINs, Conditional Logic (`CASE WHEN`), Null Handling (`COALESCE`), Data Aggregation.

## Resolved Tickets

### 🎟️ Ticket #1001: Order Status & History Investigation
* **Scenario:** The Customer Experience Team escalated a customer request for a complete breakdown of their order history and the representatives assigned to each case.
* **Technical Action:** Developed a query joining the `orders`, `customers`, and `employees` tables. Implemented `COALESCE` to handle `NULL` values for automated self-service orders, ensuring clean data output for the frontend team.

### 🎟️ Ticket #1002: Inventory Data Quality Audit
* **Scenario:** The Operations Manager suspected a mismatch between physically registered stock and the system-calculated remaining stock based on sales data.
* **Technical Action:** Built a data validation query using a **CTE** to aggregate all historically sold units (excluding canceled orders to ensure data integrity). Crossed this aggregated data with current inventory levels using conditional logic (`CASE WHEN`) to automatically flag items as 'HEALTHY', 'WARNING: LOW STOCK', or 'CRITICAL: OUT OF STOCK'.

---
*Note: Database schema and mock data generation scripts are included in the `/database_setup` directory.*