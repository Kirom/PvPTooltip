-- PvPTooltip Tooltip Renderer
-- Implements PvP information display and formatting for game tooltips

local TooltipRenderer = {}
PvPTooltip.TooltipRenderer = TooltipRenderer

-- Initialize the tooltip renderer module
function TooltipRenderer:Initialize()
    PvPTooltip:Debug("TooltipRenderer module initialized")
end

-- Resolve a specialization id to its localized name (e.g. 270 -> "Mistweaver").
-- Returns nil when unavailable so callers can fall back gracefully.
local function resolveSpecName(specId)
    if not specId then
        return nil
    end
    local ok, _, name = pcall(GetSpecializationInfoByID, specId)
    if ok and name and name ~= "" then
        return name
    end
    return nil
end

-- Normalize a bracket value to a list of entries. Per-spec brackets (shuffle/blitz
-- with several specs) arrive as an array; single brackets as one table.
local function getBracketEntries(bracketData)
    if type(bracketData) ~= "table" then
        return {}
    end
    if bracketData[1] ~= nil then
        return bracketData
    end
    return { bracketData }
end

-- User settings (nil before first-run init → callers treat absence as "show all").
local function settings()
    return PvPTooltipDB and PvPTooltipDB.settings
end

-- A bracket is shown unless explicitly toggled off.
local function bracketEnabled(gameMode)
    local s = settings()
    if not s or not s.brackets then
        return true
    end
    return s.brackets[gameMode] ~= false
end

-- Per-spec entries (shuffle/blitz) honor the "show all specs" toggle. When off we
-- show only the hovered unit's active spec; if that's unknown, show all (else the
-- player would see nothing). Non-spec entries always pass.
local function specVisible(entry, currentSpec)
    local s = settings()
    if not s or s.showAllSpecs ~= false then
        return true
    end
    if not entry.shuffleSpecId or not currentSpec then
        return true
    end
    return entry.shuffleSpecId == currentSpec
end

-- Render a subsection header (gold).
local function addHeader(tooltip, text)
    tooltip:AddLine(PvPTooltip.ColorUtils:FormatSubsectionHeader(text))
end

-- Main rendering function - enhances tooltip with PvP information with comprehensive error handling
function TooltipRenderer:EnhanceTooltip(tooltip, playerData, currentSpec)
    -- Handle missing data gracefully without breaking tooltips
    if not tooltip then
        PvPTooltip:Debug("No tooltip provided to EnhanceTooltip - graceful degradation")
        return false
    end
    
    if not playerData then
        PvPTooltip:Debug("No player data provided to EnhanceTooltip - graceful degradation")
        return false
    end
    
    -- Validate player data structure with graceful degradation
    if not self:ValidatePlayerData(playerData) then
        PvPTooltip:Debug("Invalid player data structure - graceful degradation")
        return false
    end
    
    PvPTooltip:Debug(string.format("Enhancing tooltip for player: %s", playerData.name or "unknown"))
    
    -- Single error boundary for rendering: callers hover-path (EventManager) and
    -- settings preview both come through here, so one pcall protects both.
    local success, result = pcall(function()
        -- Section visibility settings (absent before first-run init -> show all).
        local s = PvPTooltipDB and PvPTooltipDB.settings

        self:AddSectionTitle(tooltip)

        if not s or s.showRating then
            self:FormatRatingSection(tooltip, playerData.brackets, currentSpec)
        end
        if not s or s.showExperience then
            self:FormatExperienceSection(tooltip, playerData.brackets, currentSpec)
        end
        if not s or s.showSeason then
            self:FormatSeasonSection(tooltip, playerData.brackets, currentSpec)
        end
    end)

    if not success then
        PvPTooltip:Debug("Error during tooltip enhancement: " .. tostring(result) .. " - graceful degradation")
        return false
    end

    return true
end

-- Add the main "PvP Tooltip info:" section title (Requirement 6.1)
function TooltipRenderer:AddSectionTitle(tooltip)
    local titleText = (PvPTooltip.Config and PvPTooltip.Config.Tooltip
        and PvPTooltip.Config.Tooltip.mainTitle) or "PvP Tooltip info:"
    tooltip:AddLine(" ")
    tooltip:AddLine(PvPTooltip.ColorUtils:FormatSectionTitle(titleText))
end

-- Render one bracket subsection. Shared by all three sections; the only
-- differences are the header, which entry value decides "empty", and how a line
-- is drawn. valueOf(entry) -> number used for the hideEmpty check; draw(tooltip,
-- gameMode, entry, label) emits the line (entry is nil for an absent bracket).
-- Applies the per-bracket, hide-empty, and show-all-specs settings filters.
function TooltipRenderer:RenderSection(tooltip, brackets, currentSpec, header, valueOf, draw)
    if not tooltip then
        return false
    end
    if not brackets or type(brackets) ~= "table" then
        PvPTooltip:Debug("No brackets data available for section - graceful degradation")
        return false
    end

    addHeader(tooltip, header)

    local hideEmpty = settings() and settings().hideEmpty
    local gameModes = (PvPTooltip.Config and PvPTooltip.Config.GameModes)
        or {"2v2", "3v3", "shuffle", "rbg", "blitz"}

    for _, gameMode in ipairs(gameModes) do
        if bracketEnabled(gameMode) then
            local entries = getBracketEntries(brackets[gameMode])
            if #entries == 0 then
                if not hideEmpty then
                    draw(tooltip, gameMode, nil, nil)
                end
            else
                for _, entry in ipairs(entries) do
                    if specVisible(entry, currentSpec)
                       and not (hideEmpty and valueOf(entry) == 0) then
                        local label = self:GetEntryLabel(gameMode, entry, currentSpec)
                        draw(tooltip, gameMode, entry, label)
                    end
                end
            end
        end
    end

    return true
