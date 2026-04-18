from __future__ import annotations
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException
from mysql.connector.connection import MySQLConnection

from ..schemas.notifications import (
    CreateNotificationRequest, NotificationListResponse,
    NotificationResponse, CountResponse, MessageResponse,
)
from ...db.session import get_db
from ...services import notification_service

router = APIRouter(prefix="/api/notifications", tags=["Notifications"])


@router.get("/", response_model=NotificationListResponse, summary="List notifications")
async def get_notifications(
    is_read: Optional[int] = None,
    severity: Optional[str] = None,
    limit: int = 50,
    db: MySQLConnection = Depends(get_db),
):
    """
    Retrieve notifications with optional filters.
    `is_read`: 0 = unread only, 1 = read only, omit for all.
    `severity`: info | warning | critical.
    """
    rows = notification_service.get_notifications(db=db, is_read=is_read, severity=severity, limit=limit)
    return NotificationListResponse(notifications=rows, count=len(rows))


@router.get("/unread/count", response_model=CountResponse, summary="Unread notification count")
async def unread_count(db: MySQLConnection = Depends(get_db)):
    """Return the total number of unread notifications."""
    return CountResponse(count=notification_service.get_unread_count(db=db))


@router.put("/read-all", response_model=MessageResponse, summary="Mark all notifications read")
async def mark_all_read(db: MySQLConnection = Depends(get_db)):
    """Mark every unread notification as read and broadcast via Socket.IO."""
    count = await notification_service.mark_all_read(db=db)
    return MessageResponse(message=f"{count} notification(s) marked as read", count=count)


@router.put("/{nid}/read", response_model=MessageResponse, summary="Mark a notification read")
async def mark_read(nid: int, db: MySQLConnection = Depends(get_db)):
    """Mark a single notification as read."""
    result = await notification_service.mark_notification_read(db=db, nid=nid)
    if result is None:
        raise HTTPException(status_code=404, detail="Notification not found")
    if result.get("already"):
        return MessageResponse(message="Already read")
    return MessageResponse(message="Marked as read", id=nid)


@router.delete("/clear-all", response_model=MessageResponse, summary="Delete all read notifications")
async def clear_all(db: MySQLConnection = Depends(get_db)):
    """Permanently delete all notifications that have already been read."""
    count = notification_service.clear_read_notifications(db=db)
    return MessageResponse(message=f"{count} read notification(s) cleared", count=count)


@router.delete("/{nid}", response_model=MessageResponse, summary="Delete a notification")
async def delete_notification(nid: int, db: MySQLConnection = Depends(get_db)):
    """Permanently delete a single notification by ID."""
    deleted = await notification_service.delete_notification(db=db, nid=nid)
    if not deleted:
        raise HTTPException(status_code=404, detail="Notification not found")
    return MessageResponse(message="Notification deleted", id=nid)


@router.post("/", response_model=NotificationResponse, status_code=201, summary="Create a notification")
async def create_notification(
    body: CreateNotificationRequest,
    db: MySQLConnection = Depends(get_db),
):
    """Manually push a notification — useful for admin tooling or testing."""
    row = await notification_service.create_notification(
        db=db,
        title=body.title,
        message=body.message,
        notification_type=body.notification_type,
        severity=body.severity,
        related_id=body.related_id,
    )
    if row is None:
        raise HTTPException(status_code=500, detail="Failed to create notification")
    return NotificationResponse(notification=row)
