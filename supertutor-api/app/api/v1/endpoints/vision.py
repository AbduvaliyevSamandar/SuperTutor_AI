from fastapi import APIRouter, File, Form, HTTPException, UploadFile

from app.services.llm.orchestrator import (
    AllProvidersFailed,
    analyze_image_with_fallback,
)
from app.services.prompts import vision_review_prompt_for

router = APIRouter()

ALLOWED_MIME = {
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
    "image/heic",
}
MAX_BYTES = 8 * 1024 * 1024  # 8 MB


@router.post("/chat-vision")
async def chat_vision(
    file: UploadFile = File(...),
    subject: str = Form(default="math"),
    prompt: str = Form(
        default="Bu rasmda nima ko'rinmoqda? Har bir masala uchun to'g'ri yechim ber.",
    ),
) -> dict:
    mime = file.content_type or "image/jpeg"
    if mime not in ALLOWED_MIME:
        raise HTTPException(
            status_code=415, detail=f"Unsupported image type: {mime}"
        )
    data = await file.read()
    if not data:
        raise HTTPException(status_code=400, detail="Empty image")
    if len(data) > MAX_BYTES:
        raise HTTPException(
            status_code=413, detail=f"Image too large (>{MAX_BYTES} bytes)"
        )

    system = vision_review_prompt_for(subject)
    try:
        text, provider = analyze_image_with_fallback(
            prompt=prompt, image=data, mime=mime, system=system
        )
    except AllProvidersFailed as e:
        raise HTTPException(status_code=503, detail=str(e)) from e

    return {"reply": text, "provider": provider}
