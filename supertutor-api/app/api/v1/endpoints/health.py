from fastapi import APIRouter
from app.core.config import get_settings

router = APIRouter()


@router.get("/health")
def health() -> dict:
    s = get_settings()
    return {
        "status": "ok",
        "env": s.app_env,
        "groq_configured": bool(s.groq_api_key),
        "supabase_configured": bool(s.supabase_url and s.supabase_anon_key),
    }
