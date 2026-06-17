CREATE TABLE IF NOT EXISTS mart.dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    year INTEGER NOT NULL,
    quarter INTEGER NOT NULL,
    month INTEGER NOT NULL,
    month_name TEXT NOT NULL,
    day_of_month INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    day_name TEXT NOT NULL,
    is_weekend BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS mart.dim_coin (
    coin_key SERIAL PRIMARY KEY,
    coin_id TEXT NOT NULL UNIQUE,
    symbol TEXT NOT NULL,
    name TEXT NOT NULL,
    image TEXT
);

CREATE TABLE IF NOT EXISTS mart.fact_crypto_market_snapshot (
    fact_key BIGSERIAL PRIMARY KEY,
    coin_key INTEGER NOT NULL REFERENCES mart.dim_coin (coin_key),
    date_key INTEGER NOT NULL REFERENCES mart.dim_date (date_key),
    extracted_at TIMESTAMPTZ NOT NULL,
    market_cap_rank INTEGER,
    current_price DOUBLE PRECISION,
    market_cap DOUBLE PRECISION,
    fully_diluted_valuation DOUBLE PRECISION,
    total_volume DOUBLE PRECISION,
    high_24h DOUBLE PRECISION,
    low_24h DOUBLE PRECISION,
    price_change_24h DOUBLE PRECISION,
    price_change_percentage_24h DOUBLE PRECISION,
    market_cap_change_24h DOUBLE PRECISION,
    market_cap_change_percentage_24h DOUBLE PRECISION,
    circulating_supply DOUBLE PRECISION,
    total_supply DOUBLE PRECISION,
    max_supply DOUBLE PRECISION,
    ath DOUBLE PRECISION,
    ath_change_percentage DOUBLE PRECISION,
    atl DOUBLE PRECISION,
    atl_change_percentage DOUBLE PRECISION,
    volatility_24h_pct DOUBLE PRECISION,
    volume_to_mcap_ratio DOUBLE PRECISION,
    supply_utilization_pct DOUBLE PRECISION,
    price_from_ath_pct DOUBLE PRECISION,
    UNIQUE (coin_key, extracted_at)
);

CREATE INDEX IF NOT EXISTS idx_fact_date_key ON mart.fact_crypto_market_snapshot (date_key);
CREATE INDEX IF NOT EXISTS idx_fact_coin_key ON mart.fact_crypto_market_snapshot (coin_key);
CREATE INDEX IF NOT EXISTS idx_fact_extracted_at ON mart.fact_crypto_market_snapshot (extracted_at);
