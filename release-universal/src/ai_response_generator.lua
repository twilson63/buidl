-- ai_response_generator.lua
-- Context-aware AI response generation system

local OpenRouterClient = require("openrouter_client")

local AIResponseGenerator = {}

-- Default configuration
local DEFAULT_CONFIG = {
    max_context_messages = 10,
    context_window_hours = 24,
    response_max_tokens = 800,
    temperature = 0.7,
    enable_actions = true,
    enable_memory = true,
    conversation_style = "helpful" -- helpful, casual, professional
}

function AIResponseGenerator.new(config)
    config = config or {}
    
    -- Merge with defaults
    for key, value in pairs(DEFAULT_CONFIG) do
        if config[key] == nil then
            config[key] = value
        end
    end
    
    local generator = {
        config = config,
        openrouter_client = OpenRouterClient.new({
            api_key = config.openrouter_api_key,
            default_model = config.openrouter_model or "anthropic/claude-3.5-sonnet"
        }),
        stats = {
            responses_generated = 0,
            actions_detected = 0,
            context_messages_used = 0,
            average_response_time = 0,
            total_response_time = 0
        }
    }
    
    setmetatable(generator, {__index = AIResponseGenerator})
    return generator
end

-- Generate AI response with context
function AIResponseGenerator:generate_response(user_query, context_messages, metadata)
    local start_time = os.clock()
    
    metadata = metadata or {}
    
    -- Build conversation context
    local messages = self:_build_conversation_context(user_query, context_messages, metadata)
    
    -- Generate response
    local response, error_msg = self.openrouter_client:chat_completion(messages, {
        max_tokens = self.config.response_max_tokens,
        temperature = self.config.temperature
    })
    
    local end_time = os.clock()
    local response_time = (end_time - start_time) * 1000
    
    -- Update statistics
    self.stats.responses_generated = self.stats.responses_generated + 1
    self.stats.total_response_time = self.stats.total_response_time + response_time
    self.stats.average_response_time = self.stats.total_response_time / self.stats.responses_generated
    self.stats.context_messages_used = self.stats.context_messages_used + #context_messages
    
    if response then
        local ai_response = response.choices[1].message.content
        
        -- Parse for actions if enabled
        local actions = nil
        if self.config.enable_actions then
            actions = self:_parse_actions(ai_response)
            if actions and #actions > 0 then
                self.stats.actions_detected = self.stats.actions_detected + #actions
            end
        end
        
        return {
            response = ai_response,
            actions = actions,
            model_used = response.model,
            tokens_used = response.usage.total_tokens,
            response_time_ms = response_time,
            context_messages_count = #context_messages,
            metadata = metadata
        }
    else
        return nil, error_msg
    end
end

-- Build conversation context for AI
function AIResponseGenerator:_build_conversation_context(user_query, context_messages, metadata)
    local messages = {}
    
    -- System message with bot personality and context
    local system_message = self:_create_system_message(metadata)
    table.insert(messages, system_message)
    
    -- Add context messages (conversation history)
    local context_added = 0
    for i = #context_messages, 1, -1 do -- Reverse order (newest first)
        if context_added >= self.config.max_context_messages then
            break
        end
        
        local msg = context_messages[i]
        if msg.metadata and msg.metadata.text then
            local timestamp = msg.metadata.timestamp or os.time()
            local time_ago = os.time() - timestamp
            
            -- Only include messages within time window
            if time_ago <= (self.config.context_window_hours * 3600) then
                local context_msg = OpenRouterClient.create_user_message(
                    string.format("[%s] %s: %s", 
                        self:_format_timestamp(timestamp),
                        msg.metadata.user_id or "User",
                        msg.metadata.text)
                )
                table.insert(messages, context_msg)
                context_added = context_added + 1
            end
        end
    end
    
    -- Add current user query
    local user_message = OpenRouterClient.create_user_message(user_query)
    table.insert(messages, user_message)
    
    return messages
