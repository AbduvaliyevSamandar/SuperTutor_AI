"""Delete the old manual `SuperTutor_AI` service (duplicate of supertutor-api)."""
import os, sys, httpx

OLD = "SuperTutor_AI"

key = os.environ["RENDER_API_KEY"]
with httpx.Client(
    base_url="https://api.render.com/v1",
    headers={"Authorization": f"Bearer {key}", "Accept": "application/json"},
    timeout=30,
) as client:
    r = client.get("/services", params={"limit": 100})
    r.raise_for_status()
    target = next(
        (it["service"] for it in r.json() if it["service"]["name"] == OLD), None
    )
    if not target:
        print(f"No service named '{OLD}' found.")
        sys.exit(0)
    sid = target["id"]
    print(f"Deleting {OLD} ({sid}) ...")
    d = client.delete(f"/services/{sid}")
    d.raise_for_status()
    print("OK")
