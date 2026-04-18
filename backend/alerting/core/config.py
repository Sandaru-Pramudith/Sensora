from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    db_host: str
    db_user: str
    db_password: str
    db_name: str
    db_port: int = 3306

    secret_key: str = "dev-secret-key"
    debug: bool = False
    port: int = 5000

    thresholds: dict = {
        "ethylene": {"warning": 1.0, "critical": 2.5},
        "voc": {"warning": 50.0, "critical": 100.0},
        "temperature": {"warning": 25.0, "critical": 30.0},
        "humidity": {"warning": 80.0, "critical": 90.0},
    }

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

settings = Settings()
