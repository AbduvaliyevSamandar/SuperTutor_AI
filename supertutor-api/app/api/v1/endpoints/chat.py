from fastapi import APIRouter, HTTPException
from app.schemas.chat import ChatRequest, ChatResponse
from app.services.llm.orchestrator import (
    AllProvidersFailed,
    chat_with_fallback,
)
from app.services.prompts import system_prompt_for

router = APIRouter()


@router.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest) -> ChatResponse:
    system = system_prompt_for(req.subject)
    if req.level:
        system += f"\nLearner CEFR level: {req.level}."

    messages = [{"role": "system", "content": system}]
    messages.extend([m.model_dump() for m in req.messages])

    try:
        reply, provider = chat_with_fallback(messages)
    except AllProvidersFailed as e:
        raise HTTPException(status_code=503, detail=str(e)) from e

    return ChatResponse(reply=reply, provider=provider)
