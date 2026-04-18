import sys
import os
import pytest
from fastapi.testclient import TestClient

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from ml_reporting.main import app


@pytest.fixture
def client():
    return TestClient(app)


def test_get_basket_report_returns_expected_structure(client):
    # Use a basket ID that already exists in your database
    basket_id = 1

    response = client.get(f"/reports/basket/{basket_id}")

    assert response.status_code == 200

    body = response.json()

    assert "basket" in body
    assert "prediction" in body
    assert "sensor_readings" in body

    assert isinstance(body["sensor_readings"], list)
    assert isinstance(body["prediction"], dict)

    assert "status" in body["prediction"]
    assert "condition" in body["prediction"]
    assert "hours_left" in body["prediction"]