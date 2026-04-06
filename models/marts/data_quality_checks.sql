-- models/data_quality_checks.sql
-- depends_on: {{ ref('fct_orders') }}
-- depends_on: {{ ref('dim_customers') }}
-- depends_on: {{ ref('dim_products') }}
-- depends_on: {{ ref('fct_daily_revenue') }}
-- depends_on: {{ ref('int_customer_sessions') }}
-- depends_on: {{ ref('int_order_items') }}

{{ config(materialized='table') }}

with orders_not_empty as (
    select
        'orders_not_empty' as check_name,
        'marts.fct_orders' as table_name,
        'Yesterday should have at least 100 orders' as description,
        'critical' as severity,
        '>= 100' as expected,
        count(*) as actual,
        count(*) >= 100 as passed,
        current_timestamp as run_at
    from {{ ref('fct_orders') }}
    where order_date = current_date - 1
),

orders_no_null_revenue as (
    select
        'orders_no_null_revenue' as check_name,
        'marts.fct_orders' as table_name,
        'No orders should have NULL gross_revenue' as description,
        'critical' as severity,
        '== 0' as expected,
        count(*) as actual,
        count(*) = 0 as passed,
        current_timestamp as run_at
    from {{ ref('fct_orders') }}
    where gross_revenue is null
        and order_date >= current_date - 3
),

orders_revenue_range as (
    select
        'orders_revenue_range' as check_name,
        'marts.fct_orders' as table_name,
        'No orders with negative or suspiciously high revenue' as description,
        'warning' as severity,
        '== 0' as expected,
        count(*) as actual,
        count(*) = 0 as passed,
        current_timestamp as run_at
    from {{ ref('fct_orders') }}
    where gross_revenue < 0
        or gross_revenue > 50000
),

customers_unique as (
    select
        'customers_unique' as check_name,
        'marts.dim_customers' as table_name,
        'Customer dimension should have no duplicate customer_ids' as description,
        'critical' as severity,
        '== 0' as expected,
        count(*) - count(distinct customer_id) as actual,
        (count(*) - count(distinct customer_id)) = 0 as passed,
        current_timestamp as run_at
    from {{ ref('dim_customers') }}
),

products_have_cost as (
    select
        'products_have_cost' as check_name,
        'marts.dim_products' as table_name,
        'Active products should have a valid unit cost' as description,
        'warning' as severity,
        '== 0' as expected,
        count(*) as actual,
        count(*) = 0 as passed,
        current_timestamp as run_at
    from {{ ref('dim_products') }}
    where (unit_cost is null or unit_cost <= 0)
        and product_status = 'Active'
),

daily_revenue_freshness as (
    select
        'daily_revenue_freshness' as check_name,
        'marts.fct_daily_revenue' as table_name,
        'Daily revenue should be no more than 2 days stale' as description,
        'critical' as severity,
        '<= 2' as expected,
        datediff(day, max(revenue_date), current_date) as actual,
        datediff(day, max(revenue_date), current_date) <= 2 as passed,
        current_timestamp as run_at
    from {{ ref('fct_daily_revenue') }}
),

sessions_event_count as (
    select
        'sessions_event_count' as check_name,
        'transforms.int_customer_sessions' as table_name,
        'All sessions should have at least 1 event' as description,
        'warning' as severity,
        '== 0' as expected,
        count(*) as actual,
        count(*) = 0 as passed,
        current_timestamp as run_at
    from {{ ref('int_customer_sessions') }}
    where event_count <= 0
),

margin_sanity as (
    select
        'margin_sanity' as check_name,
        'transforms.int_order_items' as table_name,
        'Very few items should have extreme margin percentages' as description,
        'warning' as severity,
        '<= 10' as expected,
        count(*) as actual,
        count(*) <= 10 as passed,
        current_timestamp as run_at
    from {{ ref('int_order_items') }}
    where margin_pct < -50
        or margin_pct > 99
)

select * from orders_not_empty
union all
select * from orders_no_null_revenue
union all
select * from orders_revenue_range
union all
select * from customers_unique
union all
select * from products_have_cost
union all
select * from daily_revenue_freshness
union all
select * from sessions_event_count
union all
select * from margin_sanity