-- create_config.lua
-- Utility to create configuration template

local Config = require("config")

print("Creating configuration template...")
local success = Config.create_config_template(".env")

if success then
    print("\nConfiguration template created successfully!")
    print("Edit .env file with your actual API keys and settings before running the bot.")
    print("\nRequired settings:")
    print("- SLACK_BOT_TOKEN: Get from your Slack app configuration")
    print("- SLACK_SIGNING_SECRET: Get from your Slack app configuration")
    print("- OPENROUTER_API_KEY: Get from https://openrouter.ai/")
else
    print("Failed to create configuration template")
    os.exit(1)
end