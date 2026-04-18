import sys
import os
import pandas as pd

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from ml_reporting.predict import predict_from_last_10min_rows


def test_ml_prediction_returns_valid_output():
    df = pd.DataFrame([
        {"temp": 30.0, "hum": 50.0, "eco2": 500, "tvoc": 100, "aqi": 20},
        {"temp": 31.0, "hum": 51.0, "eco2": 510, "tvoc": 105, "aqi": 21},
        {"temp": 32.0, "hum": 52.0, "eco2": 520, "tvoc": 110, "aqi": 22},
    ])

    result = predict_from_last_10min_rows(df)

    assert "spoil_stage" in result
    assert "spoil_probability" in result
    assert "pred_fraction" in result
    assert "hours_left" in result

    assert isinstance(result["spoil_stage"], (bool, int))
    assert 0.0 <= result["spoil_probability"] <= 1.0
    assert 0.0 <= result["pred_fraction"] <= 1.0
    assert result["hours_left"] >= 0
    