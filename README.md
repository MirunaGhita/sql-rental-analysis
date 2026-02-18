## 🏠 NestLoop Rental Analytics Project

![SQL](https://img.shields.io/badge/SQL-Server-blue?style=for-the-badge&logo=Microsoft-SQL-Server)
![Project](https://img.shields.io/badge/Project-pink?style=for-the-badge)

## 📌 Project Overview

This project is modeled after a short-term rental platform. 

The database simulates a real-world rental marketplace with hosts, guests, properties, bookings, and reviews.

## 🔍 Analysis & Queries

  **1) Host Performance Dashboard**

Ranks all hosts by total revenue from completed bookings. Includes their number of listings, average property rating, cancellation rates, and a `Superhost` / `Standard` label.

  **2) Occupancy Rate by Property**

For each property, calculates what percentage of 2024 was booked (completed stays only, out of 365 days). Includes the property title, city, price per night, and average review score. Flags properties relative to the platform average occupancy as `Above Average`, `Below Average`, or `Underperforming`.

  **3) Guest Travel Patterns**

Finds guests who have booked in more than one city. For each, shows every city they've visited, how many times, and their total spend on completed stays. Includes a column showing their single highest-rated stay (property title + rating).

  **4) Monthly Revenue Trend Report**

Breaks down revenue from completed 2024 bookings month by month, grouped by city. Includes total revenue, number of bookings, and a month_over_month_change column showing the revenue difference versus the prior month for the same city.

  **5) Amenity Impact on Ratings**

Determines which amenities correlate with higher guest ratings. For each amenity, calculates the average rating_overall across all reviewed properties that have it and compares it to the platform-wide average. 

---
**Overall Skills Practiced:**
| Skill | Used In |
|---|---|
| Multi-table JOINs (`LEFT JOIN`, `INNER JOIN`, `CROSS JOIN`) | All tasks |
| Conditional aggregation (`CASE` inside `SUM` / `COUNT`) | Tasks 1, 2 |
| CTEs (`WITH` expressions) | Tasks 2, 3, 4, 5 |
| Window functions (`AVG OVER`, `LAG`, `ROW_NUMBER`) | Tasks 2, 3, 4 |
| Date functions (`DATEDIFF`, `DATEPART`, `DATENAME`, `YEAR`) | Tasks 2, 4 |
| `CAST` and float division | Tasks 1, 2 |
| `NULLIF` for divide-by-zero protection | Task 1 |
| Many-to-many JOIN traversal | Task 5 |
| Subquery filtering with `HAVING` | Task 3 |
| `ROUND` and computed difference columns | Tasks 1, 2, 5 |
| `ORDER BY` with column aliases | All tasks |
---

## 🗂️ Database Structure

The database contains **7 tables**:

```
hosts
 └── properties
      ├── property_amenities ──── amenities
      └── bookings
           ├── reviews
           └── (guest_id) ──────── guests
```
### Table Descriptions:

**`hosts`** — People who list properties on the platform. Tracks whether they hold Superhost status, their response rate, and when they joined.

**`guests`** — People who make bookings. Includes country of origin and join date.

**`properties`** — Individual listings, linked to a host. Stores property type (Apartment, House, Villa), room type (Entire place, Private room), neighborhood, city, pricing, and capacity.

**`amenities`** — A lookup table of 15 amenities such as WiFi, Pool, Kitchen, and Workspace.

**`property_amenities`** — Many-to-many join table linking properties to their amenities.

**`bookings`** — Reservation records linking a guest to a property. Includes check-in/check-out dates, number of guests, the locked-in price at time of booking, and a status of `confirmed`, `completed`, or `cancelled`. 
Total amount is a **persisted computed column** calculated automatically as `nights × price + cleaning_fee`.

**`reviews`** — Post-stay ratings left by guests, tied to a specific booking. Captures overall rating plus sub-scores for cleanliness, location, and value (all on a 1–5 scale).

## 🛡️ License
This project is licensed under the [MIT License](LICENSE). You are free to use, modify, and share this project with proper attribution.

## 🌟 About Me
Hi there! I am Miruna, an aspiring data analyst with experience in reporting, process optimization and transforming numbers into narratives 📖.

## ☕ Connect:
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/miruna-ghi%C8%9B%C4%83/)
