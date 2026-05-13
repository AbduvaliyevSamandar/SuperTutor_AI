"""Top users by XP."""
from fastapi import APIRouter, HTTPException

from app.core.supabase import get_supabase_admin

router = APIRouter()


@router.get("/leaderboard/top")
def top(limit: int = 20) -> dict:
    client = get_supabase_admin()
    if client is None:
        raise HTTPException(status_code=503, detail="DB not configured")

    cur = (
        client.table("user_currency")
        .select("user_id, xp_total")
        .gt("xp_total", 0)
        .order("xp_total", desc=True)
        .limit(min(max(1, limit), 100))
        .execute()
    )
    items: list[dict] = []
    for row in cur.data or []:
        prof = (
            client.table("profiles")
            .select("display_name")
            .eq("user_id", row["user_id"])
            .maybe_single()
            .execute()
        )
        items.append({
            "user_id": row["user_id"],
            "xp_total": row["xp_total"],
            "display_name": (prof.data or {}).get("display_name") or "Foydalanuvchi",
        })
    return {"items": items}
