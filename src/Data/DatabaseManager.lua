-- PvPTooltip Database Manager
-- Reads the generated compact PvP database (ns.pvpCharacters) and returns
-- player data normalized to the schema the renderer expects.
--
-- Generated DB shape (see PvP Tooltip scripts -> repositories.py):
--   ns.pvpCharacters[region][RealmDisplayName][CharName].brackets[bracket] = {
--       CR, TotBest, SeasBest, TotG, WR, [SSSpec]   -- POSITIONAL, no field names
--   }
--   bracket key is one of: "2v2", "3v3", "rbg", "ss", "btz"
--   Per-spec brackets (ss/btz) with several specs are instead an ARRAY of those
--   arrays, one per specialization: brackets["ss"] = { {CR,...,SSSpec}, {...} }.
--   Discriminate the two forms by data[1]: number = single, table = per-spec.

local DatabaseManager = {}
PvPTooltip.DatabaseManager = DatabaseManager

local databasesReady = false

-- Compact bracket keys (as emitted by the generator) -> names used by the
-- renderer / Config.GameModes.
local BRACKET_KEY_MAP = {
    ["2v2"] = "2v2",
    ["3v3"] = "3v3",
    ["rbg"] = "rbg",
    ["ss"] = "shuffle",
    ["btz"] = "blitz",
}

-- Lazily built per-region index: normalizedRealm -> actual DB realm key.
-- Lets us match a live realm name ("Aerie Peak") to the DB key ("AeriePeak"
-- or "Aerie Peak") regardless of spaces/case/punctuation.
local realmIndex = nil

local function getNamespace()
    return _G["PvPTooltipNamespace"]
end

local function normalizeRealm(realm)
    if not realm or realm == "" then
        return nil
    end
    if PvPTooltip.RealmResolver and PvPTooltip.RealmResolver.NormalizeRealmName then
        local ok, result = pcall(function()
            return PvPTooltip.RealmResolver:NormalizeRealmName(realm)
        end)
        if ok and result then
            return result
        end
    end
    -- Fallback normalization: lowercase, strip spaces/apostrophes/hyphens.
    local normalized = string.lower(realm)
    normalized = string.gsub(normalized, "[%s'`%-]", "")
    return normalized
end

-- Initialize the database manager
function DatabaseManager:Initialize()
    local ns = getNamespace()

    -- Expose DB references onto PvPTooltip for the other modules.
    if ns then
        PvPTooltip.realmSlugs = ns.realmSlugs
        PvPTooltip.regionIDs = ns.regionIDs
        PvPTooltip.pvpCharacters = ns.pvpCharacters
    end

    databasesReady = ns ~= nil and type(ns.pvpCharacters) == "table"
    realmIndex = nil -- force rebuild on next lookup

    if databasesReady then
        local eu = ns.pvpCharacters["eu"] and "ok" or "missing"
        local us = ns.pvpCharacters["us"] and "ok" or "missing"
        PvPTooltip:Debug("DatabaseManager initialized (eu=" .. eu .. ", us=" .. us .. ")")
    else
        PvPTooltip:Error("DatabaseManager: pvpCharacters database not found")
    end

    return databasesReady
end

-- Check if databases are loaded and ready
function DatabaseManager:IsDataAvailable()
    return databasesReady
end

-- Build (once) a normalized-realm lookup table for every region.
local function buildRealmIndex()
    realmIndex = {}
    local chars = PvPTooltip.pvpCharacters
    if type(chars) ~= "table" then
        return
    end
    for region, realms in pairs(chars) do
        if type(realms) == "table" then
            realmIndex[region] = {}
            for realmKey in pairs(realms) do
                local norm = normalizeRealm(realmKey)
                if norm then
                    realmIndex[region][norm] = realmKey
                end
            end
        end
    end
end

-- Resolve a (possibly normalized) realm name to the actual DB realm key.
local function resolveRealmKey(region, realmName)
    local regionData = PvPTooltip.pvpCharacters and PvPTooltip.pvpCharacters[region]
    if type(regionData) ~= "table" then
        return nil
    end
    -- Fast path: exact key already present.
    if regionData[realmName] then
        return realmName
    end
    if not realmIndex then
        buildRealmIndex()
    end
    local idx = realmIndex[region]
    if not idx then
        return nil
    end
    return idx[normalizeRealm(realmName)]
