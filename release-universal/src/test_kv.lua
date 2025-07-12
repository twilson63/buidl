-- test_kv.lua
-- Test Hype key-value store functionality

print("Testing Hype key-value store...")

-- Try to access the kv module
print("Available global modules:")
for k, v in pairs(_G) do
    if type(v) == "table" and k:match("^[a-z]") then
        print("  " .. k .. ": " .. type(v))
    end
end

-- Test if kv is available
if kv then
    print("✓ kv module found")
    print("kv module methods:")
    for k, v in pairs(kv) do
        print("  " .. k .. ": " .. type(v))
    end
    
    -- Try to open a database
    local db = kv.open("./data/test_kv.db")
    if db then
        print("✓ Database opened successfully")
        
        -- Test database methods
        print("Database methods:")
        for k, v in pairs(db) do
            print("  " .. k .. ": " .. type(v))
        end
        
        -- Try basic operations
        db:open_db("test_bucket")
        local success = db:put("test_bucket", "key1", "value1")
        print("Put operation success:", success)
        
        local value = db:get("test_bucket", "key1")
        print("Retrieved value:", value)
        
    else
        print("✗ Failed to open database")
    end
else
    print("✗ kv module not found")
    print("This might mean kv is not available in 'hype run' mode")
end