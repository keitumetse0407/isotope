#!/bin/bash
# ISOTOPE Automation Stack — Deployment Script
# Run on VPS: ./deploy_automation.sh
# VPS: 185.167.97.193 | Ubuntu 22.04

set -e

echo "🚀 ISOTOPE Automation Stack Deployment"
echo "======================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root (sudo ./deploy_automation.sh)"
  exit 1
fi

# Check if .env exists
if [ ! -f automation/.env ]; then
  echo "❌ .env file not found!"
  echo "   Copy automation/.env.example to automation/.env and fill in your values"
  exit 1
fi

# Load environment variables
set -a
source automation/.env
set +a

echo "✅ Environment loaded"
echo ""

# ============================================
# STEP 1: Install Docker (if not installed)
# ============================================
echo "📦 Step 1: Checking Docker installation..."
if ! command -v docker &> /dev/null; then
  echo "   Installing Docker..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  rm get-docker.sh
  echo "✅ Docker installed"
else
  echo "✅ Docker already installed"
fi

echo ""

# ============================================
# STEP 2: Install Docker Compose (if not installed)
# ============================================
echo "📦 Step 2: Checking Docker Compose installation..."
if ! command -v docker-compose &> /dev/null; then
  echo "   Installing Docker Compose..."
  apt-get update
  apt-get install -y docker-compose
  echo "✅ Docker Compose installed"
else
  echo "✅ Docker Compose already installed"
fi

echo ""

# ============================================
# STEP 3: Create Required Directories
# ============================================
echo "📁 Step 3: Creating required directories..."
mkdir -p automation/n8n-data
mkdir -p automation/waha-sessions
mkdir -p automation/nginx/ssl
mkdir -p data
chmod 755 automation/n8n-data
chmod 755 automation/waha-sessions
echo "✅ Directories created"
echo ""

# ============================================
# STEP 4: Pull Docker Images
# ============================================
echo "📥 Step 4: Pulling Docker images..."
cd automation
docker-compose pull
echo "✅ Images pulled"
echo ""

# ============================================
# STEP 5: Start Services
# ============================================
echo "🚀 Step 5: Starting services..."
docker-compose up -d
echo "✅ Services started"
echo ""

# ============================================
# STEP 6: Wait for Services to be Ready
# ============================================
echo "⏳ Step 6: Waiting for services to be ready..."
sleep 30

# Check n8n health
if curl -s http://localhost:5678/healthz > /dev/null; then
  echo "✅ n8n is running (port 5678)"
else
  echo "⚠️  n8n may still be starting..."
fi

# Check WAHA health
if curl -s http://localhost:8765/health > /dev/null; then
  echo "✅ WAHA is running (port 8765)"
else
  echo "⚠️  WAHA may still be starting..."
fi

# Check FastAPI health
if curl -s http://localhost:8100/health > /dev/null; then
  echo "✅ FastAPI is running (port 8100)"
else
  echo "⚠️  FastAPI may still be starting..."
fi

echo ""

# ============================================
# STEP 7: Display Access Information
# ============================================
echo "======================================"
echo "🎉 DEPLOYMENT COMPLETE!"
echo "======================================"
echo ""
echo "📊 Service Access:"
echo "   n8n Dashboard:    http://${VPS_IP}:5678"
echo "   WAHA API:         http://${VPS_IP}:8765"
echo "   FastAPI:          http://${VPS_IP}:8100"
echo "   Telegram Bot:     t.me/ISOTOPE_Signals_bot"
echo ""
echo "🔐 n8n Login:"
echo "   Username: ${N8N_ADMIN_USER}"
echo "   Password: ${N8N_ADMIN_PASSWORD}"
echo ""
echo "📱 Next Steps:"
echo "   1. Login to n8n dashboard"
echo "   2. Import workflows from automation/n8n-workflows/"
echo "   3. Scan WAHA QR code (see WAHA dashboard)"
echo "   4. Test Telegram bot: t.me/ISOTOPE_Signals_bot"
echo ""
echo "📄 Logs:"
echo "   docker-compose logs -f n8n"
echo "   docker-compose logs -f waha"
echo "   docker-compose logs -f telegram-bot"
echo "   docker-compose logs -f fastapi"
echo ""
echo "🛑 Stop Services:"
echo "   cd automation && docker-compose down"
echo ""
echo "======================================"
echo "Built by Elkai | ELEV8 DIGITAL"
echo "======================================"
