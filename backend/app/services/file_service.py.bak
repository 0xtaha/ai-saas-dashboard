# File handling service
import os
import hashlib
import mimetypes
from werkzeug.utils import secure_filename
from datetime import datetime
from flask import current_app

from app.extensions import db
from app.models.file import File


class FileService:
    """Handle file operations"""

    ALLOWED_EXTENSIONS = {'txt', 'pdf', 'png', 'jpg', 'jpeg', 'gif', 'doc', 'docx', 'csv', 'xlsx'}

    @staticmethod
    def allowed_file(filename):
        """Check if file extension is allowed"""
        return '.' in filename and \
               filename.rsplit('.', 1)[1].lower() in FileService.ALLOWED_EXTENSIONS

    @staticmethod
    def calculate_checksum(file_data):
        """Calculate SHA-256 checksum of file data"""
        sha256_hash = hashlib.sha256()
        sha256_hash.update(file_data)
        return sha256_hash.hexdigest()

    @staticmethod
    def validate_file(file):
        """Validate file before upload"""
        if not file:
            return False, "No file provided"

        if file.filename == '':
            return False, "No file selected"

        if not FileService.allowed_file(file.filename):
            return False, f"File type not allowed. Allowed types: {', '.join(FileService.ALLOWED_EXTENSIONS)}"

        # Check file size
        max_size = current_app.config.get('MAX_CONTENT_LENGTH', 16 * 1024 * 1024)
        file.seek(0, os.SEEK_END)
        file_size = file.tell()
        file.seek(0)

        if file_size > max_size:
            return False, f"File too large. Maximum size: {max_size / (1024 * 1024):.2f} MB"

        if file_size == 0:
            return False, "File is empty"

        return True, "File is valid"

    @staticmethod
    def save_file(file, user_id):
        """
        Save uploaded file with checksum as ID
        Returns: (success, message, file_record or None)
        """
        # Validate file
        is_valid, message = FileService.validate_file(file)
        if not is_valid:
            return False, message, None

        # Read file data and calculate checksum
        file_data = file.read()
        checksum = FileService.calculate_checksum(file_data)
        file.seek(0)  # Reset file pointer

        # Check if file already exists
        existing_file = File.query.filter_by(checksum=checksum).first()
        if existing_file:
            return True, "File already exists (duplicate detected)", existing_file

        # Prepare file metadata
        original_filename = secure_filename(file.filename)
        file_extension = os.path.splitext(original_filename)[1]
        stored_filename = f"{checksum}{file_extension}"

        # Get upload folder from config
        upload_folder = os.path.join(
            current_app.root_path,
            '..',
            'uploaded_files'
        )
        os.makedirs(upload_folder, exist_ok=True)

        filepath = os.path.join(upload_folder, stored_filename)

        # Get MIME type
        mime_type, _ = mimetypes.guess_type(original_filename)

        # Save file to disk
        try:
            with open(filepath, 'wb') as f:
                f.write(file_data)
        except Exception as e:
            return False, f"Failed to save file: {str(e)}", None

        # Create database record
        file_record = File(
            checksum=checksum,
            original_filename=original_filename,
            stored_filename=stored_filename,
            filepath=filepath,
            file_size=len(file_data),
            mime_type=mime_type,
            user_id=user_id,
            is_processed=False
        )

        try:
            db.session.add(file_record)
            db.session.commit()
            return True, "File uploaded successfully", file_record
        except Exception as e:
            db.session.rollback()
            # Clean up file if database insert fails
            if os.path.exists(filepath):
                os.remove(filepath)
            return False, f"Failed to save file metadata: {str(e)}", None

    @staticmethod
    def get_file_by_checksum(checksum):
        """Get file by checksum"""
        return File.query.filter_by(checksum=checksum).first()

    @staticmethod
    def get_user_files(user_id, page=1, per_page=20):
        """Get all files for a user with pagination"""
        return File.query.filter_by(user_id=user_id)\
            .order_by(File.uploaded_at.desc())\
            .paginate(page=page, per_page=per_page, error_out=False)

    @staticmethod
    def delete_file(checksum, user_id):
        """Delete a file"""
        file_record = File.query.filter_by(checksum=checksum, user_id=user_id).first()

        if not file_record:
            return False, "File not found"

        # Delete file from disk
        if os.path.exists(file_record.filepath):
            try:
                os.remove(file_record.filepath)
            except Exception as e:
                return False, f"Failed to delete file from disk: {str(e)}"

        # Delete from database
        try:
            db.session.delete(file_record)
            db.session.commit()
            return True, "File deleted successfully"
        except Exception as e:
            db.session.rollback()
            return False, f"Failed to delete file record: {str(e)}"

    @staticmethod
    def mark_as_processed(checksum, processing_result):
        """Mark file as processed with result"""
        file_record = File.query.filter_by(checksum=checksum).first()

        if not file_record:
            return False, "File not found"

        try:
            file_record.is_processed = True
            file_record.processed_at = datetime.utcnow()
            file_record.processing_result = processing_result
            db.session.commit()
            return True, "File marked as processed"
        except Exception as e:
            db.session.rollback()
            return False, f"Failed to update file: {str(e)}"
