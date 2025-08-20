# Bitwarden Self-Hosting Implementation Guide

## 🚀 Quick Start Summary

This guide provides step-by-step instructions for deploying Bitwarden self-hosting on Azure with SAML SSO integration.

**Total Implementation Time**: 2-3 hours  
**Prerequisites**: Azure subscription, basic Linux knowledge  
**Result**: Production-ready Bitwarden instance with Azure AD SSO

---

## 📋 Prerequisites

### Required Accounts & Access
- ✅ Azure subscription with contributor access
- ✅ Azure CLI installed and configured
- ✅ SSH client (built into most systems)
- ✅ Access to create Azure AD Enterprise Applications
- ✅ Bitwarden account for installation ID/key (free at bitwarden.com/host)

### Local Environment Setup
```bash
# Verify Azure CLI is installed
az --version

# Login to Azure
az login

# Set your subscription (if you have multiple)
az account list --output table
az account set --subscription "your-subscription-name"
```

---

## 🏗️ Phase 1: Azure Infrastructure Setup

### Step 1.1: Run Infrastructure Script

```bash
# Make script executable
chmod +x scripts/01-azure-infrastructure.sh

# Run the infrastructure setup
./scripts/01-azure-infrastructure.sh
```

**What this does:**
- Creates resource group `bitwarden-rg` in West Europe
- Provisions Ubuntu 22.04 VM with Standard_B2s size
- Opens ports 80 (HTTP) and 443 (HTTPS)
- Generates SSH keys automatically
- Creates sslip.io hostname for easy DNS

### Step 1.2: Verify Infrastructure

```bash
# Check resource group
az group show --name bitwarden-rg --output table

# Check VM status
az vm show --resource-group bitwarden-rg --name bitwarden-vm --show-details --output table

# Get connection info
az vm show -d --resource-group bitwarden-rg --name bitwarden-vm --query "{Name:name, PublicIP:publicIps, Status:powerState}" --output table
```

### Step 1.3: Test SSH Connection

```bash
# Connect to your VM (replace with your actual IP)
ssh azureuser@YOUR_PUBLIC_IP

# Test basic connectivity
ping google.com
sudo apt update
exit
```

**Expected Results:**
- ✅ VM accessible via SSH
- ✅ Internet connectivity working
- ✅ `config.env` file created with your settings

---

## 🐳 Phase 2: Docker & Bitwarden Installation

### Step 2.1: Upload and Run Docker Installation

```bash
# Copy script to VM
scp scripts/02-docker-installation.sh azureuser@YOUR_PUBLIC_IP:~/

# Connect and run script
ssh azureuser@YOUR_PUBLIC_IP
chmod +x 02-docker-installation.sh
./02-docker-installation.sh
```

### Step 2.2: Verify Docker Installation

```bash
# Test Docker (may need to logout/login or run: newgrp docker)
docker run hello-world
docker compose version

# Check bitwarden user and directory
sudo ls -la /opt/bitwarden
sudo -u bitwarden -i
pwd  # Should be /home/bitwarden
docker ps  # Should work without sudo
exit
```

### Step 2.3: Install Bitwarden

```bash
# Copy Bitwarden setup script
scp scripts/03-bitwarden-setup.sh azureuser@YOUR_PUBLIC_IP:~/

# Run as bitwarden user
ssh azureuser@YOUR_PUBLIC_IP
sudo cp 03-bitwarden-setup.sh /opt/bitwarden/
sudo chown bitwarden:bitwarden /opt/bitwarden/03-bitwarden-setup.sh
sudo -u bitwarden -i
cd /opt/bitwarden
chmod +x 03-bitwarden-setup.sh
./03-bitwarden-setup.sh
```

### Step 2.4: Configure Installation

**When prompted during installation:**

1. **Domain name**: Use your sslip.io hostname
   ```
   vault.20-51-123-45.sslip.io
   ```

2. **Let's Encrypt**: Choose `Y` for free SSL certificate

3. **Installation ID and Key**: 
   - Visit https://bitwarden.com/host
   - Create account and get Installation ID/Key
   - Paste when prompted

### Step 2.5: Configure SMTP (Email)

```bash
# Edit global override file
nano bwdata/env/global.override.env

# Add SMTP configuration (example with Gmail)
globalSettings__mail__smtp__host=smtp.gmail.com
globalSettings__mail__smtp__port=587
globalSettings__mail__smtp__ssl=false
globalSettings__mail__smtp__username=your-email@gmail.com
globalSettings__mail__smtp__password=your-app-password
adminSettings__admins=your-email@gmail.com
```

### Step 2.6: Start Bitwarden

```bash
# Start all services
./bitwarden.sh start

# Check container health (wait 2-3 minutes)
docker ps

# Test SMTP configuration
./bitwarden.sh checksmtp

# Test web access
curl -I https://your-hostname
```

