CREATE TABLE IF NOT EXISTS raw.raw_crypto_data (
    id TEXT NOT NULL,
    symbol TEXT,
    name TEXT,
    image TEXT,
    current_price DOUBLE PRECISION,
    market_cap DOUBLE PRECISION,
    market_cap_rank INTEGER,
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
    ath_date TIMESTAMPTZ,
    atl DOUBLE PRECISION,
    atl_change_percentage DOUBLE PRECISION,
    atl_date TIMESTAMPTZ,
    roi JSONB,
    last_updated TIMESTAMPTZ,
    extracted_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (id, extracted_at)
);

CREATE INDEX IF NOT EXISTS idx_raw_id ON raw.raw_crypto_data (id);
CREATE INDEX IF NOT EXISTS idx_raw_extracted_at ON raw.raw_crypto_data (extracted_at);
