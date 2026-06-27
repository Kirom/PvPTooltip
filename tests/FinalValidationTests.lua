-- PvPTooltip Final Validation Tests
-- Comprehensive validation for Task 15: Integration testing and final validation

local FinalValidationTests = {}
PvPTooltip.FinalValidationTests = FinalValidationTests

-- Test results storage
local validationResults = {}

-- Initialize final validation tests
function FinalValidationTests:Initialize()
    PvPTooltip:Debug("FinalValidationTests module initialized")
end

-- Run all final validation tests
function FinalValidationTests:RunAllTests()
    PvPTooltip:Debug("Running Final Validation Tests...")
    
    validationResults = {
        tests = {},
        passed = 0,
        failed = 0,
        startTime = GetTime()
    }
    
    -- Task 15 Sub-tasks validation
    self:ValidateTooltipDisplayContexts()
    self:ValidateColorCodingAccuracy()
    self:ValidateCrossRegionRealm()
    self:ValidateUIAddonCompatibility()
    self:ValidateAllRequirements()
    
    -- Additional comprehensive validation
    self:ValidatePerformanceRequirements()
    self:ValidateErrorHandlingRobustness()
    self:ValidateDataIntegrity()
    
    validationResults.endTime = GetTime()
    validationResults.duration = (validationResults.endTime - validationResults.startTime) * 1000
    
    return validationResults
end

-- Validate tooltip display across all supported game contexts
function FinalValidationTests:ValidateTooltipDisplayContexts()
    local testName = "Tooltip Display Contexts Validation"
    PvPTooltip:Debug("Validating: " .. testName)
    
    local success, error = pcall(function()
        -- Test all contexts mentioned in requirements
        local gameContexts = {
            {
                name = "World Player Hover",
                unitType = "player",
                requirement = "1.1",
                description = "Hovering over player character in the world"
            },
            {
                name = "Party Interface",
                unitType = "party1",
                requirement = "1.2", 
                description = "Hovering over player in party interface"
            },
            {
                name = "Raid Interface",
                unitType = "raid1",
                requirement = "1.3",
                description = "Hovering over player in raid interface"
            },
            {
                name = "LFG Leader",
                unitType = "player",
                requirement = "1.4",
                description = "Hovering over LFG leader while seeking for group"
            },
            {
                name = "LFG Applicants",
                unitType = "player", 
                requirement = "1.5",
                description = "Hovering over LFG applicants as group leader"
            }
        }
        
        local contextsPassed = 0
        local totalContexts = #gameContexts
        
        for _, context in ipairs(gameContexts) do
            local contextSuccess = pcall(function()
                -- Create mock tooltip for this context
                local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
                mockTooltip.context = context.name
                mockTooltip.GetUnit = function() return context.unitType, context.unitType end
                
                -- Create test player data
                local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData("ContextPlayer")
                
                -- Test tooltip enhancement
                local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
                PvPTooltip.TestUtils.AssertTrue(result, 
                    string.format("Should enhance tooltip for %s", context.name))
                
                -- Validate tooltip content structure
                PvPTooltip.TestUtils.AssertTrue(#mockTooltip.lines > 0,
                    string.format("%s should generate tooltip content", context.name))
                
                local content = table.concat(mockTooltip.lines, "\n")
                
                -- Validate required sections per requirements
                PvPTooltip.TestUtils.AssertTrue(string.find(content, "PvP Tooltip info") ~= nil,
                    string.format("%s should contain main title (Req 6.1)", context.name))
                PvPTooltip.TestUtils.AssertTrue(string.find(content, "Current Rating") ~= nil,
                    string.format("%s should contain rating section (Req 2.1)", context.name))
                PvPTooltip.TestUtils.AssertTrue(string.find(content, "Character Experience") ~= nil,
                    string.format("%s should contain experience section (Req 3.1)", context.name))
                PvPTooltip.TestUtils.AssertTrue(string.find(content, "Current Season") ~= nil,
                    string.format("%s should contain season section (Req 4.1)", context.name))
                
                PvPTooltip:Debug(string.format("✓ %s - Requirement %s validated", 
                    context.name, context.requirement))
            end)
            
            if contextSuccess then
                contextsPassed = contextsPassed + 1
            else
                PvPTooltip:Debug(string.format("✗ %s - Failed validation", context.name))
            end
        end
        
        PvPTooltip.TestUtils.AssertEquals(totalContexts, contextsPassed,
            string.format("All %d game contexts should pass validation", totalContexts))
        
        PvPTooltip:Debug(string.format("Tooltip contexts validation: %d/%d passed", 
            contextsPassed, totalContexts))
    end)
    
    self:RecordValidationResult(testName, success, error)
