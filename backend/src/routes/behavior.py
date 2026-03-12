"""
Behavior routes.

GET /api/v1/behavior/daily/{date} — return daily behavior report for a device
"""

from __future__ import annotations

from datetime import date, datetime, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from src.database import get_db
from src.middleware.auth_middleware import get_current_user
from src.models.conversation import ConversationSession
from src.models.user import User
from pydantic import BaseModel

router = APIRouter(prefix="/behavior", tags=["behavior"])


class DailyReport(BaseModel):
    date: str
    device_id: str
    total_sessions: int
    total_turns: int
    first_interaction: datetime | None
    last_interaction: datetime | None


@router.get("/daily/{report_date}", response_model=DailyReport)
async def get_daily_report(
    report_date: date,
    device_id: Annotated[str, Query(description="Hardware device ID")],
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> DailyReport:
    """
    Return a daily activity summary for the given device and date.

    Uses conversation session data as a proxy for behavioral activity.
    """
    day_start = datetime(report_date.year, report_date.month, report_date.day, tzinfo=timezone.utc)
    day_end = datetime(report_date.year, report_date.month, report_date.day, 23, 59, 59, tzinfo=timezone.utc)

    result = await db.execute(
        select(ConversationSession).where(
            ConversationSession.device_id == device_id,
            ConversationSession.started_at >= day_start,
            ConversationSession.started_at <= day_end,
        )
    )
    sessions = result.scalars().all()

    total_turns = sum(s.turn_count for s in sessions)
    started_times = [s.started_at for s in sessions if s.started_at]

    return DailyReport(
        date=str(report_date),
        device_id=device_id,
        total_sessions=len(sessions),
        total_turns=total_turns,
        first_interaction=min(started_times) if started_times else None,
        last_interaction=max(started_times) if started_times else None,
    )
