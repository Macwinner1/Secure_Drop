# Secure Drop - Deployment Guide

This guide will help you deploy Secure Drop to AWS EC2 using GitHub Actions and GHCR (GitHub Container Registry).

## 📋 Prerequisites

- GitHub account with repository
- AWS EC2 instance (t2.micro or larger)
- Domain name (optional, but recommended)
- SSH access to EC2 instance

## 🚀 Quick Start

### Step 1: Enable GitHub Container Registry

1. Go to your GitHub repository
2. Navigate to **Settings** → **Actions** → **General**
3. Under "Workflow permissions", select:
   - ✅ **Read and write permissions**
   - ✅ **Allow GitHub Actions to create and approve pull requests**
4. Click **Save**

### Step 2: Set Up EC2 Instance

#### Launch EC2 Instance
```bash
# Instance Type: t2.micro (Free Tier)
# OS: Ubuntu 22.04 LTS
# Security Group: Allow ports 22, 80, 443
```

#### Connect to EC2
```bash
ssh -i your-key.pem ubuntu@your-ec2-ip
```

#### Install Docker & Docker Compose
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version

# Logout and login again for group changes to take effect
exit
```

### Step 3: Prepare EC2 for Deployment

```bash
# SSH back into EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# Create application directory
sudo mkdir -p /opt/secure-drop
sudo chown $USER:$USER /opt/secure-drop
cd /opt/secure-drop

# Clone repository (or create files manually)
git clone https://github.com/YOUR_USERNAME/secure-drop.git .

# Create .env file
cp .env.example .env
nano .env
```

#### Configure .env for Production
```env
APP_NAME="Secure Drop"
APP_ENV=production
APP_KEY=base64:YOUR_KEY_HERE  # Generate with: php artisan key:generate
APP_DEBUG=false
APP_URL=https://yourdomain.com

DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=secure_drop
DB_USERNAME=secure_drop
DB_PASSWORD=STRONG_PASSWORD_HERE

# Traefik Configuration
DOMAIN=yourdomain.com
ACME_EMAIL=admin@yourdomain.com

# GitHub Container Registry
GITHUB_USERNAME=your-github-username
```

### Step 4: Configure GitHub Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**

Add the following secrets:

| Secret Name | Value | Description |
|------------|-------|-------------|
| `VPS_HOST` | `your-ec2-ip` | EC2 public IP address |
| `VPS_USERNAME` | `ubuntu` | SSH username (usually ubuntu) |
| `VPS_SSH_KEY` | `<private-key>` | Your EC2 private key content |

#### How to get VPS_SSH_KEY:
```bash
# On your local machine
cat your-key.pem
# Copy the entire content including:
# -----BEGIN RSA PRIVATE KEY-----
# ...
# -----END RSA PRIVATE KEY-----
```

### Step 5: Make Your Repository Public (or Configure GHCR Access)

#### Option A: Public Repository (Easiest)
- Go to **Settings** → **General** → **Danger Zone**
- Click "Change visibility" → "Make public"

#### Option B: Private Repository with PAT
1. Create Personal Access Token:
   - Go to GitHub **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
   - Click "Generate new token (classic)"
   - Select scopes: `read:packages`, `write:packages`
   - Copy the token

2. On EC2, login to GHCR:
```bash
echo YOUR_PAT_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin
```

### Step 6: Initial Deployment

On your EC2 instance:

```bash
cd /opt/secure-drop

# Login to GHCR (if private repo)
echo YOUR_PAT_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# Set GitHub username in .env
export GITHUB_USERNAME=your-github-username

# Pull the image
docker pull ghcr.io/$GITHUB_USERNAME/secure-drop:latest

# Start services
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Generate application key (if not set in .env)
docker-compose exec app php artisan key:generate

# Run migrations
docker-compose exec app php artisan migrate --force

# Cache configuration
docker-compose exec app php artisan config:cache
docker-compose exec app php artisan route:cache

