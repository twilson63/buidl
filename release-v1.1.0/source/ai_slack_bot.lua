-- ai_slack_bot.lua
-- AI-powered Slack bot with OpenRouter integration

local VectorDB = require("vector_db_bundle")
local PrivacyEmbeddings = require("privacy_conscious_embeddings")
local AIResponseGenerator = require("ai_response_generator")
local Config = require("config")

local AISlackBot = {}

-- Enhanced configuration with AI settings
local DEFAULT_CONFIG = {
    -- Slack settings
    slack_bot_token = nil,
    slack_signing_secret = nil,
    slack_channel_whitelist = {},
    
    -- Privacy settings
    privacy_level = "high",
    use_enterprise_zdr = false,
    
    -- Database settings
    db_path = "./data/ai_slack_bot.db",
    
    -- AI settings
    openrouter_api_key = nil,
    openrouter_model = "anthropic/claude-3.5-sonnet",
    ai_enabled = true,
    ai_response_max_tokens = 800,
    ai_temperature = 0.7,
    ai_conversation_style = "helpful", -- helpful, casual, professional
    
    -- Context settings
    max_context_messages = 8,
    context_window_hours = 24,
    enable_conversation_summary = true,
    
    -- Action settings
    enable_actions = true,
    action_confirmation_required = true,
    
    -- Response settings
    mention_keywords = {"@bot", "@assistant", "@help"},
    auto_respond_to_mentions = true,
    response_delay_ms = 1000, -- Delay before responding
    
    -- Server settings
    port = 8080,
    webhook_path = "/slack/events"
}

function AISlackBot.new(config_overrides)
    config_overrides = config_overrides or {}
    
    -- Load configuration from environment, .env file, and overrides
    local config = Config.get_config(config_overrides)
    
    -- Validate configuration
    local validation_errors = Config.validate_config(config)
    if #validation_errors > 0 then
        print("Configuration validation errors:")
        for _, error in ipairs(validation_errors) do
            print("  - " .. error)
        end
        print("Please check your configuration and try again.")
        return nil
    end
    
    local bot = {
        config = config,
        vector_db = nil,
        embeddings = nil,
        ai_generator = nil,
        conversation_memory = {}, -- Store recent conversations per channel
        stats = {
            messages_processed = 0,
            ai_responses_generated = 0,
            actions_executed = 0,
            context_retrievals = 0,
            errors = 0,
            start_time = os.time(),
            last_response_time = nil
        }
    }
    
    setmetatable(bot, {__index = AISlackBot})
    
    -- Initialize components
    bot:_init_components()
    
    return bot
end

-- Initialize all bot components
function AISlackBot:_init_components()
    print("Initializing AI Slack bot components...")
    
    -- Print configuration summary
    Config.print_config_summary(self.config)
    
    -- Initialize vector database
    self.vector_db = VectorDB.new(self.config.db_path)
    local db_stats = self.vector_db:get_stats()
    print(string.format("Vector database: %d existing messages", db_stats.count))
    
    -- Initialize privacy-conscious embeddings
    self.embeddings = PrivacyEmbeddings.new({
        privacy_level = self.config.privacy_level,
        use_enterprise_zdr = self.config.use_enterprise_zdr
    })
    
    -- Initialize AI response generator
    if self.config.ai_enabled and self.config.openrouter_api_key then
        self.ai_generator = AIResponseGenerator.new({
            openrouter_api_key = self.config.openrouter_api_key,
            openrouter_model = self.config.openrouter_model,
            max_context_messages = self.config.max_context_messages,
            context_window_hours = self.config.context_window_hours,
            response_max_tokens = self.config.ai_response_max_tokens,
            temperature = self.config.ai_temperature,
            conversation_style = self.config.ai_conversation_style,
            enable_actions = self.config.enable_actions
        })
        print("AI response generator initialized")
    else
        print("AI response generator disabled (missing API key or disabled)")
    end
    
    local privacy_report = self.embeddings:get_privacy_report()
    print(string.format("Privacy level: %s (Score: %.1f/100)", 
        self.config.privacy_level, privacy_report.statistics.privacy_compliance_score))
end

-- Enhanced webhook handler with AI capabilities
function AISlackBot:handle_webhook(req_body, headers)
    local event_data = self:_parse_json(req_body)
    if not event_data then
        return self:_error_response("Invalid JSON")
    end
    
    -- Handle URL verification
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

