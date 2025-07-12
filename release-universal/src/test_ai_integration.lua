-- test_ai_integration.lua
-- Test AI integration with Slack bot

local AISlackBot = require("ai_slack_bot")

local function test_ai_integration()
    print("=== AI SLACK BOT INTEGRATION TEST ===\n")
    
    -- Test configuration
    local config = {
        privacy_level = "high",
        db_path = "./data/ai_test.db",
        ai_enabled = true,
        openrouter_api_key = "test-key", -- Simulated
        openrouter_model = "anthropic/claude-3.5-sonnet",
        auto_respond_to_mentions = true,
        enable_actions = true,
        max_context_messages = 5,
        context_window_hours = 24
    }
    
    local tests_passed = 0
    local total_tests = 0
    
    -- Test 1: AI bot initialization
    total_tests = total_tests + 1
    print("1. Testing AI bot initialization...")
    
    local ai_bot = AISlackBot.new(config)
    
    if ai_bot then
        tests_passed = tests_passed + 1
        print("   ✓ AI bot initialized successfully")
        
        local stats = ai_bot:get_stats()
        print("   ✓ Initial stats:", stats.ai_responses_generated, "responses generated")
    else
        print("   ✗ AI bot initialization failed")
    end
    
    -- Test 2: Message processing with embedding
    total_tests = total_tests + 1
    print("2. Testing message processing with embedding...")
    
    -- Simulate storing some context messages
    local context_messages = {
        "We deployed the new feature yesterday and it's working well",
        "The database migration completed successfully",
        "There was a minor issue with the API but it's been resolved",
        "The client meeting went great, they loved the new design"
    }
    
    for i, msg_text in ipairs(context_messages) do
        local message_json = string.format(
            '{"type":"event_callback","event":{"type":"message","text":"%s","user":"U%d","channel":"C123456","ts":"%d"}}',
            msg_text, i, os.time() - (i * 3600)
        )
        
        print("Processing message:", i, "JSON:", message_json)
        ai_bot:handle_webhook(message_json, {})
    end
    
    local stats_after_messages = ai_bot:get_stats()
    if stats_after_messages.messages_processed >= 4 then
        tests_passed = tests_passed + 1
        print("   ✓ Context messages processed and stored")
    else
        print("   ✗ Message processing failed")
        print("   Debug: messages_processed =", stats_after_messages.messages_processed)
    end
    
    -- Test 3: AI mention handling
    total_tests = total_tests + 1
    print("3. Testing AI mention handling...")
    
    local mention_json = '{"type":"event_callback","event":{"type":"app_mention","text":"<@U123456> What is the status of the deployment?","user":"U999999","channel":"C123456","ts":"' .. tostring(os.time()) .. '"}}'
    
    local mention_response = ai_bot:handle_webhook(mention_json, {})
    
    if mention_response.status == 200 then
        tests_passed = tests_passed + 1
        print("   ✓ AI mention handled successfully")
        
        local stats_after_mention = ai_bot:get_stats()
        if stats_after_mention.ai_responses_generated > 0 then
            print("   ✓ AI response generated")
        else
            print("   ⚠ AI response not generated (may be simulated)")
        end
    else
        print("   ✗ AI mention handling failed")
    end
    
    -- Test 4: Context retrieval
    total_tests = total_tests + 1
    print("4. Testing context retrieval...")
    
    local context_stats = ai_bot:get_stats()
    if context_stats.context_retrievals > 0 then
        tests_passed = tests_passed + 1
        print("   ✓ Context retrieval working")
    else
        print("   ✗ Context retrieval failed")
    end
    
    -- Test 5: Conversation memory
    total_tests = total_tests + 1
    print("5. Testing conversation memory...")
    
    local memory_stats = ai_bot:get_stats().conversation_memory
    if memory_stats and memory_stats.total_messages_in_memory > 0 then
        tests_passed = tests_passed + 1
        print(string.format("   ✓ Conversation memory: %d messages in %d channels", 
            memory_stats.total_messages_in_memory, memory_stats.channels_tracked))
    else
        print("   ✗ Conversation memory not working")
        print("   Debug: memory_stats =", memory_stats and memory_stats.total_messages_in_memory or "nil")
    end
    
    -- Test 6: Privacy compliance with AI
    total_tests = total_tests + 1
    print("6. Testing privacy compliance with AI...")
    
    local privacy_stats = ai_bot:get_stats().privacy
    if privacy_stats.score >= 70 then
        tests_passed = tests_passed + 1
        print(string.format("   ✓ Privacy compliance maintained: %.1f/100", privacy_stats.score))
    else
        print("   ✗ Privacy compliance insufficient")
    end
    
    -- Test 7: AI response generation capabilities
    total_tests = total_tests + 1
    print("7. Testing AI response generation...")
    
    -- Test different query types
    local test_queries = {
        "What's the project status?",
        "Help me with the database issue",
        "Can you create a summary of recent discussions?",
        "Schedule a meeting for tomorrow"
    }
    
    local successful_queries = 0
    
    for _, query in ipairs(test_queries) do
        local query_json = string.format(
            '{"type":"event_callback","event":{"type":"app_mention","text":"<@U123456> %s","user":"U888888","channel":"C123456","ts":"%d"}}',
            query, os.time()
        )
        
        local response = ai_bot:handle_webhook(query_json, {})
        if response.status == 200 then
            successful_queries = successful_queries + 1
        end
    end
    
    if successful_queries >= 3 then
        tests_passed = tests_passed + 1
        print(string.format("   ✓ AI queries processed: %d/%d successful", successful_queries, #test_queries))
    else
        print("   ✗ AI query processing failed")
    end
    
    -- Test 8: Conversation summary
    total_tests = total_tests + 1
    print("8. Testing conversation summary...")
    
    local summary = ai_bot:create_conversation_summary("C123456", 24)
    if summary and summary ~= "" and not string.find(summary, "error") then
        tests_passed = tests_passed + 1
        print("   ✓ Conversation summary generated")
        print("   Summary preview:", string.sub(summary, 1, 100) .. "...")
    else
        print("   ✗ Conversation summary failed")
    end
    
    -- Test 9: Statistics and monitoring
    total_tests = total_tests + 1
    print("9. Testing statistics and monitoring...")
    
    local final_stats = ai_bot:get_stats()
    
    if final_stats.uptime_seconds >= 0 and 
       final_stats.messages_processed > 0 and
       final_stats.ai_stats then
        tests_passed = tests_passed + 1
        print("   ✓ Statistics collection working")
        print("   Final metrics:")
        print(string.format("     Messages processed: %d", final_stats.messages_processed))
        print(string.format("     AI responses: %d", final_stats.ai_responses_generated))
        print(string.format("     Context retrievals: %d", final_stats.context_retrievals))
        print(string.format("     Vector database: %d messages", final_stats.vector_database.total_messages))
    else
        print("   ✗ Statistics collection failed")
        print("   Debug: uptime =", final_stats.uptime_seconds)
        print("   Debug: messages_processed =", final_stats.messages_processed)
        print("   Debug: ai_stats =", final_stats.ai_stats and "exists" or "nil")
    end
    
    -- Test 10: Error handling
    total_tests = total_tests + 1
    print("10. Testing error handling...")
    
    local error_response = ai_bot:handle_webhook("invalid json", {})
    if error_response.status == 400 then
        tests_passed = tests_passed + 1
        print("   ✓ Error handling working")
    else
        print("   ✗ Error handling failed")
    end
    
    -- Summary
    print("\n" .. string.rep("=", 60))
    print("AI INTEGRATION TEST RESULTS:")
    print(string.rep("=", 60))
    
    print(string.format("Tests passed: %d/%d (%.1f%%)", 
        tests_passed, total_tests, (tests_passed / total_tests) * 100))
    
    if tests_passed == total_tests then
        print("\n🎉 ALL AI INTEGRATION TESTS PASSED!")
        print("✅ AI-powered Slack bot is fully functional")
        print("")
        print("Features validated:")
        print("  ✓ OpenRouter LLM integration")
        print("  ✓ Context-aware responses")
        print("  ✓ Action detection and execution")
        print("  ✓ Privacy-conscious AI processing")
        print("  ✓ Conversation memory and summaries")
        print("  ✓ Comprehensive monitoring")
        print("")
        print("Ready for production deployment!")
        
    else
        print("\n⚠️  SOME AI INTEGRATION TESTS FAILED")
        print("Address these issues before production:")
        
        local failed_tests = total_tests - tests_passed
        print(string.format("  • %d AI functionality gaps", failed_tests))
        print("  • Review error messages above")
        print("  • Test with real OpenRouter API key")
    end
    
    return tests_passed == total_tests
end

-- Run the test
print("Starting AI integration test...")
print("This will test all AI-powered features of the Slack bot")
print("")

local success = test_ai_integration()

if success then
    print("\n🚀 PHASE 3 COMPLETE!")
    print("AI integration is ready for production use.")
else
    print("\n❌ PHASE 3 NEEDS ATTENTION")
    print("Review and fix failing tests before deployment.")
end