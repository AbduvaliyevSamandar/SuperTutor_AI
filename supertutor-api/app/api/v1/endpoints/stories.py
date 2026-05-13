"""Short stories with comprehension questions."""
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
LANG_NAME = {
    "english": "English",
    "russian": "Russian",
    "german": "German",
    "turkish": "Turkish",
}


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


class StoryQuestion(BaseModel):
    question: str
    options: list[str]
    correct_index: int


class StoryResponse(BaseModel):
    id: str
    title: str
    paragraphs: list[str]
    questions: list[StoryQuestion]


@router.get("/stories/generate", response_model=StoryResponse)
def generate(subject: str = "english", level: str = "A2") -> StoryResponse:
    lang = LANG_NAME.get(subject.lower(), "English")
    prompt = (
        f"Write a short {lang} story for an Uzbek CEFR {level} learner. "
        "Return ONLY JSON: "
        '{"title":"...","paragraphs":["...","...","..."],"questions":[{"question":"...","options":["A","B","C","D"],"correct_index":0},...]}. '
        "Exactly 3 paragraphs (2-3 sentences each). Exactly 3 multiple-choice questions about the story. Engaging plot, simple vocabulary."
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
    paragraphs = [str(p) for p in (data.get("paragraphs") or []) if str(p).strip()]
    raw_qs = data.get("questions") or []
    qs: list[StoryQuestion] = []
    for q in raw_qs:
        opts = q.get("options") or []
        if len(opts) != 4:
            continue
        try:
            ci = int(q.get("correct_index", 0))
        except (TypeError, ValueError):
            ci = 0
        qs.append(StoryQuestion(
            question=str(q.get("question", "")),
            options=[str(o) for o in opts],
            correct_index=max(0, min(3, ci)),
        ))
    if not paragraphs or not qs:
        raise HTTPException(status_code=502, detail="LLM did not produce valid story")

    return StoryResponse(
        id=str(uuid.uuid4()),
        title=str(data.get("title", "Story")),
        paragraphs=paragraphs,
        questions=qs,
    )
