# Architecture Overview

## Project Structure

The backend follows a layered architecture pattern:

### Layers

1. **Routes Layer** (`app/routes/`)
   - Handle HTTP requests and responses
   - Input validation
   - Route to appropriate services

2. **Services Layer** (`app/services/`)
   - Business logic
   - Data processing
   - External API integrations

3. **Models Layer** (`app/models/`)
   - Database models
   - Data relationships
   - Database operations

4. **Utilities Layer** (`app/utils/`)
   - Helper functions
   - Validators
   - Response formatters

5. **Middleware Layer** (`app/middleware/`)
   - Error handling
   - Rate limiting
   - Request/response processing

## Design Patterns

- **Factory Pattern**: App creation
- **Service Layer Pattern**: Business logic separation
- **Repository Pattern**: Data access
- **Decorator Pattern**: Route protection and validation

## Database Schema

### Users
- id (Primary Key)
- username
- email (Unique)
- password_hash
- created_at
- updated_at

### Files
- id (Primary Key)
- user_id (Foreign Key)
- filename
- original_filename
- file_path
- file_size
- mime_type
- created_at

### AI Requests
- id (Primary Key)
- user_id (Foreign Key)
- request_type
- prompt
- response
- created_at

## Security Considerations

- JWT authentication
- Password hashing with werkzeug
- Input validation
- Rate limiting
- CORS configuration
- File upload restrictions
