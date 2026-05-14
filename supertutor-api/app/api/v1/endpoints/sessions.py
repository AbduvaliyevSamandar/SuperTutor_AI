from fastapi import APIRouter, Depends, HTTPException
from app.core.db_utils import safe_single, safe_list
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
    try:
        result = (
            client.table("sessions")
            .insert({"user_id": user_id, "subject": req.subject})
            .execute()
        )
        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create session")
        return SessionStartResponse(id=result.data[0]["id"])
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"DB error: {e}") from e


@router.patch("/sessions/{session_id}")
def update_session(
    session_id: str,
    req: SessionUpdateRequest,
    user_id: str = Depends(require_user_id),
) -> dict:
    client = _db()
    try:
        client.table("sessions").update({
            "duration_seconds": req.duration_seconds,
            "messages_count": req.messages_count,
        }).eq("id", session_id).eq("user_id", user_id).execute()
    except Exception:
        pass
    return {"ok": True}


@router.post("/sessions/{session_id}/end")
def end_session(
    session_id: str,
    user_id: str = Depends(require_user_id),
) -> dict:
    client = _db()
    row = safe_single(
        client.table("sessions")
        .select("subject, messages_count")
        .eq("id", session_id)
        .eq("user_id", user_id)
        .maybe_single()
    )
    try:
        client.table("sessions").update({"ended_at": "now()"}).eq(
            "id", session_id
        ).eq("user_id", user_id).execute()
    except Exception:
        pass

    if row and (row.get("messages_count") or 0) >= 4:
        try:
            _summarize_and_save(user_id, row.get("subject") or "english")
        except Exception:
            pass
    return {"ok": True}


def _summarize_and_save(user_id: str, subject: str) -> None:
    from app.services.llm.orchestrator import chat_with_fallback
    from app.services.personalization import update_notes

    client = get_supabase_admin()
    if client is None:
        return
    rows = list(reversed(safe_list(
        client.table("chat_messages")
        .select("role, content")
        .eq("user_id", user_id)
        .eq("subject", subject)
        .order("created_at", desc=True)
        .limit(20)
    )))
    if not rows:
        return
    transcript = "\n".join(
        f"{r['role'][0].upper()}: {r['content'][:300]}" for r in rows
    )
    prompt = (
        "You are reviewing a tutoring transcript. Write a SINGLE short paragraph "
        "(<=2 sentences) of teacher notes capturing this learner's main mistakes "
        "or weak topics. Plain text, no preamble.\n\nTranscript:\n" + transcript
    )
    try:
        observation, _ = chat_with_fallback([
            {"role": "system", "content": "You write concise teacher notes."},
            {"role": "user", "content": prompt},
        ])
    except Exception:
        observation = (
            f"Completed a {subject} session on {__import__('datetime').date.today()}."
        )
    update_notes(user_id, subject, observation.strip()[:600])
