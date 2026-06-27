-- PvPTooltip Performance Monitor
-- Centralized performance monitoring and optimization management

local PerformanceMonitor = {}
PvPTooltip.PerformanceMonitor = PerformanceMonitor

-- Performance metrics storage
local performanceData = {
    startTime = GetTime(),
    tooltipMetrics = {
        totalRequests = 0,
        successfulRequests = 0,
        failedRequests = 0,
        throttledRequests = 0,
        averageResponseTime = 0,
        slowQueries = 0
    },
    databaseMetrics = {
        totalLookups = 0,
        cacheHits = 0,
        cacheMisses = 0,
        averageLookupTime = 0,
        slowLookups = 0,
        memoryCleanups = 0
    },
    memoryMetrics = {
        peakUsage = 0,
        currentUsage = 0,
        cleanupTriggers = 0,
        compressionSavings = 0
    },
    systemMetrics = {
        frameRate = 0,
        lastFrameRateCheck = 0,
        memoryPressure = false,
        throttlingActive = false
    }
}

-- Performance thresholds and settings
local performanceThresholds = {
    slowTooltipMs = 100,
    slowLookupMs = 50,
    maxTooltipsPerSecond = 10,
    memoryPressureThreshold = 50 * 1024 * 1024, -- 50MB
    frameRateThreshold = 30
}

-- Initialize the performance monitor
function PerformanceMonitor:Initialize()
    PvPTooltip:Debug("PerformanceMonitor initializing...")
    
    -- Load performance settings from config
    self:LoadPerformanceSettings()
    
    -- Set up periodic monitoring
    self:SetupPeriodicMonitoring()
    
    PvPTooltip:Debug("PerformanceMonitor initialized")
end

-- Load performance settings from configuration
function PerformanceMonitor:LoadPerformanceSettings()
    if not PvPTooltip.Config or not PvPTooltip.Config.Performance then
        PvPTooltip:Debug("No performance configuration found, using defaults")
        return
    end
    
    local config = PvPTooltip.Config.Performance
    
    -- Update thresholds from config
    performanceThresholds.slowTooltipMs = config.slowQueryThreshold or performanceThresholds.slowTooltipMs
    performanceThresholds.maxTooltipsPerSecond = config.tooltipSpamThreshold or performanceThresholds.maxTooltipsPerSecond
    
    PvPTooltip:Debug("Performance settings loaded from configuration")
end

-- Set up periodic performance monitoring
function PerformanceMonitor:SetupPeriodicMonitoring()
    if not PvPTooltip.Config or not PvPTooltip.Config.Performance or 
       not PvPTooltip.Config.Performance.enablePerformanceMetrics then
        PvPTooltip:Debug("Performance monitoring disabled")
        return
    end
    
    -- Monitor every 30 seconds
    local function monitoringTimer()
        self:CollectSystemMetrics()
        self:CheckPerformanceThresholds()
        C_Timer.NewTimer(30, monitoringTimer)
    end
    
    -- Start monitoring
    C_Timer.NewTimer(30, monitoringTimer)
    PvPTooltip:Debug("Periodic performance monitoring started")
end

-- Collect system performance metrics
function PerformanceMonitor:CollectSystemMetrics()
    local currentTime = GetTime()
    
    -- Collect frame rate
    if currentTime - performanceData.systemMetrics.lastFrameRateCheck >= 5 then
        performanceData.systemMetrics.frameRate = GetFramerate()
        performanceData.systemMetrics.lastFrameRateCheck = currentTime
    end
    
    -- Collect memory usage (if available)
    if collectgarbage then
        local memoryKB = collectgarbage("count")
        performanceData.memoryMetrics.currentUsage = memoryKB * 1024 -- Convert to bytes
        
        if performanceData.memoryMetrics.currentUsage > performanceData.memoryMetrics.peakUsage then
            performanceData.memoryMetrics.peakUsage = performanceData.memoryMetrics.currentUsage
        end
        
        -- Check for memory pressure
        performanceData.systemMetrics.memoryPressure = 
            performanceData.memoryMetrics.currentUsage > performanceThresholds.memoryPressureThreshold
    end
end

