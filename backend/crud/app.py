from flask import Flask
from flask_cors import CORS
from dotenv import load_dotenv
from sqlalchemy import text
load_dotenv()

from .config import DevelopmentConfig
from .extensions import db
from .errors import APIError, error_payload


def _ensure_schema_compatibility() -> None:
    """Apply tiny safe migrations needed by current ORM models."""
    with db.engine.begin() as conn:
        has_created_by = conn.execute(
            text("SHOW COLUMNS FROM basket LIKE 'created_by'")
        ).first()

        if not has_created_by:
            conn.execute(text("ALTER TABLE basket ADD COLUMN created_by INT UNSIGNED NULL"))

def create_app(config_class=DevelopmentConfig):
    """Application factory function"""
    
    app = Flask(__name__)
    app.config.from_object(config_class)

    # Validate database URL
    if not app.config.get("SQLALCHEMY_DATABASE_URI"):
        raise RuntimeError("SQLALCHEMY_DATABASE_URI is missing. Set it in .env or config.py")

    # Initialize extensions
    db.init_app(app)
    CORS(app, resources={r"/api/*": {"origins": "*"}})

    # Register blueprints
    from .routes import bp
    app.register_blueprint(bp)

    # Health check endpoint
    @app.get("/")
    def home():
        return {
            "status": "ok",
            "service": "sensora-api",
            "version": "1.0.0"
        }

    # Error handlers
    @app.errorhandler(APIError)
    def handle_api_error(e: APIError):
        return error_payload(e.message, e.code, e.details), e.code

    @app.errorhandler(404)
    def handle_404(_):
        return error_payload("Not found", 404), 404

    @app.errorhandler(500)
    def handle_500(_):
        return error_payload("Internal server error", 500), 500

    # Create database tables
    with app.app_context():
        try:
            _ensure_schema_compatibility()
            db.create_all()
        except Exception as e:
            print(f"[CRUD INIT ERROR] {e}")

    return app

if __name__ == "__main__":
    app = create_app()
    app.run(host="0.0.0.0", port=5002, debug=True)
