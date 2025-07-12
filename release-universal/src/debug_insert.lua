-- debug_insert.lua
-- Debug vector insertion issues

local kv = require('kv')

local function debug_kv_operations()
    print("=== Debugging KV Operations ===")
    
    -- Open database
    local db = kv.open("./data/debug.db")
    
    -- Open bucket
    db:open_db("test")
    print("✓ Database and bucket opened")
    
    -- Test basic put operation
    print("\n1. Testing basic put operation...")
    local result = db:put("test", "simple_key", "simple_value")
    print("Put result:", result)
    print("Put result type:", type(result))
    
    -- Try to retrieve
    local value = db:get("test", "simple_key")
    print("Retrieved value:", value)
    print("Retrieved value type:", type(value))
    
    -- Test with vector data
    print("\n2. Testing vector serialization...")
    local test_vector = {0.1, 0.2, 0.3, 0.4, 0.5}
    local vector_str = table.concat(test_vector, ",")
    print("Vector string:", vector_str)
    
    local vector_result = db:put("test", "vector_key", vector_str)
    print("Vector put result:", vector_result)
    print("Vector put result type:", type(vector_result))
    
    local retrieved_vector_str = db:get("test", "vector_key")
    print("Retrieved vector string:", retrieved_vector_str)
    
    -- Parse back
    if retrieved_vector_str then
        local parsed_vector = {}
        for num_str in string.gmatch(retrieved_vector_str, "[^,]+") do
            table.insert(parsed_vector, tonumber(num_str))
        end
        print("Parsed vector length:", #parsed_vector)
        print("First element:", parsed_vector[1])
    end
    
    -- Test metadata serialization
    print("\n3. Testing metadata serialization...")
    local metadata = {
        text = "Hello world",
        user_id = "U12345",
        timestamp = os.time()
    }
    
    -- Simple JSON-like serialization
    local metadata_str = string.format('{"text":"%s","user_id":"%s","timestamp":%d}',
        metadata.text, metadata.user_id, metadata.timestamp)
    print("Metadata string:", metadata_str)
    
    local meta_result = db:put("test", "meta_key", metadata_str)
    print("Metadata put result:", meta_result)
    
    local retrieved_meta_str = db:get("test", "meta_key")
    print("Retrieved metadata:", retrieved_meta_str)
    
    -- Test what happens with nil/false returns
    print("\n4. Testing return value interpretation...")
    if result then
        print("Put operation succeeded (truthy)")
    else
        print("Put operation failed (falsy)")
        print("Result was:", result)
    end
    
    -- Check what the database actually contains
    print("\n5. Verifying stored data...")
    local keys_to_check = {"simple_key", "vector_key", "meta_key"}
    for _, key in ipairs(keys_to_check) do
        local val = db:get("test", key)
        if val then
            print(string.format("  %s: %s", key, val))
        else
            print(string.format("  %s: NOT FOUND", key))
        end
    end
    
    print("\n=== Debug Complete ===")
end

debug_kv_operations()