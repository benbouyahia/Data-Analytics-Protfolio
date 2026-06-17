DROP VIEW IF EXISTS staging.stg_crypto_data;
DROP TABLE IF EXISTS staging.stg_crypto_data;
DROP TABLE IF EXISTS staging.stg_crypto_snapshots;

CREATE TABLE staging.stg_crypto_snapshots AS
WITH cleaned_data AS (
    SELECT
        id,
        UPPER(COALESCE(symbol, '')) AS symbol,
        COALESCE(name, '') AS name,
        image,
        COALESCE(current_price, 0)::DOUBLE PRECISION AS current_price,
        COALESCE(market_cap, 0)::DOUBLE PRECISION AS market_cap,
        COALESCE(market_cap_rank, 0)::INTEGER AS market_cap_rank,
        COALESCE(fully_diluted_valuation, 0)::DOUBLE PRECISION AS fully_diluted_valuation,
        COALESCE(total_volume, 0)::DOUBLE PRECISION AS total_volume,
        COALESCE(high_24h, 0)::DOUBLE PRECISION AS high_24h,
        COALESCE(low_24h, 0)::DOUBLE PRECISION AS low_24h,
        last_updated::TIMESTAMPTZ AS last_updated_dt,
        ath_date::TIMESTAMPTZ AS ath_date_dt,
        atl_date::TIMESTAMPTZ AS atl_date_dt,
        COALESCE(price_change_24h, 0)::DOUBLE PRECISION AS price_change_24h,
        COALESCE(price_change_percentage_24h, 0)::DOUBLE PRECISION AS price_change_percentage_24h,
        COALESCE(market_cap_change_24h, 0)::DOUBLE PRECISION AS market_cap_change_24h,
        COALESCE(market_cap_change_percentage_24h, 0)::DOUBLE PRECISION AS market_cap_change_percentage_24h,
        COALESCE(circulating_supply, 0)::DOUBLE PRECISION AS circulating_supply,
        COALESCE(total_supply, 0)::DOUBLE PRECISION AS total_supply,
        COALESCE(max_supply, 0)::DOUBLE PRECISION AS max_supply,
        COALESCE(ath, 0)::DOUBLE PRECISION AS ath,
        COALESCE(ath_change_percentage, 0)::DOUBLE PRECISION AS ath_change_percentage,
        COALESCE(atl, 0)::DOUBLE PRECISION AS atl,
        COALESCE(atl_change_percentage, 0)::DOUBLE PRECISION AS atl_change_percentage,
        roi,
        extracted_at,
        CASE
            WHEN COALESCE(current_price, 0) > 0
            THEN ROUND(
                ((COALESCE(high_24h, 0) - COALESCE(low_24h, 0)) / current_price * 100)::NUMERIC,
                2
            )::DOUBLE PRECISION
            ELSE NULL
        END AS volatility_24h_pct,
        CASE
            WHEN COALESCE(market_cap, 0) > 0
            THEN ROUND(
                (COALESCE(total_volume, 0) / market_cap)::NUMERIC,
                4
            )::DOUBLE PRECISION
            ELSE NULL
        END AS volume_to_mcap_ratio,
        CASE
            WHEN COALESCE(max_supply, 0) > 0
            THEN ROUND(
                (COALESCE(circulating_supply, 0) / max_supply * 100)::NUMERIC,
                2
            )::DOUBLE PRECISION
            ELSE NULL
        END AS supply_utilization_pct,
        CASE
            WHEN COALESCE(ath, 0) > 0
            THEN ROUND(
                ((current_price - ath) / ath * 100)::NUMERIC,
                2
            )::DOUBLE PRECISION
            ELSE NULL
        END AS price_from_ath_pct,
        CASE
            WHEN id IS NULL OR symbol IS NULL OR current_price IS NULL THEN 'INVALID'
            WHEN COALESCE(current_price, 0) <= 0 THEN 'INVALID_PRICE'
            WHEN COALESCE(max_supply, 0) > 0
                 AND COALESCE(circulating_supply, 0) > max_supply THEN 'INVALID_SUPPLY'
            ELSE 'VALID'
        END AS data_quality_flag
    FROM raw.raw_crypto_data
)
SELECT
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
    atl,
    atl_change_percentage,
    roi,
    extracted_at,
    last_updated_dt,
    ath_date_dt,
    atl_date_dt,
    volatility_24h_pct,
    volume_to_mcap_ratio,
    supply_utilization_pct,
    price_from_ath_pct,
    data_quality_flag
FROM cleaned_data
WHERE data_quality_flag = 'VALID';

CREATE INDEX idx_stg_snap_id ON staging.stg_crypto_snapshots (id);
CREATE INDEX idx_stg_snap_extracted_at ON staging.stg_crypto_snapshots (extracted_at);
CREATE INDEX idx_stg_snap_symbol ON staging.stg_crypto_snapshots (symbol);

CREATE VIEW staging.stg_crypto_data AS
SELECT DISTINCT ON (id)
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
    atl,
    atl_change_percentage,
    roi,
    extracted_at,
    last_updated_dt,
    ath_date_dt,
    atl_date_dt,
    volatility_24h_pct,
    volume_to_mcap_ratio,
    supply_utilization_pct,
    price_from_ath_pct,
    data_quality_flag
FROM staging.stg_crypto_snapshots
ORDER BY id, extracted_at DESC;
