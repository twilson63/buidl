# Deployment Guide

This guide covers production deployment of Buidl - the AI-powered dev bot.

## 🚀 Quick Deployment

### 1. Production Server Setup

```bash
# Download and extract release
curl -L https://github.com/your-org/ai-slack-bot/releases/latest/download/buidl-v1.0.0.tar.gz -o buidl-v1.0.0.tar.gz
tar -xzf buidl-v1.0.0.tar.gz
cd release

# Install system-wide
sudo ./scripts/install.sh
```

### 2. Configuration

```bash
# Create configuration
buidl-config

# Edit with production values
sudo nano /usr/local/buidl/config/.env
```

### 3. Service Setup

```bash
# Create systemd service
sudo tee /etc/systemd/system/buidl.service > /dev/null <<EOF
[Unit]
Description=Buidl Dev Bot
After=network.target

[Service]
Type=simple
User=buidl
WorkingDirectory=/usr/local/buidl/config
ExecStart=/usr/local/buidl/bin/buidl
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create user and permissions
sudo useradd -r -s /bin/false buidl
sudo chown -R buidl:buidl /usr/local/buidl/
sudo chmod 750 /usr/local/buidl/config/

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable buidl
sudo systemctl start buidl
```

### 4. Monitoring

```bash
# Check status
sudo systemctl status buidl

# View logs
sudo journalctl -u buidl -f

# Health check
curl http://localhost:8080/health
```

## 🐳 Docker Deployment

### Dockerfile

```dockerfile
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    tar \
    && rm -rf /var/lib/apt/lists/*

# Install Hype runtime (if needed)
RUN curl -sSL https://hype-install-url.sh | bash

# Create app directory
WORKDIR /app

# Copy release files
COPY buidl-v1.0.0.tar.gz .
RUN tar -xzf buidl-v1.0.0.tar.gz
RUN mv release/* .

# Create user
RUN useradd -r -s /bin/false slack-bot
RUN chown -R slack-bot:slack-bot /app

# Expose port
EXPOSE 8080

# Set user
USER slack-bot

# Run bot
CMD ["./bin/slack-bot"]
```

### Docker Compose

```yaml
version: '3.8'

services:
  slack-bot:
    build: .
    ports:
      - "8080:8080"
    environment:
      - SLACK_BOT_TOKEN=${SLACK_BOT_TOKEN}
      - SLACK_SIGNING_SECRET=${SLACK_SIGNING_SECRET}
      - OPENROUTER_API_KEY=${OPENROUTER_API_KEY}
      - PRIVACY_LEVEL=high
      - DB_PATH=/data/slack_bot.db
    volumes:
      - slack-bot-data:/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

volumes:
  slack-bot-data:
```

## ☁️ Cloud Deployment

### AWS EC2

```bash
# Launch EC2 instance
aws ec2 run-instances \
    --image-id ami-0c55b159cbfafe1d0 \
    --instance-type t3.medium \
    --key-name my-key \
    --security-group-ids sg-12345678 \
    --subnet-id subnet-12345678

# Connect and setup
ssh -i my-key.pem ubuntu@ec2-instance-ip
sudo apt-get update
sudo apt-get install -y curl nginx

# Install bot
curl -L https://github.com/your-org/ai-slack-bot/releases/latest/download/buidl-v1.0.0.tar.gz -o buidl-v1.0.0.tar.gz
tar -xzf buidl-v1.0.0.tar.gz
cd release
sudo ./scripts/install.sh

# Configure nginx reverse proxy
sudo tee /etc/nginx/sites-available/slack-bot > /dev/null <<EOF
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/slack-bot /etc/nginx/sites-enabled/
sudo systemctl restart nginx
```

### Google Cloud Run

```yaml
# cloudbuild.yaml
steps:
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/slack-bot:latest', '.']
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/slack-bot:latest']
  - name: 'gcr.io/cloud-builders/gcloud'
    args:
      - 'run'
      - 'deploy'
      - 'slack-bot'
      - '--image=gcr.io/$PROJECT_ID/slack-bot:latest'
      - '--region=us-central1'
      - '--platform=managed'
      - '--allow-unauthenticated'
      - '--port=8080'
      - '--memory=1Gi'
      - '--set-env-vars'
      - 'SLACK_BOT_TOKEN=$$SLACK_BOT_TOKEN,SLACK_SIGNING_SECRET=$$SLACK_SIGNING_SECRET,OPENROUTER_API_KEY=$$OPENROUTER_API_KEY'
```

