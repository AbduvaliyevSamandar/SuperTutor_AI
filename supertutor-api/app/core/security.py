from fastapi import Header, HTTPException
from app.core.supabase import get_supabase_admin


def _extract_token(authorization: str | None) -> str | None:
    if not authorization:
        return None
    parts = authorization.split(" ", 1)
    if len(parts) != 2 or parts[0].lower() != "bearer":
        return None
    return parts[1].strip() or None


def current_user_id(authorization: str | None = Header(default=None)) -> str | None:
    """Returns user id if a valid Supabase JWT is provided, else None (guest)."""
    token = _extract_token(authorization)
    if not token:
        return None
    client = get_supabase_admin()
    if client is None:
        return None  # Supabase not configured server-side; treat as guest
    try:
        user_response = client.auth.get_user(token)
        user = getattr(user_response, "user", None)
        return user.id if user else None
    except Exception:
        return None


def require_user_id(authorization: str | None = Header(default=None)) -> str:
    """Strict variant: 401 if no valid user."""
    uid = current_user_id(authorization)
    if not uid:
        raise HTTPException(status_code=401, detail="Authentication required")
    return uid
