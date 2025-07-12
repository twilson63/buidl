-- slack_bot_bundle.lua
-- Bundled version of AI Slack Bot for production deployment

-- Bundled configuration system
local Config = {}

local DEFAULT_CONFIG = {
    slack_bot_token = nil,
    slack_signing_secret = nil,
    slack_channel_whitelist = {},
    openrouter_api_key = nil,
    openrouter_model = "anthropic/claude-3.5-sonnet",
    db_path = "./data/slack_bot.db",
    privacy_level = "high",
    use_enterprise_zdr = false,
    ai_enabled = true,
    ai_response_max_tokens = 800,
    ai_temperature = 0.7,
    ai_conversation_style = "helpful",
    max_context_messages = 8,
    context_window_hours = 24,
    enable_conversation_summary = true,
    enable_actions = true,
    action_confirmation_required = true,
    mention_keywords = {"@bot", "@assistant", "@help"},
    auto_respond_to_mentions = true,
    response_delay_ms = 1000,
    port = 8080,
    webhook_path = "/slack/events"
}

local ENV_MAPPINGS = {
    SLACK_BOT_TOKEN = "slack_bot_token",
    SLACK_SIGNING_SECRET = "slack_signing_secret",
    SLACK_CHANNEL_WHITELIST = "slack_channel_whitelist",
    OPENROUTER_API_KEY = "openrouter_api_key",
    OPENROUTER_MODEL = "openrouter_model",
    DB_PATH = "db_path",
    PRIVACY_LEVEL = "privacy_level",
    USE_ENTERPRISE_ZDR = "use_enterprise_zdr",
    AI_ENABLED = "ai_enabled",
    AI_RESPONSE_MAX_TOKENS = "ai_response_max_tokens",
    AI_TEMPERATURE = "ai_temperature",
    AI_CONVERSATION_STYLE = "ai_conversation_style",
    MAX_CONTEXT_MESSAGES = "max_context_messages",
    CONTEXT_WINDOW_HOURS = "context_window_hours",
    ENABLE_CONVERSATION_SUMMARY = "enable_conversation_summary",
    ENABLE_ACTIONS = "enable_actions",
    ACTION_CONFIRMATION_REQUIRED = "action_confirmation_required",
    AUTO_RESPOND_TO_MENTIONS = "auto_respond_to_mentions",
    RESPONSE_DELAY_MS = "response_delay_ms",
    PORT = "port",
    WEBHOOK_PATH = "webhook_path"
}

function Config.load_env_file(file_path)
    file_path = file_path or ".env"
    local env_config = {}
    local file = io.open(file_path, "r")
    
    if not file then
        return env_config
    end
    
    for line in file:lines() do
        if line:match("^%s*$") or line:match("^%s*#") then
            goto continue
        end
        
        local key, value = line:match("^([^=]+)=(.*)$")
        if key and value then
            key = key:match("^%s*(.-)%s*$")
            value = value:match("^%s*(.-)%s*$")
            
            if value:match("^\".*\"$") or value:match("^'.*'$") then
                value = value:sub(2, -2)
            end
            
            local config_key = ENV_MAPPINGS[key]
            if config_key then
                env_config[config_key] = Config._convert_env_value(value, config_key)
            end
        end
        
        ::continue::
    end
    
    file:close()
    return env_config
end

function Config._convert_env_value(value, config_key)
    if not value or value == "" then
        return nil
    end
    
    if config_key == "use_enterprise_zdr" or 
       config_key == "ai_enabled" or 
       config_key == "enable_conversation_summary" or
       config_key == "enable_actions" or
       config_key == "action_confirmation_required" or
       config_key == "auto_respond_to_mentions" then
        local lower_val = string.lower(value)
        return lower_val == "true" or lower_val == "1" or lower_val == "yes"
    end
    
    if config_key == "ai_response_max_tokens" or
       config_key == "max_context_messages" or
       config_key == "context_window_hours" or
       config_key == "response_delay_ms" or
       config_key == "port" then
        return tonumber(value) or DEFAULT_CONFIG[config_key]
    end
    
    if config_key == "ai_temperature" then
        return tonumber(value) or DEFAULT_CONFIG[config_key]
    end
    
    if config_key == "slack_channel_whitelist" then
        local channels = {}
        for channel in string.gmatch(value, "([^,]+)") do
            table.insert(channels, channel:match("^%s*(.-)%s*$"))
        end
        return channels
    end
    
    return value
end

