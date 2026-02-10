#!/bin/bash

# Secure Drop - EC2 Setup Script
# Run this on your EC2 instance to prepare for deployment

set -e

echo "🚀 Secure Drop - EC2 Setup Script"
echo "=================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "⚠️  Please do not run as root. Run as ubuntu user."
    exit 1
fi

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker
echo "🐳 Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "✅ Docker installed"
else
    echo "✅ Docker already installed"
fi

# Install Docker Compose
echo "🔧 Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose installed"
else
    echo "✅ Docker Compose already installed"
fi

# Install Git
echo "📚 Installing Git..."
if ! command -v git &> /dev/null; then
    sudo apt install -y git
    echo "✅ Git installed"
else
    echo "✅ Git already installed"
fi

# Create application directory
echo "📁 Creating application directory..."
sudo mkdir -p /opt/secure-drop
sudo chown $USER:$USER /opt/secure-drop
echo "✅ Directory created: /opt/secure-drop"

# Configure UFW firewall
echo "🔒 Configuring firewall..."
if command -v ufw &> /dev/null; then
    sudo ufw --force enable
    sudo ufw allow 22/tcp
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw status
    echo "✅ Firewall configured"
else
    echo "⚠️  UFW not found, skipping firewall setup"
fi

# Enable automatic security updates
echo "🛡️  Enabling automatic security updates..."
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
echo "✅ Automatic updates enabled"

# Display versions
echo ""
echo "📊 Installed Versions:"
echo "====================="
docker --version
docker-compose --version
git --version

echo ""
echo "✅ EC2 Setup Complete!"
echo ""
echo "📝 Next Steps:"
echo "1. Logout and login again for Docker group changes:"
echo "   exit"
echo "   ssh -i your-key.pem ubuntu@your-ec2-ip"
echo ""
echo "2. Clone your repository:"
echo "   cd /opt/secure-drop"
echo "   git clone https://github.com/YOUR_USERNAME/secure-drop.git ."
echo ""
echo "3. Configure environment:"
echo "   cp .env.example .env"
echo "   nano .env"
echo ""
echo "4. Login to GitHub Container Registry:"
echo "   echo YOUR_PAT_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin"
echo ""
echo "5. Pull and start services:"
echo "   docker pull ghcr.io/YOUR_USERNAME/secure-drop:latest"
echo "   docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d"
echo ""
echo "6. Run migrations:"
echo "   docker-compose exec app php artisan migrate --force"
echo ""
echo "🌐 Your application will be available at:"
echo "   http://$(curl -s ifconfig.me)"
echo ""
