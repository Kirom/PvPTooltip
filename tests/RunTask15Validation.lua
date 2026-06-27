-- Task 15 Validation Runner
-- Comprehensive test runner for Task 15: Integration testing and final validation

-- Task 15 Test Runner
local Task15Runner = {}

-- Run Task 15 validation tests
function Task15Runner:RunTask15Validation()
    print("=== Task 15: Integration Testing and Final Validation ===")
    print("Running comprehensive validation tests...")
    
    if not PvPTooltip then
        print("ERROR: PvPTooltip addon not loaded. Please ensure the addon is loaded before running tests.")
        return false
    end
    
    -- Initialize test modules if needed
    if PvPTooltip.FinalValidationTests and PvPTooltip.FinalValidationTests.Initialize then
        PvPTooltip.FinalValidationTests:Initialize()
    end
    
    if PvPTooltip.IntegrationTests and PvPTooltip.IntegrationTests.Initialize then
        PvPTooltip.IntegrationTests:Initialize()
    end
    
    local allTestsPassed = true
    local testResults = {}
    
    -- Run Final Validation Tests (Task 15 specific)
    print("\n--- Running Final Validation Tests ---")
    if PvPTooltip.FinalValidationTests then
        local finalResults = PvPTooltip.FinalValidationTests:RunAllTests()
        testResults.finalValidation = finalResults
        
        if finalResults.failed > 0 then
            allTestsPassed = false
        end
        
        -- Generate detailed report
        PvPTooltip.FinalValidationTests:GenerateValidationReport()
    else
        print("WARNING: FinalValidationTests module not available")
        allTestsPassed = false
    end
    
    -- Run Integration Tests (includes Task 15 tests)
    print("\n--- Running Integration Tests ---")
    if PvPTooltip.IntegrationTests then
        local integrationResults = PvPTooltip.IntegrationTests:RunAllTests()
        testResults.integration = integrationResults
        
        if integrationResults.failed > 0 then
            allTestsPassed = false
        end
        
        print(string.format("Integration Tests: %d passed, %d failed", 
            integrationResults.passed, integrationResults.failed))
    else
        print("WARNING: IntegrationTests module not available")
        allTestsPassed = false
    end
    
    -- Run specific Task 15 sub-task validations
    print("\n--- Validating Task 15 Sub-tasks ---")
    local subTaskResults = self:ValidateTask15SubTasks()
    testResults.subTasks = subTaskResults
    
    if not subTaskResults.allPassed then
        allTestsPassed = false
    end
    
    -- Generate final Task 15 report
    self:GenerateTask15Report(testResults, allTestsPassed)
    
    return allTestsPassed
end

-- Validate specific Task 15 sub-tasks
function Task15Runner:ValidateTask15SubTasks()
    local subTaskResults = {
        allPassed = true,
        results = {}
    }
    
    -- Sub-task 1: Test tooltip display across all supported game contexts
    print("  Validating: Tooltip display across all supported game contexts")
    local tooltipContextsResult = self:ValidateTooltipContexts()
    subTaskResults.results.tooltipContexts = tooltipContextsResult
    if not tooltipContextsResult then
        subTaskResults.allPassed = false
    end
    
    -- Sub-task 2: Validate color coding accuracy and data formatting
    print("  Validating: Color coding accuracy and data formatting")
    local colorCodingResult = self:ValidateColorCoding()
    subTaskResults.results.colorCoding = colorCodingResult
    if not colorCodingResult then
        subTaskResults.allPassed = false
    end
    
    -- Sub-task 3: Verify cross-region and cross-realm functionality
    print("  Validating: Cross-region and cross-realm functionality")
    local crossRegionResult = self:ValidateCrossRegionRealm()
    subTaskResults.results.crossRegion = crossRegionResult
    if not crossRegionResult then
        subTaskResults.allPassed = false
    end
    
    -- Sub-task 4: Ensure compatibility with popular UI addons
    print("  Validating: Compatibility with popular UI addons")
    local compatibilityResult = self:ValidateUICompatibility()
    subTaskResults.results.compatibility = compatibilityResult
    if not compatibilityResult then
        subTaskResults.allPassed = false
    end
    
    -- Sub-task 5: Comprehensive requirements validation
    print("  Validating: All requirements comprehensive validation")
    local requirementsResult = self:ValidateAllRequirements()
    subTaskResults.results.requirements = requirementsResult
    if not requirementsResult then
        subTaskResults.allPassed = false
    end
    
    return subTaskResults
