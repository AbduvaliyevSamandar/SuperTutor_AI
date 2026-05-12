"""LLM/STT orchestrator with cascade fallback."""
from functools import lru_cache
import logging

from app.services.llm.base import LLMProvider, STTProvider
from app.services.llm.gemini_provider import GeminiLLM
from app.services.llm.groq_provider import GroqLLM, GroqSTT
from app.services.llm.openai_provider import OpenAILLM, OpenAISTT

logger = logging.getLogger(__name__)


class AllProvidersFailed(RuntimeError):
    pass


@lru_cache
def _llm_chain() -> list[LLMProvider]:
    return [GroqLLM(), OpenAILLM(), GeminiLLM()]


@lru_cache
def _stt_chain() -> list[STTProvider]:
    return [GroqSTT(), OpenAISTT()]


def llm_status() -> list[dict]:
    return [{"name": p.name, "configured": p.is_configured()} for p in _llm_chain()]


def stt_status() -> list[dict]:
    return [{"name": p.name, "configured": p.is_configured()} for p in _stt_chain()]


def chat_with_fallback(messages: list[dict]) -> tuple[str, str]:
    errors: list[str] = []
    for p in _llm_chain():
        if not p.is_configured():
            continue
        try:
            reply = p.chat(messages)
            if reply.strip():
                return reply, p.name
            errors.append(f"{p.name}: empty response")
        except Exception as e:
            logger.warning("LLM %s failed: %s", p.name, e)
            errors.append(f"{p.name}: {type(e).__name__}: {e}")
    raise AllProvidersFailed(
        "No LLM provider succeeded. " + (" | ".join(errors) if errors else "None configured.")
    )


def transcribe_with_fallback(
    audio: bytes, filename: str = "audio.webm", language: str | None = None
) -> tuple[str, str]:
    errors: list[str] = []
    for p in _stt_chain():
        if not p.is_configured():
            continue
        try:
            text = p.transcribe(audio, filename=filename, language=language)
            return text, p.name
        except Exception as e:
            logger.warning("STT %s failed: %s", p.name, e)
            errors.append(f"{p.name}: {type(e).__name__}: {e}")
    raise AllProvidersFailed(
        "No STT provider succeeded. " + (" | ".join(errors) if errors else "None configured.")
    )
