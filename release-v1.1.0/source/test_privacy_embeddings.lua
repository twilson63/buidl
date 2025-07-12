-- test_privacy_embeddings.lua
-- Test privacy-conscious embedding service

local PrivacyEmbeddings = require("privacy_conscious_embeddings")

local function test_privacy_levels()
    print("=== PRIVACY-CONSCIOUS EMBEDDINGS TEST ===\n")
    
    -- Test messages with different sensitivity levels
    local test_messages = {
        {
            text = "Hello team, how is everyone doing today?",
            sensitive = false,
            description = "Regular team message"
        },
        {
            text = "My email is john.doe@company.com and my phone is 555-123-4567",
            sensitive = true,
            description = "Contains PII (email, phone)"
        },
        {
            text = "The API key is abc123xyz and the database password is secret123",
            sensitive = true,
            description = "Contains credentials"
        },
        {
            text = "Working on the new feature deployment for tomorrow",
            sensitive = false,
            description = "Regular work message"
        },
        {
            text = "Please update your password to NewSecret2024 for security",
            sensitive = true,
            description = "Contains password information"
        }
    }
    
    -- Test different privacy configurations
    local configs = {
        {
            name = "High Privacy (Local Only)",
            config = {
                privacy_level = PrivacyEmbeddings.PRIVACY_LEVELS.HIGH,
                use_enterprise_zdr = false
            }
        },
        {
            name = "Medium Privacy (Anonymized External)",
            config = {
                privacy_level = PrivacyEmbeddings.PRIVACY_LEVELS.MEDIUM,
                use_enterprise_zdr = false
            }
        },
        {
            name = "Low Privacy (Full External)",
            config = {
                privacy_level = PrivacyEmbeddings.PRIVACY_LEVELS.LOW,
                use_enterprise_zdr = false
            }
        },
        {
            name = "Enterprise ZDR",
            config = {
                privacy_level = PrivacyEmbeddings.PRIVACY_LEVELS.MEDIUM,
                use_enterprise_zdr = true
            }
        }
    }
    
    -- Test each configuration
    for _, config_test in ipairs(configs) do
        print(string.format("--- %s ---", config_test.name))
        
        local service = PrivacyEmbeddings.new(config_test.config)
        
        -- Process test messages
        for _, msg in ipairs(test_messages) do
            local result = service:get_embedding(msg.text)
            
            local security_indicator = msg.sensitive and "🔒" or "📝"
            print(string.format("%s %s:", security_indicator, msg.description))
            print(string.format("  Method: %s", result.method))
            print(string.format("  Privacy Level: %s", result.privacy_level))
            print(string.format("  Vector Dimension: %d", result.dimension))
            
            if result.zdr_enabled then
                print("  ✓ Zero Data Retention Enabled")
            end
            
            -- Check if vector has meaningful content
            local has_content = false
            for _, value in ipairs(result.vector) do
                if math.abs(value) > 0.001 then
                    has_content = true
                    break
                end
            end
            
            print(string.format("  Vector Quality: %s", has_content and "✓ Good" or "⚠ Empty"))
            print("")
        end
        
        -- Generate privacy report
        local privacy_report = service:get_privacy_report()
        print("Privacy Compliance Report:")
        print(string.format("  Privacy Score: %.1f/100", privacy_report.statistics.privacy_compliance_score))
        print(string.format("  Local Processing: %.1f%%", privacy_report.statistics.local_processing_rate * 100))
        print(string.format("  Sensitive Data Filtered: %d", privacy_report.statistics.sensitive_data_filtered))
        
        if #privacy_report.recommendations > 0 then
            print("  Recommendations:")
            for _, rec in ipairs(privacy_report.recommendations) do
                print("    - " .. rec)
            end
        end
        
        print(string.rep("-", 60))
        print("")
    end
    
    -- Preset configurations demo
    print("=== PRESET CONFIGURATIONS ===")
    local presets = PrivacyEmbeddings.get_preset_configs()
    
    for name, config in pairs(presets) do
        print(string.format("%s:", name))
        print(string.format("  Privacy Level: %s", config.privacy_level))
        print(string.format("  Enterprise ZDR: %s", config.use_enterprise_zdr and "Yes" or "No"))
        print(string.format("  Data Residency: %s", config.data_residency))
        print("")
    end
    
    print("=== PRIVACY TEST COMPLETE ===")
    
    -- Summary and recommendations
    print("\n=== DEPLOYMENT RECOMMENDATIONS ===")
    print("For Enterprise/Sensitive Data:")
    print("  ✓ Use HIGH privacy level (local-only processing)")
    print("  ✓ Implement additional PII detection patterns")
    print("  ✓ Regular privacy compliance audits")
    
    print("\nFor Balanced Approach:")
    print("  ✓ Use MEDIUM privacy level with anonymization")
    print("  ✓ Consider OpenAI Enterprise with ZDR for external processing")
    print("  ✓ Monitor sensitive data detection rates")
    
    print("\nFor Maximum Quality:")
    print("  ✓ Use OpenAI Enterprise with Zero Data Retention")
    print("  ✓ Implement data residency controls (EU/US)")
    print("  ✓ Regular security audits and compliance reviews")
end

-- Run the test
test_privacy_levels()