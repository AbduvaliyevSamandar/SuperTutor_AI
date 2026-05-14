"""Helpers that absorb common Supabase quirks (e.g. maybe_single throwing 406)."""
from typing import Any


def safe_single(query) -> dict | None:
    """Execute a `.maybe_single()` PostgREST query and ALWAYS return dict|None.

    Older/newer supabase-py versions sometimes raise an APIError when zero rows
    are returned even though we asked for `maybe_single`. This wrapper swallows
    that case and returns None, so endpoint code can stay simple.
    """
    try:
        r = query.execute()
    except Exception:
        return None
    data = getattr(r, "data", None)
    if data is None:
        return None
    if isinstance(data, list):
        return data[0] if data else None
    if isinstance(data, dict):
        return data
    return None


def safe_list(query) -> list[Any]:
    try:
        r = query.execute()
    except Exception:
        return []
    return list(getattr(r, "data", None) or [])
