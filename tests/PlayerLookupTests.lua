-- PvPTooltip Player Lookup Tests
-- Unit tests for player lookup functionality

local PlayerLookupTests = {}
PvPTooltip.PlayerLookupTests = PlayerLookupTests

-- Test results storage
local testResults = {}

-- Initialize player lookup tests
function PlayerLookupTests:Initialize()
    PvPTooltip:Debug("PlayerLookupTests module initialized")
end

-- Run all player lookup tests
function PlayerLookupTests:RunAllTests()
    PvPTooltip:Debug("Running PlayerLookupTests...")
    
    testResults = {
        tests = {},
        passed = 0,
        failed = 0,
        startTime = GetTime()
    }
    
    -- Test player lookup initialization
    self:TestPlayerLookupInitialization()
    
    -- Test unit information extraction
    self:TestUnitInformationExtraction()
    
    -- Test player data lookup
    self:TestPlayerDataLookup()
    
    -- Test cross-faction and cross-realm handling
    self:TestCrossFactionHandling()
    
    -- Test cache functionality
    self:TestCacheFunctionality()
    
    -- Test error handling and graceful degradation
    self:TestErrorHandling()
    
    -- Test performance characteristics
    self:TestPerformanceCharacteristics()
    
    -- Test validation functions
    self:TestValidationFunctions()
    
    testResults.endTime = GetTime()
    testResults.duration = (testResults.endTime - testResults.startTime) * 1000
    
    return testResults
end

-- Test player lookup initialization
function PlayerLookupTests:TestPlayerLookupInitialization()
    local testName = "Player Lookup Initialization"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test that PlayerLookup exists
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.PlayerLookup, "PlayerLookup should exist")
        
        -- Test initialization method exists
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.PlayerLookup.Initialize, "Initialize method should exist")
        
        -- Test IsReady method
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.PlayerLookup.IsReady, "IsReady method should exist")
        
        -- Test that player lookup is ready (depends on DatabaseManager and RealmResolver)
        local isReady = PvPTooltip.PlayerLookup:IsReady()
        PvPTooltip.TestUtils.AssertTrue(isReady, "PlayerLookup should be ready after initialization")
        
        -- Test main lookup method exists
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.PlayerLookup.FindPlayerData, "FindPlayerData method should exist")
        
        -- Test utility methods exist
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.PlayerLookup.GetUnitInfo, "GetUnitInfo method should exist")
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.PlayerLookup.ValidateUnitInfo, "ValidateUnitInfo method should exist")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test unit information extraction
function PlayerLookupTests:TestUnitInformationExtraction()
    local testName = "Unit Information Extraction"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test GetUnitInfo with invalid inputs
        local unitInfo = PvPTooltip.PlayerLookup:GetUnitInfo(nil)
        PvPTooltip.TestUtils.AssertNil(unitInfo, "GetUnitInfo should return nil for nil input")
        
        unitInfo = PvPTooltip.PlayerLookup:GetUnitInfo("")
        PvPTooltip.TestUtils.AssertNil(unitInfo, "GetUnitInfo should return nil for empty string")
        
        unitInfo = PvPTooltip.PlayerLookup:GetUnitInfo("invalid_unit")
        -- This may return nil or valid data depending on WoW API, should not throw error
        
        -- Test with "player" unit (should work in most contexts)
        unitInfo = PvPTooltip.PlayerLookup:GetUnitInfo("player")
        if unitInfo then
            -- If we get unit info, validate its structure
            PvPTooltip.TestUtils.AssertNotNil(unitInfo.name, "Unit info should include name")
            PvPTooltip.TestUtils.AssertNotNil(unitInfo.realm, "Unit info should include realm")
            PvPTooltip.TestUtils.AssertTrue(type(unitInfo.name) == "string", "Unit name should be string")
            PvPTooltip.TestUtils.AssertTrue(type(unitInfo.realm) == "string", "Unit realm should be string")
        end
        
        -- Test ValidateUnitInfo with various inputs
        local isValid = PvPTooltip.PlayerLookup:ValidateUnitInfo(nil)
        PvPTooltip.TestUtils.AssertFalse(isValid, "Should reject nil unit info")
        
        isValid = PvPTooltip.PlayerLookup:ValidateUnitInfo({})
        PvPTooltip.TestUtils.AssertFalse(isValid, "Should reject empty unit info")
        
        isValid = PvPTooltip.PlayerLookup:ValidateUnitInfo({name = ""})
        PvPTooltip.TestUtils.AssertFalse(isValid, "Should reject unit info with empty name")
        
        isValid = PvPTooltip.PlayerLookup:ValidateUnitInfo({name = "TestPlayer"})
        PvPTooltip.TestUtils.AssertFalse(isValid, "Should reject unit info without realm")
        
        -- Test with valid unit info
        local validUnitInfo = {
            name = "TestPlayer",
            realm = "test-realm",
            guid = "Player-1234-567890",
            class = "WARRIOR",
            level = 80,
            faction = "Alliance"
        }
        
        isValid = PvPTooltip.PlayerLookup:ValidateUnitInfo(validUnitInfo)
        PvPTooltip.TestUtils.AssertTrue(isValid, "Should accept valid unit info")
        
        -- Test with suspicious data (very long names)
        local suspiciousUnitInfo = {
            name = string.rep("A", 100), -- Very long name
            realm = "test-realm"
        }
        
        isValid = PvPTooltip.PlayerLookup:ValidateUnitInfo(suspiciousUnitInfo)
        PvPTooltip.TestUtils.AssertFalse(isValid, "Should reject suspiciously long names")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test player data lookup
