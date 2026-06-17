# pipeline.py

```
from data._01_extract import extract_data

from data._02_load_raw import load_raw_data

from data._03_transform import transform_data

from data._04_validate import validate_data

from data._05_load_staging import load_staging

from data.database import init_db


def run_pipeline():

    # Initialize database
    init_db()

    # Extract
    file_path = extract_data()

    # Load raw
    load_raw_data(file_path)

    # Transform
    df = transform_data()

    # Validate
    df = validate_data(df)

    # Load staging
    load_staging(df)

print("Pipeline complete")


run_pipeline()
```

# database.py

```
import sqlite3
from pathlib import Path

DB_PATH = Path("crypto.db")
SQL_DIR = Path("sql")

def get_connection():
    return sqlite3.connect(DB_PATH)

def init_db():
    conn = get_connection()
    cursor = conn.cursor()

    # Read and execute raw_tables.sql
    sql_path = SQL_DIR / "raw_tables.sql"
    sql_text = sql_path.read_text().replace('\r\n', '\n')
    cursor.executescript(sql_text)

    # Read and execute staging_tables.sql
    sql_path = SQL_DIR / "staging_tables.sql"
    sql_text = sql_path.read_text().replace('\r\n', '\n')
    cursor.executescript(sql_text)

    conn.commit()
    conn.close()
```

# _01_extract.py

```
import requests
import json
from datetime import datetime


def extract_data():

    url = "https://api.coingecko.com/api/v3/coins/markets"

    response = requests.get(
        url,
        params={
            "vs_currency": "usd",
            "per_page": 250,
            "page": 1
        }
    )

    data = response.json()

    filename = f"data/raw_{datetime.now().date()}.jsonl"

    with open(filename, "w") as f:

        for row in data:

            row["_extracted_at"] = datetime.utcnow().isoformat()

            f.write(json.dumps(row) + "\n")

    print(f"Saved {len(data)} rows")

    return filename 
```

# _02_load_raw.py

```
import json

from data.database import get_connection


def load_raw_data(file_path):

    conn = get_connection()

    cursor = conn.cursor()

    with open(file_path, "r") as f:

        for line in f:

            row = json.loads(line)

            cursor.execute("""

                INSERT OR REPLACE INTO raw_crypto_data (
                    id,
                    symbol,
                    name,
                    image,
                    current_price,
                    market_cap,
                    market_cap_rank,
                    fully_diluted_valuation,
                    total_volume,
                    high_24h,
                    low_24h,
                    price_change_24h,
                    price_change_percentage_24h,
                    market_cap_change_24h,
                    market_cap_change_percentage_24h,
                    circulating_supply,
                    total_supply,
                    max_supply,
                    ath,
                    ath_change_percentage,
                    ath_date,
                    atl,
                    atl_change_percentage,
                    atl_date,
                    roi,
                    last_updated,
                    _extracted_at
                )

                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)

            """, (

                row.get("id"),
                row.get("symbol"),
                row.get("name"),
                row.get("image"),
                row.get("current_price"),
                row.get("market_cap"),
                row.get("market_cap_rank"),
                row.get("fully_diluted_valuation"),
                row.get("total_volume"),
                row.get("high_24h"),
                row.get("low_24h"),
                row.get("price_change_24h"),
                row.get("price_change_percentage_24h"),
                row.get("market_cap_change_24h"),
                row.get("market_cap_change_percentage_24h"),
                row.get("circulating_supply"),
                row.get("total_supply"),
                row.get("max_supply"),
                row.get("ath"),
                row.get("ath_change_percentage"),
                row.get("ath_date"),
                row.get("atl"),
                row.get("atl_change_percentage"),
                row.get("atl_date"),
                json.dumps(row.get("roi")),
                row.get("last_updated"),
                row.get("_extracted_at")

            ))

    conn.commit()

    conn.close()

    print("Loaded raw data")
```

# _03_transform.py

