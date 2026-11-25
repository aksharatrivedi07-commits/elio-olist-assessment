use role transformer;
use warehouse elio_wh;
use schema olist.raw;

-- raw tables: everything as text, exactly as in the csvs, plus load info

create or replace table customers (
  customer_id varchar,
  customer_unique_id varchar,
  customer_zip_code_prefix varchar,
  customer_city varchar,
  customer_state varchar,
  _source_file varchar,
  _loaded_at timestamp_ntz
);

create or replace table orders (
  order_id varchar,
  customer_id varchar,
  order_status varchar,
  order_purchase_timestamp varchar,
  order_approved_at varchar,
  order_delivered_carrier_date varchar,
  order_delivered_customer_date varchar,
  order_estimated_delivery_date varchar,
  _source_file varchar,
  _loaded_at timestamp_ntz
);

create or replace table order_items (
  order_id varchar,
  order_item_id varchar,
  product_id varchar,
  seller_id varchar,
  shipping_limit_date varchar,
  price varchar,
  freight_value varchar,
  _source_file varchar,
  _loaded_at timestamp_ntz
);

create or replace table order_payments (
  order_id varchar,
  payment_sequential varchar,
  payment_type varchar,
  payment_installments varchar,
  payment_value varchar,
  _source_file varchar,
  _loaded_at timestamp_ntz
);

create or replace table order_reviews (
  review_id varchar,
  order_id varchar,
  review_score varchar,
  review_comment_title varchar,
  review_comment_message varchar,
  review_creation_date varchar,
  review_answer_timestamp varchar,
  _source_file varchar,
  _loaded_at timestamp_ntz
);

-- note: "lenght" is misspelled in the source file. kept as-is here, fixed in staging
create or replace table products (
  product_id varchar,
  product_category_name varchar,
  product_name_lenght varchar,
  product_description_lenght varchar,
  product_photos_qty varchar,
  product_weight_g varchar,
  product_length_cm varchar,
  product_height_cm varchar,
  product_width_cm varchar,
  _source_file varchar,
  _loaded_at timestamp_ntz
);

create or replace table sellers (
  seller_id varchar,
  seller_zip_code_prefix varchar,
  seller_city varchar,
  seller_state varchar,
  _source_file varchar,
  _loaded_at timestamp_ntz
);

create or replace table category_translation (
  product_category_name varchar,
  product_category_name_english varchar,
  _source_file varchar,
  _loaded_at timestamp_ntz
);

show tables in schema olist.raw;