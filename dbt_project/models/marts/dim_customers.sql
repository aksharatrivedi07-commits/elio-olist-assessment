-- one row per real customer (customer_unique_id), not per order.
-- location is taken from their most recent order.

with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

customer_orders as (
    select
        c.customer_unique_id,
        c.city,
        c.state,
        o.order_id,
        o.purchased_at
    from orders o
    join customers c on o.customer_id = c.customer_id
),

order_summary as (
    select
        customer_unique_id,
        min(purchased_at) as first_order_at,
        max(purchased_at) as last_order_at,
        count(distinct order_id) as total_orders
    from customer_orders
    group by customer_unique_id
),

latest_location as (
    select customer_unique_id, city, state
    from customer_orders
    qualify row_number() over (partition by customer_unique_id order by purchased_at desc) = 1
)

select
    {{ dbt_utils.generate_surrogate_key(['s.customer_unique_id']) }} as customer_key,
    s.customer_unique_id,
    l.city,
    l.state,
    s.first_order_at,
    s.last_order_at,
    s.total_orders,
    s.total_orders > 1 as is_repeat_customer
from order_summary s
join latest_location l on s.customer_unique_id = l.customer_unique_id