-- PvPTooltip Analytics
-- Reports which tooltip layout is in use through Wago Analytics. Does nothing
-- unless the WagoAnalytics add-on (installed by the Wago App) is loaded, and
-- users opt out in the Wago App settings. No network access here: Wago
-- Analytics saves the values to its SavedVariables on logout and the Wago App
-- uploads them.

local Analytics = {}
PvPTooltip.Analytics = Analytics

function Analytics:Initialize()
    local wago = _G.WagoAnalytics
    local wagoID = C_AddOns and C_AddOns.GetAddOnMetadata
        and C_AddOns.GetAddOnMetadata("PvPTooltip", "X-Wago-ID")
    if not (wago and wago.Register and wagoID) then
        return
    end
    self.wago = wago:Register(wagoID)
    self:TrackLayout(PvPTooltipDB.settings.layout)
end

-- One switch per layout with only the active one on, so the dashboard shows
-- each layout's share. Re-run when the setting changes; the values at logout
-- are the ones saved.
function Analytics:TrackLayout(layout)
    if not self.wago then
        return
    end
    local config = PvPTooltip.Config
    if not config.LayoutNames[layout] then
        layout = config.DefaultLayout
    end
    for _, key in ipairs(config.Layouts) do
        self.wago:Switch("Layout_" .. key, key == layout)
    end
end

return Analytics
