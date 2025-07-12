---
layout: guide
title: Getting Started
nav_order: 1
description: Quick start guide for setting up and running Buidl
---

# Getting Started with Buidl
{: .no_toc }

This guide will help you set up and run Buidl, the AI-powered dev bot for Slack.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Prerequisites

### System Requirements
- **Operating System**: Linux, macOS, or Windows (with WSL)
- **Memory**: 512MB RAM minimum, 1GB recommended
- **Storage**: 100MB for installation, additional for message storage
- **Network**: Internet access for OpenRouter API

### Required Accounts
- **Slack Workspace** with admin access to create apps
- **OpenRouter Account** for AI processing ([sign up](https://openrouter.ai/))

---

## Installation

### Option 1: Pre-built Binary (macOS)

For macOS users with Apple Silicon:

```bash
# Download latest release
curl -L https://github.com/twilson63/buidl/releases/latest/download/buidl-v1.1.0-macos-arm64.tar.gz -o buidl.tar.gz

# Extract and install
tar -xzf buidl.tar.gz
cd macos-arm64
sudo ./install.sh
```

### Option 2: Build from Source

For all other platforms:

```bash
# Install Hype framework first
curl -sSL https://raw.githubusercontent.com/twilson63/hype/main/install.sh | bash

# Download source code
curl -L https://github.com/twilson63/buidl/releases/latest/download/buidl-v1.1.0-source.tar.gz -o buidl-source.tar.gz
tar -xzf buidl-source.tar.gz
cd source

# Build binaries
./build.sh
```

### Verification

Test that installation was successful:

```bash
# Check version
buidl --version

# Run test suite
buidl-test
```

---

## Slack App Setup

### Create Slack App

1. Go to [Slack API Apps](https://api.slack.com/apps)
2. Click **"Create New App"** → **"From scratch"**
3. Enter app name (e.g., "Buidl Bot") and select your workspace
4. Click **"Create App"**

### Configure Bot Permissions

1. Navigate to **"OAuth & Permissions"**
2. Add these **Bot Token Scopes**:
   - `app_mentions:read` - Listen for mentions
   - `channels:history` - Read channel messages
   - `chat:write` - Send messages
   - `im:history` - Read direct messages
   - `users:read` - Get user information

3. Click **"Install to Workspace"** 
4. Copy the **Bot User OAuth Token** (starts with `xoxb-`)

### Enable Socket Mode (Recommended)

For real-time WebSocket communication:

1. Navigate to **"Socket Mode"**
2. Enable Socket Mode
3. Click **"Generate an app-level token"**
4. Add `connections:write` scope
5. Copy the **App-Level Token** (starts with `xapp-`)

### Alternative: HTTP Events API

If you prefer HTTP webhooks:

1. Navigate to **"Event Subscriptions"** 
2. Enable Events
3. Set **Request URL** to your public endpoint: `https://your-domain.com/slack/events`
4. Subscribe to **Bot Events**:
   - `app_mention` - Bot mentions
   - `message.channels` - Channel messages

---

## Configuration

### Create Configuration

```bash
# Generate configuration template
buidl-config
```

This creates a `.env` file. Edit it with your API keys:

### Socket Mode Configuration (Recommended)

```bash
# Slack Configuration
SLACK_BOT_TOKEN=xoxb-your-bot-token-here
SLACK_APP_TOKEN=xapp-your-app-token-here
BOT_USER_ID=U1234567890

# OpenRouter Configuration  
OPENROUTER_API_KEY=sk-or-your-api-key-here
OPENROUTER_MODEL=anthropic/claude-3.5-sonnet

# Privacy Settings
PRIVACY_LEVEL=high
AI_ENABLED=true
```

### HTTP Mode Configuration (Alternative)

```bash
# Slack Configuration
SLACK_BOT_TOKEN=xoxb-your-bot-token-here
SLACK_SIGNING_SECRET=your-signing-secret-here

# OpenRouter Configuration
OPENROUTER_API_KEY=sk-or-your-api-key-here

# Server Settings
PORT=8080
WEBHOOK_PATH=/slack/events
```

### Get Required Values

#### Bot User ID
```bash
# Using Slack API
curl -X GET https://slack.com/api/auth.test \
  -H "Authorization: Bearer xoxb-your-bot-token"
```

#### OpenRouter API Key
1. Sign up at [OpenRouter](https://openrouter.ai/)
2. Go to **API Keys** section
3. Create new API key (starts with `sk-or-`)

---

## Running Buidl

### Socket Mode (Recommended)

```bash
# Start with WebSocket Socket Mode
buidl

# Or explicitly
buidl-socket
```

### HTTP Mode (Alternative)

```bash
# Start with HTTP Events API
buidl-http
```

### Expected Output

```
=== BUIDL v1.1.0 (Socket Mode) ===
AI-powered dev bot with WebSocket integration

📋 Configuration loaded successfully
🔐 Privacy level: high
🤖 AI enabled: yes

🗄️ Initializing vector database...
✅ Vector database initialized

🧠 Initializing embeddings...
✅ Embeddings initialized

🤖 Initializing AI response generator...
✅ AI response generator initialized

🔌 Initializing Slack Socket Mode...
✅ Slack Socket Mode client initialized

🚀 Starting Buidl Socket Mode bot...
💬 Ready to receive messages via WebSocket!
```

---

## Testing

### Mention the Bot

In your Slack workspace:

```
@Buidl Bot hello! Can you help me with some tasks?
```

### Expected Response

The bot should respond with a helpful AI-generated message acknowledging your request.

### Debug Issues

```bash
# Check configuration
buidl-config --validate

# Run comprehensive tests
buidl-test

# Check logs
tail -f ~/.buidl/logs/buidl.log
```

---

## Next Steps

Congratulations! Buidl is now running. Here's what to explore next:

1. **[Configuration Guide](configuration/)** - Advanced configuration options
2. **[WebSocket Setup](websocket-setup/)** - Optimize for real-time performance
3. **[Deployment Guide](deployment/)** - Deploy to production environments
4. **[Privacy Guide](privacy/)** - Configure privacy and security settings

---

## Troubleshooting

### Common Issues

**Bot not responding to mentions**
- Verify bot is added to the channel
- Check `BOT_USER_ID` is correct
- Ensure bot has proper permissions

**Connection failures**
- Verify API tokens are correct
- Check network connectivity
- Ensure Socket Mode is enabled (for WebSocket mode)

**Build failures**
- Install Hype framework first
- Check system requirements
- Verify all dependencies are available

### Getting Help

- **Documentation**: Browse the full [documentation](../)
- **Issues**: Report problems on [GitHub Issues](https://github.com/twilson63/buidl/issues)
- **Discussions**: Join [GitHub Discussions](https://github.com/twilson63/buidl/discussions)