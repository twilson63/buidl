-- similarity_search.lua
-- Vector similarity search implementation

local SimilaritySearch = {}
local VectorMath = require("src/vector_math")

-- Create new similarity search instance
function SimilaritySearch.new(vector_store)
    local search = {
        store = vector_store
    }
    
    setmetatable(search, {__index = SimilaritySearch})
    return search
end

-- Search for similar vectors
function SimilaritySearch:search(query_vector, options)
    options = options or {}
    local limit = options.limit or 10
    local threshold = options.threshold or 0.0
    local filters = options.filters or {}
    
    if not VectorMath.is_valid_vector(query_vector) then
        return {}, "Invalid query vector"
    end
    
    local results = {}
    local all_ids = self.store:get_all_ids()
    
    -- Linear search through all vectors
    for _, id in ipairs(all_ids) do
        local entry = self.store:get_vector(id)
        
        if entry and entry.vector then
            -- Apply metadata filters
            if self:_passes_filters(entry.metadata, filters) then
                -- Calculate similarity
                local similarity = VectorMath.cosine_similarity(query_vector, entry.vector)
                
                -- Check threshold
                if similarity >= threshold then
                    table.insert(results, {
                        id = entry.id,
                        similarity = similarity,
                        vector = entry.vector,
                        metadata = entry.metadata
                    })
                end
            end
        end
    end
    
    -- Sort by similarity (descending)
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

-- Search by Euclidean distance
function SimilaritySearch:search_by_distance(query_vector, options)
    options = options or {}
    local limit = options.limit or 10
    local max_distance = options.max_distance or math.huge
    local filters = options.filters or {}
    
    if not VectorMath.is_valid_vector(query_vector) then
        return {}, "Invalid query vector"
    end
    
    local results = {}
    local all_ids = self.store:get_all_ids()
    
    -- Linear search through all vectors
    for _, id in ipairs(all_ids) do
        local entry = self.store:get_vector(id)
        
        if entry and entry.vector then
            -- Apply metadata filters
            if self:_passes_filters(entry.metadata, filters) then
                -- Calculate distance
                local distance = VectorMath.euclidean_distance(query_vector, entry.vector)
                
                -- Check max distance
                if distance <= max_distance then
                    table.insert(results, {
                        id = entry.id,
                        distance = distance,
                        vector = entry.vector,
                        metadata = entry.metadata
                    })
                end
            end
        end
    end
    
    -- Sort by distance (ascending)
    table.sort(results, function(a, b)
        return a.distance < b.distance
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

-- Find k-nearest neighbors
function SimilaritySearch:knn(query_vector, k, filters)
    return self:search(query_vector, {
        limit = k,
        threshold = 0.0,
        filters = filters or {}
    })
end

-- Search within similarity range
function SimilaritySearch:search_range(query_vector, min_similarity, max_similarity, filters)
    local all_results = self:search(query_vector, {
        limit = 0, -- No limit
        threshold = min_similarity,
        filters = filters or {}
    })
    
    -- Filter by max similarity
    local filtered_results = {}
    for _, result in ipairs(all_results) do
        if result.similarity <= max_similarity then
            table.insert(filtered_results, result)
        end
    end
    
    return filtered_results
end

-- Check if metadata passes filters
function SimilaritySearch:_passes_filters(metadata, filters)
    if not metadata then
        metadata = {}
    end
    
    for key, value in pairs(filters) do
        if key == "timestamp_after" then
            local timestamp = metadata.timestamp or 0
            if timestamp <= value then
                return false
            end
        elseif key == "timestamp_before" then
            local timestamp = metadata.timestamp or math.huge
            if timestamp >= value then
                return false
            end
        elseif key == "user_id_not" then
            if metadata.user_id == value then
                return false
            end
        elseif key:match("_not$") then
            -- Handle "_not" suffix filters
            local actual_key = key:gsub("_not$", "")
            if metadata[actual_key] == value then
                return false
            end
        else
            -- Exact match filter
            if metadata[key] ~= value then
                return false
            end
        end
    end
    
    return true
end

-- Get statistics about search performance
function SimilaritySearch:get_search_stats()
    local total_vectors = self.store:count()
    
    return {
        total_vectors = total_vectors,
        search_type = "linear_scan",
        complexity = "O(n)",
        estimated_search_time_ms = total_vectors * 0.1 -- Rough estimate
    }
end

-- Batch search for multiple queries
function SimilaritySearch:batch_search(query_vectors, options)
    local batch_results = {}
    
    for i, query_vector in ipairs(query_vectors) do
        local results = self:search(query_vector, options)
        batch_results[i] = results
    end
    
    return batch_results
end

-- Find outliers (vectors with low similarity to all others)
function SimilaritySearch:find_outliers(threshold, sample_size)
    threshold = threshold or 0.3
    sample_size = sample_size or 100
    
    local all_ids = self.store:get_all_ids()
    local outliers = {}
    
    -- Sample subset if too many vectors
    local ids_to_check = all_ids
    if #all_ids > sample_size then
        ids_to_check = {}
        local step = math.floor(#all_ids / sample_size)
        for i = 1, #all_ids, step do
            table.insert(ids_to_check, all_ids[i])
        end
    end
    
    for _, id in ipairs(ids_to_check) do
        local entry = self.store:get_vector(id)
        if entry and entry.vector then
            -- Find most similar vectors
            local results = self:search(entry.vector, {limit = 5, threshold = 0.0})
            
            -- Check if max similarity (excluding self) is below threshold
            local max_similarity = 0
            for _, result in ipairs(results) do
                if result.id ~= id and result.similarity > max_similarity then
                    max_similarity = result.similarity
                end
            end
            
            if max_similarity < threshold then
                table.insert(outliers, {
                    id = id,
                    max_similarity = max_similarity,
                    metadata = entry.metadata
                })
            end
        end
    end
    
    return outliers
end

return SimilaritySearch