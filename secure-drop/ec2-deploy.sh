#!/bin/bash

# EC2 Deployment Script for Secure Drop
# IP: 34.227.207.115

set -e

echo "🚀 Starting EC2 Deployment for Secure Drop..."
echo "📍 Target IP: 34.227.207.115"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Step 1: Check if .env exists
echo "📝 Step 1: Checking environment configuration..."
if [ ! -f .env ]; then
    print_warning ".env file not found. Creating from .env.ec2..."
    cp .env.ec2 .env
    print_status ".env file created"
    print_warning "⚠️  IMPORTANT: Generate APP_KEY before continuing!"
    echo ""
    echo "Run this command to generate APP_KEY:"
    echo "  docker-compose run --rm app php artisan key:generate"
    echo ""
    read -p "Press Enter after generating APP_KEY to continue..."
else
    print_status ".env file exists"
fi

# Step 2: Stop existing containers
echo ""
echo "🛑 Step 2: Stopping existing containers..."
docker-compose down 2>/dev/null || true
print_status "Containers stopped"

# Step 3: Pull/Build images
echo ""
echo "🐳 Step 3: Building Docker images..."
docker-compose -f docker-compose.yml -f docker-compose.ec2.yml build --no-cache
print_status "Images built successfully"

# Step 4: Start services
echo ""
echo "🚀 Step 4: Starting services..."
docker-compose -f docker-compose.yml -f docker-compose.ec2.yml up -d
print_status "Services started"

# Step 5: Wait for database
echo ""
echo "⏳ Step 5: Waiting for database to be ready..."
sleep 15
print_status "Database should be ready"

# Step 6: Run migrations
echo ""
echo "🗄️  Step 6: Running database migrations..."
docker-compose exec -T app php artisan migrate --force
print_status "Migrations completed"

# Step 7: Cache configuration
echo ""
echo "⚡ Step 7: Caching configuration..."
docker-compose exec -T app php artisan config:cache
docker-compose exec -T app php artisan route:cache
docker-compose exec -T app php artisan view:cache
print_status "Configuration cached"

# Step 8: Set permissions
echo ""
echo "🔒 Step 8: Setting permissions..."
docker-compose exec -T app chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true
print_status "Permissions set"

# Step 9: Generate API docs
echo ""
echo "📚 Step 9: Generating API documentation..."
docker-compose exec -T app php artisan scribe:generate 2>/dev/null || print_warning "Scribe not available, skipping docs generation"

# Step 10: Check container status
echo ""
echo "📊 Step 10: Checking container status..."
docker-compose ps

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_status "Deployment completed successfully!"
echo ""
echo "🌐 Access your application at:"
echo "   http://34.227.207.115"
echo ""
echo "📚 API Documentation:"
echo "   http://34.227.207.115/docs"
echo ""
echo "🔍 Health Check:"
echo "   http://34.227.207.115/up"
echo ""
echo "📝 Useful commands:"
echo "   View logs:        docker-compose logs -f app"
echo "   Check status:     docker-compose ps"
echo "   Run tests:        docker-compose exec app php artisan test"
echo "   Cleanup secrets:  docker-compose exec app php artisan secrets:cleanup"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
