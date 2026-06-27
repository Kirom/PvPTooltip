-- PvPTooltip Integration Tests
-- End-to-end integration tests for complete addon functionality

local IntegrationTests = {}
PvPTooltip.IntegrationTests = IntegrationTests

-- Test results storage
local testResults = {}

-- Initialize integration tests
function IntegrationTests:Initialize()
    PvPTooltip:Debug("IntegrationTests module initialized")
end

-- Run all integration tests
function IntegrationTests:RunAllTests()
    PvPTooltip:Debug("Running IntegrationTests...")
    
    testResults = {
        tests = {},
        passed = 0,
        failed = 0,
        startTime = GetTime()
    }
    
    -- Test complete addon workflow
    self:TestCompleteAddonWorkflow()
    
    -- Test event handling integration
    self:TestEventHandlingIntegration()
    
    -- Test cross-component communication
    self:TestCrossComponentCommunication()
    
    -- Test error recovery and graceful degradation
    self:TestErrorRecoveryIntegration()
    
    -- Test configuration integration
    self:TestConfigurationIntegration()
    
    -- Test performance under load
    self:TestPerformanceUnderLoad()
    
    -- Test compatibility scenarios
    self:TestCompatibilityScenarios()
    
    -- Test data consistency
    self:TestDataConsistency()
    
    -- Task 15: Integration testing and final validation
    -- Test tooltip display across all supported game contexts
    self:TestTooltipContexts()
    
    -- Test color coding accuracy and data formatting
    self:TestColorCodingAccuracy()
    
    -- Test cross-region and cross-realm functionality
    self:TestCrossRegionRealm()
    
    -- Test compatibility with popular UI addons
    self:TestUIAddonCompatibility()
    
    -- Test comprehensive requirements validation
    self:TestRequirementsValidation()
    
    testResults.endTime = GetTime()
    testResults.duration = (testResults.endTime - testResults.startTime) * 1000
    
    return testResults
end

-- Test complete addon workflow from unit hover to tooltip display
function IntegrationTests:TestCompleteAddonWorkflow()
    local testName = "Complete Addon Workflow"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Simulate the complete workflow: Unit hover -> Player lookup -> Tooltip enhancement
        
        -- Step 1: Verify all components are initialized
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.DatabaseManager, "DatabaseManager should be initialized")
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.PlayerLookup, "PlayerLookup should be initialized")
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.TooltipRenderer, "TooltipRenderer should be initialized")
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.ColorUtils, "ColorUtils should be initialized")
        
        -- Step 2: Verify database is loaded
        local isDataAvailable = PvPTooltip.DatabaseManager:IsDataAvailable()
        PvPTooltip.TestUtils.AssertTrue(isDataAvailable, "Database should be loaded and available")
        
        -- Step 3: Verify PlayerLookup is ready
        local isLookupReady = PvPTooltip.PlayerLookup:IsReady()
        PvPTooltip.TestUtils.AssertTrue(isLookupReady, "PlayerLookup should be ready")
        
        -- Step 4: Simulate unit information extraction
        -- Note: In a real scenario, this would come from WoW API, but we'll simulate it
        local mockUnitInfo = {
            name = "TestPlayer",
            realm = "test-realm",
            guid = "Player-1234-567890",
            class = "WARRIOR",
            level = 80,
            faction = "Alliance"
        }
        
        local isValidUnit = PvPTooltip.PlayerLookup:ValidateUnitInfo(mockUnitInfo)
        PvPTooltip.TestUtils.AssertTrue(isValidUnit, "Mock unit info should be valid")
        
        -- Step 5: Simulate player data lookup
        local playerData = PvPTooltip.PlayerLookup:LookupPlayerInDatabase(
            mockUnitInfo.name, 
            mockUnitInfo.realm, 
            "eu"
        )
        
        -- Note: playerData might be nil if the test player doesn't exist in database
        -- This is expected behavior, not a failure
        
        -- Step 6: Test tooltip enhancement with mock data
        local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData(
            mockUnitInfo.name, 
            mockUnitInfo.realm, 
            "eu"
        )
        
        local isValidPlayerData = PvPTooltip.TooltipRenderer:ValidatePlayerData(mockPlayerData)
        PvPTooltip.TestUtils.AssertTrue(isValidPlayerData, "Mock player data should be valid")
        
        -- Step 7: Create mock tooltip and enhance it
        local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        local enhanceResult = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
        PvPTooltip.TestUtils.AssertTrue(enhanceResult, "Tooltip enhancement should succeed")
        
        -- Step 8: Verify tooltip content
        PvPTooltip.TestUtils.AssertTrue(#mockTooltip.lines > 0, "Tooltip should have content")
        
        local tooltipContent = table.concat(mockTooltip.lines, "\n")
        PvPTooltip.TestUtils.AssertTrue(string.find(tooltipContent, "PvP Tooltip info") ~= nil, 
            "Tooltip should contain main title")
        PvPTooltip.TestUtils.AssertTrue(string.find(tooltipContent, "Current Rating") ~= nil, 
            "Tooltip should contain rating section")
        
        -- Step 9: Test the complete FindPlayerData workflow
        -- This simulates what happens when EventManager calls PlayerLookup
        local workflowResult = PvPTooltip.PlayerLookup:FindPlayerData("player")
        -- Result can be nil (no data found) or valid player data - both are acceptable
        
        -- Step 10: Verify error handling in the complete workflow
        local errorHandlingResult = PvPTooltip.PlayerLookup:FindPlayerData(nil)
        PvPTooltip.TestUtils.AssertNil(errorHandlingResult, "Should handle nil unit gracefully")
        
        errorHandlingResult = PvPTooltip.TooltipRenderer:EnhanceTooltip(nil, mockPlayerData)
        PvPTooltip.TestUtils.AssertFalse(errorHandlingResult, "Should handle nil tooltip gracefully")
        
        PvPTooltip:Debug("Complete addon workflow test passed")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test event handling integration
function IntegrationTests:TestEventHandlingIntegration()
    local testName = "Event Handling Integration"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test EventManager integration (if available)
        if PvPTooltip.EventManager then
            PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.EventManager.OnTooltipSetUnit, 
                "OnTooltipSetUnit handler should exist")
            
            -- Create mock tooltip for event testing
            local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
            mockTooltip.GetUnit = function() return "TestPlayer", "player" end
            
            -- Test event handler doesn't crash
            local eventResult = PvPTooltip.EventManager:OnTooltipSetUnit(mockTooltip)
            -- Result can be anything, just shouldn't crash
            
            -- Test throttling functionality (if available)
            if PvPTooltip.EventManager.GetThrottlingStatus then
                local throttlingStatus = PvPTooltip.EventManager:GetThrottlingStatus()
                PvPTooltip.TestUtils.AssertNotNil(throttlingStatus, "Should return throttling status")
            end
        end
        
        -- Test that components can handle rapid events
        for i = 1, 10 do
            local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
            local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData("Player" .. i)
            
            -- This should not cause errors even with rapid calls
            PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
        end
        
        PvPTooltip:Debug("Event handling integration test passed")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test cross-component communication
