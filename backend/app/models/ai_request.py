"""
AI Request model for tracking file processing
"""
from app.extensions import db
from datetime import datetime


class AIRequest(db.Model):
    __tablename__ = 'ai_requests'

    id = db.Column(db.Integer, primary_key=True)
    file_checksum = db.Column(db.String(64), db.ForeignKey('files.checksum'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)

    # Request details
    request_type = db.Column(db.String(50), nullable=False)
    prompt = db.Column(db.Text, nullable=True)

    # Response details
    response = db.Column(db.Text, nullable=True)
    status = db.Column(db.String(20), default='pending')
    error_message = db.Column(db.Text, nullable=True)

    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    completed_at = db.Column(db.DateTime, nullable=True)

    def to_dict(self):
        return {
            'id': self.id,
            'file_checksum': self.file_checksum,
            'request_type': self.request_type,
            'status': self.status,
            'response': self.response,
            'error_message': self.error_message,
            'created_at': self.created_at.isoformat(),
            'completed_at': self.completed_at.isoformat() if self.completed_at else None
        }
