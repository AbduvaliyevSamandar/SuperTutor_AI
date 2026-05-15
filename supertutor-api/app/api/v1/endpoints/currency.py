"""Hearts / XP / gems / daily-goal endpoints."""
from datetime import date as _date_module_date, datetime, timedelta, timezone
date = _date_module_date

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.core.security import require_user_id
from app.core.supabase import get_supabase_admin

router = APIRouter()

HEART_REFILL_MINUTES = 30
HEART_REFILL_COST_GEMS = 350
MAX_HEARTS = 5


class CurrencyResponse(BaseModel):
    hearts: int
    max_hearts: int
    xp_total: int
    gems: int
    streak_freezes: int
    next_heart_in_seconds: int
    daily_target_xp: int
    daily_earned_xp: int


class AwardXpRequest(BaseModel):
    xp: int = Field(ge=1, le=500)
    reason: str | None = None


class XpResult(BaseModel):
    xp_total: int
    daily_earned_xp: int
    daily_target_xp: int
    daily_goal_reached: bool


class SetGoalRequest(BaseModel):
    target_xp: int = Field(ge=10, le=200)


def _db():
    client = get_supabase_admin()
    if client is None:
        raise HTTPException(status_code=503, detail="DB not configured")
    return client


def _ensure_currency_row(client, user_id: str) -> dict:
    """Return the user's currency row, creating it if missing."""
    from app.core.db_utils import safe_single
    row = safe_single(
        client.table("user_currency")
        .select("*")
        .eq("user_id", user_id)
        .maybe_single()
    )
    if row:
        return row
    try:
        client.table("user_currency").upsert({"user_id": user_id}).execute()
    except Exception:
        pass
    row = safe_single(
        client.table("user_currency")
        .select("*")
        .eq("user_id", user_id)
        .maybe_single()
    )
    return row or {
        "user_id": user_id,
        "hearts": 5,
        "max_hearts": 5,
        "xp_total": 0,
        "gems": 50,
        "streak_freezes": 0,
        "last_heart_refill_at": None,
    }


def _today_goal(client, user_id: str) -> dict:
    from app.core.db_utils import safe_single
    today = date.today().isoformat()
    row = safe_single(
        client.table("daily_goals")
        .select("*")
        .eq("user_id", user_id)
        .eq("date", today)
        .maybe_single()
    )
    if row:
        return row
    try:
        client.table("daily_goals").upsert(
            {"user_id": user_id, "date": today, "target_xp": 20, "earned_xp": 0}
        ).execute()
    except Exception:
        pass
    return {"user_id": user_id, "date": today, "target_xp": 20, "earned_xp": 0}


def _heart_refill_seconds(row: dict) -> int:
    if row["hearts"] >= row["max_hearts"]:
        return 0
    last = row.get("last_heart_refill_at")
    if not last:
        return 0
    try:
        ts = datetime.fromisoformat(last.replace("Z", "+00:00"))
    except ValueError:
        return 0
    next_at = ts + timedelta(minutes=HEART_REFILL_MINUTES)
    delta = (next_at - datetime.now(timezone.utc)).total_seconds()
    return max(0, int(delta))


