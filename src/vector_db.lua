-- vector_db.lua
-- Main Vector Database API - High-level interface

local VectorDB = {}
local VectorStore = require("src/vector_store")
local SimilaritySearch = require("src/similarity_search")
local VectorMath = require("src/vector_math")
local LSHIndex = require("src/lsh_index")
local MetadataIndex = require("src/metadata_index")

-- Create new vector database instance
function VectorDB.new(db_path, options)
    options = options or {}
    
    -- Initialize Hype key-value database
    local kv = require('kv')
    local kv_db = kv.open(db_path)
    
    -- Create vector store and search instances
    local store = VectorStore.new(kv_db)
    local search = SimilaritySearch.new(store)
    
    -- Create LSH index for fast similarity search
    local lsh_index = LSHIndex.new(store, options.lsh)
    
    -- Create metadata index for fast filtering
    local metadata_index = MetadataIndex.new(store)
    
    -- Setup common indexed fields
    metadata_index:add_indexed_field("user_id", "exact")
    metadata_index:add_indexed_field("channel", "exact")
    metadata_index:add_indexed_field("timestamp", "range")
    metadata_index:add_indexed_field("text", "text")
    
    local db = {
        _kv_db = kv_db,
        _store = store,
        _search = search,
        _lsh_index = lsh_index,
        _metadata_index = metadata_index,
        _db_path = db_path,
        _use_lsh = options.use_lsh ~= false, -- Default to true
        _auto_rebuild_threshold = options.auto_rebuild_threshold or 1000
    }
    
    setmetatable(db, {__index = VectorDB})
    
    -- Rebuild indexes if database already has data
    if store:count() > 0 then
        db:_rebuild_indexes()
    end
    
    return db
end

-- Insert a single vector entry
function VectorDB:insert(entry)
    if not entry or not entry.id or not entry.vector then
        return false, "Entry must have id and vector fields"
    end
    
    if not VectorMath.is_valid_vector(entry.vector) then
        return false, "Invalid vector data"
    end
    
    local success, error_msg = self._store:store_vector(entry.id, entry.vector, entry.metadata)
    
    if success then
        -- Add to LSH index
        if self._use_lsh then
            self._lsh_index:add_vector(entry.id, entry.vector)
        end
        
        -- Add to metadata index
        if entry.metadata then
            self._metadata_index:index_vector(entry.id, entry.metadata)
        end
    end
    
    return success, error_msg
end

-- Insert multiple vector entries in batch
function VectorDB:insert_batch(entries)
    if not entries or #entries == 0 then
        return 0
    end
    
    return self._store:store_batch(entries)
end

-- Search for similar vectors
function VectorDB:search(query)
    if not query or not query.vector then
        return {}, "Query must contain vector field"
    end
    
    if not VectorMath.is_valid_vector(query.vector) then
        return {}, "Invalid query vector"
    end
    
    local options = {
        limit = query.limit or 10,
        threshold = query.threshold or 0.0,
        filters = query.filters or {}
    }
    
    -- Use LSH index if enabled and no complex filters
    if self._use_lsh and self:_can_use_lsh_for_query(query) then
        return self._lsh_index:search(query.vector, options)
    else
        -- Use linear search with metadata pre-filtering
        if next(query.filters) then
            -- Get candidate IDs from metadata index
            local candidate_ids = self._metadata_index:filter_candidates(query.filters)
            return self:_search_candidates(query.vector, candidate_ids, options)
        else
            -- No filters, use original search
            return self._search:search(query.vector, options)
        end
    end
end

-- Update an existing vector entry
function VectorDB:update(id, changes)
    if not id or not changes then
        return false, "ID and changes are required"
    end
    
    -- Get existing entry
    local existing = self._store:get_vector(id)
    if not existing then
        return false, "Vector not found"
    end
    
    -- Merge changes
    local new_vector = changes.vector or existing.vector
    local new_metadata = existing.metadata or {}
    
    if changes.metadata then
        for key, value in pairs(changes.metadata) do
            new_metadata[key] = value
        end
    end
    
    -- Validate new vector if changed
    if changes.vector and not VectorMath.is_valid_vector(new_vector) then
        return false, "Invalid new vector data"
    end
    
    -- Store updated entry
    return self._store:store_vector(id, new_vector, new_metadata)
