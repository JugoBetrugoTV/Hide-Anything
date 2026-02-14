--[[
    HideAnything - Core.lua
    Main addon engine: initialization, frame hiding/showing, event handling,
    combat lockdown protection, secure hooks, re-hide on show, alpha system,
    LibDataBroker data object
]]

local AddonName, HA = ...

---------------------------------------------------------------------------
-- Addon version (read from TOC at load, safe for all WoW versions)
---------------------------------------------------------------------------
local function SafeGetVersion()
    local ok, ver
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        ok, ver = pcall(C_AddOns.GetAddOnMetadata, AddonName, "Version")
    end
    if not ok or not ver then
        if GetAddOnMetadata then
            ok, ver = pcall(GetAddOnMetadata, AddonName, "Version")
        end
    end
    return (ok and ver) or "1.1.0"
end
HA.version = SafeGetVersion()

---------------------------------------------------------------------------
-- Event frame
---------------------------------------------------------------------------
HA.eventFrame = CreateFrame("Frame", "HideAnythingEventFrame", UIParent)
HA.eventFrame:RegisterEvent("ADDON_LOADED")
HA.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
HA.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
HA.eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

local pendingQueue = {} -- frames to hide/show after combat ends
HA.inCombat = false

---------------------------------------------------------------------------
-- Event handler
---------------------------------------------------------------------------
HA.eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == AddonName then
            HA:OnInitialize()
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Always reapply hidden frames and CVars on login/reload
        C_Timer.After(0.5, function()
            HA:ReapplyHiddenFrames()
            HA:ReapplyHiddenCVars()
            HA:ReapplyFrameAlphas()
        end)
    elseif event == "PLAYER_REGEN_DISABLED" then
        HA.inCombat = true
    elseif event == "PLAYER_REGEN_ENABLED" then
        HA.inCombat = false
        HA:ProcessPendingQueue()
    end
end)

---------------------------------------------------------------------------
-- Initialize addon
---------------------------------------------------------------------------
function HA:OnInitialize()
    local ok, err = pcall(function()
        local L = self.L

        -- Initialize saved variables / database
        self:InitDB()

        -- Initialize minimap button (LibDBIcon)
        if self.InitMinimap then
            self:InitMinimap()
        end

        -- Initialize floating button
        if self.InitFloatingButton then
            self:InitFloatingButton()
        end

        -- Initialize LDB data object
        if self.InitLDB then
            self:InitLDB()
        end

        -- Mark init as done (for startup diagnostic in Locales.lua)
        self._initDone = true

        -- Print loaded message
        self:Print(L["ADDON_LOADED"]:format(self.version))
    end)
    if not ok then
        print("|cffff0000[HideAnything] INIT ERROR:|r " .. tostring(err))
    end
end

---------------------------------------------------------------------------
-- Get a frame object from its name string
---------------------------------------------------------------------------
function HA:GetFrameByName(name)
    if not name or name == "" then return nil end

    -- Try _G first
    local frame = _G[name]
    if frame and type(frame) == "table" and frame.IsObjectType and frame:IsObjectType("Frame") then
        return frame
    end

    -- Try nested names (e.g. "PlayerFrame.PlayerFrameContent")
    local parts = { strsplit(".", name) }
    local obj = _G[parts[1]]
    for i = 2, #parts do
        if obj and type(obj) == "table" then
            obj = obj[parts[i]]
        else
            return nil
        end
    end
    if obj and type(obj) == "table" and obj.IsObjectType and obj:IsObjectType("Frame") then
        return obj
    end

    return nil
end

---------------------------------------------------------------------------
-- Get the display name for a frame
---------------------------------------------------------------------------
function HA:GetFrameName(frame)
    if not frame then return "nil" end
    local name = frame:GetName()
    if name and name ~= "" then
        return name
    end
    local parent = frame:GetParent()
    local parentName = parent and parent:GetName() or "UIParent"
    local objType = frame:GetObjectType() or "Frame"
    return parentName .. ".<" .. objType .. ">"
end

---------------------------------------------------------------------------
-- Check if a frame is protected and should not be hidden
---------------------------------------------------------------------------
function HA:IsProtectedFrame(frameName)
    return self.PROTECTED_FRAMES[frameName] == true
end

