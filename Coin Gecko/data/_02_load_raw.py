import json
from datetime import datetime

from psycopg2.extras import Json, execute_batch

from data.database import get_connection

UPSERT_SQL = """
INSERT INTO raw.raw_crypto_data (
    id, symbol, name, image, current_price, market_cap, market_cap_rank,
    fully_diluted_valuation, total_volume, high_24h, low_24h,
    price_change_24h, price_change_percentage_24h,
    market_cap_change_24h, market_cap_change_percentage_24h,
    circulating_supply, total_supply, max_supply,
    ath, ath_change_percentage, ath_date, atl, atl_change_percentage, atl_date,
    roi, last_updated, extracted_at
)
VALUES (
    %(id)s, %(symbol)s, %(name)s, %(image)s, %(current_price)s, %(market_cap)s,
    %(market_cap_rank)s, %(fully_diluted_valuation)s, %(total_volume)s,
    %(high_24h)s, %(low_24h)s, %(price_change_24h)s, %(price_change_percentage_24h)s,
    %(market_cap_change_24h)s, %(market_cap_change_percentage_24h)s,
    %(circulating_supply)s, %(total_supply)s, %(max_supply)s,
    %(ath)s, %(ath_change_percentage)s, %(ath_date)s, %(atl)s,
    %(atl_change_percentage)s, %(atl_date)s, %(roi)s, %(last_updated)s, %(extracted_at)s
)
ON CONFLICT (id, extracted_at) DO UPDATE SET
    symbol = EXCLUDED.symbol,
    name = EXCLUDED.name,
    image = EXCLUDED.image,
    current_price = EXCLUDED.current_price,
    market_cap = EXCLUDED.market_cap,
    market_cap_rank = EXCLUDED.market_cap_rank,
    fully_diluted_valuation = EXCLUDED.fully_diluted_valuation,
    total_volume = EXCLUDED.total_volume,
    high_24h = EXCLUDED.high_24h,
    low_24h = EXCLUDED.low_24h,
    price_change_24h = EXCLUDED.price_change_24h,
    price_change_percentage_24h = EXCLUDED.price_change_percentage_24h,
    market_cap_change_24h = EXCLUDED.market_cap_change_24h,
    market_cap_change_percentage_24h = EXCLUDED.market_cap_change_percentage_24h,
    circulating_supply = EXCLUDED.circulating_supply,
    total_supply = EXCLUDED.total_supply,
    max_supply = EXCLUDED.max_supply,
    ath = EXCLUDED.ath,
    ath_change_percentage = EXCLUDED.ath_change_percentage,
    ath_date = EXCLUDED.ath_date,
    atl = EXCLUDED.atl,
    atl_change_percentage = EXCLUDED.atl_change_percentage,
    atl_date = EXCLUDED.atl_date,
    roi = EXCLUDED.roi,
    last_updated = EXCLUDED.last_updated,
    extracted_at = EXCLUDED.extracted_at
"""


def _parse_timestamp(value):
    if not value:
        return None
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def _row_to_record(row: dict) -> dict:
    extracted_at = row.get("extracted_at") or row.get("_extracted_at")
    return {
        "id": row.get("id"),
        "symbol": row.get("symbol"),
        "name": row.get("name"),
        "image": row.get("image"),
        "current_price": row.get("current_price"),
        "market_cap": row.get("market_cap"),
        "market_cap_rank": row.get("market_cap_rank"),
        "fully_diluted_valuation": row.get("fully_diluted_valuation"),
        "total_volume": row.get("total_volume"),
        "high_24h": row.get("high_24h"),
        "low_24h": row.get("low_24h"),
        "price_change_24h": row.get("price_change_24h"),
        "price_change_percentage_24h": row.get("price_change_percentage_24h"),
        "market_cap_change_24h": row.get("market_cap_change_24h"),
        "market_cap_change_percentage_24h": row.get("market_cap_change_percentage_24h"),
        "circulating_supply": row.get("circulating_supply"),
        "total_supply": row.get("total_supply"),
        "max_supply": row.get("max_supply"),
        "ath": row.get("ath"),
        "ath_change_percentage": row.get("ath_change_percentage"),
        "ath_date": _parse_timestamp(row.get("ath_date")),
        "atl": row.get("atl"),
        "atl_change_percentage": row.get("atl_change_percentage"),
        "atl_date": _parse_timestamp(row.get("atl_date")),
        "roi": Json(row.get("roi")) if row.get("roi") is not None else None,
        "last_updated": _parse_timestamp(row.get("last_updated")),
        "extracted_at": _parse_timestamp(extracted_at),
    }


def load_raw_data(file_path: str) -> int:
    records = []
    with open(file_path, "r", encoding="utf-8") as f:
        for line in f:
            records.append(_row_to_record(json.loads(line)))

    with get_connection() as conn:
        with conn.cursor() as cursor:
            execute_batch(cursor, UPSERT_SQL, records, page_size=100)

    print(f"Loaded {len(records)} rows into raw.raw_crypto_data")
    return len(records)
