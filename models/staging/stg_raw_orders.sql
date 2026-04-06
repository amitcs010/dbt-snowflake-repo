{{ config(materialized='table') }}

-- depends_on: {{ source('raw', 'raw_orders') }}

with raw_orders as (
    select
        cast(o.id as number) as order_id,
        cast(o.customer_id as number) as customer_id,
        cast(o.order_number as varchar) as order_number,
        cast(o.status as varchar) as order_status,
        cast(o.created_at as date) as order_date,
        cast(o.created_at as timestamp) as order_timestamp,
        cast(o.updated_at as timestamp) as updated_at,
        cast(o.total_amount as decimal(12, 2)) as total_amount,
        cast(o.discount_amount as decimal(12, 2)) as discount_amount,
        cast(o.shipping_amount as decimal(12, 2)) as shipping_amount,
        cast(o.tax_amount as decimal(12, 2)) as tax_amount,
        coalesce(o.coupon_code, 'NONE') as coupon_code,
        cast(o.payment_method as varchar) as payment_method,
        cast(o.shipping_method as varchar) as shipping_method,
        cast(o.billing_country as varchar) as billing_country,
        cast(o.shipping_country as varchar) as shipping_country,
        coalesce(o.channel, 'web') as order_channel,
        current_timestamp() as _loaded_at
    from
        {{ source('raw', 'raw_orders') }} o
    where
        o.created_at >= dateadd(day, -3, current_timestamp())
        and o.is_test = false
        and o.status != 'cancelled_by_system'
        and o.total_amount > 0
)

select * from raw_orders