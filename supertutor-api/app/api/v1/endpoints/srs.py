"""Spaced repetition for vocabulary — SM-2 algorithm."""
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.core.security import require_user_id
from app.core.supabase import get_supabase_admin

router = APIRouter()


class DueWord(BaseModel):
    id: str
    word: str
    language: str
    translation_uz: str
    definition: str
    due_at: str | None = None


class ReviewRequest(BaseModel):
    word_id: str
    # SM-2 quality: 1 = Again, 2 = Hard, 3 = Good, 4 = Easy
    rating: int = Field(ge=1, le=4)


class ReviewResponse(BaseModel):
    word_id: str
    next_due_in_days: int
    next_due_at: str


def _db():
    client = get_supabase_admin()
    if client is None:
        raise HTTPException(status_code=503, detail="DB not configured")
    return client


def _sm2_update(ease: float, interval: int, reps: int, rating: int) -> tuple[float, int, int]:
    """Modified SM-2: rating 1=Again, 2=Hard, 3=Good, 4=Easy."""
    if rating == 1:
        reps = 0
        interval = 0
        ease = max(1.3, ease - 0.2)
    else:
        reps += 1
        if rating == 2:
            ease = max(1.3, ease - 0.15)
            interval = max(1, int(interval * 1.2)) if reps > 1 else 1
        elif rating == 3:
            interval = 1 if reps == 1 else (6 if reps == 2 else int(interval * ease))
        else:  # 4 = Easy
            ease = ease + 0.10
            interval = 4 if reps == 1 else (10 if reps == 2 else int(interval * ease * 1.3))
    return ease, max(0, interval), reps


@router.get("/srs/due", response_model=list[DueWord])
def due_words(user_id: str = Depends(require_user_id)) -> list[DueWord]:
    client = _db()
    now = datetime.now(timezone.utc).isoformat()
    r = (
        client.table("vocabulary_entries")
        .select("id, word, language, translation_uz, definition, due_at")
        .eq("user_id", user_id)
        .lte("due_at", now)
        .order("due_at")
        .limit(50)
        .execute()
    )
    return [
        DueWord(
            id=row["id"],
            word=row["word"],
            language=row["language"],
            translation_uz=row.get("translation_uz") or "",
            definition=row.get("definition") or "",
            due_at=row.get("due_at"),
        )
        for row in (r.data or [])
    ]


@router.post("/srs/review", response_model=ReviewResponse)
def review(
    req: ReviewRequest,
    user_id: str = Depends(require_user_id),
) -> ReviewResponse:
    client = _db()
    from app.core.db_utils import safe_single
    cur = safe_single(
        client.table("vocabulary_entries")
        .select("ease_factor, interval_days, repetitions")
        .eq("id", req.word_id)
        .eq("user_id", user_id)
        .maybe_single()
    )
    if not cur:
        raise HTTPException(status_code=404, detail="Word not found")
    ease = float(cur.get("ease_factor") or 2.5)
    interval = int(cur.get("interval_days") or 0)
    reps = int(cur.get("repetitions") or 0)
    ease, interval, reps = _sm2_update(ease, interval, reps, req.rating)

    now = datetime.now(timezone.utc)
    due = now + timedelta(days=max(1, interval) if req.rating > 1 else 0)
    if req.rating == 1:
        due = now + timedelta(minutes=10)

    client.table("vocabulary_entries").update({
        "ease_factor": ease,
        "interval_days": interval,
        "repetitions": reps,
        "last_reviewed_at": now.isoformat(),
        "due_at": due.isoformat(),
    }).eq("id", req.word_id).eq("user_id", user_id).execute()

    return ReviewResponse(
        word_id=req.word_id,
        next_due_in_days=max(0, (due - now).days),
        next_due_at=due.isoformat(),
    )
