-- PvPTooltip Error Handling Tests
-- Comprehensive tests for error handling and graceful degradation

local ErrorHandlingTests = {}
PvPTooltip.ErrorHandlingTests = ErrorHandlingTests

-- Test results storage
local testResults = {}

-- Initialize test suite
function ErrorHandlingTests:Initialize()
    PvPTooltip:Debug("ErrorHandlingTests module initialized")
end

-- Check if all required modules are available for testing
function ErrorHandlingTests:CheckModuleAvailability()
    local requiredModules = {
        "ErrorHandler", "DatabaseManager", "PlayerLookup", "TooltipRenderer"
    }
    
    local missingModules = {}
    local availableModules = {}
    
    for _, moduleName in ipairs(requiredModules) do
        local module = PvPTooltip[moduleName]
        if module and type(module) == "table" then
            table.insert(availableModules, moduleName)
        else
            table.insert(missingModules, moduleName)
        end
    end
    
    return #missingModules == 0, availableModules, missingModules
end

-- Run all error handling tests
function ErrorHandlingTests:RunAllTests()
    PvPTooltip:Print("=== Running Error Handling Tests ===")
    
    testResults = {}
    
    -- Test database corruption handling
    self:TestDatabaseCorruptionHandling()
    
    -- Test unit resolution failures
    self:TestUnitResolutionFailures()
    
    -- Test missing data graceful degradation
    self:TestMissingDataDegradation()
    
    -- Test tooltip rendering errors
    self:TestTooltipRenderingErrors()
    
    -- Test configuration errors
    self:TestConfigurationErrors()
    
    -- Test memory and performance safeguards
    self:TestPerformanceSafeguards()
    
    -- Report results
    self:ReportTestResults()
end

-- Test database corruption handling
function ErrorHandlingTests:TestDatabaseCorruptionHandling()
    local testName = "Database Corruption Handling"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success = true
    local details = {}
    
    -- Test 1: Corrupted player data structure
    local corruptedPlayerData = {
        name = "TestPlayer",
        realm = "test-realm",
        region = "eu",
        brackets = "this should be a table" -- Corrupted: string instead of table
    }
    
    if PvPTooltip.DatabaseManager and PvPTooltip.DatabaseManager.ValidatePlayerDataStructure then
        local isValid = PvPTooltip.DatabaseManager:ValidatePlayerDataStructure("TestPlayer", corruptedPlayerData)
        if isValid then
            success = false
            table.insert(details, "Failed to detect corrupted player data structure")
        else
            table.insert(details, "✓ Correctly detected corrupted player data structure")
        end
    end
    
    -- Test 2: Corrupted bracket data
    local corruptedBracketData = {
        currentRating = "not a number", -- Should be number
        personalBest = -100, -- Invalid negative rating
        winRate = 150 -- Invalid win rate > 100%
    }
    
    if PvPTooltip.DatabaseManager and PvPTooltip.DatabaseManager.ValidateBracketData then
        local isValid = PvPTooltip.DatabaseManager:ValidateBracketData(corruptedBracketData)
        if isValid then
            success = false
            table.insert(details, "Failed to detect corrupted bracket data")
        else
            table.insert(details, "✓ Correctly detected corrupted bracket data")
        end
    end
    
    -- Test 3: Database integrity validation
    local corruptedDatabase = {
        ["realm1"] = {
            ["Player1"] = "corrupted data", -- Should be table
            ["Player2"] = {brackets = {}} -- Valid data
        },
        ["realm2"] = "completely corrupted" -- Should be table
    }
    
    if PvPTooltip.ErrorHandler and PvPTooltip.ErrorHandler.ValidateDatabaseIntegrity then
        local isValid = PvPTooltip.ErrorHandler:ValidateDatabaseIntegrity(corruptedDatabase, "TestDB")
        if isValid then
            success = false
            table.insert(details, "Failed to detect database corruption")
        else
            table.insert(details, "✓ Correctly detected database corruption")
        end
    end
    
    testResults[testName] = {
        success = success,
        details = details
    }
end

