-- vector_store.lua
-- Vector storage layer for Hype key-value database

local VectorStore = {}
local VectorMath = require("src/vector_math")

-- Create new vector store instance
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

-- Serialize vector to string for storage
function VectorStore:_serialize_vector(vector)
    local parts = {}
    for i = 1, #vector do
        parts[i] = tostring(vector[i])
    end
    return table.concat(parts, ",")
end

-- Deserialize vector from string
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

-- Serialize metadata to JSON-like string
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

-- Deserialize metadata from JSON-like string
function VectorStore:_deserialize_metadata(metadata_str)
    if not metadata_str or metadata_str == "{}" then
        return {}
    end
    
    local metadata = {}
    
    -- Simple JSON parsing for basic types
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

-- Store a vector with metadata
function VectorStore:store_vector(id, vector, metadata)
    if not VectorMath.is_valid_vector(vector) then
        return false, "Invalid vector"
    end
    
    if not id or id == "" then
        return false, "Invalid ID"
    end
    
    local vector_key = "vec:" .. id
    local metadata_key = "meta:" .. id
    
    -- Serialize and store vector
    local vector_str = self:_serialize_vector(vector)
    local success1 = self.db:put(self.vector_bucket, vector_key, vector_str)
    
    -- Serialize and store metadata
    local metadata_str = self:_serialize_metadata(metadata or {})
    local success2 = self.db:put(self.metadata_bucket, metadata_key, metadata_str)
    
    if success1 and success2 then
        -- Add to index
        self:_add_to_index(id)
        return true
    else
        return false, "Failed to store vector or metadata"
    end
end

-- Retrieve a vector with metadata
function VectorStore:get_vector(id)
    if not id or id == "" then
        return nil, "Invalid ID"
    end
    
    local vector_key = "vec:" .. id
    local metadata_key = "meta:" .. id
    
    -- Get vector
    local vector_str = self.db:get(self.vector_bucket, vector_key)
    if not vector_str then
        return nil, "Vector not found"
    end
    
    -- Get metadata
    local metadata_str = self.db:get(self.metadata_bucket, metadata_key)
    
    -- Deserialize
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

-- Delete a vector
function VectorStore:delete_vector(id)
    if not id or id == "" then
        return false, "Invalid ID"
    end
    
    local vector_key = "vec:" .. id
    local metadata_key = "meta:" .. id
    
    -- Delete from storage
    local success1 = self.db:delete(self.vector_bucket, vector_key)
    local success2 = self.db:delete(self.metadata_bucket, metadata_key)
    
    if success1 or success2 then
        -- Remove from index
        self:_remove_from_index(id)
        return true
    else
        return false, "Failed to delete vector"
    end
end

-- Get all vector IDs from index
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

-- Add ID to index
function VectorStore:_add_to_index(id)
    local current_ids = self:get_all_ids()
    
    -- Check if already exists
    for _, existing_id in ipairs(current_ids) do
        if existing_id == id then
            return -- Already in index
        end
    end
    
    -- Add new ID
    table.insert(current_ids, id)
    local index_str = table.concat(current_ids, ",")
    self.db:put(self.index_bucket, "all_ids", index_str)
end

-- Remove ID from index
function VectorStore:_remove_from_index(id)
    local current_ids = self:get_all_ids()
    local new_ids = {}
    
    for _, existing_id in ipairs(current_ids) do
        if existing_id ~= id then
            table.insert(new_ids, existing_id)
        end
    end
    
    local index_str = table.concat(new_ids, ",")
    self.db:put(self.index_bucket, "all_ids", index_str)
end

-- Get count of stored vectors
function VectorStore:count()
    local ids = self:get_all_ids()
    return #ids
end

-- Check if vector exists
function VectorStore:exists(id)
    if not id or id == "" then
        return false
    end
    
    local vector_key = "vec:" .. id
    local vector_str = self.db:get(self.vector_bucket, vector_key)
    return vector_str ~= nil
end

-- Batch store multiple vectors
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

return VectorStore