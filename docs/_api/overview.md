---
layout: api
title: API Overview
nav_order: 1
description: Overview of Buidl's internal APIs and extension points
---

# API Overview
{: .no_toc }

Buidl provides several APIs for extending functionality and integrating with external services.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Core APIs

### Vector Database API

The vector database provides semantic search capabilities for message history and context retrieval.

```lua
local vector_db = VectorDB.new({
    db_path = "./data/buidl.db",
    privacy_level = "high"
})

-- Add message to database
vector_db:add_message({
    text = "How do I deploy to production?",
    user = "U1234567890",
    channel = "C1234567890",
    timestamp = "1704067200.123456"
})

-- Search for similar messages
local results = vector_db:search("deployment help", {
    limit = 5,
    channel = "C1234567890"
})
```

#### Methods

| Method | Description | Parameters |
|--------|-------------|------------|
| `new(config)` | Create new vector database | `config`: Configuration object |
| `add_message(message)` | Add message to database | `message`: Message object |
| `search(query, options)` | Search for similar messages | `query`: Search string, `options`: Search options |
| `get_stats()` | Get database statistics | None |

### AI Response Generator API

Generates context-aware responses using OpenRouter and conversation history.

```lua
local ai_generator = AIResponseGenerator.new({
    openrouter_client = openrouter,
    conversation_style = "helpful",
    max_context_messages = 8
})

-- Generate response with context
local response = ai_generator:generate_response(
    "How do I fix this error?",
    context_messages
)
```

#### Methods

| Method | Description | Parameters |
|--------|-------------|------------|
| `new(config)` | Create response generator | `config`: Configuration object |
| `generate_response(message, context)` | Generate AI response | `message`: User message, `context`: Context array |
| `detect_actions(response)` | Detect executable actions | `response`: AI response text |

### Slack Integration API

Handles Slack communication via WebSocket Socket Mode or HTTP Events API.

```lua
local slack_client = SlackSocketMode.new({
    SLACK_APP_TOKEN = config.SLACK_APP_TOKEN,
    SLACK_BOT_TOKEN = config.SLACK_BOT_TOKEN,
    BOT_USER_ID = config.BOT_USER_ID
})

-- Send message to channel
slack_client:send_message("C1234567890", "Hello from Buidl!")

-- Set up event handlers
slack_client:set_vector_db(vector_db)
slack_client:set_ai_generator(ai_generator)
```

#### Methods

| Method | Description | Parameters |
|--------|-------------|------------|
| `new(config)` | Create Slack client | `config`: Configuration object |
| `connect()` | Connect to Slack | None |
| `send_message(channel, text)` | Send message | `channel`: Channel ID, `text`: Message text |
| `run()` | Start event loop | None |
| `disconnect()` | Disconnect gracefully | None |

---

## REST API Endpoints

When running, Buidl exposes HTTP endpoints for monitoring and management.

### Health Check

```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "uptime": 3600,
  "version": "1.1.0",
  "mode": "socket"
}
```

### Statistics

```http
GET /stats
```

**Response:**
```json
{
  "uptime_seconds": 3600,
  "messages_processed": 150,
  "ai_responses_generated": 45,
  "vector_database": {
    "total_messages": 150,
    "storage_mb": 2.1
  },
  "privacy": {
    "level": "high",
    "score": 95.0
  },
  "socket": {
    "connected": true,
    "ping_ms": 45,
    "reconnects": 0
  }
}
```

### Configuration

```http
GET /config
```

**Response:**
```json
{
  "version": "1.1.0",
  "mode": "socket",
  "privacy_level": "high",
  "ai_enabled": true,
  "features": {
    "websocket": true,
    "vector_search": true,
    "actions": true
  }
}
```

### Socket Status

```http
GET /socket-status
```

**Response:**
```json
{
  "connected": true,
  "url": "wss://wss-primary.slack.com/websocket/...",
  "ping_ms": 45,
  "last_message": "2025-07-12T13:45:30Z",
  "reconnect_count": 0,
  "health": "healthy"
}
```

---

## Configuration API

### Environment Configuration

```lua
local config_module = require('config')

-- Load configuration from environment and .env file
local config = config_module.load_config()

-- Validate configuration
local is_valid, errors = config_module.validate_config(config)

-- Get default configuration
local defaults = config_module.get_defaults()
```

#### Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `load_config()` | Load configuration from all sources | Configuration object |
| `validate_config(config)` | Validate configuration | `boolean`, `errors` |
| `get_defaults()` | Get default configuration | Default configuration object |

### Configuration Schema

```lua
{
  -- Required
  SLACK_BOT_TOKEN = "string",
  OPENROUTER_API_KEY = "string",
  
  -- Socket Mode
  SLACK_APP_TOKEN = "string",
  BOT_USER_ID = "string",
  
  -- Optional
  PRIVACY_LEVEL = "high|medium|low",
  AI_ENABLED = "boolean",
  PORT = "number",
  DB_PATH = "string"
}
```

