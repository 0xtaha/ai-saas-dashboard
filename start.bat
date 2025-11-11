@echo off
REM AI SaaS Dashboard - Quick Start Script for Windows

echo Starting AI SaaS Dashboard...

REM Check if .env exists
if not exist .env (
    echo Creating .env file from .env.example...
    copy .env.example .env
    echo Please edit .env with your configuration before proceeding
    exit /b 1
)

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo Docker is not running. Please start Docker Desktop and try again.
    exit /b 1
)

REM Build and start services
echo Building Docker containers...
docker-compose build

echo Starting services...
docker-compose up -d

echo.
echo Waiting for services to be ready...
timeout /t 5 /nobreak >nul

REM Check if services are running
docker-compose ps | findstr "Up" >nul
if not errorlevel 1 (
    echo.
    echo Services started successfully!
    echo.
    echo Access points:
    echo    Frontend: http://localhost:3000
    echo    Backend:  http://localhost:5000
    echo    Database: localhost:5432
    echo.
    echo View logs with: docker-compose logs -f
    echo Stop services with: docker-compose down
    echo.

    REM Initialize database
    echo Initializing database...
    docker-compose exec -T backend python scripts/init_db.py 2>nul

    echo.
    echo Setup complete! Visit http://localhost:3000 to get started
) else (
    echo Failed to start services. Check logs with: docker-compose logs
    exit /b 1
)
