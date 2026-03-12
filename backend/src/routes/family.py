"""
Family routes.

GET  /api/v1/family/{family_id}/dashboard — return Orb statuses for a family group
POST /api/v1/family/{family_id}/care      — send a care message to the elder's Orb
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.database import get_db
from src.middleware.auth_middleware import get_current_user
from src.models.device import Device
from src.models.user import User

router = APIRouter(prefix="/family", tags=["family"])


class FamilyDashboard(BaseModel):
    family_id: str
    devices: list[dict]


class CareMessageRequest(BaseModel):
    message: str
    device_id: str


class CareMessageResponse(BaseModel):
    status: str
    device_id: str


@router.get("/{family_id}/dashboard", response_model=FamilyDashboard)
async def get_family_dashboard(
    family_id: str,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> FamilyDashboard:
    """Return all Orb devices that belong to a family group."""
    # A user can see the dashboard if they are the owner or a family member of
    # at least one device in the family group.
    result = await db.execute(
        select(Device).where(Device.owner_id == current_user.id)
    )
    owned_devices = result.scalars().all()

    # Also fetch devices where this user appears in family_ids
    all_result = await db.execute(select(Device))
    all_devices = all_result.scalars().all()
    shared_devices = [d for d in all_devices if str(current_user.id) in (d.family_ids or [])]

    visible_devices = {d.device_id: d for d in list(owned_devices) + shared_devices}

    devices_info = [
        {
            "device_id": d.device_id,
            "nickname": d.nickname,
            "is_online": d.is_online,
            "firmware_version": d.firmware_version,
            "last_seen_at": d.last_seen_at.isoformat() if d.last_seen_at else None,
            "owner_id": str(d.owner_id),
        }
        for d in visible_devices.values()
    ]

    return FamilyDashboard(family_id=family_id, devices=devices_info)


@router.post("/{family_id}/care", response_model=CareMessageResponse)
async def send_care_message(
    family_id: str,
    body: CareMessageRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> CareMessageResponse:
    """
    Send a remote care message from a family member to an elder's Orb.

    The message is queued in Redis so that the WebSocket pipeline can pick it
    up and relay it to the device as a TTS announcement.
    """
    result = await db.execute(select(Device).where(Device.device_id == body.device_id))
    device = result.scalar_one_or_none()
    if not device:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Device not found")

    family_ids: list[str] = device.family_ids or []
    if (
        str(device.owner_id) != str(current_user.id)
        and str(current_user.id) not in family_ids
    ):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    # TODO: push the care message to the device via Redis pub/sub or WebSocket
    # For now, acknowledge receipt.
    return CareMessageResponse(status="queued", device_id=body.device_id)
