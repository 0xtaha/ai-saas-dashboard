# File management routes
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity

from app.services.file_service import FileService
from app.services.ai_service import AIService
from app.utils.responses import success_response, error_response

files_bp = Blueprint('files', __name__)


@files_bp.route('/upload', methods=['POST'])
@jwt_required()
def upload_file():
    """Upload a file and process with AI
    ---
    tags:
      - Files
    security:
      - Bearer: []
    consumes:
      - multipart/form-data
    parameters:
      - in: formData
        name: file
        type: file
        required: true
        description: File to upload
    responses:
      201:
        description: File uploaded and processed successfully
        schema:
          type: object
          properties:
            status:
              type: string
              example: success
            message:
              type: string
            data:
              type: object
              properties:
                file:
                  type: object
                  properties:
                    checksum:
                      type: string
                    filename:
                      type: string
                    file_size:
                      type: integer
                    is_processed:
                      type: boolean
                ai_processing:
                  type: object
                  properties:
                    status:
                      type: string
                    message:
                      type: string
      400:
        description: Bad request - no file or invalid file
      401:
        description: Unauthorized - missing or invalid token
    """
    user_id = int(get_jwt_identity())  # Convert string ID to integer
    print(user_id)
    # Check if file is in request
    if 'file' not in request.files:
        return error_response("No file part in request", 400)

    file = request.files['file']
    print(file)
    # Save file using FileService
    success, message, file_record = FileService.save_file(file, user_id)

    if not success:
        return error_response(message, 400)

    # Check if this is a duplicate file
    is_duplicate = "duplicate" in message.lower()

    # If file is new and not processed, send to AI for processing
    if not is_duplicate and not file_record.is_processed:
        ai_success, ai_message, ai_request = AIService.process_file(
            file_record.checksum,
            user_id
        )

        return success_response({
            'file': file_record.to_dict(),
            'ai_processing': {
                'status': 'processing' if ai_success else 'failed',
                'message': ai_message,
                'request_id': ai_request.id if ai_request else None
            }
        }, message, 201)

    # File already exists or already processed
    return success_response({
        'file': file_record.to_dict(),
        'ai_processing': {
            'status': 'already_processed' if file_record.is_processed else 'skipped',
            'message': 'File already processed' if file_record.is_processed else message
        }
    }, message, 200)


@files_bp.route('/', methods=['GET'])
@jwt_required()
def list_files():
    """List user's files with pagination
    ---
    tags:
      - Files
    security:
      - Bearer: []
    parameters:
      - in: query
        name: page
        type: integer
        default: 1
        description: Page number
      - in: query
        name: per_page
        type: integer
        default: 20
        description: Items per page
    responses:
      200:
        description: Files retrieved successfully
        schema:
          type: object
          properties:
            status:
              type: string
              example: success
            message:
              type: string
              example: Files retrieved successfully
            data:
              type: object
              properties:
                files:
                  type: array
                  items:
                    type: object
                    properties:
                      checksum:
                        type: string
                      filename:
                        type: string
                      file_size:
                        type: integer
                      is_processed:
                        type: boolean
                pagination:
                  type: object
                  properties:
                    page:
                      type: integer
                    per_page:
                      type: integer
                    total:
                      type: integer
                    pages:
                      type: integer
      401:
        description: Unauthorized - missing or invalid token
    """
    user_id = int(get_jwt_identity())  # Convert string ID to integer

    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)

    pagination = FileService.get_user_files(user_id, page, per_page)

    return success_response({
        'files': [file.to_dict() for file in pagination.items],
        'pagination': {
            'page': pagination.page,
            'per_page': pagination.per_page,
            'total': pagination.total,
            'pages': pagination.pages
        }
    }, "Files retrieved successfully", 200)


@files_bp.route('/<string:checksum>', methods=['GET'])
@jwt_required()
def get_file(checksum):
    """Get specific file details by checksum
    ---
    tags:
      - Files
    security:
      - Bearer: []
    parameters:
      - in: path
        name: checksum
        type: string
        required: true
        description: File checksum (SHA256)
    responses:
      200:
        description: File retrieved successfully
        schema:
          type: object
          properties:
            status:
              type: string
              example: success
            message:
              type: string
              example: File retrieved successfully
            data:
              type: object
              properties:
                file:
                  type: object
                  properties:
                    checksum:
                      type: string
                    filename:
                      type: string
                    file_size:
                      type: integer
                    is_processed:
                      type: boolean
      401:
        description: Unauthorized - missing or invalid token
      403:
        description: Access denied - user doesn't own the file
      404:
        description: File not found
    """
    user_id = int(get_jwt_identity())  # Convert string ID to integer

    file_record = FileService.get_file_by_checksum(checksum)

    if not file_record:
        return error_response("File not found", 404)

    # Check if user owns the file
    if file_record.user_id != user_id:
        return error_response("Access denied", 403)

    return success_response({
        'file': file_record.to_dict()
    }, "File retrieved successfully", 200)


@files_bp.route('/<string:checksum>', methods=['DELETE'])
@jwt_required()
def delete_file(checksum):
    """Delete a file by checksum
    ---
    tags:
      - Files
    security:
      - Bearer: []
    parameters:
      - in: path
        name: checksum
        type: string
        required: true
        description: File checksum (SHA256)
    responses:
      200:
        description: File deleted successfully
        schema:
          type: object
          properties:
            status:
              type: string
              example: success
            message:
              type: string
              example: File deleted successfully
      400:
        description: Bad request - deletion failed
      401:
        description: Unauthorized - missing or invalid token
      403:
        description: Access denied - user doesn't own the file
      404:
        description: File not found
    """
    user_id = int(get_jwt_identity())  # Convert string ID to integer

    success, message = FileService.delete_file(checksum, user_id)

    if not success:
        return error_response(message, 400)

    return success_response(None, message, 200)


@files_bp.route('/<string:checksum>/processing-status', methods=['GET'])
@jwt_required()
def get_processing_status(checksum):
    """Get file processing status
    ---
    tags:
      - Files
    security:
      - Bearer: []
    parameters:
      - in: path
        name: checksum
        type: string
        required: true
        description: File checksum (SHA256)
    responses:
      200:
        description: Processing status retrieved successfully
        schema:
          type: object
          properties:
            status:
              type: string
              example: success
            message:
              type: string
              example: Processing status retrieved successfully
            data:
              type: object
              properties:
                checksum:
                  type: string
                is_processed:
                  type: boolean
                processed_at:
                  type: string
                  format: date-time
                processing_result:
                  type: object
                latest_request:
                  type: object
                  properties:
                    id:
                      type: integer
                    status:
                      type: string
                    created_at:
                      type: string
                      format: date-time
      401:
        description: Unauthorized - missing or invalid token
      403:
        description: Access denied - user doesn't own the file
      404:
        description: File not found
    """
    user_id = int(get_jwt_identity())  # Convert string ID to integer

    file_record = FileService.get_file_by_checksum(checksum)

    if not file_record:
        return error_response("File not found", 404)

    # Check if user owns the file
    if file_record.user_id != user_id:
        return error_response("Access denied", 403)

    # Get latest AI request for this file
    latest_request = None
    if file_record.ai_requests:
        latest_request = max(file_record.ai_requests, key=lambda r: r.created_at)

    return success_response({
        'checksum': file_record.checksum,
        'is_processed': file_record.is_processed,
        'processed_at': file_record.processed_at.isoformat() if file_record.processed_at else None,
        'processing_result': file_record.processing_result,
        'latest_request': latest_request.to_dict() if latest_request else None
    }, "Processing status retrieved successfully", 200)
