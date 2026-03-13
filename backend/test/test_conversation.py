"""
Tests for the conversation WebSocket pipeline.

Only the safety-classifier integration is tested here (no real STT/LLM/TTS
calls are made); the external services are mocked.
"""

from __future__ import annotations

import json
from unittest.mock import AsyncMock, patch

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from src.database import Base, get_db
from src.main import app

_TEST_DB_URL = "sqlite+aiosqlite:///:memory:"
_test_engine = create_async_engine(_TEST_DB_URL, echo=False)
_TestSessionLocal = async_sessionmaker(
    bind=_test_engine, class_=AsyncSession, expire_on_commit=False
)


async def _override_get_db():
    async with _TestSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


app.dependency_overrides[get_db] = _override_get_db


@pytest_asyncio.fixture(autouse=True)
async def setup_db():
    async with _test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with _test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture
async def client():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac


@pytest.mark.asyncio
async def test_health_endpoint(client: AsyncClient) -> None:
    """Smoke test: the health endpoint must return 200."""
    resp = await client.get("/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


@pytest.mark.asyncio
async def test_safety_classifier_blocks_selfharm_in_pipeline() -> None:
    """
    The safety classifier should flag self-harm text so the pipeline overrides
    the LLM output with the safe response template.
    """
    from src.services.safety_classifier import SafetyClassifier

    clf = SafetyClassifier()
    result = await clf.check("我不想活了")
    assert result["safe"] is False
    assert result["severity"] == "critical"


@pytest.mark.asyncio
async def test_safe_text_passes_classifier() -> None:
    from src.services.safety_classifier import SafetyClassifier

    clf = SafetyClassifier()
    result = await clf.check("今天吃了什么好吃的？")
    assert result["safe"] is True
