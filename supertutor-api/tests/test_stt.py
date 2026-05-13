import io

from app.services.llm import orchestrator
from app.services.llm.base import STTProvider


class _FakeSTT(STTProvider):
    def __init__(self, name: str, text: str | None = None, *, raise_exc: Exception | None = None):
        self.name = name
        self._text = text
        self._exc = raise_exc

    def is_configured(self) -> bool:
        return True

    def transcribe(self, audio, filename="audio.webm", language=None):
        if self._exc:
            raise self._exc
        return self._text or ""


def test_stt_returns_transcription(monkeypatch, client):
    monkeypatch.setattr(
        orchestrator,
        "_stt_chain",
        lambda: [_FakeSTT("groq", "hello world")],
    )
    r = client.post(
        "/api/v1/stt",
        files={"file": ("a.webm", io.BytesIO(b"audio-bytes"), "audio/webm")},
    )
    assert r.status_code == 200
    body = r.json()
    assert body["text"] == "hello world"
    assert body["provider"] == "groq"


def test_stt_empty_file_rejected(client):
    r = client.post(
        "/api/v1/stt",
        files={"file": ("a.webm", io.BytesIO(b""), "audio/webm")},
    )
    assert r.status_code == 400


def test_stt_fallback(monkeypatch, client):
    monkeypatch.setattr(
        orchestrator,
        "_stt_chain",
        lambda: [
            _FakeSTT("groq", raise_exc=RuntimeError("down")),
            _FakeSTT("openai", "fallback text"),
        ],
    )
    r = client.post(
        "/api/v1/stt",
        files={"file": ("a.webm", io.BytesIO(b"audio"), "audio/webm")},
    )
    assert r.status_code == 200
    assert r.json() == {"text": "fallback text", "provider": "openai"}
