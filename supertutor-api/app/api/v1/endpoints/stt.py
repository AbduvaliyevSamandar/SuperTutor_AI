from fastapi import APIRouter, File, Form, HTTPException, UploadFile
from app.services.groq_client import transcribe

router = APIRouter()


@router.post("/stt")
async def speech_to_text(
    file: UploadFile = File(...),
    language: str | None = Form(default=None),
) -> dict:
    audio_bytes = await file.read()
    if not audio_bytes:
        raise HTTPException(status_code=400, detail="Empty audio file")
    try:
        text = transcribe(audio_bytes, filename=file.filename or "audio.webm", language=language)
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"STT error: {e}") from e
    return {"text": text}
