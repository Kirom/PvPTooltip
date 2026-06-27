-- PvPTooltip Performance Tests
-- Tests for performance optimization features

local PerformanceTests = {}
PvPTooltip.PerformanceTests = PerformanceTests

-- Test tooltip debouncing and spam protection
function PerformanceTests:TestTooltipDebouncing()
    PvPTooltip:Print("=== Testing Tooltip Debouncing ===")
    
    if not PvPTooltip.EventManager then
        PvPTooltip:Print("EventManager not available")
        return false
    end
    
    -- Reset performance metrics
    if PvPTooltip.EventManager.ResetPerformanceMetrics then
        PvPTooltip.EventManager:ResetPerformanceMetrics()
    end
    
    -- Simulate rapid tooltip requests
    local mockTooltip = {
        IsShown = function() return true end,
        GetUnit = function() return "TestPlayer", "player" end,
        AddLine = function() end
    }
    
    PvPTooltip:Print("Simulating 10 rapid tooltip requests...")
    
    for i = 1, 10 do
        if PvPTooltip.EventManager.OnTooltipSetUnit then
            PvPTooltip.EventManager:OnTooltipSetUnit(mockTooltip)
        end
    end
    
    -- Check throttling status
    if PvPTooltip.EventManager.GetThrottlingStatus then
        local status = PvPTooltip.EventManager:GetThrottlingStatus()
        PvPTooltip:Print("Throttling Status:")
        PvPTooltip:Print("  Is Throttled: " .. tostring(status.isThrottled))
        PvPTooltip:Print("  Update Count: " .. status.currentUpdateCount)
        
        if status.isThrottled then
            PvPTooltip:Print("  Time Until Reset: " .. string.format("%.1fs", status.timeUntilThrottleEnd))
        end
    end
    
    -- Get performance metrics
    if PvPTooltip.EventManager.GetPerformanceMetrics then
        local metrics = PvPTooltip.EventManager:GetPerformanceMetrics()
        PvPTooltip:Print("Performance Metrics:")
        PvPTooltip:Print("  Total Requests: " .. metrics.totalRequests)
        PvPTooltip:Print("  Throttled Requests: " .. metrics.throttledRequests)
        PvPTooltip:Print("  Success Rate: " .. string.format("%.1f%%", metrics.successRate))
    end
    
    PvPTooltip:Print("Tooltip debouncing test completed")
    return true
end

-- Test database lookup cache performance
function PerformanceTests:TestLookupCache()
    PvPTooltip:Print("=== Testing Database Lookup Cache ===")
    
    if not PvPTooltip.DatabaseManager then
        PvPTooltip:Print("DatabaseManager not available")
        return false
    end
    
    -- Clear caches for clean test
    if PvPTooltip.DatabaseManager.ClearAllCaches then
        PvPTooltip.DatabaseManager:ClearAllCaches()
    end
    
    -- Test multiple lookups of the same player
    local testPlayer = "TestPlayer"
    local testRealm = "test-realm"
    local testRegion = "eu"
    
    PvPTooltip:Print("Performing 5 lookups for the same player...")
    
    local startTime = GetTime()
    
    for i = 1, 5 do
        local result = PvPTooltip.DatabaseManager:GetPlayerData(testPlayer, testRealm, testRegion)
        PvPTooltip:Print("  Lookup " .. i .. ": " .. (result and "Found" or "Not Found"))
    end
    
    local totalTime = (GetTime() - startTime) * 1000
    PvPTooltip:Print("Total lookup time: " .. string.format("%.2fms", totalTime))
    
    -- Get memory statistics
    if PvPTooltip.DatabaseManager.GetMemoryStats then
        local stats = PvPTooltip.DatabaseManager:GetMemoryStats()
        PvPTooltip:Print("Cache Statistics:")
        PvPTooltip:Print("  Lookup Cache Size: " .. stats.lookupCacheSize)
        PvPTooltip:Print("  Cache Hit Rate: " .. string.format("%.1f%%", stats.lookupCacheHitRate))
        PvPTooltip:Print("  Total Cache Entries: " .. stats.cacheStats.totalEntries)
    end
    
    PvPTooltip:Print("Database lookup cache test completed")
    return true
end

-- Test memory management
function PerformanceTests:TestMemoryManagement()
    PvPTooltip:Print("=== Testing Memory Management ===")
    
    if not PvPTooltip.DatabaseManager then
        PvPTooltip:Print("DatabaseManager not available")
        return false
    end
    
    -- Get initial memory stats
    local initialStats = nil
    if PvPTooltip.DatabaseManager.GetMemoryStats then
        initialStats = PvPTooltip.DatabaseManager:GetMemoryStats()
        PvPTooltip:Print("Initial Memory Stats:")
        PvPTooltip:Print("  Cache Entries: " .. initialStats.cacheStats.totalEntries)
        PvPTooltip:Print("  Memory Cleanups: " .. initialStats.cacheStats.memoryCleanups)
    end
    
    -- Trigger memory cleanup
    if PvPTooltip.DatabaseManager.PerformMemoryCleanup then
        PvPTooltip:Print("Triggering memory cleanup...")
        PvPTooltip.DatabaseManager:PerformMemoryCleanup()
    end
    
    -- Get post-cleanup stats
    if PvPTooltip.DatabaseManager.GetMemoryStats then
        local postStats = PvPTooltip.DatabaseManager:GetMemoryStats()
        PvPTooltip:Print("Post-Cleanup Memory Stats:")
        PvPTooltip:Print("  Cache Entries: " .. postStats.cacheStats.totalEntries)
        PvPTooltip:Print("  Memory Cleanups: " .. postStats.cacheStats.memoryCleanups)
        
        if initialStats then
            local entriesRemoved = initialStats.cacheStats.totalEntries - postStats.cacheStats.totalEntries
            PvPTooltip:Print("  Entries Removed: " .. entriesRemoved)
        end
    end
    
    PvPTooltip:Print("Memory management test completed")
    return true