function PlayerLookupTests:TestPlayerDataLookup()
    local testName = "Player Data Lookup"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test FindPlayerData with invalid inputs
        local playerData = PvPTooltip.PlayerLookup:FindPlayerData(nil)
        PvPTooltip.TestUtils.AssertNil(playerData, "FindPlayerData should return nil for nil input")
        
        playerData = PvPTooltip.PlayerLookup:FindPlayerData("")
        PvPTooltip.TestUtils.AssertNil(playerData, "FindPlayerData should return nil for empty string")
        
        -- Test LookupPlayerInDatabase method
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.PlayerLookup.LookupPlayerInDatabase, 
            "LookupPlayerInDatabase method should exist")
        
        -- Test with invalid parameters
        playerData = PvPTooltip.PlayerLookup:LookupPlayerInDatabase(nil, nil, nil)
        PvPTooltip.TestUtils.AssertNil(playerData, "Should return nil for nil parameters")
        
        playerData = PvPTooltip.PlayerLookup:LookupPlayerInDatabase("", "", "")
        PvPTooltip.TestUtils.AssertNil(playerData, "Should return nil for empty parameters")
        
        playerData = PvPTooltip.PlayerLookup:LookupPlayerInDatabase("TestPlayer", "test-realm", "invalid")
        PvPTooltip.TestUtils.AssertNil(playerData, "Should return nil for invalid region")
        
        -- Test with valid parameters but non-existent player
        playerData = PvPTooltip.PlayerLookup:LookupPlayerInDatabase("NonExistentPlayer", "test-realm", "eu")
        -- Should return nil without throwing error
        
        -- Test ValidatePlayerDataStructure method
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.PlayerLookup.ValidatePlayerDataStructure, 
            "ValidatePlayerDataStructure method should exist")
        
        -- Test with invalid player data structures
        local isValid = PvPTooltip.PlayerLookup:ValidatePlayerDataStructure(nil)
        PvPTooltip.TestUtils.AssertFalse(isValid, "Should reject nil player data")
        
        isValid = PvPTooltip.PlayerLookup:ValidatePlayerDataStructure({})
        PvPTooltip.TestUtils.AssertFalse(isValid, "Should reject empty player data")
        
        isValid = PvPTooltip.PlayerLookup:ValidatePlayerDataStructure({name = "TestPlayer"})
        PvPTooltip.TestUtils.AssertFalse(isValid, "Should reject player data without required fields")
        
        -- Test with valid player data structure
        local validPlayerData = {
            name = "TestPlayer",
            realm = "test-realm",
            region = "eu",
            brackets = {
                ["2v2"] = {
                    currentRating = 2000,
                    personalBest = 2100,
                    playedTotal = 50
                }
            }
        }
        
        isValid = PvPTooltip.PlayerLookup:ValidatePlayerDataStructure(validPlayerData)
        PvPTooltip.TestUtils.AssertTrue(isValid, "Should accept valid player data structure")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test cross-faction and cross-realm handling
