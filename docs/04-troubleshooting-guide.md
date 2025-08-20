# Bitwarden Self-Hosting Troubleshooting Guide

## 🚨 Quick Diagnostic Commands

Use these commands to quickly assess system health:

```bash
# Overall system health
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check all Bitwarden logs
docker logs bitwarden-web --tail 50
docker logs bitwarden-api --tail 50
docker logs bitwarden-identity --tail 50

# Test web connectivity
curl -I https://your-hostname
curl https://your-hostname/api/alive

# Check disk space
df -h
```

---

## 🐳 Docker & Container Issues

### Container Won't Start

**Symptoms:**
- Container shows "Exited" status
- Service unavailable errors
- Health checks failing

**Diagnostic Steps:**
```bash
# Check container status
docker ps -a

# View startup logs
docker logs bitwarden-api --since 1h

# Check resource usage
docker stats --no-stream

# Inspect container configuration
docker inspect bitwarden-api
```

**Common Causes & Solutions:**

**Port Conflicts:**
```bash
# Check what's using port 80/443
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :443

# If another service is using ports, stop it:
sudo systemctl stop apache2  # or nginx
```

**Memory Issues:**
```bash
# Check system memory
free -h
cat /proc/meminfo | grep Available

# Check Docker memory limits
docker stats

# Increase VM size if needed:
az vm resize --resource-group bitwarden-rg --name bitwarden-vm --size Standard_B4ms
```

**Database Connection Issues:**
```bash
# Check database container
docker logs bitwarden-mssql

# Test database connectivity
docker exec -it bitwarden-mssql /opt/mssql-tools/bin/sqlcmd -S localhost -U sa
```

### Container Health Check Failures

**Check Health Status:**
```bash
# View health check details
docker inspect bitwarden-api | grep -A 20 Health

# Manual health check
curl -f https://your-hostname/api/alive || echo "Health check failed"
```

**Common Fixes:**
```bash
# Restart unhealthy containers
docker restart bitwarden-api

# Full service restart
cd /opt/bitwarden
./bitwarden.sh restart

# Clean restart (removes containers)
./bitwarden.sh stop
docker system prune -f
./bitwarden.sh start
```

---

## 🌐 Network & SSL Issues

### Let's Encrypt Certificate Problems

**Symptoms:**
- Browser shows SSL warnings
- Certificate validation errors
- HTTPS redirects failing

**Diagnostic Commands:**
```bash
# Check certificate validity
echo | openssl s_client -connect your-hostname:443 -servername your-hostname 2>/dev/null | openssl x509 -noout -dates

# Check certificate details
curl -vI https://your-hostname 2>&1 | grep -E "(SSL|certificate|TLS)"

# Test HTTP-01 challenge (Let's Encrypt)
curl -I http://your-hostname/.well-known/acme-challenge/test
```

**Common Issues:**

**Port 80 Not Accessible:**
```bash
# Check Azure NSG rules
az network nsg show --resource-group bitwarden-rg --name bitwarden-vmNSG --query "securityRules[?destinationPortRange=='80']"

# Add rule if missing
az vm open-port --resource-group bitwarden-rg --name bitwarden-vm --port 80 --priority 900
```

**DNS Resolution Issues:**
```bash
# Test DNS resolution
nslookup your-hostname
dig your-hostname

# For sslip.io issues, check IP format:
# Correct: vault.20-51-123-45.sslip.io
# Wrong: vault.20.51.123.45.sslip.io (dots instead of dashes)
```

**Certificate Renewal:**
```bash
# Manual certificate renewal
cd /opt/bitwarden
./bitwarden.sh renewcert

# Check renewal logs
docker logs bitwarden-nginx | grep -i cert
```

---

## 🔐 SAML SSO Issues

### Authentication Failures

**"Invalid SAML Response" Error:**

**Diagnostic Steps:**
```bash
# Check identity service logs
docker logs bitwarden-identity --since 30m | grep -i saml

# Validate certificate format
openssl x509 -in /path/to/certificate.cer -text -noout
```

**Common Causes:**
1. **Certificate Format Issues:**
   ```
   ❌ Missing headers/footers
   ❌ Extra spaces or characters
   ❌ Wrong encoding
   
   ✅ Must include:
   -----BEGIN CERTIFICATE-----
   [base64 content]
   -----END CERTIFICATE-----
   ```

2. **Entity ID Mismatch:**
   ```bash
   # Check Bitwarden SP Entity ID
   curl https://your-hostname/sso/saml2/metadata | grep entityID
   
   # Must match Azure AD Identifier exactly
   ```

**"User Not Found" Error:**

**Common Fixes:**
1. **Verify NameID Configuration:**
   - Azure AD should send `user.objectid`
   - Not email or UPN (which can change)

2. **User Assignment:**
   - User must be assigned to Azure AD Enterprise Application
   - User must be invited to Bitwarden organization

