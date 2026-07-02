-- RealmResolver.lua
-- Handles realm name normalization and region detection for PvP data lookup

-- Create the RealmResolver module
local RealmResolver = {}
PvPTooltip.RealmResolver = RealmResolver

-- Cache for normalized realm names to improve performance
local normalizedRealmCache = {}

-- Region mapping constants
local REGION_US = "us"
local REGION_EU = "eu"

-- Fallback region: the viewer's own. WoW is region-locked, so any player you
-- can see is in your region. GetCurrentRegion: 1=US, 2=KR, 3=EU, 4=TW, 5=CN.
local function viewerRegion()
    local region = GetCurrentRegion and GetCurrentRegion()
    if region == 1 then
        return REGION_US
    end
    return REGION_EU
end

-- Initialize the resolver. regionIDs is assigned by DatabaseManager:Initialize
-- (which runs after this); GetRegionForRealm checks it at call time anyway.
function RealmResolver:Initialize()
    PvPTooltip:Debug("RealmResolver initialized")
    return true
end

-- Normalize realm name by removing special characters and converting to lowercase
-- Handles variations like spaces, apostrophes, and accented characters
function RealmResolver:NormalizeRealmName(realmName)
    if not realmName or realmName == "" then
        return nil
    end
    
    -- Check cache first for performance
    if normalizedRealmCache[realmName] then
        return normalizedRealmCache[realmName]
    end
    
    local normalized = realmName
    
    -- Convert to lowercase
    normalized = string.lower(normalized)
    
    -- Remove spaces and replace with empty string for slug matching
    normalized = string.gsub(normalized, "%s+", "")
    
    -- Remove common special characters that might cause issues
    normalized = string.gsub(normalized, "[''`]", "")
    normalized = string.gsub(normalized, "[-]", "")
    
    -- Handle common character replacements for international realms
    local charReplacements = {
        ["à"] = "a", ["á"] = "a", ["â"] = "a", ["ã"] = "a", ["ä"] = "a", ["å"] = "a",
        ["è"] = "e", ["é"] = "e", ["ê"] = "e", ["ë"] = "e",
        ["ì"] = "i", ["í"] = "i", ["î"] = "i", ["ï"] = "i",
        ["ò"] = "o", ["ó"] = "o", ["ô"] = "o", ["õ"] = "o", ["ö"] = "o",
        ["ù"] = "u", ["ú"] = "u", ["û"] = "u", ["ü"] = "u",
        ["ç"] = "c", ["ñ"] = "n",
        ["ß"] = "ss"
    }
    
    for accented, replacement in pairs(charReplacements) do
        normalized = string.gsub(normalized, accented, replacement)
    end
    
    -- Cache the result
    normalizedRealmCache[realmName] = normalized
    
    return normalized
end

-- Determine the region (EU/US) for a given realm
-- Uses the region ID database to map realm IDs to regions
function RealmResolver:GetRegionForRealm(realmIdentifier)
    -- If it's a realm ID number, look it up directly
    if type(realmIdentifier) == "number" and PvPTooltip.regionIDs then
        local regionID = PvPTooltip.regionIDs[realmIdentifier]
        if regionID == 1 then
            return REGION_US
        elseif regionID == 3 then
            return REGION_EU
        end
    end

    -- Realm name (or unknown ID): region-locking means every visible player is
    -- in the viewer's own region, so that is the correct answer here.
    return viewerRegion()
end

-- Check if RealmResolver is ready to use
function RealmResolver:IsReady()
    -- Always return true for now - data will be loaded on demand
    return true
end

-- Return the module for proper loading
return RealmResolver