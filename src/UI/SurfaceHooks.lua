-- PvPTooltip Surface Hooks
-- Adds the PvP block to tooltips beyond the unit tooltip: Group Finder (LFG),
-- Guild/Communities member lists, and the Friends list. Each surface is a thin
-- provider that extracts a player name and delegates to EventManager. All hooks
-- are pcall-wrapped so a failure never breaks Blizzard's native tooltip.

local SurfaceHooks = {}
PvPTooltip.SurfaceHooks = SurfaceHooks

local initialized = false

-- Append model: the surface already shows a native tooltip; add our block to it.
local function appendByName(tooltip, fullName)
    if not tooltip or not fullName then
        return
    end
    pcall(function()
        PvPTooltip.EventManager:EnhanceTooltipByName(tooltip, fullName)
    end)
end

-- Owned model: the hovered row has no native player tooltip. Anchor a fresh
-- GameTooltip to the row, add a name header, then our block. Returns true if
-- shown; hides the empty tooltip otherwise.
local function showOwnedByName(anchorFrame, fullName)
    if not anchorFrame or not fullName then
        return false
    end
    local shown = false
    pcall(function()
        GameTooltip:SetOwner(anchorFrame, "ANCHOR_RIGHT")
        GameTooltip:SetText(fullName, 1, 1, 1)
        if PvPTooltip.EventManager:EnhanceTooltipByName(GameTooltip, fullName) then
            shown = true
        else
            GameTooltip:Hide()
        end
    end)
    return shown
end

local function hideOwned()
    pcall(function()
        GameTooltip:Hide()
    end)
end

-- Minimal ScrollBox button hooker (retail). Hooks OnEnter/OnLeave on every
-- currently-visible row and re-hooks recycled rows on update. A weak-keyed set
-- prevents double-hooking. Returns true if the scroll box was hookable.
local function hookScrollBox(scrollBox, onEnter, onLeave)
    if not (scrollBox and scrollBox.RegisterCallback and scrollBox.GetFrames and ScrollBoxListMixin) then
        return false
    end
    local hooked = setmetatable({}, { __mode = "k" })
    local function apply()
        local frames = scrollBox:GetFrames()
        if not frames then
            return
        end
        for _, button in ipairs(frames) do
            if not hooked[button] then
                hooked[button] = true
                if onEnter then button:HookScript("OnEnter", onEnter) end
                if onLeave then button:HookScript("OnLeave", onLeave) end
            end
        end
    end
    apply()
    scrollBox:RegisterCallback(ScrollBoxListMixin.Event.OnUpdate, apply, SurfaceHooks)
    return true
end

-- Providers (filled in Tasks 4-6).
function SurfaceHooks:RegisterLFG() end
function SurfaceHooks:RegisterFriends() end
function SurfaceHooks:RegisterGuild() end

-- Tracks which surfaces are registered, so ADDON_LOADED retries don't re-hook.
local registered = { friends = false, lfg = false, guild = false }

local function tryRegister(self)
    if not registered.friends and FriendsTooltip then
        if pcall(function() self:RegisterFriends() end) then
            registered.friends = true
        end
    end
    if not registered.lfg and LFGListFrame and LFGListFrame.ApplicationViewer
        and type(LFGListUtil_SetSearchEntryTooltip) == "function" then
        if pcall(function() self:RegisterLFG() end) then
            registered.lfg = true
        end
    end
    if not registered.guild and CommunitiesFrame and CommunitiesFrame.MemberList
        and CommunitiesFrame.MemberList.ScrollBox then
        if pcall(function() self:RegisterGuild() end) then
            registered.guild = true
        end
    end
    return registered.friends and registered.lfg and registered.guild
end

-- Group Finder and Communities frames load on demand, so not every surface is
-- present at login. Register what exists now, then retry on each ADDON_LOADED
-- until all surfaces are hooked.
function SurfaceHooks:Initialize()
    if initialized then
        return
    end
    initialized = true
    PvPTooltip:Debug("SurfaceHooks initializing...")

    if tryRegister(self) then
        PvPTooltip:Debug("SurfaceHooks: all surfaces registered at init")
        return
    end

    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function()
        if tryRegister(self) then
            f:UnregisterAllEvents()
            f:SetScript("OnEvent", nil)
        end
    end)
    PvPTooltip:Debug("SurfaceHooks initialized (awaiting on-demand panels)")
end

return SurfaceHooks
