-- PvPTooltip Settings Panel
-- Registers an options panel in the native Blizzard Settings UI (AddOns tab).
-- All controls are backed directly by PvPTooltipDB / PvPTooltipDB.settings, so
-- changes persist with no extra plumbing. Tooltip rendering reads those same
-- keys (see TooltipRenderer / EventManager).

local SettingsPanel = {}
PvPTooltip.SettingsPanel = SettingsPanel

-- Uses the retail 11.x/12.x 7-arg RegisterAddOnSetting signature
-- (category, variable, variableKey, variableTable, variableType, name, default).
-- A different arg order would error; the pcall around SettingsPanel:Initialize
-- in Addon.lua catches it and the addon runs without a panel.

-- Sample player covering every bracket (incl. per-spec shuffle/blitz) so the
-- preview exercises all toggles. SAMPLE_SPEC marks the "hovered" active spec.
local SAMPLE_SPEC = 270
local SAMPLE = {
    name = "Preview",
    realm = "preview-realm",
    region = "eu",
    brackets = {
        ["2v2"]     = { currentRating = 2150, personalBest = 2400, playedTotal = 85, winRate = 65.5 },
        ["3v3"]     = { currentRating = 1950, personalBest = 2100, playedTotal = 42, winRate = 52.4 },
        -- Per-spec brackets: array form so the preview shows multiple spec rows.
        ["shuffle"] = {
            { currentRating = 2300, personalBest = 2450, playedTotal = 120, winRate = 58.3, shuffleSpecId = 270 },
            { currentRating = 2080, personalBest = 2210, playedTotal = 64, winRate = 54.0, shuffleSpecId = 269 },
            { currentRating = 1875, personalBest = 1990, playedTotal = 30, winRate = 50.0, shuffleSpecId = 268 },
        },
        ["rbg"]     = { currentRating = 1800, personalBest = 2000, playedTotal = 25, winRate = 72.0 },
        ["blitz"]   = {
            { currentRating = 1650, personalBest = 1720, playedTotal = 40, winRate = 55.0, shuffleSpecId = 270 },
            { currentRating = 0, personalBest = 1480, playedTotal = 0, winRate = 0.0, shuffleSpecId = 269 },
        },
    },
}

-- (Re)draw the preview tooltip with sample data through the real renderer, so it
-- reflects the current settings exactly.
function SettingsPanel:RefreshPreview()
    if not self.preview then
        local tt = CreateFrame("GameTooltip", "PvPTooltipPreviewTooltip", UIParent, "GameTooltipTemplate")
        -- Above the Settings window (DIALOG strata) and clamped on-screen.
        tt:SetFrameStrata("TOOLTIP")
        tt:SetClampedToScreen(true)
        self.preview = tt
    end
    local tt = self.preview
    local panel = _G.SettingsPanel
    tt:SetOwner(panel or UIParent, "ANCHOR_NONE")
    tt:ClearAllPoints()
    if panel and panel:IsShown() then
        tt:SetParent(panel)
        tt:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -60, 80)
    else
        tt:SetParent(UIParent)
        tt:SetPoint("CENTER", UIParent, "CENTER")
    end
    tt:ClearLines()
    tt:AddLine("PvPTooltip Preview", 1, 1, 1)
    if PvPTooltip.TooltipRenderer and PvPTooltip.TooltipRenderer.EnhanceTooltip then
        PvPTooltip.TooltipRenderer:EnhanceTooltip(tt, SAMPLE, SAMPLE_SPEC)
    end
    tt:Show()

    if panel and panel:IsShown() then
        if not self.credit then
            local fs = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            fs:SetTextColor(0.6, 0.6, 0.6)
            fs:SetText("Made by Kirom")
            self.credit = fs
        end
        self.credit:ClearAllPoints()
        self.credit:SetPoint("TOPRIGHT", tt, "BOTTOMRIGHT", 0, -4)
        self.credit:Show()
    end
end

function SettingsPanel:HidePreview()
    if self.preview then
        self.preview:Hide()
    end
    if self.credit then
        self.credit:Hide()
    end
