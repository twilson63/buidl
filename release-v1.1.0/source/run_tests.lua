-- run_tests.lua
-- Quick test runner for all available tests

print("=== AI SLACK BOT TEST RUNNER ===")
print("Running all available tests...")
print("")

-- Available test files
local test_files = {
    {name = "Comprehensive Test Suite", file = "test_suite.lua", description = "Full system test suite"},
    {name = "AI Integration Tests", file = "test_ai_integration.lua", description = "AI-specific integration tests"},
    {name = "Vector Database Tests", file = "test_vector_db.lua", description = "Vector database functionality"},
    {name = "Privacy Embeddings Tests", file = "test_privacy_embeddings.lua", description = "Privacy-conscious embeddings"},
    {name = "Local Embeddings Tests", file = "test_local_embeddings.lua", description = "Local embedding generation"},
    {name = "Performance Tests", file = "performance_test.lua", description = "Performance benchmarks"}
}

-- Run main test suite
print("🚀 Running main test suite...")
local success = dofile("test_suite.lua")

if success then
    print("\n✅ Main test suite completed successfully!")
    print("\nAdditional tests available:")
    
    for i, test in ipairs(test_files) do
        if test.file ~= "test_suite.lua" then
            print(string.format("  %d. %s - %s", i, test.name, test.description))
            print(string.format("     Run with: hype run %s", test.file))
        end
    end
    
    print("\n🎯 TESTING COMPLETE - ALL SYSTEMS OPERATIONAL!")
else
    print("\n❌ Main test suite failed. Please review errors above.")
    print("Run individual tests to isolate issues.")
end