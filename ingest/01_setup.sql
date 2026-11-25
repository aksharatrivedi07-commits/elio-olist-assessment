use role accountadmin;

create warehouse if not exists elio_wh
  warehouse_size = 'xsmall'
  auto_suspend = 60
  auto_resume = true
  initially_suspended = true;

create database if not exists olist;
create schema if not exists olist.raw;
create schema if not exists olist.staging;
create schema if not exists olist.marts;

create role if not exists transformer;
grant usage on warehouse elio_wh to role transformer;
grant all on database olist to role transformer;
grant all on all schemas in database olist to role transformer;
grant role transformer to user "aksharatrivedi2002";

