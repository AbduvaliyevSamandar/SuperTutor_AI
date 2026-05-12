"""Create a confirmed test user via Supabase Admin API.

Usage:
    set SUPABASE_URL=...
    set SUPABASE_SERVICE_KEY=...
    python scripts/create_test_user.py <email> <password>
"""
import os
import sys

import httpx


def main(email: str, password: str) -> int:
    url = os.environ["SUPABASE_URL"].rstrip("/")
    key = os.environ["SUPABASE_SERVICE_KEY"]

    r = httpx.post(
        f"{url}/auth/v1/admin/users",
        headers={
            "apikey": key,
            "Authorization": f"Bearer {key}",
            "Content-Type": "application/json",
        },
        json={
            "email": email,
            "password": password,
            "email_confirm": True,
        },
        timeout=30,
    )
    if r.status_code in (200, 201):
        data = r.json()
        print(f"Created user: {data.get('email')} (id={data.get('id')})")
        return 0
    print(f"Failed [{r.status_code}]: {r.text}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python create_test_user.py <email> <password>", file=sys.stderr)
        sys.exit(2)
    sys.exit(main(sys.argv[1], sys.argv[2]))
