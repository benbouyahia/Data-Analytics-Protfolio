import json
from datetime import datetime, timezone
from pathlib import Path

import requests

from data.config import DATA_DIR


def extract_data() -> str:
    url = "https://api.coingecko.com/api/v3/coins/markets"
    response = requests.get(
        url,
        params={"vs_currency": "usd", "per_page": 250, "page": 1},
        timeout=30,
    )
    response.raise_for_status()
    data = response.json()

    DATA_DIR.mkdir(parents=True, exist_ok=True)
    filename = DATA_DIR / f"raw_{datetime.now(timezone.utc).date()}.jsonl"
    extracted_at = datetime.now(timezone.utc).isoformat()

    with open(filename, "w", encoding="utf-8") as f:
        for row in data:
            row["extracted_at"] = extracted_at
            f.write(json.dumps(row) + "\n")

    print(f"Saved {len(data)} rows to {filename}")
    return str(filename)
