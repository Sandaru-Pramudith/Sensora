import sys
import os
import pandas as pd

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from ml_reporting.predict import build_feature_row


def test_build_feature_row_returns_correct_means():
    df = pd.DataFrame([
        {"temp": 30, "hum": 50, "eco2": 100, "tvoc": 20, "aqi": 5},
        {"temp": 34, "hum": 54, "eco2": 200, "tvoc": 40, "aqi": 15},
    ])

    result = build_feature_row(df)

    assert result.iloc[0]["temp"] == 32.0
    assert result.iloc[0]["hum"] == 52.0
    assert result.iloc[0]["eco2"] == 150.0
    assert result.iloc[0]["tvoc"] == 30.0
    assert result.iloc[0]["aqi"] == 10.0