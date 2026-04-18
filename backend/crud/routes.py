"""
Flask blueprint with all API routes for Sensora system
"""

from flask import Blueprint, request, jsonify
from sqlalchemy.exc import IntegrityError
from sqlalchemy import func, desc
from datetime import datetime

from .extensions import db
from .models import Basket, Device, SensorReading, Prediction
from .schemas import (
    batch_create_schema,
    batch_response_schema,
    device_assign_schema,
    sensor_reading_create_schema,
    sensor_reading_response_schema,
)
from .errors import APIError, ValidationError, ConflictError

bp = Blueprint("api", __name__, url_prefix="/api")



# UTILITY FUNCTIONS


def _norm(s: str) -> str:
    return (s or "").strip().lower()

def days_to_hours(days):
    if days is None:
        return None
    return float(days) * 24.0


def _get_unassigned_device_query():
    assigned_devices = db.session.query(Basket.device_id)
    return Device.query.filter(Device.is_active.is_(True), ~Device.device_id.in_(assigned_devices))


# BASKET CRUD OPERATIONS


@bp.route("/baskets", methods=["GET"])
def list_baskets():
    skip = request.args.get("skip", 0, type=int)
    limit = min(request.args.get("limit", 100, type=int), 1000)
    baskets = (
        Basket.query
        .order_by(Basket.basket_id.desc())
        .offset(skip)
        .limit(limit)
        .all()
    )
    return jsonify([b.to_dict() for b in baskets])


@bp.route("/baskets", methods=["POST"])
def create_basket():
    data = request.get_json(silent=True) or {}
    errors = batch_create_schema.validate(data)
    if errors:
        raise ValidationError(errors)

    device_id = data["device_id"]
    device = Device.query.filter_by(device_id=device_id).first()
    if not device:
        raise APIError("Device not found", 404)
    existing_basket = Basket.query.filter_by(device_id=device_id).first()
    if existing_basket:
        raise ConflictError("Device is already assigned to a basket")

    try:
        basket = Basket(
            location=data.get("location", "Main Isle").strip(),
            fruit_type=data.get("fruit_type", "Bananna").strip(),
            device_id=device_id,
            created_by=data.get("created_by"),
        )
        db.session.add(basket)
        db.session.commit()
        return jsonify(basket.to_dict()), 201
    except IntegrityError:
        db.session.rollback()
        raise APIError("Unable to create basket", 400)


@bp.route("/baskets/<int:basket_id>", methods=["GET"])
def get_basket(basket_id):
    basket = db.session.get(Basket, basket_id)
    if not basket:
        raise APIError("Basket not found", 404)
    return jsonify(basket.to_dict())


@bp.route("/baskets/<int:basket_id>", methods=["PUT"])
def update_basket(basket_id):
    basket = db.session.get(Basket, basket_id)
    if not basket:
        raise APIError("Basket not found", 404)
    data = request.get_json(silent=True) or {}
    if "location" in data:
        basket.location = data["location"].strip()
    if "fruit_type" in data:
        basket.fruit_type = data["fruit_type"].strip()
    if "device_id" in data:
        device_id = data["device_id"].strip()
        device = Device.query.filter_by(device_id=device_id).first()
        if not device:
            raise APIError("Device not found", 404)
        existing_basket = Basket.query.filter(
            Basket.device_id == device_id,
            Basket.basket_id != basket_id,
        ).first()
        if existing_basket:
            raise ConflictError("Device is already assigned to a basket")
        basket.device_id = device_id
    if "created_by" in data:
        basket.created_by = data["created_by"]
    try:
        db.session.commit()
        return jsonify(basket.to_dict())
    except IntegrityError:
        db.session.rollback()
        raise APIError("Unable to update basket", 400)


@bp.route("/baskets/<int:basket_id>", methods=["DELETE"])
def delete_basket(basket_id):
    confirm = request.args.get("confirm", "false").lower() == "true"
    if not confirm:
        raise APIError("Confirmation required. Pass ?confirm=true", 409)
    basket = db.session.get(Basket, basket_id)
    if not basket:
        raise APIError("Basket not found", 404)
    db.session.delete(basket)
    db.session.commit()
    return jsonify({"deleted": True, "id": basket_id})


@bp.route("/baskets/<int:basket_id>/detail", methods=["GET"])
def basket_detail(basket_id):
    basket = db.session.get(Basket, basket_id)
    if not basket:
        raise APIError("Basket not found", 404)

    device = Device.query.filter_by(device_id=basket.device_id).first()

    latest_sensor = None
    latest_pred = None

    if device:
        latest_sensor = (
            SensorReading.query
            .filter_by(device_id=device.device_id, basket_id=basket.basket_id)
            .order_by(desc(SensorReading.recorded_at), desc(SensorReading.read_id))
            .first()
        )
        latest_pred = (
            Prediction.query
            .filter_by(device_id=device.device_id, basket_id=basket.basket_id)
            .order_by(desc(Prediction.predicted_at), desc(Prediction.pred_id))
            .first()
        )

    LABEL_MAP = {"fresh": "FRESH", "spoiled": "SPOIL"}
    pred_payload = None
    if latest_pred:
        raw = latest_pred.spoil_stage
        pred_payload = {
            "predicted_label": LABEL_MAP.get("spoiled" if raw else "fresh", "SPOIL"),
            "time_remaining_hours": days_to_hours(latest_pred.hours_left),
            "predicted_at": latest_pred.predicted_at.isoformat() if latest_pred.predicted_at else None,
        }

    return jsonify({
        "basket": basket.to_dict(),
        "assigned_device": device.to_dict() if device else None,
        "latest_sensor": latest_sensor.to_dict() if latest_sensor else None,
        "latest_prediction": pred_payload,
    })