```
import sqlite3
import logging
from pathlib import Path

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

DB_PATH = "crypto.db"
SQL_DIR = Path("sql")

def load_transformation_sql():
    """Load transformation SQL from file"""
    sql_file = SQL_DIR / "transformations.sql"
    with open(sql_file, 'r') as f:
        return f.read()

def transform():
    """Execute transformation SQL and load into staging table"""
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
      
        logger.info("🔄 Starting transformation...")
      
        # Get row count before transformation
        cursor.execute("SELECT COUNT(*) FROM raw_crypto_data")
        raw_count = cursor.fetchone()[0]
        logger.info(f"   Raw records: {raw_count}")
      
        # Execute transformation SQL
        transformation_sql = load_transformation_sql()
        cursor.executescript(transformation_sql)
        conn.commit()
      
        # Get row count after transformation
        cursor.execute("SELECT COUNT(*) FROM stg_crypto_data")
        staged_count = cursor.fetchone()[0]
        logger.info(f"   Staged records: {staged_count}")
        logger.info(f"   Filtered out: {raw_count - staged_count} records")
      
        # Validate transformations
        validate_transformations(cursor)
      
        conn.close()
        logger.info("✅ Transformation complete!")
      
    except Exception as e:
        logger.error(f"❌ Transformation failed: {e}")
        raise

def validate_transformations(cursor):
    """Run quality checks on staged data"""
    logger.info("\n📊 Transformation Validation:")
  
    # Check 1: Null values in critical fields
    cursor.execute("""
        SELECT 
            COUNT(CASE WHEN symbol IS NULL THEN 1 END) as null_symbols,
            COUNT(CASE WHEN current_price IS NULL THEN 1 END) as null_prices,
            COUNT(CASE WHEN market_cap IS NULL THEN 1 END) as null_market_caps
        FROM stg_crypto_data
    """)
    nulls = cursor.fetchone()
    logger.info(f"   Null symbols: {nulls[0]}, Null prices: {nulls[1]}, Null market caps: {nulls[2]}")
  
    # Check 2: Data type verification
    cursor.execute("""
        SELECT 
            COUNT(*) as total,
            COUNT(CASE WHEN typeof(current_price) = 'real' THEN 1 END) as numeric_prices,
            COUNT(CASE WHEN typeof(market_cap_rank) = 'integer' THEN 1 END) as numeric_ranks
        FROM stg_crypto_data
    """)
    types = cursor.fetchone()
    logger.info(f"   Type check: {types[1]}/{types[0]} prices are numeric, {types[2]}/{types[0]} ranks are integers")
  
    # Check 3: Derived metrics
    cursor.execute("""
        SELECT 
            COUNT(CASE WHEN volatility_24h_pct IS NOT NULL THEN 1 END) as volatility_calculated,
            COUNT(CASE WHEN volume_to_mcap_ratio IS NOT NULL THEN 1 END) as volume_ratio_calculated,
            COUNT(CASE WHEN supply_utilization_pct IS NOT NULL THEN 1 END) as supply_util_calculated
        FROM stg_crypto_data
    """)
    metrics = cursor.fetchone()
    logger.info(f"   Metrics calculated: {metrics[0]} volatility, {metrics[1]} volume ratios, {metrics[2]} supply utilization")
  
    # Check 4: Sample data (show first record)
    cursor.execute("""
        SELECT id, symbol, current_price, volatility_24h_pct, volume_to_mcap_ratio, data_quality_flag
        FROM stg_crypto_data
        LIMIT 1
    """)
    sample = cursor.fetchone()
    if sample:
        logger.info(f"\n   Sample record: {sample}")

if __name__ == "__main__":
    transform()
```

# raw_tables.sql

