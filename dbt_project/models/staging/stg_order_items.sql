-- one row per item in an order. an order with 3 items has 3 rows

with source as (
    select * from {{ source('raw', 'order_items') }}
),

renamed as (
    select
        {{ dbt_utils.generate_surrogate_key(['order_id', 'order_item_id']) }} as order_item_key,
        order_id,
        try_to_number(order_item_id) as order_item_number,
        product_id,
        seller_id,
        try_to_timestamp(shipping_limit_date) as shipping_limit_at,
        try_to_decimal(price, 10, 2) as price,
        try_to_decimal(freight_value, 10, 2) as freight_value,
        _source_file as _source,
        _loaded_at
    from source
),

deduped as (
    select *
    from renamed
    qualify row_number() over (partition by order_item_key order by _loaded_at desc) = 1
)

select * from deduped