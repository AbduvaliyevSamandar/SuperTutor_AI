from app.core.config import get_settings
from app.services.llm.base import LLMProvider, VisionProvider


def _make_client(api_key: str):
    if not api_key:
        return None
    try:
        from google import genai

        return genai.Client(api_key=api_key)
    except Exception:
        return None


class GeminiLLM(LLMProvider):
    name = "gemini"

    def __init__(self) -> None:
        s = get_settings()
        self._model = s.gemini_model
        self._client = _make_client(s.gemini_api_key)

    def is_configured(self) -> bool:
        return self._client is not None

    def chat(self, messages: list[dict]) -> str:
        assert self._client
        from google.genai import types

        system = next((m["content"] for m in messages if m["role"] == "system"), None)
        contents = []
        for m in messages:
            if m["role"] == "system":
                continue
            role = "model" if m["role"] == "assistant" else "user"
            contents.append(
                types.Content(role=role, parts=[types.Part.from_text(text=m["content"])])
            )

        config = types.GenerateContentConfig(
            temperature=0.6,
            max_output_tokens=600,
            system_instruction=system,
        )
        r = self._client.models.generate_content(
            model=self._model, contents=contents, config=config
        )
        return r.text or ""


class GeminiVision(VisionProvider):
    name = "gemini"

    def __init__(self) -> None:
        s = get_settings()
        self._model = s.gemini_vision_model
        self._client = _make_client(s.gemini_api_key)

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
        from google.genai import types

        parts = [
            types.Part.from_text(text=prompt),
            types.Part.from_bytes(data=image, mime_type=mime),
        ]
        contents = [types.Content(role="user", parts=parts)]
        config = types.GenerateContentConfig(
            temperature=0.4,
            max_output_tokens=1200,
            system_instruction=system,
        )
        r = self._client.models.generate_content(
            model=self._model, contents=contents, config=config
        )
        return r.text or ""
