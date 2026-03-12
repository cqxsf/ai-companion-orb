"""
TTS service — wraps CosyVoice (阿里云) text-to-speech API.

Returns base64-encoded Opus audio bytes.
"""

from __future__ import annotations

import base64
import logging

import httpx

from src.config import settings

logger = logging.getLogger(__name__)


class TTSService:
    def __init__(self) -> None:
        self._client = httpx.AsyncClient(timeout=30.0)

    async def synthesize(self, text: str) -> str:
        """
        Convert *text* to speech via CosyVoice and return base64-encoded audio.

        Falls back to an empty string when the API is unavailable so that the
        conversation pipeline can still deliver a text response.
        """
        if not settings.DASHSCOPE_API_KEY:
            logger.warning("DASHSCOPE_API_KEY not configured — TTS skipped")
            return ""

        payload = {
            "model": "cosyvoice-v1",
            "input": {"text": text},
            "parameters": {
                "voice": "longxiaochun",  # warm, friendly female voice
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
                settings.COSYVOICE_API_URL, json=payload, headers=headers
            )
            resp.raise_for_status()
            data = resp.json()
            audio_bytes: bytes = base64.b64decode(data["output"]["audio"])
            return base64.b64encode(audio_bytes).decode()
        except Exception as exc:
            logger.error("TTS synthesis failed: %s", exc)
            return ""

    async def aclose(self) -> None:
        await self._client.aclose()
