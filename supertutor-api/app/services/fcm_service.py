"""Firebase Cloud Messaging — send push notifications to devices."""
import json
import logging
from functools import lru_cache

logger = logging.getLogger(__name__)


@lru_cache(maxsize=1)
def _firebase_app():
    try:
        import firebase_admin
        from firebase_admin import credentials
        from app.core.config import get_settings

        s = get_settings()
        if not s.firebase_service_account_json:
            return None
        cred_dict = json.loads(s.firebase_service_account_json)
        cred = credentials.Certificate(cred_dict)
        try:
            return firebase_admin.get_app()
        except ValueError:
            return firebase_admin.initialize_app(cred)
    except Exception as e:
        logger.warning("Firebase init failed: %s", e)
        return None


def send_notification(token: str, title: str, body: str, data: dict | None = None) -> bool:
    try:
        app = _firebase_app()
        if app is None:
            return False
        from firebase_admin import messaging

        msg = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data={str(k): str(v) for k, v in (data or {}).items()},
            token=token,
        )
        messaging.send(msg)
        return True
    except Exception as e:
        logger.warning("FCM send failed: %s", e)
        return False


def send_multicast(tokens: list[str], title: str, body: str, data: dict | None = None) -> int:
    if not tokens:
        return 0
    try:
        app = _firebase_app()
        if app is None:
            return 0
        from firebase_admin import messaging

        msg = messaging.MulticastMessage(
            notification=messaging.Notification(title=title, body=body),
            data={str(k): str(v) for k, v in (data or {}).items()},
            tokens=tokens[:500],
        )
        r = messaging.send_each_for_multicast(msg)
        return r.success_count
    except Exception as e:
        logger.warning("FCM multicast failed: %s", e)
        return 0
