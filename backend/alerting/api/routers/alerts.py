from __future__ import annotations
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException
from mysql.connector.connection import MySQLConnection

from ..schemas.alerts import (
    SensorCheckRequest, SensorCheckResponse,
    ThresholdsResponse, AckRequest, AckResponse,
    AlertListResponse, AlertSummaryResponse, CountResponse,
)
from ...db.session import get_db
from ...services import alert_service, notification_service
from ...core.config import settings

router = APIRouter(prefix="/api/alerts", tags=["Alerts"])


# ── Sensor check ──────────────────────────────────────────────────────────────

@router.post("/check", response_model=SensorCheckResponse, summary="Submit sensor readings")
async def check_sensor(
    body: SensorCheckRequest,
    db: MySQLConnection = Depends(get_db),
):
    """
    Submit sensor readings for a batch. Alerts are generated and persisted
    for any reading that exceeds a configured threshold. Real-time Socket.IO
    events are emitted for connected clients.
    """
    alerts = await alert_service.evaluate_and_save_alerts(
        db=db,
        batch_id=body.batch_id,
        fruit_type=body.fruit_type,
        sensor_data=body.sensor_data,
    )

    # Fire a notification for every triggered alert
    for alert in alerts:
        await notification_service.notify_alert_triggered(db=db, alert=alert)

    return SensorCheckResponse(
        status="ok",
        alerts_generated=len(alerts),
        alerts=alerts,
    )


@router.get("/thresholds", response_model=ThresholdsResponse, summary="Get sensor thresholds")
async def get_thresholds():
    """Return the currently configured warning/critical thresholds per sensor type."""
    return ThresholdsResponse(thresholds=settings.thresholds)


# ── History ───────────────────────────────────────────────────────────────────

@router.get("/history", response_model=AlertListResponse, summary="List alert history")
async def get_history(
    batch_id: Optional[str] = None,
    fruit_type: Optional[str] = None,
    severity: Optional[str] = None,
    acknowledged: Optional[int] = None,
    limit: int = 100,
    db: MySQLConnection = Depends(get_db),
):
    """
    Retrieve alert history with optional filters.
    `acknowledged` accepts `0` (unacknowledged) or `1` (acknowledged).
    """
    alerts = alert_service.get_alert_history(
        db=db,
        batch_id=batch_id,
        fruit_type=fruit_type,
        severity=severity,
        acknowledged=acknowledged,
        limit=limit,
    )
    return AlertListResponse(alerts=alerts, count=len(alerts))


@router.get("/history/batch/{batch_id}", response_model=AlertListResponse, summary="Batch alert history")
async def get_batch_history(batch_id: str, db: MySQLConnection = Depends(get_db)):
    """Retrieve all alerts for a specific batch."""
    alerts = alert_service.get_batch_alert_history(db=db, batch_id=batch_id)
    return AlertListResponse(alerts=alerts, count=len(alerts))


@router.get("/history/summary", response_model=AlertSummaryResponse, summary="Alert summary by batch")
async def get_summary(db: MySQLConnection = Depends(get_db)):
    """Aggregated alert counts per batch, ordered by most recent alert."""
    return AlertSummaryResponse(summary=alert_service.get_alert_summary(db=db))


@router.get("/history/unacknowledged/count", response_model=CountResponse, summary="Unacknowledged count")
async def unacked_count(db: MySQLConnection = Depends(get_db)):
    """Total number of alerts that have not yet been acknowledged."""
    return CountResponse(count=alert_service.get_unacknowledged_count(db=db))


# ── Acknowledgment ────────────────────────────────────────────────────────────

@router.put("/ack/{alert_id}", response_model=AckResponse, summary="Acknowledge an alert")
async def acknowledge(
    alert_id: int,
    body: AckRequest = AckRequest(),
    db: MySQLConnection = Depends(get_db),
):
    """Mark a single alert as acknowledged and emit a Socket.IO event."""
    result = await alert_service.acknowledge_alert(db=db, alert_id=alert_id, ack_by=body.acknowledged_by)
    if result is None:
        raise HTTPException(status_code=404, detail="Alert not found")
    if result.get("already"):
        return AckResponse(message="Already acknowledged")
    await notification_service.notify_alert_acknowledged(db=db, alert_id=alert_id, ack_by=body.acknowledged_by)
    return AckResponse(message="Alert acknowledged", alert_id=alert_id)


@router.put("/ack/batch/{batch_id}", response_model=AckResponse, summary="Acknowledge all alerts in a batch")
async def acknowledge_batch(
    batch_id: str,
    body: AckRequest = AckRequest(),
    db: MySQLConnection = Depends(get_db),
):
    """Acknowledge all unacknowledged alerts belonging to the given batch."""
    count = await alert_service.acknowledge_batch_alerts(db=db, batch_id=batch_id, ack_by=body.acknowledged_by)
    return AckResponse(message=f"{count} alert(s) acknowledged", count=count, batch_id=batch_id)


@router.delete("/ack/{alert_id}", response_model=AckResponse, summary="Reset acknowledgment")
async def unacknowledge(alert_id: int, db: MySQLConnection = Depends(get_db)):
    """Remove the acknowledgment from an alert (sets it back to unacknowledged)."""
    alert_service.reset_acknowledgment(db=db, alert_id=alert_id)
    return AckResponse(message="Acknowledgment reset", alert_id=alert_id)
