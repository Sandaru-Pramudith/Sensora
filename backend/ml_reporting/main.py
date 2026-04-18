from fastapi import FastAPI, Depends, HTTPException
import requests
from pydantic import BaseModel
from typing import List
from . import models
from .database import engine, SessionLocal
from sqlalchemy.orm import Session
from datetime import datetime
from fastapi.middleware.cors import CORSMiddleware
import traceback

from sqlalchemy import text
import pandas as pd
from .predict import predict_from_last_10min_rows
from .config import ESTIMATED_TOTAL_HOURS

from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.interval import IntervalTrigger

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

ESP32_URL = "http://192.168.1.8/data"

AUTO_CREATE_TABLES = False

if AUTO_CREATE_TABLES:
    models.Base.metadata.create_all(bind=engine)


@app.get("/fetch")
def data_reading():
    r = requests.get(ESP32_URL, timeout=20)
    r.raise_for_status()
    return r.json()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


class BasketIn(BaseModel):
    id: int
    valid: bool
    temp: float
    hum: float
    eco2: float
    tvoc: float
    aqi: float
    mq_raw: float
    mq_volts: float
    fruit_type: str | None = None
    location: str | None = None


class PayloadIn(BaseModel):
    device_id: str
    baskets: List[BasketIn]


@app.post("/data")
def ingest(payload: PayloadIn, db: Session = Depends(get_db)):
    try:
        now = datetime.now()

        device = db.query(models.Device).filter(
            models.Device.device_id == payload.device_id
        ).first()

        if device is None:
            device = models.Device(
                device_id=payload.device_id,
                wifi_ssid="SLT-Fiber-2.4G",
                is_active=True
            )
            db.add(device)
            db.commit()
            db.refresh(device)

        rows_added = 0

        for b in payload.baskets:
            if not b.valid:
                continue

            basket = db.query(models.Basket).filter(
                models.Basket.device_id == device.device_id,
                models.Basket.location == f"Basket {b.id}"
            ).first()

            if basket is None:
                basket = models.Basket(
                    device_id=device.device_id,
                    location=(b.location or f"Basket {b.id}"),
                    fruit_type=(b.fruit_type or "Banana")
                )
                db.add(basket)
                db.commit()
                db.refresh(basket)
            else:
                if b.location:
                    basket.location = b.location
                if b.fruit_type:
                    basket.fruit_type = b.fruit_type

            reading = models.SensorReading(
                device_id=device.device_id,
                basket_id=basket.basket_id,
                temp=b.temp,
                hum=b.hum,
                eco2=b.eco2,
                tvoc=b.tvoc,
                aqi=b.aqi,
                mq_raw=b.mq_raw,
                mq_volts=b.mq_volts,
                recorded_at=now
            )

            db.add(reading)
            rows_added += 1

        db.commit()
        return {
            "ok": True,
            "device_id": payload.device_id,
            "rows_added": rows_added
        }

    except Exception as e:
        db.rollback()
        print("ERROR IN /data:")
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/predict/basket/{basket_id}")
def predict_one_basket(basket_id: int, db: Session = Depends(get_db)):
    rows = db.execute(text("""
        SELECT
            read_id,
            basket_id,
            device_id,
            recorded_at,
            temp,
            hum,
            eco2,
            tvoc,
            aqi,
            mq_raw,
            mq_volts
        FROM sensor_reading
        WHERE basket_id = :basket_id
          AND recorded_at >= NOW() - INTERVAL 10 MINUTE
        ORDER BY recorded_at ASC
    """), {"basket_id": basket_id}).mappings().all()

    if not rows:
        raise HTTPException(status_code=404, detail="No readings found for this basket in the last 10 minutes")

    df = pd.DataFrame(rows)
    pred = predict_from_last_10min_rows(df)

    last_read_id = int(df["read_id"].iloc[-1])
    device_id = rows[0]["device_id"]

    prediction_row = models.Prediction(
        read_id=last_read_id,
        basket_id=basket_id,
        device_id=device_id,
        spoil_stage=pred["spoil_stage"],
        hours_left=0 if pred["spoil_stage"] else pred["hours_left"]
    )
    db.add(prediction_row)
    db.commit()
    db.refresh(prediction_row)

    return {
        "basket_id": basket_id,
        "device_id": device_id,
        "reading_count": len(rows),
        **pred
    }


