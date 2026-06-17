from data._01_extract import extract_data
from data._02_load_raw import load_raw_data
from data._03_transform import transform
from data._04_build_marts import build_marts
from data.database import init_db


def run_pipeline() -> None:
    print("Initializing database schemas...")
    init_db()

    print("Step 1/4: Extracting from CoinGecko API...")
    file_path = extract_data()

    print("Step 2/4: Loading raw data into PostgreSQL...")
    load_raw_data(file_path)

    print("Step 3/4: Transforming into staging...")
    transform()

    print("Step 4/4: Building mart (dimensions + facts)...")
    build_marts()

    print("Pipeline complete. Use mart.v_market_dashboard in Power BI.")


if __name__ == "__main__":
    run_pipeline()
