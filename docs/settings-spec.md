# PvPTooltip — In-Game Settings Spec

Native Blizzard **Settings API** (the AddOns tab in the game Options window,
`Settings.RegisterVerticalLayoutCategory`). No Ace3, no custom frame. Reasons:
ships with WoW 12.0.7, matches every other panel the player already knows,
free SavedVariables persistence pattern, search-indexed by Blizzard.

## Scope

Expose only toggles that map to render code that **already exists**. No color
pickers, no font controls, no layout editor (YAGNI — add later if asked). Every
setting below changes a branch already in `TooltipRenderer`/`EventManager`.

## SavedVariables

Add a `settings` sub-table to `PvPTooltipDB` (keep existing `enabled`/`debug`).
Defaults applied in `PvPTooltip:Initialize` first-run block (Addon.lua:42).

```lua
PvPTooltipDB.settings = {
    enabled          = true,    -- master (mirror of existing PvPTooltipDB.enabled)
    modifier         = "always",-- "always" | "shift" | "ctrl" | "alt"
    showRating       = true,    -- "Current Rating" section
    showExperience   = true,    -- "Character Experience" section
    showSeason       = true,    -- "Current Season" section
    brackets = {                -- per-bracket visibility
        ["2v2"] = true, ["3v3"] = true, ["shuffle"] = true,
        ["rbg"] = true, ["blitz"] = true,
    },
    showAllSpecs     = true,    -- shuffle/blitz: all specs vs only hovered spec
    hideEmpty        = false,   -- hide brackets with 0 games / 0 rating
    debug            = false,   -- mirror of existing PvPTooltipDB.debug
}
```

`enabled`/`debug` already live at the top level — keep those as the source of
truth and have the settings panel read/write them directly so old behaviour and
slash commands stay valid. The rest are new keys.

## Panel layout (UX)

Category **"PvPTooltip"**, vertical layout, section headers between groups:

```
PvPTooltip
─────────────────────────────────────────────
 General
   [x] Enable PvPTooltip
   Show info when:   [ Always ▾ ]      (Always / Shift / Ctrl / Alt held)
─────────────────────────────────────────────
 Sections
   [x] Current Rating
   [x] Character Experience
   [x] Current Season (games & win rate)
─────────────────────────────────────────────
 Brackets
   [x] 2v2
   [x] 3v3
   [x] Solo Shuffle
   [x] Rated Battlegrounds
   [x] Blitz
─────────────────────────────────────────────
 Display
   [x] Show all specs for Shuffle/Blitz   (off → only the hovered unit's spec)
   [ ] Hide brackets with no games
   [ ] Debug logging
```

UX notes:
- **Modifier dropdown** is the headline feature — tooltip clutter is the #1
  complaint for data-heavy tooltip addons. "Shift" lets the player keep clean
  tooltips and reveal PvP data on demand.
- Each checkbox gets a Blizzard tooltip string (the `tooltip` arg) explaining
  what it does, e.g. "Hide a bracket entirely when the player has 0 games."
- Disabling the master checkbox should visually do nothing else fancy — the
  existing `IsReady()` gate already skips enhancement when disabled.

## New file: `src/UI/SettingsPanel.lua`

Loaded **after** Config and before/with EventManager in `PvPTooltip.toc`
(needs Config for display names; standalone otherwise). Builds the panel on
`Initialize`.

```lua
local SettingsPanel = {}
PvPTooltip.SettingsPanel = SettingsPanel

-- NOTE: Settings.RegisterAddOnSetting signature shifted across 11.x→12.x.
-- Verify against 12.0.7 before coding. Current retail form:
--   Settings.RegisterAddOnSetting(category, variable, variableKey,
--       variableTable, variableType, name, defaultValue)
-- If 12.0.7 uses the older 5-arg form, adapt the helper below — only this
-- one call site changes.

function SettingsPanel:Initialize()
    if not Settings or not Settings.RegisterVerticalLayoutCategory then
        PvPTooltip:Debug("Settings API unavailable — panel skipped")
        return
    end
    local s = PvPTooltipDB.settings
    local category, layout = Settings.RegisterVerticalLayoutCategory("PvPTooltip")

    local function header(text)
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
    end

    -- Backs a boolean key in PvPTooltipDB.settings, fires re-render on change.
    local function checkbox(key, name, tip)
        local setting = Settings.RegisterAddOnSetting(
            category, "PvPTooltip_" .. key, key, s,
            Settings.VarType.Boolean, name, s[key])
        setting:SetValueChangedCallback(function() PvPTooltip:RefreshActiveTooltip() end)
        Settings.CreateCheckbox(category, setting, tip)
        return setting
    end

    header("General")
    -- Master maps to top-level PvPTooltipDB.enabled via SetEnabled, not s.enabled.
    -- Use a proxy setting with explicit get/set (Settings.CreateProxySetting or a
    -- GetValue/SetValue pair) so /pvpt enable|disable and the checkbox agree.
    -- modifier dropdown:
    local modSetting = Settings.RegisterAddOnSetting(
        category, "PvPTooltip_modifier", "modifier", s,
        Settings.VarType.String, "Show info when", s.modifier)
    local function modOptions()
        local c = Settings.CreateControlTextContainer()
        c:Add("always", "Always")
        c:Add("shift",  "Shift held")
        c:Add("ctrl",   "Ctrl held")
        c:Add("alt",    "Alt held")
        return c:GetData()
    end
    Settings.CreateDropdown(category, modSetting, modOptions,
        "Only show PvP info while this key is held.")

    header("Sections")
    checkbox("showRating",     "Current Rating",       "Show the Current Rating section.")
    checkbox("showExperience", "Character Experience", "Show personal-best ratings.")
    checkbox("showSeason",     "Current Season",       "Show games played and win rate.")

    header("Brackets")
    -- brackets is a nested table; register each key against s.brackets.
    local labels = {
        {"2v2","2v2"}, {"3v3","3v3"}, {"shuffle","Solo Shuffle"},
        {"rbg","Rated Battlegrounds"}, {"blitz","Blitz"},
    }
    for _, b in ipairs(labels) do
        local key, name = b[1], b[2]
        local setting = Settings.RegisterAddOnSetting(
            category, "PvPTooltip_bracket_" .. key, key, s.brackets,
            Settings.VarType.Boolean, name, s.brackets[key])
        setting:SetValueChangedCallback(function() PvPTooltip:RefreshActiveTooltip() end)
        Settings.CreateCheckbox(category, setting, "Show the " .. name .. " bracket.")
    end

    header("Display")
    checkbox("showAllSpecs", "Show all specs for Shuffle/Blitz",
        "Off: show only the hovered unit's active spec.")
    checkbox("hideEmpty", "Hide brackets with no games",
        "Hide a bracket entirely when there are 0 games.")
    checkbox("debug", "Debug logging", "Print debug messages to chat.")

    Settings.RegisterAddOnCategory(category)
    self.categoryID = category:GetID()
    PvPTooltip:Debug("Settings panel registered")
end

function SettingsPanel:Open()
    if self.categoryID then Settings.OpenToCategory(self.categoryID) end
end
```

