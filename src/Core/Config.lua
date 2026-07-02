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

-- Performance and behavior settings
Config.Performance = {
    slowQueryThreshold = 100        -- Milliseconds - log slow tooltip processing (debug only)
}

-- Tooltip formatting settings
Config.Tooltip = {
    -- Section titles (Requirements 6.1, 6.2)
    mainTitle = "PvP Tooltip info:",
    currentRatingTitle = "Current Rating",
    experienceTitle = "Character Experience", 
    seasonTitle = "Current Season"
}

-- Get display name for a game mode
function Config:GetDisplayName(gameMode)
    return self.DisplayNames[gameMode] or gameMode
end

-- Return the module for proper loading
return Config