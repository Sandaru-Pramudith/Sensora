import sys
import os
import pytest
from fastapi.testclient import TestClient

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from ml_reporting.main import app


@pytest.fixture
def client():
    return TestClient(app)


def test_ingest_skips_invalid_baskets(client):
    payload = {
        "device_id": "esp32_01",
        "baskets": [
            {
                "id": 1,
                "valid": True,
                "temp": 30.5,
                "hum": 50.2,
                "eco2": 500,
                "tvoc": 100,
                "aqi": 20,
                "mq_raw": 1.0,
                "mq_volts": 0.5
            },
            {
                "id": 2,
                "valid": False,
                "temp": 31.0,
                "hum": 51.0,
                "eco2": 520,
                "tvoc": 110,
                "aqi": 21,
                "mq_raw": 1.1,
                "mq_volts": 0.6
            }
        ]
    }

    response = client.post("/data", json=payload)

    assert response.status_code == 200
    assert response.json()["rows_added"] == 1
    assert response.json()["ok"] is True