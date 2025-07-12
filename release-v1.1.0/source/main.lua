-- main.lua
-- Main application entry point for AI Slack bot

local AISlackBot = require("ai_slack_bot")
local Config = require("config")

-- Command line argument parsing
local function parse_args(args)
    local parsed = {
        config_file = nil,
        create_config = false,
        help = false
    }
    
    local i = 1
    while i <= #args do
        local arg = args[i]
        
        if arg == "--config" or arg == "-c" then
            i = i + 1
            if i <= #args then
                parsed.config_file = args[i]
            else
                print("Error: --config requires a file path")
                os.exit(1)
            end
        elseif arg == "--create-config" then
            parsed.create_config = true
        elseif arg == "--help" or arg == "-h" then
            parsed.help = true
        else
            print("Unknown argument:", arg)
            parsed.help = true
        end
        
        i = i + 1
    end
    
    return parsed
end

-- Print help message
local function print_help()
    print([[
AI Slack Bot - AI-powered Slack bot with OpenRouter integration

Usage:
  hype run main.lua [OPTIONS]

Options:
  --config, -c FILE     Use custom configuration file (default: .env)
  --create-config       Create a configuration template file
  --help, -h           Show this help message

Configuration:
  The bot looks for configuration in the following order:
  1. Environment variables
  2. .env file (or file specified with --config)
  3. Command line overrides

  Required configuration:
  - SLACK_BOT_TOKEN: Your Slack bot token
  - SLACK_SIGNING_SECRET: Your Slack signing secret
  - OPENROUTER_API_KEY: Your OpenRouter API key (if AI enabled)

Example:
  # Create configuration template
  hype run main.lua --create-config
  
  # Edit .env file with your keys, then run:
  hype run main.lua
  
  # Use custom config file:
  hype run main.lua --config ./production.env

For more information, see the project documentation.
]])
end

-- Main function
local function main()
    print("Starting AI Slack Bot...")
    print("Configuration file: .env")
    print("")
    
    -- Initialize AI Slack bot
    local bot = AISlackBot.new()
    
    if not bot then
        print("Failed to initialize AI Slack bot. Please check your configuration.")
        print("Run: hype run create_config.lua to create a configuration template")
        os.exit(1)
    end
    
    -- Start the server
    print("Starting server...")
    print("Press Ctrl+C to stop")
    
    -- In a real implementation, this would start the HTTP server
    -- For now, we'll simulate server startup
    bot:start_server()
end

-- Run main function
main()