-- Check performance thresholds and trigger optimizations
function PerformanceMonitor:CheckPerformanceThresholds()
    local issues = {}
    
    -- Check frame rate
    if performanceData.systemMetrics.frameRate > 0 and 
       performanceData.systemMetrics.frameRate < performanceThresholds.frameRateThreshold then
        table.insert(issues, "Low frame rate: " .. performanceData.systemMetrics.frameRate .. " FPS")
    end
    
    -- Check memory pressure
    if performanceData.systemMetrics.memoryPressure then
        table.insert(issues, "Memory pressure detected")
        self:TriggerMemoryOptimization()
    end
    
    -- Check tooltip performance
    local tooltipSuccessRate = self:GetTooltipSuccessRate()
    if tooltipSuccessRate < 90 then
        table.insert(issues, "Low tooltip success rate: " .. string.format("%.1f%%", tooltipSuccessRate))
    end
    
    -- Log issues if any
    if #issues > 0 then
        PvPTooltip:Debug("Performance issues detected: " .. table.concat(issues, ", "))
    end
end

-- Trigger memory optimization
function PerformanceMonitor:TriggerMemoryOptimization()
    performanceData.memoryMetrics.cleanupTriggers = performanceData.memoryMetrics.cleanupTriggers + 1
    
    -- Trigger database cache cleanup
    if PvPTooltip.DatabaseManager and PvPTooltip.DatabaseManager.PerformMemoryCleanup then
        PvPTooltip.DatabaseManager:PerformMemoryCleanup()
    end
    
    -- Force garbage collection
    if collectgarbage then
        collectgarbage("collect")
    end
    
    PvPTooltip:Debug("Memory optimization triggered")
end

-- Record tooltip performance metrics
function PerformanceMonitor:RecordTooltipMetrics(success, responseTime, wasThrottled)
    local metrics = performanceData.tooltipMetrics
    
    metrics.totalRequests = metrics.totalRequests + 1
    
    if success then
        metrics.successfulRequests = metrics.successfulRequests + 1
        
        -- Update average response time
        local totalSuccessful = metrics.successfulRequests
        metrics.averageResponseTime = 
            ((metrics.averageResponseTime * (totalSuccessful - 1)) + responseTime) / totalSuccessful
        
        -- Check for slow queries
        if responseTime > performanceThresholds.slowTooltipMs then
            metrics.slowQueries = metrics.slowQueries + 1
        end
    else
        metrics.failedRequests = metrics.failedRequests + 1
    end
    
    if wasThrottled then
        metrics.throttledRequests = metrics.throttledRequests + 1
    end
end

-- Record database lookup metrics
function PerformanceMonitor:RecordDatabaseMetrics(lookupTime, cacheHit)
    local metrics = performanceData.databaseMetrics
    
    metrics.totalLookups = metrics.totalLookups + 1
    
    if cacheHit then
        metrics.cacheHits = metrics.cacheHits + 1
    else
        metrics.cacheMisses = metrics.cacheMisses + 1
        
        -- Update average lookup time (only for cache misses)
        local totalMisses = metrics.cacheMisses
        metrics.averageLookupTime = 
            ((metrics.averageLookupTime * (totalMisses - 1)) + lookupTime) / totalMisses
        
        -- Check for slow lookups
        if lookupTime > performanceThresholds.slowLookupMs then
            metrics.slowLookups = metrics.slowLookups + 1
        end
    end
end

-- Get tooltip success rate
function PerformanceMonitor:GetTooltipSuccessRate()
    local metrics = performanceData.tooltipMetrics
    if metrics.totalRequests == 0 then
        return 100
    end
    
    return (metrics.successfulRequests / metrics.totalRequests) * 100
end

-- Get cache hit rate
function PerformanceMonitor:GetCacheHitRate()
    local metrics = performanceData.databaseMetrics
    if metrics.totalLookups == 0 then
        return 0
    end
    
    return (metrics.cacheHits / metrics.totalLookups) * 100
end

-- Get comprehensive performance report
function PerformanceMonitor:GetPerformanceReport()
    local uptime = GetTime() - performanceData.startTime
    
    return {
        uptime = uptime,
        tooltip = {
            totalRequests = performanceData.tooltipMetrics.totalRequests,
            successRate = self:GetTooltipSuccessRate(),
            averageResponseTime = performanceData.tooltipMetrics.averageResponseTime,
            requestsPerSecond = uptime > 0 and (performanceData.tooltipMetrics.totalRequests / uptime) or 0,
            slowQueries = performanceData.tooltipMetrics.slowQueries,
            throttledRequests = performanceData.tooltipMetrics.throttledRequests
        },
        database = {
            totalLookups = performanceData.databaseMetrics.totalLookups,
            cacheHitRate = self:GetCacheHitRate(),
            averageLookupTime = performanceData.databaseMetrics.averageLookupTime,
            slowLookups = performanceData.databaseMetrics.slowLookups,
            memoryCleanups = performanceData.databaseMetrics.memoryCleanups
        },
        memory = {
            currentUsage = performanceData.memoryMetrics.currentUsage,
            peakUsage = performanceData.memoryMetrics.peakUsage,
            cleanupTriggers = performanceData.memoryMetrics.cleanupTriggers,
            compressionSavings = performanceData.memoryMetrics.compressionSavings
        },
        system = {
            frameRate = performanceData.systemMetrics.frameRate,
            memoryPressure = performanceData.systemMetrics.memoryPressure,
            throttlingActive = performanceData.systemMetrics.throttlingActive
        }
    }
