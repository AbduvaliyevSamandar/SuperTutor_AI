"""Render API orqali to'liq deploy avtomatlashtirish.

Idempotent: agar servislar bor bo'lsa yangilaydi, yo'q bo'lsa yaratadi.
Env vars'ni qo'shadi, deploy trigger qiladi va URL'larni bosib chiqaradi.

Usage:
    set RENDER_API_KEY=rnd_...
    python scripts/render_deploy.py
"""
from __future__ import annotations

import os
import sys
import time

import httpx

RENDER_API = "https://api.render.com/v1"
OWNER_NAME = "AbduvaliyevSamandar"  # Render owner (your account name)
REPO = "https://github.com/AbduvaliyevSamandar/SuperTutor_AI"
BRANCH = "main"

API_NAME = "supertutor-api"
WEB_NAME = "supertutor-web"

# Sirlar — .env'dan o'qiladi
SECRETS = {
    "GROQ_API_KEY": os.environ.get("GROQ_API_KEY", ""),
    "OPENAI_API_KEY": os.environ.get("OPENAI_API_KEY", ""),
    "GEMINI_API_KEY": os.environ.get("GEMINI_API_KEY", ""),
    "SUPABASE_URL": os.environ.get("SUPABASE_URL", ""),
    "SUPABASE_ANON_KEY": os.environ.get("SUPABASE_ANON_KEY", ""),
    "SUPABASE_SERVICE_KEY": os.environ.get("SUPABASE_SERVICE_KEY", ""),
}

API_NON_SECRET = {
    "APP_ENV": "production",
    "CORS_ORIGINS": "*",
    "GROQ_LLM_MODEL": "llama-3.3-70b-versatile",
    "GROQ_STT_MODEL": "whisper-large-v3",
    "OPENAI_LLM_MODEL": "gpt-4o-mini",
    "OPENAI_STT_MODEL": "whisper-1",
    "GEMINI_MODEL": "gemini-2.0-flash",
}


def auth_headers() -> dict:
    key = os.environ.get("RENDER_API_KEY")
    if not key:
        sys.exit("ERROR: set RENDER_API_KEY env var first")
    return {"Authorization": f"Bearer {key}", "Accept": "application/json"}


def list_services(client: httpx.Client) -> list[dict]:
    out: list[dict] = []
    cursor = None
    while True:
        params = {"limit": 100}
        if cursor:
            params["cursor"] = cursor
        r = client.get("/services", params=params)
        r.raise_for_status()
        rows = r.json()
        if not rows:
            break
        out.extend(item["service"] for item in rows)
        if len(rows) < 100:
            break
        cursor = rows[-1].get("cursor")
    return out


def find_service(services: list[dict], name: str) -> dict | None:
    for s in services:
        if s.get("name") == name:
            return s
    return None


def get_owner_id(client: httpx.Client) -> str:
    r = client.get("/owners")
    r.raise_for_status()
    rows = r.json()
    if not rows:
        sys.exit("ERROR: no owners on this Render account")
    # Prefer match by name; else first
    for item in rows:
        owner = item["owner"]
        if owner.get("name") == OWNER_NAME:
            return owner["id"]
    return rows[0]["owner"]["id"]


def set_env_vars(client: httpx.Client, service_id: str, env: dict[str, str]) -> None:
    payload = [{"key": k, "value": v} for k, v in env.items() if v != ""]
    r = client.put(f"/services/{service_id}/env-vars", json=payload)
    r.raise_for_status()
    print(f"  set {len(payload)} env vars")


def trigger_deploy(client: httpx.Client, service_id: str) -> str:
    r = client.post(f"/services/{service_id}/deploys", json={"clearCache": "do_not_clear"})
    r.raise_for_status()
    deploy = r.json()
    return deploy.get("id", "")


