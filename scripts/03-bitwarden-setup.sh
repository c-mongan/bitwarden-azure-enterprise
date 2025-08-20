#!/bin/bash

# Bitwarden Self-Hosting - Installation and Configuration Script
# Run this as the bitwarden user in /opt/bitwarden

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 Bitwarden Self-Hosting Setup${NC}"
echo "======================================="

# Check if running as bitwarden user
if [ "$USER" != "bitwarden" ]; then
    echo -e "${RED}❌ Please run this script as the bitwarden user${NC}"
    echo "Run: sudo -u bitwarden -i"
    echo "Then: cd /opt/bitwarden && bash /path/to/this/script"
    exit 1
fi

# Check if in correct directory
if [ "$PWD" != "/opt/bitwarden" ]; then
    echo -e "${YELLOW}⚠️  Moving to /opt/bitwarden directory...${NC}"
    cd /opt/bitwarden
fi

# Download Bitwarden installer
echo -e "${BLUE}📥 Downloading Bitwarden installer...${NC}"
curl -Lso bitwarden.sh "https://func.bitwarden.com/api/dl/?app=self-host&platform=linux"
chmod 700 bitwarden.sh

if [ -f "bitwarden.sh" ]; then
    echo -e "${GREEN}✅ Bitwarden installer downloaded successfully${NC}"
else
    echo -e "${RED}❌ Failed to download Bitwarden installer${NC}"
    exit 1
fi

echo
echo -e "${YELLOW}🔧 Starting Bitwarden Installation${NC}"
echo "============================================"
echo -e "${BLUE}You will be prompted for:${NC}"
echo "1. Domain name (use your sslip.io hostname)"
echo "2. Let's Encrypt certificate (choose Y)"
echo "3. Installation ID and Key (get from bitwarden.com/host)"
echo
echo -e "${YELLOW}⚠️  Important: Have your installation ID and key ready!${NC}"
echo "Get them from: https://bitwarden.com/host"
echo
read -p "Press Enter when ready to continue..."

# Run Bitwarden installer
echo -e "${BLUE}🚀 Running Bitwarden installer...${NC}"
./bitwarden.sh install

# Check if installation was successful
if [ -d "bwdata" ]; then
    echo -e "${GREEN}✅ Bitwarden installation completed successfully${NC}"
else
    echo -e "${RED}❌ Bitwarden installation may have failed${NC}"
    echo "Please check the output above for errors"
    exit 1
fi

echo
echo -e "${YELLOW}🔧 Post-Installation Configuration${NC}"
echo "=================================="

# Create a sample SMTP configuration
echo -e "${BLUE}📧 Creating SMTP configuration template...${NC}"
cat > smtp-config-template.txt << 'EOF'
# Add these lines to ./bwdata/env/global.override.env
# Replace with your actual SMTP settings

globalSettings__mail__smtp__host=smtp.gmail.com
globalSettings__mail__smtp__port=587
globalSettings__mail__smtp__ssl=false
globalSettings__mail__smtp__username=your-email@gmail.com
globalSettings__mail__smtp__password=your-app-password
adminSettings__admins=your-email@gmail.com

# For Gmail, use an App Password instead of your regular password
# For other providers, adjust host/port accordingly
EOF

echo -e "${GREEN}✅ SMTP configuration template created${NC}"

echo
echo -e "${GREEN}🎉 Bitwarden setup complete!${NC}"
echo "====================================="
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Configure SMTP (edit bwdata/env/global.override.env)"
echo "2. Start Bitwarden: ./bitwarden.sh start"
echo "3. Check status: docker ps"
echo "4. Test SMTP: ./bitwarden.sh checksmtp"
echo "5. Access your vault at: https://your-hostname"
echo
echo -e "${YELLOW}💡 Useful Commands:${NC}"
echo "  Start:    ./bitwarden.sh start"
echo "  Stop:     ./bitwarden.sh stop"
echo "  Restart:  ./bitwarden.sh restart"
echo "  Update:   ./bitwarden.sh updateself && ./bitwarden.sh update"
echo "  Logs:     docker logs bitwarden-web"
echo
echo -e "${YELLOW}📝 Configuration Files:${NC}"
echo "  Main config:     ./bwdata/config.yml"
echo "  Environment:     ./bwdata/env/global.override.env"
echo "  SSL/TLS certs:   ./bwdata/ssl/"
echo "  Logs:           ./bwdata/logs/"