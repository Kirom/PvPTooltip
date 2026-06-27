-- PvPTooltip Database Tests
-- Unit tests for database loading and management functionality

local DatabaseTests = {}
PvPTooltip.DatabaseTests = DatabaseTests

-- Test results storage
local testResults = {}

-- Initialize database tests
function DatabaseTests:Initialize()
    PvPTooltip:Debug("DatabaseTests module initialized")
end

-- Run all database tests
function DatabaseTests:RunAllTests()
    PvPTooltip:Debug("Running DatabaseTests...")
    
    testResults = {
        tests = {},
        passed = 0,
        failed = 0,
        startTime = GetTime()
    }
    
    -- Test database initialization
    self:TestDatabaseInitialization()
    
    -- Test database loading
    self:TestDatabaseLoading()
    
    -- Test player data retrieval
    self:TestPlayerDataRetrieval()
    
    -- Test data validation
    self:TestDataValidation()
    
    -- Test cache management
    self:TestCacheManagement()
    
    -- Test error handling
    self:TestErrorHandling()
    
    -- Test performance characteristics
    self:TestPerformanceCharacteristics()
    
    -- Test memory management
    self:TestMemoryManagement()
    
    testResults.endTime = GetTime()
    testResults.duration = (testResults.endTime - testResults.startTime) * 1000
    
    return testResults
end

-- Test database initialization
function DatabaseTests:TestDatabaseInitialization()
    local testName = "Database Initialization"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test that DatabaseManager exists
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.DatabaseManager, "DatabaseManager should exist")
        
        -- Test initialization method exists
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.DatabaseManager.Initialize, "Initialize method should exist")
        
        -- Test IsDataAvailable method
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.DatabaseManager.IsDataAvailable, "IsDataAvailable method should exist")
        
        -- Test that database is available after initialization
        local isAvailable = PvPTooltip.DatabaseManager:IsDataAvailable()
        PvPTooltip.TestUtils.AssertTrue(isAvailable, "Database should be available after initialization")
        
        -- Test cache stats are available
        local cacheStats = PvPTooltip.DatabaseManager:GetCacheStats()
        PvPTooltip.TestUtils.AssertNotNil(cacheStats, "Cache stats should be available")
        PvPTooltip.TestUtils.AssertNotNil(cacheStats.totalEntries, "Cache stats should include totalEntries")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test database loading functionality
function DatabaseTests:TestDatabaseLoading()
    local testName = "Database Loading"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test LoadDatabases method exists
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.DatabaseManager.LoadDatabases, "LoadDatabases method should exist")
        
        -- Test that databases can be reloaded
        local reloadSuccess = PvPTooltip.DatabaseManager:ReloadDatabases()
        PvPTooltip.TestUtils.AssertTrue(reloadSuccess, "Database reload should succeed")
        
        -- Test that data is still available after reload
        local isAvailable = PvPTooltip.DatabaseManager:IsDataAvailable()
        PvPTooltip.TestUtils.AssertTrue(isAvailable, "Database should be available after reload")
        
        -- Test cache stats after reload
        local cacheStats = PvPTooltip.DatabaseManager:GetCacheStats()
        PvPTooltip.TestUtils.AssertTrue(cacheStats.totalEntries >= 0, "Cache should have non-negative entry count")
        
        -- Test that both EU and US data are loaded (if available)
        PvPTooltip.TestUtils.AssertTrue(cacheStats.euEntries >= 0, "EU entries should be non-negative")
        PvPTooltip.TestUtils.AssertTrue(cacheStats.usEntries >= 0, "US entries should be non-negative")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test player data retrieval
function DatabaseTests:TestPlayerDataRetrieval()
    local testName = "Player Data Retrieval"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test GetPlayerData method exists
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.DatabaseManager.GetPlayerData, "GetPlayerData method should exist")
        
        -- Test with invalid parameters (should return nil gracefully)
        local result = PvPTooltip.DatabaseManager:GetPlayerData(nil, nil, nil)
        PvPTooltip.TestUtils.AssertNil(result, "GetPlayerData should return nil for invalid parameters")
        
        result = PvPTooltip.DatabaseManager:GetPlayerData("", "", "")
        PvPTooltip.TestUtils.AssertNil(result, "GetPlayerData should return nil for empty parameters")
        
        result = PvPTooltip.DatabaseManager:GetPlayerData("TestPlayer", "invalid-realm", "invalid-region")
        PvPTooltip.TestUtils.AssertNil(result, "GetPlayerData should return nil for invalid region")
        
        -- Test with valid parameters but non-existent player
        result = PvPTooltip.DatabaseManager:GetPlayerData("NonExistentPlayer", "test-realm", "eu")
        -- This should return nil without throwing an error
        
        -- Test realm name normalization
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.DatabaseManager.NormalizeRealmName, "NormalizeRealmName method should exist")
        
        local normalized = PvPTooltip.DatabaseManager:NormalizeRealmName("Test Realm")
        PvPTooltip.TestUtils.AssertEquals("test-realm", normalized, "Realm name should be normalized correctly")
        
        normalized = PvPTooltip.DatabaseManager:NormalizeRealmName("Test'Realm")
        PvPTooltip.TestUtils.AssertEquals("testrealm", normalized, "Apostrophes should be removed from realm names")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test data validation
