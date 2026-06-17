# Data Dictionary — CoinGecko ETL Pipeline

Reference for all layers: file extract, `raw`, `staging`, and `mart`.  
Use with **Power BI** via `mart.dim_coin`, `mart.dim_date`, and `mart.fact_crypto_market_snapshot`.

---

## Layer overview

| Layer | Object | Grain | Purpose |
|-------|--------|-------|---------|
| File | `data/raw_YYYY-MM-DD.jsonl` | 1 line = 1 coin per extract run | Audit trail; offline backup of API response |
| `raw` | `raw.raw_crypto_data` | `(id, extracted_at)` | Landing zone; API-shaped history |
| `staging` | `stg_crypto_snapshots` | `(id, extracted_at)` per valid row | Cleaned + derived metrics; all history |
| `staging` | `stg_crypto_data` (view) | 1 row per `id` | Latest valid snapshot per coin only |
| `mart` | `dim_coin` | 1 row per coin | Descriptive attributes |
| `mart` | `dim_date` | 1 row per calendar day | Time intelligence |
| `mart` | `fact_crypto_market_snapshot` | `(coin_key, extracted_at)` | Measures for BI / star schema |
| `mart` | `v_market_dashboard` (view) | Same as fact + denormalized dims | Optional single-table import (not required if using star schema) |

```text
API → JSONL → raw → staging (snapshots) → mart (dims + fact) → Power BI
```

---

## File: `data/raw_YYYY-MM-DD.jsonl`

One JSON object per line (CoinGecko `/coins/markets`, top 250, USD).

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | CoinGecko id (e.g. `bitcoin`) |
| `symbol` | string | Ticker (lowercase from API) |
| `name` | string | Display name |
| `image` | string | Logo URL |
| `current_price` | number | USD price at API time |
| `market_cap` | number | Market capitalization (USD) |
| `market_cap_rank` | integer | Rank by market cap |
| `fully_diluted_valuation` | number | FDV (USD) |
| `total_volume` | number | 24h volume (USD) |
| `high_24h` | number | 24h high (USD) |
| `low_24h` | number | 24h low (USD) |
| `price_change_24h` | number | Absolute 24h price change (USD) |
| `price_change_percentage_24h` | number | **Percent** (e.g. `-2.49` = -2.49%) |
| `market_cap_change_24h` | number | Absolute 24h market cap change |
| `market_cap_change_percentage_24h` | number | **Percent** |
| `circulating_supply` | number | Coins in circulation |
| `total_supply` | number | Total supply |
| `max_supply` | number | Max supply (null if unlimited) |
| `ath` | number | All-time high price |
| `ath_change_percentage` | number | **Percent** from ATH (CoinGecko) |
| `ath_date` | ISO datetime | ATH timestamp |
| `atl` | number | All-time low price |
| `atl_change_percentage` | number | **Percent** above ATL |
| `atl_date` | ISO datetime | ATL timestamp |
| `roi` | object or null | ROI vs BTC when provided |
| `last_updated` | ISO datetime | Last API update for this coin |
| `extracted_at` | ISO datetime | Added by pipeline; run timestamp |

---

## `raw.raw_crypto_data`

**Schema:** `raw`  
**Grain:** one row per **coin per pipeline run**  
**Primary key:** `(id, extracted_at)`

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| `id` | TEXT | API | Coin identifier (PK part 1) |
| `symbol` | TEXT | API | Ticker |
| `name` | TEXT | API | Name |
| `image` | TEXT | API | Image URL |
| `current_price` | DOUBLE PRECISION | API | USD price |
| `market_cap` | DOUBLE PRECISION | API | Market cap |
| `market_cap_rank` | INTEGER | API | Cap rank |
| `fully_diluted_valuation` | DOUBLE PRECISION | API | FDV |
| `total_volume` | DOUBLE PRECISION | API | 24h volume |
| `high_24h` | DOUBLE PRECISION | API | 24h high |
| `low_24h` | DOUBLE PRECISION | API | 24h low |
| `price_change_24h` | DOUBLE PRECISION | API | 24h absolute price change |
| `price_change_percentage_24h` | DOUBLE PRECISION | API | 24h % change (already ×100) |
| `market_cap_change_24h` | DOUBLE PRECISION | API | 24h absolute cap change |
| `market_cap_change_percentage_24h` | DOUBLE PRECISION | API | 24h cap % change |
| `circulating_supply` | DOUBLE PRECISION | API | Circulating supply |
| `total_supply` | DOUBLE PRECISION | API | Total supply |
| `max_supply` | DOUBLE PRECISION | API | Max supply |
| `ath` | DOUBLE PRECISION | API | All-time high |
| `ath_change_percentage` | DOUBLE PRECISION | API | % from ATH |
| `ath_date` | TIMESTAMPTZ | API | ATH date |
| `atl` | DOUBLE PRECISION | API | All-time low |
| `atl_change_percentage` | DOUBLE PRECISION | API | % from ATL |
| `atl_date` | TIMESTAMPTZ | API | ATL date |
| `roi` | JSONB | API | ROI object serialized |
| `last_updated` | TIMESTAMPTZ | API | API last update |
| `extracted_at` | TIMESTAMPTZ | Pipeline | Snapshot time (PK part 2) |

