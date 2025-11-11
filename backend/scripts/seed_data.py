# Seed test data script
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app import create_app
from app.extensions import db


def seed_data():
    """Seed database with test data"""
    app = create_app()

    with app.app_context():
        print("Seeding database with test data...")

        # TODO: Add test users, files, and AI requests

        db.session.commit()
        print("Test data seeded successfully!")


if __name__ == '__main__':
    seed_data()
