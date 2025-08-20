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
