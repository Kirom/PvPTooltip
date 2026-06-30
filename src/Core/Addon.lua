-- PvPTooltip Main Addon File
-- Handles addon initialization, lifecycle, and global namespace setup

-- Create global addon namespace
PvPTooltip = {}
PvPTooltip.version = "1.0.0"
PvPTooltip.name = "PvPTooltip"

-- Addon state tracking
local addonLoaded = false
local playerLoggedIn = false

-- Addon components will be populated by their respective modules as they load

-- Saved variables with error handling support
PvPTooltipDB = PvPTooltipDB or {
    errorLog = {},
    errorStats = {}
}

-- Debug and logging functions
function PvPTooltip:Debug(message)
    if PvPTooltipDB.debug then
        print("|cFF00FF00[PvPTooltip Debug]|r " .. tostring(message))
    end
end

function PvPTooltip:Print(message)
    print("|cFFFFD035[PvPTooltip]|r " .. tostring(message))
end

function PvPTooltip:Error(message)
    print("|cFFFF0000[PvPTooltip Error]|r " .. tostring(message))
end

-- Addon initialization function
function PvPTooltip:Initialize()
    if addonLoaded and playerLoggedIn then
        self:Debug("Starting addon initialization...")
        
        -- Initialize saved variables with defaults
        if not PvPTooltipDB.initialized then
            PvPTooltipDB.debug = false
            PvPTooltipDB.enabled = true
            PvPTooltipDB.errorLog = {}
            PvPTooltipDB.errorStats = {}
            PvPTooltipDB.initialized = true
            self:Print("First time setup completed")
        end

        -- Display settings (separate block so existing users get them on upgrade).
        if not PvPTooltipDB.settings then
            PvPTooltipDB.settings = {
                modifier = "always",        -- "always" | "shift" | "ctrl" | "alt"
                showRating = true,
                showExperience = true,
                showSeason = true,
                brackets = {
                    ["2v2"] = true, ["3v3"] = true, ["shuffle"] = true,
                    ["rbg"] = true, ["blitz"] = true,
                },
                showAllSpecs = true,
                hideEmpty = false,
            }
        end
        
        -- Initialize error handler first for comprehensive error tracking
        if self.ErrorHandler and self.ErrorHandler.Initialize then
            self.ErrorHandler:Initialize()
        end
        
        -- Initialize core components in proper order with error protection
        if self.Config and self.Config.Initialize then
            local success, result = pcall(self.Config.Initialize, self.Config)
            if not success then
                self:Error("Failed to initialize Config module: " .. tostring(result))
            end
        end
        
        -- Initialize performance monitor early for comprehensive tracking
        if self.PerformanceMonitor and self.PerformanceMonitor.Initialize then
            local success, result = pcall(self.PerformanceMonitor.Initialize, self.PerformanceMonitor)
            if not success then
                self:Error("Failed to initialize PerformanceMonitor module: " .. tostring(result))
            end
        end
        
        -- Initialize data management components with error protection
        if self.RealmResolver and self.RealmResolver.Initialize then
            local success, result = pcall(self.RealmResolver.Initialize, self.RealmResolver)
            if not success then
                self:Error("Failed to initialize RealmResolver module: " .. tostring(result))
            end
        end
        
        if self.DatabaseManager and self.DatabaseManager.Initialize then
            local success, result = pcall(self.DatabaseManager.Initialize, self.DatabaseManager)
            if not success then
                self:Error("Failed to initialize DatabaseManager module: " .. tostring(result))
            end
        end
        
        if self.PlayerLookup and self.PlayerLookup.Initialize then
            local success, result = pcall(self.PlayerLookup.Initialize, self.PlayerLookup)
            if not success then
                self:Error("Failed to initialize PlayerLookup module: " .. tostring(result))
            end
        end
        
        -- Initialize UI components with error protection
        if self.ColorUtils and self.ColorUtils.Initialize then
            local success, result = pcall(self.ColorUtils.Initialize, self.ColorUtils)
            if not success then
                self:Error("Failed to initialize ColorUtils module: " .. tostring(result))
            end
        end
        
        if self.TooltipRenderer and self.TooltipRenderer.Initialize then
            local success, result = pcall(self.TooltipRenderer.Initialize, self.TooltipRenderer)
            if not success then
                self:Error("Failed to initialize TooltipRenderer module: " .. tostring(result))
            end
        end

        if self.SettingsPanel and self.SettingsPanel.Initialize then
            local success, result = pcall(self.SettingsPanel.Initialize, self.SettingsPanel)
            if not success then
                self:Error("Failed to initialize SettingsPanel module: " .. tostring(result))
            end
        end
        
        -- Initialize event management last with error protection
        if self.EventManager and self.EventManager.Initialize then
            local success, result = pcall(self.EventManager.Initialize, self.EventManager)
            if not success then
                self:Error("Failed to initialize EventManager module: " .. tostring(result))
            end
        end

        -- Initialize extra-surface tooltip hooks (LFG / Guild / Friends)
        if self.SurfaceHooks and self.SurfaceHooks.Initialize then
            local success, result = pcall(self.SurfaceHooks.Initialize, self.SurfaceHooks)
            if not success then
                self:Error("Failed to initialize SurfaceHooks module: " .. tostring(result))
            end
        end

        self:Print("Addon loaded successfully (v" .. self.version .. ")")
        self:Debug("Initialization complete")
    end