### Kubernetes

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: slack-bot
spec:
  replicas: 1
  selector:
    matchLabels:
      app: slack-bot
  template:
    metadata:
      labels:
        app: slack-bot
    spec:
      containers:
      - name: slack-bot
        image: your-registry/slack-bot:latest
        ports:
        - containerPort: 8080
        env:
        - name: SLACK_BOT_TOKEN
          valueFrom:
            secretKeyRef:
              name: slack-bot-secrets
              key: token
        - name: SLACK_SIGNING_SECRET
          valueFrom:
            secretKeyRef:
              name: slack-bot-secrets
              key: signing-secret
        - name: OPENROUTER_API_KEY
          valueFrom:
            secretKeyRef:
              name: slack-bot-secrets
              key: openrouter-key
        volumeMounts:
        - name: data
          mountPath: /data
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: slack-bot-data

---
apiVersion: v1
kind: Service
metadata:
  name: slack-bot
spec:
  selector:
    app: slack-bot
  ports:
  - port: 80
    targetPort: 8080
  type: LoadBalancer

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: slack-bot-data
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

## 🔧 Configuration Management

### Environment Variables

```bash
# Production environment variables
export SLACK_BOT_TOKEN="xoxb-your-production-token"
export SLACK_SIGNING_SECRET="your-production-secret"
export OPENROUTER_API_KEY="sk-or-your-production-key"
export PRIVACY_LEVEL="high"
export DB_PATH="/var/lib/slack-bot/db"
export PORT="8080"
export AI_ENABLED="true"
export AI_RESPONSE_MAX_TOKENS="800"
export MAX_CONTEXT_MESSAGES="8"
export CONTEXT_WINDOW_HOURS="24"
```

### Secrets Management

#### AWS Secrets Manager

```bash
# Store secrets
aws secretsmanager create-secret \
    --name slack-bot/production \
    --secret-string '{
        "slack_bot_token": "xoxb-your-token",
        "slack_signing_secret": "your-secret",
        "openrouter_api_key": "sk-or-your-key"
    }'

# Retrieve in deployment script
SECRET=$(aws secretsmanager get-secret-value \
    --secret-id slack-bot/production \
    --query SecretString \
    --output text)

export SLACK_BOT_TOKEN=$(echo $SECRET | jq -r .slack_bot_token)
export SLACK_SIGNING_SECRET=$(echo $SECRET | jq -r .slack_signing_secret)
export OPENROUTER_API_KEY=$(echo $SECRET | jq -r .openrouter_api_key)
```

#### Kubernetes Secrets

```bash
# Create secrets
kubectl create secret generic slack-bot-secrets \
    --from-literal=token=xoxb-your-token \
    --from-literal=signing-secret=your-secret \
    --from-literal=openrouter-key=sk-or-your-key
```

## 🔒 Security Hardening

### SSL/TLS Configuration

```bash
# Install certbot
sudo apt-get install certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

### Firewall Configuration

```bash
# Configure UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable
```

### File Permissions

```bash
# Secure configuration files
sudo chmod 600 /usr/local/buidl/config/.env
sudo chown slack-bot:slack-bot /usr/local/buidl/config/.env

# Secure database directory
sudo mkdir -p /var/lib/slack-bot
sudo chown slack-bot:slack-bot /var/lib/slack-bot
sudo chmod 750 /var/lib/slack-bot
```

## 📊 Monitoring and Logging

### Log Management

```bash
# Configure log rotation
sudo tee /etc/logrotate.d/slack-bot > /dev/null <<EOF
/var/log/slack-bot/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 slack-bot slack-bot
    postrotate
        systemctl reload slack-bot
    endscript
}
EOF
```

### Metrics Collection

```bash
# Prometheus metrics endpoint
curl http://localhost:8080/stats

