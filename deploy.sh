#!/bin/bash
# ISOTOPE v2.0 — VPS Deployment Script
# 
# Run this on your VPS (185.167.97.193) to deploy ISOTOPE
# Usage: bash deploy.sh
#
# Built by Elkai | ELEV8 DIGITAL

set -e  # Exit on error

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║   🔬 ISOTOPE v2.0 — VPS Deployment                        ║"
echo "║                                                           ║"
echo "║   Server: 185.167.97.193 (Amsterdam, EU)                 ║"
echo "║   OS: Ubuntu 22.04 LTS                                    ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================
# STEP 1: System Update
# ============================================
echo -e "${YELLOW}[1/8] Updating system packages...${NC}"
apt update && apt upgrade -y
echo -e "${GREEN}✓ System updated${NC}"
echo ""

# ============================================
# STEP 2: Install Python 3.11
# ============================================
echo -e "${YELLOW}[2/8] Installing Python 3.11...${NC}"
apt install -y python3 python3-pip python3-venv
echo -e "${GREEN}✓ Python installed${NC}"
echo ""

# ============================================
# STEP 3: Install Dependencies
# ============================================
echo -e "${YELLOW}[3/8] Installing system dependencies...${NC}"
apt install -y git curl wget tmux sqlite3
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# ============================================
# STEP 4: Create Project Directory
# ============================================
echo -e "${YELLOW}[4/8] Setting up project directory...${NC}"
cd /root
mkdir -p isotope
cd isotope
mkdir -p data logs
echo -e "${GREEN}✓ Directory structure created${NC}"
echo ""

# ============================================
# STEP 5: Create Python Virtual Environment
# ============================================
echo -e "${YELLOW}[5/8] Creating Python virtual environment...${NC}"
python3 -m venv venv
source venv/bin/activate
echo -e "${GREEN}✓ Virtual environment created${NC}"
echo ""

# ============================================
# STEP 6: Install Python Packages
# ============================================
echo -e "${YELLOW}[6/8] Installing Python packages...${NC}"
pip install --upgrade pip
pip install pandas numpy aiohttp
echo -e "${GREEN}✓ Python packages installed${NC}"
echo ""

# ============================================
# STEP 7: Create Environment File
# ============================================
echo -e "${YELLOW}[7/8] Creating environment configuration...${NC}"
cat > .env << 'EOF'
# ISOTOPE Environment Configuration
# Edit this file with your actual API keys

# Alpha Vantage (get free key at alphavantage.co)
ALPHA_VANTAGE_KEY=your_key_here

# WhatsApp Bot (if using)
WHATSAPP_BOT_URL=http://113.30.189.89:8765/api/send
WHATSAPP_BOT_TOKEN=your_token_here

# Risk Settings
ACCOUNT_BALANCE=10000
MAX_RISK_PER_TRADE=0.02
MAX_DAILY_LOSS=0.05

# System Settings
NODE_ENV=production
LOG_LEVEL=info
EOF
echo -e "${GREEN}✓ Environment file created${NC}"
echo -e "${YELLOW}⚠ Edit .env with your API keys!${NC}"
echo ""

# ============================================
# STEP 8: Create Systemd Service
# ============================================
echo -e "${YELLOW}[8/8] Creating systemd service...${NC}"
cat > /etc/systemd/system/isotope.service << 'EOF'
[Unit]
Description=ISOTOPE v2.0 - Gold Signal Intelligence System
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/isotope
Environment="PATH=/root/isotope/venv/bin"
ExecStart=/root/isotope/venv/bin/python /root/isotope/main.py
Restart=always
RestartSec=10
StandardOutput=append:/root/isotope/logs/isotope.log
StandardError=append:/root/isotope/logs/isotope.error.log

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
systemctl daemon-reload
systemctl enable isotope
echo -e "${GREEN}✓ Systemd service created${NC}"
echo ""

# ============================================
# DEPLOYMENT COMPLETE
# ============================================
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║   ✅ DEPLOYMENT COMPLETE!                                 ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "📋 NEXT STEPS:"
echo ""
echo "1. Copy your code files to /root/isotope/"
echo "   (Use scp, git clone, or manually upload)"
echo ""
echo "2. Edit the .env file with your API keys:"
echo "   nano /root/isotope/.env"
echo ""
echo "3. Start ISOTOPE service:"
echo "   systemctl start isotope"
echo ""
echo "4. Check status:"
echo "   systemctl status isotope"
echo ""
echo "5. View logs:"
echo "   tail -f /root/isotope/logs/isotope.log"
echo ""
echo "📌 USEFUL COMMANDS:"
echo "   systemctl start isotope    - Start service"
echo "   systemctl stop isotope     - Stop service"
echo "   systemctl restart isotope  - Restart service"
echo "   systemctl status isotope   - Check status"
echo "   journalctl -u isotope -f   - View live logs"
echo ""
echo "🔒 SECURITY REMINDER:"
echo "   - Change your root password"
echo "   - Set up SSH key authentication"
echo "   - Configure firewall (ufw)"
echo ""
echo -e "${GREEN}Ready to trade!${NC}"
