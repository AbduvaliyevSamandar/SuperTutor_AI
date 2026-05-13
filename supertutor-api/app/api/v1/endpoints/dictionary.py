"""LLM-powered dictionary lookup. Returns definition, examples, translation."""
import json

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.core.security import current_user_id
from app.core.supabase import get_supabase_admin
from app.services.llm.orchestrator import AllProvidersFailed, chat_with_fallback

router = APIRouter()


_LANG_NAMES = {
    "en": "English",
    "ru": "Russian",
    "de": "German",
    "tr": "Turkish",
}


class LookupResponse(BaseModel):
    word: str
    language: str
    part_of_speech: str | None = None
    translation_uz: str
    definition: str
    examples: list[str]
    synonyms: list[str] = []


class SaveWordRequest(BaseModel):
    word: str
    language: str
    translation_uz: str
    definition: str


def _build_prompt(word: str, language: str) -> str:
    lang_name = _LANG_NAMES.get(language, "English")
    return (
        f"Define the {lang_name} word \"{word}\" for an Uzbek learner. "
        "Return ONLY a JSON object (no markdown, no commentary) with keys: "
        "part_of_speech (noun/verb/adj/...), "
        "translation_uz (short Uzbek translation), "
        "definition (one-sentence definition in simple English), "
        "examples (array of 2 short usage sentences with the word in context), "
        "synonyms (array of 2-3 close synonyms). "
        "Keep all values plain strings without surrounding quotes."
    )


@router.get("/dictionary/lookup", response_model=LookupResponse)
def lookup(word: str, language: str = "en") -> LookupResponse:
    if not word.strip():
        raise HTTPException(status_code=400, detail="word is empty")

    prompt = _build_prompt(word.strip(), language)
    messages = [
        {"role": "system", "content": "You are a precise dictionary assistant. Always reply in JSON."},
        {"role": "user", "content": prompt},
    ]

    try:
        reply, _ = chat_with_fallback(messages)
    except AllProvidersFailed as e:
        raise HTTPException(status_code=503, detail=str(e)) from e

    # Strip code fences if any
    text = reply.strip()
    if text.startswith("```"):
        text = text.split("```", 2)[1]
        if text.startswith("json"):
            text = text[4:]
        text = text.rsplit("```", 1)[0]

    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        # Fallback: return a stub built from raw reply
        return LookupResponse(
            word=word,
            language=language,
            definition=reply.strip()[:200],
            translation_uz="(no parse)",
            examples=[],
        )

    return LookupResponse(
        word=word,
        language=language,
        part_of_speech=data.get("part_of_speech"),
        translation_uz=data.get("translation_uz", ""),
        definition=data.get("definition", ""),
        examples=data.get("examples", [])[:5],
        synonyms=data.get("synonyms", [])[:5],
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
            "language": req.language,
            "translation_uz": req.translation_uz,
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
