
import logging
from connection import REPO_ROOT, connect

log = logging.getLogger("load_raw")

TABLES = {
    "customers": ["CUSTOMER_ID", "NAME", "EMAIL", "COUNTRY"],
    "products": ["PRODUCT_ID", "PRODUCT_NAME", "CATEGORY", "PRICE"],
    "sales": ["TRANSACTION_ID", "SALE_DATE", "CUSTOMER_ID", "PRODUCT_ID", "AMOUNT"],
}

SETUP = [
    "CREATE SCHEMA IF NOT EXISTS RAW",
    "CREATE FILE FORMAT IF NOT EXISTS RAW.CSV_FORMAT "
    "TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '\"' ENCODING = 'UTF8'",
    "CREATE STAGE IF NOT EXISTS RAW.LANDING FILE_FORMAT = RAW.CSV_FORMAT",
]


def create_table(cur, name, columns):
    cur.execute(
        f"CREATE TABLE IF NOT EXISTS RAW.{name.upper()} ("
        + ", ".join(f"{c} VARCHAR" for c in columns)
        + ", _FILE VARCHAR, _ROW NUMBER, _LOADED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP())"
    )


def load(cur, name, columns):
    path = (REPO_ROOT / "data" / f"{name}.csv").as_posix()

    cur.execute(f"PUT 'file://{path}' @RAW.LANDING/{name}/ AUTO_COMPRESS = TRUE OVERWRITE = FALSE")
    positions = ", ".join(f"${i}" for i in range(1, len(columns) + 1))
    results = cur.execute(
        f"COPY INTO RAW.{name.upper()} ({', '.join(columns)}, _FILE, _ROW) "
        f"FROM (SELECT {positions}, METADATA$FILENAME, METADATA$FILE_ROW_NUMBER FROM @RAW.LANDING/{name}/) "
        "ON_ERROR = ABORT_STATEMENT"
    ).fetchall()
    loaded = sum(row[3] for row in results if len(row) > 3 and isinstance(row[3], int))
    total = cur.execute(f"SELECT COUNT(*) FROM RAW.{name.upper()}").fetchone()[0]
    log.info("%-10s %s rows loaded now, %s rows in RAW.%s", name, f"{loaded:,}", f"{total:,}", name.upper())


def main():
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
    with connect() as conn:
        cur = conn.cursor()
        for statement in SETUP:
            cur.execute(statement)
        for name, columns in TABLES.items():
            create_table(cur, name, columns)
            load(cur, name, columns)


if __name__ == "__main__":
    main()
