-- PvPTooltip Player Lookup
-- Coordinates player data retrieval with proper fallback handling

local PlayerLookup = {}
PvPTooltip.PlayerLookup = PlayerLookup

-- Lookup cache for performance
local lookupCache = {}
local cacheTimeout = 300 -- 5 minutes

-- Initialize the player lookup module
function PlayerLookup:Initialize()
    PvPTooltip:Debug("PlayerLookup initializing...")
    
    -- Ensure dependencies are available
    if not PvPTooltip.DatabaseManager or not PvPTooltip.RealmResolver then
        PvPTooltip:Error("PlayerLookup requires DatabaseManager and RealmResolver")
        return false
    end
    
    -- Initialize without waiting for dependencies to be fully ready
    -- Dependencies will be checked at runtime when needed
    PvPTooltip:Debug("PlayerLookup initialized successfully (dependencies will be checked at runtime)")
    
    return true
end

-- Main lookup function for unit-based queries with comprehensive error handling
function PlayerLookup:FindPlayerData(unitID)
    -- Handle unit resolution failures gracefully
    if not unitID then
        PvPTooltip:Debug("No unitID provided to FindPlayerData - graceful degradation")
        return nil
    end
    
    -- Protect against unit resolution failures without breaking tooltips
    local success, unitInfo = pcall(function()
        return self:GetUnitInfo(unitID)
    end)
    
    if not success then
        PvPTooltip:Debug("Unit resolution failed for: " .. tostring(unitID) .. " - error: " .. tostring(unitInfo))
        return nil
    end
    
    if not unitInfo then
        PvPTooltip:Debug("Could not extract unit info for: " .. tostring(unitID) .. " - graceful degradation")
        return nil
    end
    
    -- Validate extracted unit information
    if not self:ValidateUnitInfo(unitInfo) then
        PvPTooltip:Debug("Invalid unit info extracted for: " .. tostring(unitID) .. " - graceful degradation")
        return nil
    end
    
    PvPTooltip:Debug(string.format("Looking up player: %s on %s", 
        unitInfo.name or "unknown", unitInfo.realm or "unknown"))
    
    -- Check cache first with error protection
    local success, cacheKey = pcall(function()
        return self:GenerateCacheKey(unitInfo.name, unitInfo.realm)
    end)
    
    if success and cacheKey then
        local cachedData = self:GetFromCache(cacheKey)
        if cachedData then
            PvPTooltip:Debug("Found cached data for " .. (unitInfo.name or "unknown"))
            return cachedData
        end
    else
        PvPTooltip:Debug("Error generating cache key: " .. tostring(cacheKey))
    end
    
    -- Determine region for the realm with error protection.
    -- Prefer the realm ID from the unit GUID (mapped via regionIDs) which is
    -- reliable; fall back to the realm name heuristic only if unavailable.
    local region = nil
    if PvPTooltip.RealmResolver and PvPTooltip.RealmResolver.GetRegionForRealm then
        local realmIdentifier = unitInfo.realm
        if unitInfo.guidInfo and unitInfo.guidInfo.serverID then
            realmIdentifier = unitInfo.guidInfo.serverID
        end

        local success, result = pcall(function()
            return PvPTooltip.RealmResolver:GetRegionForRealm(realmIdentifier)
        end)

        if success then
            region = result
        else
            PvPTooltip:Debug("Error determining region: " .. tostring(result))
        end
    end
    
    if not region then
        PvPTooltip:Debug("Could not determine region for realm: " .. (unitInfo.realm or "unknown") .. " - graceful degradation")
        return nil
    end
    
    -- Attempt to find player data using enhanced lookup with error protection
    local success, playerData = pcall(function()
        return self:EnhancedLookup(unitInfo.name, unitInfo.realm, region)
    end)

    if not success then
        PvPTooltip:Debug("Error during enhanced lookup: " .. tostring(playerData))
        playerData = nil
    end
    
    -- Cache the result (even if nil) to avoid repeated lookups, with error protection
    if cacheKey then
        local success, _ = pcall(function()
            self:AddToCache(cacheKey, playerData)
        end)
        
        if not success then
            PvPTooltip:Debug("Error caching lookup result")
        end
    end
    
    if playerData then
        PvPTooltip:Debug("Found PvP data for " .. (unitInfo.name or "unknown"))
    else
        PvPTooltip:Debug("No PvP data found for " .. (unitInfo.name or "unknown") .. " - graceful degradation")
    end
    
    return playerData
end