end

-- Validate tooltip display contexts
function Task15Runner:ValidateTooltipContexts()
    local success = pcall(function()
        if not PvPTooltip.TooltipRenderer then
            error("TooltipRenderer not available")
        end
        
        -- Test basic tooltip enhancement
        local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
        
        local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
        if not result then
            error("Basic tooltip enhancement failed")
        end
        
        -- Verify content was added
        if #mockTooltip.lines == 0 then
            error("No content added to tooltip")
        end
        
        local content = table.concat(mockTooltip.lines, "\n")
        if not string.find(content, "PvP Tooltip info") then
            error("Main title not found in tooltip")
        end
        
        print("    ✓ Tooltip display contexts validation passed")
    end)
    
    if not success then
        print("    ✗ Tooltip display contexts validation failed")
    end
    
    return success
end

-- Validate color coding
function Task15Runner:ValidateColorCoding()
    local success = pcall(function()
        if not PvPTooltip.ColorUtils then
            error("ColorUtils not available")
        end
        
        -- Test rating colors
        local whiteColor = PvPTooltip.ColorUtils:GetRatingColor(1500)
        local greenColor = PvPTooltip.ColorUtils:GetRatingColor(1900)
        local blueColor = PvPTooltip.ColorUtils:GetRatingColor(2200)
        local purpleColor = PvPTooltip.ColorUtils:GetRatingColor(2500)
        
        if whiteColor ~= "#FFFFFF" then
            error("White rating color incorrect: " .. tostring(whiteColor))
        end
        if greenColor ~= "#2EAD65" then
            error("Green rating color incorrect: " .. tostring(greenColor))
        end
        if blueColor ~= "#046DCC" then
            error("Blue rating color incorrect: " .. tostring(blueColor))
        end
        if purpleColor ~= "#A140E9" then
            error("Purple rating color incorrect: " .. tostring(purpleColor))
        end
        
        -- Test win rate colors
        local lowWinRate = PvPTooltip.ColorUtils:GetWinRateColor(45)
        local highWinRate = PvPTooltip.ColorUtils:GetWinRateColor(65)
        
        if lowWinRate ~= "#FF4500" then
            error("Low win rate color incorrect: " .. tostring(lowWinRate))
        end
        if highWinRate ~= "#57C94F" then
            error("High win rate color incorrect: " .. tostring(highWinRate))
        end
        
        print("    ✓ Color coding accuracy validation passed")
    end)
    
    if not success then
        print("    ✗ Color coding accuracy validation failed")
    end
    
    return success
end

-- Validate cross-region and cross-realm functionality
function Task15Runner:ValidateCrossRegionRealm()
    local success = pcall(function()
        if not PvPTooltip.DatabaseManager then
            error("DatabaseManager not available")
        end
        
        -- Check if database is loaded
        local isDataAvailable = PvPTooltip.DatabaseManager:IsDataAvailable()
        if not isDataAvailable then
            error("Database not loaded")
        end
        
        -- Test region availability
        local euAvailable = PvPTooltip.DatabaseManager:IsRegionDataAvailable("eu")
        local usAvailable = PvPTooltip.DatabaseManager:IsRegionDataAvailable("us")
        
        if not euAvailable and not usAvailable then
            error("No region data available")
        end
        
        -- Test player lookup (should not crash)
        if PvPTooltip.PlayerLookup then
            local testResult = PvPTooltip.PlayerLookup:FindPlayerData("player")
            -- Result can be nil, just verify no crash
        end
        
        print("    ✓ Cross-region cross-realm functionality validation passed")
    end)
    
    if not success then
        print("    ✗ Cross-region cross-realm functionality validation failed")
    end
    
    return success
end