# Generate API documentation
docker-compose exec app php artisan scribe:generate
```

### Step 7: Configure Domain (Optional)

#### Update DNS Records
```
Type: A
Name: @ (or subdomain)
Value: YOUR_EC2_IP
TTL: 300
```

#### Wait for DNS propagation (5-30 minutes)
```bash
# Check DNS
nslookup yourdomain.com
```

#### Traefik will automatically:
- Request SSL certificate from Let's Encrypt
- Configure HTTPS
- Redirect HTTP to HTTPS

### Step 8: Trigger GitHub Action

Push to main branch to trigger the workflow:

```bash
git add .
git commit -m "Initial deployment setup"
git push origin main
```

Monitor the workflow:
- Go to **Actions** tab in GitHub
- Watch the pipeline: Lint → Test → Security Scan → Build & Push → Deploy

## 📦 GitHub Container Registry

### View Your Images

Visit: `https://github.com/YOUR_USERNAME?tab=packages`

### Pull Image Manually

```bash
# Public image
docker pull ghcr.io/YOUR_USERNAME/secure-drop:latest

# Private image (requires authentication)
echo YOUR_PAT_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin
docker pull ghcr.io/YOUR_USERNAME/secure-drop:latest
```

### Available Tags

- `latest` - Latest main branch build
- `main-<sha>` - Specific commit from main
- `develop` - Latest develop branch build
- `develop-<sha>` - Specific commit from develop

## 🔧 Maintenance

### View Logs
```bash
docker-compose logs -f app
docker-compose logs -f nginx
docker-compose logs -f traefik
```

### Update Application
```bash
# Pull latest image
docker pull ghcr.io/$GITHUB_USERNAME/secure-drop:latest

# Restart services
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Run migrations
docker-compose exec app php artisan migrate --force
```

### Cleanup Expired Secrets
```bash
docker-compose exec app php artisan secrets:cleanup
```

### Backup Database
```bash
docker-compose exec db mysqldump -u secure_drop -p secure_drop > backup.sql
```

## 🔒 Security Checklist

- ✅ Change default database password in .env
- ✅ Set strong APP_KEY
- ✅ Configure firewall (UFW)
- ✅ Enable automatic security updates
- ✅ Use HTTPS (Traefik + Let's Encrypt)
- ✅ Regular backups
- ✅ Monitor logs

### Configure UFW Firewall
```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status
```

## 🌐 Access Your Application

- **HTTP**: `http://your-ec2-ip:8001` (if not using Traefik)
- **HTTPS**: `https://yourdomain.com` (with Traefik)
- **API Docs**: `https://yourdomain.com/docs`
- **Health Check**: `https://yourdomain.com/up`

## 🐛 Troubleshooting

### Container won't start
```bash
docker-compose logs app
docker-compose ps
```

### Database connection issues
```bash
# Check database is running
docker-compose exec db mysql -u secure_drop -p

# Verify .env settings
docker-compose exec app php artisan config:clear
```

### Traefik certificate issues
```bash
# Check Traefik logs
docker-compose logs traefik

# Verify domain points to EC2
nslookup yourdomain.com

# Check Let's Encrypt rate limits
# https://letsencrypt.org/docs/rate-limits/
```

### GitHub Action fails
```bash
# Check workflow logs in GitHub Actions tab
# Common issues:
# - Missing secrets (VPS_HOST, VPS_USERNAME, VPS_SSH_KEY)
# - SSH key format (must include BEGIN/END lines)
# - EC2 security group (port 22 must be open)
```

## 📊 Monitoring

### Check Application Status
```bash
curl https://yourdomain.com/up
```

### View Container Stats
```bash
docker stats
```

### Check Disk Space
```bash
df -h
docker system df
```

## 🔄 CI/CD Workflow

The GitHub Action automatically:

1. **Lint & Test** - Runs on every push/PR
2. **Security Scan** - Trivy scans Docker image
3. **Build & Push** - Builds and pushes to GHCR (main/develop only)
4. **Deploy** - Deploys to EC2 (main only)

### Manual Deployment

If you need to deploy without pushing to GitHub:

```bash
# On EC2
cd /opt/secure-drop
./deploy.sh
```

## 📝 Notes

- First deployment may take 5-10 minutes
- Let's Encrypt certificates renew automatically
- Database data persists in Docker volumes
- Logs are stored in `storage/logs/laravel.log`

## 🆘 Support

For issues:
1. Check logs: `docker-compose logs -f`
2. Review GitHub Actions workflow
3. Verify all secrets are set correctly
4. Check EC2 security groups
5. Ensure domain DNS is configured

---

**Happy Deploying! 🚀**
