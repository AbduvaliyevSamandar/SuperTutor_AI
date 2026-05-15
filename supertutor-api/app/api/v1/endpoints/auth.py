"""Backend auth helpers that auto-confirm users (bypass email confirmation)."""
import httpx
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr, Field

from app.core.config import get_settings

router = APIRouter()


class SignupRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)
    display_name: str | None = None


class SignupResponse(BaseModel):
    id: str
    email: str


class EmailOnlyRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    new_password: str = Field(min_length=6)


def _admin_headers() -> tuple[str, dict]:
    s = get_settings()
    if not (s.supabase_url and s.supabase_service_key):
        raise HTTPException(status_code=503, detail="Supabase not configured")
    base = s.supabase_url.rstrip("/")
    h = {
        "apikey": s.supabase_service_key,
        "Authorization": f"Bearer {s.supabase_service_key}",
        "Content-Type": "application/json",
    }
    return base, h


def _find_user_by_email(email: str) -> dict | None:
    base, headers = _admin_headers()
    r = httpx.get(
        f"{base}/auth/v1/admin/users",
        headers=headers,
        params={"email": email},
        timeout=30,
    )
    if r.status_code != 200:
        return None
    data = r.json()
    users = data.get("users") if isinstance(data, dict) else None
    if not users:
        return None
    for u in users:
        if (u.get("email") or "").lower() == email.lower():
            return u
    return None


@router.post("/auth/signup", response_model=SignupResponse)
def signup(req: SignupRequest) -> SignupResponse:
    s = get_settings()
    if not (s.supabase_url and s.supabase_service_key):
        raise HTTPException(status_code=503, detail="Supabase not configured")

    body: dict = {
        "email": req.email,
        "password": req.password,
        "email_confirm": True,
    }
    if req.display_name:
        body["user_metadata"] = {"name": req.display_name}

    try:
        r = httpx.post(
            f"{s.supabase_url.rstrip('/')}/auth/v1/admin/users",
            headers={
                "apikey": s.supabase_service_key,
                "Authorization": f"Bearer {s.supabase_service_key}",
                "Content-Type": "application/json",
            },
            json=body,
            timeout=30,
        )
    except httpx.HTTPError as e:
        raise HTTPException(status_code=502, detail=f"Supabase reach error: {e}") from e

    if r.status_code in (200, 201):
        data = r.json()
        return SignupResponse(id=data["id"], email=data["email"])
    if r.status_code == 422:
        # Supabase returns 422 for "user already exists"
        raise HTTPException(status_code=409, detail="Email already registered")
    raise HTTPException(status_code=r.status_code, detail=r.text[:500])


@router.post("/auth/ensure-confirmed")
def ensure_confirmed(req: EmailOnlyRequest) -> dict:
    """Mark user's email as confirmed (fixes pre-existing accounts that
    were created before the auto-confirm signup endpoint was wired up)."""
    user = _find_user_by_email(req.email)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.get("email_confirmed_at"):
        return {"already_confirmed": True}

    base, headers = _admin_headers()
    r = httpx.put(
        f"{base}/auth/v1/admin/users/{user['id']}",
        headers=headers,
        json={"email_confirm": True},
        timeout=30,
    )
    if r.status_code in (200, 201):
        return {"confirmed": True}
    raise HTTPException(status_code=r.status_code, detail=r.text[:500])


@router.post("/auth/reset-password")
def reset_password(req: ResetPasswordRequest) -> dict:
    """Reset password by email. MVP: no email-verification step; for production
    add an OTP/email-link round-trip before allowing the change."""
    user = _find_user_by_email(req.email)
    if not user:
        raise HTTPException(status_code=404, detail="Bu email topilmadi")

    base, headers = _admin_headers()
    r = httpx.put(
        f"{base}/auth/v1/admin/users/{user['id']}",
        headers=headers,
        json={"password": req.new_password, "email_confirm": True},
        timeout=30,
    )
    if r.status_code in (200, 201):
        return {"ok": True}
    raise HTTPException(status_code=r.status_code, detail=r.text[:500])


from app.core.security import require_user_id  # noqa: E402
from fastapi import Depends  # noqa: E402


@router.delete("/auth/me")
def delete_self(user_id: str = Depends(require_user_id)) -> dict:
    """Delete the currently signed-in user's account + all data."""
    base, headers = _admin_headers()
    r = httpx.delete(
        f"{base}/auth/v1/admin/users/{user_id}",
        headers=headers,
        timeout=30,
    )
    if r.status_code in (200, 204):
        return {"ok": True}
    raise HTTPException(status_code=r.status_code, detail=r.text[:500])