function DatabaseTests:TestDataValidation()
    local testName = "Data Validation"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test ValidatePlayerDataStructure method
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.DatabaseManager.ValidatePlayerDataStructure, 
            "ValidatePlayerDataStructure method should exist")
        
        -- Test with invalid data
        local isValid = PvPTooltip.DatabaseManager:ValidatePlayerDataStructure(nil, nil)
        PvPTooltip.TestUtils.AssertFalse(isValid, "Should reject nil player data")
        
        isValid = PvPTooltip.DatabaseManager:ValidatePlayerDataStructure("", {})
        PvPTooltip.TestUtils.AssertFalse(isValid, "Should reject empty player name")
        
        isValid = PvPTooltip.DatabaseManager:ValidatePlayerDataStructure("TestPlayer", "not a table")
        PvPTooltip.TestUtils.AssertFalse(isValid, "Should reject non-table player data")
        
        -- Test with valid data structure
        local validPlayerData = {
            brackets = {
                ["2v2"] = {
                    currentRating = 2000,
                    personalBest = 2100,
                    playedTotal = 50,
                    winRate = 60
                }
            }
        }
        
        isValid = PvPTooltip.DatabaseManager:ValidatePlayerDataStructure("TestPlayer", validPlayerData)
        PvPTooltip.TestUtils.AssertTrue(isValid, "Should accept valid player data structure")
        
        -- Test ValidateBracketData method
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.DatabaseManager.ValidateBracketData, 
            "ValidateBracketData method should exist")
        
        -- Test with invalid bracket data
        isValid = PvPTooltip.DatabaseManager:ValidateBracketData(nil)
        PvPTooltip.TestUtils.AssertFalse(isValid, "Should reject nil bracket data")
        
        isValid = PvPTooltip.DatabaseManager:ValidateBracketData({currentRating = "not a number"})
        PvPTooltip.TestUtils.AssertFalse(isValid, "Should reject non-numeric rating")
        
        isValid = PvPTooltip.DatabaseManager:ValidateBracketData({winRate = 150})
        PvPTooltip.TestUtils.AssertFalse(isValid, "Should reject invalid win rate > 100%")
        
        -- Test with valid bracket data
        isValid = PvPTooltip.DatabaseManager:ValidateBracketData({
            currentRating = 2000,
            personalBest = 2100,
            playedTotal = 50,
            winRate = 60
        })
        PvPTooltip.TestUtils.AssertTrue(isValid, "Should accept valid bracket data")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test cache management