end

-- Convert a positional bracket array to the renderer's schema.
-- Fixed slot order: {CR, TotBest, SeasBest, TotG, WR[, SSSpec]}.
local function mapBracket(b)
    return {
        currentRating = b[1] or 0,
        personalBest = b[2] or 0,
        seasonBest = b[3] or 0,
        playedTotal = b[4] or 0,
        winRate = b[5] or 0,
        shuffleSpecId = b[6], -- only present for shuffle/blitz
    }
end

-- A bracket value is either a single positional array {CR,TotBest,...} or, for
-- per-spec brackets (shuffle/blitz with several specs), an array of those arrays.
-- Discriminate by data[1]: a table means the per-spec array form, a number means
-- a single positional bracket. Normalize to the renderer schema either way.
local function mapBracketValue(data)
    if type(data[1]) == "table" then
        local specs = {}
        for i = 1, #data do
            if type(data[i]) == "table" then
                specs[#specs + 1] = mapBracket(data[i])
            end
        end
        return specs
    end
    return mapBracket(data)
end

-- Retrieve player PvP data, normalized for the renderer.
-- Returns nil when the player is not in the database (graceful degradation).
function DatabaseManager:GetPlayerData(playerName, realmName, region)
    if not databasesReady then
        return nil
    end
    if type(playerName) ~= "string" or playerName == "" then
        return nil
    end
    if type(realmName) ~= "string" or realmName == "" then
        return nil
    end
    if type(region) ~= "string" or region == "" then
        return nil
    end

    region = string.lower(region)

    local realmKey = resolveRealmKey(region, realmName)
    if not realmKey then
        return nil
    end

    local entry = PvPTooltip.pvpCharacters[region][realmKey][playerName]
    if type(entry) ~= "table" or type(entry.brackets) ~= "table" then
        return nil
    end

    local brackets = {}
    for compactKey, data in pairs(entry.brackets) do
        if type(data) == "table" then
            local mode = BRACKET_KEY_MAP[compactKey] or compactKey
            brackets[mode] = mapBracketValue(data)
        end
    end

    return {
        name = playerName,
        realm = realmKey,
        region = region,
        brackets = brackets,
    }
end

-- Normalize realm name (kept for callers that expect it on the manager).
function DatabaseManager:NormalizeRealmName(realmName)
    return normalizeRealm(realmName)
end

-- Search players by partial name (debugging helper).
function DatabaseManager:SearchPlayers(partialName, region, maxResults)
    if not databasesReady or not partialName then
        return {}
    end
    maxResults = maxResults or 10
    partialName = string.lower(partialName)
    local results = {}
    local searchRegions = region and { region } or { "eu", "us" }

    for _, searchRegion in ipairs(searchRegions) do
        local regionData = PvPTooltip.pvpCharacters[searchRegion]
        if type(regionData) == "table" then
            for realmKey, realmData in pairs(regionData) do
                for playerName in pairs(realmData) do
                    if string.find(string.lower(playerName), partialName, 1, true) then
                        table.insert(results, { name = playerName, realm = realmKey, region = searchRegion })
                        if #results >= maxResults then
                            return results
                        end
                    end
                end
            end
        end
    end

    return results
end

-- Get cache statistics (counts entries in the loaded DB).
function DatabaseManager:GetCacheStats()
    local euEntries, usEntries = 0, 0
    if databasesReady then
        for region, regionData in pairs(PvPTooltip.pvpCharacters) do
            local count = 0
            for _, realmData in pairs(regionData) do
                for _ in pairs(realmData) do
                    count = count + 1
                end
            end
            if region == "eu" then
                euEntries = count
            elseif region == "us" then
                usEntries = count
            end
        end
    end
    return {
        totalEntries = euEntries + usEntries,
        euEntries = euEntries,
        usEntries = usEntries,
        loaded = databasesReady,
    }
end

-- Return the module for proper loading
return DatabaseManager