**Load behavior:** `INSERT ... ON CONFLICT (id, extracted_at) DO UPDATE` — re-running the same timestamp updates in place; new runs append new rows.

---

## `staging.stg_crypto_snapshots`

**Schema:** `staging`  
**Grain:** one row per **valid** `(id, extracted_at)`  
**Built by:** `sql/transform/staging_transform.sql` (rebuilt each pipeline run)

Includes cleaning (uppercase symbol, `COALESCE`), derived metrics, and `data_quality_flag` filtering (`VALID` only in output).

| Column | Type | Source | Description |
|--------|------|--------|-------------|
| `id` | TEXT | raw | Coin id |
| `symbol` | TEXT | raw | `UPPER(symbol)` |
| `name` | TEXT | raw | Name (empty string if null) |
| `image` | TEXT | raw | Image URL |
| `current_price` | DOUBLE PRECISION | raw | Price (0 if null) |
| `market_cap` | DOUBLE PRECISION | raw | Market cap |
| `market_cap_rank` | INTEGER | raw | Rank |
| `fully_diluted_valuation` | DOUBLE PRECISION | raw | FDV |
| `total_volume` | DOUBLE PRECISION | raw | 24h volume |
| `high_24h` | DOUBLE PRECISION | raw | 24h high |
| `low_24h` | DOUBLE PRECISION | raw | 24h low |
| `price_change_24h` | DOUBLE PRECISION | raw | 24h price change |
| `price_change_percentage_24h` | DOUBLE PRECISION | raw | 24h % (already percent) |
| `market_cap_change_24h` | DOUBLE PRECISION | raw | 24h cap change |
| `market_cap_change_percentage_24h` | DOUBLE PRECISION | raw | 24h cap % |
| `circulating_supply` | DOUBLE PRECISION | raw | Circulating supply |
| `total_supply` | DOUBLE PRECISION | raw | Total supply |
| `max_supply` | DOUBLE PRECISION | raw | Max supply |
| `ath` | DOUBLE PRECISION | raw | ATH price |
| `ath_change_percentage` | DOUBLE PRECISION | raw | % from ATH (API) |
| `atl` | DOUBLE PRECISION | raw | ATL price |
| `atl_change_percentage` | DOUBLE PRECISION | raw | % from ATL (API) |
| `roi` | JSONB | raw | ROI (not loaded to fact) |
| `extracted_at` | TIMESTAMPTZ | raw | Snapshot time |
| `last_updated_dt` | TIMESTAMPTZ | raw | `last_updated` cast |
| `ath_date_dt` | TIMESTAMPTZ | raw | `ath_date` cast |
| `atl_date_dt` | TIMESTAMPTZ | raw | `atl_date` cast |
| `volatility_24h_pct` | DOUBLE PRECISION | **Derived** | `(high_24h - low_24h) / current_price × 100` |
| `volume_to_mcap_ratio` | DOUBLE PRECISION | **Derived** | `total_volume / market_cap` |
| `supply_utilization_pct` | DOUBLE PRECISION | **Derived** | `circulating / max_supply × 100` (null if no max) |
| `price_from_ath_pct` | DOUBLE PRECISION | **Derived** | `(current_price - ath) / ath × 100` |
| `data_quality_flag` | TEXT | **Derived** | `VALID`, `INVALID`, `INVALID_PRICE`, `INVALID_SUPPLY` (only `VALID` rows kept) |

**Power BI:** Use for full history. For “current market” without duplicate symbols, prefer `staging.stg_crypto_data` or filter fact to latest `extracted_at`.

