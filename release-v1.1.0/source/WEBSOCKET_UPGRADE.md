# WebSocket Upgrade Guide

## Overview

Buidl now supports WebSocket-based Slack integration using Socket Mode, providing real-time bidirectional communication and improved performance over the HTTP Events API.

## Benefits of WebSocket Socket Mode

### Performance Improvements
- **Real-time responses**: Instant message processing without HTTP polling
- **Lower latency**: Direct WebSocket connection eliminates HTTP overhead
- **Bidirectional communication**: Bot can initiate conversations and send proactive messages
- **Connection persistence**: Maintains long-lived connection with automatic reconnection

### Deployment Simplification
- **No public URLs required**: Eliminates need for webhook endpoints
- **Simplified networking**: No reverse proxy or port forwarding needed
- **Easier development**: Test locally without ngrok or similar tools
- **Enhanced security**: Outbound-only connections reduce attack surface

## Implementation Details

### WebSocket Module (Hype v1.6.0)

The latest Hype framework includes built-in WebSocket support:

```lua
local websocket = require('websocket')

-- Connect to WebSocket server
local ws = websocket.connect("wss://example.com/socket")

-- Send messages
ws:send("Hello WebSocket!")

-- Receive messages (blocking)
local message = ws:receive()

-- Close connection
ws:close()
```

### Socket Mode Architecture

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

## Migration Guide

### 1. Update Slack App Configuration

#### Enable Socket Mode
1. Go to your Slack app settings at https://api.slack.com/apps
2. Navigate to "Socket Mode" in the sidebar
3. Enable Socket Mode
4. Generate an App-Level Token with `connections:write` scope
5. Save the token (starts with `xapp-`)

#### Get Bot User ID
1. Go to "OAuth & Permissions" in your Slack app
2. Note the Bot User ID (starts with `U`)
3. Or use the Slack API: `GET https://slack.com/api/auth.test`

### 2. Update Configuration

Add the following to your `.env` file:

```bash
# Socket Mode Configuration
SLACK_APP_TOKEN=xapp-your-app-level-token-here
BOT_USER_ID=U1234567890

# Existing configuration (still required)
SLACK_BOT_TOKEN=xoxb-your-slack-bot-token-here
OPENROUTER_API_KEY=sk-or-your-openrouter-api-key-here
```

### 3. Switch to Socket Mode Implementation

#### Option A: Use New Socket Mode Binary
```bash
# Build Socket Mode version
hype build buidl_socket_mode.lua -o buidl-socket

# Run with Socket Mode
./buidl-socket
```

#### Option B: Update Existing Implementation
Replace HTTP Events API calls with WebSocket Socket Mode integration.

### 4. Test the Migration

```bash
# Verify WebSocket support
hype build test_websocket.lua -o test_ws
./test_ws

# Test Socket Mode connection
# (requires valid SLACK_APP_TOKEN)
hype build buidl_socket_mode.lua -o buidl-socket
./buidl-socket
```

## Configuration Reference

### Required Environment Variables

```bash
# Socket Mode (WebSocket-based)
SLACK_APP_TOKEN=xapp-your-app-token-here
BOT_USER_ID=U1234567890

# Authentication (still required)
SLACK_BOT_TOKEN=xoxb-your-bot-token-here
OPENROUTER_API_KEY=sk-or-your-api-key-here
```

### Optional Settings

```bash
# Connection Management
SOCKET_PING_INTERVAL=30          # Seconds between ping messages
SOCKET_RECONNECT_ATTEMPTS=5      # Maximum reconnection attempts
SOCKET_RECONNECT_DELAY=5         # Seconds between reconnection attempts

# Performance Tuning
SOCKET_RECEIVE_TIMEOUT=1         # Seconds to wait for messages
SOCKET_SEND_TIMEOUT=5            # Seconds to wait for send completion
```

## Troubleshooting

### Common Issues

#### 1. "Module json not found"
**Solution**: Use bundled JSON implementation or ensure proper module loading.

#### 2. "WebSocket connection failed"
**Solutions**:
- Verify `SLACK_APP_TOKEN` is correct and has `connections:write` scope
- Check network connectivity and firewall settings
- Ensure Socket Mode is enabled in Slack app settings

#### 3. "Invalid App-Level Token"
**Solutions**:
- Generate new App-Level Token in Slack app settings
- Verify token starts with `xapp-`
- Check token permissions include `connections:write`

#### 4. "Bot not responding to mentions"
**Solutions**:
- Verify `BOT_USER_ID` is correct
- Check bot permissions in Slack workspace
- Ensure bot is added to channels where it should respond

### Debug Mode

Enable debug logging for WebSocket connections:

```bash
# Enable verbose WebSocket logging
export WEBSOCKET_DEBUG=1
./buidl-socket
```

### Connection Monitoring

Monitor WebSocket connection health:

```bash
# Check connection status
curl http://localhost:8080/socket-status

# View connection statistics
curl http://localhost:8080/stats | grep -i socket
```

## Performance Comparison

| Feature | HTTP Events API | Socket Mode |
|---------|----------------|-------------|
| Latency | 500-2000ms | 50-200ms |
| Connection Type | Stateless HTTP | Persistent WebSocket |
| Deployment Complexity | High (webhooks) | Low (outbound only) |
| Real-time Capability | Limited | Full |
| Resource Usage | Higher (polling) | Lower (event-driven) |
| Development Testing | Complex (ngrok) | Simple (local) |

## Security Considerations

### Socket Mode Security Benefits
- **Outbound-only connections**: Bot initiates all connections to Slack
- **No open ports**: No incoming webhook endpoints to secure
- **Token-based authentication**: App-Level tokens with specific scopes
- **Connection encryption**: All data transmitted over WSS (TLS)

### Best Practices
1. **Rotate tokens regularly**: Generate new App-Level tokens periodically
2. **Limit token scopes**: Only grant `connections:write` scope for Socket Mode
3. **Monitor connections**: Log all WebSocket events for audit trails
4. **Implement rate limiting**: Respect Slack API rate limits
5. **Secure token storage**: Use environment variables or secure vaults

## Future Enhancements

### Planned Features
- **Multi-workspace support**: Connect to multiple Slack workspaces
- **Connection pooling**: Manage multiple WebSocket connections efficiently
- **Event filtering**: Subscribe to specific event types only
- **Compression support**: Enable WebSocket compression for large messages
- **Health checks**: Built-in connection health monitoring

### Performance Optimizations
- **Message batching**: Group multiple responses for efficiency
- **Caching layer**: Cache frequently accessed data locally
- **Connection sharing**: Share connections between bot instances
- **Load balancing**: Distribute connections across multiple processes

## Support and Documentation

### Additional Resources
- [Slack Socket Mode Documentation](https://api.slack.com/apis/connections/socket)
- [Hype WebSocket Documentation](https://github.com/twilson63/hype)
- [OpenRouter API Documentation](https://openrouter.ai/docs)

### Getting Help
- **Issues**: Report problems at [GitHub Issues](https://github.com/twilson63/buidl/issues)
- **Discussions**: Join conversations in [GitHub Discussions](https://github.com/twilson63/buidl/discussions)
- **Documentation**: Check the [docs/](../docs/) directory for detailed guides

---

**Ready to upgrade?** Follow the migration guide above to switch from HTTP Events API to WebSocket Socket Mode for improved performance and simplified deployment.