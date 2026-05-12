from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_env: str = "development"
    app_port: int = 8000
    cors_origins: str = "*"

    # LLM providers (cascade order: groq -> openai -> gemini)
    groq_api_key: str = ""
    groq_llm_model: str = "llama-3.3-70b-versatile"
    groq_stt_model: str = "whisper-large-v3"

    openai_api_key: str = ""
    openai_llm_model: str = "gpt-4o-mini"
    openai_stt_model: str = "whisper-1"

    gemini_api_key: str = ""
    gemini_model: str = "gemini-2.0-flash"

    supabase_url: str = ""
    supabase_anon_key: str = ""
    supabase_service_key: str = ""

    @property
    def cors_origin_list(self) -> list[str]:
        if self.cors_origins.strip() == "*":
            return ["*"]
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