-- Validate unit information to prevent processing invalid data
function PlayerLookup:ValidateUnitInfo(unitInfo)
    if not unitInfo or type(unitInfo) ~= "table" then
        return false
    end
    
    -- Check required fields
    if not unitInfo.name or type(unitInfo.name) ~= "string" or unitInfo.name == "" then
        return false
    end
    
    if not unitInfo.realm or type(unitInfo.realm) ~= "string" or unitInfo.realm == "" then
        return false
    end
    
    -- Additional validation for suspicious data
    if string.len(unitInfo.name) > 50 or string.len(unitInfo.realm) > 100 then
        return false
    end
    
    return true
end

-- Extract name, realm, and other unit details from WoW API with comprehensive error handling
function PlayerLookup:GetUnitInfo(unitID)
    if not unitID then
        return nil
    end
    
    -- Protect against WoW API failures
    local success, unitName, unitRealm = pcall(UnitName, unitID)
    if not success or not unitName then
        PvPTooltip:Debug("UnitName API call failed for: " .. tostring(unitID))
        return nil
    end
    
    -- Handle cases where realm might be nil (same realm) with error protection
    if not unitRealm or unitRealm == "" then
        local success, realmName = pcall(GetRealmName)
        if success and realmName then
            unitRealm = realmName
        else
            PvPTooltip:Debug("GetRealmName API call failed, using fallback")
            unitRealm = "Unknown"
        end
    end
    
    -- Get additional unit information with error protection for each API call
    local unitGUID = nil
    local success, guid = pcall(UnitGUID, unitID)
    if success then
        unitGUID = guid
    end
    
    local unitClass = nil
    local success, class = pcall(UnitClass, unitID)
    if success then
        unitClass = class
    end
    
    local unitLevel = nil
    local success, level = pcall(UnitLevel, unitID)
    if success then
        unitLevel = level
    end
    
    local unitFaction = nil
    local success, faction = pcall(UnitFactionGroup, unitID)
    if success then
        unitFaction = faction
    end
    
    -- Clean up the name (remove server suffix if present) with error protection
    local cleanName = unitName
    local success, result = pcall(function()
        return string.gsub(unitName, "%-.*", "")
    end)
    if success then
        cleanName = result
    end
    
    -- Validate cleaned name
    if not cleanName or cleanName == "" then
        PvPTooltip:Debug("Invalid cleaned name for unit: " .. tostring(unitID))
        return nil
    end
    
    -- Normalize realm name using RealmResolver if available, with error protection
    local normalizedRealm = unitRealm
    if PvPTooltip.RealmResolver and PvPTooltip.RealmResolver.NormalizeRealmName then
        local success, result = pcall(function()
            return PvPTooltip.RealmResolver:NormalizeRealmName(unitRealm)
        end)
        if success and result then
            normalizedRealm = result
        else
            PvPTooltip:Debug("RealmResolver normalization failed, using fallback")
            normalizedRealm = self:FallbackNormalizeRealm(unitRealm)
        end
    else
        -- Fallback normalization if RealmResolver not ready
        normalizedRealm = self:FallbackNormalizeRealm(unitRealm)
    end
    
    -- Extract additional info from GUID if available with error protection
    local guidInfo = nil
    if unitGUID then
        local success, result = pcall(function()
            return self:ParseGUID(unitGUID)
        end)
        if success then
            guidInfo = result
        end
    end
    
    -- Final validation of extracted data
    if not cleanName or not normalizedRealm then
        PvPTooltip:Debug("Essential unit info missing after extraction")
        return nil
    end
    
    return {
        name = cleanName,
        fullName = unitName,
        realm = normalizedRealm,
        originalRealm = unitRealm,
        guid = unitGUID,
        guidInfo = guidInfo,
        class = unitClass,
        level = unitLevel,
        faction = unitFaction,
        unitID = unitID
    }
end

-- Fallback realm normalization when RealmResolver is not ready
function PlayerLookup:FallbackNormalizeRealm(realmName)
    if not realmName then
        return nil
    end
    
    -- Basic normalization
    local normalized = string.lower(realmName)
    normalized = string.gsub(normalized, "%s+", "-")
    normalized = string.gsub(normalized, "'", "")
    
    return normalized
end

-- Parse GUID to extract additional unit information
function PlayerLookup:ParseGUID(guid)
    if not guid then
        return nil
    end
    
    -- GUID format: Player-[server_id]-[player_id]
    local guidType, serverID, playerID = string.match(guid, "([^-]+)-([^-]+)-([^-]+)")
    
    if guidType == "Player" and serverID and playerID then
        return {
            type = guidType,
            serverID = tonumber(serverID),
            playerID = tonumber(playerID)
        }
    end
    
    return nil
