"""Poll Render until both supertutor-api and supertutor-web deploys reach a terminal state."""
import os, sys, time
import httpx

TARGETS = ["supertutor-api", "supertutor-web"]
TERMINAL = {"live", "build_failed", "update_failed", "canceled", "deactivated"}


def main() -> int:
    key = os.environ["RENDER_API_KEY"]
    headers = {"Authorization": f"Bearer {key}", "Accept": "application/json"}
    with httpx.Client(base_url="https://api.render.com/v1", headers=headers, timeout=30) as client:
        services = client.get("/services", params={"limit": 100}).json()
        ids = {
            s["service"]["name"]: s["service"]["id"]
            for s in services
            if s["service"]["name"] in TARGETS
        }
        print("Watching:", ids)

        prev = {}
        start = time.time()
        while True:
            done = 0
            line = []
            for name in TARGETS:
                sid = ids.get(name)
                if not sid:
                    continue
                d = client.get(f"/services/{sid}/deploys", params={"limit": 1}).json()
                if not d:
                    line.append(f"{name}=no-deploys")
                    continue
                status = d[0]["deploy"]["status"]
                line.append(f"{name}={status}")
                if prev.get(name) != status:
                    print(f"  {name}: {prev.get(name)} -> {status}")
                    prev[name] = status
                if status in TERMINAL:
                    done += 1

            if done == len(TARGETS):
                print("=== both finished ===")
                for n in TARGETS:
                    print(f"  {n}: {prev.get(n)}")
                return 0

            if time.time() - start > 1200:  # 20 min hard cap
                print("=== timeout ===", line)
                return 1

            time.sleep(15)


if __name__ == "__main__":
    sys.exit(main())
