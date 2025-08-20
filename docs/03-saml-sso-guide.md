# SAML SSO Configuration Guide

## 🎯 Overview

This guide provides detailed instructions for configuring SAML SSO between Bitwarden self-hosted and Microsoft Entra ID (Azure AD). This integration enables users to authenticate using their corporate Azure AD credentials.

---

## 🔧 Prerequisites

- ✅ Bitwarden self-hosted instance running with HTTPS
- ✅ Azure AD tenant with admin privileges
- ✅ Ability to create Enterprise Applications in Azure AD
- ✅ Test user accounts in Azure AD

---

## 🏗️ SAML Architecture Overview

```
User Browser          Azure AD (IdP)         Bitwarden (SP)
     │                      │                      │
     │──── 1. Access SSO ───┤                      │
     │                      │                      │
     │                      │←── 2. AuthnRequest ──│
     │                      │                      │
     │←── 3. Redirect to ───┤                      │
     │       Azure AD       │                      │
     │                      │                      │
     │──── 4. Login ────────┤                      │
     │                      │                      │
     │←── 5. SAML Response ─┤                      │
     │    (with assertion)  │                      │
     │                      │                      │
     │──── 6. POST to ACS ─────────────────────────┤
     │                      │                      │
     │←─── 7. Access Granted ──────────────────────┤
```

**Key Terms:**
- **IdP (Identity Provider)**: Azure AD - authenticates users
- **SP (Service Provider)**: Bitwarden - provides the service
- **AuthnRequest**: SAML authentication request
- **ACS**: Assertion Consumer Service - receives SAML responses

---

## 🔐 Phase 1: Azure AD Configuration

### Step 1.1: Create Enterprise Application

1. **Navigate to Azure Portal**:
   ```
   https://portal.azure.com
   → Azure Active Directory
   → Enterprise Applications
   → + New Application
   ```

2. **Create Custom Application**:
   - Click "Create your own application"
   - Name: `Bitwarden Self-Hosted`
   - Select: "Integrate any other application you don't find in the gallery"
   - Click "Create"

### Step 1.2: Configure Single Sign-On

1. **Access SSO Settings**:
   ```
   Enterprise Application → Single sign-on → SAML
   ```

2. **Edit Basic SAML Configuration**:
   ```
   Identifier (Entity ID):
   https://your-hostname/sso/saml2
   
   Reply URL (Assertion Consumer Service URL):
   https://your-hostname/sso/saml2/Acs
   
   Sign on URL:
   https://your-hostname/#/sso
   ```

   **Example with sslip.io**:
   ```
   Identifier: https://vault.20-51-123-45.sslip.io/sso/saml2
   Reply URL: https://vault.20-51-123-45.sslip.io/sso/saml2/Acs
   Sign on URL: https://vault.20-51-123-45.sslip.io/#/sso
   ```

### Step 1.3: Configure User Attributes & Claims

**Critical Configuration:**
1. **Name ID Configuration**:
   ```
   Source attribute: user.objectid
   Name identifier format: Default
   ```

2. **Why ObjectID?**
   - ✅ Stable - doesn't change when user email changes
   - ✅ Unique - guaranteed unique across tenant
   - ✅ Persistent - doesn't change over time
   - ❌ Don't use UPN/email - can change and cause user identity issues

3. **Additional Claims** (Optional):
   ```
   Claim name: http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress
   Source attribute: user.mail
   
   Claim name: http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname
   Source attribute: user.givenname
   
   Claim name: http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname
   Source attribute: user.surname
   ```

### Step 1.4: Download Certificate

1. **In SAML Signing Certificate section**:
   - Download "Certificate (Base64)"
   - Save as `azure-ad-certificate.cer`
   - Keep this file safe - you'll need it for Bitwarden

2. **Certificate Format Verification**:
   ```bash
   # Certificate should look like this:
   -----BEGIN CERTIFICATE-----
   MIICmzCCAYMCBgGH...
   [base64 encoded content]
   ...Qw==
   -----END CERTIFICATE-----
   ```

### Step 1.5: Note Azure AD URLs

**From the "Set up Bitwarden Self-Hosted" section, note:**
```
Login URL: https://login.microsoftonline.com/YOUR_TENANT_ID/saml2
Logout URL: https://login.microsoftonline.com/YOUR_TENANT_ID/saml2
Azure AD Identifier: https://sts.windows.net/YOUR_TENANT_ID/
```