function DatabaseTests:TestCacheManagement()
    local testName = "Cache Management"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test cache stats retrieval
        local cacheStats = PvPTooltip.DatabaseManager:GetCacheStats()
        PvPTooltip.TestUtils.AssertNotNil(cacheStats, "Cache stats should be available")
        PvPTooltip.TestUtils.AssertTrue(type(cacheStats.totalEntries) == "number", "totalEntries should be a number")
        PvPTooltip.TestUtils.AssertTrue(type(cacheStats.euEntries) == "number", "euEntries should be a number")
        PvPTooltip.TestUtils.AssertTrue(type(cacheStats.usEntries) == "number", "usEntries should be a number")
        
        -- Test cache clearing (if method exists)
        if PvPTooltip.DatabaseManager.ClearAllCaches then
            PvPTooltip.DatabaseManager:ClearAllCaches()
            local clearedStats = PvPTooltip.DatabaseManager:GetCacheStats()
            PvPTooltip.TestUtils.AssertEquals(0, clearedStats.totalEntries, "Cache should be empty after clearing")
            
            -- Reload to restore cache
            PvPTooltip.DatabaseManager:ReloadDatabases()
        end
        
        -- Test memory stats (if available)
        if PvPTooltip.DatabaseManager.GetMemoryStats then
            local memoryStats = PvPTooltip.DatabaseManager:GetMemoryStats()
            PvPTooltip.TestUtils.AssertNotNil(memoryStats, "Memory stats should be available")
            PvPTooltip.TestUtils.AssertNotNil(memoryStats.cacheStats, "Memory stats should include cache stats")
        end
        
        -- Test cache cleanup (if method exists)
        if PvPTooltip.DatabaseManager.CleanupCache then
            -- This should not throw an error
            PvPTooltip.DatabaseManager:CleanupCache()
        end
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test error handling
function DatabaseTests:TestErrorHandling()
    local testName = "Error Handling"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test graceful handling of corrupted data
        local corruptedPlayerData = {
            brackets = "this should be a table"
        }
        
        local isValid = PvPTooltip.DatabaseManager:ValidatePlayerDataStructure("TestPlayer", corruptedPlayerData)
        PvPTooltip.TestUtils.AssertFalse(isValid, "Should detect corrupted player data structure")
        
        -- Test handling of extreme values
        local extremeBracketData = {
            currentRating = -100,
            personalBest = 999999,
            playedTotal = -50,
            winRate = -10
        }
        
        isValid = PvPTooltip.DatabaseManager:ValidateBracketData(extremeBracketData)
        PvPTooltip.TestUtils.AssertFalse(isValid, "Should reject bracket data with negative values")
        
        -- Test data sanitization (if method exists)
        if PvPTooltip.DatabaseManager.SanitizeBracketData then
            local sanitized = PvPTooltip.DatabaseManager:SanitizeBracketData({
                currentRating = -100,
                winRate = 150
            })
            
            PvPTooltip.TestUtils.AssertTrue(sanitized.currentRating >= 0, "Sanitized rating should be non-negative")
            PvPTooltip.TestUtils.AssertTrue(sanitized.winRate <= 100, "Sanitized win rate should not exceed 100%")
        end
        
        -- Test handling of nil/empty inputs
        local result = PvPTooltip.DatabaseManager:GetPlayerData(nil, "test-realm", "eu")
        PvPTooltip.TestUtils.AssertNil(result, "Should handle nil player name gracefully")
        
        result = PvPTooltip.DatabaseManager:GetPlayerData("TestPlayer", nil, "eu")
        PvPTooltip.TestUtils.AssertNil(result, "Should handle nil realm name gracefully")
        
        result = PvPTooltip.DatabaseManager:GetPlayerData("TestPlayer", "test-realm", nil)
        PvPTooltip.TestUtils.AssertNil(result, "Should handle nil region gracefully")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test performance characteristics
function DatabaseTests:TestPerformanceCharacteristics()
    local testName = "Performance Characteristics"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test lookup performance
        local lookupCount = 100
        local startTime = GetTime()
        
        for i = 1, lookupCount do
            -- Perform lookups with various parameters
            PvPTooltip.DatabaseManager:GetPlayerData("TestPlayer" .. i, "test-realm", "eu")
            PvPTooltip.DatabaseManager:GetPlayerData("TestPlayer" .. i, "test-realm", "us")
        end
        
        local endTime = GetTime()
        local totalTime = (endTime - startTime) * 1000 -- Convert to milliseconds
        local averageTime = totalTime / (lookupCount * 2) -- 2 lookups per iteration
        
        PvPTooltip:Debug(string.format("Average lookup time: %.2fms", averageTime))
        
        -- Performance should be reasonable (less than 10ms per lookup on average)
        PvPTooltip.TestUtils.AssertTrue(averageTime < 10, 
            string.format("Average lookup time should be < 10ms, got %.2fms", averageTime))
        
        -- Test cache performance (if lookup cache is available)
        if PvPTooltip.DatabaseManager.GetMemoryStats then
            local memStats = PvPTooltip.DatabaseManager:GetMemoryStats()
            if memStats.lookupCacheHitRate then
                PvPTooltip:Debug(string.format("Lookup cache hit rate: %.1f%%", memStats.lookupCacheHitRate))
            end
        end
        
        -- Test realm normalization performance
        startTime = GetTime()
        for i = 1, 1000 do
            PvPTooltip.DatabaseManager:NormalizeRealmName("Test Realm " .. i)
        end
        endTime = GetTime()
        
        local normalizationTime = (endTime - startTime) * 1000
        PvPTooltip:Debug(string.format("Realm normalization time for 1000 operations: %.2fms", normalizationTime))
        
        PvPTooltip.TestUtils.AssertTrue(normalizationTime < 100, 
            "Realm normalization should be fast (< 100ms for 1000 operations)")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test memory management