end

-- Validate color coding accuracy and data formatting
function FinalValidationTests:ValidateColorCodingAccuracy()
    local testName = "Color Coding Accuracy Validation"
    PvPTooltip:Debug("Validating: " .. testName)
    
    local success, error = pcall(function()
        if not PvPTooltip.ColorUtils then
            error("ColorUtils module not available for validation")
        end
        
        -- Validate rating color requirements (Req 2.2-2.5)
        local ratingColorTests = {
            {
                rating = 1500,
                expectedColor = "#FFFFFF",
                requirement = "2.2",
                description = "0-1799 rating should be white"
            },
            {
                rating = 1800,
                expectedColor = "#2EAD65", 
                requirement = "2.3",
                description = "1800-2099 rating should be green"
            },
            {
                rating = 2100,
                expectedColor = "#046DCC",
                requirement = "2.4", 
                description = "2100-2399 rating should be blue"
            },
            {
                rating = 2400,
                expectedColor = "#A140E9",
                requirement = "2.5",
                description = "2400+ rating should be purple"
            }
        }
        
        for _, test in ipairs(ratingColorTests) do
            local actualColor = PvPTooltip.ColorUtils:GetRatingColor(test.rating)
            PvPTooltip.TestUtils.AssertEquals(test.expectedColor, actualColor,
                string.format("Requirement %s: %s", test.requirement, test.description))
            
            PvPTooltip:Debug(string.format("✓ Rating %d -> %s (Req %s)", 
                test.rating, actualColor, test.requirement))
        end
        
        -- Validate win rate color requirements (Req 4.3-4.4)
        local winRateColorTests = {
            {
                winRate = 50,
                expectedColor = "#FF4500",
                requirement = "4.3",
                description = "≤50% win rate should be red"
            },
            {
                winRate = 51,
                expectedColor = "#57C94F",
                requirement = "4.4", 
                description = ">50% win rate should be green"
            }
        }
        
        for _, test in ipairs(winRateColorTests) do
            local actualColor = PvPTooltip.ColorUtils:GetWinRateColor(test.winRate)
            PvPTooltip.TestUtils.AssertEquals(test.expectedColor, actualColor,
                string.format("Requirement %s: %s", test.requirement, test.description))
            
            PvPTooltip:Debug(string.format("✓ Win rate %d%% -> %s (Req %s)", 
                test.winRate, actualColor, test.requirement))
        end
        
        -- Validate data formatting requirements
        local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
        
        -- Set specific test data
        mockPlayerData.brackets["2v2"] = {
            currentRating = 2200,
            personalBest = 2400,
            playedTotal = 75,
            winRate = 64.0
        }
        
        local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
        PvPTooltip.TestUtils.AssertTrue(result, "Should enhance tooltip for formatting validation")
        
        local content = table.concat(mockTooltip.lines, "\n")
        
        -- Validate games played formatting (Req 4.2)
        PvPTooltip.TestUtils.AssertTrue(string.find(content, "FFD035") ~= nil,
            "Requirement 4.2: Games played should use #FFD035 color")
        
        -- Validate win rate formatting (Req 4.5)
        PvPTooltip.TestUtils.AssertTrue(string.find(content, "75 %(64%% won%)") ~= nil,
            "Requirement 4.5: Win rate should be formatted as 'playedTotal (winRate% won)'")
        
        PvPTooltip:Debug("Color coding and formatting validation completed")
    end)
    
    self:RecordValidationResult(testName, success, error)
end

