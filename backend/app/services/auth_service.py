"""
Authentication service - Business logic
"""
from app.models.user import User
from app.extensions import db


class AuthService:
    """Handle authentication logic"""
    
    def register_user(self, username, password, email=None):
        """Register a new user"""
        if not username or not password:
            raise ValueError("Username and password required")
        
        if User.query.filter_by(username=username).first():
            raise ValueError("User already exists")
        
        user = User(username=username, email=email)
        user.set_password(password)
        
        db.session.add(user)
        db.session.commit()
        
        return user
    
    def authenticate_user(self, username, password):
        """Authenticate user credentials"""
        if not username or not password:
            raise ValueError("Username and password required")
        
        user = User.query.filter_by(username=username).first()
        
        if not user or not user.check_password(password):
            raise ValueError("Invalid credentials")
        
        return user