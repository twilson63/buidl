-- buidl_socket_mode.lua
-- Main application using WebSocket Socket Mode for real-time Slack integration

local config_module = require('config')
local SlackSocketMode = require('slack_socket_mode')

-- Load bundled modules
dofile('vector_db_bundle.lua')
dofile('privacy_conscious_embeddings.lua')
dofile('ai_response_generator.lua')
dofile('openrouter_client.lua')

local function main()
    print("=== BUIDL v1.1.0 (Socket Mode) ===")
    print("AI-powered dev bot with WebSocket integration")
    print("")
    
    -- Load configuration
    local config = config_module.load_config()
    if not config then
        print("❌ Failed to load configuration")
        print("Run 'buidl-config' to create configuration")
        return 1
    end
    
    -- Validate required Socket Mode configuration
    if not config.SLACK_APP_TOKEN then
        print("❌ SLACK_APP_TOKEN is required for Socket Mode")
        print("Add your Slack App Token to the configuration")
        return 1
    end
    
    if not config.SLACK_BOT_TOKEN then
        print("❌ SLACK_BOT_TOKEN is required")
        return 1
    end
    
    if not config.BOT_USER_ID then
        print("❌ BOT_USER_ID is required")
        print("Add your bot's user ID to the configuration")
        return 1
    end
    
    print("📋 Configuration loaded successfully")
    print("🔐 Privacy level: " .. (config.PRIVACY_LEVEL or "medium"))
    print("🤖 AI enabled: " .. (config.AI_ENABLED and "yes" or "no"))
    print("")
    
    -- Initialize vector database
    print("🗄️ Initializing vector database...")
    local vector_db = VectorDB.new({
        db_path = config.DB_PATH or "./data/buidl.db",
        privacy_level = config.PRIVACY_LEVEL or "high"
    })
    
    if not vector_db then
        print("❌ Failed to initialize vector database")
        return 1
    end
    
    print("✅ Vector database initialized")
    
    -- Initialize embeddings system
    print("🧠 Initializing embeddings...")
    local embeddings = PrivacyConsciousEmbeddings.new({
        privacy_level = config.PRIVACY_LEVEL or "high",
        use_enterprise_zdr = config.USE_ENTERPRISE_ZDR or false
    })
    
    if not embeddings then
        print("❌ Failed to initialize embeddings")
        return 1
    end
    
    print("✅ Embeddings initialized")
    
    -- Initialize AI response generator
    local ai_generator = nil
    if config.AI_ENABLED ~= false then
        print("🤖 Initializing AI response generator...")
        
        local openrouter = OpenRouterClient.new({
            api_key = config.OPENROUTER_API_KEY,
            model = config.OPENROUTER_MODEL or "anthropic/claude-3.5-sonnet",
            max_tokens = config.AI_RESPONSE_MAX_TOKENS or 800,
            temperature = config.AI_TEMPERATURE or 0.7
        })
        
        if openrouter then
            ai_generator = AIResponseGenerator.new({
                openrouter_client = openrouter,
                conversation_style = config.AI_CONVERSATION_STYLE or "helpful",
                max_context_messages = config.MAX_CONTEXT_MESSAGES or 8,
                context_window_hours = config.CONTEXT_WINDOW_HOURS or 24,
                enable_conversation_summary = config.ENABLE_CONVERSATION_SUMMARY ~= false,
                enable_actions = config.ENABLE_ACTIONS ~= false,
                action_confirmation_required = config.ACTION_CONFIRMATION_REQUIRED ~= false
            })
            
            if ai_generator then
                print("✅ AI response generator initialized")
            else
                print("⚠️ AI response generator failed to initialize")
            end
        else
            print("⚠️ OpenRouter client failed to initialize")
        end
    else
        print("🤖 AI responses disabled")
    end
    
    -- Initialize Slack Socket Mode client
    print("🔌 Initializing Slack Socket Mode...")
    local slack_client = SlackSocketMode.new({
        SLACK_APP_TOKEN = config.SLACK_APP_TOKEN,
        SLACK_BOT_TOKEN = config.SLACK_BOT_TOKEN,
        BOT_USER_ID = config.BOT_USER_ID,
        MAX_CONTEXT_MESSAGES = config.MAX_CONTEXT_MESSAGES or 8
    })
    
    if not slack_client then
        print("❌ Failed to initialize Slack Socket Mode client")
        return 1
    end
    
    -- Connect dependencies
    slack_client:set_vector_db(vector_db)
    if ai_generator then
        slack_client:set_ai_generator(ai_generator)
    end
    
    print("✅ Slack Socket Mode client initialized")
    print("")
    
    -- Set up signal handlers for graceful shutdown
    local function shutdown()
        print("🛑 Shutting down...")
        slack_client:disconnect()
        print("👋 Goodbye!")
        os.exit(0)
    end
    
    -- Handle Ctrl+C gracefully
    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)
    
    -- Start the bot
    print("🚀 Starting Buidl Socket Mode bot...")
    print("💬 Ready to receive messages via WebSocket!")
    print("📊 Statistics available at: http://localhost:" .. (config.PORT or 8080) .. "/stats")
    print("")
    
    -- Start Socket Mode connection
    local success, error_msg = pcall(function()
        slack_client:run()
    end)
    
    if not success then
        print("❌ Error running bot: " .. (error_msg or "unknown"))
        return 1
    end
    
    return 0
end

-- Run main function
if arg and arg[0] then
    local exit_code = main()
    os.exit(exit_code)
else
    -- For testing/require purposes
    return {
        main = main
    }
end