end

-- Check if addon is ready to operate
function PvPTooltip:IsReady()
    local ready = addonLoaded and playerLoggedIn and PvPTooltipDB.enabled
    
    -- Debug output to help diagnose issues
    if not ready then
        self:Debug("IsReady check failed:")
        self:Debug("  addonLoaded: " .. tostring(addonLoaded))
        self:Debug("  playerLoggedIn: " .. tostring(playerLoggedIn))
        self:Debug("  PvPTooltipDB.enabled: " .. tostring(PvPTooltipDB and PvPTooltipDB.enabled))
    end
    
    return ready
end

-- Enable/disable addon functionality
function PvPTooltip:SetEnabled(enabled)
    PvPTooltipDB.enabled = enabled
    if enabled then
        self:Print("Addon enabled")
        if self.EventManager and self.EventManager.RegisterTooltipEvents then
            self.EventManager:RegisterTooltipEvents()
        end
    else
        -- The modern tooltip hook can't be removed; OnUnitTooltip gates on
        -- IsReady(), so a disabled addon simply skips enhancement.
        self:Print("Addon disabled")
    end
end

-- Event frame for addon lifecycle events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        PvPTooltip:Debug("ADDON_LOADED event received for: " .. tostring(addonName))
        
        -- Check for our addon (be flexible with the name)
        if addonName == "PvPTooltip" or addonName == "PvP Tooltip" or 
           (addonName and string.find(string.lower(addonName), "pvptooltip")) then
            addonLoaded = true
            PvPTooltip:Debug("Our addon loaded: " .. tostring(addonName))
            PvPTooltip:Initialize()
        end
    elseif event == "PLAYER_LOGIN" then
        playerLoggedIn = true
        PvPTooltip:Debug("PLAYER_LOGIN event received")
        PvPTooltip:Initialize()
    end
end)

-- Fallback timer to ensure addon loads even if events fail
local fallbackTimer = C_Timer.NewTimer(2, function()
    if not addonLoaded then
        PvPTooltip:Debug("Fallback: Forcing addon loaded state")
        addonLoaded = true
        playerLoggedIn = true -- Assume player is logged in if we're running
        PvPTooltip:Initialize()
    end
end)

-- Slash command for basic addon control
SLASH_PVPTOOLTIP1 = "/pvptooltip"
SLASH_PVPTOOLTIP2 = "/pvpt"

