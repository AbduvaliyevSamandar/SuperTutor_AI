from fastapi import APIRouter
from app.core.config import get_settings
from app.services.llm.orchestrator import llm_status, stt_status

router = APIRouter()


@router.get("/health")
def health() -> dict:
    s = get_settings()
    return {
        "status": "ok",
        "env": s.app_env,
        "supabase_configured": bool(s.supabase_url and s.supabase_anon_key),
        "llm_providers": llm_status(),
        "stt_providers": stt_status(),
    }
