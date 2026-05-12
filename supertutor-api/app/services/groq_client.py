from typing import Iterable
from groq import Groq
from app.core.config import get_settings


def _client() -> Groq:
    settings = get_settings()
    if not settings.groq_api_key:
        raise RuntimeError("GROQ_API_KEY is not set")
    return Groq(api_key=settings.groq_api_key)


def chat_completion(messages: list[dict], model: str | None = None) -> str:
    settings = get_settings()
    client = _client()
    response = client.chat.completions.create(
        model=model or settings.groq_llm_model,
        messages=messages,
        temperature=0.6,
        max_tokens=400,
    )
    return response.choices[0].message.content or ""


def transcribe(audio_bytes: bytes, filename: str = "audio.webm", language: str | None = None) -> str:
    settings = get_settings()
    client = _client()
    transcription = client.audio.transcriptions.create(
        file=(filename, audio_bytes),
        model=settings.groq_stt_model,
        language=language,
        response_format="text",
    )
    # SDK returns string when response_format="text"
    return transcription if isinstance(transcription, str) else getattr(transcription, "text", "")
