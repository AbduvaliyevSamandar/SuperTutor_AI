"""IELTS Reading: passage + comprehension questions."""
import json
import re
import uuid

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.services.llm.orchestrator import (
    AllProvidersFailed,
    chat_with_fallback,
)

router = APIRouter()

_JSON_RE = re.compile(r"\{[\s\S]*\}", re.MULTILINE)


def _extract_json(text: str) -> dict | None:
    text = text.strip()
    if text.startswith("```"):
        text = text.split("```", 2)[1]
        if text.startswith("json"):
            text = text[4:]
        text = text.rsplit("```", 1)[0].strip()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass
    m = _JSON_RE.search(text)
    if not m:
        return None
    try:
        return json.loads(m.group(0))
    except json.JSONDecodeError:
        return None


class ReadingQuestion(BaseModel):
    question: str
    options: list[str]
    correct_index: int


class ReadingPassage(BaseModel):
    id: str
    title: str
    passage: str
    questions: list[ReadingQuestion]


class CheckRequest(BaseModel):
    questions: list[ReadingQuestion]
    answers: list[int]


class CheckResponse(BaseModel):
    score: int
    total: int
    percentage: int
    band: float


def _band_from_pct(pct: int) -> float:
    # Rough IELTS Reading band conversion (Academic, /13)
    if pct >= 92: return 9.0
    if pct >= 85: return 8.0
    if pct >= 77: return 7.0
    if pct >= 69: return 6.5
    if pct >= 60: return 6.0
    if pct >= 50: return 5.5
    if pct >= 40: return 5.0
    if pct >= 30: return 4.5
    return 4.0


@router.get("/ielts/reading/passage", response_model=ReadingPassage)
def passage(level: str = "B2") -> ReadingPassage:
    prompt = (
        f"Generate an IELTS Reading Academic passage (level {level}, ~500 words, "
        "factual non-fiction topic like science, history, environment or technology). "
        "Then 7 multiple-choice comprehension questions (4 options each). "
        "Return ONLY JSON: "
        '{"title":"...","passage":"...","questions":[{"question":"...","options":["A","B","C","D"],"correct_index":0},...]}. '
        "Passage as a single string with \\n\\n between paragraphs. "
        "Questions mix detail, vocabulary, inference."
    )
    try:
        reply, _ = chat_with_fallback([
            {"role": "system", "content": "You return ONE JSON object only."},
            {"role": "user", "content": prompt},
        ])
    except AllProvidersFailed as e:
        raise HTTPException(status_code=503, detail=str(e)) from e
    data = _extract_json(reply) or {}
    questions: list[ReadingQuestion] = []
    for q in data.get("questions") or []:
        opts = q.get("options") or []
        if len(opts) != 4:
            continue
        try:
            ci = int(q.get("correct_index", 0))
        except (TypeError, ValueError):
            ci = 0
        questions.append(ReadingQuestion(
            question=str(q.get("question", "")),
            options=[str(o) for o in opts],
            correct_index=max(0, min(3, ci)),
        ))
    if not questions or not data.get("passage"):
        raise HTTPException(status_code=502, detail="LLM did not produce valid passage")
    return ReadingPassage(
        id=str(uuid.uuid4()),
        title=str(data.get("title", "Reading passage")),
        passage=str(data.get("passage", "")),
        questions=questions,
    )


@router.post("/ielts/reading/check", response_model=CheckResponse)
def check(req: CheckRequest) -> CheckResponse:
    total = len(req.questions)
    correct = 0
    for i, q in enumerate(req.questions):
        if i < len(req.answers) and req.answers[i] == q.correct_index:
            correct += 1
    pct = int(round(correct / max(1, total) * 100))
    return CheckResponse(
        score=correct,
        total=total,
        percentage=pct,
        band=_band_from_pct(pct),
    )