SlashCmdList["PVPTOOLTIP"] = function(msg)
    local command = string.lower(string.trim(msg or ""))
    
    if command == "" or command == "config" or command == "options" or command == "settings" then
        if PvPTooltip.SettingsPanel and PvPTooltip.SettingsPanel.Open then
            PvPTooltip.SettingsPanel:Open()
        else
            PvPTooltip:Print("Settings panel unavailable")
        end
    elseif command == "enable" then
        PvPTooltip:SetEnabled(true)
    elseif command == "disable" then
        PvPTooltip:SetEnabled(false)
    elseif command == "debug" then
        PvPTooltipDB.debug = not PvPTooltipDB.debug
        PvPTooltip:Print("Debug mode " .. (PvPTooltipDB.debug and "enabled" or "disabled"))
    elseif command == "status" then
        PvPTooltip:Print("Status: " .. (PvPTooltipDB.enabled and "Enabled" or "Disabled"))
        PvPTooltip:Print("Debug: " .. (PvPTooltipDB.debug and "On" or "Off"))
        PvPTooltip:Print("Ready: " .. (PvPTooltip:IsReady() and "Yes" or "No"))
        
        -- Show error statistics if available
        if PvPTooltip.ErrorHandler and PvPTooltip.ErrorHandler.GetErrorStats then
            local errorStats = PvPTooltip.ErrorHandler:GetErrorStats()
            local hasErrors = false
            for context, stats in pairs(errorStats) do
                if stats.count > 0 then
                    hasErrors = true
                    break
                end
            end
            
            if hasErrors then
                PvPTooltip:Print("Error Statistics:")
                for context, stats in pairs(errorStats) do
                    if stats.count > 0 then
                        PvPTooltip:Print(string.format("  %s: %d errors%s", 
                            context, stats.count, stats.suppressed and " (suppressed)" or ""))
                    end
                end
            else
                PvPTooltip:Print("No errors recorded")
            end
        end
    elseif command == "errors" then
        if PvPTooltipDB.errorLog and #PvPTooltipDB.errorLog > 0 then
            PvPTooltip:Print("Recent errors (last 10):")
            local startIdx = math.max(1, #PvPTooltipDB.errorLog - 9)
            for i = startIdx, #PvPTooltipDB.errorLog do
                local error = PvPTooltipDB.errorLog[i]
                PvPTooltip:Print(string.format("  [%s] %s: %s", 
                    error.time or "unknown", error.context or "unknown", error.error or "unknown"))
            end
        else
            PvPTooltip:Print("No errors in log")
        end
    elseif command == "clearerrors" then
        PvPTooltipDB.errorLog = {}
        if PvPTooltip.ErrorHandler and PvPTooltip.ErrorHandler.ResetErrorTracking then
            PvPTooltip.ErrorHandler:ResetErrorTracking()
        end
        PvPTooltip:Print("Error log cleared")
    elseif command == "performance" or command == "perf" then
        if PvPTooltip.PerformanceMonitor and PvPTooltip.PerformanceMonitor.GetPerformanceReport then
            local report = PvPTooltip.PerformanceMonitor:GetPerformanceReport()
            PvPTooltip:Print("Performance Report:")
            PvPTooltip:Print(string.format("  Uptime: %.1f minutes", report.uptime / 60))
            PvPTooltip:Print(string.format("  Tooltip Success Rate: %.1f%%", report.tooltip.successRate))
            PvPTooltip:Print(string.format("  Cache Hit Rate: %.1f%%", report.database.cacheHitRate))
            PvPTooltip:Print(string.format("  Average Response Time: %.1fms", report.tooltip.averageResponseTime))
            PvPTooltip:Print(string.format("  Frame Rate: %.1f FPS", report.system.frameRate))
            
            if report.system.memoryPressure then
                PvPTooltip:Print("  |cFFFF0000Memory Pressure Detected|r")
            end
        else
            PvPTooltip:Print("Performance monitoring not available")
        end
    elseif command == "perfstatus" then
        if PvPTooltip.PerformanceMonitor and PvPTooltip.PerformanceMonitor.GetPerformanceStatus then
            local status = PvPTooltip.PerformanceMonitor:GetPerformanceStatus()
            local statusColor = status.status == "Good" and "|cFF00FF00" or 
                               status.status == "Fair" and "|cFFFFFF00" or "|cFFFF0000"
            
            PvPTooltip:Print("Performance Status: " .. statusColor .. status.status .. "|r")
            
            if #status.issues > 0 then
                PvPTooltip:Print("Issues:")
                for _, issue in ipairs(status.issues) do
                    PvPTooltip:Print("  - " .. issue)
                end
            end
            
            if #status.recommendations > 0 then
                PvPTooltip:Print("Recommendations:")
                for i, rec in ipairs(status.recommendations) do
                    if i <= 3 then -- Show only first 3 recommendations
                        PvPTooltip:Print("  - " .. rec)
                    end
                end
            end
        else
            PvPTooltip:Print("Performance monitoring not available")
        end
    elseif command == "resetperf" then
        if PvPTooltip.PerformanceMonitor and PvPTooltip.PerformanceMonitor.ResetMetrics then
            PvPTooltip.PerformanceMonitor:ResetMetrics()
            PvPTooltip:Print("Performance metrics reset")
        else
            PvPTooltip:Print("Performance monitoring not available")
        end
    elseif command == "demo" or command == "testtooltip" then
        PvPTooltip:Print("Creating demo tooltip...")
        
        -- Create demo player data
        local demoData = {
            name = "DemoPlayer",
            realm = "demo-realm",
            region = "eu",
            brackets = {
                ["2v2"] = {
                    currentRating = 2100,
                    personalBest = 2300,
                    playedTotal = 75,
                    winRate = 64.0
                },
                ["3v3"] = {
                    currentRating = 1950,
                    personalBest = 2150,
                    playedTotal = 45,
                    winRate = 58.0
                },
                ["shuffle"] = {
                    currentRating = 2250,
                    personalBest = 2400,
                    playedTotal = 120,
                    winRate = 67.0
                }
            }
        }
        
        -- Test tooltip rendering
        if PvPTooltip.TooltipRenderer then
            local mockTooltip = {
                lines = {},
                AddLine = function(self, text, r, g, b)
                    table.insert(self.lines, text or "")
                    print(text or "")
                end
            }
            
            local result = PvPTooltip.TooltipRenderer:EnhanceTooltip(mockTooltip, demoData)
            if result then
                PvPTooltip:Print("Demo tooltip created successfully!")
                PvPTooltip:Print("Lines added: " .. #mockTooltip.lines)
            else
                PvPTooltip:Print("Demo tooltip creation failed")
            end
        else
            PvPTooltip:Print("TooltipRenderer not available")
        end
    elseif command == "force" or command == "forceready" then
        PvPTooltip:Print("Forcing addon to ready state...")
        addonLoaded = true
        playerLoggedIn = true
        PvPTooltipDB.enabled = true
        PvPTooltip:Initialize()
        PvPTooltip:Print("Addon forced to ready state")
    else
        PvPTooltip:Print("Commands:")
        PvPTooltip:Print("  /pvptooltip config - Open settings panel")
        PvPTooltip:Print("  /pvptooltip enable - Enable the addon")
        PvPTooltip:Print("  /pvptooltip disable - Disable the addon")
        PvPTooltip:Print("  /pvptooltip debug - Toggle debug mode")
        PvPTooltip:Print("  /pvptooltip status - Show addon status")
        PvPTooltip:Print("  /pvptooltip errors - Show recent errors")
        PvPTooltip:Print("  /pvptooltip clearerrors - Clear error log")
        PvPTooltip:Print("  /pvptooltip performance - Show performance report")
        PvPTooltip:Print("  /pvptooltip perfstatus - Show performance status")
        PvPTooltip:Print("  /pvptooltip resetperf - Reset performance metrics")
        PvPTooltip:Print("  /pvptooltip force - Force addon to ready state")
        PvPTooltip:Print("  /pvptooltip demo - Test tooltip rendering with demo data")
    end
end