"""IELTS Listening: short audio script + comprehension questions."""
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


class ListenQuestion(BaseModel):
    question: str
    options: list[str]
    correct_index: int


class ListeningTest(BaseModel):
    id: str
    title: str
    script: str  # one-narrator script that we'll TTS on client
    questions: list[ListenQuestion]


class CheckRequest(BaseModel):
    questions: list[ListenQuestion]
    answers: list[int]


class CheckResponse(BaseModel):
    score: int
    total: int
    percentage: int


@router.get("/ielts/listening/test", response_model=ListeningTest)
def listening_test() -> ListeningTest:
    prompt = (
        "Generate a short IELTS-style listening monologue script (~150 words, "
        "B1-B2 level, single narrator, topic like a campus announcement, "
        "travel info, or a short lecture intro). Then 5 multiple-choice "
        "comprehension questions (4 options each). Return ONLY JSON: "
        '{"title":"...","script":"...","questions":[{"question":"...","options":["A","B","C","D"],"correct_index":0},...]}.'
    )
    try:
        reply, _ = chat_with_fallback([
            {"role": "system", "content": "You return ONE JSON object only."},
            {"role": "user", "content": prompt},
        ])
    except AllProvidersFailed as e:
        raise HTTPException(status_code=503, detail=str(e)) from e
    data = _extract_json(reply) or {}
    qs: list[ListenQuestion] = []
    for q in data.get("questions") or []:
        opts = q.get("options") or []
        if len(opts) != 4:
            continue
        try:
            ci = int(q.get("correct_index", 0))
        except (TypeError, ValueError):
            ci = 0
        qs.append(ListenQuestion(
            question=str(q.get("question", "")),
            options=[str(o) for o in opts],
            correct_index=max(0, min(3, ci)),
        ))
    if not qs or not data.get("script"):
        raise HTTPException(status_code=502, detail="LLM did not produce valid test")
    return ListeningTest(
        id=str(uuid.uuid4()),
        title=str(data.get("title", "Listening test")),
        script=str(data.get("script", "")),
        questions=qs,
    )


@router.post("/ielts/listening/check", response_model=CheckResponse)
def check(req: CheckRequest) -> CheckResponse:
    total = len(req.questions)
    correct = 0
    for i, q in enumerate(req.questions):
        if i < len(req.answers) and req.answers[i] == q.correct_index:
            correct += 1
    pct = int(round(correct / max(1, total) * 100))
    return CheckResponse(score=correct, total=total, percentage=pct)