end

-- Test performance monitoring
function PerformanceTests:TestPerformanceMonitoring()
    PvPTooltip:Print("=== Testing Performance Monitoring ===")
    
    if not PvPTooltip.PerformanceMonitor then
        PvPTooltip:Print("PerformanceMonitor not available")
        return false
    end
    
    -- Reset metrics for clean test
    if PvPTooltip.PerformanceMonitor.ResetMetrics then
        PvPTooltip.PerformanceMonitor:ResetMetrics()
    end
    
    -- Simulate some performance data
    if PvPTooltip.PerformanceMonitor.RecordTooltipMetrics then
        PvPTooltip:Print("Recording test performance metrics...")
        
        -- Record some successful operations
        for i = 1, 5 do
            PvPTooltip.PerformanceMonitor:RecordTooltipMetrics(true, 25 + (i * 5), false)
        end
        
        -- Record some failed operations
        for i = 1, 2 do
            PvPTooltip.PerformanceMonitor:RecordTooltipMetrics(false, 0, false)
        end
        
        -- Record some throttled operations
        PvPTooltip.PerformanceMonitor:RecordTooltipMetrics(true, 30, true)
    end
    
    -- Get performance report
    if PvPTooltip.PerformanceMonitor.GetPerformanceReport then
        local report = PvPTooltip.PerformanceMonitor:GetPerformanceReport()
        PvPTooltip:Print("Performance Report:")
        PvPTooltip:Print("  Total Requests: " .. report.tooltip.totalRequests)
        PvPTooltip:Print("  Success Rate: " .. string.format("%.1f%%", report.tooltip.successRate))
        PvPTooltip:Print("  Average Response Time: " .. string.format("%.1fms", report.tooltip.averageResponseTime))
        PvPTooltip:Print("  Throttled Requests: " .. report.tooltip.throttledRequests)
    end
    
    -- Get performance status
    if PvPTooltip.PerformanceMonitor.GetPerformanceStatus then
        local status = PvPTooltip.PerformanceMonitor:GetPerformanceStatus()
        PvPTooltip:Print("Performance Status: " .. status.status)
        
        if #status.issues > 0 then
            PvPTooltip:Print("Issues: " .. table.concat(status.issues, ", "))
        end
    end
    
    PvPTooltip:Print("Performance monitoring test completed")
    return true
end

-- Run all performance tests
function PerformanceTests:RunAllTests()
    PvPTooltip:Print("=== Running All Performance Tests ===")
    
    local tests = {
        {name = "Tooltip Debouncing", func = self.TestTooltipDebouncing},
        {name = "Lookup Cache", func = self.TestLookupCache},
        {name = "Memory Management", func = self.TestMemoryManagement},
        {name = "Performance Monitoring", func = self.TestPerformanceMonitoring}
    }
    
    local passed = 0
    local total = #tests
    
    for _, test in ipairs(tests) do
        PvPTooltip:Print("Running test: " .. test.name)
        local success, result = pcall(test.func, self)
        
        if success and result then
            passed = passed + 1
            PvPTooltip:Print("✓ " .. test.name .. " - PASSED")
        else
            PvPTooltip:Print("✗ " .. test.name .. " - FAILED" .. (result and "" or " (error: " .. tostring(result) .. ")"))
        end
        
        PvPTooltip:Print("") -- Empty line for readability
    end
    
    PvPTooltip:Print("=== Performance Test Results ===")
    PvPTooltip:Print("Passed: " .. passed .. "/" .. total)
    
    if passed == total then
        PvPTooltip:Print("All performance tests passed!")
    else
        PvPTooltip:Print("Some performance tests failed. Check the output above for details.")
    end
    
    return passed == total
end

-- Quick performance test
function PerformanceTests:QuickTest()
    PvPTooltip:Print("=== Quick Performance Test ===")
    
    -- Test basic functionality
    local hasEventManager = PvPTooltip.EventManager ~= nil
    local hasDatabaseManager = PvPTooltip.DatabaseManager ~= nil
    local hasPerformanceMonitor = PvPTooltip.PerformanceMonitor ~= nil
    
    PvPTooltip:Print("Component Status:")
    PvPTooltip:Print("  EventManager: " .. (hasEventManager and "✓" or "✗"))
    PvPTooltip:Print("  DatabaseManager: " .. (hasDatabaseManager and "✓" or "✗"))
    PvPTooltip:Print("  PerformanceMonitor: " .. (hasPerformanceMonitor and "✓" or "✗"))
    
    -- Test performance monitoring if available
    if hasPerformanceMonitor and PvPTooltip.PerformanceMonitor.GetPerformanceStatus then
        local status = PvPTooltip.PerformanceMonitor:GetPerformanceStatus()
        PvPTooltip:Print("Performance Status: " .. status.status)
    end
    
    -- Test throttling status if available
    if hasEventManager and PvPTooltip.EventManager.GetThrottlingStatus then
        local throttling = PvPTooltip.EventManager:GetThrottlingStatus()
        PvPTooltip:Print("Throttling Active: " .. tostring(throttling.isThrottled))
    end
    
    PvPTooltip:Print("Quick performance test completed")
end


-- Return the module for proper loading
return PerformanceTests