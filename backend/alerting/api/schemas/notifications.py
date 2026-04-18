from __future__ import annotations
from typing import List, Optional
from pydantic import BaseModel, Field


# ── Request bodies ────────────────────────────────────────────────────────────

class CreateNotificationRequest(BaseModel):
    title: str = Field(..., description="Short notification title")
    message: str = Field(..., description="Full notification body")
    notification_type: str = Field("system", description="alert_triggered | alert_acknowledged | device_offline | system")
    severity: str = Field("info", description="info | warning | critical")
    related_id: Optional[int] = Field(None, description="Related alert or device ID")


# ── Response models ───────────────────────────────────────────────────────────

class NotificationOut(BaseModel):
    id: int
    notification_type: str
    title: str
    message: str
    severity: str
    related_id: Optional[int]
    is_read: bool
    created_at: Optional[str]
    read_at: Optional[str]

    class Config:
        from_attributes = True


class NotificationListResponse(BaseModel):
    notifications: List[NotificationOut]
    count: int


class NotificationResponse(BaseModel):
    notification: NotificationOut


class CountResponse(BaseModel):
    count: int


class MessageResponse(BaseModel):
    message: str
    id: Optional[int] = None
    count: Optional[int] = None