function PlayerLookupTests:TestCrossFactionHandling()
    local testName = "Cross-Faction Handling"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test HandleCrossFactionData method
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.PlayerLookup.HandleCrossFactionData, 
            "HandleCrossFactionData method should exist")
        
        -- Test with invalid parameters
        local result = PvPTooltip.PlayerLookup:HandleCrossFactionData(nil, nil, nil)
        PvPTooltip.TestUtils.AssertNil(result, "Should return nil for nil parameters")
        
        result = PvPTooltip.PlayerLookup:HandleCrossFactionData("", "", "")
        PvPTooltip.TestUtils.AssertNil(result, "Should return nil for empty parameters")
        
        -- Test GenerateNameVariations method
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.PlayerLookup.GenerateNameVariations, 
            "GenerateNameVariations method should exist")
        
        local variations = PvPTooltip.PlayerLookup:GenerateNameVariations("TestPlayer")
        PvPTooltip.TestUtils.AssertNotNil(variations, "Should return name variations")
        PvPTooltip.TestUtils.AssertTrue(type(variations) == "table", "Name variations should be a table")
        PvPTooltip.TestUtils.AssertTrue(#variations > 0, "Should generate at least one name variation")
        
        -- Test that original name is included
        local foundOriginal = false
        for _, variation in ipairs(variations) do
            if variation == "TestPlayer" then
                foundOriginal = true
                break
            end
        end
        PvPTooltip.TestUtils.AssertTrue(foundOriginal, "Original name should be included in variations")
        
        -- Test GenerateRealmVariations method
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.PlayerLookup.GenerateRealmVariations, 
            "GenerateRealmVariations method should exist")
        
        variations = PvPTooltip.PlayerLookup:GenerateRealmVariations("Test Realm")
        PvPTooltip.TestUtils.AssertNotNil(variations, "Should return realm variations")
        PvPTooltip.TestUtils.AssertTrue(type(variations) == "table", "Realm variations should be a table")
        PvPTooltip.TestUtils.AssertTrue(#variations > 0, "Should generate at least one realm variation")
        
        -- Test that variations include expected formats
        local hasHyphenated = false
        for _, variation in ipairs(variations) do
            if string.find(variation, "%-") then
                hasHyphenated = true
                break
            end
        end
        -- Should have at least one hyphenated variation for "Test Realm"
        
        -- Test HandleConnectedRealms method (if available)
        if PvPTooltip.PlayerLookup.HandleConnectedRealms then
            result = PvPTooltip.PlayerLookup:HandleConnectedRealms("TestPlayer", "test-realm", "eu")
            -- Should not throw error, result can be nil
        end
        
        -- Test EnhancedLookup method
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.PlayerLookup.EnhancedLookup, 
            "EnhancedLookup method should exist")
        
        result = PvPTooltip.PlayerLookup:EnhancedLookup("TestPlayer", "test-realm", "eu")
        -- Should not throw error, result can be nil
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test cache functionality
function PlayerLookupTests:TestCacheFunctionality()
    local testName = "Cache Functionality"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test GenerateCacheKey method
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.PlayerLookup.GenerateCacheKey, 
            "GenerateCacheKey method should exist")
        
        local cacheKey = PvPTooltip.PlayerLookup:GenerateCacheKey("TestPlayer", "test-realm")
        PvPTooltip.TestUtils.AssertNotNil(cacheKey, "Should generate cache key")
        PvPTooltip.TestUtils.AssertTrue(type(cacheKey) == "string", "Cache key should be string")
        
        -- Test with nil parameters
        cacheKey = PvPTooltip.PlayerLookup:GenerateCacheKey(nil, nil)
        PvPTooltip.TestUtils.AssertNil(cacheKey, "Should return nil for nil parameters")
        
        -- Test cache key consistency
        local key1 = PvPTooltip.PlayerLookup:GenerateCacheKey("TestPlayer", "test-realm")
        local key2 = PvPTooltip.PlayerLookup:GenerateCacheKey("TestPlayer", "test-realm")
        PvPTooltip.TestUtils.AssertEquals(key1, key2, "Cache keys should be consistent")
        
        -- Test case insensitivity
        local key3 = PvPTooltip.PlayerLookup:GenerateCacheKey("TESTPLAYER", "TEST-REALM")
        local key4 = PvPTooltip.PlayerLookup:GenerateCacheKey("testplayer", "test-realm")
        PvPTooltip.TestUtils.AssertEquals(key3, key4, "Cache keys should be case insensitive")
        
        -- Test GetFromCache and AddToCache methods
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.PlayerLookup.GetFromCache, "GetFromCache method should exist")
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.PlayerLookup.AddToCache, "AddToCache method should exist")
        
        -- Test cache operations
        local testKey = "test@test-realm"
        local testData = {name = "TestPlayer", realm = "test-realm"}
        
        -- Should return nil for non-existent key
        local cachedData = PvPTooltip.PlayerLookup:GetFromCache(testKey)
        PvPTooltip.TestUtils.AssertNil(cachedData, "Should return nil for non-existent cache key")
        
        -- Add to cache and retrieve
        PvPTooltip.PlayerLookup:AddToCache(testKey, testData)
        cachedData = PvPTooltip.PlayerLookup:GetFromCache(testKey)
        PvPTooltip.TestUtils.AssertNotNil(cachedData, "Should return cached data")
        PvPTooltip.TestUtils.AssertEquals(testData.name, cachedData.name, "Cached data should match original")
        
        -- Test ClearCache method
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.PlayerLookup.ClearCache, "ClearCache method should exist")
        
        PvPTooltip.PlayerLookup:ClearCache()
        cachedData = PvPTooltip.PlayerLookup:GetFromCache(testKey)
        PvPTooltip.TestUtils.AssertNil(cachedData, "Cache should be empty after clearing")
        
        -- Test GetCacheStats method
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.PlayerLookup.GetCacheStats, "GetCacheStats method should exist")
        
        local cacheStats = PvPTooltip.PlayerLookup:GetCacheStats()
        PvPTooltip.TestUtils.AssertNotNil(cacheStats, "Should return cache stats")
        PvPTooltip.TestUtils.AssertTrue(type(cacheStats.totalEntries) == "number", "Should include totalEntries")
        PvPTooltip.TestUtils.AssertTrue(type(cacheStats.validEntries) == "number", "Should include validEntries")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test error handling and graceful degradation
