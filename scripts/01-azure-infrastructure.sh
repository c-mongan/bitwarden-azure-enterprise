#!/bin/bash

# Bitwarden Self-Hosting on Azure - Infrastructure Setup
# This script creates the Azure infrastructure needed for Bitwarden self-hosting

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Bitwarden Azure Infrastructure Setup${NC}"
echo "=================================================="

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if user is logged in
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not logged into Azure. Please login first.${NC}"
    az login
fi

# Configuration variables
RESOURCE_GROUP="bitwarden-rg"
LOCATION="westeurope"
VM_NAME="bitwarden-vm"
VM_SIZE="Standard_B2s"
ADMIN_USERNAME="azureuser"

echo -e "${BLUE}📋 Configuration:${NC}"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  VM Name: $VM_NAME"
echo "  VM Size: $VM_SIZE"
echo "  Admin User: $ADMIN_USERNAME"
echo

# Create resource group
echo -e "${BLUE}🏗️  Creating resource group...${NC}"
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION \
    --output table

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Resource group created successfully${NC}"
else
    echo -e "${RED}❌ Failed to create resource group${NC}"
    exit 1
fi

# Create virtual machine
echo -e "${BLUE}💻 Creating virtual machine...${NC}"
echo "This may take a few minutes..."

az vm create \
    --resource-group $RESOURCE_GROUP \
    --name $VM_NAME \
    --image Ubuntu2204 \
    --size $VM_SIZE \
    --admin-username $ADMIN_USERNAME \
    --generate-ssh-keys \
    --public-ip-sku Standard \
    --storage-sku Premium_LRS \
    --output table

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Virtual machine created successfully${NC}"
else
    echo -e "${RED}❌ Failed to create virtual machine${NC}"
    exit 1
fi

# Open HTTP port (80) for Let's Encrypt validation
echo -e "${BLUE}🔓 Opening HTTP port (80)...${NC}"
az vm open-port \
    --resource-group $RESOURCE_GROUP \
    --name $VM_NAME \
    --port 80 \
    --priority 900 \
    --output table

# Open HTTPS port (443) for web traffic
echo -e "${BLUE}🔒 Opening HTTPS port (443)...${NC}"
az vm open-port \
    --resource-group $RESOURCE_GROUP \
    --name $VM_NAME \
    --port 443 \
    --priority 901 \
    --output table

# Get public IP address
echo -e "${BLUE}🌐 Retrieving public IP address...${NC}"
PUBLIC_IP=$(az vm show -d \
    --resource-group $RESOURCE_GROUP \
    --name $VM_NAME \
    --query publicIps \
    --output tsv)

if [ -n "$PUBLIC_IP" ]; then
    echo -e "${GREEN}✅ Public IP: $PUBLIC_IP${NC}"
    
    # Generate sslip.io hostname
    SSLIP_HOSTNAME="vault.$(echo $PUBLIC_IP | tr '.' '-').sslip.io"
    echo -e "${GREEN}🌍 Your Bitwarden hostname: $SSLIP_HOSTNAME${NC}"
    
    # Save configuration for next steps
    cat > config.env << EOF
# Bitwarden Configuration
PUBLIC_IP=$PUBLIC_IP
HOSTNAME=$SSLIP_HOSTNAME
RESOURCE_GROUP=$RESOURCE_GROUP
VM_NAME=$VM_NAME
ADMIN_USERNAME=$ADMIN_USERNAME
EOF
    
    echo -e "${GREEN}✅ Configuration saved to config.env${NC}"
else
    echo -e "${RED}❌ Failed to retrieve public IP${NC}"
    exit 1
fi

echo
echo -e "${GREEN}🎉 Infrastructure setup complete!${NC}"
echo "=================================================="
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Connect to your VM: ssh $ADMIN_USERNAME@$PUBLIC_IP"
echo "2. Run the Docker installation script"
echo "3. Install and configure Bitwarden"
echo
echo -e "${YELLOW}💡 Save this information:${NC}"
echo "  VM IP: $PUBLIC_IP"
echo "  Hostname: $SSLIP_HOSTNAME"
echo "  SSH: ssh $ADMIN_USERNAME@$PUBLIC_IP"