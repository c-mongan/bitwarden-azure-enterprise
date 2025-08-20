# Bitwarden-Self-Hosting-Azure

Here's the simplest + most impressive project to build for Bitwarden's Integration Engineer role that you can realistically finish in an afternoon and proudly put on your CV.

## 🚀 Quick Local Demo (5 minutes)

**Need an immediate working Bitwarden instance for demos or development?**

```bash
# Generate SSL certificates
./generate-ssl.sh

# Configure environment
cp .env.example .env
# Edit .env and set ADMIN_TOKEN (generate with: openssl rand -base64 48)

# Start local deployment
docker-compose up -d

# Access at https://localhost
```

📖 **[Complete Local Deployment Guide](LOCAL-DEPLOYMENT.md)**

This local setup provides a fully functional Bitwarden instance using Vaultwarden, perfect for:
- Job interview demonstrations
- Development and testing
- Quick proof-of-concept deployments
- Azure connectivity troubleshooting workarounds

⸻

## TL;DR (Azure Cloud Deployment)

Spin up a single Ubuntu VM on Azure, deploy self-hosted Bitwarden with Docker, secure it with Let's Encrypt (HTTPS), wire SSO (SAML) to Microsoft Entra ID, and—if you have an Org license—flip on SCIM. Use a wildcard DNS helper like sslip.io if you don't own a domain yet. This exactly mirrors Bitwarden's recommended install path and the identity flows customers ask for.  ￼

⸻

Why this is the “best ROI”
	•	Directly matches Bitwarden’s docs and customer asks: Docker install on Linux, ports 80/443, domain + cert, SMTP, SSO (SAML), optional SCIM. That’s their official journey.  ￼
	•	No domain? Still easy: sslip.io (or nip.io) gives you a hostname that maps to your VM’s IP, so you can still pass Let’s Encrypt’s checks.  ￼ ￼
	•	Let’s Encrypt is straightforward—just keep port 80 open for HTTP-01: the challenge must hit port 80 (and you’ll redirect to 443 after).  ￼

⸻

Step-by-step (copy/paste friendly)

1) Make a tiny Azure VM + open web ports

# Login
az login

# Resource group (pick your preferred region)
az group create -n bw-rg -l westeurope

# Ubuntu VM (B2s is plenty for a lab)
az vm create -g bw-rg -n bw-vm --image Ubuntu2204 --size Standard_B2s \
  --admin-username azureuser --generate-ssh-keys

# Open HTTP/HTTPS (needed for Let's Encrypt and the site)
az vm open-port -g bw-rg -n bw-vm --port 80
az vm open-port -g bw-rg -n bw-vm --port 443

Azure’s az vm and open-port commands are documented here; also consider VM auto-shutdown to save cost.  ￼

No domain? Use sslip.io. If your VM IP is 20.51.123.45, a name like vault.20-51-123-45.sslip.io will resolve to it.  ￼

2) SSH in and install Docker (for containers)

ssh azureuser@<vm-ip>
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc >/dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo ${UBUNTU_CODENAME:-$VERSION_CODENAME}) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

Bitwarden’s Linux guide uses Docker + Compose to run all services.  ￼

3) Install Bitwarden the easy way (script)

# good practice: a dedicated user & folder
sudo adduser bitwarden
sudo mkdir -p /opt/bitwarden && sudo chown bitwarden:bitwarden /opt/bitwarden && sudo chmod 700 /opt/bitwarden
sudo -iu bitwarden
cd /opt/bitwarden

# download + run installer
curl -Lso bitwarden.sh "https://func.bitwarden.com/api/dl/?app=self-host&platform=linux" && chmod 700 bitwarden.sh
./bitwarden.sh install

When prompted:
	•	Domain: your hostname (real domain or vault.<ip-dashed>.sslip.io).
	•	Let’s Encrypt: pick Y for a free, trusted cert (requires 80/443 open).
	•	Install ID/Key: the script links you to get them.
If you skip a cert, Bitwarden warns you must front with HTTPS or clients won’t work—so use Let’s Encrypt.  ￼

Start it:

./bitwarden.sh start
docker ps   # all containers should be "healthy"

￼