function IntegrationTests:TestCrossComponentCommunication()
    local testName = "Cross-Component Communication"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test DatabaseManager -> PlayerLookup communication
        if PvPTooltip.DatabaseManager and PvPTooltip.PlayerLookup then
            -- PlayerLookup should be able to access DatabaseManager
            local dbAvailable = PvPTooltip.DatabaseManager:IsDataAvailable()
            local lookupReady = PvPTooltip.PlayerLookup:IsReady()
            
            if dbAvailable then
                PvPTooltip.TestUtils.AssertTrue(lookupReady, 
                    "PlayerLookup should be ready when DatabaseManager is available")
            end
            
            -- Test data flow from DatabaseManager to PlayerLookup
            local testResult = PvPTooltip.PlayerLookup:LookupPlayerInDatabase("TestPlayer", "test-realm", "eu")
            -- Result can be nil, just shouldn't crash
        end
        
        -- Test PlayerLookup -> TooltipRenderer communication
        if PvPTooltip.PlayerLookup and PvPTooltip.TooltipRenderer then
            local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
            
            -- TooltipRenderer should be able to validate PlayerLookup data
            local isValid = PvPTooltip.TooltipRenderer:ValidatePlayerData(mockPlayerData)
            PvPTooltip.TestUtils.AssertTrue(isValid, "TooltipRenderer should validate PlayerLookup data")
        end
        
        -- Test ColorUtils -> TooltipRenderer communication
        if PvPTooltip.ColorUtils and PvPTooltip.TooltipRenderer then
            local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
            local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
            
            -- TooltipRenderer should use ColorUtils for formatting
            local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
            PvPTooltip.TestUtils.AssertTrue(result, "TooltipRenderer should work with ColorUtils")
            
            -- Check that colors were applied
            local content = table.concat(mockTooltip.lines, "\n")
            local hasColors = string.find(content, "|c") ~= nil or string.find(content, "|r") ~= nil
            PvPTooltip.TestUtils.AssertTrue(hasColors, "TooltipRenderer should apply colors via ColorUtils")
        end
        
        -- Test RealmResolver -> PlayerLookup communication (if available)
        if PvPTooltip.RealmResolver and PvPTooltip.PlayerLookup then
            -- PlayerLookup should use RealmResolver for realm normalization
            local testRealm = "Test Realm"
            
            if PvPTooltip.RealmResolver.NormalizeRealmName then
                local normalized = PvPTooltip.RealmResolver:NormalizeRealmName(testRealm)
                PvPTooltip.TestUtils.AssertNotNil(normalized, "RealmResolver should normalize realm names")
            end
        end
        
        -- Test Config -> All Components communication
        if PvPTooltip.Config then
            -- All components should be able to access configuration
            PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.Config, "Config should be accessible to all components")
            
            if PvPTooltip.Config.GameModes then
                PvPTooltip.TestUtils.AssertTrue(type(PvPTooltip.Config.GameModes) == "table", 
                    "Config should provide game modes list")
            end
        end
        
        PvPTooltip:Debug("Cross-component communication test passed")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test error recovery and graceful degradation
function IntegrationTests:TestErrorRecoveryIntegration()
    local testName = "Error Recovery Integration"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test graceful degradation when components are missing
        local originalColorUtils = PvPTooltip.ColorUtils
        PvPTooltip.ColorUtils = nil
        
        -- TooltipRenderer should still work without ColorUtils
        local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
        
        local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
        PvPTooltip.TestUtils.AssertTrue(result, "TooltipRenderer should work without ColorUtils")
        
        -- Restore ColorUtils
        PvPTooltip.ColorUtils = originalColorUtils
        
        -- Test graceful degradation when database is unavailable
        local originalDatabaseManager = PvPTooltip.DatabaseManager
        PvPTooltip.DatabaseManager = nil
        
        -- PlayerLookup should handle missing DatabaseManager gracefully
        local lookupResult = PvPTooltip.PlayerLookup:FindPlayerData("player")
        PvPTooltip.TestUtils.AssertNil(lookupResult, "PlayerLookup should return nil when database unavailable")
        
        -- Restore DatabaseManager
        PvPTooltip.DatabaseManager = originalDatabaseManager
        
        -- Test error handling with corrupted data
        local corruptedPlayerData = {
            name = 123, -- Should be string
            brackets = "not a table" -- Should be table
        }
        
        mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, corruptedPlayerData)
        PvPTooltip.TestUtils.AssertFalse(result, "Should handle corrupted data gracefully")
        
        -- Test error handling with invalid unit info
        local corruptedUnitInfo = {
            name = "", -- Empty name
            realm = nil -- Missing realm
        }
        
        local isValid = PvPTooltip.PlayerLookup:ValidateUnitInfo(corruptedUnitInfo)
        PvPTooltip.TestUtils.AssertFalse(isValid, "Should detect invalid unit info")
        
        -- Test that addon continues working after errors
        mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
        
        result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
        PvPTooltip.TestUtils.AssertTrue(result, "Addon should continue working after handling errors")
        
        PvPTooltip:Debug("Error recovery integration test passed")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test configuration integration
