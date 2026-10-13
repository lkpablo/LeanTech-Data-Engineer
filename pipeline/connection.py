
import os
from pathlib import Path

import snowflake.connector
from dotenv import load_dotenv

REPO_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(REPO_ROOT / ".env")


def connect():
    return snowflake.connector.connect(
        account=os.environ["SNOWFLAKE_ACCOUNT"],
        user=os.environ["SNOWFLAKE_USER"],
        authenticator="SNOWFLAKE_JWT",
        private_key_file=str(REPO_ROOT / os.environ["SNOWFLAKE_PRIVATE_KEY_PATH"]),
        role=os.environ["SNOWFLAKE_ROLE"],
        warehouse=os.environ["SNOWFLAKE_WAREHOUSE"],
        database=os.environ["SNOWFLAKE_DATABASE"],
    )


if __name__ == "__main__":
    with connect() as conn:
        user, role, warehouse, database, version = conn.cursor().execute(
            "SELECT CURRENT_USER(), CURRENT_ROLE(), CURRENT_WAREHOUSE(), CURRENT_DATABASE(), CURRENT_VERSION()"
        ).fetchone()
    print(f"Connected as {user} | role {role} | warehouse {warehouse} | database {database} | Snowflake {version}")
