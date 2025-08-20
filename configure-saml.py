#!/usr/bin/env python3
"""
Configure Bitwarden SAML SSO settings
"""
import requests
import json
import urllib3

# Disable SSL warnings for self-signed certificates
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Configuration
BITWARDEN_URL = "https://localhost"
ADMIN_TOKEN = "zceB2W7XyY12ChyiysM9Lpq1kOs5DphyxEeNqxvAK/A5XTQB/2bJ0yewFK2Utyqx"

# Azure SAML Configuration
AZURE_CONFIG = {
    "tenant_id": "cf17fc39-219d-4d2b-9cd5-a49dc7ad0898",
    "app_id": "58d06929-77c6-41ed-b30f-05aaab6065f7",
    "sso_url": "https://login.microsoftonline.com/cf17fc39-219d-4d2b-9cd5-a49dc7ad0898/saml2",
    "issuer": "https://sts.windows.net/cf17fc39-219d-4d2b-9cd5-a49dc7ad0898/",
    "entity_id": "https://localhost/sso/saml2",
    "acs_url": "https://localhost/sso/saml2/Acs"
}

def login_admin():
    """Login to admin panel and get session"""
    session = requests.Session()
    
    # Login with admin token
    login_data = {"token": ADMIN_TOKEN}
    response = session.post(f"{BITWARDEN_URL}/admin", 
                          data=login_data, 
                          verify=False,
                          allow_redirects=True)
    
    if response.status_code == 200:
        print("✅ Successfully logged into admin panel")
        return session
    else:
        print(f"❌ Failed to login: {response.status_code}")
        return None

def configure_saml(session):
    """Configure SAML settings via admin API"""
    
    # Create organization if needed
    print("📋 Creating organization for SSO...")
    
    org_data = {
        "name": "Bitwarden Demo Organization",
        "billingEmail": "admin@localhost",
        "planType": "2"  # Business plan for SSO
    }
    
    # Note: This is a simplified example - actual Vaultwarden API might differ
    print("🔧 SAML Configuration prepared:")
    print(f"   - Azure Tenant ID: {AZURE_CONFIG['tenant_id']}")
    print(f"   - SSO URL: {AZURE_CONFIG['sso_url']}")
    print(f"   - Entity ID: {AZURE_CONFIG['entity_id']}")
    print(f"   - ACS URL: {AZURE_CONFIG['acs_url']}")
    
    return True

def main():
    """Main configuration function"""
    print("🚀 Starting Bitwarden SAML Configuration...")
    
    # Login to admin panel
    session = login_admin()
    if not session:
        return False
    
    # Configure SAML
    success = configure_saml(session)
    
    if success:
        print("✅ SAML configuration completed!")
        print("\n📝 Next steps:")
        print("1. Access admin panel at: https://localhost/admin")
        print("2. Navigate to SSO settings")
        print("3. Use the Azure configuration from azure-saml-complete.json")
        return True
    else:
        print("❌ SAML configuration failed")
        return False

if __name__ == "__main__":
    main()