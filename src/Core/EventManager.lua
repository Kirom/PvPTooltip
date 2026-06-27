-- PvPTooltip Event Manager
-- Handles WoW event registration and tooltip interception

local EventManager = {}
PvPTooltip.EventManager = EventManager

-- Event frame for tooltip events
local tooltipEventFrame = nil
local eventsRegistered = false

-- Tooltip update debouncing and spam protection
local lastTooltipUpdate = 0
local tooltipUpdateTimer = nil
local tooltipUpdateCount = 0
local tooltipUpdateWindow = 0
local isThrottled = false
local throttleEndTime = 0

-- Performance metrics
local performanceMetrics = {
    totalTooltipRequests = 0,
    throttledRequests = 0,
    successfulUpdates = 0,
    failedUpdates = 0,
    averageProcessingTime = 0,
    lastResetTime = GetTime()
}

-- Initialize the event manager
function EventManager:Initialize()
    PvPTooltip:Debug("EventManager initializing...")
    
    -- Create event frame if it doesn't exist
    if not tooltipEventFrame then
        tooltipEventFrame = CreateFrame("Frame", "PvPTooltipEventFrame")
    end
    
    -- Register tooltip events if addon is enabled
    if PvPTooltip:IsReady() then
        self:RegisterTooltipEvents()
    end
    
    PvPTooltip:Debug("EventManager initialized")
end

-- Register tooltip-related events
function EventManager:RegisterTooltipEvents()
    if eventsRegistered then
        return
    end
    
    PvPTooltip:Debug("Registering tooltip events...")

    -- Preferred: modern tooltip data API (retail 10.0.2+, incl. Midnight).
    -- Blizzard calls this once per unit tooltip, only after unit data is set,
    -- so no OnShow firing on item/spell tooltips and no timing race.
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
        and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
            if tooltip == GameTooltip then
                EventManager:OnUnitTooltip(tooltip)
            end
        end)
        PvPTooltip:Debug("Registered via TooltipDataProcessor (modern API)")
    elseif GameTooltip then
        -- Legacy fallback (pre-10.0.2): hook OnShow and filter to unit tooltips.
        GameTooltip:HookScript("OnShow", function(tooltip)
            self:OnTooltipSetUnit(tooltip)
        end)
        GameTooltip:HookScript("OnHide", function(tooltip)
            self:OnTooltipHide(tooltip)
        end)
        PvPTooltip:Debug("Registered via OnShow hook (legacy fallback)")
    end

    eventsRegistered = true
    PvPTooltip:Debug("Tooltip events registered")
end

-- Modern path: a unit tooltip's data was set. Tooltips rebuild their lines on
-- each SetUnit, so we can enhance directly without the legacy throttling.
function EventManager:OnUnitTooltip(tooltip)
    if not tooltip then
        return
    end
    local ok, isReady = pcall(function()
        return PvPTooltip and PvPTooltip.IsReady and PvPTooltip:IsReady()
    end)
    if not ok or not isReady then
        return
    end
    self:ProcessTooltipUpdate(tooltip, GetTime())
end

-- Unregister tooltip events
function EventManager:UnregisterTooltipEvents()
    if not eventsRegistered then
        return
    end
    
    PvPTooltip:Debug("Unregistering tooltip events...")
    
    -- Cancel any pending tooltip updates
    if tooltipUpdateTimer then
        tooltipUpdateTimer:Cancel()
        tooltipUpdateTimer = nil
    end
    
    eventsRegistered = false
    PvPTooltip:Debug("Tooltip events unregistered")
end

