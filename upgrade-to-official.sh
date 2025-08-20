#!/bin/bash
echo "🚀 Upgrading to Official Bitwarden with Enterprise SSO"
echo "===================================================="

# Stop current containers
echo "🛑 Stopping Vaultwarden containers..."
docker-compose down

# Backup current configuration
echo "💾 Backing up current configuration..."
mkdir -p backup
cp -r vaultwarden-data backup/
cp *.json *.env backup/

# Get Bitwarden Install ID and Key
echo "📋 You need Bitwarden Install ID and Key from:"
echo "   https://bitwarden.com/host/"
echo ""
read -p "Enter Install ID: " INSTALL_ID
read -p "Enter Install Key: " INSTALL_KEY

# Set domain (using sslip.io for easy SSL)
VM_IP=$(curl -s ipecho.net/plain)
DOMAIN="vault.${VM_IP//./-}.sslip.io"

echo "🌐 Using domain: $DOMAIN"

# Download official Bitwarden
echo "📦 Downloading official Bitwarden installer..."
curl -Lso bitwarden.sh "https://func.bitwarden.com/api/dl/?app=self-host&platform=linux"
chmod 700 bitwarden.sh

# Configure installation
echo "⚙️ Configuring Bitwarden installation..."
cat > install-config.txt << EOF
$DOMAIN
y
$INSTALL_ID
$INSTALL_KEY
EOF

echo "🚀 Installing official Bitwarden..."
echo "This will:"
echo "  1. Download official Bitwarden containers"
echo "  2. Configure Let's Encrypt SSL certificates"
echo "  3. Set up database and services"
echo "  4. Enable enterprise SSO features"

# Run installation with our config
./bitwarden.sh install < install-config.txt

echo "✅ Official Bitwarden installation complete!"
echo ""
echo "📝 Next steps:"
echo "1. Start Bitwarden: ./bitwarden.sh start"
echo "2. Access admin portal: https://$DOMAIN/admin"
echo "3. Configure SAML SSO with our Azure settings"
echo "4. Enable SCIM provisioning"
echo ""
echo "🔗 Your Bitwarden URL: https://$DOMAIN"