function DatabaseTests:TestMemoryManagement()
    local testName = "Memory Management"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Force garbage collection before test
        collectgarbage("collect")
        local startMemory = collectgarbage("count")
        
        -- Perform memory-intensive operations
        local testData = {}
        for i = 1, 1000 do
            testData[i] = PvPTooltip.DatabaseManager:GetPlayerData("TestPlayer" .. i, "test-realm", "eu")
        end
        
        -- Force garbage collection and measure memory
        collectgarbage("collect")
        local endMemory = collectgarbage("count")
        local memoryUsed = endMemory - startMemory
        
        PvPTooltip:Debug(string.format("Memory used for 1000 lookups: %.2f KB", memoryUsed))
        
        -- Memory usage should be reasonable (less than 1MB for 1000 lookups)
        PvPTooltip.TestUtils.AssertTrue(memoryUsed < 1024, 
            string.format("Memory usage should be < 1MB, got %.2f KB", memoryUsed))
        
        -- Test memory cleanup (if available)
        if PvPTooltip.DatabaseManager.PerformMemoryCleanup then
            PvPTooltip.DatabaseManager:PerformMemoryCleanup()
            
            collectgarbage("collect")
            local cleanupMemory = collectgarbage("count")
            
            PvPTooltip:Debug(string.format("Memory after cleanup: %.2f KB", cleanupMemory))
        end
        
        -- Clear test data
        testData = nil
        collectgarbage("collect")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Record test result
function DatabaseTests:RecordTestResult(testName, success, error)
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
function DatabaseTests:GetTestResults()
    return testResults
end

-- Run specific test by name
function DatabaseTests:RunSpecificTest(testName)
    PvPTooltip:Print("Running specific database test: " .. testName)
    
    testResults = {
        tests = {},
        passed = 0,
        failed = 0,
        startTime = GetTime()
    }
    
    if testName == "Database Initialization" then
        self:TestDatabaseInitialization()
    elseif testName == "Database Loading" then
        self:TestDatabaseLoading()
    elseif testName == "Player Data Retrieval" then
        self:TestPlayerDataRetrieval()
    elseif testName == "Data Validation" then
        self:TestDataValidation()
    elseif testName == "Cache Management" then
        self:TestCacheManagement()
    elseif testName == "Error Handling" then
        self:TestErrorHandling()
    elseif testName == "Performance Characteristics" then
        self:TestPerformanceCharacteristics()
    elseif testName == "Memory Management" then
        self:TestMemoryManagement()
    else
        PvPTooltip:Print("Unknown test name: " .. testName)
        return nil
    end
    
    testResults.endTime = GetTime()
    testResults.duration = (testResults.endTime - testResults.startTime) * 1000
    
    return testResults
end

-- Quick database test
function DatabaseTests:QuickTest()
    PvPTooltip:Print("=== Quick Database Test ===")
    
    local tests = {
        {
            name = "DatabaseManager exists",
            test = function()
                return PvPTooltip.DatabaseManager ~= nil
            end
        },
        {
            name = "Database is available",
            test = function()
                return PvPTooltip.DatabaseManager and PvPTooltip.DatabaseManager:IsDataAvailable()
            end
        },
        {
            name = "Cache stats available",
            test = function()
                if not PvPTooltip.DatabaseManager then return false end
                local stats = PvPTooltip.DatabaseManager:GetCacheStats()
                return stats and stats.totalEntries ~= nil
            end
        },
        {
            name = "Player data retrieval works",
            test = function()
                if not PvPTooltip.DatabaseManager then return false end
                -- This should not throw an error, even if no data is found
                local result = PvPTooltip.DatabaseManager:GetPlayerData("TestPlayer", "test-realm", "eu")
                return true -- Success if no error thrown
            end
        },
        {
            name = "Data validation works",
            test = function()
                if not PvPTooltip.DatabaseManager or not PvPTooltip.DatabaseManager.ValidatePlayerDataStructure then 
                    return false 
                end
                return not PvPTooltip.DatabaseManager:ValidatePlayerDataStructure(nil, nil)
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
    
    PvPTooltip:Print(string.format("Quick database test: %d/%d passed", passed, #tests))
    return passed == #tests
end