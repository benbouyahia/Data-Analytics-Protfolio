-- Seed calendar dates (2020-01-01 through 2030-12-31)
INSERT INTO mart.dim_date (
    date_key,
    full_date,
    year,
    quarter,
    month,
    month_name,
    day_of_month,
    day_of_week,
    day_name,
    is_weekend
)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INTEGER AS date_key,
    d::DATE AS full_date,
    EXTRACT(YEAR FROM d)::INTEGER AS year,
    EXTRACT(QUARTER FROM d)::INTEGER AS quarter,
    EXTRACT(MONTH FROM d)::INTEGER AS month,
    TO_CHAR(d, 'Month') AS month_name,
    EXTRACT(DAY FROM d)::INTEGER AS day_of_month,
    EXTRACT(ISODOW FROM d)::INTEGER AS day_of_week,
    TO_CHAR(d, 'Dy') AS day_name,
    EXTRACT(ISODOW FROM d) IN (6, 7) AS is_weekend
FROM generate_series('2020-01-01'::DATE, '2030-12-31'::DATE, '1 day'::INTERVAL) AS d
ON CONFLICT (date_key) DO NOTHING;

-- Upsert coin dimension from all staging snapshots
INSERT INTO mart.dim_coin (coin_id, symbol, name, image)
SELECT DISTINCT ON (id)
    id AS coin_id,
    symbol,
    name,
    image
FROM staging.stg_crypto_snapshots
ORDER BY id, extracted_at DESC
ON CONFLICT (coin_id) DO UPDATE SET
    symbol = EXCLUDED.symbol,
    name = EXCLUDED.name,
    image = EXCLUDED.image;

-- Reload fact table from staging (full refresh; fine at this data volume)
TRUNCATE mart.fact_crypto_market_snapshot RESTART IDENTITY;

INSERT INTO mart.fact_crypto_market_snapshot (
    coin_key,
    date_key,
    extracted_at,
    market_cap_rank,
    current_price,
    market_cap,
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
    volatility_24h_pct,
    volume_to_mcap_ratio,
    supply_utilization_pct,
    price_from_ath_pct
)
SELECT
    c.coin_key,
    TO_CHAR(s.extracted_at AT TIME ZONE 'UTC', 'YYYYMMDD')::INTEGER AS date_key,
    s.extracted_at,
    s.market_cap_rank,
    s.current_price,
    s.market_cap,
    s.fully_diluted_valuation,
    s.total_volume,
    s.high_24h,
    s.low_24h,
    s.price_change_24h,
    s.price_change_percentage_24h,
    s.market_cap_change_24h,
    s.market_cap_change_percentage_24h,
    s.circulating_supply,
    s.total_supply,
    s.max_supply,
    s.ath,
    s.ath_change_percentage,
    s.atl,
    s.atl_change_percentage,
    s.volatility_24h_pct,
    s.volume_to_mcap_ratio,
    s.supply_utilization_pct,
    s.price_from_ath_pct
FROM staging.stg_crypto_snapshots s
JOIN mart.dim_coin c ON s.id = c.coin_id;

-- Denormalized view for Power BI (single-table import)
CREATE OR REPLACE VIEW mart.v_market_dashboard AS
SELECT
    c.coin_id,
    c.symbol,
    c.name,
    c.image,
    d.full_date AS snapshot_date,
    d.year,
    d.quarter,
    d.month,
    d.month_name,
    d.day_name,
    d.is_weekend,
    f.extracted_at,
    f.market_cap_rank,
    f.current_price,
    f.market_cap,
    f.fully_diluted_valuation,
    f.total_volume,
    f.high_24h,
    f.low_24h,
    f.price_change_24h,
    f.price_change_percentage_24h,
    f.market_cap_change_24h,
    f.market_cap_change_percentage_24h,
    f.circulating_supply,
    f.total_supply,
    f.max_supply,
    f.ath,
    f.ath_change_percentage,
    f.atl,
    f.atl_change_percentage,
    f.volatility_24h_pct,
    f.volume_to_mcap_ratio,
    f.supply_utilization_pct,
    f.price_from_ath_pct
FROM mart.fact_crypto_market_snapshot f
JOIN mart.dim_coin c ON f.coin_key = c.coin_key
JOIN mart.dim_date d ON f.date_key = d.date_key;
