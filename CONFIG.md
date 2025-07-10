# Configuration Guide

The AI Slack Bot uses a flexible configuration system that supports multiple sources for configuration values.

## Configuration Sources

The bot loads configuration in the following order of precedence:

1. **Environment variables** (highest priority)
2. **`.env` file** (medium priority)
3. **Default values** (lowest priority)

## Getting Started

### Step 1: Create Configuration Template

```bash
hype run create_config.lua
```

This creates a `.env` file with all available configuration options and their default values.

### Step 2: Edit Configuration

Edit the `.env` file with your actual API keys and settings:

```bash
# Required: Get from your Slack app configuration
SLACK_BOT_TOKEN=xoxb-your-actual-bot-token
SLACK_SIGNING_SECRET=your-actual-signing-secret

# Required: Get from https://openrouter.ai/
OPENROUTER_API_KEY=sk-or-your-actual-api-key
```

### Step 3: Run the Bot

```bash
hype run main.lua
```

## Configuration Options

### Slack Settings

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `SLACK_BOT_TOKEN` | Your Slack bot token (starts with `xoxb-`) | - | Yes |
| `SLACK_SIGNING_SECRET` | Your Slack signing secret | - | Yes |
| `SLACK_CHANNEL_WHITELIST` | Comma-separated channel IDs to restrict bot to | All channels | No |

### OpenRouter API Settings

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `OPENROUTER_API_KEY` | Your OpenRouter API key (starts with `sk-or-`) | - | Yes (if AI enabled) |
| `OPENROUTER_MODEL` | AI model to use | `anthropic/claude-3.5-sonnet` | No |

### Database Settings

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `DB_PATH` | Path to the database file | `./data/slack_bot.db` | No |

### Privacy Settings

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `PRIVACY_LEVEL` | Privacy level: `high`, `medium`, `low` | `high` | No |
| `USE_ENTERPRISE_ZDR` | Use enterprise zero-data-retention | `false` | No |

**Privacy Levels:**
- `high`: Local-only processing, no external API calls for embeddings
- `medium`: Filtered external processing, PII detection
- `low`: Full external processing allowed

### AI Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `AI_ENABLED` | Enable AI features | `true` | No |
| `AI_RESPONSE_MAX_TOKENS` | Maximum tokens in AI responses | `800` | No |
| `AI_TEMPERATURE` | AI creativity level (0.0-2.0) | `0.7` | No |
| `AI_CONVERSATION_STYLE` | Style: `helpful`, `casual`, `professional` | `helpful` | No |
| `MAX_CONTEXT_MESSAGES` | Max context messages for AI | `8` | No |
| `CONTEXT_WINDOW_HOURS` | Context window in hours | `24` | No |
| `ENABLE_CONVERSATION_SUMMARY` | Enable conversation summaries | `true` | No |

### Action Settings

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `ENABLE_ACTIONS` | Enable action detection/execution | `true` | No |
| `ACTION_CONFIRMATION_REQUIRED` | Require confirmation for actions | `true` | No |

### Response Settings

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `AUTO_RESPOND_TO_MENTIONS` | Auto-respond to @mentions | `true` | No |
| `RESPONSE_DELAY_MS` | Delay before responding (ms) | `1000` | No |

### Server Settings

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `PORT` | HTTP server port | `8080` | No |
| `WEBHOOK_PATH` | Slack webhook path | `/slack/events` | No |

## Environment Variables

You can also set configuration using environment variables:

```bash
export SLACK_BOT_TOKEN="xoxb-your-token"
export OPENROUTER_API_KEY="sk-or-your-key"
hype run main.lua
```

Environment variables take precedence over `.env` file values.

## Configuration Validation

The bot validates configuration on startup and will display helpful error messages for:

- Missing required API keys
- Invalid privacy levels
- Invalid conversation styles
- Out-of-range numeric values
- Invalid port numbers

## Multiple Environments

You can create different configuration files for different environments:

```bash
# Development
cp .env .env.development

# Production
cp .env .env.production
```

Then load the appropriate file:
```bash
# Load development config
cp .env.development .env
hype run main.lua

# Load production config
cp .env.production .env
hype run main.lua
```

## Security Best Practices

1. **Never commit API keys to version control**
2. **Use environment variables in production**
3. **Restrict file permissions on .env files**
4. **Use separate API keys for different environments**
5. **Enable high privacy level for sensitive data**

## Troubleshooting

### Common Issues

1. **"OpenRouter API key is required"**
   - Set `OPENROUTER_API_KEY` in your `.env` file
   - Or disable AI: `AI_ENABLED=false`

2. **"Slack bot token is required"**
   - Set `SLACK_BOT_TOKEN` in your `.env` file
   - Get token from Slack app configuration

3. **"Privacy level must be one of: high, medium, low"**
   - Check `PRIVACY_LEVEL` value in `.env`
   - Valid values: `high`, `medium`, `low`

### Debug Configuration

The bot prints a configuration summary on startup showing which settings are configured. Look for:
- `***configured***` means the value is set
- `NOT SET` means the value is missing

## Advanced Configuration

### Custom Database Path

```bash
DB_PATH=/path/to/custom/database.db
```

### Channel Restrictions

```bash
# Only respond in specific channels
SLACK_CHANNEL_WHITELIST=C1234567890,C0987654321
```

### Performance Tuning

```bash
# Reduce context for faster responses
MAX_CONTEXT_MESSAGES=5
CONTEXT_WINDOW_HOURS=12

# Reduce AI response length
AI_RESPONSE_MAX_TOKENS=400
```

### High-Security Setup

```bash
PRIVACY_LEVEL=high
USE_ENTERPRISE_ZDR=true
AI_ENABLED=true
ACTION_CONFIRMATION_REQUIRED=true
```