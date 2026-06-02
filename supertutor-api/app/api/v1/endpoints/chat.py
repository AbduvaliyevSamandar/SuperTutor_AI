import json

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException
from fastapi.responses import StreamingResponse

from app.core.security import current_user_id
from app.core.supabase import get_supabase_admin
from app.schemas.chat import ChatRequest, ChatResponse
from app.services.llm.orchestrator import (
    AllProvidersFailed,
    chat_with_fallback,
    stream_with_fallback,
)
from app.services.personalization import fetch_personalization
from app.services.prompts import system_prompt_for

router = APIRouter()

# When conversation grows beyond this many user/assistant turns, we trim the
# oldest messages and keep a brief summary prepended to the system prompt.
_KEEP_RECENT = 16


def _persist_pair(
    user_id: str,
    session_id: str,
    subject: str,
    user_msg: str | None,
    assistant_msg: str,
) -> None:
    client = get_supabase_admin()
    if client is None:
        return
    rows = []
    if user_msg:
        rows.append({
            "user_id": user_id,
            "session_id": session_id,
            "subject": subject,
            "role": "user",
            "content": user_msg[:8000],
        })
    rows.append({
        "user_id": user_id,
        "session_id": session_id,
        "subject": subject,
        "role": "assistant",
        "content": assistant_msg[:8000],
    })
    try:
        client.table("chat_messages").insert(rows).execute()
    except Exception:
        pass


def _trim_messages(msgs: list[dict]) -> tuple[list[dict], str | None]:
    """Keep the last _KEEP_RECENT messages; summarize older ones into a note."""
    if len(msgs) <= _KEEP_RECENT:
        return msgs, None
    old = msgs[:-_KEEP_RECENT]
    recent = msgs[-_KEEP_RECENT:]
    summary_lines = []
    for m in old[-30:]:
        role = m["role"][0].upper()
        content = m["content"][:200]
        summary_lines.append(f"{role}: {content}")
    summary = "Earlier in this conversation:\n" + "\n".join(summary_lines)
    return recent, summary


def _build_system(req: ChatRequest, user_id: str | None) -> str:
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
    return system


def _prepare_messages(req: ChatRequest, user_id: str | None) -> list[dict]:
    system = _build_system(req, user_id)
    raw = [m.model_dump() for m in req.messages]
    trimmed, summary = _trim_messages(raw)
    if summary:
        system += "\n\n" + summary
    return [{"role": "system", "content": system}, *trimmed]


@router.post("/chat", response_model=ChatResponse)
def chat(
    req: ChatRequest,
    background: BackgroundTasks,
    user_id: str | None = Depends(current_user_id),
) -> ChatResponse:
    messages = _prepare_messages(req, user_id)

    try:
        reply, provider = chat_with_fallback(messages)
    except AllProvidersFailed as e:
        raise HTTPException(status_code=503, detail=str(e)) from e

    if user_id and req.session_id and req.messages:
        last_user = next(
            (m for m in reversed(req.messages) if m.role == "user"), None
        )
        background.add_task(
            _persist_pair,
            user_id,
            req.session_id,
            req.subject,
            last_user.content if last_user else None,
            reply,
        )

    return ChatResponse(reply=reply, provider=provider)


@router.post("/chat/stream")
def chat_stream(
    req: ChatRequest,
    background: BackgroundTasks,
    user_id: str | None = Depends(current_user_id),
) -> StreamingResponse:
    messages = _prepare_messages(req, user_id)

    def event_source():
        full_reply = ""
        provider_name = ""
        try:
            for chunk, p in stream_with_fallback(messages):
                full_reply += chunk
                provider_name = p
                yield "data: " + json.dumps({"delta": chunk, "provider": p}) + "\n\n"
        except AllProvidersFailed as e:
            yield "data: " + json.dumps({"error": str(e)}) + "\n\n"
            return
        except Exception as e:
            yield "data: " + json.dumps({"error": f"{type(e).__name__}: {e}"}) + "\n\n"
            return

        yield "data: " + json.dumps({"done": True, "provider": provider_name}) + "\n\n"

        if user_id and req.session_id and req.messages and full_reply:
            last_user = next(
                (m for m in reversed(req.messages) if m.role == "user"), None
            )
            background.add_task(
                _persist_pair,
                user_id,
                req.session_id,
                req.subject,
                last_user.content if last_user else None,
                full_reply,
            )

    return StreamingResponse(
        event_source(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
        },
    )


@router.get("/chat/warmup")
def warmup() -> dict:
    """Lightweight ping that pre-warms the LLM provider connection pool."""
    return {"warm": True}
