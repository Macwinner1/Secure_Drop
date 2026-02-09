#!/bin/bash

# Secure Drop Deployment Script

set -e

echo "🚀 Starting Secure Drop deployment..."

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ .env file not found. Copying from .env.example..."
    cp .env.example .env
    echo "⚠️  Please update .env with your configuration and run again."
    exit 1
fi

# Pull latest changes
echo "📥 Pulling latest changes..."
git pull origin main

# Build and start containers
echo "🐳 Building and starting Docker containers..."
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build

# Wait for database
echo "⏳ Waiting for database..."
sleep 10

# Run migrations
echo "🗄️  Running database migrations..."
docker-compose exec -T app php artisan migrate --force

# Cache configuration
echo "⚡ Caching configuration..."
docker-compose exec -T app php artisan config:cache
docker-compose exec -T app php artisan route:cache
docker-compose exec -T app php artisan view:cache

# Generate API documentation
echo "📚 Generating API documentation..."
docker-compose exec -T app php artisan scribe:generate

# Cleanup expired secrets
echo "🧹 Cleaning up expired secrets..."
docker-compose exec -T app php artisan secrets:cleanup

echo "✅ Deployment completed successfully!"
echo "🌐 Application is running at: ${APP_URL:-http://localhost:8000}"