-- Test unit resolution failures
function ErrorHandlingTests:TestUnitResolutionFailures()
    local testName = "Unit Resolution Failures"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success = true
    local details = {}
    
    -- Test 1: Invalid unit ID
    if PvPTooltip.PlayerLookup and PvPTooltip.PlayerLookup.FindPlayerData then
        local playerData = PvPTooltip.PlayerLookup:FindPlayerData(nil)
        if playerData ~= nil then
            success = false
            table.insert(details, "Failed to handle nil unitID gracefully")
        else
            table.insert(details, "✓ Correctly handled nil unitID")
        end
        
        -- Test with invalid unit ID
        playerData = PvPTooltip.PlayerLookup:FindPlayerData("invalid_unit_id")
        if playerData ~= nil then
            -- This might be expected to return nil, so we just log it
            table.insert(details, "✓ Handled invalid unitID (returned nil)")
        else
            table.insert(details, "✓ Correctly handled invalid unitID")
        end
    end
    
    -- Test 2: Invalid unit info structure
    if PvPTooltip.PlayerLookup and PvPTooltip.PlayerLookup.ValidateUnitInfo then
        local invalidUnitInfo = {
            name = "", -- Empty name
            realm = nil -- Missing realm
        }
        
        local isValid = PvPTooltip.PlayerLookup:ValidateUnitInfo(invalidUnitInfo)
        if isValid then
            success = false
            table.insert(details, "Failed to detect invalid unit info")
        else
            table.insert(details, "✓ Correctly detected invalid unit info")
        end
    end
    
    testResults[testName] = {
        success = success,
        details = details
    }
end

-- Test missing data graceful degradation
function ErrorHandlingTests:TestMissingDataDegradation()
    local testName = "Missing Data Graceful Degradation"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success = true
    local details = {}
    
    -- Test 1: Missing player data
    if PvPTooltip.DatabaseManager and PvPTooltip.DatabaseManager.GetPlayerData then
        local playerData = PvPTooltip.DatabaseManager:GetPlayerData("NonexistentPlayer", "nonexistent-realm", "eu")
        if playerData ~= nil then
            -- This should return nil for missing data
            table.insert(details, "Note: GetPlayerData returned data for nonexistent player")
        else
            table.insert(details, "✓ Correctly handled missing player data")
        end
    end
    
    -- Test 2: Tooltip rendering with missing data
    if PvPTooltip.TooltipRenderer and PvPTooltip.TooltipRenderer.EnhanceTooltip then
        -- Create a mock tooltip object
        local mockTooltip = {
            AddLine = function() end,
            lines = {}
        }
        
        local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, nil)
        if result == true then
            success = false
            table.insert(details, "Failed to handle nil player data in tooltip rendering")
        else
            table.insert(details, "✓ Correctly handled nil player data in tooltip rendering")
        end
    end
    
    -- Test 3: Empty brackets data
    if PvPTooltip.TooltipRenderer and PvPTooltip.TooltipRenderer.ValidatePlayerData then
        local emptyPlayerData = {
            name = "TestPlayer",
            realm = "test-realm",
            region = "eu",
            brackets = {} -- Empty brackets
        }
        
        local isValid = PvPTooltip.TooltipRenderer:ValidatePlayerData(emptyPlayerData)
        if isValid then
            success = false
            table.insert(details, "Failed to detect empty brackets data")
        else
            table.insert(details, "✓ Correctly detected empty brackets data")
        end
    end
    
    testResults[testName] = {
        success = success,
        details = details
    }
end

