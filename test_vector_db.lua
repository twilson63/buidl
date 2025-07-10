-- test_vector_db.lua
-- Simple test file to validate vector database implementation

-- Mock the Hype kv module for testing
local MockKV = {}
MockKV.__index = MockKV

function MockKV:new()
    local instance = {
        buckets = {},
        data = {}
    }
    setmetatable(instance, MockKV)
    return instance
end

function MockKV:open_db(bucket_name)
    if not self.buckets[bucket_name] then
        self.buckets[bucket_name] = true
        self.data[bucket_name] = {}
    end
end

function MockKV:put(bucket, key, value)
    if not self.data[bucket] then
        self:open_db(bucket)
    end
    self.data[bucket][key] = value
    return true
end

function MockKV:get(bucket, key)
    if not self.data[bucket] then
        return nil
    end
    return self.data[bucket][key]
end

function MockKV:delete(bucket, key)
    if not self.data[bucket] then
        return false
    end
    if self.data[bucket][key] then
        self.data[bucket][key] = nil
        return true
    end
    return false
end

-- Mock kv.open function
kv = {
    open = function(path)
        return MockKV:new()
    end
}

-- Load our vector database modules
local VectorDB = require("src/vector_db")

-- Test function
local function run_tests()
    print("=== Vector Database Tests ===")
    
    -- Initialize database
    print("\n1. Initializing database...")
    local db = VectorDB.new("./test.db")
    print("✓ Database initialized")
    
    -- Test vector insertion
    print("\n2. Testing vector insertion...")
    local test_vector1 = {0.1, 0.2, 0.3, 0.4, 0.5}
    local success = db:insert({
        id = "test1",
        vector = test_vector1,
        metadata = {
            text = "Hello world",
            timestamp = os.time(),
            user_id = "user123"
        }
    })
    
    if success then
        print("✓ Vector insertion successful")
    else
        print("✗ Vector insertion failed")
        return
    end
    
    -- Test vector retrieval
    print("\n3. Testing vector retrieval...")
    local retrieved = db:get("test1")
    if retrieved and retrieved.vector then
        print("✓ Vector retrieval successful")
        print("  ID:", retrieved.id)
        print("  Vector dimension:", #retrieved.vector)
        print("  Metadata text:", retrieved.metadata.text)
    else
        print("✗ Vector retrieval failed")
        return
    end
    
    -- Insert more test vectors
    print("\n4. Inserting more test vectors...")
    local test_vectors = {
        {
            id = "test2",
            vector = {0.2, 0.3, 0.4, 0.5, 0.6},
            metadata = {text = "Similar vector", user_id = "user456"}
        },
        {
            id = "test3", 
            vector = {0.9, 0.8, 0.7, 0.1, 0.2},
            metadata = {text = "Different vector", user_id = "user789"}
        }
    }
    
    local batch_count = db:insert_batch(test_vectors)
    print("✓ Batch inserted", batch_count, "vectors")
    
    -- Test similarity search
    print("\n5. Testing similarity search...")
    local query_vector = {0.15, 0.25, 0.35, 0.45, 0.55}
    local search_results = db:search({
        vector = query_vector,
        limit = 2,
        threshold = 0.0
    })
    
    if #search_results > 0 then
        print("✓ Similarity search successful")
        for i, result in ipairs(search_results) do
            print(string.format("  Result %d: ID=%s, Similarity=%.3f", 
                i, result.id, result.similarity))
        end
    else
        print("✗ Similarity search returned no results")
    end
    
    -- Test k-nearest neighbors
    print("\n6. Testing k-nearest neighbors...")
    local knn_results = db:knn(query_vector, 2)
    if #knn_results > 0 then
        print("✓ KNN search successful")
        for i, result in ipairs(knn_results) do
            print(string.format("  KNN %d: ID=%s, Similarity=%.3f", 
                i, result.id, result.similarity))
        end
    else
        print("✗ KNN search failed")
    end
    
    -- Test metadata filtering
    print("\n7. Testing metadata filtering...")
    local filtered_results = db:search({
        vector = query_vector,
        limit = 5,
        filters = {
            user_id = "user123"
        }
    })
    
    print("✓ Filtered search completed, found", #filtered_results, "results")
    
    -- Test database statistics
    print("\n8. Testing database statistics...")
    local stats = db:get_stats()
    print("✓ Database stats:")
    print("  Total vectors:", stats.count)
    print("  Storage (MB):", stats.estimated_storage_mb)
    print("  Search complexity:", stats.search_complexity)
    
    -- Test vector update
    print("\n9. Testing vector update...")
    local update_success = db:update("test1", {
        metadata = {
            text = "Updated hello world",
            updated_at = os.time()
        }
    })
    
    if update_success then
        print("✓ Vector update successful")
        local updated = db:get("test1")
        print("  Updated text:", updated.metadata.text)
    else
        print("✗ Vector update failed")
    end
    
    -- Test vector existence
    print("\n10. Testing vector existence...")
    local exists = db:exists("test1")
    local not_exists = db:exists("nonexistent")
    
    if exists and not not_exists then
        print("✓ Existence check working correctly")
    else
        print("✗ Existence check failed")
    end
    
    -- Test vector deletion
    print("\n11. Testing vector deletion...")
    local delete_success = db:delete("test3")
    if delete_success then
        print("✓ Vector deletion successful")
        local after_delete_stats = db:get_stats()
        print("  Vectors after deletion:", after_delete_stats.count)
    else
        print("✗ Vector deletion failed")
    end
    
    -- Test database validation
    print("\n12. Testing database validation...")
    local validation = db:validate()
    print("✓ Database validation completed")
    print("  Total entries:", validation.total_entries)
    print("  Valid entries:", validation.valid_entries)
    print("  Integrity score:", string.format("%.2f", validation.integrity_score))
    
    print("\n=== All Tests Completed ===")
end

-- Run the tests
run_tests()