end

-- Create current rating display section (Requirement 2.1)
function TooltipRenderer:FormatRatingSection(tooltip, brackets, currentSpec)
    local header = (PvPTooltip.Config and PvPTooltip.Config.Tooltip
        and PvPTooltip.Config.Tooltip.currentRatingTitle) or "Current Rating"
    return self:RenderSection(tooltip, brackets, currentSpec, header,
        function(entry) return entry.currentRating or 0 end,
        function(t, gm, entry, label)
            self:AddRatingLine(t, gm, (entry and entry.currentRating) or 0, label)
        end)
end

-- Create character experience (personal best) display section (Requirement 3.1)
function TooltipRenderer:FormatExperienceSection(tooltip, brackets, currentSpec)
    local header = (PvPTooltip.Config and PvPTooltip.Config.Tooltip
        and PvPTooltip.Config.Tooltip.experienceTitle) or "Character Experience"
    return self:RenderSection(tooltip, brackets, currentSpec, header,
        function(entry) return entry.personalBest or 0 end,
        function(t, gm, entry, label)
            self:AddRatingLine(t, gm, (entry and entry.personalBest) or 0, label)
        end)
end

-- Create current season statistics display section (Requirement 4.1)
function TooltipRenderer:FormatSeasonSection(tooltip, brackets, currentSpec)
    local header = (PvPTooltip.Config and PvPTooltip.Config.Tooltip
        and PvPTooltip.Config.Tooltip.seasonTitle) or "Current Season"
    return self:RenderSection(tooltip, brackets, currentSpec, header,
        function(entry) return entry.playedTotal or 0 end,
        function(t, gm, entry, label)
            self:AddSeasonLine(t, gm, (entry and entry.playedTotal) or 0,
                (entry and entry.winRate) or 0, label)
        end)
end

-- Build the left-column label for a per-spec bracket entry (shuffle/blitz). Returns
-- nil for non-spec entries so callers use the default game-mode label. The unit's
-- active spec (currentSpec) is marked; other specs are listed plainly.
function TooltipRenderer:GetEntryLabel(gameMode, entry, currentSpec)
    local specId = entry and entry.shuffleSpecId
    if not specId then
        return nil
    end

    local label = PvPTooltip.ColorUtils:FormatGameModeLabel(gameMode)
    local specName = resolveSpecName(specId)
    if specName then
        label = label .. " |cFFB0B0B0(" .. specName .. ")|r"
    end
    if currentSpec and specId == currentSpec then
        label = "|cFF00FF00>|r " .. label -- mark the hovered unit's active spec
    end
    return label
end

-- Add a single rating line to the tooltip (Requirements 2.2, 2.3, 2.4, 2.5)
function TooltipRenderer:AddRatingLine(tooltip, gameMode, rating, labelOverride)
    if not tooltip or not gameMode then
        return
    end

    -- Format game mode label (Requirement 6.3)
    local gameModeLabel = labelOverride or PvPTooltip.ColorUtils:FormatGameModeLabel(gameMode)

    -- Format rating with color coding (Requirements 2.2, 2.3, 2.4, 2.5)
    local coloredRating = PvPTooltip.ColorUtils:FormatColoredRating(rating or 0)

    -- Two-column line: WoW aligns the right value for us (proportional font, so
    -- space padding cannot align columns).
    tooltip:AddDoubleLine(gameModeLabel, coloredRating)
end

-- Add a single season statistics line to the tooltip (Requirements 4.2, 4.3, 4.4, 4.5)
function TooltipRenderer:AddSeasonLine(tooltip, gameMode, playedTotal, winRate, labelOverride)
    if not tooltip or not gameMode then
        return
    end

    -- Format game mode label (Requirement 6.3)
    local gameModeLabel = labelOverride or PvPTooltip.ColorUtils:FormatGameModeLabel(gameMode)

    -- Format win rate display (Requirements 4.2, 4.3, 4.4, 4.5)
    local coloredWinRate = PvPTooltip.ColorUtils:FormatColoredWinRate(playedTotal or 0, winRate or 0)

    -- Two-column line: WoW aligns the right value for us.
    tooltip:AddDoubleLine(gameModeLabel, coloredWinRate)
end

-- Validate player data structure before rendering
function TooltipRenderer:ValidatePlayerData(playerData)
    if not playerData then
        return false
    end
    
    -- Check required fields
    if not playerData.name or not playerData.brackets then
        PvPTooltip:Debug("Player data missing required fields")
        return false
    end
    
    -- Check that brackets is a table
    if type(playerData.brackets) ~= "table" then
        PvPTooltip:Debug("Player data brackets is not a table")
        return false
    end
    
    -- Check if at least one bracket has some data
    local hasData = false
    for _, bracketData in pairs(playerData.brackets) do
        for _, entry in ipairs(getBracketEntries(bracketData)) do
            if type(entry) == "table" and
               (entry.currentRating or entry.personalBest or entry.playedTotal) then
                hasData = true
                break
            end
        end
        if hasData then
            break
        end
    end
    
    if not hasData then
        PvPTooltip:Debug("Player data has no valid bracket information")
        return false
    end
    
    return true
end

-- Return the module for proper loading
return TooltipRenderer