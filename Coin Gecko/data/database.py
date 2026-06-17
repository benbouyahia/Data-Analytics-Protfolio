import re
from contextlib import contextmanager
from pathlib import Path

import psycopg2

from data.config import DATABASE_URL, SQL_DIR


@contextmanager
def get_connection():
    conn = psycopg2.connect(DATABASE_URL)
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def _split_sql_statements(sql_text: str) -> list[str]:
    """Split SQL file into statements, ignoring semicolons inside comments."""
    sql_text = sql_text.replace("\r\n", "\n")
    # Strip block and line comments for splitting only
    stripped = re.sub(r"/\*.*?\*/", "", sql_text, flags=re.DOTALL)
    stripped = re.sub(r"--[^\n]*", "", stripped)
    parts = [p.strip() for p in stripped.split(";")]
    return [p for p in parts if p]


def run_sql_file(conn, path: Path) -> None:
    sql_text = path.read_text(encoding="utf-8")
    # Keep dollar-quoted blocks (DO $$ ... $$) as a single statement
    if re.search(r"\$\$", sql_text):
        statements = [sql_text]
    else:
        statements = _split_sql_statements(sql_text)
    with conn.cursor() as cursor:
        for statement in statements:
            cursor.execute(statement)


def init_db() -> None:
    ddl_files = [
        SQL_DIR / "ddl" / "01_schemas.sql",
        SQL_DIR / "ddl" / "02_raw_tables.sql",
        SQL_DIR / "ddl" / "03_migrate_raw_history.sql",
        SQL_DIR / "ddl" / "04_mart_schema.sql",
        SQL_DIR / "ddl" / "05_mart_tables.sql",
    ]
    with get_connection() as conn:
        for ddl_file in ddl_files:
            run_sql_file(conn, ddl_file)
