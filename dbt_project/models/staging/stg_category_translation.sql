-- portuguese to english product category names

with source as (
    select * from {{ source('raw', 'category_translation') }}
),

renamed as (
    select
        product_category_name as category_name_pt,
        product_category_name_english as category_name_en,
        _source_file as _source,
        _loaded_at
    from source
),

deduped as (
    select *
    from renamed
    qualify row_number() over (partition by category_name_pt order by _loaded_at desc) = 1
)

select * from deduped