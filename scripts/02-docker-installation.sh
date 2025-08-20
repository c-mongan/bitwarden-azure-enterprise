#!/bin/bash

# Bitwarden Self-Hosting - Docker Installation Script
# Run this script on your Ubuntu VM to install Docker and prepare for Bitwarden

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐳 Docker Installation for Bitwarden${NC}"
echo "============================================"

# Update package index
echo -e "${BLUE}📦 Updating package index...${NC}"
sudo apt-get update

# Install prerequisites
echo -e "${BLUE}🔧 Installing prerequisites...${NC}"
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
echo -e "${BLUE}🔑 Adding Docker GPG key...${NC}"
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo -e "${BLUE}📋 Setting up Docker repository...${NC}"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
sudo apt-get update

# Install Docker Engine
echo -e "${BLUE}🐳 Installing Docker Engine...${NC}"
sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Add current user to docker group
echo -e "${BLUE}👤 Adding user to docker group...${NC}"
sudo usermod -aG docker $USER

# Enable and start Docker service
echo -e "${BLUE}🚀 Starting Docker service...${NC}"
sudo systemctl enable docker
sudo systemctl start docker

# Verify Docker installation
echo -e "${BLUE}✅ Verifying Docker installation...${NC}"
if docker --version && docker compose version; then
    echo -e "${GREEN}✅ Docker installed successfully!${NC}"
    docker --version
    docker compose version
else
    echo -e "${RED}❌ Docker installation failed${NC}"
    exit 1
fi

# Create bitwarden user and directory
echo -e "${BLUE}👤 Setting up Bitwarden user and directory...${NC}"
sudo adduser --disabled-password --gecos "" bitwarden
sudo mkdir -p /opt/bitwarden
sudo chown bitwarden:bitwarden /opt/bitwarden
sudo chmod 755 /opt/bitwarden

# Add bitwarden user to docker group
sudo usermod -aG docker bitwarden

echo
echo -e "${GREEN}🎉 Docker installation complete!${NC}"
echo "=========================================="
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Log out and log back in for group changes to take effect"
echo "   OR run: newgrp docker"
echo "2. Switch to bitwarden user: sudo -u bitwarden -i"
echo "3. Navigate to: cd /opt/bitwarden"
echo "4. Download and run Bitwarden installer"
echo
echo -e "${YELLOW}💡 Test Docker access:${NC}"
echo "  docker run hello-world"