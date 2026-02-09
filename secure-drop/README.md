# Secure Drop - Burn-on-Read Secret Sharing Service

A scalable, secure service for sharing sensitive information with automatic deletion after reading.

## Features

- **Burn on Read**: Secrets are permanently deleted after first access
- **Optional TTL**: Set expiration time for secrets
- **Encrypted Storage**: All secrets encrypted in database using Laravel's encryption
- **UUID-based IDs**: Non-sequential, secure identifiers
- **Service-Repository Pattern**: Clean architecture with separation of concerns
- **Docker Containerized**: Multi-stage builds for minimal image size
- **Traefik Integration**: Reverse proxy with automatic HTTPS
- **CI/CD Pipeline**: Automated testing, security scanning, and deployment
- **API Documentation**: Auto-generated docs at `/docs`

## Architecture

```
┌─────────────┐
│   Traefik   │ (Reverse Proxy + SSL)
└──────┬──────┘
       │
┌──────▼──────┐
│    Nginx    │ (Web Server)
└──────┬──────┘
       │
┌──────▼──────┐
│  PHP-FPM    │ (Application)
│  (Laravel)  │
└──────┬──────┘
       │
┌──────▼──────┐
│    MySQL    │ (Database)
└─────────────┘
```

### Service-Repository Pattern

- **Controller** → Handles HTTP requests/responses
- **Service** → Business logic layer
- **Repository** → Database operations
- **Model** → Data representation

## API Endpoints

### POST /api/v1/secrets
Create a new secret.

**Request:**
```json
{
  "content": "MySecretPassword123",
  "ttl_minutes": 60
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "id": "9d4e5f6a-7b8c-9d0e-1f2a-3b4c5d6e7f8a",
    "url": "http://localhost/api/v1/secrets/9d4e5f6a-7b8c-9d0e-1f2a-3b4c5d6e7f8a",
    "expires_at": "2026-02-09T20:30:00.000000Z"
  }
}
```

### GET /api/v1/secrets/{id}
Retrieve and delete a secret (burn on read).

**Response (200):**
```json
{
  "success": true,
  "data": {
    "content": "MySecretPassword123",
    "created_at": "2026-02-09T19:30:00.000000Z"
  }
}
```

**Response (404):**
```json
{
  "success": false,
  "message": "Secret not found or has expired"
}
```

## Local Development Setup

### Prerequisites
- Docker & Docker Compose
- Git

### One-Command Setup

```bash
git clone <repository-url>
cd secure-drop
cp .env.example .env
docker-compose up -d
docker-compose exec app php artisan key:generate
docker-compose exec app php artisan migrate
```

Access the application:
- API: http://localhost:8000
- Documentation: http://localhost:8000/docs

### With Traefik (Local)

```bash
docker-compose -f docker-compose.yml up -d
```

Access via: http://secure-drop.localhost

## Production Deployment

### Environment Variables

Create `.env` file with:

```env
APP_ENV=production
APP_DEBUG=false
APP_KEY=<generate-with-artisan>
APP_URL=https://your-domain.com

DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=secure_drop
DB_USERNAME=secure_drop
DB_PASSWORD=<strong-password>

DOMAIN=your-domain.com
ACME_EMAIL=admin@your-domain.com
```

### Deploy to VPS

```bash
# On VPS
git clone <repository-url> /opt/secure-drop
cd /opt/secure-drop
cp .env.example .env
# Edit .env with production values
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
docker-compose exec app php artisan key:generate
docker-compose exec app php artisan migrate --force
docker-compose exec app php artisan config:cache
docker-compose exec app php artisan route:cache
```

## Traefik Configuration

### Labels Explained

**Local Development:**
```yaml
- "traefik.enable=true"
- "traefik.http.routers.secure-drop.rule=Host(`secure-drop.localhost`)"
- "traefik.http.routers.secure-drop.entrypoints=web"
```

**Production:**
```yaml
- "traefik.enable=true"
- "traefik.http.routers.secure-drop.rule=Host(`your-domain.com`)"
- "traefik.http.routers.secure-drop.entrypoints=websecure"
- "traefik.http.routers.secure-drop.tls.certresolver=letsencrypt"
```

### Key Features:
- Automatic HTTPS with Let's Encrypt
- HTTP to HTTPS redirect
- Docker label-based configuration
- No manual nginx/Apache configuration needed

## CI/CD Pipeline

### GitHub Actions Workflow

1. **Lint & Test**
   - Run Laravel Pint (code style)
   - Execute PHPUnit tests

2. **Security Scan**
   - Build Docker image
   - Run Trivy vulnerability scanner
   - Upload results to GitHub Security

3. **Build & Push**
   - Build optimized Docker image
   - Push to GitHub Container Registry (GHCR)

4. **Deploy**
   - SSH to VPS
   - Pull latest image
   - Run migrations
   - Cache configuration

### Required Secrets

Add these to GitHub repository secrets:
- `VPS_HOST`: Your VPS IP/hostname
- `VPS_USERNAME`: SSH username
- `VPS_SSH_KEY`: Private SSH key

## Security Features

- **Non-root User**: Application runs as `appuser` (UID 1000)
- **Encrypted Storage**: Laravel encryption for all secrets
- **Minimal Image**: Alpine-based, multi-stage build
- **Health Checks**: Container health monitoring
- **Input Validation**: Request validation with size limits
- **No Sequential IDs**: UUID-based identifiers

## Testing

```bash
# Run all tests
docker-compose exec app php artisan test

# Run with coverage
docker-compose exec app php artisan test --coverage

# Run specific test
docker-compose exec app php artisan test --filter=SecretApiTest
```

## Maintenance

### Cleanup Expired Secrets

```bash
docker-compose exec app php artisan secrets:cleanup
```

### Schedule in Production

Add to crontab:
```bash
* * * * * cd /opt/secure-drop && docker-compose exec -T app php artisan schedule:run >> /dev/null 2>&1
```

## API Documentation

Generate documentation:
```bash
docker-compose exec app php artisan scribe:generate
```

Access at: http://localhost:8000/docs

## Monitoring

### Health Check Endpoint

```bash
curl http://localhost:8000/up
```

### Container Health

```bash
docker-compose ps
```

## Troubleshooting

### Permission Issues
```bash
docker-compose exec app chown -R appuser:appuser storage bootstrap/cache
```

### Clear Cache
```bash
docker-compose exec app php artisan cache:clear
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan route:clear
```

### View Logs
```bash
docker-compose logs -f app
docker-compose logs -f nginx
```

## License

MIT License
