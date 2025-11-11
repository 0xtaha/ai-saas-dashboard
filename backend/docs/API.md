# API Documentation

## Authentication Endpoints

### Register User
```
POST /api/auth/register
```

**Request Body:**
```json
{
  "username": "string",
  "email": "string",
  "password": "string"
}
```

### Login
```
POST /api/auth/login
```

**Request Body:**
```json
{
  "email": "string",
  "password": "string"
}
```

**Response:**
```json
{
  "access_token": "string",
  "user": {
    "id": "integer",
    "username": "string",
    "email": "string"
  }
}
```

## File Endpoints

### Upload File
```
POST /api/files/upload
Authorization: Bearer <token>
```

### List Files
```
GET /api/files/
Authorization: Bearer <token>
```

### Get File
```
GET /api/files/{file_id}
Authorization: Bearer <token>
```

### Delete File
```
DELETE /api/files/{file_id}
Authorization: Bearer <token>
```

## AI Processing Endpoints

### Process AI Request
```
POST /api/ai/process
Authorization: Bearer <token>
```

### Get AI History
```
GET /api/ai/history
Authorization: Bearer <token>
```

## Health Check Endpoints

### Health Check
```
GET /api/health/
```

### Readiness Check
```
GET /api/health/ready
```
