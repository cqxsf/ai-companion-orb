"""
Memory service — stores conversation context in Redis.

Keeps the last N turns (configurable via LLM_CONTEXT_WINDOW) for each device.
"""

from __future__ import annotations

import json
import logging

from redis.asyncio import Redis

from src.config import settings

logger = logging.getLogger(__name__)

_CONTEXT_TTL_SECONDS = 60 * 60 * 24  # 24 hours


class MemoryService:
    def __init__(self, redis: Redis) -> None:
        self._redis = redis

    def _key(self, device_id: str) -> str:
        return f"ctx:{device_id}"

    async def get_context(self, device_id: str) -> list[dict[str, str]]:
        """Return the last LLM_CONTEXT_WINDOW turns for the device."""
        raw = await self._redis.lrange(self._key(device_id), 0, -1)
        turns: list[dict[str, str]] = []
        for item in raw:
            try:
                turns.append(json.loads(item))
            except json.JSONDecodeError:
                logger.warning("Failed to parse context item for device %s", device_id)
        return turns[-settings.LLM_CONTEXT_WINDOW :]

    async def add_turn(self, device_id: str, role: str, content: str) -> None:
        """Append a single turn and refresh the TTL."""
        key = self._key(device_id)
        turn = json.dumps({"role": role, "content": content}, ensure_ascii=False)
        await self._redis.rpush(key, turn)
        await self._redis.expire(key, _CONTEXT_TTL_SECONDS)

        # Trim to 2× context window to avoid unbounded growth
        max_items = settings.LLM_CONTEXT_WINDOW * 2
        await self._redis.ltrim(key, -max_items, -1)

    async def summarize_old_turns(self, device_id: str) -> None:
        """
        Placeholder for LLM-based long-term summarisation.

        A future implementation would:
        1. Retrieve turns older than LLM_CONTEXT_WINDOW.
        2. Ask the LLM to produce a summary paragraph.
        3. Store the summary and prune the old turns.
        """
        logger.info("summarize_old_turns called for device %s (not yet implemented)", device_id)

    async def clear_context(self, device_id: str) -> None:
        """Remove all context for a device (e.g. after session ends)."""
        await self._redis.delete(self._key(device_id))