---

## Extension Points

### Custom Embeddings

Implement custom embedding providers:

```lua
local CustomEmbeddings = {}

function CustomEmbeddings.new(config)
  local self = setmetatable({}, CustomEmbeddings)
  self.config = config
  return self
end

function CustomEmbeddings:generate_embedding(text)
  -- Custom embedding logic
  return embedding_vector
end

-- Register with vector database
vector_db:set_embeddings_provider(CustomEmbeddings.new(config))
```

### Custom AI Providers

Implement alternative AI providers:

```lua
local CustomAI = {}

function CustomAI.new(config)
  local self = setmetatable({}, CustomAI)
  self.config = config
  return self
end

function CustomAI:generate_response(prompt, context)
  -- Custom AI logic
  return response_text
end

-- Use with response generator
local ai_generator = AIResponseGenerator.new({
  ai_provider = CustomAI.new(config)
})
```

### Action Handlers

Implement custom action handlers:

```lua
local CustomActions = {}

function CustomActions:handle_action(action_type, parameters)
  if action_type == "deploy" then
    -- Custom deployment logic
    return self:deploy(parameters)
  end
  
  return nil -- Not handled
end

-- Register action handler
ai_generator:register_action_handler(CustomActions.new())
```

---

## WebSocket API

### Connection Events

```lua
-- Connection opened
function on_open()
  print("WebSocket connected")
end

-- Message received
function on_message(message)
  local data = json.decode(message)
  -- Handle Slack event
end

-- Connection closed
function on_close(code, reason)
  print("WebSocket closed:", reason)
end

-- Error occurred
function on_error(error)
  print("WebSocket error:", error)
end
```

### Message Types

#### Slack Events
```json
{
  "type": "events_api",
  "envelope_id": "abc123",
  "payload": {
    "event": {
      "type": "message",
      "text": "Hello bot!",
      "user": "U1234567890",
      "channel": "C1234567890",
      "ts": "1704067200.123456"
    }
  }
}
```

#### Ping/Pong
```json
{
  "type": "ping",
  "id": 1704067200
}
```

#### Acknowledgments
```json
{
  "envelope_id": "abc123"
}
```

---

## Error Handling

### Error Types

```lua
-- Configuration errors
ConfigurationError = {
  missing_required = "Required configuration missing",
  invalid_format = "Invalid configuration format",
  validation_failed = "Configuration validation failed"
}

-- Connection errors
ConnectionError = {
  slack_auth_failed = "Slack authentication failed",
  websocket_failed = "WebSocket connection failed",
  api_request_failed = "API request failed"
}

-- Processing errors
ProcessingError = {
  embedding_failed = "Embedding generation failed",
  ai_request_failed = "AI request failed",
  database_error = "Database operation failed"
}
```

### Error Responses

```lua
-- Standard error format
{
  error = true,
  type = "configuration_error",
  message = "SLACK_BOT_TOKEN is required",
  code = "missing_required",
  timestamp = "2025-07-12T13:45:30Z"
}
```

---

## Rate Limiting

### Slack API Limits

Buidl automatically handles Slack API rate limits:

- **Message sending**: 1 message per second per channel
- **API requests**: Respects Slack's rate limit headers
- **WebSocket**: No explicit limits (reasonable usage expected)

### OpenRouter Limits

- **Requests per minute**: Varies by plan
- **Tokens per request**: Configurable via `AI_RESPONSE_MAX_TOKENS`
- **Concurrent requests**: Limited to prevent abuse

### Custom Rate Limiting

```lua
local RateLimiter = {}

function RateLimiter.new(requests_per_minute)
  local self = setmetatable({}, RateLimiter)
  self.limit = requests_per_minute
  self.requests = {}
  return self
end

function RateLimiter:check_limit(key)
  local now = os.time()
  local window_start = now - 60
  
  -- Clean old requests
  self.requests[key] = self.requests[key] or {}
  local filtered = {}
  for _, timestamp in ipairs(self.requests[key]) do
    if timestamp > window_start then
      table.insert(filtered, timestamp)
    end
  end
  self.requests[key] = filtered
  
  -- Check limit
  if #self.requests[key] >= self.limit then
    return false, "Rate limit exceeded"
  end
  
  -- Record request
  table.insert(self.requests[key], now)
  return true
end
```

---

## Next Steps

- **[WebSocket API](websocket-api/)** - Detailed WebSocket API reference
- **[Vector Database API](vector-database-api/)** - Vector database operations
- **[AI Integration API](ai-integration-api/)** - AI provider integration
- **[Extension Guide](../guides/extensions/)** - Building custom extensions