4) SMTP (email) so verification/invites work (fast dev option)

Edit ./bwdata/env/global.override.env (values from your mail provider—Mailtrap or any SMTP works):

globalSettings__mail__smtp__host=smtp.example.com
globalSettings__mail__smtp__port=587
globalSettings__mail__smtp__ssl=false      # true if using SMTPS/465
globalSettings__mail__smtp__username=USER
globalSettings__mail__smtp__password=PASS
adminSettings__admins=you@yourdomain.com   # grants Admin Portal access

Apply + test:

./bitwarden.sh restart
./bitwarden.sh checksmtp

These exact vars + the checksmtp helper are in the Bitwarden doc.  ￼

5) SSO with Microsoft Entra ID (SAML)—the crowd-pleaser

Follow Bitwarden’s Entra SAML guide (it walks both portals side-by-side). In Azure, create a non-gallery Enterprise App, paste the SP Entity ID and ACS URL from Bitwarden, set the Sign-on URL to your vault https://<host>/#/sso, and use the Base64 certificate from Azure in Bitwarden’s SSO page. For stability, set NameID to user.objectid. Then test.  ￼

6) (Optional) SCIM auto-provisioning

If you have a Teams/Enterprise org, enable SCIM in self-host (enable_scim: true in bwdata/config.yml, rebuild/update), then add Azure SCIM integration (Provisioning → Automatic, paste SCIM URL + token, Test Connection).  ￼

⸻

What to show on your CV / portfolio
	•	One bullet (impact-first):
“Deployed self-hosted Bitwarden on Azure (Docker) with Let’s Encrypt (HTTPS) and SAML SSO via Microsoft Entra ID; enabled SCIM provisioning for automated user/group lifecycle; produced a 1-page runbook + 15-min demo.”
	•	Screenshots to include:
	1.	https://<host> with the web vault login, 2) Entra Enterprise App SAML config, 3) Bitwarden SSO settings (redact secrets), 4) SCIM Test connection green check (if enabled).
	•	Why reviewers care: it proves you can deploy containerized Bitwarden, handle TLS/ports/DNS, and integrate SSO/SCIM—straight from the official playbook that customers follow.  ￼

⸻

Tiny glossary (super simple)
	•	DNS name: the friendly name your browser uses (you can use sslip.io if you don’t own a domain).  ￼
	•	HTTPS/TLS: the padlock; you’ll get a real certificate with Let’s Encrypt (needs port 80 open to validate).  ￼
	•	Docker: runs apps in “boxes” so Bitwarden’s parts start together and stay consistent.  ￼
	•	SAML SSO: “Log in with Microsoft” via Entra ID; paste URLs/cert between portals per the guide; set NameID to user.objectid.  ￼
	•	SCIM: automatic user/group sync from Entra to Bitwarden (flip a flag, rebuild, then connect Azure).  ￼

⸻

## 🔧 Troubleshooting

### Azure Connectivity Issues

If experiencing `management.azure.com` timeouts or Azure CLI connectivity problems:

1. **Use Local Deployment**: Switch to the local Docker deployment for immediate functionality
   ```bash
   # Quick local setup
   ./generate-ssl.sh
   cp .env.example .env
   # Edit .env and set ADMIN_TOKEN
   docker-compose up -d
   ```

2. **Azure CLI Diagnostics**
   ```bash
   # Test basic connectivity
   az account show
   
   # Test Azure endpoints
   curl -I https://management.azure.com
   
   # Reset Azure CLI
   az logout
   az login --use-device-code
   ```

### Quick alternatives if something blocks you
	•	**Azure timeouts**: Use the local deployment above for immediate demos
	•	No domain yet: stick with sslip.io; it resolves hostnames embedded with your VM's IP.  ￼
	•	Ports blocked: move them in Azure NSG using az vm open-port.  ￼
	•	Let's Encrypt failing: verify 80/443 are open; HTTP-01 must reach port 80.  ￼

⸻

If you want, I can tailor this into a single paste-once script for your VM (prompts for hostname, installs Docker, runs the Bitwarden installer, and prints the exact SAML fields to copy), plus a 1-page runbook you can hand to interviewers.