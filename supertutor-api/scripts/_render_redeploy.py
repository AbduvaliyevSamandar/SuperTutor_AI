"""Trigger fresh deploys for both supertutor services."""
import os, sys, httpx

TARGETS = ["supertutor-api", "supertutor-web"]

key = os.environ["RENDER_API_KEY"]
with httpx.Client(
    base_url="https://api.render.com/v1",
    headers={"Authorization": f"Bearer {key}", "Accept": "application/json"},
    timeout=30,
) as client:
    services = client.get("/services", params={"limit": 100}).json()
    for item in services:
        s = item["service"]
        if s["name"] not in TARGETS:
            continue
        r = client.post(
            f"/services/{s['id']}/deploys",
            json={"clearCache": "do_not_clear"},
        )
        # Render returns 201 with the deploy object directly (not wrapped)
        try:
            d = r.json()
            print(f"{s['name']:25s} -> deploy {d.get('id')} status={d.get('status')}")
        except Exception:
            print(f"{s['name']:25s} -> HTTP {r.status_code}")