-- Handle tooltip set unit event with advanced debouncing and spam protection
function EventManager:OnTooltipSetUnit(tooltip)
    local startTime = GetTime()
    performanceMetrics.totalTooltipRequests = performanceMetrics.totalTooltipRequests + 1
    
    -- Protect against addon state errors without breaking tooltips
    local success, isReady = pcall(function()
        return PvPTooltip and PvPTooltip.IsReady and PvPTooltip:IsReady()
    end)
    
    if not success or not isReady then
        -- Graceful degradation - don't process tooltip but don't break it either
        return
    end
    
    -- Check if we're currently throttled
    local currentTime = GetTime()
    if isThrottled and currentTime < throttleEndTime then
        performanceMetrics.throttledRequests = performanceMetrics.throttledRequests + 1
        PvPTooltip:Debug("Tooltip update throttled - too many requests")
        return
    elseif isThrottled and currentTime >= throttleEndTime then
        -- Reset throttling
        isThrottled = false
        tooltipUpdateCount = 0
        tooltipUpdateWindow = currentTime
        PvPTooltip:Debug("Tooltip throttling reset")
    end
    
    -- Protect against timing and configuration errors
    local success, _ = pcall(function()
        -- Get performance settings with fallbacks
        local debounceMs = 50 -- Safe fallback
        local spamThreshold = 5 -- Safe fallback
        
        if PvPTooltip.Config and PvPTooltip.Config.Performance then
            debounceMs = PvPTooltip.Config.Performance.tooltipDebounceMs or debounceMs
            spamThreshold = PvPTooltip.Config.Performance.tooltipSpamThreshold or spamThreshold
        end
        
        -- Advanced spam protection - track requests per second
        if currentTime - tooltipUpdateWindow >= 1.0 then
            -- Reset window
            tooltipUpdateWindow = currentTime
            tooltipUpdateCount = 0
        end
        
        tooltipUpdateCount = tooltipUpdateCount + 1
        
        -- Check if we're exceeding spam threshold
        if tooltipUpdateCount > spamThreshold then
            -- Enable throttling for 2 seconds
            isThrottled = true
            throttleEndTime = currentTime + 2.0
            performanceMetrics.throttledRequests = performanceMetrics.throttledRequests + 1
            PvPTooltip:Debug("Tooltip spam detected - enabling throttling for 2 seconds")
            return
        end
        
        -- Enhanced debouncing with spam consideration
        local effectiveDebounce = debounceMs
        if tooltipUpdateCount > (spamThreshold * 0.7) then
            -- Increase debounce time when approaching spam threshold
            effectiveDebounce = debounceMs * 2
        end
        
        if currentTime - lastTooltipUpdate < (effectiveDebounce / 1000) then
            -- Cancel existing timer and create new one with error protection
            if tooltipUpdateTimer then
                local success, _ = pcall(function()
                    tooltipUpdateTimer:Cancel()
                end)
                if not success then
                    PvPTooltip:Debug("Error canceling tooltip timer")
                end
            end
            
            -- Create new timer with error protection
            local success, timer = pcall(function()
                return C_Timer.NewTimer(effectiveDebounce / 1000, function()
                    self:ProcessTooltipUpdate(tooltip, startTime)
                end)
            end)
            
            if success then
                tooltipUpdateTimer = timer
            else
                PvPTooltip:Debug("Error creating tooltip timer - processing immediately")
                self:ProcessTooltipUpdate(tooltip, startTime)
            end
            return
        end
        
        -- Process immediately if enough time has passed
        self:ProcessTooltipUpdate(tooltip, startTime)
        lastTooltipUpdate = currentTime
    end)
    
    if not success then
        PvPTooltip:Debug("Error in tooltip event handling - graceful degradation")
        performanceMetrics.failedUpdates = performanceMetrics.failedUpdates + 1
        -- Don't break the tooltip system, just skip our enhancement
    end
end

