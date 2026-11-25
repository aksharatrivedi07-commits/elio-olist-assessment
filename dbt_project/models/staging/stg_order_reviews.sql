-- one review per order: the most recent one.
-- in the source, one review can cover several orders and one order can have several reviews,
-- so review_id is not unique. order_id is the key here.

with source as (
    select * from {{ source('raw', 'order_reviews') }}
),

renamed as (
    select
        order_id,
        review_id,
        try_to_number(review_score) as review_score,
        review_comment_title,
        review_comment_message,
        try_to_timestamp(review_creation_date) as review_created_at,
        try_to_timestamp(review_answer_timestamp) as review_answered_at,
        _source_file as _source,
        _loaded_at
    from source
),

latest_per_order as (
    select *
    from renamed
    qualify row_number() over (
        partition by order_id
        order by review_answered_at desc, review_created_at desc
    ) = 1
)

select * from latest_per_order