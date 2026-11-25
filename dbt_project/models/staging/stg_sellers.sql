-- one row per seller

with source as (
    select * from {{ source('raw', 'sellers') }}
),

renamed as (
    select
        seller_id,
        seller_zip_code_prefix as zip_code_prefix,
        lower(trim(seller_city)) as city,
        upper(trim(seller_state)) as state,
        _source_file as _source,
        _loaded_at
    from source
),

deduped as (
    select *
    from renamed
    qualify row_number() over (partition by seller_id order by _loaded_at desc) = 1
)

select * from deduped