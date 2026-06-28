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
    
    -- Protect against tooltip rendering errors without breaking the tooltip system
    local success, result = pcall(function()
        -- Add main section title (Requirement 6.1) with error protection
        local success = self:AddSectionTitle(tooltip)
        if not success then
            PvPTooltip:Debug("Error adding section title - continuing with degraded display")
        end
        
        -- Add current rating section (Requirement 2.1) with error protection
        success = self:FormatRatingSection(tooltip, playerData.brackets, currentSpec)
        if not success then
            PvPTooltip:Debug("Error formatting rating section - continuing with degraded display")
        end

        -- Add character experience section (Requirement 3.1) with error protection
        success = self:FormatExperienceSection(tooltip, playerData.brackets, currentSpec)
        if not success then
            PvPTooltip:Debug("Error formatting experience section - continuing with degraded display")
        end

        -- Add current season section (Requirement 4.1) with error protection
        success = self:FormatSeasonSection(tooltip, playerData.brackets, currentSpec)
        if not success then
            PvPTooltip:Debug("Error formatting season section - continuing with degraded display")
        end
        
        return true
    end)
    
    if not success then
        PvPTooltip:Debug("Critical error during tooltip enhancement: " .. tostring(result) .. " - graceful degradation")
        
        -- Attempt to add a minimal error-safe display
        local fallbackSuccess, _ = pcall(function()
            tooltip:AddLine(" ")
            tooltip:AddLine("|cFFFF0000PvP Tooltip info:|r")
            tooltip:AddLine("|cFFFFFFFFData temporarily unavailable|r")
        end)
        
        if not fallbackSuccess then
            PvPTooltip:Debug("Even fallback tooltip enhancement failed - complete graceful degradation")
        end
        
        return false
    end
    
    return true
end

-- Add the main "PvP Tooltip info:" section title with error handling (Requirement 6.1)
function TooltipRenderer:AddSectionTitle(tooltip)
    if not tooltip then
        return false
    end
    
    -- Protect against configuration errors
    local success, titleText = pcall(function()
        if PvPTooltip.Config and PvPTooltip.Config.Tooltip and PvPTooltip.Config.Tooltip.mainTitle then
            return PvPTooltip.Config.Tooltip.mainTitle
        else
            return "PvP Tooltip info:" -- Fallback title
        end
    end)
    
    if not success then
        titleText = "PvP Tooltip info:" -- Safe fallback
    end
    
    -- Protect against color utility errors
    local coloredTitle = titleText
    if PvPTooltip.ColorUtils and PvPTooltip.ColorUtils.FormatSectionTitle then
        local success, result = pcall(function()
            return PvPTooltip.ColorUtils:FormatSectionTitle(titleText)
        end)
        if success and result then
            coloredTitle = result
        else
            -- Fallback to manual coloring
            coloredTitle = "|cFFFF0000" .. titleText .. "|r"
        end
    else
        -- Fallback to manual coloring
        coloredTitle = "|cFFFF0000" .. titleText .. "|r"
    end
    
    -- Protect against tooltip API errors
    local success, _ = pcall(function()
        tooltip:AddLine(" ")
        tooltip:AddLine(coloredTitle)
    end)
    
    if not success then
        PvPTooltip:Debug("Error adding section title to tooltip")
        return false
    end
    
    return true
end

