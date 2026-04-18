from flask import jsonify

class APIError(Exception):
    """Custom API Error Exception"""
    
    def __init__(self, message: str, code: int = 400, details=None):
        super().__init__(message)
        self.message = message
        self.code = code
        self.details = details

def error_payload(message: str, code: int = 400, details=None):
    """Generate standardized error response"""
    payload = {
        "error": {
            "message": message,
            "code": code
        }
    }
    if details is not None:
        payload["error"]["details"] = details
    return payload

# Specific error classes for cleaner code
class ValidationError(APIError):
    def __init__(self, details: dict):
        super().__init__("Validation failed", 400, details)

class NotFoundError(APIError):
    def __init__(self, resource: str):
        super().__init__(f"{resource} not found", 404)

class DuplicateError(APIError):
    def __init__(self, field: str):
        super().__init__(
            f"{field} already exists",
            409,
            {field: ["Already used"]}
        )

class ConflictError(APIError):
    def __init__(self, message: str, details: dict = None):
        super().__init__(message, 409, details)