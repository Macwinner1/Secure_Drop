#!/bin/bash

# Secure Drop Local Development Setup Script

set -e

echo "🚀 Setting up Secure Drop for local development..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Copy .env if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file from .env.example..."
    cp .env.example .env
else
    echo "✅ .env file already exists"
fi

# Build and start containers
echo "🐳 Building and starting Docker containers..."
docker-compose up -d --build

# Wait for containers to be ready
echo "⏳ Waiting for containers to be ready..."
sleep 10

# Install dependencies
echo "📦 Installing Composer dependencies..."
docker-compose exec app composer install

# Generate application key
echo "🔑 Generating application key..."
docker-compose exec app php artisan key:generate

# Run migrations
echo "🗄️  Running database migrations..."
docker-compose exec app php artisan migrate

# Generate API documentation
echo "📚 Generating API documentation..."
docker-compose exec app php artisan scribe:generate

# Set proper permissions
echo "🔒 Setting proper permissions..."
docker-compose exec app chown -R appuser:appuser storage bootstrap/cache

echo ""
echo "✅ Setup completed successfully!"
echo ""
echo "🌐 Application URLs:"
echo "   - API: http://localhost:8000"
echo "   - Documentation: http://localhost:8000/docs"
echo "   - Health Check: http://localhost:8000/up"
echo ""
echo "📝 Useful commands:"
echo "   - View logs: docker-compose logs -f"
echo "   - Run tests: docker-compose exec app php artisan test"
echo "   - Cleanup secrets: docker-compose exec app php artisan secrets:cleanup"
echo "   - Stop containers: docker-compose down"
echo ""