def _apply_passive_refill(client, row: dict) -> dict:
    """Refill 1 heart per HEART_REFILL_MINUTES elapsed since last refill."""
    if row["hearts"] >= row["max_hearts"]:
        return row
    last = row.get("last_heart_refill_at")
    if not last:
        return row
    try:
        ts = datetime.fromisoformat(last.replace("Z", "+00:00"))
    except ValueError:
        return row
    elapsed = datetime.now(timezone.utc) - ts
    refills = int(elapsed.total_seconds() // (HEART_REFILL_MINUTES * 60))
    if refills <= 0:
        return row
    new_hearts = min(row["max_hearts"], row["hearts"] + refills)
    if new_hearts == row["hearts"]:
        return row
    new_ts = ts + timedelta(minutes=HEART_REFILL_MINUTES * refills)
    if new_hearts == row["max_hearts"]:
        new_ts = datetime.now(timezone.utc)
    client.table("user_currency").update(
        {
            "hearts": new_hearts,
            "last_heart_refill_at": new_ts.isoformat(),
        }
    ).eq("user_id", row["user_id"]).execute()
    row["hearts"] = new_hearts
    row["last_heart_refill_at"] = new_ts.isoformat()
    return row


def _to_response(row: dict, goal: dict) -> CurrencyResponse:
    return CurrencyResponse(
        hearts=row["hearts"],
        max_hearts=row["max_hearts"],
        xp_total=row["xp_total"],
        gems=row["gems"],
        streak_freezes=row["streak_freezes"],
        next_heart_in_seconds=_heart_refill_seconds(row),
        daily_target_xp=goal["target_xp"],
        daily_earned_xp=goal["earned_xp"],
    )


@router.get("/currency/me", response_model=CurrencyResponse)
def get_me(user_id: str = Depends(require_user_id)) -> CurrencyResponse:
    client = _db()
    row = _ensure_currency_row(client, user_id)
    row = _apply_passive_refill(client, row)
    goal = _today_goal(client, user_id)
    return _to_response(row, goal)


@router.post("/currency/lose-heart", response_model=CurrencyResponse)
def lose_heart(user_id: str = Depends(require_user_id)) -> CurrencyResponse:
    client = _db()
    row = _ensure_currency_row(client, user_id)
    row = _apply_passive_refill(client, row)
    if row["hearts"] <= 0:
        raise HTTPException(status_code=409, detail="No hearts left")
    new_hearts = row["hearts"] - 1
    update = {"hearts": new_hearts}
    if row["hearts"] == row["max_hearts"]:
        update["last_heart_refill_at"] = datetime.now(timezone.utc).isoformat()
    client.table("user_currency").update(update).eq("user_id", user_id).execute()
    row["hearts"] = new_hearts
    if "last_heart_refill_at" in update:
        row["last_heart_refill_at"] = update["last_heart_refill_at"]
    goal = _today_goal(client, user_id)
    return _to_response(row, goal)


@router.post("/currency/refill-hearts", response_model=CurrencyResponse)
def refill_hearts(user_id: str = Depends(require_user_id)) -> CurrencyResponse:
    """Spend gems to refill to full hearts."""
    client = _db()
    row = _ensure_currency_row(client, user_id)
    if row["hearts"] >= row["max_hearts"]:
        goal = _today_goal(client, user_id)
        return _to_response(row, goal)
    if row["gems"] < HEART_REFILL_COST_GEMS:
        raise HTTPException(
            status_code=402,
            detail=f"Need {HEART_REFILL_COST_GEMS} gems (have {row['gems']})",
        )
    new_gems = row["gems"] - HEART_REFILL_COST_GEMS
    client.table("user_currency").update(
        {"hearts": row["max_hearts"], "gems": new_gems}
    ).eq("user_id", user_id).execute()
    row["hearts"] = row["max_hearts"]
    row["gems"] = new_gems
    goal = _today_goal(client, user_id)
    return _to_response(row, goal)


@router.post("/currency/award-xp", response_model=XpResult)
def award_xp(
    req: AwardXpRequest,
    user_id: str = Depends(require_user_id),
) -> XpResult:
    client = _db()
    row = _ensure_currency_row(client, user_id)
    goal = _today_goal(client, user_id)

    new_total = row["xp_total"] + req.xp
    new_today = goal["earned_xp"] + req.xp
    reached_before = goal["earned_xp"] >= goal["target_xp"]
    reached_now = new_today >= goal["target_xp"]

    client.table("user_currency").update({"xp_total": new_total}).eq(
        "user_id", user_id
    ).execute()
    client.table("daily_goals").update({"earned_xp": new_today}).eq(
        "user_id", user_id
    ).eq("date", goal["date"]).execute()

    # Bonus: 5 gems when daily goal first reached today
    if not reached_before and reached_now:
        client.table("user_currency").update({"gems": row["gems"] + 5}).eq(
            "user_id", user_id
        ).execute()

    return XpResult(
        xp_total=new_total,
        daily_earned_xp=new_today,
        daily_target_xp=goal["target_xp"],
        daily_goal_reached=reached_now,
    )


@router.post("/currency/use-streak-freeze", response_model=CurrencyResponse)
def use_freeze(user_id: str = Depends(require_user_id)) -> CurrencyResponse:
    client = _db()
    row = _ensure_currency_row(client, user_id)
    if (row.get("streak_freezes") or 0) <= 0:
        raise HTTPException(status_code=402, detail="Streak freezeingiz yo'q")
    new_freezes = (row.get("streak_freezes") or 0) - 1
    client.table("user_currency").update(
        {"streak_freezes": new_freezes}
    ).eq("user_id", user_id).execute()
    # Also extend last_active_date by 1 day to preserve streak
    try:
        client.table("profiles").update(
            {"last_active_date": date.today().isoformat()}
        ).eq("user_id", user_id).execute()
    except Exception:
        pass
    row["streak_freezes"] = new_freezes
    goal = _today_goal(client, user_id)
    return _to_response(row, goal)


@router.post("/currency/buy-streak-freeze", response_model=CurrencyResponse)
def buy_freeze(user_id: str = Depends(require_user_id)) -> CurrencyResponse:
    """Buy 1 streak-freeze for 200 gems."""
    cost = 200
    client = _db()
    row = _ensure_currency_row(client, user_id)
    if row["gems"] < cost:
        raise HTTPException(
            status_code=402,
            detail=f"Yetarli gemma yo'q ({row['gems']}/{cost})",
        )
    client.table("user_currency").update({
        "gems": row["gems"] - cost,
        "streak_freezes": (row.get("streak_freezes") or 0) + 1,
    }).eq("user_id", user_id).execute()
    row["gems"] = row["gems"] - cost
    row["streak_freezes"] = (row.get("streak_freezes") or 0) + 1
    goal = _today_goal(client, user_id)
    return _to_response(row, goal)


@router.post("/currency/set-goal", response_model=CurrencyResponse)
def set_goal(
    req: SetGoalRequest,
    user_id: str = Depends(require_user_id),
) -> CurrencyResponse:
    client = _db()
    today = date.today().isoformat()
    client.table("daily_goals").upsert(
        {"user_id": user_id, "date": today, "target_xp": req.target_xp}
    ).execute()
    row = _ensure_currency_row(client, user_id)
    goal = _today_goal(client, user_id)
    return _to_response(row, goal)
