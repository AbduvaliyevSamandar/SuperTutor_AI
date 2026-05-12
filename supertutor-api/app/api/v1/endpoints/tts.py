from fastapi import APIRouter, HTTPException
from fastapi.responses import Response
from app.schemas.chat import TTSRequest
from app.services.tts_service import synthesize

router = APIRouter()


@router.post("/tts")
async def text_to_speech(req: TTSRequest):
    if not req.text.strip():
        raise HTTPException(status_code=400, detail="Text is empty")
    try:
        audio = await synthesize(req.text, language=req.language, voice=req.voice)
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"TTS error: {e}") from e
    return Response(content=audio, media_type="audio/mpeg")