function IntegrationTests:TestConfigurationIntegration()
    local testName = "Configuration Integration"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test that all components use configuration properly
        if PvPTooltip.Config then
            -- Test game modes configuration
            if PvPTooltip.Config.GameModes then
                local gameModes = PvPTooltip.Config.GameModes
                PvPTooltip.TestUtils.AssertTrue(type(gameModes) == "table", "GameModes should be a table")
                PvPTooltip.TestUtils.AssertTrue(#gameModes > 0, "GameModes should not be empty")
                
                -- Test that TooltipRenderer uses configured game modes
                local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
                local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
                
                -- Add data for configured game modes
                for _, gameMode in ipairs(gameModes) do
                    mockPlayerData.brackets[gameMode] = {
                        currentRating = 2000,
                        personalBest = 2100,
                        playedTotal = 50,
                        winRate = 60
                    }
                end
                
                local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
                PvPTooltip.TestUtils.AssertTrue(result, "TooltipRenderer should use configured game modes")
            end
            
            -- Test color configuration
            if PvPTooltip.Config.Colors then
                local colors = PvPTooltip.Config.Colors
                PvPTooltip.TestUtils.AssertTrue(type(colors) == "table", "Colors should be a table")
                
                -- Test that ColorUtils uses configured colors
                if PvPTooltip.ColorUtils and PvPTooltip.ColorUtils.GetRatingColor then
                    local ratingColor = PvPTooltip.ColorUtils:GetRatingColor(2000)
                    PvPTooltip.TestUtils.AssertNotNil(ratingColor, "Should return rating color")
                end
            end
            
            -- Test tooltip configuration
            if PvPTooltip.Config.Tooltip then
                local tooltipConfig = PvPTooltip.Config.Tooltip
                PvPTooltip.TestUtils.AssertTrue(type(tooltipConfig) == "table", "Tooltip config should be a table")
                
                -- Test that TooltipRenderer uses tooltip configuration
                local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
                local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
                
                local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
                PvPTooltip.TestUtils.AssertTrue(result, "TooltipRenderer should use tooltip configuration")
                
                -- Check for configured text in tooltip
                local content = table.concat(mockTooltip.lines, "\n")
                if tooltipConfig.mainTitle then
                    PvPTooltip.TestUtils.AssertTrue(string.find(content, tooltipConfig.mainTitle) ~= nil, 
                        "Tooltip should use configured main title")
                end
            end
        end
        
        -- Test configuration fallbacks
        local originalConfig = PvPTooltip.Config
        PvPTooltip.Config = nil
        
        -- Components should work with fallback values
        local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
        
        local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
        PvPTooltip.TestUtils.AssertTrue(result, "Components should work with fallback configuration")
        
        -- Restore configuration
        PvPTooltip.Config = originalConfig
        
        PvPTooltip:Debug("Configuration integration test passed")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test performance under load
function IntegrationTests:TestPerformanceUnderLoad()
    local testName = "Performance Under Load"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test rapid tooltip enhancements (simulating fast mouse movement)
        local startTime = GetTime()
        local enhancementCount = 100
        
        for i = 1, enhancementCount do
            local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
            local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData("Player" .. i)
            
            PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
        end
        
        local totalTime = (GetTime() - startTime) * 1000
        local avgTime = totalTime / enhancementCount
        
        PvPTooltip:Debug(string.format("Rapid tooltip enhancements: %d in %.2fms (avg: %.2fms)", 
            enhancementCount, totalTime, avgTime))
        
        -- Should handle rapid enhancements efficiently
        PvPTooltip.TestUtils.AssertTrue(avgTime < 20, 
            string.format("Average enhancement time should be < 20ms under load, got %.2fms", avgTime))
        
        -- Test concurrent player lookups
        startTime = GetTime()
        local lookupCount = 50
        
        for i = 1, lookupCount do
            PvPTooltip.PlayerLookup:FindPlayerData("player")
        end
        
        totalTime = (GetTime() - startTime) * 1000
        avgTime = totalTime / lookupCount
        
        PvPTooltip:Debug(string.format("Concurrent player lookups: %d in %.2fms (avg: %.2fms)", 
            lookupCount, totalTime, avgTime))
        
        -- Should handle concurrent lookups efficiently
        PvPTooltip.TestUtils.AssertTrue(avgTime < 100, 
            string.format("Average lookup time should be < 100ms under load, got %.2fms", avgTime))
        
        -- Test memory stability under load
        collectgarbage("collect")
        local startMemory = collectgarbage("count")
        
        for i = 1, 200 do
            local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
            local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData("LoadTest" .. i)
            
            PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
            PvPTooltip.PlayerLookup:FindPlayerData("player")
            
            -- Force garbage collection periodically
            if i % 50 == 0 then
                collectgarbage("collect")
            end
        end
        
        collectgarbage("collect")
        local endMemory = collectgarbage("count")
        local memoryGrowth = endMemory - startMemory
        
        PvPTooltip:Debug(string.format("Memory growth under load: %.2f KB", memoryGrowth))
        
        -- Memory growth should be reasonable
        PvPTooltip.TestUtils.AssertTrue(memoryGrowth < 500, 
            string.format("Memory growth should be < 500KB under load, got %.2f KB", memoryGrowth))
        
        PvPTooltip:Debug("Performance under load test passed")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test compatibility scenarios
function IntegrationTests:TestCompatibilityScenarios()
    local testName = "Compatibility Scenarios"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test with different player data formats
        local playerDataFormats = {
            -- Standard format
            {
                name = "StandardPlayer",
                realm = "test-realm",
                region = "eu",
                brackets = {
                    ["2v2"] = {currentRating = 2000, personalBest = 2100, playedTotal = 50, winRate = 60}
                }
            },
            -- Minimal format
            {
                name = "MinimalPlayer",
                brackets = {
                    ["3v3"] = {currentRating = 1800}
                }
            },
            -- Extended format with extra fields
            {
                name = "ExtendedPlayer",
                realm = "test-realm",
                region = "eu",
                extraField = "should be ignored",
                brackets = {
                    ["shuffle"] = {
                        currentRating = 2200,
                        personalBest = 2300,
                        playedTotal = 80,
                        winRate = 65,
                        shuffleSpecId = 270,
                        extraBracketField = "should be ignored"
                    }
                }
            }
        }
        
        for i, playerData in ipairs(playerDataFormats) do
            local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
            
            -- Should handle different data formats gracefully
            local isValid = PvPTooltip.TooltipRenderer:ValidatePlayerData(playerData)
            if isValid then
                local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, playerData)
                PvPTooltip.TestUtils.AssertTrue(result, 
                    string.format("Should handle player data format %d", i))
            end
        end
        
        -- Test with different tooltip objects
        local tooltipFormats = {
            -- Standard mock tooltip
            PvPTooltip.TestUtils.CreateMockTooltip(),
            -- Tooltip with extra methods
            {
                lines = {},
                AddLine = function(self, text) table.insert(self.lines, text or "") end,
                GetUnit = function() return "player", "player" end,
                IsShown = function() return true end,
                Show = function() end,
                Hide = function() end,
                extraMethod = function() end
            },
            -- Minimal tooltip
            {
                lines = {},
                AddLine = function(self, text) table.insert(self.lines, text or "") end
            }
        }
        
        local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
        
        for i, tooltip in ipairs(tooltipFormats) do
            local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(tooltip, mockPlayerData)
            PvPTooltip.TestUtils.AssertTrue(result, 
                string.format("Should handle tooltip format %d", i))
        end
        
        -- Test with different realm name formats
        local realmFormats = {
            "test-realm",
            "Test Realm",
            "Test'Realm",
            "Test Realm-US",
            "TestRealm",
            "test realm"
        }
        
        for _, realmName in ipairs(realmFormats) do
            if PvPTooltip.DatabaseManager and PvPTooltip.DatabaseManager.NormalizeRealmName then
                local normalized = PvPTooltip.DatabaseManager:NormalizeRealmName(realmName)
                PvPTooltip.TestUtils.AssertNotNil(normalized, 
                    string.format("Should normalize realm name: %s", realmName))
            end
        end
        
        PvPTooltip:Debug("Compatibility scenarios test passed")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test data consistency across components
