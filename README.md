# Case Study 03: Foodie-Fi

## 1. Project Overview

Foodie-Fi is a subscription-based streaming service focused on food-related content. This project uses PostgreSQL to analyze customer subscription journeys and answer business questions about plan adoption, churn, upgrades, and downgrades.

**Tools:** PostgreSQL, pgAdmin 4, Visual Studio Code  
**SQL concepts:** Aggregations, joins, date functions, CTEs, subqueries, window functions (`LEAD`, `ROW_NUMBER`), and conditional counting.

## 2. Dataset Description & Data Structure

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

> Source: The analysis follows the questions from the [8 Week SQL Challenge — Case Study #3: Foodie-Fi](https://8weeksqlchallenge.com/case-study-3/).

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

### 4. Churn rate

**Business question:** What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

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

<img width="350" height="93" alt="image" src="https://github.com/user-attachments/assets/d4d612fb-07f3-46ba-89f9-3f877cd9ae5e" />


### 4. Customer plan immediately after the free trial

**Business question:** What plan do customers move to after their initial free trial, and what percentage of customers choose each plan?

```sql
with cte as (
    select
        customer_id,
        plan_id,
        lead(plan_id) over (partition by customer_id order by start_date) as next_plan_id
     from subscriptions
    )
select
    next_plan_id as plan_id,
    plan_name,
    count(next_plan_id) as customer,
    round(count(next_plan_id)*100.0/((SELECT COUNT(DISTINCT customer_id) FROM subscriptions)),1) as percentage
from cte c
    join plans p
    on c.next_plan_id=p.plan_id
where c.plan_id=0
group by plan_name, c.next_plan_id
order by next_plan_id;
```

<img width="458" height="178" alt="image" src="https://github.com/user-attachments/assets/0f56d7ca-1d0c-46f4-bf6a-da3850f1ed42" />


### 5. Subscription plan distribution at 31 December 2020

**Business question:** How many customers were on each plan at the end of 2020?

```sql
with cte as (
    select
        plan_id,
        plan_name,
        start_date,
        customer_id,
        row_number() over (partition by customer_id order by start_date desc ) as ranking
     from subscriptions join plans using (plan_id)
    )
select
    plan_name as plan_2020,
    count(customer_id) as customer_count,
    round(count(customer_id)*100.0/((SELECT COUNT(DISTINCT customer_id) FROM cte)),1) as percentage
from cte
where start_date<'2021-01-01'and ranking =1
group by plan_name,plan_id
order by plan_id;
```


<img width="438" height="169" alt="image" src="https://github.com/user-attachments/assets/8e30b29b-78ad-4d0f-a083-8c6de269ba73" />


**Business question:** How many days does it take on average for customers to move from joining Foodie-Fi to an annual plan?

```sql
with cte as ( 
    -- extract first day join
    select
        plan_id,
        start_date,
        min(start_date) over (partition by customer_id) as join_date
     from subscriptions
    )
select
    round(avg( start_date-join_date ),0) as avg_days_to_annyal
from cte
where plan_id = 3;
```

<img width="235" height="100" alt="image" src="https://github.com/user-attachments/assets/a24ddd37-0eac-413a-be3d-6e350a9d4574" />


