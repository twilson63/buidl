-- test_websocket_methods.lua
-- Explore WebSocket module methods and usage

local websocket = require('websocket')

print("=== WebSocket Module Exploration ===")
print("Available methods:")

for key, value in pairs(websocket) do
    print("- " .. key .. " (" .. type(value) .. ")")
end

print("\n=== Testing WebSocket.connect ===")

-- Test the connect method
local connect_func = websocket.connect
if connect_func then
    print("✅ websocket.connect is available")
    print("Type: " .. type(connect_func))
    
    -- Try to see function signature by calling with wrong args
    local success, error_msg = pcall(connect_func)
    print("Call without args result: " .. tostring(error_msg))
    
    -- Try with URL
    local success2, result2 = pcall(connect_func, "wss://ws.postman-echo.com/raw")
    print("Call with URL result: " .. tostring(result2))
    
else
    print("❌ websocket.connect not available")
end

print("\n=== Testing WebSocket.newServer ===")

-- Test the newServer method
local newServer_func = websocket.newServer
if newServer_func then
    print("✅ websocket.newServer is available")
    print("Type: " .. type(newServer_func))
    
    -- Try to see function signature
    local success, error_msg = pcall(newServer_func)
    print("Call without args result: " .. tostring(error_msg))
    
else
    print("❌ websocket.newServer not available")
end

return 0