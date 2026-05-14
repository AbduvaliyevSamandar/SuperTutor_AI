from fastapi import APIRouter, Depends, HTTPException
from app.core.db_utils import safe_single
from app.core.security import require_user_id
from app.core.supabase import get_supabase_admin
from app.schemas.sessions import UserStats

router = APIRouter()


@router.get("/stats/me", response_model=UserStats)
def my_stats(user_id: str = Depends(require_user_id)) -> UserStats:
    client = get_supabase_admin()
    if client is None:
        raise HTTPException(status_code=503, detail="Database not configured")

    row = safe_single(
        client.table("user_stats")
        .select("*")
        .eq("user_id", user_id)
        .maybe_single()
    ) or {}
    prof = safe_single(
        client.table("profiles")
        .select("english_level, streak_days")
        .eq("user_id", user_id)
        .maybe_single()
    ) or {}

    return UserStats(
        total_sessions=row.get("total_sessions", 0) or 0,
        total_seconds=row.get("total_seconds", 0) or 0,
        total_messages=row.get("total_messages", 0) or 0,
        english_sessions=row.get("english_sessions", 0) or 0,
        math_sessions=row.get("math_sessions", 0) or 0,
        streak_days=prof.get("streak_days", 0) or 0,
        english_level=prof.get("english_level", "A1") or "A1",
    )