# Example output:
{
    "uptime_seconds": 86400,
    "messages_processed": 1250,
    "ai_responses_generated": 45,
    "vector_database": {
        "total_messages": 1250,
        "storage_mb": 15.2
    },
    "privacy": {
        "level": "high",
        "score": 85.0
    }
}
```

### Health Checks

```bash
#!/bin/bash
# health-check.sh
HEALTH_URL="http://localhost:8080/health"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_URL)

if [ $RESPONSE -eq 200 ]; then
    echo "OK: Slack bot is healthy"
    exit 0
else
    echo "ERROR: Slack bot is unhealthy (HTTP $RESPONSE)"
    exit 1
fi
```

## 🔄 Backup and Recovery

### Database Backup

```bash
#!/bin/bash
# backup-script.sh
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/var/backups/slack-bot"
DB_PATH="/var/lib/slack-bot/db"

mkdir -p $BACKUP_DIR
cp -r $DB_PATH $BACKUP_DIR/db_backup_$DATE
tar -czf $BACKUP_DIR/slack-bot-backup-$DATE.tar.gz -C $BACKUP_DIR db_backup_$DATE
rm -rf $BACKUP_DIR/db_backup_$DATE

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
```

### Disaster Recovery

```bash
# Restore from backup
tar -xzf slack-bot-backup-20240101_120000.tar.gz
sudo systemctl stop slack-bot
sudo cp -r db_backup_20240101_120000/* /var/lib/slack-bot/db/
sudo chown -R slack-bot:slack-bot /var/lib/slack-bot/db/
sudo systemctl start slack-bot
```

## 🚀 Performance Optimization

### System Tuning

```bash
# Increase file descriptor limits
echo "slack-bot soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "slack-bot hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# Optimize TCP settings
sudo tee -a /etc/sysctl.conf > /dev/null <<EOF
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
EOF

sudo sysctl -p
```

### Application Tuning

```bash
# Environment variables for performance
export MAX_CONTEXT_MESSAGES=5      # Reduce for faster responses
export CONTEXT_WINDOW_HOURS=12     # Reduce for less memory usage
export AI_RESPONSE_MAX_TOKENS=400  # Reduce for faster AI responses
```

## 🔍 Troubleshooting

### Common Issues

1. **Bot not responding to mentions**
   ```bash
   # Check logs
   sudo journalctl -u slack-bot -f
   
   # Verify webhook URL in Slack app settings
   # Check firewall rules
   sudo ufw status
   ```

2. **High memory usage**
   ```bash
   # Check memory usage
   ps aux | grep slack-bot
   
   # Reduce context window
   export CONTEXT_WINDOW_HOURS=6
   export MAX_CONTEXT_MESSAGES=3
   ```

3. **Database corruption**
   ```bash
   # Stop service
   sudo systemctl stop slack-bot
   
   # Restore from backup
   sudo cp -r /var/backups/slack-bot/latest/* /var/lib/slack-bot/db/
   
   # Start service
   sudo systemctl start slack-bot
   ```

### Debug Mode

```bash
# Enable debug logging
export DEBUG=1
slack-bot-run
```

## 📋 Deployment Checklist

### Pre-deployment

- [ ] Test release on staging environment
- [ ] Run full test suite
- [ ] Verify all configuration values
- [ ] Check SSL certificates
- [ ] Backup existing data
- [ ] Notify team of deployment window

### Deployment

- [ ] Deploy to production
- [ ] Run health checks
- [ ] Verify bot responds to mentions
- [ ] Check logs for errors
- [ ] Monitor resource usage
- [ ] Test key functionality

### Post-deployment

- [ ] Monitor for 24 hours
- [ ] Check error rates
- [ ] Verify backup automation
- [ ] Update documentation
- [ ] Send deployment notification
- [ ] Schedule next maintenance window

## 📞 Support

For deployment issues:
- Check logs: `sudo journalctl -u slack-bot -f`
- Health check: `curl http://localhost:8080/health`
- Statistics: `curl http://localhost:8080/stats`
- Documentation: [docs/](docs/)
- Issues: [GitHub Issues](https://github.com/your-org/ai-slack-bot/issues)