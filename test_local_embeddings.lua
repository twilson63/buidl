-- test_local_embeddings.lua
-- Test local embeddings implementation

local embedding_module = require("local_embeddings")

-- Run the benchmark
print("Testing local embeddings performance and quality...")
print("")

local results = embedding_module.benchmark()

print("")
print("Local embeddings testing complete!")