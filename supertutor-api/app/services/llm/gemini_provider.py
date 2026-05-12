from app.core.config import get_settings
from app.services.llm.base import LLMProvider


class GeminiLLM(LLMProvider):
    name = "gemini"

    def __init__(self) -> None:
        s = get_settings()
        self._key = s.gemini_api_key
        self._model = s.gemini_model
        self._client = None
        if self._key:
            try:
                from google import genai

                self._client = genai.Client(api_key=self._key)
            except Exception:
                self._client = None

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
            max_output_tokens=400,
            system_instruction=system,
        )
        r = self._client.models.generate_content(
            model=self._model, contents=contents, config=config
        )
        return r.text or ""
