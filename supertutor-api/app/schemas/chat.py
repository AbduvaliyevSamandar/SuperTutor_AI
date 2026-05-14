from pydantic import BaseModel, Field
from typing import Literal


class ChatMessage(BaseModel):
    role: Literal["system", "user", "assistant"]
    content: str


class ChatRequest(BaseModel):
    subject: str = Field(default="english")
    level: str | None = None
    messages: list[ChatMessage]
    session_id: str | None = None


class ChatResponse(BaseModel):
    reply: str
    provider: str | None = None


class TTSRequest(BaseModel):
    text: str
    language: str = "en"
    voice: str | None = None
