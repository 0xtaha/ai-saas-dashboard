# Helper functions
import os
import uuid
from datetime import datetime


def generate_unique_filename(original_filename):
    """Generate unique filename with timestamp and UUID"""
    ext = os.path.splitext(original_filename)[1]
    timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
    unique_id = str(uuid.uuid4())[:8]
    return f"{timestamp}_{unique_id}{ext}"


def get_file_extension(filename):
    """Get file extension from filename"""
    return os.path.splitext(filename)[1].lower()


def format_file_size(size_bytes):
    """Format file size in human-readable format"""
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if size_bytes < 1024.0:
            return f"{size_bytes:.2f} {unit}"
        size_bytes /= 1024.0
    return f"{size_bytes:.2f} PB"


def sanitize_filename(filename):
    """Sanitize filename to prevent security issues"""
    # Remove any directory path components
    filename = os.path.basename(filename)
    # Replace spaces with underscores
    filename = filename.replace(' ', '_')
    return filename