end

-- Look up player in database with comprehensive error handling and graceful degradation
function PlayerLookup:LookupPlayerInDatabase(playerName, realmName, region)
    -- Validate input parameters
    if not playerName or type(playerName) ~= "string" or playerName == "" then
        PvPTooltip:Debug("Invalid playerName for database lookup: " .. tostring(playerName))
        return nil
    end
    
    if not realmName or type(realmName) ~= "string" or realmName == "" then
        PvPTooltip:Debug("Invalid realmName for database lookup: " .. tostring(realmName))
        return nil
    end
    
    if not region or type(region) ~= "string" or region == "" then
        PvPTooltip:Debug("Invalid region for database lookup: " .. tostring(region))
        return nil
    end
    
    -- Graceful degradation: ensure database manager exists
    if not PvPTooltip.DatabaseManager then
        PvPTooltip:Debug("DatabaseManager not available - graceful degradation")
        return nil
    end
    
    -- Graceful degradation: ensure database is available
    local success, isAvailable = pcall(function()
        return PvPTooltip.DatabaseManager:IsDataAvailable()
    end)
    
    if not success or not isAvailable then
        PvPTooltip:Debug("Database not available for lookup - graceful degradation")
        return nil
    end
    
    -- Attempt database lookup with comprehensive error protection
    local success, playerData = pcall(function()
        return PvPTooltip.DatabaseManager:GetPlayerData(playerName, realmName, region)
    end)
    
    if not success then
        PvPTooltip:Debug("Error during database lookup: " .. tostring(playerData) .. " - graceful degradation")
        return nil
    end
    
    -- Validate returned data structure
    if playerData and not self:ValidatePlayerDataStructure(playerData) then
        PvPTooltip:Debug("Invalid player data structure returned from database - graceful degradation")
        return nil
    end
    
    return playerData
end

-- Validate player data structure returned from database
function PlayerLookup:ValidatePlayerDataStructure(playerData)
    if not playerData or type(playerData) ~= "table" then
        return false
    end
    
    -- Check required fields
    if not playerData.name or type(playerData.name) ~= "string" then
        return false
    end
    
    if not playerData.realm or type(playerData.realm) ~= "string" then
        return false
    end
    
    if not playerData.region or type(playerData.region) ~= "string" then
        return false
    end
    
    if not playerData.brackets or type(playerData.brackets) ~= "table" then
        return false
    end
    
    -- Validate at least one bracket has meaningful data
    local hasValidData = false
    for gameMode, bracketData in pairs(playerData.brackets) do
        if type(bracketData) == "table" then
            -- Check if bracket has any meaningful data
            if (bracketData.currentRating and bracketData.currentRating > 0) or
               (bracketData.personalBest and bracketData.personalBest > 0) or
               (bracketData.playedTotal and bracketData.playedTotal > 0) then
                hasValidData = true
                break
            end
        end
    end
    
    return hasValidData
end

-- Handle cross-faction character lookups
function PlayerLookup:HandleCrossFactionData(playerName, realmName, region)
    if not playerName or not realmName or not region then
        return nil
    end
    
    -- Try different name variations that might exist in the database
    local nameVariations = self:GenerateNameVariations(playerName)
    
    for _, variation in ipairs(nameVariations) do
        local playerData = self:LookupPlayerInDatabase(variation, realmName, region)
        if playerData then
            PvPTooltip:Debug("Found cross-faction data using name variation: " .. variation)
            return playerData
        end
    end
    
    -- Try different realm name variations
    local realmVariations = self:GenerateRealmVariations(realmName)
    
    for _, realmVariation in ipairs(realmVariations) do
        local playerData = self:LookupPlayerInDatabase(playerName, realmVariation, region)
        if playerData then
            PvPTooltip:Debug("Found data using realm variation: " .. realmVariation)
            return playerData
        end
    end
    
    -- Try the opposite region as a fallback
    local oppositeRegion = (region == "eu") and "us" or "eu"
    local playerData = self:LookupPlayerInDatabase(playerName, realmName, oppositeRegion)
    if playerData then
        PvPTooltip:Debug("Found data in opposite region: " .. oppositeRegion)
        return playerData
    end
    
    return nil
end

