import os
from pathlib import Path
import joblib
import gdown

BASE_DIR = Path(__file__).resolve().parent
MODELS_DIR = BASE_DIR / "models_downloaded"
MODELS_DIR.mkdir(parents=True, exist_ok=True)

CLS_DIR = MODELS_DIR / "Logistic_regression_Classifier"
REG_DIR = MODELS_DIR / "Random_forest_Regressor"
CLS_DIR.mkdir(parents=True, exist_ok=True)
REG_DIR.mkdir(parents=True, exist_ok=True)


MODEL_FILES = {
    "status_model": {
        "url": os.getenv("STATUS_MODEL_URL"),
        "path": CLS_DIR / "current_status_lr_without_mq.pkl",
    },
    "status_scaler": {
        "url": os.getenv("STATUS_SCALER_URL"),
        "path": CLS_DIR / "current_status_scaler_without_mq.pkl",
    },
    "status_threshold": {
        "url": os.getenv("STATUS_THRESHOLD_URL"),
        "path": CLS_DIR / "current_status_threshold_without_mq.pkl",
    },
    "hours_model": {
        "url": os.getenv("HOURS_MODEL_URL"),
        "path": REG_DIR / "hours_remaining_rf_without_mq.pkl",
    },
}


def download_if_missing(url: str, destination: Path) -> None:
    if destination.exists():
        print(f"[MODEL] Already exists: {destination}")
        return

    if not url:
        raise RuntimeError(f"Missing download URL for {destination.name}")

    print(f"[MODEL] Downloading {destination.name}...")
    gdown.download(url=url, output=str(destination), quiet=False, fuzzy=True)

    if not destination.exists():
        raise RuntimeError(f"Download failed for {destination.name}")

    print(f"[MODEL] Download completed: {destination.name}")


def ensure_models_downloaded() -> None:
    for item in MODEL_FILES.values():
        download_if_missing(item["url"], item["path"])


def load_models():
    ensure_models_downloaded()

    status_model = joblib.load(MODEL_FILES["status_model"]["path"])
    status_scaler = joblib.load(MODEL_FILES["status_scaler"]["path"])
    status_threshold = joblib.load(MODEL_FILES["status_threshold"]["path"])
    hours_model = joblib.load(MODEL_FILES["hours_model"]["path"])

    return status_model, status_scaler, status_threshold, hours_model