-- test_websocket_simple.lua
-- Simple WebSocket connection test

local websocket = require('websocket')

print("=== Simple WebSocket Test ===")

print("Connecting to WebSocket echo server...")
local ws = websocket.connect("wss://ws.postman-echo.com/raw")

if ws then
    print("✅ Connection established")
    print("Type: " .. type(ws))
    
    -- Test basic methods by trying them
    local methods_to_test = {"send", "receive", "read", "close", "write"}
    
    for _, method in ipairs(methods_to_test) do
        local success, result = pcall(function()
            return ws[method] ~= nil
        end)
        
        if success and result then
            print("✅ Method '" .. method .. "' is available")
        else
            print("❌ Method '" .. method .. "' not available")
        end
    end
    
    -- Try to send a message
    print("\nTesting send...")
    local send_success, send_error = pcall(function()
        if ws.send then
            return ws:send("Hello!")
        elseif ws.write then
            return ws:write("Hello!")
        else
            error("No send method found")
        end
    end)
    
    if send_success then
        print("✅ Send successful")
    else
        print("❌ Send failed: " .. tostring(send_error))
    end
    
    -- Try to receive a message
    print("\nTesting receive...")
    local recv_success, recv_result = pcall(function()
        if ws.receive then
            return ws:receive()
        elseif ws.read then
            return ws:read()
        else
            error("No receive method found")
        end
    end)
    
    if recv_success then
        print("✅ Receive successful: " .. tostring(recv_result))
    else
        print("❌ Receive failed: " .. tostring(recv_result))
    end
    
    -- Close connection
    if ws.close then
        ws:close()
        print("✅ Connection closed")
    end
    
else
    print("❌ Failed to connect")
end

return 0