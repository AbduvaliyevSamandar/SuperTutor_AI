"""Today's daily-lesson plan: SRS words + chat seed + quiz."""
from datetime import date, datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.core.security import require_user_id
from app.core.supabase import get_supabase_admin

router = APIRouter()


_SEEDS = {
    "english": "Hi! Let's talk about your day. What did you do today?",
    "russian": "Привет! Давай поговорим о твоём дне.",
    "german": "Hallo! Wie war dein Tag heute?",
    "turkish": "Merhaba! Bugün nasıl geçti?",
    "math": "Bugun matematika mashqlarini boshlaymiz.",
}


class DailyWord(BaseModel):
    id: str
    word: str
    translation_uz: str
    language: str


class DailyLesson(BaseModel):
    subject: str
    chat_seed: str
    quiz_subject: str
    srs_words: list[DailyWord]
    chat_done: bool = False
    quiz_done: bool = False
    srs_done: bool = False
    target_xp: int = 25


class CompleteRequest(BaseModel):
    part: str  # "chat" | "quiz" | "srs"


def _db():
    client = get_supabase_admin()
    if client is None:
        raise HTTPException(status_code=503, detail="DB not configured")
    return client


@router.get("/daily-lesson/today", response_model=DailyLesson)
def today(user_id: str = Depends(require_user_id)) -> DailyLesson:
    client = _db()

    # Pick subject from profile.learning_goal/english_level if set, else english
    from app.core.db_utils import safe_single
    prof = safe_single(
        client.table("profiles")
        .select("learning_goal, english_level")
        .eq("user_id", user_id)
        .maybe_single()
    ) or {}
    subject = "english"
    goal = (prof.get("learning_goal") or "").lower()
    if "matematika" in goal or "math" in goal:
        subject = "math"

    # Get up to 5 due SRS words
    now = datetime.now(timezone.utc).isoformat()
    srs = (
        client.table("vocabulary_entries")
        .select("id, word, translation_uz, language")
        .eq("user_id", user_id)
        .lte("due_at", now)
        .order("due_at")
        .limit(5)
        .execute()
    )
    words = [
        DailyWord(
            id=r["id"],
            word=r["word"],
            translation_uz=r.get("translation_uz") or "",
            language=r["language"],
        )
        for r in (srs.data or [])
    ]

    # Today's progress
    today_str = date.today().isoformat()
    p = safe_single(
        client.table("daily_lesson_progress")
        .select("chat_done, quiz_done, srs_done")
        .eq("user_id", user_id)
        .eq("date", today_str)
        .maybe_single()
    ) or {}

    return DailyLesson(
        subject=subject,
        chat_seed=_SEEDS.get(subject, _SEEDS["english"]),
        quiz_subject=subject,
        srs_words=words,
        chat_done=bool(p.get("chat_done")),
        quiz_done=bool(p.get("quiz_done")),
        srs_done=bool(p.get("srs_done")),
        target_xp=25,
    )


@router.post("/daily-lesson/complete")
def complete(
    req: CompleteRequest,
    user_id: str = Depends(require_user_id),
) -> dict:
    if req.part not in ("chat", "quiz", "srs"):
        raise HTTPException(status_code=400, detail="invalid part")

    client = _db()
    today_str = date.today().isoformat()
    update = {f"{req.part}_done": True}
    client.table("daily_lesson_progress").upsert(
        {"user_id": user_id, "date": today_str, **update},
        on_conflict="user_id,date",
    ).execute()
    return {"ok": True}