**Expected Results:**
- ✅ All containers show "healthy" status
- ✅ HTTPS certificate valid (Let's Encrypt)
- ✅ Web vault accessible at https://your-hostname
- ✅ SMTP test passes

---

## 🔐 Phase 3: SAML SSO Configuration

### Step 3.1: Azure AD Enterprise Application Setup

1. **Navigate to Azure Portal**:
   - Go to Azure Active Directory
   - Select "Enterprise Applications"
   - Click "New Application"

2. **Create Non-Gallery Application**:
   - Click "Create your own application"
   - Name: "Bitwarden Self-Hosted"
   - Select "Integrate any other application"
   - Click "Create"

3. **Configure Single Sign-On**:
   - Go to "Single sign-on" in left menu
   - Select "SAML"
   - Click "Edit" on Basic SAML Configuration

### Step 3.2: Basic SAML Configuration

**In Azure AD, configure:**

```
Identifier (Entity ID):
https://your-hostname/sso/saml2

Reply URL (Assertion Consumer Service URL):
https://your-hostname/sso/saml2/Acs

Sign on URL:
https://your-hostname/#/sso
```

**Example with sslip.io:**
```
Identifier: https://vault.20-51-123-45.sslip.io/sso/saml2
Reply URL: https://vault.20-51-123-45.sslip.io/sso/saml2/Acs
Sign on URL: https://vault.20-51-123-45.sslip.io/#/sso
```

### Step 3.3: User Attributes & Claims

**Set NameID format:**
- Source attribute: `user.objectid`
- Name identifier format: `Default`

**Why ObjectID?** It's stable and doesn't change if user email changes.

### Step 3.4: Download Certificate

1. In "SAML Signing Certificate" section
2. Download "Certificate (Base64)"
3. Save as `azure-ad-cert.cer`

### Step 3.5: Configure Bitwarden SSO

1. **Access Admin Portal**:
   ```
   https://your-hostname/admin
   ```

2. **Navigate to SSO Settings**:
   - Go to "Single Sign-On" tab
   - Select "SAML 2.0"

3. **Configure SAML Settings**:
   ```
   SP Entity ID: https://your-hostname/sso/saml2
   
   IdP Entity ID: https://sts.windows.net/YOUR_TENANT_ID/
   
   IdP Single Sign-On Service URL:
   https://login.microsoftonline.com/YOUR_TENANT_ID/saml2
   
   IdP Single Log Out Service URL:
   https://login.microsoftonline.com/YOUR_TENANT_ID/saml2
   
   X509 Public Certificate: [Paste certificate content from downloaded file]
   ```

4. **Advanced Settings**:
   ```
   Name ID Format: Not configured
   Outbound Signing Algorithm: rsa-sha256
   Signing Behavior: If IdP wants authn requests signed
   ```

### Step 3.6: Test SAML Authentication

1. **Create Test Organization**:
   - In Bitwarden admin, create new organization
   - Enable SSO for the organization
   - Note the SSO Identifier

2. **Test Login Flow**:
   - Go to `https://your-hostname/#/sso`
   - Enter SSO Identifier
   - Should redirect to Azure AD
   - Login with Azure AD credentials
   - Should redirect back to Bitwarden

**Troubleshooting Common Issues:**
- Certificate format errors: Ensure no extra spaces/headers
- Redirect loops: Check Reply URL configuration
- "Invalid SAML Response": Verify Entity IDs match exactly

---

## ✅ Phase 4: Testing & Validation

### Step 4.1: End-to-End Testing

```bash
# Check all containers are healthy
docker ps

# Test web vault access
curl -I https://your-hostname

# Test API health
curl https://your-hostname/api/alive

# Check SSL certificate
openssl s_client -connect your-hostname:443 -servername your-hostname
```

### Step 4.2: SAML Flow Testing

1. **SP-Initiated Flow**:
   - Start at Bitwarden SSO page
   - Enter organization identifier
   - Complete Azure AD login

2. **IdP-Initiated Flow** (Optional):
   - Start from Azure AD portal
   - Click Bitwarden application
   - Should land in Bitwarden vault

### Step 4.3: User Management Testing

1. **Create Test Users in Azure AD**
2. **Assign to Bitwarden Application**
3. **Test Login Process**
4. **Verify User Attributes**

---

## 📊 Monitoring & Maintenance

### Key Commands for Operations

```bash
# Service management
./bitwarden.sh start|stop|restart

# View logs
docker logs bitwarden-web
docker logs bitwarden-api
docker logs bitwarden-mssql

# Update Bitwarden
./bitwarden.sh updateself
./bitwarden.sh update

# Backup (recommended)
tar -czf bitwarden-backup-$(date +%Y%m%d).tar.gz bwdata/
```

### Health Check Endpoints

```bash
# API health
curl https://your-hostname/api/alive

# Database health
curl https://your-hostname/api/config

# Certificate expiry
echo | openssl s_client -connect your-hostname:443 2>/dev/null | openssl x509 -noout -dates
```

---

## 🎯 Success Criteria

By completion, you should have:

- ✅ **Secure Web Access**: HTTPS with valid certificate
- ✅ **Functional SSO**: Users can login via Azure AD
- ✅ **Healthy Services**: All containers running and responding
- ✅ **Email Working**: SMTP configured and tested
- ✅ **Documentation**: Complete setup and troubleshooting guides

---

## 🚨 Troubleshooting Guide

### Common Issues & Solutions

**Issue**: Let's Encrypt fails
```bash
# Check port 80 is accessible
curl -I http://your-hostname/.well-known/acme-challenge/test

# Verify DNS resolution
nslookup your-hostname
```

**Issue**: SAML authentication fails
- Verify Entity IDs match exactly
- Check certificate format (no headers/footers)
- Validate NameID configuration

**Issue**: Containers unhealthy
```bash
# Check logs for specific container
docker logs bitwarden-api

# Restart specific service
docker restart bitwarden-api
```

---

## 💡 Pro Tips for Interviews

1. **Explain Your Choices**: "I used ObjectID for NameID because..."
2. **Show Problem-Solving**: "When X failed, I debugged by..."
3. **Demonstrate Learning**: "I initially tried Y but learned Z was better..."
4. **Business Context**: "This solves the customer problem of..."

---

*This implementation follows Bitwarden's official recommendations and industry best practices for enterprise identity integration.*