end

-- Create system message with bot personality
function AIResponseGenerator:_create_system_message(metadata)
    local channel = metadata.channel or "general"
    local user_id = metadata.user_id or "user"
    local current_time = os.date("%Y-%m-%d %H:%M:%S")
    
    local base_personality = {
        helpful = "You are a helpful Slack bot assistant. You provide clear, concise, and actionable responses.",
        casual = "You are a friendly and casual Slack bot. You use a conversational tone and keep things light.",
        professional = "You are a professional Slack bot assistant. You maintain a formal tone and focus on productivity."
    }
    
    local personality = base_personality[self.config.conversation_style] or base_personality.helpful
    
    local system_content = string.format([[%s

Context:
- You are responding in the #%s channel
- Current time: %s
- User asking: %s
- You have access to recent conversation history shown above

Guidelines:
- Keep responses concise and relevant
- Use the conversation context to provide better answers
- If you detect actionable requests, suggest specific next steps
- Be helpful while respecting privacy and security
- Use Slack-appropriate formatting when helpful

Action Detection:
- If the user asks for specific actions (create, update, delete, search, etc.), indicate this clearly
- Format action suggestions as: "I can help with: [specific action]"
- Provide clear steps for any suggested actions]], 
        personality, channel, current_time, user_id)
    
    return OpenRouterClient.create_system_message(system_content)
end

-- Parse AI response for actionable items
function AIResponseGenerator:_parse_actions(response_text)
    if not response_text or response_text == "" then
        return {}
    end
    
    local actions = {}
    local text_lower = string.lower(response_text)
    
    -- Action patterns to detect
    local action_patterns = {
        {
            pattern = "create",
            keywords = {"create", "add", "new", "make", "generate"},
            action_type = "create"
        },
        {
            pattern = "update",
            keywords = {"update", "modify", "change", "edit", "revise"},
            action_type = "update"
        },
        {
            pattern = "delete",
            keywords = {"delete", "remove", "clear", "clean"},
            action_type = "delete"
        },
        {
            pattern = "search",
            keywords = {"search", "find", "look", "query", "check"},
            action_type = "search"
        },
        {
            pattern = "help",
            keywords = {"help", "assist", "support", "guide"},
            action_type = "help"
        },
        {
            pattern = "schedule",
            keywords = {"schedule", "plan", "calendar", "meeting", "remind"},
            action_type = "schedule"
        }
    }
    
    -- Check for action indicators
    for _, pattern in ipairs(action_patterns) do
        for _, keyword in ipairs(pattern.keywords) do
            if string.find(text_lower, keyword) then
                -- Extract context around the keyword
                local context_start = math.max(1, string.find(text_lower, keyword) - 50)
                local context_end = math.min(string.len(response_text), string.find(text_lower, keyword) + 50)
                local context = string.sub(response_text, context_start, context_end)
                
                table.insert(actions, {
                    type = pattern.action_type,
                    keyword = keyword,
                    context = context,
                    confidence = self:_calculate_action_confidence(keyword, context)
                })
                break -- Only one action per pattern
            end
        end
    end
    
    -- Remove duplicates and sort by confidence
    actions = self:_deduplicate_actions(actions)
    table.sort(actions, function(a, b) return a.confidence > b.confidence end)
    
    return actions
end

-- Calculate confidence score for detected action
function AIResponseGenerator:_calculate_action_confidence(keyword, context)
    local confidence = 0.5 -- Base confidence
    
    -- Boost confidence for certain patterns
    local high_confidence_patterns = {
        "i can help", "let me", "i'll", "i will", "would you like"
    }
    
    local context_lower = string.lower(context)
    for _, pattern in ipairs(high_confidence_patterns) do
        if string.find(context_lower, pattern) then
            confidence = confidence + 0.3
        end
    end
    
    -- Reduce confidence for uncertain language
    local uncertain_patterns = {
        "might", "maybe", "perhaps", "could", "possibly"
    }
    
    for _, pattern in ipairs(uncertain_patterns) do
        if string.find(context_lower, pattern) then
            confidence = confidence - 0.2
        end
    end
    
    return math.max(0, math.min(1, confidence))