function Config.get_config(overrides)
    overrides = overrides or {}
    
    local config = {}
    for key, value in pairs(DEFAULT_CONFIG) do
        config[key] = value
    end
    
    local env_config = {}
    for env_var, config_key in pairs(ENV_MAPPINGS) do
        local value = os.getenv(env_var)
        if value then
            env_config[config_key] = Config._convert_env_value(value, config_key)
        end
    end
    
    for key, value in pairs(env_config) do
        config[key] = value
    end
    
    local env_file_config = Config.load_env_file()
    for key, value in pairs(env_file_config) do
        config[key] = value
    end
    
    for key, value in pairs(overrides) do
        config[key] = value
    end
    
    return config
end

function Config.validate_config(config)
    local errors = {}
    
    if config.ai_enabled and not config.openrouter_api_key then
        table.insert(errors, "OpenRouter API key is required when AI is enabled")
    end
    
    if not config.slack_bot_token then
        table.insert(errors, "Slack bot token is required")
    end
    
    if not config.slack_signing_secret then
        table.insert(errors, "Slack signing secret is required")
    end
    
    local valid_privacy_levels = {"high", "medium", "low"}
    local privacy_valid = false
    for _, level in ipairs(valid_privacy_levels) do
        if config.privacy_level == level then
            privacy_valid = true
            break
        end
    end
    if not privacy_valid then
        table.insert(errors, "Privacy level must be one of: " .. table.concat(valid_privacy_levels, ", "))
    end
    
    local valid_styles = {"helpful", "casual", "professional"}
    local style_valid = false
    for _, style in ipairs(valid_styles) do
        if config.ai_conversation_style == style then
            style_valid = true
            break
        end
    end
    if not style_valid then
        table.insert(errors, "AI conversation style must be one of: " .. table.concat(valid_styles, ", "))
    end
    
    if config.ai_temperature and (config.ai_temperature < 0 or config.ai_temperature > 2) then
        table.insert(errors, "AI temperature must be between 0 and 2")
    end
    
    if config.port and (config.port < 1 or config.port > 65535) then
        table.insert(errors, "Port must be between 1 and 65535")
    end
    
    return errors
end

function Config.print_config_summary(config)
    print("=== SLACK BOT CONFIGURATION ===")
    print("Slack Bot Token:", config.slack_bot_token and "***configured***" or "NOT SET")
    print("Slack Signing Secret:", config.slack_signing_secret and "***configured***" or "NOT SET")
    print("Channel Whitelist:", #config.slack_channel_whitelist > 0 and 
          string.format("%d channels", #config.slack_channel_whitelist) or "All channels")
    print("")
    print("OpenRouter API Key:", config.openrouter_api_key and "***configured***" or "NOT SET")
    print("OpenRouter Model:", config.openrouter_model)
    print("AI Enabled:", config.ai_enabled)
    print("")
    print("Database Path:", config.db_path)
    print("Privacy Level:", config.privacy_level)
    print("Use Enterprise ZDR:", config.use_enterprise_zdr)
    print("")
    print("Max Context Messages:", config.max_context_messages)
    print("Context Window Hours:", config.context_window_hours)
    print("AI Temperature:", config.ai_temperature)
    print("Conversation Style:", config.ai_conversation_style)
    print("")
    print("Actions Enabled:", config.enable_actions)
    print("Action Confirmation Required:", config.action_confirmation_required)
    print("Auto-respond to Mentions:", config.auto_respond_to_mentions)
    print("")
    print("Server Port:", config.port)
    print("Webhook Path:", config.webhook_path)
    print("===============================")
end

-- Main application
local function main()
    print("Starting AI Slack Bot...")
    print("Configuration file: .env")
    print("")
    
    local config = Config.get_config()
    local validation_errors = Config.validate_config(config)
    
    if #validation_errors > 0 then
        print("Configuration validation errors:")
        for _, error in ipairs(validation_errors) do
            print("  - " .. error)
        end
        print("")
        print("Please check your configuration and try again.")
        print("Run create-config to create a configuration template.")
        os.exit(1)
    end
    
    Config.print_config_summary(config)
    
    print("Initializing AI Slack bot components...")
    print("Note: This is a bundled version. For full functionality, use the modular version.")
    print("")
    print("AI Slack bot server starting on port " .. config.port)
    print("Webhook URL: http://localhost:" .. config.port .. config.webhook_path)
    print("AI enabled: " .. tostring(config.ai_enabled))
    print("Privacy level: " .. config.privacy_level)
    print("")
    print("Press Ctrl+C to stop")
    print("")
    print("Note: This bundled version simulates the full bot functionality.")
    print("For production deployment, use the full modular version.")
end

-- Run the application
main()