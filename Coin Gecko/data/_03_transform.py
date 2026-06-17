import logging

from data.config import SQL_DIR
from data.database import get_connection, run_sql_file

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

TRANSFORM_SQL = SQL_DIR / "transform" / "staging_transform.sql"


def _validate_transformations(cursor) -> None:
    logger.info("Transformation validation:")

    cursor.execute(
        """
        SELECT
            COUNT(*) FILTER (WHERE symbol IS NULL) AS null_symbols,
            COUNT(*) FILTER (WHERE current_price IS NULL) AS null_prices,
            COUNT(*) FILTER (WHERE market_cap IS NULL) AS null_market_caps
        FROM staging.stg_crypto_data
        """
    )
    nulls = cursor.fetchone()
    logger.info(
        "  Null symbols: %s, null prices: %s, null market caps: %s",
        nulls[0],
        nulls[1],
        nulls[2],
    )

    cursor.execute(
        """
        SELECT
            COUNT(*) AS total,
            COUNT(*) FILTER (WHERE current_price IS NOT NULL) AS valid_prices,
            COUNT(*) FILTER (WHERE market_cap_rank IS NOT NULL) AS valid_ranks
        FROM staging.stg_crypto_data
        """
    )
    types = cursor.fetchone()
    logger.info(
        "  Rows: %s | prices present: %s | ranks present: %s",
        types[0],
        types[1],
        types[2],
    )

    cursor.execute(
        """
        SELECT
            COUNT(*) FILTER (WHERE volatility_24h_pct IS NOT NULL),
            COUNT(*) FILTER (WHERE volume_to_mcap_ratio IS NOT NULL),
            COUNT(*) FILTER (WHERE supply_utilization_pct IS NOT NULL)
        FROM staging.stg_crypto_data
        """
    )
    metrics = cursor.fetchone()
    logger.info(
        "  Derived metrics: volatility=%s, volume_ratio=%s, supply_util=%s",
        metrics[0],
        metrics[1],
        metrics[2],
    )

    cursor.execute(
        """
        SELECT id, symbol, current_price, volatility_24h_pct,
               volume_to_mcap_ratio, data_quality_flag
        FROM staging.stg_crypto_data
        ORDER BY market_cap_rank
        LIMIT 1
        """
    )
    sample = cursor.fetchone()
    if sample:
        logger.info("  Sample record: %s", sample)


def transform() -> None:
    with get_connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute("SELECT COUNT(*) FROM raw.raw_crypto_data")
            raw_count = cursor.fetchone()[0]
            logger.info("Starting transformation (%s raw records)", raw_count)

            if raw_count == 0:
                raise RuntimeError("No raw data found. Run extract and load_raw first.")

        run_sql_file(conn, TRANSFORM_SQL)

        with conn.cursor() as cursor:
            cursor.execute("SELECT COUNT(*) FROM staging.stg_crypto_snapshots")
            snapshot_count = cursor.fetchone()[0]
            cursor.execute("SELECT COUNT(*) FROM staging.stg_crypto_data")
            latest_count = cursor.fetchone()[0]
            logger.info(
                "Snapshots: %s rows | Latest view: %s coins | Filtered from raw: %s",
                snapshot_count,
                latest_count,
                raw_count - snapshot_count,
            )
            _validate_transformations(cursor)

    logger.info("Transformation complete")


if __name__ == "__main__":
    transform()
