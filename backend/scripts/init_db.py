# Database initialization script
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app import create_app
from app.extensions import db


def init_database():
    """Initialize database with tables"""
    app = create_app()

    with app.app_context():
        print("Creating database tables...")
        db.create_all()
        print("Database tables created successfully!")


if __name__ == '__main__':
    init_database()
