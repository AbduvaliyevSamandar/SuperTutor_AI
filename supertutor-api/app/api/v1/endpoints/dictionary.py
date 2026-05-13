"""LLM-powered dictionary lookup. Returns definition, examples, translation
between any source and target language pair (en, ru, de, tr, uz)."""
import json
import re

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.core.security import current_user_id
from app.core.supabase import get_supabase_admin
from app.services.llm.orchestrator import AllProvidersFailed, chat_with_fallback

router = APIRouter()


LANG_NAMES = {
    "en": "English",
    "ru": "Russian",
    "de": "German",
    "tr": "Turkish",
    "uz": "Uzbek",
}


class LookupResponse(BaseModel):
    word: str
    source: str
    target: str
    part_of_speech: str | None = None
    translation: str
    definition: str
    examples: list[str]
    example_translations: list[str] = []
    synonyms: list[str] = []


class SaveWordRequest(BaseModel):
    word: str
    source: str
    target: str
    translation: str
    definition: str


def _normalize_lang(code: str | None, default: str) -> str:
    if not code:
        return default
    c = code.lower().strip()
    return c if c in LANG_NAMES else default


def _build_prompt(word: str, source: str, target: str) -> str:
    src = LANG_NAMES.get(source, "English")
    tgt = LANG_NAMES.get(target, "Uzbek")
    return (
        f'Dictionary entry for the {src} word "{word}", '
        f'translated and explained for a {tgt} speaker.\n'
        "Return ONLY one JSON object (no markdown fences, no commentary, no prose). "
        "Schema:\n"
        "{\n"
        '  "part_of_speech": "noun|verb|adjective|adverb|phrase",\n'
        f'  "translation": "concise {tgt} translation",\n'
        f'  "definition": "one short sentence in {tgt} explaining the word",\n'
        f'  "examples": ["{src} sentence with the word", "another {src} sentence"],\n'
        f'  "example_translations": ["{tgt} translation of example 1", "translation 2"],\n'
        f'  "synonyms": ["{src} synonym 1", "synonym 2"]\n'
        "}\n"
        "Examples must be in the SOURCE language. Translations in the TARGET language."
    )


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


@router.get("/dictionary/lookup", response_model=LookupResponse)
def lookup(
    word: str,
    source: str = "en",
    target: str = "uz",
    language: str | None = None,
) -> LookupResponse:
    if not word.strip():
        raise HTTPException(status_code=400, detail="word is empty")

    src = _normalize_lang(language or source, default="en")
    tgt = _normalize_lang(target, default="uz")
    if src == tgt:
        tgt = "uz" if src != "uz" else "en"

    messages = [
        {
            "role": "system",
            "content": "You are a precise bilingual dictionary. Reply with ONE JSON object only.",
        },
        {"role": "user", "content": _build_prompt(word.strip(), src, tgt)},
    ]

    try:
        reply, _ = chat_with_fallback(messages)
    except AllProvidersFailed as e:
        raise HTTPException(status_code=503, detail=str(e)) from e

    data = _extract_json(reply) or {}

    return LookupResponse(
        word=word,
        source=src,
        target=tgt,
        part_of_speech=data.get("part_of_speech"),
        translation=str(data.get("translation", "")).strip() or "—",
        definition=str(data.get("definition", "")).strip()
        or reply.strip()[:200],
        examples=[str(x) for x in (data.get("examples") or [])][:5],
        example_translations=[
            str(x) for x in (data.get("example_translations") or [])
        ][:5],
        synonyms=[str(x) for x in (data.get("synonyms") or [])][:5],
    )


@router.post("/dictionary/save")
def save_word(
    req: SaveWordRequest,
    user_id: str | None = Depends(current_user_id),
) -> dict:
    if not user_id:
        raise HTTPException(status_code=401, detail="Login required")
    client = get_supabase_admin()
    if client is None:
        raise HTTPException(status_code=503, detail="DB not configured")
    client.table("vocabulary_entries").upsert(
        {
            "user_id": user_id,
            "word": req.word,
            "language": req.source,
            "translation_uz": req.translation,
            "definition": req.definition,
        },
        on_conflict="user_id,word,language",
    ).execute()
    return {"ok": True}


@router.get("/dictionary/saved")
def saved_words(
    user_id: str | None = Depends(current_user_id),
) -> dict:
    if not user_id:
        raise HTTPException(status_code=401, detail="Login required")
    client = get_supabase_admin()
    if client is None:
        raise HTTPException(status_code=503, detail="DB not configured")
    r = (
        client.table("vocabulary_entries")
        .select("word, language, translation_uz, definition, saved_at")
        .eq("user_id", user_id)
        .order("saved_at", desc=True)
        .limit(200)
        .execute()
    )
    return {"items": r.data or []}