end

-- Reset all performance metrics
function PerformanceMonitor:ResetMetrics()
    performanceData = {
        startTime = GetTime(),
        tooltipMetrics = {
            totalRequests = 0,
            successfulRequests = 0,
            failedRequests = 0,
            throttledRequests = 0,
            averageResponseTime = 0,
            slowQueries = 0
        },
        databaseMetrics = {
            totalLookups = 0,
            cacheHits = 0,
            cacheMisses = 0,
            averageLookupTime = 0,
            slowLookups = 0,
            memoryCleanups = 0
        },
        memoryMetrics = {
            peakUsage = 0,
            currentUsage = 0,
            cleanupTriggers = 0,
            compressionSavings = 0
        },
        systemMetrics = {
            frameRate = 0,
            lastFrameRateCheck = 0,
            memoryPressure = false,
            throttlingActive = false
        }
    }
    
    PvPTooltip:Debug("Performance metrics reset")
end

-- Get performance optimization recommendations
function PerformanceMonitor:GetOptimizationRecommendations()
    local recommendations = {}
    local report = self:GetPerformanceReport()
    
    -- Tooltip performance recommendations
    if report.tooltip.successRate < 95 then
        table.insert(recommendations, "Consider increasing tooltip debounce time to improve success rate")
    end
    
    if report.tooltip.averageResponseTime > performanceThresholds.slowTooltipMs then
        table.insert(recommendations, "Tooltip response time is slow - consider optimizing data lookup")
    end
    
    if report.tooltip.throttledRequests > (report.tooltip.totalRequests * 0.1) then
        table.insert(recommendations, "High throttling rate - consider adjusting spam threshold")
    end
    
    -- Database performance recommendations
    if report.database.cacheHitRate < 80 then
        table.insert(recommendations, "Low cache hit rate - consider increasing cache size or retention time")
    end
    
    if report.database.averageLookupTime > performanceThresholds.slowLookupMs then
        table.insert(recommendations, "Database lookups are slow - consider optimizing data structure")
    end
    
    -- Memory recommendations
    if report.memory.cleanupTriggers > 10 then
        table.insert(recommendations, "Frequent memory cleanups - consider reducing cache size")
    end
    
    if report.system.memoryPressure then
        table.insert(recommendations, "Memory pressure detected - enable data compression or reduce cache size")
    end
    
    -- System recommendations
    if report.system.frameRate > 0 and report.system.frameRate < performanceThresholds.frameRateThreshold then
        table.insert(recommendations, "Low frame rate - consider reducing tooltip update frequency")
    end
    
    return recommendations
end

-- Enable/disable performance monitoring
function PerformanceMonitor:SetMonitoringEnabled(enabled)
    if enabled then
        self:SetupPeriodicMonitoring()
        PvPTooltip:Debug("Performance monitoring enabled")
    else
        -- Note: We can't easily disable the timer once started, but we can skip processing
        PvPTooltip:Debug("Performance monitoring disabled")
    end
end

-- Get current performance status
function PerformanceMonitor:GetPerformanceStatus()
    local report = self:GetPerformanceReport()
    
    local status = "Good"
    local issues = {}
    
    -- Check various metrics
    if report.tooltip.successRate < 90 then
        status = "Poor"
        table.insert(issues, "Low tooltip success rate")
    elseif report.tooltip.successRate < 95 then
        status = "Fair"
        table.insert(issues, "Moderate tooltip success rate")
    end
    
    if report.database.cacheHitRate < 70 then
        status = "Poor"
        table.insert(issues, "Low cache hit rate")
    elseif report.database.cacheHitRate < 85 then
        if status == "Good" then status = "Fair" end
        table.insert(issues, "Moderate cache hit rate")
    end
    
    if report.system.memoryPressure then
        status = "Poor"
        table.insert(issues, "Memory pressure")
    end
    
    if report.system.frameRate > 0 and report.system.frameRate < performanceThresholds.frameRateThreshold then
        status = "Poor"
        table.insert(issues, "Low frame rate")
    end
    
    return {
        status = status,
        issues = issues,
        uptime = report.uptime,
        recommendations = #issues > 0 and self:GetOptimizationRecommendations() or {}
    }
end

-- Return the module for proper loading
return PerformanceMonitor