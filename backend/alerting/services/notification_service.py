"""
services/notification_service.py

All notification business logic — no HTTP concerns.
"""
from __future__ import annotations
from typing import List, Optional

from mysql.connector.connection import MySQLConnection

from ..core.socket import sio


def _serialize(row: dict) -> dict:
    for k in ("created_at", "read_at"):
        if row.get(k) and hasattr(row[k], "strftime"):
            row[k] = row[k].strftime("%Y-%m-%d %H:%M:%S")
    return row


# ── Core create ───────────────────────────────────────────────────────────────

async def create_notification(
    db: MySQLConnection,
    title: str,
    message: str,
    notification_type: str = "system",
    severity: str = "info",
    related_id: Optional[int] = None,
    emit: bool = True,
) -> Optional[dict]:
    """
    Persist a notification and optionally broadcast it via Socket.IO.
    Returns the full notification dict or None on DB failure.
    """
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(
            """
            INSERT INTO notifications
                (notification_type, title, message, severity, related_id)
            VALUES (%s, %s, %s, %s, %s)
            """,
            (notification_type, title, message, severity, related_id),
        )
        db.commit()
        nid = cursor.lastrowid
        cursor.execute("SELECT * FROM notifications WHERE id = %s", (nid,))
        row = _serialize(cursor.fetchone())
        if emit:
            await sio.emit("new_notification", row)
        return row
    except Exception as exc:
        print(f"[notification_service] create error: {exc}")
        return None
    finally:
        cursor.close()


# ── Convenience factories ─────────────────────────────────────────────────────

async def notify_alert_triggered(db: MySQLConnection, alert: dict) -> Optional[dict]:
    sev = alert.get("severity", "info")
    icon = "🔴" if sev == "critical" else "🟡"
    return await create_notification(
        db=db,
        title=f"{icon} {sev.upper()} alert — {alert.get('alert_type', '').upper()}",
        message=alert.get("message", "A sensor threshold was exceeded."),
        notification_type="alert_triggered",
        severity=sev,
        related_id=alert.get("id"),
    )


async def notify_alert_acknowledged(
    db: MySQLConnection, alert_id: int, ack_by: str
) -> Optional[dict]:
    return await create_notification(
        db=db,
        title="✅ Alert acknowledged",
        message=f"Alert #{alert_id} was acknowledged by {ack_by}.",
        notification_type="alert_acknowledged",
        severity="info",
        related_id=alert_id,
    )


async def notify_device_offline(
    db: MySQLConnection, device_id: str, device_name: str
) -> Optional[dict]:
    return await create_notification(
        db=db,
        title=f"📵 Device offline — {device_name}",
        message=f"Device '{device_name}' ({device_id}) has missed its heartbeat.",
        notification_type="device_offline",
        severity="warning",
    )


async def notify_system(
    db: MySQLConnection, title: str, message: str, severity: str = "info"
) -> Optional[dict]:
    return await create_notification(db=db, title=title, message=message, severity=severity)


# ── Query helpers ─────────────────────────────────────────────────────────────

def get_notifications(
    db: MySQLConnection,
    is_read: Optional[int] = None,
    severity: Optional[str] = None,
    limit: int = 50,
) -> List[dict]:
    cursor = db.cursor(dictionary=True)
    try:
        sql = "SELECT * FROM notifications WHERE 1=1"
        params: list = []
        if is_read is not None:
            sql += " AND is_read = %s";  params.append(is_read)
        if severity:
            sql += " AND severity = %s"; params.append(severity)
        sql += " ORDER BY created_at DESC LIMIT %s"; params.append(limit)
        cursor.execute(sql, params)
        return [_serialize(r) for r in cursor.fetchall()]
    finally:
        cursor.close()


def get_unread_count(db: MySQLConnection) -> int:
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute("SELECT COUNT(*) AS cnt FROM notifications WHERE is_read = 0")
        return cursor.fetchone()["cnt"]
    finally:
        cursor.close()


async def mark_notification_read(db: MySQLConnection, nid: int) -> Optional[dict]:
    """Returns None if not found, {"already": True} if already read, else {"id": nid}."""
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute("SELECT id, is_read FROM notifications WHERE id = %s", (nid,))
        row = cursor.fetchone()
        if not row:
            return None
        if row["is_read"]:
            return {"already": True}
        cursor.execute("UPDATE notifications SET is_read=1, read_at=NOW() WHERE id=%s", (nid,))
        db.commit()
        await sio.emit("notification_read", {"id": nid})
        return {"id": nid}
    finally:
        cursor.close()


async def mark_all_read(db: MySQLConnection) -> int:
    cursor = db.cursor()
    try:
        cursor.execute("UPDATE notifications SET is_read=1, read_at=NOW() WHERE is_read=0")
        db.commit()
        count = cursor.rowcount
        await sio.emit("all_notifications_read", {"count": count})
        return count
    finally:
        cursor.close()


async def delete_notification(db: MySQLConnection, nid: int) -> bool:
    """Returns False if not found."""
    cursor = db.cursor()
    try:
        cursor.execute("DELETE FROM notifications WHERE id = %s", (nid,))
        db.commit()
        if not cursor.rowcount:
            return False
        await sio.emit("notification_deleted", {"id": nid})
        return True
    finally:
        cursor.close()


def clear_read_notifications(db: MySQLConnection) -> int:
    cursor = db.cursor()
    try:
        cursor.execute("DELETE FROM notifications WHERE is_read = 1")
        db.commit()
        return cursor.rowcount
    finally:
        cursor.close()
