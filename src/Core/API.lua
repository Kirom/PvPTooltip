-- PvPTooltip Public API
-- Stable read-only lookup into PvPTooltip's rating database for other addons.
-- Works even when the user turns PvPTooltip's own tooltip off (General >
-- "Enable PvPTooltip"): that toggle only gates rendering, not lookups.
--
-- Feature-detect:  if PvPTooltip and PvPTooltip.API and PvPTooltip.API.version >= 1 then ... end
--
-- Data caveats:
--   * allTimeBest is the highest rating PvPTooltip's data pipeline has OBSERVED
--     (peak kept across seasons), not Blizzard's true lifetime peak.
--   * Only characters with a rated game this season are in the database.
--   * Data is a snapshot from the last database refresh, not live.

local API = {}
PvPTooltip.API = API

-- Bump only on breaking changes to the functions or returned fields below.
API.version = 1

-- Accepted bracket names -> internal bracket keys (DatabaseManager output).
local BRACKETS = {
    ["2v2"] = "2v2",
    ["3v3"] = "3v3",
    rbg = "rbg",
    shuffle = "shuffle", ss = "shuffle",
    blitz = "blitz", btz = "blitz",
}

-- Fresh table per call so callers can't mutate PvPTooltip's lookup cache.
local function toPublic(e)
    return {
        current = e.currentRating,
        allTimeBest = e.personalBest,
        seasonBest = e.seasonBest,
        games = e.playedTotal,  -- games this season
        winRate = e.winRate,    -- percent, 0-100
        specId = e.shuffleSpecId, -- shuffle/blitz only, nil otherwise
    }
end

-- True once the region database is loaded and lookups can succeed.
function API.IsReady()
    return PvPTooltip.PlayerLookup and PvPTooltip.PlayerLookup:IsReady() and true or false
end

-- GetRating(name, realm, bracket[, specId])
--   name    "Name" or "Name-Realm" (character name in its exact in-game case)
--   realm   optional realm name; defaults to the realm in `name`, then your own
--   bracket "2v2" | "3v3" | "rbg" | "shuffle" (or "ss") | "blitz" (or "btz")
--   specId  optional specialization ID, shuffle/blitz only
-- Returns, or nil when not found / not ready / bad bracket:
--   2v2/3v3/rbg, or shuffle/blitz with specId:
--     { current, allTimeBest, seasonBest, games, winRate, specId }
--   shuffle/blitz without specId: a list of those, one per spec played.
function API.GetRating(name, realm, bracket, specId)
    local mode = BRACKETS[bracket]
    if not mode or type(name) ~= "string" or not API.IsReady() then
        return nil
    end
    -- Midnight 12.0: names from restricted contexts can be secret values.
    if issecretvalue and (issecretvalue(name) or issecretvalue(realm)) then
        return nil
    end

    local data = PvPTooltip.PlayerLookup:FindPlayerDataByName(name, realm)
    local value = data and data.brackets[mode]
    if not value then
        return nil
    end
    if mode ~= "shuffle" and mode ~= "blitz" then
        return toPublic(value)
    end

    -- Per-spec brackets: one entry, or an array of entries when several specs.
    local entries = value[1] and value or { value }
    if specId then
        for _, e in ipairs(entries) do
            if e.shuffleSpecId == specId then
                return toPublic(e)
            end
        end
        return nil
    end
    local list = {}
    for i, e in ipairs(entries) do
        list[i] = toPublic(e)
    end
    return list
end

return API
