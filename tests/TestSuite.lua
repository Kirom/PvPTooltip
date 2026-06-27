-- PvPTooltip Comprehensive Test Suite
-- Main test runner and coordinator for all test modules

local TestSuite = {}
PvPTooltip.TestSuite = TestSuite

-- Test modules
local testModules = {}
local testResults = {}
local testConfig = {
    enablePerformanceTests = true,
    enableIntegrationTests = true,
    enableUnitTests = true,
    verboseOutput = false,
    stopOnFirstFailure = false,
    testTimeout = 30 -- seconds
}

-- Initialize the test suite
function TestSuite:Initialize()
    PvPTooltip:Debug("TestSuite initializing...")
    
    -- Register test modules
    self:RegisterTestModules()
    
    -- Initialize test environment
    self:InitializeTestEnvironment()
    
    PvPTooltip:Debug("TestSuite initialized with " .. #testModules .. " test modules")
end

-- Register all test modules
function TestSuite:RegisterTestModules()
    testModules = {
        {
            name = "DatabaseTests",
            module = PvPTooltip.DatabaseTests,
            category = "unit",
            description = "Unit tests for database loading and management"
        },
        {
            name = "PlayerLookupTests",
            module = PvPTooltip.PlayerLookupTests,
            category = "unit",
            description = "Unit tests for player lookup functionality"
        },
        {
            name = "TooltipRenderingTests",
            module = PvPTooltip.TooltipRenderingTests,
            category = "integration",
            description = "Integration tests for tooltip rendering"
        },
        {
            name = "PerformanceBenchmarks",
            module = PvPTooltip.PerformanceBenchmarks,
            category = "performance",
            description = "Performance benchmarks and memory usage tests"
        },
        {
            name = "ErrorHandlingTests",
            module = PvPTooltip.ErrorHandlingTests,
            category = "unit",
            description = "Error handling and graceful degradation tests"
        },
        {
            name = "IntegrationTests",
            module = PvPTooltip.IntegrationTests,
            category = "integration",
            description = "End-to-end integration tests"
        },
        {
            name = "FinalValidationTests",
            module = PvPTooltip.FinalValidationTests,
            category = "integration",
            description = "Task 15: Final validation and comprehensive testing"
        }
    }
    
    -- Initialize all test modules
    for _, testModule in ipairs(testModules) do
        if testModule.module and testModule.module.Initialize then
            local success, error = pcall(testModule.module.Initialize, testModule.module)
            if not success then
                PvPTooltip:Debug("Failed to initialize test module " .. testModule.name .. ": " .. tostring(error))
            end
        end
    end
end

-- Initialize test environment
function TestSuite:InitializeTestEnvironment()
    -- Create test data directory if needed
    if not PvPTooltip.TestData then
        PvPTooltip.TestData = {}
    end
    
    -- Initialize test utilities
    self:InitializeTestUtilities()
    
    -- Set up test configuration
    self:LoadTestConfiguration()
end

-- Initialize test utilities
function TestSuite:InitializeTestUtilities()
    PvPTooltip.TestUtils = {
        -- Mock tooltip object for testing
        CreateMockTooltip = function()
            return {
                lines = {},
                AddLine = function(self, text)
                    table.insert(self.lines, text or "")
                end,
                GetUnit = function() return "player", "player" end,
                IsShown = function() return true end,
                Show = function() end,
                Hide = function() end
            }
        end,
        
        -- Mock player data for testing
        CreateMockPlayerData = function(name, realm, region)
            return {
                name = name or "TestPlayer",
                realm = realm or "test-realm",
                region = region or "eu",
                brackets = {
                    ["2v2"] = {
                        currentRating = 2000,
                        personalBest = 2200,
                        seasonBest = 2100,
                        playedTotal = 50,
                        winRate = 60.0
                    },
                    ["3v3"] = {
                        currentRating = 1850,
                        personalBest = 2000,
                        seasonBest = 1900,
                        playedTotal = 30,
                        winRate = 55.0
                    },
                    ["shuffle"] = {
                        currentRating = 2300,
                        personalBest = 2400,
                        seasonBest = 2350,
                        playedTotal = 80,
                        winRate = 65.0,
                        shuffleSpecId = 270
                    }
                }
            }
        end,
        
        -- Assert functions for testing
        AssertEquals = function(expected, actual, message)
            if expected ~= actual then
                error(string.format("Assertion failed: %s. Expected: %s, Actual: %s", 
                    message or "Values not equal", tostring(expected), tostring(actual)))
            end
        end,
        
        AssertNotNil = function(value, message)
            if value == nil then
                error(message or "Value should not be nil")
            end
        end,
        
        AssertNil = function(value, message)
            if value ~= nil then
                error(message or "Value should be nil")
            end
        end,
        
        AssertTrue = function(value, message)
            if not value then
                error(message or "Value should be true")
            end
        end,
        
        AssertFalse = function(value, message)
            if value then
                error(message or "Value should be false")
            end
        end,
        
        -- Performance measurement utilities
        MeasureTime = function(func)
            local startTime = GetTime()
            local success, result = pcall(func)
            local endTime = GetTime()
            return success, result, (endTime - startTime) * 1000 -- Return time in milliseconds
        end,
        
        -- Memory measurement utilities
        MeasureMemory = function(func)
            collectgarbage("collect")
            local startMemory = collectgarbage("count")
            local success, result = pcall(func)
            collectgarbage("collect")
            local endMemory = collectgarbage("count")
            return success, result, endMemory - startMemory -- Return memory difference in KB
        end
    }
end

-- Load test configuration
function TestSuite:LoadTestConfiguration()
    -- Default configuration
    testConfig = {
        enablePerformanceTests = true,
        enableIntegrationTests = true,
        enableUnitTests = true,
        verboseOutput = false,
        stopOnFirstFailure = false,
        testTimeout = 30,
        performanceThresholds = {
            databaseLookup = 50, -- milliseconds
            tooltipRender = 10,  -- milliseconds
            memoryUsage = 1024   -- KB
        }
    }
    
    -- Override with saved settings if available
    if PvPTooltip.Config and PvPTooltip.Config.Testing then
        for key, value in pairs(PvPTooltip.Config.Testing) do
            testConfig[key] = value
        end
    end
end

-- Run all tests
function TestSuite:RunAllTests()
    PvPTooltip:Print("=== PvPTooltip Comprehensive Test Suite ===")
    PvPTooltip:Print("Starting test execution...")
    
    testResults = {
        startTime = GetTime(),
        totalTests = 0,
        passedTests = 0,
        failedTests = 0,
        skippedTests = 0,
        modules = {}
    }
    
    -- Run tests by category
    if testConfig.enableUnitTests then
        self:RunTestsByCategory("unit")
    end
    
    if testConfig.enableIntegrationTests then
        self:RunTestsByCategory("integration")
    end
    
    if testConfig.enablePerformanceTests then
        self:RunTestsByCategory("performance")
    end
    
    -- Generate final report
    self:GenerateFinalReport()
    
    return testResults
end

-- Run tests by category
function TestSuite:RunTestsByCategory(category)
    PvPTooltip:Print(string.format("=== Running %s Tests ===", string.upper(category)))
    
    for _, testModule in ipairs(testModules) do
        if testModule.category == category and testModule.module then
            self:RunTestModule(testModule)
            
            if testConfig.stopOnFirstFailure and testResults.failedTests > 0 then
                PvPTooltip:Print("Stopping test execution due to failure (stopOnFirstFailure enabled)")
                break
            end
        end
    end
end

-- Run a single test module
function TestSuite:RunTestModule(testModule)
    PvPTooltip:Print(string.format("Running %s: %s", testModule.name, testModule.description))
    
    local moduleResults = {
        name = testModule.name,
        category = testModule.category,
        startTime = GetTime(),
        tests = {},
        passed = 0,
        failed = 0,
        skipped = 0,
        errors = {}
    }
    
    -- Check if module is available
    if not testModule.module then
        PvPTooltip:Print("  Module not available - SKIPPED")
        moduleResults.skipped = 1
        testResults.skippedTests = testResults.skippedTests + 1
        testResults.modules[testModule.name] = moduleResults
        return
    end
    
    -- Run module tests with timeout protection
    local success, result = self:RunWithTimeout(function()
        return testModule.module:RunAllTests()
    end, testConfig.testTimeout)
    
    if not success then
        PvPTooltip:Print("  Module execution failed: " .. tostring(result))
        moduleResults.failed = 1
        moduleResults.errors = {result}
        testResults.failedTests = testResults.failedTests + 1
    else
        -- Process module results
        if type(result) == "table" and result.tests then
            for testName, testResult in pairs(result.tests) do
                moduleResults.tests[testName] = testResult
                if testResult.success then
                    moduleResults.passed = moduleResults.passed + 1
                    testResults.passedTests = testResults.passedTests + 1
                else
                    moduleResults.failed = moduleResults.failed + 1
                    testResults.failedTests = testResults.failedTests + 1
                    if testResult.error then
                        table.insert(moduleResults.errors, testResult.error)
                    end
                end
            end
        else
            -- Simple boolean result
            if result then
                moduleResults.passed = 1
                testResults.passedTests = testResults.passedTests + 1
            else
                moduleResults.failed = 1
                testResults.failedTests = testResults.failedTests + 1
            end
        end
    end
    
    moduleResults.endTime = GetTime()
    moduleResults.duration = (moduleResults.endTime - moduleResults.startTime) * 1000
    
    testResults.totalTests = testResults.totalTests + moduleResults.passed + moduleResults.failed + moduleResults.skipped
    testResults.modules[testModule.name] = moduleResults
    
    -- Print module summary
    local status = moduleResults.failed > 0 and "|cFFFF0000FAILED|r" or "|cFF00FF00PASSED|r"
    PvPTooltip:Print(string.format("  %s (%d passed, %d failed, %d skipped) - %.2fms", 
        status, moduleResults.passed, moduleResults.failed, moduleResults.skipped, moduleResults.duration))
    
    if testConfig.verboseOutput and #moduleResults.errors > 0 then
        for _, error in ipairs(moduleResults.errors) do
            PvPTooltip:Print("    Error: " .. tostring(error))
        end
    end
end

-- Run function with timeout protection
function TestSuite:RunWithTimeout(func, timeout)
    local startTime = GetTime()
    local success, result = pcall(func)
    local duration = GetTime() - startTime
    
    if duration > timeout then
        return false, "Test execution timed out after " .. timeout .. " seconds"
    end
    
    return success, result
end

-- Generate final test report
function TestSuite:GenerateFinalReport()
    testResults.endTime = GetTime()
    testResults.totalDuration = (testResults.endTime - testResults.startTime) * 1000
    
    PvPTooltip:Print("=== Test Suite Results ===")
    PvPTooltip:Print(string.format("Total Tests: %d", testResults.totalTests))
    PvPTooltip:Print(string.format("Passed: %d", testResults.passedTests))
    PvPTooltip:Print(string.format("Failed: %d", testResults.failedTests))
    PvPTooltip:Print(string.format("Skipped: %d", testResults.skippedTests))
    PvPTooltip:Print(string.format("Total Duration: %.2fms", testResults.totalDuration))
    
    local successRate = testResults.totalTests > 0 and 
        (testResults.passedTests / testResults.totalTests * 100) or 0
    PvPTooltip:Print(string.format("Success Rate: %.1f%%", successRate))
    
    -- Module breakdown
    PvPTooltip:Print("\nModule Breakdown:")
    for moduleName, moduleResults in pairs(testResults.modules) do
        local status = moduleResults.failed > 0 and "FAILED" or "PASSED"
        PvPTooltip:Print(string.format("  %s: %s (%d/%d passed)", 
            moduleName, status, moduleResults.passed, moduleResults.passed + moduleResults.failed))
    end
    
    -- Overall result
    if testResults.failedTests == 0 then
        PvPTooltip:Print("|cFF00FF00All tests passed!|r")
    else
        PvPTooltip:Print("|cFFFF0000Some tests failed. Check the output above for details.|r")
    end
    
    -- Save results for external access
    PvPTooltip.LastTestResults = testResults
end

-- Run specific test module by name
function TestSuite:RunTestModule(moduleName)
    for _, testModule in ipairs(testModules) do
        if testModule.name == moduleName then
            PvPTooltip:Print("Running single test module: " .. moduleName)
            self:RunTestModule(testModule)
            return testResults.modules[moduleName]
        end
    end
    
    PvPTooltip:Print("Test module not found: " .. moduleName)
    return nil
end

-- Run quick smoke tests
function TestSuite:RunQuickTests()
    PvPTooltip:Print("=== Quick Smoke Tests ===")
    
    local quickTests = {
        {
            name = "Addon Initialization",
            test = function()
                return PvPTooltip ~= nil and PvPTooltip.DatabaseManager ~= nil
            end
        },
        {
            name = "Database Availability",
            test = function()
                return PvPTooltip.DatabaseManager and PvPTooltip.DatabaseManager:IsDataAvailable()
            end
        },
        {
            name = "Player Lookup Ready",
            test = function()
                return PvPTooltip.PlayerLookup and PvPTooltip.PlayerLookup:IsReady()
            end
        },
        {
            name = "Tooltip Renderer Available",
            test = function()
                return PvPTooltip.TooltipRenderer ~= nil
            end
        },
        {
            name = "Color Utils Available",
            test = function()
                return PvPTooltip.ColorUtils ~= nil
            end
        }
    }
    
    local passed = 0
    for _, test in ipairs(quickTests) do
        local success, result = pcall(test.test)
        if success and result then
            PvPTooltip:Print("✓ " .. test.name)
            passed = passed + 1
        else
            PvPTooltip:Print("✗ " .. test.name .. (success and "" or " (error: " .. tostring(result) .. ")"))
        end
    end
    
    PvPTooltip:Print(string.format("Quick tests: %d/%d passed", passed, #quickTests))
    return passed == #quickTests
end

-- Get test configuration
function TestSuite:GetTestConfig()
    return testConfig
end

-- Set test configuration
function TestSuite:SetTestConfig(config)
    if type(config) == "table" then
        for key, value in pairs(config) do
            testConfig[key] = value
        end
        PvPTooltip:Debug("Test configuration updated")
    end
end

-- Get last test results
function TestSuite:GetLastResults()
    return testResults
end

-- Get available test modules
function TestSuite:GetTestModules()
    return testModules
end

-- Enable/disable specific test categories
function TestSuite:SetTestCategory(category, enabled)
    if category == "unit" then
        testConfig.enableUnitTests = enabled
    elseif category == "integration" then
        testConfig.enableIntegrationTests = enabled
    elseif category == "performance" then
        testConfig.enablePerformanceTests = enabled
    end
    
    PvPTooltip:Debug(string.format("%s tests %s", category, enabled and "enabled" or "disabled"))
end

-- Generate test report in different formats
function TestSuite:GenerateReport(format)
    format = format or "console"
    
    if format == "console" then
        self:GenerateFinalReport()
    elseif format == "json" then
        return self:GenerateJSONReport()
    elseif format == "summary" then
        return self:GenerateSummaryReport()
    end
end

-- Generate JSON report for external tools
function TestSuite:GenerateJSONReport()
    -- Simple JSON-like table structure
    return {
        summary = {
            totalTests = testResults.totalTests,
            passedTests = testResults.passedTests,
            failedTests = testResults.failedTests,
            skippedTests = testResults.skippedTests,
            successRate = testResults.totalTests > 0 and (testResults.passedTests / testResults.totalTests * 100) or 0,
            duration = testResults.totalDuration
        },
        modules = testResults.modules,
        timestamp = date("%Y-%m-%d %H:%M:%S"),
        version = PvPTooltip.Version or "unknown"
    }
end

-- Generate summary report
function TestSuite:GenerateSummaryReport()
    local summary = {
        status = testResults.failedTests == 0 and "PASSED" or "FAILED",
        total = testResults.totalTests,
        passed = testResults.passedTests,
        failed = testResults.failedTests,
        skipped = testResults.skippedTests,
        duration = testResults.totalDuration,
        modules = {}
    }
    
    for moduleName, moduleResults in pairs(testResults.modules) do
        summary.modules[moduleName] = {
            status = moduleResults.failed == 0 and "PASSED" or "FAILED",
            passed = moduleResults.passed,
            failed = moduleResults.failed,
            duration = moduleResults.duration
        }
    end
    
    return summary
end