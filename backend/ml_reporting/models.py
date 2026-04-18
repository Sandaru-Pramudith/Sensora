from sqlalchemy import Boolean, Column, Integer, String, DateTime, Float, BigInteger, ForeignKey, text, func
from .database import Base
from sqlalchemy.orm import relationship
from datetime import datetime
from sqlalchemy.dialects.mysql import INTEGER


class Device(Base):
    __tablename__ = "device"

    device_id = Column(String(50), primary_key=True, index=True)
    wifi_ssid = Column(String(64), nullable = True)
    is_active = Column(Boolean, nullable= False, server_default=text("true"))

    baskets = relationship("Basket", back_populates="device")
    readings = relationship("SensorReading", back_populates="device")
    predictions = relationship("Prediction", back_populates="device")

class Basket(Base):
    __tablename__ = "basket"
    
    basket_id = Column(Integer, primary_key=True, autoincrement=True, index=True)
    device_id = Column(String(50), ForeignKey("device.device_id"), nullable=False, index=True)
    location = Column(String(100), nullable=False, server_default=text("'Main Isle'"))
    fruit_type = Column(String(50), nullable=False, server_default=text("'Bananna'"))

    device = relationship("Device", back_populates="baskets")
    readings = relationship("SensorReading", back_populates="basket")
    predictions = relationship("Prediction", back_populates="basket")


class SensorReading(Base):
    __tablename__ = "sensor_reading"

    read_id = Column(BigInteger, primary_key=True, autoincrement=True, index=True)
    device_id = Column(String(50), ForeignKey("device.device_id"), nullable=False, index=True)
    basket_id = Column(Integer, ForeignKey("basket.basket_id"), nullable=False, index=True)
   
    temp = Column(Float, nullable=False)
    hum = Column(Float, nullable=False)
    eco2 = Column(Float, nullable=False)
    tvoc = Column(Float, nullable=False)
    aqi = Column(Float, nullable=False)
    mq_raw = Column(Float, nullable=False)
    mq_volts = Column(Float, nullable=False)


    recorded_at = Column(DateTime, nullable=False, server_default=text("CURRENT_TIMESTAMP"))

    device = relationship("Device", back_populates="readings")
    basket = relationship("Basket", back_populates="readings")

class Prediction(Base):
    __tablename__ = "prediction"
     
    pred_id = Column(BigInteger, primary_key=True, autoincrement=True, index=True)
    read_id = Column(BigInteger, ForeignKey("sensor_reading.read_id"), nullable=False, index=True)
    basket_id = Column(Integer, ForeignKey("basket.basket_id"), nullable=False, index=True)
    device_id = Column(String(50), ForeignKey("device.device_id"), nullable=False, index=True)
    spoil_stage = Column(Boolean, nullable=False)
    hours_left = Column(Float, nullable=True)

    predicted_at = Column(DateTime, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    
    device = relationship("Device", back_populates="predictions")
    basket = relationship("Basket", back_populates="predictions")

from sqlalchemy.dialects.mysql import INTEGER

class BasketReport(Base):
    __tablename__ = "basket_report"

    report_id = Column(INTEGER(unsigned=True), primary_key=True, autoincrement=True)

    basket_id = Column(
        INTEGER(unsigned=True),
        ForeignKey("basket.basket_id", ondelete="CASCADE"),
        nullable=False
    )

    avg_temp = Column(Float)
    avg_hum = Column(Float)
    max_tvoc = Column(Float)
    avg_mq_volts = Column(Float)
    status = Column(String(30))

    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now())

class BasketReportHourly(Base):
    __tablename__ = "basket_report_hourly"

    hourly_id = Column(Integer, primary_key=True, index=True)
    basket_id = Column(Integer, ForeignKey("basket.basket_id", ondelete="CASCADE"), nullable=False, index=True)
    recorded_hour = Column(DateTime, nullable=False)
    temp = Column(Float, default=0)
    hum = Column(Float, default=0)
    tvoc = Column(Float, default=0)
    mq_volts = Column(Float, default=0)
    created_at = Column(DateTime, server_default=func.now())