"""App version + force-update support."""
from fastapi import APIRouter

router = APIRouter()

# Bumped whenever a non-backwards-compatible change ships.
# Clients below `min_supported` must show a hard upgrade prompt.
APP_VERSION = {
    "min_supported": "1.0.0",
    "latest": "1.1.0",
    "latest_changelog": (
        "🎉 Yangi: streaming chat, suhbat tarixi, AI ovoz tanlash, "
        "yutuqlar, kunlik maqsad nishonasi."
    ),
    "play_store_url": (
        "https://play.google.com/store/apps/details?id=com.supertutor.supertutor_app"
    ),
}


@router.get("/version")
def version() -> dict:
    return APP_VERSION
