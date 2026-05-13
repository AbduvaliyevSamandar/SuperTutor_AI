from fastapi import APIRouter
from app.api.v1.endpoints import (
    auth,
    chat,
    currency,
    dictionary,
    health,
    quiz,
    sessions,
    stats,
    stt,
    tts,
    vision,
)

api_router = APIRouter(prefix="/v1")
api_router.include_router(health.router, tags=["health"])
api_router.include_router(auth.router, tags=["auth"])
api_router.include_router(chat.router, tags=["chat"])
api_router.include_router(vision.router, tags=["chat"])
api_router.include_router(stt.router, tags=["voice"])
api_router.include_router(tts.router, tags=["voice"])
api_router.include_router(sessions.router, tags=["sessions"])
api_router.include_router(stats.router, tags=["stats"])
api_router.include_router(dictionary.router, tags=["dictionary"])
api_router.include_router(quiz.router, tags=["quiz"])
api_router.include_router(currency.router, tags=["currency"])