---

## 📧 Email/SMTP Issues

### Email Not Sending

**Test SMTP Configuration:**
```bash
cd /opt/bitwarden
./bitwarden.sh checksmtp
```

**Common SMTP Problems:**

**Gmail Configuration:**
```bash
# Correct Gmail settings for global.override.env:
globalSettings__mail__smtp__host=smtp.gmail.com
globalSettings__mail__smtp__port=587
globalSettings__mail__smtp__ssl=false
globalSettings__mail__smtp__username=your-email@gmail.com
globalSettings__mail__smtp__password=your-app-password  # Not regular password!
```

**Email Logs:**
```bash
# Check email sending logs
docker logs bitwarden-api | grep -i mail
docker logs bitwarden-api | grep -i smtp
```

---

## 💾 Database Issues

### Database Connection Problems

**Symptoms:**
- API errors about database connectivity
- Login failures
- Data not saving

**Diagnostic Commands:**
```bash
# Check database container
docker logs bitwarden-mssql

# Test database connection
docker exec -it bitwarden-mssql /opt/mssql-tools/bin/sqlcmd -S localhost -U sa
```

**Database Recovery:**
```bash
# Stop all services
./bitwarden.sh stop

# Backup current data
sudo cp -r bwdata/mssql/data bwdata/mssql/data.backup

# Start only database
docker-compose -f bwdata/docker/docker-compose.yml up -d mssql
```

---

## 🔧 Performance Issues

### Slow Response Times

**Performance Monitoring:**
```bash
# Check system resources
top
htop  # if installed

# Check Docker container resources
docker stats

# Test response times
time curl https://your-hostname/api/alive
```

**Increase VM Resources:**
```bash
# Scale up VM
az vm deallocate --resource-group bitwarden-rg --name bitwarden-vm
az vm resize --resource-group bitwarden-rg --name bitwarden-vm --size Standard_B4ms
az vm start --resource-group bitwarden-rg --name bitwarden-vm
```

---

## 🛠️ Emergency Recovery Procedures

### Complete Service Recovery

**If Everything is Broken:**
```bash
# 1. Stop all services
cd /opt/bitwarden
./bitwarden.sh stop

# 2. Backup data
sudo tar -czf bitwarden-emergency-backup-$(date +%Y%m%d-%H%M).tar.gz bwdata/

# 3. Clean slate restart
docker system prune -a -f
./bitwarden.sh install
# Follow prompts with same configuration

# 4. Start services
./bitwarden.sh start
```

---

## 📊 Monitoring Checklist

### Daily Health Checks
```bash
#!/bin/bash
# Save as health_check.sh

echo "=== Bitwarden Health Check $(date) ==="

# Container status
echo "Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep bitwarden

# Service endpoints
echo -e "\nService Health:"
curl -s -o /dev/null -w "Web Vault: %{http_code}\n" https://your-hostname/
curl -s -o /dev/null -w "API: %{http_code}\n" https://your-hostname/api/alive

# Certificate expiry
echo -e "\nCertificate:"
echo | openssl s_client -connect your-hostname:443 -servername your-hostname 2>/dev/null | openssl x509 -noout -dates | grep "notAfter"

# Disk space
echo -e "\nDisk Usage:"
df -h | grep -E "(Filesystem|/dev/)"

echo "=== End Health Check ==="
```

---

## 🆘 Getting Help

### Log Collection for Support

**Collect All Relevant Logs:**
```bash
#!/bin/bash
# Save as collect_logs.sh

TIMESTAMP=$(date +%Y%m%d-%H%M)
LOG_DIR="bitwarden-logs-$TIMESTAMP"

mkdir -p $LOG_DIR

# System info
uname -a > $LOG_DIR/system_info.txt
docker --version >> $LOG_DIR/system_info.txt
df -h > $LOG_DIR/disk_usage.txt

# Container logs
docker logs bitwarden-web > $LOG_DIR/web.log 2>&1
docker logs bitwarden-api > $LOG_DIR/api.log 2>&1
docker logs bitwarden-identity > $LOG_DIR/identity.log 2>&1
docker logs bitwarden-mssql > $LOG_DIR/database.log 2>&1

# Configuration (sanitized)
cp bwdata/config.yml $LOG_DIR/
cp bwdata/env/global.override.env $LOG_DIR/ 2>/dev/null || echo "No global override found"

# Create archive
tar -czf $LOG_DIR.tar.gz $LOG_DIR/
echo "Logs collected in: $LOG_DIR.tar.gz"
```

### Support Resources

1. **Bitwarden Community**: https://community.bitwarden.com/
2. **Official Documentation**: https://bitwarden.com/help/
3. **GitHub Issues**: https://github.com/bitwarden/server/issues
4. **Docker Documentation**: https://docs.docker.com/

---

*Keep this guide handy for quick issue resolution and system maintenance.*