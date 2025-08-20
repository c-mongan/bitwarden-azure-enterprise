#!/bin/bash
set -e

# VM Configuration
VM_IP="20.160.104.163"
DOMAIN="vault.20-160-104-163.sslip.io"
SSH_USER="azureuser"

echo "🚀 Official Bitwarden Deployment on Azure"
echo "========================================"
echo "VM IP: $VM_IP"
echo "Domain: $DOMAIN"
echo "SSH User: $SSH_USER"
echo ""

# Get Install ID and Key
echo "📋 You need Bitwarden Install ID and Key:"
echo "1. Go to https://bitwarden.com/host/"
echo "2. Enter your email address"
echo "3. Select US region"
echo "4. Copy Install ID and Key"
echo ""
read -p "Enter Install ID: " INSTALL_ID
read -p "Enter Install Key: " INSTALL_KEY

if [[ -z "$INSTALL_ID" || -z "$INSTALL_KEY" ]]; then
    echo "❌ Install ID and Key are required"
    exit 1
fi

echo ""
echo "🔧 Deploying to Azure VM..."

# Create deployment script for VM
cat > vm-setup.sh << 'EOF'
#!/bin/bash
set -e

echo "📦 Installing Docker..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc >/dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo ${UBUNTU_CODENAME:-$VERSION_CODENAME}) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "👤 Creating bitwarden user..."
sudo adduser --disabled-password --gecos "" bitwarden
sudo mkdir -p /opt/bitwarden
sudo chown bitwarden:bitwarden /opt/bitwarden
sudo chmod 700 /opt/bitwarden

echo "📥 Downloading Bitwarden installer..."
sudo -u bitwarden bash -c 'cd /opt/bitwarden && curl -Lso bitwarden.sh "https://func.bitwarden.com/api/dl/?app=self-host&platform=linux" && chmod 700 bitwarden.sh'

echo "✅ VM setup complete!"
EOF

# Copy and run setup script on VM
echo "📤 Copying setup script to VM..."
scp -o StrictHostKeyChecking=no vm-setup.sh $SSH_USER@$VM_IP:~/
ssh -o StrictHostKeyChecking=no $SSH_USER@$VM_IP 'chmod +x vm-setup.sh && ./vm-setup.sh'

# Create Bitwarden installation script
cat > bitwarden-install.sh << EOF
#!/bin/bash
set -e

echo "🏢 Installing Official Bitwarden..."
cd /opt/bitwarden

# Create installation answers
cat > install-answers.txt << 'INSTALL_EOF'
$DOMAIN
y
$INSTALL_ID
$INSTALL_KEY
INSTALL_EOF

echo "🚀 Running Bitwarden installer..."
sudo -u bitwarden ./bitwarden.sh install < install-answers.txt

echo "🔄 Starting Bitwarden..."
sudo -u bitwarden ./bitwarden.sh start

echo "✅ Bitwarden installation complete!"
echo "🌐 Access your vault at: https://$DOMAIN"
echo "👨‍💼 Admin panel: https://$DOMAIN/admin"
EOF

# Copy and run Bitwarden installation
echo "📤 Installing Bitwarden on VM..."
scp bitwarden-install.sh $SSH_USER@$VM_IP:~/
ssh $SSH_USER@$VM_IP 'chmod +x bitwarden-install.sh && ./bitwarden-install.sh'

echo ""
echo "🎉 Deployment Complete!"
echo "======================================"
echo "🌐 Bitwarden URL: https://$DOMAIN"
echo "👨‍💼 Admin Portal: https://$DOMAIN/admin"
echo "🔐 Let's Encrypt SSL: Automatically configured"
echo ""
echo "📝 Next Steps:"
echo "1. Access your vault and create an account"
echo "2. Configure SMTP for email (optional)"
echo "3. Set up SAML SSO with Azure AD"
echo "4. Enable SCIM provisioning (if licensed)"
echo ""
echo "💡 Test the deployment:"
echo "   curl -I https://$DOMAIN"

# Cleanup
rm -f vm-setup.sh bitwarden-install.sh

echo ""
echo "🏆 You now have OFFICIAL Bitwarden running on Azure!"
echo "   This is enterprise-grade and production-ready!"