```
CREATE TABLE IF NOT EXISTS raw_crypto_data (
  id TEXT PRIMARY KEY,
  symbol TEXT,
  name TEXT,
  image TEXT,
  current_price REAL,
  market_cap REAL,
  market_cap_rank INTEGER,
  fully_diluted_valuation REAL,
  total_volume REAL,
  high_24h REAL,
  low_24h REAL,
  price_change_24h REAL,
  price_change_percentage_24h REAL,
  market_cap_change_24h REAL,
  market_cap_change_percentage_24h REAL,
  circulating_supply REAL,
  total_supply REAL,
  max_supply REAL,
  ath REAL,
  ath_change_percentage REAL,
  ath_date TEXT,
  atl REAL,
  atl_change_percentage REAL,
  atl_date TEXT,
  roi TEXT,
  last_updated TEXT,
  _extracted_at TEXT
);
```

# staging_tables.sql

```
CREATE TABLE IF NOT EXISTS stg_crypto_data (
  id TEXT,
  symbol TEXT,
  name TEXT,
  image TEXT,
  current_price REAL,
  market_cap REAL,
  market_cap_rank INTEGER,
  fully_diluted_valuation REAL,
  total_volume REAL,
  high_24h REAL,
  low_24h REAL,
  price_change_24h REAL,
  price_change_percentage_24h REAL,
  market_cap_change_24h REAL,
  market_cap_change_percentage_24h REAL,
  circulating_supply REAL,
  total_supply REAL,
  max_supply REAL,
  ath REAL,
  ath_change_percentage REAL,
  ath_date TEXT,
  atl REAL,
  atl_change_percentage REAL,
  atl_date TEXT,
  roi TEXT,
  last_updated TEXT,
  _extracted_at TEXT
);

```

# transformations.sql

