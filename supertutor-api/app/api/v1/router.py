from fastapi import APIRouter
from app.api.v1.endpoints import (
    activity,
    auth,
    chat,
    commute,
    currency,
    daily_lesson,
    dictionary,
    exercises,
    feedback as feedback_mod,
    friends,
    health,
    identify,
    ielts,
    leaderboard,
    listening_test as listening_test_mod,
    mock_test,
    podcast,
    pronunciation,
    quiz,
    reading,
    sessions,
    srs,
    stats,
    stories,
    stt,
    teachback,
    tts,
    vocab_personalized,
    vision,
    word_of_day,
    writing,
)

api_router = APIRouter(prefix="/v1")
api_router.include_router(health.router, tags=["health"])
api_router.include_router(auth.router, tags=["auth"])
api_router.include_router(chat.router, tags=["chat"])
api_router.include_router(vision.router, tags=["chat"])
api_router.include_router(identify.router, tags=["chat"])
api_router.include_router(stt.router, tags=["voice"])
api_router.include_router(tts.router, tags=["voice"])
api_router.include_router(pronunciation.router, tags=["voice"])
api_router.include_router(sessions.router, tags=["sessions"])
api_router.include_router(stats.router, tags=["stats"])
api_router.include_router(activity.router, tags=["stats"])
api_router.include_router(dictionary.router, tags=["dictionary"])
api_router.include_router(word_of_day.router, tags=["dictionary"])
api_router.include_router(quiz.router, tags=["quiz"])
api_router.include_router(currency.router, tags=["currency"])
api_router.include_router(leaderboard.router, tags=["leaderboard"])
api_router.include_router(exercises.router, tags=["exercises"])
api_router.include_router(srs.router, tags=["srs"])
api_router.include_router(ielts.router, tags=["ielts"])
api_router.include_router(writing.router, tags=["ielts"])
api_router.include_router(reading.router, tags=["ielts"])
api_router.include_router(listening_test_mod.router, tags=["ielts"])
api_router.include_router(mock_test.router, tags=["ielts"])
api_router.include_router(stories.router, tags=["stories"])
api_router.include_router(daily_lesson.router, tags=["daily"])
api_router.include_router(friends.router, tags=["social"])
api_router.include_router(podcast.router, tags=["learning"])
api_router.include_router(feedback_mod.router, tags=["feedback"])
api_router.include_router(commute.router, tags=["learning"])
api_router.include_router(teachback.router, tags=["learning"])
api_router.include_router(vocab_personalized.router, tags=["srs"])
