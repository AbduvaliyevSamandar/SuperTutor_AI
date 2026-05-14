"""Daily word generator — LLM-backed, cached per day in memory."""
import json
import re
import threading
from datetime import date

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.services.llm.orchestrator import (
    AllProvidersFailed,
    chat_with_fallback,
)

router = APIRouter()

_CACHE: dict[str, dict] = {}
_LOCK = threading.Lock()
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


class WordOfDayResponse(BaseModel):
    word: str
    part_of_speech: str
    translation_uz: str
    definition_en: str
    example: str
    date: str


@router.get("/word-of-day", response_model=WordOfDayResponse)
def word_of_day() -> WordOfDayResponse:
    key = date.today().isoformat()
    with _LOCK:
        cached = _CACHE.get(key)
    if cached:
        return WordOfDayResponse(**cached)

    prompt = (
        "Pick ONE interesting B1/B2 English word (avoid common words like "
        "'hello', 'good'). Return ONLY JSON: "
        '{"word":"...","part_of_speech":"noun|verb|adjective|adverb",'
        '"translation_uz":"<Uzbek translation>","definition_en":"<short EN definition>",'
        '"example":"<one example sentence>"}'
    )
    try:
        reply, _ = chat_with_fallback([
            {"role": "system", "content": "JSON only."},
            {"role": "user", "content": prompt},
        ])
    except AllProvidersFailed as e:
        raise HTTPException(status_code=503, detail=str(e)) from e

    data = _extract_json(reply) or {}
    if not data.get("word"):
        raise HTTPException(status_code=502, detail="LLM did not return word")

    payload = {
        "word": str(data["word"]),
        "part_of_speech": str(data.get("part_of_speech") or "noun"),
        "translation_uz": str(data.get("translation_uz") or ""),
        "definition_en": str(data.get("definition_en") or ""),
        "example": str(data.get("example") or ""),
        "date": key,
    }
    with _LOCK:
        _CACHE[key] = payload
        # Trim cache to last 7 days
        if len(_CACHE) > 7:
            for k in sorted(_CACHE.keys())[:-7]:
                _CACHE.pop(k, None)
    return WordOfDayResponse(**payload)
