-- PvPTooltip Tooltip Renderer
-- Implements PvP information display and formatting for game tooltips.
-- Picks the layout from settings and renders it; the Classic layout lives here,
-- the others in src/UI/Layouts/*.lua. Also holds the row / column helpers the
-- layouts share.

local TooltipRenderer = {}
PvPTooltip.TooltipRenderer = TooltipRenderer

-- Layout renderers keyed by the settings value (PvPTooltipDB.settings.layout).
-- Each is { Render = function(renderer, tooltip, playerData, currentSpec) }
-- returning true iff it added lines. Layout files register themselves here.
TooltipRenderer.layouts = {}

-- Initialize the tooltip renderer module
function TooltipRenderer:Initialize()
    PvPTooltip:Debug("TooltipRenderer module initialized")
end

-- Spec name and icon by specialization id (e.g. 270 -> Mistweaver). Static
-- game data, so successful lookups are cached; nil when unavailable.
local specCache = {}
local function resolveSpecInfo(specId)
    if not specId then
        return nil
    end
    local cached = specCache[specId]
    if cached then
        return cached
    end
    local ok, _, name, _, icon = pcall(GetSpecializationInfoByID, specId)
    if ok and name and name ~= "" then
        cached = { name = name, icon = icon }
        specCache[specId] = cached
        return cached
    end
    return nil
end

-- Resolve a specialization id to its localized name.
-- Returns nil when unavailable so callers can fall back gracefully.
local function resolveSpecName(specId)
    local spec = resolveSpecInfo(specId)
    return spec and spec.name
end

-- Normalize a bracket value to a list of entries. Per-spec brackets (shuffle/blitz
-- with several specs) arrive as an array; single brackets as one table.
local function getBracketEntries(bracketData)
    if type(bracketData) ~= "table" then
        return {}
    end
    if bracketData[1] ~= nil then
        return bracketData
    end
    return { bracketData }
end

-- User settings (nil before first-run init → callers treat absence as "show all").
local function settings()
    return PvPTooltipDB and PvPTooltipDB.settings
end

-- A bracket is shown unless explicitly toggled off.
local function bracketEnabled(gameMode)
    local s = settings()
    if not s or not s.brackets then
        return true
    end
    return s.brackets[gameMode] ~= false
end

-- Per-spec entries (shuffle/blitz) honor the "show all specs" toggle. When off we
-- show only the hovered unit's active spec; if that's unknown, show all (else the
-- player would see nothing). Non-spec entries always pass.
local function specVisible(entry, currentSpec)
    local s = settings()
    if not s or s.showAllSpecs ~= false then
        return true
    end
    if not entry.shuffleSpecId or not currentSpec then
        return true
    end
    return entry.shuffleSpecId == currentSpec
end

-- Render a subsection header (gold).
local function addHeader(tooltip, text)
    tooltip:AddLine(PvPTooltip.ColorUtils:FormatSubsectionHeader(text))
end

-- The layout chosen in settings; unknown values fall back to the default.
function TooltipRenderer:GetLayout()
    local s = settings()
    local key = s and s.layout
    if key and self.layouts[key] then
        return self.layouts[key]
    end
    return self.layouts[PvPTooltip.Config.DefaultLayout] or self.layouts.classic
end

-- Main rendering function - enhances tooltip with PvP information with comprehensive error handling
function TooltipRenderer:EnhanceTooltip(tooltip, playerData, currentSpec)
    -- Handle missing data gracefully without breaking tooltips
    if not tooltip then
        PvPTooltip:Debug("No tooltip provided to EnhanceTooltip - graceful degradation")
        return false
    end

    if not playerData then
        PvPTooltip:Debug("No player data provided to EnhanceTooltip - graceful degradation")
        return false
    end

    -- Validate player data structure with graceful degradation
    if not self:ValidatePlayerData(playerData) then
        PvPTooltip:Debug("Invalid player data structure - graceful degradation")
        return false
    end

    PvPTooltip:Debug(string.format("Enhancing tooltip for player: %s", playerData.name or "unknown"))

    -- Single error boundary for rendering: callers hover-path (EventManager) and
    -- settings preview both come through here, so one pcall protects both.
    local layout = self:GetLayout()
    local success, result = pcall(layout.Render, self, tooltip, playerData, currentSpec)

    if not success then
        PvPTooltip:Debug("Error during tooltip enhancement: " .. tostring(result) .. " - graceful degradation")
        return false
    end

    return result and true or false
end

-- ---------------------------------------------------------------------------
-- Classic layout: three sections (Current Rating / Character Experience /
-- Current Season), each listing every bracket.
-- ---------------------------------------------------------------------------

TooltipRenderer.layouts.classic = {
    Render = function(renderer, tooltip, playerData, currentSpec)
        -- Section visibility settings (absent before first-run init -> show all).
        local s = settings()

        renderer:AddSectionTitle(tooltip)

        if not s or s.showRating then
            renderer:FormatRatingSection(tooltip, playerData.brackets, currentSpec)
        end
        if not s or s.showExperience then
            renderer:FormatExperienceSection(tooltip, playerData.brackets, currentSpec)
        end
        if not s or s.showSeason then
            renderer:FormatSeasonSection(tooltip, playerData.brackets, currentSpec)
        end
        return true
    end,
}

-- Add the main "PvP Tooltip info:" section title (Requirement 6.1)
function TooltipRenderer:AddSectionTitle(tooltip)
    local titleText = (PvPTooltip.Config and PvPTooltip.Config.Tooltip
        and PvPTooltip.Config.Tooltip.mainTitle) or "PvP Tooltip info:"
    tooltip:AddLine(" ")
    tooltip:AddLine(PvPTooltip.ColorUtils:FormatSectionTitle(titleText))
end

-- The rows (bracket entries) a section or table shows, in display order, after
-- the per-bracket, show-all-specs and hide-empty settings filters. Each row is
-- { gameMode = "shuffle", entry = <bracket entry> }; entry is nil for a bracket
-- with no data (kept unless hide-empty is on). isEmpty(entry) decides what
-- hide-empty hides.
function TooltipRenderer:CollectRows(brackets, currentSpec, isEmpty)
    local rows = {}
    if type(brackets) ~= "table" then
        return rows
    end

    local hideEmpty = settings() and settings().hideEmpty
    local gameModes = (PvPTooltip.Config and PvPTooltip.Config.GameModes)
        or {"2v2", "3v3", "shuffle", "rbg", "blitz"}

    for _, gameMode in ipairs(gameModes) do
        if bracketEnabled(gameMode) then
            local entries = getBracketEntries(brackets[gameMode])
            if #entries == 0 then
                if not hideEmpty then
                    rows[#rows + 1] = { gameMode = gameMode }
                end
            else
                for _, entry in ipairs(entries) do
                    if specVisible(entry, currentSpec)
                       and not (hideEmpty and isEmpty(entry)) then
                        rows[#rows + 1] = { gameMode = gameMode, entry = entry }
                    end
                end
            end
        end
    end

    return rows
end

-- Render one bracket subsection. Shared by all three sections; the only
-- differences are the header, which entry value decides "empty", and how a line
-- is drawn. valueOf(entry) -> number used for the hideEmpty check; draw(tooltip,
-- gameMode, entry, label) emits the line (entry is nil for an absent bracket).
function TooltipRenderer:RenderSection(tooltip, brackets, currentSpec, header, valueOf, draw)
    if not tooltip then
        return false
    end
    if not brackets or type(brackets) ~= "table" then
        PvPTooltip:Debug("No brackets data available for section - graceful degradation")
        return false
    end

    addHeader(tooltip, header)

    local rows = self:CollectRows(brackets, currentSpec,
        function(entry) return valueOf(entry) == 0 end)
    for _, row in ipairs(rows) do
        local label = row.entry and self:GetEntryLabel(row.gameMode, row.entry, currentSpec)
        draw(tooltip, row.gameMode, row.entry, label)
    end

    return true
end

-- Create current rating display section (Requirement 2.1)
function TooltipRenderer:FormatRatingSection(tooltip, brackets, currentSpec)
    local header = (PvPTooltip.Config and PvPTooltip.Config.Tooltip
        and PvPTooltip.Config.Tooltip.currentRatingTitle) or "Current Rating"
    return self:RenderSection(tooltip, brackets, currentSpec, header,
        function(entry) return entry.currentRating or 0 end,
        function(t, gm, entry, label)
            self:AddRatingLine(t, gm, (entry and entry.currentRating) or 0, label)
        end)
end

-- Create character experience (personal best) display section (Requirement 3.1)
function TooltipRenderer:FormatExperienceSection(tooltip, brackets, currentSpec)
    local header = (PvPTooltip.Config and PvPTooltip.Config.Tooltip
        and PvPTooltip.Config.Tooltip.experienceTitle) or "Character Experience"
    return self:RenderSection(tooltip, brackets, currentSpec, header,
        function(entry) return entry.personalBest or 0 end,
        function(t, gm, entry, label)
            self:AddRatingLine(t, gm, (entry and entry.personalBest) or 0, label)
        end)
end

-- Create current season statistics display section (Requirement 4.1)
function TooltipRenderer:FormatSeasonSection(tooltip, brackets, currentSpec)
    local header = (PvPTooltip.Config and PvPTooltip.Config.Tooltip
        and PvPTooltip.Config.Tooltip.seasonTitle) or "Current Season"
    return self:RenderSection(tooltip, brackets, currentSpec, header,
        function(entry) return entry.playedTotal or 0 end,
        function(t, gm, entry, label)
            self:AddSeasonLine(t, gm, (entry and entry.playedTotal) or 0,
                (entry and entry.winRate) or 0, label)
        end)
end

-- Build the left-column label for a per-spec bracket entry (shuffle/blitz). Returns
-- nil for non-spec entries so callers use the default game-mode label. The unit's
-- active spec (currentSpec) is marked; other specs are listed plainly.
function TooltipRenderer:GetEntryLabel(gameMode, entry, currentSpec)
    local specId = entry and entry.shuffleSpecId
    if not specId then
        return nil
    end

    local label = PvPTooltip.ColorUtils:FormatGameModeLabel(gameMode)
    local specName = resolveSpecName(specId)
    if specName then
        label = label .. " |cFFB0B0B0(" .. specName .. ")|r"
    end
    if currentSpec and specId == currentSpec then
        label = "|cFF00FF00>|r " .. label -- mark the hovered unit's active spec
    end
    return label
end

-- Add a single rating line to the tooltip (Requirements 2.2, 2.3, 2.4, 2.5)
function TooltipRenderer:AddRatingLine(tooltip, gameMode, rating, labelOverride)
    if not tooltip or not gameMode then
        return
    end

    -- Format game mode label (Requirement 6.3)
    local gameModeLabel = labelOverride or PvPTooltip.ColorUtils:FormatGameModeLabel(gameMode)

    -- Format rating with color coding (Requirements 2.2, 2.3, 2.4, 2.5)
    local coloredRating = PvPTooltip.ColorUtils:FormatColoredRating(rating or 0)

    -- Two-column line: WoW aligns the right value for us (proportional font, so
    -- space padding cannot align columns).
    tooltip:AddDoubleLine(gameModeLabel, coloredRating)
end

-- Add a single season statistics line to the tooltip (Requirements 4.2, 4.3, 4.4, 4.5)
function TooltipRenderer:AddSeasonLine(tooltip, gameMode, playedTotal, winRate, labelOverride)
    if not tooltip or not gameMode then
        return
    end

    -- Format game mode label (Requirement 6.3)
    local gameModeLabel = labelOverride or PvPTooltip.ColorUtils:FormatGameModeLabel(gameMode)

    -- Format win rate display (Requirements 4.2, 4.3, 4.4, 4.5)
    local coloredWinRate = PvPTooltip.ColorUtils:FormatColoredWinRate(playedTotal or 0, winRate or 0)

    -- Two-column line: WoW aligns the right value for us.
    tooltip:AddDoubleLine(gameModeLabel, coloredWinRate)
end

-- ---------------------------------------------------------------------------
-- Shared helpers for the modern layouts (Compact / Sections / Panel)
-- ---------------------------------------------------------------------------

local DASH = "-"

-- Spec icon as an inline texture, cropped of its border and sized to the text.
-- The dimmed variant (vertex-colored grey) marks a spec that isn't the unit's
-- active one.
local ICON_MARKUP = "|T%s:0:0:0:0:64:64:5:59:5:59|t"
local ICON_MARKUP_DIM = "|T%s:0:0:0:0:64:64:5:59:5:59:110:110:110|t"

-- Which value columns are on (the section toggles in settings).
function TooltipRenderer:GetVisibleColumns()
    local s = settings()
    return {
        rating = not s or s.showRating ~= false,
        best = not s or s.showExperience ~= false,
        season = not s or s.showSeason ~= false,
    }
end

-- Rows for the table layouts (one per bracket / spec). With hide-empty on, a
-- row goes when every visible column is zero.
function TooltipRenderer:BuildTableRows(brackets, currentSpec, cols)
    return self:CollectRows(brackets, currentSpec, function(entry)
        return not ((cols.rating and (entry.currentRating or 0) > 0)
            or (cols.best and (entry.personalBest or 0) > 0)
            or (cols.season and (entry.playedTotal or 0) > 0))
    end)
end

-- Value columns, left to right. The season toggle shows two: games and win %.
function TooltipRenderer:GetTableColumns(cols)
    local titles = PvPTooltip.Config.Tooltip.columns
    local columns = {}
    if cols.rating then
        columns[#columns + 1] = { key = "rating", header = titles.rating }
    end
    if cols.best then
        columns[#columns + 1] = { key = "best", header = titles.best }
    end
    if cols.season then
        columns[#columns + 1] = { key = "games", header = titles.games }
        columns[#columns + 1] = { key = "win", header = titles.win }
    end
    return columns
end

-- Colored text for one table cell. entry is nil for a bracket with no data.
function TooltipRenderer:FormatCell(key, entry)
    local colorUtils = PvPTooltip.ColorUtils
    if key == "rating" then
        local rating = entry and entry.currentRating or 0
        return rating > 0 and colorUtils:FormatColoredRating(rating) or colorUtils:FormatMuted(DASH)
    elseif key == "best" then
        local best = entry and entry.personalBest or 0
        if best == 0 then
            return colorUtils:FormatMuted(DASH)
        end
        return colorUtils:FormatColoredText(tostring(best), colorUtils:GetDimRatingColor(best))
    elseif key == "games" then
        local played = entry and entry.playedTotal or 0
        if played == 0 then
            return colorUtils:FormatMuted(DASH)
        end
        return colorUtils:FormatColoredText(tostring(played), PvPTooltip.Config.Colors.games)
    elseif key == "win" then
        local played = entry and entry.playedTotal or 0
        if played == 0 then
            return ""
        end
        local winRate = entry.winRate or 0
        return colorUtils:FormatColoredText(string.format("%.0f%%", winRate),
            colorUtils:GetWinRateColor(winRate))
    end
    return ""
end

-- How a row's label looks: bracket name, spec icon (per-spec brackets only)
-- and state. "active"/"inactive" = the unit's active spec is known and this row
-- is / isn't it; "empty" = a bracket with no data; "normal" otherwise.
function TooltipRenderer:GetRowInfo(row, currentSpec)
    local specId = row.entry and row.entry.shuffleSpecId
    local spec = resolveSpecInfo(specId)
    local state = "normal"
    if not row.entry then
        state = "empty"
    elseif specId and currentSpec then
        state = (specId == currentSpec) and "active" or "inactive"
    end
    return PvPTooltip.Config:GetShortName(row.gameMode), spec and spec.icon, state
end

-- Label text for the line-based table layouts (Compact / Sections).
function TooltipRenderer:FormatRowLabel(row, currentSpec)
    local name, icon, state = self:GetRowInfo(row, currentSpec)
    local colors = PvPTooltip.Config.Colors
    local muted = state == "inactive" or state == "empty"
    local text = PvPTooltip.ColorUtils:FormatColoredText(name, muted and colors.inactive or colors.gameMode)
    if icon then
        local markup = state == "inactive" and ICON_MARKUP_DIM or ICON_MARKUP
        text = text .. " " .. string.format(markup, tostring(icon))
    end
    return text
end

-- "PvP" block title with the add-on icon.
function TooltipRenderer:FormatModernTitle()
    local config = PvPTooltip.Config
    return string.format("|T%s:0|t ", config.Media.icon)
        .. PvPTooltip.ColorUtils:FormatColoredText(config.Tooltip.modernTitle, config.Colors.title)
end

-- Inline transparent texture `width` pixels wide (nothing when width < 1:
-- a zero width would make the texture square).
function TooltipRenderer:Spacer(width)
    width = math.floor(width + 0.5)
    if width < 1 then
        return ""
    end
    return string.format("|T%s:1:%d|t", PvPTooltip.Config.Media.spacer, width)
end

-- Rendered width of `text` in a font object (default: the tooltip body font).
-- Color codes don't count; the measuring font strings are never drawn.
local measureFrame
local measurers = {}
function TooltipRenderer:TextWidth(text, fontObject)
    if not text or text == "" then
        return 0
    end
    fontObject = fontObject or "GameTooltipText"
    local fontString = measurers[fontObject]
    if not fontString then
        if not measureFrame then
            measureFrame = CreateFrame("Frame", nil, UIParent)
            measureFrame:SetSize(1, 1)
            measureFrame:SetPoint("TOPLEFT")
            measureFrame:SetAlpha(0)
        end
        fontString = measureFrame:CreateFontString(nil, "ARTWORK", fontObject)
        fontString:SetPoint("TOPLEFT")
        measurers[fontObject] = fontString
    end
    fontString:SetText(text)
    if fontString.GetUnboundedStringWidth then
        return fontString:GetUnboundedStringWidth()
    end
    return fontString:GetStringWidth()
end

-- Size `columns` (from GetTableColumns) to their content. rowCells[r][c] is
-- the text of row r, column c; widthOf(text, isHeader) measures it. gap /
-- innerGap = space before a column / an `inner` one. A column is as wide as
-- its widest cell or header. Sets column.width, column.headerWidth and
-- column.right (distance from the block's right edge to the column's right
-- edge, so columns line up right-aligned). Returns the total width.
function TooltipRenderer:FitColumns(columns, rowCells, widthOf, gap, innerGap)
    for c, column in ipairs(columns) do
        local width = 0
        for _, cells in ipairs(rowCells) do
            width = math.max(width, widthOf(cells[c], false))
        end
        if column.header then
            column.headerWidth = widthOf(column.header, true)
            width = math.max(width, column.headerWidth)
        end
        column.width = width
        column.gapBefore = (c > 1) and (column.inner and innerGap or gap) or 0
    end

    local offset = 0
    for c = #columns, 1, -1 do
        columns[c].right = offset
        offset = offset + columns[c].width + columns[c].gapBefore
    end
    return offset
end

-- Join right-aligned cells into one string for a tooltip's right-hand text,
-- padding with spacers so each cell's right edge lands `right` pixels from the
-- end. cells = { { text, width, right }, ... } ordered right to left. Pads are
-- rounded against the running position, so rounding never accumulates.
function TooltipRenderer:JoinAligned(cells)
    local parts, pos = {}, 0
    for _, cell in ipairs(cells) do
        local pad = cell.right - pos
        if pad >= 0.5 then
            local spacer = self:Spacer(pad)
            table.insert(parts, 1, spacer)
            pos = pos + math.floor(pad + 0.5)
        end
        table.insert(parts, 1, cell.text)
        pos = pos + cell.width
    end
    return table.concat(parts)
end

-- Validate player data structure before rendering
function TooltipRenderer:ValidatePlayerData(playerData)
    if not playerData then
        return false
    end

    -- Check required fields
    if not playerData.name or not playerData.brackets then
        PvPTooltip:Debug("Player data missing required fields")
        return false
    end

    -- Check that brackets is a table
    if type(playerData.brackets) ~= "table" then
        PvPTooltip:Debug("Player data brackets is not a table")
        return false
    end

    -- Check if at least one bracket has some data
    local hasData = false
    for _, bracketData in pairs(playerData.brackets) do
        for _, entry in ipairs(getBracketEntries(bracketData)) do
            if type(entry) == "table" and
               (entry.currentRating or entry.personalBest or entry.playedTotal) then
                hasData = true
                break
            end
        end
        if hasData then
            break
        end
    end

    if not hasData then
        PvPTooltip:Debug("Player data has no valid bracket information")
        return false
    end

    return true
end

-- Return the module for proper loading
return TooltipRenderer