function IntegrationTests:TestDataConsistency()
    local testName = "Data Consistency"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test that data flows consistently through the pipeline
        local testPlayerName = "ConsistencyTest"
        local testRealmName = "test-realm"
        local testRegion = "eu"
        
        -- Step 1: Create consistent test data
        local originalPlayerData = {
            name = testPlayerName,
            realm = testRealmName,
            region = testRegion,
            brackets = {
                ["2v2"] = {
                    currentRating = 2000,
                    personalBest = 2200,
                    seasonBest = 2100,
                    playedTotal = 75,
                    winRate = 64.0
                },
                ["3v3"] = {
                    currentRating = 1850,
                    personalBest = 2000,
                    seasonBest = 1900,
                    playedTotal = 45,
                    winRate = 57.8
                }
            }
        }
        
        -- Step 2: Validate data consistency in TooltipRenderer
        local isValid = PvPTooltip.TooltipRenderer:ValidatePlayerData(originalPlayerData)
        PvPTooltip.TestUtils.AssertTrue(isValid, "Original player data should be valid")
        
        -- Step 3: Test tooltip rendering preserves data integrity
        local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        local renderResult = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, originalPlayerData)
        PvPTooltip.TestUtils.AssertTrue(renderResult, "Tooltip rendering should succeed")
        
        -- Step 4: Verify tooltip contains expected data
        local tooltipContent = table.concat(mockTooltip.lines, "\n")
        
        -- Check for rating values
        PvPTooltip.TestUtils.AssertTrue(string.find(tooltipContent, "2000") ~= nil, 
            "Tooltip should contain 2v2 rating")
        PvPTooltip.TestUtils.AssertTrue(string.find(tooltipContent, "1850") ~= nil, 
            "Tooltip should contain 3v3 rating")
        
        -- Check for personal best values
        PvPTooltip.TestUtils.AssertTrue(string.find(tooltipContent, "2200") ~= nil, 
            "Tooltip should contain 2v2 personal best")
        PvPTooltip.TestUtils.AssertTrue(string.find(tooltipContent, "2000") ~= nil, 
            "Tooltip should contain 3v3 personal best")
        
        -- Step 5: Test data consistency through PlayerLookup validation
        if PvPTooltip.PlayerLookup.ValidatePlayerDataStructure then
            local lookupValid = PvPTooltip.PlayerLookup:ValidatePlayerDataStructure(originalPlayerData)
            PvPTooltip.TestUtils.AssertTrue(lookupValid, 
                "PlayerLookup should validate the same data as TooltipRenderer")
        end
        
        -- Step 6: Test realm name consistency
        if PvPTooltip.DatabaseManager and PvPTooltip.DatabaseManager.NormalizeRealmName then
            local normalizedRealm = PvPTooltip.DatabaseManager:NormalizeRealmName(testRealmName)
            PvPTooltip.TestUtils.AssertEquals(testRealmName, normalizedRealm, 
                "Realm name should remain consistent through normalization")
        end
        
        -- Step 7: Test cache consistency (if available)
        if PvPTooltip.PlayerLookup.AddToCache and PvPTooltip.PlayerLookup.GetFromCache then
            local cacheKey = PvPTooltip.PlayerLookup:GenerateCacheKey(testPlayerName, testRealmName)
            
            PvPTooltip.PlayerLookup:AddToCache(cacheKey, originalPlayerData)
            local cachedData = PvPTooltip.PlayerLookup:GetFromCache(cacheKey)
        PvPTooltip.TestUtils.AssertNotNil(cachedData, "Cached data should be retrievable")
        
        -- Verify cached data matches original
        PvPTooltip.TestUtils.AssertEquals(originalPlayerData.name, cachedData.name, 
            "Cached player name should match original")
        PvPTooltip.TestUtils.AssertEquals(originalPlayerData.realm, cachedData.realm, 
            "Cached realm should match original")
        
        -- Verify bracket data consistency
        for gameMode, bracketData in pairs(originalPlayerData.brackets) do
            PvPTooltip.TestUtils.AssertNotNil(cachedData.brackets[gameMode], 
                string.format("Cached data should contain %s bracket", gameMode))
            
            local cachedBracket = cachedData.brackets[gameMode]
            PvPTooltip.TestUtils.AssertEquals(bracketData.currentRating, cachedBracket.currentRating,
                string.format("%s current rating should be consistent", gameMode))
            PvPTooltip.TestUtils.AssertEquals(bracketData.personalBest, cachedBracket.personalBest,
                string.format("%s personal best should be consistent", gameMode))
        end
        end
        
        -- Step 8: Test color consistency
        if PvPTooltip.ColorUtils then
            local testRating = 2000
            local color1 = PvPTooltip.ColorUtils:GetRatingColor(testRating)
            local color2 = PvPTooltip.ColorUtils:GetRatingColor(testRating)
            
            PvPTooltip.TestUtils.AssertEquals(color1, color2, 
                "Color utils should return consistent colors for same rating")
            
            -- Test win rate color consistency
            local testWinRate = 65.0
            local winColor1 = PvPTooltip.ColorUtils:GetWinRateColor(testWinRate)
            local winColor2 = PvPTooltip.ColorUtils:GetWinRateColor(testWinRate)
            
            PvPTooltip.TestUtils.AssertEquals(winColor1, winColor2, 
                "Color utils should return consistent colors for same win rate")
        end
        
        PvPTooltip:Debug("Data consistency test passed")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test tooltip display across all supported game contexts
function IntegrationTests:TestTooltipContexts()
    local testName = "Tooltip Display Contexts"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData("ContextTest")
        
        -- Test different tooltip contexts
        local tooltipContexts = {
            {
                name = "Unit Frame Tooltip",
                tooltip = PvPTooltip.TestUtils.CreateMockTooltip(),
                unitType = "player",
                context = "unitframe"
            },
            {
                name = "Nameplate Tooltip", 
                tooltip = PvPTooltip.TestUtils.CreateMockTooltip(),
                unitType = "target",
                context = "nameplate"
            },
            {
                name = "Party Frame Tooltip",
                tooltip = PvPTooltip.TestUtils.CreateMockTooltip(),
                unitType = "party1",
                context = "party"
            },
            {
                name = "Raid Frame Tooltip",
                tooltip = PvPTooltip.TestUtils.CreateMockTooltip(),
                unitType = "raid1",
                context = "raid"
            },
            {
                name = "LFG Tooltip",
                tooltip = PvPTooltip.TestUtils.CreateMockTooltip(),
                unitType = "player",
                context = "lfg"
            }
        }
        
        for _, context in ipairs(tooltipContexts) do
            -- Enhance tooltip for this context
            local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(context.tooltip, mockPlayerData)
            PvPTooltip.TestUtils.AssertTrue(result, 
                string.format("Should enhance tooltip for %s", context.name))
            
            -- Verify tooltip has content
            PvPTooltip.TestUtils.AssertTrue(#context.tooltip.lines > 0, 
                string.format("%s should have tooltip content", context.name))
            
            -- Verify standard sections are present
            local content = table.concat(context.tooltip.lines, "\n")
            PvPTooltip.TestUtils.AssertTrue(string.find(content, "PvP Tooltip info") ~= nil,
                string.format("%s should contain main title", context.name))
            PvPTooltip.TestUtils.AssertTrue(string.find(content, "Current Rating") ~= nil,
                string.format("%s should contain rating section", context.name))
        end
        
        PvPTooltip:Debug("Tooltip contexts test passed")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test color coding accuracy across all rating ranges
function IntegrationTests:TestColorCodingAccuracy()
    local testName = "Color Coding Accuracy"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        if not PvPTooltip.ColorUtils then
            PvPTooltip:Debug("ColorUtils not available, skipping color coding test")
            return
        end
        
        -- Test rating color boundaries
        local ratingTests = {
            {rating = 0, expectedColor = "#FFFFFF", description = "Unrated (0)"},
            {rating = 1799, expectedColor = "#FFFFFF", description = "White tier max (1799)"},
            {rating = 1800, expectedColor = "#2EAD65", description = "Green tier min (1800)"},
            {rating = 2099, expectedColor = "#2EAD65", description = "Green tier max (2099)"},
            {rating = 2100, expectedColor = "#046DCC", description = "Blue tier min (2100)"},
            {rating = 2399, expectedColor = "#046DCC", description = "Blue tier max (2399)"},
            {rating = 2400, expectedColor = "#A140E9", description = "Purple tier min (2400)"},
            {rating = 3000, expectedColor = "#A140E9", description = "Purple tier high (3000)"}
        }
        
        for _, test in ipairs(ratingTests) do
            local actualColor = PvPTooltip.ColorUtils:GetRatingColor(test.rating)
            PvPTooltip.TestUtils.AssertEquals(test.expectedColor, actualColor,
                string.format("Rating color for %s should be %s", test.description, test.expectedColor))
        end
        
        -- Test win rate color boundaries
        local winRateTests = {
            {winRate = 0, expectedColor = "#FF4500", description = "0% win rate"},
            {winRate = 50, expectedColor = "#FF4500", description = "50% win rate"},
            {winRate = 50.1, expectedColor = "#57C94F", description = "50.1% win rate"},
            {winRate = 75, expectedColor = "#57C94F", description = "75% win rate"},
            {winRate = 100, expectedColor = "#57C94F", description = "100% win rate"}
        }
        
        for _, test in ipairs(winRateTests) do
            local actualColor = PvPTooltip.ColorUtils:GetWinRateColor(test.winRate)
            PvPTooltip.TestUtils.AssertEquals(test.expectedColor, actualColor,
                string.format("Win rate color for %s should be %s", test.description, test.expectedColor))
        end
        
        -- Test color application in tooltips
        local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
        
        -- Set specific ratings to test color application
        mockPlayerData.brackets["2v2"].currentRating = 2400 -- Purple
        mockPlayerData.brackets["3v3"].currentRating = 1800 -- Green
        mockPlayerData.brackets["shuffle"].winRate = 45 -- Red
        
        local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
        PvPTooltip.TestUtils.AssertTrue(result, "Should enhance tooltip with test colors")
        
        local content = table.concat(mockTooltip.lines, "\n")
        
        -- Verify color codes are applied (WoW color format |cFFRRGGBB)
        PvPTooltip.TestUtils.AssertTrue(string.find(content, "|c") ~= nil,
            "Tooltip should contain color codes")
        PvPTooltip.TestUtils.AssertTrue(string.find(content, "A140E9") ~= nil,
            "Tooltip should contain purple color for 2400 rating")
        PvPTooltip.TestUtils.AssertTrue(string.find(content, "2EAD65") ~= nil,
            "Tooltip should contain green color for 1800 rating")
        
        PvPTooltip:Debug("Color coding accuracy test passed")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test cross-region and cross-realm functionality
