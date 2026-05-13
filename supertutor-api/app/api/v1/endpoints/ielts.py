"""IELTS Speaking simulator: 3 parts + final feedback."""
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


class PartQuestion(BaseModel):
    part: int
    text: str
    seconds: int = 60


class StartResponse(BaseModel):
    session_id: str
    questions: list[PartQuestion]


class Answer(BaseModel):
    question: str
    transcript: str


class FeedbackRequest(BaseModel):
    answers: list[Answer]


class BandScores(BaseModel):
    fluency: float
    lexical: float
    grammar: float
    pronunciation: float
    overall: float
    feedback: str


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


@router.post("/ielts/speaking/start", response_model=StartResponse)
def start() -> StartResponse:
    prompt = (
        "Generate an IELTS Speaking test for an Uzbek learner. Return ONLY JSON: "
        '{"questions":[{"part":1,"text":"...","seconds":30},...]}. '
        "Part 1: exactly 4 short personal questions, 30 seconds each. "
        "Part 2: exactly 1 long-turn cue card topic, 120 seconds. "
        "Part 3: exactly 3 discussion questions tied to Part 2 topic, 45 seconds each. "
        "Total 8 questions. Use simple, natural examiner English."
    )
    messages = [
        {"role": "system", "content": "You return ONE JSON object only."},
        {"role": "user", "content": prompt},
    ]
    try:
        reply, _ = chat_with_fallback(messages)
    except AllProvidersFailed as e:
        raise HTTPException(status_code=503, detail=str(e)) from e

    data = _extract_json(reply) or {}
    raw_qs = data.get("questions") or []
    questions: list[PartQuestion] = []
    for q in raw_qs:
        try:
            questions.append(PartQuestion(
                part=int(q.get("part", 1)),
                text=str(q.get("text", "")).strip(),
                seconds=int(q.get("seconds", 60)),
            ))
        except Exception:
            continue
    if len(questions) < 4:
        raise HTTPException(status_code=502, detail="LLM did not produce enough questions")

    return StartResponse(session_id=str(uuid.uuid4()), questions=questions)


@router.post("/ielts/speaking/feedback", response_model=BandScores)
def feedback(req: FeedbackRequest) -> BandScores:
    transcripts = "\n".join(
        f"Q: {a.question}\nA: {a.transcript}" for a in req.answers if a.transcript.strip()
    )
    if not transcripts:
        raise HTTPException(status_code=400, detail="No transcripts")

    prompt = (
        "Score this IELTS Speaking transcript using band scores 0-9 for each "
        "of Fluency & Coherence, Lexical Resource, Grammatical Range & Accuracy, "
        "Pronunciation (estimate from text). Return ONLY JSON: "
        '{"fluency":7.0,"lexical":6.5,"grammar":6.5,"pronunciation":6.0,'
        '"overall":6.5,"feedback":"<2-3 sentence Uzbek feedback>"}. '
        "Be honest and specific.\n\n"
        f"Transcripts:\n{transcripts}"
    )
    messages = [
        {"role": "system", "content": "You are a certified IELTS examiner. Reply with ONE JSON only."},
        {"role": "user", "content": prompt},
    ]
    try:
        reply, _ = chat_with_fallback(messages)
    except AllProvidersFailed as e:
        raise HTTPException(status_code=503, detail=str(e)) from e

    data = _extract_json(reply) or {}
    def _bs(k: str, fallback: float) -> float:
        try:
            v = float(data.get(k, fallback))
            return max(0.0, min(9.0, v))
        except (TypeError, ValueError):
            return fallback

    return BandScores(
        fluency=_bs("fluency", 5.0),
        lexical=_bs("lexical", 5.0),
        grammar=_bs("grammar", 5.0),
        pronunciation=_bs("pronunciation", 5.0),
        overall=_bs("overall", 5.0),
        feedback=str(data.get("feedback") or "Davom eting va ko'p mashq qiling."),
    )
