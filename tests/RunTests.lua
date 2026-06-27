-- PvPTooltip Test Runner
-- Convenient script to run all tests or specific test suites

-- Test runner commands for easy execution
local TestRunner = {}

-- Run all tests
function TestRunner:RunAllTests()
    if not PvPTooltip or not PvPTooltip.TestSuite then
        print("PvPTooltip TestSuite not available. Make sure the addon is loaded.")
        return false
    end
    
    print("=== Running Complete PvPTooltip Test Suite ===")
    local results = PvPTooltip.TestSuite:RunAllTests()
    
    return results.failedTests == 0
end

-- Run quick smoke tests
function TestRunner:RunQuickTests()
    if not PvPTooltip or not PvPTooltip.TestSuite then
        print("PvPTooltip TestSuite not available. Make sure the addon is loaded.")
        return false
    end
    
    print("=== Running Quick Smoke Tests ===")
    return PvPTooltip.TestSuite:RunQuickTests()
end

-- Run specific test category
function TestRunner:RunCategory(category)
    if not PvPTooltip or not PvPTooltip.TestSuite then
        print("PvPTooltip TestSuite not available. Make sure the addon is loaded.")
        return false
    end
    
    print("=== Running " .. string.upper(category) .. " Tests ===")
    
    -- Temporarily enable only the specified category
    local originalConfig = PvPTooltip.TestSuite:GetTestConfig()
    
    PvPTooltip.TestSuite:SetTestCategory("unit", category == "unit")
    PvPTooltip.TestSuite:SetTestCategory("integration", category == "integration")
    PvPTooltip.TestSuite:SetTestCategory("performance", category == "performance")
    
    local results = PvPTooltip.TestSuite:RunAllTests()
    
    -- Restore original configuration
    PvPTooltip.TestSuite:SetTestConfig(originalConfig)
    
    return results.failedTests == 0
end

-- Run unit tests only
function TestRunner:RunUnitTests()
    return self:RunCategory("unit")
end

-- Run integration tests only
function TestRunner:RunIntegrationTests()
    return self:RunCategory("integration")
end

-- Run performance tests only
function TestRunner:RunPerformanceTests()
    return self:RunCategory("performance")
end

-- Run specific test module
function TestRunner:RunModule(moduleName)
    if not PvPTooltip or not PvPTooltip.TestSuite then
        print("PvPTooltip TestSuite not available. Make sure the addon is loaded.")
        return false
    end
    
    print("=== Running " .. moduleName .. " Module ===")
    local results = PvPTooltip.TestSuite:RunTestModule(moduleName)
    
    if results then
        return results.failed == 0
    else
        return false
    end
end

-- Generate test report
function TestRunner:GenerateReport(format)
    if not PvPTooltip or not PvPTooltip.TestSuite then
        print("PvPTooltip TestSuite not available. Make sure the addon is loaded.")
        return nil
    end
    
    return PvPTooltip.TestSuite:GenerateReport(format or "console")
end

-- Get last test results
function TestRunner:GetLastResults()
    if not PvPTooltip or not PvPTooltip.TestSuite then
        print("PvPTooltip TestSuite not available. Make sure the addon is loaded.")
        return nil
    end
    
    return PvPTooltip.TestSuite:GetLastResults()
end

-- Expose TestRunner globally for easy access
_G.PvPTooltipTestRunner = TestRunner

-- Convenience functions for slash commands or console use
_G.RunPvPTooltipTests = function() return TestRunner:RunAllTests() end
_G.RunPvPTooltipQuickTests = function() return TestRunner:RunQuickTests() end
_G.RunPvPTooltipUnitTests = function() return TestRunner:RunUnitTests() end
_G.RunPvPTooltipIntegrationTests = function() return TestRunner:RunIntegrationTests() end
_G.RunPvPTooltipPerformanceTests = function() return TestRunner:RunPerformanceTests() end

-- Individual module test functions
_G.RunDatabaseTests = function() return TestRunner:RunModule("DatabaseTests") end
_G.RunPlayerLookupTests = function() return TestRunner:RunModule("PlayerLookupTests") end
_G.RunTooltipRenderingTests = function() return TestRunner:RunModule("TooltipRenderingTests") end
_G.RunPerformanceBenchmarks = function() return TestRunner:RunModule("PerformanceBenchmarks") end
_G.RunIntegrationTests = function() return TestRunner:RunModule("IntegrationTests") end
_G.RunErrorHandlingTests = function() return TestRunner:RunModule("ErrorHandlingTests") end

-- Print usage instructions
function TestRunner:PrintUsage()
    print("=== PvPTooltip Test Runner Usage ===")
    print("Available commands:")
    print("  RunPvPTooltipTests() - Run all tests")
    print("  RunPvPTooltipQuickTests() - Run quick smoke tests")
    print("  RunPvPTooltipUnitTests() - Run unit tests only")
    print("  RunPvPTooltipIntegrationTests() - Run integration tests only")
    print("  RunPvPTooltipPerformanceTests() - Run performance tests only")
    print("")
    print("Individual module tests:")
    print("  RunDatabaseTests() - Test database functionality")
    print("  RunPlayerLookupTests() - Test player lookup functionality")
    print("  RunTooltipRenderingTests() - Test tooltip rendering")
    print("  RunPerformanceBenchmarks() - Run performance benchmarks")
    print("  RunIntegrationTests() - Run integration tests")
    print("  RunErrorHandlingTests() - Test error handling")
    print("")
    print("Advanced usage:")
    print("  PvPTooltipTestRunner:GenerateReport('json') - Generate JSON report")
    print("  PvPTooltipTestRunner:GetLastResults() - Get detailed results")
end

-- Auto-print usage when this file is loaded
TestRunner:PrintUsage()

return TestRunner