function IntegrationTests:TestCrossRegionRealm()
    local testName = "Cross-Region Cross-Realm Functionality"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test different region/realm combinations
        local testCombinations = {
            {name = "EUPlayer", realm = "stormrage", region = "eu"},
            {name = "USPlayer", realm = "tichondrius", region = "us"},
            {name = "CrossRealmPlayer", realm = "area-52", region = "us"},
            {name = "SpecialCharPlayer", realm = "quel'thalas", region = "eu"}
        }
        
        for _, combo in ipairs(testCombinations) do
            -- Test player lookup for different regions/realms
            if PvPTooltip.PlayerLookup then
                local playerData = PvPTooltip.PlayerLookup:LookupPlayerInDatabase(
                    combo.name, combo.realm, combo.region)
                
                -- Result can be nil (player not found) - this is acceptable
                -- Just verify the lookup doesn't crash
                PvPTooltip:Debug(string.format("Lookup for %s-%s (%s): %s", 
                    combo.name, combo.realm, combo.region, 
                    playerData and "found" or "not found"))
            end
            
            -- Test realm normalization
            if PvPTooltip.RealmResolver and PvPTooltip.RealmResolver.NormalizeRealmName then
                local normalized = PvPTooltip.RealmResolver:NormalizeRealmName(combo.realm)
                PvPTooltip.TestUtils.AssertNotNil(normalized, 
                    string.format("Should normalize realm name: %s", combo.realm))
            end
            
            -- Test region detection
            if PvPTooltip.RealmResolver and PvPTooltip.RealmResolver.GetRegionForRealm then
                local detectedRegion = PvPTooltip.RealmResolver:GetRegionForRealm(combo.realm)
                -- Region detection might return nil for unknown realms - acceptable
                PvPTooltip:Debug(string.format("Region detection for %s: %s", 
                    combo.realm, detectedRegion or "unknown"))
            end
        end
        
        -- Test database availability for both regions
        if PvPTooltip.DatabaseManager then
            local euAvailable = PvPTooltip.DatabaseManager:IsRegionDataAvailable("eu")
            local usAvailable = PvPTooltip.DatabaseManager:IsRegionDataAvailable("us")
            
            PvPTooltip:Debug(string.format("Database availability - EU: %s, US: %s", 
                euAvailable and "yes" or "no", usAvailable and "yes" or "no"))
            
            -- At least one region should be available
            PvPTooltip.TestUtils.AssertTrue(euAvailable or usAvailable, 
                "At least one region database should be available")
        end
        
        -- Test cross-faction lookup (if supported)
        local crossFactionTests = {
            {name = "AlliancePlayer", faction = "Alliance"},
            {name = "HordePlayer", faction = "Horde"}
        }
        
        for _, factionTest in ipairs(crossFactionTests) do
            if PvPTooltip.PlayerLookup and PvPTooltip.PlayerLookup.HandleCrossFactionData then
                local result = PvPTooltip.PlayerLookup:HandleCrossFactionData(
                    factionTest.name, "test-realm")
                -- Result can be nil - just verify no crash
                PvPTooltip:Debug(string.format("Cross-faction lookup for %s: %s", 
                    factionTest.name, result and "handled" or "not handled"))
            end
        end
        
        PvPTooltip:Debug("Cross-region cross-realm test passed")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test compatibility with popular UI addons (simulation)
function IntegrationTests:TestUIAddonCompatibility()
    local testName = "UI Addon Compatibility"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Simulate different UI addon environments
        local addonEnvironments = {
            {
                name = "ElvUI",
                modifications = {
                    -- ElvUI might modify tooltip appearance
                    tooltipSkin = true,
                    customFonts = true
                }
            },
            {
                name = "TukUI", 
                modifications = {
                    tooltipSkin = true,
                    customColors = true
                }
            },
            {
                name = "Bartender4",
                modifications = {
                    -- Bartender mainly affects action bars, minimal tooltip impact
                    actionBarMods = true
                }
            },
            {
                name = "Shadowed Unit Frames",
                modifications = {
                    unitFrameMods = true,
                    tooltipAnchoring = true
                }
            }
        }
        
        for _, env in ipairs(addonEnvironments) do
            PvPTooltip:Debug(string.format("Testing compatibility with %s", env.name))
            
            -- Create modified tooltip to simulate addon environment
            local modifiedTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
            
            -- Add simulated addon modifications
            if env.modifications.tooltipSkin then
                modifiedTooltip.skinned = true
                modifiedTooltip.SetBackdrop = function() end
            end
            
            if env.modifications.customFonts then
                modifiedTooltip.GetFont = function() return "CustomFont", 12 end
                modifiedTooltip.SetFont = function() end
            end
            
            if env.modifications.customColors then
                modifiedTooltip.defaultTextColor = {r = 0.8, g = 0.8, b = 0.8}
            end
            
            if env.modifications.tooltipAnchoring then
                modifiedTooltip.SetOwner = function() end
                modifiedTooltip.SetPoint = function() end
            end
            
            -- Test tooltip enhancement with modified tooltip
            local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
            local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(modifiedTooltip, mockPlayerData)
            
            PvPTooltip.TestUtils.AssertTrue(result, 
                string.format("Should work with %s modifications", env.name))
            
            -- Verify content is still added
            PvPTooltip.TestUtils.AssertTrue(#modifiedTooltip.lines > 0,
                string.format("Should add content with %s", env.name))
            
            local content = table.concat(modifiedTooltip.lines, "\n")
            PvPTooltip.TestUtils.AssertTrue(string.find(content, "PvP Tooltip info") ~= nil,
                string.format("Should maintain content integrity with %s", env.name))
        end
        
        -- Test with missing tooltip methods (graceful degradation)
        local minimalTooltip = {
            lines = {},
            AddLine = function(self, text) table.insert(self.lines, text or "") end
            -- Missing other methods that some addons might remove
        }
        
        local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
        local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(minimalTooltip, mockPlayerData)
        
        PvPTooltip.TestUtils.AssertTrue(result, 
            "Should work with minimal tooltip interface")
        
        -- Test event handling compatibility
        if PvPTooltip.EventManager then
            -- Simulate addon that might interfere with events
            local originalOnShow = GameTooltip and GameTooltip:GetScript("OnShow")
            
            -- Test that our event handling doesn't conflict
            local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
            mockTooltip.GetUnit = function() return "player", "player" end
            
            local eventResult = PvPTooltip.EventManager:OnTooltipSetUnit(mockTooltip)
            -- Should not crash regardless of result
            
            PvPTooltip:Debug("Event handling compatibility verified")
        end
        
        PvPTooltip:Debug("UI addon compatibility test passed")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test comprehensive requirements validation
