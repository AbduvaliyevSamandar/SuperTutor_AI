from pydantic import BaseModel


class SessionStartRequest(BaseModel):
    subject: str


class SessionStartResponse(BaseModel):
    id: str


class SessionUpdateRequest(BaseModel):
    duration_seconds: int = 0
    messages_count: int = 0


class UserStats(BaseModel):
    total_sessions: int = 0
    total_seconds: int = 0
    total_messages: int = 0
    english_sessions: int = 0
    math_sessions: int = 0
    streak_days: int = 0
    english_level: str = "A1"