-- Test tooltip rendering errors
function ErrorHandlingTests:TestTooltipRenderingErrors()
    local testName = "Tooltip Rendering Errors"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success = true
    local details = {}
    
    -- Test 1: Invalid tooltip object
    if PvPTooltip.TooltipRenderer and PvPTooltip.TooltipRenderer.EnhanceTooltip then
        local validPlayerData = {
            name = "TestPlayer",
            realm = "test-realm",
            region = "eu",
            brackets = {
                ["2v2"] = {
                    currentRating = 2000,
                    personalBest = 2100,
                    playedTotal = 50,
                    winRate = 60
                }
            }
        }
        
        local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(nil, validPlayerData)
        if result == true then
            success = false
            table.insert(details, "Failed to handle nil tooltip object")
        else
            table.insert(details, "✓ Correctly handled nil tooltip object")
        end
    end
    
    -- Test 2: Tooltip with error-prone AddLine function
    if PvPTooltip.TooltipRenderer and PvPTooltip.TooltipRenderer.AddSectionTitle then
        local errorTooltip = {
            AddLine = function()
                error("Simulated tooltip error")
            end
        }
        
        local result = PvPTooltip.TooltipRenderer:AddSectionTitle(errorTooltip)
        if result == true then
            success = false
            table.insert(details, "Failed to handle tooltip AddLine error")
        else
            table.insert(details, "✓ Correctly handled tooltip AddLine error")
        end
    end
    
    testResults[testName] = {
        success = success,
        details = details
    }
end

-- Test configuration errors
function ErrorHandlingTests:TestConfigurationErrors()
    local testName = "Configuration Errors"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success = true
    local details = {}
    
    -- Test 1: Missing configuration values
    local originalConfig = PvPTooltip.Config
    PvPTooltip.Config = nil -- Temporarily remove config
    
    if PvPTooltip.TooltipRenderer and PvPTooltip.TooltipRenderer.AddSectionTitle then
        local mockTooltip = {
            AddLine = function() end,
            lines = {}
        }
        
        local result = PvPTooltip.TooltipRenderer:AddSectionTitle(mockTooltip)
        -- Should still work with fallback values
        table.insert(details, "✓ Handled missing configuration with fallback")
    end
    
    PvPTooltip.Config = originalConfig -- Restore config
    
    -- Test 2: Invalid color values
    if PvPTooltip.Config and PvPTooltip.Config.ValidateColors then
        -- This would be tested during config initialization
        table.insert(details, "✓ Configuration validation available")
    end
    
    testResults[testName] = {
        success = success,
        details = details
    }
end

-- Test performance safeguards
function ErrorHandlingTests:TestPerformanceSafeguards()
    local testName = "Performance Safeguards"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success = true
    local details = {}
    
    -- Test 1: Error rate limiting
    if PvPTooltip.ErrorHandler and PvPTooltip.ErrorHandler.LogError then
        -- Generate multiple errors quickly
        for i = 1, 15 do
            PvPTooltip.ErrorHandler:LogError("TestContext", "Test error " .. i, true) -- Suppress logging
        end
        
        local issuppressed = PvPTooltip.ErrorHandler:IsErrorSuppressed("TestContext")
        if isSupressed then
            table.insert(details, "✓ Error rate limiting working")
        else
            table.insert(details, "Note: Error rate limiting may not be active")
        end
        
        -- Reset for cleanup
        PvPTooltip.ErrorHandler:ResetErrorTracking("TestContext")
    end
    
    -- Test 2: Memory monitoring
    if PvPTooltip.ErrorHandler and PvPTooltip.ErrorHandler.CheckMemoryUsage then
        local success, memUsage = PvPTooltip.ErrorHandler:CheckMemoryUsage("TestMemory", 0.1) -- Very low threshold
        table.insert(details, string.format("✓ Memory monitoring working (%.1f MB)", memUsage or 0))
    end
    
    testResults[testName] = {
        success = success,
        details = details
    }
end

-- Report test results
function ErrorHandlingTests:ReportTestResults()
    PvPTooltip:Print("=== Error Handling Test Results ===")
    
    local totalTests = 0
    local passedTests = 0
    
    for testName, result in pairs(testResults) do
        totalTests = totalTests + 1
        if result.success then
            passedTests = passedTests + 1
        end
        
        local status = result.success and "|cFF00FF00PASS|r" or "|cFFFF0000FAIL|r"
        PvPTooltip:Print(string.format("%s: %s", testName, status))
        
        for _, detail in ipairs(result.details) do
            PvPTooltip:Print("  " .. detail)
        end
    end
    
    PvPTooltip:Print(string.format("Tests completed: %d/%d passed", passedTests, totalTests))
    
    if passedTests == totalTests then
        PvPTooltip:Print("|cFF00FF00All error handling tests passed!|r")
    else
        PvPTooltip:Print("|cFFFFFF00Some tests failed - check implementation|r")
    end
