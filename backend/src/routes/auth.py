"""
Authentication routes.

POST /api/v1/auth/register — create a new user account, returns JWT
POST /api/v1/auth/login    — verify credentials, returns JWT
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from passlib.context import CryptContext
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.database import get_db
from src.middleware.auth_middleware import create_access_token
from src.models.user import User
from src.schemas.auth import LoginRequest, RegisterRequest, TokenResponse

router = APIRouter(prefix="/auth", tags=["auth"])
_pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(
    body: RegisterRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TokenResponse:
    """Create a new user and return an access token."""
    result = await db.execute(select(User).where(User.phone == body.phone))
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Phone number already registered",
        )

    user = User(
        phone=body.phone,
        password_hash=_pwd_ctx.hash(body.password),
        name=body.name,
        role=body.role,
    )
    db.add(user)
    await db.flush()  # populate user.id before commit

    token = create_access_token(user.id, user.role)
    return TokenResponse(access_token=token, user_id=str(user.id), role=user.role)


@router.post("/login", response_model=TokenResponse)
async def login(
    body: LoginRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TokenResponse:
    """Verify credentials and return an access token."""
    result = await db.execute(select(User).where(User.phone == body.phone))
    user = result.scalar_one_or_none()

    if not user or not _pwd_ctx.verify(body.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect phone or password",
        )

    token = create_access_token(user.id, user.role)
    return TokenResponse(access_token=token, user_id=str(user.id), role=user.role)
