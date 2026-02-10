#!/bin/bash

# Secure Drop EC2 Setup Script
# Run this on your EC2 instance: Ubuntu 24.04

set -e

echo "🚀 Setting up Secure Drop on EC2..."

# Update system
echo "📦 Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker
echo "🐳 Installing Docker..."
sudo apt-get install -y ca-certificates curl gnupg lsb-release
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose standalone
echo "📦 Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Git
echo "📦 Installing Git..."
sudo apt-get install -y git

# Create application directory
echo "📁 Creating application directory..."
sudo mkdir -p /opt/secure-drop
sudo chown -R $USER:$USER /opt/secure-drop

# Clone repository (you'll need to do this manually or provide repo URL)
echo "📥 Clone your repository:"
echo "   cd /opt/secure-drop"
echo "   git clone <your-repo-url> ."

# Create .env file
echo "📝 Creating .env file..."
cat > /opt/secure-drop/.env.example << 'EOF'
APP_NAME="Secure Drop"
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=http://YOUR_EC2_IP_HERE

LOG_CHANNEL=stack
LOG_LEVEL=error

DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=secure_drop
DB_USERNAME=secure_drop
DB_PASSWORD=CHANGE_THIS_SECURE_PASSWORD

DOMAIN=YOUR_EC2_IP_OR_DOMAIN_HERE
ACME_EMAIL=admin@example.com
EOF

echo ""
echo "✅ EC2 setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Clone your repository to /opt/secure-drop"
echo "2. Copy .env.example to .env and update values"
echo "3. Update APP_URL and DOMAIN with your EC2 IP or domain"
echo "4. Generate APP_KEY: docker-compose exec app php artisan key:generate"
echo "5. Run: cd /opt/secure-drop && ./deploy.sh"
echo ""
echo "⚠️  Make sure to:"
echo "   - Configure security group to allow ports 80, 443, 22"
echo "   - Update DOMAIN in .env if using custom domain"
echo "   - Change DB_PASSWORD to a strong password"
