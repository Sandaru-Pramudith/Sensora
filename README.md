# 🌿 Sensora — Intelligent Environmental Monitoring & Spoilage Prediction

![Flutter](https://img.shields.io/badge/Flutter-Framework-02569B?style=flat-square&logo=flutter)
![FastAPI](https://img.shields.io/badge/FastAPI-Backend-009688?style=flat-square&logo=fastapi)
![Scikit-learn](https://img.shields.io/badge/Scikit--learn-ML-F7931E?style=flat-square&logo=scikit-learn)
![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub_Actions-2088FF?style=flat-square&logo=github-actions)
![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)

> A full-stack IoT & Machine Learning system for real-time environmental monitoring and predictive shelf-life analytics — built for supermarkets and warehouses to minimize spoilage, improve inventory efficiency, and enable data-driven decisions.

---

## 📸 Interface Preview

| Dashboard | All Baskets |
|-----------|-------------|
| ![Dashboard](screenshots/dashboard.png) | ![All Baskets](screenshots/all_baskets.png) |

| Batch Status | Batch Analysis | Sensor Analytics |
|---|---|---|
| ![Batch Status](screenshots/batch_status.png) | ![Batch Analysis](screenshots/batch_analysis.png) | ![Analytics](screenshots/analytics.png) |

<details>
<summary>📱 Category View (Baskets Overview)</summary>

![Baskets Overview](screenshots/baskets_overview.png)

</details>

---

## 🚀 Key Components

### 📱 Frontend — Flutter / Dart

A cross-platform mobile application that provides:

- Real-time environmental monitoring dashboard
- Interactive line charts:
  - Temperature Trends
  - Air Safety Index (AQI)
  - VOC / Gas Emissions
- Basket health status (Fresh / Spoiled / Empty)
- Instant spoilage alerts for proactive decision-making

### ⚙️ Backend — FastAPI / Python

A high-performance RESTful API responsible for:

- User authentication (Admin & Staff roles)
- Database operations and management
- Processing and serving sensor data to the frontend

### 🧠 Machine Learning — Predictive Analytics

An intelligent prediction engine that:

- Uses **Random Forest Regressors**
- Estimates **Batch Lifetime / Shelf Life** (in hours)
- Enables proactive inventory and waste reduction decisions

---

## 🔄 Supermarket Setup Pipeline

```
STAGE_01 → Environment Setup & Sensor Activation
           Power on ESP32 nodes, connect to WiFi, calibrate
           Temperature / Humidity / CO₂ / VOC sensors.

STAGE_02 → Batch Registration & Tracking
           Register fruit type, arrival time, and storage
           location. Assign sensor-to-batch mappings.

STAGE_03 → Prediction & Monitoring Activation
           Feed sensor data into ML model. Activate dashboard
           alerts for overripe / spoilage risk / discard.
```

---

## 🛠️ System Architecture

```
ESP32 Sensors  →  SQL Database  →  FastAPI Backend  →  Flutter App
(Temp/Humidity     (Persistent       (Auth + API +        (Dashboard +
  VOC / AQI)        sensor logs)      ML inference)        Charts + Alerts)
```

### 📡 Data Acquisition

Captures key environmental metrics:

- Temperature (°C)
- Humidity (%)
- Air Quality Index (AQI)
- Volatile Organic Compounds — VOC (ppb)

---

## 📦 Tech Stack

| Layer | Technologies |
|-------|-------------|
| 📱 Mobile | Flutter, Dart, fl_chart |
| ⚙️ Backend | Python, FastAPI, SQLAlchemy |
| 🗄️ Database | SQL |
| 🧠 ML / Data Science | Scikit-learn, Pandas, NumPy, Pickle |
| 🔄 DevOps | GitHub Actions, Jest, Python Unittest, venv |

---

## ⚡ Quick Start

```bash
# Clone the repository
git clone https://github.com/your-org/sensora.git

# Backend setup
cd backend
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload

# Flutter frontend
cd mobile
flutter pub get
flutter run
```

> **Note:** Large trained ML models are stored locally and excluded from version control.  
> Directory: `backend/ml_reporting/models/`  
> Includes: Random Forest Regressors, hourly shelf-life prediction models.

---

## 🔐 Security

- Role-based authentication system (Admin & Staff)
- Secure access control for sensitive warehouse analytics data
- Protected API endpoints for all prediction and monitoring routes

---

## 🔬 CI/CD & Automation

- CI/CD pipelines powered by **GitHub Actions**
- Automated testing:
  - **Frontend**: Jest
  - **Backend**: Python Unittest
- Streamlined deployment process

---

## ⚡ Future Improvements

- [ ] Integration with physical IoT hardware devices
- [ ] Advanced anomaly detection models
- [ ] Cloud deployment (AWS / GCP)
- [ ] Real-time streaming with WebSockets

---

## 🎯 Project Goal

Sensora aims to transform traditional warehouse management into a data-driven, predictive system that:

- **Minimizes spoilage** through early detection
- **Improves inventory efficiency** with real-time tracking
- **Enhances decision-making** with ML-powered insights

---

> *Sensora is not just a monitoring system — it's a **predictive intelligence platform** that bridges IoT, Machine Learning, and modern software architecture to solve real-world supply chain challenges.*

