#!/bin/bash

echo "🔐 Starting Local Bitwarden Deployment"
echo "======================================"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if SSL certificates exist
if [ ! -f "nginx/ssl/localhost.crt" ]; then
    echo "🔑 Generating SSL certificates..."
    ./generate-ssl.sh
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "⚙️  Creating environment file..."
    cp .env.example .env
    echo "📝 Please edit .env file and set ADMIN_TOKEN before proceeding."
    echo "💡 Generate token with: openssl rand -base64 48"
    echo ""
    echo "After setting ADMIN_TOKEN, run this script again."
    exit 1
fi

# Check if ADMIN_TOKEN is set
if ! grep -q "ADMIN_TOKEN=.*[^[:space:]]" .env; then
    echo "❌ ADMIN_TOKEN not set in .env file"
    echo "💡 Generate token with: openssl rand -base64 48"
    echo "📝 Edit .env file and set ADMIN_TOKEN=your_generated_token"
    exit 1
fi

echo "🚀 Starting services..."
docker-compose up -d

echo ""
echo "✅ Bitwarden is starting up!"
echo ""
echo "📱 Access Points:"
echo "   • Web Vault: https://localhost"
echo "   • Admin Panel: https://localhost/admin"
echo ""
echo "🔍 Check status: docker-compose ps"
echo "📊 View logs: docker-compose logs -f"
echo "🛑 Stop services: docker-compose down"
echo ""
echo "⚠️  Note: You'll see a certificate warning - this is expected with self-signed certificates."
echo "    Click 'Advanced' and 'Proceed to localhost' to continue."