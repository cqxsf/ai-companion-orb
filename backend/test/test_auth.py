"""
Tests for authentication endpoints.

Uses an in-memory SQLite database via SQLAlchemy so no real Postgres is needed.
"""

from __future__ import annotations

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from src.database import Base, get_db, init_redis, close_redis
from src.main import app

# ---------------------------------------------------------------------------
# In-memory SQLite override
# ---------------------------------------------------------------------------
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
async def test_register_success(client: AsyncClient) -> None:
    resp = await client.post(
        "/api/v1/auth/register",
        json={"phone": "13800000001", "password": "secret123", "name": "张三", "role": "elder"},
    )
    assert resp.status_code == 201
    data = resp.json()
    assert "access_token" in data
    assert data["role"] == "elder"


@pytest.mark.asyncio
async def test_register_duplicate_phone(client: AsyncClient) -> None:
    payload = {"phone": "13800000002", "password": "secret123", "name": "李四", "role": "family"}
    await client.post("/api/v1/auth/register", json=payload)
    resp = await client.post("/api/v1/auth/register", json=payload)
    assert resp.status_code == 409


@pytest.mark.asyncio
async def test_login_success(client: AsyncClient) -> None:
    await client.post(
        "/api/v1/auth/register",
        json={"phone": "13800000003", "password": "mypassword", "name": "王五", "role": "family"},
    )
    resp = await client.post(
        "/api/v1/auth/login",
        json={"phone": "13800000003", "password": "mypassword"},
    )
    assert resp.status_code == 200
    assert "access_token" in resp.json()


@pytest.mark.asyncio
async def test_login_wrong_password(client: AsyncClient) -> None:
    await client.post(
        "/api/v1/auth/register",
        json={"phone": "13800000004", "password": "correctpass", "name": "赵六", "role": "elder"},
    )
    resp = await client.post(
        "/api/v1/auth/login",
        json={"phone": "13800000004", "password": "wrongpass"},
    )
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_login_nonexistent_user(client: AsyncClient) -> None:
    resp = await client.post(
        "/api/v1/auth/login",
        json={"phone": "99999999999", "password": "whatever"},
    )
    assert resp.status_code == 401
