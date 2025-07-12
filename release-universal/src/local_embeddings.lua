-- local_embeddings.lua
-- Local text embedding implementation in Lua

local LocalEmbeddings = {}

-- ============================================================================
-- TEXT PREPROCESSING
-- ============================================================================

-- Simple tokenization and normalization
function LocalEmbeddings.tokenize(text)
    if not text or text == "" then
        return {}
    end
    
    -- Convert to lowercase and extract words
    local tokens = {}
    for word in string.gmatch(string.lower(text), "%w+") do
        -- Filter out very short words and common stop words
        if #word >= 3 and not LocalEmbeddings.is_stop_word(word) then
            table.insert(tokens, word)
        end
    end
    
    return tokens
end

-- Basic stop words list
function LocalEmbeddings.is_stop_word(word)
    local stop_words = {
        ["the"] = true, ["and"] = true, ["for"] = true, ["are"] = true,
        ["but"] = true, ["not"] = true, ["you"] = true, ["all"] = true,
        ["can"] = true, ["had"] = true, ["her"] = true, ["was"] = true,
        ["one"] = true, ["our"] = true, ["out"] = true, ["day"] = true,
        ["get"] = true, ["has"] = true, ["him"] = true, ["his"] = true,
        ["how"] = true, ["its"] = true, ["may"] = true, ["new"] = true,
        ["now"] = true, ["old"] = true, ["see"] = true, ["two"] = true,
        ["who"] = true, ["boy"] = true, ["did"] = true, ["way"] = true,
        ["what"] = true, ["when"] = true, ["will"] = true, ["with"] = true
    }
    
    return stop_words[word] or false
end

-- ============================================================================
-- TF-IDF VECTORIZATION
-- ============================================================================

local TFIDFVectorizer = {}

function TFIDFVectorizer.new()
    local vectorizer = {
        vocabulary = {},        -- word -> index mapping
        idf_scores = {},       -- inverse document frequency scores
        vocab_size = 0,
        documents_count = 0
    }
    
    setmetatable(vectorizer, {__index = TFIDFVectorizer})
    return vectorizer
end

-- Build vocabulary from a collection of documents
function TFIDFVectorizer:fit(documents)
    local word_doc_count = {}
    self.documents_count = #documents
    
    -- Count word occurrences across documents
    for _, doc in ipairs(documents) do
        local tokens = LocalEmbeddings.tokenize(doc)
        local word_set = {}
        
        -- Count unique words per document
        for _, token in ipairs(tokens) do
            word_set[token] = true
        end
        
        -- Increment document count for each unique word
        for word, _ in pairs(word_set) do
            word_doc_count[word] = (word_doc_count[word] or 0) + 1
        end
    end
    
    -- Build vocabulary and calculate IDF scores
    local index = 1
    for word, doc_freq in pairs(word_doc_count) do
        -- Only include words that appear in at least 2 documents but not too frequently
        if doc_freq >= 2 and doc_freq <= (self.documents_count * 0.8) then
            self.vocabulary[word] = index
            self.idf_scores[word] = math.log(self.documents_count / doc_freq)
            index = index + 1
        end
    end
    
    self.vocab_size = index - 1
    print(string.format("Built vocabulary: %d words from %d documents", 
        self.vocab_size, self.documents_count))
end

-- Transform text into TF-IDF vector
function TFIDFVectorizer:transform(text)
    local tokens = LocalEmbeddings.tokenize(text)
    if #tokens == 0 then
        -- Return zero vector for empty input
        local zero_vector = {}
        for i = 1, math.max(self.vocab_size, 100) do
            zero_vector[i] = 0.0
        end
        return zero_vector
    end
    
    -- Count term frequencies
    local term_freq = {}
    for _, token in ipairs(tokens) do
        term_freq[token] = (term_freq[token] or 0) + 1
    end
    
    -- Calculate TF-IDF vector
    local vector = {}
    for i = 1, math.max(self.vocab_size, 100) do
        vector[i] = 0.0
    end
    
    for word, freq in pairs(term_freq) do
        local word_index = self.vocabulary[word]
        if word_index then
            local tf = freq / #tokens  -- Term frequency
            local idf = self.idf_scores[word] or 0  -- Inverse document frequency
            vector[word_index] = tf * idf
        end
    end
    
    -- Normalize vector to unit length
    local magnitude = 0
    for _, value in ipairs(vector) do
        magnitude = magnitude + (value * value)
    end
    magnitude = math.sqrt(magnitude)
    
    if magnitude > 0 then
        for i = 1, #vector do
            vector[i] = vector[i] / magnitude
        end
    end
    
    return vector
end

-- ============================================================================
-- SIMPLE WORD2VEC-STYLE EMBEDDINGS
-- ============================================================================

