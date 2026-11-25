# ingest notes

how the raw data was loaded into snowflake (olist.raw).

## steps
1. `01_setup.sql`: warehouse, database, schemas (raw, staging, marts), transformer role
2. `02_file_format_and_stage.sql`: csv file format and internal stage
3. manual step: csv files uploaded through the snowsight ui into olist_stage
4. `03_raw_tables.sql`: one raw table per csv
5. `04_copy_into.sql`: copy into each table, plus a row count check

## decisions
- all columns loaded as varchar on purpose. raw stays exactly like the source, and types are cast later in dbt staging
- every table has `_source_file` and `_loaded_at` so each row can be traced back to its file and load time
- `on_error = abort_statement`: if any row fails, the whole file is rejected, so nothing gets dropped without me knowing
- file format uses utf8 encoding for portuguese characters, and handles quoted fields because review comments contain commas and line breaks

## what i found
- all 8 files loaded, 0 rows rejected
- row counts: customers 99,441 / orders 99,441 / order_items 112,650 / payments 103,886 / reviews 99,224 / products 32,951 / sellers 3,095 / translation 71
- geolocation file uploaded but not loaded, not needed for this analysis
- the source misspells "lenght" in two product columns. kept as-is in raw, renamed in staging
- customer_id vs customer_unique_id: 99,441 customer_ids but only 96,096 unique customers. customer_id is created per order, so the customer dimension is built on customer_unique_id
- reviews: 99,224 rows but 98,410 unique review_ids (814 duplicates). removed in staging
- portuguese characters: city names have no accents in the source. checked review comments instead, accented words (não, já, férias) display correctly
- multi-line review comments loaded as single rows, confirming the quoted-field setting works