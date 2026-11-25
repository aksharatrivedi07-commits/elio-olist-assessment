-- one row per product, with english category name where available

with products as (
    select * from {{ ref('stg_products') }}
),

translation as (
    select * from {{ ref('stg_category_translation') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['p.product_id']) }} as product_key,
    p.product_id,
    p.category_name_pt,
    coalesce(t.category_name_en, p.category_name_pt, 'unknown') as category_name,
    p.weight_g,
    p.length_cm,
    p.height_cm,
    p.width_cm,
    p.photos_qty
from products p
left join translation t on p.category_name_pt = t.category_name_pt