```
-- Drop staging table if exists (or use CREATE TABLE IF NOT EXISTS)
DROP TABLE IF EXISTS stg_crypto_data;

-- ============================================================================
-- MAIN TRANSFORMATION LOGIC
-- ============================================================================
CREATE TABLE stg_crypto_data AS
WITH cleaned_data AS (
    -- TYPE CONVERSIONS & CLEANING
    SELECT
        id,
        UPPER(COALESCE(symbol, '')) AS symbol,
        COALESCE(name, '') AS name,
        image,
      
        -- NUMERIC: Ensure valid prices
        CAST(COALESCE(current_price, 0) AS REAL) AS current_price,
        CAST(COALESCE(market_cap, 0) AS REAL) AS market_cap,
        CAST(COALESCE(market_cap_rank, 0) AS INTEGER) AS market_cap_rank,
        CAST(COALESCE(fully_diluted_valuation, 0) AS REAL) AS fully_diluted_valuation,
        CAST(COALESCE(total_volume, 0) AS REAL) AS total_volume,
        CAST(COALESCE(high_24h, 0) AS REAL) AS high_24h,
        CAST(COALESCE(low_24h, 0) AS REAL) AS low_24h,

        -- DATE CONVERSIONS
        DATETIME(last_updated) AS last_updated_dt,
        DATETIME(ath_date) AS ath_date_dt,
        DATETIME(atl_date) AS atl_date_dt,
      
        -- PRICE CHANGES (keep original + new derived fields)
        CAST(COALESCE(price_change_24h, 0) AS REAL) AS price_change_24h,
        CAST(COALESCE(price_change_percentage_24h, 0) AS REAL) AS price_change_percentage_24h,
        CAST(COALESCE(market_cap_change_24h, 0) AS REAL) AS market_cap_change_24h,
        CAST(COALESCE(market_cap_change_percentage_24h, 0) AS REAL) AS market_cap_change_percentage_24h,
      
        -- SUPPLY DATA
        CAST(COALESCE(circulating_supply, 0) AS REAL) AS circulating_supply,
        CAST(COALESCE(total_supply, 0) AS REAL) AS total_supply,
        CAST(COALESCE(max_supply, 0) AS REAL) AS max_supply,
      
        -- ATH/ATL
        CAST(COALESCE(ath, 0) AS REAL) AS ath,
        CAST(COALESCE(ath_change_percentage, 0) AS REAL) AS ath_change_percentage,
        CAST(COALESCE(atl, 0) AS REAL) AS atl,
        CAST(COALESCE(atl_change_percentage, 0) AS REAL) AS atl_change_percentage,
      
        roi,
        _extracted_at,

        -- ====================================================================
        -- DERIVED METRICS / CALCULATIONS
        -- ====================================================================
      
        -- Volatility: Price range as % of current price
        CASE 
            WHEN CAST(COALESCE(current_price, 0) AS REAL) > 0 
            THEN ROUND(
                (CAST(COALESCE(high_24h, 0) AS REAL) - CAST(COALESCE(low_24h, 0) AS REAL)) / 
                CAST(COALESCE(current_price, 0) AS REAL) * 100, 
                2
            )
            ELSE NULL 
        END AS volatility_24h_pct,
      
        -- Volume to Market Cap Ratio (liquidity indicator)
        CASE 
            WHEN CAST(COALESCE(market_cap, 0) AS REAL) > 0 
            THEN ROUND(
                CAST(COALESCE(total_volume, 0) AS REAL) / CAST(COALESCE(market_cap, 0) AS REAL), 
                4
            )
            ELSE NULL 
        END AS volume_to_mcap_ratio,

        -- Supply Utilization: Circulating as % of Max Supply
        CASE 
            WHEN CAST(COALESCE(max_supply, 0) AS REAL) > 0 
            THEN ROUND(
                CAST(COALESCE(circulating_supply, 0) AS REAL) / CAST(COALESCE(max_supply, 0) AS REAL) * 100, 
                2
            )
            ELSE NULL 
        END AS supply_utilization_pct,
      
        -- Price from ATH (% decline from peak)
        CASE 
            WHEN CAST(COALESCE(ath, 0) AS REAL) > 0 
            THEN ROUND(
                (CAST(COALESCE(current_price, 0) AS REAL) - CAST(COALESCE(ath, 0) AS REAL)) / 
                CAST(COALESCE(ath, 0) AS REAL) * 100, 
                2
            )
            ELSE NULL 
        END AS price_from_ath_pct,
      
        -- Quality Flag: Records with critical missing data
        CASE 
            WHEN id IS NULL OR symbol IS NULL OR current_price IS NULL THEN 'INVALID'
            WHEN CAST(COALESCE(current_price, 0) AS REAL) <= 0 THEN 'INVALID_PRICE'
            WHEN CAST(COALESCE(circulating_supply, 0) AS REAL) > CAST(COALESCE(max_supply, 0) AS REAL) THEN 'INVALID_SUPPLY'
            ELSE 'VALID'
        END AS data_quality_flag
      
    FROM raw_crypto_data
),

-- ============================================================================
-- FINAL FILTERING & DEDUPLICATION
-- ============================================================================
final_data AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY id ORDER BY _extracted_at DESC) AS row_num
    FROM cleaned_data
    WHERE data_quality_flag = 'VALID'  -- Only valid records
)

SELECT
    id, symbol, name, image, current_price, market_cap, market_cap_rank,
    fully_diluted_valuation, total_volume, high_24h, low_24h,
    price_change_24h, price_change_percentage_24h, market_cap_change_24h,
    market_cap_change_percentage_24h, circulating_supply, total_supply, max_supply,
    ath, ath_change_percentage, atl, atl_change_percentage,
    roi, _extracted_at, last_updated_dt, ath_date_dt, atl_date_dt,
    volatility_24h_pct, volume_to_mcap_ratio, supply_utilization_pct,
    price_from_ath_pct, data_quality_flag
FROM final_data
WHERE row_num = 1  -- Keep only latest version of each coin
ORDER BY market_cap_rank;

-- ============================================================================
-- CREATE INDEXES FOR ANALYTICS PERFORMANCE
-- ============================================================================
CREATE INDEX idx_stg_symbol ON stg_crypto_data(symbol);
CREATE INDEX idx_stg_market_cap_rank ON stg_crypto_data(market_cap_rank);
CREATE INDEX idx_stg_extracted_at ON stg_crypto_data(_extracted_at);
```
