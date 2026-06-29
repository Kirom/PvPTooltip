-- PvPTooltip Settings Panel
-- Registers an options panel in the native Blizzard Settings UI (AddOns tab).
-- All controls are backed directly by PvPTooltipDB / PvPTooltipDB.settings, so
-- changes persist with no extra plumbing. Tooltip rendering reads those same
-- keys (see TooltipRenderer / EventManager).

local SettingsPanel = {}
PvPTooltip.SettingsPanel = SettingsPanel

-- ponytail: assumes the retail 11.x/12.x 7-arg RegisterAddOnSetting signature
-- (category, variable, variableKey, variableTable, variableType, name, default).
-- If 12.0.7 ships a different arg order this call errors; the pcall around
-- SettingsPanel:Initialize in Addon.lua catches it and the addon runs without a
-- panel. Adjust the two register calls below if so.

function SettingsPanel:Initialize()
    if not Settings or not Settings.RegisterVerticalLayoutCategory
        or not Settings.RegisterAddOnSetting then
        PvPTooltip:Debug("Settings API unavailable - panel skipped")
        return
    end

    local boolType = (Settings.VarType and Settings.VarType.Boolean) or "boolean"
    local strType = (Settings.VarType and Settings.VarType.String) or "string"
    local s = PvPTooltipDB.settings

    local category, layout = Settings.RegisterVerticalLayoutCategory("PvPTooltip")

    local function header(text)
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
    end

    -- Register a boolean control backed by tbl[key]; re-render the live tooltip
    -- on change, then run an optional side effect.
    local function checkbox(tbl, key, name, tip, onChange)
        local variable = "PvPTooltip_" .. key
        local setting = Settings.RegisterAddOnSetting(
            category, variable, key, tbl, boolType, name, tbl[key])
        setting:SetValueChangedCallback(function(_, value)
            if onChange then onChange(value) end
            if PvPTooltip.EventManager and PvPTooltip.EventManager.RefreshActiveTooltip then
                PvPTooltip.EventManager:RefreshActiveTooltip()
            end
        end)
        Settings.CreateCheckbox(category, setting, tip)
        return setting
    end

    header("General")
    -- Master enable + debug live at the top level of PvPTooltipDB (slash commands
    -- read them), so bind directly there. SetEnabled also (re)registers events.
    checkbox(PvPTooltipDB, "enabled", "Enable PvPTooltip",
        "Show PvP ratings in unit tooltips.",
        function(value) PvPTooltip:SetEnabled(value) end)

    local modSetting = Settings.RegisterAddOnSetting(
        category, "PvPTooltip_modifier", "modifier", s, strType,
        "Show info when", s.modifier)
    modSetting:SetValueChangedCallback(function()
        if PvPTooltip.EventManager and PvPTooltip.EventManager.RefreshActiveTooltip then
            PvPTooltip.EventManager:RefreshActiveTooltip()
        end
    end)
    Settings.CreateDropdown(category, modSetting, function()
        local c = Settings.CreateControlTextContainer()
        c:Add("always", "Always")
        c:Add("shift", "Shift held")
        c:Add("ctrl", "Ctrl held")
        c:Add("alt", "Alt held")
        return c:GetData()
    end, "Only show PvP info while this key is held.")

    header("Sections")
    checkbox(s, "showRating", "Current Rating", "Show the Current Rating section.")
    checkbox(s, "showExperience", "Character Experience", "Show personal-best ratings.")
    checkbox(s, "showSeason", "Current Season", "Show games played and win rate.")

    header("Brackets")
    local brackets = {
        {"2v2", "2v2"}, {"3v3", "3v3"}, {"shuffle", "Solo Shuffle"},
        {"rbg", "Rated Battlegrounds"}, {"blitz", "Blitz"},
    }
    for _, b in ipairs(brackets) do
        local key, name = b[1], b[2]
        local variable = "PvPTooltip_bracket_" .. key
        local setting = Settings.RegisterAddOnSetting(
            category, variable, key, s.brackets, boolType, name, s.brackets[key])
        setting:SetValueChangedCallback(function()
            if PvPTooltip.EventManager and PvPTooltip.EventManager.RefreshActiveTooltip then
                PvPTooltip.EventManager:RefreshActiveTooltip()
            end
        end)
        Settings.CreateCheckbox(category, setting, "Show the " .. name .. " bracket.")
    end

    header("Display")
    checkbox(s, "showAllSpecs", "Show all specs for Shuffle/Blitz",
        "Off: show only the hovered unit's active spec.")
    checkbox(s, "hideEmpty", "Hide brackets with no games",
        "Hide a bracket entirely when there are 0 games.")
    checkbox(PvPTooltipDB, "debug", "Debug logging",
        "Print debug messages to chat.")

    Settings.RegisterAddOnCategory(category)
    self.categoryID = category:GetID()
    PvPTooltip:Debug("Settings panel registered")
end

-- Open the panel (bound to /pvpt config).
function SettingsPanel:Open()
    if self.categoryID and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(self.categoryID)
    else
        PvPTooltip:Print("Settings panel unavailable")
    end
end

return SettingsPanel
