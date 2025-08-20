#!/bin/bash
echo "🧪 Manual Testing Guide for Bitwarden Integration"
echo "================================================"

echo "1. 🌐 Test Web Access"
echo "   Open: https://localhost"
echo "   Expected: Bitwarden login page (accept certificate warning)"
echo ""

echo "2. 👤 Create Test Account"
echo "   Click 'Create Account'"
echo "   Email: test@localhost.com"
echo "   Password: TestPassword123!"
echo "   Expected: Account created successfully"
echo ""

echo "3. 🔐 Test Basic Functions"
echo "   Login with test account"
echo "   Add new password entry"
echo "   Test password generator"
echo "   Expected: Full password manager functionality"
echo ""

echo "4. 👨‍💼 Test Admin Panel"
echo "   Open: https://localhost/admin"
echo "   Token: zceB2W7XyY12ChyiysM9Lpq1kOs5DphyxEeNqxvAK/A5XTQB/2bJ0yewFK2Utyqx"
echo "   Expected: Admin dashboard with user management"
echo ""

echo "5. 🔗 Test Azure Integration"
echo "   Open Azure Portal → Enterprise Applications → Bitwarden SAML"
echo "   Try 'Test single sign-on'"
echo "   Expected: Azure AD authenticates, Bitwarden endpoint fails (expected)"
echo ""

echo "6. 📊 Verify Architecture"
echo "   Check containers: docker ps"
echo "   Check logs: docker logs vaultwarden"
echo "   Check config: cat azure-saml-complete.json"
echo "   Expected: All systems operational"
echo ""

# Test basic connectivity
echo "🔍 Running automated tests..."

# Test web server
if curl -k -s https://localhost >/dev/null; then
    echo "   ✅ Web server responding"
else
    echo "   ❌ Web server not responding"
fi

# Test API
if curl -k -s https://localhost/api/config >/dev/null; then
    echo "   ✅ API responding"
else
    echo "   ❌ API not responding"
fi

# Test admin panel
if curl -k -s https://localhost/admin | grep -q "admin token"; then
    echo "   ✅ Admin panel accessible"
else
    echo "   ❌ Admin panel not accessible"
fi

# Test Azure integration
if az rest --method GET --uri "https://graph.microsoft.com/v1.0/servicePrincipals/0261697c-356d-4711-8660-8b18c89dec8f" --query "displayName" -o tsv 2>/dev/null | grep -q "Bitwarden SAML"; then
    echo "   ✅ Azure Enterprise Application configured"
else
    echo "   ❌ Azure integration issue"
fi

echo ""
echo "🎯 Demo Success Criteria:"
echo "   ✅ Web vault accessible and functional"
echo "   ✅ Admin panel working with token auth"  
echo "   ✅ Azure AD Enterprise Application configured"
echo "   ✅ SAML settings properly configured"
echo "   ✅ Complete automation via CLI/scripts"
echo ""
echo "💡 For interviews, focus on:"
echo "   • The Azure AD integration complexity you solved"
echo "   • The automation and infrastructure-as-code approach"
echo "   • The enterprise architecture patterns demonstrated"
echo "   • The security and compliance considerations"