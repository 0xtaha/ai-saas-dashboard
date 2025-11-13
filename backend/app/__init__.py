"""
Application factory pattern
"""
from flask import Flask
from app.config import config
from app.extensions import db, jwt, migrate, cors, swagger


def create_app(config_name='development'):
    """Create and configure Flask application"""
    app = Flask(__name__)

    # Load configuration
    app.config.from_object(config[config_name])

    # Swagger configuration
    app.config['SWAGGER'] = {
        'title': 'AI SaaS Dashboard API',
        'uiversion': 3,
        'version': '1.0.0',
        'description': 'API documentation for AI SaaS Dashboard',
        'termsOfService': '',
        'contact': {
            'name': 'API Support',
            'email': 'support@example.com'
        },
        'securityDefinitions': {
            'Bearer': {
                'type': 'token',
                'name': 'Authorization',
                'in': 'header',
                'description': 'Enter your JWT token with "Bearer " prefix. Example: Bearer eyJhbGc...'
            }
        },
        'security': [
            {
                'Bearer': []
            }
        ],
        'specs': [
            {
                'endpoint': 'apispec',
                'route': '/apispec.json',
                'rule_filter': lambda rule: True,
                'model_filter': lambda tag: True,
            }
        ],
        'static_url_path': '/flasgger_static',
        'swagger_ui': True,
        'specs_route': '/api/docs/'
    }

    # Initialize CORS first (before other extensions that might add routes)
    cors.init_app(
        app,
        origins=app.config['CORS_ORIGINS'],
        allow_headers=app.config['CORS_ALLOW_HEADERS'],
        methods=app.config['CORS_METHODS'],
        supports_credentials=app.config['CORS_SUPPORTS_CREDENTIALS']
    )

    # Initialize other extensions
    db.init_app(app)
    jwt.init_app(app)
    migrate.init_app(app, db)
    swagger.init_app(app)

    # Register blueprints
    from app.routes import register_blueprints
    register_blueprints(app)

    # Register error handlers
    from app.middleware.error_handler import register_error_handlers
    register_error_handlers(app)

    return app