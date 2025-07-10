-- performance_test.lua
-- Performance comparison between linear search and LSH indexing

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

-- Generate random vector
local function generate_random_vector(dimension)
    local vector = {}
    for i = 1, dimension do
        vector[i] = (math.random() - 0.5) * 2 -- Range: -1 to 1
    end
    return vector
end

-- Generate test dataset
local function generate_test_data(count, dimension)
    math.randomseed(12345) -- Fixed seed for reproducible results
    
    local vectors = {}
    for i = 1, count do
        table.insert(vectors, {
            id = "vec_" .. i,
            vector = generate_random_vector(dimension),
            metadata = {
                user_id = "user_" .. (i % 100), -- 100 different users
                timestamp = os.time() - (i * 60), -- 1 minute apart
                text = "Sample message " .. i,
                channel = "general"
            }
        })
    end
    
    return vectors
end

-- Measure execution time
local function measure_time(func)
    local start_time = os.clock()
    local result = func()
    local end_time = os.clock()
    return (end_time - start_time) * 1000, result -- Return milliseconds
end

-- Run performance tests
local function run_performance_tests()
    print("=== Vector Database Performance Tests ===\n")
    
    local test_sizes = {100, 500, 1000, 2000}
    local dimension = 128 -- Smaller dimension for faster testing
    local num_queries = 10
    
    for _, size in ipairs(test_sizes) do
        print(string.format("Testing with %d vectors (dimension: %d)", size, dimension))
        print(string.rep("-", 50))
        
        -- Generate test data
        local test_vectors = generate_test_data(size, dimension)
        local query_vector = generate_random_vector(dimension)
        
        -- Test 1: Linear search (no indexing)
        print("1. Linear Search (no indexing)")
        local db_linear = VectorDB.new("./test_linear.db", {
            use_lsh = false
        })
        
        -- Insert data and measure time
        local insert_time, _ = measure_time(function()
            return db_linear:insert_batch(test_vectors)
        end)
        
        -- Search and measure time
        local search_times = {}
        for i = 1, num_queries do
            local search_time, results = measure_time(function()
                return db_linear:search({
                    vector = query_vector,
                    limit = 10,
                    threshold = 0.0
                })
            end)
            table.insert(search_times, search_time)
        end
        
        local avg_search_time = 0
        for _, time in ipairs(search_times) do
            avg_search_time = avg_search_time + time
        end
        avg_search_time = avg_search_time / #search_times
        
        print(string.format("  Insert time: %.2f ms", insert_time))
        print(string.format("  Avg search time: %.2f ms", avg_search_time))
        
        -- Test 2: LSH indexing
        print("2. LSH Indexing")
        local db_lsh = VectorDB.new("./test_lsh.db", {
            use_lsh = true,
            lsh = {
                num_tables = 5,
                num_hyperplanes = 10
            }
        })
        
        -- Insert data and measure time
        local lsh_insert_time, _ = measure_time(function()
            return db_lsh:insert_batch(test_vectors)
        end)
        
        -- Search and measure time
        local lsh_search_times = {}
        for i = 1, num_queries do
            local search_time, results = measure_time(function()
                return db_lsh:search({
                    vector = query_vector,
                    limit = 10,
                    threshold = 0.0
                })
            end)
            table.insert(lsh_search_times, search_time)
        end
        
        local lsh_avg_search_time = 0
        for _, time in ipairs(lsh_search_times) do
            lsh_avg_search_time = lsh_avg_search_time + time
        end
        lsh_avg_search_time = lsh_avg_search_time / #lsh_search_times
        
        print(string.format("  Insert time: %.2f ms", lsh_insert_time))
        print(string.format("  Avg search time: %.2f ms", lsh_avg_search_time))
        
        -- Test 3: Metadata filtering
        print("3. Metadata Filtering")
        local filter_time, filtered_results = measure_time(function()
            return db_lsh:search({
                vector = query_vector,
                limit = 10,
                threshold = 0.0,
                filters = {
                    user_id = "user_50"
                }
            })
        end)
        
        print(string.format("  Filtered search time: %.2f ms", filter_time))
        print(string.format("  Filtered results: %d", #filtered_results))
        
        -- Calculate performance improvement
        local search_speedup = avg_search_time / lsh_avg_search_time
        local insert_overhead = ((lsh_insert_time - insert_time) / insert_time) * 100
        
        print("4. Performance Summary")
        print(string.format("  Search speedup: %.2fx", search_speedup))
        print(string.format("  Insert overhead: %.1f%%", insert_overhead))
        
        -- Get detailed statistics
        local stats = db_lsh:get_stats()
        if stats.lsh_performance then
            print(string.format("  Theoretical speedup: %.2fx", stats.lsh_performance.theoretical_speedup))
            print(string.format("  Avg candidates checked: %.1f", stats.lsh_performance.avg_candidates_per_search))
        end
        
        print("")
    end
    
    -- Accuracy test
    print("=== Accuracy Comparison ===")
    local test_vectors = generate_test_data(500, dimension)
    local query_vector = generate_random_vector(dimension)
    
    -- Create databases
    local db_linear = VectorDB.new("./accuracy_linear.db", {use_lsh = false})
    local db_lsh = VectorDB.new("./accuracy_lsh.db", {use_lsh = true})
    
    db_linear:insert_batch(test_vectors)
    db_lsh:insert_batch(test_vectors)
    
    -- Get results from both
    local linear_results = db_linear:search({
        vector = query_vector,
        limit = 20,
        threshold = 0.0
    })
    
    local lsh_results = db_lsh:search({
        vector = query_vector,
        limit = 20,
        threshold = 0.0
    })
    
    -- Calculate overlap
    local linear_ids = {}
    for _, result in ipairs(linear_results) do
        linear_ids[result.id] = result.similarity
    end
    
    local overlap_count = 0
    local similarity_diff_sum = 0
    
    for _, lsh_result in ipairs(lsh_results) do
        if linear_ids[lsh_result.id] then
            overlap_count = overlap_count + 1
            local diff = math.abs(linear_ids[lsh_result.id] - lsh_result.similarity)
            similarity_diff_sum = similarity_diff_sum + diff
        end
    end
    
    local recall = overlap_count / math.min(#linear_results, #lsh_results)
    local avg_similarity_diff = overlap_count > 0 and (similarity_diff_sum / overlap_count) or 0
    
    print(string.format("Recall (LSH vs Linear): %.2f%%", recall * 100))
    print(string.format("Avg similarity difference: %.4f", avg_similarity_diff))
    print(string.format("Linear results: %d, LSH results: %d, Overlap: %d", 
        #linear_results, #lsh_results, overlap_count))
    
    print("\n=== Performance Tests Completed ===")
end

-- Run the performance tests
run_performance_tests()