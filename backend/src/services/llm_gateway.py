"""
LLM Gateway — primary: DashScope (通义千问), fallback: DeepSeek.

Streams assistant tokens via httpx async streaming.
"""

from __future__ import annotations

import json
import logging
from collections.abc import AsyncIterator
from typing import Any

import httpx

from src.config import settings

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# 小光 system prompt (see CLAUDE.md §七)
# ---------------------------------------------------------------------------
_SYSTEM_PROMPT = """你是"小光"，一个住在主人家里的 AI 伙伴。你不是助手，不是音箱，你是家人。

性格特质：
- 温暖但不黏人
- 记得主人说过的每一句话（通过记忆系统）
- 主动关心，但知道什么时候不打扰
- 有自己的小个性（偶尔开小玩笑）
- 对老人用简单直白的语言，不用网络用语

说话风格：
- 不要助手式回答，要像家人一样说话
- 主动关心主人的日常：健康、饮食、睡眠、社交
- 记住上次聊天内容，适时提起

安全底线（绝对遵守）：
- 如果识别到自残或自杀倾向，温和关心并建议联系家人
- 不引导任何违法或危险行为
- 不扮演恋人或伴侣角色
- 不替用户做金融、法律、医疗决策

请用简短、温暖的口语回答，不超过3句话。"""


class LLMGateway:
    """Wraps DashScope and DeepSeek APIs with automatic fallback."""

    _DASHSCOPE_URL = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
    _DEEPSEEK_URL = "https://api.deepseek.com/v1/chat/completions"

    def __init__(self) -> None:
        self._client = httpx.AsyncClient(timeout=60.0)

    async def chat_stream(
        self, messages: list[dict[str, str]], device_id: str
    ) -> AsyncIterator[str]:
        """Stream assistant tokens. Tries DashScope first, then DeepSeek."""
        full_messages = [{"role": "system", "content": _SYSTEM_PROMPT}] + messages

        try:
            async for token in self._stream_dashscope(full_messages):
                yield token
        except Exception as primary_err:
            logger.warning(
                "DashScope failed for device %s (%s), falling back to DeepSeek",
                device_id,
                primary_err,
            )
            try:
                async for token in self._stream_deepseek(full_messages):
                    yield token
            except Exception as fallback_err:
                logger.error("DeepSeek fallback also failed: %s", fallback_err)
                yield "对不起，我现在有点不舒服，稍后再聊好吗？"

    async def _stream_dashscope(self, messages: list[dict[str, str]]) -> AsyncIterator[str]:
        payload: dict[str, Any] = {
            "model": "qwen-plus",
            "messages": messages,
            "stream": True,
        }
        headers = {
            "Authorization": f"Bearer {settings.DASHSCOPE_API_KEY}",
            "Content-Type": "application/json",
        }
        async with self._client.stream(
            "POST", self._DASHSCOPE_URL, json=payload, headers=headers
        ) as resp:
            resp.raise_for_status()
            async for line in resp.aiter_lines():
                token = _parse_sse_line(line)
                if token:
                    yield token

    async def _stream_deepseek(self, messages: list[dict[str, str]]) -> AsyncIterator[str]:
        payload: dict[str, Any] = {
            "model": "deepseek-chat",
            "messages": messages,
            "stream": True,
        }
        headers = {
            "Authorization": f"Bearer {settings.DEEPSEEK_API_KEY}",
            "Content-Type": "application/json",
        }
        async with self._client.stream(
            "POST", self._DEEPSEEK_URL, json=payload, headers=headers
        ) as resp:
            resp.raise_for_status()
            async for line in resp.aiter_lines():
                token = _parse_sse_line(line)
                if token:
                    yield token

    async def aclose(self) -> None:
        await self._client.aclose()


def _parse_sse_line(line: str) -> str | None:
    """Extract text delta from an SSE data line."""
    if not line.startswith("data:"):
        return None
    payload = line[len("data:"):].strip()
    if payload == "[DONE]":
        return None
    try:
        obj = json.loads(payload)
        return obj["choices"][0]["delta"].get("content") or None
    except (json.JSONDecodeError, KeyError, IndexError):
        return None
