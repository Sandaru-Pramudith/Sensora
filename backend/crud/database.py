import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

load_dotenv()

db_user = os.getenv("DB_USER")
db_pass = os.getenv("DB_PASSWORD")
db_host = os.getenv("DB_HOST")
db_port = os.getenv("DB_PORT", "3306")
db_name = os.getenv("DB_NAME")

URL_database = f"mysql+pymysql://{db_user}:{db_pass}@{db_host}:{db_port}/{db_name}"

engine = create_engine(URL_database)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()
