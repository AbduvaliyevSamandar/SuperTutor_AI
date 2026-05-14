"""Pull learner profile + notes for personalized prompts."""
from app.core.db_utils import safe_single
from app.core.supabase import get_supabase_admin


def fetch_personalization(user_id: str | None, subject: str) -> str:
    if not user_id:
        return ""
    client = get_supabase_admin()
    if client is None:
        return ""

    profile = safe_single(
        client.table("profiles")
        .select("display_name, english_level, learning_goal")
        .eq("user_id", user_id)
        .maybe_single()
    ) or {}

    notes_row = safe_single(
        client.table("learner_notes")
        .select("notes")
        .eq("user_id", user_id)
        .eq("subject", subject)
        .maybe_single()
    ) or {}
    notes = notes_row.get("notes") or ""

    bits: list[str] = []
    if profile.get("display_name"):
        bits.append(f"Learner name: {profile['display_name']}.")
    if profile.get("english_level"):
        bits.append(f"Current CEFR level: {profile['english_level']}.")
    if profile.get("learning_goal"):
        bits.append(f"Their goal: {profile['learning_goal']}.")
    if notes.strip():
        bits.append(f"Teacher notes from past sessions: {notes.strip()[:600]}")

    if not bits:
        return ""
    return "\n\nLearner context:\n- " + "\n- ".join(bits)


def update_notes(user_id: str, subject: str, observation: str) -> None:
    client = get_supabase_admin()
    if client is None:
        return
    cur = safe_single(
        client.table("learner_notes")
        .select("notes")
        .eq("user_id", user_id)
        .eq("subject", subject)
        .maybe_single()
    ) or {}
    existing = (cur.get("notes") or "").strip()
    merged = (observation.strip() + "\n" + existing).strip()[:1500]
    try:
        client.table("learner_notes").upsert(
            {"user_id": user_id, "subject": subject, "notes": merged},
            on_conflict="user_id,subject",
        ).execute()
    except Exception:
        pass
