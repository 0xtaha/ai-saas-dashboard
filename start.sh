#!/bin/bash

# AI SaaS Dashboard - Quick Start Script

echo "🚀 Starting AI SaaS Dashboard..."

# Check if .env exists
if [ ! -f .env ]; then
    echo "📝 Creating .env file from .env.example..."
    cp .env.example .env
    echo "⚠️  Please edit .env with your configuration before proceeding"
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Build and start services
echo "🔨 Building Docker containers..."
docker-compose build

echo "🚀 Starting services..."
docker-compose up -d

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 5

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    echo ""
    echo "✅ Services started successfully!"
    echo ""
    echo "📍 Access points:"
    echo "   Frontend: http://localhost:3000"
    echo "   Backend:  http://localhost:5000"
    echo "   Database: localhost:5432"
    echo ""
    echo "📊 View logs with: docker-compose logs -f"
    echo "🛑 Stop services with: docker-compose down"
    echo ""

    # Initialize database if needed
    echo "🗄️  Initializing database..."
    docker-compose exec -T backend python scripts/init_db.py 2>/dev/null || echo "Database already initialized or backend not ready yet"

    echo ""
    echo "🎉 Setup complete! Visit http://localhost:3000 to get started"
else
    echo "❌ Failed to start services. Check logs with: docker-compose logs"
    exit 1
fi
