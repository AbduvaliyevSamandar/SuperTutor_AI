from app.services.llm import orchestrator
from app.services.llm.base import LLMProvider


class _FakeProvider(LLMProvider):
    def __init__(self, name: str, reply: str | None = None, *, raise_exc: Exception | None = None):
        self.name = name
        self._reply = reply
        self._exc = raise_exc

    def is_configured(self) -> bool:
        return True

    def chat(self, messages):
        if self._exc:
            raise self._exc
        return self._reply or ""


def test_chat_uses_first_configured(monkeypatch, client):
    monkeypatch.setattr(
        orchestrator,
        "_llm_chain",
        lambda: [_FakeProvider("groq", "Hello there!"), _FakeProvider("openai", "ignored")],
    )
    r = client.post(
        "/api/v1/chat",
        json={"subject": "english", "messages": [{"role": "user", "content": "Hi"}]},
    )
    assert r.status_code == 200, r.text
    data = r.json()
    assert data["reply"] == "Hello there!"
    assert data["provider"] == "groq"


def test_chat_falls_back_on_error(monkeypatch, client):
    monkeypatch.setattr(
        orchestrator,
        "_llm_chain",
        lambda: [
            _FakeProvider("groq", raise_exc=RuntimeError("boom")),
            _FakeProvider("openai", "Fallback reply"),
        ],
    )
    r = client.post(
        "/api/v1/chat",
        json={"subject": "english", "messages": [{"role": "user", "content": "Hi"}]},
    )
    assert r.status_code == 200, r.text
    data = r.json()
    assert data["reply"] == "Fallback reply"
    assert data["provider"] == "openai"


def test_chat_all_providers_fail(monkeypatch, client):
    monkeypatch.setattr(
        orchestrator,
        "_llm_chain",
        lambda: [
            _FakeProvider("groq", raise_exc=RuntimeError("a")),
            _FakeProvider("openai", raise_exc=RuntimeError("b")),
        ],
    )
    r = client.post(
        "/api/v1/chat",
        json={"subject": "english", "messages": [{"role": "user", "content": "Hi"}]},
    )
    assert r.status_code == 503


def test_chat_uses_subject_prompt(monkeypatch, client):
    captured: dict = {}

    class Capture(LLMProvider):
        name = "groq"

        def is_configured(self): return True
        def chat(self, messages):
            captured["messages"] = messages
            return "ok"

    monkeypatch.setattr(orchestrator, "_llm_chain", lambda: [Capture()])
    client.post(
        "/api/v1/chat",
        json={"subject": "math", "messages": [{"role": "user", "content": "2+2"}]},
    )
    system = captured["messages"][0]
    assert system["role"] == "system"
    assert "math tutor" in system["content"].lower()


def test_chat_includes_level(monkeypatch, client):
    captured = {}

    class Capture(LLMProvider):
        name = "groq"
        def is_configured(self): return True
        def chat(self, messages):
            captured["sys"] = messages[0]["content"]
            return "ok"

    monkeypatch.setattr(orchestrator, "_llm_chain", lambda: [Capture()])
    client.post(
        "/api/v1/chat",
        json={
            "subject": "english",
            "level": "B1",
            "messages": [{"role": "user", "content": "Hi"}],
        },
    )
    assert "B1" in captured["sys"]