local SimpleEmbeddings = {}

function SimpleEmbeddings.new(dimension)
    local embeddings = {
        dimension = dimension or 128,
        word_vectors = {},
        vocabulary = {},
        vocab_size = 0
    }
    
    setmetatable(embeddings, {__index = SimpleEmbeddings})
    return embeddings
end

-- Initialize random vectors for vocabulary words
function SimpleEmbeddings:fit(documents)
    local word_freq = {}
    
    -- Count word frequencies
    for _, doc in ipairs(documents) do
        local tokens = LocalEmbeddings.tokenize(doc)
        for _, token in ipairs(tokens) do
            word_freq[token] = (word_freq[token] or 0) + 1
        end
    end
    
    -- Build vocabulary (words that appear at least 3 times)
    local index = 1
    for word, freq in pairs(word_freq) do
        if freq >= 3 then
            self.vocabulary[word] = index
            
            -- Initialize random vector for this word
            local vector = {}
            for i = 1, self.dimension do
                vector[i] = (math.random() - 0.5) * 0.1  -- Small random values
            end
            self.word_vectors[word] = vector
            index = index + 1
        end
    end
    
    self.vocab_size = index - 1
    print(string.format("Built embeddings: %d words, %d dimensions", 
        self.vocab_size, self.dimension))
end

-- Transform text into embedding by averaging word vectors
function SimpleEmbeddings:transform(text)
    local tokens = LocalEmbeddings.tokenize(text)
    local vector = {}
    
    -- Initialize zero vector
    for i = 1, self.dimension do
        vector[i] = 0.0
    end
    
    if #tokens == 0 then
        return vector
    end
    
    -- Average word vectors
    local found_words = 0
    for _, token in ipairs(tokens) do
        local word_vector = self.word_vectors[token]
        if word_vector then
            for i = 1, self.dimension do
                vector[i] = vector[i] + word_vector[i]
            end
            found_words = found_words + 1
        end
    end
    
    -- Average and normalize
    if found_words > 0 then
        for i = 1, self.dimension do
            vector[i] = vector[i] / found_words
        end
        
        -- Normalize to unit length
        local magnitude = 0
        for _, value in ipairs(vector) do
            magnitude = magnitude + (value * value)
        end
        magnitude = math.sqrt(magnitude)
        
        if magnitude > 0 then
            for i = 1, #vector do
                vector[i] = vector[i] / magnitude
            end
        end
    end
    
    return vector
end

-- ============================================================================
-- BENCHMARK AND COMPARISON
-- ============================================================================

