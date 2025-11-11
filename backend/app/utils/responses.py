"""
Standardized API responses
"""
from flask import jsonify


def success_response(data, message="Success", status_code=200):
    """Create success response"""
    return jsonify({
        "data": data,
        "message": message,
        "status": "success"
    }), status_code


def error_response(message, status_code):
    """Create error response"""
    return jsonify({
        "error": message,
        "status": "error"
    }), status_code