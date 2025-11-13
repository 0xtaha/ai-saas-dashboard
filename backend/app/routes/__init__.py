# Routes package initialization
"""
Blueprint registration
"""
from app.routes.auth import auth_bp
from app.routes.files import files_bp
from app.routes.health import health_bp


def register_blueprints(app):
    """Register all blueprints"""
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(files_bp, url_prefix='/api/files')
    app.register_blueprint(health_bp)  # health_bp already has url_prefix='/api/health' in its definition