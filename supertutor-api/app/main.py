from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.core.rate_limit import RateLimitMiddleware
from app.api.v1.router import api_router


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(title="SuperTutor API", version="0.1.0")

    app.add_middleware(RateLimitMiddleware, llm_rpm=20, default_rpm=120)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origin_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(api_router, prefix="/api")

    @app.get("/")
    def root() -> dict:
        return {"name": "SuperTutor API", "docs": "/docs"}

    return app


app = create_app()
