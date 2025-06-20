#!/bin/bash

# Open WebUI Production Server Setup Script for Hetzner Cloud
# This script prepares a fresh Ubuntu server for Open WebUI deployment
# Run as root: curl -fsSL https://raw.githubusercontent.com/yourusername/yourrepo/main/deploy/setup-server.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
APP_USER="deploy"
APP_DIR="/opt/open-webui"
DOCKER_COMPOSE_VERSION="2.24.0"

echo -e "${GREEN}🚀 Starting Open WebUI server setup...${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script must be run as root${NC}"
   exit 1
fi

# Update system
echo -e "${YELLOW}📦 Updating system packages...${NC}"
apt-get update -y
apt-get upgrade -y

# Install essential packages
echo -e "${YELLOW}🔧 Installing essential packages...${NC}"
apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    ufw \
    fail2ban \
    htop \
    jq

# Create deploy user
echo -e "${YELLOW}👤 Creating deploy user...${NC}"
if ! id "$APP_USER" &>/dev/null; then
    useradd -m -s /bin/bash $APP_USER
    usermod -aG sudo $APP_USER
    
    # Set up SSH for deploy user (optional - you can copy your key manually)
    mkdir -p /home/$APP_USER/.ssh
    chmod 700 /home/$APP_USER/.ssh
    chown $APP_USER:$APP_USER /home/$APP_USER/.ssh
    
    echo -e "${GREEN}✅ User $APP_USER created${NC}"
else
    echo -e "${YELLOW}ℹ️  User $APP_USER already exists${NC}"
fi

# Install Docker
echo -e "${YELLOW}🐳 Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    
    # Add deploy user to docker group
    usermod -aG docker $APP_USER
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    echo -e "${GREEN}✅ Docker installed${NC}"
else
    echo -e "${YELLOW}ℹ️  Docker already installed${NC}"
fi

# Install Docker Compose
echo -e "${YELLOW}🔧 Installing Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    echo -e "${GREEN}✅ Docker Compose installed${NC}"
else
    echo -e "${YELLOW}ℹ️  Docker Compose already installed${NC}"
fi

# Create application directory
echo -e "${YELLOW}📁 Setting up application directory...${NC}"
mkdir -p $APP_DIR
chown $APP_USER:$APP_USER $APP_DIR

# Configure firewall
echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo -e "${GREEN}✅ Firewall configured${NC}"

# Configure fail2ban
echo -e "${YELLOW}🛡️  Configuring fail2ban...${NC}"
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
EOF

systemctl enable fail2ban
systemctl start fail2ban

echo -e "${GREEN}✅ Fail2ban configured${NC}"

# Set up log rotation for Docker
echo -e "${YELLOW}📝 Configuring Docker log rotation...${NC}"
cat > /etc/docker/daemon.json << EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

systemctl restart docker

# Create deployment script
echo -e "${YELLOW}📝 Creating deployment helper script...${NC}"
cat > $APP_DIR/deploy.sh << 'EOF'
#!/bin/bash

# Open WebUI Deployment Helper Script
# Usage: ./deploy.sh [branch]

set -e

BRANCH=${1:-main}
REPO_URL="https://github.com/abarrantes/open-webui.git"  # UPDATE THIS WITH YOUR ACTUAL REPO
APP_DIR="/opt/open-webui"

echo "🚀 Deploying Open WebUI from branch: $BRANCH"

cd $APP_DIR

# Pull latest code
if [ -d ".git" ]; then
    git fetch origin
    git checkout $BRANCH
    git pull origin $BRANCH
else
    git clone -b $BRANCH $REPO_URL .
fi

# Check if .env.production exists
if [ ! -f ".env.production" ]; then
    echo "❌ .env.production file not found!"
    echo "📝 Please copy .env.production.example to .env.production and configure it"
    exit 1
fi

# Deploy
echo "🔄 Deploying..."
docker-compose -f docker-compose.prod.yml --env-file .env.production pull
docker-compose -f docker-compose.prod.yml --env-file .env.production up -d --remove-orphans

# Clean up old images
docker image prune -f --filter "until=72h"

echo "✅ Deployment complete!"
echo "🌐 Your Open WebUI should be available at your configured domain"
EOF

chmod +x $APP_DIR/deploy.sh
chown $APP_USER:$APP_USER $APP_DIR/deploy.sh

# Create backup script
echo -e "${YELLOW}💾 Creating backup script...${NC}"
cat > $APP_DIR/backup.sh << 'EOF'
#!/bin/bash

# Open WebUI Backup Script
# Creates a backup of data and configuration

set -e

APP_DIR="/opt/open-webui"
BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

echo "📦 Creating backup: $DATE"

# Stop services
cd $APP_DIR
docker-compose -f docker-compose.prod.yml --env-file .env.production stop

# Create backup
tar -czf "$BACKUP_DIR/open-webui-backup-$DATE.tar.gz" \
    -C /var/lib/docker/volumes \
    open-webui_open-webui-data \
    open-webui_letsencrypt-data

# Backup config files
cp .env.production "$BACKUP_DIR/env-production-$DATE"
cp docker-compose.prod.yml "$BACKUP_DIR/docker-compose-prod-$DATE.yml"

# Restart services
docker-compose -f docker-compose.prod.yml --env-file .env.production start

# Clean old backups (keep last 7 days)
find $BACKUP_DIR -name "open-webui-backup-*.tar.gz" -mtime +7 -delete

echo "✅ Backup completed: $BACKUP_DIR/open-webui-backup-$DATE.tar.gz"
EOF

chmod +x $APP_DIR/backup.sh
chown $APP_USER:$APP_USER $APP_DIR/backup.sh

# Set up automatic backups (optional)
echo -e "${YELLOW}⏰ Setting up daily backups...${NC}"
(crontab -u $APP_USER -l 2>/dev/null; echo "0 2 * * * $APP_DIR/backup.sh >> /var/log/open-webui-backup.log 2>&1") | crontab -u $APP_USER -

echo -e "${GREEN}🎉 Server setup complete!${NC}"
echo ""
echo -e "${YELLOW}📋 Next steps:${NC}"
echo "1. Switch to deploy user: sudo su - $APP_USER"
echo "2. Go to app directory: cd $APP_DIR"
echo "3. Clone your repository or copy files"
echo "4. Copy .env.production.example to .env.production and configure it"
echo "5. Run: ./deploy.sh"
echo ""
echo -e "${YELLOW}🔒 Security recommendations:${NC}"
echo "- Change SSH port (edit /etc/ssh/sshd_config)"
echo "- Disable password authentication (use SSH keys only)"
echo "- Consider setting up a VPN for admin access"
echo ""
echo -e "${GREEN}✅ Happy deploying! 🚀${NC}"