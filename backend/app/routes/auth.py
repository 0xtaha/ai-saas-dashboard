"""
Authentication routes
"""
from flask import Blueprint, request
from flask_jwt_extended import create_access_token
from flasgger import swag_from
from app.services.auth_service import AuthService
from app.utils.responses import success_response, error_response

auth_bp = Blueprint('auth', __name__)
auth_service = AuthService()


@auth_bp.route('/register', methods=['POST'])
def register():
    """Register a new user
    ---
    tags:
      - Authentication
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          required:
            - username
            - email
            - password
          properties:
            username:
              type: string
              example: johndoe
            email:
              type: string
              format: email
              example: john@example.com
            password:
              type: string
              format: password
              example: SecurePass123!
    responses:
      201:
        description: User registered successfully
        schema:
          type: object
          properties:
            status:
              type: string
              example: success
            message:
              type: string
              example: User registered successfully
            data:
              type: object
              properties:
                id:
                  type: integer
                username:
                  type: string
                email:
                  type: string
      400:
        description: Bad request - validation error
      500:
        description: Internal server error
    """
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
    """Login user
    ---
    tags:
      - Authentication
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          required:
            - email
            - password
          properties:
            email:
              type: string
              format: email
              example: john@example.com
              description: Email or username for login
            password:
              type: string
              format: password
              example: SecurePass123!
    responses:
      200:
        description: Login successful
        schema:
          type: object
          properties:
            status:
              type: string
              example: success
            message:
              type: string
              example: Login successful
            data:
              type: object
              properties:
                access_token:
                  type: string
                  description: JWT access token
                user:
                  type: object
                  properties:
                    id:
                      type: integer
                    username:
                      type: string
                    email:
                      type: string
      401:
        description: Invalid credentials
      500:
        description: Internal server error
    """
    try:
        data = request.get_json()
        user = auth_service.authenticate_user(
            data.get('email'),
            data.get('password')
        )
        user = user.to_dict()
        token = create_access_token(identity=user)

        return success_response({
            'access_token': token,
            'user': user
        }, 'Login successful')
    except ValueError as e:
        return error_response(str(e), 401)
    except Exception as e:
        return error_response(str(e), 500)


@auth_bp.route('/logout', methods=['POST'])
def logout():
    """Logout user (client-side token removal)
    ---
    tags:
      - Authentication
    responses:
      200:
        description: Logout successful
        schema:
          type: object
          properties:
            status:
              type: string
              example: success
            message:
              type: string
              example: Logout successful
    """
    # JWT is stateless, so logout is handled client-side by removing the token
    # This endpoint exists for consistency and can be extended for token blacklisting
    return success_response(None, 'Logout successful')


@auth_bp.route('/profile', methods=['GET'])
def get_profile():
    """Get current user profile
    ---
    tags:
      - Authentication
    security:
      - Bearer: []
    responses:
      200:
        description: Profile retrieved successfully
        schema:
          type: object
          properties:
            status:
              type: string
              example: success
            message:
              type: string
              example: Profile retrieved successfully
            data:
              type: object
              properties:
                id:
                  type: integer
                username:
                  type: string
                email:
                  type: string
                created_at:
                  type: string
                  format: date-time
      401:
        description: Unauthorized - invalid or missing token
      404:
        description: User not found
    """
    from flask_jwt_extended import jwt_required, get_jwt_identity
    from app.models.user import User

    @jwt_required()
    def _get_profile():
        user_id = get_jwt_identity()['id']
        user = User.query.filter_by(id=user_id).first()

        if not user:
            return error_response('User not found', 404)

        return success_response(user.to_dict(), 'Profile retrieved successfully')

    return _get_profile()