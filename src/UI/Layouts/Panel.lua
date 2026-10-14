-- PvPTooltip Panel Layout
-- A frame embedded in the tooltip: pixel-aligned columns under a column header,
-- a highlight on the unit's active spec, and a thin bar per row (fill = current
-- rating, tick = personal best, on a shared 0-3000 scale so players compare).
--
-- Space is reserved with one tooltip line holding a transparent spacer texture
-- of the panel's exact size, so the tooltip sizes itself around the panel
-- whatever its font. Blizzard's GameTooltip_InsertFrame isn't used: it writes
-- tooltip.insertedFrames, and that field written from add-on code would taint
-- Blizzard's own tooltip code that reads it later.

local TooltipRenderer = PvPTooltip.TooltipRenderer

local Panel = {}
TooltipRenderer.layouts.panel = Panel

local INSET = 10       -- tooltip text inset from each side edge
local TOP_MARGIN = 8   -- space between the tooltip's lines above and the panel
local COLUMN_GAP = 14  -- px between columns
local LABEL_GAP = 18   -- min space between the label column and the first value column
local ICON_GAP = 4     -- label to spec icon
local HEADER_GAP = 3   -- header text to divider, divider to first row
local BAR_GAP = 2      -- row text to its rating bar
local BAR_HEIGHT = 2
local ROW_GAP = 4      -- rating bar to the next row
local BAR_SCALE = 3000 -- rating that fills a bar (raised to the highest shown)

local HEADER_FONT = "GameTooltipTextSmall"
local BODY_FONT = "GameTooltipText"

local panels = {} -- tooltip -> its panel (created on first use, then reused)

-- Stretch the panel to the tooltip's text width so its right-aligned columns
-- end where the tooltip's other right-hand texts do. The tooltip can widen
-- after we render (lines added later by other add-ons), hence OnUpdate.
local function syncWidth(panel)
    local width = panel:GetParent():GetWidth()
    if issecretvalue and issecretvalue(width) then
        return
    end
    width = math.max(panel.contentWidth or 0, width - 2 * INSET)
    if math.abs(panel:GetWidth() - width) > 0.5 then
        panel:SetWidth(width)
    end
end

-- Bar fills and best-ticks are fractions of the panel width.
local function layoutBars(panel)
    local width = panel:GetWidth()
    for i = 1, panel.numRows or 0 do
        local row = panel.rows[i]
        if row.fillFrac > 0 then
            row.barFill:SetWidth(math.max(1, width * row.fillFrac))
            row.barFill:Show()
        else
            row.barFill:Hide()
        end
        if row.bestFrac > 0 then
            row.barBest:ClearAllPoints()
            row.barBest:SetPoint("CENTER", row.barBg, "LEFT", math.min(width * row.bestFrac, width - 1), 0)
            row.barBest:Show()
        else
            row.barBest:Hide()
        end
    end
end

local function createPanel(tooltip)
    local panel = CreateFrame("Frame", nil, tooltip)
    panel:Hide()
    panel.rows = {}
    panel.headers = {}

    panel.title = panel:CreateFontString(nil, "ARTWORK", BODY_FONT)
    panel.title:SetPoint("TOPLEFT")

    panel.divider = panel:CreateTexture(nil, "ARTWORK")
    panel.divider:SetColorTexture(1, 1, 1, 0.15)
    panel.divider:SetHeight(1)

    panel:SetScript("OnUpdate", syncWidth)
    panel:SetScript("OnSizeChanged", layoutBars)

    -- Go with the tooltip's content: OnTooltipCleared fires on every rebuild
    -- (incl. Blizzard's periodic unit-tooltip refresh, after which we render
    -- again), OnHide when the tooltip closes.
    local function hide()
        panel:Hide()
    end
    tooltip:HookScript("OnTooltipCleared", hide)
    tooltip:HookScript("OnHide", hide)
    return panel
end

