---
layout: default
title: WebSocket Setup
description: Enable Socket Mode for real-time WebSocket communication
permalink: /guides/websocket-setup/
---

# WebSocket Setup Guide
{: .no_toc }

Learn how to set up WebSocket-based communication using Slack's Socket Mode for real-time performance.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Overview

WebSocket Socket Mode provides significant advantages over HTTP Events API:

### Performance Benefits
- **75-90% faster response times** (50-200ms vs 500-2000ms)
- **Real-time bidirectional communication**
- **Persistent connections** with automatic reconnection
- **Event-driven architecture** eliminates polling overhead

### Deployment Benefits
- **No public webhook URLs** required
- **Outbound-only connections** enhance security
- **Local development friendly** (no ngrok needed)
- **Simplified networking** and firewall configuration

---

## Slack App Configuration

### Enable Socket Mode

1. Go to your [Slack app settings](https://api.slack.com/apps)
2. Select your Buidl bot app
3. Navigate to **"Socket Mode"** in the sidebar
4. Toggle **"Enable Socket Mode"** to ON

### Generate App-Level Token

1. Click **"Generate an app-level token"**
2. Enter token name: `buidl-socket-token`
3. Add the **`connections:write`** scope
4. Click **"Generate"**
5. Copy the **App-Level Token** (starts with `xapp-`)

⚠️ **Important**: Keep this token secure - it provides app-level access to your Slack workspace.

### Configure Event Subscriptions

1. Navigate to **"Event Subscriptions"**
2. Enable Events (if not already enabled)
3. **Remove webhook URL** (not needed for Socket Mode)
4. Subscribe to **Bot Events**:
   - `app_mention` - When bot is mentioned
   - `message.channels` - Messages in channels bot is added to
   - `message.im` - Direct messages to bot

### Bot Token Scopes

Ensure your bot has these **OAuth scopes**:

- `app_mentions:read` - Read mentions
- `channels:history` - Read channel messages  
- `chat:write` - Send messages
- `im:history` - Read direct messages
- `users:read` - Get user information

---

## Configuration

### Update Environment Variables

Add these variables to your `.env` file:

```bash
# Socket Mode Configuration
SLACK_APP_TOKEN=xapp-your-app-level-token-here
BOT_USER_ID=U1234567890

# Existing Bot Configuration
SLACK_BOT_TOKEN=xoxb-your-bot-token-here
OPENROUTER_API_KEY=sk-or-your-api-key-here
```

### Get Bot User ID

You can find your bot's user ID in several ways:

#### Method 1: Slack API
```bash
curl -X GET https://slack.com/api/auth.test \
  -H "Authorization: Bearer xoxb-your-bot-token" \
  | jq -r '.user_id'
```

#### Method 2: Slack App Settings
1. Go to **"Basic Information"** in your app settings
2. Find **"App Credentials"** section
3. The Bot User ID is listed there

#### Method 3: From Slack Client
1. Go to your Slack workspace
2. Find your bot in the member list
3. Click on the bot profile
4. The user ID is in the profile URL: `slack://user?team=T123&id=U123456789`

### Optional Configuration

```bash
# Connection Management
SOCKET_PING_INTERVAL=30              # Seconds between ping messages
SOCKET_RECONNECT_ATTEMPTS=5          # Maximum reconnection attempts
SOCKET_RECONNECT_DELAY=5             # Seconds between reconnections

# Performance Tuning
SOCKET_RECEIVE_TIMEOUT=1             # Message receive timeout
SOCKET_SEND_TIMEOUT=5                # Message send timeout
```

---

## Running with WebSocket

### Start Socket Mode

```bash
# Primary command (uses Socket Mode by default)
buidl

# Explicit Socket Mode
buidl-socket
```

### Expected Output

```
=== BUIDL v1.1.0 (Socket Mode) ===
AI-powered dev bot with WebSocket integration

📋 Configuration loaded successfully
🔐 Privacy level: high
🤖 AI enabled: yes

🔌 Initializing Slack Socket Mode...
Connecting to Slack Socket Mode: wss://wss-primary.slack.com/websocket/...
✅ WebSocket connection established
📞 Received hello from Slack
✅ Slack Socket Mode client initialized

🚀 Starting Buidl Socket Mode bot...
💬 Ready to receive messages via WebSocket!
```

### Health Monitoring

Check connection status:

```bash
# View connection health
curl http://localhost:8080/socket-status

# Monitor statistics
curl http://localhost:8080/stats | grep -i socket
```

---

## Testing WebSocket Connection

### Test Bot Mention

In your Slack workspace:

```
@Buidl Bot hello! Testing WebSocket connection.
```

You should see:
- **Instant response** (50-200ms latency)
- **Real-time message processing** in bot logs
- **No polling delays**

### Performance Comparison

Test response times:

```bash
# Socket Mode (WebSocket)
time echo "@Buidl Bot quick test" | slack-send

# HTTP Mode (for comparison)  
time echo "@Buidl Bot quick test" | slack-send-http
```

Expected results:
- **Socket Mode**: 50-200ms
- **HTTP Mode**: 500-2000ms

---

## Connection Management

### Automatic Reconnection

The bot automatically handles:
- **Network disconnections** with exponential backoff
- **Slack service interruptions** with retry logic
- **Connection health monitoring** with ping/pong

### Manual Reconnection

If needed, restart the connection:

```bash
# Graceful restart
pkill -TERM buidl-socket
buidl-socket

# Or use systemd (if installed as service)
sudo systemctl restart buidl
```

### Connection Troubleshooting

Debug connection issues:

```bash
# Enable WebSocket debugging
export WEBSOCKET_DEBUG=1
buidl-socket

# Check connection logs
tail -f ~/.buidl/logs/websocket.log

# Test basic connectivity
websocket-test wss://wss-primary.slack.com/websocket/test
```

---

## Security Considerations

### Outbound-Only Connections

Socket Mode provides enhanced security:
- **No open ports** - bot initiates all connections
- **No webhook endpoints** to secure
- **Encrypted connections** via WSS (WebSocket Secure)
- **Token-based authentication** with scoped permissions

### Token Security

Protect your App-Level Token:

```bash
# Store in secure environment file
echo "SLACK_APP_TOKEN=xapp-..." >> ~/.buidl/.env.secure
chmod 600 ~/.buidl/.env.secure

# Use environment variables in production
export SLACK_APP_TOKEN="$(vault kv get -field=slack_app_token secret/buidl)"
```

### Network Security

Configure firewall for outbound-only:

```bash
# Allow outbound HTTPS/WSS only
sudo ufw allow out 443/tcp
sudo ufw deny in 443/tcp

# Block unnecessary inbound connections
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

---

## Migration from HTTP Mode

### Gradual Migration

1. **Test Socket Mode** alongside existing HTTP setup
2. **Verify functionality** with Socket Mode enabled
3. **Monitor performance** and stability
4. **Switch primary mode** to Socket Mode
5. **Disable HTTP webhooks** when confident

### Rollback Plan

Keep HTTP mode as fallback:

```bash
# Quick switch to HTTP mode if needed
buidl-http

# Or update configuration
echo "USE_SOCKET_MODE=false" >> .env
buidl
```

### Configuration Comparison

| Setting | Socket Mode | HTTP Mode |
|---------|-------------|-----------|
| **SLACK_APP_TOKEN** | Required | Not used |
| **BOT_USER_ID** | Required | Optional |
| **SLACK_SIGNING_SECRET** | Not used | Required |
| **Webhook URL** | Not needed | Required |
| **Public endpoint** | Not needed | Required |

---

## Troubleshooting

### Common Issues

**"Invalid App-Level Token"**
- Verify token starts with `xapp-`
- Check token has `connections:write` scope
- Ensure Socket Mode is enabled in app settings

**"WebSocket connection failed"**
- Check network connectivity
- Verify firewall allows outbound HTTPS (port 443)
- Test with WebSocket debugging enabled

**"Bot not responding to mentions"**
- Verify `BOT_USER_ID` is correct
- Check bot permissions in channels
- Ensure Event Subscriptions are configured

### Debug Commands

```bash
# Test WebSocket module
buidl-test --websocket

# Validate Socket Mode configuration
buidl-config --validate-socket

# Check connection health
curl http://localhost:8080/socket-health
```

---

## Next Steps

- **[Deployment Guide](deployment/)** - Deploy Socket Mode to production
- **[Performance Tuning](performance/)** - Optimize WebSocket performance
- **[Monitoring Guide](monitoring/)** - Monitor WebSocket connections
- **[API Reference](../api/)** - Explore WebSocket API details