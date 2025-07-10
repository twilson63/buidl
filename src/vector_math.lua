-- vector_math.lua
-- Core vector mathematics operations for the vector database

local VectorMath = {}

-- Calculate dot product of two vectors
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

-- Calculate magnitude (length) of a vector
function VectorMath.magnitude(vec)
    local sum_squares = 0
    for i = 1, #vec do
        sum_squares = sum_squares + (vec[i] * vec[i])
    end
    
    return math.sqrt(sum_squares)
end

-- Calculate cosine similarity between two vectors
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

-- Normalize a vector to unit length
function VectorMath.normalize(vec)
    local mag = VectorMath.magnitude(vec)
    if mag == 0 then
        return vec
    end
    
    local normalized = {}
    for i = 1, #vec do
        normalized[i] = vec[i] / mag
    end
    
    return normalized
end

-- Calculate Euclidean distance between two vectors
function VectorMath.euclidean_distance(vec1, vec2)
    if #vec1 ~= #vec2 then
        error("Vectors must have the same dimension")
    end
    
    local sum_squares = 0
    for i = 1, #vec1 do
        local diff = vec1[i] - vec2[i]
        sum_squares = sum_squares + (diff * diff)
    end
    
    return math.sqrt(sum_squares)
end

-- Add two vectors
function VectorMath.add(vec1, vec2)
    if #vec1 ~= #vec2 then
        error("Vectors must have the same dimension")
    end
    
    local result = {}
    for i = 1, #vec1 do
        result[i] = vec1[i] + vec2[i]
    end
    
    return result
end

-- Subtract two vectors
function VectorMath.subtract(vec1, vec2)
    if #vec1 ~= #vec2 then
        error("Vectors must have the same dimension")
    end
    
    local result = {}
    for i = 1, #vec1 do
        result[i] = vec1[i] - vec2[i]
    end
    
    return result
end

-- Multiply vector by scalar
function VectorMath.scalar_multiply(vec, scalar)
    local result = {}
    for i = 1, #vec do
        result[i] = vec[i] * scalar
    end
    
    return result
end

-- Check if vector is valid (all numbers, non-empty)
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

-- Get vector dimension
function VectorMath.dimension(vec)
    return #vec
end

return VectorMath