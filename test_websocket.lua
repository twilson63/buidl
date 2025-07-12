-- test_websocket.lua
-- Test WebSocket functionality in Hype framework

print("=== Testing WebSocket Module ===")

-- Test 1: Module availability
print("1. Testing WebSocket module availability...")
local websocket_available, websocket = pcall(require, 'websocket')

if websocket_available then
    print("✅ WebSocket module loaded successfully")
    print("   Type: " .. type(websocket))
    
    -- Check available methods
    if type(websocket) == "table" then
        print("   Available methods:")
        for key, value in pairs(websocket) do
            print("   - " .. key .. " (" .. type(value) .. ")")
        end
    end
else
    print("❌ WebSocket module not available: " .. tostring(websocket))
    return 1
end

-- Test 2: Client creation (without actually connecting)
print("\n2. Testing WebSocket client creation...")
local client_available = websocket.client ~= nil

if client_available then
    print("✅ WebSocket client method available")
    print("   Type: " .. type(websocket.client))
else
    print("❌ WebSocket client method not available")
end

-- Test 3: Server creation (without actually starting)
print("\n3. Testing WebSocket server creation...")
local server_available = websocket.server ~= nil

if server_available then
    print("✅ WebSocket server method available")
    print("   Type: " .. type(websocket.server))
else
    print("❌ WebSocket server method not available")
end

-- Test 4: Test connection to a public WebSocket echo server
print("\n4. Testing WebSocket connection...")
print("   Attempting to connect to wss://ws.postman-echo.com/raw...")

local connection_success = false
local error_message = nil

local success, error_or_ws = pcall(function()
    return websocket.client("wss://ws.postman-echo.com/raw", {
        on_open = function()
            print("   ✅ WebSocket connection opened")
            connection_success = true
        end,
        on_message = function(message)
            print("   📨 Received message: " .. tostring(message))
        end,
        on_close = function(code, reason)
            print("   🔌 WebSocket connection closed: " .. tostring(reason) .. " (code: " .. tostring(code) .. ")")
        end,
        on_error = function(error)
            print("   ❌ WebSocket error: " .. tostring(error))
            error_message = tostring(error)
        end
    })
end)

if success and error_or_ws then
    print("   ✅ WebSocket client created successfully")
    print("   Type: " .. type(error_or_ws))
    
    -- Try to send a test message
    if error_or_ws.send then
        local send_success, send_error = pcall(function()
            error_or_ws:send("Hello WebSocket!")
        end)
        
        if send_success then
            print("   ✅ Test message sent")
        else
            print("   ❌ Failed to send test message: " .. tostring(send_error))
        end
    end
    
    -- Clean up
    if error_or_ws.close then
        error_or_ws:close()
    end
else
    print("   ❌ Failed to create WebSocket client: " .. tostring(error_or_ws))
end

-- Summary
print("\n=== WebSocket Test Summary ===")
if websocket_available then
    print("✅ WebSocket module is available in Hype v1.6.0")
    print("✅ Ready to implement Socket Mode for Slack integration")
    
    if client_available and server_available then
        print("✅ Both client and server functionality available")
    else
        print("⚠️ Limited WebSocket functionality (missing client or server)")
    end
else
    print("❌ WebSocket module not available")
    print("   Consider updating Hype framework or checking documentation")
end

print("\nNext steps:")
print("1. Update Slack app to enable Socket Mode")
print("2. Get App-Level Token (xapp-) for Socket Mode")
print("3. Test with real Slack WebSocket connection")
print("4. Replace HTTP Events API with Socket Mode")

return websocket_available and 0 or 1