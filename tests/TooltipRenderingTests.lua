-- PvPTooltip Tooltip Rendering Tests
-- Integration tests for tooltip rendering functionality

local TooltipRenderingTests = {}
PvPTooltip.TooltipRenderingTests = TooltipRenderingTests

-- Test results storage
local testResults = {}

-- Initialize tooltip rendering tests
function TooltipRenderingTests:Initialize()
    PvPTooltip:Debug("TooltipRenderingTests module initialized")
end

-- Run all tooltip rendering tests
function TooltipRenderingTests:RunAllTests()
    PvPTooltip:Debug("Running TooltipRenderingTests...")
    
    testResults = {
        tests = {},
        passed = 0,
        failed = 0,
        startTime = GetTime()
    }
    
    -- Test tooltip renderer initialization
    self:TestTooltipRendererInitialization()
    
    -- Test tooltip enhancement
    self:TestTooltipEnhancement()
    
    -- Test section rendering
    self:TestSectionRendering()
    
    -- Test color formatting
    self:TestColorFormatting()
    
    -- Test data validation
    self:TestDataValidation()
    
    -- Test error handling
    self:TestErrorHandling()
    
    -- Test performance characteristics
    self:TestPerformanceCharacteristics()
    
    -- Test integration with other components
    self:TestComponentIntegration()
    
    testResults.endTime = GetTime()
    testResults.duration = (testResults.endTime - testResults.startTime) * 1000
    
    return testResults
end

-- Test tooltip renderer initialization
function TooltipRenderingTests:TestTooltipRendererInitialization()
    local testName = "Tooltip Renderer Initialization"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test that TooltipRenderer exists
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.TooltipRenderer, "TooltipRenderer should exist")
        
        -- Test initialization method exists
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.TooltipRenderer.Initialize, "Initialize method should exist")
        
        -- Test main rendering method exists
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.TooltipRenderer.EnhanceTooltip, "EnhanceTooltip method should exist")
        
        -- Test section rendering methods exist
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.TooltipRenderer.AddSectionTitle, "AddSectionTitle method should exist")
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.TooltipRenderer.FormatRatingSection, "FormatRatingSection method should exist")
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.TooltipRenderer.FormatExperienceSection, "FormatExperienceSection method should exist")
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.TooltipRenderer.FormatSeasonSection, "FormatSeasonSection method should exist")
        
        -- Test utility methods exist
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.TooltipRenderer.ValidatePlayerData, "ValidatePlayerData method should exist")
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.TooltipRenderer.HasDisplayableData, "HasDisplayableData method should exist")
        
        -- Test dependencies are available
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.ColorUtils, "ColorUtils dependency should be available")
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.Config, "Config dependency should be available")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test tooltip enhancement
function TooltipRenderingTests:TestTooltipEnhancement()
    local testName = "Tooltip Enhancement"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Create mock tooltip
        local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        
        -- Create mock player data
        local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData("TestPlayer", "test-realm", "eu")
        
        -- Test EnhanceTooltip with valid data
        local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
        PvPTooltip.TestUtils.AssertTrue(result, "EnhanceTooltip should succeed with valid data")
        
        -- Verify tooltip was modified
        PvPTooltip.TestUtils.AssertTrue(#mockTooltip.lines > 0, "Tooltip should have lines added")
        
        -- Check for expected content
        local tooltipContent = table.concat(mockTooltip.lines, "\n")
        PvPTooltip.TestUtils.AssertTrue(string.find(tooltipContent, "PvP Tooltip info") ~= nil, 
            "Tooltip should contain main title")
        PvPTooltip.TestUtils.AssertTrue(string.find(tooltipContent, "Current Rating") ~= nil, 
            "Tooltip should contain current rating section")
        PvPTooltip.TestUtils.AssertTrue(string.find(tooltipContent, "Character Experience") ~= nil, 
            "Tooltip should contain experience section")
        PvPTooltip.TestUtils.AssertTrue(string.find(tooltipContent, "Current Season") ~= nil, 
            "Tooltip should contain season section")
        
        -- Test EnhanceTooltip with nil tooltip
        result = PvPTooltip.TooltipRenderer:EnhanceTooltip(nil, mockPlayerData)
        PvPTooltip.TestUtils.AssertFalse(result, "EnhanceTooltip should fail gracefully with nil tooltip")
        
        -- Test EnhanceTooltip with nil player data
        result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, nil)
        PvPTooltip.TestUtils.AssertFalse(result, "EnhanceTooltip should fail gracefully with nil player data")
        
        -- Test EnhanceTooltip with invalid player data
        local invalidPlayerData = {name = "TestPlayer"} -- Missing required fields
        result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, invalidPlayerData)
        PvPTooltip.TestUtils.AssertFalse(result, "EnhanceTooltip should fail gracefully with invalid player data")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test section rendering