-- Create current rating display section with error handling (Requirement 2.1)
function TooltipRenderer:FormatRatingSection(tooltip, brackets, currentSpec)
    if not tooltip then
        return false
    end
    
    -- Graceful degradation for missing brackets data
    if not brackets or type(brackets) ~= "table" then
        PvPTooltip:Debug("No brackets data available for rating section - graceful degradation")
        return false
    end
    
    -- Add section header with error protection (Requirement 6.2)
    local success, _ = pcall(function()
        local headerText = "Current Rating" -- Safe fallback
        if PvPTooltip.Config and PvPTooltip.Config.Tooltip and PvPTooltip.Config.Tooltip.currentRatingTitle then
            headerText = PvPTooltip.Config.Tooltip.currentRatingTitle
        end
        
        local coloredHeader = headerText
        if PvPTooltip.ColorUtils and PvPTooltip.ColorUtils.FormatSubsectionHeader then
            local success, result = pcall(function()
                return PvPTooltip.ColorUtils:FormatSubsectionHeader(headerText)
            end)
            if success and result then
                coloredHeader = result
            else
                coloredHeader = "|cFFFFD035" .. headerText .. "|r" -- Fallback coloring
            end
        else
            coloredHeader = "|cFFFFD035" .. headerText .. "|r" -- Fallback coloring
        end
        
        tooltip:AddLine(coloredHeader)
    end)
    
    if not success then
        PvPTooltip:Debug("Error adding rating section header")
        return false
    end
    
    -- Add rating entries for each game mode with error protection
    local gameModes = {"2v2", "3v3", "shuffle", "rbg", "blitz"} -- Safe fallback
    if PvPTooltip.Config and PvPTooltip.Config.GameModes then
        gameModes = PvPTooltip.Config.GameModes
    end
    
    for _, gameMode in ipairs(gameModes) do
        local success, _ = pcall(function()
            local entries = getBracketEntries(brackets[gameMode])
            if #entries == 0 then
                self:AddRatingLine(tooltip, gameMode, 0)
                return
            end
            for _, entry in ipairs(entries) do
                local label = self:GetEntryLabel(gameMode, entry, currentSpec)
                self:AddRatingLine(tooltip, gameMode, entry.currentRating or 0, label)
            end
        end)

        if not success then
            PvPTooltip:Debug("Error adding rating line for game mode: " .. tostring(gameMode))
            -- Continue with other game modes instead of failing completely
        end
    end

    return true
end

-- Create character experience (personal best) display section with error handling (Requirement 3.1)
function TooltipRenderer:FormatExperienceSection(tooltip, brackets, currentSpec)
    if not tooltip then
        return false
    end
    
    -- Graceful degradation for missing brackets data
    if not brackets or type(brackets) ~= "table" then
        PvPTooltip:Debug("No brackets data available for experience section - graceful degradation")
        return false
    end
    
    -- Add section header with error protection (Requirement 6.2)
    local success, _ = pcall(function()
        local headerText = "Character Experience" -- Safe fallback
        if PvPTooltip.Config and PvPTooltip.Config.Tooltip and PvPTooltip.Config.Tooltip.experienceTitle then
            headerText = PvPTooltip.Config.Tooltip.experienceTitle
        end
        
        local coloredHeader = headerText
        if PvPTooltip.ColorUtils and PvPTooltip.ColorUtils.FormatSubsectionHeader then
            local success, result = pcall(function()
                return PvPTooltip.ColorUtils:FormatSubsectionHeader(headerText)
            end)
            if success and result then
                coloredHeader = result
            else
                coloredHeader = "|cFFFFD035" .. headerText .. "|r" -- Fallback coloring
            end
        else
            coloredHeader = "|cFFFFD035" .. headerText .. "|r" -- Fallback coloring
        end
        
        tooltip:AddLine(coloredHeader)
    end)
    
    if not success then
        PvPTooltip:Debug("Error adding experience section header")
        return false
    end
    
    -- Add personal best entries for each game mode with error protection
    local gameModes = {"2v2", "3v3", "shuffle", "rbg", "blitz"} -- Safe fallback
    if PvPTooltip.Config and PvPTooltip.Config.GameModes then
        gameModes = PvPTooltip.Config.GameModes
    end
    
    for _, gameMode in ipairs(gameModes) do
        local success, _ = pcall(function()
            local entries = getBracketEntries(brackets[gameMode])
            if #entries == 0 then
                self:AddRatingLine(tooltip, gameMode, 0)
                return
            end
            for _, entry in ipairs(entries) do
                local label = self:GetEntryLabel(gameMode, entry, currentSpec)
                self:AddRatingLine(tooltip, gameMode, entry.personalBest or 0, label)
            end
        end)

        if not success then
            PvPTooltip:Debug("Error adding experience line for game mode: " .. tostring(gameMode))
            -- Continue with other game modes instead of failing completely
        end
    end

    return true
end

