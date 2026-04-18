import numpy as np
import pandas as pd
from .config import ESTIMATED_TOTAL_HOURS
from .model_loader import load_models

status_model, status_scaler, status_threshold, hours_model = load_models()

REG_FEATURES = [
    "temp",
    "hum",
    "eco2",
    "tvoc",
    "aqi",
]

CLS_FEATURES = [
    "temp",
    "hum",
    "eco2",
    "tvoc",
    "aqi",
]


def safe_std(series: pd.Series) -> float:
    if len(series) <= 1:
        return 0.0
    value = float(series.std(ddof=0))
    if np.isnan(value):
        return 0.0
    return value


def build_feature_row(df: pd.DataFrame) -> pd.DataFrame:
    if df.empty:
        raise ValueError("No sensor rows found")

    feature_row = {
        "temp": float(df["temp"].mean()),
        "hum": float(df["hum"].mean()),
        "eco2": float(df["eco2"].mean()),
        "tvoc": float(df["tvoc"].mean()),
        "aqi": float(df["aqi"].mean()),
    }

    return pd.DataFrame([feature_row])


def predict_from_last_10min_rows(df: pd.DataFrame) -> dict:
    feature_df = build_feature_row(df)

    x_cls = feature_df[CLS_FEATURES]
    x_cls_scaled = status_scaler.transform(x_cls)
    spoil_prob = float(status_model.predict_proba(x_cls_scaled)[:, 1][0])
    spoil_stage = int(spoil_prob >= status_threshold)

    x_reg = feature_df[REG_FEATURES]
    pred_frac = float(hours_model.predict(x_reg)[0])
    pred_frac = max(0.0, min(1.0, pred_frac))
    hours_left = float(pred_frac * ESTIMATED_TOTAL_HOURS)

    return {
        "spoil_stage": spoil_stage,
        "spoil_probability": spoil_prob,
        "pred_fraction": pred_frac,
        "hours_left": hours_left,
    }
