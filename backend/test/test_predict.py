import sys
import os

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

def test_predict_from_last_10min_rows_returns_complete_output(monkeypatch):
    
    
    import pandas as pd
    from ml_reporting import predict

    class DummyScaler:
        def transform(self, x):
            return x

    class DummyStatusModel:
        def predict_proba(self, x):
            import numpy as np
            return np.array([[0.2, 0.8]])

  
    class DummyHoursModel:
        def predict(self, x):
            return [0.5]

    monkeypatch.setattr(predict, "status_scaler", DummyScaler())
    monkeypatch.setattr(predict, "status_model", DummyStatusModel())
    monkeypatch.setattr(predict, "hours_model", DummyHoursModel())

    df = pd.DataFrame([
        {"temp": 30, "hum": 50, "eco2": 500, "tvoc": 100, "aqi": 20},
        {"temp": 32, "hum": 52, "eco2": 520, "tvoc": 110, "aqi": 21},
    ])

    result = predict.predict_from_last_10min_rows(df)

    assert "spoil_stage" in result
    assert "spoil_probability" in result
    assert "pred_fraction" in result
    assert "hours_left" in result
    assert 0.0 <= result["pred_fraction"] <= 1.0