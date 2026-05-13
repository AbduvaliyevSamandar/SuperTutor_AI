"""Pronunciation scoring — compare user audio transcript to target sentence."""
import difflib
import re

from fastapi import APIRouter, File, Form, HTTPException, UploadFile

from app.services.llm.orchestrator import (
    AllProvidersFailed,
    transcribe_with_fallback,
)

router = APIRouter()


def _tokenize(s: str) -> list[str]:
    return re.findall(r"[A-Za-zÀ-ÿА-яЁё]+", s.lower())


@router.post("/pronunciation/score")
async def score(
    file: UploadFile = File(...),
    target: str = Form(...),
    language: str = Form(default="en"),
) -> dict:
    audio = await file.read()
    if not audio:
        raise HTTPException(status_code=400, detail="Empty audio")
    if not target.strip():
        raise HTTPException(status_code=400, detail="Empty target")

    try:
        heard, _ = transcribe_with_fallback(
            audio, filename=file.filename or "audio.webm", language=language
        )
    except AllProvidersFailed as e:
        raise HTTPException(status_code=503, detail=str(e)) from e

    target_tokens = _tokenize(target)
    heard_tokens = _tokenize(heard or "")

    matcher = difflib.SequenceMatcher(a=target_tokens, b=heard_tokens)
    matched: set[int] = set()
    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        if tag == "equal":
            for k in range(i1, i2):
                matched.add(k)

    per_word = [
        {"word": w, "correct": idx in matched}
        for idx, w in enumerate(target_tokens)
    ]
    overall = (
        round(len(matched) / max(1, len(target_tokens)) * 100)
        if target_tokens
        else 0
    )

    feedback = (
        "A'lo! Talaffuzingiz aniq." if overall >= 90
        else "Yaxshi, lekin yaxshilash mumkin." if overall >= 60
        else "Sekinroq va aniqroq qaytaring."
    )

    return {
        "score": overall,
        "heard": heard,
        "target": target,
        "per_word": per_word,
        "feedback": feedback,
    }
