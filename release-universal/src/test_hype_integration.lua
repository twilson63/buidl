-- test_hype_integration.lua
-- Test vector database with real Hype framework

local VectorDB = require("src/vector_db")

-- Test function
local function test_hype_integration()
    print("=== Hype Integration Test ===")
    
    -- Test 1: Initialize database with real Hype kv store
    print("\n1. Testing Hype key-value store integration...")
    
    local db = VectorDB.new("./data/test_integration.db", {
        use_lsh = true,
        lsh = {
            num_tables = 3,
            num_hyperplanes = 8
        }
    })
    
    print("✓ Database initialized with Hype backend")
    
    -- Test 2: Insert some test vectors
    print("\n2. Testing vector insertion...")
    
    local test_vectors = {
        {
            id = "msg_001",
            vector = {0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8},
            metadata = {
                text = "Hello from Slack channel",
                user_id = "U12345",
                timestamp = os.time(),
                channel = "general"
            }
        },
        {
            id = "msg_002", 
            vector = {0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9},
            metadata = {
                text = "Another message in the channel",
                user_id = "U67890",
                timestamp = os.time() - 3600,
                channel = "general"
            }
        },
        {
            id = "msg_003",
            vector = {0.9, 0.8, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6},
            metadata = {
                text = "Different topic discussion",
                user_id = "U11111",
                timestamp = os.time() - 7200,
                channel = "random"
            }
        }
    }
    
    local batch_count = db:insert_batch(test_vectors)
    print(string.format("✓ Inserted %d vectors in batch", batch_count))
    
    -- Test 3: Verify storage and retrieval
    print("\n3. Testing vector retrieval...")
    
    local retrieved = db:get("msg_001")
    if retrieved and retrieved.vector then
        print("✓ Vector retrieval successful")
        print("  ID:", retrieved.id)
        print("  Vector length:", #retrieved.vector)
        print("  Text:", retrieved.metadata.text)
        print("  User:", retrieved.metadata.user_id)
    else
        print("✗ Vector retrieval failed")
        return false
    end
    
    -- Test 4: Search functionality
    print("\n4. Testing similarity search...")
    
    local query_vector = {0.15, 0.25, 0.35, 0.45, 0.55, 0.65, 0.75, 0.85}
    local search_results = db:search({
        vector = query_vector,
        limit = 3,
        threshold = 0.0
    })
    
    if #search_results > 0 then
        print("✓ Similarity search successful")
        for i, result in ipairs(search_results) do
            print(string.format("  Result %d: %s (similarity: %.3f)", 
                i, result.id, result.similarity))
        end
    else
        print("✗ Similarity search returned no results")
        return false
    end
    
    -- Test 5: Filtered search
    print("\n5. Testing filtered search...")
    
    local filtered_results = db:search({
        vector = query_vector,
        limit = 5,
        filters = {
            channel = "general"
        }
    })
    
    print(string.format("✓ Filtered search found %d results", #filtered_results))
    for _, result in ipairs(filtered_results) do
        print(string.format("  - %s: %s", result.id, result.metadata.text))
    end
    
    -- Test 6: Database statistics
    print("\n6. Testing database statistics...")
    
    local stats = db:get_stats()
    print("✓ Database statistics:")
    print(string.format("  Total vectors: %d", stats.count))
    print(string.format("  Search complexity: %s", stats.search_complexity))
    print(string.format("  LSH enabled: %s", tostring(stats.lsh_enabled)))
    
    if stats.lsh_stats then
        print(string.format("  LSH tables: %d", stats.lsh_stats.num_tables))
        print(string.format("  LSH hyperplanes: %d", stats.lsh_stats.num_hyperplanes))
    end
    
    -- Test 7: K-nearest neighbors
    print("\n7. Testing k-nearest neighbors...")
    
    local knn_results = db:knn(query_vector, 2)
    print(string.format("✓ KNN search found %d neighbors", #knn_results))
    
    -- Test 8: Index rebuild
    print("\n8. Testing index rebuild...")
    
    local rebuild_success, rebuild_msg = db:rebuild_index()
    if rebuild_success then
        print("✓ Index rebuild successful:", rebuild_msg)
    else
        print("✗ Index rebuild failed")
        return false
    end
    
    -- Test 9: Vector update
    print("\n9. Testing vector update...")
    
    local update_success = db:update("msg_001", {
        metadata = {
            text = "Updated message text",
            updated_at = os.time()
        }
    })
    
    if update_success then
        print("✓ Vector update successful")
        local updated = db:get("msg_001")
        print("  Updated text:", updated.metadata.text)
    else
        print("✗ Vector update failed")
        return false
    end
    
    -- Test 10: Database validation
    print("\n10. Testing database validation...")
    
    local validation = db:validate()
    print("✓ Database validation completed")
    print(string.format("  Integrity score: %.2f", validation.integrity_score))
    print(string.format("  Valid entries: %d/%d", validation.valid_entries, validation.total_entries))
    
    -- Test 11: Data persistence
    print("\n11. Testing data persistence...")
    
    -- Close and reopen database
    db:close()
    
    local db2 = VectorDB.new("./data/test_integration.db", {
        use_lsh = true
    })
    
    local persistent_stats = db2:get_stats()
    if persistent_stats.count == stats.count then
        print("✓ Data persistence verified")
        print(string.format("  Vectors persisted: %d", persistent_stats.count))
    else
        print("✗ Data persistence failed")
        return false
    end
    
    print("\n=== All Hype Integration Tests Passed! ===")
    return true
end

-- Run the test
local success = test_hype_integration()

if success then
    print("\n🎉 Vector database is ready for production use with Hype!")
    print("The database can now be integrated into the Slack bot server.")
else
    print("\n❌ Integration tests failed. Please check the implementation.")
    os.exit(1)
end