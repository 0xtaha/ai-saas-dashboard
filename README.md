# AI SaaS Dashboard

A full-stack AI-powered file processing platform with a React frontend and Flask backend.

## Features

- **User Authentication** - Secure JWT-based authentication
- **File Upload** - Drag-and-drop file uploads with checksum-based deduplication
- **AI Processing** - Automatic file processing with AI integration
- **Results Visualization** - Interactive display of processing results
- **File Management** - List, view, and delete uploaded files
- **Processing History** - Track all AI processing requests

## Tech Stack

### Frontend
- React 18
- React Router 6
- Axios
- CSS3
- Nginx (for production)

### Backend
- Flask 3.0
- SQLAlchemy
- PostgreSQL
- JWT Authentication
- Flask-CORS
- Flask-Migrate

### Infrastructure
- Docker & Docker Compose
- Redis (for caching)
- Nginx (frontend hosting)

## Project Structure

```
ai-saas-dashboard/
├── frontend/                   # React frontend application
│   ├── src/
│   │   ├── components/        # React components
│   │   ├── pages/             # Page components
│   │   ├── services/          # API services
│   │   ├── contexts/          # React contexts
│   │   └── styles/            # CSS files
│   ├── public/
│   ├── Dockerfile             # Frontend Docker config
│   ├── nginx.conf             # Nginx configuration
│   └── package.json
│
├── backend/                    # Flask backend API
│   ├── app/
│   │   ├── models/            # Database models
│   │   ├── routes/            # API endpoints
│   │   ├── services/          # Business logic
│   │   ├── utils/             # Utilities
│   │   └── middleware/        # Middleware
│   ├── uploaded_files/        # File storage
│   ├── Dockerfile             # Backend Docker config
│   └── requirements.txt
│
├── docker-compose.yml         # Docker Compose configuration
├── .env.example               # Environment variables template
└── README.md                  # This file
```

## Quick Start with Docker

### Prerequisites
- Docker
- Docker Compose

### 1. Clone the repository

```bash
git clone <repository-url>
cd ai-saas-dashboard
```

### 2. Set up environment variables

```bash
cp .env.example .env
```

Edit `.env` and configure your settings:
```env
SECRET_KEY=your-secret-key-here
JWT_SECRET_KEY=your-jwt-secret-key-here
AI_API_URL=https://your-ai-api-url
AI_API_KEY=your-ai-api-key
```

### 3. Build and run with Docker Compose

```bash
docker-compose up --build
```

This will start:
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:5000
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

### 4. Access the application

Open your browser and navigate to:
```
http://localhost:3000
```

### 5. Initialize the database

On first run, initialize the database:

```bash
# Enter the backend container
docker-compose exec backend bash

# Run database initialization
python scripts/init_db.py

# Exit container
exit
```

## Development Setup (Without Docker)

### Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set up environment
cp .env.example .env
# Edit .env with your configuration

# Initialize database
python scripts/init_db.py

# Run development server
python run.py
```

Backend runs on: http://localhost:5000

### Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Set up environment
cp .env.example .env
# Edit .env with your configuration

# Run development server
npm start
```

Frontend runs on: http://localhost:3000

## Docker Commands

### Start all services
```bash
docker-compose up
```

### Start in detached mode
```bash
docker-compose up -d
```

### Rebuild containers
```bash
docker-compose up --build
```

### Stop all services
```bash
docker-compose down
```

### Stop and remove volumes
```bash
docker-compose down -v
```

### View logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f frontend
docker-compose logs -f backend
```

### Execute commands in containers
```bash
# Backend shell
docker-compose exec backend bash

# Frontend shell
docker-compose exec frontend sh

# Database shell
docker-compose exec db psql -U postgres -d ai_saas
```

### Rebuild specific service
```bash
docker-compose up --build frontend
docker-compose up --build backend
```

## API Documentation

### Authentication Endpoints

- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/logout` - Logout user
- `GET /api/auth/profile` - Get user profile

### File Endpoints

