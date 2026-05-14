"""IELTS full mock test — combines Listening + Reading + Writing + Speaking."""
from fastapi import APIRouter
from pydantic import BaseModel, Field

router = APIRouter()


class SectionResult(BaseModel):
    section: str  # "listening" | "reading" | "writing" | "speaking"
    band: float = Field(ge=0, le=9)


class MockScoreRequest(BaseModel):
    results: list[SectionResult]


class MockScoreResponse(BaseModel):
    overall: float
    listening: float
    reading: float
    writing: float
    speaking: float
    cefr: str  # "A1".."C2"


def _band_to_cefr(b: float) -> str:
    if b >= 8.5: return "C2"
    if b >= 7.0: return "C1"
    if b >= 6.0: return "B2"
    if b >= 5.0: return "B1"
    if b >= 4.0: return "A2"
    return "A1"


def _round_half(x: float) -> float:
    return round(x * 2) / 2


@router.post("/ielts/mock/score", response_model=MockScoreResponse)
def score(req: MockScoreRequest) -> MockScoreResponse:
    by_section = {s: 0.0 for s in ["listening", "reading", "writing", "speaking"]}
    for r in req.results:
        if r.section in by_section:
            by_section[r.section] = float(r.band)
    overall = _round_half(
        sum(by_section.values()) / 4
    )
    return MockScoreResponse(
        overall=overall,
        listening=by_section["listening"],
        reading=by_section["reading"],
        writing=by_section["writing"],
        speaking=by_section["speaking"],
        cefr=_band_to_cefr(overall),
    )
