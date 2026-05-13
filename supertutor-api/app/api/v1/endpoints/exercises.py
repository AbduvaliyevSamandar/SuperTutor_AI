"""Listening + cloze exercise generators."""
import json
import re

from fastapi import APIRouter, HTTPException

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


@router.get("/listening/sentence")
def listening_sentence(subject: str = "english", level: str = "A2") -> dict:
    lang = LANG_NAME.get(subject.lower(), "English")
    prompt = (
        f"Generate ONE short {lang} sentence at CEFR {level} level that an Uzbek "
        f"learner should practice listening to. Return ONLY JSON: "
        f'{{"text": "...", "translation_uz": "Uzbek translation"}}. '
        f"Keep the sentence 6-12 words. No emojis, no quotes inside."
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
    return {
        "text": data.get("text") or reply.strip().split("\n")[0],
        "translation_uz": data.get("translation_uz", ""),
        "language_code": _bcp47(subject),
    }


@router.get("/cloze/generate")
def cloze_generate(subject: str = "english", level: str = "A2") -> dict:
    lang = LANG_NAME.get(subject.lower(), "English")
    prompt = (
        f"Generate ONE {lang} sentence at CEFR {level} level with EXACTLY one "
        f"word replaced by ___ (three underscores). Provide 4 options where "
        f"only one is correct grammatically and semantically. "
        f"Return ONLY JSON: "
        f'{{"sentence":"I ___ to the gym every day.","options":["go","goes","went","going"],'
        f'"correct_index":0,"translation_uz":"Men har kuni sport zaliga boraman."}}'
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
    opts = data.get("options") or []
    if len(opts) != 4:
        raise HTTPException(status_code=502, detail="LLM returned invalid cloze")
    try:
        ci = int(data.get("correct_index", 0))
    except (TypeError, ValueError):
        ci = 0
    return {
        "sentence": data.get("sentence", ""),
        "options": [str(x) for x in opts][:4],
        "correct_index": max(0, min(3, ci)),
        "translation_uz": data.get("translation_uz", ""),
    }


def _bcp47(subject: str) -> str:
    return {
        "english": "en",
        "russian": "ru",
        "german": "de",
        "turkish": "tr",
    }.get(subject.lower(), "en")