- `POST /api/files/upload` - Upload file
- `GET /api/files/` - List files (paginated)
- `GET /api/files/:checksum` - Get file details
- `DELETE /api/files/:checksum` - Delete file
- `GET /api/files/:checksum/processing-status` - Get processing status

### Health Check

- `GET /api/health/` - Health check
- `GET /api/health/ready` - Readiness check

## Environment Variables

### Backend (`backend/.env`)
```env
FLASK_ENV=development
FLASK_DEBUG=True
SECRET_KEY=your-secret-key
JWT_SECRET_KEY=your-jwt-secret-key
DATABASE_URL=postgresql://user:password@localhost:5432/ai_saas
AI_API_URL=https://api.example.com/v1/messages
AI_API_KEY=your-ai-api-key
MAX_CONTENT_LENGTH=16777216
```

### Frontend (`frontend/.env`)
```env
REACT_APP_API_URL=http://localhost:5000/api
```

### Docker Compose (`.env`)
```env
SECRET_KEY=your-secret-key
JWT_SECRET_KEY=your-jwt-secret-key
AI_API_URL=https://api.example.com
AI_API_KEY=your-api-key
```

## Database

### PostgreSQL Connection
- Host: localhost
- Port: 5432
- Database: ai_saas
- User: postgres
- Password: postgres (change in production)

### Migrations

```bash
# Create migration
cd backend
flask db migrate -m "Migration message"

# Apply migration
flask db upgrade

# Rollback migration
flask db downgrade
```

## Production Deployment

### 1. Update environment variables

Set production values in `.env`:
- Change all secret keys
- Set `FLASK_ENV=production`
- Configure production database URL
- Set proper AI API credentials

### 2. Build for production

```bash
docker-compose -f docker-compose.yml build
```

### 3. Run in production mode

```bash
docker-compose up -d
```

### 4. Use reverse proxy

For production, use a reverse proxy (nginx/traefik) for:
- SSL/TLS termination
- Load balancing
- Rate limiting
- Static file caching

## Features in Detail

### File Upload Flow
1. User uploads file via drag-and-drop or file picker
2. Frontend validates file type and size
3. File is uploaded to backend with progress tracking
4. Backend calculates SHA-256 checksum
5. Duplicate detection - returns existing file if checksum matches
6. File saved to `uploaded_files/` directory
7. Metadata stored in database with checksum as primary key
8. File automatically sent to AI API for processing
9. Processing status tracked in real-time
10. Results displayed to user

### Authentication Flow
1. User registers or logs in
2. Backend validates credentials
3. JWT token issued on successful login
4. Token stored in localStorage
5. Token sent with each API request
6. Backend validates token on protected endpoints
7. Auto-redirect to login on token expiration

### AI Processing
- Files automatically processed on upload
- Duplicate files not re-processed
- Processing status tracked in database
- Results stored and can be retrieved later
- Mock data shown when AI backend unavailable

## Testing

### Backend Tests
```bash
cd backend
pytest
pytest --cov=app
```

### Frontend Tests
```bash
cd frontend
npm test
```

## Monitoring

### Health Checks

- Frontend: http://localhost:3000/health
- Backend: http://localhost:5000/api/health/

### Logs

Application logs are stored in:
- Backend: `backend/logs/app.log`
- Docker: `docker-compose logs`

## Troubleshooting

### Database Connection Issues
```bash
# Check if database is running
docker-compose ps

# View database logs
docker-compose logs db

# Reset database
docker-compose down -v
docker-compose up -d db
```

### Frontend Not Loading
```bash
# Check if frontend container is running
docker-compose ps frontend

# View frontend logs
docker-compose logs frontend

# Rebuild frontend
docker-compose up --build frontend
```

### Backend API Errors
```bash
# View backend logs
docker-compose logs backend

# Check environment variables
docker-compose exec backend env

# Restart backend
docker-compose restart backend
```

### CORS Issues
Ensure backend `CORS_ORIGINS` includes frontend URL:
```env
CORS_ORIGINS=http://localhost:3000
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Write/update tests
5. Submit a pull request

## License

MIT

## Support

For issues and questions:
- Create an issue on GitHub
- Check documentation in `frontend/README.md` and `backend/README.md`
