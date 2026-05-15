"""Camera dictionary — identify object in image, return its name in target lang."""
import base64
import json
import re

from fastapi import APIRouter, File, Form, HTTPException, UploadFile

from app.services.llm.orchestrator import (
    AllProvidersFailed,
    analyze_image_with_fallback,
)

router = APIRouter()

_LANG = {
    "en": "English",
    "ru": "Russian",
    "de": "German",
    "tr": "Turkish",
    "uz": "Uzbek",
}


@router.post("/identify/object")
async def identify(
    file: UploadFile = File(...),
    target: str = Form(default="en"),
) -> dict:
    if file.content_type not in {"image/jpeg", "image/jpg", "image/png", "image/webp"}:
        raise HTTPException(status_code=415, detail=f"Bad image type: {file.content_type}")
    data = await file.read()
    if not data:
        raise HTTPException(status_code=400, detail="Empty image")
    if len(data) > 8 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="Image too large")

    lang = _LANG.get(target.lower(), "English")
    prompt = (
        f"Identify the main object in this image. Return ONLY JSON: "
        f'{{"word":"<{lang} name>","translation_uz":"<Uzbek translation>",'
        '"example":"<short example sentence in target language using the word>",'
        '"confidence":"high|medium|low"}}. '
        "If there are multiple objects, pick the most prominent one."
    )
    system = "You identify objects in images. Reply with ONE JSON object only."
    try:
        text, _ = analyze_image_with_fallback(
            prompt=prompt,
            image=data,
            mime=file.content_type or "image/jpeg",
            system=system,
        )
    except AllProvidersFailed as e:
        raise HTTPException(status_code=503, detail=str(e)) from e

    text = text.strip()
    if text.startswith("```"):
        text = text.split("```", 2)[1]
        if text.startswith("json"):
            text = text[4:]
        text = text.rsplit("```", 1)[0].strip()
    try:
        result = json.loads(text)
    except Exception:
        m = re.search(r"\{[\s\S]*\}", text)
        if not m:
            raise HTTPException(status_code=502, detail="bad LLM JSON")
        try:
            result = json.loads(m.group(0))
        except Exception:
            raise HTTPException(status_code=502, detail="bad LLM JSON")

    return {
        "word": str(result.get("word", "")),
        "translation_uz": str(result.get("translation_uz", "")),
        "example": str(result.get("example", "")),
        "confidence": str(result.get("confidence", "medium")),
        "target": target,
    }
