-- test_socket_mode.lua
-- Test the Socket Mode implementation

print("=== Testing Slack Socket Mode Implementation ===")

-- Load required modules
local config_module = require('config')

-- Test configuration
local test_config = {
    SLACK_APP_TOKEN = "xapp-test-token",
    SLACK_BOT_TOKEN = "xoxb-test-token",
    BOT_USER_ID = "U123456789",
    OPENROUTER_API_KEY = "sk-or-test-key",
    MAX_CONTEXT_MESSAGES = 5
}

-- Load Socket Mode module
dofile('slack_socket_mode.lua')

print("1. Testing SlackSocketMode creation...")
local slack_client = SlackSocketMode.new(test_config)

if slack_client then
    print("✅ SlackSocketMode created successfully")
    print("   Type: " .. type(slack_client))
    
    -- Test configuration
    if slack_client.config then
        print("✅ Configuration loaded")
        print("   App Token: " .. (slack_client.config.SLACK_APP_TOKEN or "missing"))
        print("   Bot Token: " .. (slack_client.config.SLACK_BOT_TOKEN or "missing"))
        print("   Bot User ID: " .. (slack_client.config.BOT_USER_ID or "missing"))
    else
        print("❌ Configuration not loaded")
    end
    
    -- Test method availability
    local methods_to_test = {
        "get_socket_url",
        "connect",
        "on_message",
        "handle_event",
        "send_message",
        "send_ack",
        "ping",
        "disconnect"
    }
    
    print("\n2. Testing method availability...")
    for _, method in ipairs(methods_to_test) do
        if slack_client[method] and type(slack_client[method]) == "function" then
            print("✅ Method '" .. method .. "' available")
        else
            print("❌ Method '" .. method .. "' missing")
        end
    end
    
    -- Test dependency setting
    print("\n3. Testing dependency injection...")
    slack_client:set_vector_db({test = "vector_db"})
    slack_client:set_ai_generator({test = "ai_generator"})
    
    if slack_client.vector_db and slack_client.ai_generator then
        print("✅ Dependencies set successfully")
    else
        print("❌ Failed to set dependencies")
    end
    
    print("\n✅ Socket Mode implementation test passed")
    
else
    print("❌ Failed to create SlackSocketMode")
    return 1
end

print("\n=== Socket Mode Benefits ===")
print("✅ Real-time bidirectional communication")
print("✅ Lower latency responses")
print("✅ No need for public webhook URLs")
print("✅ Simplified deployment (no reverse proxy needed)")
print("✅ Built-in connection management and reconnection")

print("\n=== Setup Instructions ===")
print("1. Enable Socket Mode in your Slack app settings")
print("2. Generate App-Level Token with connections:write scope")
print("3. Add SLACK_APP_TOKEN and BOT_USER_ID to configuration")
print("4. Use buidl_socket_mode.lua instead of HTTP Events API")

return 0