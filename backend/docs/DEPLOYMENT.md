# Deployment Guide

## Prerequisites

- Python 3.8+
- PostgreSQL (for production)
- Redis (optional, for rate limiting)
- Docker (optional)

## Environment Variables

Create a `.env` file with the following variables:

```
FLASK_APP=run.py
FLASK_ENV=production
SECRET_KEY=your-secret-key
JWT_SECRET_KEY=your-jwt-secret-key
DATABASE_URL=postgresql://user:password@localhost/dbname
OPENAI_API_KEY=your-openai-api-key
UPLOAD_FOLDER=/path/to/uploads
MAX_CONTENT_LENGTH=10485760
```

## Installation

1. Clone the repository
2. Create virtual environment: `python -m venv .venv`
3. Activate virtual environment: `source .venv/bin/activate` (Linux/Mac) or `.venv\Scripts\activate` (Windows)
4. Install dependencies: `pip install -r requirements.txt`
5. Initialize database: `python scripts/init_db.py`
6. Run migrations: `flask db upgrade`

## Running the Application

### Development
```bash
flask run
```

### Production
```bash
gunicorn -w 4 -b 0.0.0.0:8000 wsgi:app
```

## Docker Deployment

```bash
docker-compose up -d
```

## Health Checks

- Health: `GET /api/health/`
- Readiness: `GET /api/health/ready`
