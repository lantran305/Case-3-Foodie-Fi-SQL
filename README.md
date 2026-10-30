# Case Study 03: Foodie-Fi

## 1. Project Overview

Foodie-Fi is a subscription-based streaming service focused on food-related content. This project uses PostgreSQL to analyze customer subscription journeys and answer business questions about plan adoption, churn, upgrades, and downgrades.

**Tools: PostgreSQL, pgAdmin 4, Visual Studio Code**
**SQL concepts:** **Aggregations, joins, date functions, CTEs, subqueries, window functions (`LEAD`, `ROW_NUMBER`), and conditional counting.**

<img width="726" height="730" alt="image" src="https://github.com/user-attachments/assets/f9b66b94-650b-4f12-ae74-8487f53d0519" />


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
```

> Source: The analysis follows the questions from the [8 Week SQL Challenge — Case Study #3: Foodie-Fi](https://8weeksqlchallenge.com/case-study-3/).

## Analysis & Queries

The SQL solutions are available in [`Analysis Questions.sql`](./Analysis%20Questions.sql). Below are selected examples of the analysis.

### 1. Total number of customers

```sql
-- 1. How many customers has Foodie-Fi ever had?
SELECT
    COUNT(DISTINCT customer_id) AS customers_count
FROM
    subscriptions;
```

<img width="291" height="127" alt="image" src="https://github.com/user-attachments/assets/84ac8609-5daf-4d32-b1d3-2ba263e92ee0" />


### 2. Monthly trial sign-ups

```sql
-- 2.What is the monthly distribution of trial plan start_date values for our dataset use the start of the month as the group by value

SELECT
    DATE_TRUNC('month', start_date)::date AS MONTH,
    COUNT(plan_id) AS trial_count
FROM
    subscriptions
WHERE
    plan_id = 1
GROUP BY
    DATE_TRUNC('month', start_date)
ORDER BY
    month;
```

<img width="306" height="389" alt="image" src="https://github.com/user-attachments/assets/a413ebeb-e8eb-4b91-b307-b0303ee9cbf3" />


### 4. Churn rate

```sql
--4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

WITH customer_count AS (
    SELECT
        COUNT(DISTINCT customer_id) AS total_customer,
        COUNT(DISTINCT CASE WHEN plan_id = 4 THEN customer_id END) AS churned_customer
    FROM subscriptions
)
SELECT
    churned_customer,
    ROUND(churned_customer * 100.0/ total_customer, 1) AS churned_percentage
FROM customer_count;
```

<img width="350" height="93" alt="image" src="https://github.com/user-attachments/assets/d4d612fb-07f3-46ba-89f9-3f877cd9ae5e" />


### 4. Customer plan immediately after the free trial

```sql
-- 6.What is the number and percentage of customer plans after their initial free trial?

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

<img width="502" height="179" alt="image" src="https://github.com/user-attachments/assets/607b2b66-2fb3-4b1f-8b49-e7204d153dbf" />



### 5. Subscription plan distribution at 31 December 2020

```sql
-- 7.What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

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


<img width="438" height="173" alt="image" src="https://github.com/user-attachments/assets/35dd9d06-ad8b-44d2-9b65-cbbd45969f6f" />

### 6. Customers have upgraded to an annual plan in 2020


```sql
-- 8.How many customers have upgraded to an annual plan in 2020?

with cte as (
    select
        plan_id,
        customer_id,
        start_date,
        row_number() over (partition by customer_id order by start_date desc ) as ranking
     from subscriptions
     where start_date<='2020-12-31' and start_date>='2020-01-01'
    )
select
    count( customer_id) as customers_upgraded_annual_plan_2020
from cte
where ranking =1 and plan_id = 3;
    
```

<img width="349" height="101" alt="image" src="https://github.com/user-attachments/assets/e1ec6a99-3e5a-40b2-ae70-c925fc6d5f35" />

### 7. Average days to upgrade


```sql
-- 8.How many customers have upgraded to an annual plan in 2020?

with cte as (
    select
        plan_id,
        customer_id,
        start_date,
        row_number() over (partition by customer_id order by start_date desc ) as ranking
     from subscriptions
     where start_date<='2020-12-31' and start_date>='2020-01-01'
    )
select
    count( customer_id) as customers_upgraded_annual_plan_2020
from cte
where ranking =1 and plan_id = 3;
    
```

<img width="226" height="91" alt="image" src="https://github.com/user-attachments/assets/ada7b897-af7f-4299-bac9-65f3bd4535b7" />


### 8. Breakdown into 30 day periods (i.e. 0-30 days, 31-60 days etc)


```sql
-- 10.Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

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
    CONCAT(
        ((start_date - join_date - 1) / 30) * 30 + 1,
        '-',
        ((start_date - join_date - 1) / 30 + 1) * 30,
        ' days'
    ) AS days_period,
    COUNT(DISTINCT customer_id) AS customer_count
FROM cte
WHERE plan_id = 3
GROUP BY 1
ORDER BY MIN(start_date - join_date);

    
```

<img width="324" height="372" alt="image" src="https://github.com/user-attachments/assets/baf5f751-751f-4327-b05b-353d38b29613" />
