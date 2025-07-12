# Testing Guide

The AI Slack Bot project includes a comprehensive test suite to verify all functionality works correctly.

## Quick Testing

### Run All Tests
```bash
hype run test_suite.lua
```

### Run Test Runner
```bash
hype run run_tests.lua
```

## Test Suite Overview

### Main Test Suite (`test_suite.lua`)
Comprehensive test suite covering all major components:

1. **Configuration System** - Tests config loading, validation, and environment variables
2. **Vector Database** - Tests vector storage, search, and statistics  
3. **Privacy Embeddings** - Tests privacy-conscious embedding generation
4. **OpenRouter Client** - Tests OpenRouter API client (simulated)
5. **AI Response Generator** - Tests AI response generation and action detection
6. **Slack Integration** - Tests Slack webhook handling and message processing
7. **End-to-End Flow** - Tests complete conversation flow with AI
8. **Error Handling** - Tests error handling and validation

### Individual Test Files

| Test File | Description | Command |
|-----------|-------------|---------|
| `test_suite.lua` | Main comprehensive test suite | `hype run test_suite.lua` |
| `test_ai_integration.lua` | AI integration tests | `hype run test_ai_integration.lua` |
| `test_vector_db.lua` | Vector database tests | `hype run test_vector_db.lua` |
| `test_privacy_embeddings.lua` | Privacy embeddings tests | `hype run test_privacy_embeddings.lua` |
| `test_local_embeddings.lua` | Local embeddings tests | `hype run test_local_embeddings.lua` |
| `performance_test.lua` | Performance benchmarks | `hype run performance_test.lua` |

## Test Results

### Successful Test Run
```
=== AI SLACK BOT TEST SUITE ===
Running comprehensive tests...

[1/8] Configuration System ✅ PASSED
[2/8] Vector Database ✅ PASSED
[3/8] Privacy Embeddings ✅ PASSED
[4/8] OpenRouter Client ✅ PASSED
[5/8] AI Response Generator ✅ PASSED
[6/8] Slack Integration ✅ PASSED
[7/8] End-to-End Flow ✅ PASSED
[8/8] Error Handling ✅ PASSED

===================================================
TEST SUITE SUMMARY
===================================================
Total tests: 8
Passed: 8
Failed: 0
Errors: 0
Duration: 1.28 seconds

Pass rate: 100.0%
🎉 ALL TESTS PASSED!
```

## What Each Test Validates

### 1. Configuration System
- ✅ Default configuration loading
- ✅ Environment variable parsing
- ✅ Configuration validation
- ✅ Missing API key detection
- ✅ Invalid configuration rejection

### 2. Vector Database
- ✅ Database creation and initialization
- ✅ Vector insertion and storage
- ✅ Vector search with similarity matching
- ✅ Database statistics and metadata
- ✅ LSH indexing functionality

### 3. Privacy Embeddings
- ✅ High privacy level enforcement
- ✅ Local embedding generation
- ✅ Privacy report generation
- ✅ PII detection and filtering
- ✅ Privacy compliance scoring

### 4. OpenRouter Client
- ✅ Client initialization
- ✅ Message formatting
- ✅ API request simulation
- ✅ Response parsing
- ✅ Usage statistics tracking

### 5. AI Response Generator
- ✅ Response generation with context
- ✅ Action detection in responses
- ✅ Conversation context building
- ✅ Token usage tracking
- ✅ Model configuration

### 6. Slack Integration
- ✅ Bot initialization
- ✅ Webhook handling
- ✅ Message processing
- ✅ Event parsing
- ✅ Statistics collection

### 7. End-to-End Flow
- ✅ Complete conversation flow
- ✅ Context message processing
- ✅ AI mention handling
- ✅ Response generation
- ✅ Action detection and execution

### 8. Error Handling
- ✅ Invalid configuration handling
- ✅ Malformed JSON handling
- ✅ Missing API key handling
- ✅ Network error simulation
- ✅ Graceful degradation

## Test Data and Cleanup

Tests use temporary data in `./test_data/` directory:
- Created automatically during test runs
- Cleaned up after test completion
- Isolated from production data

## Continuous Integration

The test suite is designed to be run in CI/CD pipelines:

```bash
# Basic CI test run
hype run test_suite.lua

# Exit code indicates success/failure
echo $?  # 0 = success, 1 = failure
```

## Performance Testing

Run performance benchmarks:
```bash
hype run performance_test.lua
```

This tests:
- Vector database insertion speed
- Search performance with different dataset sizes
- Memory usage patterns
- LSH indexing efficiency

## Debugging Failed Tests

### Common Issues

1. **Configuration Test Failures**
   - Check if `.env` file exists
   - Verify API keys are set
   - Confirm privacy levels are valid

2. **Database Test Failures**
   - Ensure sufficient disk space
   - Check file permissions
   - Verify database directory exists

3. **AI Integration Failures**
   - Confirm OpenRouter API key
   - Check network connectivity
   - Verify model availability

### Debug Mode

Add debug output to any test:
```lua
-- Add at beginning of test function
print("DEBUG: Starting test...")
local result = some_function()
print("DEBUG: Result:", result)
```

## Test Coverage

The test suite covers:
- ✅ **Core functionality** - All major features
- ✅ **Error conditions** - Invalid inputs and edge cases
- ✅ **Integration** - Component interactions
- ✅ **Performance** - Speed and memory usage
- ✅ **Configuration** - All settings and options
- ✅ **Privacy** - Data protection and compliance

## Adding New Tests

To add a new test to the main suite:

```lua
-- In test_suite.lua, add to run_test_suite():
suite:add_test("My New Test", test_my_feature, "Description of test")

-- Add test function:
local function test_my_feature()
    print("  Testing my feature...")
    
    -- Test logic here
    local result = my_function()
    
    if result then
        print("  ✅ My feature working")
        return true
    else
        print("  ❌ My feature failed")
        return false
    end
end
```

## Test Environment

Tests run in a controlled environment:
- Simulated API calls (no real external requests)
- Temporary database files
- Isolated configuration
- Predictable test data

This ensures tests are:
- ✅ **Fast** - No network delays
- ✅ **Reliable** - No external dependencies
- ✅ **Repeatable** - Consistent results
- ✅ **Isolated** - No side effects

## Production Readiness

A 100% test pass rate indicates:
- ✅ All core functionality working
- ✅ Configuration system robust
- ✅ Error handling comprehensive
- ✅ AI integration functional
- ✅ Privacy compliance maintained
- ✅ Performance characteristics understood

The system is ready for production deployment when all tests pass consistently.