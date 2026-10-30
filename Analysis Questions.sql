SET search_path = foodie_fi;

-- 1. How many customers has Foodie-Fi ever had?
SELECT
    COUNT(DISTINCT customer_id) AS customers_count
FROM
    subscriptions;

-- 2.What is the monthly distribution of trial plan start_date values for our dataset 
-- use the start of the month as the group by value

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

    
-- 3.What plan start_date values occur after the year 2020 for our dataset? 
--Show the breakdown by count of events for each plan_name

SELECT
    plan_name,
    count(*) AS plan_count
FROM
    subscriptions
    JOIN plans USING (plan_id)
WHERE
    start_date > '2020-12-31'
GROUP BY
    plan_name;

--4. What is the customer count and percentage of 
--customers who have churned rounded to 1 decimal place?

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

-- 5.How many customers have churned straight after their initial free trial 
-- what percentage is this rounded to the nearest whole number?
with cte as (
    select
    customer_id,
    plan_id,
     lead(plan_id) over( partition by customer_id order by start_date) as next_plan_id
     
    from subscriptions
)
select
    count(distinct customer_id) as customer_count,
    ROUND(
        COUNT(DISTINCT customer_id) * 100.0 /
        (SELECT COUNT(DISTINCT customer_id) FROM subscriptions)
    ) AS churned_after_trial_percentage
from cte
where plan_id =0 and next_plan_id =4;

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

-- 7.What is the customer count and percentage breakdown 
-- of all 5 plan_name values at 2020-12-31?

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
where ranking =1 and plan_id = 3
    

-- 9.How many days on average does it take for a customer to 
-- an annual plan from the day they join Foodie-Fi?

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

-- 11.How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

with cte as (
    select
        plan_id,
        customer_id,
        start_date,
        lead (plan_id) over ( partition by customer_id order by start_date) as next_plan_id
     from subscriptions
     where start_date<='2020-12-31' and start_date>='2020-01-01' 
    )
select
    count( customer_id) as customers_downgraded_2_to_1
from cte
where plan_id = 2 and next_plan_id =1;