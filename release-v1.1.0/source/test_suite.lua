-- test_suite.lua
-- Comprehensive test suite for AI Slack Bot

local Config = require("config")

-- Test suite framework
local TestSuite = {}

function TestSuite.new()
    local suite = {
        tests = {},
        results = {
            passed = 0,
            failed = 0,
            errors = 0,
            skipped = 0
        },
        start_time = nil,
        end_time = nil
    }
    
    setmetatable(suite, {__index = TestSuite})
    return suite
end

function TestSuite:add_test(name, test_func, description)
    table.insert(self.tests, {
        name = name,
        func = test_func,
        description = description or ""
    })
end

function TestSuite:run()
    print("=== AI SLACK BOT TEST SUITE ===")
    print("Running comprehensive tests...")
    print("")
    
    self.start_time = os.clock()
    
    for i, test in ipairs(self.tests) do
        print(string.format("[%d/%d] %s", i, #self.tests, test.name))
        if test.description ~= "" then
            print("  " .. test.description)
        end
        
        local success, result = pcall(test.func)
        
        if success then
            if result then
                print("  ✅ PASSED")
                self.results.passed = self.results.passed + 1
            else
                print("  ❌ FAILED")
                self.results.failed = self.results.failed + 1
            end
        else
            print("  💥 ERROR: " .. tostring(result))
            self.results.errors = self.results.errors + 1
        end
        
        print("")
    end
    
    self.end_time = os.clock()
    self:print_summary()
end

function TestSuite:print_summary()
    local total = self.results.passed + self.results.failed + self.results.errors + self.results.skipped
    local duration = self.end_time - self.start_time
    
    print("=" .. string.rep("=", 50))
    print("TEST SUITE SUMMARY")
    print("=" .. string.rep("=", 50))
    print(string.format("Total tests: %d", total))
    print(string.format("Passed: %d", self.results.passed))
    print(string.format("Failed: %d", self.results.failed))
    print(string.format("Errors: %d", self.results.errors))
    print(string.format("Duration: %.2f seconds", duration))
    print("")
    
    local pass_rate = total > 0 and (self.results.passed / total * 100) or 0
    print(string.format("Pass rate: %.1f%%", pass_rate))
    
    if self.results.failed == 0 and self.results.errors == 0 then
        print("🎉 ALL TESTS PASSED!")
    else
        print("⚠️  Some tests failed. Review output above.")
    end
end

-- Individual test functions
local function test_configuration_system()
    print("  Testing configuration loading...")
    
    -- Test default configuration
    local config = Config.get_config()
    if not config then
        print("  ❌ Failed to load default configuration")
        return false
    end
    
    -- Test configuration validation with missing keys
    local empty_config = {
        slack_bot_token = nil,
        slack_signing_secret = nil,
        openrouter_api_key = nil,
        ai_enabled = true,
        privacy_level = "high",
        ai_conversation_style = "helpful"
    }
    local errors = Config.validate_config(empty_config)
    if #errors == 0 then
        print("  ❌ Expected validation errors for missing API keys")
        return false
    end
    
    -- Test environment variable parsing
    local test_config = Config.get_config({
        slack_bot_token = "test-token",
        slack_signing_secret = "test-secret",
        openrouter_api_key = "test-key"
    })
    
    local validation_errors = Config.validate_config(test_config)
    if #validation_errors > 0 then
        print("  ❌ Validation failed for valid test configuration")
        return false
    end
    
    print("  ✅ Configuration system working")
    return true
end

local function test_vector_database()
    print("  Testing vector database operations...")
    
    local VectorDB = require("vector_db_bundle")
    
    -- Test database creation
    local db = VectorDB.new("./test_data/test_vectors.db")
    if not db then
        print("  ❌ Failed to create vector database")
        return false
    end
    
    -- Test vector insertion
    local test_entry = {
        id = "test_vector_1",
        vector = {0.1, 0.2, 0.3, 0.4},
        metadata = {
            text = "This is a test message",
            timestamp = os.time()
        }
    }
    
    local success, error_msg = db:insert(test_entry)
    if not success then
        print("  ❌ Failed to insert vector: " .. (error_msg or "unknown error"))
        return false
    end
    
    -- Test vector search
    local results = db:search({
        vector = {0.1, 0.2, 0.3, 0.4},
        limit = 5,
        threshold = 0.5
    })
    
    if not results or #results == 0 then
        print("  ❌ Failed to search vectors")
        return false
    end
    
    -- Test database statistics
    local stats = db:get_stats()
    if not stats or stats.count == 0 then
        print("  ❌ Database statistics not working")
        return false
    end
    
    print("  ✅ Vector database working")
    return true
end

local function test_privacy_embeddings()
    print("  Testing privacy-conscious embeddings...")
    
    local PrivacyEmbeddings = require("privacy_conscious_embeddings")
    
    -- Test high privacy level
    local high_privacy = PrivacyEmbeddings.new({privacy_level = "high"})
    if not high_privacy then
        print("  ❌ Failed to create high privacy embeddings")
        return false
    end
    
    local result = high_privacy:get_embedding("This is a test message")
    if not result or not result.vector or #result.vector == 0 then
        print("  ❌ Failed to generate embedding")
        return false
    end
    
    if result.method ~= "simple_local" then
        print("  ❌ High privacy should use local embeddings")
        return false
    end
    
    -- Test privacy report
    local privacy_report = high_privacy:get_privacy_report()
    if not privacy_report or not privacy_report.statistics then
        print("  ❌ Privacy report not working")
        return false
    end
    
    print("  ✅ Privacy embeddings working")
    return true
end

local function test_openrouter_client()
    print("  Testing OpenRouter client (simulation)...")
    
    local OpenRouterClient = require("openrouter_client")
    
    -- Test client creation
    local client = OpenRouterClient.new({
        api_key = "test-key"
    })
    
    if not client then
        print("  ❌ Failed to create OpenRouter client")
        return false
    end
    
    -- Test message creation
    local test_messages = {
        OpenRouterClient.create_system_message("You are a helpful assistant"),
        OpenRouterClient.create_user_message("Hello, how are you?")
    }
    
    if #test_messages ~= 2 then
        print("  ❌ Failed to create test messages")
        return false
    end
    
    -- Test simulated API call
    local response, error_msg = client:chat_completion(test_messages)
    if not response then
        print("  ❌ Failed to get API response: " .. (error_msg or "unknown error"))
        return false
    end
    
    -- Test statistics
    local stats = client:get_stats()
    if not stats or stats.requests_made == 0 then
        print("  ❌ Client statistics not working")
        return false
    end
    
    print("  ✅ OpenRouter client working")
    return true
end

local function test_ai_response_generator()
    print("  Testing AI response generator...")
    
    local AIResponseGenerator = require("ai_response_generator")
    
    -- Test generator creation
    local generator = AIResponseGenerator.new({
        openrouter_api_key = "test-key",
        openrouter_model = "anthropic/claude-3.5-sonnet"
    })
    
    if not generator then
        print("  ❌ Failed to create AI response generator")
        return false
    end
    
    -- Test response generation
    local test_context = {
        {
            metadata = {
                text = "The project is going well",
                user_id = "user1",
                timestamp = os.time() - 3600
            }
        }
    }
    
    local response, error_msg = generator:generate_response(
        "What's the project status?", 
        test_context,
        {channel = "general", user_id = "user2"}
    )
    
    if not response then
        print("  ❌ Failed to generate AI response: " .. (error_msg or "unknown error"))
        return false
    end
    
    if not response.response or response.response == "" then
        print("  ❌ AI response is empty")
        return false
    end
    
    -- Test action detection
    if not response.actions then
        print("  ❌ Action detection not working")
        return false
    end
    
    print("  ✅ AI response generator working")
    return true
end

local function test_slack_integration()
    print("  Testing Slack integration...")
    
    local AISlackBot = require("ai_slack_bot")
    
    -- Test bot creation with test config
    local bot = AISlackBot.new({
        slack_bot_token = "test-token",
        slack_signing_secret = "test-secret",
        openrouter_api_key = "test-key",
        db_path = "./test_data/test_slack.db"
    })
    
    if not bot then
        print("  ❌ Failed to create Slack bot")
        return false
    end
    
    -- Test webhook handling
    local test_webhook = '{"type":"url_verification","challenge":"test-challenge"}'
    local response = bot:handle_webhook(test_webhook, {})
    
    if not response or response.status ~= 200 then
        print("  ❌ Webhook handling failed")
        return false
    end
    
    -- Test message processing
    local message_webhook = '{"type":"event_callback","event":{"type":"message","text":"Hello world","user":"U123","channel":"C123","ts":"' .. os.time() .. '"}}'
    local msg_response = bot:handle_webhook(message_webhook, {})
    
    if not msg_response or msg_response.status ~= 200 then
        print("  ❌ Message processing failed")
        return false
    end
    
    -- Test statistics
    local stats = bot:get_stats()
    if not stats or not stats.uptime_seconds then
        print("  ❌ Bot statistics not working")
        return false
    end
    
    print("  ✅ Slack integration working")
    return true
end

local function test_end_to_end_flow()
    print("  Testing end-to-end AI conversation flow...")
    
    local AISlackBot = require("ai_slack_bot")
    
    -- Create bot with test configuration
    local bot = AISlackBot.new({
        slack_bot_token = "test-token",
        slack_signing_secret = "test-secret",
        openrouter_api_key = "test-key",
        db_path = "./test_data/test_e2e.db",
        privacy_level = "high"
    })
    
    if not bot then
        print("  ❌ Failed to create bot for E2E test")
        return false
    end
    
    -- 1. Process some context messages
    local context_messages = {
        "We deployed the new feature yesterday",
        "The API is working well",
        "Database migration completed"
    }
    
    for i, msg in ipairs(context_messages) do
        local webhook = string.format(
            '{"type":"event_callback","event":{"type":"message","text":"%s","user":"U%d","channel":"C123","ts":"%d"}}',
            msg, i, os.time() - (i * 3600)
        )
        bot:handle_webhook(webhook, {})
    end
    
    -- 2. Send AI mention
    local mention_webhook = '{"type":"event_callback","event":{"type":"app_mention","text":"<@U123> What is the deployment status?","user":"U999","channel":"C123","ts":"' .. os.time() .. '"}}'
    local mention_response = bot:handle_webhook(mention_webhook, {})
    
    if not mention_response or mention_response.status ~= 200 then
        print("  ❌ AI mention handling failed")
        return false
    end
    
    -- 3. Check final statistics
    local final_stats = bot:get_stats()
    if not final_stats or final_stats.messages_processed < 3 then
        print("  ❌ Messages not processed correctly")
        return false
    end
    
    if not final_stats.ai_responses_generated or final_stats.ai_responses_generated < 1 then
        print("  ❌ AI responses not generated")
        return false
    end
    
    print("  ✅ End-to-end flow working")
    return true
end

local function test_error_handling()
    print("  Testing error handling...")
    
    local AISlackBot = require("ai_slack_bot")
    
    -- Test invalid configuration
    local invalid_bot = AISlackBot.new({
        privacy_level = "invalid_level"
    })
    
    if invalid_bot then
        print("  ❌ Should have failed with invalid configuration")
        return false
    end
    
    -- Test valid bot with invalid webhook
    local bot = AISlackBot.new({
        slack_bot_token = "test-token",
        slack_signing_secret = "test-secret",
        openrouter_api_key = "test-key",
        db_path = "./test_data/test_error.db"
    })
    
    if not bot then
        print("  ❌ Failed to create bot for error testing")
        return false
    end
    
    -- Test invalid JSON
    local error_response = bot:handle_webhook("invalid json", {})
    if not error_response or error_response.status ~= 400 then
        print("  ❌ Invalid JSON not handled correctly")
        return false
    end
    
    print("  ✅ Error handling working")
    return true
end

-- Main test suite execution
local function run_test_suite()
    local suite = TestSuite.new()
    
    -- Add all tests
    suite:add_test("Configuration System", test_configuration_system, "Tests config loading, validation, and environment variables")
    suite:add_test("Vector Database", test_vector_database, "Tests vector storage, search, and statistics")
    suite:add_test("Privacy Embeddings", test_privacy_embeddings, "Tests privacy-conscious embedding generation")
    suite:add_test("OpenRouter Client", test_openrouter_client, "Tests OpenRouter API client (simulated)")
    suite:add_test("AI Response Generator", test_ai_response_generator, "Tests AI response generation and action detection")
    suite:add_test("Slack Integration", test_slack_integration, "Tests Slack webhook handling and message processing")
    suite:add_test("End-to-End Flow", test_end_to_end_flow, "Tests complete conversation flow with AI")
    suite:add_test("Error Handling", test_error_handling, "Tests error handling and validation")
    
    -- Create test data directory
    os.execute("mkdir -p ./test_data")
    
    -- Run all tests
    suite:run()
    
    -- Cleanup test data
    os.execute("rm -rf ./test_data")
    
    -- Return success status
    return suite.results.failed == 0 and suite.results.errors == 0
end

-- Run the test suite
return run_test_suite()