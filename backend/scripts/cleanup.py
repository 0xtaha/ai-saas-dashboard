# Cleanup old files script
import sys
import os
from datetime import datetime, timedelta

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app import create_app
from app.extensions import db


def cleanup_old_files(days=30):
    """Remove files older than specified days"""
    app = create_app()

    with app.app_context():
        cutoff_date = datetime.utcnow() - timedelta(days=days)
        print(f"Cleaning up files older than {cutoff_date}...")

        # TODO: Implement file cleanup logic

        print("Cleanup completed!")


if __name__ == '__main__':
    cleanup_old_files()
