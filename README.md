Sensora: Intelligent Environmental Monitoring & Spoilage Prediction
Sensora is a professional full-stack IoT and Machine Learning solution designed for real-time environmental monitoring and predictive analytics. The system specifically targets warehouse inventory management by tracking air quality, gas emissions, and temperature to provide scientific insights into batch health and remaining shelf life.

🚀 Key Components
Frontend (Flutter/Dart): A cross-platform mobile application providing an intuitive dashboard with interactive line charts (Temperature Trends, Air Safety Index, and VOC Emissions) and real-time spoilage alerts.

Backend (FastAPI/Python): A high-performance RESTful API that handles authentication, database management (SQL), and serves as the bridge between raw sensor data and the user interface.

Machine Learning (ML Reporting): An intelligent predictive engine using Random Forest Regressors to calculate Batch Lifetime based on sensor input, allowing for proactive inventory decisions.

🛠️ System Architecture
Data Acquisition: Captures critical environmental metrics including Temperature, AQI (Air Safety Index), and MQ Volts (VOC Emission Level).

Infrastructure: Utilizes a decoupled architecture with a centralized SQL database for data persistence and a Python Virtual Environment (venv) for isolated backend dependency management.

Automation (DevOps): Integrated with CI/CD pipelines via GitHub Actions to automate unit testing (using Jest for Frontend and Python Unittest for Backend) and deployment.

Security: Implements secure authentication mechanisms for Admin and Staff roles, ensuring protected access to sensitive warehouse analytics.

🧠 ML Model Management
To maintain repository efficiency, large trained model artifacts (such as .pkl files) are managed locally.

Directory: backend/ml_reporting/models/

Models Included: Random Forest Regressors for hourly shelf-life prediction without requiring external MQ sensor calibration.

📦 Technical Stack
Mobile: Flutter, fl_chart

Backend: Python, FastAPI, SQLAlchemy

Database: SQL 

Data Science: Scikit-learn, Pandas, NumPy, Pickle

DevOps: GitHub Actions, Git