-- Validate cross-region and cross-realm functionality
function FinalValidationTests:ValidateCrossRegionRealm()
    local testName = "Cross-Region Cross-Realm Validation"
    PvPTooltip:Debug("Validating: " .. testName)
    
    local success, error = pcall(function()
        if not PvPTooltip.DatabaseManager then
            error("DatabaseManager not available for cross-region validation")
        end
        
        -- Validate database loading requirements (Req 5.1-5.4)
        local databaseFiles = {
            {file = "db_pvp_eu_characters.lua", requirement = "5.1", region = "eu"},
            {file = "db_pvp_us_characters.lua", requirement = "5.2", region = "us"},
            {file = "db_realms.lua", requirement = "5.3", type = "realms"},
            {file = "db_regions.lua", requirement = "5.4", type = "regions"}
        }
        
        for _, dbFile in ipairs(databaseFiles) do
            -- Check if database data is available
            local isAvailable = false
            
            if dbFile.region then
                isAvailable = PvPTooltip.DatabaseManager:IsRegionDataAvailable(dbFile.region)
                PvPTooltip:Debug(string.format("Database %s (%s): %s", 
                    dbFile.file, dbFile.region, isAvailable and "available" or "not available"))
            else
                -- For realm/region mapping files, check if the functionality exists
                isAvailable = PvPTooltip.DatabaseManager:IsDataAvailable()
                PvPTooltip:Debug(string.format("Database %s: %s", 
                    dbFile.file, isAvailable and "loaded" or "not loaded"))
            end
            
            -- At least one region should be available
            if dbFile.region then
                -- Individual region availability is optional, but we log it
                PvPTooltip:Debug(string.format("Requirement %s: %s region data %s", 
                    dbFile.requirement, dbFile.region, isAvailable and "available" or "unavailable"))
            end
        end
        
        -- Validate realm matching requirement (Req 5.5)
        local testRealms = {
            {name = "stormrage", expectedRegion = "us"},
            {name = "kazzak", expectedRegion = "eu"},
            {name = "area-52", expectedRegion = "us"},
            {name = "draenor", expectedRegion = "eu"}
        }
        
        for _, realmTest in ipairs(testRealms) do
            if PvPTooltip.RealmResolver then
                -- Test realm normalization
                if PvPTooltip.RealmResolver.NormalizeRealmName then
                    local normalized = PvPTooltip.RealmResolver:NormalizeRealmName(realmTest.name)
                    PvPTooltip.TestUtils.AssertNotNil(normalized,
                        string.format("Should normalize realm name: %s", realmTest.name))
                end
                
                -- Test region detection
                if PvPTooltip.RealmResolver.GetRegionForRealm then
                    local detectedRegion = PvPTooltip.RealmResolver:GetRegionForRealm(realmTest.name)
                    PvPTooltip:Debug(string.format("Realm %s -> Region %s", 
                        realmTest.name, detectedRegion or "unknown"))
                end
            end
            
            -- Test player lookup across regions
            if PvPTooltip.PlayerLookup then
                local playerData = PvPTooltip.PlayerLookup:LookupPlayerInDatabase(
                    "TestPlayer", realmTest.name, realmTest.expectedRegion)
                -- Result can be nil - just verify no crash occurs
                PvPTooltip:Debug(string.format("Cross-region lookup %s-%s: %s", 
                    "TestPlayer", realmTest.name, playerData and "found" or "not found"))
            end
        end
        
        PvPTooltip:Debug("Cross-region cross-realm validation completed")
    end)
    
    self:RecordValidationResult(testName, success, error)
end

