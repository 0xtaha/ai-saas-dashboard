# AI SaaS Dashboard - Backend

A Flask-based backend API for the AI SaaS Dashboard application.

## Features

- User authentication with JWT
- File upload and management
- AI request processing
- Request history tracking
- Rate limiting
- Health check endpoints

## Tech Stack

- **Framework**: Flask 3.0
- **Database**: SQLAlchemy with PostgreSQL/SQLite
- **Authentication**: Flask-JWT-Extended
- **AI Integration**: OpenAI API
- **Testing**: Pytest

## Quick Start

### Prerequisites

- Python 3.8+
- PostgreSQL (optional, SQLite for development)

### Installation

1. Clone the repository
2. Create virtual environment:
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # Linux/Mac
   .venv\Scripts\activate     # Windows
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Set up environment variables:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

5. Initialize database:
   ```bash
   python scripts/init_db.py
   ```

6. Run the application:
   ```bash
   flask run
   ```

The API will be available at `http://localhost:5000`

## Project Structure

```
backend/
├── app/                    # Application package
│   ├── models/            # Database models
│   ├── routes/            # API endpoints
│   ├── services/          # Business logic
│   ├── utils/             # Utilities
│   └── middleware/        # Middleware
├── tests/                 # Test suite
├── scripts/               # Utility scripts
├── docs/                  # Documentation
└── uploads/               # File storage
```

## API Documentation

See [docs/API.md](docs/API.md) for detailed API documentation.

## Testing

Run tests:
```bash
pytest
```

Run with coverage:
```bash
pytest --cov=app --cov-report=html
```

## Deployment

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for deployment instructions.

## License

MIT
