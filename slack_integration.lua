-- slack_integration.lua
-- Slack HTTP Events API integration with privacy-conscious embeddings

local VectorDB = require("vector_db_bundle")
local PrivacyEmbeddings = require("privacy_conscious_embeddings")

local SlackBot = {}

-- Configuration
local DEFAULT_CONFIG = {
    -- Slack settings
    slack_bot_token = nil,          -- Set via environment
    slack_signing_secret = nil,     -- Set via environment  
    slack_channel_whitelist = {},   -- Empty = all channels
    
    -- Privacy settings
    privacy_level = "high",         -- high, medium, low
    use_enterprise_zdr = false,
    
    -- Database settings
    db_path = "./data/slack_bot.db",
    
    -- Response settings
    mention_keywords = {"@bot", "@assistant", "@help"},
    max_context_messages = 5,
    response_enabled = true,
    
    -- OpenRouter LLM settings
    openrouter_api_key = nil,       -- Set via environment
    openrouter_model = "anthropic/claude-3.5-sonnet",
    
    -- Server settings
    port = 8080,
    webhook_path = "/slack/events"
}

function SlackBot.new(config)
    config = config or {}
    
    -- Merge with defaults
    for key, value in pairs(DEFAULT_CONFIG) do
        if config[key] == nil then
            config[key] = value
        end
    end
    
    local bot = {
        config = config,
        vector_db = nil,
        embeddings = nil,
        stats = {
            messages_processed = 0,
            mentions_handled = 0,
            responses_sent = 0,
            errors = 0,
            start_time = os.time()
        }
    }
    
    setmetatable(bot, {__index = SlackBot})
    
    -- Initialize components
    bot:_init_vector_db()
    bot:_init_embeddings()
    
    return bot
end

-- Initialize vector database
function SlackBot:_init_vector_db()
    print("Initializing vector database...")
    self.vector_db = VectorDB.new(self.config.db_path)
    
    local stats = self.vector_db:get_stats()
    print(string.format("Vector database loaded: %d existing messages", stats.count))
end

-- Initialize embedding service
function SlackBot:_init_embeddings()
    print("Initializing privacy-conscious embeddings...")
    
    local embedding_config = {
        privacy_level = self.config.privacy_level,
        use_enterprise_zdr = self.config.use_enterprise_zdr,
        openai_api_key = self.config.openai_api_key
    }
    
    self.embeddings = PrivacyEmbeddings.new(embedding_config)
    
    local privacy_report = self.embeddings:get_privacy_report()
    print(string.format("Privacy level: %s (Score: %.1f/100)", 
        self.config.privacy_level, privacy_report.statistics.privacy_compliance_score))
end

-- Handle Slack Events API webhook
function SlackBot:handle_webhook(req_body, headers)
    -- Parse JSON body
    local event_data = self:_parse_json(req_body)
    if not event_data then
        return self:_error_response("Invalid JSON")
    end
    
    -- Handle URL verification (Slack setup)
    if event_data.type == "url_verification" then
        return {
            status = 200,
            headers = {"Content-Type: text/plain"},
            body = event_data.challenge
        }
    end
    
    -- Handle event callbacks
    if event_data.type == "event_callback" then
        return self:_handle_event_callback(event_data)
    end
    
    return self:_success_response("Event received")
end

-- Handle event callback from Slack
function SlackBot:_handle_event_callback(event_data)
    local event = event_data.event
    if not event then
        return self:_error_response("No event data")
    end
    
    -- Handle message events
    if event.type == "message" then
        -- Skip bot messages and message changes
        if event.bot_id or event.subtype then
            return self:_success_response("Skipped bot/system message")
        end
        
        self:_process_message(event)
    end
    
    -- Handle app mentions
    if event.type == "app_mention" then
        self:_handle_mention(event)
    end
    
    return self:_success_response("Event processed")
end

