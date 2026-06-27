-- PvPTooltip Configuration Module
-- Defines constants, colors, and configuration settings

local Config = {}

-- Ensure PvPTooltip namespace exists
if not PvPTooltip then
    PvPTooltip = {}
end

PvPTooltip.Config = Config

-- Color constants for UI elements
Config.Colors = {
    -- Section titles and headers (Requirement 6.1, 6.2)
    sectionTitle = "FF0000",        -- Red for main "PvP Tooltip info:" title
    subsectionTitle = "FFD035",     -- Gold for section headers (Current Rating, Character Experience, Current Season)
    gameMode = "FFFFFF",            -- White for game mode labels (Requirement 6.3)
    gamesPlayed = "FFD035",         -- Gold for games played count (Requirement 4.2)
    
    -- Rating-based color coding (Requirements 2.2, 2.3, 2.4, 2.5)
    ratingColors = {
        [0] = "FFFFFF",             -- White (0-1799)
        [1800] = "2EAD65",          -- Green (1800-2099) 
        [2100] = "046DCC",          -- Blue (2100-2399)
        [2400] = "A140E9"           -- Purple (2400+)
    },
    
    -- Win rate colors (Requirements 4.3, 4.4)
    winRateColors = {
        low = "FF4500",             -- Red-orange for ≤50%
        high = "57C94F"             -- Green for >50%
    }
}

-- Game mode definitions and display order
Config.GameModes = {
    "2v2",
    "3v3", 
    "shuffle",
    "rbg",
    "blitz"
}

-- Human-readable display names for game modes
Config.DisplayNames = {
    ["2v2"] = "2v2",
    ["3v3"] = "3v3",
    ["shuffle"] = "shuffle",
    ["rbg"] = "RBG",
    ["blitz"] = "Blitz"
}

-- Database file paths
Config.DatabasePaths = {
    euCharacters = "src/db/db_pvp_eu_characters.lua",
    usCharacters = "src/db/db_pvp_us_characters.lua",
    realms = "src/db/db_realms.lua",
    regions = "src/db/db_regions.lua"
}

-- Performance and behavior settings
Config.Performance = {
    tooltipDebounceMs = 50,         -- Minimum time between tooltip updates
    tooltipSpamThreshold = 5,       -- Maximum tooltip updates per second before throttling
    maxCacheSize = 10000,           -- Maximum cached player entries
    cacheCleanupInterval = 300,     -- Seconds between cache cleanup
    cacheMaxAge = 3600,             -- Maximum age of cached entries in seconds (1 hour)
    cacheAccessThreshold = 10,      -- Minimum access count to keep entry during cleanup
    maxErrorsPerMinute = 10,        -- Maximum errors logged per minute per context
    errorSuppressionTime = 60,      -- Seconds to suppress errors after rate limit
    
    -- Database lookup optimizations
    enableLookupCache = true,       -- Enable fast lookup cache for recent queries
    lookupCacheSize = 1000,         -- Size of fast lookup cache
    lookupCacheMaxAge = 300,        -- Maximum age of lookup cache entries (5 minutes)
    
    -- Memory management settings
    enableMemoryOptimization = true, -- Enable memory optimization features
    memoryCleanupInterval = 600,    -- Seconds between memory cleanup cycles (10 minutes)
    memoryPressureThreshold = 0.8,  -- Memory usage threshold to trigger aggressive cleanup
    enableDataCompression = false,  -- Enable data compression (disabled by default for compatibility)
    
    -- Performance monitoring
    enablePerformanceMetrics = true, -- Enable performance metrics collection
    metricsRetentionTime = 1800,    -- How long to keep performance metrics (30 minutes)
    slowQueryThreshold = 100        -- Milliseconds - log queries slower than this
}

