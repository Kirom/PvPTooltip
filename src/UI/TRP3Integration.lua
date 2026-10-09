-- PvPTooltip Total RP 3 Integration
-- When hovering a player with an RP profile, TRP3 shows its own tooltip
-- (TRP3_CharacterTooltip) and hides the GameTooltip, taking the PvP block with
-- it. Append the block to the bottom of TRP3's tooltip instead.

local TRP3Integration = {}
PvPTooltip.TRP3Integration = TRP3Integration

local hooked = false

-- AddOn_TotalRP3.Enums.UNIT_TYPE.CHARACTER. Companion (pet) profiles reuse the
-- same tooltip frame with a different targetMode.
local CHARACTER = "CHARACTER"

local LINE_SIDES = { "TextLeft", "TextRight" }

-- TRP3's body-text font size, so our lines match the rest of its tooltip.
-- getValue asserts on unknown keys (it's a TRP3 internal), hence the pcall.
local function trp3BodyFontSize()
    local config = TRP3_API and TRP3_API.configuration
    if not (config and config.getValue) then
        return nil
    end
    local ok, size = pcall(config.getValue, "tooltip_char_subSize")
    if ok and type(size) == "number" then
        return size
    end
    return nil
end

-- Whether TRP3 is about to hide the GameTooltip for this profile. Mirrors its
-- RegisterTooltip.lua show(): hidden when "hide original tooltip" is on, except
-- for ignored / mature-filtered profiles, which get a short notice shown next
-- to the GameTooltip instead.
local function trp3HidesGameTooltip(targetID)
    local tooltipAPI = TRP3_API.ui and TRP3_API.ui.tooltip
    if tooltipAPI and tooltipAPI.shouldHideGameTooltip and not tooltipAPI.shouldHideGameTooltip() then
        return false
    end
    local register = TRP3_API.register
    if register and register.isIDIgnored and register.isIDIgnored(targetID) then
        return false
    end
    if register and register.unitIDIsFilteredForMatureContent
        and register.unitIDIsFilteredForMatureContent(targetID) then
        return false
    end
    return true
end

-- Tooltip line fontstrings are reused across rebuilds, and TRP3 resizes the
-- ones it fills (name 16, notification icons 10, ...). Lines appended past its
-- content would keep whatever size an earlier, longer profile left there.
local function resetLineFonts(tooltip, firstLine)
    local file, height, flags = GameTooltipText:GetFont()
    height = trp3BodyFontSize() or height
    local name = tooltip:GetName()
    for i = firstLine, tooltip:NumLines() do
        for _, side in ipairs(LINE_SIDES) do
            local fontString = tooltip[side .. i] or _G[name .. side .. i]
            if fontString then
                fontString:SetFont(file, height, flags)
            end
        end
    end
end

-- Opt-out toggle in the settings panel (absent before first-run init -> enabled).
local function enabledInSettings()
    local s = PvPTooltipDB and PvPTooltipDB.settings
    return not s or s.showInTRP3 ~= false
end

-- TRP3 hides and re-shows its tooltip on every (re)build, so OnShow fires once
-- per build with fresh lines and up-to-date target fields.
local function onCharacterTooltipShow(tooltip)
    if not enabledInSettings() or tooltip.targetMode ~= CHARACTER then
        return
    end
    -- targetType is the unit token TRP3 built the tooltip for ("mouseover", ...).
    local unit, targetID = tooltip.targetType, tooltip.target
    if not unit or not targetID then
        return
    end
    if issecretvalue and (issecretvalue(unit) or issecretvalue(targetID)) then
        return
    end
    -- TRP3 builds its tooltip before hiding the GameTooltip. If the GameTooltip
    -- stays up, it already carries the PvP block.
    if GameTooltip:IsShown() and not trp3HidesGameTooltip(targetID) then
        return
    end
    if not PvPTooltip:IsReady() or not PvPTooltip.EventManager:ModifierAllows() then
        return
    end

    local firstLine = tooltip:NumLines() + 1
    if PvPTooltip.EventManager:EnhanceTooltipForUnit(tooltip, unit) then
        resetLineFonts(tooltip, firstLine)
        tooltip:Show() -- re-layout to fit the appended lines
    end
end

function TRP3Integration:Hook()
    if hooked or not TRP3_CharacterTooltip then
        return
    end
    -- pcall: an error here would propagate out of TRP3's tooltip:Show() and
    -- abort its tooltip build.
    TRP3_CharacterTooltip:HookScript("OnShow", function(tooltip)
        local ok, err = pcall(onCharacterTooltipShow, tooltip)
        if not ok then
            PvPTooltip:Debug("TRP3 tooltip error: " .. tostring(err) .. " - graceful degradation")
        end
    end)
    hooked = true
    PvPTooltip:Debug("TRP3 integration enabled")
end

-- Re-render TRP3's tooltip (modifier gate / settings changes). TRP3 rebuilds it
-- from its GameTooltip:SetUnit hook and hides the GameTooltip again - the same
-- path its own modifier-key handling uses.
function TRP3Integration:RefreshActiveTooltip()
    local tooltip = TRP3_CharacterTooltip
    if not (hooked and tooltip:IsShown() and tooltip.target and tooltip.targetMode == CHARACTER) then
        return
    end
    local unit = tooltip.targetType
    if not unit or (issecretvalue and issecretvalue(unit)) or not UnitExists(unit) then
        return
    end
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    GameTooltip:SetUnit(unit)
end

-- TRP3 isn't load-on-demand: by PLAYER_LOGIN (when modules initialize) it is
-- either loaded or absent until the next reload.
function TRP3Integration:IsAvailable()
    return C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("totalRP3") and true or false
end

-- Without TRP3, nothing is hooked or registered.
function TRP3Integration:Initialize()
    if self:IsAvailable() then
        self:Hook()
    end
end

return TRP3Integration
