FROM apache/airflow:3.1.0-python3.12

# The pipeline's own environment, separate from Airflow's.
COPY requirements.txt /tmp/requirements.txt
RUN python -m venv /home/airflow/pipeline-venv \
    && /home/airflow/pipeline-venv/bin/pip install --no-cache-dir -r /tmp/requirements.txt
