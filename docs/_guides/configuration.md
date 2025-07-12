---
layout: guide
title: Configuration
nav_order: 3
description: Complete configuration reference for Buidl
---

# Configuration Guide
{: .no_toc }

Complete reference for configuring Buidl with all available options and best practices.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Configuration Methods

### Environment Variables

The primary configuration method using environment variables:

```bash
# Set directly
export SLACK_BOT_TOKEN="xoxb-your-token"

# Or use .env file
echo "SLACK_BOT_TOKEN=xoxb-your-token" >> .env
```

### Configuration File

Generate a template configuration file:

```bash
# Create .env template
buidl-config

# Create custom location
buidl-config --output /path/to/config/.env
```

### Runtime Configuration

Override settings at runtime:

```bash
# Override specific settings
PRIVACY_LEVEL=medium buidl

# Multiple overrides
AI_ENABLED=false PORT=3000 buidl
```

---

## Required Configuration

### Slack Authentication

#### Socket Mode (Recommended)
```bash
# Bot token for API access
SLACK_BOT_TOKEN=xoxb-your-bot-token-here

# App-level token for Socket Mode
SLACK_APP_TOKEN=xapp-your-app-level-token-here

# Bot user ID for mention detection
BOT_USER_ID=U1234567890
```

#### HTTP Mode (Alternative)
```bash
# Bot token for API access
SLACK_BOT_TOKEN=xoxb-your-bot-token-here

# Signing secret for webhook verification
SLACK_SIGNING_SECRET=your-signing-secret-here
```

### AI Integration

```bash
# OpenRouter API key
OPENROUTER_API_KEY=sk-or-your-api-key-here

# Model selection (optional)
OPENROUTER_MODEL=anthropic/claude-3.5-sonnet
```

---

## Optional Configuration

### AI Settings

```bash
# Enable/disable AI responses
AI_ENABLED=true

# Response generation
AI_RESPONSE_MAX_TOKENS=800
AI_TEMPERATURE=0.7
AI_CONVERSATION_STYLE=helpful  # helpful, casual, professional

# Context management
MAX_CONTEXT_MESSAGES=8
CONTEXT_WINDOW_HOURS=24
ENABLE_CONVERSATION_SUMMARY=true
```

### Privacy Settings

```bash
# Privacy level: high, medium, low
PRIVACY_LEVEL=high

# Enterprise zero data retention
USE_ENTERPRISE_ZDR=false
```

#### Privacy Levels

| Level | Description | Processing | Performance |
|-------|-------------|------------|-------------|
| **high** | Local-only processing | All local | Fastest |
| **medium** | Filtered external | PII filtered | Balanced |
| **low** | Full external | Cloud-based | Most features |

### Database Configuration

```bash
# Database location
DB_PATH=./data/buidl.db

# Storage settings
MAX_MESSAGE_HISTORY=10000
MESSAGE_RETENTION_DAYS=30
```

### Server Settings

```bash
# HTTP server port
PORT=8080

# Webhook path (HTTP mode)
WEBHOOK_PATH=/slack/events

# Request timeout
REQUEST_TIMEOUT_MS=30000
```

### Action Settings

```bash
# Enable command execution
ENABLE_ACTIONS=true

# Require confirmation for actions
ACTION_CONFIRMATION_REQUIRED=true

# Allowed action types
ALLOWED_ACTIONS=git,npm,docker,shell
```

### Response Settings

```bash
# Auto-respond to mentions
AUTO_RESPOND_TO_MENTIONS=true

# Response delay
RESPONSE_DELAY_MS=1000

# Typing indicators
SHOW_TYPING_INDICATOR=true
```

### Socket Mode Settings

```bash
# Connection management
SOCKET_PING_INTERVAL=30
SOCKET_RECONNECT_ATTEMPTS=5
SOCKET_RECONNECT_DELAY=5

# Performance tuning
SOCKET_RECEIVE_TIMEOUT=1
SOCKET_SEND_TIMEOUT=5
```

---

## Advanced Configuration

### Channel Restrictions

```bash
# Restrict to specific channels (comma-separated)
SLACK_CHANNEL_WHITELIST=C1234567890,C0987654321

# Exclude specific channels
SLACK_CHANNEL_BLACKLIST=C1111111111

# Require bot to be mentioned
REQUIRE_MENTION=true
```

### User Restrictions

```bash
# Allow specific users only
USER_WHITELIST=U1234567890,U0987654321

# Block specific users
USER_BLACKLIST=U1111111111

# Admin users (can override settings)
ADMIN_USERS=U1234567890
```

### Logging Configuration

```bash
# Log level: debug, info, warn, error
LOG_LEVEL=info

# Log file location
LOG_FILE=./logs/buidl.log

# Enable request logging
LOG_REQUESTS=true

# Enable AI conversation logging
LOG_AI_CONVERSATIONS=false
```

### Performance Tuning

