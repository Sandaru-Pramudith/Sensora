from __future__ import annotations
from typing import List, Optional

from mysql.connector.connection import MySQLConnection

from ..core.config import settings
from ..core.socket import sio


def _serialize_alert(row: dict) -> dict:
    for k in ("created_at", "acknowledged_at"):
        if row.get(k) and hasattr(row[k], "strftime"):
            row[k] = row[k].strftime("%Y-%m-%d %H:%M:%S")
    return row


# ── Threshold evaluation (kept only for compatibility) ───────────────────────

async def evaluate_and_save_alerts(
    db: MySQLConnection,
    batch_id: str,
    fruit_type: str,
    sensor_data: dict,
) -> List[dict]:
    """
    Old threshold-based alert creation.
    Kept so /api/alerts/check will still work if called,
    but the main Alerts UI now reads directly from prediction table.
    """
    thresholds = settings.thresholds
    generated: List[dict] = []
    cursor = db.cursor(dictionary=True)

    try:
        for sensor_type, value in sensor_data.items():
            if sensor_type not in thresholds:
                continue

            limits = thresholds[sensor_type]
            severity: Optional[str] = None
            threshold_val: Optional[float] = None

            if float(value) >= limits["critical"]:
                severity, threshold_val = "critical", limits["critical"]
            elif float(value) >= limits["warning"]:
                severity, threshold_val = "warning", limits["warning"]

            if severity is None:
                continue

            message = (
                f"{severity.upper()}: {sensor_type.upper()} = {value} "
                f"(threshold: {threshold_val}) for batch {batch_id} [{fruit_type}]"
            )

            cursor.execute(
                """
                INSERT INTO alerts
                    (batch_id, fruit_type, alert_type, message, severity, value, threshold)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                """,
                (batch_id, fruit_type, sensor_type, message, severity, float(value), threshold_val),
            )
            db.commit()

            alert = {
                "id": cursor.lastrowid,
                "batch_id": batch_id,
                "fruit_type": fruit_type,
                "alert_type": sensor_type,
                "message": message,
                "severity": severity,
                "value": float(value),
                "threshold": threshold_val,
                "acknowledged": False,
                "acknowledged_by": None,
                "acknowledged_at": None,
                "created_at": None,
            }
            generated.append(alert)
            await sio.emit("new_alert", alert)

    finally:
        cursor.close()

    return generated


# ── Active alerts from prediction table ──────────────────────────────────────

def get_alert_history(
    db: MySQLConnection,
    batch_id: Optional[str] = None,
    fruit_type: Optional[str] = None,
    severity: Optional[str] = None,
    acknowledged: Optional[int] = None,
    limit: int = 100,
) -> List[dict]:
    """
    Return only ACTIVE spoilage alerts.
    A basket appears here only if its latest prediction says spoiled.
    If latest prediction becomes fresh again, it disappears automatically.
    """
    cursor = db.cursor(dictionary=True)
    try:
        sql = """
            SELECT
                p.pred_id AS id,
                CAST(p.basket_id AS CHAR) AS batch_id,
                COALESCE(b.fruit_type, 'Unknown') AS fruit_type,
                'spoilage' AS alert_type,
                CONCAT(
                    'Spoilage detected for basket ', p.basket_id,
                    CASE
                        WHEN b.location IS NOT NULL AND b.location <> ''
                            THEN CONCAT(' at ', b.location)
                        ELSE ''
                    END,
                    ' [', COALESCE(b.fruit_type, 'Unknown'), ']'
                ) AS message,
                'critical' AS severity,
                COALESCE(p.hours_left, 0) AS value,
                0 AS threshold,
                0 AS acknowledged,
                NULL AS acknowledged_by,
                NULL AS acknowledged_at,
                p.predicted_at AS created_at
            FROM prediction p
            LEFT JOIN basket b
                ON b.basket_id = p.basket_id
            WHERE p.pred_id = (
                SELECT p2.pred_id
                FROM prediction p2
                WHERE p2.basket_id = p.basket_id
                ORDER BY p2.predicted_at DESC, p2.pred_id DESC
                LIMIT 1
            )
            AND p.spoil_stage = 1
        """

        params: list = []

        if batch_id:
            sql += " AND CAST(p.basket_id AS CHAR) = %s"
            params.append(batch_id)

        if fruit_type:
            sql += " AND b.fruit_type = %s"
            params.append(fruit_type)

        if severity:
            sql += " AND 'critical' = %s"
            params.append(severity)

        if acknowledged is not None:
            # prediction-based live alerts are always active/unacknowledged
            if int(acknowledged) == 1:
                return []

        sql += " ORDER BY p.predicted_at DESC, p.pred_id DESC LIMIT %s"
        params.append(limit)

        cursor.execute(sql, params)
        return [_serialize_alert(dict(r)) for r in cursor.fetchall()]
    finally:
        cursor.close()


def get_batch_alert_history(db: MySQLConnection, batch_id: str) -> List[dict]:
    return get_alert_history(db=db, batch_id=batch_id, limit=1)


def get_alert_summary(db: MySQLConnection) -> List[dict]:
    """
    Summary of currently active spoilage alerts.
    One spoiled basket = one active alert.
    """
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(
            """
            SELECT
                CAST(p.basket_id AS CHAR) AS batch_id,
                COALESCE(b.fruit_type, 'Unknown') AS fruit_type,
                1 AS total,
                1 AS unacknowledged,
                1 AS critical_count,
                0 AS warning_count,
                p.predicted_at AS latest_alert
            FROM prediction p
            LEFT JOIN basket b
                ON b.basket_id = p.basket_id
            WHERE p.pred_id = (
                SELECT p2.pred_id
                FROM prediction p2
                WHERE p2.basket_id = p.basket_id
                ORDER BY p2.predicted_at DESC, p2.pred_id DESC
                LIMIT 1
            )
            AND p.spoil_stage = 1
            ORDER BY p.predicted_at DESC, p.pred_id DESC
            """
        )

        result = []
        for row in cursor.fetchall():
            d = dict(row)
            if d.get("latest_alert"):
                d["latest_alert"] = d["latest_alert"].strftime("%Y-%m-%d %H:%M:%S")
            result.append(d)
        return result
    finally:
        cursor.close()


def get_unacknowledged_count(db: MySQLConnection) -> int:
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(
            """
            SELECT COUNT(*) AS cnt
            FROM prediction p
            WHERE p.pred_id = (
                SELECT p2.pred_id
                FROM prediction p2
                WHERE p2.basket_id = p.basket_id
                ORDER BY p2.predicted_at DESC, p2.pred_id DESC
                LIMIT 1
            )
            AND p.spoil_stage = 1
            """
        )
        return int(cursor.fetchone()["cnt"])
    finally:
        cursor.close()


# ── Acknowledgment disabled for live prediction alerts ───────────────────────

async def acknowledge_alert(
    db: MySQLConnection,
    alert_id: int,
    ack_by: str,
) -> Optional[dict]:
    """
    Live spoilage alerts should disappear only when the latest prediction
    becomes fresh again, so manual acknowledge is not used.
    """
    return {"alert_id": alert_id, "already": True}


async def acknowledge_batch_alerts(
    db: MySQLConnection,
    batch_id: str,
    ack_by: str,
) -> int:
    return 0


def reset_acknowledgment(db: MySQLConnection, alert_id: int) -> None:
    return None