**To find your Tenant ID:**
```
Azure Portal → Azure Active Directory → Overview → Tenant ID
```

---

## 🔧 Phase 2: Bitwarden Configuration

### Step 2.1: Access Bitwarden Admin Portal

1. **Navigate to Admin Portal**:
   ```
   https://your-hostname/admin
   ```

2. **Login with Admin Credentials**:
   - Use the admin email configured in SMTP settings
   - Check your email for login verification

### Step 2.2: Configure SSO Settings

1. **Navigate to SSO**:
   ```
   Admin Portal → Single Sign-On → SAML 2.0
   ```

2. **SP Configuration** (Service Provider):
   ```
   SP Entity ID: https://your-hostname/sso/saml2
   ```

3. **IdP Configuration** (Identity Provider):
   ```
   IdP Entity ID: https://sts.windows.net/YOUR_TENANT_ID/
   
   IdP Single Sign-On Service URL:
   https://login.microsoftonline.com/YOUR_TENANT_ID/saml2
   
   IdP Single Log Out Service URL:
   https://login.microsoftonline.com/YOUR_TENANT_ID/saml2
   ```

4. **Certificate Configuration**:
   ```
   X509 Public Certificate:
   [Paste the full content of azure-ad-certificate.cer including headers]
   ```

5. **Advanced Settings**:
   ```
   Name ID Format: Not configured
   Outbound Signing Algorithm: rsa-sha256
   Signing Behavior: If IdP wants authn requests signed
   Validate Certificates: Checked
   ```

### Step 2.3: Create Organization with SSO

1. **Create New Organization**:
   ```
   Admin Portal → Organizations → New Organization
   ```

2. **Organization Settings**:
   ```
   Name: Test Organization
   Plan: Free (for testing)
   ```

3. **Enable SSO**:
   ```
   Organization → Settings → Single Sign-On
   → Enable SSO Authentication
   → SSO Identifier: test-org (choose something memorable)
   ```

---

## ✅ Phase 3: Testing Authentication

### Step 3.1: SP-Initiated SSO Test

1. **Access SSO Login Page**:
   ```
   https://your-hostname/#/sso
   ```

2. **Enter Organization Identifier**:
   ```
   SSO Identifier: test-org
   ```

3. **Complete Authentication Flow**:
   - Should redirect to Azure AD
   - Login with Azure AD credentials
   - Should redirect back to Bitwarden
   - Should be logged into Bitwarden vault

### Step 3.2: Troubleshooting Authentication Issues

**Common Error Messages and Solutions:**

**"Invalid SAML Response"**
```
Cause: Certificate or metadata mismatch
Solution: 
- Verify certificate format (including headers)
- Check Entity IDs match exactly
- Ensure URLs are correct
```

**"User not found"**
```
Cause: User mapping issue
Solution:
- Verify NameID is set to user.objectid
- Check user exists in both Azure AD and is assigned to app
- Confirm user has been invited to Bitwarden organization
```

**"Authentication failed"**
```
Cause: Various configuration issues
Solution:
- Check Bitwarden logs: docker logs bitwarden-identity
- Verify certificate hasn't expired
- Confirm Azure AD app is active
```

### Step 3.3: User Management

**Assign Users to Application:**
1. ```
   Azure AD → Enterprise Applications → Bitwarden Self-Hosted
   → Users and groups → + Add user/group
   ```

2. **Select Users**:
   - Choose test users
   - Assign appropriate roles

**Invite Users to Bitwarden Organization:**
1. ```
   Bitwarden Admin → Organizations → Test Organization → Members
   → Invite User
   ```

2. **Invitation Process**:
   - Enter user's Azure AD email
   - User will receive email invitation
   - User can then use SSO to access

---

## 🔍 Phase 4: Advanced Configuration

### Step 4.1: IdP-Initiated SSO (Optional)

**Enable from Azure AD Portal:**
1. ```
   Azure AD → Enterprise Applications → Bitwarden Self-Hosted
   → Single sign-on → Edit Basic SAML Configuration
   ```

