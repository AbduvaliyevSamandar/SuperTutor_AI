from fastapi import APIRouter, File, Form, HTTPException, UploadFile
from app.services.llm.orchestrator import (
    AllProvidersFailed,
    transcribe_with_fallback,
)

router = APIRouter()


@router.post("/stt")
async def speech_to_text(
    file: UploadFile = File(...),
    language: str | None = Form(default=None),
) -> dict:
    audio = await file.read()
    if not audio:
        raise HTTPException(status_code=400, detail="Empty audio file")
    try:
        text, provider = transcribe_with_fallback(
            audio, filename=file.filename or "audio.webm", language=language
        )
    except AllProvidersFailed as e:
        raise HTTPException(status_code=503, detail=str(e)) from e
    return {"text": text, "provider": provider}