-- Enhanced event callback handler
function AISlackBot:_handle_event_callback(event_data)
    local event = event_data.event
    if not event then
        return self:_error_response("No event data")
    end
    
    -- Handle message events
    if event.type == "message" then
        if event.bot_id or event.subtype then
            return self:_success_response("Skipped bot/system message")
        end
        
        self:_process_message(event)
    end
    
    -- Handle app mentions with AI response
    if event.type == "app_mention" then
        self:_handle_ai_mention(event)
    end
    
    return self:_success_response("Event processed")
end

-- Enhanced message processing with conversation tracking
function AISlackBot:_process_message(message)
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
            return
        end
    end
    
    -- Generate embedding
    local embedding_result = self.embeddings:get_embedding(message.text)
    
    -- Store in vector database
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
        -- Update conversation memory
        self:_update_conversation_memory(message.channel, message_entry)
        
        print(string.format("Stored message: %s (method: %s)", 
            message_entry.id, embedding_result.method))
    else
        print("Failed to store message:", error_msg)
        self.stats.errors = self.stats.errors + 1
    end
end

-- Update conversation memory for better context
function AISlackBot:_update_conversation_memory(channel, message_entry)
    if not self.conversation_memory[channel] then
        self.conversation_memory[channel] = {}
    end
    
    -- Add message to memory
    table.insert(self.conversation_memory[channel], message_entry)
    
    -- Keep only recent messages (last 20)
    local memory = self.conversation_memory[channel]
    if #memory > 20 then
        table.remove(memory, 1) -- Remove oldest
    end
end

