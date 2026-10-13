
from datetime import datetime, timedelta

from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import DAG

PROJECT_DIR = "/opt/project"
VENV = "/home/airflow/pipeline-venv/bin"
# The project folder is shared with the host: keep dbt's working files apart from the host's.
DBT_ARGS = "--project-dir dbt --profiles-dir dbt --target-path /tmp/dbt-target"

with DAG(
    dag_id="sales_pipeline",
    schedule="@daily",
    start_date=datetime(2026, 10, 1),
    catchup=False,
    default_args={"retries": 2, "retry_delay": timedelta(minutes=2)},
    tags=["sales"],
) as dag:
    load_raw = BashOperator(
        task_id="load_raw",
        bash_command=f"{VENV}/python pipeline/load_raw.py",
        cwd=PROJECT_DIR,
    )
    # Stop before transforming if the raw data is older than the freshness rules in _sources.yml.
    source_freshness = BashOperator(
        task_id="dbt_source_freshness",
        bash_command=f"{VENV}/dbt source freshness {DBT_ARGS}",
        cwd=PROJECT_DIR,
    )
    # Models plus the tests declared in the YAML metadata: a failed rule fails the run.
    dbt_build = BashOperator(
        task_id="dbt_build",
        bash_command=f"{VENV}/dbt build {DBT_ARGS}",
        cwd=PROJECT_DIR,
    )

    load_raw >> source_freshness >> dbt_build
