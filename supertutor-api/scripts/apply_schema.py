"""Run schema.sql against the Supabase Postgres directly.

Usage:
    set PGPASSWORD=your-db-password
    python scripts/apply_schema.py
"""
import os
import sys
from pathlib import Path

import psycopg2

PROJECT_REF = "amtbevwkxtkzhnpiqcgi"
# Try pooler hosts; new projects may use aws-1-*
POOLER_HOSTS = [
    "aws-1-ap-southeast-1.pooler.supabase.com",
    "aws-1-eu-central-1.pooler.supabase.com",
    "aws-1-us-east-1.pooler.supabase.com",
    "aws-1-us-west-1.pooler.supabase.com",
    "aws-1-ap-south-1.pooler.supabase.com",
    "aws-1-ap-northeast-1.pooler.supabase.com",
    "aws-1-ap-northeast-2.pooler.supabase.com",
    "aws-1-eu-west-1.pooler.supabase.com",
    "aws-1-eu-west-2.pooler.supabase.com",
    "aws-1-eu-west-3.pooler.supabase.com",
    "aws-1-sa-east-1.pooler.supabase.com",
    "aws-1-ca-central-1.pooler.supabase.com",
    "aws-0-ap-southeast-2.pooler.supabase.com",
    "aws-0-ap-northeast-1.pooler.supabase.com",
    "aws-0-eu-west-1.pooler.supabase.com",
    "aws-0-sa-east-1.pooler.supabase.com",
    "aws-0-ca-central-1.pooler.supabase.com",
]
PORT = 6543  # transaction-mode pooler
USER = f"postgres.{PROJECT_REF}"
DB = "postgres"

SCHEMA_FILE = Path(__file__).parent.parent / "supabase" / "schema.sql"


def _try_connect(host: str, password: str):
    print(f"  trying {host} ...", end=" ", flush=True)
    try:
        conn = psycopg2.connect(
            host=host,
            port=PORT,
            user=USER,
            password=password,
            dbname=DB,
            sslmode="require",
            connect_timeout=10,
        )
        print("OK")
        return conn
    except Exception as e:
        msg = str(e).strip().splitlines()[0] if str(e).strip() else type(e).__name__
        print(f"failed: {msg}")
        return None


def main() -> int:
    password = os.environ.get("PGPASSWORD")
    if not password:
        print("ERROR: PGPASSWORD env var is required", file=sys.stderr)
        return 2

    sql = SCHEMA_FILE.read_text(encoding="utf-8")
    print("Connecting via Supabase pooler:")
    conn = None
    for host in POOLER_HOSTS:
        conn = _try_connect(host, password)
        if conn:
            break
    if not conn:
        print("ERROR: could not connect to any pooler region", file=sys.stderr)
        return 3
    conn.autocommit = True
    try:
        with conn.cursor() as cur:
            cur.execute(sql)
        print("Schema applied successfully.")

        with conn.cursor() as cur:
            cur.execute(
                "select table_name from information_schema.tables "
                "where table_schema='public' order by table_name"
            )
            tables = [r[0] for r in cur.fetchall()]
        print("public tables:", tables)
    finally:
        conn.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
