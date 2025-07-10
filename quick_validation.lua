-- quick_validation.lua
-- Quick validation tests for Phase 3 readiness

local SlackBot = require("slack_integration")

local function quick_validation()
    print("=== QUICK VALIDATION FOR PHASE 3 READINESS ===\n")
    
    local tests_passed = 0
    local total_tests = 0
    
    -- Test 1: Bot initialization
    total_tests = total_tests + 1
    print("1. Testing bot initialization...")
    local bot = SlackBot.new({
        privacy_level = "high",
        db_path = "./data/validation_test.db",
        response_enabled = true
    })
    
    if bot then
        tests_passed = tests_passed + 1
        print("   ✓ Bot initialized successfully")
    else
        print("   ✗ Bot initialization failed")
    end
    
    -- Test 2: URL verification
    total_tests = total_tests + 1
    print("2. Testing URL verification...")
    local challenge_json = '{"type":"url_verification","challenge":"test123"}'
    local response = bot:handle_webhook(challenge_json, {})
    
    if response.status == 200 and response.body == "test123" then
        tests_passed = tests_passed + 1
        print("   ✓ URL verification working")
    else
        print("   ✗ URL verification failed")
    end
    
    -- Test 3: Message processing
    total_tests = total_tests + 1
    print("3. Testing message processing...")
    local message_json = '{"type":"event_callback","event":{"type":"message","text":"Hello world","user":"U123","channel":"C123","ts":"1234567890"}}'
    local msg_response = bot:handle_webhook(message_json, {})
    
    if msg_response.status == 200 then
        tests_passed = tests_passed + 1
        print("   ✓ Message processing working")
    else
        print("   ✗ Message processing failed")
    end
    
    -- Test 4: Privacy controls
    total_tests = total_tests + 1
    print("4. Testing privacy controls...")
    local stats = bot:get_stats()
    
    if stats.privacy and stats.privacy.score >= 70 then
        tests_passed = tests_passed + 1
        print("   ✓ Privacy controls active (score: " .. stats.privacy.score .. "/100)")
    else
        print("   ✗ Privacy controls insufficient")
    end
    
    -- Test 5: Vector database
    total_tests = total_tests + 1
    print("5. Testing vector database...")
    local vector_stats = bot:get_stats().vector_database
    
    if vector_stats and vector_stats.total_messages >= 0 then
        tests_passed = tests_passed + 1
        print("   ✓ Vector database operational")
    else
        print("   ✗ Vector database failed")
    end
    
    -- Test 6: Error handling
    total_tests = total_tests + 1
    print("6. Testing error handling...")
    local error_response = bot:handle_webhook("invalid json", {})
    
    if error_response.status == 400 then
        tests_passed = tests_passed + 1
        print("   ✓ Error handling working")
    else
        print("   ✗ Error handling failed")
    end
    
    -- Test 7: Statistics
    total_tests = total_tests + 1
    print("7. Testing statistics...")
    local full_stats = bot:get_stats()
    
    if full_stats.messages_processed ~= nil and full_stats.uptime_seconds ~= nil then
        tests_passed = tests_passed + 1
        print("   ✓ Statistics collection working")
    else
        print("   ✗ Statistics collection failed")
    end
    
    -- Summary
    print("\n" .. string.rep("=", 50))
    print("VALIDATION SUMMARY:")
    print(string.rep("=", 50))
    print(string.format("Tests passed: %d/%d (%.1f%%)", 
        tests_passed, total_tests, (tests_passed / total_tests) * 100))
    
    if tests_passed == total_tests then
        print("\n🎉 ALL VALIDATIONS PASSED!")
        print("✅ Slack bot is ready for Phase 3 (AI Integration)")
        print("")
        print("Core functionality verified:")
        print("  ✓ Webhook handling")
        print("  ✓ Message processing")
        print("  ✓ Privacy controls")
        print("  ✓ Vector database")
        print("  ✓ Error handling")
        print("  ✓ Statistics")
        print("")
        print("Ready to proceed with:")
        print("  • OpenRouter LLM integration")
        print("  • Context-aware response generation")
        print("  • Action execution system")
        
    else
        print("\n⚠️  SOME VALIDATIONS FAILED")
        print("Address these issues before Phase 3:")
        
        local failed_tests = total_tests - tests_passed
        print(string.format("  • %d critical functionality gaps", failed_tests))
        print("  • Review error messages above")
        print("  • Fix issues before AI integration")
    end
    
    return tests_passed == total_tests
end

-- Run validation
return quick_validation()