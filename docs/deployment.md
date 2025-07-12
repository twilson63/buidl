---
layout: default
title: Deployment Guide
description: Deploy Buidl to production environments
permalink: /guides/deployment/
---

# Deployment Guide

Complete guide for deploying Buidl to production environments with best practices for security, monitoring, and maintenance.

## Quick Deployment

### Docker Deployment (Recommended)

```bash
# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl tar && \
    rm -rf /var/lib/apt/lists/*

# Install Hype framework
RUN curl -sSL https://raw.githubusercontent.com/twilson63/hype/main/install.sh | bash

# Create app directory
WORKDIR /app

# Copy release
COPY buidl-v1.1.0-source.tar.gz .
RUN tar -xzf buidl-v1.1.0-source.tar.gz --strip-components=1 && \
    ./build.sh

# Create non-root user
RUN useradd -r -s /bin/false buidl
RUN chown -R buidl:buidl /app
USER buidl

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080
CMD ["./buidl-socket"]
EOF

# Build and run
docker build -t buidl:latest .
docker run -d --name buidl \
    -e SLACK_BOT_TOKEN="$SLACK_BOT_TOKEN" \
    -e SLACK_APP_TOKEN="$SLACK_APP_TOKEN" \
    -e BOT_USER_ID="$BOT_USER_ID" \
    -e OPENROUTER_API_KEY="$OPENROUTER_API_KEY" \
    -p 8080:8080 \
    buidl:latest
```

### Kubernetes Deployment

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: buidl
  labels:
    app: buidl
spec:
  replicas: 1
  selector:
    matchLabels:
      app: buidl
  template:
    metadata:
      labels:
        app: buidl
    spec:
      containers:
      - name: buidl
        image: buidl:latest
        ports:
        - containerPort: 8080
        env:
        - name: SLACK_BOT_TOKEN
          valueFrom:
            secretKeyRef:
              name: buidl-secrets
              key: slack-bot-token
        - name: SLACK_APP_TOKEN
          valueFrom:
            secretKeyRef:
              name: buidl-secrets
              key: slack-app-token
        - name: BOT_USER_ID
          valueFrom:
            secretKeyRef:
              name: buidl-secrets
              key: bot-user-id
        - name: OPENROUTER_API_KEY
          valueFrom:
            secretKeyRef:
              name: buidl-secrets
              key: openrouter-api-key
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
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        volumeMounts:
        - name: data
          mountPath: /app/data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: buidl-data

---
apiVersion: v1
kind: Secret
metadata:
  name: buidl-secrets
type: Opaque
stringData:
  slack-bot-token: "xoxb-your-token"
  slack-app-token: "xapp-your-token"
  bot-user-id: "U1234567890"
  openrouter-api-key: "sk-or-your-key"

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: buidl-data
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

## Production Configuration

### Environment Variables

```bash
# Production .env
NODE_ENV=production
LOG_LEVEL=info

# Slack Configuration
SLACK_BOT_TOKEN=xoxb-production-token
SLACK_APP_TOKEN=xapp-production-token
BOT_USER_ID=U1234567890

# AI Configuration
OPENROUTER_API_KEY=sk-or-production-key
AI_RESPONSE_MAX_TOKENS=800
MAX_CONTEXT_MESSAGES=8

# Security
PRIVACY_LEVEL=high
USE_ENTERPRISE_ZDR=true
ACTION_CONFIRMATION_REQUIRED=true

# Performance
SOCKET_PING_INTERVAL=60
DB_PATH=/data/buidl.db
```

### Security Hardening

```bash
# Create dedicated user
sudo useradd -r -s /bin/false buidl
sudo mkdir -p /opt/buidl/{bin,config,data,logs}
sudo chown -R buidl:buidl /opt/buidl

# Set secure permissions
sudo chmod 750 /opt/buidl/config
sudo chmod 700 /opt/buidl/data
sudo chmod 755 /opt/buidl/logs

# Secure configuration files
sudo chmod 600 /opt/buidl/config/.env
sudo chown buidl:buidl /opt/buidl/config/.env
```

## Monitoring and Logging

### Health Checks

```bash
#!/bin/bash
# health-check.sh

HEALTH_URL="http://localhost:8080/health"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL")

if [ "$RESPONSE" -eq 200 ]; then
    echo "✅ Buidl is healthy"
    exit 0
else
    echo "❌ Buidl is unhealthy (HTTP $RESPONSE)"
    exit 1
fi
```