end

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

    -- A setting changed: re-render the live unit tooltip (no-op if none hovered)
    -- and the settings preview (only while it's visible).
    local function onSettingChanged()
        if PvPTooltip.EventManager and PvPTooltip.EventManager.RefreshActiveTooltip then
            PvPTooltip.EventManager:RefreshActiveTooltip()
        end
        if self.preview and self.preview:IsShown() then
            self:RefreshPreview()
        end
    end

    local function checkbox(tbl, key, name, tip, onChange)
        local variable = "PvPTooltip_" .. key
        local setting = Settings.RegisterAddOnSetting(
            category, variable, key, tbl, boolType, name, tbl[key])
        setting:SetValueChangedCallback(function(_, value)
            if onChange then onChange(value) end
            onSettingChanged()
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
    modSetting:SetValueChangedCallback(onSettingChanged)
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
        setting:SetValueChangedCallback(onSettingChanged)
        Settings.CreateCheckbox(category, setting, "Show the " .. name .. " bracket.")
    end

    header("Display")
    checkbox(s, "showAllSpecs", "Show all specs for Shuffle/Blitz",
        "Off: show only the hovered unit's active spec.")
    checkbox(s, "hideEmpty", "Hide brackets with no games",
        "Hide a bracket entirely when there are 0 games.")
    checkbox(PvPTooltipDB, "debug", "Debug logging",
        "Print debug messages to chat.")

    -- Region data add-ons (PvPTooltip_DataEU/US) are toggled in the ESC > AddOns
    -- list, RaiderIO-style — not here. Addon.lua auto-disables the foreign region.

    Settings.RegisterAddOnCategory(category)
    self.categoryID = category:GetID()
    self.category = category

    -- The Settings UI (SettingsPanel frame) is load-on-demand, so it's usually
    -- absent at login. Wire the preview hooks once Blizzard_Settings loads, which
    -- covers opening via ESC > Options just as well as /pvpt config (where Open
    -- also calls EnsureHooks). Runs immediately if already loaded.
    if EventUtil and EventUtil.ContinueOnAddOnLoaded then
        EventUtil.ContinueOnAddOnLoaded("Blizzard_Settings", function() self:EnsureHooks() end)
    else
        self:EnsureHooks()
    end
    PvPTooltip:Debug("Settings panel registered")
end

-- Wire preview show/hide to the Settings window. Idempotent.
function SettingsPanel:EnsureHooks()
    if self.hooked then
        return
    end
    local panel = _G.SettingsPanel
    if not panel then
        return
    end

    -- Render once when our page becomes current, hide otherwise.
    local function evaluate()
        local current = panel.GetCurrentCategory and panel:GetCurrentCategory()
        local id = current and current.GetID and current:GetID()
        local onOurPage = panel:IsShown() and id == self.categoryID
        if onOurPage then
            if not (self.preview and self.preview:IsShown()) then
                self:RefreshPreview()
            end
        else
            self:HidePreview()
        end
    end

    -- Poll the current category on a throttled OnUpdate. SelectCategory doesn't
    -- fire on the AddOns-list click in 12.0.7, and OnShow fires before the
    -- category is current; polling at 0.15s (only while shown) catches the switch.
    panel:HookScript("OnUpdate", function(_, elapsed)
        self._acc = (self._acc or 0) + elapsed
        if self._acc < 0.15 then
            return
        end
        self._acc = 0
        evaluate()
    end)
    panel:HookScript("OnHide", function() self:HidePreview() end)
    self.hooked = true
    evaluate() -- handle the panel already being open on our category
end

-- Open the panel (bound to /pvpt config).
function SettingsPanel:Open()
    if not (self.categoryID and Settings and Settings.OpenToCategory) then
        PvPTooltip:Print("Settings panel unavailable")
        return
    end
    Settings.OpenToCategory(self.categoryID)
    self:EnsureHooks()
    self:RefreshPreview()
end

return SettingsPanel
