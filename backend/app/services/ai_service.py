# AI API integration service
import os
import requests
import base64
from datetime import datetime
from flask import current_app

from app.extensions import db
from app.models.ai_request import AIRequest
from app.models.file import File


class AIService:
    """Handle AI API integrations"""

    @staticmethod
    def process_file(file_checksum, user_id, request_type='process'):
        """
        Process a file with AI API
        Returns: (success, message, ai_request)
        """
        # Get file record
        file_record = File.query.filter_by(checksum=file_checksum).first()
        if not file_record:
            return False, "File not found", None

        # Check if file was already processed
        if file_record.is_processed:
            return True, "File already processed", None

        # Create AI request record
        ai_request = AIRequest(
            file_checksum=file_checksum,
            user_id=user_id,
            request_type=request_type,
            status='processing'
        )

        try:
            db.session.add(ai_request)
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            return False, f"Failed to create AI request: {str(e)}", None

        # Get AI API configuration
        ai_api_url = current_app.config.get('AI_API_URL')
        ai_api_key = current_app.config.get('AI_API_KEY')

        if not ai_api_url or not ai_api_key:
            AIService._update_request_status(ai_request.id, 'failed',
                                            error_message="AI API not configured")
            return False, "AI API not configured", ai_request

        # Read file content
        try:
            with open(file_record.filepath, 'rb') as f:
                file_content = f.read()
        except Exception as e:
            AIService._update_request_status(ai_request.id, 'failed',
                                            error_message=f"Failed to read file: {str(e)}")
            return False, f"Failed to read file: {str(e)}", ai_request

        # Encode file content to base64 for API transmission
        file_base64 = base64.b64encode(file_content).decode('utf-8')

        # Send request to AI API
        try:
            response = AIService._send_to_ai_api(
                ai_api_url,
                ai_api_key,
                file_record,
                file_base64
            )

            if response.get('success'):
                result = response.get('result', '')

                # Update AI request
                AIService._update_request_status(
                    ai_request.id,
                    'completed',
                    response=result
                )

                # Mark file as processed
                file_record.is_processed = True
                file_record.processed_at = datetime.utcnow()
                file_record.processing_result = result
                db.session.commit()

                return True, "File processed successfully", ai_request
            else:
                error_msg = response.get('error', 'Unknown error')
                AIService._update_request_status(
                    ai_request.id,
                    'failed',
                    error_message=error_msg
                )
                return False, f"AI processing failed: {error_msg}", ai_request

        except Exception as e:
            AIService._update_request_status(
                ai_request.id,
                'failed',
                error_message=str(e)
            )
            return False, f"Failed to process file: {str(e)}", ai_request

    @staticmethod
    def _send_to_ai_api(api_url, api_key, file_record, file_base64):
        """Send file to AI API for processing"""
        headers = {
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json'
        }

        payload = {
            'file': {
                'name': file_record.original_filename,
                'mime_type': file_record.mime_type,
                'size': file_record.file_size,
                'content': file_base64,
                'checksum': file_record.checksum
            },
            'options': {
                'process_type': 'analyze',
                'extract_text': True,
                'generate_summary': True
            }
        }

        try:
            response = requests.post(
                api_url,
                json=payload,
                headers=headers,
                timeout=60
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            return {
                'success': False,
                'error': str(e)
            }

    @staticmethod
    def _update_request_status(request_id, status, response=None, error_message=None):
        """Update AI request status"""
        try:
            ai_request = AIRequest.query.get(request_id)
            if ai_request:
                ai_request.status = status
                if response:
                    ai_request.response = response
                if error_message:
                    ai_request.error_message = error_message
                if status in ['completed', 'failed']:
                    ai_request.completed_at = datetime.utcnow()
                db.session.commit()
        except Exception as e:
            db.session.rollback()
            current_app.logger.error(f"Failed to update AI request status: {str(e)}")

    @staticmethod
    def get_request_history(user_id, page=1, per_page=20):
        """Get AI request history for a user"""
        return AIRequest.query.filter_by(user_id=user_id)\
            .order_by(AIRequest.created_at.desc())\
            .paginate(page=page, per_page=per_page, error_out=False)

    @staticmethod
    def get_request_by_id(request_id, user_id):
        """Get specific AI request"""
        return AIRequest.query.filter_by(id=request_id, user_id=user_id).first()
