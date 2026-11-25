-- one row per customer_id (note: customer_id is per order, customer_unique_id is the real person)

with source as (
    select * from {{ source('raw', 'customers') }}
),

renamed as (
    select
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix as zip_code_prefix,
        lower(trim(customer_city)) as city,
        upper(trim(customer_state)) as state,
        _source_file as _source,
        _loaded_at
    from source
),

deduped as (
    select *
    from renamed
    qualify row_number() over (partition by customer_id order by _loaded_at desc) = 1
)

select * from deduped