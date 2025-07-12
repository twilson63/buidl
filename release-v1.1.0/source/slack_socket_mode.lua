-- slack_socket_mode.lua
-- WebSocket-based Slack integration using Socket Mode

local websocket = require('websocket')
local http = require('http')
local json = require('json')

local SlackSocketMode = {}
SlackSocketMode.__index = SlackSocketMode

function SlackSocketMode.new(config)
    local self = setmetatable({}, SlackSocketMode)
    self.config = config
    self.ws = nil
    self.running = false
    self.reconnect_attempts = 0
    self.max_reconnect_attempts = 5
    self.ping_interval = 30 -- seconds
    self.last_ping = 0
    
    return self
end

-- Get Socket Mode URL from Slack API
function SlackSocketMode:get_socket_url()
    local response = http.post("https://slack.com/api/apps.connections.open", {
        headers = {
            ["Authorization"] = "Bearer " .. self.config.SLACK_APP_TOKEN,
            ["Content-Type"] = "application/x-www-form-urlencoded"
        }
    })
    
    if response.status == 200 then
        local data = json.decode(response.body)
        if data.ok then
            return data.url
        else
            error("Failed to get Socket Mode URL: " .. data.error)
        end
    else
        error("HTTP error getting Socket Mode URL: " .. response.status)
    end
end

-- Connect to Slack via WebSocket
function SlackSocketMode:connect()
    local socket_url = self:get_socket_url()
    print("Connecting to Slack Socket Mode: " .. socket_url)
    
    -- Use websocket.connect() method from Hype
    local success, ws_or_error = pcall(websocket.connect, socket_url)
    
    if success and ws_or_error then
        self.ws = ws_or_error
        self.running = true
        self.reconnect_attempts = 0
        print("✅ WebSocket connection established")
        return true
    else
        print("❌ Failed to connect: " .. tostring(ws_or_error))
        return false
    end
end

-- Handle WebSocket connection opened
function SlackSocketMode:on_open()
    print("✅ Connected to Slack Socket Mode")
    self.last_ping = os.time()
end

-- Handle incoming WebSocket messages
function SlackSocketMode:on_message(message)
    local data = json.decode(message)
    
    if data.type == "hello" then
        print("📞 Received hello from Slack")
        
    elseif data.type == "events_api" then
        -- Handle Slack events
        self:handle_event(data)
        
        -- Acknowledge the event
        self:send_ack(data.envelope_id)
        
    elseif data.type == "disconnect" then
        print("🔌 Slack requesting disconnect: " .. (data.reason or "unknown"))
        self:disconnect()
    end
end

-- Handle Slack events (messages, mentions, etc.)
function SlackSocketMode:handle_event(data)
    local event = data.payload.event
    
    if event.type == "message" and event.text then
        print("📨 Message received: " .. event.text)
        
        -- Check if bot is mentioned
        local bot_user_id = "<@" .. self.config.BOT_USER_ID .. ">"
        if string.find(event.text, bot_user_id) then
            print("🤖 Bot mentioned, processing...")
            self:process_mention(event)
        end
        
        -- Store message in vector database
        self:store_message(event)
    end
end

-- Process bot mentions
function SlackSocketMode:process_mention(event)
    -- Remove bot mention from text
    local clean_text = event.text:gsub("<@[^>]+>", ""):gsub("^%s+", ""):gsub("%s+$", "")
    
    -- Generate AI response using existing logic
    local context = self:get_context(clean_text, event.channel)
    local ai_response = self:generate_ai_response(clean_text, context)
    
    -- Send response back to Slack
    if ai_response then
        self:send_message(event.channel, ai_response)
    end
end

-- Store message in vector database
function SlackSocketMode:store_message(event)
    if self.vector_db then
        local message_data = {
            text = event.text,
            user = event.user,
            channel = event.channel,
            timestamp = event.ts,
            thread_ts = event.thread_ts
        }
        
        self.vector_db:add_message(message_data)
    end
end