---

## `staging.stg_crypto_data` (view)

**Grain:** **one row per `id`** — latest `extracted_at` per coin  
**Definition:** `DISTINCT ON (id) ... ORDER BY id, extracted_at DESC` from `stg_crypto_snapshots`

Same columns as `stg_crypto_snapshots` (except no `data_quality_flag` in the view select list).  
**Use for:** Current-state tables, KPIs, rankings when you want ~250 rows and no history duplication.

---

## `mart.dim_coin`

**Grain:** one row per coin  
**Primary key:** `coin_key` (surrogate)  
**Natural key:** `coin_id` (unique)

| Column | Type | Description | Power BI |
|--------|------|-------------|----------|
| `coin_key` | SERIAL | Surrogate PK; join to fact | Hide; use in relationships |
| `coin_id` | TEXT | CoinGecko id (e.g. `bitcoin`) | Filters, drill-through |
| `symbol` | TEXT | Ticker (e.g. `BTC`) | Axis, legend, tables |
| `name` | TEXT | Full name | Tooltips, tables |
| `image` | TEXT | Logo URL | Optional image visuals |

**Updated:** On each mart build from latest staging row per `id` (`ON CONFLICT` upsert).

---

## `mart.dim_date`

**Grain:** one row per calendar day  
**Primary key:** `date_key` (`YYYYMMDD` integer)

| Column | Type | Description | Power BI |
|--------|------|-------------|----------|
| `date_key` | INTEGER | `YYYYMMDD` (e.g. `20260518`) | FK to fact; hide or use for sorting |
| `full_date` | DATE | Calendar date | Axis, slicers |
| `year` | INTEGER | Year | Slicers, charts |
| `quarter` | INTEGER | 1–4 | Slicers |
| `month` | INTEGER | 1–12 | Slicers |
| `month_name` | TEXT | Month name | Labels |
| `day_of_month` | INTEGER | Day of month | — |
| `day_of_week` | INTEGER | ISO (1=Mon … 7=Sun) | — |
| `day_name` | TEXT | Short day name | Labels |
| `is_weekend` | BOOLEAN | Sat/Sun flag | Filters |

**Seeded:** 2020-01-01 through 2030-12-31 in `sql/mart/build_marts.sql`.  
**Link to fact:** `fact.date_key` = calendar day of `extracted_at` (UTC). Multiple runs same day share `date_key` but differ on `extracted_at`.

---

## `mart.fact_crypto_market_snapshot`

**Grain:** one row per **coin per pipeline run**  
**Primary key:** `fact_key`  
**Unique:** `(coin_key, extracted_at)`

### Keys & time

| Column | Type | Description | Power BI summarization |
|--------|------|-------------|------------------------|
| `fact_key` | BIGSERIAL | Row id | Hide |
| `coin_key` | INTEGER | FK → `dim_coin` | Relationship only |
| `date_key` | INTEGER | FK → `dim_date` | Relationship only |
| `extracted_at` | TIMESTAMPTZ | Exact snapshot time | Filter to **latest** for “now”; axis for trends |

### Rank & price

| Column | Type | Description | Power BI summarization |
|--------|------|-------------|------------------------|
| `market_cap_rank` | INTEGER | Cap rank at snapshot | **Don't summarize** / Min with latest filter |
| `current_price` | DOUBLE PRECISION | USD price | **Don't summarize** / Max per coin |
| `high_24h` | DOUBLE PRECISION | 24h high | Don't summarize |
| `low_24h` | DOUBLE PRECISION | 24h low | Don't summarize |

### Market size & volume

| Column | Type | Description | Power BI summarization |
|--------|------|-------------|------------------------|
| `market_cap` | DOUBLE PRECISION | Market cap (USD) | **Sum** OK for universe total (latest filter) |
| `fully_diluted_valuation` | DOUBLE PRECISION | FDV | Don't summarize; use in ratios |
| `total_volume` | DOUBLE PRECISION | 24h volume | **Sum** OK for total market volume |

### 24h change

| Column | Type | Description | Power BI summarization |
|--------|------|-------------|------------------------|
| `price_change_24h` | DOUBLE PRECISION | Absolute 24h price change (USD) | Don't summarize |
| `price_change_percentage_24h` | DOUBLE PRECISION | **Percent** (e.g. `-2.5` = -2.5%) | **Never Sum**; Max + latest filter |
| `market_cap_change_24h` | DOUBLE PRECISION | Absolute 24h cap change | Don't summarize |
| `market_cap_change_percentage_24h` | DOUBLE PRECISION | 24h cap % change | Never Sum |