def run_predictions_for_all_baskets():
    db = SessionLocal()
    try:
        basket_rows = db.execute(text("""
            SELECT DISTINCT basket_id, device_id
            FROM sensor_reading
            WHERE recorded_at >= NOW() - INTERVAL 10 MINUTE
            ORDER BY basket_id
        """)).mappings().all()

        if not basket_rows:
            print("[SCHEDULER] No basket readings found in last 10 minutes")
            return

        for basket in basket_rows:
            basket_id = basket["basket_id"]
            device_id = basket["device_id"]

            rows = db.execute(text("""
                SELECT
                    read_id,
                    basket_id,
                    device_id,
                    recorded_at,
                    temp,
                    hum,
                    eco2,
                    tvoc,
                    aqi,
                    mq_raw,
                    mq_volts
                FROM sensor_reading
                WHERE basket_id = :basket_id
                  AND recorded_at >= NOW() - INTERVAL 10 MINUTE
                ORDER BY recorded_at ASC
            """), {"basket_id": basket_id}).mappings().all()

            if not rows:
                continue

            df = pd.DataFrame(rows)

            try:
                pred = predict_from_last_10min_rows(df)
                last_read_id = int(df["read_id"].iloc[-1])

                existing = db.query(models.Prediction).filter(
                    models.Prediction.read_id == last_read_id,
                    models.Prediction.basket_id == basket_id
                ).first()

                if existing:
                    print(f"[SCHEDULER] Prediction already exists for basket {basket_id}, read_id {last_read_id}")
                    continue

                prediction_row = models.Prediction(
                    read_id=last_read_id,
                    basket_id=basket_id,
                    device_id=device_id,
                    spoil_stage=pred["spoil_stage"],
                    hours_left=0 if pred["spoil_stage"] else pred["hours_left"]
                )

                db.add(prediction_row)

                print(
                    f"[SCHEDULER] Basket {basket_id} | "
                    f"spoil_stage={pred['spoil_stage']} | "
                    f"spoil_probability={pred['spoil_probability']:.4f} | "
                    f"pred_fraction={pred['pred_fraction']:.4f} | "
                    f"hours_left={pred['hours_left']:.2f}"
                )

            except Exception as e:
                print(f"[SCHEDULER] Prediction failed for basket {basket_id}: {e}")

        db.commit()

    except Exception:
        db.rollback()
        print("[SCHEDULER] ERROR:")
        traceback.print_exc()

    finally:
        db.close()


@app.get("/predict/all-baskets")
def predict_all_baskets(db: Session = Depends(get_db)):
    basket_rows = db.execute(text("""
        SELECT DISTINCT basket_id, device_id
        FROM sensor_reading
        WHERE recorded_at >= NOW() - INTERVAL 10 MINUTE
        ORDER BY basket_id
    """)).mappings().all()

    if not basket_rows:
        raise HTTPException(
            status_code=404,
            detail="No basket readings found in the last 10 minutes"
        )

    results = []

    for basket in basket_rows:
        basket_id = basket["basket_id"]
        device_id = basket["device_id"]

        try:
            rows = db.execute(text("""
                SELECT
                    read_id,
                    basket_id,
                    device_id,
                    recorded_at,
                    temp,
                    hum,
                    eco2,
                    tvoc,
                    aqi,
                    mq_raw,
                    mq_volts
                FROM sensor_reading
                WHERE basket_id = :basket_id
                  AND device_id = :device_id
                  AND recorded_at >= NOW() - INTERVAL 10 MINUTE
                ORDER BY recorded_at ASC
            """), {
                "basket_id": basket_id,
                "device_id": device_id
            }).mappings().all()

            if not rows:
                results.append({
                    "basket_id": basket_id,
                    "device_id": device_id,
                    "reading_count": 0,
                    "error": "No rows found for this basket/device in last 10 minutes"
                })
                continue

            df = pd.DataFrame(rows)

            if len(df) < 2:
                results.append({
                    "basket_id": basket_id,
                    "device_id": device_id,
                    "reading_count": len(rows),
                    "error": "Not enough readings for prediction"
                })
                continue

            pred = predict_from_last_10min_rows(df)
            last_read_id = int(df["read_id"].iloc[-1])

            existing_prediction = db.execute(text("""
                SELECT prediction_id
                FROM prediction
                WHERE read_id = :read_id
                LIMIT 1
            """), {"read_id": last_read_id}).fetchone()

            if not existing_prediction:
                prediction_row = models.Prediction(
                    read_id=last_read_id,
                    basket_id=basket_id,
                    device_id=device_id,
                    spoil_stage=pred["spoil_stage"],
                    hours_left=0 if pred["spoil_stage"] else pred["hours_left"]
                )
                db.add(prediction_row)

            results.append({
                "basket_id": basket_id,
                "device_id": device_id,
                "reading_count": len(rows),
                **pred
            })

        except Exception as e:
            db.rollback()
            results.append({
                "basket_id": basket_id,
                "device_id": device_id,
                "reading_count": len(rows) if 'rows' in locals() else 0,
                "error": str(e)
            })

    db.commit()
    return {"predictions": results}


