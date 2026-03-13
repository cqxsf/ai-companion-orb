"""
Conversation WebSocket endpoint.

WS /api/v1/conversation/stream

Pipeline per audio chunk:
  1. Receive {"type": "audio_chunk", "data": "<b64_opus>", "seq": N}
  2. STT  → transcript text
  3. Safety check on user input
  4. LLM  (streaming) → assistant text
  5. Safety check on LLM output → if unsafe, override text + trigger push
  6. TTS  → base64 Opus audio
  7. Send {"type": "ai_response", "text": "...", "audio": "...", "mood": "..."}
  8. Send {"type": "mood_update", "mood": "...", "transition_ms": 500}
"""

from __future__ import annotations

import json
import logging
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from sqlalchemy.ext.asyncio import AsyncSession

from src.database import AsyncSessionLocal, get_redis
from src.middleware.rate_limiter import RateLimiter
from src.models.alert import Alert
from src.models.conversation import ConversationSession, Message
from src.services.llm_gateway import LLMGateway
from src.services.memory_service import MemoryService
from src.services.push_service import PushService
from src.services.safety_classifier import SafetyClassifier
from src.services.stt_service import STTService
from src.services.tts_service import TTSService
from src.utils.encryption import decrypt_text, encrypt_text

router = APIRouter(prefix="/conversation", tags=["conversation"])

logger = logging.getLogger(__name__)

_rate_limiter = RateLimiter()
_stt = STTService()
_tts = TTSService()
_llm = LLMGateway()
_safety = SafetyClassifier()
_push = PushService()

# Maps mood keywords to Orb mood names (CLAUDE.md §四)
_MOOD_MAP: dict[str, str] = {
    "happy": "happy",
    "sad": "concerned",
    "calm": "calm",
    "thinking": "thinking",
    "alert": "alert",
    "ok": "ok",
}
_SAFE_RESPONSE = "没关系的，我在这里陪着你。如果你感到难受，记得要联系家人或者拨打心理援助热线。"


@router.websocket("/stream")
async def conversation_stream(websocket: WebSocket) -> None:
    """
    WebSocket endpoint for real-time voice conversation with the Orb device.

    Query parameter: device_id (required)
    """
    device_id: str = websocket.query_params.get("device_id", "unknown")
    await websocket.accept()
    logger.info("WebSocket connected: device_id=%s", device_id)

    # Acquire Redis for rate limiting and memory
    redis_gen = get_redis()
    redis = await redis_gen.__anext__()
    memory = MemoryService(redis)

    # Start a new conversation session
    async with AsyncSessionLocal() as db:
        session = ConversationSession(device_id=device_id)
        db.add(session)
        await db.commit()
        await db.refresh(session)
        session_id: uuid.UUID = session.id

    try:
        while True:
            raw = await websocket.receive_text()
            # Rate limit check
            try:
                await _rate_limiter.check(redis, key=f"device:{device_id}")
            except Exception:
                await websocket.send_text(
                    json.dumps({"type": "error", "message": "Rate limit exceeded"})
                )
                continue

            try:
                msg = json.loads(raw)
            except json.JSONDecodeError:
                await websocket.send_text(
                    json.dumps({"type": "error", "message": "Invalid JSON"})
                )
                continue

            if msg.get("type") != "audio_chunk":
                continue

            audio_b64: str = msg.get("data", "")

            # ── 1. STT ──────────────────────────────────────────────────────
            await websocket.send_text(json.dumps({"type": "mood_update", "mood": "listening", "transition_ms": 300}))
            user_text = await _stt.transcribe(audio_b64)
            if not user_text:
                continue

            # ── 2. Safety check on user input ───────────────────────────────
            input_safety = await _safety.check(user_text)
            if not input_safety["safe"]:
                await _handle_safety_event(
                    websocket, db, device_id, session_id, user_text, input_safety, redis
                )
                continue

            # ── 3. Save user turn to memory and DB ──────────────────────────
            await memory.add_turn(device_id, "user", user_text)
            await _persist_message(db, session_id, "user", user_text)

            # ── 4. LLM stream ────────────────────────────────────────────────
            await websocket.send_text(json.dumps({"type": "mood_update", "mood": "thinking", "transition_ms": 300}))
            context = await memory.get_context(device_id)
            assistant_text_parts: list[str] = []
            async for token in _llm.chat_stream(context, device_id):
                assistant_text_parts.append(token)
            assistant_text = "".join(assistant_text_parts)

            # ── 5. Safety check on LLM output ───────────────────────────────
            output_safety = await _safety.check(assistant_text)
            if not output_safety["safe"]:
                assistant_text = _SAFE_RESPONSE
                await _trigger_safety_alert(db, device_id, assistant_text, output_safety, redis)

            # ── 6. TTS ──────────────────────────────────────────────────────
            audio_out = await _tts.synthesize(assistant_text)

            # ── 7. Persist assistant turn ────────────────────────────────────
            await memory.add_turn(device_id, "assistant", assistant_text)
            await _persist_message(db, session_id, "assistant", assistant_text)

            # ── 8. Send response ─────────────────────────────────────────────
            mood = _infer_mood(assistant_text)
            await websocket.send_text(
                json.dumps({
                    "type": "ai_response",
                    "text": assistant_text,
                    "audio": audio_out,
                    "mood": mood,
                })
            )
            await websocket.send_text(
                json.dumps({"type": "mood_update", "mood": mood, "transition_ms": 500})
            )

    except WebSocketDisconnect:
        logger.info("WebSocket disconnected: device_id=%s", device_id)
    finally:
        async with AsyncSessionLocal() as db:
            result = await db.get(ConversationSession, session_id)
            if result:
                result.ended_at = datetime.now(tz=timezone.utc)
                await db.commit()