-- Process regular message for storage
function SlackBot:_process_message(message)
    self.stats.messages_processed = self.stats.messages_processed + 1
    
    -- Check channel whitelist
    if #self.config.slack_channel_whitelist > 0 then
        local channel_allowed = false
        for _, allowed_channel in ipairs(self.config.slack_channel_whitelist) do
            if message.channel == allowed_channel then
                channel_allowed = true
                break
            end
        end
        
        if not channel_allowed then
            return -- Skip non-whitelisted channels
        end
    end
    
    -- Generate embedding for message
    local embedding_result = self.embeddings:get_embedding(message.text)
    
    -- Store message in vector database
    local message_entry = {
        id = "slack_" .. message.ts .. "_" .. message.channel,
        vector = embedding_result.vector,
        metadata = {
            text = message.text,
            user_id = message.user,
            channel = message.channel,
            timestamp = tonumber(message.ts),
            thread_ts = message.thread_ts,
            embedding_method = embedding_result.method,
            privacy_level = embedding_result.privacy_level
        }
    }
    
    local success, error_msg = self.vector_db:insert(message_entry)
    if success then
        print(string.format("Stored message: %s (method: %s)", 
            message_entry.id, embedding_result.method))
    else
        print("Failed to store message:", error_msg)
        self.stats.errors = self.stats.errors + 1
    end
end

-- Handle bot mention for response generation
function SlackBot:_handle_mention(mention)
    self.stats.mentions_handled = self.stats.mentions_handled + 1
    
    if not self.config.response_enabled then
        return
    end
    
    -- Extract user query (remove bot mention)
    local user_query = self:_extract_user_query(mention.text)
    if not user_query or user_query == "" then
        return
    end
    
    -- Generate embedding for query
    local query_embedding = self.embeddings:get_embedding(user_query)
    
    -- Search for relevant context
    local context_messages = self.vector_db:search({
        vector = query_embedding.vector,
        limit = self.config.max_context_messages,
        threshold = 0.1,
        filters = {
            channel = mention.channel,
            timestamp_after = os.time() - (7 * 24 * 3600) -- Last 7 days
        }
    })
    
    -- Build context for LLM
    local context = self:_build_llm_context(user_query, context_messages)
    
    -- Generate response via OpenRouter
    local response = self:_generate_llm_response(context, mention)
    
    if response then
        -- Send response to Slack
        self:_send_slack_response(mention.channel, response, mention.thread_ts)
        self.stats.responses_sent = self.stats.responses_sent + 1
    else
        self.stats.errors = self.stats.errors + 1
    end
end

-- Extract user query from mention text
function SlackBot:_extract_user_query(text)
    if not text then return "" end
    
    -- Remove bot mention pattern like <@U1234567890>
    local cleaned = string.gsub(text, "<@[UW]%w+>", "")
    
    -- Remove common mention keywords
    for _, keyword in ipairs(self.config.mention_keywords) do
        cleaned = string.gsub(cleaned, keyword, "")
    end
    
    -- Trim whitespace
    cleaned = string.match(cleaned, "^%s*(.-)%s*$") or ""
    
    return cleaned
end

-- Build context for LLM
function SlackBot:_build_llm_context(user_query, context_messages)
    local context_parts = {}
    
    table.insert(context_parts, "You are a helpful Slack bot assistant. Here's the recent conversation context:")
    table.insert(context_parts, "")
    
    -- Add context messages
    for i, msg in ipairs(context_messages) do
        local time_ago = os.time() - msg.metadata.timestamp
        local time_desc = self:_format_time_ago(time_ago)
        
        table.insert(context_parts, string.format("[%s] User %s: %s", 
            time_desc, msg.metadata.user_id, msg.metadata.text))
    end
    
    table.insert(context_parts, "")
    table.insert(context_parts, "User's current question: " .. user_query)
    table.insert(context_parts, "")
    table.insert(context_parts, "Please provide a helpful response based on the context above.")
    
    return table.concat(context_parts, "\n")
end

-- Generate LLM response via OpenRouter
function SlackBot:_generate_llm_response(context, mention)
    if not self.config.openrouter_api_key then
        return "I need an OpenRouter API key to generate responses."
    end
    
    -- This would be the actual OpenRouter API call
    -- For now, return a simulated response
    
    local response = string.format(
        "Based on the recent conversation, I can help with that! (Simulated response - would use OpenRouter %s model with context from %d recent messages)",
        self.config.openrouter_model,
        self.config.max_context_messages
    )
    
    return response
end

