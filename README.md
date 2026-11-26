# Olist on Snowflake + dbt

My take-home for Elio. I loaded the raw Olist CSVs into Snowflake, modelled them with dbt through raw, staging and marts layers, and used the result to answer a commercial question. The findings and recommendation are in [analysis_answers.md](analysis_answers.md).

## Platform and setup

I used Snowflake, as the brief asked.

| Item | Value |
|---|---|
| Account | Snowflake free trial, Enterprise edition, AWS London |
| Warehouse | `ELIO_WH`, X-Small, auto-suspend 60 seconds |
| Database | `OLIST` |
| Schemas | `RAW`, `STAGING`, `MARTS` |
| Role | `TRANSFORMER` (dbt and loading never run as ACCOUNTADMIN) |
| dbt | dbt-core 1.12.7, dbt-snowflake 1.12.5 (pinned in `requirements.txt`) |
| dbt packages | dbt_utils 1.4.1 (pinned in `dbt_project/packages.yml`) |
| Python | 3.11 |

## Running it end to end

**1. Python environment**
```bash
git clone https://github.com/aksharatrivedi07-commits/elio-olist-assessment.git
cd elio-olist-assessment
python3.11 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

**2. Snowflake objects.** In a Snowsight worksheet, run `ingest/01_setup.sql` as ACCOUNTADMIN. Change the user name on the last line to yours.

**3. Load the raw data**
- Download the [Olist dataset from Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) into `data/` (the CSVs are not in the repo).
- Run `ingest/02_file_format_and_stage.sql`.
- Upload the CSVs to `OLIST.RAW.OLIST_STAGE`. I did this through the Snowsight UI (Catalog > OLIST > RAW > Stages > OLIST_STAGE > + Files). A `PUT` from SnowSQL works too.
- Run `ingest/03_raw_tables.sql`, then `ingest/04_copy_into.sql`. The row-count query at the bottom of `04` should match the counts in `ingest/README.md`.

**4. Connect dbt.** I used key-pair authentication, so no password is stored anywhere.
```bash
mkdir -p ~/.dbt
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out ~/.dbt/rsa_key.p8 -nocrypt
openssl rsa -in ~/.dbt/rsa_key.p8 -pubout -out ~/.dbt/rsa_key.pub
```
Attach the public key to your Snowflake user (`alter user <name> set rsa_public_key = '<key>';`), copy `profiles.yml.example` to `~/.dbt/profiles.yml`, and set:
```bash
export SNOWFLAKE_ACCOUNT=<your account identifier>
export SNOWFLAKE_USER=<your user name>
export SNOWFLAKE_PRIVATE_KEY_PATH=~/.dbt/rsa_key.p8
```

**5. Build and test**
```bash
cd dbt_project
dbt deps
dbt debug
dbt build
```
Expect 11 models and 45 tests: 44 pass and 1 warns. The warning is 13 products whose category has no English translation. I kept them and show the Portuguese name rather than failing the build.

**6. Analytics queries.** Open `sql/analytics_queries.sql` in a Snowsight worksheet with role `TRANSFORMER` and warehouse `ELIO_WH`, and run each query on its own.

## How the repo is organised

```
ingest/                  snowflake setup + loading sql, notes on what i found while loading
dbt_project/
  models/staging/        one model per source table, plus sources and tests
  models/marts/          dim_customers, dim_products, fct_order_items, plus tests and docs
  macros/                schema naming override
docs/data_model.md       erd, normalisation reasoning, keys, materialisation
sql/analytics_queries.sql
analysis_answers.md      part b: insights, recommendation, caveats, memo
profiles.yml.example     dbt connection template using environment variables
```

The modelling decisions are explained in [docs/data_model.md](docs/data_model.md), and the loading decisions and data issues in [ingest/README.md](ingest/README.md).

## New to me, and how I got up to speed

I hadn't used Snowflake or dbt before this. I learned from the Snowflake and dbt docs, and used Claude as a tutor to explain syntax and error messages. I wrote and ran every model myself and can walk through any of it.

The parts that actually took time:
- **Authentication.** dbt's browser login only works with single sign-on, which a trial account doesn't have, so I switched to key-pair auth. That then failed because my Snowflake user name was stored in lowercase, while the key login looks it up in capitals. Renaming the user fixed it. I also learned that Snowflake keeps a separate login name and user name, and that grants use one while logins use the other.
- **Schema names.** By default dbt combines schema names, so my marts landed in `STAGING_MARTS`. A small macro (`macros/generate_schema_name.sql`) fixes that.
- **Local setup.** Python on my Mac couldn't verify SSL certificates, so pip failed until I ran the certificate installer. I also moved the project out of OneDrive, because syncing the virtual environment and git folder was causing problems.
- [Add one or two lines in your own words: what surprised you, or what you'd tell someone starting dbt tomorrow.]

## Shortcuts and what I'd do next

Given the time limit, I focused on a clean, tested pipeline and a defensible recommendation, and skipped Part C. With more time, in rough priority order:

- **CI.** A GitHub Actions workflow that runs `dbt build` on every pull request against a separate CI schema, with the private key stored as a GitHub secret.
- **Incremental loading.** Make `fct_order_items` incremental with a merge on `order_item_key`, and make the raw load safe to re-run. `COPY INTO` already skips files it has loaded before, but `02_file_format_and_stage.sql` uses `create or replace`, which would wipe the stage if re-run.
- **Environments.** Separate dev and prod databases and roles, with a zero-copy clone of prod for each pull request.
- **Source freshness and row-count alerts** on the raw tables (see B3 in the analysis).
- **Automate the upload** with `PUT` instead of the Snowsight UI.
- **Re-check the timing** for the recommended email using only true repeat orders. The current 28.5-day median includes same-day orders.
- I didn't load the geolocation file because the analysis doesn't need it.