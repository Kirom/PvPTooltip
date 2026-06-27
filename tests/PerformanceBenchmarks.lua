-- PvPTooltip Performance Benchmarks
-- Performance benchmarks and memory usage tests

local PerformanceBenchmarks = {}
PvPTooltip.PerformanceBenchmarks = PerformanceBenchmarks

-- Test results storage
local testResults = {}
local benchmarkResults = {}

-- Performance thresholds (in milliseconds unless noted)
local performanceThresholds = {
    databaseLookup = 50,        -- Database lookup should be < 50ms
    tooltipRender = 10,         -- Tooltip rendering should be < 10ms
    memoryUsage = 1024,         -- Memory usage should be < 1MB (in KB)
    cacheAccess = 1,            -- Cache access should be < 1ms
    initialization = 5000,      -- Initialization should be < 5 seconds
    validation = 0.1            -- Validation should be < 0.1ms per operation
}

-- Initialize performance benchmarks
function PerformanceBenchmarks:Initialize()
    PvPTooltip:Debug("PerformanceBenchmarks module initialized")
    
    -- Load performance thresholds from config if available
    if PvPTooltip.Config and PvPTooltip.Config.Performance then
        for key, value in pairs(PvPTooltip.Config.Performance.thresholds or {}) do
            performanceThresholds[key] = value
        end
    end
end

-- Run all performance benchmarks
function PerformanceBenchmarks:RunAllTests()
    PvPTooltip:Debug("Running PerformanceBenchmarks...")
    
    testResults = {
        tests = {},
        passed = 0,
        failed = 0,
        startTime = GetTime()
    }
    
    benchmarkResults = {
        databasePerformance = {},
        tooltipPerformance = {},
        memoryUsage = {},
        cachePerformance = {},
        overallPerformance = {}
    }
    
    -- Run database performance benchmarks
    self:BenchmarkDatabasePerformance()
    
    -- Run tooltip rendering benchmarks
    self:BenchmarkTooltipRendering()
    
    -- Run memory usage benchmarks
    self:BenchmarkMemoryUsage()
    
    -- Run cache performance benchmarks
    self:BenchmarkCachePerformance()
    
    -- Run initialization benchmarks
    self:BenchmarkInitialization()
    
    -- Run validation performance benchmarks
    self:BenchmarkValidationPerformance()
    
    -- Run stress tests
    self:RunStressTests()
    
    -- Generate performance report
    self:GeneratePerformanceReport()
    
    testResults.endTime = GetTime()
    testResults.duration = (testResults.endTime - testResults.startTime) * 1000
    
    return testResults
end

