-- Power BI primary source (denormalized star schema)
SELECT * FROM mart.v_market_dashboard LIMIT 100;

-- Latest snapshot only
SELECT * FROM mart.v_market_dashboard
WHERE extracted_at = (SELECT MAX(extracted_at) FROM mart.v_market_dashboard);

-- Top 10 by market cap (latest run)
SELECT symbol, current_price, market_cap, market_cap_rank
FROM mart.v_market_dashboard
WHERE extracted_at = (SELECT MAX(extracted_at) FROM mart.v_market_dashboard)
ORDER BY market_cap_rank
LIMIT 10;

-- Price trend for Bitcoin across pipeline runs
SELECT snapshot_date, extracted_at, current_price, market_cap
FROM mart.v_market_dashboard
WHERE coin_id = 'bitcoin'
ORDER BY extracted_at;

-- Star schema: fact + dimensions
SELECT
    c.symbol,
    d.full_date,
    f.current_price,
    f.volatility_24h_pct
FROM mart.fact_crypto_market_snapshot f
JOIN mart.dim_coin c ON f.coin_key = c.coin_key
JOIN mart.dim_date d ON f.date_key = d.date_key
ORDER BY f.extracted_at DESC, f.market_cap_rank
LIMIT 20;
