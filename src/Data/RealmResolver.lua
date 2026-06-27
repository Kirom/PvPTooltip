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

-- Default region fallback
local DEFAULT_REGION = REGION_EU

-- Initialize the resolver with database references
function RealmResolver:Initialize()
    PvPTooltip:Debug("RealmResolver initializing...")
    
    -- Ensure database modules are available
    if not PvPTooltip.realmSlugs then
        PvPTooltip:Debug("RealmResolver: Realm slugs database not loaded yet")
        return false
    end
    
    if not PvPTooltip.regionIDs then
        PvPTooltip:Debug("RealmResolver: Region IDs database not loaded yet")
        return false
    end
    
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

-- Get the standardized realm name from realm slug database
-- Returns the proper display name for a given realm identifier
function RealmResolver:GetRealmName(realmIdentifier)
    if not realmIdentifier then
        return nil
    end
    
    -- If it's a number, treat it as realm ID and look up in region database
    if type(realmIdentifier) == "number" then
        -- For realm IDs, we need additional logic to map to names
        -- This would require a reverse lookup table which isn't provided in current data
        return nil
    end
    
    -- Handle string realm names/slugs
    local realmStr = tostring(realmIdentifier)
    
    -- First try direct lookup in realm slugs
    if PvPTooltip.realmSlugs and PvPTooltip.realmSlugs[realmStr] then
        return PvPTooltip.realmSlugs[realmStr]
    end
    
    -- Try normalized version
    local normalized = self:NormalizeRealmName(realmStr)
    if normalized and PvPTooltip.realmSlugs then
        -- Search through realm slugs for a match
        for slug, displayName in pairs(PvPTooltip.realmSlugs) do
            local normalizedSlug = self:NormalizeRealmName(slug)
            if normalizedSlug == normalized then
                return displayName
            end
        end
    end
    
    -- If no match found, return the original identifier
    return realmStr
end

-- Determine the region (EU/US) for a given realm
-- Uses the region ID database to map realm IDs to regions
function RealmResolver:GetRegionForRealm(realmIdentifier)
    if not realmIdentifier then
        return DEFAULT_REGION
    end
    
    -- If it's a realm ID number, look it up directly
    if type(realmIdentifier) == "number" and PvPTooltip.regionIDs then
        local regionID = PvPTooltip.regionIDs[realmIdentifier]
        if regionID then
            -- Region mapping based on the database structure:
            -- 1 = US, 2 = KR, 3 = EU, 4 = TW, 5 = CN
            if regionID == 1 then
                return REGION_US
            elseif regionID == 3 then
                return REGION_EU
            else
                -- For other regions (KR, TW, CN), default to EU for now
                -- This could be extended in the future if needed
                return DEFAULT_REGION
            end
        end
    end
    
    -- For string realm names, we need to do a more complex lookup
    local realmName = self:GetRealmName(realmIdentifier)
    if realmName then
        -- Use heuristics based on realm name patterns for common cases
        local region = self:_GuessRegionFromRealmName(realmName)
        if region then
            return region
        end
    end
    
    -- Default fallback
    return DEFAULT_REGION
end

-- Internal method to guess region based on realm name patterns
-- This is a fallback when realm ID lookup isn't available
function RealmResolver:_GuessRegionFromRealmName(realmName)
    if not realmName then
        return nil
    end
    
    local lowerName = string.lower(realmName)
    
    -- Common US realm patterns
    local usPatterns = {
        "area 52", "mal'ganis", "tichondrius", "illidan", "stormrage",
        "emerald dream", "sargeras", "dalaran", "proudmoore", "whisperwind"
    }
    
    for _, pattern in ipairs(usPatterns) do
        if string.find(lowerName, pattern, 1, true) then
            return REGION_US
        end
    end
    
    -- Common EU realm patterns (including non-English names)
    local euPatterns = {
        "kazzak", "tarren mill", "stormscale", "draenor", "silvermoon",
        "outland", "twisting nether", "ragnaros", "archimonde", "hyjal",
        -- German realms
        "blackrock", "destromath", "frostmourne", "antonidas",
        -- French realms
        "chants", "conseil", "confrérie", "uldaman", "dalaran",
        -- Spanish realms
        "sanguino", "tyrande", "uldum", "colinas"
    }
    
    for _, pattern in ipairs(euPatterns) do
        if string.find(lowerName, pattern, 1, true) then
            return REGION_EU
        end
    end
    
    -- If no pattern matches, return nil to use default
    return nil
end

-- Resolve realm information for cross-realm player lookup
-- Returns normalized realm name and region for database queries
function RealmResolver:ResolveRealmInfo(realmIdentifier)
    local realmName = self:GetRealmName(realmIdentifier)
    local region = self:GetRegionForRealm(realmIdentifier)
    local normalizedName = self:NormalizeRealmName(realmName)
    
    return {
        originalName = realmIdentifier,
        displayName = realmName,
        normalizedName = normalizedName,
        region = region
    }
end

-- Handle special cases for connected realms and realm groups
-- Some realms share the same database entries
function RealmResolver:HandleConnectedRealms(realmName)
    if not realmName then
        return realmName
    end
    
    -- Define connected realm mappings
    -- These realms share player databases
    local connectedRealms = {
        -- Example connected realm groups (this would need to be populated with actual data)
        ["aegwynn"] = "aegwynn",
        ["bonechewer"] = "aegwynn", -- Example: if these are connected
        -- Add more connected realm mappings as needed
    }
    
    local normalized = self:NormalizeRealmName(realmName)
    if normalized and connectedRealms[normalized] then
        return connectedRealms[normalized]
    end
    
    return realmName
end

-- Validate that a realm exists in our database
function RealmResolver:IsValidRealm(realmIdentifier)
    local realmInfo = self:ResolveRealmInfo(realmIdentifier)
    return realmInfo and realmInfo.normalizedName ~= nil
end

-- Clear the normalization cache (useful for testing or memory management)
function RealmResolver:ClearCache()
    normalizedRealmCache = {}
end

-- Get statistics about cached entries (for debugging)
function RealmResolver:GetCacheStats()
    local count = 0
    for _ in pairs(normalizedRealmCache) do
        count = count + 1
    end
    
    return {
        cachedEntries = count,
        totalRealms = self:_CountTotalRealms()
    }
end

-- Internal method to count total realms in database
function RealmResolver:_CountTotalRealms()
    local count = 0
    if PvPTooltip.realmSlugs then
        for _ in pairs(PvPTooltip.realmSlugs) do
            count = count + 1
        end
    end
    return count
end

-- Check if RealmResolver is ready to use
function RealmResolver:IsReady()
    -- Always return true for now - data will be loaded on demand
    return true
end

-- Return the module for proper loading
return RealmResolver