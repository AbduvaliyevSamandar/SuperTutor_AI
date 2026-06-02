"""Per-user/IP rate limiting middleware (no external deps)."""
import base64
import json
import time
from collections import defaultdict, deque

from fastapi import Request
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware

_LLM_PREFIXES = (
    "/api/v1/chat",
    "/api/v1/quiz",
    "/api/v1/ielts",
    "/api/v1/writing",
    "/api/v1/reading",
    "/api/v1/listening",
    "/api/v1/mock-test",
    "/api/v1/vision",
    "/api/v1/identify",
    "/api/v1/stt",
    "/api/v1/stories",
    "/api/v1/teachback",
    "/api/v1/podcast",
    "/api/v1/commute",
    "/api/v1/exercises",
    "/api/v1/dictionary",
    "/api/v1/pronunciation",
    "/api/v1/vocab",
    "/api/v1/daily-lesson",
    "/api/v1/word-of-day",
)


def _request_key(request: Request) -> str:
    auth = request.headers.get("authorization", "")
    if auth.lower().startswith("bearer "):
        token = auth[7:]
        try:
            segment = token.split(".")[1]
            segment += "=" * (-len(segment) % 4)
            data = json.loads(base64.b64decode(segment))
            sub = data.get("sub", "")
            if sub:
                return f"u:{sub}"
        except Exception:
            pass
    host = getattr(request.client, "host", "unknown")
    return f"ip:{host}"


class RateLimitMiddleware(BaseHTTPMiddleware):
    """Sliding-window rate limiter.

    LLM-heavy paths: llm_rpm requests/minute.
    Everything else: default_rpm requests/minute.
    """

    def __init__(self, app, llm_rpm: int = 20, default_rpm: int = 120) -> None:
        super().__init__(app)
        self._llm_rpm = llm_rpm
        self._default_rpm = default_rpm
        self._windows: dict[str, deque] = defaultdict(deque)
        self._last_cleanup = time.monotonic()

    def _cleanup(self) -> None:
        now = time.monotonic()
        if now - self._last_cleanup < 120:
            return
        cutoff = now - 60
        stale = [k for k, q in self._windows.items() if not q or q[-1] < cutoff]
        for k in stale:
            del self._windows[k]
        self._last_cleanup = now

    async def dispatch(self, request: Request, call_next):
        path = request.url.path
        if not path.startswith("/api/v1/") or path in ("/api/v1/health", "/api/v1/auth/login", "/api/v1/auth/signup"):
            return await call_next(request)

        key = _request_key(request)
        is_llm = path.startswith(_LLM_PREFIXES)
        limit = self._llm_rpm if is_llm else self._default_rpm

        now = time.monotonic()
        q = self._windows[key]
        while q and q[0] < now - 60:
            q.popleft()

        if len(q) >= limit:
            return JSONResponse(
                status_code=429,
                content={"detail": f"Rate limit: {limit} req/min. Retry after 60s."},
                headers={"Retry-After": "60"},
            )

        q.append(now)
        self._cleanup()
        return await call_next(request)
