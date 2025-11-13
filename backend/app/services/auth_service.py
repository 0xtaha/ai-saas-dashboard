"""
Authentication service - Business logic
"""
from app.models.user import User
from app.extensions import db


class AuthService:
    """Handle authentication logic"""
    
    def register_user(self, username, password, email):
        """Register a new user"""
        if not username or not password:
            raise ValueError("Username and password required")
        
        if User.query.filter_by(email=email, username=username).first():
            raise ValueError("User already exists")
        
        user = User(username=username, email=email)
        user.set_password(password)
        # todo : add support for using AD
        db.session.add(user)
        db.session.commit()
        
        return user
    
    def authenticate_user(self, email, password):
        """Authenticate user credentials"""
        if not email or not password:
            raise ValueError("Username and password required")
        
        user = User.query.filter_by(email=email).first()
        
        if not user or not user.check_password(password):
            raise ValueError("Invalid credentials")
        
        return user