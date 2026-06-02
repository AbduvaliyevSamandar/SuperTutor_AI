import base64

from app.core.config import get_settings
from app.services.llm.base import LLMProvider, STTProvider, VisionProvider


def _make_client(api_key: str):
    if not api_key:
        return None
    try:
        from openai import OpenAI

        return OpenAI(api_key=api_key, timeout=15.0, max_retries=0)
    except Exception:
        return None


class OpenAILLM(LLMProvider):
    name = "openai"

    def __init__(self) -> None:
        s = get_settings()
        self._model = s.openai_llm_model
        self._client = _make_client(s.openai_api_key)

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

    def chat_stream(self, messages: list[dict]):
        assert self._client
        stream = self._client.chat.completions.create(
            model=self._model,
            messages=messages,
            temperature=0.6,
            max_tokens=600,
            stream=True,
        )
        for chunk in stream:
            delta = chunk.choices[0].delta.content if chunk.choices else None
            if delta:
                yield delta


class OpenAISTT(STTProvider):
    name = "openai"

    def __init__(self) -> None:
        s = get_settings()
        self._model = s.openai_stt_model
        self._client = _make_client(s.openai_api_key)

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


class OpenAIVision(VisionProvider):
    name = "openai"

    def __init__(self) -> None:
        s = get_settings()
        self._model = s.openai_vision_model
        self._client = _make_client(s.openai_api_key)

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
