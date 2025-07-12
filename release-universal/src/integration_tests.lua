-- integration_tests.lua
-- Comprehensive integration tests for Slack bot

local SlackBot = require("slack_integration")

-- Test utilities
local TestUtils = {}

function TestUtils.create_test_bot(config)
    local default_config = {
        privacy_level = "high",
        use_enterprise_zdr = false,
        db_path = "./data/test_integration.db",
        response_enabled = true,
        max_context_messages = 3,
        port = 8081,
        webhook_path = "/test/slack/events"
    }
    
    -- Merge config
    for key, value in pairs(config or {}) do
        default_config[key] = value
    end
    
    return SlackBot.new(default_config)
end

function TestUtils.create_slack_message(overrides)
    local base_message = {
        type = "message",
        text = "Hello world",
        user = "U1234567890",
        channel = "C1234567890",
        ts = tostring(os.time()),
        team = "T1234567890"
    }
    
    for key, value in pairs(overrides or {}) do
        base_message[key] = value
    end
    
    return base_message
end

function TestUtils.create_slack_event(event_data)
    return {
        type = "event_callback",
        event = event_data,
        team_id = "T1234567890",
        api_app_id = "A1234567890"
    }
end

function TestUtils.create_mention_event(text, channel)
    return {
        type = "app_mention",
        text = text or "<@U1234567890> help me",
        user = "U1234567890",
        channel = channel or "C1234567890",
        ts = tostring(os.time())
    }
end

function TestUtils.simulate_json_request(data)
    -- Simple JSON serialization for testing
    local json_parts = {}
    table.insert(json_parts, '{"type":"' .. data.type .. '"')
    
    if data.challenge then
        table.insert(json_parts, ',"challenge":"' .. data.challenge .. '"')
    end
    
    if data.event then
        table.insert(json_parts, ',"event":{"type":"' .. data.event.type .. '"')
        table.insert(json_parts, ',"text":"' .. (data.event.text or "") .. '"')
        table.insert(json_parts, ',"user":"' .. (data.event.user or "") .. '"')
        table.insert(json_parts, ',"channel":"' .. (data.event.channel or "") .. '"')
        table.insert(json_parts, ',"ts":"' .. (data.event.ts or "") .. '"')
        table.insert(json_parts, '}')
    end
    
    table.insert(json_parts, '}')
    return table.concat(json_parts)
end

-- Integration test suite
local IntegrationTests = {}

function IntegrationTests.test_webhook_url_verification()
    print("=== TEST: Webhook URL Verification ===")
    
    local bot = TestUtils.create_test_bot()
    
    -- Test URL verification challenge
    local challenge_data = {
        type = "url_verification",
        challenge = "test_challenge_123"
    }
    
    local json_body = TestUtils.simulate_json_request(challenge_data)
    local response = bot:handle_webhook(json_body, {})
    
    local success = (response.status == 200 and response.body == "test_challenge_123")
    print(success and "✓ URL verification passed" or "✗ URL verification failed")
    
    return success
end

function IntegrationTests.test_message_processing_pipeline()
    print("\n=== TEST: Message Processing Pipeline ===")
    
    local bot = TestUtils.create_test_bot()
    local tests_passed = 0
    local total_tests = 0
    
    -- Test 1: Regular message processing
    total_tests = total_tests + 1
    local message = TestUtils.create_slack_message({
        text = "Hello team, how is everyone doing today?",
        user = "U1111111111",
        channel = "C1111111111",
        ts = tostring(os.time())
    })
    
    local event_data = TestUtils.create_slack_event(message)
    local json_body = TestUtils.simulate_json_request(event_data)
    
    local response = bot:handle_webhook(json_body, {})
    
    if response.status == 200 then
        tests_passed = tests_passed + 1
        print("✓ Regular message processing")
    else
        print("✗ Regular message processing failed")
    end
    
    -- Test 2: Message with PII
    total_tests = total_tests + 1
    local pii_message = TestUtils.create_slack_message({
        text = "My email is john.doe@company.com for contact",
        user = "U2222222222",
        channel = "C1111111111",
        ts = tostring(os.time())
    })
    
    local pii_event = TestUtils.create_slack_event(pii_message)
    local pii_json = TestUtils.simulate_json_request(pii_event)
    
    local pii_response = bot:handle_webhook(pii_json, {})
    
    if pii_response.status == 200 then
        tests_passed = tests_passed + 1
        print("✓ PII message processing")
    else
        print("✗ PII message processing failed")
    end
    
    -- Test 3: Check database storage
    total_tests = total_tests + 1
    local stats = bot:get_stats()
    
    if stats.messages_processed >= 2 then
        tests_passed = tests_passed + 1
        print("✓ Database storage verified")
    else
        print("✗ Database storage failed")
    end
    
    print(string.format("Message processing: %d/%d tests passed", tests_passed, total_tests))
    return tests_passed == total_tests
