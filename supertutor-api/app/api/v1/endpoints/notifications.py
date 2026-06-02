"""FCM token registration endpoints."""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.core.security import require_user_id
from app.core.supabase import get_supabase_admin

router = APIRouter()


class TokenRequest(BaseModel):
    fcm_token: str
    platform: str = "android"  # android | ios | web


@router.post("/notifications/register-token")
def register_token(
    req: TokenRequest,
    user_id: str = Depends(require_user_id),
) -> dict:
    client = get_supabase_admin()
    if client is None:
        raise HTTPException(status_code=503, detail="DB unavailable")
    try:
        client.table("user_fcm_tokens").upsert(
            {"user_id": user_id, "token": req.fcm_token, "platform": req.platform},
            on_conflict="user_id,token",
        ).execute()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e)) from e
    return {"status": "registered"}


@router.delete("/notifications/unregister-token")
def unregister_token(
    req: TokenRequest,
    user_id: str = Depends(require_user_id),
) -> dict:
    client = get_supabase_admin()
    if client is None:
        raise HTTPException(status_code=503, detail="DB unavailable")
    try:
        client.table("user_fcm_tokens").delete().match(
            {"user_id": user_id, "token": req.fcm_token}
        ).execute()
    except Exception:
        pass
    return {"status": "unregistered"}
