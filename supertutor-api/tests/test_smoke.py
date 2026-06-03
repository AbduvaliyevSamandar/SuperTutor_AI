"""Backend smoke tests — run with: pytest supertutor-api/tests"""
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_root():
    r = client.get("/")
    assert r.status_code == 200
    assert "SuperTutor" in r.json()["name"]


def test_health():
    r = client.get("/api/v1/health")
    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "ok"
    # All three provider chains should be reported even if not configured.
    assert "llm_providers" in body
    assert "stt_providers" in body
    assert "vision_providers" in body


def test_version():
    r = client.get("/api/v1/version")
    assert r.status_code == 200
    body = r.json()
    assert "min_supported" in body
    assert "latest" in body


def test_chat_warmup():
    r = client.get("/api/v1/chat/warmup")
    assert r.status_code == 200
    assert r.json()["warm"] is True


def test_tts_voices():
    r = client.get("/api/v1/tts/voices")
    assert r.status_code == 200
    items = r.json()["items"]
    assert isinstance(items, list)
    assert len(items) > 0
    sample = items[0]
    for key in ("id", "label", "gender", "language"):
        assert key in sample


def test_tts_voices_filtered():
    r = client.get("/api/v1/tts/voices?language=en")
    assert r.status_code == 200
    items = r.json()["items"]
    assert all(v["language"] == "en" for v in items)


def test_chat_requires_subject_or_messages():
    # Missing messages -> validation error
    r = client.post("/api/v1/chat", json={"subject": "english"})
    assert r.status_code == 422


def test_stats_me_requires_auth():
    r = client.get("/api/v1/stats/me")
    assert r.status_code == 401


def test_sessions_list_requires_auth():
    r = client.get("/api/v1/sessions")
    assert r.status_code == 401


def test_notifications_register_requires_auth():
    r = client.post(
        "/api/v1/notifications/register-token",
        json={"fcm_token": "test"},
    )
    assert r.status_code == 401


def test_dictionary_lookup_validation():
    # Empty word -> 400
    r = client.get("/api/v1/dictionary/lookup?word=")
    assert r.status_code == 400
