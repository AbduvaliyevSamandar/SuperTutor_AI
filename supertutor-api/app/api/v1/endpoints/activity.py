"""Recent activity for charts (XP history, streak heatmap)."""
from datetime import date, timedelta

from fastapi import APIRouter, Depends, HTTPException

from app.core.security import require_user_id
from app.core.supabase import get_supabase_admin

router = APIRouter()


@router.get("/activity/weekly")
def weekly(user_id: str = Depends(require_user_id)) -> dict:
    """Return last 14 days of daily_goals (date, earned_xp, target_xp)."""
    client = get_supabase_admin()
    if client is None:
        raise HTTPException(status_code=503, detail="DB not configured")
    start = (date.today() - timedelta(days=13)).isoformat()
    r = (
        client.table("daily_goals")
        .select("date, target_xp, earned_xp")
        .eq("user_id", user_id)
        .gte("date", start)
        .order("date")
        .execute()
    )
    rows = r.data or []
    # Fill gaps so the client gets exactly 14 days
    by_date = {row["date"]: row for row in rows}
    out: list[dict] = []
    for i in range(14):
        d = (date.today() - timedelta(days=13 - i)).isoformat()
        existing = by_date.get(d)
        out.append({
            "date": d,
            "earned_xp": (existing or {}).get("earned_xp", 0),
            "target_xp": (existing or {}).get("target_xp", 20),
        })
    return {"days": out}
