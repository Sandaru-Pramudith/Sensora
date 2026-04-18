"""
SQLAlchemy database models for Sensora API - fixed MySQL types
"""

from datetime import datetime
from .extensions import db
from sqlalchemy.dialects.mysql import INTEGER, BIGINT
from sqlalchemy import Enum



# USER MODEL

class User(db.Model):
    __tablename__ = "users"

    id = db.Column(INTEGER(unsigned=True), primary_key=True, autoincrement=True)
    full_name = db.Column(db.String(150), nullable=False)
    email = db.Column(db.String(150), nullable=False, unique=True)
    mobile_number = db.Column(db.String(20), nullable=False, unique=True)
    date_of_birth = db.Column(db.Date, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(
        Enum("admin", "operator", "viewer", name="role_enum"),
        nullable=False,
        default="viewer"
    )
    is_active = db.Column(db.Boolean, nullable=False, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_login = db.Column(db.DateTime, nullable=True)

    baskets_created = db.relationship("Basket", backref="creator", lazy=True)

    def to_dict(self):
        return {
            "id": self.id,
            "full_name": self.full_name,
            "email": self.email,
            "mobile_number": self.mobile_number,
            "date_of_birth": self.date_of_birth.isoformat() if self.date_of_birth else None,
            "role": self.role,
            "is_active": bool(self.is_active),
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "last_login": self.last_login.isoformat() if self.last_login else None,
        }



# DEVICE MODEL

class Device(db.Model):
    __tablename__ = "device"

    device_id = db.Column(db.String(50), primary_key=True)
    wifi_ssid = db.Column(db.String(64), nullable=True)
    is_active = db.Column(db.Boolean, nullable=False, default=True)

    baskets = db.relationship("Basket", backref="device", lazy=True)
    sensor_readings = db.relationship("SensorReading", backref="device", lazy=True)
    predictions = db.relationship("Prediction", backref="device", lazy=True)

    def to_dict(self):
        return {
            "device_id": self.device_id,
            "wifi_ssid": self.wifi_ssid,
            "is_active": bool(self.is_active),
        }



# BASKET MODEL

class Basket(db.Model):
    __tablename__ = "basket"

    basket_id = db.Column(INTEGER(unsigned=True), primary_key=True, autoincrement=True)
    device_id = db.Column(db.String(50), db.ForeignKey("device.device_id"), nullable=False)
    location = db.Column(db.String(100), nullable=False, default="Main Isle")
    fruit_type = db.Column(db.String(50), nullable=False, default="Bananna")
    created_by = db.Column(INTEGER(unsigned=True), db.ForeignKey("users.id"), nullable=True)

    sensor_readings = db.relationship("SensorReading", backref="basket", lazy=True)
    predictions = db.relationship("Prediction", backref="basket", lazy=True)

    def to_dict(self):
        return {
            "basket_id": self.basket_id,
            "device_id": self.device_id,
            "location": self.location,
            "fruit_type": self.fruit_type,
            "created_by": self.created_by,
        }



# SENSOR READING MODEL

class SensorReading(db.Model):
    __tablename__ = "sensor_reading"

    read_id = db.Column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    device_id = db.Column(db.String(50), db.ForeignKey("device.device_id"), nullable=False)
    basket_id = db.Column(INTEGER(unsigned=True), db.ForeignKey("basket.basket_id"), nullable=False)

    temp = db.Column(db.Float, nullable=False)
    hum = db.Column(db.Float, nullable=False)
    eco2 = db.Column(db.Float, nullable=False)
    tvoc = db.Column(db.Float, nullable=False)
    aqi = db.Column(db.Float, nullable=False)
    mq_raw = db.Column(db.Float, nullable=False)
    mq_volts = db.Column(db.Float, nullable=False)

    recorded_at = db.Column(db.DateTime, default=datetime.utcnow)

    predictions = db.relationship("Prediction", backref="sensor_reading", lazy=True)

    def to_dict(self):
        return {
            "read_id": self.read_id,
            "device_id": self.device_id,
            "basket_id": self.basket_id,
            "temp": self.temp,
            "hum": self.hum,
            "eco2": self.eco2,
            "tvoc": self.tvoc,
            "aqi": self.aqi,
            "mq_raw": self.mq_raw,
            "mq_volts": self.mq_volts,
            "recorded_at": self.recorded_at.isoformat() if self.recorded_at else None,
        }



# PREDICTION MODEL

class Prediction(db.Model):
    __tablename__ = "prediction"

    pred_id = db.Column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    read_id = db.Column(BIGINT(unsigned=True), db.ForeignKey("sensor_reading.read_id"), nullable=False)
    basket_id = db.Column(INTEGER(unsigned=True), db.ForeignKey("basket.basket_id"), nullable=False)
    device_id = db.Column(db.String(50), db.ForeignKey("device.device_id"), nullable=False)

    spoil_stage = db.Column(db.Boolean, nullable=False)
    hours_left = db.Column(db.Float, nullable=True)
    predicted_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "pred_id": self.pred_id,
            "read_id": self.read_id,
            "basket_id": self.basket_id,
            "device_id": self.device_id,
            "spoil_stage": self.spoil_stage,
            "hours_left": self.hours_left,
            "predicted_at": self.predicted_at.isoformat() if self.predicted_at else None,
        }