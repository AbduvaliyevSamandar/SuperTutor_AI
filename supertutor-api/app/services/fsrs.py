"""FSRS-5 spaced repetition scheduler (self-contained, no ML training).

Reference: https://github.com/open-spaced-repetition/fsrs4anki
Default weights from FSRS-5 (anonymized average user).

Rating: 1=Again, 2=Hard, 3=Good, 4=Easy.
"""
from __future__ import annotations

import math
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

# FSRS-5 default weights
W = [
    0.40255, 1.18385, 3.173, 15.69105,
    7.1949, 0.5345, 1.4604, 0.0046,
    1.54575, 0.1192, 1.01925, 1.9395,
    0.11, 0.29605, 2.2698, 0.2315,
    2.9898, 0.51655, 0.6621,
]

DECAY = -0.5
FACTOR = 19.0 / 81.0
MIN_STABILITY = 0.1
MAX_STABILITY = 36500.0  # 100 years cap
DESIRED_RETENTION = 0.9


@dataclass
class FsrsState:
    stability: float | None  # None => new card
    difficulty: float        # 1.0 .. 10.0
    reps: int                # informational only

    @classmethod
    def new(cls) -> "FsrsState":
        return cls(stability=None, difficulty=5.0, reps=0)


def _clamp_d(d: float) -> float:
    return max(1.0, min(10.0, d))


def _init_stability(rating: int) -> float:
    return max(W[rating - 1], MIN_STABILITY)


def _init_difficulty(rating: int) -> float:
    return _clamp_d(W[4] - math.exp(W[5] * (rating - 1)) + 1.0)


def _retrievability(elapsed_days: float, stability: float) -> float:
    if stability <= 0:
        return 0.0
    return (1.0 + FACTOR * elapsed_days / stability) ** DECAY


def _next_difficulty(d: float, rating: int) -> float:
    delta = -W[6] * (rating - 3)
    d_prime = d + delta
    # Mean reversion toward initial-good difficulty
    d_target = _init_difficulty(4)
    new_d = W[7] * d_target + (1.0 - W[7]) * d_prime
    return _clamp_d(new_d)


def _next_stability_recall(s: float, d: float, r: float, rating: int) -> float:
    hard_penalty = W[15] if rating == 2 else 1.0
    easy_bonus = W[16] if rating == 4 else 1.0
    new_s = s * (
        1.0
        + math.exp(W[8])
        * (11.0 - d)
        * (s ** -W[9])
        * (math.exp(W[10] * (1.0 - r)) - 1.0)
        * hard_penalty
        * easy_bonus
    )
    return max(MIN_STABILITY, min(MAX_STABILITY, new_s))


def _next_stability_forget(s: float, d: float, r: float) -> float:
    new_s = (
        W[11]
        * (d ** -W[12])
        * (((s + 1.0) ** W[13]) - 1.0)
        * math.exp(W[14] * (1.0 - r))
    )
    return max(MIN_STABILITY, min(MAX_STABILITY, new_s))


def _interval_from_stability(stability: float) -> int:
    """Days until retention drops to DESIRED_RETENTION."""
    # R = (1 + FACTOR * t/S)^DECAY = DESIRED_RETENTION
    # t = S/FACTOR * (DESIRED_RETENTION^(1/DECAY) - 1)
    t = stability / FACTOR * (DESIRED_RETENTION ** (1.0 / DECAY) - 1.0)
    return max(1, int(round(t)))


def review(
    state: FsrsState,
    rating: int,
    last_reviewed_at: datetime | None,
    now: datetime | None = None,
) -> tuple[FsrsState, int, datetime]:
    """Apply one review. Returns (new_state, next_interval_days, due_at)."""
    if rating not in (1, 2, 3, 4):
        raise ValueError(f"rating must be 1..4, got {rating}")
    now = now or datetime.now(timezone.utc)

    # New card
    if state.stability is None or last_reviewed_at is None:
        s = _init_stability(rating)
        d = _init_difficulty(rating)
        new_state = FsrsState(stability=s, difficulty=d, reps=state.reps + 1)
        # Fresh cards: short ramp before long intervals
        if rating == 1:
            due = now + timedelta(minutes=10)
            return new_state, 0, due
        interval = _interval_from_stability(s)
        return new_state, interval, now + timedelta(days=interval)

    elapsed = max(0.0, (now - last_reviewed_at).total_seconds() / 86400.0)
    r = _retrievability(elapsed, state.stability)
    d_new = _next_difficulty(state.difficulty, rating)

    if rating == 1:
        s_new = _next_stability_forget(state.stability, state.difficulty, r)
        new_state = FsrsState(stability=s_new, difficulty=d_new, reps=0)
        due = now + timedelta(minutes=10)
        return new_state, 0, due

    s_new = _next_stability_recall(state.stability, state.difficulty, r, rating)
    new_state = FsrsState(stability=s_new, difficulty=d_new, reps=state.reps + 1)
    interval = _interval_from_stability(s_new)
    return new_state, interval, now + timedelta(days=interval)