def create_api_service(client: httpx.Client, owner_id: str) -> dict:
    body = {
        "type": "web_service",
        "name": API_NAME,
        "ownerId": owner_id,
        "repo": REPO,
        "branch": BRANCH,
        "autoDeploy": "yes",
        "rootDir": "supertutor-api",
        "serviceDetails": {
            "env": "docker",
            "plan": "free",
            "region": "singapore",
            "dockerfilePath": "./Dockerfile",
            "dockerContext": ".",
            "healthCheckPath": "/api/v1/health",
        },
    }
    r = client.post("/services", json=body)
    r.raise_for_status()
    return r.json()["service"]


def create_web_service(client: httpx.Client, owner_id: str) -> dict:
    body = {
        "type": "static_site",
        "name": WEB_NAME,
        "ownerId": owner_id,
        "repo": REPO,
        "branch": BRANCH,
        "autoDeploy": "yes",
        "rootDir": "supertutor-app",
        "serviceDetails": {
            "buildCommand": "bash build_render.sh",
            "publishPath": "build/web",
            "pullRequestPreviewsEnabled": "no",
            "routes": [
                {"type": "rewrite", "source": "/*", "destination": "/index.html"}
            ],
        },
    }
    r = client.post("/services", json=body)
    r.raise_for_status()
    return r.json()["service"]


def ensure_api(client: httpx.Client, owner_id: str, existing: list[dict]) -> dict:
    s = find_service(existing, API_NAME) or find_service(existing, "supertutor-ai")
    if s:
        print(f"  found existing API service: {s['name']} ({s['id']})")
        return s
    print("  creating supertutor-api service...")
    return create_api_service(client, owner_id)


def ensure_web(client: httpx.Client, owner_id: str, existing: list[dict]) -> dict:
    s = find_service(existing, WEB_NAME)
    if s:
        print(f"  found existing web service: {s['name']} ({s['id']})")
        return s
    print("  creating supertutor-web service...")
    return create_web_service(client, owner_id)


def host_of(service: dict) -> str:
    sd = service.get("serviceDetails") or {}
    url = sd.get("url") or service.get("dashboardUrl") or ""
    return url


def main() -> int:
    headers = auth_headers()
    with httpx.Client(base_url=RENDER_API, headers=headers, timeout=60) as client:
        print("== Resolving owner...")
        owner_id = get_owner_id(client)
        print(f"  owner: {owner_id}")

        print("== Listing services...")
        existing = list_services(client)
        print(f"  found {len(existing)} services")

        print("== Ensuring backend (supertutor-api)...")
        api_svc = ensure_api(client, owner_id, existing)
        api_id = api_svc["id"]
        api_url = host_of(api_svc) or f"https://{API_NAME}.onrender.com"
        if not api_url.startswith("http"):
            api_url = f"https://{api_url}"

        print("== Setting backend env vars...")
        backend_env = {**API_NON_SECRET, **SECRETS}
        set_env_vars(client, api_id, backend_env)

        print("== Ensuring frontend (supertutor-web)...")
        web_svc = ensure_web(client, owner_id, existing)
        web_id = web_svc["id"]
        web_url = host_of(web_svc) or f"https://{WEB_NAME}.onrender.com"
        if not web_url.startswith("http"):
            web_url = f"https://{web_url}"

        print("== Setting frontend env vars...")
        frontend_env = {
            "API_BASE_URL": api_url,
            "SUPABASE_URL": SECRETS["SUPABASE_URL"],
            "SUPABASE_ANON_KEY": SECRETS["SUPABASE_ANON_KEY"],
        }
        set_env_vars(client, web_id, frontend_env)

        print("== Triggering deploys...")
        api_dep = trigger_deploy(client, api_id)
        print(f"  api deploy: {api_dep}")
        time.sleep(1)
        web_dep = trigger_deploy(client, web_id)
        print(f"  web deploy: {web_dep}")

        print()
        print("=" * 60)
        print(f"  Backend  : {api_url}")
        print(f"  Frontend : {web_url}")
        print(f"  Health   : {api_url}/api/v1/health")
        print("=" * 60)
        print("Builds running. ~5 min backend, ~10 min frontend (first build).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
