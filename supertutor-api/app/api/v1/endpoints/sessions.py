from fastapi import APIRouter, Depends, HTTPException
from app.core.security import require_user_id
from app.core.supabase import get_supabase_admin
from app.schemas.sessions import (
    SessionStartRequest,
    SessionStartResponse,
    SessionUpdateRequest,
)

router = APIRouter()


def _db():
    client = get_supabase_admin()
    if client is None:
        raise HTTPException(status_code=503, detail="Database not configured")
    return client


@router.post("/sessions", response_model=SessionStartResponse)
def start_session(
    req: SessionStartRequest,
    user_id: str = Depends(require_user_id),
) -> SessionStartResponse:
    client = _db()
    result = (
        client.table("sessions")
        .insert({"user_id": user_id, "subject": req.subject})
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to create session")
    return SessionStartResponse(id=result.data[0]["id"])


@router.patch("/sessions/{session_id}")
def update_session(
    session_id: str,
    req: SessionUpdateRequest,
    user_id: str = Depends(require_user_id),
) -> dict:
    client = _db()
    result = (
        client.table("sessions")
        .update({
            "duration_seconds": req.duration_seconds,
            "messages_count": req.messages_count,
        })
        .eq("id", session_id)
        .eq("user_id", user_id)
        .execute()
    )
    if not result.data:
        raise HTTPException(status_code=404, detail="Session not found")
    return {"ok": True}


@router.post("/sessions/{session_id}/end")
def end_session(
    session_id: str,
    user_id: str = Depends(require_user_id),
) -> dict:
    client = _db()
    client.table("sessions").update({"ended_at": "now()"}).eq(
        "id", session_id
    ).eq("user_id", user_id).execute()
    return {"ok": True}
