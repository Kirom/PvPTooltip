-- PvPTooltip Sections Layout
-- The classic three sections (rating / personal best / season), restyled:
-- one "PvP" title, small muted section headers, indented rows with spec icons,
-- and season stats as aligned games / win % columns.

local TooltipRenderer = PvPTooltip.TooltipRenderer

local Sections = {}
TooltipRenderer.layouts.sections = Sections

local INDENT = 10    -- px rows sit in from their section header
local INNER_GAP = 10 -- px between games and win % in the season section
local LABEL_GAP = 16 -- px kept clear between the label and the value

local function playedText(entry)
    local played = entry and entry.playedTotal or 0
    if played == 0 then
        return PvPTooltip.ColorUtils:FormatMuted("-")
    end
    return PvPTooltip.ColorUtils:FormatColoredText(
        played .. (played == 1 and " game" or " games"), PvPTooltip.Config.Colors.games)
end

-- Right-hand texts for a section's rows; key matches GetVisibleColumns.
local SECTIONS = {
    {
        key = "rating",
        valueOf = function(entry) return entry.currentRating or 0 end,
        values = function(renderer, rows)
            local out = {}
            for i, row in ipairs(rows) do
                out[i] = renderer:FormatCell("rating", row.entry)
            end
            return out
        end,
    },
    {
        key = "best",
        valueOf = function(entry) return entry.personalBest or 0 end,
        values = function(renderer, rows)
            local colorUtils = PvPTooltip.ColorUtils
            local out = {}
            for i, row in ipairs(rows) do
                local best = row.entry and row.entry.personalBest or 0
                out[i] = best > 0 and colorUtils:FormatColoredRating(best) or colorUtils:FormatMuted("-")
            end
            return out
        end,
    },
    {
        key = "season",
        valueOf = function(entry) return entry.playedTotal or 0 end,
        values = function(renderer, rows)
            local columns = { { key = "games" }, { key = "win", inner = true } }
            local rowCells = {}
            for i, row in ipairs(rows) do
                rowCells[i] = { playedText(row.entry), renderer:FormatCell("win", row.entry) }
            end
            local function widthOf(text)
                return renderer:TextWidth(text)
            end
            renderer:FitColumns(columns, rowCells, widthOf, 0, INNER_GAP)
            local out = {}
            for i, cells in ipairs(rowCells) do
                out[i] = renderer:JoinAligned({
                    { text = cells[2], width = widthOf(cells[2]), right = columns[2].right },
                    { text = cells[1], width = widthOf(cells[1]), right = columns[1].right },
                })
            end
            return out
        end,
    },
}

function Sections.Render(renderer, tooltip, playerData, currentSpec)
    local cols = renderer:GetVisibleColumns()
    local blocks = {}
    for _, section in ipairs(SECTIONS) do
        if cols[section.key] then
            local rows = renderer:CollectRows(playerData.brackets, currentSpec,
                function(entry) return section.valueOf(entry) == 0 end)
            if #rows > 0 then
                blocks[#blocks + 1] = { section = section, rows = rows }
            end
        end
    end
    if #blocks == 0 then
        return false
    end

    local titles = PvPTooltip.Config.Tooltip.sectionTitles
    local indent = renderer:Spacer(INDENT)
    local lead = renderer:Spacer(LABEL_GAP)

    tooltip:AddLine(" ")
    tooltip:AddLine(renderer:FormatModernTitle())
    for _, block in ipairs(blocks) do
        tooltip:AddLine(PvPTooltip.ColorUtils:FormatMuted(titles[block.section.key]))
        local values = block.section.values(renderer, block.rows)
        for i, row in ipairs(block.rows) do
            tooltip:AddDoubleLine(indent .. renderer:FormatRowLabel(row, currentSpec), lead .. values[i])
        end
    end

    return true
end

return Sections
