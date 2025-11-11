"""
Configuration classes for different environments
"""
import os
from datetime import timedelta


class Config:
    """Base configuration"""
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key')
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'jwt-secret-key')
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=1)
    
    # File upload
    MAX_CONTENT_LENGTH = int(os.getenv('MAX_CONTENT_LENGTH', 16 * 1024 * 1024))
    UPLOAD_FOLDER = os.getenv('UPLOAD_FOLDER', 'uploads')
    ALLOWED_EXTENSIONS = {'txt', 'pdf', 'png', 'jpg', 'jpeg', 'gif', 'doc', 'docx'}
    
    # Database
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # AI API
    AI_API_URL = os.getenv('AI_API_URL')
    AI_API_KEY = os.getenv('AI_API_KEY')


class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = os.getenv(
        'DATABASE_URL',
        'sqlite:///dev.db'
    )


class ProductionConfig(Config):
    """Production configuration"""
    DEBUG = False
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL')
    
    # Additional production settings
    SESSION_COOKIE_SECURE = True
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = 'Lax'


class TestingConfig(Config):
    """Testing configuration"""
    TESTING = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///test.db'


config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}