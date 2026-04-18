from typing import Generator
import threading
import mysql.connector
from mysql.connector.connection import MySQLConnection
from ..core.config import settings


_schema_checked = False
_schema_lock = threading.Lock()


def _ensure_alerting_schema(db: MySQLConnection) -> None:
    """Create/upgrade alerting tables needed by alert and notification services."""
    cursor = db.cursor()
    try:
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS notifications (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                notification_type VARCHAR(50) NOT NULL DEFAULT 'system',
                title VARCHAR(255) NOT NULL,
                message TEXT NOT NULL,
                severity ENUM('info', 'warning', 'critical') NOT NULL DEFAULT 'info',
                related_id INT NULL,
                is_read TINYINT(1) NOT NULL DEFAULT 0,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                read_at TIMESTAMP NULL,
                INDEX idx_notifications_created_at (created_at),
                INDEX idx_notifications_is_read (is_read)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """
        )

        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS alerts (
                id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
                batch_id VARCHAR(50) NOT NULL,
                fruit_type VARCHAR(50) NOT NULL,
                alert_type VARCHAR(50) NOT NULL,
                message TEXT NOT NULL,
                severity ENUM('warning', 'critical') NOT NULL,
                value FLOAT NOT NULL,
                threshold FLOAT NOT NULL,
                acknowledged TINYINT(1) NOT NULL DEFAULT 0,
                acknowledged_by VARCHAR(100) NULL,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                acknowledged_at TIMESTAMP NULL,
                INDEX idx_alerts_batch_created (batch_id, created_at),
                INDEX idx_alerts_ack (acknowledged),
                INDEX idx_alerts_severity (severity)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """
        )

        cursor.execute("SHOW COLUMNS FROM alerts")
        existing = {row[0] for row in cursor.fetchall()}

        alter_statements = []
        if "batch_id" not in existing:
            alter_statements.append("ADD COLUMN batch_id VARCHAR(50) NOT NULL DEFAULT ''")
        if "alert_type" not in existing:
            alter_statements.append("ADD COLUMN alert_type VARCHAR(50) NOT NULL DEFAULT 'system'")
        if "message" not in existing:
            alter_statements.append("ADD COLUMN message TEXT NULL")
        if "severity" not in existing:
            alter_statements.append(
                "ADD COLUMN severity ENUM('warning', 'critical') NOT NULL DEFAULT 'warning'"
            )
        if "value" not in existing:
            alter_statements.append("ADD COLUMN value FLOAT NOT NULL DEFAULT 0")
        if "threshold" not in existing:
            alter_statements.append("ADD COLUMN threshold FLOAT NOT NULL DEFAULT 0")
        if "acknowledged" not in existing:
            alter_statements.append("ADD COLUMN acknowledged TINYINT(1) NOT NULL DEFAULT 0")
        if "acknowledged_by" not in existing:
            alter_statements.append("ADD COLUMN acknowledged_by VARCHAR(100) NULL")
        if "created_at" not in existing:
            alter_statements.append("ADD COLUMN created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP")
        if "acknowledged_at" not in existing:
            alter_statements.append("ADD COLUMN acknowledged_at TIMESTAMP NULL")

        for stmt in alter_statements:
            cursor.execute(f"ALTER TABLE alerts {stmt}")

        db.commit()
    finally:
        cursor.close()


def _connect() -> MySQLConnection:
    db = mysql.connector.connect(
        host=settings.db_host,
        user=settings.db_user,
        password=settings.db_password,
        database=settings.db_name,
        port=settings.db_port,
    )

    global _schema_checked
    if not _schema_checked:
        with _schema_lock:
            if not _schema_checked:
                _ensure_alerting_schema(db)
                _schema_checked = True

    return db


def get_db() -> Generator[MySQLConnection, None, None]:
    """
    FastAPI dependency — yields a MySQL connection and guarantees it is closed
    after the request, even if an exception is raised.

    Usage in a router:
        @router.get("/example")
        async def example(db: MySQLConnection = Depends(get_db)):
            ...
    """
    db = _connect()
    try:
        yield db
    finally:
        db.close()
