{{ config(materialized='table') }}

-- depends_on: {{ source('raw', 'raw_products') }}

with raw_products as (
    select
        cast(p.id as number) as product_id,
        cast(p.sku as varchar(50)) as sku,
        cast(p.name as varchar(200)) as product_name,
        cast(p.category as varchar(100)) as category,
        cast(p.subcategory as varchar(100)) as subcategory,
        cast(p.brand as varchar(100)) as brand,
        cast(p.price as decimal(10, 2)) as unit_price,
        cast(p.cost as decimal(10, 2)) as unit_cost,
        cast(p.weight_kg as decimal(8, 3)) as weight_kg,
        case
            when p.status = 'A' then 'Active'
            when p.status = 'D' then 'Discontinued'
            when p.status = 'O' then 'Out of Stock'
            else 'Unknown'
        end as product_status,
        coalesce(p.supplier_id, -1) as supplier_id,
        try_to_date(p.launch_date) as launch_date,
        try_to_date(p.last_restock_date) as last_restock_date,
        p.inventory_count,
        current_timestamp() as _loaded_at
    from {{ source('raw', 'raw_products') }} p
    where p.id is not null
      and p.name is not null
)

select * from raw_products