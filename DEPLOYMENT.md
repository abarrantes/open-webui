# Open WebUI Production Deployment Guide

This guide will help you deploy your Open WebUI fork to a Hetzner Cloud VPS with a Rails-developer-friendly workflow similar to Kamal.

## 🎯 Overview

This deployment setup provides:
- **Zero-downtime deployments** with Docker Compose
- **Automatic SSL certificates** via Let's Encrypt
- **GitHub Actions CI/CD** for automated deployments
- **OpenAI integration** (no local LLM required)
- **Production-ready security** configuration

## 📋 Prerequisites

1. **Hetzner Cloud VPS** - Any size works (CPX11 is sufficient for moderate usage)
2. **Domain name** pointed to your server's IP
3. **OpenAI API key** from your OpenAI subscription
4. **GitHub repository** (your fork of Open WebUI)

## 🚀 Quick Start

### 1. Server Setup

SSH into your Hetzner VPS and run the setup script:

```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/yourrepo/main/deploy/setup-server.sh | sudo bash
```

This script will:
- Install Docker and Docker Compose
- Configure firewall and security
- Create a deploy user
- Set up automatic backups

### 2. Repository Setup

Update the deployment script with your repository URL:

```bash
# Edit deploy/setup-server.sh and update this line:
REPO_URL="https://github.com/yourusername/yourrepo.git"
```

### 3. Environment Configuration

On your server, configure your environment:

```bash
sudo su - deploy
cd /opt/open-webui
git clone https://github.com/yourusername/yourrepo.git .
cp .env.production.example .env.production
nano .env.production  # Configure your settings
```

**Required settings in `.env.production`:**
- `OPENAI_API_KEY` - Your OpenAI API key
- `DOMAIN` - Your domain (e.g., openwebui.yourdomain.com)
- `ACME_EMAIL` - Your email for Let's Encrypt
- `WEBUI_SECRET_KEY` - Generate with `openssl rand -base64 32`

### 4. GitHub Secrets

Add these secrets to your GitHub repository:

```
PRODUCTION_HOST=your-server-ip
PRODUCTION_USERNAME=deploy
PRODUCTION_SSH_KEY=your-private-ssh-key
PRODUCTION_PATH=/opt/open-webui
```

### 5. Deploy

#### Manual Deployment
```bash
sudo su - deploy
cd /opt/open-webui
./deploy.sh
```

#### Automatic Deployment
Push to main branch - GitHub Actions will automatically deploy!

## 🔧 Configuration Details

### Docker Compose Structure

The production setup uses:
- **open-webui**: Main application container
- **traefik**: Reverse proxy with automatic SSL

### Key Features Enabled

- ✅ OpenAI API integration
- ✅ Web search (DuckDuckGo by default)
- ✅ Image generation (DALL-E)
- ✅ Document RAG
- ✅ Automatic SSL certificates
- ✅ Data persistence
- ❌ Ollama (disabled for cost efficiency)
- ❌ User registration (disabled by default)

## 🎛️ Environment Variables

### Essential Configuration

```bash
# OpenAI (Required)
OPENAI_API_KEY=sk-your-key-here
OPENAI_API_BASE_URL=https://api.openai.com/v1

# Domain & SSL (Required)
DOMAIN=openwebui.yourdomain.com
ACME_EMAIL=you@yourdomain.com

# Security (Required)
WEBUI_SECRET_KEY=your-secure-secret-here

# Application
WEBUI_NAME="My Open WebUI"
DEFAULT_MODELS=gpt-4,gpt-3.5-turbo
```

### Optional Enhancements

```bash
# Web Search
ENABLE_WEB_SEARCH=true
WEB_SEARCH_ENGINE=duckduckgo

# Google Search (if preferred)
GOOGLE_PSE_API_KEY=your-google-api-key
GOOGLE_PSE_ENGINE_ID=your-search-engine-id

# Features
ENABLE_IMAGE_GENERATION=true
ENABLE_MESSAGE_RATING=true
ENABLE_SIGNUP=false  # Keep false for private instance
```

## 🔒 Security Features

### Automatic Security Setup
- **Firewall**: Only ports 22, 80, 443 open
- **Fail2ban**: Protects against brute force attacks
- **SSL**: Automatic Let's Encrypt certificates
- **Docker**: Non-root container execution

### Additional Recommendations
```bash
# Change SSH port (edit /etc/ssh/sshd_config)
Port 2222

# Disable password auth (use SSH keys only)
PasswordAuthentication no

# Restart SSH
sudo systemctl restart ssh
```

## 📊 Monitoring & Maintenance

### Health Checks

Check service status:
```bash
cd /opt/open-webui
docker-compose -f docker-compose.prod.yml --env-file .env.production ps
```

View logs:
```bash
docker-compose -f docker-compose.prod.yml --env-file .env.production logs -f open-webui
```

### Backups

Automatic daily backups are configured. Manual backup:
```bash
cd /opt/open-webui
./backup.sh
```

Backups are stored in `/opt/backups/` and kept for 7 days.

### Updates

**Automatic via GitHub Actions:**
1. Push to main branch
2. GitHub Actions builds and deploys automatically

**Manual updates:**
```bash
cd /opt/open-webui
./deploy.sh
```

## 🚨 Troubleshooting

### Common Issues

**1. SSL Certificate Issues**
```bash
# Check Traefik logs
docker logs traefik-prod

# Ensure domain points to server IP
dig yourdomain.com
```

**2. OpenAI API Errors**
```bash
# Check OpenAI API key in environment
docker-compose -f docker-compose.prod.yml --env-file .env.production exec open-webui env | grep OPENAI
```

**3. Database/Data Issues**
```bash
# Check volume mounts
docker volume ls
docker volume inspect open-webui_open-webui-data
```

### Service Recovery

If services are down:
```bash
cd /opt/open-webui
docker-compose -f docker-compose.prod.yml --env-file .env.production down
docker-compose -f docker-compose.prod.yml --env-file .env.production up -d
```

## 💰 Cost Optimization

### Hetzner Cloud Sizing
- **CPX11** (2 vCPU, 4GB RAM): €4.15/month - Good for personal use
- **CPX21** (3 vCPU, 8GB RAM): €8.21/month - Better for multiple users
- **CPX31** (4 vCPU, 16GB RAM): €16.90/month - Production ready

### OpenAI Usage Tips
- Set reasonable rate limits in Open WebUI
- Monitor usage in OpenAI dashboard
- Consider using GPT-3.5-turbo for general queries and GPT-4 for complex tasks

## 🔄 Kamal-style Workflows

This setup mimics Kamal's simplicity:

```bash
# Deploy (like `kamal deploy`)
./deploy.sh

# Check status (like `kamal app status`)
docker-compose -f docker-compose.prod.yml ps

# View logs (like `kamal app logs`)
docker-compose -f docker-compose.prod.yml logs -f

# Access container (like `kamal app exec`)
docker-compose -f docker-compose.prod.yml exec open-webui bash
```

## 🎉 Next Steps

1. **Customize**: Modify branding, features, and models in `.env.production`
2. **Monitor**: Set up monitoring with tools like Uptime Kuma
3. **Scale**: Add more servers with load balancing if needed
4. **Integrate**: Connect additional services (Redis, external databases)

## 📝 Testing GitHub Actions Deployment

The GitHub Actions workflow is configured and ready to deploy automatically on every push to main branch.

Testing SSH authentication fix for automated deployment.

---

**Enjoy your production Open WebUI deployment! 🚀**

For issues, check the [troubleshooting section](#-troubleshooting) or open an issue in your repository.