scheduler = BackgroundScheduler()


@app.on_event("startup")
def start_scheduler():
    if not scheduler.running:
        scheduler.add_job(
            run_predictions_for_all_baskets,
            IntervalTrigger(minutes=10),
            id="predict_every_10_min",
            replace_existing=True
        )
        scheduler.start()
        print("[SCHEDULER] Started: prediction every 10 minutes")


@app.on_event("shutdown")
def stop_scheduler():
    if scheduler.running:
        scheduler.shutdown()
        print("[SCHEDULER] Stopped")


@app.get("/reports/basket/{basket_id}")
def get_basket_report(basket_id: int, db: Session = Depends(get_db)):
    basket = db.query(models.Basket).filter(models.Basket.basket_id == basket_id).first()

    if not basket:
        raise HTTPException(status_code=404, detail="Basket not found")

    latest_prediction = (
        db.query(models.Prediction)
        .filter(models.Prediction.basket_id == basket_id)
        .order_by(models.Prediction.predicted_at.desc(), models.Prediction.pred_id.desc())
        .first()
    )

    latest_sensor = (
        db.query(models.SensorReading)
        .filter(models.SensorReading.basket_id == basket_id)
        .order_by(models.SensorReading.recorded_at.desc(), models.SensorReading.read_id.desc())
        .limit(100)
        .all()
    )

    if not latest_sensor:
        raise HTTPException(status_code=404, detail="No sensor readings found")

    condition = "Unknown"
    status = "fresh"
    spoil_stage = None
    hours_left = None
    lifetime_percentage = None
    remaining_life_percentage = None
    predicted_at = None

    if latest_prediction:
        spoil_stage = bool(latest_prediction.spoil_stage)
        predicted_at = latest_prediction.predicted_at

        latest_row = latest_sensor[0]
        latest_tvoc = latest_row.tvoc if latest_row.tvoc is not None else None

        if spoil_stage:
            hours_left = 0
            condition = "Spoilage Detected"
            status = "spoiled"
        elif latest_tvoc is not None and latest_tvoc < 10:
            hours_left = None
            condition = "Empty Basket"
            status = "not_available"
        else:
            hours_left = latest_prediction.hours_left
            condition = "Fresh"
            status = "fresh"

        if hours_left is not None:
            lifetime_percentage = ((ESTIMATED_TOTAL_HOURS - hours_left) / ESTIMATED_TOTAL_HOURS) * 100
            remaining_life_percentage = (hours_left / ESTIMATED_TOTAL_HOURS) * 100
        else:
            lifetime_percentage = None
            remaining_life_percentage = None

    return {
        "basket": {
            "basket_id": basket.basket_id,
            "device_id": basket.device_id,
            "location": basket.location,
            "fruit_type": basket.fruit_type
        },
        "prediction": {
            "spoil_stage": spoil_stage,
            "condition": condition,
            "status": status,
            "lifetime_percentage": lifetime_percentage,
            "remaining_life_percentage": remaining_life_percentage,
            "hours_left": hours_left,
            "predicted_at": predicted_at
        },
        "sensor_readings": [
            {
                "read_id": row.read_id,
                "temp": row.temp,
                "hum": row.hum,
                "eco2": row.eco2,
                "tvoc": row.tvoc,
                "aqi": row.aqi,
                "mq_raw": row.mq_raw,
                "mq_volts": row.mq_volts,
                "recorded_at": row.recorded_at
            }
            for row in latest_sensor
        ]
    }