end

-- Delete a vector entry
function VectorDB:delete(id)
    if not id then
        return false, "ID is required"
    end
    
    -- Get vector before deletion for index cleanup
    local entry = self._store:get_vector(id)
    local success = self._store:delete_vector(id)
    
    if success and entry then
        -- Remove from LSH index
        if self._use_lsh and entry.vector then
            self._lsh_index:remove_vector(id, entry.vector)
        end
        
        -- Remove from metadata index
        if entry.metadata then
            self._metadata_index:remove_vector(id, entry.metadata)
        end
    end
    
    return success
end

-- Delete multiple entries based on filters
function VectorDB:delete_where(filters)
    if not filters or next(filters) == nil then
        return 0, "Filters are required for bulk delete"
    end
    
    local all_ids = self._store:get_all_ids()
    local deleted_count = 0
    
    for _, id in ipairs(all_ids) do
        local entry = self._store:get_vector(id)
        if entry and self._search:_passes_filters(entry.metadata, filters) then
            local success = self._store:delete_vector(id)
            if success then
                deleted_count = deleted_count + 1
            end
        end
    end
    
    return deleted_count
end

-- Get a specific vector entry by ID
function VectorDB:get(id)
    if not id then
        return nil, "ID is required"
    end
    
    return self._store:get_vector(id)
end

-- Check if a vector exists
function VectorDB:exists(id)
    if not id then
        return false
    end
    
    return self._store:exists(id)
end

-- Get database statistics
function VectorDB:get_stats()
    local total_count = self._store:count()
    local search_stats = self._search:get_search_stats()
    
    -- Calculate approximate storage size (rough estimate)
    local avg_vector_size = 1536 * 4  -- Assume 1536 dimensions, 4 bytes per float
    local estimated_storage_mb = (total_count * avg_vector_size) / (1024 * 1024)
    
    return {
        count = total_count,
        estimated_storage_mb = math.floor(estimated_storage_mb * 100) / 100,
        index_size_kb = math.floor((total_count * 50) / 1024), -- Rough index estimate
        last_updated = os.time(),
        search_complexity = search_stats.complexity,
        db_path = self._db_path
    }
end

-- Find k-nearest neighbors
function VectorDB:knn(vector, k, filters)
    if not VectorMath.is_valid_vector(vector) then
        return {}, "Invalid vector"
    end
    
    return self._search:knn(vector, k or 5, filters)
end

-- Search by distance instead of similarity
function VectorDB:search_by_distance(query)
    if not query or not query.vector then
        return {}, "Query must contain vector field"
    end
    
    if not VectorMath.is_valid_vector(query.vector) then
        return {}, "Invalid query vector"
    end
    
    local options = {
        limit = query.limit or 10,
        max_distance = query.max_distance or math.huge,
        filters = query.filters or {}
    }
    
    return self._search:search_by_distance(query.vector, options)
end

-- Find outlier vectors
function VectorDB:find_outliers(threshold, sample_size)
    return self._search:find_outliers(threshold, sample_size)
end

-- Rebuild index for optimization (placeholder for future indexing)
function VectorDB:rebuild_index()
    -- For now, this is a no-op since we use linear search
    -- In future, this could rebuild more efficient index structures
    local stats = self:get_stats()
    return true, string.format("Index rebuilt for %d vectors", stats.count)
end

-- Get all vector IDs
function VectorDB:get_all_ids()
    return self._store:get_all_ids()
end

-- Batch search for multiple queries
function VectorDB:batch_search(queries, options)
    local query_vectors = {}
    for _, query in ipairs(queries) do
        if query.vector and VectorMath.is_valid_vector(query.vector) then
            table.insert(query_vectors, query.vector)
        end
    end
    
    return self._search:batch_search(query_vectors, options)
end

-- Export vectors to simple format
function VectorDB:export_vectors()
    local all_ids = self._store:get_all_ids()
    local exported = {}
    
    for _, id in ipairs(all_ids) do
        local entry = self._store:get_vector(id)
        if entry then
            table.insert(exported, {
                id = entry.id,
                vector = entry.vector,
                metadata = entry.metadata
            })
        end
    end
    
    return exported
