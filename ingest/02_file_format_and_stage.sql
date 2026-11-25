use role transformer;
use warehouse elio_wh;
use schema olist.raw;

-- rules for reading the olist csv files
create or replace file format csv_format
  type = csv
  field_delimiter = ','
  skip_header = 1
  field_optionally_enclosed_by = '"'
  encoding = 'UTF8'
  empty_field_as_null = true
  null_if = ('', 'NULL');

-- a folder inside snowflake where the files wait before loading
create or replace stage olist_stage
  file_format = csv_format;

-- files uploaded manually via snowsight: catalog > olist > raw > stages > olist_stage > + files
-- check with: list @olist_stage;