-- Get conversation context
function SlackSocketMode:get_context(query, channel)
    if self.vector_db then
        return self.vector_db:search(query, {
            limit = self.config.MAX_CONTEXT_MESSAGES or 5,
            channel = channel
        })
    end
    return {}
end

-- Generate AI response
function SlackSocketMode:generate_ai_response(message, context)
    if self.ai_generator then
        return self.ai_generator:generate_response(message, context)
    end
    return nil
end

-- Send message to Slack channel
function SlackSocketMode:send_message(channel, text)
    local payload = {
        channel = channel,
        text = text,
        as_user = true
    }
    
    local response = http.post("https://slack.com/api/chat.postMessage", {
        headers = {
            ["Authorization"] = "Bearer " .. self.config.SLACK_BOT_TOKEN,
            ["Content-Type"] = "application/json"
        },
        body = json.encode(payload)
    })
    
    if response.status == 200 then
        local data = json.decode(response.body)
        if data.ok then
            print("📤 Message sent successfully")
        else
            print("❌ Failed to send message: " .. data.error)
        end
    else
        print("❌ HTTP error sending message: " .. response.status)
    end
end

-- Send acknowledgment for received events
function SlackSocketMode:send_ack(envelope_id)
    local ack = {
        envelope_id = envelope_id
    }
    
    if self.ws then
        local success, error_msg = pcall(function()
            return self.ws:send(json.encode(ack))
        end)
        
        if not success then
            print("❌ Failed to send ACK: " .. tostring(error_msg))
        end
    end
end

-- Handle WebSocket connection closed
function SlackSocketMode:on_close(code, reason)
    print("🔌 WebSocket connection closed: " .. (reason or "unknown") .. " (code: " .. (code or "unknown") .. ")")
    self.running = false
    
    -- Attempt to reconnect
    if self.reconnect_attempts < self.max_reconnect_attempts then
        self.reconnect_attempts = self.reconnect_attempts + 1
        print("🔄 Attempting to reconnect (" .. self.reconnect_attempts .. "/" .. self.max_reconnect_attempts .. ")...")
        
        -- Wait before reconnecting
        os.execute("sleep 5")
        self:connect()
    else
        print("❌ Maximum reconnection attempts reached. Giving up.")
    end
end

-- Handle WebSocket errors
function SlackSocketMode:on_error(error)
    print("❌ WebSocket error: " .. (error or "unknown"))
end

-- Send periodic ping to keep connection alive
function SlackSocketMode:ping()
    local current_time = os.time()
    if current_time - self.last_ping >= self.ping_interval then
        if self.ws then
            local ping_message = {
                id = current_time,
                type = "ping"
            }
            
            local success, error_msg = pcall(function()
                return self.ws:send(json.encode(ping_message))
            end)
            
            if success then
                self.last_ping = current_time
            else
                print("❌ Failed to send ping: " .. tostring(error_msg))
            end
        end
    end
end

-- Main event loop
function SlackSocketMode:run()
    if not self:connect() then
        error("Failed to connect to Slack Socket Mode")
    end
    
    print("🚀 Slack Socket Mode bot started!")
    print("Press Ctrl+C to stop...")
    
    -- Main loop
    while self.running do
        -- Send periodic pings
        self:ping()
        
        -- Try to receive messages
        if self.ws then
            local success, message = pcall(function()
                return self.ws:receive()
            end)
            
            if success and message then
                self:on_message(message)
            elseif not success and message ~= "timeout" then
                print("❌ WebSocket receive error: " .. tostring(message))
                self:on_error(message)
            end
        end
        
        -- Small delay to prevent busy waiting
        os.execute("sleep 0.1")
    end
end

-- Gracefully disconnect
function SlackSocketMode:disconnect()
    print("🛑 Disconnecting from Slack...")
    self.running = false
    
    if self.ws then
        self.ws:close()
        self.ws = nil
    end
    
    print("✅ Disconnected successfully")
end

-- Set dependencies
function SlackSocketMode:set_vector_db(vector_db)
    self.vector_db = vector_db
end

function SlackSocketMode:set_ai_generator(ai_generator)
    self.ai_generator = ai_generator
end

return SlackSocketMode