-- Process the actual tooltip update with comprehensive error handling and performance tracking
function EventManager:ProcessTooltipUpdate(tooltip, startTime)
    local processingStartTime = startTime or GetTime()
    
    -- Handle unit resolution failures without breaking tooltips
    if not tooltip then
        PvPTooltip:Debug("No tooltip provided to ProcessTooltipUpdate - graceful degradation")
        performanceMetrics.failedUpdates = performanceMetrics.failedUpdates + 1
        return
    end
    
    -- Protect against tooltip state errors
    local success, isShown = pcall(function()
        return tooltip:IsShown()
    end)
    
    if not success or not isShown then
        PvPTooltip:Debug("Tooltip not shown or error checking state - graceful degradation")
        performanceMetrics.failedUpdates = performanceMetrics.failedUpdates + 1
        return
    end
    
    -- Protect against unit information extraction failures
    local success, unitName, unitID = pcall(function()
        return tooltip:GetUnit()
    end)
    
    if not success then
        PvPTooltip:Debug("Error getting unit information from tooltip: " .. tostring(unitName) .. " - graceful degradation")
        performanceMetrics.failedUpdates = performanceMetrics.failedUpdates + 1
        return
    end
    
    if not unitName or not unitID then
        PvPTooltip:Debug("No unit information available in tooltip - graceful degradation")
        performanceMetrics.failedUpdates = performanceMetrics.failedUpdates + 1
        return
    end
    
    PvPTooltip:Debug("Processing tooltip for unit: " .. tostring(unitName) .. " (" .. tostring(unitID) .. ")")
    
    -- Attempt to enhance the tooltip with PvP information with comprehensive error protection
    local success, errorMsg = pcall(function()
        self:EnhanceTooltipWithPvPInfo(tooltip, unitID)
    end)
    
    -- Update performance metrics
    local processingTime = (GetTime() - processingStartTime) * 1000 -- Convert to milliseconds
    
    if success then
        performanceMetrics.successfulUpdates = performanceMetrics.successfulUpdates + 1
        
        -- Update average processing time
        local totalUpdates = performanceMetrics.successfulUpdates
        performanceMetrics.averageProcessingTime = 
            ((performanceMetrics.averageProcessingTime * (totalUpdates - 1)) + processingTime) / totalUpdates
        
        -- Log slow queries
        if PvPTooltip.Config and PvPTooltip.Config.Performance and 
           PvPTooltip.Config.Performance.slowQueryThreshold and
           processingTime > PvPTooltip.Config.Performance.slowQueryThreshold then
            PvPTooltip:Debug(string.format("Slow tooltip processing detected: %.2fms for unit %s", 
                processingTime, tostring(unitName)))
        end
    else
        performanceMetrics.failedUpdates = performanceMetrics.failedUpdates + 1
        PvPTooltip:Debug("Error enhancing tooltip: " .. tostring(errorMsg) .. " - graceful degradation")
        -- Don't break the tooltip system, just log the error and continue
    end
    
    -- Record metrics in PerformanceMonitor if available
    if PvPTooltip.PerformanceMonitor and PvPTooltip.PerformanceMonitor.RecordTooltipMetrics then
        local wasThrottled = isThrottled or (tooltipUpdateCount > (PvPTooltip.Config.Performance.tooltipSpamThreshold or 5) * 0.7)
        PvPTooltip.PerformanceMonitor:RecordTooltipMetrics(success, processingTime, wasThrottled)
    end
end

