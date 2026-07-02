-- PvPTooltip Main Addon File
-- Handles addon initialization, lifecycle, and global namespace setup

-- Create global addon namespace
PvPTooltip = {}
PvPTooltip.name = "PvPTooltip"
-- Version comes from the .toc (packager substitutes @project-version@ from the
-- git tag). A dev checkout has the raw placeholder, so show "dev" there.
do
    local v = C_AddOns and C_AddOns.GetAddOnMetadata
        and C_AddOns.GetAddOnMetadata("PvPTooltip", "Version")
    if not v or v == "" or string.find(v, "project%-version") then
        v = "dev"
    end
    PvPTooltip.version = v
end

-- Addon state tracking
local addonLoaded = false
local playerLoggedIn = false

-- Addon components will be populated by their respective modules as they load

-- Saved variables
PvPTooltipDB = PvPTooltipDB or {}

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

-- Per-region character databases ship as separate add-ons (see PvPTooltip.toc /
-- .pkgmeta). GetCurrentRegion: 1=US, 2=KR, 3=EU, 4=TW, 5=CN.
local REGION_HOME_ADDON = {
    [1] = "PvPTooltip_DataUS",
    [3] = "PvPTooltip_DataEU",
}
local ALL_DATA_ADDONS = { "PvPTooltip_DataEU", "PvPTooltip_DataUS" }

-- On first login, disable the data add-ons that don't match the player's region
-- so later sessions only load the home region (halves the DB's memory). WoW is
-- region-locked, so a foreign region's ratings are never queried. Runs once; the
-- user's manual choices in the settings panel are respected afterwards. The
-- disable takes effect on the next reload (this session's data is already loaded).
function PvPTooltip:ConfigureRegionData()
    if PvPTooltipDB.regionDataConfigured then
        return
    end
    if not (C_AddOns and C_AddOns.DisableAddOn and C_AddOns.IsAddOnLoaded) then
        return
    end
    local region = GetCurrentRegion and GetCurrentRegion()
    local home = region and REGION_HOME_ADDON[region]
    for _, addon in ipairs(ALL_DATA_ADDONS) do
        if addon ~= home and C_AddOns.IsAddOnLoaded(addon) then
            C_AddOns.DisableAddOn(addon)
            self:Debug("Disabled foreign region data add-on: " .. addon)
        end
    end
    PvPTooltipDB.regionDataConfigured = true
end

-- Addon initialization function
function PvPTooltip:Initialize()
    if addonLoaded and playerLoggedIn then
        self:Debug("Starting addon initialization...")
        
        -- Initialize saved variables with defaults
        if not PvPTooltipDB.initialized then
            PvPTooltipDB.debug = false
            PvPTooltipDB.enabled = true
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
        
        -- Keep only the player's region character DB loaded on future sessions.
        self:ConfigureRegionData()

        -- Initialize core components in proper order with error protection
        if self.Config and self.Config.Initialize then
            local success, result = pcall(self.Config.Initialize, self.Config)
            if not success then
                self:Error("Failed to initialize Config module: " .. tostring(result))
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
        if addonName == "PvPTooltip" then
            addonLoaded = true
            PvPTooltip:Debug("Addon loaded")
            self:UnregisterEvent("ADDON_LOADED")
            PvPTooltip:Initialize()
        end
    elseif event == "PLAYER_LOGIN" then
        playerLoggedIn = true
        PvPTooltip:Debug("PLAYER_LOGIN event received")
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
    else
        PvPTooltip:Print("Commands:")
        PvPTooltip:Print("  /pvptooltip config - Open settings panel")
        PvPTooltip:Print("  /pvptooltip enable - Enable the addon")
        PvPTooltip:Print("  /pvptooltip disable - Disable the addon")
        PvPTooltip:Print("  /pvptooltip debug - Toggle debug mode")
        PvPTooltip:Print("  /pvptooltip status - Show addon status")
    end
end