**Important:** CoinGecko % fields are already scaled (not 0.025). In Power BI, avoid applying **Percentage** format that multiplies by 100 again unless you divide by 100 in DAX first.

### Supply

| Column | Type | Description | Power BI summarization |
|--------|------|-------------|------------------------|
| `circulating_supply` | DOUBLE PRECISION | Circulating coins | Don't summarize |
| `total_supply` | DOUBLE PRECISION | Total supply | Don't summarize |
| `max_supply` | DOUBLE PRECISION | Max supply (0 in staging if null) | Don't summarize |

### ATH / ATL

| Column | Type | Description | Power BI summarization |
|--------|------|-------------|------------------------|
| `ath` | DOUBLE PRECISION | All-time high price | Don't summarize |
| `ath_change_percentage` | DOUBLE PRECISION | **% from ATH** (API) | Never Sum; not 24h change |
| `atl` | DOUBLE PRECISION | All-time low | Don't summarize |
| `atl_change_percentage` | DOUBLE PRECISION | **% above ATL** | Never Sum |

### Derived (from staging)

| Column | Type | Formula | Power BI use |
|--------|------|---------|--------------|
| `volatility_24h_pct` | DOUBLE PRECISION | `(high_24h - low_24h) / current_price × 100` | Volatility screens, scatter |
| `volume_to_mcap_ratio` | DOUBLE PRECISION | `total_volume / market_cap` | Liquidity / turnover |
| `supply_utilization_pct` | DOUBLE PRECISION | `circulating / max_supply × 100` | Tokenomics (if max supply > 0) |
| `price_from_ath_pct` | DOUBLE PRECISION | `(current_price - ath) / ath × 100` | Drawdown vs peak |

---

## `mart.v_market_dashboard` (view, optional)

Denormalized join: `fact` + `dim_coin` + `dim_date`.  
Same measures as fact plus `coin_id`, `symbol`, `name`, `image`, `snapshot_date`, calendar columns.

**Use if:** You want one table in Power BI without managing relationships.  
**Star schema (recommended):** Import `dim_coin`, `dim_date`, `fact` only — you do not need this view.

---

## Relationships (Power BI)

```text
dim_coin[coin_key]  (1) ──< (many)  fact[coin_key]
dim_date[date_key]  (1) ──< (many)  fact[date_key]
```

- **History:** Multiple fact rows per `coin_key` (different `extracted_at`).
- **Latest snapshot:** Filter `fact[extracted_at] = MAX(extracted_at)` or use `staging.stg_crypto_data`.

### Example DAX (latest snapshot)

```dax
Latest Extracted At =
MAXX( ALL( fact_crypto_market_snapshot[extracted_at] ), fact_crypto_market_snapshot[extracted_at] )

BTC Price (Latest) =
CALCULATE(
    MAX( fact_crypto_market_snapshot[current_price] ),
    dim_coin[coin_id] = "bitcoin",
    fact_crypto_market_snapshot[extracted_at] = [Latest Extracted At]
)
```

---

## Columns not in fact (where they live)

| Column | Location |
|--------|----------|
| `symbol`, `name`, `image`, `coin_id` | `mart.dim_coin` |
| `year`, `month`, `day_name`, `is_weekend` | `mart.dim_date` |
| `roi`, `data_quality_flag` | `staging.stg_crypto_snapshots` only |
| `last_updated_dt`, `ath_date_dt`, `atl_date_dt` | Staging only |

---

## Data quality flags (staging only)

| Flag | Meaning |
|------|---------|
| `VALID` | Loaded to snapshots / fact |
| `INVALID` | Missing id, symbol, or price |
| `INVALID_PRICE` | Price ≤ 0 |
| `INVALID_SUPPLY` | Circulating > max supply when max > 0 |

---

## Related files

| File | Role |
|------|------|
| `sql/ddl/02_raw_tables.sql` | Raw DDL |
| `sql/transform/staging_transform.sql` | Staging logic |
| `sql/ddl/05_mart_tables.sql` | Mart DDL |
| `sql/mart/build_marts.sql` | Populate dims + fact |
| `sql/analytics/sample_queries.sql` | Example SQL |
