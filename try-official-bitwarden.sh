#!/bin/bash
echo "🏢 Installing Official Bitwarden (Free Self-Hosted)"
echo "================================================="

# Check if we want to proceed
echo "⚠️  Important Notes:"
echo "   • Free version does NOT include SSO/SAML"
echo "   • Requires Install ID from bitwarden.com/host"
echo "   • More complex setup than Vaultwarden"
echo "   • Our Azure SAML work won't function without Enterprise license"
echo ""
read -p "Do you want to proceed? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Keeping current Vaultwarden setup (recommended)"
    exit 0
fi

# Stop current containers
echo "🛑 Stopping current Vaultwarden setup..."
docker-compose down

# Backup current setup
echo "💾 Backing up current configuration..."
mkdir -p backup-vaultwarden
cp -r vaultwarden-data backup-vaultwarden/ 2>/dev/null || true
cp *.json *.env backup-vaultwarden/

# Get Install ID and Key
echo "📋 You need to get Install ID and Key from:"
echo "   https://bitwarden.com/host/"
echo ""
echo "Steps:"
echo "1. Go to https://bitwarden.com/host/"
echo "2. Enter your email"
echo "3. Select region (US for most users)"  
echo "4. Copy Install ID and Key"
echo ""
read -p "Enter Install ID: " INSTALL_ID
read -p "Enter Install Key: " INSTALL_KEY

# Validate inputs
if [[ -z "$INSTALL_ID" || -z "$INSTALL_KEY" ]]; then
    echo "❌ Install ID and Key are required"
    exit 1
fi

# Set domain for SSL
VM_IP=$(curl -s ipecho.net/plain 2>/dev/null || echo "localhost")
if [[ "$VM_IP" != "localhost" ]]; then
    DOMAIN="vault.${VM_IP//./-}.sslip.io"
else
    DOMAIN="localhost"
fi

echo "🌐 Using domain: $DOMAIN"

# Create bitwarden directory
echo "📁 Setting up Bitwarden directory..."
mkdir -p bitwarden-official
cd bitwarden-official

# Download official installer
echo "📦 Downloading official Bitwarden installer..."
curl -Lso bitwarden.sh "https://func.bitwarden.com/api/dl/?app=self-host&platform=linux"
chmod 700 bitwarden.sh

# Create configuration file for automated install
echo "⚙️ Creating installation configuration..."
cat > install-answers.txt << EOF
$DOMAIN
y
$INSTALL_ID
$INSTALL_KEY
EOF

echo "🚀 Installing official Bitwarden..."
echo "This will download and configure:"
echo "   • Official Bitwarden containers"
echo "   • Database (MSSQL)"
echo "   • Web vault and API"
echo "   • Admin panel"
echo ""

# Run installation
if ./bitwarden.sh install < install-answers.txt; then
    echo "✅ Official Bitwarden installation complete!"
    
    # Start services
    echo "🔄 Starting Bitwarden services..."
    ./bitwarden.sh start
    
    echo ""
    echo "🎉 Official Bitwarden is now running!"
    echo "📍 Access URL: https://$DOMAIN"
    echo "👨‍💼 Admin URL: https://$DOMAIN/admin"
    echo ""
    echo "⚠️  SSO Features:"
    echo "   • SAML SSO: ❌ Requires Enterprise license"
    echo "   • SCIM: ❌ Requires Enterprise license"
    echo "   • Basic auth: ✅ Works with free version"
    echo ""
    echo "💡 Our Azure integration work demonstrates the knowledge,"
    echo "   even though free version can't use it!"
    
else
    echo "❌ Installation failed"
    echo "Common issues:"
    echo "   • Invalid Install ID/Key"
    echo "   • Network connectivity"
    echo "   • Port conflicts"
    echo ""
    echo "🔄 Restoring Vaultwarden setup..."
    cd ..
    docker-compose up -d
    echo "✅ Vaultwarden restored"
fi