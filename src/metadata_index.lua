-- metadata_index.lua
-- Inverted index for fast metadata filtering - O(1) lookups

local MetadataIndex = {}

-- Create new metadata index
function MetadataIndex.new(vector_store)
    local index = {
        store = vector_store,
        indexes = {},           -- field_name -> { value -> [id1, id2, ...] }
        indexed_fields = {},    -- Track which fields are indexed
        range_indexes = {}      -- Special indexes for range queries (timestamps, etc.)
    }
    
    setmetatable(index, {__index = MetadataIndex})
    return index
end

-- Add field to indexing
function MetadataIndex:add_indexed_field(field_name, field_type)
    field_type = field_type or "exact" -- "exact", "range", "text"
    
    if not self.indexes[field_name] then
        self.indexes[field_name] = {}
        self.indexed_fields[field_name] = field_type
        
        if field_type == "range" then
            self.range_indexes[field_name] = {
                sorted_values = {},
                value_to_ids = {}
            }
        end
    end
end

-- Index a vector's metadata
function MetadataIndex:index_vector(id, metadata)
    if not metadata then
        return
    end
    
    -- Index each field that we're tracking
    for field_name, field_type in pairs(self.indexed_fields) do
        local value = metadata[field_name]
        
        if value ~= nil then
            if field_type == "exact" then
                self:_add_to_exact_index(field_name, value, id)
            elseif field_type == "range" then
                self:_add_to_range_index(field_name, value, id)
            elseif field_type == "text" then
                self:_add_to_text_index(field_name, value, id)
            end
        end
    end
end

-- Remove vector from metadata index
function MetadataIndex:remove_vector(id, metadata)
    if not metadata then
        return
    end
    
    -- Remove from each indexed field
    for field_name, field_type in pairs(self.indexed_fields) do
        local value = metadata[field_name]
        
        if value ~= nil then
            if field_type == "exact" then
                self:_remove_from_exact_index(field_name, value, id)
            elseif field_type == "range" then
                self:_remove_from_range_index(field_name, value, id)
            elseif field_type == "text" then
                self:_remove_from_text_index(field_name, value, id)
            end
        end
    end
end

-- Add to exact match index
function MetadataIndex:_add_to_exact_index(field_name, value, id)
    local value_key = tostring(value)
    
    if not self.indexes[field_name][value_key] then
        self.indexes[field_name][value_key] = {}
    end
    
    local ids = self.indexes[field_name][value_key]
    
    -- Check if already exists
    for _, existing_id in ipairs(ids) do
        if existing_id == id then
            return -- Already indexed
        end
    end
    
    table.insert(ids, id)
end

-- Remove from exact match index
function MetadataIndex:_remove_from_exact_index(field_name, value, id)
    local value_key = tostring(value)
    local ids = self.indexes[field_name][value_key]
    
    if ids then
        for i = #ids, 1, -1 do
            if ids[i] == id then
                table.remove(ids, i)
            end
        end
        
        -- Clean up empty arrays
        if #ids == 0 then
            self.indexes[field_name][value_key] = nil
        end
    end
end

-- Add to range index (for timestamps, numbers)
function MetadataIndex:_add_to_range_index(field_name, value, id)
    local range_index = self.range_indexes[field_name]
    
    -- Add to value mapping
    if not range_index.value_to_ids[value] then
        range_index.value_to_ids[value] = {}
        -- Insert into sorted array
        self:_insert_sorted(range_index.sorted_values, value)
    end
    
    local ids = range_index.value_to_ids[value]
    
    -- Check if already exists
    for _, existing_id in ipairs(ids) do
        if existing_id == id then
            return
        end
    end
    
    table.insert(ids, id)
end

-- Remove from range index
function MetadataIndex:_remove_from_range_index(field_name, value, id)
    local range_index = self.range_indexes[field_name]
    local ids = range_index.value_to_ids[value]
    
    if ids then
        for i = #ids, 1, -1 do
            if ids[i] == id then
                table.remove(ids, i)
            end
        end
        
        -- Clean up if empty
        if #ids == 0 then
            range_index.value_to_ids[value] = nil
            -- Remove from sorted array
            for i, v in ipairs(range_index.sorted_values) do
                if v == value then
                    table.remove(range_index.sorted_values, i)
                    break
                end
            end
        end
    end
end

-- Add to text index (simple word-based)
function MetadataIndex:_add_to_text_index(field_name, text, id)
    -- Simple tokenization - split by spaces and common punctuation
    local words = {}
    for word in string.gmatch(string.lower(text), "%w+") do
        if #word >= 3 then -- Only index words 3+ characters
            words[word] = true
        end
    end
    
    -- Index each word
    for word, _ in pairs(words) do
        self:_add_to_exact_index(field_name .. "_word", word, id)
    end
end

-- Remove from text index
function MetadataIndex:_remove_from_text_index(field_name, text, id)
    local words = {}
    for word in string.gmatch(string.lower(text), "%w+") do
        if #word >= 3 then
            words[word] = true
        end
    end
    
    for word, _ in pairs(words) do
        self:_remove_from_exact_index(field_name .. "_word", word, id)
    end
end

-- Binary search insert for sorted array
function MetadataIndex:_insert_sorted(array, value)
    local left, right = 1, #array
    local insert_pos = #array + 1
    
    while left <= right do
        local mid = math.floor((left + right) / 2)
        if array[mid] < value then
            left = mid + 1
        elseif array[mid] > value then
            right = mid - 1
            insert_pos = mid
        else
            -- Value already exists
            return
        end
    end
    
    table.insert(array, insert_pos, value)
end