-- Benchmark database performance
function PerformanceBenchmarks:BenchmarkDatabasePerformance()
    local testName = "Database Performance"
    PvPTooltip:Debug("Benchmarking: " .. testName)
    
    local success, error = pcall(function()
        if not PvPTooltip.DatabaseManager then
            error("DatabaseManager not available")
        end
        
        local dbBenchmarks = {}
        
        -- Benchmark database loading
        local startTime = GetTime()
        local loadSuccess = PvPTooltip.DatabaseManager:ReloadDatabases()
        local loadTime = (GetTime() - startTime) * 1000
        
        dbBenchmarks.loadTime = loadTime
        dbBenchmarks.loadSuccess = loadSuccess
        
        PvPTooltip:Debug(string.format("Database load time: %.2fms", loadTime))
        
        -- Benchmark player data retrieval
        local lookupTimes = {}
        local lookupCount = 100
        
        for i = 1, lookupCount do
            startTime = GetTime()
            PvPTooltip.DatabaseManager:GetPlayerData("TestPlayer" .. i, "test-realm", "eu")
            local lookupTime = (GetTime() - startTime) * 1000
            table.insert(lookupTimes, lookupTime)
        end
        
        -- Calculate statistics
        local totalLookupTime = 0
        local minLookupTime = math.huge
        local maxLookupTime = 0
        
        for _, time in ipairs(lookupTimes) do
            totalLookupTime = totalLookupTime + time
            minLookupTime = math.min(minLookupTime, time)
            maxLookupTime = math.max(maxLookupTime, time)
        end
        
        local avgLookupTime = totalLookupTime / lookupCount
        
        dbBenchmarks.avgLookupTime = avgLookupTime
        dbBenchmarks.minLookupTime = minLookupTime
        dbBenchmarks.maxLookupTime = maxLookupTime
        dbBenchmarks.totalLookupTime = totalLookupTime
        
        PvPTooltip:Debug(string.format("Average lookup time: %.2fms (min: %.2fms, max: %.2fms)", 
            avgLookupTime, minLookupTime, maxLookupTime))
        
        -- Benchmark realm normalization
        local normalizationTimes = {}
        local normalizationCount = 1000
        
        for i = 1, normalizationCount do
            startTime = GetTime()
            PvPTooltip.DatabaseManager:NormalizeRealmName("Test Realm " .. i)
            local normTime = (GetTime() - startTime) * 1000
            table.insert(normalizationTimes, normTime)
        end
        
        local totalNormTime = 0
        for _, time in ipairs(normalizationTimes) do
            totalNormTime = totalNormTime + time
        end
        
        local avgNormTime = totalNormTime / normalizationCount
        dbBenchmarks.avgNormalizationTime = avgNormTime
        
        PvPTooltip:Debug(string.format("Average normalization time: %.4fms", avgNormTime))
        
        -- Performance validation
        local performanceIssues = {}
        
        if avgLookupTime > performanceThresholds.databaseLookup then
            table.insert(performanceIssues, string.format("Slow database lookups: %.2fms > %dms threshold", 
                avgLookupTime, performanceThresholds.databaseLookup))
        end
        
        if loadTime > performanceThresholds.initialization then
            table.insert(performanceIssues, string.format("Slow database loading: %.2fms > %dms threshold", 
                loadTime, performanceThresholds.initialization))
        end
        
        dbBenchmarks.performanceIssues = performanceIssues
        benchmarkResults.databasePerformance = dbBenchmarks
        
        -- Test passes if no critical performance issues
        local testPassed = #performanceIssues == 0
        if not testPassed then
            error("Performance thresholds exceeded: " .. table.concat(performanceIssues, "; "))
        end
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Benchmark tooltip rendering performance
function PerformanceBenchmarks:BenchmarkTooltipRendering()
    local testName = "Tooltip Rendering Performance"
    PvPTooltip:Debug("Benchmarking: " .. testName)
    
    local success, error = pcall(function()
        if not PvPTooltip.TooltipRenderer then
            error("TooltipRenderer not available")
        end
        
        local tooltipBenchmarks = {}
        local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
        
        -- Benchmark tooltip enhancement
        local renderTimes = {}
        local renderCount = 200
        
        for i = 1, renderCount do
            local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
            
            local startTime = GetTime()
            PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
            local renderTime = (GetTime() - startTime) * 1000
            
            table.insert(renderTimes, renderTime)
        end
        
        -- Calculate statistics
        local totalRenderTime = 0
        local minRenderTime = math.huge
        local maxRenderTime = 0
        
        for _, time in ipairs(renderTimes) do
            totalRenderTime = totalRenderTime + time
            minRenderTime = math.min(minRenderTime, time)
            maxRenderTime = math.max(maxRenderTime, time)
        end
        
        local avgRenderTime = totalRenderTime / renderCount
        
        tooltipBenchmarks.avgRenderTime = avgRenderTime
        tooltipBenchmarks.minRenderTime = minRenderTime
        tooltipBenchmarks.maxRenderTime = maxRenderTime
        tooltipBenchmarks.totalRenderTime = totalRenderTime
        
        PvPTooltip:Debug(string.format("Average render time: %.2fms (min: %.2fms, max: %.2fms)", 
            avgRenderTime, minRenderTime, maxRenderTime))
        
        -- Benchmark individual section rendering
        local sectionBenchmarks = {}
        
        -- Benchmark section title
        local sectionTimes = {}
        for i = 1, 100 do
            local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
            local startTime = GetTime()
            PvPTooltip.TooltipRenderer:AddSectionTitle(mockTooltip)
            local sectionTime = (GetTime() - startTime) * 1000
            table.insert(sectionTimes, sectionTime)
        end
        
        local avgSectionTime = 0
        for _, time in ipairs(sectionTimes) do
            avgSectionTime = avgSectionTime + time
        end
        avgSectionTime = avgSectionTime / #sectionTimes
        sectionBenchmarks.sectionTitle = avgSectionTime
        
        -- Benchmark rating section
        sectionTimes = {}
        for i = 1, 100 do
            local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
            local startTime = GetTime()
            PvPTooltip.TooltipRenderer:FormatRatingSection(mockTooltip, mockPlayerData.brackets)
            local sectionTime = (GetTime() - startTime) * 1000
            table.insert(sectionTimes, sectionTime)
        end
        
        avgSectionTime = 0
        for _, time in ipairs(sectionTimes) do
            avgSectionTime = avgSectionTime + time
        end
        avgSectionTime = avgSectionTime / #sectionTimes
        sectionBenchmarks.ratingSection = avgSectionTime
        
        tooltipBenchmarks.sectionBenchmarks = sectionBenchmarks
        
        -- Benchmark data validation
        local validationTimes = {}
        for i = 1, 1000 do
            local startTime = GetTime()
            PvPTooltip.TooltipRenderer:ValidatePlayerData(mockPlayerData)
            local validationTime = (GetTime() - startTime) * 1000
            table.insert(validationTimes, validationTime)
        end
        
        local avgValidationTime = 0
        for _, time in ipairs(validationTimes) do
            avgValidationTime = avgValidationTime + time
        end
        avgValidationTime = avgValidationTime / #validationTimes
        tooltipBenchmarks.avgValidationTime = avgValidationTime
        
        PvPTooltip:Debug(string.format("Average validation time: %.4fms", avgValidationTime))
        
        -- Performance validation
        local performanceIssues = {}
        
        if avgRenderTime > performanceThresholds.tooltipRender then
            table.insert(performanceIssues, string.format("Slow tooltip rendering: %.2fms > %dms threshold", 
                avgRenderTime, performanceThresholds.tooltipRender))
        end
        
        if avgValidationTime > performanceThresholds.validation then
            table.insert(performanceIssues, string.format("Slow validation: %.4fms > %.1fms threshold", 
                avgValidationTime, performanceThresholds.validation))
        end
        
        tooltipBenchmarks.performanceIssues = performanceIssues
        benchmarkResults.tooltipPerformance = tooltipBenchmarks
        
        -- Test passes if no critical performance issues
        local testPassed = #performanceIssues == 0
        if not testPassed then
            error("Performance thresholds exceeded: " .. table.concat(performanceIssues, "; "))
        end
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Benchmark memory usage
function PerformanceBenchmarks:BenchmarkMemoryUsage()
    local testName = "Memory Usage"
    PvPTooltip:Debug("Benchmarking: " .. testName)
    
    local success, error = pcall(function()
        local memoryBenchmarks = {}
        
        -- Force garbage collection before starting
        collectgarbage("collect")
        local baselineMemory = collectgarbage("count")
        
        -- Benchmark database loading memory usage
        collectgarbage("collect")
        local beforeDbLoad = collectgarbage("count")
        
        if PvPTooltip.DatabaseManager then
            PvPTooltip.DatabaseManager:ReloadDatabases()
        end
        
        collectgarbage("collect")
        local afterDbLoad = collectgarbage("count")
        local dbMemoryUsage = afterDbLoad - beforeDbLoad
        
        memoryBenchmarks.databaseMemory = dbMemoryUsage
        PvPTooltip:Debug(string.format("Database memory usage: %.2f KB", dbMemoryUsage))
        
        -- Benchmark tooltip rendering memory usage
        collectgarbage("collect")
        local beforeTooltips = collectgarbage("count")
        
        if PvPTooltip.TooltipRenderer then
            local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
            
            for i = 1, 100 do
                local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
                PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
            end
        end
        
        collectgarbage("collect")
        local afterTooltips = collectgarbage("count")
        local tooltipMemoryUsage = afterTooltips - beforeTooltips
        
        memoryBenchmarks.tooltipMemory = tooltipMemoryUsage
        PvPTooltip:Debug(string.format("Tooltip rendering memory usage: %.2f KB", tooltipMemoryUsage))
        
        -- Benchmark player lookup memory usage
        collectgarbage("collect")
        local beforeLookups = collectgarbage("count")
        
        if PvPTooltip.PlayerLookup then
            for i = 1, 100 do
                PvPTooltip.PlayerLookup:FindPlayerData("player")
            end
        end
        
        collectgarbage("collect")
        local afterLookups = collectgarbage("count")
        local lookupMemoryUsage = afterLookups - beforeLookups
        
        memoryBenchmarks.lookupMemory = lookupMemoryUsage
        PvPTooltip:Debug(string.format("Player lookup memory usage: %.2f KB", lookupMemoryUsage))
        
        -- Calculate total addon memory usage
        collectgarbage("collect")
        local currentMemory = collectgarbage("count")
        local totalAddonMemory = currentMemory - baselineMemory
        
        memoryBenchmarks.totalMemory = totalAddonMemory
        memoryBenchmarks.baselineMemory = baselineMemory
        memoryBenchmarks.currentMemory = currentMemory
        
        PvPTooltip:Debug(string.format("Total addon memory usage: %.2f KB", totalAddonMemory))
        
        -- Memory leak detection
        local memoryLeakTest = self:DetectMemoryLeaks()
        memoryBenchmarks.memoryLeakTest = memoryLeakTest
        
        -- Performance validation
        local performanceIssues = {}
        
        if totalAddonMemory > performanceThresholds.memoryUsage then
            table.insert(performanceIssues, string.format("High memory usage: %.2f KB > %d KB threshold", 
                totalAddonMemory, performanceThresholds.memoryUsage))
        end
        
        if memoryLeakTest.leakDetected then
            table.insert(performanceIssues, "Potential memory leak detected")
        end
        
        memoryBenchmarks.performanceIssues = performanceIssues
        benchmarkResults.memoryUsage = memoryBenchmarks
        
        -- Test passes if no critical memory issues
        local testPassed = #performanceIssues == 0
        if not testPassed then
            error("Memory usage issues: " .. table.concat(performanceIssues, "; "))
        end
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Detect memory leaks
function PerformanceBenchmarks:DetectMemoryLeaks()
    local leakTest = {
        leakDetected = false,
        memoryGrowth = 0,
        iterations = 50
    }
    
    -- Force garbage collection
    collectgarbage("collect")
    local startMemory = collectgarbage("count")
    
    -- Perform operations that should not cause memory leaks
    for i = 1, leakTest.iterations do
        if PvPTooltip.TooltipRenderer then
            local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
            local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
            PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
        end
        
        if PvPTooltip.PlayerLookup then
            PvPTooltip.PlayerLookup:FindPlayerData("player")
        end
        
        if PvPTooltip.DatabaseManager then
            PvPTooltip.DatabaseManager:GetPlayerData("TestPlayer", "test-realm", "eu")
        end
        
        -- Force garbage collection every 10 iterations
        if i % 10 == 0 then
            collectgarbage("collect")
        end
    end
    
    -- Final garbage collection
    collectgarbage("collect")
    local endMemory = collectgarbage("count")
    
    leakTest.memoryGrowth = endMemory - startMemory
    
    -- Consider it a leak if memory grew by more than 50KB after operations
    if leakTest.memoryGrowth > 50 then
        leakTest.leakDetected = true
    end
    
    PvPTooltip:Debug(string.format("Memory leak test: %.2f KB growth over %d iterations", 
        leakTest.memoryGrowth, leakTest.iterations))
    
    return leakTest
end

-- Benchmark cache performance
function PerformanceBenchmarks:BenchmarkCachePerformance()
    local testName = "Cache Performance"
    PvPTooltip:Debug("Benchmarking: " .. testName)
    
    local success, error = pcall(function()
        local cacheBenchmarks = {}
        
        -- Benchmark database cache performance
        if PvPTooltip.DatabaseManager then
            local cacheAccessTimes = {}
            
            -- Populate cache first
            for i = 1, 10 do
                PvPTooltip.DatabaseManager:GetPlayerData("TestPlayer" .. i, "test-realm", "eu")
            end
            
            -- Benchmark cache access
            for i = 1, 100 do
                local startTime = GetTime()
                PvPTooltip.DatabaseManager:GetPlayerData("TestPlayer1", "test-realm", "eu")
                local accessTime = (GetTime() - startTime) * 1000
                table.insert(cacheAccessTimes, accessTime)
            end
            
            local totalCacheTime = 0
            for _, time in ipairs(cacheAccessTimes) do
                totalCacheTime = totalCacheTime + time
            end
            
            local avgCacheTime = totalCacheTime / #cacheAccessTimes
            cacheBenchmarks.avgDatabaseCacheTime = avgCacheTime
            
            PvPTooltip:Debug(string.format("Average database cache access time: %.4fms", avgCacheTime))
        end
        
        -- Benchmark player lookup cache performance
        if PvPTooltip.PlayerLookup then
            local lookupCacheAccessTimes = {}
            
            -- Populate lookup cache
            for i = 1, 10 do
                local testKey = "testplayer" .. i .. "@test-realm"
                local testData = PvPTooltip.TestUtils.CreateMockPlayerData("TestPlayer" .. i)
                PvPTooltip.PlayerLookup:AddToCache(testKey, testData)
            end
            
            -- Benchmark lookup cache access
            for i = 1, 100 do
                local startTime = GetTime()
                PvPTooltip.PlayerLookup:GetFromCache("testplayer1@test-realm")
                local accessTime = (GetTime() - startTime) * 1000
                table.insert(lookupCacheAccessTimes, accessTime)
            end
            
            local totalLookupCacheTime = 0
            for _, time in ipairs(lookupCacheAccessTimes) do
                totalLookupCacheTime = totalLookupCacheTime + time
            end
            
            local avgLookupCacheTime = totalLookupCacheTime / #lookupCacheAccessTimes
            cacheBenchmarks.avgLookupCacheTime = avgLookupCacheTime
            
            PvPTooltip:Debug(string.format("Average lookup cache access time: %.4fms", avgLookupCacheTime))
            
            -- Clean up cache
            PvPTooltip.PlayerLookup:ClearCache()
        end
        
        -- Performance validation
        local performanceIssues = {}
        
        if cacheBenchmarks.avgDatabaseCacheTime and 
           cacheBenchmarks.avgDatabaseCacheTime > performanceThresholds.cacheAccess then
            table.insert(performanceIssues, string.format("Slow database cache access: %.4fms > %dms threshold", 
                cacheBenchmarks.avgDatabaseCacheTime, performanceThresholds.cacheAccess))
        end
        
        if cacheBenchmarks.avgLookupCacheTime and 
           cacheBenchmarks.avgLookupCacheTime > performanceThresholds.cacheAccess then
            table.insert(performanceIssues, string.format("Slow lookup cache access: %.4fms > %dms threshold", 
                cacheBenchmarks.avgLookupCacheTime, performanceThresholds.cacheAccess))
        end
        
        cacheBenchmarks.performanceIssues = performanceIssues
        benchmarkResults.cachePerformance = cacheBenchmarks
        
        -- Test passes if no critical performance issues
        local testPassed = #performanceIssues == 0
        if not testPassed then
            error("Cache performance issues: " .. table.concat(performanceIssues, "; "))
        end
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Benchmark initialization performance
function PerformanceBenchmarks:BenchmarkInitialization()
    local testName = "Initialization Performance"
    PvPTooltip:Debug("Benchmarking: " .. testName)
    
    local success, error = pcall(function()
        local initBenchmarks = {}
        
        -- Benchmark component initialization times
        local components = {
            "DatabaseManager",
            "PlayerLookup", 
            "TooltipRenderer",
            "ColorUtils",
            "RealmResolver"
        }
        
        for _, componentName in ipairs(components) do
            local component = PvPTooltip[componentName]
            if component and component.Initialize then
                local startTime = GetTime()
                component:Initialize()
                local initTime = (GetTime() - startTime) * 1000
                
                initBenchmarks[componentName] = initTime
                PvPTooltip:Debug(string.format("%s initialization time: %.2fms", componentName, initTime))
            end
        end
        
        -- Calculate total initialization time
        local totalInitTime = 0
        for _, time in pairs(initBenchmarks) do
            totalInitTime = totalInitTime + time
        end
        
        initBenchmarks.totalInitTime = totalInitTime
        PvPTooltip:Debug(string.format("Total initialization time: %.2fms", totalInitTime))
        
        -- Performance validation
        local performanceIssues = {}
        
        if totalInitTime > performanceThresholds.initialization then
            table.insert(performanceIssues, string.format("Slow initialization: %.2fms > %dms threshold", 
                totalInitTime, performanceThresholds.initialization))
        end
        
        initBenchmarks.performanceIssues = performanceIssues
        benchmarkResults.overallPerformance.initialization = initBenchmarks
        
        -- Test passes if no critical performance issues
        local testPassed = #performanceIssues == 0
        if not testPassed then
            error("Initialization performance issues: " .. table.concat(performanceIssues, "; "))
        end
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Benchmark validation performance
function PerformanceBenchmarks:BenchmarkValidationPerformance()
    local testName = "Validation Performance"
    PvPTooltip:Debug("Benchmarking: " .. testName)
    
    local success, error = pcall(function()
        local validationBenchmarks = {}
        
        -- Benchmark player data validation
        if PvPTooltip.TooltipRenderer and PvPTooltip.TooltipRenderer.ValidatePlayerData then
            local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
            local validationTimes = {}
            
            for i = 1, 1000 do
                local startTime = GetTime()
                PvPTooltip.TooltipRenderer:ValidatePlayerData(mockPlayerData)
                local validationTime = (GetTime() - startTime) * 1000
                table.insert(validationTimes, validationTime)
            end
            
            local totalValidationTime = 0
            for _, time in ipairs(validationTimes) do
                totalValidationTime = totalValidationTime + time
            end
            
            local avgValidationTime = totalValidationTime / #validationTimes
            validationBenchmarks.playerDataValidation = avgValidationTime
            
            PvPTooltip:Debug(string.format("Average player data validation time: %.4fms", avgValidationTime))
        end
        
        -- Benchmark unit info validation
        if PvPTooltip.PlayerLookup and PvPTooltip.PlayerLookup.ValidateUnitInfo then
            local mockUnitInfo = {name = "TestPlayer", realm = "test-realm"}
            local validationTimes = {}
            
            for i = 1, 1000 do
                local startTime = GetTime()
                PvPTooltip.PlayerLookup:ValidateUnitInfo(mockUnitInfo)
                local validationTime = (GetTime() - startTime) * 1000
                table.insert(validationTimes, validationTime)
            end
            
            local totalValidationTime = 0
            for _, time in ipairs(validationTimes) do
                totalValidationTime = totalValidationTime + time
            end
            
            local avgValidationTime = totalValidationTime / #validationTimes
            validationBenchmarks.unitInfoValidation = avgValidationTime
            
            PvPTooltip:Debug(string.format("Average unit info validation time: %.4fms", avgValidationTime))
        end
        
        benchmarkResults.overallPerformance.validation = validationBenchmarks
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Run stress tests
function PerformanceBenchmarks:RunStressTests()
    local testName = "Stress Tests"
    PvPTooltip:Debug("Running: " .. testName)
    
    local success, error = pcall(function()
        local stressResults = {}
        
        -- Stress test: Rapid tooltip rendering
        if PvPTooltip.TooltipRenderer then
            local mockPlayerData = PvPTooltip.TestUtils.CreateMockPlayerData()
            local stressCount = 500
            local startTime = GetTime()
            
            for i = 1, stressCount do
                local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
                PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockPlayerData)
            end
            
            local stressTime = (GetTime() - startTime) * 1000
            stressResults.rapidTooltipRendering = {
                count = stressCount,
                totalTime = stressTime,
                avgTime = stressTime / stressCount
            }
            
            PvPTooltip:Debug(string.format("Stress test - %d tooltip renders in %.2fms (avg: %.2fms)", 
                stressCount, stressTime, stressTime / stressCount))
        end
        
        -- Stress test: Rapid database lookups
        if PvPTooltip.DatabaseManager then
            local stressCount = 1000
            local startTime = GetTime()
            
            for i = 1, stressCount do
                PvPTooltip.DatabaseManager:GetPlayerData("StressTest" .. (i % 100), "test-realm", "eu")
            end
            
            local stressTime = (GetTime() - startTime) * 1000
            stressResults.rapidDatabaseLookups = {
                count = stressCount,
                totalTime = stressTime,
                avgTime = stressTime / stressCount
            }
            
            PvPTooltip:Debug(string.format("Stress test - %d database lookups in %.2fms (avg: %.2fms)", 
                stressCount, stressTime, stressTime / stressCount))
        end
        
        -- Memory stress test
        collectgarbage("collect")
        local beforeStress = collectgarbage("count")
        
        -- Create and destroy many objects
        for i = 1, 100 do
            local tempData = {}
            for j = 1, 100 do
                tempData[j] = PvPTooltip.TestUtils.CreateMockPlayerData("StressPlayer" .. j)
            end
            tempData = nil
        end
        
        collectgarbage("collect")
        local afterStress = collectgarbage("count")
        
        stressResults.memoryStress = {
            memoryGrowth = afterStress - beforeStress
        }
        
        PvPTooltip:Debug(string.format("Memory stress test - growth: %.2f KB", afterStress - beforeStress))
        
        benchmarkResults.overallPerformance.stressTests = stressResults
    end)
    
    self:RecordTestResult(testName, success, error)
end

-- Generate performance report
function PerformanceBenchmarks:GeneratePerformanceReport()
    PvPTooltip:Print("=== Performance Benchmark Report ===")
    
    -- Database performance
    if benchmarkResults.databasePerformance then
        local db = benchmarkResults.databasePerformance
        PvPTooltip:Print("Database Performance:")
        PvPTooltip:Print(string.format("  Load Time: %.2fms", db.loadTime or 0))
        PvPTooltip:Print(string.format("  Avg Lookup Time: %.2fms", db.avgLookupTime or 0))
        PvPTooltip:Print(string.format("  Avg Normalization Time: %.4fms", db.avgNormalizationTime or 0))
    end
    
    -- Tooltip performance
    if benchmarkResults.tooltipPerformance then
        local tooltip = benchmarkResults.tooltipPerformance
        PvPTooltip:Print("Tooltip Performance:")
        PvPTooltip:Print(string.format("  Avg Render Time: %.2fms", tooltip.avgRenderTime or 0))
        PvPTooltip:Print(string.format("  Avg Validation Time: %.4fms", tooltip.avgValidationTime or 0))
    end
    
    -- Memory usage
    if benchmarkResults.memoryUsage then
        local memory = benchmarkResults.memoryUsage
        PvPTooltip:Print("Memory Usage:")
        PvPTooltip:Print(string.format("  Total Addon Memory: %.2f KB", memory.totalMemory or 0))
        PvPTooltip:Print(string.format("  Database Memory: %.2f KB", memory.databaseMemory or 0))
        PvPTooltip:Print(string.format("  Tooltip Memory: %.2f KB", memory.tooltipMemory or 0))
        
        if memory.memoryLeakTest then
            local leak = memory.memoryLeakTest
            PvPTooltip:Print(string.format("  Memory Leak Test: %s (%.2f KB growth)", 
                leak.leakDetected and "FAILED" or "PASSED", leak.memoryGrowth))
        end
    end
    
    -- Overall performance status
    local allIssues = {}
    for category, results in pairs(benchmarkResults) do
        if results.performanceIssues then
            for _, issue in ipairs(results.performanceIssues) do
                table.insert(allIssues, category .. ": " .. issue)
            end
        end
    end
    
    if #allIssues == 0 then
        PvPTooltip:Print("|cFF00FF00All performance benchmarks passed!|r")
    else
        PvPTooltip:Print("|cFFFFFF00Performance Issues Found:|r")
        for _, issue in ipairs(allIssues) do
            PvPTooltip:Print("  " .. issue)
        end
    end
end

-- Record test result
function PerformanceBenchmarks:RecordTestResult(testName, success, error)
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
function PerformanceBenchmarks:GetTestResults()
    return testResults
end

-- Get benchmark results
function PerformanceBenchmarks:GetBenchmarkResults()
    return benchmarkResults
end

-- Set performance thresholds
function PerformanceBenchmarks:SetPerformanceThresholds(thresholds)
    if type(thresholds) == "table" then
        for key, value in pairs(thresholds) do
            performanceThresholds[key] = value
        end
        PvPTooltip:Debug("Performance thresholds updated")
    end
end

-- Get performance thresholds
function PerformanceBenchmarks:GetPerformanceThresholds()
    return performanceThresholds
end

-- Quick performance test
function PerformanceBenchmarks:QuickTest()
    PvPTooltip:Print("=== Quick Performance Test ===")
    
    local tests = {
        {
            name = "Database lookup performance",
            test = function()
                if not PvPTooltip.DatabaseManager then return false end
                local startTime = GetTime()
                PvPTooltip.DatabaseManager:GetPlayerData("TestPlayer", "test-realm", "eu")
                local lookupTime = (GetTime() - startTime) * 1000
                return lookupTime < performanceThresholds.databaseLookup
            end
        },
        {
            name = "Tooltip render performance",
            test = function()
                if not PvPTooltip.TooltipRenderer then return false end
                local mockTooltip = PvPTooltip.TestUtils.CreateMockTooltip()
                local mockData = PvPTooltip.TestUtils.CreateMockPlayerData()
                local startTime = GetTime()
                PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, mockData)
                local renderTime = (GetTime() - startTime) * 1000
                return renderTime < performanceThresholds.tooltipRender
            end
        },
        {
            name = "Memory usage reasonable",
            test = function()
                collectgarbage("collect")
                local memory = collectgarbage("count")
                return memory < performanceThresholds.memoryUsage * 2 -- Allow 2x threshold for quick test
            end
        },
        {
            name = "Cache access performance",
            test = function()
                if not PvPTooltip.PlayerLookup then return false end
                local testKey = "quicktest@test-realm"
                local testData = {name = "QuickTest"}
                PvPTooltip.PlayerLookup:AddToCache(testKey, testData)
                
                local startTime = GetTime()
                PvPTooltip.PlayerLookup:GetFromCache(testKey)
                local cacheTime = (GetTime() - startTime) * 1000
                
                PvPTooltip.PlayerLookup:ClearCache()
                return cacheTime < performanceThresholds.cacheAccess
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
    
    PvPTooltip:Print(string.format("Quick performance test: %d/%d passed", passed, #tests))
    return passed == #tests
end