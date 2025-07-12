---
layout: default
title: Vector Database API
description: Vector database API for semantic search and embeddings
permalink: /api/vector-database/
---

# Vector Database API

The vector database provides semantic search capabilities for message history and context retrieval using embeddings.

## Initialization

### Basic Setup
```lua
local vector_db = VectorDB.new({
    db_path = "./data/buidl.db",
    privacy_level = "high"
})
```

### Configuration Options
```lua
local config = {
    db_path = "./data/buidl.db",          -- Database file location
    privacy_level = "high",                -- high, medium, low
    max_messages = 10000,                  -- Maximum messages to store
    embedding_dimensions = 384,            -- Embedding vector dimensions
    similarity_threshold = 0.7,            -- Minimum similarity for matches
    use_lsh_index = true,                  -- Enable LSH indexing for performance
    lsh_tables = 10,                       -- Number of LSH tables
    lsh_hash_size = 10                     -- LSH hash size
}

local vector_db = VectorDB.new(config)
```

## Core Operations

### Adding Messages
```lua
-- Add single message
vector_db:add_message({
    text = "How do I deploy to production?",
    user = "U1234567890",
    channel = "C1234567890", 
    timestamp = "1704067200.123456",
    thread_ts = "1704067100.123456"  -- Optional: thread timestamp
})

-- Add message with metadata
vector_db:add_message({
    text = "The deployment failed with error code 500",
    user = "U1234567890",
    channel = "C1234567890",
    timestamp = "1704067200.123456",
    metadata = {
        urgency = "high",
        category = "deployment",
        tags = {"error", "production"}
    }
})
```

### Searching Messages
```lua
-- Basic search
local results = vector_db:search("deployment help", {
    limit = 5,
    channel = "C1234567890"
})

-- Advanced search with filters
local results = vector_db:search("database error", {
    limit = 10,
    channel = "C1234567890",
    user = "U1234567890",           -- Filter by user
    time_range = {
        start = "1704000000.000000",
        end = "1704086400.000000"
    },
    min_similarity = 0.8,           -- Higher similarity threshold
    include_metadata = true         -- Include metadata in results
})
```

### Search Results Format
```lua
{
    {
        text = "To deploy to production, run: npm run deploy:prod",
        user = "U1234567890",
        channel = "C1234567890",
        timestamp = "1704067200.123456",
        similarity = 0.92,
        metadata = {
            category = "deployment",
            tags = {"production", "npm"}
        }
    },
    -- More results...
}
```

## Embedding Management

### Privacy Levels

#### High Privacy (Local Only)
```lua
local embeddings = PrivacyConsciousEmbeddings.new({
    privacy_level = "high",
    local_model = "sentence-transformers/all-MiniLM-L6-v2"
})
```

#### Medium Privacy (Filtered External)
```lua
local embeddings = PrivacyConsciousEmbeddings.new({
    privacy_level = "medium",
    pii_filter = true,
    api_endpoint = "https://api.openai.com/v1/embeddings"
})
```

#### Low Privacy (Full External)
```lua
local embeddings = PrivacyConsciousEmbeddings.new({
    privacy_level = "low",
    api_endpoint = "https://api.openai.com/v1/embeddings",
    model = "text-embedding-ada-002"
})
```

### Custom Embedding Providers
```lua
local CustomEmbedding = {}

function CustomEmbedding.new(config)
    local self = setmetatable({}, CustomEmbedding)
    self.config = config
    return self
end

function CustomEmbedding:generate_embedding(text)
    -- Your custom embedding logic
    local embedding = your_embedding_function(text)
    return embedding
end

-- Register custom provider
vector_db:set_embedding_provider(CustomEmbedding.new(config))
```

## Performance Optimization

### LSH Indexing
```lua
-- Enable LSH for sub-linear search
local vector_db = VectorDB.new({
    db_path = "./data/buidl.db",
    use_lsh_index = true,
    lsh_tables = 20,        -- More tables = better recall
    lsh_hash_size = 12      -- Larger hash = more precision
})

-- Search with LSH
local results = vector_db:search_lsh("deployment error", {
    limit = 10,
    candidate_limit = 100   -- LSH candidates to evaluate
})
```

### Batch Operations
```lua
-- Add multiple messages efficiently
local messages = {
    {text = "Message 1", user = "U1", channel = "C1", timestamp = "1.1"},
    {text = "Message 2", user = "U2", channel = "C1", timestamp = "1.2"},
    -- ... more messages
}

vector_db:add_batch(messages, {
    batch_size = 100,       -- Process in batches
    parallel = true         -- Enable parallel processing
})
```

