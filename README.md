# Official Bitwarden Self-Hosting on Azure with Enterprise SAML SSO

[![Azure](https://img.shields.io/badge/Azure-0078D4?style=flat&logo=microsoft-azure&logoColor=white)](https://portal.azure.com)
[![Bitwarden](https://img.shields.io/badge/Bitwarden-175DDC?style=flat&logo=bitwarden&logoColor=white)](https://bitwarden.com)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)](https://docker.com)
[![Status](https://img.shields.io/badge/Status-✅%20Running-brightgreen)](https://vault.20-160-104-163.sslip.io)

A **production-ready enterprise Bitwarden deployment** on Microsoft Azure with **SAML SSO integration**, demonstrating enterprise-grade password management infrastructure with automated deployment, monitoring, and Azure AD authentication.

## 🚀 Live Demo

**🌐 Access the running instance**: https://vault.20-160-104-163.sslip.io  
**⚙️ Admin Panel**: https://vault.20-160-104-163.sslip.io/admin  
**📊 Status**: ✅ Running (8+ days uptime) • 10+ healthy containers • SQL Server database

---

## 📋 What You'll Deploy

This repository provides **complete automation** to deploy:

### 🏗️ **Azure Infrastructure**
- Ubuntu 22.04 VM (Standard_B2s) 
- Network Security Groups (ports 80, 443, 22)
- Public IP with sslip.io DNS
- Premium SSD storage

### 🔐 **Official Bitwarden Server**
- **10+ microservice containers** (not Vaultwarden)
- Microsoft SQL Server database
- Enterprise-grade architecture
- SAML SSO support (with licensing)
- Real-time notifications
- Comprehensive audit logging

### 🔗 **Azure AD Integration**
- Enterprise Application setup
- SAML 2.0 authentication
- Claims mapping (ObjectID, email, name)
- Single sign-on flows

---

## 🚀 Quick Start (15 Minutes)

### Prerequisites
- Azure subscription with Contributor access
- Azure CLI installed (`az --version`)
- Basic terminal/command line knowledge
- (Optional) Bitwarden hosting license from bitwarden.com/host

### Step 1: Clone Repository
```bash
git clone https://github.com/your-username/Bitwarden-Self-Hosting-Azure.git
cd Bitwarden-Self-Hosting-Azure
```

### Step 2: Azure Authentication
```bash
# Login to Azure
az login

# Verify subscription
az account show --output table

# Set subscription if you have multiple
az account set --subscription "your-subscription-name"
```

### Step 3: Deploy Infrastructure (5 minutes)
```bash
# Make script executable
chmod +x scripts/01-azure-infrastructure.sh

# Deploy Azure VM and networking
./scripts/01-azure-infrastructure.sh
```

**Expected Output:**
```
🚀 Bitwarden Azure Infrastructure Setup
✅ Resource group created successfully
✅ Virtual machine created successfully
🌍 Your Bitwarden hostname: vault.20-XXX-XXX-XXX.sslip.io
```

### Step 4: Setup Bitwarden on VM (10 minutes)
```bash
# Get your VM's public IP from previous step
VM_IP=$(az vm show -d --resource-group bitwarden-rg --name bitwarden-vm --query publicIps --output tsv)
echo "Your VM IP: $VM_IP"

# SSH to your VM
ssh azureuser@$VM_IP

# On the VM, run setup scripts:
curl -O https://raw.githubusercontent.com/your-username/Bitwarden-Self-Hosting-Azure/main/vm-setup.sh
chmod +x vm-setup.sh
./vm-setup.sh

# Get Bitwarden hosting credentials from https://bitwarden.com/host
# Then run the official installer:
sudo -u bitwarden /opt/bitwarden/bitwarden.sh install
```

**During Installation, Provide:**
1. **Domain**: `vault.20-XXX-XXX-XXX.sslip.io` (your sslip.io hostname)
2. **Let's Encrypt**: `Y` (for free SSL certificate)
3. **Install ID**: Get from bitwarden.com/host
4. **Install Key**: Get from bitwarden.com/host

### Step 5: Start Services
```bash
# Still on the VM:
sudo -u bitwarden /opt/bitwarden/bitwarden.sh start

# Verify all containers are healthy (wait 2-3 minutes)
sudo docker ps
```

### Step 6: Configure SMTP (Email Support)
```bash
# Edit email configuration
sudo -u bitwarden nano /opt/bitwarden/bwdata/env/global.override.env

# Add your email settings (example with Gmail):
globalSettings__mail__smtp__host=smtp.gmail.com
globalSettings__mail__smtp__port=587
globalSettings__mail__smtp__ssl=false
globalSettings__mail__smtp__username=your-email@gmail.com
globalSettings__mail__smtp__password=your-gmail-app-password

# Restart to apply changes
sudo -u bitwarden /opt/bitwarden/bitwarden.sh restart
```

---

## 🎯 Access Your Bitwarden

### Web Vault
Visit: `https://vault.20-XXX-XXX-XXX.sslip.io`
- Create your master account
- Install browser extensions
- Configure mobile apps

### Admin Panel
Visit: `https://vault.20-XXX-XXX-XXX.sslip.io/admin`
- Manage users and organizations
- Configure SSO settings
- Monitor system health
- View audit logs

---

## 🔐 Azure AD SAML SSO Setup

### Step 1: Create Enterprise Application
```bash
# In Azure Portal or CLI:
az ad app create --display-name "Bitwarden SAML SSO"
```

### Step 2: Configure SAML Settings
In Azure Portal → Enterprise Applications → Bitwarden SAML SSO:

**Basic SAML Configuration:**
```
Identifier (Entity ID): https://your-hostname/sso/saml2
Reply URL: https://your-hostname/sso/saml2/Acs  
Sign on URL: https://your-hostname/#/sso
```

**User Attributes & Claims:**
- **Name ID**: `user.objectid` (recommended for stability)
- **Email**: `user.mail`
- **First Name**: `user.givenname`
- **Last Name**: `user.surname`

### Step 3: Configure Bitwarden SSO
In Bitwarden Admin Panel → Organizations → SSO:
1. Select **SAML 2.0**
2. Use certificate and URLs from Azure AD
3. Test authentication flow

---

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Users         │    │  Azure AD        │    │   Azure VM      │
│                 │    │                  │    │                 │
│ ┌─────────────┐ │    │ ┌──────────────┐ │    │ ┌─────────────┐ │
│ │ Web Clients │ │◄──►│ │ SAML IdP     │ │◄──►│ │ Bitwarden   │ │
│ │ Mobile Apps │ │    │ │ Enterprise   │ │    │ │ (Official)  │ │
│ │ Extensions  │ │    │ │ Application  │ │    │ │ 10+ Services│ │
│ └─────────────┘ │    │ └──────────────┘ │    │ └─────────────┘ │
└─────────────────┘    └──────────────────┘    └─────────────────┘
        ↑                        ↑                        ↑
   HTTPS Client              SAML Auth              Docker Containers
```

### Container Architecture
```bash
# 10+ Production Containers:
bitwarden-web             # Web vault UI
bitwarden-api             # Core API service  
bitwarden-identity        # Authentication service
bitwarden-sso             # SAML/SSO service
bitwarden-admin           # Admin panel
bitwarden-notifications   # Push notifications
bitwarden-events          # Audit logging
bitwarden-icons           # Website icons
bitwarden-attachments     # File uploads
bitwarden-mssql           # SQL Server database
bitwarden-nginx           # Reverse proxy
```

---

## 📊 Current Performance

**Live Performance Metrics** (tested):
- **Server Response**: ~1.8 seconds (needs optimization)
- **Database**: Microsoft SQL Server
- **Uptime**: 8+ days continuous
- **SSL**: Let's Encrypt (A+ rating)
- **Containers**: All healthy

**Recommended Optimizations:**
1. **Upgrade VM**: Standard_B2s → Standard_D2s_v3 (4 vCPU, 8GB RAM)
2. **Configure Caching**: Add nginx response caching
3. **Optimize SQL**: Increase SQL Server memory allocation

---

## 🛠️ Management Commands

### Service Management
```bash
# SSH to your VM first:
ssh azureuser@YOUR_VM_IP

# Switch to bitwarden user:
sudo -u bitwarden -i
cd /opt/bitwarden

# Service operations:
./bitwarden.sh start      # Start all services
./bitwarden.sh stop       # Stop all services  
./bitwarden.sh restart    # Restart services
./bitwarden.sh update     # Update to latest version

# Monitoring:
docker ps                 # Check container status
docker logs bitwarden-api # View API logs
./bitwarden.sh checksmtp  # Test email configuration
```

### Health Checks
```bash
# Test web access:
curl -I https://your-hostname

# Test API health:
curl https://your-hostname/api/alive

# Check SSL certificate:
echo | openssl s_client -connect your-hostname:443 -servername your-hostname 2>/dev/null | openssl x509 -noout -dates
```

### Backup & Maintenance
```bash
# Create backup:
sudo tar -czf bitwarden-backup-$(date +%Y%m%d).tar.gz /opt/bitwarden/bwdata

# Update Bitwarden:
./bitwarden.sh updateself
./bitwarden.sh update
./bitwarden.sh restart
```

---

## 🔧 Troubleshooting

### Common Issues

**1. Can't Access Web Vault**
```bash
# Check container status:
docker ps

# Check nginx logs:
docker logs bitwarden-nginx

# Verify ports are open:
netstat -tlnp | grep -E ':80|:443'
```

**2. Password Reset Emails Not Working**
```bash
# Check SMTP configuration:
cat /opt/bitwarden/bwdata/env/global.override.env | grep mail

# Test SMTP:
./bitwarden.sh checksmtp
```

**3. Slow Performance** 
- **Immediate**: Clear mobile app cache
- **Short-term**: Upgrade VM to Standard_D2s_v3
- **Long-term**: Implement caching and CDN

**4. SSL Certificate Issues**
```bash
# Check certificate status:
./bitwarden.sh renewcert

# View certificate details:
openssl x509 -in /opt/bitwarden/bwdata/ssl/your-hostname/certificate.crt -text -noout
```

---

## 💰 Cost Estimates

### Azure Resources
| Component | Size | Monthly Cost (USD) |
|-----------|------|-------------------|
| **VM** | Standard_B2s (current) | ~$35-45 |
| **VM** | Standard_D2s_v3 (recommended) | ~$70-85 |
| **Storage** | 30GB Premium SSD | ~$5-8 |
| **Networking** | Standard IP + bandwidth | ~$3-8 |
| **Total** | Current setup | **~$40-60/month** |
| **Total** | Optimized setup | **~$80-100/month** |

### Additional Costs
- **Bitwarden License**: Contact Bitwarden for enterprise pricing
- **Domain Name**: $10-15/year (optional, sslip.io is free)

---

## 🔒 Security Considerations

### Production Security Checklist
- [ ] **SMTP Configured**: Email notifications working
- [ ] **SSL Certificate**: Let's Encrypt auto-renewal enabled  
- [ ] **Firewall Rules**: Only ports 22, 80, 443 open
- [ ] **Admin Access**: Strong admin token configured
- [ ] **Backups**: Regular automated backups scheduled
- [ ] **Updates**: Bitwarden updates applied monthly
- [ ] **Monitoring**: Health checks and alerts configured

### Security Best Practices
1. **Admin Token**: Generated securely (current: see `configure-saml.py`)
2. **Database**: Encrypted at rest on Premium SSD
3. **Network**: Azure NSG restricts access
4. **Containers**: Isolated Docker networks
5. **SSL/TLS**: Modern protocols only (TLS 1.2+)

---

## 📚 Documentation

- **[Complete Architecture Analysis](REPOSITORY-ARCHITECTURE-ANALYSIS.md)** - Deep technical dive
- **[Implementation Guide](docs/02-implementation-guide.md)** - Detailed setup steps
- **[SAML SSO Configuration](docs/03-saml-sso-guide.md)** - Azure AD integration
- **[Troubleshooting Guide](docs/04-troubleshooting-guide.md)** - Common issues
- **[Local Development](LOCAL-DEPLOYMENT.md)** - Vaultwarden alternative

---

## 🤝 Contributing

This is a demonstration project showcasing enterprise Bitwarden deployment. Issues and improvements welcome!

### Development Setup
```bash
# For local testing (uses Vaultwarden):
./generate-ssl.sh
docker-compose up -d
# Access at https://localhost
```

---

## 📄 License

This project is for demonstration purposes. Bitwarden server requires appropriate licensing for production use.

- **Official Bitwarden**: Commercial license required for production
- **Scripts & Configuration**: MIT License
- **Azure Resources**: Standard Azure pricing applies

---

## 🏆 Enterprise Integration Showcase

This repository demonstrates:
- ✅ **Production Infrastructure**: Real Azure deployment with monitoring
- ✅ **Enterprise Authentication**: SAML SSO with Azure AD integration  
- ✅ **Container Orchestration**: 10+ microservice containers
- ✅ **Security Implementation**: SSL, firewall rules, secrets management
- ✅ **DevOps Automation**: Infrastructure as code with Azure CLI
- ✅ **Performance Analysis**: Real-world performance testing and optimization
- ✅ **Documentation**: Comprehensive setup and troubleshooting guides

**Perfect for demonstrating enterprise integration engineering skills and Azure infrastructure expertise.**

---

*🚀 Ready to deploy your own enterprise password management solution? Start with Step 1 above!*