"""Commute Mode — hands-free graduated interval audio lessons.

Generates a 10-step lesson in one LLM call. Each step has:
- prompt_uz: what the AI says in Uzbek (cue)
- target_en: the expected English sentence
- hint: short clue (optional)

The Flutter screen plays prompt → records user → STT → checks similarity
to target_en → confirms → next.
"""
from __future__ import annotations

import json
import re
from typing import Literal

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.services.llm.orchestrator import (
    AllProvidersFailed,
    chat_with_fallback,
)

router = APIRouter()


class CommuteStep(BaseModel):
    prompt_uz: str
    target_en: str
    hint: str = ""


class CommuteLesson(BaseModel):
    title: str
    steps: list[CommuteStep]


class CommuteRequest(BaseModel):
    language: str = Field(default="english")
    level: Literal["A1", "A2", "B1", "B2", "C1"] = "A2"
    topic: str | None = None
    n_steps: int = Field(default=10, ge=5, le=20)


SYSTEM = """You are creating a Pimsleur-style audio language lesson.
The user is Uzbek and learning English (or the chosen target language).
For each step you produce:
- prompt_uz: ONE short Uzbek instruction asking the user to say something,
  using natural conversational Uzbek (e.g., "Endi 'Men hoziroq kelaman'
  jumlasini ingliz tilida ayting").
- target_en: the EXACT short English sentence the learner should produce.
  Keep it under 12 words, matching the CEFR level.
- hint: optional 1-3 word vocab hint (in English).

Use graduated interval: reuse some words from earlier steps. Vary tense and
sentence structure across the lesson. Make it feel like a coherent topic.

Respond with JSON ONLY: {"title": "...", "steps": [{...}, ...]}.
"""


def _build_prompt(req: CommuteRequest) -> str:
    topic = req.topic or "everyday conversation"
    return (
        f"Target language: {req.language}. CEFR level: {req.level}. "
        f"Topic: {topic}. Number of steps: {req.n_steps}."
    )


def _coerce_json(raw: str) -> dict:
    raw = raw.strip()
    # Strip ```json ... ``` fences
    m = re.search(r"\{.*\}", raw, flags=re.DOTALL)
    if not m:
        raise ValueError("No JSON object found in LLM response")
    return json.loads(m.group(0))


@router.post("/commute/lesson", response_model=CommuteLesson)
def lesson(req: CommuteRequest) -> CommuteLesson:
    messages = [
        {"role": "system", "content": SYSTEM},
        {"role": "user", "content": _build_prompt(req)},
    ]
    try:
        raw, _ = chat_with_fallback(messages)
    except AllProvidersFailed as e:
        raise HTTPException(status_code=503, detail=str(e)) from e

    try:
        data = _coerce_json(raw)
        steps = [CommuteStep(**s) for s in data.get("steps", [])][: req.n_steps]
        if not steps:
            raise ValueError("Empty steps")
        title = data.get("title") or "Commute lesson"
        return CommuteLesson(title=title, steps=steps)
    except Exception as e:
        raise HTTPException(
            status_code=502, detail=f"Bad LLM JSON: {e}"
        ) from e
