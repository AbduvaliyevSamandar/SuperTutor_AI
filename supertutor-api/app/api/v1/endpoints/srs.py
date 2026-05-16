"""Spaced repetition for vocabulary — FSRS-5 algorithm.

Backward compatible with the previous SM-2 schema:
- ease_factor column now stores FSRS stability (float days)
- repetitions column stores reps counter
- A new optional difficulty column is read when present; defaults to 5.0.
"""
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.core.db_utils import safe_single
from app.core.security import require_user_id
from app.core.supabase import get_supabase_admin
from app.services.fsrs import FsrsState, review as fsrs_review

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
    rating: int = Field(ge=1, le=4)  # 1=Again, 2=Hard, 3=Good, 4=Easy


class ReviewResponse(BaseModel):
    word_id: str
    next_due_in_days: int
    next_due_at: str
    stability: float
    difficulty: float


def _db():
    client = get_supabase_admin()
    if client is None:
        raise HTTPException(status_code=503, detail="DB not configured")
    return client


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
    cur = safe_single(
        client.table("vocabulary_entries")
        .select("ease_factor, interval_days, repetitions, difficulty, last_reviewed_at")
        .eq("id", req.word_id)
        .eq("user_id", user_id)
        .maybe_single()
    )
    if not cur:
        raise HTTPException(status_code=404, detail="Word not found")

    # Map legacy SM-2 row -> FSRS state
    # ease_factor is repurposed as stability (days).
    stability_raw = cur.get("ease_factor")
    stability = float(stability_raw) if stability_raw is not None else None
    if stability is not None and stability < 0.5:
        # Likely a legacy SM-2 ease (1.3..3.0). Treat as new card.
        stability = None

    last_iso = cur.get("last_reviewed_at")
    last_reviewed_at = None
    if last_iso:
        try:
            last_reviewed_at = datetime.fromisoformat(
                last_iso.replace("Z", "+00:00")
            )
        except Exception:
            last_reviewed_at = None

    state = FsrsState(
        stability=stability,
        difficulty=float(cur.get("difficulty") or 5.0),
        reps=int(cur.get("repetitions") or 0),
    )

    now = datetime.now(timezone.utc)
    new_state, interval, due = fsrs_review(
        state, req.rating, last_reviewed_at, now=now
    )

    update: dict = {
        "ease_factor": new_state.stability,
        "interval_days": interval,
        "repetitions": new_state.reps,
        "last_reviewed_at": now.isoformat(),
        "due_at": due.isoformat(),
    }
    # Write difficulty only if the column exists; absorb errors silently.
    try:
        client.table("vocabulary_entries").update(
            {**update, "difficulty": new_state.difficulty}
        ).eq("id", req.word_id).eq("user_id", user_id).execute()
    except Exception:
        client.table("vocabulary_entries").update(update).eq(
            "id", req.word_id
        ).eq("user_id", user_id).execute()

    return ReviewResponse(
        word_id=req.word_id,
        next_due_in_days=max(0, (due - now).days),
        next_due_at=due.isoformat(),
        stability=new_state.stability or 0.0,
        difficulty=new_state.difficulty,
    )
