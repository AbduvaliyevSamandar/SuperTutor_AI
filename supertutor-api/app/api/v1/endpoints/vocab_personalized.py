"""Generate a personalized starter vocabulary deck.

LLM picks N high-frequency words that match the learner's CEFR level and
interests. Each entry is inserted into vocabulary_entries with FSRS defaults
so the SRS scheduler can pick them up immediately.
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.core.security import require_user_id
from app.core.supabase import get_supabase_admin
from app.services.llm.orchestrator import (
    AllProvidersFailed,
    chat_with_fallback,
)

router = APIRouter()


class GenerateRequest(BaseModel):
    language: Literal["english", "russian", "german", "turkish"] = "english"
    level: Literal["A1", "A2", "B1", "B2", "C1"] = "A2"
    interests: list[str] = Field(default_factory=list)
    n_words: int = Field(default=50, ge=10, le=200)


class GenerateResponse(BaseModel):
    inserted: int
    skipped_existing: int


SYSTEM = """You curate personalized vocabulary decks for language learners.

Given target language, CEFR level, and interests, output JSON ONLY:
{
  "words": [
    {"word": "...", "translation_uz": "...", "definition": "short English definition"},
    ...
  ]
}

Rules:
- Pick high-frequency, useful words at the target CEFR level.
- Half should be topical to the listed interests; half general.
- translation_uz: short, natural Uzbek translation.
- definition: under 80 chars, target language.
- No duplicates. No transliterations. No proper nouns.
"""


def _coerce(raw: str) -> dict:
    m = re.search(r"\{.*\}", raw.strip(), flags=re.DOTALL)
    if not m:
        raise ValueError("No JSON found")
    return json.loads(m.group(0))


@router.post("/vocab/personalized/generate", response_model=GenerateResponse)
def generate(
    req: GenerateRequest,
    user_id: str = Depends(require_user_id),
) -> GenerateResponse:
    client = get_supabase_admin()
    if client is None:
        raise HTTPException(status_code=503, detail="DB not configured")

    interests = ", ".join(req.interests) if req.interests else "general daily life"
    user_msg = (
        f"Target language: {req.language}\n"
        f"Level: {req.level}\n"
        f"Interests: {interests}\n"
        f"Count: {req.n_words}"
    )
    messages = [
        {"role": "system", "content": SYSTEM},
        {"role": "user", "content": user_msg},
    ]

    try:
        raw, _ = chat_with_fallback(messages)
    except AllProvidersFailed as e:
        raise HTTPException(status_code=503, detail=str(e)) from e

    try:
        words = _coerce(raw).get("words", [])
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Bad JSON: {e}") from e

    if not words:
        return GenerateResponse(inserted=0, skipped_existing=0)

    # Skip duplicates already in vocab for this user+language
    existing_rows = (
        client.table("vocabulary_entries")
        .select("word")
        .eq("user_id", user_id)
        .eq("language", req.language)
        .execute()
    )
    existing = {row["word"].strip().lower() for row in (existing_rows.data or [])}

    now_iso = datetime.now(timezone.utc).isoformat()
    rows: list[dict] = []
    seen_in_batch: set[str] = set()
    for w in words[: req.n_words]:
        if not isinstance(w, dict):
            continue
        word = (w.get("word") or "").strip()
        if not word:
            continue
        key = word.lower()
        if key in existing or key in seen_in_batch:
            continue
        seen_in_batch.add(key)
        rows.append({
            "user_id": user_id,
            "word": word,
            "language": req.language,
            "translation_uz": (w.get("translation_uz") or "")[:200],
            "definition": (w.get("definition") or "")[:300],
            "ease_factor": None,  # FSRS: null stability = new card
            "interval_days": 0,
            "repetitions": 0,
            "due_at": now_iso,
        })

    if not rows:
        return GenerateResponse(
            inserted=0,
            skipped_existing=len(words),
        )

    try:
        client.table("vocabulary_entries").insert(rows).execute()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"DB insert: {e}") from e

    return GenerateResponse(
        inserted=len(rows),
        skipped_existing=len(words) - len(rows),
    )
