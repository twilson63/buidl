-- simple_vector_test.lua
-- Simple vector database test without module dependencies

local kv = require('kv')

-- Simple vector math functions
local function dot_product(vec1, vec2)
    local sum = 0
    for i = 1, #vec1 do
        sum = sum + (vec1[i] * vec2[i])
    end
    return sum
end

local function magnitude(vec)
    local sum_squares = 0
    for i = 1, #vec do
        sum_squares = sum_squares + (vec[i] * vec[i])
    end
    return math.sqrt(sum_squares)
end

local function cosine_similarity(vec1, vec2)
    local dot = dot_product(vec1, vec2)
    local mag1 = magnitude(vec1)
    local mag2 = magnitude(vec2)
    if mag1 == 0 or mag2 == 0 then
        return 0
    end
    return dot / (mag1 * mag2)
end

-- Simple vector storage
local function serialize_vector(vector)
    local parts = {}
    for i = 1, #vector do
        parts[i] = tostring(vector[i])
    end
    return table.concat(parts, ",")
end

local function deserialize_vector(vector_str)
    if not vector_str or vector_str == "" then
        return nil
    end
    
    local vector = {}
    for num_str in string.gmatch(vector_str, "[^,]+") do
        local num = tonumber(num_str)
        if not num then
            return nil
        end
        table.insert(vector, num)
    end
    return vector
end

-- Main test
local function test_simple_vector_db()
    print("=== Simple Vector Database Test ===")
    
    -- Open database
    print("\n1. Opening database...")
    local db = kv.open("./data/simple_test.db")
    
    if not db then
        print("✗ Failed to open database")
        return false
    end
    
    print("✓ Database opened")
    
    -- Setup buckets
    db:open_db("vectors")
    db:open_db("metadata")
    print("✓ Database buckets created")
    
    -- Test data
    local test_vectors = {
        {
            id = "vec1",
            vector = {0.1, 0.2, 0.3, 0.4, 0.5},
            text = "Hello world"
        },
        {
            id = "vec2", 
            vector = {0.2, 0.3, 0.4, 0.5, 0.6},
            text = "Hello there"
        },
        {
            id = "vec3",
            vector = {0.9, 0.8, 0.1, 0.2, 0.3},
            text = "Goodbye world"
        }
    }
    
    -- Store vectors
    print("\n2. Storing vectors...")
    for _, entry in ipairs(test_vectors) do
        local vector_str = serialize_vector(entry.vector)
        local success1 = db:put("vectors", "vec:" .. entry.id, vector_str)
        local success2 = db:put("metadata", "meta:" .. entry.id, entry.text)
        
        if success1 and success2 then
            print("✓ Stored " .. entry.id)
        else
            print("✗ Failed to store " .. entry.id)
        end
    end
    
    -- Retrieve and verify
    print("\n3. Retrieving vectors...")
    for _, entry in ipairs(test_vectors) do
        local vector_str = db:get("vectors", "vec:" .. entry.id)
        local text = db:get("metadata", "meta:" .. entry.id)
        
        if vector_str and text then
            local vector = deserialize_vector(vector_str)
            print(string.format("✓ Retrieved %s: %d dims, text: %s", 
                entry.id, #vector, text))
        else
            print("✗ Failed to retrieve " .. entry.id)
        end
    end
    
    -- Test similarity search
    print("\n4. Testing similarity search...")
    local query_vector = {0.15, 0.25, 0.35, 0.45, 0.55}
    local results = {}
    
    -- Compare with all stored vectors
    for _, entry in ipairs(test_vectors) do
        local vector_str = db:get("vectors", "vec:" .. entry.id)
        if vector_str then
            local vector = deserialize_vector(vector_str)
            local similarity = cosine_similarity(query_vector, vector)
            table.insert(results, {
                id = entry.id,
                similarity = similarity,
                text = entry.text
            })
        end
    end
    
    -- Sort by similarity
    table.sort(results, function(a, b)
        return a.similarity > b.similarity
    end)
    
    print("Search results (sorted by similarity):")
    for i, result in ipairs(results) do
        print(string.format("  %d. %s (%.3f): %s", 
            i, result.id, result.similarity, result.text))
    end
    
    -- Test persistence
    print("\n5. Testing persistence...")
    
    -- Close and reopen database
    local db2 = kv.open("./data/simple_test.db")
    db2:open_db("vectors")
    db2:open_db("metadata")
    
    -- Verify data is still there
    local vector_str = db2:get("vectors", "vec:vec1")
    local text = db2:get("metadata", "meta:vec1")
    
    if vector_str and text then
        print("✓ Data persistence verified")
        local vector = deserialize_vector(vector_str)
        print(string.format("  Persisted vec1: %d dims, text: %s", #vector, text))
    else
        print("✗ Data persistence failed")
        return false
    end
    
    print("\n=== Simple Vector Database Test Completed Successfully! ===")
    return true
end

-- Run the test
local success = test_simple_vector_db()

if success then
    print("\n🎉 Vector database works with Hype!")
    print("Ready to integrate full implementation.")
else
    print("\n❌ Vector database test failed.")
    os.exit(1)
end