-- Generate realm name variations for cross-realm lookups
function PlayerLookup:GenerateRealmVariations(realmName)
    if not realmName then
        return {}
    end
    
    local variations = {}
    
    -- Add original realm name
    table.insert(variations, realmName)
    
    -- Add normalized version
    local normalized = self:FallbackNormalizeRealm(realmName)
    if normalized and normalized ~= realmName then
        table.insert(variations, normalized)
    end
    
    -- Add version with spaces replaced by hyphens
    local withHyphens = string.gsub(realmName, "%s+", "-")
    if withHyphens ~= realmName then
        table.insert(variations, withHyphens)
    end
    
    -- Add version with hyphens replaced by spaces
    local withSpaces = string.gsub(realmName, "%-+", " ")
    if withSpaces ~= realmName then
        table.insert(variations, withSpaces)
    end
    
    -- Add version without special characters
    local withoutSpecial = string.gsub(realmName, "[^%w]", "")
    if withoutSpecial ~= realmName and withoutSpecial ~= "" then
        table.insert(variations, withoutSpecial)
    end
    
    return variations
end

-- Generate name variations for cross-faction lookups
function PlayerLookup:GenerateNameVariations(playerName)
    if not playerName then
        return {}
    end
    
    local variations = {}
    
    -- Add original name
    table.insert(variations, playerName)
    
    -- Add capitalized version
    local capitalized = string.upper(string.sub(playerName, 1, 1)) .. string.lower(string.sub(playerName, 2))
    if capitalized ~= playerName then
        table.insert(variations, capitalized)
    end
    
    -- Add all lowercase version
    local lowercase = string.lower(playerName)
    if lowercase ~= playerName then
        table.insert(variations, lowercase)
    end
    
    -- Add all uppercase version
    local uppercase = string.upper(playerName)
    if uppercase ~= playerName then
        table.insert(variations, uppercase)
    end
    
    -- Handle special characters that might be different
    local withoutSpecial = string.gsub(playerName, "[^%w]", "")
    if withoutSpecial ~= playerName and withoutSpecial ~= "" then
        table.insert(variations, withoutSpecial)
    end
    
    return variations
end

-- Generate cache key for lookup results
function PlayerLookup:GenerateCacheKey(playerName, realmName)
    if not playerName or not realmName then
        return nil
    end
    
    return string.lower(playerName) .. "@" .. string.lower(realmName)
end

-- Get data from lookup cache
function PlayerLookup:GetFromCache(cacheKey)
    if not cacheKey or not lookupCache[cacheKey] then
        return nil
    end
    
    local cacheEntry = lookupCache[cacheKey]
    local currentTime = GetTime()
    
    -- Check if cache entry is still valid
    if (currentTime - cacheEntry.timestamp) > cacheTimeout then
        lookupCache[cacheKey] = nil
        return nil
    end
    
    return cacheEntry.data
end

-- Add data to lookup cache
function PlayerLookup:AddToCache(cacheKey, playerData)
    if not cacheKey then
        return
    end
    
    lookupCache[cacheKey] = {
        data = playerData,
        timestamp = GetTime()
    }
end

-- Clear lookup cache
function PlayerLookup:ClearCache()
    lookupCache = {}
    PvPTooltip:Debug("Player lookup cache cleared")
end

-- Clean up expired cache entries
function PlayerLookup:CleanupCache()
    local currentTime = GetTime()
    local cleaned = 0
    
    for cacheKey, cacheEntry in pairs(lookupCache) do
        if (currentTime - cacheEntry.timestamp) > cacheTimeout then
            lookupCache[cacheKey] = nil
            cleaned = cleaned + 1
        end
    end
    
    if cleaned > 0 then
        PvPTooltip:Debug("Cleaned up " .. cleaned .. " expired lookup cache entries")
    end
end

-- Get cache statistics
function PlayerLookup:GetCacheStats()
    local totalEntries = 0
    local validEntries = 0
    local currentTime = GetTime()
    
    for cacheKey, cacheEntry in pairs(lookupCache) do
        totalEntries = totalEntries + 1
        if (currentTime - cacheEntry.timestamp) <= cacheTimeout then
            validEntries = validEntries + 1
        end
    end
    
    return {
        totalEntries = totalEntries,
        validEntries = validEntries,
        expiredEntries = totalEntries - validEntries,
        cacheTimeout = cacheTimeout
    }
end

-- Set cache timeout
function PlayerLookup:SetCacheTimeout(timeout)
    if timeout and timeout > 0 then
        cacheTimeout = timeout
        PvPTooltip:Debug("Lookup cache timeout set to " .. timeout .. " seconds")
    end