-- Error handling and graceful degradation settings
Config.ErrorHandling = {
    enableErrorLogging = true,      -- Enable error logging to saved variables
    maxErrorLogEntries = 100,       -- Maximum error log entries to keep
    enableGracefulDegradation = true, -- Enable graceful degradation on errors
    enableCorruptionDetection = true, -- Enable database corruption detection
    maxCorruptionRate = 0.5,        -- Maximum acceptable corruption rate (50%)
    enableMemoryMonitoring = false, -- Enable memory usage monitoring
    memoryThresholdMB = 50          -- Memory usage threshold in MB
}

-- Tooltip formatting settings
Config.Tooltip = {
    maxLineLength = 40,             -- Maximum characters per line
    indentSpaces = 2,               -- Spaces for indentation
    sectionSpacing = 1,             -- Empty lines between sections
    
    -- Section titles (Requirements 6.1, 6.2)
    mainTitle = "PvP Tooltip info:",
    currentRatingTitle = "Current Rating",
    experienceTitle = "Character Experience", 
    seasonTitle = "Current Season"
}

-- Initialize configuration
function Config:Initialize()
    PvPTooltip:Debug("Config module initialized")
    
    -- Validate color format (ensure all colors are valid hex)
    self:ValidateColors()
    
    -- Set up any dynamic configuration
    self:SetupDynamicConfig()
end

-- Validate that all color values are proper hex codes
function Config:ValidateColors()
    local function isValidHex(color)
        return type(color) == "string" and string.match(color, "^%x%x%x%x%x%x$")
    end
    
    -- Check basic colors
    for key, color in pairs(self.Colors) do
        if type(color) == "string" and not isValidHex(color) then
            PvPTooltip:Error("Invalid color format for " .. key .. ": " .. color)
        end
    end
    
    -- Check rating colors
    for rating, color in pairs(self.Colors.ratingColors) do
        if not isValidHex(color) then
            PvPTooltip:Error("Invalid rating color format for " .. rating .. ": " .. color)
        end
    end
    
    -- Check win rate colors
    for key, color in pairs(self.Colors.winRateColors) do
        if not isValidHex(color) then
            PvPTooltip:Error("Invalid win rate color format for " .. key .. ": " .. color)
        end
    end
end

-- Set up any configuration that depends on runtime conditions
function Config:SetupDynamicConfig()
    -- Could be used for locale-specific settings, server-specific configs, etc.
    -- Currently just logs that setup is complete
    PvPTooltip:Debug("Dynamic configuration setup complete")
end

-- Get color for a specific rating value
function Config:GetRatingColor(rating)
    if not rating or rating < 1800 then
        return self.Colors.ratingColors[0]
    elseif rating < 2100 then
        return self.Colors.ratingColors[1800]
    elseif rating < 2400 then
        return self.Colors.ratingColors[2100]
    else
        return self.Colors.ratingColors[2400]
    end
end

-- Get color for win rate percentage
function Config:GetWinRateColor(winRate)
    if not winRate or winRate <= 50 then
        return self.Colors.winRateColors.low
    else
        return self.Colors.winRateColors.high
    end
end

-- Get display name for a game mode
function Config:GetDisplayName(gameMode)
    return self.DisplayNames[gameMode] or gameMode
end

-- Check if a game mode is valid
function Config:IsValidGameMode(gameMode)
    for _, mode in ipairs(self.GameModes) do
        if mode == gameMode then
            return true
        end
    end
    return false
end

-- Format win rate display according to requirement 4.5: "{playedTotal} ({winRate}% won)"
function Config:FormatWinRateDisplay(playedTotal, winRate)
    if not playedTotal or not winRate then
        return "0 (0% won)"
    end
    return string.format("%d (%.0f%% won)", playedTotal, winRate)
end

-- Get formatted color string for WoW tooltip display
function Config:GetColoredText(text, colorHex)
    if not colorHex then
        return text
    end
    return string.format("|cff%s%s|r", colorHex, text)
end


-- Return the module for proper loading
return Config