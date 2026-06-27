-- PvPTooltip Test Configuration
-- Configuration settings for the test suite

local TestConfig = {
    -- Test execution settings
    execution = {
        enableUnitTests = true,
        enableIntegrationTests = true,
        enablePerformanceTests = true,
        verboseOutput = false,
        stopOnFirstFailure = false,
        testTimeout = 30, -- seconds
        parallelExecution = false
    },
    
    -- Performance thresholds
    performance = {
        thresholds = {
            databaseLookup = 50,        -- milliseconds
            tooltipRender = 10,         -- milliseconds
            memoryUsage = 1024,         -- KB
            cacheAccess = 1,            -- milliseconds
            initialization = 5000,      -- milliseconds
            validation = 0.1            -- milliseconds
        },
        
        -- Benchmark settings
        benchmarks = {
            lookupIterations = 100,
            renderIterations = 200,
            stressTestIterations = 500,
            memoryTestIterations = 100
        }
    },
    
    -- Test data settings
    testData = {
        mockPlayerCount = 10,
        mockRealmNames = {
            "test-realm",
            "example-server",
            "mock-realm"
        },
        mockRegions = {"eu", "us"},
        
        -- Sample player data for testing
        samplePlayers = {
            {
                name = "TestWarrior",
                realm = "test-realm",
                region = "eu",
                brackets = {
                    ["2v2"] = {currentRating = 2000, personalBest = 2200, playedTotal = 75, winRate = 64.0},
                    ["3v3"] = {currentRating = 1850, personalBest = 2000, playedTotal = 45, winRate = 57.8},
                    ["shuffle"] = {currentRating = 2300, personalBest = 2400, playedTotal = 120, winRate = 68.3, shuffleSpecId = 71}
                }
            },
            {
                name = "TestMage",
                realm = "example-server",
                region = "us",
                brackets = {
                    ["2v2"] = {currentRating = 1750, personalBest = 1900, playedTotal = 32, winRate = 53.1},
                    ["rbg"] = {currentRating = 2100, personalBest = 2250, playedTotal = 28, winRate = 75.0},
                    ["blitz"] = {currentRating = 1950, personalBest = 2050, playedTotal = 67, winRate = 59.7}
                }
            }
        }
    },
    
    -- Error simulation settings
    errorSimulation = {
        enableCorruptedDataTests = true,
        enableMissingDependencyTests = true,
        enableMemoryLeakTests = true,
        enableTimeoutTests = true
    },
    
    -- Reporting settings
    reporting = {
        generateDetailedReports = true,
        saveReportsToFile = false,
        reportFormats = {"console", "json"},
        includePerformanceGraphs = false,
        includeMemoryAnalysis = true
    },
    
    -- Integration test settings
    integration = {
        testRealDatabaseLookups = false, -- Set to true to test with actual database
        testEventHandling = true,
        testCrossComponentCommunication = true,
        testConfigurationIntegration = true,
        testCompatibilityScenarios = true
    },
    
    -- Debug settings
    debug = {
        enableDebugOutput = true,
        logTestExecution = false,
        captureErrorDetails = true,
        enablePerformanceProfiling = false
    }
}

-- Apply test configuration to PvPTooltip if available
if PvPTooltip then
    if not PvPTooltip.Config then
        PvPTooltip.Config = {}
    end
    
    if not PvPTooltip.Config.Testing then
        PvPTooltip.Config.Testing = {}
    end
    
    -- Merge test configuration
    for key, value in pairs(TestConfig) do
        PvPTooltip.Config.Testing[key] = value
    end
    
    -- Set performance thresholds in main config
    if not PvPTooltip.Config.Performance then
        PvPTooltip.Config.Performance = {}
    end
    
    PvPTooltip.Config.Performance.thresholds = TestConfig.performance.thresholds
end

-- Export configuration
return TestConfig