-- one row per item sold. the main table for analysis.
-- order-level fields (dates, review score) repeat on each item of the same order.

with items as (
    select * from {{ ref('stg_order_items') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

reviews as (
    select * from {{ ref('stg_order_reviews') }}
),

orders_enriched as (
    select
        o.order_id,
        o.order_status,
        o.purchased_at,
        o.delivered_to_customer_at,
        o.estimated_delivery_date,
        c.customer_unique_id,
        row_number() over (
            partition by c.customer_unique_id
            order by o.purchased_at, o.order_id
        ) as customer_order_number,
        r.review_score
    from orders o
    join customers c on o.customer_id = c.customer_id
    left join reviews r on o.order_id = r.order_id
)

select
    i.order_item_key,
    i.order_id,
    i.order_item_number,
    {{ dbt_utils.generate_surrogate_key(['oe.customer_unique_id']) }} as customer_key,
    {{ dbt_utils.generate_surrogate_key(['i.product_id']) }} as product_key,
    i.seller_id,
    oe.purchased_at::date as order_date,
    oe.order_status,
    oe.customer_order_number,
    i.price,
    i.freight_value,
    i.price + i.freight_value as item_total,
    oe.delivered_to_customer_at::date as delivered_date,
    oe.estimated_delivery_date,
    datediff('day', oe.purchased_at, oe.delivered_to_customer_at) as days_to_deliver,
    datediff('day', oe.estimated_delivery_date, oe.delivered_to_customer_at::date) as days_late,
    oe.review_score
from items i
join orders_enriched oe on i.order_id = oe.order_id