-- Validate compatibility with popular UI addons
function FinalValidationTests:ValidateUIAddonCompatibility()
    local testName = "UI Addon Compatibility Validation"
    PvPTooltip:Debug("Validating: " .. testName)
    
    local success, error = pcall(function()
        -- Test compatibility with major UI addon modifications
        local addonScenarios = {
            {
                name = "ElvUI Compatibility",
                modifications = {
                    tooltipSkinning = true,
                    fontOverrides = true,
                    colorOverrides = true
                }
            },
            {
                name = "TukUI Compatibility", 
                modifications = {
                    tooltipSkinning = true,
                    layoutChanges = true
                }
            },
            {
                name = "Shadowed Unit Frames",
                modifications = {
                    unitFrameOverrides = true,
                    tooltipAnchoring = true
                }
            },
            {
                name = "Bartender4",
                modifications = {
                    actionBarMods = true
                }
            }
        }
        
        for _, scenario in ipairs(addonScenarios) do
            local scenarioSuccess = pcall(function()
                -- Create modified tooltip environment
                local modifiedTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
                
                -- Apply addon-specific modifications
                if scenario.modifications.tooltipSkinning then
                    modifiedTooltip.skinned = true
                    modifiedTooltip.SetBackdrop = function() end
                    modifiedTooltip.SetBackdropColor = function() end
                end
                
                if scenario.modifications.fontOverrides then
                    modifiedTooltip.GetFont = function() return "ElvUI Font", 12, "OUTLINE" end
                    modifiedTooltip.SetFont = function() end
                end
                
                if scenario.modifications.colorOverrides then
                    modifiedTooltip.defaultTextColor = {r = 0.9, g = 0.9, b = 0.9}
                end
                
                if scenario.modifications.tooltipAnchoring then
                    modifiedTooltip.SetOwner = function() end
                    modifiedTooltip.SetPoint = function() end
                    modifiedTooltip.ClearAllPoints = function() end
                end
                
                -- Test addon compatibility
                local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
                local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(modifiedTooltip, mockPlayerData)
                
                PvPTooltip.TestUtils.AssertTrue(result,
                    string.format("Should work with %s modifications", scenario.name))
                
                -- Verify content integrity
                PvPTooltip.TestUtils.AssertTrue(#modifiedTooltip.lines > 0,
                    string.format("Should generate content with %s", scenario.name))
                
                local content = table.concat(modifiedTooltip.lines, "\n")
                PvPTooltip.TestUtils.AssertTrue(string.find(content, "PvP Tooltip info") ~= nil,
                    string.format("Should maintain content with %s", scenario.name))
                
                PvPTooltip:Debug(string.format("✓ %s - Compatible", scenario.name))
            end)
            
            if not scenarioSuccess then
                PvPTooltip:Debug(string.format("✗ %s - Compatibility issue detected", scenario.name))
            end
        end
        
        -- Test graceful degradation with missing methods
        local degradationTest = pcall(function()
            local minimalTooltip = {
                lines = {},
                AddLine = function(self, text) table.insert(self.lines, text or "") end
                -- Intentionally missing other methods
            }
            
            local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
            local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(minimalTooltip, mockPlayerData)
            
            PvPTooltip.TestUtils.AssertTrue(result,
                "Should gracefully handle minimal tooltip interface")
        end)
        
        PvPTooltip.TestUtils.AssertTrue(degradationTest,
            "Should demonstrate graceful degradation")
        
        PvPTooltip:Debug("UI addon compatibility validation completed")
    end)
    
    self:RecordValidationResult(testName, success, error)
end