-- Create current season statistics display section with error handling (Requirement 4.1)
function TooltipRenderer:FormatSeasonSection(tooltip, brackets, currentSpec)
    if not tooltip then
        return false
    end
    
    -- Graceful degradation for missing brackets data
    if not brackets or type(brackets) ~= "table" then
        PvPTooltip:Debug("No brackets data available for season section - graceful degradation")
        return false
    end
    
    -- Add section header with error protection (Requirement 6.2)
    local success, _ = pcall(function()
        local headerText = "Current Season" -- Safe fallback
        if PvPTooltip.Config and PvPTooltip.Config.Tooltip and PvPTooltip.Config.Tooltip.seasonTitle then
            headerText = PvPTooltip.Config.Tooltip.seasonTitle
        end
        
        local coloredHeader = headerText
        if PvPTooltip.ColorUtils and PvPTooltip.ColorUtils.FormatSubsectionHeader then
            local success, result = pcall(function()
                return PvPTooltip.ColorUtils:FormatSubsectionHeader(headerText)
            end)
            if success and result then
                coloredHeader = result
            else
                coloredHeader = "|cFFFFD035" .. headerText .. "|r" -- Fallback coloring
            end
        else
            coloredHeader = "|cFFFFD035" .. headerText .. "|r" -- Fallback coloring
        end
        
        tooltip:AddLine(coloredHeader)
    end)
    
    if not success then
        PvPTooltip:Debug("Error adding season section header")
        return false
    end
    
    -- Add season statistics for each game mode with error protection
    local gameModes = {"2v2", "3v3", "shuffle", "rbg", "blitz"} -- Safe fallback
    if PvPTooltip.Config and PvPTooltip.Config.GameModes then
        gameModes = PvPTooltip.Config.GameModes
    end
    
    for _, gameMode in ipairs(gameModes) do
        local success, _ = pcall(function()
            local entries = getBracketEntries(brackets[gameMode])
            if #entries == 0 then
                self:AddSeasonLine(tooltip, gameMode, 0, 0)
                return
            end
            for _, entry in ipairs(entries) do
                local label = self:GetEntryLabel(gameMode, entry, currentSpec)
                self:AddSeasonLine(tooltip, gameMode, entry.playedTotal or 0, entry.winRate or 0, label)
            end
        end)

        if not success then
            PvPTooltip:Debug("Error adding season line for game mode: " .. tostring(gameMode))
            -- Continue with other game modes instead of failing completely
        end
    end

    return true
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

-- Add colored line utility for custom formatting
function TooltipRenderer:AddColoredLine(tooltip, text, colorHex)
    if not tooltip or not text then
        return
    end
    
    local coloredText = text
    if colorHex then
        coloredText = PvPTooltip.ColorUtils:FormatColoredText(text, colorHex)
    end
    
    tooltip:AddLine(coloredText)
end

-- Add empty line for spacing
function TooltipRenderer:AddSpacing(tooltip, lines)
    if not tooltip then
        return
    end
    
    local lineCount = lines or 1
    for i = 1, lineCount do
        tooltip:AddLine(" ")
    end
end

-- Check if player has any PvP data worth displaying
function TooltipRenderer:HasDisplayableData(playerData)
    if not self:ValidatePlayerData(playerData) then
        return false
    end
    
    -- Check if any bracket has meaningful data
    for _, gameMode in ipairs(PvPTooltip.Config.GameModes) do
        for _, entry in ipairs(getBracketEntries(playerData.brackets[gameMode])) do
            -- Consider data displayable if there's a rating > 0 or games played > 0
            if (entry.currentRating and entry.currentRating > 0) or
               (entry.personalBest and entry.personalBest > 0) or
               (entry.playedTotal and entry.playedTotal > 0) then
                return true
            end
        end
    end

    return false
end