async def _persist_message(
    db: AsyncSession, session_id: uuid.UUID, role: str, content: str
) -> None:
    encrypted = encrypt_text(content)
    msg = Message(session_id=session_id, role=role, content_encrypted=encrypted)
    async with AsyncSessionLocal() as session:
        session.add(msg)
        await session.commit()


async def _handle_safety_event(
    websocket: WebSocket,
    db: AsyncSession,
    device_id: str,
    session_id: uuid.UUID,
    user_text: str,
    safety_result: dict,
    redis,
) -> None:
    """Respond empathetically and trigger alert pipeline."""
    response = _SAFE_RESPONSE
    audio_out = await _tts.synthesize(response)
    await websocket.send_text(
        json.dumps({"type": "ai_response", "text": response, "audio": audio_out, "mood": "concerned"})
    )
    await websocket.send_text(
        json.dumps({"type": "mood_update", "mood": "concerned", "transition_ms": 500})
    )
    await _trigger_safety_alert(db, device_id, user_text, safety_result, redis)


async def _trigger_safety_alert(
    db: AsyncSession,
    device_id: str,
    text: str,
    safety_result: dict,
    redis,
) -> None:
    """Persist an alert record and push notification to family members."""
    async with AsyncSessionLocal() as session:
        alert = Alert(
            device_id=device_id,
            alert_type="safety",
            severity=str(safety_result.get("severity", "high")),
            description=f"Safety signal detected: {text[:200]}",
        )
        session.add(alert)
        await session.commit()

    # TODO: look up family registration IDs from DB; using placeholder for now
    await _push.send_safety_alert(device_id=device_id, family_registration_ids=[])
    logger.warning("Safety alert created for device %s", device_id)


def _infer_mood(text: str) -> str:
    """Heuristic mood inference from response text."""
    if any(w in text for w in ["开心", "好呀", "太棒", "哈哈", "笑"]):
        return "happy"
    if any(w in text for w in ["担心", "难过", "帮你", "没关系"]):
        return "concerned"
    return "calm"
