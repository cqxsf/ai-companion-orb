"""
Redis-based sliding-window rate limiter.

Default limit: 60 requests per minute per device_id (configurable via
RATE_LIMIT_PER_MINUTE in settings).
"""

from __future__ import annotations

import time

from fastapi import HTTPException, status
from redis.asyncio import Redis

from src.config import settings

_WINDOW_SECONDS = 60


class RateLimiter:
    """
    Sliding-window rate limiter backed by Redis sorted sets.

    Usage::

        limiter = RateLimiter()
        await limiter.check(redis, key="device:abc123")
    """

    def __init__(self, limit: int = settings.RATE_LIMIT_PER_MINUTE) -> None:
        self.limit = limit

    async def check(self, redis: Redis, key: str) -> None:
        """
        Raise HTTP 429 if *key* has exceeded the rate limit.

        Uses a sorted set where each member is a unique timestamp token and the
        score is the Unix timestamp, allowing stale entries to be purged.
        """
        now = time.time()
        window_start = now - _WINDOW_SECONDS
        redis_key = f"rl:{key}"

        # Remove entries older than the sliding window
        await redis.zremrangebyscore(redis_key, "-inf", window_start)

        current_count = await redis.zcard(redis_key)
        if current_count >= self.limit:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Rate limit exceeded",
                headers={"Retry-After": str(_WINDOW_SECONDS)},
            )

        # Record this request
        await redis.zadd(redis_key, {f"{now}": now})
        await redis.expire(redis_key, _WINDOW_SECONDS * 2)
