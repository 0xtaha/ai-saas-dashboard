"""
File model
"""
from app.extensions import db
from datetime import datetime


class File(db.Model):
    __tablename__ = 'files'

    # Use checksum as primary key
    checksum = db.Column(db.String(64), primary_key=True)
    original_filename = db.Column(db.String(255), nullable=False)
    stored_filename = db.Column(db.String(255), nullable=False)
    filepath = db.Column(db.String(500), nullable=False)
    file_size = db.Column(db.Integer, nullable=False)
    mime_type = db.Column(db.String(100))
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    uploaded_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Processing status
    is_processed = db.Column(db.Boolean, default=False)
    processed_at = db.Column(db.DateTime, nullable=True)
    processing_result = db.Column(db.Text, nullable=True)

    # Relationship to AI requests
    ai_requests = db.relationship('AIRequest', backref='file', lazy=True)

    def to_dict(self):
        return {
            'checksum': self.checksum,
            'filename': self.original_filename,
            'size': self.file_size,
            'mime_type': self.mime_type,
            'uploaded_at': self.uploaded_at.isoformat(),
            'is_processed': self.is_processed,
            'processed_at': self.processed_at.isoformat() if self.processed_at else None,
            'processing_result': self.processing_result
        }