function PlayerLookupTests:TestErrorHandling()
    local testName = "Error Handling"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test graceful handling of missing dependencies
        local originalDatabaseManager = PvPTooltip.DatabaseManager
        PvPTooltip.DatabaseManager = nil
        
        local result = PvPTooltip.PlayerLookup:FindPlayerData("player")
        PvPTooltip.TestUtils.AssertNil(result, "Should handle missing DatabaseManager gracefully")
        
        -- Restore DatabaseManager
        PvPTooltip.DatabaseManager = originalDatabaseManager
        
        -- Test handling of corrupted unit info
        local corruptedUnitInfo = {
            name = 123, -- Should be string
            realm = nil -- Missing realm
        }
        
        local isValid = PvPTooltip.PlayerLookup:ValidateUnitInfo(corruptedUnitInfo)
        PvPTooltip.TestUtils.AssertFalse(isValid, "Should reject corrupted unit info")
        
        -- Test handling of extreme values
        local extremeUnitInfo = {
            name = string.rep("A", 1000), -- Extremely long name
            realm = string.rep("B", 1000)  -- Extremely long realm
        }
        
        isValid = PvPTooltip.PlayerLookup:ValidateUnitInfo(extremeUnitInfo)
        PvPTooltip.TestUtils.AssertFalse(isValid, "Should reject extremely long names/realms")
        
        -- Test fallback realm normalization
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.PlayerLookup.FallbackNormalizeRealm, 
            "FallbackNormalizeRealm method should exist")
        
        local normalized = PvPTooltip.PlayerLookup:FallbackNormalizeRealm("Test Realm")
        PvPTooltip.TestUtils.AssertEquals("test-realm", normalized, "Fallback normalization should work")
        
        normalized = PvPTooltip.PlayerLookup:FallbackNormalizeRealm(nil)
        PvPTooltip.TestUtils.AssertNil(normalized, "Should handle nil realm gracefully")
        
        -- Test GUID parsing with invalid GUIDs
        if PvPTooltip.PlayerLookup.ParseGUID then
            local guidInfo = PvPTooltip.PlayerLookup:ParseGUID(nil)
            PvPTooltip.TestUtils.AssertNil(guidInfo, "Should handle nil GUID")
            
            guidInfo = PvPTooltip.PlayerLookup:ParseGUID("invalid-guid")
            PvPTooltip.TestUtils.AssertNil(guidInfo, "Should handle invalid GUID format")
            
            guidInfo = PvPTooltip.PlayerLookup:ParseGUID("Player-1234-567890")
            if guidInfo then
                PvPTooltip.TestUtils.AssertEquals("Player", guidInfo.type, "Should parse GUID type correctly")
                PvPTooltip.TestUtils.AssertEquals(1234, guidInfo.serverID, "Should parse server ID correctly")
            end
        end
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test performance characteristics
function PlayerLookupTests:TestPerformanceCharacteristics()
    local testName = "Performance Characteristics"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test lookup performance
        local lookupCount = 50
        local startTime = GetTime()
        
        for i = 1, lookupCount do
            PvPTooltip.PlayerLookup:FindPlayerData("player")
        end
        
        local endTime = GetTime()
        local totalTime = (endTime - startTime) * 1000
        local averageTime = totalTime / lookupCount
        
        PvPTooltip:Debug(string.format("Average lookup time: %.2fms", averageTime))
        
        -- Performance should be reasonable (less than 50ms per lookup on average)
        PvPTooltip.TestUtils.AssertTrue(averageTime < 50, 
            string.format("Average lookup time should be < 50ms, got %.2fms", averageTime))
        
        -- Test cache performance
        local testKey = "perftest@test-realm"
        local testData = {name = "PerfTest", realm = "test-realm"}
        
        -- Add to cache
        PvPTooltip.PlayerLookup:AddToCache(testKey, testData)
        
        -- Test cache retrieval performance
        startTime = GetTime()
        for i = 1, 1000 do
            PvPTooltip.PlayerLookup:GetFromCache(testKey)
        end
        endTime = GetTime()
        
        local cacheTime = (endTime - startTime) * 1000
        PvPTooltip:Debug(string.format("Cache retrieval time for 1000 operations: %.2fms", cacheTime))
        
        PvPTooltip.TestUtils.AssertTrue(cacheTime < 100, 
            "Cache retrieval should be fast (< 100ms for 1000 operations)")
        
        -- Test name variation generation performance
        startTime = GetTime()
        for i = 1, 100 do
            PvPTooltip.PlayerLookup:GenerateNameVariations("TestPlayer" .. i)
        end
        endTime = GetTime()
        
        local variationTime = (endTime - startTime) * 1000
        PvPTooltip:Debug(string.format("Name variation generation time for 100 operations: %.2fms", variationTime))
        
        PvPTooltip.TestUtils.AssertTrue(variationTime < 50, 
            "Name variation generation should be fast (< 50ms for 100 operations)")
        
        -- Clean up
        PvPTooltip.PlayerLookup:ClearCache()
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test validation functions
function PlayerLookupTests:TestValidationFunctions()
    local testName = "Validation Functions"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test ValidatePlayerData method (if available)
        if PvPTooltip.PlayerLookup.ValidatePlayerData then
            local isValid = PvPTooltip.PlayerLookup:ValidatePlayerData(nil)
            PvPTooltip.TestUtils.AssertFalse(isValid, "Should reject nil player data")
            
            isValid = PvPTooltip.PlayerLookup:ValidatePlayerData({})
            PvPTooltip.TestUtils.AssertFalse(isValid, "Should reject empty player data")
            
            local validData = {
                name = "TestPlayer",
                realm = "test-realm",
                region = "eu",
                brackets = {
                    ["2v2"] = {currentRating = 2000}
                }
            }
            
            isValid = PvPTooltip.PlayerLookup:ValidatePlayerData(validData)
            PvPTooltip.TestUtils.AssertTrue(isValid, "Should accept valid player data")
        end
        
        -- Test comprehensive unit info validation
        local testCases = {
            {
                unitInfo = nil,
                expected = false,
                description = "nil unit info"
            },
            {
                unitInfo = {},
                expected = false,
                description = "empty unit info"
            },
            {
                unitInfo = {name = ""},
                expected = false,
                description = "empty name"
            },
            {
                unitInfo = {name = "TestPlayer"},
                expected = false,
                description = "missing realm"
            },
            {
                unitInfo = {name = "TestPlayer", realm = ""},
                expected = false,
                description = "empty realm"
            },
            {
                unitInfo = {name = "TestPlayer", realm = "test-realm"},
                expected = true,
                description = "valid unit info"
            },
            {
                unitInfo = {name = 123, realm = "test-realm"},
                expected = false,
                description = "non-string name"
            },
            {
                unitInfo = {name = "TestPlayer", realm = 456},
                expected = false,
                description = "non-string realm"
            }
        }
        
        for _, testCase in ipairs(testCases) do
            local isValid = PvPTooltip.PlayerLookup:ValidateUnitInfo(testCase.unitInfo)
            if testCase.expected then
                PvPTooltip.TestUtils.AssertTrue(isValid, "Should accept " .. testCase.description)
            else
                PvPTooltip.TestUtils.AssertFalse(isValid, "Should reject " .. testCase.description)
            end
        end
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Record test result
function PlayerLookupTests:RecordTestResult(testName, success, error)
    testResults.tests[testName] = {
        success = success,
        error = error,
        timestamp = GetTime()
    }
    
    if success then
        testResults.passed = testResults.passed + 1
        PvPTooltip:Debug("✓ " .. testName .. " - PASSED")
    else
        testResults.failed = testResults.failed + 1
        PvPTooltip:Debug("✗ " .. testName .. " - FAILED: " .. tostring(error))
    end