-- Enhance tooltip with PvP information with comprehensive error handling
function EventManager:EnhanceTooltipWithPvPInfo(tooltip, unitID)
    -- Graceful degradation: check if required modules are available
    if not PvPTooltip.PlayerLookup or not PvPTooltip.PlayerLookup.FindPlayerData then
        PvPTooltip:Debug("PlayerLookup module not available - graceful degradation")
        return
    end
    
    if not PvPTooltip.TooltipRenderer or not PvPTooltip.TooltipRenderer.EnhanceTooltip then
        PvPTooltip:Debug("TooltipRenderer module not available - graceful degradation")
        return
    end
    
    -- Attempt to find player data with error protection
    local success, playerData = pcall(function()
        return PvPTooltip.PlayerLookup:FindPlayerData(unitID)
    end)
    
    if not success then
        PvPTooltip:Debug("Error finding player data: " .. tostring(playerData) .. " - graceful degradation")
        return
    end
    
    if not playerData then
        -- No data for this player: leave the tooltip untouched (graceful, quiet).
        PvPTooltip:Debug("No PvP data found for unit: " .. tostring(unitID) .. " - graceful degradation")
        return
    end
    
    -- Attempt to enhance tooltip with error protection that won't break the tooltip system
    local success, result = pcall(function()
        return PvPTooltip.TooltipRenderer:EnhanceTooltip(tooltip, playerData)
    end)
    
    if not success then
        PvPTooltip:Debug("Error enhancing tooltip with PvP data: " .. tostring(result) .. " - graceful degradation")
        
        -- Attempt a minimal safe fallback display
        local fallbackSuccess, _ = pcall(function()
            tooltip:AddLine(" ")
            tooltip:AddLine("|cFFFF0000PvP Tooltip info:|r")
            tooltip:AddLine("|cFFFFFFFFData temporarily unavailable|r")
        end)
        
        if not fallbackSuccess then
            PvPTooltip:Debug("Even fallback tooltip display failed - complete graceful degradation")
        end
        
        return
    end
    
    if not result then
        PvPTooltip:Debug("Tooltip enhancement returned false - data may be invalid")
    end
end

-- Handle tooltip hide event
function EventManager:OnTooltipHide(tooltip)
    -- Cancel any pending updates for this tooltip
    if tooltipUpdateTimer then
        tooltipUpdateTimer:Cancel()
        tooltipUpdateTimer = nil
    end
    
    PvPTooltip:Debug("Tooltip hidden")
end

-- Check if events are currently registered
function EventManager:AreEventsRegistered()
    return eventsRegistered
end

-- Force refresh of all tooltip hooks (useful for debugging)
function EventManager:RefreshTooltipHooks()
    self:UnregisterTooltipEvents()
    self:RegisterTooltipEvents()
    PvPTooltip:Debug("Tooltip hooks refreshed")
end

-- Get performance metrics for monitoring and debugging
function EventManager:GetPerformanceMetrics()
    local currentTime = GetTime()
    local uptime = currentTime - performanceMetrics.lastResetTime
    
    return {
        uptime = uptime,
        totalRequests = performanceMetrics.totalTooltipRequests,
        successfulUpdates = performanceMetrics.successfulUpdates,
        failedUpdates = performanceMetrics.failedUpdates,
        throttledRequests = performanceMetrics.throttledRequests,
        averageProcessingTime = performanceMetrics.averageProcessingTime,
        requestsPerSecond = uptime > 0 and (performanceMetrics.totalTooltipRequests / uptime) or 0,
        successRate = performanceMetrics.totalTooltipRequests > 0 and 
                     (performanceMetrics.successfulUpdates / performanceMetrics.totalTooltipRequests * 100) or 0,
        isThrottled = isThrottled,
        throttleEndTime = throttleEndTime,
        currentUpdateCount = tooltipUpdateCount,
        updateWindow = tooltipUpdateWindow
    }
end

-- Reset performance metrics
function EventManager:ResetPerformanceMetrics()
    performanceMetrics = {
        totalTooltipRequests = 0,
        throttledRequests = 0,
        successfulUpdates = 0,
        failedUpdates = 0,
        averageProcessingTime = 0,
        lastResetTime = GetTime()
    }
    
    -- Reset throttling state
    isThrottled = false
    throttleEndTime = 0
    tooltipUpdateCount = 0
    tooltipUpdateWindow = GetTime()
    
    PvPTooltip:Debug("Performance metrics reset")
end

-- Get current throttling status
function EventManager:GetThrottlingStatus()
    return {
        isThrottled = isThrottled,
        throttleEndTime = throttleEndTime,
        currentUpdateCount = tooltipUpdateCount,
        updateWindow = tooltipUpdateWindow,
        timeUntilThrottleEnd = isThrottled and math.max(0, throttleEndTime - GetTime()) or 0
    }
end


-- Return the module for proper loading
return EventManager