end

-- Import vectors from simple format
function VectorDB:import_vectors(vectors)
    if not vectors or #vectors == 0 then
        return 0, "No vectors to import"
    end
    
    local success_count = 0
    for _, entry in ipairs(vectors) do
        if entry.id and entry.vector then
            local success = self:insert(entry)
            if success then
                success_count = success_count + 1
            end
        end
    end
    
    return success_count, string.format("Imported %d/%d vectors", success_count, #vectors)
end

-- Close database connection
function VectorDB:close()
    -- Hype handles database closing automatically
    -- This is here for API completeness
    return true
end

-- Validate database integrity
function VectorDB:validate()
    local all_ids = self._store:get_all_ids()
    local valid_count = 0
    local invalid_entries = {}
    
    for _, id in ipairs(all_ids) do
        local entry = self._store:get_vector(id)
        if entry and entry.vector and VectorMath.is_valid_vector(entry.vector) then
            valid_count = valid_count + 1
        else
            table.insert(invalid_entries, id)
        end
    end
    
    return {
        total_entries = #all_ids,
        valid_entries = valid_count,
        invalid_entries = invalid_entries,
        integrity_score = valid_count / math.max(#all_ids, 1)
    }
end

-- Helper method: Check if LSH can be used for this query
function VectorDB:_can_use_lsh_for_query(query)
    local filters = query.filters or {}
    
    -- LSH works best with simple or no filters
    -- Complex filters like ranges or text search work better with metadata index
    for key, _ in pairs(filters) do
        if key:match("timestamp_") or key:match("_text$") or key:match("_range$") then
            return false -- Use metadata index instead
        end
    end
    
    return true
end

-- Helper method: Search specific candidate IDs
function VectorDB:_search_candidates(query_vector, candidate_ids, options)
    local results = {}
    
    for _, id in ipairs(candidate_ids) do
        local entry = self._store:get_vector(id)
        if entry and entry.vector then
            local similarity = VectorMath.cosine_similarity(query_vector, entry.vector)
            
            if similarity >= options.threshold then
                table.insert(results, {
                    id = entry.id,
                    similarity = similarity,
                    vector = entry.vector,
                    metadata = entry.metadata
                })
            end
        end
    end
    
    -- Sort by similarity
    table.sort(results, function(a, b)
        return a.similarity > b.similarity
    end)
    
    -- Apply limit
    if options.limit > 0 and #results > options.limit then
        local limited_results = {}
        for i = 1, options.limit do
            limited_results[i] = results[i]
        end
        results = limited_results
    end
    
    return results
end

-- Helper method: Rebuild all indexes
function VectorDB:_rebuild_indexes()
    if self._use_lsh then
        self._lsh_index:rebuild()
    end
    self._metadata_index:rebuild()
end

-- Enhanced rebuild index method
function VectorDB:rebuild_index()
    self:_rebuild_indexes()
    local stats = self:get_stats()
    return true, string.format("Indexes rebuilt for %d vectors", stats.count)
end

-- Enhanced statistics with index information
function VectorDB:get_stats()
    local total_count = self._store:count()
    local search_stats = self._search:get_search_stats()
    
    -- Calculate approximate storage size
    local avg_vector_size = 1536 * 4
    local estimated_storage_mb = (total_count * avg_vector_size) / (1024 * 1024)
    
    local stats = {
        count = total_count,
        estimated_storage_mb = math.floor(estimated_storage_mb * 100) / 100,
        index_size_kb = math.floor((total_count * 50) / 1024),
        last_updated = os.time(),
        search_complexity = self._use_lsh and "O(1) with LSH" or search_stats.complexity,
        db_path = self._db_path,
        lsh_enabled = self._use_lsh
    }
    
    -- Add LSH stats if enabled
    if self._use_lsh then
        local lsh_stats = self._lsh_index:get_stats()
        local lsh_perf = self._lsh_index:estimate_search_performance()
        stats.lsh_stats = lsh_stats
        stats.lsh_performance = lsh_perf
    end
    
    -- Add metadata index stats
    local metadata_stats = self._metadata_index:get_stats()
    stats.metadata_index = metadata_stats
    
    return stats
end

return VectorDB