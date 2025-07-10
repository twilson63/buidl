-- lsh_index.lua
-- Locality Sensitive Hashing for O(1) vector similarity search

local LSHIndex = {}
local VectorMath = require("src/vector_math")

-- Create new LSH index
function LSHIndex.new(vector_store, options)
    options = options or {}
    
    local index = {
        store = vector_store,
        num_tables = options.num_tables or 5,        -- Number of hash tables
        num_hyperplanes = options.num_hyperplanes or 10, -- Hash bits per table
        hash_tables = {},                            -- Hash table storage
        hyperplanes = {},                           -- Random hyperplanes
        bucket_size_limit = options.bucket_size_limit or 100, -- Max vectors per bucket
        rebuild_threshold = options.rebuild_threshold or 1000  -- Rebuild after N inserts
    }
    
    setmetatable(index, {__index = LSHIndex})
    index:_initialize_hash_tables()
    return index
end

-- Initialize hash tables and random hyperplanes
function LSHIndex:_initialize_hash_tables()
    math.randomseed(os.time())
    
    -- Initialize hash tables
    for i = 1, self.num_tables do
        self.hash_tables[i] = {}
        self.hyperplanes[i] = {}
        
        -- Generate random hyperplanes for this table
        for j = 1, self.num_hyperplanes do
            self.hyperplanes[i][j] = self:_generate_random_hyperplane()
        end
    end
end

-- Generate a random hyperplane (unit vector)
function LSHIndex:_generate_random_hyperplane(dimension)
    dimension = dimension or 1536 -- Default OpenAI embedding dimension
    local hyperplane = {}
    
    -- Generate random vector
    for i = 1, dimension do
        hyperplane[i] = (math.random() - 0.5) * 2 -- Range: -1 to 1
    end
    
    -- Normalize to unit vector
    return VectorMath.normalize(hyperplane)
end

