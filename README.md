# Case Study 03: Foodie-Fi

## 1. Project Overview

Foodie-Fi is a subscription-based streaming service focused on food-related content. This project uses PostgreSQL to analyze customer subscription journeys and answer business questions about plan adoption, churn, upgrades, and downgrades.

The analysis follows the questions from the [8 Week SQL Challenge — Case Study #3: Foodie-Fi](https://8weeksqlchallenge.com/case-study-3/).

**Tools:** PostgreSQL, pgAdmin 4, Visual Studio Code  
**SQL concepts:** Aggregations, joins, date functions, CTEs, subqueries, window functions (`LEAD`, `ROW_NUMBER`), and conditional counting.

## Dataset Description & Data Structure

The dataset contains two tables in the `foodie_fi` schema.

### `plans`

Contains the subscription plans available to customers.

| Column | Description |
|---|---|
| `plan_id` | Unique identifier for each plan |
| `plan_name` | Plan name |
| `price` | Subscription price; `NULL` for churn |

| plan_id | plan_name | price |
|---:|---|---:|
| 0 | trial | 0.00 |
| 1 | basic monthly | 9.90 |
| 2 | pro monthly | 19.90 |
| 3 | pro annual | 199.00 |
| 4 | churn | `NULL` |

### `subscriptions`

Records the date on which each customer's subscription plan starts.

| Column | Description |
|---|---|
| `customer_id` | Customer identifier |
| `plan_id` | Subscription plan identifier; references `plans.plan_id` |
| `start_date` | Date the plan starts |

**Relationship:** `plans.plan_id` → `subscriptions.plan_id` (one plan can be associated with many subscription records).

### Important data interpretation

- A customer's first record is generally the 7-day free trial.
- Each subsequent record indicates a plan change and its effective start date.
- `plan_id = 4` represents churn.
- For questions about a customer's plan at a historical date, select the latest subscription record on or before that date.
- The SQL file sets the schema with `SET search_path = foodie_fi;`.

## Analysis & Queries

The SQL solutions are available in [`Analysis Questions.sql`](./Analysis%20Questions.sql). Below are selected examples of the analysis.

### 1. Total number of customers

**Business question:** How many customers has Foodie-Fi ever had?

```sql
SELECT COUNT(DISTINCT customer_id) AS customers_count
FROM subscriptions;
```

**Result:** Add a screenshot from pgAdmin showing the query result.

![Total customers query result](images/q1-total-customers.png)

### 2. Monthly trial sign-ups

**Business question:** How are trial plan start dates distributed by month?

```sql
SELECT
    DATE_TRUNC('month', start_date)::DATE AS month,
    COUNT(*) AS trial_count
FROM subscriptions
WHERE plan_id = 0
GROUP BY DATE_TRUNC('month', start_date)
ORDER BY month;
```

**Result:** Add a screenshot from pgAdmin showing the monthly counts.

![Monthly trial sign-ups query result](images/q2-monthly-trials.png)

### 3. Churn rate

**Business question:** What percentage of customers have churned?

```sql
WITH customer_count AS (
    SELECT
        COUNT(DISTINCT customer_id) AS total_customer,
        COUNT(DISTINCT CASE
            WHEN plan_id = 4 THEN customer_id
        END) AS churned_customer
    FROM subscriptions
)
SELECT
    churned_customer,
    ROUND(churned_customer * 100.0 / total_customer, 1)
        AS churned_percentage
FROM customer_count;
```

**Result:** Add a screenshot from pgAdmin showing the churn count and percentage.

![Churn analysis query result](images/q4-churn-rate.png)

### 4. Customer plan immediately after the free trial

**Business question:** What plan do customers move to after their initial free trial, and what percentage of customers choose each plan?

```sql
WITH cte AS (
    SELECT
        customer_id,
        plan_id,
        LEAD(plan_id) OVER (
            PARTITION BY customer_id
            ORDER BY start_date
        ) AS next_plan_id
    FROM subscriptions
)
SELECT
    c.next_plan_id AS plan_id,
    p.plan_name,
    COUNT(*) AS customer_count,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(DISTINCT customer_id) FROM subscriptions),
        1
    ) AS percentage
FROM cte c
JOIN plans p
    ON c.next_plan_id = p.plan_id
WHERE c.plan_id = 0
GROUP BY c.next_plan_id, p.plan_name
ORDER BY c.next_plan_id;
```

**Result:** Add a screenshot from pgAdmin showing the count and percentage for each next plan.

![Plan after trial query result](images/q6-plans-after-trial.png)

### 5. Subscription plan distribution at 31 December 2020

**Business question:** How many customers were on each plan at the end of 2020?

```sql
WITH ranked_subscriptions AS (
    SELECT
        s.customer_id,
        s.plan_id,
        p.plan_name,
        s.start_date,
        ROW_NUMBER() OVER (
            PARTITION BY s.customer_id
            ORDER BY s.start_date DESC
        ) AS rn
    FROM subscriptions s
    JOIN plans p USING (plan_id)
    WHERE s.start_date < DATE '2021-01-01'
)
SELECT
    plan_name,
    COUNT(*) AS customer_count,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(DISTINCT customer_id) FROM subscriptions),
        1
    ) AS percentage
FROM ranked_subscriptions
WHERE rn = 1
GROUP BY plan_id, plan_name
ORDER BY plan_id;
```

**Result:** Add a screenshot from pgAdmin showing the plan distribution.

![Plan distribution at year end](images/q7-plan-distribution.png)

### 6. Average time to upgrade to an annual plan

**Business question:** How many days does it take on average for customers to move from joining Foodie-Fi to an annual plan?

```sql
WITH cte AS (
    SELECT
        customer_id,
        plan_id,
        start_date,
        MIN(start_date) OVER (
            PARTITION BY customer_id
        ) AS join_date
    FROM subscriptions
)
SELECT
    ROUND(AVG(start_date - join_date)) AS avg_days_to_annual
FROM cte
WHERE plan_id = 3;
```

**Result:** Add a screenshot from pgAdmin showing the average number of days.

![Average days to annual plan](images/q9-average-days-annual.png)

## How to Run

1. Create or connect to the `foodie_fi` database in PostgreSQL.
2. Load the source tables and data using the provided `schema.sql` (if it contains the schema and inserts).
3. Open `Analysis Questions.sql` in pgAdmin 4 or run it through a PostgreSQL client.
4. Execute the queries and review the result sets.
5. Save screenshots of selected query outputs into the `images/` directory using the filenames referenced above.

## Repository Structure

```text
case-03-foodie-fi/
├── Analysis Questions.sql
├── schema.sql
├── README.md
└── images/
    ├── q1-total-customers.png
    ├── q2-monthly-trials.png
    ├── q4-churn-rate.png
    ├── q6-plans-after-trial.png
    ├── q7-plan-distribution.png
    └── q9-average-days-annual.png
```

> **Note:** The image paths above are placeholders. Add your own pgAdmin screenshots with the matching filenames, or update the image links to match your actual filenames.
