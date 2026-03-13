from datetime import datetime

from pydantic import BaseModel


class BindDeviceRequest(BaseModel):
    device_id: str
    nickname: str = "小光"


class DeviceStatusResponse(BaseModel):
    device_id: str
    nickname: str
    is_online: bool
    firmware_version: str
    last_seen_at: datetime | None
    owner_id: str
