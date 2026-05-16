"""Teach-back (Feynman) evaluation.

The user explains a concept aloud after a lesson. We score their
explanation on 4 axes and surface knowledge gaps.
"""
from __future__ import annotations

import json
import re

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.services.llm.orchestrator import (
    AllProvidersFailed,
    chat_with_fallback,
)

router = APIRouter()


class TeachbackRequest(BaseModel):
    topic: str
    reference: str | None = Field(default=None, description="Source material or lesson notes")
    explanation: str = Field(..., description="What the user said when teaching it back")


class TeachbackScore(BaseModel):
    accuracy: int = Field(ge=0, le=10)
    completeness: int = Field(ge=0, le=10)
    clarity: int = Field(ge=0, le=10)
    fluency: int = Field(ge=0, le=10)
    overall: int = Field(ge=0, le=10)
    strengths: list[str] = []
    gaps: list[str] = []
    next_step: str = ""


SYSTEM = """You are an expert tutor evaluating a student's "teach-back".
The student tries to explain a concept they just learned (Feynman technique).
You score their explanation on a 0-10 scale across:
- accuracy: factual correctness
- completeness: covers the main points
- clarity: clear, well-organized, easy to follow
- fluency: confident language, smooth delivery

Reply strictly in JSON:
{
  "accuracy": 0-10,
  "completeness": 0-10,
  "clarity": 0-10,
  "fluency": 0-10,
  "overall": 0-10,
  "strengths": ["..."],
  "gaps": ["..."],
  "next_step": "one sentence: what to study next, in Uzbek"
}

Provide 1-3 strengths and 1-3 specific gaps. Be kind but honest.
"""


def _coerce(raw: str) -> dict:
    m = re.search(r"\{.*\}", raw.strip(), flags=re.DOTALL)
    if not m:
        raise ValueError("No JSON in response")
    return json.loads(m.group(0))


@router.post("/teachback/evaluate", response_model=TeachbackScore)
def evaluate(req: TeachbackRequest) -> TeachbackScore:
    user_msg = f"Topic: {req.topic}\n\n"
    if req.reference:
        user_msg += f"Source/lesson notes:\n{req.reference}\n\n"
    user_msg += f"Student's explanation:\n{req.explanation}"

    messages = [
        {"role": "system", "content": SYSTEM},
        {"role": "user", "content": user_msg},
    ]
    try:
        raw, _ = chat_with_fallback(messages)
    except AllProvidersFailed as e:
        raise HTTPException(status_code=503, detail=str(e)) from e

    try:
        data = _coerce(raw)
        return TeachbackScore(**data)
    except Exception as e:
        raise HTTPException(
            status_code=502, detail=f"Bad LLM JSON: {e}"
        ) from e
