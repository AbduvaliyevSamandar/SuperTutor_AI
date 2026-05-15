"""Daily AI-generated 'podcast' — short narrated English text."""
from datetime import date
import threading

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.services.llm.orchestrator import (
    AllProvidersFailed,
    chat_with_fallback,
)

router = APIRouter()

_CACHE: dict[str, dict] = {}
_LOCK = threading.Lock()


class PodcastResponse(BaseModel):
    title: str
    script: str
    summary_uz: str
    date: str


@router.get("/podcast/today", response_model=PodcastResponse)
def today(level: str = "B1") -> PodcastResponse:
    key = f"{date.today().isoformat()}-{level}"
    with _LOCK:
        cached = _CACHE.get(key)
    if cached:
        return PodcastResponse(**cached)

    prompt = (
        f"Write a short 5-minute English podcast monologue (~400 words, CEFR {level}) "
        "on an interesting general-interest topic (science, history, technology, "
        "culture, psychology — pick one). Natural spoken style, includes 'today I want "
        "to talk about...' opening and 'thanks for listening' closing. "
        "After the script add a 2-sentence Uzbek summary. Return ONLY JSON: "
        '{"title":"...","script":"<full English script>","summary_uz":"<Uzbek summary>"}'
    )
    try:
        reply, _ = chat_with_fallback([
            {"role": "system", "content": "JSON only."},
            {"role": "user", "content": prompt},
        ])
    except AllProvidersFailed as e:
        raise HTTPException(status_code=503, detail=str(e)) from e

    import json, re
    text = reply.strip()
    if text.startswith("```"):
        text = text.split("```", 2)[1]
        if text.startswith("json"):
            text = text[4:]
        text = text.rsplit("```", 1)[0].strip()
    try:
        data = json.loads(text)
    except Exception:
        m = re.search(r"\{[\s\S]*\}", text)
        if not m:
            raise HTTPException(status_code=502, detail="bad LLM JSON")
        try:
            data = json.loads(m.group(0))
        except Exception:
            raise HTTPException(status_code=502, detail="bad LLM JSON")

    payload = {
        "title": str(data.get("title", "Daily podcast")),
        "script": str(data.get("script", "")),
        "summary_uz": str(data.get("summary_uz", "")),
        "date": date.today().isoformat(),
    }
    with _LOCK:
        _CACHE[key] = payload
        if len(_CACHE) > 14:
            for k in sorted(_CACHE.keys())[:-14]:
                _CACHE.pop(k, None)
    return PodcastResponse(**payload)
