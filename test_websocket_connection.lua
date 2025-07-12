-- test_websocket_connection.lua
-- Test actual WebSocket connection and message handling

local websocket = require('websocket')

print("=== Testing WebSocket Connection ===")

-- Connect to a test WebSocket server
print("Connecting to wss://ws.postman-echo.com/raw...")

local ws = websocket.connect("wss://ws.postman-echo.com/raw")

if ws then
    print("✅ WebSocket connection created")
    print("WebSocket object type: " .. type(ws))
    
    -- Check available methods on the WebSocket object
    print("\nAvailable methods on WebSocket object:")
    if type(ws) == "userdata" then
        local mt = getmetatable(ws)
        if mt and mt.__index then
            for key, value in pairs(mt.__index) do
                print("- " .. key .. " (" .. type(value) .. ")")
            end
        else
            print("No metatable methods found")
        end
    elseif type(ws) == "table" then
        for key, value in pairs(ws) do
            print("- " .. key .. " (" .. type(value) .. ")")
        end
    end
    
    -- Try common WebSocket methods
    print("\nTesting common methods:")
    
    -- Test send
    if ws.send then
        print("✅ send method available")
        local success, error_msg = pcall(ws.send, ws, "Hello WebSocket!")
        if success then
            print("✅ Message sent successfully")
        else
            print("❌ Send failed: " .. tostring(error_msg))
        end
    else
        print("❌ send method not available")
    end
    
    -- Test receive/read
    if ws.receive then
        print("✅ receive method available")
    elseif ws.read then
        print("✅ read method available")
    else
        print("❌ No receive/read method found")
    end
    
    -- Test close
    if ws.close then
        print("✅ close method available")
        ws:close()
        print("✅ Connection closed")
    else
        print("❌ close method not available")
    end
    
else
    print("❌ Failed to create WebSocket connection")
end

print("\n=== Test Complete ===")
return 0