"""
Device routes.

POST /api/v1/devices/bind          — bind a hardware device to the authenticated user
GET  /api/v1/devices/{device_id}/status — return device status
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.database import get_db
from src.middleware.auth_middleware import get_current_user
from src.models.device import Device
from src.models.user import User
from src.schemas.device import BindDeviceRequest, DeviceStatusResponse

router = APIRouter(prefix="/devices", tags=["devices"])


@router.post("/bind", response_model=DeviceStatusResponse, status_code=status.HTTP_201_CREATED)
async def bind_device(
    body: BindDeviceRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> DeviceStatusResponse:
    """Bind a hardware Orb device to the authenticated user account."""
    result = await db.execute(select(Device).where(Device.device_id == body.device_id))
    device = result.scalar_one_or_none()

    if device:
        if str(device.owner_id) == str(current_user.id):
            # Already bound by this user — idempotent
            return _to_response(device)
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Device is already bound to another account",
        )

    device = Device(
        device_id=body.device_id,
        owner_id=current_user.id,
        nickname=body.nickname,
    )
    db.add(device)
    await db.flush()
    return _to_response(device)


@router.get("/{device_id}/status", response_model=DeviceStatusResponse)
async def get_device_status(
    device_id: str,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> DeviceStatusResponse:
    """Return current status for the requested device."""
    result = await db.execute(select(Device).where(Device.device_id == device_id))
    device = result.scalar_one_or_none()
    if not device:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Device not found")

    # Only the owner or a family member may read status
    family_ids: list[str] = device.family_ids or []
    if str(device.owner_id) != str(current_user.id) and str(current_user.id) not in family_ids:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")

    return _to_response(device)


def _to_response(device: Device) -> DeviceStatusResponse:
    return DeviceStatusResponse(
        device_id=device.device_id,
        nickname=device.nickname,
        is_online=device.is_online,
        firmware_version=device.firmware_version,
        last_seen_at=device.last_seen_at,
        owner_id=str(device.owner_id),
    )
