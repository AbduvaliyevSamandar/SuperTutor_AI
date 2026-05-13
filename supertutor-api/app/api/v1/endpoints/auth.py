"""Backend signup that auto-confirms the user (bypasses email confirmation)."""
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
