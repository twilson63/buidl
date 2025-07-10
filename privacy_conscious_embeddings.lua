-- privacy_conscious_embeddings.lua
-- Privacy-conscious embedding service with configurable privacy levels

local LocalEmbeddings = require("local_embeddings")

local PrivacyEmbeddings = {}

-- Privacy levels
PrivacyEmbeddings.PRIVACY_LEVELS = {
    HIGH = "high",      -- Local only, no external APIs
    MEDIUM = "medium",  -- Filtered external APIs, anonymized data
    LOW = "low"         -- Standard external APIs with full data
}

function PrivacyEmbeddings.new(config)
    config = config or {}
    
    local service = {
        privacy_level = config.privacy_level or PrivacyEmbeddings.PRIVACY_LEVELS.HIGH,
        openai_api_key = config.openai_api_key,
        use_enterprise_zdr = config.use_enterprise_zdr or false,
        data_residency = config.data_residency or "US", -- US, EU, etc.
        
        -- Local embedding fallbacks
        tfidf_vectorizer = nil,
        simple_embeddings = nil,
        
        -- Content filtering
        sensitive_patterns = {
            -- PII patterns
            "%d%d%d%-%d%d%-%d%d%d%d",  -- SSN pattern
            "%w+@%w+%.%w+",            -- Email pattern
            "password",                -- Password mentions
            "api[_%s]?key",           -- API key mentions
            "secret",                  -- Secret mentions
            "token"                    -- Token mentions
        },
        
        -- Statistics
        stats = {
            total_requests = 0,
            local_processed = 0,
            external_processed = 0,
            filtered_requests = 0,
            cache_hits = 0
        }
    }
    
    setmetatable(service, {__index = PrivacyEmbeddings})
    
    -- Initialize local embedding fallbacks
    service:_init_local_embeddings()
    
    return service
end

-- Initialize local embedding services
function PrivacyEmbeddings:_init_local_embeddings()
    self.tfidf_vectorizer = LocalEmbeddings.TFIDFVectorizer.new()
    self.simple_embeddings = LocalEmbeddings.SimpleEmbeddings.new(128)
    
    -- Pre-train on common Slack vocabulary
    local training_corpus = {
        "hello team meeting today",
        "working on feature development",
        "need help with issue",
        "thanks for the update",
        "code review required",
        "deployment successful",
        "testing completed",
        "bug fix implemented",
        "documentation updated",
        "project status report"
    }
    
    self.tfidf_vectorizer:fit(training_corpus)
    self.simple_embeddings:fit(training_corpus)
end

-- Check if text contains sensitive information
function PrivacyEmbeddings:_contains_sensitive_data(text)
    if not text then return false end
    
    local lower_text = string.lower(text)
    
    for _, pattern in ipairs(self.sensitive_patterns) do
        if string.match(lower_text, pattern) then
            return true
        end
    end
    
    return false
end

-- Anonymize text by removing sensitive patterns
function PrivacyEmbeddings:_anonymize_text(text)
    if not text then return text end
    
    local anonymized = text
    
    -- Replace email addresses
    anonymized = string.gsub(anonymized, "%w+@%w+%.%w+", "[EMAIL]")
    
    -- Replace potential SSNs
    anonymized = string.gsub(anonymized, "%d%d%d%-%d%d%-%d%d%d%d", "[SSN]")
    
    -- Replace API keys/tokens (basic pattern)
    anonymized = string.gsub(anonymized, "[Aa]pi[_%s]?[Kk]ey[:%s]*[%w%-_]+", "[API_KEY]")
    anonymized = string.gsub(anonymized, "[Tt]oken[:%s]*[%w%-_]+", "[TOKEN]")
    anonymized = string.gsub(anonymized, "[Pp]assword[:%s]*[%w%-_]+", "[PASSWORD]")
    
    return anonymized
end

-- Get embedding with privacy controls
function PrivacyEmbeddings:get_embedding(text, options)
    options = options or {}
    self.stats.total_requests = self.stats.total_requests + 1
    
    if not text or text == "" then
        return self:_get_zero_vector()
    end
    
    -- Privacy level enforcement
    if self.privacy_level == PrivacyEmbeddings.PRIVACY_LEVELS.HIGH then
        return self:_get_local_embedding(text)
    end
    
    -- Check for sensitive data
    if self:_contains_sensitive_data(text) then
        self.stats.filtered_requests = self.stats.filtered_requests + 1
        
        if self.privacy_level == PrivacyEmbeddings.PRIVACY_LEVELS.MEDIUM then
            -- Use anonymized version for external API
            local anonymized_text = self:_anonymize_text(text)
            return self:_get_external_embedding(anonymized_text, options)
        else
            -- Fall back to local processing for sensitive data
            return self:_get_local_embedding(text)
        end
    end
    
    -- For non-sensitive data, use external API if available
    if self.privacy_level == PrivacyEmbeddings.PRIVACY_LEVELS.LOW or 
       self.privacy_level == PrivacyEmbeddings.PRIVACY_LEVELS.MEDIUM then
        return self:_get_external_embedding(text, options)
    end
    
    -- Default to local processing
    return self:_get_local_embedding(text)
end