end

-- Handle connected realms for cross-realm lookups
function PlayerLookup:HandleConnectedRealms(playerName, realmName, region)
    if not playerName or not realmName or not region then
        return nil
    end
    
    -- Get connected realm information if RealmResolver is available
    if PvPTooltip.RealmResolver and PvPTooltip.RealmResolver.HandleConnectedRealms then
        local connectedRealm = PvPTooltip.RealmResolver:HandleConnectedRealms(realmName)
        if connectedRealm and connectedRealm ~= realmName then
            local playerData = self:LookupPlayerInDatabase(playerName, connectedRealm, region)
            if playerData then
                PvPTooltip:Debug("Found data on connected realm: " .. connectedRealm)
                return playerData
            end
        end
    end
    
    return nil
end

-- Enhanced lookup with all fallback methods
function PlayerLookup:EnhancedLookup(playerName, realmName, region)
    if not playerName or not realmName or not region then
        return nil
    end
    
    -- Try direct lookup first
    local playerData = self:LookupPlayerInDatabase(playerName, realmName, region)
    if playerData then
        return playerData
    end
    
    -- Try cross-faction variations
    playerData = self:HandleCrossFactionData(playerName, realmName, region)
    if playerData then
        return playerData
    end
    
    -- Try connected realms
    playerData = self:HandleConnectedRealms(playerName, realmName, region)
    if playerData then
        return playerData
    end
    
    return nil
end

-- Check if player lookup is ready
function PlayerLookup:IsReady()
    return PvPTooltip.DatabaseManager and PvPTooltip.DatabaseManager:IsDataAvailable() and
           PvPTooltip.RealmResolver and PvPTooltip.RealmResolver:IsReady()
end

-- Validate player data structure
function PlayerLookup:ValidatePlayerData(playerData)
    if not playerData then
        return false
    end
    
    -- Check required fields
    if not playerData.name or not playerData.realm or not playerData.region then
        return false
    end
    
    -- Check brackets structure
    if not playerData.brackets or type(playerData.brackets) ~= "table" then
        return false
    end
    
    -- Validate at least one bracket has data
    local hasData = false
    for gameMode, bracketData in pairs(playerData.brackets) do
        if type(bracketData) == "table" and 
           (bracketData.currentRating or bracketData.personalBest or bracketData.playedTotal) then
            hasData = true
            break
        end
    end
    
    return hasData
end

-- Get detailed lookup information for debugging
function PlayerLookup:GetLookupInfo(unitID)
    local unitInfo = self:GetUnitInfo(unitID)
    if not unitInfo then
        return nil
    end
    
    local region = nil
    if PvPTooltip.RealmResolver and PvPTooltip.RealmResolver.GetRegionForRealm then
        region = PvPTooltip.RealmResolver:GetRegionForRealm(unitInfo.realm)
    end
    
    local cacheKey = self:GenerateCacheKey(unitInfo.name, unitInfo.realm)
    local cachedData = self:GetFromCache(cacheKey)
    
    return {
        unitInfo = unitInfo,
        region = region,
        cacheKey = cacheKey,
        hasCachedData = cachedData ~= nil,
        isReady = self:IsReady(),
        databaseReady = PvPTooltip.DatabaseManager and PvPTooltip.DatabaseManager:IsDataAvailable(),
        realmResolverReady = PvPTooltip.RealmResolver and PvPTooltip.RealmResolver:IsReady()
    }
end

-- Test lookup functionality with a known player
function PlayerLookup:TestLookup(playerName, realmName, region)
    if not playerName or not realmName then
        PvPTooltip:Print("Usage: TestLookup(playerName, realmName, [region])")
        return nil
    end
    
    region = region or "eu"
    
    PvPTooltip:Print("Testing lookup for: " .. playerName .. " on " .. realmName .. " (" .. region .. ")")
    
    -- Test direct database lookup
    local directResult = self:LookupPlayerInDatabase(playerName, realmName, region)
    PvPTooltip:Print("Direct lookup: " .. (directResult and "Found" or "Not found"))
    
    -- Test enhanced lookup
    local enhancedResult = self:EnhancedLookup(playerName, realmName, region)
    PvPTooltip:Print("Enhanced lookup: " .. (enhancedResult and "Found" or "Not found"))
    
    -- Show cache status
    local cacheKey = self:GenerateCacheKey(playerName, realmName)
    local cachedData = self:GetFromCache(cacheKey)
    PvPTooltip:Print("Cache status: " .. (cachedData and "Cached" or "Not cached"))
    
    return enhancedResult
