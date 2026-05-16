"""Tests for FSRS-5 scheduler."""
from datetime import datetime, timedelta, timezone

from app.services.fsrs import FsrsState, review


def test_new_card_good_yields_positive_interval():
    state = FsrsState.new()
    new_state, interval, due = review(state, 3, None)
    assert new_state.stability is not None and new_state.stability > 0
    assert interval >= 1
    assert due > datetime.now(timezone.utc)


def test_new_card_again_short_lapse():
    state = FsrsState.new()
    new_state, interval, due = review(state, 1, None)
    # "Again" on new card: 10-minute relapse window
    assert interval == 0
    assert (due - datetime.now(timezone.utc)).total_seconds() < 700


def test_easy_extends_more_than_good():
    base = FsrsState.new()
    _, easy_int, _ = review(base, 4, None)
    _, good_int, _ = review(base, 3, None)
    assert easy_int >= good_int


def test_hard_shorter_than_good_on_review():
    # First, get a card into the review phase.
    initial = FsrsState.new()
    after_good, _, due_good = review(initial, 3, None)
    last_reviewed = datetime.now(timezone.utc)

    # Simulate 1 day passing
    later = last_reviewed + timedelta(days=after_good.stability or 1)

    _, hard_int, _ = review(after_good, 2, last_reviewed, now=later)
    _, good_int, _ = review(after_good, 3, last_reviewed, now=later)
    assert hard_int <= good_int


def test_again_resets_difficulty_upward():
    state = FsrsState(stability=10.0, difficulty=5.0, reps=3)
    last_reviewed = datetime.now(timezone.utc) - timedelta(days=5)
    new_state, _, _ = review(state, 1, last_reviewed)
    # Difficulty should not decrease on "Again"
    assert new_state.difficulty >= state.difficulty - 0.01


def test_difficulty_clamped_to_1_10():
    state = FsrsState.new()
    for _ in range(40):
        state, _, _ = review(state, 4, None)
        assert 1.0 <= state.difficulty <= 10.0
        assert state.stability is not None
