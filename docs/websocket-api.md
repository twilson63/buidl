---
layout: default
title: WebSocket API
description: WebSocket API reference for real-time Slack integration
permalink: /api/websocket-api/
---

# WebSocket API Reference

The WebSocket API provides real-time bidirectional communication with Slack using Socket Mode.

## Connection Management

### Establishing Connection

```lua
local slack_client = SlackSocketMode.new({
    SLACK_APP_TOKEN = "xapp-your-token",
    SLACK_BOT_TOKEN = "xoxb-your-token", 
    BOT_USER_ID = "U1234567890"
})

-- Connect to Slack
slack_client:connect()
```

### Connection Events

The WebSocket connection handles several event types:

#### Hello Event
Sent when connection is established:
```json
{
  "type": "hello",
  "num_connections": 1,
  "debug_info": {
    "host": "wss-primary.slack.com",
    "build_number": 123,
    "approximate_connection_time": 18060
  }
}
```

#### Events API Event
Wraps Slack Events API payloads:
```json
{
  "type": "events_api",
  "envelope_id": "57d12c34-e2e2-4223-8a9e-2c803925bf02",
  "payload": {
    "token": "verification-token",
    "team_id": "T12345678",
    "api_app_id": "A12345678",
    "event": {
      "type": "message",
      "text": "Hello bot!",
      "user": "U1234567890",
      "ts": "1234567890.123456",
      "channel": "C1234567890"
    }
  }
}
```

## Message Handling

### Sending Messages

```lua
-- Send message to channel
slack_client:send_message("C1234567890", "Hello from Buidl!")

-- Send with formatting
slack_client:send_message("C1234567890", {
    text = "Deployment complete!",
    blocks = {
        {
            type = "section",
            text = {
                type = "mrkdwn",
                text = "*Status:* ✅ Success"
            }
        }
    }
})
```

### Event Acknowledgment

All events must be acknowledged:
```lua
function SlackSocketMode:send_ack(envelope_id)
    local ack = {
        envelope_id = envelope_id
    }
    self.ws:send(json.encode(ack))
end
```

## Error Handling

### Connection Errors
```lua
function SlackSocketMode:on_error(error)
    print("❌ WebSocket error: " .. error)
    
    -- Attempt reconnection
    if self.reconnect_attempts < self.max_reconnect_attempts then
        self:reconnect()
    end
end
```

### Reconnection Logic
```lua
function SlackSocketMode:reconnect()
    self.reconnect_attempts = self.reconnect_attempts + 1
    
    -- Exponential backoff
    local delay = math.min(30, 2 ^ self.reconnect_attempts)
    
    os.execute("sleep " .. delay)
    self:connect()
end
```

## Performance Optimization

### Ping/Pong Management
```lua
function SlackSocketMode:ping()
    local ping_message = {
        id = os.time(),
        type = "ping"
    }
    self.ws:send(json.encode(ping_message))
end
```

### Message Batching
For high-volume scenarios, batch messages:
```lua
local message_queue = {}

function SlackSocketMode:queue_message(channel, text)
    table.insert(message_queue, {
        channel = channel,
        text = text,
        timestamp = os.time()
    })
end

function SlackSocketMode:flush_queue()
    for _, message in ipairs(message_queue) do
        self:send_message(message.channel, message.text)
    end
    message_queue = {}
end
```

## Rate Limiting

Slack enforces rate limits on WebSocket connections:
- **1 message per second** per channel
- **Burst allowance** of 5 messages
- **Connection limit** based on team size

```lua
local RateLimiter = {
    last_send = {},
    burst_count = {},
    max_burst = 5
}

function RateLimiter:can_send(channel)
    local now = os.time()
    local last = self.last_send[channel] or 0
    
    if now - last >= 1 then
        self.last_send[channel] = now
        self.burst_count[channel] = 0
        return true
    end
    
    local burst = self.burst_count[channel] or 0
    if burst < self.max_burst then
        self.burst_count[channel] = burst + 1
        return true
    end
    
    return false
end
```

## Security Considerations

### Token Management
```lua
-- Validate token format
function validate_app_token(token)
    return token and token:match("^xapp%-")
end

-- Secure token storage
local function load_secure_token()
    local file = io.open(os.getenv("HOME") .. "/.buidl/token", "r")
    if file then
        local token = file:read("*all"):gsub("%s+", "")
        file:close()
        return token
    end
end
```

### Connection Security
- All connections use **WSS (WebSocket Secure)**
- **App-level tokens** with specific scopes
- **Connection validation** with Slack's servers
- **Automatic disconnection** on invalid tokens

## Debugging

### Enable Debug Mode
```lua
-- Set debug flag
local debug_mode = os.getenv("WEBSOCKET_DEBUG") == "1"

if debug_mode then
    function debug_log(message)
        print("[DEBUG] " .. os.date("%Y-%m-%d %H:%M:%S") .. " " .. message)
    end
end
```

### Connection Monitoring
```lua
function SlackSocketMode:get_connection_stats()
    return {
        connected = self.running,
        reconnect_count = self.reconnect_attempts,
        last_ping = self.last_ping,
        uptime = os.time() - self.start_time,
        messages_sent = self.message_count or 0
    }
end
```

## Examples

### Basic Bot Setup
```lua
local slack = SlackSocketMode.new({
    SLACK_APP_TOKEN = os.getenv("SLACK_APP_TOKEN"),
    SLACK_BOT_TOKEN = os.getenv("SLACK_BOT_TOKEN"),
    BOT_USER_ID = os.getenv("BOT_USER_ID")
})

-- Set up message handler
slack.on_message = function(event)
    if event.type == "message" and event.text then
        if string.find(event.text, "<@" .. slack.config.BOT_USER_ID .. ">") then
            slack:send_message(event.channel, "Hello! How can I help?")
        end
    end
end

-- Start connection
slack:run()
```

### Advanced Event Processing
```lua
local event_handlers = {
    message = function(event)
        -- Process message
        local response = ai_generator:generate_response(event.text)
        slack:send_message(event.channel, response)
    end,
    
    app_mention = function(event)
        -- Handle direct mentions
        local context = vector_db:search(event.text)
        local response = ai_generator:generate_response(event.text, context)
        slack:send_message(event.channel, response)
    end,
    
    file_shared = function(event)
        -- Process shared files
        slack:send_message(event.channel, "File received: " .. event.file.name)
    end
}

-- Register handlers
for event_type, handler in pairs(event_handlers) do
    slack:register_handler(event_type, handler)
end
```