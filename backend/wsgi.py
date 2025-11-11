"""
WSGI entry point for production (Gunicorn, uWSGI)
"""
from app import create_app

app = create_app('production')