end

function IntegrationTests.test_mention_handling()
    print("\n=== TEST: Mention Handling ===")
    
    local bot = TestUtils.create_test_bot()
    local tests_passed = 0
    local total_tests = 0
    
    -- Test 1: App mention processing
    total_tests = total_tests + 1
    local mention = TestUtils.create_mention_event(
        "<@U1234567890> What was discussed about the project?",
        "C1111111111"
    )
    
    local mention_event = TestUtils.create_slack_event(mention)
    local mention_json = TestUtils.simulate_json_request(mention_event)
    
    local mention_response = bot:handle_webhook(mention_json, {})
    
    if mention_response.status == 200 then
        tests_passed = tests_passed + 1
        print("✓ Mention processing")
    else
        print("✗ Mention processing failed")
    end
    
    -- Test 2: Check mention statistics
    total_tests = total_tests + 1
    local stats = bot:get_stats()
    
    if stats.mentions_handled >= 1 then
        tests_passed = tests_passed + 1
        print("✓ Mention statistics updated")
    else
        print("✗ Mention statistics failed")
    end
    
    print(string.format("Mention handling: %d/%d tests passed", tests_passed, total_tests))
    return tests_passed == total_tests
end

function IntegrationTests.test_privacy_controls()
    print("\n=== TEST: Privacy Controls ===")
    
    local tests_passed = 0
    local total_tests = 0
    
    -- Test different privacy levels
    local privacy_levels = {"high", "medium", "low"}
    
    for _, level in ipairs(privacy_levels) do
        total_tests = total_tests + 1
        
        local bot = TestUtils.create_test_bot({
            privacy_level = level,
            db_path = "./data/test_privacy_" .. level .. ".db"
        })
        
        -- Process a message with PII
        local pii_message = TestUtils.create_slack_message({
            text = "The API key is abc123xyz and password is secret456",
            user = "U3333333333",
            channel = "C2222222222"
        })
        
        local pii_event = TestUtils.create_slack_event(pii_message)
        local pii_json = TestUtils.simulate_json_request(pii_event)
        
        local response = bot:handle_webhook(pii_json, {})
        
        if response.status == 200 then
            local stats = bot:get_stats()
            local expected_score = (level == "high") and 80 or 
                                  (level == "medium") and 60 or 40
            
            if stats.privacy.score >= expected_score - 10 then
                tests_passed = tests_passed + 1
                print(string.format("✓ Privacy level %s (score: %.1f)", level, stats.privacy.score))
            else
                print(string.format("✗ Privacy level %s failed (score: %.1f)", level, stats.privacy.score))
            end
        else
            print(string.format("✗ Privacy level %s webhook failed", level))
        end
    end
    
    print(string.format("Privacy controls: %d/%d tests passed", tests_passed, total_tests))
    return tests_passed == total_tests
end

function IntegrationTests.test_error_handling()
    print("\n=== TEST: Error Handling ===")
    
    local bot = TestUtils.create_test_bot()
    local tests_passed = 0
    local total_tests = 0
    
    -- Test 1: Invalid JSON
    total_tests = total_tests + 1
    local invalid_response = bot:handle_webhook("invalid json", {})
    
    if invalid_response.status == 400 then
        tests_passed = tests_passed + 1
        print("✓ Invalid JSON handled")
    else
        print("✗ Invalid JSON handling failed")
    end
    
    -- Test 2: Empty body
    total_tests = total_tests + 1
    local empty_response = bot:handle_webhook("", {})
    
    if empty_response.status == 400 then
        tests_passed = tests_passed + 1
        print("✓ Empty body handled")
    else
        print("✗ Empty body handling failed")
    end
    
    -- Test 3: Malformed event
    total_tests = total_tests + 1
    local malformed_json = '{"type":"event_callback"}'
    local malformed_response = bot:handle_webhook(malformed_json, {})
    
    if malformed_response.status == 400 then
        tests_passed = tests_passed + 1
        print("✓ Malformed event handled")
    else
        print("✗ Malformed event handling failed")
    end
    
    print(string.format("Error handling: %d/%d tests passed", tests_passed, total_tests))
    return tests_passed == total_tests
end

