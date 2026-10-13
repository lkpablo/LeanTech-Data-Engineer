# LeanTech Data Engineer Skills Challenge

Sales data loaded into Snowflake, validated and modelled as a star schema with dbt, orchestrated with Airflow. The answers to each part of the challenge, and why each technology was chosen, are in `SOLUTION.md`. The sales data product itself is documented in `dbt/README.md`.

## Requirements
- Python 3.12
- A Snowflake account with the `ACCOUNTADMIN` role. A free trial works; choose **Enterprise** edition (90-day Time Travel).
- Docker Desktop, only to run the pipeline with Airflow.

Run every command from the repository root. Commands are shown for PowerShell; on macOS or Linux use `source .venv/bin/activate` instead.

## Setup (one time)

**1. Python environment**
```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

**2. Key pair for the service user**
```powershell
python setup/generate_keys.py
```
Writes the private key to `.secrets/` (ignored by git) and prints the public key.

**3. Snowflake objects.** In Snowsight, open a SQL file, paste `setup/snowflake_setup.sql`, replace `<RSA_PUBLIC_KEY>` with the printed public key and run it with **Run All**, so every statement runs. It creates the warehouse `LEANTECH_WH`, the database `SALES_DW`, the role `LEANTECH_PIPELINE` and the service user `SVC_LEANTECH`. It is the only manual step: it creates the user everything else connects with, and it needs `ACCOUNTADMIN`.

**4. Configuration.** Copy `.env.example` to `.env` and set `SNOWFLAKE_ACCOUNT` to your account identifier (Snowsight: your user menu → Account → Copy account identifier).

**5. Check the connection**
```powershell
python pipeline/connection.py
```
Expected:
```
Connected as SVC_LEANTECH | role LEANTECH_PIPELINE | warehouse LEANTECH_WH | database SALES_DW | ...
```

## Run the pipeline

### Option A: with Airflow
```powershell
docker compose up -d
docker compose exec airflow airflow dags test sales_pipeline
```
The first `up` builds the image and takes several minutes. The DAG runs `load_raw` → `dbt_source_freshness` → `dbt_build` and ends with `state=success`. The Airflow UI is at http://localhost:8080 (no login, local only): the `sales_pipeline` DAG, its runs and the logs of each task. Stop it with `docker compose down`.

### Option B: step by step
```powershell
python pipeline/load_raw.py
```
Loads the CSV files in `data/` into the `RAW` schema. Expected on the first run:
```
customers  202 rows loaded now, 202 rows in RAW.CUSTOMERS
products   50 rows loaded now, 50 rows in RAW.PRODUCTS
sales      5,003 rows loaded now, 5,003 rows in RAW.SALES
```
A second run loads 0 rows: files already loaded are skipped.

dbt reads the connection from environment variables, so load `.env` into the session first:
```powershell
Get-Content .env | Where-Object { $_ -match '^[A-Z_]+=' } | ForEach-Object { $k, $v = $_ -split '=', 2; Set-Item "env:$k" $v }
dbt source freshness --project-dir dbt --profiles-dir dbt
dbt build --project-dir dbt --profiles-dir dbt
```
(macOS or Linux: `set -a; source .env; set +a`.) Expected: freshness `PASS` for the three raw tables, then `Done. PASS=17 ... ERROR=0`. The tables are in `SALES_DW.ANALYTICS`; every rejected or flagged source record is in `SALES_DW.ANALYTICS.DATA_QUALITY_ISSUES`.

The sample files are already in `data/`. `python data/generate_samples.py` regenerates them, identical, from a fixed seed.

## SQL answers
Run in Snowsight, after the pipeline, with **Run All**:
- `sql/sql_exercises.sql`: section 1, with its own temporary sample tables.
- `sql/insights.sql`: section 2.3, the three queries on the star schema.
- `sql/snowflake_features.sql`: section 2.4, Time Travel and cloning on a copy of `fact_sales`.

## Troubleshooting
- **`certificate verify failed`:** an antivirus inspecting HTTPS traffic (Avast, Kaspersky...) replaces Snowflake's certificate with its own, and Python rejects it. Exclude `*.snowflakecomputing.com` from its HTTPS scanning.
- **`Role 'LEANTECH_PIPELINE' ... is not granted` or `warehouse None`:** part of `setup/snowflake_setup.sql` did not run. Run the whole file again with Run All; it is safe to repeat.
- **dbt `KeyError ... apply_grants.sql`:** a parse cache written by another dbt installation. Delete `dbt/target/` and run again.

## Layout
```
setup/      Snowflake setup and key generation
data/       sample CSV files and their generator
pipeline/   connection and raw load
dbt/        staging and marts models, seed, tests, metadata, data product README
sql/        SQL answers (sections 1, 2.3, 2.4)
dags/       Airflow DAG
```
