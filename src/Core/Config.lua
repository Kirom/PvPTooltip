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

-- Get display name for a game mode
function Config:GetDisplayName(gameMode)
    return self.DisplayNames[gameMode] or gameMode
end

-- Return the module for proper loading
return Config