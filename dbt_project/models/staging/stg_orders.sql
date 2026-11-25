-- one row per order, cleaned and typed

with source as (
    select * from {{ source('raw', 'orders') }}
),

renamed as (
    select
        order_id,
        customer_id,
        lower(order_status) as order_status,
        try_to_timestamp(order_purchase_timestamp) as purchased_at,
        try_to_timestamp(order_approved_at) as approved_at,
        try_to_timestamp(order_delivered_carrier_date) as delivered_to_carrier_at,
        try_to_timestamp(order_delivered_customer_date) as delivered_to_customer_at,
        try_to_timestamp(order_estimated_delivery_date)::date as estimated_delivery_date,
        _source_file as _source,
        _loaded_at
    from source
),

deduped as (
    select *
    from renamed
    qualify row_number() over (partition by order_id order by _loaded_at desc) = 1
)

select * from deduped