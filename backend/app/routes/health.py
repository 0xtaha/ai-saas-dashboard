# Health check routes
from flask import Blueprint, jsonify
from datetime import datetime

health_bp = Blueprint('health', __name__, url_prefix='/api/health')


@health_bp.route('/', methods=['GET'])
def health_check():
    """Basic health check endpoint
    ---
    tags:
      - Health
    responses:
      200:
        description: Service is healthy
        schema:
          type: object
          properties:
            status:
              type: string
              example: healthy
            timestamp:
              type: string
              format: date-time
    """
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat()
    }), 200


@health_bp.route('/ready', methods=['GET'])
def readiness_check():
    """Readiness check endpoint
    ---
    tags:
      - Health
    responses:
      200:
        description: Service is ready to accept requests
        schema:
          type: object
          properties:
            status:
              type: string
              example: ready
            timestamp:
              type: string
              format: date-time
    """
    # TODO: Add database connectivity check
    return jsonify({
        'status': 'ready',
        'timestamp': datetime.utcnow().isoformat()
    }), 200