local function acquireRow(panel, index)
    local row = panel.rows[index]
    if row then
        return row
    end
    row = { cells = {}, fillFrac = 0, bestFrac = 0 }

    row.highlight = panel:CreateTexture(nil, "BACKGROUND")
    row.highlight:SetColorTexture(1, 1, 1, 0.07)

    row.label = panel:CreateFontString(nil, "ARTWORK", BODY_FONT)
    row.icon = panel:CreateTexture(nil, "ARTWORK")
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    row.barBg = panel:CreateTexture(nil, "ARTWORK")
    row.barBg:SetColorTexture(1, 1, 1, 0.08)
    row.barBg:SetHeight(BAR_HEIGHT)
    row.barFill = panel:CreateTexture(nil, "ARTWORK", nil, 1)
    row.barFill:SetHeight(BAR_HEIGHT)
    row.barFill:SetPoint("LEFT", row.barBg, "LEFT")
    row.barBest = panel:CreateTexture(nil, "ARTWORK", nil, 2)
    row.barBest:SetColorTexture(1, 1, 1, 0.85)
    row.barBest:SetSize(1, BAR_HEIGHT + 2)

    panel.rows[index] = row
    return row
end

local function hideRow(row)
    row.highlight:Hide()
    row.label:Hide()
    row.icon:Hide()
    row.barBg:Hide()
    row.barFill:Hide()
    row.barBest:Hide()
    for _, cell in pairs(row.cells) do
        cell:Hide()
    end
    row.fillFrac, row.bestFrac = 0, 0
end