`RefreshActiveTooltip` (new, Addon.lua or EventManager): if `GameTooltip` is
shown over a unit, re-run `OnUnitTooltip(GameTooltip)` so toggles preview live.
Cheap; `ponytail:` one-liner — if no unit shown, no-op.

## Wiring into existing render code

All edits are guard clauses around code that already runs.

1. **Modifier gate** — `EventManager:OnUnitTooltip` (EventManager.lua:40), after
   the `IsReady` check:
   ```lua
   local mod = PvPTooltipDB.settings and PvPTooltipDB.settings.modifier or "always"
   if (mod == "shift" and not IsShiftKeyDown())
   or (mod == "ctrl" and not IsControlKeyDown())
   or (mod == "alt"  and not IsAltKeyDown()) then
       return
   end
   ```

2. **Section toggles** — `TooltipRenderer:EnhanceTooltip` (TooltipRenderer.lua:59),
   gate each Format call:
   ```lua
   local s = PvPTooltipDB.settings
   if not s or s.showRating     then self:FormatRatingSection(...) end
   if not s or s.showExperience then self:FormatExperienceSection(...) end
   if not s or s.showSeason     then self:FormatSeasonSection(...) end
   ```
   (`not s` fallback = show everything if settings missing — safe default.)

3. **Bracket toggles** — the three `for _, gameMode in ipairs(gameModes)` loops
   (lines 204, 273, 342) skip a disabled bracket:
   ```lua
   if s and s.brackets and s.brackets[gameMode] == false then goto continue end
   ```
   (or wrap the body in `if enabled then ... end` — no `goto` needed). Best:
   factor the shared per-mode loop into one helper to avoid editing it 3×.
   **Altitude note:** the 3 Format functions are near-identical; consider a
   single `RenderBracketSection(tooltip, brackets, currentSpec, valueFn, header)`
   that takes the per-entry value extractor. Optional but kills the bracket/spec
   filter triplication.

4. **Hide-empty** — in each loop, the `#entries == 0` branch currently emits a
   `0` line; when `hideEmpty`, skip instead of emitting. Also skip per-entry
   lines whose value is 0 for that section.

5. **Show-all-specs** — in the per-entry loop, when `not showAllSpecs` and the
   entry has a `shuffleSpecId`, render only the entry whose `shuffleSpecId ==
   currentSpec`; if `currentSpec` is nil (no inspect data), fall back to showing
   all (otherwise the player sees nothing).

## Slash command

Add to `SlashCmdList["PVPTOOLTIP"]` (Addon.lua:190):
```lua
elseif command == "config" or command == "options" or command == "settings" then
    if PvPTooltip.SettingsPanel then PvPTooltip.SettingsPanel:Open() end
```
Add to the help block + advertise `/pvpt config`. Bare `/pvpt` with no arg could
also open the panel (common convention) — decide during impl.

## TOC

Add `src/UI/SettingsPanel.lua` after `Config.lua`, before `EventManager.lua`.

## Out of scope (deliberately skipped)

- Color / font / spacing customization — no existing render hook, big surface.
  Add when a user actually asks.
- Profiles / per-character settings — single global config is enough.
- Minimap button — `/pvpt config` + Options panel cover access.

## Test

`Settings` API can't run under luacheck, so: one `__main__`-style in-game smoke
path is the test — `/pvpt config` opens panel, toggle each box, hover a unit,
confirm sections/brackets appear/disappear and modifier gate works. No unit-test
framework in this addon. Keep logic testable by putting the *filter decisions*
(should-show-bracket, should-show-section) in small pure helpers if practical.
```