-- Get IDs for exact match filter
function MetadataIndex:get_ids_for_exact_match(field_name, value)
    local value_key = tostring(value)
    local ids = self.indexes[field_name] and self.indexes[field_name][value_key]
    
    if ids then
        -- Return copy to avoid modification
        local result = {}
        for _, id in ipairs(ids) do
            table.insert(result, id)
        end
        return result
    else
        return {}
    end
end

-- Get IDs for range query
function MetadataIndex:get_ids_for_range(field_name, min_value, max_value)
    local range_index = self.range_indexes[field_name]
    if not range_index then
        return {}
    end
    
    local result_ids = {}
    local ids_seen = {}
    
    -- Find values in range
    for _, value in ipairs(range_index.sorted_values) do
        if value >= min_value and value <= max_value then
            local ids = range_index.value_to_ids[value]
            if ids then
                for _, id in ipairs(ids) do
                    if not ids_seen[id] then
                        ids_seen[id] = true
                        table.insert(result_ids, id)
                    end
                end
            end
        elseif value > max_value then
            break -- No more values in range
        end
    end
    
    return result_ids
end

-- Get IDs for text search
function MetadataIndex:get_ids_for_text_search(field_name, query_text)
    local words = {}
    for word in string.gmatch(string.lower(query_text), "%w+") do
        if #word >= 3 then
            table.insert(words, word)
        end
    end
    
    if #words == 0 then
        return {}
    end
    
    -- Get IDs for first word
    local result_ids = self:get_ids_for_exact_match(field_name .. "_word", words[1])
    
    -- Intersect with other words (simple AND logic)
    for i = 2, #words do
        local word_ids = self:get_ids_for_exact_match(field_name .. "_word", words[i])
        local word_ids_set = {}
        for _, id in ipairs(word_ids) do
            word_ids_set[id] = true
        end
        
        -- Keep only IDs that appear in both sets
        local intersected = {}
        for _, id in ipairs(result_ids) do
            if word_ids_set[id] then
                table.insert(intersected, id)
            end
        end
        result_ids = intersected
    end
    
    return result_ids
end

-- Apply filters and return candidate IDs
function MetadataIndex:filter_candidates(filters)
    if not filters or next(filters) == nil then
        return self.store:get_all_ids() -- No filters, return all
    end
    
    local candidate_sets = {}
    local has_filters = false
    
    -- Process each filter
    for key, value in pairs(filters) do
        local candidate_ids = {}
        
        if key == "timestamp_after" or key == "timestamp_before" then
            -- Range query
            local field_name = "timestamp"
            if self.indexed_fields[field_name] == "range" then
                if key == "timestamp_after" then
                    candidate_ids = self:get_ids_for_range(field_name, value, math.huge)
                else -- timestamp_before
                    candidate_ids = self:get_ids_for_range(field_name, 0, value)
                end
            end
        elseif key:match("_not$") then
            -- Negative filter - skip for now, will filter in post-processing
            goto continue
        elseif key:match("_text$") then
            -- Text search
            local field_name = key:gsub("_text$", "")
            if self.indexed_fields[field_name] == "text" then
                candidate_ids = self:get_ids_for_text_search(field_name, value)
            end
        else
            -- Exact match
            if self.indexed_fields[key] then
                candidate_ids = self:get_ids_for_exact_match(key, value)
            end
        end
        
        if #candidate_ids > 0 then
            table.insert(candidate_sets, candidate_ids)
            has_filters = true
        end
        
        ::continue::
    end
    
    if not has_filters then
        return self.store:get_all_ids()
    end
    
    -- Intersect all candidate sets (AND logic)
    local result = candidate_sets[1] or {}
    
    for i = 2, #candidate_sets do
        local set_b = {}
        for _, id in ipairs(candidate_sets[i]) do
            set_b[id] = true
        end
        
        local intersected = {}
        for _, id in ipairs(result) do
            if set_b[id] then
                table.insert(intersected, id)
            end
        end
        result = intersected
    end
    
    return result
end

-- Rebuild entire index
function MetadataIndex:rebuild()
    self.indexes = {}
    self.range_indexes = {}
    
    -- Re-initialize indexed fields
    for field_name, field_type in pairs(self.indexed_fields) do
        self.indexes[field_name] = {}
        if field_type == "range" then
            self.range_indexes[field_name] = {
                sorted_values = {},
                value_to_ids = {}
            }
        end
    end
    
    -- Re-index all vectors
    local all_ids = self.store:get_all_ids()
    local indexed_count = 0
    
    for _, id in ipairs(all_ids) do
        local entry = self.store:get_vector(id)
        if entry and entry.metadata then
            self:index_vector(id, entry.metadata)
            indexed_count = indexed_count + 1
        end
    end
    
    return indexed_count
end

-- Get index statistics
function MetadataIndex:get_stats()
    local stats = {
        indexed_fields = {},
        total_index_entries = 0
    }
    
    for field_name, field_type in pairs(self.indexed_fields) do
        local field_stats = {
            type = field_type,
            unique_values = 0,
            total_entries = 0
        }
        
        if field_type == "range" then
            local range_index = self.range_indexes[field_name]
            field_stats.unique_values = #range_index.sorted_values
            for _, ids in pairs(range_index.value_to_ids) do
                field_stats.total_entries = field_stats.total_entries + #ids
            end
        else
            local index = self.indexes[field_name]
            if index then
                for _, ids in pairs(index) do
                    field_stats.unique_values = field_stats.unique_values + 1
                    field_stats.total_entries = field_stats.total_entries + #ids
                end
            end
        end
        
        stats.indexed_fields[field_name] = field_stats
        stats.total_index_entries = stats.total_index_entries + field_stats.total_entries
    end
    
    return stats
end

return MetadataIndex