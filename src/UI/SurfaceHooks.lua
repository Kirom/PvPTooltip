-- PvPTooltip Surface Hooks
-- Shows the PvP block on Group Finder, Guild/Communities and Friends tooltips.

local SurfaceHooks = {}
PvPTooltip.SurfaceHooks = SurfaceHooks

local initialized = false

local function appendByName(tooltip, fullName)
    if not tooltip or not fullName then
        return
    end
    pcall(function()
        PvPTooltip.EventManager:EnhanceTooltipByName(tooltip, fullName)
    end)
end

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

function SurfaceHooks:RegisterLFG()
    if type(LFGListUtil_SetSearchEntryTooltip) == "function" then
        hooksecurefunc("LFGListUtil_SetSearchEntryTooltip", function(tooltip, resultID)
            if not resultID then
                return
            end
            local ok, info = pcall(C_LFGList.GetSearchResultInfo, resultID)
            if ok and info and info.leaderName then
                appendByName(tooltip, info.leaderName)
            end
        end)
    end

    local av = LFGListFrame and LFGListFrame.ApplicationViewer
    if not (av and av.ScrollBox) then
        return
    end

    local function memberOnEnter(self)
        local parent = self:GetParent()
        local applicantID = parent and parent.applicantID
        if not applicantID or not self.memberIdx then
            return
        end
        local ok, fullName = pcall(C_LFGList.GetApplicantMemberInfo, applicantID, self.memberIdx)
        if ok and fullName then
            showOwnedByName(self, fullName)
        end
    end

    local subHooked = setmetatable({}, { __mode = "k" })
    local function rowOnEnter(self)
        if self.applicantID and self.Members then
            for _, member in pairs(self.Members) do
                if not subHooked[member] then
                    subHooked[member] = true
                    member:HookScript("OnEnter", memberOnEnter)
                    member:HookScript("OnLeave", hideOwned)
                end
            end
        elseif self.memberIdx then
            memberOnEnter(self)
        end
    end

    hookScrollBox(av.ScrollBox, rowOnEnter, hideOwned)
end

function SurfaceHooks:RegisterFriends()
    if not FriendsTooltip then
        return
    end
    hooksecurefunc(FriendsTooltip, "Show", function(self)
        local button = self.button
        if not button then
            return
        end
        local fullName
        if button.buttonType == FRIENDS_BUTTON_TYPE_BNET then
            local ok, info = pcall(C_BattleNet.GetFriendAccountInfo, button.id)
            local game = ok and info and info.gameAccountInfo
            if game and game.clientProgram == BNET_CLIENT_WOW and game.characterName then
                if game.realmName and game.realmName ~= "" then
                    fullName = game.characterName .. "-" .. game.realmName
                else
                    fullName = game.characterName
                end
            end
        elseif button.buttonType == FRIENDS_BUTTON_TYPE_WOW then
            local ok, info = pcall(C_FriendList.GetFriendInfoByIndex, button.id)
            if ok and info and info.name then
                fullName = info.name
            end
        end
        if fullName then
            showOwnedByName(FriendsTooltip, fullName)
        end
    end)
    hooksecurefunc(FriendsTooltip, "Hide", hideOwned)
end

function SurfaceHooks:RegisterGuild()
    local memberList = CommunitiesFrame and CommunitiesFrame.MemberList
    local scrollBox = memberList and memberList.ScrollBox
    if not scrollBox then
        return
    end
    local function onEnter(self)
        if type(self.GetMemberInfo) ~= "function" then
            return
        end
        local ok, info = pcall(self.GetMemberInfo, self)
        if not ok or not info or not info.name then
            return
        end
        if info.clubType ~= nil
            and Enum and Enum.ClubType
            and info.clubType ~= Enum.ClubType.Guild
            and info.clubType ~= Enum.ClubType.Character then
            return
        end
        showOwnedByName(self, info.name)
    end
    hookScrollBox(scrollBox, onEnter, hideOwned)
end

local registered = { friends = false, lfg = false, guild = false }

local function tryRegister(self)
    if not registered.friends and FriendsTooltip then
        if pcall(function() self:RegisterFriends() end) then
            registered.friends = true
        end
    end
    if not registered.lfg and LFGListFrame and LFGListFrame.ApplicationViewer
        and LFGListFrame.ApplicationViewer.ScrollBox
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

-- Group Finder and Communities frames load on demand; retry on ADDON_LOADED.
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
