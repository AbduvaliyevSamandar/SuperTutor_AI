from fastapi import APIRouter
from app.api.v1.endpoints import health, chat, stt, tts

api_router = APIRouter(prefix="/v1")
api_router.include_router(health.router, tags=["health"])
api_router.include_router(chat.router, tags=["chat"])
api_router.include_router(stt.router, tags=["voice"])
api_router.include_router(tts.router, tags=["voice"])