---------------------------------------------------------------------------
-- Hide a single frame by name
---------------------------------------------------------------------------
function HA:HideFrame(frameName)
    local L = self.L

    if not frameName or frameName == "" then
        self:FeedbackError("ERROR_FRAME_NIL")
        return false
    end

    -- Combat check
    if self.inCombat or InCombatLockdown() then
        self:FeedbackCombatError()
        table.insert(pendingQueue, { action = "hide", name = frameName })
        return false
    end

    -- Protected check
    if self:IsProtectedFrame(frameName) then
        self:FeedbackProtected(frameName)
        return false
    end

    -- Already hidden?
    if self.db.hiddenFrames[frameName] then
        self:FeedbackAlreadyHidden(frameName)
        return false
    end

    -- Find the frame
    local frame = self:GetFrameByName(frameName)
    if not frame then
        self:FeedbackFrameNotFound(frameName)
        return false
    end

    -- Hide it
    local success = self:SecureHideFrame(frame, frameName)
    if success then
        self.db.hiddenFrames[frameName] = true
        self:FeedbackHide(frameName)
        if self.RefreshFrameList then
            self:RefreshFrameList()
        end
    end

    return success
end

---------------------------------------------------------------------------
-- Show a single frame by name
---------------------------------------------------------------------------
function HA:ShowFrame(frameName)
    local L = self.L

    if not frameName or frameName == "" then
        self:FeedbackError("ERROR_FRAME_NIL")
        return false
    end

    -- Combat check
    if self.inCombat or InCombatLockdown() then
        self:FeedbackCombatError()
        table.insert(pendingQueue, { action = "show", name = frameName })
        return false
    end

    -- Is it even hidden?
    if not self.db.hiddenFrames[frameName] then
        self:Print(L["FRAME_NOT_HIDDEN"]:format(frameName))
        return false
    end

    -- Lock check
    if self:GetSetting("locked") then
        self:Print(L["FRAMES_LOCKED"])
        return false
    end

    -- Remove from DB FIRST (before showing, so the re-hide hook doesn't trigger)
    self.db.hiddenFrames[frameName] = nil

    -- Find the frame and show it
    local frame = self:GetFrameByName(frameName)
    if frame then
        self:SecureShowFrame(frame, frameName)
    end

    self:FeedbackShow(frameName)

    if self.RefreshFrameList then
        self:RefreshFrameList()
    end

    return true
end

---------------------------------------------------------------------------
-- Hide a CVar (set to 0)
---------------------------------------------------------------------------
function HA:HideCVar(cvarName)
    if not cvarName or cvarName == "" then return false end

    if self.db.hiddenCVars[cvarName] then return false end

    local ok = pcall(SetCVar, cvarName, "0")
    if not ok then
        self:FeedbackError("ERROR_CVAR_FAILED", cvarName)
        return false
    end

    self.db.hiddenCVars[cvarName] = true

    local displayName = cvarName
    for _, entry in ipairs(self.FRAME_CATALOG) do
        if entry.cvar == cvarName then
            displayName = self:GetCatalogLabel(entry)
            break
        end
    end
    self:FeedbackHide(displayName)

    if self.RefreshFrameList then
        self:RefreshFrameList()
    end
    return true
end

---------------------------------------------------------------------------
-- Show a CVar (set to 1)
---------------------------------------------------------------------------
function HA:ShowCVar(cvarName)
    if not cvarName or cvarName == "" then return false end

    if not self.db.hiddenCVars[cvarName] then return false end

    pcall(SetCVar, cvarName, "1")
    self.db.hiddenCVars[cvarName] = nil

    local displayName = cvarName
    for _, entry in ipairs(self.FRAME_CATALOG) do
        if entry.cvar == cvarName then
            displayName = self:GetCatalogLabel(entry)
            break
        end
    end
    self:FeedbackShow(displayName)

    if self.RefreshFrameList then
        self:RefreshFrameList()
    end
    return true
end

---------------------------------------------------------------------------
-- Reapply hidden CVars (after login/reload)
---------------------------------------------------------------------------
function HA:ReapplyHiddenCVars()
    if not self.db or not self.db.hiddenCVars then return end
    for cvarName, _ in pairs(self.db.hiddenCVars) do
        pcall(SetCVar, cvarName, "0")
    end
end

---------------------------------------------------------------------------
-- Show all hidden frames
---------------------------------------------------------------------------
function HA:ShowAllFrames()
    local L = self.L

    if self.inCombat or InCombatLockdown() then
        self:FeedbackCombatError()
        return
    end

    local count = 0
    for frameName, _ in pairs(self.db.hiddenFrames) do
        local frame = self:GetFrameByName(frameName)
        if frame then
            self:SecureShowFrame(frame, frameName)
        end
        count = count + 1
    end

    if count == 0 then
        self:FeedbackNoFramesHidden()
        return
    end

    wipe(self.db.hiddenFrames)

    -- Also restore all hidden CVars
    if self.db.hiddenCVars then
        for cvarName, _ in pairs(self.db.hiddenCVars) do
            pcall(SetCVar, cvarName, "1")
            count = count + 1
        end
        wipe(self.db.hiddenCVars)
    end

    -- Also reset all frame alphas
    if self.db.frameAlphas then
        for frameName, _ in pairs(self.db.frameAlphas) do
            local frame = self:GetFrameByName(frameName)
            if frame then
                pcall(function() frame:SetAlpha(1) end)
            end
        end
        wipe(self.db.frameAlphas)
    end

    self:FeedbackShowAll(count)

    if self.RefreshFrameList then
        self:RefreshFrameList()
    end
end

---------------------------------------------------------------------------
-- Reapply all hidden frames (after login/reload)
---------------------------------------------------------------------------
function HA:ReapplyHiddenFrames()
    if not self.db or not self.db.hiddenFrames then return end

    local failed = {}
    for frameName, _ in pairs(self.db.hiddenFrames) do
        local frame = self:GetFrameByName(frameName)
        if frame then
            self:SecureHideFrame(frame, frameName)
        else
            table.insert(failed, frameName)
        end
    end

    -- Retry failed frames after a short delay
    if #failed > 0 then
        C_Timer.After(2.0, function()
            for _, frameName in ipairs(failed) do
                local frame = self:GetFrameByName(frameName)
                if frame then
                    self:SecureHideFrame(frame, frameName)
                end
            end
        end)
    end
end

---------------------------------------------------------------------------
-- Securely hide a frame (with hook to prevent it from re-showing)
---------------------------------------------------------------------------
HA.hookedFrames = {}

function HA:SecureHideFrame(frame, frameName)
    if not frame then return false end

    local success, err = pcall(function()
        frame:Hide()
        frame:SetAlpha(0)
    end)

    if not success then
        self:FeedbackError("ERROR_FRAME_PROTECTED", frameName)
        return false
    end

    -- Hook Show() to prevent re-appearing
    if not self.hookedFrames[frameName] then
        local hookSuccess = pcall(function()
            hooksecurefunc(frame, "Show", function(f)
                if HA.db and HA.db.hiddenFrames and HA.db.hiddenFrames[frameName] then
                    if not InCombatLockdown() then
                        f:Hide()
                        f:SetAlpha(0)
                    end
                end
            end)
            hooksecurefunc(frame, "SetShown", function(f, shown)
                if shown and HA.db and HA.db.hiddenFrames and HA.db.hiddenFrames[frameName] then
                    if not InCombatLockdown() then
                        f:Hide()
                        f:SetAlpha(0)
                    end
                end
            end)
        end)

        if hookSuccess then
            self.hookedFrames[frameName] = true
        else
            self:FeedbackError("ERROR_HOOK_FAILED", frameName)
        end
    end

    return true
end

---------------------------------------------------------------------------
-- Securely show a frame
---------------------------------------------------------------------------
function HA:SecureShowFrame(frame, frameName)
    if not frame then return end

    -- Restore alpha: use saved alpha if exists, otherwise 1.0
    local alpha = 1.0
    if self.db and self.db.frameAlphas and self.db.frameAlphas[frameName] then
        alpha = self.db.frameAlphas[frameName]
    end

    pcall(function()
        frame:SetAlpha(alpha)
        frame:Show()
    end)
end

---------------------------------------------------------------------------
-- Set frame alpha (opacity)
---------------------------------------------------------------------------
function HA:SetFrameAlpha(frameName, alpha)
    local L = self.L

    if not frameName or frameName == "" then
        self:FeedbackError("ERROR_FRAME_NIL")
        return false
    end

    -- Clamp alpha 0.0 - 1.0
    alpha = math.max(0, math.min(1, alpha))

    -- If alpha is 1.0, remove from frameAlphas (reset)
    if alpha >= 1.0 then
        self.db.frameAlphas[frameName] = nil
        local frame = self:GetFrameByName(frameName)
        if frame and not self.db.hiddenFrames[frameName] then
            pcall(function() frame:SetAlpha(1) end)
        end
        self:ChatMsg(L["ALPHA_RESET"]:format(frameName))
    else
        self.db.frameAlphas[frameName] = alpha
        local frame = self:GetFrameByName(frameName)
        if frame and not self.db.hiddenFrames[frameName] then
            pcall(function() frame:SetAlpha(alpha) end)
        end
        self:ChatMsg(L["ALPHA_SET"]:format(frameName, math.floor(alpha * 100)))
    end

    if self.RefreshFrameList then
        self:RefreshFrameList()
    end

    return true
end

---------------------------------------------------------------------------
-- Get frame alpha (returns 0.0-1.0, defaults to 1.0)
---------------------------------------------------------------------------
function HA:GetFrameAlpha(frameName)
    if self.db and self.db.frameAlphas and self.db.frameAlphas[frameName] then
        return self.db.frameAlphas[frameName]
    end
    return 1.0
end

---------------------------------------------------------------------------
-- Reapply frame alphas (after login/reload)
---------------------------------------------------------------------------
function HA:ReapplyFrameAlphas()
    if not self.db or not self.db.frameAlphas then return end
    for frameName, alpha in pairs(self.db.frameAlphas) do
        if not self.db.hiddenFrames[frameName] then
            local frame = self:GetFrameByName(frameName)
            if frame then
                pcall(function() frame:SetAlpha(alpha) end)
            end
        end
    end
end

---------------------------------------------------------------------------
-- Process pending queue after combat
---------------------------------------------------------------------------
function HA:ProcessPendingQueue()
    if #pendingQueue == 0 then return end

    for _, entry in ipairs(pendingQueue) do
        if entry.action == "hide" then
            self:HideFrame(entry.name)
        elseif entry.action == "show" then
            self:ShowFrame(entry.name)
        end
    end
    wipe(pendingQueue)
end

---------------------------------------------------------------------------
-- Get count of hidden frames
---------------------------------------------------------------------------
function HA:GetHiddenCount()
    local count = 0
    if self.db and self.db.hiddenFrames then
        for _ in pairs(self.db.hiddenFrames) do
            count = count + 1
        end
    end
    return count
end

---------------------------------------------------------------------------
-- List hidden frames
---------------------------------------------------------------------------
function HA:ListHiddenFrames()
    local L = self.L
    local count = self:GetHiddenCount()

    if count == 0 then
        self:FeedbackNoFramesHidden()
        return
    end

    self:Print(L["LIST_HEADER"]:format(count))
    local i = 1
    for frameName, _ in pairs(self.db.hiddenFrames) do
        self:Print(L["LIST_ENTRY"]:format(i, frameName))
        i = i + 1
    end
end

---------------------------------------------------------------------------
-- Lock / Unlock
---------------------------------------------------------------------------
function HA:LockFrames()
    self:SetSetting("locked", true)
    self:FeedbackLock()
end

function HA:UnlockFrames()
    self:SetSetting("locked", false)
    self:FeedbackUnlock()
end

function HA:ToggleLock()
    if self:GetSetting("locked") then
        self:UnlockFrames()
    else
        self:LockFrames()
    end
end

---------------------------------------------------------------------------
-- Reset all
---------------------------------------------------------------------------
HA.resetPending = false

function HA:RequestReset()
    local L = self.L
    if self.resetPending then
        self:ShowAllFrames()
        self:ResetDB()
        self:FeedbackReset()
        self.resetPending = false
    else
        self:Print(L["RESET_CONFIRM"])
        self.resetPending = true
        C_Timer.After(15, function()
            HA.resetPending = false
        end)
    end
end

function HA:ConfirmReset()
    self.resetPending = true
    self:RequestReset()
end

---------------------------------------------------------------------------
-- LibDataBroker data object (for bar addons: Titan Panel, ChocolateBar, etc.)
---------------------------------------------------------------------------
function HA:InitLDB()
    local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
    if not LDB then return end

    self.ldbObject = LDB:NewDataObject("HideAnything", {
        type    = "launcher",
        label   = "HideAnything",
        icon    = "Interface\\Icons\\INV_Misc_Eye_02",
        OnClick = function(frame, button)
            if button == "LeftButton" then
                if IsShiftKeyDown() then
                    HA:ShowAllFrames()
                else
                    HA:ToggleOptionsPanel()
                end
            elseif button == "RightButton" then
                HA:ToggleOptionsPanel()
            end
        end,
        OnTooltipShow = function(tooltip)
            local L = HA.L
            tooltip:AddLine(L["MINIMAP_TOOLTIP_TITLE"])
            tooltip:AddLine(" ")
            tooltip:AddLine(L["MINIMAP_TOOLTIP_LEFT"], 1, 1, 1)
            tooltip:AddLine(L["MINIMAP_TOOLTIP_SHIFT"], 1, 1, 1)
            tooltip:AddLine(L["MINIMAP_TOOLTIP_DRAG"], 1, 1, 1)
            local count = HA:GetHiddenCount()
            if count > 0 then
                tooltip:AddLine(" ")
                tooltip:AddLine(L["STATUS_HIDDEN_COUNT"]:format(count), 1, 0.82, 0)
            end
        end,
    })
end