function IntegrationTests.test_context_building()
    print("\n=== TEST: Context Building ===")
    
    local bot = TestUtils.create_test_bot()
    local tests_passed = 0
    local total_tests = 0
    
    -- Insert some historical messages
    local history_messages = {
        "We discussed the new feature yesterday",
        "The database migration is scheduled for next week",
        "Please review the pull request when you have time",
        "The client meeting went well"
    }
    
    for i, text in ipairs(history_messages) do
        local message = TestUtils.create_slack_message({
            text = text,
            user = "U444444444" .. i,
            channel = "C3333333333",
            ts = tostring(os.time() - (i * 3600)) -- 1 hour apart
        })
        
        local event = TestUtils.create_slack_event(message)
        local json = TestUtils.simulate_json_request(event)
        bot:handle_webhook(json, {})
    end
    
    -- Test context retrieval
    total_tests = total_tests + 1
    local mention = TestUtils.create_mention_event(
        "<@U1234567890> What was discussed about the feature?",
        "C3333333333"
    )
    
    local mention_event = TestUtils.create_slack_event(mention)
    local mention_json = TestUtils.simulate_json_request(mention_event)
    
    local response = bot:handle_webhook(mention_json, {})
    
    if response.status == 200 then
        local stats = bot:get_stats()
        if stats.vector_database.total_messages >= 4 then
            tests_passed = tests_passed + 1
            print("✓ Context building with historical messages")
        else
            print("✗ Context building failed - insufficient messages")
        end
    else
        print("✗ Context building failed - webhook error")
    end
    
    print(string.format("Context building: %d/%d tests passed", tests_passed, total_tests))
    return tests_passed == total_tests
end

function IntegrationTests.test_performance_under_load()
    print("\n=== TEST: Performance Under Load ===")
    
    local bot = TestUtils.create_test_bot({
        db_path = "./data/test_load.db"
    })
    
    local tests_passed = 0
    local total_tests = 0
    
    -- Test 1: Process many messages quickly
    total_tests = total_tests + 1
    local start_time = os.clock()
    local message_count = 100
    
    for i = 1, message_count do
        local message = TestUtils.create_slack_message({
            text = "Test message number " .. i,
            user = "U555555555",
            channel = "C4444444444",
            ts = tostring(os.time() + i)
        })
        
        local event = TestUtils.create_slack_event(message)
        local json = TestUtils.simulate_json_request(event)
        bot:handle_webhook(json, {})
    end
    
    local processing_time = (os.clock() - start_time) * 1000
    local messages_per_second = message_count / (processing_time / 1000)
    
    print(string.format("Processed %d messages in %.2f ms (%.1f msg/sec)", 
        message_count, processing_time, messages_per_second))
    
    if messages_per_second > 20 then
        tests_passed = tests_passed + 1
        print("✓ Performance under load acceptable")
    else
        print("✗ Performance under load failed")
    end
    
    -- Test 2: Memory usage reasonable
    total_tests = total_tests + 1
    local stats = bot:get_stats()
    
    if stats.vector_database.storage_mb < 10 then
        tests_passed = tests_passed + 1
        print(string.format("✓ Memory usage reasonable (%.2f MB)", stats.vector_database.storage_mb))
    else
        print(string.format("✗ Memory usage too high (%.2f MB)", stats.vector_database.storage_mb))
    end
    
    print(string.format("Performance: %d/%d tests passed", tests_passed, total_tests))
    return tests_passed == total_tests
end

-- Main test runner
function IntegrationTests.run_all_tests()
    print("=== SLACK BOT INTEGRATION TEST SUITE ===")
    print("Testing all critical functionality before Phase 3\n")
    
    local test_results = {}
    local test_functions = {
        {"URL Verification", IntegrationTests.test_webhook_url_verification},
        {"Message Processing", IntegrationTests.test_message_processing_pipeline},
        {"Mention Handling", IntegrationTests.test_mention_handling},
        {"Privacy Controls", IntegrationTests.test_privacy_controls},
        {"Error Handling", IntegrationTests.test_error_handling},
        {"Context Building", IntegrationTests.test_context_building},
        {"Performance Load", IntegrationTests.test_performance_under_load}
    }
    
    local passed_tests = 0
    local total_tests = #test_functions
    
    for _, test_info in ipairs(test_functions) do
        local test_name = test_info[1]
        local test_func = test_info[2]
        
        local success = test_func()
        test_results[test_name] = success
        
        if success then
            passed_tests = passed_tests + 1
        end
    end
    
    -- Final summary
    print("\n" .. string.rep("=", 60))
    print("INTEGRATION TEST RESULTS:")
    print(string.rep("=", 60))
    
    for test_name, result in pairs(test_results) do
        local status = result and "✓ PASS" or "✗ FAIL"
        print(string.format("%-20s: %s", test_name, status))
    end
    
    print(string.rep("-", 60))
    print(string.format("TOTAL: %d/%d tests passed (%.1f%%)", 
        passed_tests, total_tests, (passed_tests / total_tests) * 100))
    
    if passed_tests == total_tests then
        print("\n🎉 ALL TESTS PASSED - READY FOR PHASE 3!")
        print("The Slack bot integration is solid and production-ready.")
    else
        print("\n⚠️  SOME TESTS FAILED - REVIEW BEFORE PHASE 3")
        print("Address failing tests before proceeding to AI integration.")
    end
    
    return passed_tests == total_tests
end

-- Run the test suite
return IntegrationTests.run_all_tests()