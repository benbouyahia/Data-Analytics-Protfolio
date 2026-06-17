# CoinGecko Crypto ETL Pipeline

A portfolio-grade ETL pipeline that extracts live cryptocurrency market data from the [CoinGecko API](https://www.coingecko.com/en/api), loads it into **PostgreSQL**, and builds **staging** and **mart** layers (star schema) ready for **Power BI**.

**Stack:** Python · PostgreSQL · psycopg2 · CoinGecko API · SQL · Power BI

## What it does

| Step           | Module                 | Output                                         |
| -------------- | ---------------------- | ---------------------------------------------- |
| 1. Extract     | `_01_extract.py`     | `data/raw_YYYY-MM-DD.jsonl`                  |
| 2. Load        | `_02_load_raw.py`    | `raw.raw_crypto_data` (historical snapshots) |
| 3. Transform   | `_03_transform.py`   | `staging.stg_crypto_snapshots` + latest view |
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

| Object                     | Purpose                        |
| -------------------------- | ------------------------------ |
| `stg_crypto_snapshots`   | All valid historical snapshots |
| `stg_crypto_data` (view) | Latest snapshot per coin only  |

### `mart` — star schema for BI

| Table                           | Role                                                   |
| ------------------------------- | ------------------------------------------------------ |
| `dim_coin`                    | Coin attributes (symbol, name, image)                  |
| `dim_date`                    | Calendar (2020–2030) for time intelligence            |
| `fact_crypto_market_snapshot` | Measures + FKs to coin and date                        |
| `v_market_dashboard`          | **Denormalized view for Power BI** (recommended) |

**Fact grain:** one row per coin per `extracted_at` (each pipeline run).

**Fact measures:** `current_price`, `market_cap`, `total_volume`, `price_change_percentage_24h`, `volatility_24h_pct`, `volume_to_mcap_ratio`, `price_from_ath_pct`, and more.

## Power BI Setup

A single-page Power BI dashboard that gives a snapshot view of the cryptocurrency market, sourced from a CoinGecko-derived data warehouse. It tracks 258 coins across price, market cap, volume, volatility, and all-time-high/low metrics, refreshed at the latest available extraction timestamp.

## Overview

The report (`Coingecko.pbix`) is a single-page dashboard,  **Market Pulse** , that uses a bookmark-driven navigator to switch between four focused views without leaving the page:

| View                            | What it shows                                                                                                                        |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| **Market Pulse**(default) | Market cap by coin, 24h gainers/losers split, volume-to-market-cap ratio by coin, and a volatility-vs-distance-from-ATH scatter plot |
| **Majors & Dominance**    | Same charts as Market Pulse, plus a KPI row for BTC/ETH dominance and 24h price moves                                                |
| **Volume & Volatility**   | Same charts as Market Pulse, focused on the volume and volatility visuals                                                            |
| **Table View**            | A detailed sortable table of all tracked coins, swapped in for the volume/volatility charts                                          |

Two KPI card rows sit at the top of the page and are toggled in/out depending on the selected view:

* **Row 1** (always visible): Coins Tracked, Total Market Cap, BTC Price, % Market Green, Coins Green 24h, Coins Red 24h
* **Row 2** (Majors & Dominance only): Top 10 Concentration %, ETH Dominance %, ETH 24h %, BTC Dominance %, BTC 24h %

## Measures (DAX)

All measures live in a dedicated `_Measures` table.

| Measure                                 | Purpose                                                                                                                                     |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `Latest Extracted At`                 | Returns the max `extracted_at`across the whole fact table; used by nearly every other measure to pin calculations to the latest snapshot. |
| `Is Latest Snapshot Filter`           | Flags whether the current row context matches the latest snapshot.                                                                          |
| `Coins Tracked`                       | Distinct count of coins in the latest snapshot.                                                                                             |
| `Total Market Cap`                    | Sum of market cap in the latest snapshot.                                                                                                   |
| `Coins Green 24h`/`Coins Red 24h`   | Count of coins with positive / negative 24h price change in the latest snapshot.                                                            |
| `% Market Green`                      | Share of (Green) / (Green + Red) coins.                                                                                                     |
| `BTC Price`                           | BTC's `current_price `in the latest snapshot.                                                                                             |
| `BTC 24h %`/`ETH 24h %`             | BTC / ETH's 24h price change %, formatted as a string with a `%`suffix.                                                                   |
| `BTC Dominance %`/`ETH dominance %` | BTC's / ETH's share of total market cap, formatted as a string with a `%`suffix.                                                          |
| `top 10 concentration %`              | Share of total market cap held by the top 10 coins by market cap rank.                                                                      |
| `Median 24h Change %`                 | Median 24h price change % across all coins (defined but not currently placed on the report).                                                |
| `Stablecoins`                         | A hardcoded list (USDT, USDC, DAI, BUSD, TUSD) via `DATATABLE`, defined but not currently used on the report.                             |
| `Underperformingcoins`                | Returns coins trading at ≤50% of their all-time high (defined but not currently used on the report).                                       |

## Report Page Snippet

![1781736759955](image/README/1781736759955.png)

![1781736789549](image/README/1781736789549.png)

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
