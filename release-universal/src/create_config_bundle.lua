-- create_config_bundle.lua
-- Bundled configuration creation utility

local function create_config_template()
    local template = [[# Slack Bot Configuration
# Get these values from your Slack app configuration
SLACK_BOT_TOKEN=xoxb-your-slack-bot-token-here
SLACK_SIGNING_SECRET=your-slack-signing-secret-here

# Optional: Restrict bot to specific channels (comma-separated)
# SLACK_CHANNEL_WHITELIST=C1234567890,C0987654321

# OpenRouter API Configuration
# Sign up at https://openrouter.ai/ to get your API key
OPENROUTER_API_KEY=sk-or-your-openrouter-api-key-here
OPENROUTER_MODEL=anthropic/claude-3.5-sonnet

# Database Configuration
DB_PATH=./data/slack_bot.db

# Privacy Settings (high=local-only, medium=filtered, low=full-external)
PRIVACY_LEVEL=high
USE_ENTERPRISE_ZDR=false

# AI Configuration
AI_ENABLED=true
AI_RESPONSE_MAX_TOKENS=800
AI_TEMPERATURE=0.7
AI_CONVERSATION_STYLE=helpful
MAX_CONTEXT_MESSAGES=8
CONTEXT_WINDOW_HOURS=24
ENABLE_CONVERSATION_SUMMARY=true

# Action Settings
ENABLE_ACTIONS=true
ACTION_CONFIRMATION_REQUIRED=true

# Response Settings
AUTO_RESPOND_TO_MENTIONS=true
RESPONSE_DELAY_MS=1000

# Server Settings
PORT=8080
WEBHOOK_PATH=/slack/events
]]
    
    local file = io.open(".env", "w")
    if file then
        file:write(template)
        file:close()
        print("Configuration template created at: .env")
        print("Please edit the file with your actual API keys and settings.")
        print("")
        print("Required settings:")
        print("- SLACK_BOT_TOKEN: Get from your Slack app configuration")
        print("- SLACK_SIGNING_SECRET: Get from your Slack app configuration")
        print("- OPENROUTER_API_KEY: Get from https://openrouter.ai/")
        return true
    else
        print("Failed to create configuration template")
        return false
    end
end

print("Creating configuration template...")
local success = create_config_template()

if success then
    print("\nConfiguration template created successfully!")
    print("Edit .env file with your actual API keys and settings before running the bot.")
else
    print("Failed to create configuration template")
    os.exit(1)
end