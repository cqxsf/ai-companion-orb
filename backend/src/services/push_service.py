"""
Push notification service — wraps JPush (极光推送) REST API.

Used to alert family members when a safety signal is detected.
"""

from __future__ import annotations

import base64
import logging

import httpx

from src.config import settings

logger = logging.getLogger(__name__)

_JPUSH_API_URL = "https://api.jpush.cn/v3/push"


class PushService:
    def __init__(self) -> None:
        self._client = httpx.AsyncClient(timeout=15.0)

    def _auth_header(self) -> str:
        credentials = f"{settings.JPUSH_APP_KEY}:{settings.JPUSH_MASTER_SECRET}"
        encoded = base64.b64encode(credentials.encode()).decode()
        return f"Basic {encoded}"

    async def send_to_users(
        self,
        registration_ids: list[str],
        title: str,
        body: str,
        extras: dict | None = None,
    ) -> bool:
        """
        Send a push notification to specific JPush registration IDs.

        Returns True on success, False on failure.
        """
        if not settings.JPUSH_APP_KEY or not settings.JPUSH_MASTER_SECRET:
            logger.warning("JPush credentials not configured — push skipped")
            return False

        payload: dict = {
            "platform": "all",
            "audience": {"registration_id": registration_ids},
            "notification": {
                "android": {"alert": body, "title": title, "extras": extras or {}},
                "ios": {
                    "alert": {"title": title, "body": body},
                    "extras": extras or {},
                    "sound": "default",
                },
            },
            "options": {"apns_production": True},
        }
        try:
            resp = await self._client.post(
                _JPUSH_API_URL,
                json=payload,
                headers={
                    "Authorization": self._auth_header(),
                    "Content-Type": "application/json",
                },
            )
            resp.raise_for_status()
            logger.info("Push sent to %d recipients", len(registration_ids))
            return True
        except Exception as exc:
            logger.error("Push notification failed: %s", exc)
            return False

    async def send_safety_alert(self, device_id: str, family_registration_ids: list[str]) -> None:
        """Convenience method for safety (🔴) alerts to family members."""
        await self.send_to_users(
            registration_ids=family_registration_ids,
            title="⚠️ 小光紧急提醒",
            body="您关爱的家人可能需要您的关注，请尽快联系。",
            extras={"device_id": device_id, "alert_type": "safety"},
        )

    async def aclose(self) -> None:
        await self._client.aclose()