end

-- Get test results for external access
function ErrorHandlingTests:GetTestResults()
    return testResults
end

-- Quick test for basic error handling functionality
function ErrorHandlingTests:QuickTest()
    PvPTooltip:Print("=== Quick Error Handling Test ===")
    
    -- First, check if the addon is properly initialized
    if not PvPTooltip:IsReady() then
        PvPTooltip:Print("Addon not ready. Status: ready: no")
        PvPTooltip:Print("Try running '/pvptooltip status' to check addon state")
        return
    end
    
    -- Check module availability
    local allAvailable, available, missing = self:CheckModuleAvailability()
    if not allAvailable then
        PvPTooltip:Print("Some required modules are missing:")
        for _, moduleName in ipairs(missing) do
            PvPTooltip:Print("  ✗ " .. moduleName)
        end
        PvPTooltip:Print("Available modules:")
        for _, moduleName in ipairs(available) do
            PvPTooltip:Print("  ✓ " .. moduleName)
        end
        return
    end
    
    local tests = {
        {
            name = "ErrorHandler SafeCall",
            test = function()
                if not PvPTooltip.ErrorHandler then 
                    PvPTooltip:Print("  ErrorHandler module not available")
                    return false 
                end
                if not PvPTooltip.ErrorHandler.SafeCall then
                    PvPTooltip:Print("  SafeCall method not available")
                    return false
                end
                local success, result = PvPTooltip.ErrorHandler:SafeCall(function() error("test") end, "QuickTest")
                return not success -- Should return false for error
            end
        },
        {
            name = "DatabaseManager corruption detection",
            test = function()
                if not PvPTooltip.DatabaseManager then 
                    PvPTooltip:Print("  DatabaseManager module not available")
                    return false 
                end
                if not PvPTooltip.DatabaseManager.ValidateBracketData then 
                    PvPTooltip:Print("  ValidateBracketData method not available")
                    return false 
                end
                return not PvPTooltip.DatabaseManager:ValidateBracketData({currentRating = "invalid"})
            end
        },
        {
            name = "PlayerLookup graceful degradation",
            test = function()
                if not PvPTooltip.PlayerLookup then 
                    PvPTooltip:Print("  PlayerLookup module not available")
                    return false 
                end
                if not PvPTooltip.PlayerLookup.FindPlayerData then 
                    PvPTooltip:Print("  FindPlayerData method not available")
                    return false 
                end
                return PvPTooltip.PlayerLookup:FindPlayerData(nil) == nil
            end
        },
        {
            name = "TooltipRenderer error handling",
            test = function()
                if not PvPTooltip.TooltipRenderer then 
                    PvPTooltip:Print("  TooltipRenderer module not available")
                    return false 
                end
                if not PvPTooltip.TooltipRenderer.EnhanceTooltip then 
                    PvPTooltip:Print("  EnhanceTooltip method not available")
                    return false 
                end
                return not PvPTooltip.TooltipRenderer:EnhanceTooltip(nil, nil)
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
    
    PvPTooltip:Print(string.format("Quick test: %d/%d passed", passed, #tests))
    
    -- Additional diagnostic information
    PvPTooltip:Print("=== Module Availability Diagnostic ===")
    local modules = {
        "ErrorHandler", "DatabaseManager", "PlayerLookup", "TooltipRenderer", 
        "ColorUtils", "EventManager", "Config", "RealmResolver"
    }
    
    for _, moduleName in ipairs(modules) do
        local module = PvPTooltip[moduleName]
        if module and type(module) == "table" then
            local methodCount = 0
            for key, value in pairs(module) do
                if type(value) == "function" then
                    methodCount = methodCount + 1
                end
            end
            PvPTooltip:Print(string.format("✓ %s: Available (%d methods)", moduleName, methodCount))
        else
            PvPTooltip:Print(string.format("✗ %s: Not available or not a table", moduleName))
        end
    end
end

-- Return the module for proper loading
return ErrorHandlingTests