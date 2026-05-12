from functools import lru_cache
from supabase import Client, create_client
from app.core.config import get_settings


@lru_cache
def get_supabase_admin() -> Client | None:
    s = get_settings()
    if not (s.supabase_url and s.supabase_service_key):
        return None
    return create_client(s.supabase_url, s.supabase_service_key)


@lru_cache
def get_supabase_anon() -> Client | None:
    s = get_settings()
    if not (s.supabase_url and s.supabase_anon_key):
        return None
    return create_client(s.supabase_url, s.supabase_anon_key)
