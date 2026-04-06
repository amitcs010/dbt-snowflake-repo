{{ config(materialized='table') }}

-- depends_on: {{ ref('int_order_items') }}
-- depends_on: {{ source('raw', 'stg_raw_orders') }}

with order_items as (
    select * from {{ ref('int_order_items') }}
),

orders as (
    select * from {{ source('raw', 'stg_raw_orders') }}
),

joined_data as (
    select
        o.order_date as revenue_date,
        oi.category,
        oi.subcategory,
        oi.brand,
        o.order_channel,
        o.billing_country,
        o.payment_method,
        o.order_id,
        o.customer_id,
        oi.quantity,
        oi.product_id,
        oi.gross_revenue,
        oi.net_revenue,
        oi.cogs,
        oi.gross_margin,
        oi.is_discounted
    from order_items oi
    inner join orders o
        on oi.order_id = o.order_id
    where o.order_status not in ('pending_payment', 'fraud_review', 'cancelled')
),

aggregated as (
    select
        revenue_date,
        category,
        subcategory,
        brand,
        order_channel,
        billing_country,
        payment_method,

        -- Volume metrics
        count(distinct order_id) as order_count,
        count(distinct customer_id) as customer_count,
        sum(quantity) as units_sold,
        count(distinct product_id) as unique_products_sold,

        -- Revenue metrics
        sum(gross_revenue) as gross_revenue,
        sum(net_revenue) as net_revenue,
        sum(cogs) as cogs,
        sum(gross_margin) as gross_margin,
        round(
            case when sum(gross_revenue) > 0 
                then sum(gross_margin) / sum(gross_revenue) * 100 
                else 0 
            end, 2
        ) as margin_pct,

        -- Averages
        round(sum(gross_revenue) / nullif(count(distinct order_id), 0), 2) as avg_order_value,
        round(sum(gross_revenue) / nullif(sum(quantity), 0), 2) as avg_unit_price,

        -- Discount metrics
        sum(case when is_discounted then gross_revenue else 0 end) as discounted_revenue,
        round(
            sum(case when is_discounted then gross_revenue else 0 end) 
            / nullif(sum(gross_revenue), 0) * 100, 2
        ) as discount_revenue_pct
    from joined_data
    group by 
        revenue_date,
        category,
        subcategory,
        brand,
        order_channel,
        billing_country,
        payment_method
),

with_comparisons as (
    select
        *,
        sum(gross_revenue) - lag(sum(gross_revenue), 1) over (
            partition by category, order_channel
            order by revenue_date
        ) as revenue_vs_prev_day,
        sum(gross_revenue) - lag(sum(gross_revenue), 7) over (
            partition by category, order_channel
            order by revenue_date
        ) as revenue_vs_prev_week,
        current_timestamp() as _loaded_at
    from aggregated
)

select * from with_comparisons