-- Get local embedding using TF-IDF
function PrivacyEmbeddings:_get_local_embedding(text)
    self.stats.local_processed = self.stats.local_processed + 1
    
    -- Try TF-IDF first
    local tfidf_vector = self.tfidf_vectorizer:transform(text)
    
    -- Check if we got a meaningful vector (not all zeros)
    local has_content = false
    for _, value in ipairs(tfidf_vector) do
        if value ~= 0 then
            has_content = true
            break
        end
    end
    
    if has_content then
        return {
            vector = tfidf_vector,
            method = "tfidf_local",
            privacy_level = "high",
            dimension = #tfidf_vector
        }
    end
    
    -- Fall back to simple embeddings
    local simple_vector = self.simple_embeddings:transform(text)
    return {
        vector = simple_vector,
        method = "simple_local",
        privacy_level = "high",
        dimension = #simple_vector
    }
end

-- Get external embedding (placeholder - would integrate with actual API)
function PrivacyEmbeddings:_get_external_embedding(text, options)
    self.stats.external_processed = self.stats.external_processed + 1
    
    -- This would be the actual OpenAI API call
    -- For now, simulate with local processing
    print("SIMULATION: Would send to OpenAI API:", string.sub(text, 1, 50) .. "...")
    
    if self.use_enterprise_zdr then
        print("Using Enterprise Zero Data Retention")
    end
    
    -- Simulate API response with local embedding for demo
    local vector = self.tfidf_vectorizer:transform(text)
    
    return {
        vector = vector,
        method = "openai_simulated",
        privacy_level = self.privacy_level,
        dimension = #vector,
        zdr_enabled = self.use_enterprise_zdr
    }
end

-- Get zero vector for empty input
function PrivacyEmbeddings:_get_zero_vector()
    local vector = {}
    for i = 1, 128 do
        vector[i] = 0.0
    end
    
    return {
        vector = vector,
        method = "zero_vector",
        privacy_level = "high",
        dimension = 128
    }
end

-- Get privacy compliance report
function PrivacyEmbeddings:get_privacy_report()
    local total = self.stats.total_requests
    
    return {
        privacy_level = self.privacy_level,
        enterprise_zdr = self.use_enterprise_zdr,
        statistics = {
            total_requests = total,
            local_processing_rate = total > 0 and (self.stats.local_processed / total) or 0,
            external_processing_rate = total > 0 and (self.stats.external_processed / total) or 0,
            sensitive_data_filtered = self.stats.filtered_requests,
            privacy_compliance_score = self:_calculate_privacy_score()
        },
        recommendations = self:_get_privacy_recommendations()
    }
end

-- Calculate privacy compliance score
function PrivacyEmbeddings:_calculate_privacy_score()
    local score = 0
    
    -- Base score by privacy level
    if self.privacy_level == PrivacyEmbeddings.PRIVACY_LEVELS.HIGH then
        score = score + 80
    elseif self.privacy_level == PrivacyEmbeddings.PRIVACY_LEVELS.MEDIUM then
        score = score + 60
    else
        score = score + 40
    end
    
    -- Bonus for enterprise features
    if self.use_enterprise_zdr then
        score = score + 15
    end
    
    -- Bonus for local processing rate
    local total = self.stats.total_requests
    if total > 0 then
        local local_rate = self.stats.local_processed / total
        score = score + (local_rate * 5)
    end
    
    return math.min(score, 100)
end

-- Get privacy recommendations
function PrivacyEmbeddings:_get_privacy_recommendations()
    local recommendations = {}
    
    if self.privacy_level == PrivacyEmbeddings.PRIVACY_LEVELS.LOW then
        table.insert(recommendations, "Consider upgrading to MEDIUM or HIGH privacy level for sensitive data")
    end
    
    if not self.use_enterprise_zdr and self.stats.external_processed > 0 then
        table.insert(recommendations, "Consider OpenAI Enterprise Zero Data Retention for sensitive workloads")
    end
    
    if self.stats.filtered_requests > 0 then
        table.insert(recommendations, "Sensitive data detected - review data handling procedures")
    end
    
    local local_rate = self.stats.total_requests > 0 and 
        (self.stats.local_processed / self.stats.total_requests) or 0
    
    if local_rate < 0.5 and self.privacy_level == PrivacyEmbeddings.PRIVACY_LEVELS.HIGH then
        table.insert(recommendations, "Consider improving local embedding quality or training data")
    end
    
    return recommendations
end

-- Configuration for different deployment scenarios
function PrivacyEmbeddings.get_preset_configs()
    return {
        enterprise_secure = {
            privacy_level = PrivacyEmbeddings.PRIVACY_LEVELS.HIGH,
            use_enterprise_zdr = false,
            data_residency = "US"
        },
        enterprise_hybrid = {
            privacy_level = PrivacyEmbeddings.PRIVACY_LEVELS.MEDIUM,
            use_enterprise_zdr = true,
            data_residency = "EU"
        },
        startup_quality = {
            privacy_level = PrivacyEmbeddings.PRIVACY_LEVELS.LOW,
            use_enterprise_zdr = false,
            data_residency = "US"
        }
    }
end

return PrivacyEmbeddings