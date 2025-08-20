#!/bin/bash

# Create SSL directory if it doesn't exist
mkdir -p nginx/ssl

# Generate self-signed SSL certificate for localhost
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout nginx/ssl/localhost.key \
    -out nginx/ssl/localhost.crt \
    -subj "/C=US/ST=Local/L=Local/O=Development/OU=IT Department/CN=localhost"

echo "SSL certificates generated successfully!"
echo "Certificate: nginx/ssl/localhost.crt"
echo "Private Key: nginx/ssl/localhost.key"