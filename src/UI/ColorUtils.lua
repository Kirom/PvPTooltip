-- PvPTooltip Color Utilities
-- Provides color coding functionality for ratings, win rates, and UI elements

local ColorUtils = {}
PvPTooltip.ColorUtils = ColorUtils

-- Initialize the ColorUtils module
function ColorUtils:Initialize()
    PvPTooltip:Debug("ColorUtils module initialized")
end

-- Get color hex code for a rating value (Requirements 2.2, 2.3, 2.4, 2.5)
-- @param rating number - The rating value to get color for
-- @return string - Hex color code without # prefix
function ColorUtils:GetRatingColor(rating)
    if not rating or type(rating) ~= "number" then
        return PvPTooltip.Config.Colors.ratingColors[0] -- Default to white
    end
    
    if rating < 1800 then
        return PvPTooltip.Config.Colors.ratingColors[0]      -- White (0-1799)
    elseif rating < 2100 then
        return PvPTooltip.Config.Colors.ratingColors[1800]   -- Green (1800-2099)
    elseif rating < 2400 then
        return PvPTooltip.Config.Colors.ratingColors[2100]   -- Blue (2100-2399)
    else
        return PvPTooltip.Config.Colors.ratingColors[2400]   -- Purple (2400+)
    end
end

-- Get color hex code for a win rate percentage (Requirements 4.3, 4.4)
-- @param winRate number - Win rate percentage (0-100)
-- @return string - Hex color code without # prefix
function ColorUtils:GetWinRateColor(winRate)
    if not winRate or type(winRate) ~= "number" then
        return PvPTooltip.Config.Colors.winRateColors.low -- Default to red
    end
    
    if winRate <= 50 then
        return PvPTooltip.Config.Colors.winRateColors.low   -- Red-orange (≤50%)
    else
        return PvPTooltip.Config.Colors.winRateColors.high  -- Green (>50%)
    end
end

-- Get color hex code for games played count (Requirement 4.2)
-- @return string - Hex color code without # prefix
function ColorUtils:GetGamesPlayedColor()
    return PvPTooltip.Config.Colors.gamesPlayed -- Gold (#FFD035)
end

-- Get color hex code for section titles (Requirement 6.1)
-- @return string - Hex color code without # prefix
function ColorUtils:GetSectionTitleColor()
    return PvPTooltip.Config.Colors.sectionTitle -- Red
end

-- Get color hex code for subsection headers (Requirement 6.2)
-- @return string - Hex color code without # prefix
function ColorUtils:GetSubsectionTitleColor()
    return PvPTooltip.Config.Colors.subsectionTitle -- Gold
end

-- Get color hex code for game mode labels (Requirement 6.3)
-- @return string - Hex color code without # prefix
function ColorUtils:GetGameModeColor()
    return PvPTooltip.Config.Colors.gameMode -- White
end

-- Format text with WoW color codes for tooltip display
-- @param text string - The text to colorize
-- @param colorHex string - Hex color code (with or without # prefix)
-- @return string - WoW formatted colored text
function ColorUtils:FormatColoredText(text, colorHex)
    if not text then
        return ""
    end
    
    if not colorHex then
        return text
    end
    
    -- Remove # prefix if present
    local cleanHex = string.gsub(colorHex, "^#", "")
    
    -- Validate hex format (6 characters, hexadecimal)
    if not string.match(cleanHex, "^%x%x%x%x%x%x$") then
        PvPTooltip:Debug("Invalid color hex format: " .. tostring(colorHex))
        return text
    end
    
    return string.format("|cff%s%s|r", cleanHex, text)
end

-- Format a rating value with appropriate color coding
-- @param rating number - The rating value
-- @return string - Formatted colored rating text
function ColorUtils:FormatColoredRating(rating)
    if not rating or rating == 0 then
        return self:FormatColoredText("0", self:GetRatingColor(0))
    end
    
    local colorHex = self:GetRatingColor(rating)
    return self:FormatColoredText(tostring(rating), colorHex)
end

-- Format win rate display with color coding (Requirement 4.5)
-- @param playedTotal number - Total games played
-- @param winRate number - Win rate percentage (0-100)
-- @return string - Formatted colored win rate text
function ColorUtils:FormatColoredWinRate(playedTotal, winRate)
    -- No games played: show just the count, not a meaningless "(0% won)".
    if not playedTotal or playedTotal == 0 then
        return self:FormatColoredText("0", self:GetGamesPlayedColor())
    end

    winRate = winRate or 0

    -- Format games played in gold color
    local gamesText = self:FormatColoredText(tostring(playedTotal), self:GetGamesPlayedColor())
    
    -- Format win rate percentage with appropriate color
    local winRateText = string.format("%.0f%% won", winRate)
    local coloredWinRate = self:FormatColoredText(winRateText, self:GetWinRateColor(winRate))
    
    return string.format("%s (%s)", gamesText, coloredWinRate)
end

-- Format section title with red color (Requirement 6.1)
-- @param title string - The section title text
-- @return string - Formatted colored title
function ColorUtils:FormatSectionTitle(title)
    return self:FormatColoredText(title, self:GetSectionTitleColor())
end

-- Format subsection header with gold color (Requirement 6.2)
-- @param header string - The subsection header text
-- @return string - Formatted colored header
function ColorUtils:FormatSubsectionHeader(header)
    return self:FormatColoredText(header, self:GetSubsectionTitleColor())
end

-- Format game mode label with white color (Requirement 6.3)
-- @param gameMode string - The game mode name
-- @return string - Formatted colored game mode label
function ColorUtils:FormatGameModeLabel(gameMode)
    local displayName = PvPTooltip.Config:GetDisplayName(gameMode)
    return self:FormatColoredText(displayName, self:GetGameModeColor())
end

-- Return the module for proper loading
return ColorUtils