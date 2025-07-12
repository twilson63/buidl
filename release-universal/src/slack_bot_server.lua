-- slack_bot_server.lua
-- Main Slack bot server with privacy-conscious vector database

local SlackBot = require("slack_integration")

-- Load configuration from environment or defaults
local function load_config()
    return {
        -- Slack settings
        slack_bot_token = os.getenv("SLACK_BOT_TOKEN"),
        slack_signing_secret = os.getenv("SLACK_SIGNING_SECRET"),
        slack_channel_whitelist = {}, -- Configure specific channels if needed
        
        -- Privacy settings (configurable)
        privacy_level = os.getenv("PRIVACY_LEVEL") or "high", -- high, medium, low
        use_enterprise_zdr = os.getenv("USE_ENTERPRISE_ZDR") == "true",
        
        -- Database settings
        db_path = os.getenv("DB_PATH") or "./data/slack_bot.db",
        
        -- Response settings
        response_enabled = os.getenv("RESPONSE_ENABLED") ~= "false", -- Default true
        max_context_messages = tonumber(os.getenv("MAX_CONTEXT_MESSAGES")) or 5,
        
        -- OpenRouter LLM settings
        openrouter_api_key = os.getenv("OPENROUTER_API_KEY"),
        openrouter_model = os.getenv("OPENROUTER_MODEL") or "anthropic/claude-3.5-sonnet",
        
        -- Server settings
        port = tonumber(os.getenv("PORT")) or 8080,
        webhook_path = os.getenv("WEBHOOK_PATH") or "/slack/events"
    }
end

-- Main application
local function main()
    print("=== SLACK BOT WITH PRIVACY-CONSCIOUS VECTOR DATABASE ===")
    print("")
    
    -- Load configuration
    local config = load_config()
    
    -- Display configuration (without sensitive values)
    print("Configuration:")
    print("  Privacy Level:", config.privacy_level)
    print("  Enterprise ZDR:", config.use_enterprise_zdr and "Enabled" or "Disabled")
    print("  Database Path:", config.db_path)
    print("  Response Mode:", config.response_enabled and "Enabled" or "Disabled")
    print("  Context Messages:", config.max_context_messages)
    print("  Server Port:", config.port)
    print("  Webhook Path:", config.webhook_path)
    print("")
    
    -- Validate required configuration
    if not config.slack_bot_token then
        print("WARNING: SLACK_BOT_TOKEN not set - responses will be simulated")
    end
    
    if not config.openrouter_api_key then
        print("WARNING: OPENROUTER_API_KEY not set - responses will be simulated")
    end
    
    if not config.slack_signing_secret then
        print("WARNING: SLACK_SIGNING_SECRET not set - webhook verification disabled")
    end
    
    print("")
    
    -- Create and start bot
    local bot = SlackBot.new(config)
    
    -- Display initial statistics
    local stats = bot:get_stats()
    print("Initial State:")
    print(string.format("  Vector Database: %d existing messages", stats.vector_database.total_messages))
    print(string.format("  Privacy Score: %.1f/100", stats.privacy.score))
    print(string.format("  Local Processing Rate: %.1f%%", stats.privacy.local_processing_rate * 100))
    print("")
    
    -- Setup instructions
    print("=== SETUP INSTRUCTIONS ===")
    print("")
    print("1. Slack App Configuration:")
    print("   - Create app at https://api.slack.com/apps")
    print("   - Enable Events API")
    print("   - Set Request URL: http://your-server.com" .. config.webhook_path)
    print("   - Subscribe to events: message.channels, app_mention")
    print("   - Install app to workspace")
    print("")
    
    print("2. Environment Variables:")
    if not config.slack_bot_token then
        print("   export SLACK_BOT_TOKEN=xoxb-your-bot-token")
    end
    if not config.slack_signing_secret then
        print("   export SLACK_SIGNING_SECRET=your-signing-secret")
    end
    if not config.openrouter_api_key then
        print("   export OPENROUTER_API_KEY=your-openrouter-key")
    end
    print("")
    
    print("3. Privacy Configuration:")
    print("   export PRIVACY_LEVEL=high     # high, medium, low")
    print("   export USE_ENTERPRISE_ZDR=true  # for OpenAI Enterprise")
    print("")
    
    print("4. Optional Settings:")
    print("   export RESPONSE_ENABLED=true")
    print("   export MAX_CONTEXT_MESSAGES=5")
    print("   export DB_PATH=./data/slack_bot.db")
    print("")
    
    -- Start the server
    print("=== STARTING SERVER ===")
    print("")
    
    bot:start_server()
end

-- Handle graceful shutdown
local function setup_signal_handlers()
    -- Note: Signal handling in Lua/Hype may be limited
    -- This is a placeholder for cleanup on shutdown
    print("Setting up signal handlers...")
end

-- Run the application
setup_signal_handlers()
main()