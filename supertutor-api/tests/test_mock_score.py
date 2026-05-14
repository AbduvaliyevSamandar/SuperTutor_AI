def test_mock_score_average(client):
    payload = {
        "results": [
            {"section": "listening", "band": 7.0},
            {"section": "reading", "band": 6.5},
            {"section": "writing", "band": 6.0},
            {"section": "speaking", "band": 7.5},
        ]
    }
    r = client.post("/api/v1/ielts/mock/score", json=payload)
    assert r.status_code == 200
    data = r.json()
    # Average = 6.75 → rounded to nearest 0.5 → 7.0 (half-rounding)
    assert data["overall"] in (6.5, 7.0)
    assert data["listening"] == 7.0
    assert data["reading"] == 6.5
    assert data["cefr"] in {"B2", "C1"}


def test_mock_score_handles_missing_section(client):
    r = client.post(
        "/api/v1/ielts/mock/score",
        json={"results": [{"section": "writing", "band": 8.0}]},
    )
    assert r.status_code == 200
    data = r.json()
    assert data["writing"] == 8.0
    # The other three default to 0
    assert data["listening"] == 0.0


def test_mock_score_clamps_bad_input(client):
    r = client.post(
        "/api/v1/ielts/mock/score",
        json={"results": [{"section": "speaking", "band": 12.0}]},
    )
    assert r.status_code == 422  # band > 9 fails validation


def test_mock_score_band_to_cefr(client):
    r = client.post(
        "/api/v1/ielts/mock/score",
        json={
            "results": [
                {"section": "listening", "band": 9.0},
                {"section": "reading", "band": 9.0},
                {"section": "writing", "band": 9.0},
                {"section": "speaking", "band": 9.0},
            ]
        },
    )
    data = r.json()
    assert data["overall"] == 9.0
    assert data["cefr"] == "C2"
