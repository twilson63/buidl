-- openrouter_client.lua
-- OpenRouter API client for LLM integration

local OpenRouterClient = {}

-- Default configuration
local DEFAULT_CONFIG = {
    api_base_url = "https://openrouter.ai/api/v1",
    default_model = "anthropic/claude-3.5-sonnet",
    max_tokens = 1000,
    temperature = 0.7,
    timeout_seconds = 30,
    retry_attempts = 3,
    retry_delay = 1000 -- milliseconds
}

function OpenRouterClient.new(config)
    config = config or {}
    
    -- Merge with defaults
    for key, value in pairs(DEFAULT_CONFIG) do
        if config[key] == nil then
            config[key] = value
        end
    end
    
    local client = {
        config = config,
        api_key = config.api_key,
        stats = {
            requests_made = 0,
            successful_responses = 0,
            failed_responses = 0,
            total_tokens_used = 0,
            total_cost_usd = 0.0
        }
    }
    
    setmetatable(client, {__index = OpenRouterClient})
    return client
end

-- Make chat completion request
function OpenRouterClient:chat_completion(messages, options)
    options = options or {}
    
    if not self.api_key then
        return nil, "OpenRouter API key not configured"
    end
    
    if not messages or #messages == 0 then
        return nil, "Messages array is required"
    end
    
    -- Prepare request payload
    local payload = {
        model = options.model or self.config.default_model,
        messages = messages,
        max_tokens = options.max_tokens or self.config.max_tokens,
        temperature = options.temperature or self.config.temperature,
        stream = false -- We'll handle streaming later if needed
    }
    
    -- Add optional parameters
    if options.top_p then payload.top_p = options.top_p end
    if options.frequency_penalty then payload.frequency_penalty = options.frequency_penalty end
    if options.presence_penalty then payload.presence_penalty = options.presence_penalty end
    if options.stop then payload.stop = options.stop end
    
    -- Make HTTP request with retry logic
    local response, error_msg = self:_make_request_with_retry(payload)
    
    if response then
        self.stats.successful_responses = self.stats.successful_responses + 1
        
        -- Update usage statistics
        if response.usage then
            self.stats.total_tokens_used = self.stats.total_tokens_used + (response.usage.total_tokens or 0)
            
            -- Estimate cost (rough approximation)
            local cost_per_token = self:_estimate_cost_per_token(payload.model)
            self.stats.total_cost_usd = self.stats.total_cost_usd + 
                ((response.usage.total_tokens or 0) * cost_per_token)
        end
        
        return response
    else
        self.stats.failed_responses = self.stats.failed_responses + 1
        return nil, error_msg
    end
end

-- Make HTTP request with retry logic
function OpenRouterClient:_make_request_with_retry(payload)
    local attempts = 0
    local last_error = nil
    
    while attempts < self.config.retry_attempts do
        attempts = attempts + 1
        self.stats.requests_made = self.stats.requests_made + 1
        
        local response, error_msg = self:_make_http_request(payload)
        
        if response then
            return response, nil
        else
            last_error = error_msg
            
            -- Check if error is retryable
            if not self:_is_retryable_error(error_msg) then
                break
            end
            
            -- Wait before retry (exponential backoff)
            if attempts < self.config.retry_attempts then
                local delay = self.config.retry_delay * (2 ^ (attempts - 1))
                self:_sleep(delay)
            end
        end
    end
    
    return nil, last_error
end

