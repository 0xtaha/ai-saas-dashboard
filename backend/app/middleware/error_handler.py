"""
Global error handlers
"""
from flask import jsonify
from werkzeug.exceptions import HTTPException


def register_error_handlers(app):
    """Register error handlers"""
    
    @app.errorhandler(HTTPException)
    def handle_http_exception(e):
        return jsonify({
            "error": e.description,
            "status": "error"
        }), e.code
    
    @app.errorhandler(Exception)
    def handle_exception(e):
        app.logger.error(f"Unhandled exception: {str(e)}")
        return jsonify({
            "error": "Internal server error",
            "status": "error"
        }), 500