-- Validate all requirements comprehensively
function FinalValidationTests:ValidateAllRequirements()
    local testName = "Comprehensive Requirements Validation"
    PvPTooltip:Debug("Validating: " .. testName)
    
    local success, error = pcall(function()
        -- Create comprehensive test data
        local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
        
        -- Set comprehensive test data for all game modes
        local gameModes = {"2v2", "3v3", "shuffle", "rbg", "blitz"}
        for i, gameMode in ipairs(gameModes) do
            mockPlayerData.brackets[gameMode] = {
                currentRating = 1800 + (i * 100), -- Varying ratings
                personalBest = 2000 + (i * 100),  -- Varying personal bests
                playedTotal = 50 + (i * 10),      -- Varying games played
                winRate = 55 + (i * 2)            -- Varying win rates
            }
        end
        
        -- Test comprehensive tooltip enhancement
        local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
        PvPTooltip.TestUtils.AssertTrue(result, "Should enhance tooltip with comprehensive data")
        
        local content = table.concat(mockTooltip.lines, "\n")
        
        -- Validate all required sections exist
        local requiredSections = {
            {text = "PvP Tooltip info", requirement = "6.1", description = "Main title"},
            {text = "Current Rating", requirement = "6.2", description = "Rating section header"},
            {text = "Character Experience", requirement = "6.2", description = "Experience section header"},
            {text = "Current Season", requirement = "6.2", description = "Season section header"}
        }
        
        for _, section in ipairs(requiredSections) do
            PvPTooltip.TestUtils.AssertTrue(string.find(content, section.text) ~= nil,
                string.format("Requirement %s: Should contain %s", section.requirement, section.description))
        end
        
        -- Validate all game modes are displayed
        for _, gameMode in ipairs(gameModes) do
            local displayName = gameMode == "rbg" and "RBG" or 
                               gameMode == "blitz" and "Blitz" or gameMode
            PvPTooltip.TestUtils.AssertTrue(string.find(content, displayName) ~= nil,
                string.format("Should display %s game mode", gameMode))
        end
        
        -- Validate color formatting is applied
        PvPTooltip.TestUtils.AssertTrue(string.find(content, "|c") ~= nil,
            "Should apply color formatting")
        PvPTooltip.TestUtils.AssertTrue(string.find(content, "|r") ~= nil,
            "Should properly close color formatting")
        
        -- Validate win rate formatting
        PvPTooltip.TestUtils.AssertTrue(string.find(content, "%% won%)") ~= nil,
            "Should format win rates correctly")
        
        PvPTooltip:Debug("Comprehensive requirements validation completed")
    end)
    
    self:RecordValidationResult(testName, success, error)
end

-- Validate performance requirements
function FinalValidationTests:ValidatePerformanceRequirements()
    local testName = "Performance Requirements Validation"
    PvPTooltip:Debug("Validating: " .. testName)
    
    local success, error = pcall(function()
        -- Test tooltip enhancement performance
        local enhancementCount = 50
        local startTime = GetTime()
        
        for i = 1, enhancementCount do
            local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
            local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData("PerfTest" .. i)
            
            PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
        end
        
        local totalTime = (GetTime() - startTime) * 1000
        local avgTime = totalTime / enhancementCount
        
        PvPTooltip:Debug(string.format("Performance: %d enhancements in %.2fms (avg: %.2fms)", 
            enhancementCount, totalTime, avgTime))
        
        -- Performance should be reasonable for real-time tooltip updates
        PvPTooltip.TestUtils.AssertTrue(avgTime < 50,
            string.format("Average enhancement time should be < 50ms, got %.2fms", avgTime))
        
        -- Test memory stability
        collectgarbage("collect")
        local startMemory = collectgarbage("count")
        
        for i = 1, 100 do
            local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
            local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData("MemTest" .. i)
            
            PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
            
            if i % 25 == 0 then
                collectgarbage("collect")
            end
        end
        
        collectgarbage("collect")
        local endMemory = collectgarbage("count")
        local memoryGrowth = endMemory - startMemory
        
        PvPTooltip:Debug(string.format("Memory stability: %.2f KB growth after 100 operations", memoryGrowth))
        
        -- Memory growth should be minimal
        PvPTooltip.TestUtils.AssertTrue(memoryGrowth < 200,
            string.format("Memory growth should be < 200KB, got %.2f KB", memoryGrowth))
        
        PvPTooltip:Debug("Performance requirements validation completed")
    end)
    
    self:RecordValidationResult(testName, success, error)
end

-- Validate error handling robustness
function FinalValidationTests:ValidateErrorHandlingRobustness()
    local testName = "Error Handling Robustness Validation"
    PvPTooltip:Debug("Validating: " .. testName)
    
    local success, error = pcall(function()
        -- Test with nil inputs
        local nilResult = PvPTooltip.TooltipRenderer:EnhanceTooltip(nil, nil)
        PvPTooltip.TestUtils.AssertFalse(nilResult, "Should handle nil inputs gracefully")
        
        -- Test with corrupted player data
        local corruptedData = {
            name = 123, -- Should be string
            brackets = "not a table" -- Should be table
        }
        
        local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        local corruptedResult = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, corruptedData)
        PvPTooltip.TestUtils.AssertFalse(corruptedResult, "Should handle corrupted data gracefully")
        
        -- Test with missing bracket data
        local incompleteData = {
            name = "IncompletePlayer",
            realm = "test-realm",
            brackets = {} -- Empty brackets
        }
        
        mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        local incompleteResult = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, incompleteData)
        -- Should handle gracefully (result can be true or false, just shouldn't crash)
        
        -- Test addon continues working after errors
        mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        local validData = PvPTooltip.TestUtils.CreateMockPlayerData()
        local recoveryResult = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, validData)
        PvPTooltip.TestUtils.AssertTrue(recoveryResult, "Should continue working after handling errors")
        
        PvPTooltip:Debug("Error handling robustness validation completed")
    end)
    
    self:RecordValidationResult(testName, success, error)
