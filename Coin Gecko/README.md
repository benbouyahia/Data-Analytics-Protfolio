# CoinGecko Crypto ETL Pipeline

A portfolio-grade ETL pipeline that extracts live cryptocurrency market data from the [CoinGecko API](https://www.coingecko.com/en/api), loads it into **PostgreSQL**, and builds **staging** and **mart** layers (star schema) ready for **Power BI**.

**Stack:** Python · PostgreSQL · psycopg2 · CoinGecko API · SQL · Power BI

## What it does

| Step | Module | Output |
|------|--------|--------|
| 1. Extract | `_01_extract.py` | `data/raw_YYYY-MM-DD.jsonl` |
| 2. Load | `_02_load_raw.py` | `raw.raw_crypto_data` (historical snapshots) |
| 3. Transform | `_03_transform.py` | `staging.stg_crypto_snapshots` + latest view |
| 4. Build marts | `_04_build_marts.py` | `mart.dim_*`, `mart.fact_*`, Power BI view |

```mermaid
flowchart LR
  API[CoinGecko_API] --> Extract["_01_extract"]
  Extract --> JSONL[raw_JSONL]
  JSONL --> LoadRaw["_02_load_raw"]
  LoadRaw --> RawTable[raw.raw_crypto_data]
  RawTable --> Transform["_03_transform"]
  Transform --> StgTable[staging.stg_crypto_snapshots]
  StgTable --> Marts["_04_build_marts"]
  Marts --> Fact[mart.fact_crypto_market_snapshot]
  Marts --> Dims[mart.dim_coin + dim_date]
  Fact --> PBI[mart.v_market_dashboard]
  Dims --> PBI
```

## Project structure

```
Coin Gecko/
├── data/
│   ├── config.py
│   ├── database.py
│   ├── pipeline.py
│   ├── _01_extract.py
│   ├── _02_load_raw.py
│   ├── _03_transform.py
│   └── _04_build_marts.py
├── sql/
│   ├── ddl/
│   ├── transform/
│   ├── mart/
│   └── analytics/
├── requirements.txt
├── .env.example
└── README.md
```

## Prerequisites

- Python 3.11+
- PostgreSQL 15+ and pgAdmin 4
- [Power BI Desktop](https://www.microsoft.com/power-platform/products/power-bi)

## Setup

### 1. PostgreSQL + pgAdmin

1. Create a database (e.g. `crypto_db`) in pgAdmin.
2. Copy `.env.example` to `.env` and set your connection string:

```
DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5433/crypto_db
```

### 2. Install and run

```powershell
cd "C:\Users\Ayoub-PC\Desktop\Coin Gecko"
.venv\Scripts\activate
pip install -r requirements.txt
python -m data.pipeline
```

Each pipeline run **appends a new snapshot** (same coin, new `extracted_at`). Re-run daily to build history for trend charts in Power BI.

## Data dictionary

Full column reference for every layer (raw, staging, mart, JSONL): [`docs/data_dictionary.md`](docs/data_dictionary.md).

## Data model

### `raw` — landing (historical)

- **Grain:** one row per coin per pipeline run
- **Primary key:** `(id, extracted_at)`

### `staging` — cleaned snapshots

| Object | Purpose |
|--------|---------|
| `stg_crypto_snapshots` | All valid historical snapshots |
| `stg_crypto_data` (view) | Latest snapshot per coin only |

### `mart` — star schema for BI

| Table | Role |
|-------|------|
| `dim_coin` | Coin attributes (symbol, name, image) |
| `dim_date` | Calendar (2020–2030) for time intelligence |
| `fact_crypto_market_snapshot` | Measures + FKs to coin and date |
| `v_market_dashboard` | **Denormalized view for Power BI** (recommended) |

**Fact grain:** one row per coin per `extracted_at` (each pipeline run).

**Fact measures:** `current_price`, `market_cap`, `total_volume`, `price_change_percentage_24h`, `volatility_24h_pct`, `volume_to_mcap_ratio`, `price_from_ath_pct`, and more.

## Power BI setup

### Option A — Single table (recommended to start)

1. Open **Power BI Desktop** → **Get data** → **PostgreSQL database**.
2. Server: `localhost` (port `5433` if not default — use **Advanced** options).
3. Database: your DB name (e.g. `crypto_db`).
4. Select view: **`mart.v_market_dashboard`**.
5. Load.

**Suggested visuals:**

| Visual | Fields |
|--------|--------|
| Table | `symbol`, `current_price`, `market_cap_rank`, `price_change_percentage_24h` |
| Bar chart | `symbol` (Top 10 by filter), `market_cap` |
| Line chart | `extracted_at` or `snapshot_date`, `current_price` — filter `coin_id = bitcoin` |
| Card | `COUNT(symbol)` filtered to latest `extracted_at` |

**Latest snapshot only:** Add a filter `extracted_at = MAX(extracted_at)` or use a measure.

### Option B — Star schema (multiple tables)

Import these tables and relate in Model view:

- `mart.dim_coin` ← `mart.fact_crypto_market_snapshot` → `mart.dim_date`
- Relationship: `dim_coin[coin_key]` → `fact[coin_key]`
- Relationship: `dim_date[date_key]` → `fact[date_key]`

Hide `coin_key` and `date_key` from report view; use `symbol` and `full_date` / `snapshot_date` instead.

### Refresh data

After each `python -m data.pipeline`, in Power BI: **Home** → **Refresh**.

## pgAdmin

Browse schemas: `raw` → `staging` → `mart`. Run [`sql/analytics/sample_queries.sql`](sql/analytics/sample_queries.sql) for examples including Bitcoin price over time.

## Design decisions

| Choice | Why |
|--------|-----|
| Historical raw PK `(id, extracted_at)` | Enables trend analysis across pipeline runs |
| Staging snapshots + latest view | Full history for facts; simple “current state” queries |
| Mart star schema | Standard pattern for Power BI and portfolio demos |
| `v_market_dashboard` | One import for quick dashboards; star schema optional |
| SQL-heavy transforms | Reviewable in pgAdmin; separates ETL from BI tool |

## API reference

- `GET https://api.coingecko.com/api/v3/coins/markets`
- Params: `vs_currency=usd`, `per_page=250`, `page=1`

## Future enhancements

- Schedule daily runs (Task Scheduler / GitHub Actions)
- Incremental fact loads instead of full refresh
- `dim_coin` SCD Type 2 if coin metadata changes matter historically
- Docker Compose for PostgreSQL

## License

Personal / learning project. CoinGecko data is subject to [their API terms](https://www.coingecko.com/en/api_terms).
