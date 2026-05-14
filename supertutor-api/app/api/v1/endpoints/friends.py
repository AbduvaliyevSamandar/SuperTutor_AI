"""Friend codes + friend leaderboard."""
import secrets
import string

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.core.security import require_user_id
from app.core.supabase import get_supabase_admin

router = APIRouter()


class MyCodeResponse(BaseModel):
    friend_code: str


class AddFriendRequest(BaseModel):
    friend_code: str


class FriendRow(BaseModel):
    user_id: str
    display_name: str
    xp_total: int
    streak_days: int


def _db():
    client = get_supabase_admin()
    if client is None:
        raise HTTPException(status_code=503, detail="DB not configured")
    return client


def _gen_code() -> str:
    alphabet = string.ascii_uppercase + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(6))


@router.get("/friends/me", response_model=MyCodeResponse)
def my_code(user_id: str = Depends(require_user_id)) -> MyCodeResponse:
    client = _db()
    row = (
        client.table("profiles")
        .select("friend_code")
        .eq("user_id", user_id)
        .maybe_single()
        .execute()
    )
    code = (row.data or {}).get("friend_code")
    if not code:
        # Generate and save
        for _ in range(5):
            code = _gen_code()
            try:
                client.table("profiles").update({"friend_code": code}).eq(
                    "user_id", user_id
                ).execute()
                break
            except Exception:
                continue
    return MyCodeResponse(friend_code=code or "------")


@router.post("/friends/add")
def add_friend(
    req: AddFriendRequest,
    user_id: str = Depends(require_user_id),
) -> dict:
    code = req.friend_code.strip().upper()
    if len(code) != 6:
        raise HTTPException(status_code=400, detail="Kod 6 belgili bo'lishi kerak")
    client = _db()
    target = (
        client.table("profiles")
        .select("user_id")
        .eq("friend_code", code)
        .maybe_single()
        .execute()
    )
    friend_id = (target.data or {}).get("user_id")
    if not friend_id:
        raise HTTPException(status_code=404, detail="Bunday kod bilan foydalanuvchi topilmadi")
    if friend_id == user_id:
        raise HTTPException(status_code=400, detail="O'zingizni qo'sha olmaysiz")
    client.table("friendships").upsert(
        {"user_id": user_id, "friend_id": friend_id},
        on_conflict="user_id,friend_id",
    ).execute()
    # Mutual: also add reverse for symmetric leaderboard
    client.table("friendships").upsert(
        {"user_id": friend_id, "friend_id": user_id},
        on_conflict="user_id,friend_id",
    ).execute()
    return {"ok": True}


@router.get("/friends/list", response_model=list[FriendRow])
def list_friends(user_id: str = Depends(require_user_id)) -> list[FriendRow]:
    client = _db()
    fr = (
        client.table("friendships")
        .select("friend_id")
        .eq("user_id", user_id)
        .execute()
    )
    ids = [r["friend_id"] for r in (fr.data or [])]
    if not ids:
        return []
    rows: list[FriendRow] = []
    for fid in ids:
        prof = (
            client.table("profiles")
            .select("display_name, streak_days")
            .eq("user_id", fid)
            .maybe_single()
            .execute()
        )
        cur = (
            client.table("user_currency")
            .select("xp_total")
            .eq("user_id", fid)
            .maybe_single()
            .execute()
        )
        rows.append(FriendRow(
            user_id=fid,
            display_name=(prof.data or {}).get("display_name") or "Do'st",
            xp_total=(cur.data or {}).get("xp_total") or 0,
            streak_days=(prof.data or {}).get("streak_days") or 0,
        ))
    rows.sort(key=lambda r: r.xp_total, reverse=True)
    return rows


@router.delete("/friends/{friend_id}")
def remove_friend(
    friend_id: str,
    user_id: str = Depends(require_user_id),
) -> dict:
    client = _db()
    client.table("friendships").delete().eq("user_id", user_id).eq(
        "friend_id", friend_id
    ).execute()
    client.table("friendships").delete().eq("user_id", friend_id).eq(
        "friend_id", user_id
    ).execute()
    return {"ok": True}