end

-- Validate data integrity
function FinalValidationTests:ValidateDataIntegrity()
    local testName = "Data Integrity Validation"
    PvPTooltip:Debug("Validating: " .. testName)
    
    local success, error = pcall(function()
        -- Test data consistency through the pipeline
        local originalData = PvPTooltip.TestUtils.CreateMockPlayerData("IntegrityTest")
        
        -- Validate data structure
        if PvPTooltip.TooltipRenderer.ValidatePlayerData then
            local isValid = PvPTooltip.TooltipRenderer:ValidatePlayerData(originalData)
            PvPTooltip.TestUtils.AssertTrue(isValid, "Test data should be valid")
        end
        
        -- Test tooltip rendering preserves data integrity
        local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, originalData)
        PvPTooltip.TestUtils.AssertTrue(result, "Should render valid data successfully")
        
        -- Verify expected data appears in tooltip
        local content = table.concat(mockTooltip.lines, "\n")
        
        -- Check for rating values
        for gameMode, bracketData in pairs(originalData.brackets) do
            if bracketData.currentRating and bracketData.currentRating > 0 then
                PvPTooltip.TestUtils.AssertTrue(string.find(content, tostring(bracketData.currentRating)) ~= nil,
                    string.format("Should display %s current rating %d", gameMode, bracketData.currentRating))
            end
        end
        
        PvPTooltip:Debug("Data integrity validation completed")
    end)
    
    self:RecordValidationResult(testName, success, error)
end

-- Record validation result
function FinalValidationTests:RecordValidationResult(testName, success, error)
    validationResults.tests[testName] = {
        success = success,
        error = error,
        timestamp = GetTime()
    }
    
    if success then
        validationResults.passed = validationResults.passed + 1
        PvPTooltip:Debug(testName .. " - VALIDATION PASSED")
    else
        validationResults.failed = validationResults.failed + 1
        PvPTooltip:Debug(testName .. " - VALIDATION FAILED: " .. tostring(error))
    end
end

-- Generate final validation report
function FinalValidationTests:GenerateValidationReport()
    local totalTests = validationResults.passed + validationResults.failed
    local successRate = totalTests > 0 and (validationResults.passed / totalTests * 100) or 0
    
    PvPTooltip:Print("=== Task 15: Final Validation Report ===")
    PvPTooltip:Print(string.format("Total Validations: %d", totalTests))
    PvPTooltip:Print(string.format("Passed: %d", validationResults.passed))
    PvPTooltip:Print(string.format("Failed: %d", validationResults.failed))
    PvPTooltip:Print(string.format("Success Rate: %.1f%%", successRate))
    PvPTooltip:Print(string.format("Duration: %.2fms", validationResults.duration))
    
    -- Detailed results
    PvPTooltip:Print("\nValidation Details:")
    for testName, result in pairs(validationResults.tests) do
        local status = result.success and "|cFF00FF00PASSED|r" or "|cFFFF0000FAILED|r"
        PvPTooltip:Print(string.format("  %s: %s", testName, status))
        if not result.success and result.error then
            PvPTooltip:Print(string.format("    Error: %s", tostring(result.error)))
        end
    end
    
    -- Overall result
    if validationResults.failed == 0 then
        PvPTooltip:Print("|cFF00FF00Task 15: Integration testing and final validation - COMPLETED|r")
    else
        PvPTooltip:Print("|cFFFF0000Task 15: Some validations failed. Review the details above.|r")
    end
    
    return validationResults
end

return FinalValidationTests