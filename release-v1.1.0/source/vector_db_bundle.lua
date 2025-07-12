-- vector_db_bundle.lua
-- Complete vector database implementation bundled for Hype

local kv = require('kv')

-- ============================================================================
-- VECTOR MATH MODULE
-- ============================================================================

local VectorMath = {}

function VectorMath.dot_product(vec1, vec2)
    if #vec1 ~= #vec2 then
        error("Vectors must have the same dimension")
    end
    
    local sum = 0
    for i = 1, #vec1 do
        sum = sum + (vec1[i] * vec2[i])
    end
    
    return sum
end

function VectorMath.magnitude(vec)
    local sum_squares = 0
    for i = 1, #vec do
        sum_squares = sum_squares + (vec[i] * vec[i])
    end
    
    return math.sqrt(sum_squares)
end

function VectorMath.cosine_similarity(vec1, vec2)
    if #vec1 ~= #vec2 then
        error("Vectors must have the same dimension")
    end
    
    local dot = VectorMath.dot_product(vec1, vec2)
    local mag1 = VectorMath.magnitude(vec1)
    local mag2 = VectorMath.magnitude(vec2)
    
    if mag1 == 0 or mag2 == 0 then
        return 0
    end
    
    return dot / (mag1 * mag2)
end

function VectorMath.is_valid_vector(vec)
    if type(vec) ~= "table" or #vec == 0 then
        return false
    end
    
    for i = 1, #vec do
        if type(vec[i]) ~= "number" or vec[i] ~= vec[i] then -- NaN check
            return false
        end
    end
    
    return true
end

-- ============================================================================
-- VECTOR STORE MODULE  
-- ============================================================================

local VectorStore = {}

function VectorStore.new(db_instance)
    local store = {
        db = db_instance,
        vector_bucket = "vectors",
        metadata_bucket = "metadata", 
        index_bucket = "index"
    }
    
    -- Ensure buckets exist
    store.db:open_db(store.vector_bucket)
    store.db:open_db(store.metadata_bucket)
    store.db:open_db(store.index_bucket)
    
    setmetatable(store, {__index = VectorStore})
    return store
end

function VectorStore:_serialize_vector(vector)
    local parts = {}
    for i = 1, #vector do
        parts[i] = tostring(vector[i])
    end
    return table.concat(parts, ",")
end

function VectorStore:_deserialize_vector(vector_str)
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

function VectorStore:_serialize_metadata(metadata)
    if not metadata then
        return "{}"
    end
    
    local parts = {}
    for key, value in pairs(metadata) do
        if type(value) == "string" then
            table.insert(parts, string.format('"%s":"%s"', key, value))
        elseif type(value) == "number" then
            table.insert(parts, string.format('"%s":%s', key, tostring(value)))
        elseif type(value) == "boolean" then
            table.insert(parts, string.format('"%s":%s', key, value and "true" or "false"))
        end
    end
    
    return "{" .. table.concat(parts, ",") .. "}"
end

function VectorStore:_deserialize_metadata(metadata_str)
    if not metadata_str or metadata_str == "{}" then
        return {}
    end
    
    local metadata = {}
    
    for key, value in string.gmatch(metadata_str, '"([^"]+)":"([^"]*)"') do
        metadata[key] = value
    end
    
    for key, value in string.gmatch(metadata_str, '"([^"]+)":([%d%.%-]+)') do
        metadata[key] = tonumber(value)
    end
    
    for key, value in string.gmatch(metadata_str, '"([^"]+)":(true|false)') do
        metadata[key] = (value == "true")
    end
    
    return metadata
end

function VectorStore:store_vector(id, vector, metadata)
    if not VectorMath.is_valid_vector(vector) then
        return false, "Invalid vector"
    end
    
    if not id or id == "" then
        return false, "Invalid ID"
    end
    
    local vector_key = "vec:" .. id
    local metadata_key = "meta:" .. id
    
    local vector_str = self:_serialize_vector(vector)
    self.db:put(self.vector_bucket, vector_key, vector_str)
    
    local metadata_str = self:_serialize_metadata(metadata or {})
    self.db:put(self.metadata_bucket, metadata_key, metadata_str)
    
    self:_add_to_index(id)
    return true
end

