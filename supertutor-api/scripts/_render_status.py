"""Quick status check of Render services."""
import os
import sys
import httpx


def main() -> int:
    key = os.environ.get("RENDER_API_KEY")
    if not key:
        print("set RENDER_API_KEY first", file=sys.stderr)
        return 2

    with httpx.Client(
        base_url="https://api.render.com/v1",
        headers={"Authorization": f"Bearer {key}", "Accept": "application/json"},
        timeout=30,
    ) as client:
        r = client.get("/services", params={"limit": 100})
        r.raise_for_status()
        for item in r.json():
            s = item["service"]
            sd = s.get("serviceDetails") or {}
            url = sd.get("url") or "-"
            print(f"{s['name']:30s} {s['type']:14s} suspended={s.get('suspended')} url={url}")

            # Fetch latest deploy status
            deploys = client.get(
                f"/services/{s['id']}/deploys", params={"limit": 1}
            )
            if deploys.status_code == 200 and deploys.json():
                d = deploys.json()[0]["deploy"]
                print(f"  -> latest deploy: {d.get('status')}  ({d.get('id')})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