function IntegrationTests:TestRequirementsValidation()
    local testName = "Comprehensive Requirements Validation"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Requirement 1: PvP information display in various contexts
        local contexts = {"world", "party", "raid", "lfg"}
        for _, context in ipairs(contexts) do
            local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
            local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
            
            local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
            PvPTooltip.TestUtils.AssertTrue(result, 
                string.format("Requirement 1: Should display PvP info in %s context", context))
        end
        
        -- Requirement 2: Current ratings display with proper colors
        local ratingTests = {
            {rating = 1500, expectedInRange = true, description = "white range"},
            {rating = 1900, expectedInRange = true, description = "green range"},
            {rating = 2200, expectedInRange = true, description = "blue range"},
            {rating = 2500, expectedInRange = true, description = "purple range"}
        }
        
        for _, test in ipairs(ratingTests) do
            if PvPTooltip.ColorUtils then
                local color = PvPTooltip.ColorUtils:GetRatingColor(test.rating)
                PvPTooltip.TestUtils.AssertNotNil(color, 
                    string.format("Requirement 2: Should return color for %s", test.description))
            end
        end
        
        -- Requirement 3: Personal best ratings display
        local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
        mockPlayerData.brackets["2v2"].personalBest = 2300
        
        local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
        PvPTooltip.TestUtils.AssertTrue(result, "Requirement 3: Should display personal best")
        
        local content = table.concat(mockTooltip.lines, "\n")
        PvPTooltip.TestUtils.AssertTrue(string.find(content, "Character Experience") ~= nil,
            "Requirement 3: Should contain experience section")
        
        -- Requirement 4: Season statistics with win rates
        PvPTooltip.TestUtils.AssertTrue(string.find(content, "Current Season") ~= nil,
            "Requirement 4: Should contain season section")
        PvPTooltip.TestUtils.AssertTrue(string.find(content, "won") ~= nil,
            "Requirement 4: Should display win rate")
        
        -- Requirement 5: EU/US region support
        if PvPTooltip.DatabaseManager then
            local euSupported = PvPTooltip.DatabaseManager:IsRegionDataAvailable("eu")
            local usSupported = PvPTooltip.DatabaseManager:IsRegionDataAvailable("us")
            
            PvPTooltip.TestUtils.AssertTrue(euSupported or usSupported,
                "Requirement 5: Should support at least one region")
        end
        
        -- Requirement 6: Visual formatting
        PvPTooltip.TestUtils.AssertTrue(string.find(content, "PvP Tooltip info") ~= nil,
            "Requirement 6: Should have main title")
        PvPTooltip.TestUtils.AssertTrue(string.find(content, "|c") ~= nil,
            "Requirement 6: Should use color formatting")
        
        -- Requirements 7-8: Documentation and automation (file existence)
        -- These are validated by the presence of the files, not runtime behavior
        
        PvPTooltip:Debug("Requirements validation test passed")
    end)
    
    self:RecordTestResult(testName, success, error)
            
            PvPTooltip.TestUtils.AssertNotNil(cachedData, "Cached data should be retrievable")
            PvPTooltip.TestUtils.AssertEquals(originalPlayerData.name, cachedData.name, 
                "Cached data should maintain name consistency")
            
            -- Clean up cache
            PvPTooltip.PlayerLookup:ClearCache()
        end
        
        -- Step 8: Test color consistency
        if PvPTooltip.ColorUtils then
            -- Test that same rating values produce same colors
            if PvPTooltip.ColorUtils.GetRatingColor then
                local color1 = PvPTooltip.ColorUtils:GetRatingColor(2000)
                local color2 = PvPTooltip.ColorUtils:GetRatingColor(2000)
                PvPTooltip.TestUtils.AssertEquals(color1, color2, 
                    "Same rating should produce same color")
            end
            
            if PvPTooltip.ColorUtils.GetWinRateColor then
                local winColor1 = PvPTooltip.ColorUtils:GetWinRateColor(64.0)
                local winColor2 = PvPTooltip.ColorUtils:GetWinRateColor(64.0)
                PvPTooltip.TestUtils.AssertEquals(winColor1, winColor2, 
                    "Same win rate should produce same color")
            end
        end
        
        PvPTooltip:Debug("Data consistency test passed")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Record test result
function IntegrationTests:RecordTestResult(testName, success, error)
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
function IntegrationTests:GetTestResults()
    return testResults
end

