# Docker Deployment Guide

This guide explains how to run the AI SaaS Dashboard using Docker and Docker Compose.

## Architecture

The application consists of 4 services:

1. **Frontend** - React app served by Nginx (Port 3000)
2. **Backend** - Flask API server (Port 5000)
3. **Database** - PostgreSQL 15 (Port 5432)
4. **Redis** - Cache/sessions (Port 6379)

## Prerequisites

- Docker Desktop (Windows/Mac) or Docker Engine (Linux)
- Docker Compose v2.0+
- 4GB+ RAM allocated to Docker
- 10GB+ disk space

## Quick Start

### Option 1: Using Start Scripts

**Windows:**
```cmd
start.bat
```

**Linux/Mac:**
```bash
./start.sh
```

### Option 2: Manual Start

1. **Copy environment file:**
```bash
cp .env.example .env
```

2. **Edit .env with your configuration**

3. **Build and start:**
```bash
docker-compose up --build -d
```

4. **Initialize database:**
```bash
docker-compose exec backend python scripts/init_db.py
```

5. **Access the application:**
- Frontend: http://localhost:3000
- Backend: http://localhost:5000/api

## Docker Commands Reference

### Starting Services

```bash
# Start all services in foreground
docker-compose up

# Start all services in background
docker-compose up -d

# Start with rebuild
docker-compose up --build

# Start specific service
docker-compose up frontend
```

### Stopping Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (deletes database data)
docker-compose down -v

# Stop specific service
docker-compose stop frontend
```

### Viewing Logs

```bash
# View all logs
docker-compose logs

# Follow logs in real-time
docker-compose logs -f

# View specific service logs
docker-compose logs -f backend
docker-compose logs -f frontend
```

### Service Management

```bash
# Restart a service
docker-compose restart backend

# Rebuild a specific service
docker-compose build frontend

# Scale a service
docker-compose up -d --scale backend=3
```

### Executing Commands

```bash
# Backend shell
docker-compose exec backend bash

# Run Flask commands
docker-compose exec backend flask db upgrade
docker-compose exec backend python scripts/seed_data.py

# Frontend shell
docker-compose exec frontend sh

# Database access
docker-compose exec db psql -U postgres -d ai_saas
```

### Cleanup

```bash
# Remove stopped containers
docker-compose rm

# Remove all unused images
docker image prune -a

# Complete cleanup (removes everything)
docker-compose down -v --rmi all
```

## Configuration

### Environment Variables

Create a `.env` file in the root directory:

```env
# Security
SECRET_KEY=your-super-secret-key-change-in-production
JWT_SECRET_KEY=your-jwt-secret-key-change-in-production

# AI Configuration
AI_API_URL=https://api.example.com/v1/messages
AI_API_KEY=your-ai-api-key-here

# Database
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=ai_saas

# Frontend
REACT_APP_API_URL=http://localhost:5000/api
```

### Service-Specific Configurations

**Frontend (frontend/.env):**
```env
REACT_APP_API_URL=http://localhost:5000/api
```

**Backend (backend/.env):**
```env
FLASK_ENV=production
DATABASE_URL=postgresql://postgres:postgres@db:5432/ai_saas
AI_API_URL=https://api.example.com
AI_API_KEY=your-key
```

## Production Deployment

### Using Production Override

```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

Production overrides include:
- Auto-restart policies
- Gunicorn with multiple workers
- Production environment variables
- Password-protected Redis

### Recommended Production Setup

1. **Use environment-specific configs:**
```bash
# Set production environment variables
export SECRET_KEY=$(openssl rand -hex 32)
export JWT_SECRET_KEY=$(openssl rand -hex 32)
export POSTGRES_PASSWORD=$(openssl rand -hex 16)
```

2. **Enable SSL/TLS:**
   - Use reverse proxy (nginx/traefik)
   - Configure SSL certificates
   - Force HTTPS redirects

3. **Set resource limits:**
```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
```

4. **Configure healthchecks:**
```yaml
services:
  backend:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

## Troubleshooting

### Services Won't Start

**Check Docker status:**
```bash
docker info
```

**View service status:**
```bash
docker-compose ps
```

**Check logs for errors:**
```bash
docker-compose logs backend
docker-compose logs db
```

### Database Connection Issues

**Test database connection:**
```bash
docker-compose exec backend python -c "from app import create_app; app = create_app(); print('DB Connected!')"
```

**Reset database:**
```bash
docker-compose down -v
docker-compose up -d db
docker-compose exec backend python scripts/init_db.py
```

### Frontend Build Fails

**Clear npm cache:**
```bash
docker-compose exec frontend npm cache clean --force
docker-compose build --no-cache frontend
```

### Port Already in Use

**Find process using port:**
```bash
# Linux/Mac
lsof -i :3000
lsof -i :5000

# Windows
netstat -ano | findstr :3000
netstat -ano | findstr :5000
```

**Change ports in docker-compose.yml:**
```yaml
services:
  frontend:
    ports:
      - "8080:80"  # Changed from 3000:80
```

### Out of Disk Space

**Clean up Docker resources:**
```bash
docker system df  # Check disk usage
docker system prune -a  # Remove unused data
docker volume prune  # Remove unused volumes
```

## Monitoring

### Health Checks

**Frontend:**
```bash
curl http://localhost:3000/health
```

**Backend:**
```bash
curl http://localhost:5000/api/health
```

### Resource Usage

```bash
# Monitor resource usage
docker stats

# View container details
docker-compose top
```

### Database

**Check database size:**
```bash
docker-compose exec db psql -U postgres -d ai_saas -c "SELECT pg_size_pretty(pg_database_size('ai_saas'));"
```

**View active connections:**
```bash
docker-compose exec db psql -U postgres -d ai_saas -c "SELECT * FROM pg_stat_activity;"
```

## Backup & Restore

### Backup Database

```bash
docker-compose exec db pg_dump -U postgres ai_saas > backup.sql
```

### Restore Database

```bash
docker-compose exec -T db psql -U postgres ai_saas < backup.sql
```

### Backup Files

```bash
tar -czf uploaded_files_backup.tar.gz backend/uploaded_files/
```

## Performance Optimization

### Frontend
- Built files are cached by nginx
- Gzip compression enabled
- Static assets have long cache times

### Backend
- Use Gunicorn with multiple workers
- Enable Redis caching
- Configure database connection pooling

### Database
- Regular vacuuming
- Proper indexing
- Connection pooling

## Security Best Practices

1. **Change default passwords**
2. **Use strong secret keys**
3. **Enable HTTPS in production**
4. **Restrict database access**
5. **Use Docker secrets for sensitive data**
6. **Regular security updates**
7. **Scan images for vulnerabilities:**
```bash
docker scan backend
docker scan frontend
```

## Useful Docker Compose Patterns

### Override for Development

Create `docker-compose.override.yml`:
```yaml
version: '3.8'
services:
  backend:
    volumes:
      - ./backend:/app
    environment:
      - FLASK_DEBUG=True
```

### Environment-Specific Configs

```bash
# Development
docker-compose up

# Production
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up

# Staging
docker-compose -f docker-compose.yml -f docker-compose.staging.yml up
```

## Next Steps

1. ✅ Start the application
2. ✅ Register a user account
3. ✅ Upload test files
4. ✅ Monitor logs and performance
5. ✅ Configure production settings
6. ✅ Set up CI/CD pipeline
7. ✅ Configure monitoring and alerts

## Support

For issues and questions:
- Check logs: `docker-compose logs -f`
- Review main README.md
- Check service-specific READMEs in `frontend/` and `backend/`
