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

    -- Modifier gate: optionally show PvP info only while a key is held.
    local mod = (PvPTooltipDB and PvPTooltipDB.settings and PvPTooltipDB.settings.modifier) or "always"
    if (mod == "shift" and not IsShiftKeyDown())
        or (mod == "ctrl" and not IsControlKeyDown())
        or (mod == "alt" and not IsAltKeyDown()) then
        return
    end

    self:ProcessTooltipUpdate(tooltip, GetTime())
end

-- Re-render the tooltip currently under the cursor so settings changes preview
-- live. SetUnit rebuilds the tooltip, which re-fires our post-call hook (no
-- duplicate lines). No-op when no unit tooltip is shown.
function EventManager:RefreshActiveTooltip()
    if not GameTooltip or not GameTooltip:IsShown() then
        return
    end
    local _, unit = GameTooltip:GetUnit()
    if unit then
        GameTooltip:SetUnit(unit)
    end
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

    -- Best-effort: the hovered unit's active spec, used to highlight the matching
    -- Solo Shuffle / Blitz line. Only available when inspect data is present (party,
    -- arena, recently inspected); 0/nil otherwise, in which case all specs show plainly.
    local currentSpec = nil
    pcall(function()
        if UnitIsPlayer(unitID) and GetInspectSpecialization then
            local spec = GetInspectSpecialization(unitID)
            if spec and spec > 0 then
                currentSpec = spec
            end
        end
    end)

    local enhanceOk, errorMsg = pcall(function()
        self:EnhanceTooltipWithPvPInfo(tooltip, unitID, currentSpec)
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
function EventManager:EnhanceTooltipWithPvPInfo(tooltip, unitID, currentSpec)
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
        return PvPTooltip.TooltipRenderer:EnhanceTooltip(tooltip, playerData, currentSpec)
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