-- Enhanced mention handler with AI response
function AISlackBot:_handle_ai_mention(mention)
    if not self.config.auto_respond_to_mentions then
        return
    end
    
    -- Extract user query
    local user_query = self:_extract_user_query(mention.text)
    if not user_query or user_query == "" then
        return
    end
    
    -- Generate AI response
    local ai_response = self:_generate_ai_response(user_query, mention)
    
    if ai_response then
        -- Add response delay if configured
        if self.config.response_delay_ms > 0 then
            self:_sleep(self.config.response_delay_ms)
        end
        
        -- Send response
        self:_send_slack_response(mention.channel, ai_response.response, mention.thread_ts)
        
        -- Handle actions if detected
        if ai_response.actions and #ai_response.actions > 0 then
            self:_handle_detected_actions(ai_response.actions, mention)
        end
        
        -- Update statistics
        self.stats.ai_responses_generated = self.stats.ai_responses_generated + 1
        self.stats.last_response_time = os.time()
        
        print(string.format("AI response generated: %d tokens, %d actions detected", 
            ai_response.tokens_used or 0, ai_response.actions and #ai_response.actions or 0))
    else
        print("Failed to generate AI response")
        self.stats.errors = self.stats.errors + 1
    end
end

-- Generate AI response with context
function AISlackBot:_generate_ai_response(user_query, mention)
    if not self.ai_generator then
        return nil
    end
    
    self.stats.context_retrievals = self.stats.context_retrievals + 1
    
    -- Get query embedding
    local query_embedding = self.embeddings:get_embedding(user_query)
    
    -- Search for relevant context
    local context_messages = self.vector_db:search({
        vector = query_embedding.vector,
        limit = self.config.max_context_messages,
        threshold = 0.1,
        filters = {
            channel = mention.channel,
            timestamp_after = os.time() - (self.config.context_window_hours * 3600)
        }
    })
    
    -- Combine with conversation memory
    local enhanced_context = self:_combine_context_sources(context_messages, mention.channel)
    
    -- Generate response
    local response, error_msg = self.ai_generator:generate_response(
        user_query,
        enhanced_context,
        {
            channel = mention.channel,
            user_id = mention.user,
            thread_ts = mention.thread_ts
        }
    )
    
    if response then
        return response
    else
        print("AI response generation failed:", error_msg)
        return nil
    end
end

-- Combine vector search results with conversation memory
function AISlackBot:_combine_context_sources(search_results, channel)
    local combined_context = {}
    local seen_messages = {}
    
    -- Add search results
    for _, result in ipairs(search_results) do
        if not seen_messages[result.id] then
            table.insert(combined_context, result)
            seen_messages[result.id] = true
        end
    end
    
    -- Add recent conversation memory
    local memory = self.conversation_memory[channel] or {}
    for _, msg in ipairs(memory) do
        if not seen_messages[msg.id] then
            table.insert(combined_context, msg)
            seen_messages[msg.id] = true
        end
    end
    
    -- Sort by timestamp (newest first)
    table.sort(combined_context, function(a, b)
        local timestamp_a = a.metadata and a.metadata.timestamp or 0
        local timestamp_b = b.metadata and b.metadata.timestamp or 0
        return timestamp_a > timestamp_b
    end)
    
    -- Limit to max context messages
    if #combined_context > self.config.max_context_messages then
        local limited_context = {}
        for i = 1, self.config.max_context_messages do
            limited_context[i] = combined_context[i]
        end
        combined_context = limited_context
    end
    
    return combined_context
end

-- Handle detected actions from AI response
function AISlackBot:_handle_detected_actions(actions, mention)
    if not self.config.enable_actions then
        return
    end
    
    for _, action in ipairs(actions) do
        if action.confidence > 0.7 then -- Only high-confidence actions
            local action_result = self:_execute_action(action, mention)
            
            if action_result then
                self.stats.actions_executed = self.stats.actions_executed + 1
                
                -- Send action confirmation if required
                if self.config.action_confirmation_required then
                    local confirmation_msg = string.format("✅ Action completed: %s", action.type)
                    self:_send_slack_response(mention.channel, confirmation_msg, mention.thread_ts)
                end
            end
        end
    end
end

-- Execute specific action
function AISlackBot:_execute_action(action, mention)
    print(string.format("Executing action: %s (confidence: %.2f)", action.type, action.confidence))
    
    -- Action implementations (placeholder)
    if action.type == "search" then
        return self:_execute_search_action(action, mention)
    elseif action.type == "help" then
        return self:_execute_help_action(action, mention)
    elseif action.type == "create" then
        return self:_execute_create_action(action, mention)
    elseif action.type == "schedule" then
        return self:_execute_schedule_action(action, mention)
    end
    
    return false
end

-- Execute search action
function AISlackBot:_execute_search_action(action, mention)
    -- This would implement actual search functionality
    print("Search action executed")
    return true
end

-- Execute help action
function AISlackBot:_execute_help_action(action, mention)
    local help_message = [[I can help you with:
    
🔍 **Search**: Find relevant information from conversation history
📊 **Status**: Check project status and updates
📅 **Schedule**: Help with meeting coordination
💬 **Questions**: Answer questions based on team knowledge
🔧 **Actions**: Execute specific tasks when requested

Just mention me with your question or request!]]
    
    self:_send_slack_response(mention.channel, help_message, mention.thread_ts)
    return true
end

-- Execute create action
function AISlackBot:_execute_create_action(action, mention)
    print("Create action executed")
    return true
end

-- Execute schedule action
function AISlackBot:_execute_schedule_action(action, mention)
    print("Schedule action executed")
    return true
end

-- Extract user query from mention
function AISlackBot:_extract_user_query(text)
    if not text then return "" end
    
    -- Remove bot mention
    local cleaned = string.gsub(text, "<@[UW]%w+>", "")
    
    -- Remove mention keywords
    if self.config.mention_keywords then
        for _, keyword in ipairs(self.config.mention_keywords) do
            cleaned = string.gsub(cleaned, keyword, "")
        end
    end
    
    -- Trim whitespace
    cleaned = string.match(cleaned, "^%s*(.-)%s*$") or ""
    
    return cleaned
end

-- Send response to Slack
function AISlackBot:_send_slack_response(channel, response, thread_ts)
    if not self.config.slack_bot_token then
        print("Cannot send response: No Slack bot token configured")
        return false
    end
    
    -- This would be the actual Slack API call
    print(string.format("SIMULATION: Sending AI response to channel %s", channel))
    print("Response:", response)
    
    if thread_ts then
        print(string.format("In thread: %s", thread_ts))
    end
    
    return true
end

-- Generate conversation summary
function AISlackBot:create_conversation_summary(channel, hours_back)
    if not self.ai_generator then
        return "AI generator not available"
    end
    
    hours_back = hours_back or 24
    local cutoff_time = os.time() - (hours_back * 3600)
    
    -- Get messages from the time period
    local messages = self.vector_db:search({
        vector = {}, -- Empty vector for metadata-only search
        limit = 50,
        threshold = 0,
        filters = {
            channel = channel,
            timestamp_after = cutoff_time
        }
    })
    
    if #messages == 0 then
        return "No messages found in the specified time period."
    end
    
    return self.ai_generator:create_conversation_summary(messages, 500)
end

-- Enhanced statistics with AI metrics
function AISlackBot:get_stats()
    local uptime = os.time() - self.stats.start_time
    local vector_stats = self.vector_db:get_stats()
    local privacy_report = self.embeddings:get_privacy_report()
    
    local ai_stats = nil
    if self.ai_generator then
        ai_stats = self.ai_generator:get_stats()
    end
    
    return {
        uptime_seconds = uptime,
        messages_processed = self.stats.messages_processed,
        ai_responses_generated = self.stats.ai_responses_generated,
        actions_executed = self.stats.actions_executed,
        context_retrievals = self.stats.context_retrievals,
        errors = self.stats.errors,
        last_response_time = self.stats.last_response_time,
        vector_database = {
            total_messages = vector_stats.count,
            storage_mb = vector_stats.estimated_storage_mb
        },
        privacy = {
            level = self.config.privacy_level,
            score = privacy_report.statistics.privacy_compliance_score,
            local_processing_rate = privacy_report.statistics.local_processing_rate
        },
        ai_stats = ai_stats,
        conversation_memory = self:_get_memory_stats()
    }
end

-- Get conversation memory statistics
function AISlackBot:_get_memory_stats()
    local total_channels = 0
    local total_messages = 0
    
    for channel, messages in pairs(self.conversation_memory) do
        total_channels = total_channels + 1
        total_messages = total_messages + #messages
    end
    
    return {
        channels_tracked = total_channels,
        total_messages_in_memory = total_messages,
        average_messages_per_channel = total_channels > 0 and (total_messages / total_channels) or 0
    }
end

-- Sleep function
function AISlackBot:_sleep(milliseconds)
    local start_time = os.clock()
    while (os.clock() - start_time) * 1000 < milliseconds do
        -- Busy wait
    end
end

-- Simple JSON parsing (enhanced)
function AISlackBot:_parse_json(json_str)
    if not json_str or json_str == "" then
        return nil
    end
    
    -- Handle challenge response
    if string.match(json_str, '"challenge"') then
        local challenge = string.match(json_str, '"challenge"%s*:%s*"([^"]+)"')
        if challenge then
            return {
                type = "url_verification",
                challenge = challenge
            }
        end
    end
    
    -- Handle event callback
    if string.match(json_str, '"event_callback"') then
        -- Extract event type
        local event_type = string.match(json_str, '"type"%s*:%s*"([^"]+)"', string.find(json_str, '"event"'))
        
        -- Extract text
        local text = string.match(json_str, '"text"%s*:%s*"([^"]+)"')
        
        -- Extract user
        local user = string.match(json_str, '"user"%s*:%s*"([^"]+)"')
        
        -- Extract channel
        local channel = string.match(json_str, '"channel"%s*:%s*"([^"]+)"')
        
        -- Extract timestamp
        local ts = string.match(json_str, '"ts"%s*:%s*"([^"]+)"')
        
        return {
            type = "event_callback",
            event = {
                type = event_type or "message",
                text = text or "test message",
                user = user or "U1234567890",
                channel = channel or "C1234567890",
                ts = ts or tostring(os.time())
            }
        }
    end
    
    return nil
end

-- Error response
function AISlackBot:_error_response(message)
    return {
        status = 400,
        headers = {"Content-Type: application/json"},
        body = string.format('{"error": "%s"}', message)
    }
end

-- Success response
function AISlackBot:_success_response(message)
    return {
        status = 200,
        headers = {"Content-Type: application/json"},
        body = string.format('{"status": "ok", "message": "%s"}', message)
    }
end

-- Create HTTP server
function AISlackBot:start_server()
    local http = require("http")
    local server = http.newServer()
    
    -- Health check with AI status
    server:handle("/health", function(req, res)
        local stats = self:get_stats()
        res:json({
            status = "healthy",
            uptime = stats.uptime_seconds,
            ai_enabled = self.config.ai_enabled,
            stats = stats
        })
    end)
    
    -- Slack webhook
    server:handle(self.config.webhook_path, function(req, res)
        local result = self:handle_webhook(req.body, req.headers)
        res:status(result.status)
        for _, header in ipairs(result.headers or {}) do
            res:header(header)
        end
        res:send(result.body)
    end)
    
    -- AI-specific endpoints
    server:handle("/ai/stats", function(req, res)
        local stats = self:get_stats()
        res:json(stats.ai_stats or {error = "AI not enabled"})
    end)
    
    server:handle("/ai/summary", function(req, res)
        local channel = req.query.channel or "general"
        local hours = tonumber(req.query.hours) or 24
        
        local summary = self:create_conversation_summary(channel, hours)
        res:json({
            channel = channel,
            hours_back = hours,
            summary = summary
        })
    end)
    
    -- Enhanced stats endpoint
    server:handle("/stats", function(req, res)
        res:json(self:get_stats())
    end)
    
    print(string.format("AI Slack bot server starting on port %d", self.config.port))
    print(string.format("Webhook URL: http://localhost:%d%s", self.config.port, self.config.webhook_path))
    print("AI enabled:", self.config.ai_enabled)
    print("Privacy level:", self.config.privacy_level)
    
    server:listen(self.config.port)
end

return AISlackBot