2. **Add Relay State**:
   ```
   Relay State: https://your-hostname/#/sso?organizationIdentifier=test-org
   ```

3. **Test from Azure AD**:
   - Go to Azure AD My Apps portal
   - Click Bitwarden application
   - Should directly access Bitwarden vault

### Step 4.2: Group-Based Access (Optional)

**Azure AD Groups Configuration:**
1. **Create Security Group**:
   ```
   Azure AD → Groups → New Group
   Name: Bitwarden Users
   Type: Security
   ```

2. **Assign Group to Application**:
   ```
   Enterprise Application → Users and groups
   → Add user/group → Select group
   ```

3. **Map Groups in Claims** (Optional):
   ```
   SAML Claims → Add group claim
   Source attribute: Security groups
   ```

---

## 📊 Monitoring & Maintenance

### Step 5.1: Health Monitoring

**Check SAML Endpoint Health:**
```bash
# Test SP metadata endpoint
curl https://your-hostname/sso/saml2

# Test IdP connectivity
curl -I https://login.microsoftonline.com/YOUR_TENANT_ID/saml2
```

**Monitor Authentication Logs:**
```bash
# Bitwarden identity service logs
docker logs bitwarden-identity --tail 100

# Filter for SAML events
docker logs bitwarden-identity 2>&1 | grep -i saml
```

### Step 5.2: Certificate Management

**Monitor Certificate Expiry:**
```bash
# Check Azure AD certificate expiry
openssl x509 -in azure-ad-certificate.cer -text -noout | grep -A2 Validity

# Check Let's Encrypt certificate
echo | openssl s_client -connect your-hostname:443 2>/dev/null | openssl x509 -noout -dates
```

**Certificate Rotation Process:**
1. Download new certificate from Azure AD
2. Update certificate in Bitwarden admin portal
3. Test authentication flows
4. Monitor for any failures

---

## 🚨 Troubleshooting Reference

### Common Issues and Solutions

**Issue: "SAML assertion audience restriction validation failed"**
```
Cause: Entity ID mismatch
Check: Verify SP Entity ID in Bitwarden matches Identifier in Azure AD exactly
```

**Issue: "Invalid signature on SAML assertion"**
```
Cause: Certificate problem
Check: Ensure certificate is properly formatted with headers/footers
```

**Issue: "NameID not found in assertion"**
```
Cause: NameID configuration issue
Check: Verify Azure AD is sending user.objectid as NameID
```

**Issue: Users redirected but not logged in**
```
Cause: User not in organization
Check: Ensure user is invited to Bitwarden organization
```

### Debug Commands

```bash
# Check SAML metadata
curl https://your-hostname/sso/saml2/metadata

# View detailed identity logs
docker logs bitwarden-identity --since 1h

# Test SAML assertion
curl -X POST https://your-hostname/sso/saml2/Acs \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "SAMLResponse=<base64_encoded_response>"
```

---

## 🎯 Testing Checklist

**Pre-Production Validation:**
- [ ] SP-initiated SSO works
- [ ] IdP-initiated SSO works (if configured)
- [ ] User attributes map correctly
- [ ] Organization access is properly restricted
- [ ] Logout functionality works
- [ ] Certificate validation passes
- [ ] Error handling works gracefully

**Security Verification:**
- [ ] HTTPS enforced for all SAML endpoints
- [ ] Certificate signatures validated
- [ ] User identity mapping is stable
- [ ] Unauthorized users cannot access
- [ ] Session management works correctly

---

## 💡 Interview Talking Points

### Technical Expertise
- "I configured SAML 2.0 with proper certificate validation and user attribute mapping"
- "I chose ObjectID for NameID to ensure stable user identity even when emails change"
- "The configuration supports both SP-initiated and IdP-initiated SSO flows"

### Problem-Solving Examples
- "When SAML assertion validation failed, I debugged by examining the certificate format and Entity ID configuration"
- "I implemented proper error handling so users get meaningful feedback when authentication fails"
- "I set up monitoring to proactively detect certificate expiration issues"

### Business Value
- "This integration eliminates password fatigue and improves security posture"
- "Users have a seamless experience with their existing corporate credentials"
- "IT administrators can manage access centrally through Azure AD groups"

---

*This SAML configuration follows Microsoft and Bitwarden best practices for enterprise identity integration.*