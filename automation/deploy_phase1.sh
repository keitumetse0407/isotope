#!/bin/bash
# ISOTOPE Phase 1 Deployment Script
# Location: /root/isotope/automation/
# Services: n8n + WAHA + Telegram Bot

set -e

echo "========================================"
echo "ISOTOPE Phase 1 Deployment"
echo "========================================"
echo ""

# Step 1: Create required directories
echo "[1/8] Creating required directories..."
mkdir -p /root/isotope/automation/n8n-data
mkdir -p /root/isotope/automation/waha-sessions
chmod 755 /root/isotope/automation/n8n-data
chmod 755 /root/isotope/automation/waha-sessions
echo "      Done: n8n-data, waha-sessions"
echo ""

# Step 2: Verify .env exists
echo "[2/8] Checking .env file..."
if [ ! -f /root/isotope/automation/.env ]; then
    echo "ERROR: .env file not found!"
    echo "       Run: cp /root/isotope/automation/.env.example /root/isotope/automation/.env"
    echo "       Then edit with: nano /root/isotope/automation/.env"
    exit 1
fi
echo "      Done: .env found"
echo ""

# Step 3: Verify Docker is running
echo "[3/8] Checking Docker status..."
if ! systemctl is-active --quiet docker; then
    echo "ERROR: Docker is not running!"
    echo "       Run: systemctl start docker"
    exit 1
fi
echo "      Done: Docker is running"
echo ""

# Step 4: Pull all images first (avoids timeout during deploy)
echo "[4/8] Pulling Docker images (this may take 2-5 minutes)..."
cd /root/isotope/automation
docker-compose pull n8n
docker-compose pull waha
echo "      Done: Images pulled"
echo ""

# Step 5: Deploy n8n first
echo "[5/8] Starting n8n service..."
docker-compose up -d n8n
echo "      Waiting 30 seconds for n8n to initialize..."
sleep 30
echo "      Done: n8n started"
echo ""

# Step 6: Deploy WAHA second
echo "[6/8] Starting WAHA service..."
docker-compose up -d waha
echo "      Waiting 15 seconds for WAHA to initialize..."
sleep 15
echo "      Done: WAHA started"
echo ""

# Step 7: Deploy Telegram bot last
echo "[7/8] Starting Telegram bot service..."
docker-compose up -d telegram-bot
echo "      Waiting 10 seconds for bot to initialize..."
sleep 10
echo "      Done: Telegram bot started"
echo ""

# Step 8: Verify all containers are running
echo "[8/8] Verifying all services..."
echo ""
docker-compose ps
echo ""

# Health checks
echo "========================================"
echo "Health Checks"
echo "========================================"
echo ""

# Check n8n
echo -n "n8n (port 5678): "
if curl -s http://localhost:5678/healthz > /dev/null 2>&1; then
    echo "HEALTHY"
else
    echo "UNHEALTHY - Check logs: docker-compose logs n8n"
fi

# Check WAHA
echo -n "WAHA (port 8765): "
if curl -s http://localhost:8765/health > /dev/null 2>&1; then
    echo "HEALTHY"
else
    echo "UNHEALTHY - Check logs: docker-compose logs waha"
fi

# Check Telegram bot
echo -n "Telegram Bot: "
if docker ps --format '{{.Names}}' | grep -q isotope-telegram; then
    echo "RUNNING"
else
    echo "NOT RUNNING - Check logs: docker-compose logs telegram-bot"
fi

echo ""
echo "========================================"
echo "Deployment Complete!"
echo "========================================"
echo ""
echo "Access Points:"
echo "  n8n Dashboard:  http://185.167.97.193:5678"
echo "  WAHA API:       http://185.167.97.193:8765"
echo "  Telegram Bot:   t.me/YOUR_BOT_NAME?start"
echo ""
echo "Next Steps:"
echo "  1. Login to n8n: http://185.167.97.193:5678"
echo "     Username: admin"
echo "     Password: (set in .env)"
echo ""
echo "  2. Scan WAHA QR code:"
echo "     Open: http://185.167.97.193:8765"
echo "     Click 'Connect' and scan QR with WhatsApp"
echo ""
echo "  3. Test Telegram bot:"
echo "     Message: t.me/YOUR_BOT_NAME"
echo "     Send: /start"
echo ""
echo "View Logs:"
echo "  All services: docker-compose logs -f"
echo "  n8n only:     docker-compose logs -f n8n"
echo "  WAHA only:    docker-compose logs -f waha"
echo "  Bot only:     docker-compose logs -f telegram-bot"
echo ""
echo "Stop All:"
echo "  docker-compose down"
echo ""
