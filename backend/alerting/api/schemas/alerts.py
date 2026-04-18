from __future__ import annotations
from datetime import datetime
from typing import Dict, List, Optional
from pydantic import BaseModel, Field


# ── Enums (as literals for simplicity) ───────────────────────────────────────

Severity = str   # "warning" | "critical"


# ── Request bodies ────────────────────────────────────────────────────────────

class SensorCheckRequest(BaseModel):
    batch_id: str = Field(..., description="Unique identifier for the storage batch")
    fruit_type: str = Field("Unknown", description="Type of fruit being monitored")
    sensor_data: Dict[str, float] = Field(
        ...,
        description="Sensor readings keyed by type (ethylene, voc, temperature, humidity)",
        example={"ethylene": 1.5, "temperature": 27.0, "humidity": 85.0},
    )


class AckRequest(BaseModel):
    acknowledged_by: str = Field("Store Staff", description="Name or role of the person acknowledging")


# ── Response models ───────────────────────────────────────────────────────────

class AlertOut(BaseModel):
    id: int
    batch_id: str
    fruit_type: str
    alert_type: str
    message: str
    severity: Severity
    value: float
    threshold: float
    acknowledged: Optional[bool] = None
    acknowledged_by: Optional[str] = None
    acknowledged_at: Optional[str] = None
    created_at: Optional[str] = None

    class Config:
        from_attributes = True


class SensorCheckResponse(BaseModel):
    status: str
    alerts_generated: int
    alerts: List[AlertOut]


class ThresholdsResponse(BaseModel):
    thresholds: Dict[str, Dict[str, float]]


class AlertListResponse(BaseModel):
    alerts: List[AlertOut]
    count: int


class AlertSummaryItem(BaseModel):
    batch_id: str
    fruit_type: str
    total: int
    unacknowledged: int
    critical_count: int
    warning_count: int
    latest_alert: Optional[str]


class AlertSummaryResponse(BaseModel):
    summary: List[AlertSummaryItem]


class CountResponse(BaseModel):
    count: int


class AckResponse(BaseModel):
    message: str
    alert_id: Optional[int] = None
    count: Optional[int] = None
    batch_id: Optional[str] = None
