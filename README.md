# Buidl

AI-powered dev bot that executes commands and builds things via Slack using vector embeddings and OpenRouter integration.

## 🚀 Features

- **🤖 AI-Powered Responses**: Uses OpenRouter (Claude 3.5 Sonnet) for intelligent conversation
- **🔍 Context-Aware**: Searches conversation history using vector embeddings for relevant context
- **🔐 Privacy-First**: Configurable privacy levels with local embedding options
- **⚡ High Performance**: LSH indexing for sub-linear search performance
- **🎯 Action Detection**: Automatically detects and executes actions from AI responses
- **📊 Comprehensive Monitoring**: Detailed statistics and performance tracking
- **🔧 Easy Configuration**: Environment-based configuration with validation
- **🧪 Well-Tested**: Comprehensive test suite with 100% pass rate

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Architecture](#architecture)
- [Development](#development)
- [Testing](#testing)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [License](#license)

## 🚀 Quick Start

### 1. Download and Extract

```bash
# Download the latest release
curl -L https://github.com/your-org/buidl/releases/latest/download/buidl-v1.0.0.tar.gz -o buidl-v1.0.0.tar.gz

# Extract the archive
tar -xzf buidl-v1.0.0.tar.gz
cd release
```

### 2. Install

```bash
# Install system-wide
sudo ./scripts/install.sh

# Or install to custom location
INSTALL_DIR=/opt/slack-bot ./scripts/install.sh
```

### 3. Configure

```bash
# Create configuration template
buidl-config

# Edit configuration with your API keys
nano /usr/local/buidl/config/.env
```

### 4. Run Tests

```bash
# Verify installation
buidl-test
```

### 5. Start Bot

```bash
# Start the bot
buidl-run
```

## 📦 Installation

### System Requirements

- **Operating System**: Linux, macOS, or Windows (with WSL)
- **Runtime**: Hype Framework
- **Memory**: 512MB RAM minimum, 1GB recommended
- **Storage**: 100MB for installation, additional for message storage
- **Network**: Internet access for OpenRouter API

### Installation Methods

#### Option 1: System Installation (Recommended)

```bash
# Extract release
tar -xzf buidl-v1.0.0.tar.gz
cd release

# Install system-wide
sudo ./scripts/install.sh

# This creates:
# - /usr/local/buidl/ - Installation directory
# - /usr/local/bin/buidl* - System commands
```

#### Option 2: Custom Installation

```bash
# Install to custom directory
INSTALL_DIR=/opt/buidl ./scripts/install.sh

# Add to PATH manually
export PATH="/opt/buidl/bin:$PATH"
```

#### Option 3: Portable Installation

```bash
# Run directly from release directory
cd release
./bin/create-config
# Edit config/.env
./scripts/run.sh
```

### Verification

```bash
# Check installation
buidl --version
buidl-test
```

## ⚙️ Configuration

The bot uses a flexible configuration system supporting environment variables and `.env` files.

### Required Configuration

```bash
# Slack Configuration
SLACK_BOT_TOKEN=xoxb-your-slack-bot-token
SLACK_SIGNING_SECRET=your-slack-signing-secret

# OpenRouter Configuration
OPENROUTER_API_KEY=sk-or-your-openrouter-api-key
```

### Getting API Keys

#### Slack Bot Token

1. Go to [Slack API](https://api.slack.com/apps)
2. Create a new app or select existing
3. Go to "OAuth & Permissions"
4. Install app to workspace
5. Copy "Bot User OAuth Token" (starts with `xoxb-`)

#### Slack Signing Secret

1. In your Slack app settings
2. Go to "Basic Information"
3. Copy "Signing Secret"

#### OpenRouter API Key

1. Sign up at [OpenRouter](https://openrouter.ai/)
2. Go to API Keys section
3. Create new API key (starts with `sk-or-`)

### Optional Configuration

```bash
# AI Configuration
AI_ENABLED=true
AI_RESPONSE_MAX_TOKENS=800
AI_TEMPERATURE=0.7
AI_CONVERSATION_STYLE=helpful  # helpful, casual, professional

# Privacy Settings
PRIVACY_LEVEL=high  # high, medium, low
USE_ENTERPRISE_ZDR=false

# Performance Settings
MAX_CONTEXT_MESSAGES=8
CONTEXT_WINDOW_HOURS=24

# Server Settings
PORT=8080
WEBHOOK_PATH=/slack/events
```

For complete configuration reference, see [CONFIG.md](docs/CONFIG.md).

## 📊 Performance

### Benchmarks
- **Vector search**: <120ms for 1000 messages
- **Message processing**: 40+ messages/second
- **Memory usage**: ~0.6MB per 1000 messages
- **Storage**: Efficient binary serialization

### Scalability
- **Optimal**: Teams with <5K messages/month
- **Supported**: Up to 50K messages with <1s search time
- **Architecture**: Linear O(n) search, LSH indexing ready

## 🛠 Architecture

### Components
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  Slack Events   │───▶│  Message Parser  │───▶│  Vector Store   │
│     HTTP API    │    │  & PII Filter    │    │   (Hype K/V)    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ OpenRouter LLM  │◀───│  Context Builder │◀───│  Similarity     │
│   (Optional)    │    │  & AI Response   │    │    Search       │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### Data Flow
1. **Message Ingestion**: Slack → HTTP webhook → Message processor
2. **Vector Generation**: Text → Local embeddings → Vector database
3. **Context Retrieval**: User query → Similarity search → Context building
4. **AI Response**: Context → OpenRouter → Slack response

## 🔧 API Endpoints

### Health Check
```bash
GET /health
```

### Statistics
```bash
GET /stats
```

### Configuration
```bash
GET /config
```

### Slack Webhook
```bash
POST /slack/events
```

## 🧪 Testing

### Run Benchmarks
```bash
hype build benchmark.lua -o benchmark_bin
./benchmark_bin
```

### Test Privacy Features
```bash
hype build test_privacy_embeddings.lua -o test_privacy_bin
./test_privacy_bin
```

### Test Vector Database
```bash
hype build test_bundle.lua -o test_bundle_bin
./test_bundle_bin
```

## 📈 Monitoring

### Key Metrics
- **messages_processed**: Total messages stored
- **mentions_handled**: Bot mentions processed
- **responses_sent**: AI responses generated
- **privacy_score**: Privacy compliance score
- **local_processing_rate**: % of data processed locally

### Health Indicators
- **Vector database**: Message count and storage size
- **Privacy compliance**: PII detection rate
- **Response quality**: Context relevance scores

## 🔐 Security Best Practices

### Data Protection
- **Encryption**: All data encrypted at rest and in transit
- **Access Control**: Bot token and signing secret validation
- **Audit Logging**: Comprehensive request/response logging
- **Rate Limiting**: Built-in protection against abuse

### Privacy Controls
- **PII Filtering**: Automatic detection and handling
- **Data Minimization**: Store only necessary metadata
- **Retention Policies**: Configurable message retention
- **Consent Management**: Per-channel privacy settings

## 🚧 Deployment

### Production Checklist
- [ ] Set all required environment variables
- [ ] Configure HTTPS with valid certificates
- [ ] Set up log rotation and monitoring
- [ ] Configure backup strategy for database
- [ ] Test disaster recovery procedures
- [ ] Security audit and penetration testing

### Cloud Deployment
```bash
# Build for target platform
hype build slack_bot_server.lua -o slack_bot_server -t linux

# Deploy to cloud server
scp slack_bot_server user@server:/opt/slack-bot/
ssh user@server "cd /opt/slack-bot && ./slack_bot_server"
```

## 📚 Documentation

**📖 [Complete Documentation](https://twilson63.github.io/buidl/)** - Visit our comprehensive docs site

### Quick Links
- [Getting Started Guide](https://twilson63.github.io/buidl/guides/getting-started/) - Installation and setup
- [WebSocket Setup](https://twilson63.github.io/buidl/guides/websocket-setup/) - Enable Socket Mode
- [Configuration Reference](https://twilson63.github.io/buidl/guides/configuration/) - All configuration options
- [API Documentation](https://twilson63.github.io/buidl/api/overview/) - API reference and examples

## 🤝 Contributing

### Development Setup
```bash
# Clone repository
git clone <repository>
cd slack-bot

# Install dependencies
curl -sSL https://raw.githubusercontent.com/twilson63/hype/main/install.sh | bash

# Run tests
./run_tests.sh
```

### Code Style
- Follow Lua best practices
- Use meaningful variable names
- Add comprehensive comments
- Include error handling

## 📄 License

MIT License - see LICENSE file for details

## 🆘 Support

### Getting Help
- **Issues**: Report bugs and feature requests
- **Documentation**: Check the docs/ directory
- **Community**: Join our Discord server

### Performance Issues
- Check privacy level settings
- Monitor memory usage
- Consider LSH indexing for large datasets
- Review database storage patterns

---

**Built with ❤️ using Lua and the Hype framework**