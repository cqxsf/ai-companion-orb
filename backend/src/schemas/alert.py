import uuid

from pydantic import BaseModel


class AckAlertRequest(BaseModel):
    alert_id: uuid.UUID