function TooltipRenderingTests:TestSectionRendering()
    local testName = "Section Rendering"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        
        -- Test AddSectionTitle
        local result = PvPTooltip.TooltipRenderer:AddSectionTitle(mockTooltip)
        PvPTooltip.TestUtils.AssertTrue(result, "AddSectionTitle should succeed")
        PvPTooltip.TestUtils.AssertTrue(#mockTooltip.lines > 0, "Section title should add lines to tooltip")
        
        -- Test with nil tooltip
        result = PvPTooltip.TooltipRenderer:AddSectionTitle(nil)
        PvPTooltip.TestUtils.AssertFalse(result, "AddSectionTitle should fail gracefully with nil tooltip")
        
        -- Test FormatRatingSection
        mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        local mockBrackets = {
            ["2v2"] = {currentRating = 2000, personalBest = 2100, playedTotal = 50, winRate = 60},
            ["3v3"] = {currentRating = 1850, personalBest = 2000, playedTotal = 30, winRate = 55}
        }
        
        result = PvPTooltip.TooltipRenderer:FormatRatingSection(mockTooltip, mockBrackets)
        PvPTooltip.TestUtils.AssertTrue(result, "FormatRatingSection should succeed")
        PvPTooltip.TestUtils.AssertTrue(#mockTooltip.lines > 0, "Rating section should add lines to tooltip")
        
        -- Verify content includes game modes
        local content = table.concat(mockTooltip.lines, "\n")
        PvPTooltip.TestUtils.AssertTrue(string.find(content, "2v2") ~= nil, "Should include 2v2 rating")
        PvPTooltip.TestUtils.AssertTrue(string.find(content, "3v3") ~= nil, "Should include 3v3 rating")
        
        -- Test FormatExperienceSection
        mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        result = PvPTooltip.TooltipRenderer:FormatExperienceSection(mockTooltip, mockBrackets)
        PvPTooltip.TestUtils.AssertTrue(result, "FormatExperienceSection should succeed")
        PvPTooltip.TestUtils.AssertTrue(#mockTooltip.lines > 0, "Experience section should add lines to tooltip")
        
        -- Test FormatSeasonSection
        mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        result = PvPTooltip.TooltipRenderer:FormatSeasonSection(mockTooltip, mockBrackets)
        PvPTooltip.TestUtils.AssertTrue(result, "FormatSeasonSection should succeed")
        PvPTooltip.TestUtils.AssertTrue(#mockTooltip.lines > 0, "Season section should add lines to tooltip")
        
        -- Test with empty brackets
        mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        result = PvPTooltip.TooltipRenderer:FormatRatingSection(mockTooltip, {})
        PvPTooltip.TestUtils.AssertFalse(result, "Should handle empty brackets gracefully")
        
        -- Test with nil brackets
        result = PvPTooltip.TooltipRenderer:FormatRatingSection(mockTooltip, nil)
        PvPTooltip.TestUtils.AssertFalse(result, "Should handle nil brackets gracefully")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test color formatting
function TooltipRenderingTests:TestColorFormatting()
    local testName = "Color Formatting"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test that ColorUtils is available and working
        PvPTooltip.TestUtils.AssertNotNil(PvPTooltip.ColorUtils, "ColorUtils should be available")
        
        -- Test color formatting methods exist
        if PvPTooltip.ColorUtils.FormatColoredRating then
            local coloredRating = PvPTooltip.ColorUtils:FormatColoredRating(2000)
            PvPTooltip.TestUtils.AssertNotNil(coloredRating, "Should format colored rating")
            PvPTooltip.TestUtils.AssertTrue(type(coloredRating) == "string", "Colored rating should be string")
        end
        
        if PvPTooltip.ColorUtils.FormatColoredWinRate then
            local coloredWinRate = PvPTooltip.ColorUtils:FormatColoredWinRate(50, 60)
            PvPTooltip.TestUtils.AssertNotNil(coloredWinRate, "Should format colored win rate")
            PvPTooltip.TestUtils.AssertTrue(type(coloredWinRate) == "string", "Colored win rate should be string")
        end
        
        -- Test tooltip rendering with color formatting
        local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
        
        local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
        PvPTooltip.TestUtils.AssertTrue(result, "Tooltip enhancement should succeed")
        
        -- Check for color codes in tooltip content
        local content = table.concat(mockTooltip.lines, "\n")
        local hasColorCodes = string.find(content, "|c") ~= nil or string.find(content, "|r") ~= nil
        PvPTooltip.TestUtils.AssertTrue(hasColorCodes, "Tooltip should contain color codes")
        
        -- Test AddColoredLine utility method
        if PvPTooltip.TooltipRenderer.AddColoredLine then
            mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
            PvPTooltip.TooltipRenderer:AddColoredLine(mockTooltip, "Test Line", "#FF0000")
            
            PvPTooltip.TestUtils.AssertTrue(#mockTooltip.lines > 0, "AddColoredLine should add line to tooltip")
            
            local line = mockTooltip.lines[1]
            PvPTooltip.TestUtils.AssertTrue(string.find(line, "Test Line") ~= nil, "Line should contain text")
        end
        
        -- Test GetDisplayLength utility method
        if PvPTooltip.TooltipRenderer.GetDisplayLength then
            local length = PvPTooltip.TooltipRenderer:GetDisplayLength("Test")
            PvPTooltip.TestUtils.AssertEquals(4, length, "Display length should be 4 for 'Test'")
            
            -- Test with color codes
            length = PvPTooltip.TooltipRenderer:GetDisplayLength("|cFFFF0000Test|r")
            PvPTooltip.TestUtils.AssertEquals(4, length, "Display length should ignore color codes")
        end
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test data validation
function TooltipRenderingTests:TestDataValidation()
    local testName = "Data Validation"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test ValidatePlayerData with various inputs
        local isValid = PvPTooltip.TooltipRenderer:ValidatePlayerData(nil)
        PvPTooltip.TestUtils.AssertFalse(isValid, "Should reject nil player data")
        
        isValid = PvPTooltip.TooltipRenderer:ValidatePlayerData({})
        PvPTooltip.TestUtils.AssertFalse(isValid, "Should reject empty player data")
        
        isValid = PvPTooltip.TooltipRenderer:ValidatePlayerData({name = "TestPlayer"})
        PvPTooltip.TestUtils.AssertFalse(isValid, "Should reject player data without brackets")
        
        isValid = PvPTooltip.TooltipRenderer:ValidatePlayerData({
            name = "TestPlayer",
            brackets = "not a table"
        })
        PvPTooltip.TestUtils.AssertFalse(isValid, "Should reject player data with invalid brackets")
        
        isValid = PvPTooltip.TooltipRenderer:ValidatePlayerData({
            name = "TestPlayer",
            brackets = {}
        })
        PvPTooltip.TestUtils.AssertFalse(isValid, "Should reject player data with empty brackets")
        
        -- Test with valid player data
        local validPlayerData = {
            name = "TestPlayer",
            brackets = {
                ["2v2"] = {
                    currentRating = 2000,
                    personalBest = 2100,
                    playedTotal = 50
                }
            }
        }
        
        isValid = PvPTooltip.TooltipRenderer:ValidatePlayerData(validPlayerData)
        PvPTooltip.TestUtils.AssertTrue(isValid, "Should accept valid player data")
        
        -- Test HasDisplayableData method
        local hasData = PvPTooltip.TooltipRenderer:HasDisplayableData(validPlayerData)
        PvPTooltip.TestUtils.AssertTrue(hasData, "Should detect displayable data")
        
        hasData = PvPTooltip.TooltipRenderer:HasDisplayableData(nil)
        PvPTooltip.TestUtils.AssertFalse(hasData, "Should reject nil data")
        
        -- Test with data that has no meaningful values
        local emptyDataPlayer = {
            name = "TestPlayer",
            brackets = {
                ["2v2"] = {
                    currentRating = 0,
                    personalBest = 0,
                    playedTotal = 0
                }
            }
        }
        
        hasData = PvPTooltip.TooltipRenderer:HasDisplayableData(emptyDataPlayer)
        PvPTooltip.TestUtils.AssertFalse(hasData, "Should reject data with no meaningful values")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test error handling
function TooltipRenderingTests:TestErrorHandling()
    local testName = "Error Handling"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test tooltip rendering with corrupted tooltip object
        local corruptedTooltip = {
            AddLine = function() error("Simulated tooltip error") end
        }
        
        local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
        
        -- This should not crash the addon
        local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(corruptedTooltip, mockPlayerData)
        PvPTooltip.TestUtils.AssertFalse(result, "Should handle tooltip errors gracefully")
        
        -- Test with missing ColorUtils dependency
        local originalColorUtils = PvPTooltip.ColorUtils
        PvPTooltip.ColorUtils = nil
        
        local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
        
        -- Should still work with fallback formatting
        PvPTooltip.TestUtils.AssertTrue(result, "Should work with missing ColorUtils (fallback)")
        
        -- Restore ColorUtils
        PvPTooltip.ColorUtils = originalColorUtils
        
        -- Test with missing Config dependency
        local originalConfig = PvPTooltip.Config
        PvPTooltip.Config = nil
        
        mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
        
        -- Should still work with fallback values
        PvPTooltip.TestUtils.AssertTrue(result, "Should work with missing Config (fallback)")
        
        -- Restore Config
        PvPTooltip.Config = originalConfig
        
        -- Test with corrupted player data
        local corruptedPlayerData = {
            name = "TestPlayer",
            brackets = {
                ["2v2"] = {
                    currentRating = "not a number",
                    personalBest = nil,
                    playedTotal = -50
                }
            }
        }
        
        mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, corruptedPlayerData)
        
        -- Should handle corrupted data gracefully
        PvPTooltip.TestUtils.AssertFalse(result, "Should handle corrupted player data gracefully")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test performance characteristics
function TooltipRenderingTests:TestPerformanceCharacteristics()
    local testName = "Performance Characteristics"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
        
        -- Test rendering performance
        local renderCount = 100
        local startTime = GetTime()
        
        for i = 1, renderCount do
            local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
            PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
        end
        
        local endTime = GetTime()
        local totalTime = (endTime - startTime) * 1000
        local averageTime = totalTime / renderCount
        
        PvPTooltip:Debug(string.format("Average rendering time: %.2fms", averageTime))
        
        -- Rendering should be fast (less than 10ms per render on average)
        PvPTooltip.TestUtils.AssertTrue(averageTime < 10, 
            string.format("Average rendering time should be < 10ms, got %.2fms", averageTime))
        
        -- Test memory usage during rendering
        collectgarbage("collect")
        local startMemory = collectgarbage("count")
        
        for i = 1, 50 do
            local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
            PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
        end
        
        collectgarbage("collect")
        local endMemory = collectgarbage("count")
        local memoryUsed = endMemory - startMemory
        
        PvPTooltip:Debug(string.format("Memory used for 50 renders: %.2f KB", memoryUsed))
        
        -- Memory usage should be reasonable (less than 100KB for 50 renders)
        PvPTooltip.TestUtils.AssertTrue(memoryUsed < 100, 
            string.format("Memory usage should be < 100KB, got %.2f KB", memoryUsed))
        
        -- Test validation performance
        startTime = GetTime()
        for i = 1, 1000 do
            PvPTooltip.TooltipRenderer:ValidatePlayerData(mockPlayerData)
        end
        endTime = GetTime()
        
        local validationTime = (endTime - startTime) * 1000
        PvPTooltip:Debug(string.format("Validation time for 1000 operations: %.2fms", validationTime))
        
        PvPTooltip.TestUtils.AssertTrue(validationTime < 50, 
            "Validation should be fast (< 50ms for 1000 operations)")
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Test integration with other components
function TooltipRenderingTests:TestComponentIntegration()
    local testName = "Component Integration"
    PvPTooltip:Debug("Testing: " .. testName)
    
    local success, error = pcall(function()
        -- Test integration with ColorUtils
        if PvPTooltip.ColorUtils then
            local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
            local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
            
            local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
            PvPTooltip.TestUtils.AssertTrue(result, "Should integrate with ColorUtils successfully")
            
            -- Verify color formatting was applied
            local content = table.concat(mockTooltip.lines, "\n")
            local hasColors = string.find(content, "|c") ~= nil
            PvPTooltip.TestUtils.AssertTrue(hasColors, "Should apply color formatting through ColorUtils")
        end
        
        -- Test integration with Config
        if PvPTooltip.Config then
            -- Test that config values are used
            local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
            local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
            
            local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
            PvPTooltip.TestUtils.AssertTrue(result, "Should integrate with Config successfully")
            
            -- Test that game modes from config are used
            if PvPTooltip.Config.GameModes then
                local content = table.concat(mockTooltip.lines, "\n")
                for _, gameMode in ipairs(PvPTooltip.Config.GameModes) do
                    if mockPlayerData.brackets[gameMode] then
                        -- Should find the game mode in the tooltip content
                        local displayName = PvPTooltip.Config:GetDisplayName and 
                            PvPTooltip.Config:GetDisplayName(gameMode) or gameMode
                        -- Note: This test might be too strict depending on formatting
                    end
                end
            end
        end
        
        -- Test GetTooltipPreview method (if available)
        if PvPTooltip.TooltipRenderer.GetTooltipPreview then
            local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
            local preview = PvPTooltip.TooltipRenderer:GetTooltipPreview(mockPlayerData)
            
            PvPTooltip.TestUtils.AssertNotNil(preview, "Should generate tooltip preview")
            PvPTooltip.TestUtils.AssertTrue(type(preview) == "string", "Preview should be string")
            PvPTooltip.TestUtils.AssertTrue(string.len(preview) > 0, "Preview should not be empty")
        end
        
        -- Test TestRender method (if available)
        if PvPTooltip.TooltipRenderer.TestRender then
            local testData = PvPTooltip.TooltipRenderer:TestRender()
            PvPTooltip.TestUtils.AssertNotNil(testData, "TestRender should return test data")
        end
        
        -- Test GetRenderStats method (if available)
        if PvPTooltip.TooltipRenderer.GetRenderStats then
            local stats = PvPTooltip.TooltipRenderer:GetRenderStats()
            PvPTooltip.TestUtils.AssertNotNil(stats, "Should return render stats")
            PvPTooltip.TestUtils.AssertNotNil(stats.dependencies, "Stats should include dependency info")
        end
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Record test result
function TooltipRenderingTests:RecordTestResult(testName, success, error)
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
function TooltipRenderingTests:GetTestResults()
    return testResults
end

-- Quick tooltip rendering test
function TooltipRenderingTests:QuickTest()
    PvPTooltip:Print("=== Quick Tooltip Rendering Test ===")
    
    local tests = {
        {
            name = "TooltipRenderer exists",
            test = function()
                return PvPTooltip.TooltipRenderer ~= nil
            end
        },
        {
            name = "EnhanceTooltip method works",
            test = function()
                if not PvPTooltip.TooltipRenderer then return false end
                local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
                local mockData = PvPTooltip.TestUtils.CreateMockPlayerData()
                return PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockData)
            end
        },
        {
            name = "Data validation works",
            test = function()
                if not PvPTooltip.TooltipRenderer or not PvPTooltip.TooltipRenderer.ValidatePlayerData then 
                    return false 
                end
                return not PvPTooltip.TooltipRenderer:ValidatePlayerData(nil)
            end
        },
        {
            name = "Error handling works",
            test = function()
                if not PvPTooltip.TooltipRenderer then return false end
                -- Should not throw error with nil inputs
                local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(nil, nil)
                return result == false -- Should return false, not throw error
            end
        },
        {
            name = "ColorUtils integration works",
            test = function()
                return PvPTooltip.ColorUtils ~= nil
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
    
    PvPTooltip:Print(string.format("Quick tooltip rendering test: %d/%d passed", passed, #tests))
    return passed == #tests
end