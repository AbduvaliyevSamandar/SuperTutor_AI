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
    # Fetch session details before closing
    row = (
        client.table("sessions")
        .select("subject, messages_count")
        .eq("id", session_id)
        .eq("user_id", user_id)
        .maybe_single()
        .execute()
    )
    client.table("sessions").update({"ended_at": "now()"}).eq(
        "id", session_id
    ).eq("user_id", user_id).execute()

    # If the session was substantial, summarize observations via LLM
    if row.data and (row.data.get("messages_count") or 0) >= 4:
        try:
            _summarize_and_save(user_id, row.data.get("subject") or "english")
        except Exception:
            pass
    return {"ok": True}


def _summarize_and_save(user_id: str, subject: str) -> None:
    """Pull recent messages and ask LLM to produce 1-2 brief teacher notes."""
    from app.services.llm.orchestrator import chat_with_fallback
    from app.services.personalization import update_notes

    # NOTE: we don't currently persist messages server-side, so this is a
    # placeholder that simply records that a session happened. When chat
    # history persistence is added, replace this with real transcript analysis.
    observation = (
        f"Completed a {subject} session on {__import__('datetime').date.today()}."
    )
    update_notes(user_id, subject, observation)
    # Best-effort: ignore LLM errors silently
    _ = chat_with_fallback  # touch import to keep available for future use