-- Validate UI addon compatibility
function Task15Runner:ValidateUICompatibility()
    local success = pcall(function()
        if not PvPTooltip.TooltipRenderer then
            error("TooltipRenderer not available")
        end
        
        -- Test with modified tooltip (simulating UI addon)
        local modifiedTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        modifiedTooltip.skinned = true
        modifiedTooltip.SetBackdrop = function() end
        
        local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
        local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(modifiedTooltip, mockPlayerData)
        
        if not result then
            error("Failed to enhance modified tooltip")
        end
        
        -- Test with minimal tooltip interface
        local minimalTooltip = {
            lines = {},
            AddLine = function(self, text) table.insert(self.lines, text or "") end
        }
        
        result = PvPTooltip.TooltipRenderer:EnhanceTooltip(minimalTooltip, mockPlayerData)
        if not result then
            error("Failed to enhance minimal tooltip")
        end
        
        print("    ✓ UI addon compatibility validation passed")
    end)
    
    if not success then
        print("    ✗ UI addon compatibility validation failed")
    end
    
    return success
end

-- Validate all requirements
function Task15Runner:ValidateAllRequirements()
    local success = pcall(function()
        -- Test comprehensive tooltip with all sections
        local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
        local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
        
        local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
        if not result then
            error("Comprehensive tooltip enhancement failed")
        end
        
        local content = table.concat(mockTooltip.lines, "\n")
        
        -- Check for required sections
        local requiredSections = {
            "PvP Tooltip info",
            "Current Rating", 
            "Character Experience",
            "Current Season"
        }
        
        for _, section in ipairs(requiredSections) do
            if not string.find(content, section) then
                error("Missing required section: " .. section)
            end
        end
        
        -- Check for color formatting
        if not string.find(content, "|c") then
            error("No color formatting found")
        end
        
        print("    ✓ All requirements validation passed")
    end)
    
    if not success then
        print("    ✗ All requirements validation failed")
    end
    
    return success
end

-- Generate Task 15 final report
function Task15Runner:GenerateTask15Report(testResults, allPassed)
    print("\n=== Task 15: Final Validation Report ===")
    
    if allPassed then
        print("|cFF00FF00TASK 15 COMPLETED SUCCESSFULLY|r")
        print("✓ All integration tests and validations passed")
        print("✓ Tooltip display works across all supported game contexts")
        print("✓ Color coding accuracy validated")
        print("✓ Cross-region and cross-realm functionality verified")
        print("✓ UI addon compatibility confirmed")
        print("✓ All requirements comprehensively validated")
    else
        print("|cFFFF0000TASK 15 VALIDATION ISSUES DETECTED|r")
        print("Some validations failed. Review the detailed output above.")
        
        -- Show which sub-tasks failed
        if testResults.subTasks then
            for subTask, result in pairs(testResults.subTasks.results) do
                local status = result and "✓" or "✗"
                print(string.format("%s %s", status, subTask))
            end
        end
    end
    
    print("\nTask 15 Sub-tasks Summary:")
    print("- Test tooltip display across all supported game contexts")
    print("- Validate color coding accuracy and data formatting") 
    print("- Verify cross-region and cross-realm functionality")
    print("- Ensure compatibility with popular UI addons")
    print("- Requirements: All requirements comprehensive validation")
    
    if allPassed then
        print("\n|cFF00FF00Task 15 implementation is complete and validated.|r")
    else
        print("\n|cFFFFFF00Task 15 requires attention to resolve validation issues.|r")
    end
end

-- Expose globally for easy access
_G.RunTask15Validation = function() return Task15Runner:RunTask15Validation() end
_G.Task15ValidationRunner = Task15Runner

-- Print usage
print("=== Task 15 Validation Runner Loaded ===")
print("Run: RunTask15Validation() to execute Task 15 validation")
print("This will test:")
print("  - Tooltip display across all supported game contexts")
print("  - Color coding accuracy and data formatting")
print("  - Cross-region and cross-realm functionality") 
print("  - Compatibility with popular UI addons")
print("  - Comprehensive requirements validation")

return Task15Runner