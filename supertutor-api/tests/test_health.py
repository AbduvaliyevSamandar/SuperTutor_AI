def test_health_ok(client):
    r = client.get("/api/v1/health")
    assert r.status_code == 200
    data = r.json()
    assert data["status"] == "ok"
    assert "llm_providers" in data
    assert "stt_providers" in data
    names = [p["name"] for p in data["llm_providers"]]
    assert names == ["groq", "openai", "gemini"]
