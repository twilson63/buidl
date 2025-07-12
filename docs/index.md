---
layout: default
title: Home
description: "AI-powered dev bot that executes commands and builds things via Slack using vector embeddings and OpenRouter integration"
---

<div class="hero">
    <h1>Buidl</h1>
    <p class="subtitle">AI-powered dev bot that executes commands and builds things via Slack</p>
    <div class="hero-buttons">
        <a href="{{ '/guides/getting-started/' | relative_url }}" class="btn btn-primary">
            🚀 Get Started
        </a>
        <a href="https://github.com/{{ site.repository }}/releases/latest" class="btn btn-secondary">
            📦 Download v{{ site.version }}
        </a>
        <a href="{{ '/guides/websocket-setup/' | relative_url }}" class="btn btn-accent">
            ⚡ WebSocket Setup
        </a>
    </div>
</div>

## ✨ Key Features

<div class="cards">
    <div class="card">
        <div class="card-icon primary">🚀</div>
        <h3>WebSocket Support</h3>
        <p>Real-time bidirectional communication with <strong>75-90% faster response times</strong> (50-200ms vs 500-2000ms HTTP).</p>
        <a href="{{ '/guides/websocket-setup/' | relative_url }}" class="btn btn-primary">Setup WebSocket →</a>
    </div>

    <div class="card">
        <div class="card-icon secondary">🧠</div>
        <h3>AI-Powered Responses</h3>
        <p>Uses OpenRouter (Claude 3.5 Sonnet) for intelligent, context-aware conversations with your development team.</p>
        <a href="{{ '/guides/configuration/' | relative_url }}" class="btn btn-primary">Configure AI →</a>
    </div>

    <div class="card">
        <div class="card-icon accent">🔍</div>
        <h3>Vector Embeddings</h3>
        <p>Searches conversation history using semantic similarity for relevant context and intelligent responses.</p>
        <a href="{{ '/api/vector-database/' | relative_url }}" class="btn btn-primary">Learn More →</a>
    </div>

    <div class="card">
        <div class="card-icon primary">🔐</div>
        <h3>Privacy-First</h3>
        <p>Configurable privacy levels with local embedding options for maximum data protection and compliance.</p>
        <a href="{{ '/guides/privacy/' | relative_url }}" class="btn btn-primary">Privacy Guide →</a>
    </div>

    <div class="card">
        <div class="card-icon secondary">⚡</div>
        <h3>High Performance</h3>
        <p>LSH indexing for sub-linear search performance and efficient message processing at scale.</p>
        <a href="{{ '/guides/performance/' | relative_url }}" class="btn btn-primary">Performance →</a>
    </div>

    <div class="card">
        <div class="card-icon accent">🔧</div>
        <h3>Easy Deployment</h3>
        <p>No public webhook URLs needed with Socket Mode - simplified networking and enhanced security.</p>
        <a href="{{ '/guides/deployment/' | relative_url }}" class="btn btn-primary">Deploy →</a>
    </div>
</div>

## 🚀 Quick Start

### macOS (Pre-built Binary)

```bash
# Download and install
curl -L https://github.com/{{ site.repository }}/releases/latest/download/buidl-v{{ site.version }}-macos-arm64.tar.gz -o buidl.tar.gz
tar -xzf buidl.tar.gz
cd macos-arm64
./install.sh

# Configure
buidl-config

# Start bot
buidl
```

### Any Platform (Source)

```bash
# Download source
curl -L https://github.com/{{ site.repository }}/releases/latest/download/buidl-v{{ site.version }}-source.tar.gz -o buidl-source.tar.gz
tar -xzf buidl-source.tar.gz
cd source

# Build (requires Hype framework)
./build.sh

# Configure and run
./buidl-config
./buidl-socket
```

<div class="alert alert-info">
    <strong>💡 Pro Tip:</strong> Use WebSocket Socket Mode for the best performance! It's 75-90% faster than HTTP Events API.
</div>

## 📊 Performance Comparison

<div class="table-wrapper">

| Feature | HTTP Events API | Socket Mode | Improvement |
|---------|----------------|-------------|-------------|
| **Latency** | 500-2000ms | 50-200ms | **75-90% faster** |
| **Connection** | Stateless HTTP | Persistent WebSocket | **Real-time** |
| **Deployment** | Complex (webhooks) | Simple (outbound only) | **Simplified** |
| **Security** | Public endpoints | Outbound connections | **Enhanced** |
| **Development** | ngrok required | Local testing friendly | **Easier** |

</div>

## 🏗️ Architecture Overview

```
┌─────────────────┐    WebSocket    ┌──────────────────┐
│   Slack API     │◄─── Secure ────►│  Buidl Bot       │
│  Socket Mode    │     Connection  │  (Local/Private) │
└─────────────────┘                 └──────────────────┘
                                            │
                                            ▼
                                    ┌──────────────────┐
                                    │  Vector Database │
                                    │  AI Processing   │
                                    │  Local Storage   │
                                    └──────────────────┘
```

### Components

- **Slack Integration** - WebSocket Socket Mode or HTTP Events API
- **Vector Database** - Semantic search with privacy-conscious embeddings  
- **AI Processing** - Context-aware response generation
- **OpenRouter** - Claude 3.5 Sonnet integration for intelligent responses

## 📖 Documentation

<div class="cards">
    <div class="card">
        <div class="card-icon primary">📚</div>
        <h3>Getting Started</h3>
        <p>Complete installation guide with step-by-step instructions for all platforms.</p>
        <a href="{{ '/guides/getting-started/' | relative_url }}" class="btn btn-primary">Start Here →</a>
    </div>

    <div class="card">
        <div class="card-icon secondary">⚡</div>
        <h3>WebSocket Setup</h3>
        <p>Enable Socket Mode for real-time performance and simplified deployment.</p>
        <a href="{{ '/guides/websocket-setup/' | relative_url }}" class="btn btn-primary">Setup Guide →</a>
    </div>

    <div class="card">
        <div class="card-icon accent">⚙️</div>
        <h3>Configuration</h3>
        <p>Complete reference for all configuration options and environment variables.</p>
        <a href="{{ '/guides/configuration/' | relative_url }}" class="btn btn-primary">Configure →</a>
    </div>

    <div class="card">
        <div class="card-icon primary">🔌</div>
        <h3>API Reference</h3>
        <p>Detailed API documentation with examples for extending and integrating.</p>
        <a href="{{ '/api/overview/' | relative_url }}" class="btn btn-primary">API Docs →</a>
    </div>
</div>

## 🌟 Community & Support

- **GitHub Repository**: [{{ site.repository }}](https://github.com/{{ site.repository }})
- **Issues & Bug Reports**: [Report Issues](https://github.com/{{ site.repository }}/issues)
- **Feature Requests**: [GitHub Discussions](https://github.com/{{ site.repository }}/discussions)
- **Latest Releases**: [Download Page](https://github.com/{{ site.repository }}/releases)

---

<div class="text-center">
    <p style="font-size: 1.25rem; color: var(--text-secondary);">
        Ready to supercharge your Slack workspace with AI? 
        <a href="{{ '/guides/getting-started/' | relative_url }}" style="color: var(--primary-color); font-weight: 600;">Get started now →</a>
    </p>
</div>