# DEVICE MANAGEMENT


@bp.route("/devices", methods=["GET"])
def list_devices():
    devices = Device.query.order_by(Device.device_id.asc()).all()
    return jsonify([d.to_dict() for d in devices])


@bp.route("/devices/available", methods=["GET"])
def available_devices():
    devices = _get_unassigned_device_query().order_by(Device.device_id.asc()).all()
    return jsonify([d.to_dict() for d in devices])


@bp.route("/baskets/<int:basket_id>/assign-device", methods=["POST"])
def assign_device(basket_id):
    
    basket = Basket.query.get(basket_id)
    if not basket:
        raise APIError("Basket not found", 404)
    data = request.get_json(silent=True) or {}
    errors = device_assign_schema.validate(data)

    if errors:
        raise ValidationError(errors)
    device_id = data.get("device_id") or data.get("device_code")

    if not device_id:
        raise APIError("Provide device_id or device_code", 400)
    device = Device.query.filter_by(device_id=device_id).first()

    if not device:
        raise APIError("Device not found", 404)
    
    if not device.is_active:
        raise ConflictError("Device is not active")

    existing_basket = Basket.query.filter(
        Basket.device_id == device_id,
        Basket.basket_id != basket_id,
    ).first()
    if existing_basket:
        raise ConflictError("Device is already assigned to a basket")

    basket.device_id = device.device_id
    db.session.commit()

    return jsonify({
        "device": device.to_dict(),
        "basket": basket.to_dict(),
    })



# SENSOR READINGS


@bp.route("/sensor-readings", methods=["GET"])
def list_sensor_readings():
    device_id = request.args.get("device_id")
    basket_id = request.args.get("basket_id")
    limit = min(request.args.get("limit", 100, type=int), 1000)

    q = SensorReading.query

    if device_id:
        q = q.filter_by(device_id=device_id)
    if basket_id:
        q = q.filter_by(basket_id=basket_id)
    rows = q.order_by(desc(SensorReading.recorded_at), desc(SensorReading.read_id)).limit(limit).all()
    
    return jsonify([r.to_dict() for r in rows])


@bp.route("/sensor-readings", methods=["POST"])
def create_sensor_reading():
    data = request.get_json(silent=True) or {}

    errors = sensor_reading_create_schema.validate(data)
    if errors:
        raise ValidationError(errors)
    device_id = data.get("device_id")
    device = Device.query.filter_by(device_id=device_id).first()
    if not device:
        raise APIError("Device not found", 404)
    
    basket_id = data.get("basket_id")
    if basket_id is None:
        latest_basket = (
            Basket.query
            .filter_by(device_id=device_id)
            .order_by(desc(Basket.basket_id))
            .first()
        )
        basket_id = latest_basket.basket_id if latest_basket else None
    if basket_id is None:
        raise APIError("basket_id is required when device is not assigned", 400)

    basket = Basket.query.get(basket_id)
    if not basket:
        raise APIError("Basket not found", 404)

    reading = SensorReading(
        device_id=device_id,
        basket_id=basket_id,
        temp=float(data["temp"]),
        hum=float(data["hum"]),
        eco2=float(data["eco2"]),
        tvoc=float(data["tvoc"]),
        aqi=float(data["aqi"]),
        mq_raw=float(data["mq_raw"]),
        mq_volts=float(data["mq_volts"]),
        recorded_at=datetime.utcnow(),
    )
    db.session.add(reading)
    db.session.commit()
    return jsonify(reading.to_dict()), 201


@bp.route("/sensor-readings/<int:read_id>", methods=["GET"])
def get_sensor_reading(read_id):
    reading = db.session.get(SensorReading, read_id)
    if not reading:

        raise APIError("Sensor reading not found", 404)
    return jsonify(reading.to_dict())



# PREDICTIONS


@bp.route("/stats/predictions/summary", methods=["GET"])
def prediction_summary():
    device_id = request.args.get("device_id")
    q = db.session.query(Prediction.spoil_stage, func.count(Prediction.pred_id))
    if device_id:

        q = q.filter(Prediction.device_id == device_id)
    rows = q.group_by(Prediction.spoil_stage).all()
    counts = {"FRESH": 0, "SPOIL": 0}
    for spoil_stage, count in rows:
        key = "SPOIL" if spoil_stage else "FRESH"
        counts[key] += int(count)
    return jsonify({

        "device_id": device_id,
        "total_predictions": counts["FRESH"] + counts["SPOIL"],
        "by_predicted_label": counts,
    })