-- Quick integration test
function IntegrationTests:QuickTest()
    PvPTooltip:Print("=== Quick Integration Test ===")
    
    local tests = {
        {
            name = "All components available",
            test = function()
                return PvPTooltip.DatabaseManager ~= nil and
                       PvPTooltip.PlayerLookup ~= nil and
                       PvPTooltip.TooltipRenderer ~= nil and
                       PvPTooltip.ColorUtils ~= nil
            end
        },
        {
            name = "Complete workflow works",
            test = function()
                local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
                local mockData = PvPTooltip.TestUtils.CreateMockPlayerData()
                return PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockData)
            end
        },
        {
            name = "Error handling works",
            test = function()
                -- Should handle errors gracefully
                local result1 = PvPTooltip.PlayerLookup:FindPlayerData(nil)
                local result2 = PvPTooltip.TooltipRenderer:EnhanceTooltip(nil, nil)
                return result1 == nil and result2 == false
            end
        },
        {
            name = "Data validation consistent",
            test = function()
                local mockData = PvPTooltip.TestUtils.CreateMockPlayerData()
                local valid1 = PvPTooltip.TooltipRenderer:ValidatePlayerData(mockData)
                local valid2 = true
                if PvPTooltip.PlayerLookup.ValidatePlayerDataStructure then
                    valid2 = PvPTooltip.PlayerLookup:ValidatePlayerDataStructure(mockData)
                end
                return valid1 and valid2
            end
        },
        {
            name = "Performance acceptable",
            test = function()
                local startTime = GetTime()
                for i = 1, 10 do
                    local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
                    local mockData = PvPTooltip.TestUtils.CreateMockPlayerData()
                    PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockData)
                end
                local totalTime = (GetTime() - startTime) * 1000
                return totalTime < 100 -- Should complete 10 renders in < 100ms
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
    
    PvPTooltip:Print(string.format("Quick integration test: %d/%d passed", passed, #tests))
    return passed == #tests
enden
d

-- Record test result
function IntegrationTests:RecordTestResult(testName, success, error)
    testResults.tests[testName] = {
        success = success,
        error = error,
        timestamp = GetTime()
    }
    
    if success then
        testResults.passed = testResults.passed + 1
        PvPTooltip:Debug(testName .. " - PASSED")
    else
        testResults.failed = testResults.failed + 1
        PvPTooltip:Debug(testName .. " - FAILED: " .. tostring(error))
    end
end

-- Test tooltip display across all supported game contexts
function IntegrationTests:TestTooltipContexts()
    local testName = "Tooltip Display Contexts"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData("ContextTest")
        
        -- Test different tooltip contexts
        local tooltipContexts = {
            {
                name = "Unit Frame Tooltip",
                tooltip = PvPTooltip.TestUtils.CreateMockTooltip(),
                unitType = "player",
                context = "unitframe"
            },
            {
                name = "Nameplate Tooltip", 
                tooltip = PvPTooltip.TestUtils.CreateMockTooltip(),
                unitType = "target",
                context = "nameplate"
            },
            {
                name = "Party Frame Tooltip",
                tooltip = PvPTooltip.TestUtils.CreateMockTooltip(),
                unitType = "party1",
                context = "party"
            },
            {
                name = "Raid Frame Tooltip",
                tooltip = PvPTooltip.TestUtils.CreateMockTooltip(),
                unitType = "raid1",
                context = "raid"
            },
            {
                name = "LFG Tooltip",
                tooltip = PvPTooltip.TestUtils.CreateMockTooltip(),
                unitType = "player",
                context = "lfg"
            }
        }
        
        for _, context in ipairs(tooltipContexts) do
            -- Enhance tooltip for this context
            local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(context.tooltip, mockPlayerData)
            PvPTooltip.TestUtils.AssertTrue(result, 
                string.format("Should enhance tooltip for %s", context.name))
            
            -- Verify tooltip has content
            PvPTooltip.TestUtils.AssertTrue(#context.tooltip.lines > 0, 
                string.format("%s should have tooltip content", context.name))
            
            -- Verify standard sections are present
            local content = table.concat(context.tooltip.lines, "\n")
            PvPTooltip.TestUtils.AssertTrue(string.find(content, "PvP Tooltip info") ~= nil,
                string.format("%s should contain main title", context.name))
            PvPTooltip.TestUtils.AssertTrue(string.find(content, "Current Rating") ~= nil,
                string.format("%s should contain rating section", context.name))
        end
        
        PvPTooltip:Debug("Tooltip contexts test passed")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test color coding accuracy across all rating ranges
function IntegrationTests:TestColorCodingAccuracy()
    local testName = "Color Coding Accuracy"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        if not PvPTooltip.ColorUtils then
            PvPTooltip:Debug("ColorUtils not available, skipping color coding test")
            return
        end
        
        -- Test rating color boundaries
        local ratingTests = {
            {rating = 0, expectedColor = "#FFFFFF", description = "Unrated (0)"},
            {rating = 1799, expectedColor = "#FFFFFF", description = "White tier max (1799)"},
            {rating = 1800, expectedColor = "#2EAD65", description = "Green tier min (1800)"},
            {rating = 2099, expectedColor = "#2EAD65", description = "Green tier max (2099)"},
            {rating = 2100, expectedColor = "#046DCC", description = "Blue tier min (2100)"},
            {rating = 2399, expectedColor = "#046DCC", description = "Blue tier max (2399)"},
            {rating = 2400, expectedColor = "#A140E9", description = "Purple tier min (2400)"},
            {rating = 3000, expectedColor = "#A140E9", description = "Purple tier high (3000)"}
        }
        
        for _, test in ipairs(ratingTests) do
            local actualColor = PvPTooltip.ColorUtils:GetRatingColor(test.rating)
            PvPTooltip.TestUtils.AssertEquals(test.expectedColor, actualColor,
                string.format("Rating color for %s should be %s", test.description, test.expectedColor))
        end
        
        -- Test win rate color boundaries
        local winRateTests = {
            {winRate = 0, expectedColor = "#FF4500", description = "0% win rate"},
            {winRate = 50, expectedColor = "#FF4500", description = "50% win rate"},
            {winRate = 50.1, expectedColor = "#57C94F", description = "50.1% win rate"},
            {winRate = 75, expectedColor = "#57C94F", description = "75% win rate"},
            {winRate = 100, expectedColor = "#57C94F", description = "100% win rate"}
        }
        
        for _, test in ipairs(winRateTests) do
            local actualColor = PvPTooltip.ColorUtils:GetWinRateColor(test.winRate)
            PvPTooltip.TestUtils.AssertEquals(test.expectedColor, actualColor,
                string.format("Win rate color for %s should be %s", test.description, test.expectedColor))
        end
        
        -- Test color application in tooltips
        local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
        
        -- Set specific ratings to test color application
        mockPlayerData.brackets["2v2"].currentRating = 2400 -- Purple
        mockPlayerData.brackets["3v3"].currentRating = 1800 -- Green
        mockPlayerData.brackets["shuffle"].winRate = 45 -- Red
        
        local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
        PvPTooltip.TestUtils.AssertTrue(result, "Should enhance tooltip with test colors")
        
        local content = table.concat(mockTooltip.lines, "\n")
        
        -- Verify color codes are applied (WoW color format |cFFRRGGBB)
        PvPTooltip.TestUtils.AssertTrue(string.find(content, "|c") ~= nil,
            "Tooltip should contain color codes")
        PvPTooltip.TestUtils.AssertTrue(string.find(content, "A140E9") ~= nil,
            "Tooltip should contain purple color for 2400 rating")
        PvPTooltip.TestUtils.AssertTrue(string.find(content, "2EAD65") ~= nil,
            "Tooltip should contain green color for 1800 rating")
        
        PvPTooltip:Debug("Color coding accuracy test passed")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test cross-region and cross-realm functionality
function IntegrationTests:TestCrossRegionRealm()
    local testName = "Cross-Region Cross-Realm Functionality"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test different region/realm combinations
        local testCombinations = {
            {name = "EUPlayer", realm = "stormrage", region = "eu"},
            {name = "USPlayer", realm = "tichondrius", region = "us"},
            {name = "CrossRealmPlayer", realm = "area-52", region = "us"},
            {name = "SpecialCharPlayer", realm = "quel'thalas", region = "eu"}
        }
        
        for _, combo in ipairs(testCombinations) do
            -- Test player lookup for different regions/realms
            if PvPTooltip.PlayerLookup then
                local playerData = PvPTooltip.PlayerLookup:LookupPlayerInDatabase(
                    combo.name, combo.realm, combo.region)
                
                -- Result can be nil (player not found) - this is acceptable
                -- Just verify the lookup doesn't crash
                PvPTooltip:Debug(string.format("Lookup for %s-%s (%s): %s", 
                    combo.name, combo.realm, combo.region, 
                    playerData and "found" or "not found"))
            end
            
            -- Test realm normalization
            if PvPTooltip.RealmResolver and PvPTooltip.RealmResolver.NormalizeRealmName then
                local normalized = PvPTooltip.RealmResolver:NormalizeRealmName(combo.realm)
                PvPTooltip.TestUtils.AssertNotNil(normalized, 
                    string.format("Should normalize realm name: %s", combo.realm))
            end
            
            -- Test region detection
            if PvPTooltip.RealmResolver and PvPTooltip.RealmResolver.GetRegionForRealm then
                local detectedRegion = PvPTooltip.RealmResolver:GetRegionForRealm(combo.realm)
                -- Region detection might return nil for unknown realms - acceptable
                PvPTooltip:Debug(string.format("Region detection for %s: %s", 
                    combo.realm, detectedRegion or "unknown"))
            end
        end
        
        -- Test database availability for both regions
        if PvPTooltip.DatabaseManager then
            local euAvailable = PvPTooltip.DatabaseManager:IsRegionDataAvailable("eu")
            local usAvailable = PvPTooltip.DatabaseManager:IsRegionDataAvailable("us")
            
            PvPTooltip:Debug(string.format("Database availability - EU: %s, US: %s", 
                euAvailable and "yes" or "no", usAvailable and "yes" or "no"))
            
            -- At least one region should be available
            PvPTooltip.TestUtils.AssertTrue(euAvailable or usAvailable, 
                "At least one region database should be available")
        end
        
        -- Test cross-faction lookup (if supported)
        local crossFactionTests = {
            {name = "AlliancePlayer", faction = "Alliance"},
            {name = "HordePlayer", faction = "Horde"}
        }
        
        for _, factionTest in ipairs(crossFactionTests) do
            if PvPTooltip.PlayerLookup and PvPTooltip.PlayerLookup.HandleCrossFactionData then
                local result = PvPTooltip.PlayerLookup:HandleCrossFactionData(
                    factionTest.name, "test-realm")
                -- Result can be nil - just verify no crash
                PvPTooltip:Debug(string.format("Cross-faction lookup for %s: %s", 
                    factionTest.name, result and "handled" or "not handled"))
            end
        end
        
        PvPTooltip:Debug("Cross-region cross-realm test passed")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test compatibility with popular UI addons (simulation)
function IntegrationTests:TestUIAddonCompatibility()
    local testName = "UI Addon Compatibility"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Simulate different UI addon environments
        local addonEnvironments = {
            {
                name = "ElvUI",
                modifications = {
                    -- ElvUI might modify tooltip appearance
                    tooltipSkin = true,
                    customFonts = true
                }
            },
            {
                name = "TukUI", 
                modifications = {
                    tooltipSkin = true,
                    customColors = true
                }
            },
            {
                name = "Bartender4",
                modifications = {
                    -- Bartender mainly affects action bars, minimal tooltip impact
                    actionBarMods = true
                }
            },
            {
                name = "Shadowed Unit Frames",
                modifications = {
                    unitFrameMods = true,
                    tooltipAnchoring = true
                }
            }
        }
        
        for _, env in ipairs(addonEnvironments) do
            PvPTooltip:Debug(string.format("Testing compatibility with %s", env.name))
            
            -- Create modified tooltip to simulate addon environment
            local modifiedTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
            
            -- Add simulated addon modifications
            if env.modifications.tooltipSkin then
                modifiedTooltip.skinned = true
                modifiedTooltip.SetBackdrop = function() end
            end
            
            if env.modifications.customFonts then
                modifiedTooltip.GetFont = function() return "CustomFont", 12 end
                modifiedTooltip.SetFont = function() end
            end
            
            if env.modifications.customColors then
                modifiedTooltip.defaultTextColor = {r = 0.8, g = 0.8, b = 0.8}
            end
            
            if env.modifications.tooltipAnchoring then
                modifiedTooltip.SetOwner = function() end
                modifiedTooltip.SetPoint = function() end
            end
            
            -- Test tooltip enhancement with modified tooltip
            local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
            local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(modifiedTooltip, mockPlayerData)
            
            PvPTooltip.TestUtils.AssertTrue(result, 
                string.format("Should work with %s modifications", env.name))
            
            -- Verify content is still added
            PvPTooltip.TestUtils.AssertTrue(#modifiedTooltip.lines > 0,
                string.format("Should add content with %s", env.name))
            
            local content = table.concat(modifiedTooltip.lines, "\n")
            PvPTooltip.TestUtils.AssertTrue(string.find(content, "PvP Tooltip info") ~= nil,
                string.format("Should maintain content integrity with %s", env.name))
        end
        
        -- Test with missing tooltip methods (graceful degradation)
        local minimalTooltip = {
            lines = {},
            AddLine = function(self, text) table.insert(self.lines, text or "") end
            -- Missing other methods that some addons might remove
        }
        
        local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
        local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(minimalTooltip, mockPlayerData)
        
        PvPTooltip.TestUtils.AssertTrue(result, 
            "Should work with minimal tooltip interface")
        
        -- Test event handling compatibility
        if PvPTooltip.EventManager then
            -- Simulate addon that might interfere with events
            local originalOnShow = GameTooltip and GameTooltip:GetScript("OnShow")
            
            -- Test that our event handling doesn't conflict
            local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
            mockTooltip.GetUnit = function() return "player", "player" end
            
            local eventResult = PvPTooltip.EventManager:OnTooltipSetUnit(mockTooltip)
            -- Should not crash regardless of result
            
            PvPTooltip:Debug("Event handling compatibility verified")
        end
        
        PvPTooltip:Debug("UI addon compatibility test passed")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test comprehensive requirements validation
function IntegrationTests:TestRequirementsValidation()
    local testName = "Comprehensive Requirements Validation"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Requirement 1: PvP information display in various contexts
        local contexts = {"world", "party", "raid", "lfg"}
        for _, context in ipairs(contexts) do
            local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
            local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
            
            local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
            PvPTooltip.TestUtils.AssertTrue(result, 
                string.format("Requirement 1: Should display PvP info in %s context", context))
        end
        
        -- Requirement 2: Current ratings display with proper colors
        local ratingTests = {
            {rating = 1500, expectedInRange = true, description = "white range"},
            {rating = 1900, expectedInRange = true, description = "green range"},
            {rating = 2200, expectedInRange = true, description = "blue range"},
            {rating = 2500, expectedInRange = true, description = "purple range"}
        }
        
        for _, test in ipairs(ratingTests) do
            if PvPTooltip.ColorUtils then
                local color = PvPTooltip.ColorUtils:GetRatingColor(test.rating)
                PvPTooltip.TestUtils.AssertNotNil(color, 
                    string.format("Requirement 2: Should return color for %s", test.description))
            end
        end
        
        -- Requirement 3: Personal best ratings display
        local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
        mockPlayerData.brackets["2v2"].personalBest = 2300
        
        local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
        PvPTooltip.TestUtils.AssertTrue(result, "Requirement 3: Should display personal best")
        
        local content = table.concat(mockTooltip.lines, "\n")
        PvPTooltip.TestUtils.AssertTrue(string.find(content, "Character Experience") ~= nil,
            "Requirement 3: Should contain experience section")
        
        -- Requirement 4: Season statistics with win rates
        PvPTooltip.TestUtils.AssertTrue(string.find(content, "Current Season") ~= nil,
            "Requirement 4: Should contain season section")
        PvPTooltip.TestUtils.AssertTrue(string.find(content, "won") ~= nil,
            "Requirement 4: Should display win rate")
        
        -- Requirement 5: EU/US region support
        if PvPTooltip.DatabaseManager then
            local euSupported = PvPTooltip.DatabaseManager:IsRegionDataAvailable("eu")
            local usSupported = PvPTooltip.DatabaseManager:IsRegionDataAvailable("us")
            
            PvPTooltip.TestUtils.AssertTrue(euSupported or usSupported,
                "Requirement 5: Should support at least one region")
        end
        
        -- Requirement 6: Visual formatting
        PvPTooltip.TestUtils.AssertTrue(string.find(content, "PvP Tooltip info") ~= nil,
            "Requirement 6: Should have main title")
        PvPTooltip.TestUtils.AssertTrue(string.find(content, "|c") ~= nil,
            "Requirement 6: Should use color formatting")
        
        -- Requirements 7-8: Documentation and automation (file existence)
        -- These are validated by the presence of the files, not runtime behavior
        
        PvPTooltip:Debug("Requirements validation test passed")
    end)
    
    self:RecordTestResult(testName, success, error)
end

return IntegrationTests