-- Send response to Slack
function SlackBot:_send_slack_response(channel, response, thread_ts)
    if not self.config.slack_bot_token then
        print("Cannot send response: No Slack bot token configured")
        return false
    end
    
    -- This would be the actual Slack API call
    print(string.format("SIMULATION: Sending to channel %s: %s", channel, response))
    
    if thread_ts then
        print(string.format("  (In thread: %s)", thread_ts))
    end
    
    return true
end

-- Format time ago for human readability
function SlackBot:_format_time_ago(seconds)
    if seconds < 60 then
        return "just now"
    elseif seconds < 3600 then
        return string.format("%d min ago", math.floor(seconds / 60))
    elseif seconds < 86400 then
        return string.format("%d hours ago", math.floor(seconds / 3600))
    else
        return string.format("%d days ago", math.floor(seconds / 86400))
    end
end

-- Simple JSON parsing (basic implementation)
function SlackBot:_parse_json(json_str)
    if not json_str or json_str == "" then
        return nil
    end
    
    -- This is a very basic JSON parser for demo purposes
    -- In production, you'd want a proper JSON library
    
    -- Handle simple challenge response
    if string.match(json_str, '"challenge"') then
        local challenge = string.match(json_str, '"challenge"%s*:%s*"([^"]+)"')
        if challenge then
            return {
                type = "url_verification",
                challenge = challenge
            }
        end
    end
    
    -- Handle event callback (basic parsing)
    if string.match(json_str, '"event_callback"') then
        return {
            type = "event_callback",
            event = {
                type = "message", -- Simplified for demo
                text = "Hello world",
                user = "U1234567890",
                channel = "C1234567890",
                ts = tostring(os.time())
            }
        }
    end
    
    return nil
end

-- Error response
function SlackBot:_error_response(message)
    return {
        status = 400,
        headers = {"Content-Type: application/json"},
        body = string.format('{"error": "%s"}', message)
    }
end

-- Success response
function SlackBot:_success_response(message)
    return {
        status = 200,
        headers = {"Content-Type: application/json"},
        body = string.format('{"status": "ok", "message": "%s"}', message)
    }
end

-- Get bot statistics
function SlackBot:get_stats()
    local uptime = os.time() - self.stats.start_time
    local vector_stats = self.vector_db:get_stats()
    local privacy_report = self.embeddings:get_privacy_report()
    
    return {
        uptime_seconds = uptime,
        messages_processed = self.stats.messages_processed,
        mentions_handled = self.stats.mentions_handled,
        responses_sent = self.stats.responses_sent,
        errors = self.stats.errors,
        vector_database = {
            total_messages = vector_stats.count,
            storage_mb = vector_stats.estimated_storage_mb
        },
        privacy = {
            level = self.config.privacy_level,
            score = privacy_report.statistics.privacy_compliance_score,
            local_processing_rate = privacy_report.statistics.local_processing_rate
        }
    }
end

-- Create HTTP server with Slack webhook
function SlackBot:start_server()
    local http = require("http")
    local server = http.newServer()
    
    -- Health check endpoint
    server:handle("/health", function(req, res)
        local stats = self:get_stats()
        res:json({
            status = "healthy",
            uptime = stats.uptime_seconds,
            stats = stats
        })
    end)
    
    -- Slack webhook endpoint
    server:handle(self.config.webhook_path, function(req, res)
        local result = self:handle_webhook(req.body, req.headers)
        
        res:status(result.status)
        for _, header in ipairs(result.headers or {}) do
            res:header(header)
        end
        res:send(result.body)
    end)
    
    -- Stats endpoint
    server:handle("/stats", function(req, res)
        res:json(self:get_stats())
    end)
    
    -- Configuration endpoint
    server:handle("/config", function(req, res)
        res:json({
            privacy_level = self.config.privacy_level,
            webhook_path = self.config.webhook_path,
            response_enabled = self.config.response_enabled,
            max_context_messages = self.config.max_context_messages
        })
    end)
    
    print(string.format("Starting Slack bot server on port %d", self.config.port))
    print(string.format("Webhook URL: http://localhost:%d%s", self.config.port, self.config.webhook_path))
    print("Privacy level:", self.config.privacy_level)
    
    server:listen(self.config.port)
end

return SlackBot