### Indexing Strategies
```lua
-- Create specialized indexes
vector_db:create_index("channel", "channel")
vector_db:create_index("user", "user") 
vector_db:create_index("timestamp", "timestamp")
vector_db:create_index("composite", {"channel", "user"})

-- Use indexes in queries
local results = vector_db:search("help", {
    use_index = "channel",
    channel = "C1234567890"
})
```

## Database Management

### Statistics and Monitoring
```lua
local stats = vector_db:get_stats()
print("Messages stored: " .. stats.total_messages)
print("Database size: " .. stats.size_mb .. " MB")
print("Average similarity: " .. stats.avg_similarity)
print("Index efficiency: " .. stats.index_efficiency)
```

### Maintenance Operations
```lua
-- Optimize database
vector_db:optimize()

-- Rebuild indexes
vector_db:rebuild_indexes()

-- Cleanup old messages
vector_db:cleanup({
    older_than = "30d",     -- Remove messages older than 30 days
    keep_minimum = 1000     -- But keep at least 1000 messages
})

-- Vacuum database
vector_db:vacuum()
```

### Backup and Restore
```lua
-- Create backup
vector_db:backup("./backups/buidl_" .. os.date("%Y%m%d") .. ".db")

-- Restore from backup
vector_db:restore("./backups/buidl_20240115.db")

-- Export to JSON
vector_db:export_json("./exports/messages.json", {
    include_embeddings = false,
    anonymize_users = true
})
```

## Data Privacy

### PII Detection and Filtering
```lua
local pii_filter = PIIFilter.new({
    patterns = {
        email = "[%w%._%+%-]+@[%w%.%-]+%.%w+",
        phone = "%d%d%d%-%d%d%d%-%d%d%d%d",
        ssn = "%d%d%d%-%d%d%-%d%d%d%d",
        credit_card = "%d%d%d%d%s%d%d%d%d%s%d%d%d%d%s%d%d%d%d"
    },
    replacement = "[REDACTED]",
    log_detections = true
})

-- Filter text before embedding
local filtered_text = pii_filter:filter(original_text)
vector_db:add_message({
    text = filtered_text,
    original_hash = hash(original_text)  -- For verification
})
```

### Data Retention Policies
```lua
-- Set retention policy
vector_db:set_retention_policy({
    default_retention = "90d",
    channel_policies = {
        ["C_PRIVATE"] = "7d",       -- Private channels: 7 days
        ["C_PUBLIC"] = "365d",      -- Public channels: 1 year
        ["C_ARCHIVE"] = "never"     -- Archive channels: never delete
    },
    user_preferences = {
        ["U_GDPR_USER"] = "30d"     -- GDPR user: 30 days max
    }
})
```

## Error Handling

### Database Errors
```lua
local success, error_msg = pcall(function()
    vector_db:add_message(message)
end)

if not success then
    if error_msg:match("database locked") then
        -- Retry with exponential backoff
        retry_with_backoff(function()
            vector_db:add_message(message)
        end)
    elseif error_msg:match("disk full") then
        -- Cleanup old data
        vector_db:cleanup({older_than = "7d"})
    else
        -- Log error
        logger:error("Database error: " .. error_msg)
    end
end
```

### Embedding Errors
```lua
local function safe_generate_embedding(text)
    local success, embedding = pcall(function()
        return embedding_provider:generate(text)
    end)
    
    if success then
        return embedding
    else
        -- Fallback to simple TF-IDF
        return tfidf_embedding(text)
    end
end
```

## Examples

### Basic Message Storage and Search
```lua
-- Initialize database
local db = VectorDB.new({db_path = "./messages.db"})

-- Add some messages
db:add_message({
    text = "How do I restart the service?",
    user = "alice",
    channel = "devops"
})

db:add_message({
    text = "sudo systemctl restart myservice",
    user = "bob", 
    channel = "devops"
})

-- Search for help
local results = db:search("restart service", {limit = 5})
for _, result in ipairs(results) do
    print(result.text .. " (similarity: " .. result.similarity .. ")")
end
```

### Advanced Context Retrieval
```lua
-- Context-aware search for AI responses
function get_conversation_context(query, channel, max_context)
    local recent_messages = db:search("", {
        channel = channel,
        time_range = {
            start = tostring(os.time() - 3600),  -- Last hour
            end = tostring(os.time())
        },
        limit = 20,
        sort_by = "timestamp"
    })
    
    local relevant_messages = db:search(query, {
        channel = channel,
        limit = max_context or 5,
        min_similarity = 0.6
    })
    
    -- Combine and deduplicate
    local context = {}
    local seen = {}
    
    for _, msg in ipairs(relevant_messages) do
        if not seen[msg.timestamp] then
            table.insert(context, msg)
            seen[msg.timestamp] = true
        end
    end
    
    return context
end
```