@app.get("/reports/baskets")
def get_all_baskets(db: Session = Depends(get_db)):
    baskets = db.query(models.Basket).all()
    results = []

    for b in baskets:
        latest_prediction = (
            db.query(models.Prediction)
            .filter(models.Prediction.basket_id == b.basket_id)
            .order_by(models.Prediction.predicted_at.desc(), models.Prediction.pred_id.desc())
            .first()
        )

        latest_sensor = (
            db.query(models.SensorReading)
            .filter(models.SensorReading.basket_id == b.basket_id)
            .order_by(models.SensorReading.recorded_at.desc(), models.SensorReading.read_id.desc())
            .first()
        )

        latest_tvoc = latest_sensor.tvoc if latest_sensor and latest_sensor.tvoc is not None else None

        status = "fresh"
        spoil_stage = None
        hours_left = None
        lifetime_percentage = None
        remaining_life_percentage = None

        if latest_prediction:
            spoil_stage = bool(latest_prediction.spoil_stage)

            if spoil_stage:
                status = "spoiled"
                hours_left = 0
            elif latest_tvoc is not None and latest_tvoc < 10:
                status = "not_available"
                hours_left = None
            else:
                status = "fresh"
                hours_left = latest_prediction.hours_left

            if hours_left is not None:
                lifetime_percentage = ((ESTIMATED_TOTAL_HOURS - hours_left) / ESTIMATED_TOTAL_HOURS) * 100
                remaining_life_percentage = (hours_left / ESTIMATED_TOTAL_HOURS) * 100
            else:
                lifetime_percentage = None
                remaining_life_percentage = None

        results.append({
            "basket_id": b.basket_id,
            "device_id": b.device_id,
            "location": b.location,
            "fruit_type": b.fruit_type,
            "status": status,
            "spoil_stage": spoil_stage,
            "hours_left": hours_left,
            "lifetime_percentage": lifetime_percentage,
            "remaining_life_percentage": remaining_life_percentage
        })

    return results


@app.get("/reports/basket/{basket_id}/readings")
def get_basket_readings(basket_id: int, db: Session = Depends(get_db)):
    basket = db.query(models.Basket).filter(models.Basket.basket_id == basket_id).first()

    if not basket:
        raise HTTPException(status_code=404, detail="Basket not found")

    rows = (
        db.query(models.SensorReading)
        .filter(models.SensorReading.basket_id == basket_id)
        .order_by(models.SensorReading.recorded_at.desc())
        .limit(100)
        .all()
    )

    rows = list(reversed(rows))

    return {
        "basket_id": basket_id,
        "count": len(rows),
        "readings": [
            {
                "temp": r.temp,
                "hum": r.hum,
                "eco2": r.eco2,
                "tvoc": r.tvoc,
                "aqi": r.aqi,
                "mq_raw": r.mq_raw,
                "mq_volts": r.mq_volts,
                "recorded_at": r.recorded_at
            }
            for r in rows
        ]
    }


@app.get("/reports/basket/{basket_id}/predictions")
def get_prediction_history(basket_id: int, db: Session = Depends(get_db)):
    basket = db.query(models.Basket).filter(models.Basket.basket_id == basket_id).first()

    if not basket:
        raise HTTPException(status_code=404, detail="Basket not found")

    rows = (
        db.query(models.Prediction)
        .filter(models.Prediction.basket_id == basket_id)
        .order_by(models.Prediction.predicted_at.desc())
        .limit(50)
        .all()
    )

    return [
        {
            "spoil_stage": bool(r.spoil_stage),
            "hours_left": r.hours_left,
            "predicted_at": r.predicted_at
        }
        for r in rows
    ]
