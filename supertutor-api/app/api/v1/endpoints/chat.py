from fastapi import APIRouter, Depends, HTTPException

from app.core.security import current_user_id
from app.core.supabase import get_supabase_admin
from app.schemas.chat import ChatRequest, ChatResponse
from app.services.llm.orchestrator import (
    AllProvidersFailed,
    chat_with_fallback,
)
from app.services.personalization import fetch_personalization
from app.services.prompts import system_prompt_for

router = APIRouter()


def _persist(user_id: str, session_id: str | None, subject: str,
             role: str, content: str) -> None:
    if not user_id or not session_id:
        return
    client = get_supabase_admin()
    if client is None:
        return
    try:
        client.table("chat_messages").insert({
            "user_id": user_id,
            "session_id": session_id,
            "subject": subject,
            "role": role,
            "content": content[:8000],
        }).execute()
    except Exception:
        pass


@router.post("/chat", response_model=ChatResponse)
def chat(
    req: ChatRequest,
    user_id: str | None = Depends(current_user_id),
) -> ChatResponse:
    system = system_prompt_for(req.subject)
    if req.level:
        system += f"\nLearner CEFR level: {req.level}."
    system += fetch_personalization(user_id, req.subject.lower())

    if req.scenario_role:
        system += (
            f"\n\nROLEPLAY MODE: You are playing the role of {req.scenario_role}. "
            "Stay in character. Use natural conversational language fitting that role. "
            "Do NOT break character to teach grammar mid-conversation."
        )
        if req.scenario_goal:
            system += (
                f"\nThe learner's goal in this scenario: {req.scenario_goal}. "
                "Guide them toward this goal naturally."
            )
        system += (
            "\nAfter every 4-5 exchanges, briefly add a [TUTOR NOTE: ...] line "
            "in Uzbek with 1 correction or vocabulary tip, then continue in role."
        )

    messages = [{"role": "system", "content": system}]
    messages.extend([m.model_dump() for m in req.messages])

    try:
        reply, provider = chat_with_fallback(messages)
    except AllProvidersFailed as e:
        raise HTTPException(status_code=503, detail=str(e)) from e

    # Persist the latest user message + assistant reply for memory
    if user_id and req.session_id and req.messages:
        last_user = next(
            (m for m in reversed(req.messages) if m.role == "user"), None
        )
        if last_user is not None:
            _persist(user_id, req.session_id, req.subject, "user", last_user.content)
        _persist(user_id, req.session_id, req.subject, "assistant", reply)

    return ChatResponse(reply=reply, provider=provider)
