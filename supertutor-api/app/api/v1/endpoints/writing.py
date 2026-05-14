"""IELTS Writing Task 2 — prompts + AI band scoring."""
import json
import random
import re

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.services.llm.orchestrator import (
    AllProvidersFailed,
    chat_with_fallback,
)

router = APIRouter()


_PROMPTS_TASK2 = [
    "Some people believe that universities should focus on teaching practical skills, while others say their main purpose is academic study. Discuss both views and give your opinion.",
    "In many countries, the gap between the rich and the poor is widening. What are the causes of this issue, and what can governments do about it?",
    "Some argue technology has improved education for everyone, while others disagree. Discuss both views and give your opinion.",
    "Many people prefer to live in cities even though life there can be stressful. Why is this the case? Should governments encourage people to live in rural areas?",
    "Tourism brings benefits but also harms local communities and the environment. To what extent do you agree or disagree?",
    "Today many people choose to work from home. Do the advantages of remote work outweigh the disadvantages?",
    "Some people believe children should learn a foreign language at primary school. Others think this should start later. Discuss both views.",
    "In many countries, the average lifespan is increasing. What problems does this cause and how can they be solved?",
]


class TaskResponse(BaseModel):
    id: str
    prompt: str
    time_limit_minutes: int = 40
    min_words: int = 250


class FeedbackRequest(BaseModel):
    prompt: str
    essay: str = Field(min_length=20)


class WritingFeedback(BaseModel):
    task_response: float
    coherence: float
    lexical: float
    grammar: float
    overall: float
    word_count: int
    feedback: str
    improved_intro: str | None = None
    improvements: list[str] = []


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


@router.get("/ielts/writing/task", response_model=TaskResponse)
def task() -> TaskResponse:
    p = random.choice(_PROMPTS_TASK2)
    return TaskResponse(id=str(abs(hash(p)) % 10**12), prompt=p)


@router.post("/ielts/writing/feedback", response_model=WritingFeedback)
def feedback(req: FeedbackRequest) -> WritingFeedback:
    words = len(re.findall(r"\b\w+\b", req.essay))

    prompt = (
        "You are an IELTS Writing Task 2 examiner. Score the essay below using "
        "band scores 0-9 for: task_response, coherence (Coherence & Cohesion), "
        "lexical (Lexical Resource), grammar (Grammatical Range & Accuracy). "
        "Also produce overall band (average rounded to nearest 0.5), a "
        "short Uzbek feedback paragraph (2-3 sentences), an improved intro "
        "sentence, and 3 specific improvement bullets in Uzbek. "
        "Return ONLY JSON: "
        '{"task_response":7.0,"coherence":6.5,"lexical":6.5,"grammar":6.0,'
        '"overall":6.5,"feedback":"...","improved_intro":"...",'
        '"improvements":["...","...","..."]}\n\n'
        f"Task prompt: {req.prompt}\n\nStudent essay ({words} words):\n{req.essay}"
    )
    messages = [
        {"role": "system", "content": "You are a strict IELTS examiner. JSON only."},
        {"role": "user", "content": prompt},
    ]
    try:
        reply, _ = chat_with_fallback(messages)
    except AllProvidersFailed as e:
        raise HTTPException(status_code=503, detail=str(e)) from e

    data = _extract_json(reply) or {}

    def _band(k: str, d: float) -> float:
        try:
            return max(0.0, min(9.0, float(data.get(k, d))))
        except (TypeError, ValueError):
            return d

    return WritingFeedback(
        task_response=_band("task_response", 5.0),
        coherence=_band("coherence", 5.0),
        lexical=_band("lexical", 5.0),
        grammar=_band("grammar", 5.0),
        overall=_band("overall", 5.0),
        word_count=words,
        feedback=str(data.get("feedback") or "Davom etib mashq qiling."),
        improved_intro=(data.get("improved_intro") or None),
        improvements=[str(x) for x in (data.get("improvements") or [])][:5],
    )
