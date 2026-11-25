-- one row per payment. an order can be paid in parts (e.g. card + voucher)

with source as (
    select * from {{ source('raw', 'order_payments') }}
),

renamed as (
    select
        {{ dbt_utils.generate_surrogate_key(['order_id', 'payment_sequential']) }} as payment_key,
        order_id,
        try_to_number(payment_sequential) as payment_sequential,
        lower(payment_type) as payment_type,
        try_to_number(payment_installments) as installments,
        try_to_decimal(payment_value, 10, 2) as payment_value,
        _source_file as _source,
        _loaded_at
    from source
),

deduped as (
    select *
    from renamed
    qualify row_number() over (partition by payment_key order by _loaded_at desc) = 1
)

select * from deduped