-- Make actual HTTP request
function OpenRouterClient:_make_http_request(payload)
    -- For now, simulate the OpenRouter API call
    -- In production, this would use Hype's HTTP client
    
    print("SIMULATION: OpenRouter API Request")
    print("Model:", payload.model)
    print("Messages:", #payload.messages)
    print("Max Tokens:", payload.max_tokens)
    
    -- Simulate response based on last message
    local last_message = payload.messages[#payload.messages]
    local user_input = last_message.content or ""
    
    -- Generate simulated response
    local response_text = self:_generate_simulated_response(user_input, payload.model)
    
    -- Simulate API response format
    local response = {
        id = "chatcmpl-" .. tostring(os.time()),
        object = "chat.completion",
        created = os.time(),
        model = payload.model,
        choices = {
            {
                index = 0,
                message = {
                    role = "assistant",
                    content = response_text
                },
                finish_reason = "stop"
            }
        },
        usage = {
            prompt_tokens = self:_estimate_tokens(self:_messages_to_string(payload.messages)),
            completion_tokens = self:_estimate_tokens(response_text),
            total_tokens = nil -- Will be calculated
        }
    }
    
    -- Calculate total tokens
    response.usage.total_tokens = response.usage.prompt_tokens + response.usage.completion_tokens
    
    return response, nil
end

-- Generate simulated response (for testing)
function OpenRouterClient:_generate_simulated_response(user_input, model)
    local responses = {
        ["help"] = "I'm here to help! What specific question do you have?",
        ["status"] = "All systems are running normally. The last deployment was successful.",
        ["project"] = "The current project is progressing well. We're on track for the next milestone.",
        ["meeting"] = "The next team meeting is scheduled for tomorrow at 3 PM.",
        ["bug"] = "I can help you troubleshoot. Can you provide more details about the issue?",
        ["feature"] = "That's an interesting feature request. Let me check the current roadmap.",
        ["database"] = "The database is performing well. Recent optimizations have improved query speed.",
        ["deployment"] = "The deployment pipeline is ready. All tests are passing.",
        ["code"] = "I can help with code review. Please share the specific code you'd like me to look at.",
        ["documentation"] = "The documentation has been updated recently. Check the latest version."
    }
    
    local input_lower = string.lower(user_input)
    
    -- Try to match keywords
    for keyword, response in pairs(responses) do
        if string.find(input_lower, keyword) then
            return string.format("%s\n\n*(Response generated by %s)*", response, model)
        end
    end
    
    -- Default response
    return string.format([[I understand you're asking about: "%s"

Based on the conversation context, I can help you with:
- Project status and updates
- Technical questions and troubleshooting
- Team coordination and meeting information
- Code review and documentation

Could you provide more specific details about what you'd like to know?

*(Response generated by %s)*]], 
        user_input, model)
end

-- Convert messages array to string for token estimation
function OpenRouterClient:_messages_to_string(messages)
    local parts = {}
    for _, message in ipairs(messages) do
        table.insert(parts, (message.role or "user") .. ": " .. (message.content or ""))
    end
    return table.concat(parts, "\n")
end

-- Estimate token count (rough approximation)
function OpenRouterClient:_estimate_tokens(text)
    if not text or text == "" then
        return 0
    end
    
    -- Rough estimate: 1 token per 4 characters
    return math.ceil(string.len(text) / 4)
end

-- Estimate cost per token for different models
function OpenRouterClient:_estimate_cost_per_token(model)
    local cost_table = {
        ["anthropic/claude-3.5-sonnet"] = 0.000003,  -- $3 per 1M tokens
        ["openai/gpt-4o"] = 0.000005,               -- $5 per 1M tokens
        ["openai/gpt-3.5-turbo"] = 0.000001,        -- $1 per 1M tokens
        ["meta-llama/llama-2-70b-chat"] = 0.0000007, -- $0.7 per 1M tokens
        ["mistralai/mistral-7b-instruct"] = 0.0000002 -- $0.2 per 1M tokens
    }
    
    return cost_table[model] or 0.000003 -- Default to Claude pricing
end

-- Check if error is retryable
function OpenRouterClient:_is_retryable_error(error_msg)
    if not error_msg then
        return false
    end
    
    local retryable_errors = {
        "timeout",
        "connection",
        "rate limit",
        "server error",
        "503",
        "502",
        "500"
    }
    
    local error_lower = string.lower(error_msg)
    for _, retryable in ipairs(retryable_errors) do
        if string.find(error_lower, retryable) then
            return true
        end
    end
    
    return false
end

-- Sleep function (placeholder)
function OpenRouterClient:_sleep(milliseconds)
    -- In production, this would use proper sleep/delay
    local start_time = os.clock()
    while (os.clock() - start_time) * 1000 < milliseconds do
        -- Busy wait (not ideal, but works for simulation)
    end
end

-- Create simple chat message
function OpenRouterClient.create_message(role, content)
    return {
        role = role,
        content = content
    }
end

-- Create system message
function OpenRouterClient.create_system_message(content)
    return OpenRouterClient.create_message("system", content)
end

-- Create user message
function OpenRouterClient.create_user_message(content)
    return OpenRouterClient.create_message("user", content)
end

-- Create assistant message
function OpenRouterClient.create_assistant_message(content)
    return OpenRouterClient.create_message("assistant", content)
end

-- Get usage statistics
function OpenRouterClient:get_stats()
    return {
        requests_made = self.stats.requests_made,
        successful_responses = self.stats.successful_responses,
        failed_responses = self.stats.failed_responses,
        success_rate = self.stats.requests_made > 0 and 
            (self.stats.successful_responses / self.stats.requests_made) or 0,
        total_tokens_used = self.stats.total_tokens_used,
        estimated_cost_usd = self.stats.total_cost_usd,
        average_tokens_per_request = self.stats.successful_responses > 0 and 
            (self.stats.total_tokens_used / self.stats.successful_responses) or 0
    }
end

-- Reset statistics
function OpenRouterClient:reset_stats()
    self.stats = {
        requests_made = 0,
        successful_responses = 0,
        failed_responses = 0,
        total_tokens_used = 0,
        total_cost_usd = 0.0
    }
end

-- Test connection to OpenRouter
function OpenRouterClient:test_connection()
    local test_messages = {
        OpenRouterClient.create_system_message("You are a helpful assistant."),
        OpenRouterClient.create_user_message("Hello! Can you confirm this connection is working?")
    }
    
    local response, error_msg = self:chat_completion(test_messages, {
        max_tokens = 50,
        temperature = 0.5
    })
    
    if response then
        return true, "Connection successful"
    else
        return false, error_msg
    end
end

-- Get available models (placeholder)
function OpenRouterClient:get_available_models()
    return {
        "anthropic/claude-3.5-sonnet",
        "openai/gpt-4o",
        "openai/gpt-3.5-turbo",
        "meta-llama/llama-2-70b-chat",
        "mistralai/mistral-7b-instruct",
        "cohere/command-r-plus"
    }
end

return OpenRouterClient