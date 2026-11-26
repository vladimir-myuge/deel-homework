# Deel Analytics Engineering Challenge - Globepay

A dbt project on Snowflake that ingests the Globepay acceptance and chargeback reports, models them into an analyst-ready fact table and answers three questions about card payments.

The write-up (data exploration, design decisions, lineage, answers with SQL and charts) is in the attached document.

## Stack

- dbt Core 1.12, dbt-snowflake 1.12
- Snowflake (key-pair auth, dedicated service user)
- Python 3.14

## Repository structure

```
deel-homework/
├── README.md
└── deel_homework/                         dbt project
    ├── dbt_project.yml
    ├── macros/
    │   ├── load_raw_from_stage.sql        generic loader: stage CSV -> RAW table + technical columns
    │   └── load_raw_globepay.sql          list of Globepay tables to load
    ├── models/
    │   ├── _shared_docs.md                shared column descriptions ({% docs %} blocks)
    │   ├── staging/globepay/
    │   │   ├── _globepay__sources.yml     RAW tables declared as sources
    │   │   ├── _globepay__models.yml
    │   │   ├── stg_globepay__acceptance.sql
    │   │   └── stg_globepay__chargebacks.sql
    │   ├── intermediate/
    │   │   ├── _intermediate__models.yml
    │   │   └── int_payments__with_chargebacks.sql
    │   └── marts/
    │       ├── _marts__models.yml         enforced contract
    │       └── fct_payments.sql
    └── tests/
        ├── generic/test_is_positive.sql
        └── assert_fct_payments__no_chargeback_on_declined.sql
```

## Model layers

| Layer | Model | Materialization | Purpose |
| --- | --- | --- | --- |
| Ingestion | `load_raw_globepay` macro | Tables in `RAW` | Copy CSV files from the stage as VARCHAR, add file name, file hash, load id and load time |
| Staging | `stg_globepay__acceptance` | View | Take the latest file version per transaction, rename, cast types, normalize `UK` to `GB`, convert amount to USD |
| Staging | `stg_globepay__chargebacks` | View | Take the latest file version per transaction, rename, cast the chargeback flag |
| Intermediate | `int_payments__with_chargebacks` | View | Join transactions with chargebacks; chargeback is NULL for declined payments |
| Marts | `fct_payments` | Table | One row per transaction for analysts, with an enforced contract |

## How to run

1. In Snowflake, create the database and the stage, and upload both CSV files to it:
   ```sql
   create database if not exists DEEL_HOMEWORK;
   create schema if not exists DEEL_HOMEWORK.RAW;
   create stage if not exists DEEL_HOMEWORK.RAW.GLOBEPAY_STAGE;
   ```
   Files are picked by name pattern: `*Acceptance*.csv` and `*Chargeback*.csv`.
2. Configure `~/.dbt/profiles.yml` with a profile named `deel_homework` (Snowflake account, user, key or password, role, warehouse, database `DEEL_HOMEWORK`).
3. From the `deel_homework/` folder:
   ```bash
   dbt debug                              # check the connection
   dbt run-operation load_raw_globepay    # load CSV files from the stage into RAW (idempotent)
   dbt build                              # build all models and run all tests
   dbt docs generate && dbt docs serve    # documentation and lineage graph
   ```

Running the load macro twice loads 0 files the second time: Snowflake skips files already loaded into a table.

## Tests

- Sources: keys are not null and unique; every chargeback row refers to an existing transaction.
- Staging: strict type casts fail the build on bad values; accepted values for state; not null on the FX rate and the USD amount; a custom `is_positive` test warns on non-positive amounts (one known case).
- Intermediate and marts: unique transaction id after the join; enforced contract on `fct_payments`; a singular test that declined payments never have a chargeback.

## Key assumptions

- Amounts are in major units (the API spec says minor units, but the data has decimals).
- `rates` are quoted as local currency per 1 USD, so `amount_usd = amount_local / rate`.
- All timestamps are UTC.
