from pydantic import BaseModel, Field
from typing import Literal


class ChatMessage(BaseModel):
    role: Literal["system", "user", "assistant"]
    content: str


class ChatRequest(BaseModel):
    subject: str = Field(default="english", description="english | math | russian | german | turkish")
    level: str | None = Field(default=None, description="CEFR level for languages: A1..C1")
    messages: list[ChatMessage]


class ChatResponse(BaseModel):
    reply: str
    provider: str | None = None


class TTSRequest(BaseModel):
    text: str
    language: str = "en"
    voice: str | None = None
