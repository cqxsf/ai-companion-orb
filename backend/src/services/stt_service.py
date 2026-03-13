"""
STT service — wraps Paraformer (阿里云) speech-to-text API.

Accepts base64-encoded Opus audio bytes and returns a transcribed string.
"""

from __future__ import annotations

import base64
import logging

import httpx

from src.config import settings

logger = logging.getLogger(__name__)


class STTService:
    def __init__(self) -> None:
        self._client = httpx.AsyncClient(timeout=30.0)

    async def transcribe(self, audio_b64: str) -> str:
        """
        Transcribe base64-encoded Opus *audio_b64* to text.

        Returns an empty string when the API is unavailable.
        """
        if not settings.DASHSCOPE_API_KEY:
            logger.warning("DASHSCOPE_API_KEY not configured — STT skipped")
            return ""

        payload = {
            "model": "paraformer-realtime-v1",
            "input": {
                "audio": audio_b64,
                "format": "opus",
                "sample_rate": 16000,
            },
        }
        headers = {
            "Authorization": f"Bearer {settings.DASHSCOPE_API_KEY}",
            "Content-Type": "application/json",
        }
        try:
            resp = await self._client.post(
                settings.PARAFORMER_API_URL, json=payload, headers=headers
            )
            resp.raise_for_status()
            data = resp.json()
            return data.get("output", {}).get("text", "")
        except Exception as exc:
            logger.error("STT transcription failed: %s", exc)
            return ""

    async def aclose(self) -> None:
        await self._client.aclose()