-- Get formatted tooltip preview for testing
function TooltipRenderer:GetTooltipPreview(playerData)
    if not playerData then
        return "No player data provided"
    end
    
    if not self:ValidatePlayerData(playerData) then
        return "Invalid player data structure"
    end
    
    local lines = {}
    
    -- Main title
    table.insert(lines, "")
    table.insert(lines, PvPTooltip.Config.Tooltip.mainTitle)
    
    -- A preview label: display name plus the spec name for per-spec entries.
    local function previewLabel(gameMode, entry)
        local displayName = PvPTooltip.Config:GetDisplayName(gameMode)
        local specName = entry and entry.shuffleSpecId and resolveSpecName(entry.shuffleSpecId)
        if specName then
            return displayName .. " (" .. specName .. ")"
        end
        return displayName
    end

    -- Current Rating section
    table.insert(lines, PvPTooltip.Config.Tooltip.currentRatingTitle)
    for _, gameMode in ipairs(PvPTooltip.Config.GameModes) do
        for _, entry in ipairs(getBracketEntries(playerData.brackets[gameMode])) do
            table.insert(lines, string.format("  %s                    %d",
                previewLabel(gameMode, entry), entry.currentRating or 0))
        end
    end

    -- Character Experience section
    table.insert(lines, PvPTooltip.Config.Tooltip.experienceTitle)
    for _, gameMode in ipairs(PvPTooltip.Config.GameModes) do
        for _, entry in ipairs(getBracketEntries(playerData.brackets[gameMode])) do
            table.insert(lines, string.format("  %s                    %d",
                previewLabel(gameMode, entry), entry.personalBest or 0))
        end
    end

    -- Current Season section
    table.insert(lines, PvPTooltip.Config.Tooltip.seasonTitle)
    for _, gameMode in ipairs(PvPTooltip.Config.GameModes) do
        for _, entry in ipairs(getBracketEntries(playerData.brackets[gameMode])) do
            local played = entry.playedTotal or 0
            local seasonStat = played == 0 and "0"
                or string.format("%d (%.0f%% won)", played, entry.winRate or 0)
            table.insert(lines, string.format("  %s                    %s",
                previewLabel(gameMode, entry), seasonStat))
        end
    end

    return table.concat(lines, "\n")
end

-- Test tooltip rendering with sample data
function TooltipRenderer:TestRender()
    -- Create sample player data for testing
    local sampleData = {
        name = "TestPlayer",
        realm = "test-realm",
        region = "eu",
        brackets = {
            ["2v2"] = {
                currentRating = 2150,
                personalBest = 2400,
                seasonBest = 2200,
                playedTotal = 85,
                winRate = 65.5
            },
            ["3v3"] = {
                currentRating = 1950,
                personalBest = 2100,
                seasonBest = 2000,
                playedTotal = 42,
                winRate = 52.4
            },
            ["shuffle"] = {
                currentRating = 2300,
                personalBest = 2450,
                seasonBest = 2350,
                playedTotal = 120,
                winRate = 58.3,
                shuffleSpecId = 270
            },
            ["rbg"] = {
                currentRating = 1800,
                personalBest = 2000,
                seasonBest = 1850,
                playedTotal = 25,
                winRate = 72.0
            },
            ["blitz"] = {
                currentRating = 0,
                personalBest = 1650,
                seasonBest = 0,
                playedTotal = 0,
                winRate = 0.0,
                shuffleSpecId = 270
            }
        }
    }
    
    PvPTooltip:Print("=== Tooltip Render Test ===")
    PvPTooltip:Print("Player: " .. sampleData.name)
    PvPTooltip:Print("Has displayable data: " .. tostring(self:HasDisplayableData(sampleData)))
    PvPTooltip:Print("Data validation: " .. tostring(self:ValidatePlayerData(sampleData)))
    
    local preview = self:GetTooltipPreview(sampleData)
    PvPTooltip:Print("Tooltip Preview:")
    PvPTooltip:Print(preview)
    
    return sampleData
end

-- Get rendering statistics for debugging
function TooltipRenderer:GetRenderStats()
    return {
        module = "TooltipRenderer",
        initialized = true,
        dependencies = {
            config = PvPTooltip.Config ~= nil,
            colorUtils = PvPTooltip.ColorUtils ~= nil
        },
        supportedGameModes = PvPTooltip.Config and PvPTooltip.Config.GameModes or {},
        tooltipSettings = PvPTooltip.Config and PvPTooltip.Config.Tooltip or {}
    }
end


-- Return the module for proper loading
return TooltipRenderer