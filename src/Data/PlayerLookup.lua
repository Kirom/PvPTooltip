-- PvPTooltip Player Lookup
-- Resolves a unit or "Name-Realm" string to PvP data from the database, with a
-- short-lived cache. Error isolation happens once at the tooltip-hook boundary
-- (EventManager), so this module is plain code.

local PlayerLookup = {}
PvPTooltip.PlayerLookup = PlayerLookup

-- Lookup cache for performance
local lookupCache = {}
local cacheTimeout = 300 -- 5 minutes

-- Sentinel for a cached "player not in DB" result. Storing plain nil would make
-- the entry indistinguishable from a cache miss, so misses would re-run the
-- full lookup on every hover.
local NO_DATA = {}

-- Initialize the player lookup module
function PlayerLookup:Initialize()
    if not PvPTooltip.DatabaseManager or not PvPTooltip.RealmResolver then
        PvPTooltip:Error("PlayerLookup requires DatabaseManager and RealmResolver")
        return false
    end
    PvPTooltip:Debug("PlayerLookup initialized")
    return true
end

-- Parse GUID to extract the realm (server) ID, the reliable region source.
-- GUID format: Player-[server_id]-[player_id]
function PlayerLookup:ParseGUID(guid)
    if not guid then
        return nil
    end

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

-- Extract name and normalized realm for a unit. Returns nil for unnamed units.
function PlayerLookup:GetUnitInfo(unitID)
    if not unitID then
        return nil
    end

    local unitName, unitRealm = UnitName(unitID)
    if not unitName then
        return nil
    end

    -- Realm is nil/empty for same-realm units.
    if not unitRealm or unitRealm == "" then
        unitRealm = GetRealmName() or "Unknown"
    end

    -- Strip a "-Realm" suffix from the name if present.
    local cleanName = string.gsub(unitName, "%-.*", "")
    if cleanName == "" then
        return nil
    end

    local normalizedRealm = PvPTooltip.RealmResolver:NormalizeRealmName(unitRealm)
    if not normalizedRealm then
        return nil
    end

    return {
        name = cleanName,
        realm = normalizedRealm,
        guidInfo = self:ParseGUID(UnitGUID(unitID)),
        unitID = unitID
    }
end

-- Look up player in database. No name/realm variation cascade: the DB realm
-- index is keyed by the same normalizer both ways, and character names are
-- stored exact-case, so variations could never produce an additional match.
function PlayerLookup:LookupPlayerInDatabase(playerName, realmName, region)
    if not playerName or not realmName or not region then
        return nil
    end
    if not (PvPTooltip.DatabaseManager and PvPTooltip.DatabaseManager:IsDataAvailable()) then
        PvPTooltip:Debug("Database not available for lookup")
        return nil
    end
    return PvPTooltip.DatabaseManager:GetPlayerData(playerName, realmName, region)
end

-- Main lookup function for unit-based queries.
function PlayerLookup:FindPlayerData(unitID)
    local unitInfo = self:GetUnitInfo(unitID)
    if not unitInfo then
        PvPTooltip:Debug("Could not extract unit info for: " .. tostring(unitID))
        return nil
    end

    local cacheKey = self:GenerateCacheKey(unitInfo.name, unitInfo.realm)
    local cachedData = self:GetFromCache(cacheKey)
    if cachedData then
        return cachedData ~= NO_DATA and cachedData or nil
    end

    -- Prefer the realm ID from the unit GUID (mapped via regionIDs), which is
    -- reliable; GetRegionForRealm falls back to the viewer's own region.
    local realmIdentifier = unitInfo.realm
    if unitInfo.guidInfo and unitInfo.guidInfo.serverID then
        realmIdentifier = unitInfo.guidInfo.serverID
    end
    local region = PvPTooltip.RealmResolver:GetRegionForRealm(realmIdentifier)

    local playerData = self:LookupPlayerInDatabase(unitInfo.name, unitInfo.realm, region)
    self:AddToCache(cacheKey, playerData)

    return playerData
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

    -- Check if cache entry is still valid
    if (GetTime() - cacheEntry.timestamp) > cacheTimeout then
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
        data = playerData == nil and NO_DATA or playerData,
        timestamp = GetTime()
    }
end

-- Check if player lookup is ready
function PlayerLookup:IsReady()
    return PvPTooltip.DatabaseManager and PvPTooltip.DatabaseManager:IsDataAvailable() and
           PvPTooltip.RealmResolver and PvPTooltip.RealmResolver:IsReady()
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
    local cachedData = self:GetFromCache(cacheKey)
    if cachedData then
        return cachedData ~= NO_DATA and cachedData or nil
    end

    local region = PvPTooltip.RealmResolver:GetRegionForRealm(cleanRealm)
    local playerData = self:LookupPlayerInDatabase(cleanName, cleanRealm, region)
    self:AddToCache(cacheKey, playerData)

    return playerData
end

-- Return the module for proper loading
return PlayerLookup