function LocalEmbeddings.benchmark_approaches()
    print("=== LOCAL EMBEDDINGS BENCHMARK ===")
    
    -- Sample Slack messages for training
    local training_messages = {
        "Hello team, how is everyone doing today?",
        "Great! Working on the new feature implementation.",
        "Can someone help me with this database issue?",
        "The meeting is scheduled for 3 PM today.",
        "I'll review the pull request this afternoon.",
        "Thanks for the quick response on that bug fix.",
        "Let's discuss this in the standup tomorrow.",
        "The deployment went smoothly yesterday.",
        "I'm seeing some performance issues with the API.",
        "Good morning everyone! Ready for the week.",
        "The client feedback was very positive.",
        "We need to update the documentation.",
        "The tests are all passing now.",
        "I'll be out of office next Friday.",
        "Can we schedule a code review session?",
        "The feature is ready for testing.",
        "I found a potential security vulnerability.",
        "The database migration completed successfully.",
        "Let's prioritize this ticket for next sprint.",
        "The user interface looks great!",
        "Having trouble with the authentication flow.",
        "The API response time improved significantly.",
        "Need help debugging this network issue.",
        "The new release is scheduled for Monday.",
        "Great job on optimizing the query performance."
    }
    
    -- Test messages
    local test_messages = {
        "How is the team doing?",
        "Working on new features",
        "Database problems need help",
        "Meeting time today",
        "Code review needed"
    }
    
    print(string.format("Training on %d messages, testing on %d messages", 
        #training_messages, #test_messages))
    
    -- Benchmark TF-IDF
    print("\n--- TF-IDF Vectorizer ---")
    local start_time = os.clock()
    
    local tfidf = TFIDFVectorizer.new()
    tfidf:fit(training_messages)
    
    local tfidf_vectors = {}
    for i, msg in ipairs(test_messages) do
        tfidf_vectors[i] = tfidf:transform(msg)
    end
    
    local tfidf_time = (os.clock() - start_time) * 1000
    print(string.format("TF-IDF processing time: %.2f ms", tfidf_time))
    print(string.format("Vector dimension: %d", #tfidf_vectors[1]))
    
    -- Benchmark Simple Embeddings
    print("\n--- Simple Word Embeddings ---")
    start_time = os.clock()
    
    local embeddings = SimpleEmbeddings.new(128)
    embeddings:fit(training_messages)
    
    local embedding_vectors = {}
    for i, msg in ipairs(test_messages) do
        embedding_vectors[i] = embeddings:transform(msg)
    end
    
    local embedding_time = (os.clock() - start_time) * 1000
    print(string.format("Embeddings processing time: %.2f ms", embedding_time))
    print(string.format("Vector dimension: %d", #embedding_vectors[1]))
    
    -- Test similarity between related messages
    print("\n--- Similarity Testing ---")
    
    -- Function to calculate cosine similarity
    local function cosine_similarity(vec1, vec2)
        if #vec1 ~= #vec2 then return 0 end
        
        local dot_product = 0
        local mag1, mag2 = 0, 0
        
        for i = 1, #vec1 do
            dot_product = dot_product + (vec1[i] * vec2[i])
            mag1 = mag1 + (vec1[i] * vec1[i])
            mag2 = mag2 + (vec2[i] * vec2[i])
        end
        
        mag1 = math.sqrt(mag1)
        mag2 = math.sqrt(mag2)
        
        if mag1 == 0 or mag2 == 0 then return 0 end
        return dot_product / (mag1 * mag2)
    end
    
    -- Test similar messages: "How is the team doing?" vs "Hello team, how is everyone doing today?"
    local query1 = "How is the team doing?"
    local target1 = "Hello team, how is everyone doing today?"
    
    local tfidf_query1 = tfidf:transform(query1)
    local tfidf_target1 = tfidf:transform(target1)
    local tfidf_sim1 = cosine_similarity(tfidf_query1, tfidf_target1)
    
    local emb_query1 = embeddings:transform(query1)
    local emb_target1 = embeddings:transform(target1)
    local emb_sim1 = cosine_similarity(emb_query1, emb_target1)
    
    print(string.format("Similar messages similarity:"))
    print(string.format("  TF-IDF: %.3f", tfidf_sim1))
    print(string.format("  Embeddings: %.3f", emb_sim1))
    
    -- Test different messages: "Database problems" vs "Meeting time"
    local query2 = "Database problems need help"
    local target2 = "Meeting time today"
    
    local tfidf_query2 = tfidf:transform(query2)
    local tfidf_target2 = tfidf:transform(target2)
    local tfidf_sim2 = cosine_similarity(tfidf_query2, tfidf_target2)
    
    local emb_query2 = embeddings:transform(query2)
    local emb_target2 = embeddings:transform(target2)
    local emb_sim2 = cosine_similarity(emb_query2, emb_target2)
    
    print(string.format("Different messages similarity:"))
    print(string.format("  TF-IDF: %.3f", tfidf_sim2))
    print(string.format("  Embeddings: %.3f", emb_sim2))
    
    -- Performance summary
    print("\n=== PERFORMANCE SUMMARY ===")
    print(string.format("TF-IDF: %.2f ms processing, %d dimensions", 
        tfidf_time, tfidf.vocab_size))
    print(string.format("Simple Embeddings: %.2f ms processing, %d dimensions", 
        embedding_time, embeddings.dimension))
    
    -- Quality assessment
    print("\n=== QUALITY ASSESSMENT ===")
    local tfidf_quality = (tfidf_sim1 > tfidf_sim2) and "✓ Good" or "⚠ Poor"
    local emb_quality = (emb_sim1 > emb_sim2) and "✓ Good" or "⚠ Poor"
    
    print(string.format("TF-IDF semantic understanding: %s", tfidf_quality))
    print(string.format("Embeddings semantic understanding: %s", emb_quality))
    
    -- Recommendations
    print("\n=== RECOMMENDATIONS ===")
    if tfidf_time < 50 and tfidf_sim1 > 0.1 then
        print("✓ TF-IDF: Fast and suitable for Slack bot use case")
    else
        print("⚠ TF-IDF: May need optimization")
    end
    
    if embedding_time < 50 and emb_sim1 > 0.1 then
        print("✓ Simple Embeddings: Fast and suitable for Slack bot use case")
    else
        print("⚠ Simple Embeddings: May need optimization")
    end
    
    return {
        tfidf = {vectorizer = tfidf, time = tfidf_time, quality = tfidf_sim1},
        embeddings = {vectorizer = embeddings, time = embedding_time, quality = emb_sim1}
    }
end

-- ============================================================================
-- EXPORT
-- ============================================================================

return {
    LocalEmbeddings = LocalEmbeddings,
    TFIDFVectorizer = TFIDFVectorizer,
    SimpleEmbeddings = SimpleEmbeddings,
    benchmark = LocalEmbeddings.benchmark_approaches
}