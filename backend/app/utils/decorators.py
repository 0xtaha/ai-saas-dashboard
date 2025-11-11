# Custom decorators
from functools import wraps
from flask import request
from flask_jwt_extended import get_jwt_identity
from app.utils.responses import error_response


def validate_json(*expected_args):
    """Decorator to validate JSON request data"""
    def decorator(f):
        @wraps(f)
        def wrapper(*args, **kwargs):
            if not request.is_json:
                return error_response("Content-Type must be application/json", 400)

            data = request.get_json()
            missing_fields = [field for field in expected_args if field not in data]

            if missing_fields:
                return error_response(
                    f"Missing required fields: {', '.join(missing_fields)}",
                    400
                )

            return f(*args, **kwargs)
        return wrapper
    return decorator


def admin_required():
    """Decorator to require admin role"""
    def decorator(f):
        @wraps(f)
        def wrapper(*args, **kwargs):
            user_id = get_jwt_identity()
            # TODO: Check if user is admin
            # For now, just pass through
            return f(*args, **kwargs)
        return wrapper
    return decorator
