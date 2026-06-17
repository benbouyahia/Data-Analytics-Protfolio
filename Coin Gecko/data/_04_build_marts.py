import logging

from data.config import SQL_DIR
from data.database import get_connection, run_sql_file

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

BUILD_MARTS_SQL = SQL_DIR / "mart" / "build_marts.sql"


def build_marts() -> None:
    with get_connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute("SELECT COUNT(*) FROM staging.stg_crypto_snapshots")
            snapshot_count = cursor.fetchone()[0]
            if snapshot_count == 0:
                raise RuntimeError("No staging snapshots found. Run transform first.")

        logger.info("Building mart layer from %s snapshots...", snapshot_count)
        run_sql_file(conn, BUILD_MARTS_SQL)

        with conn.cursor() as cursor:
            cursor.execute("SELECT COUNT(*) FROM mart.dim_coin")
            coin_count = cursor.fetchone()[0]
            cursor.execute("SELECT COUNT(*) FROM mart.dim_date")
            date_count = cursor.fetchone()[0]
            cursor.execute("SELECT COUNT(*) FROM mart.fact_crypto_market_snapshot")
            fact_count = cursor.fetchone()[0]
            cursor.execute(
                "SELECT COUNT(DISTINCT extracted_at) FROM mart.fact_crypto_market_snapshot"
            )
            run_count = cursor.fetchone()[0]

    logger.info(
        "Mart complete: %s coins, %s calendar dates, %s fact rows (%s pipeline runs)",
        coin_count,
        date_count,
        fact_count,
        run_count,
    )
    logger.info("Power BI: connect to mart.v_market_dashboard")


if __name__ == "__main__":
    build_marts()
