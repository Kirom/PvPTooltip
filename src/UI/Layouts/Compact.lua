-- PvPTooltip Compact Layout
-- One tooltip line per bracket with Current / Best / Played / Win% columns under a
-- single header line that doubles as the column legend. Plain double lines, so
-- it works on every tooltip; the right-hand columns are aligned by measuring
-- each cell and padding with transparent spacer textures.

local TooltipRenderer = PvPTooltip.TooltipRenderer

local Compact = {}
TooltipRenderer.layouts.compact = Compact

local COLUMN_GAP = 14 -- px between columns
local LABEL_GAP = 16  -- px kept clear between the label and the first column

function Compact.Render(renderer, tooltip, playerData, currentSpec)
    local cols = renderer:GetVisibleColumns()
    local columns = renderer:GetTableColumns(cols)
    if #columns == 0 then
        return false
    end
    local rows = renderer:BuildTableRows(playerData.brackets, currentSpec, cols)
    if #rows == 0 then
        return false
    end

    local rowCells = {}
    for r, row in ipairs(rows) do
        local cells = {}
        for c, column in ipairs(columns) do
            cells[c] = renderer:FormatCell(column.key, row.entry)
        end
        rowCells[r] = cells
    end

    -- Header and value lines share the tooltip body font, so one measure fits all.
    local function widthOf(text)
        return renderer:TextWidth(text)
    end
    renderer:FitColumns(columns, rowCells, widthOf, COLUMN_GAP)

    local lead = renderer:Spacer(LABEL_GAP)

    local legend = {}
    for c = #columns, 1, -1 do
        local column = columns[c]
        if column.header then
            legend[#legend + 1] = {
                text = PvPTooltip.ColorUtils:FormatMuted(column.header),
                width = column.headerWidth,
                right = column.right,
            }
        end
    end

    tooltip:AddLine(" ")
    tooltip:AddDoubleLine(renderer:FormatModernTitle(), lead .. renderer:JoinAligned(legend))

    for r, row in ipairs(rows) do
        local cells = {}
        for c = #columns, 1, -1 do
            local text = rowCells[r][c]
            cells[#cells + 1] = { text = text, width = widthOf(text), right = columns[c].right }
        end
        tooltip:AddDoubleLine(renderer:FormatRowLabel(row, currentSpec), lead .. renderer:JoinAligned(cells))
    end

    return true
end

return Compact