-- Hash a vector using LSH
function LSHIndex:_hash_vector(vector, table_index)
    local hash_bits = {}
    
    for i = 1, self.num_hyperplanes do
        local hyperplane = self.hyperplanes[table_index][i]
        
        -- Adjust hyperplane dimension if needed
        if #hyperplane ~= #vector then
            hyperplane = self:_generate_random_hyperplane(#vector)
            self.hyperplanes[table_index][i] = hyperplane
        end
        
        -- Compute dot product and determine bit
        local dot_product = VectorMath.dot_product(vector, hyperplane)
        hash_bits[i] = (dot_product >= 0) and "1" or "0"
    end
    
    -- Convert bit array to hash string
    return table.concat(hash_bits)
end

-- Add vector to LSH index
function LSHIndex:add_vector(id, vector)
    if not VectorMath.is_valid_vector(vector) then
        return false, "Invalid vector"
    end
    
    -- Add to each hash table
    for table_idx = 1, self.num_tables do
        local hash_key = self:_hash_vector(vector, table_idx)
        
        -- Initialize bucket if doesn't exist
        if not self.hash_tables[table_idx][hash_key] then
            self.hash_tables[table_idx][hash_key] = {}
        end
        
        -- Add vector ID to bucket
        local bucket = self.hash_tables[table_idx][hash_key]
        
        -- Check if already exists
        local exists = false
        for _, existing_id in ipairs(bucket) do
            if existing_id == id then
                exists = true
                break
            end
        end
        
        if not exists then
            table.insert(bucket, id)
        end
        
        -- Check bucket size limit
        if #bucket > self.bucket_size_limit then
            -- Could implement bucket splitting here
            -- For now, just warn
            -- print("Warning: Bucket size exceeded for hash " .. hash_key)
        end
    end
    
    return true
end

-- Remove vector from LSH index
function LSHIndex:remove_vector(id, vector)
    if not VectorMath.is_valid_vector(vector) then
        return false, "Invalid vector"
    end
    
    -- Remove from each hash table
    for table_idx = 1, self.num_tables do
        local hash_key = self:_hash_vector(vector, table_idx)
        local bucket = self.hash_tables[table_idx][hash_key]
        
        if bucket then
            -- Remove ID from bucket
            for i = #bucket, 1, -1 do
                if bucket[i] == id then
                    table.remove(bucket, i)
                end
            end
            
            -- Clean up empty bucket
            if #bucket == 0 then
                self.hash_tables[table_idx][hash_key] = nil
            end
        end
    end
    
    return true
end

-- Search for similar vectors using LSH
function LSHIndex:search(query_vector, options)
    options = options or {}
    local limit = options.limit or 10
    local threshold = options.threshold or 0.0
    
    if not VectorMath.is_valid_vector(query_vector) then
        return {}, "Invalid query vector"
    end
    
    -- Collect candidate IDs from all hash tables
    local candidate_ids = {}
    local id_counts = {}
    
    for table_idx = 1, self.num_tables do
        local hash_key = self:_hash_vector(query_vector, table_idx)
        local bucket = self.hash_tables[table_idx][hash_key]
        
        if bucket then
            for _, id in ipairs(bucket) do
                if not candidate_ids[id] then
                    candidate_ids[id] = true
                    id_counts[id] = 1
                else
                    id_counts[id] = id_counts[id] + 1
                end
            end
        end
    end
    
    -- Convert to array and sort by frequency (more tables = more likely similar)
    local candidates = {}
    for id, count in pairs(id_counts) do
        table.insert(candidates, {id = id, count = count})
    end
    
    table.sort(candidates, function(a, b)
        return a.count > b.count
    end)
    
    -- Calculate actual similarities for top candidates
    local results = {}
    local checked_count = 0
    local max_candidates = math.min(limit * 3, 100) -- Check at most 3x limit or 100
    
    for _, candidate in ipairs(candidates) do
        if checked_count >= max_candidates then
            break
        end
        
        local entry = self.store:get_vector(candidate.id)
        if entry and entry.vector then
            local similarity = VectorMath.cosine_similarity(query_vector, entry.vector)
            
            if similarity >= threshold then
                table.insert(results, {
                    id = entry.id,
                    similarity = similarity,
                    vector = entry.vector,
                    metadata = entry.metadata,
                    lsh_score = candidate.count -- How many tables matched
                })
            end
        end
        checked_count = checked_count + 1
    end
    
    -- Sort by similarity
    table.sort(results, function(a, b)
        return a.similarity > b.similarity
    end)
    
    -- Apply limit
    if limit > 0 and #results > limit then
        local limited_results = {}
        for i = 1, limit do
            limited_results[i] = results[i]
        end
        results = limited_results
    end
    
    return results
end

-- Rebuild entire index (useful after many updates)
function LSHIndex:rebuild()
    -- Clear existing index
    self:_initialize_hash_tables()
    
    -- Re-add all vectors
    local all_ids = self.store:get_all_ids()
    local rebuilt_count = 0
    
    for _, id in ipairs(all_ids) do
        local entry = self.store:get_vector(id)
        if entry and entry.vector then
            local success = self:add_vector(id, entry.vector)
            if success then
                rebuilt_count = rebuilt_count + 1
            end
        end
    end
    
    return rebuilt_count
end

-- Get index statistics
function LSHIndex:get_stats()
    local total_buckets = 0
    local non_empty_buckets = 0
    local total_entries = 0
    local max_bucket_size = 0
    local bucket_sizes = {}
    
    for table_idx = 1, self.num_tables do
        for hash_key, bucket in pairs(self.hash_tables[table_idx]) do
            total_buckets = total_buckets + 1
            if #bucket > 0 then
                non_empty_buckets = non_empty_buckets + 1
                total_entries = total_entries + #bucket
                max_bucket_size = math.max(max_bucket_size, #bucket)
                table.insert(bucket_sizes, #bucket)
            end
        end
    end
    
    -- Calculate average bucket size
    local avg_bucket_size = non_empty_buckets > 0 and (total_entries / non_empty_buckets) or 0
    
    return {
        num_tables = self.num_tables,
        num_hyperplanes = self.num_hyperplanes,
        total_buckets = total_buckets,
        non_empty_buckets = non_empty_buckets,
        total_entries = total_entries,
        avg_bucket_size = avg_bucket_size,
        max_bucket_size = max_bucket_size,
        bucket_size_limit = self.bucket_size_limit
    }
end

-- Estimate search performance
function LSHIndex:estimate_search_performance()
    local stats = self:get_stats()
    local avg_candidates_checked = stats.avg_bucket_size * self.num_tables
    
    return {
        avg_candidates_per_search = avg_candidates_checked,
        theoretical_speedup = math.max(1, self.store:count() / avg_candidates_checked),
        complexity = "O(1) average case"
    }
end

return LSHIndex