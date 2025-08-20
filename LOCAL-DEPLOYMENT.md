# Local Bitwarden Deployment Guide

This guide provides instructions for setting up a local Bitwarden instance using Vaultwarden for immediate demonstration purposes.

## Quick Start (5-minute setup)

### Prerequisites
- Docker and Docker Compose installed
- OpenSSL (usually pre-installed on macOS/Linux)

### 1. Clone and Setup
```bash
# Navigate to project directory
cd /path/to/bitwarden-project

# Generate SSL certificates
chmod +x generate-ssl.sh
./generate-ssl.sh

# Create environment file
cp .env.example .env
```

### 2. Configure Admin Access
```bash
# Generate a secure admin token
openssl rand -base64 48

# Edit .env file and add the generated token
nano .env
# Set ADMIN_TOKEN=your_generated_token_here
```

### 3. Start Services
```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps
```

### 4. Access Your Bitwarden Instance
- **Web Vault**: https://localhost (accept the self-signed certificate warning)
- **Admin Panel**: https://localhost/admin (use your admin token)

## Detailed Configuration

### Environment Variables

Create a `.env` file with the following variables:

```env
# Required: Admin token for management
ADMIN_TOKEN=your_secure_token_here

# Optional: Email configuration for user invitations
SMTP_HOST=smtp.gmail.com
SMTP_FROM=your-email@gmail.com
SMTP_PORT=587
SMTP_SECURITY=starttls
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

### SSL Configuration

The deployment uses self-signed certificates for HTTPS:
- Certificate: `nginx/ssl/localhost.crt`
- Private Key: `nginx/ssl/localhost.key`

For production deployments, replace these with valid certificates.

### Data Persistence

Vaultwarden data is stored in `./vaultwarden-data/` directory, which includes:
- User accounts and vault data
- Organization settings
- Application configuration

## Usage Instructions

### Creating Your First Account

1. Navigate to https://localhost
2. Click "Create Account"
3. Fill in your email and master password
4. Complete email verification (if SMTP is configured)

### Admin Panel Access

1. Navigate to https://localhost/admin
2. Enter your admin token
3. Manage users, organizations, and system settings

### Client Applications

Configure Bitwarden clients to use your local instance:
- **Server URL**: `https://localhost`
- Accept the self-signed certificate when prompted

## Troubleshooting

### Common Issues

1. **Certificate warnings**: Expected with self-signed certificates - click "Advanced" and proceed
2. **Port conflicts**: Ensure ports 80, 443, 8080, and 3012 are available
3. **Permission issues**: Ensure Docker has proper permissions for volume mounts

### Logs and Debugging

```bash
# View logs
docker-compose logs vaultwarden
docker-compose logs nginx

# Follow logs in real-time
docker-compose logs -f

# Restart services
docker-compose restart
```

### Stopping the Deployment

```bash
# Stop services (keeps data)
docker-compose down

# Stop and remove volumes (removes all data)
docker-compose down -v
```

## Production Considerations

This local deployment is designed for demonstration and development. For production use:

1. Use valid SSL certificates
2. Configure proper email settings
3. Set up regular backups
4. Implement proper firewall rules
5. Use environment-specific secrets management

## Demo Scenarios

### For Interview Demonstrations

1. **Account Creation**: Show user registration process
2. **Password Management**: Demonstrate adding/editing passwords
3. **Organization Features**: Create organizations and invite users
4. **Browser Integration**: Show browser extension functionality
5. **Mobile Access**: Demonstrate mobile app connectivity
6. **Admin Features**: Show user management and system monitoring

### Key Features to Highlight

- Self-hosted security and privacy
- Cross-platform compatibility
- Real-time synchronization
- Organization and sharing capabilities
- Comprehensive admin controls
- SAML SSO integration (if configured)

## Support

For issues specific to this local deployment, check:
1. Docker container logs
2. Nginx configuration
3. SSL certificate validity
4. Port availability

For Vaultwarden-specific issues, refer to the [official documentation](https://github.com/dani-garcia/vaultwarden/wiki).