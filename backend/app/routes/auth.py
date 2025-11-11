"""
Authentication routes
"""
from flask import Blueprint, request
from flask_jwt_extended import create_access_token
from app.services.auth_service import AuthService
from app.utils.responses import success_response, error_response

auth_bp = Blueprint('auth', __name__)
auth_service = AuthService()


@auth_bp.route('/register', methods=['POST'])
def register():
    """Register a new user"""
    try:
        data = request.get_json()
        user = auth_service.register_user(
            data.get('username'),
            data.get('password'),
            data.get('email')
        )
        return success_response(user.to_dict(), 'User registered successfully', 201)
    except ValueError as e:
        return error_response(str(e), 400)
    except Exception as e:
        return error_response(str(e), 500)


@auth_bp.route('/login', methods=['POST'])
def login():
    """Login user"""
    try:
        data = request.get_json()
        user = auth_service.authenticate_user(
            data.get('username'),
            data.get('password')
        )
        
        token = create_access_token(identity=user.username)
        
        return success_response({
            'access_token': token,
            'user': user.to_dict()
        }, 'Login successful')
    except ValueError as e:
        return error_response(str(e), 401)
    except Exception as e:
        return error_response(str(e), 500)