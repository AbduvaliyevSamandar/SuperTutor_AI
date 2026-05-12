from groq import Groq
from app.core.config import get_settings
from app.services.llm.base import LLMProvider, STTProvider


class GroqLLM(LLMProvider):
    name = "groq"

    def __init__(self) -> None:
        s = get_settings()
        self._key = s.groq_api_key
        self._model = s.groq_llm_model
        self._client = Groq(api_key=self._key) if self._key else None

    def is_configured(self) -> bool:
        return self._client is not None

    def chat(self, messages: list[dict]) -> str:
        assert self._client
        r = self._client.chat.completions.create(
            model=self._model,
            messages=messages,
            temperature=0.6,
            max_tokens=400,
        )
        return r.choices[0].message.content or ""


class GroqSTT(STTProvider):
    name = "groq"

    def __init__(self) -> None:
        s = get_settings()
        self._key = s.groq_api_key
        self._model = s.groq_stt_model
        self._client = Groq(api_key=self._key) if self._key else None

    def is_configured(self) -> bool:
        return self._client is not None

    def transcribe(
        self, audio: bytes, filename: str = "audio.webm", language: str | None = None
    ) -> str:
        assert self._client
        result = self._client.audio.transcriptions.create(
            file=(filename, audio),
            model=self._model,
            language=language,
            response_format="text",
        )
        return result if isinstance(result, str) else getattr(result, "text", "")