end

-- Get test results
function PlayerLookupTests:GetTestResults()
    return testResults
end

-- Quick player lookup test
function PlayerLookupTests:QuickTest()
    PvPTooltip:Print("=== Quick Player Lookup Test ===")
    
    local tests = {
        {
            name = "PlayerLookup exists",
            test = function()
                return PvPTooltip.PlayerLookup ~= nil
            end
        },
        {
            name = "PlayerLookup is ready",
            test = function()
                return PvPTooltip.PlayerLookup and PvPTooltip.PlayerLookup:IsReady()
            end
        },
        {
            name = "FindPlayerData method works",
            test = function()
                if not PvPTooltip.PlayerLookup then return false end
                -- Should not throw error even with invalid input
                local result = PvPTooltip.PlayerLookup:FindPlayerData(nil)
                return true
            end
        },
        {
            name = "Unit info validation works",
            test = function()
                if not PvPTooltip.PlayerLookup or not PvPTooltip.PlayerLookup.ValidateUnitInfo then 
                    return false 
                end
                return not PvPTooltip.PlayerLookup:ValidateUnitInfo(nil)
            end
        },
        {
            name = "Cache functionality works",
            test = function()
                if not PvPTooltip.PlayerLookup or not PvPTooltip.PlayerLookup.GenerateCacheKey then 
                    return false 
                end
                local key = PvPTooltip.PlayerLookup:GenerateCacheKey("test", "test-realm")
                return key ~= nil
            end
        }
    }
    
    local passed = 0
    for _, test in ipairs(tests) do
        local success, result = pcall(test.test)
        if success and result then
            PvPTooltip:Print("✓ " .. test.name)
            passed = passed + 1
        else
            PvPTooltip:Print("✗ " .. test.name .. (success and "" or " (error: " .. tostring(result) .. ")"))
        end
    end
    
    PvPTooltip:Print(string.format("Quick player lookup test: %d/%d passed", passed, #tests))
    return passed == #tests
end