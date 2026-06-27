-- PvPTooltip Event Manager
-- Handles WoW event registration and tooltip interception (Midnight 12.0.7+).

local EventManager = {}
PvPTooltip.EventManager = EventManager

local eventsRegistered = false

-- Initialize the event manager
function EventManager:Initialize()
    PvPTooltip:Debug("EventManager initializing...")

    if PvPTooltip:IsReady() then
        self:RegisterTooltipEvents()
    end

    PvPTooltip:Debug("EventManager initialized")
end

-- Register tooltip hook via the modern tooltip data API (retail 10.0.2+).
-- Blizzard fires this once per unit tooltip, after unit data is set, so there
-- is no OnShow race and no need for debounce/throttle machinery.
function EventManager:RegisterTooltipEvents()
    if eventsRegistered then
        return
    end

    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
        if tooltip == GameTooltip then
            EventManager:OnUnitTooltip(tooltip)
        end
    end)

    eventsRegistered = true
    PvPTooltip:Debug("Tooltip events registered (TooltipDataProcessor)")
end

-- A unit tooltip's data was set. Tooltips rebuild their lines on each SetUnit,
-- so we enhance directly.
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

-- Process the tooltip update with error handling and performance tracking.
function EventManager:ProcessTooltipUpdate(tooltip, startTime)
    local processingStartTime = startTime or GetTime()

    if not tooltip then
        return
    end

    local success, isShown = pcall(function()
        return tooltip:IsShown()
    end)
    if not success or not isShown then
        return
    end

    local success, unitName, unitID = pcall(function()
        return tooltip:GetUnit()
    end)
    if not success or not unitName or not unitID then
        return
    end

    PvPTooltip:Debug("Processing tooltip for unit: " .. tostring(unitName) .. " (" .. tostring(unitID) .. ")")

    local enhanceOk, errorMsg = pcall(function()
        self:EnhanceTooltipWithPvPInfo(tooltip, unitID)
    end)

    local processingTime = (GetTime() - processingStartTime) * 1000 -- ms

    if not enhanceOk then
        PvPTooltip:Debug("Error enhancing tooltip: " .. tostring(errorMsg) .. " - graceful degradation")
    elseif PvPTooltip.Config and PvPTooltip.Config.Performance and
           PvPTooltip.Config.Performance.slowQueryThreshold and
           processingTime > PvPTooltip.Config.Performance.slowQueryThreshold then
        PvPTooltip:Debug(string.format("Slow tooltip processing: %.2fms for unit %s",
            processingTime, tostring(unitName)))
    end

    if PvPTooltip.PerformanceMonitor and PvPTooltip.PerformanceMonitor.RecordTooltipMetrics then
        PvPTooltip.PerformanceMonitor:RecordTooltipMetrics(enhanceOk, processingTime, false)
    end
end

-- Enhance tooltip with PvP information. Quiet graceful degradation on any failure
-- so a broken lookup never breaks the underlying tooltip.
function EventManager:EnhanceTooltipWithPvPInfo(tooltip, unitID)
    if not PvPTooltip.PlayerLookup or not PvPTooltip.PlayerLookup.FindPlayerData then
        PvPTooltip:Debug("PlayerLookup module not available - graceful degradation")
        return
    end

    if not PvPTooltip.TooltipRenderer or not PvPTooltip.TooltipRenderer.EnhanceTooltip then
        PvPTooltip:Debug("TooltipRenderer module not available - graceful degradation")
        return
    end

    local success, playerData = pcall(function()
        return PvPTooltip.PlayerLookup:FindPlayerData(unitID)
    end)
    if not success then
        PvPTooltip:Debug("Error finding player data: " .. tostring(playerData) .. " - graceful degradation")
        return
    end

    if not playerData then
        -- No data for this player: leave the tooltip untouched (quiet).
        PvPTooltip:Debug("No PvP data found for unit: " .. tostring(unitID))
        return
    end

    local renderOk, result = pcall(function()
        return PvPTooltip.TooltipRenderer:EnhanceTooltip(tooltip, playerData)
    end)
    if not renderOk then
        PvPTooltip:Debug("Error enhancing tooltip with PvP data: " .. tostring(result) .. " - graceful degradation")
        return
    end

    if not result then
        PvPTooltip:Debug("Tooltip enhancement returned false - data may be invalid")
    end
end

-- Check if events are currently registered
function EventManager:AreEventsRegistered()
    return eventsRegistered
end

-- Return the module for proper loading
return EventManager