```bash
# Vector database settings
VECTOR_SEARCH_LIMIT=10
VECTOR_SIMILARITY_THRESHOLD=0.7

# Embedding settings
EMBEDDING_CACHE_SIZE=1000
EMBEDDING_BATCH_SIZE=10

# HTTP client settings
HTTP_TIMEOUT_MS=10000
HTTP_RETRY_ATTEMPTS=3
```

---

## Environment-Specific Configuration

### Development

```bash
# Development settings
NODE_ENV=development
DEBUG=true
LOG_LEVEL=debug

# Relaxed security
REQUIRE_MENTION=false
ACTION_CONFIRMATION_REQUIRED=false

# Fast responses
AI_RESPONSE_MAX_TOKENS=200
MAX_CONTEXT_MESSAGES=3
```

### Production

```bash
# Production settings
NODE_ENV=production
DEBUG=false
LOG_LEVEL=info

# Enhanced security
PRIVACY_LEVEL=high
ACTION_CONFIRMATION_REQUIRED=true
USE_ENTERPRISE_ZDR=true

# Optimized performance
AI_RESPONSE_MAX_TOKENS=800
MAX_CONTEXT_MESSAGES=8
SOCKET_PING_INTERVAL=60
```

### Testing

```bash
# Test settings
NODE_ENV=test
AI_ENABLED=false
LOG_LEVEL=error

# Test-specific overrides
SLACK_BOT_TOKEN=xoxb-test-token
DB_PATH=./test-data/test.db
```

---

## Configuration Validation

### Validate Configuration

```bash
# Validate current configuration
buidl-config --validate

# Check specific settings
buidl-config --check slack,ai,database

# Test API connections
buidl-config --test-connections
```

### Common Validation Errors

**Missing required settings**
```
❌ SLACK_BOT_TOKEN is required
❌ OPENROUTER_API_KEY is required
```

**Invalid token format**
```
❌ SLACK_BOT_TOKEN must start with 'xoxb-'
❌ SLACK_APP_TOKEN must start with 'xapp-'
```

**Connection failures**
```
❌ Cannot connect to Slack API (check SLACK_BOT_TOKEN)
❌ Cannot connect to OpenRouter (check OPENROUTER_API_KEY)
```

---

## Configuration Best Practices

### Security

1. **Use environment variables** for sensitive data
2. **Never commit API keys** to version control
3. **Rotate tokens regularly** (every 90 days)
4. **Use secure file permissions** (`chmod 600 .env`)
5. **Store secrets in vault** for production

### Performance

1. **Choose appropriate privacy level** for your needs
2. **Limit context messages** for faster responses
3. **Use Socket Mode** for real-time performance
4. **Configure appropriate timeouts** for your network
5. **Monitor resource usage** and adjust limits

### Reliability

1. **Set reasonable retry limits** for network requests
2. **Configure health checks** for monitoring
3. **Use graceful shutdown** with proper signal handling
4. **Implement circuit breakers** for external services
5. **Monitor error rates** and adjust configuration

---

## Configuration Examples

### Minimal Configuration

```bash
# Minimal working configuration
SLACK_BOT_TOKEN=xoxb-your-token
SLACK_APP_TOKEN=xapp-your-app-token
BOT_USER_ID=U1234567890
OPENROUTER_API_KEY=sk-or-your-key
```

### High-Performance Configuration

```bash
# Optimized for performance
SLACK_BOT_TOKEN=xoxb-your-token
SLACK_APP_TOKEN=xapp-your-app-token
BOT_USER_ID=U1234567890
OPENROUTER_API_KEY=sk-or-your-key

# Performance settings
PRIVACY_LEVEL=medium
AI_RESPONSE_MAX_TOKENS=400
MAX_CONTEXT_MESSAGES=5
SOCKET_PING_INTERVAL=60
VECTOR_SEARCH_LIMIT=5
```

### High-Security Configuration

```bash
# Optimized for security
SLACK_BOT_TOKEN=xoxb-your-token
SLACK_APP_TOKEN=xapp-your-app-token
BOT_USER_ID=U1234567890
OPENROUTER_API_KEY=sk-or-your-key

# Security settings
PRIVACY_LEVEL=high
USE_ENTERPRISE_ZDR=true
ENABLE_ACTIONS=false
ACTION_CONFIRMATION_REQUIRED=true
REQUIRE_MENTION=true
USER_WHITELIST=U1234567890,U0987654321
```

---

## Troubleshooting Configuration

### Debug Configuration Loading

```bash
# Show loaded configuration
buidl-config --show

# Show configuration sources
buidl-config --sources

# Test configuration validation
buidl-config --dry-run
```

### Common Issues

**Configuration not loading**
- Check file permissions
- Verify file path is correct
- Ensure proper environment variable format

**API connection failures**
- Validate token format and permissions
- Test network connectivity
- Check firewall settings

**Performance issues**
- Review resource limits
- Adjust timeout settings
- Monitor system resources

---

## Next Steps

- **[WebSocket Setup](websocket-setup/)** - Configure Socket Mode
- **[Deployment Guide](deployment/)** - Production deployment
- **[Privacy Guide](privacy/)** - Privacy and security settings
- **[Monitoring Guide](monitoring/)** - Configuration monitoring