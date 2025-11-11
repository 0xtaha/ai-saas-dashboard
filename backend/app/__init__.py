"""
Application factory pattern
"""
from flask import Flask
from app.config import config
from app.extensions import db, jwt, migrate, cors


def create_app(config_name='development'):
    """Create and configure Flask application"""
    app = Flask(__name__)
    
    # Load configuration
    app.config.from_object(config[config_name])
    
    # Initialize extensions
    db.init_app(app)
    jwt.init_app(app)
    migrate.init_app(app, db)
    cors.init_app(app)
    
    # Register blueprints
    from app.routes import register_blueprints
    register_blueprints(app)
    
    # Register error handlers
    from app.middleware.error_handler import register_error_handlers
    register_error_handlers(app)
    
    return app