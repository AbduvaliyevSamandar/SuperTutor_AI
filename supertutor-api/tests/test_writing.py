def test_writing_task_returns_prompt(client):
    r = client.get("/api/v1/ielts/writing/task")
    assert r.status_code == 200
    data = r.json()
    assert "prompt" in data
    assert data["time_limit_minutes"] == 40
    assert data["min_words"] == 250


def test_writing_feedback_requires_essay(client):
    r = client.post(
        "/api/v1/ielts/writing/feedback",
        json={"prompt": "Discuss.", "essay": "short"},
    )
    # Pydantic min_length=20 should reject
    assert r.status_code == 422