function Panel.Render(renderer, tooltip, playerData, currentSpec)
    -- Needs the tooltip's line font strings to anchor to.
    if not tooltip.GetLeftLine then
        return renderer.layouts.compact.Render(renderer, tooltip, playerData, currentSpec)
    end

    local cols = renderer:GetVisibleColumns()
    local columns = renderer:GetTableColumns(cols)
    if #columns == 0 then
        return false
    end
    local rows = renderer:BuildTableRows(playerData.brackets, currentSpec, cols)
    if #rows == 0 then
        return false
    end

    local colorUtils = PvPTooltip.ColorUtils
    local colors = PvPTooltip.Config.Colors

    local panel = panels[tooltip]
    if not panel then
        panel = createPanel(tooltip)
        panels[tooltip] = panel
    end

    -- Columns are sized from the texts they hold.
    local rowCells = {}
    for r, row in ipairs(rows) do
        local cells = {}
        for c, column in ipairs(columns) do
            cells[c] = renderer:FormatCell(column.key, row.entry)
        end
        rowCells[r] = cells
    end
    local function widthOf(text, isHeader)
        return renderer:TextWidth(text, isHeader and HEADER_FONT or BODY_FONT)
    end
    local columnsWidth = renderer:FitColumns(columns, rowCells, widthOf, COLUMN_GAP)

    -- Title row: "PvP" on the left, column legend on the right (bottom-aligned).
    local title = renderer:FormatModernTitle()
    panel.title:SetText(title)
    local _, fontSize = panel.title:GetFont()
    local lineHeight = math.ceil(math.max(panel.title:GetStringHeight() or 0, fontSize or 12))

    local mutedR, mutedG, mutedB = colorUtils:HexToRGB(colors.muted)
    local usedHeaders = {}
    for _, column in ipairs(columns) do
        if column.header then
            local header = panel.headers[column.key]
            if not header then
                header = panel:CreateFontString(nil, "ARTWORK", HEADER_FONT)
                header:SetJustifyH("RIGHT")
                panel.headers[column.key] = header
            end
            header:SetText(column.header)
            header:SetTextColor(mutedR, mutedG, mutedB)
            header:ClearAllPoints()
            header:SetPoint("BOTTOMRIGHT", panel, "TOPRIGHT", -column.right, -lineHeight)
            header:Show()
            usedHeaders[column.key] = true
        end
    end
    for key, header in pairs(panel.headers) do
        if not usedHeaders[key] then
            header:Hide()
        end
    end

    local dividerY = -(lineHeight + HEADER_GAP)
    panel.divider:ClearAllPoints()
    panel.divider:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, dividerY)
    panel.divider:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, dividerY)

    -- Rows.
    local showBars = cols.rating or cols.best
    local rowHeight = lineHeight + (showBars and (BAR_GAP + BAR_HEIGHT) or 0) + ROW_GAP
    local top = dividerY - 1 - HEADER_GAP

    local scale = BAR_SCALE
    for _, row in ipairs(rows) do
        if row.entry then
            scale = math.max(scale, row.entry.currentRating or 0, row.entry.personalBest or 0)
        end
    end

    local labelColumn = renderer:TextWidth(title, BODY_FONT)
    for r, row in ipairs(rows) do
        local slot = acquireRow(panel, r)
        local y = top - (r - 1) * rowHeight
        local entry = row.entry
        local name, icon, state = renderer:GetRowInfo(row, currentSpec)

        local dim = state == "inactive" or state == "empty"
        slot.label:SetText(name)
        slot.label:SetTextColor(colorUtils:HexToRGB(dim and colors.inactive or colors.gameMode))
        slot.label:ClearAllPoints()
        slot.label:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, y)
        slot.label:Show()
        local labelWidth = renderer:TextWidth(name, BODY_FONT)

        if icon then
            slot.icon:SetTexture(icon)
            slot.icon:SetSize(lineHeight, lineHeight)
            slot.icon:SetDesaturated(state == "inactive")
            slot.icon:SetAlpha(state == "inactive" and 0.6 or 1)
            slot.icon:ClearAllPoints()
            slot.icon:SetPoint("LEFT", slot.label, "RIGHT", ICON_GAP, 0)
            slot.icon:Show()
            labelWidth = labelWidth + ICON_GAP + lineHeight
        else
            slot.icon:Hide()
        end
        labelColumn = math.max(labelColumn, labelWidth)

        if state == "active" then
            slot.highlight:ClearAllPoints()
            slot.highlight:SetPoint("TOPLEFT", panel, "TOPLEFT", -4, y + 2)
            slot.highlight:SetPoint("BOTTOMRIGHT", panel, "TOPRIGHT", 4, y - rowHeight + ROW_GAP - 2)
            slot.highlight:Show()
        else
            slot.highlight:Hide()
        end

        local usedCells = {}
        for c, column in ipairs(columns) do
            local cell = slot.cells[column.key]
            if not cell then
                cell = panel:CreateFontString(nil, "ARTWORK", BODY_FONT)
                cell:SetJustifyH("RIGHT")
                slot.cells[column.key] = cell
            end
            cell:SetText(rowCells[r][c])
            cell:ClearAllPoints()
            cell:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -column.right, y)
            cell:Show()
            usedCells[column.key] = true
        end
        for key, cell in pairs(slot.cells) do
            if not usedCells[key] then
                cell:Hide()
            end
        end

        if showBars then
            local barY = y - lineHeight - BAR_GAP
            slot.barBg:ClearAllPoints()
            slot.barBg:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, barY)
            slot.barBg:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, barY)
            slot.barBg:Show()

            local rating = (cols.rating and entry and entry.currentRating) or 0
            local best = (cols.best and entry and entry.personalBest) or 0
            local fill = cols.rating and rating or best
            local fillR, fillG, fillB = colorUtils:HexToRGB(colorUtils:GetRatingColor(fill))
            slot.barFill:SetColorTexture(fillR, fillG, fillB, 0.8)
            slot.fillFrac = fill / scale
            slot.bestFrac = (cols.rating and best > rating) and best / scale or 0
        else
            slot.barBg:Hide()
            slot.barFill:Hide()
            slot.barBest:Hide()
            slot.fillFrac, slot.bestFrac = 0, 0
        end
    end
    for r = #rows + 1, #panel.rows do
        hideRow(panel.rows[r])
    end
    panel.numRows = #rows

    local width = math.ceil(labelColumn + LABEL_GAP + columnsWidth)
    local height = math.ceil(-top + #rows * rowHeight - ROW_GAP)
    panel.contentWidth = width
    panel:SetSize(width, height)

    -- Reserve the panel's space with one line, then lay the panel over it.
    tooltip:AddLine(string.format("|T%s:%d:%d|t", PvPTooltip.Config.Media.spacer, height + TOP_MARGIN, width))
    local line = tooltip:GetLeftLine(tooltip:NumLines())
    if not line then
        panel:Hide()
        return true
    end
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", line, "TOPLEFT", 0, -TOP_MARGIN)
    panel:Show()
    syncWidth(panel)
    layoutBars(panel)

    return true
end

return Panel
