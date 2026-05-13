import base64

from groq import Groq
from app.core.config import get_settings
from app.services.llm.base import LLMProvider, STTProvider, VisionProvider


def _client() -> Groq | None:
    s = get_settings()
    if not s.groq_api_key:
        return None
    return Groq(api_key=s.groq_api_key)


class GroqLLM(LLMProvider):
    name = "groq"

    def __init__(self) -> None:
        s = get_settings()
        self._model = s.groq_llm_model
        self._client = _client()

    def is_configured(self) -> bool:
        return self._client is not None

    def chat(self, messages: list[dict]) -> str:
        assert self._client
        r = self._client.chat.completions.create(
            model=self._model,
            messages=messages,
            temperature=0.6,
            max_tokens=600,
        )
        return r.choices[0].message.content or ""


class GroqSTT(STTProvider):
    name = "groq"

    def __init__(self) -> None:
        s = get_settings()
        self._model = s.groq_stt_model
        self._client = _client()

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


class GroqVision(VisionProvider):
    name = "groq"

    def __init__(self) -> None:
        s = get_settings()
        self._model = s.groq_vision_model
        self._client = _client()

    def is_configured(self) -> bool:
        return self._client is not None

    def analyze(
        self,
        prompt: str,
        image: bytes,
        mime: str = "image/jpeg",
        system: str | None = None,
    ) -> str:
        assert self._client
        b64 = base64.b64encode(image).decode("ascii")
        user_content = [
            {"type": "text", "text": prompt},
            {"type": "image_url", "image_url": {"url": f"data:{mime};base64,{b64}"}},
        ]
        messages: list[dict] = []
        if system:
            messages.append({"role": "system", "content": system})
        messages.append({"role": "user", "content": user_content})
        r = self._client.chat.completions.create(
            model=self._model,
            messages=messages,
            temperature=0.4,
            max_tokens=1200,
        )
        return r.choices[0].message.content or ""
