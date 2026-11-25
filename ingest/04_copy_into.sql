use role transformer;
use warehouse elio_wh;
use schema olist.raw;

-- load each csv into its raw table, adding filename + load time
-- abort_statement = if any row fails, reject the file so nothing is lost silently

copy into customers
from (select t.$1, t.$2, t.$3, t.$4, t.$5,
             metadata$filename, current_timestamp()::timestamp_ntz
      from @olist_stage t)
files = ('olist_customers_dataset.csv')
on_error = 'abort_statement';

copy into orders
from (select t.$1, t.$2, t.$3, t.$4, t.$5, t.$6, t.$7, t.$8,
             metadata$filename, current_timestamp()::timestamp_ntz
      from @olist_stage t)
files = ('olist_orders_dataset.csv')
on_error = 'abort_statement';

copy into order_items
from (select t.$1, t.$2, t.$3, t.$4, t.$5, t.$6, t.$7,
             metadata$filename, current_timestamp()::timestamp_ntz
      from @olist_stage t)
files = ('olist_order_items_dataset.csv')
on_error = 'abort_statement';

copy into order_payments
from (select t.$1, t.$2, t.$3, t.$4, t.$5,
             metadata$filename, current_timestamp()::timestamp_ntz
      from @olist_stage t)
files = ('olist_order_payments_dataset.csv')
on_error = 'abort_statement';

copy into order_reviews
from (select t.$1, t.$2, t.$3, t.$4, t.$5, t.$6, t.$7,
             metadata$filename, current_timestamp()::timestamp_ntz
      from @olist_stage t)
files = ('olist_order_reviews_dataset.csv')
on_error = 'abort_statement';

copy into products
from (select t.$1, t.$2, t.$3, t.$4, t.$5, t.$6, t.$7, t.$8, t.$9,
             metadata$filename, current_timestamp()::timestamp_ntz
      from @olist_stage t)
files = ('olist_products_dataset.csv')
on_error = 'abort_statement';

copy into sellers
from (select t.$1, t.$2, t.$3, t.$4,
             metadata$filename, current_timestamp()::timestamp_ntz
      from @olist_stage t)
files = ('olist_sellers_dataset.csv')
on_error = 'abort_statement';

copy into category_translation
from (select t.$1, t.$2,
             metadata$filename, current_timestamp()::timestamp_ntz
      from @olist_stage t)
files = ('product_category_name_translation.csv')
on_error = 'abort_statement';


select 'customers' as tbl, count(*) as n from customers union all
select 'orders', count(*) from orders union all
select 'order_items', count(*) from order_items union all
select 'order_payments', count(*) from order_payments union all
select 'order_reviews', count(*) from order_reviews union all
select 'products', count(*) from products union all
select 'sellers', count(*) from sellers union all
select 'category_translation', count(*) from category_translation;