end

-- Remove duplicate actions
function AIResponseGenerator:_deduplicate_actions(actions)
    local seen = {}
    local deduplicated = {}
    
    for _, action in ipairs(actions) do
        local key = action.type .. "_" .. action.keyword
        if not seen[key] then
            seen[key] = true
            table.insert(deduplicated, action)
        end
    end
    
    return deduplicated
end

-- Format timestamp for display
function AIResponseGenerator:_format_timestamp(timestamp)
    local time_diff = os.time() - timestamp
    
    if time_diff < 60 then
        return "just now"
    elseif time_diff < 3600 then
        return string.format("%dm ago", math.floor(time_diff / 60))
    elseif time_diff < 86400 then
        return string.format("%dh ago", math.floor(time_diff / 3600))
    else
        return os.date("%m/%d", timestamp)
    end
end

-- Get response statistics
function AIResponseGenerator:get_stats()
    local openrouter_stats = self.openrouter_client:get_stats()
    
    return {
        responses_generated = self.stats.responses_generated,
        actions_detected = self.stats.actions_detected,
        context_messages_used = self.stats.context_messages_used,
        average_response_time_ms = self.stats.average_response_time,
        average_context_per_response = self.stats.responses_generated > 0 and 
            (self.stats.context_messages_used / self.stats.responses_generated) or 0,
        openrouter_stats = openrouter_stats
    }
end

-- Test AI response generation
function AIResponseGenerator:test_response_generation()
    local test_context = {
        {
            metadata = {
                text = "We're planning to deploy the new feature next week",
                user_id = "alice",
                timestamp = os.time() - 3600,
                channel = "dev"
            }
        },
        {
            metadata = {
                text = "The database migration is complete",
                user_id = "bob", 
                timestamp = os.time() - 1800,
                channel = "dev"
            }
        }
    }
    
    local test_metadata = {
        channel = "dev",
        user_id = "charlie"
    }
    
    return self:generate_response(
        "What's the status of the deployment?",
        test_context,
        test_metadata
    )
end

-- Create conversation summary
function AIResponseGenerator:create_conversation_summary(messages, max_summary_length)
    max_summary_length = max_summary_length or 200
    
    if not messages or #messages == 0 then
        return "No messages to summarize."
    end
    
    -- Build summary request
    local summary_messages = {
        OpenRouterClient.create_system_message([[You are a helpful assistant that creates concise summaries of conversations. 
        
        Instructions:
        - Create a brief summary of the key topics and decisions
        - Focus on actionable items and important information
        - Keep the summary under ]] .. max_summary_length .. [[ characters
        - Use bullet points for clarity]]),
        
        OpenRouterClient.create_user_message("Please summarize this conversation:\n\n" .. 
            self:_format_messages_for_summary(messages))
    }
    
    local response, error_msg = self.openrouter_client:chat_completion(summary_messages, {
        max_tokens = math.floor(max_summary_length / 4), -- Rough token estimate
        temperature = 0.3 -- Lower temperature for more consistent summaries
    })
    
    if response then
        return response.choices[1].message.content
    else
        return "Summary generation failed: " .. (error_msg or "Unknown error")
    end
end

-- Format messages for summary
function AIResponseGenerator:_format_messages_for_summary(messages)
    local formatted_parts = {}
    
    for _, msg in ipairs(messages) do
        if msg.metadata and msg.metadata.text then
            local timestamp = self:_format_timestamp(msg.metadata.timestamp or os.time())
            table.insert(formatted_parts, string.format("[%s] %s: %s",
                timestamp,
                msg.metadata.user_id or "User",
                msg.metadata.text))
        end
    end
    
    return table.concat(formatted_parts, "\n")
end

return AIResponseGenerator