end

-- Get lookup statistics
function PlayerLookup:GetLookupStats()
    local cacheStats = self:GetCacheStats()
    local dbStats = PvPTooltip.DatabaseManager and PvPTooltip.DatabaseManager:GetCacheStats() or {}
    
    return {
        lookupCache = cacheStats,
        database = dbStats,
        isReady = self:IsReady(),
        dependencies = {
            databaseManager = PvPTooltip.DatabaseManager ~= nil,
            realmResolver = PvPTooltip.RealmResolver ~= nil,
            databaseReady = PvPTooltip.DatabaseManager and PvPTooltip.DatabaseManager:IsDataAvailable(),
            realmResolverReady = PvPTooltip.RealmResolver and PvPTooltip.RealmResolver:IsReady()
        }
    }
end

-- Split a "Name-Realm" string into name + realm. Realm falls back to realmHint,
-- then to the viewer's own realm. Mirrors the unit-lookup name handling but for
-- surfaces (LFG/Guild/Friends) that identify a player by string, not unitID.
function PlayerLookup:SplitNameRealm(fullName, realmHint)
    if type(fullName) ~= "string" or fullName == "" then
        return nil, nil
    end
    local name, realm = fullName, nil
    if string.find(fullName, "-", 1, true) then
        name, realm = strsplit("-", fullName, 2)
    end
    if not realm or realm == "" then
        if type(realmHint) == "string" and realmHint ~= "" then
            realm = realmHint
        else
            local ok, own = pcall(GetNormalizedRealmName)
            realm = (ok and own and own ~= "" and own) or GetRealmName()
        end
    end
    if not name or name == "" or not realm or realm == "" then
        return nil, nil
    end
    return name, realm
end

-- Name-based lookup parallel to FindPlayerData(unitID). Used by LFG/Guild/Friends
-- surfaces. `name` may be "Name-Realm"; `realm` is an optional hint. WoW is
-- region-locked, so region resolves from the realm name (no GUID needed).
function PlayerLookup:FindPlayerDataByName(name, realm)
    local cleanName, cleanRealm = self:SplitNameRealm(name, realm)
    if not cleanName or not cleanRealm then
        PvPTooltip:Debug("FindPlayerDataByName: unresolved name/realm from " .. tostring(name))
        return nil
    end

    local cacheKey = self:GenerateCacheKey(cleanName, cleanRealm)
    if cacheKey then
        local cachedData = self:GetFromCache(cacheKey)
        if cachedData then
            return cachedData
        end
    end

    local region = nil
    if PvPTooltip.RealmResolver and PvPTooltip.RealmResolver.GetRegionForRealm then
        local ok, result = pcall(function()
            return PvPTooltip.RealmResolver:GetRegionForRealm(cleanRealm)
        end)
        if ok then
            region = result
        end
    end
    if not region then
        PvPTooltip:Debug("FindPlayerDataByName: no region for realm " .. tostring(cleanRealm))
        return nil
    end

    local ok, playerData = pcall(function()
        return self:EnhancedLookup(cleanName, cleanRealm, region)
    end)
    if not ok then
        PvPTooltip:Debug("FindPlayerDataByName: lookup error " .. tostring(playerData))
        playerData = nil
    end

    if cacheKey then
        pcall(function()
            self:AddToCache(cacheKey, playerData)
        end)
    end
    return playerData
end

-- In-game self-check for the name-based path (no local Lua runner exists).
-- Run in WoW: /run PvPTooltip.PlayerLookup:TestLookupByName()
function PlayerLookup:TestLookupByName()
    local n, r = self:SplitNameRealm("Foo-Aerie Peak")
    assert(n == "Foo", "split name failed: " .. tostring(n))
    assert(r == "Aerie Peak", "split realm failed: " .. tostring(r))

    local n2, r2 = self:SplitNameRealm("Bar")
    assert(n2 == "Bar", "bare name failed: " .. tostring(n2))
    assert(r2 and r2 ~= "", "bare-name realm default failed: " .. tostring(r2))

    local n3 = self:SplitNameRealm("")
    assert(n3 == nil, "empty name should be nil")

    PvPTooltip:Print("TestLookupByName OK (own realm = " .. tostring(r2) .. ")")
    return true
end

-- Return the module for proper loading
return PlayerLookup