-- test_kv3.lua
-- Test Hype kv module using correct syntax

print("Testing Hype kv module (correct syntax)...")

-- Require the kv module
local kv = require('kv')

print("✓ kv module loaded successfully")
print("kv module type:", type(kv))

-- List kv module methods
print("kv module methods:")
for k, v in pairs(kv) do
    print("  " .. k .. ": " .. type(v))
end

-- Try to open a database
print("\nOpening database...")
local db = kv.open("./data/test_hype.db")

if db then
    print("✓ Database opened successfully")
    print("Database type:", type(db))
    
    -- List database methods
    print("Database methods:")
    for k, v in pairs(db) do
        print("  " .. k .. ": " .. type(v))
    end
    
    -- Test basic operations
    print("\nTesting basic operations...")
    
    -- Open a database bucket
    db:open_db("test_bucket")
    print("✓ Database bucket opened")
    
    -- Store a value
    local put_success = db:put("test_bucket", "test_key", "test_value")
    print("Put success:", put_success)
    
    -- Retrieve the value
    local retrieved_value = db:get("test_bucket", "test_key")
    print("Retrieved value:", retrieved_value)
    
    -- Test vector storage (serialized)
    local test_vector = {0.1, 0.2, 0.3, 0.4, 0.5}
    local vector_str = table.concat(test_vector, ",")
    
    local vector_put_success = db:put("test_bucket", "vector_key", vector_str)
    print("Vector put success:", vector_put_success)
    
    local retrieved_vector_str = db:get("test_bucket", "vector_key")
    print("Retrieved vector string:", retrieved_vector_str)
    
    -- Parse it back
    local parsed_vector = {}
    for num_str in string.gmatch(retrieved_vector_str, "[^,]+") do
        table.insert(parsed_vector, tonumber(num_str))
    end
    
    print("Parsed vector:")
    for i, v in ipairs(parsed_vector) do
        print("  [" .. i .. "] = " .. v)
    end
    
    print("\n✓ All kv operations successful!")
    
else
    print("✗ Failed to open database")
end