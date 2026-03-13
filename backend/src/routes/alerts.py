"""
Alert routes.

POST /api/v1/alerts/ack — acknowledge an alert
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.database import get_db
from src.middleware.auth_middleware import get_current_user
from src.models.alert import Alert
from src.models.user import User
from src.schemas.alert import AckAlertRequest
from pydantic import BaseModel

router = APIRouter(prefix="/alerts", tags=["alerts"])


class AckAlertResponse(BaseModel):
    alert_id: str
    is_acked: bool
    acked_at: datetime


@router.post("/ack", response_model=AckAlertResponse)
async def ack_alert(
    body: AckAlertRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> AckAlertResponse:
    """Acknowledge an alert, marking it as handled."""
    result = await db.execute(select(Alert).where(Alert.id == body.alert_id))
    alert = result.scalar_one_or_none()

    if not alert:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Alert not found")

    if alert.is_acked:
        return AckAlertResponse(
            alert_id=str(alert.id),
            is_acked=True,
            acked_at=alert.acked_at,
        )

    alert.is_acked = True
    alert.acked_by = current_user.id
    alert.acked_at = datetime.now(tz=timezone.utc)

    return AckAlertResponse(
        alert_id=str(alert.id),
        is_acked=True,
        acked_at=alert.acked_at,
    )
