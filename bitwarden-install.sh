#!/bin/bash
set -e

echo "🏢 Installing Official Bitwarden..."
cd /opt/bitwarden

# Create installation answers
cat > install-answers.txt << 'INSTALL_EOF'
vault.20-160-104-163.sslip.io
y
01432df8-00f9-409e-89c8-b33e003739b4
ZXkDKVrt6Cjqe56Q3i0R
INSTALL_EOF

echo "🚀 Running Bitwarden installer..."
sudo -u bitwarden ./bitwarden.sh install < install-answers.txt

echo "🔄 Starting Bitwarden..."
sudo -u bitwarden ./bitwarden.sh start

echo "✅ Bitwarden installation complete!"
echo "🌐 Access your vault at: https://vault.20-160-104-163.sslip.io"
echo "👨‍💼 Admin panel: https://vault.20-160-104-163.sslip.io/admin"
