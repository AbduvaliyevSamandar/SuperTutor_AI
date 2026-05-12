from openai import OpenAI
from app.core.config import get_settings
from app.services.llm.base import LLMProvider, STTProvider


class OpenAILLM(LLMProvider):
    name = "openai"

    def __init__(self) -> None:
        s = get_settings()
        self._key = s.openai_api_key
        self._model = s.openai_llm_model
        self._client = OpenAI(api_key=self._key) if self._key else None

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


class OpenAISTT(STTProvider):
    name = "openai"

    def __init__(self) -> None:
        s = get_settings()
        self._key = s.openai_api_key
        self._model = s.openai_stt_model
        self._client = OpenAI(api_key=self._key) if self._key else None

    def is_configured(self) -> bool:
        return self._client is not None

    def transcribe(
        self, audio: bytes, filename: str = "audio.webm", language: str | None = None
    ) -> str:
        assert self._client
        import io

        bio = io.BytesIO(audio)
        bio.name = filename
        r = self._client.audio.transcriptions.create(
            file=bio,
            model=self._model,
            language=language,
            response_format="text",
        )
        return r if isinstance(r, str) else getattr(r, "text", "")
