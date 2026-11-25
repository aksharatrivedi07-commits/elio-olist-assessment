-- one row per product. fixes the "lenght" typo from the source

with source as (
    select * from {{ source('raw', 'products') }}
),

renamed as (
    select
        product_id,
        product_category_name as category_name_pt,
        try_to_number(product_name_lenght) as name_length,
        try_to_number(product_description_lenght) as description_length,
        try_to_number(product_photos_qty) as photos_qty,
        try_to_number(product_weight_g) as weight_g,
        try_to_number(product_length_cm) as length_cm,
        try_to_number(product_height_cm) as height_cm,
        try_to_number(product_width_cm) as width_cm,
        _source_file as _source,
        _loaded_at
    from source
),

deduped as (
    select *
    from renamed
    qualify row_number() over (partition by product_id order by _loaded_at desc) = 1
)

select * from deduped