### Prometheus Metrics

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'buidl'
    static_configs:
      - targets: ['localhost:8080']
    metrics_path: '/metrics'
    scrape_interval: 30s
```

### Log Aggregation

```yaml
# docker-compose.yml for ELK stack
version: '3.8'
services:
  buidl:
    image: buidl:latest
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    labels:
      - "co.elastic.logs/enabled=true"
      - "co.elastic.logs/service.name=buidl"
```

## Backup and Recovery

### Database Backup

```bash
#!/bin/bash
# backup-script.sh

BACKUP_DIR="/backups/buidl"
DATE=$(date +%Y%m%d_%H%M%S)
DB_PATH="/opt/buidl/data/buidl.db"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup database
cp "$DB_PATH" "$BACKUP_DIR/buidl_${DATE}.db"

# Compress old backups
find "$BACKUP_DIR" -name "*.db" -mtime +1 -exec gzip {} \;

# Remove backups older than 30 days
find "$BACKUP_DIR" -name "*.gz" -mtime +30 -delete

echo "✅ Backup completed: buidl_${DATE}.db"
```

### Disaster Recovery

```bash
#!/bin/bash
# restore-script.sh

BACKUP_FILE="$1"
DB_PATH="/opt/buidl/data/buidl.db"

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup-file>"
    exit 1
fi

# Stop service
systemctl stop buidl

# Backup current database
cp "$DB_PATH" "${DB_PATH}.backup.$(date +%s)"

# Restore from backup
cp "$BACKUP_FILE" "$DB_PATH"
chown buidl:buidl "$DB_PATH"

# Start service
systemctl start buidl

echo "✅ Database restored from $BACKUP_FILE"
```

## Performance Tuning

### System Optimization

```bash
# Increase file descriptor limits
echo "buidl soft nofile 65536" >> /etc/security/limits.conf
echo "buidl hard nofile 65536" >> /etc/security/limits.conf

# Optimize TCP settings
cat >> /etc/sysctl.conf << 'EOF'
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
EOF

sysctl -p
```

### Application Tuning

```bash
# Performance environment variables
export MAX_CONTEXT_MESSAGES=5        # Reduce for faster responses
export CONTEXT_WINDOW_HOURS=12       # Reduce memory usage
export AI_RESPONSE_MAX_TOKENS=400    # Faster AI responses
export VECTOR_SEARCH_LIMIT=5         # Limit search results
```

## Troubleshooting

### Common Issues

#### High Memory Usage
```bash
# Monitor memory usage
ps aux | grep buidl
top -p $(pgrep buidl)

# Reduce memory footprint
export MAX_CONTEXT_MESSAGES=3
export CONTEXT_WINDOW_HOURS=6
systemctl restart buidl
```

#### Connection Issues
```bash
# Check WebSocket connectivity
netstat -tulpn | grep :8080
curl -I http://localhost:8080/health

# Test Slack connectivity
curl -X POST https://slack.com/api/auth.test \
  -H "Authorization: Bearer $SLACK_BOT_TOKEN"
```

#### Database Corruption
```bash
# Check database integrity
sqlite3 /opt/buidl/data/buidl.db "PRAGMA integrity_check;"

# Repair database
sqlite3 /opt/buidl/data/buidl.db "VACUUM;"

# Restore from backup if needed
./restore-script.sh /backups/buidl/latest.db
```

## CI/CD Pipeline

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Build Docker image
      run: |
        docker build -t buidl:${{ github.ref_name }} .
        docker tag buidl:${{ github.ref_name }} buidl:latest
    
    - name: Deploy to production
      run: |
        docker stop buidl || true
        docker rm buidl || true
        docker run -d --name buidl \
          --env-file /opt/buidl/config/.env \
          -v /opt/buidl/data:/app/data \
          -p 8080:8080 \
          buidl:latest
    
    - name: Health check
      run: |
        sleep 30
        curl -f http://localhost:8080/health
```

## Scaling

### Horizontal Scaling

```yaml
# kubernetes-hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: buidl-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: buidl
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### Load Balancing

```nginx
# nginx.conf
upstream buidl {
    least_conn;
    server buidl-1:8080;
    server buidl-2:8080;
    server buidl-3:8080;
}

server {
    listen 80;
    server_name buidl.example.com;
    
    location /health {
        proxy_pass http://buidl;
    }
    
    location /stats {
        proxy_pass http://buidl;
    }
}
```

---

Ready to deploy Buidl to production? Follow this guide for a robust, scalable deployment that's ready to handle your team's workload! 🚀