function VectorStore:get_vector(id)
    if not id or id == "" then
        return nil, "Invalid ID"
    end
    
    local vector_key = "vec:" .. id
    local metadata_key = "meta:" .. id
    
    local vector_str = self.db:get(self.vector_bucket, vector_key)
    if not vector_str then
        return nil, "Vector not found"
    end
    
    local metadata_str = self.db:get(self.metadata_bucket, metadata_key)
    
    local vector = self:_deserialize_vector(vector_str)
    local metadata = self:_deserialize_metadata(metadata_str)
    
    if not vector then
        return nil, "Failed to deserialize vector"
    end
    
    return {
        id = id,
        vector = vector,
        metadata = metadata
    }
end

function VectorStore:get_all_ids()
    local index_str = self.db:get(self.index_bucket, "all_ids")
    if not index_str or index_str == "" then
        return {}
    end
    
    local ids = {}
    for id in string.gmatch(index_str, "[^,]+") do
        if id ~= "" then
            table.insert(ids, id)
        end
    end
    
    return ids
end

function VectorStore:_add_to_index(id)
    local current_ids = self:get_all_ids()
    
    for _, existing_id in ipairs(current_ids) do
        if existing_id == id then
            return
        end
    end
    
    table.insert(current_ids, id)
    local index_str = table.concat(current_ids, ",")
    self.db:put(self.index_bucket, "all_ids", index_str)
end

function VectorStore:count()
    local ids = self:get_all_ids()
    return #ids
end

function VectorStore:store_batch(entries)
    local success_count = 0
    
    for _, entry in ipairs(entries) do
        local success, error_msg = self:store_vector(entry.id, entry.vector, entry.metadata)
        if success then
            success_count = success_count + 1
        end
    end
    
    return success_count
end

-- ============================================================================
-- VECTOR DATABASE MODULE
-- ============================================================================

local VectorDB = {}

function VectorDB.new(db_path, options)
    options = options or {}
    
    local kv_db = kv.open(db_path)
    local store = VectorStore.new(kv_db)
    
    local db = {
        _kv_db = kv_db,
        _store = store,
        _db_path = db_path
    }
    
    setmetatable(db, {__index = VectorDB})
    return db
end

function VectorDB:insert(entry)
    if not entry or not entry.id or not entry.vector then
        return false, "Entry must have id and vector fields"
    end
    
    if not VectorMath.is_valid_vector(entry.vector) then
        return false, "Invalid vector data"
    end
    
    local success, error_msg = self._store:store_vector(entry.id, entry.vector, entry.metadata)
    return success, error_msg
end

function VectorDB:insert_batch(entries)
    if not entries or #entries == 0 then
        return 0
    end
    
    return self._store:store_batch(entries)
end

function VectorDB:search(query)
    if not query or not query.vector then
        return {}, "Query must contain vector field"
    end
    
    if not VectorMath.is_valid_vector(query.vector) then
        return {}, "Invalid query vector"
    end
    
    local limit = query.limit or 10
    local threshold = query.threshold or 0.0
    local filters = query.filters or {}
    
    local results = {}
    local all_ids = self._store:get_all_ids()
    
    for _, id in ipairs(all_ids) do
        local entry = self._store:get_vector(id)
        
        if entry and entry.vector then
            if self:_passes_filters(entry.metadata, filters) then
                local similarity = VectorMath.cosine_similarity(query.vector, entry.vector)
                
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
    
    table.sort(results, function(a, b)
        return a.similarity > b.similarity
    end)
    
    if limit > 0 and #results > limit then
        local limited_results = {}
        for i = 1, limit do
            limited_results[i] = results[i]
        end
        results = limited_results
    end
    
    return results
end

function VectorDB:_passes_filters(metadata, filters)
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
        elseif key:match("_not$") then
            local actual_key = key:gsub("_not$", "")
            if metadata[actual_key] == value then
                return false
            end
        else
            if metadata[key] ~= value then
                return false
            end
        end
    end
    
    return true
end

function VectorDB:get(id)
    if not id then
        return nil, "ID is required"
    end
    
    return self._store:get_vector(id)
end

function VectorDB:knn(vector, k, filters)
    if not VectorMath.is_valid_vector(vector) then
        return {}, "Invalid vector"
    end
    
    return self:search({
        vector = vector,
        limit = k or 5,
        threshold = 0.0,
        filters = filters or {}
    })
end

function VectorDB:get_stats()
    local total_count = self._store:count()
    local avg_vector_size = 1536 * 4
    local estimated_storage_mb = (total_count * avg_vector_size) / (1024 * 1024)
    
    return {
        count = total_count,
        estimated_storage_mb = math.floor(estimated_storage_mb * 100) / 100,
        search_complexity = "O(n) linear search",
        db_path = self._db_path
    }
end

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

-- ============================================================================
-- EXPORT
-- ============================================================================

return VectorDB