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
HA._debugMode = false  -- verbose debug logging
HA._frameRetries = {}  -- retry count per frame for ReapplyHiddenFrames

---------------------------------------------------------------------------
-- Undo / Redo stack
---------------------------------------------------------------------------
HA._undoStack = {}
HA._redoStack = {}
local UNDO_MAX = 30

local function PushUndo(action)
    table.insert(HA._undoStack, action)
    if #HA._undoStack > UNDO_MAX then
        table.remove(HA._undoStack, 1)
    end
    wipe(HA._redoStack) -- clear redo on new action
end

---------------------------------------------------------------------------
-- Recently Hidden tracking (most recent first, max 10)
---------------------------------------------------------------------------
HA._recentlyHidden = {}
local RECENT_MAX = 10

local function PushRecent(itemName)
    -- Remove if already in list
    for i = #HA._recentlyHidden, 1, -1 do
        if HA._recentlyHidden[i] == itemName then
            table.remove(HA._recentlyHidden, i)
        end
    end
    table.insert(HA._recentlyHidden, 1, itemName)
    if #HA._recentlyHidden > RECENT_MAX then
        table.remove(HA._recentlyHidden)
    end
end

---------------------------------------------------------------------------
-- Catalog index (O(1) lookup by name/cvar/texture)
---------------------------------------------------------------------------
HA._catalogIndex = {} -- built once after FRAME_CATALOG is available

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
            if not HA.db then return end
            HA:ReapplyHiddenFrames()
            HA:ReapplyHiddenCVars()
            HA:ReapplyFrameAlphas()
            HA:ReapplyHiddenTextures()
            HA:ReapplyCombatStateDrivers()
        end)
    elseif event == "PLAYER_REGEN_DISABLED" then
        HA.inCombat = true
        HA:DebugLog("Entered combat")
        HA:ApplyCombatHides()
    elseif event == "PLAYER_REGEN_ENABLED" then
        HA.inCombat = false
        HA:DebugLog("Left combat")
        HA:RevertCombatHides()
        HA:ProcessPendingQueue()
    end
end)

---------------------------------------------------------------------------
-- Debug logging (improvement #14)
---------------------------------------------------------------------------
function HA:DebugLog(msg)
    if self._debugMode and msg then
        DEFAULT_CHAT_FRAME:AddMessage("|cff888888[HA Debug]|r " .. tostring(msg))
    end
end

function HA:ToggleDebug()
    self._debugMode = not self._debugMode
    self:Print(self._debugMode and "|cff00ff00Debug mode ON|r" or "|cffff4444Debug mode OFF|r")
end

---------------------------------------------------------------------------
-- Combat flag safety timer (improvement #9)
-- Resets inCombat if stuck true for 30+ seconds outside actual combat
---------------------------------------------------------------------------
C_Timer.NewTicker(30, function()
    if HA.inCombat and not InCombatLockdown() then
        HA:DebugLog("Combat flag safety reset (was stuck true)")
        HA.inCombat = false
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

        -- Build catalog index (O(1) lookup)
        for _, entry in ipairs(self.FRAME_CATALOG) do
            if entry.name then
                self._catalogIndex[entry.name] = entry
            elseif entry.cvar then
                self._catalogIndex[entry.cvar] = entry
            elseif entry.texture then
                self._catalogIndex[entry.texture] = entry
            end
        end

        -- Discover EditMode frames (Retail 10.0+)
        if self.DiscoverEditModeFrames then
            self:DiscoverEditModeFrames()
        end

        -- Start auto-save timer (improvement #24)
        self:StartAutoSave()

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
-- Fade animation system
---------------------------------------------------------------------------
HA.FADE_DURATION = 0.3
HA._activeFades = {}

local fadeFrame = CreateFrame("Frame")

local function RunFadeEngine()
    fadeFrame:SetScript("OnUpdate", function(_, dt)
        local anyActive = false
        for frameName, data in pairs(HA._activeFades) do
            anyActive = true
            data.elapsed = data.elapsed + dt
            local progress = data.elapsed / data.duration
            if progress >= 1 then
                pcall(function() data.frame:SetAlpha(data.endAlpha) end)
                HA._activeFades[frameName] = nil
                if data.onFinish then data.onFinish() end
            else
                local alpha = data.startAlpha + (data.endAlpha - data.startAlpha) * progress
                pcall(function() data.frame:SetAlpha(alpha) end)
            end
        end
        if not anyActive then
            fadeFrame:SetScript("OnUpdate", nil)
        end
    end)
end

function HA:CancelFade(frameName)
    self._activeFades[frameName] = nil
end

function HA:IsFading(frameName)
    return self._activeFades[frameName] ~= nil
end

function HA:FadeOutAndHide(frame, frameName)
    self:CancelFade(frameName)

    local startAlpha = frame:GetAlpha()
    if startAlpha <= 0 then
        self:SecureHideFrame(frame, frameName)
        if self.db then self.db.hiddenFrames[frameName] = true end
        if self.RefreshFrameList then self:RefreshFrameList() end
        return
    end

    self._activeFades[frameName] = {
        frame      = frame,
        startAlpha = startAlpha,
        endAlpha   = 0,
        elapsed    = 0,
        duration   = self.FADE_DURATION,
        onFinish   = function()
            HA:SecureHideFrame(frame, frameName)
            if HA.db then HA.db.hiddenFrames[frameName] = true end
            if HA.RefreshFrameList then HA:RefreshFrameList() end
        end,
    }
    RunFadeEngine()
end

function HA:FadeInAndShow(frame, frameName)
    self:CancelFade(frameName)

    local targetAlpha = self:GetFrameAlpha(frameName)

    pcall(function()
        frame:SetAlpha(0)
        frame:Show()
    end)

    self._activeFades[frameName] = {
        frame      = frame,
        startAlpha = 0,
        endAlpha   = targetAlpha,
        elapsed    = 0,
        duration   = self.FADE_DURATION,
        onFinish   = function()
            pcall(function() frame:SetAlpha(targetAlpha) end)
        end,
    }
    RunFadeEngine()
end

---------------------------------------------------------------------------
-- Shared nested name resolution helper (improvement #17)
---------------------------------------------------------------------------
local function ResolveNestedName(name)
    if not name or name == "" then return nil end
    local obj = _G[name]
    if obj then return obj end
    -- Try nested names (e.g. "PlayerFrame.PlayerFrameContent")
    local parts = { strsplit(".", name) }
    obj = _G[parts[1]]
    for i = 2, #parts do
        if obj and type(obj) == "table" then
            obj = obj[parts[i]]
        else
            return nil
        end
    end
    return obj
end

---------------------------------------------------------------------------
-- Get a frame object from its name string
---------------------------------------------------------------------------
function HA:GetFrameByName(name)
    local obj = ResolveNestedName(name)
    if obj and type(obj) == "table" and obj.IsObjectType and obj:IsObjectType("Frame") then
        return obj
    end
    return nil
end

---------------------------------------------------------------------------
-- Get any region (texture, fontstring, frame) by global name
---------------------------------------------------------------------------
function HA:GetRegionByName(name)
    local obj = ResolveNestedName(name)
    if obj and type(obj) == "table" and obj.Hide and obj.Show then
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
    if self:GetSetting("fadeEnabled") then
        self:FeedbackHide(frameName)
        self:FadeOutAndHide(frame, frameName)
        PushUndo({ type = "frame", action = "hide", name = frameName })
        PushRecent(frameName)
        return true
    end

    local success = self:SecureHideFrame(frame, frameName)
    if success then
        self.db.hiddenFrames[frameName] = true
        self:FeedbackHide(frameName)
        PushUndo({ type = "frame", action = "hide", name = frameName })
        PushRecent(frameName)
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

    -- Cancel any active fade-out for this frame
    self:CancelFade(frameName)

    -- Remove from DB FIRST (before showing, so the re-hide hook doesn't trigger)
    self.db.hiddenFrames[frameName] = nil

    -- Find the frame and show it
    local frame = self:GetFrameByName(frameName)
    if frame then
        if self:GetSetting("fadeEnabled") then
            self:FadeInAndShow(frame, frameName)
        else
            self:SecureShowFrame(frame, frameName)
        end
    end

    self:FeedbackShow(frameName)
    PushUndo({ type = "frame", action = "show", name = frameName })

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

    -- Combat check (improvement #4)
    if self.inCombat or InCombatLockdown() then
        self:FeedbackCombatError()
        table.insert(pendingQueue, { action = "hidecvar", cvar = cvarName })
        return false
    end

    if self.db.hiddenCVars[cvarName] then return false end

    local ok = pcall(SetCVar, cvarName, "0")
    if not ok then
        self:FeedbackError("ERROR_CVAR_FAILED", cvarName)
        return false
    end

    self.db.hiddenCVars[cvarName] = true

    local entry = self._catalogIndex[cvarName]
    local displayName = entry and self:GetCatalogLabel(entry) or cvarName
    self:FeedbackHide(displayName)

    PushUndo({ type = "cvar", action = "hide", cvar = cvarName })
    PushRecent(cvarName)

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

    local ok = pcall(SetCVar, cvarName, "1")
    if not ok then
        self:FeedbackError("ERROR_CVAR_FAILED", cvarName)
        return false
    end
    self.db.hiddenCVars[cvarName] = nil

    local entry = self._catalogIndex[cvarName]
    local displayName = entry and self:GetCatalogLabel(entry) or cvarName
    self:FeedbackShow(displayName)

    PushUndo({ type = "cvar", action = "show", cvar = cvarName })

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

    -- Improvement #1: Clear alphas BEFORE showing frames to avoid race condition
    -- where re-hide hooks could re-apply saved alpha during Show()
    local savedAlphas = self.db.frameAlphas
    if savedAlphas then
        for fName, _ in pairs(savedAlphas) do
            local f = self:GetFrameByName(fName)
            if f then
                pcall(function() f:SetAlpha(1) end)
            end
        end
        wipe(self.db.frameAlphas)
    end

    -- Collect frame names, then clear DB BEFORE showing frames
    -- so the re-hide hooks (which check hiddenFrames) don't re-hide them
    local framesToShow = {}
    for frameName, _ in pairs(self.db.hiddenFrames) do
        table.insert(framesToShow, frameName)
        count = count + 1
    end

    if count == 0 then
        self:FeedbackNoFramesHidden()
        return
    end

    wipe(self.db.hiddenFrames)

    for _, frameName in ipairs(framesToShow) do
        local frame = self:GetFrameByName(frameName)
        if frame then
            self:SecureShowFrame(frame, frameName)
        end
    end

    -- Also restore all hidden CVars
    if self.db.hiddenCVars then
        for cvarName, _ in pairs(self.db.hiddenCVars) do
            pcall(SetCVar, cvarName, "1")
            count = count + 1
        end
        wipe(self.db.hiddenCVars)
    end

    -- Also restore all hidden textures (clear DB first to prevent re-hide hooks)
    if self.db.hiddenTextures then
        local texturesToShow = {}
        for textureName, _ in pairs(self.db.hiddenTextures) do
            table.insert(texturesToShow, textureName)
            count = count + 1
        end
        wipe(self.db.hiddenTextures)
        for _, textureName in ipairs(texturesToShow) do
            local region = self:GetRegionByName(textureName)
            if region then
                pcall(function() region:SetAlpha(1); region:Show() end)
            end
        end
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

    -- Retry failed frames after a short delay (improvement #6: max 3 retries)
    if #failed > 0 then
        C_Timer.After(2.0, function()
            if not HA.db then return end
            local stillFailed = {}
            for _, frameName in ipairs(failed) do
                local frame = HA:GetFrameByName(frameName)
                if frame then
                    HA:SecureHideFrame(frame, frameName)
                    HA._frameRetries[frameName] = nil
                else
                    local retries = (HA._frameRetries[frameName] or 0) + 1
                    if retries < 3 then
                        HA._frameRetries[frameName] = retries
                        table.insert(stillFailed, frameName)
                        HA:DebugLog("Retry " .. retries .. "/3 for frame: " .. frameName)
                    else
                        HA:DebugLog("Giving up on frame after 3 retries: " .. frameName)
                        HA._frameRetries[frameName] = nil
                    end
                end
            end
            -- Recursive retry for remaining
            if #stillFailed > 0 then
                C_Timer.After(2.0, function()
                    if not HA.db then return end
                    for _, frameName in ipairs(stillFailed) do
                        local frame = HA:GetFrameByName(frameName)
                        if frame then
                            HA:SecureHideFrame(frame, frameName)
                        end
                        HA._frameRetries[frameName] = nil
                    end
                end)
            end
        end)
    end
end

---------------------------------------------------------------------------
-- Mouseover reveal system: show hidden frames at reduced alpha on hover
---------------------------------------------------------------------------
HA._mouseoverHovered = {}    -- frameName -> true while mouse is over it
HA._mouseoverHooked = {}     -- frameName -> true once OnEnter/OnLeave are hooked

function HA:SetupMouseoverReveal(frame, frameName)
    if self._mouseoverHooked[frameName] then return end

    -- Frame must be mouse-enabled for OnEnter/OnLeave to fire
    if frame.EnableMouse and not frame:IsMouseEnabled() then
        pcall(function() frame:EnableMouse(true) end)
    end

    pcall(function()
        frame:HookScript("OnEnter", function(f)
            if not HA:GetSetting("mouseoverReveal") then return end
            if not (HA.db and HA.db.hiddenFrames and HA.db.hiddenFrames[frameName]) then return end
            HA._mouseoverHovered[frameName] = true
            local alpha = HA:GetSetting("mouseoverAlpha") or 0.4
            pcall(function() f:SetAlpha(alpha) end)
        end)

        frame:HookScript("OnLeave", function(f)
            if not HA:GetSetting("mouseoverReveal") then return end
            HA._mouseoverHovered[frameName] = nil
            if HA.db and HA.db.hiddenFrames and HA.db.hiddenFrames[frameName] then
                pcall(function() f:SetAlpha(0) end)
            end
        end)
    end)

    self._mouseoverHooked[frameName] = true
end

-- Re-apply hiding mode for all hidden frames (called when mouseoverReveal changes)
function HA:ApplyMouseoverRevealMode()
    if not self.db or not self.db.hiddenFrames then return end
    if InCombatLockdown() then return end

    local reveal = self:GetSetting("mouseoverReveal")

    for frameName, _ in pairs(self.db.hiddenFrames) do
        local frame = self:GetFrameByName(frameName)
        if frame then
            if reveal then
                -- Mouseover mode: Show frame at alpha 0 so it receives mouse events
                pcall(function()
                    frame:SetAlpha(0)
                    frame:Show()
                end)
                self:SetupMouseoverReveal(frame, frameName)
            else
                -- Normal mode: fully hide the frame
                self._mouseoverHovered[frameName] = nil
                pcall(function()
                    frame:Hide()
                    frame:SetAlpha(0)
                end)
            end
        end
    end
end

---------------------------------------------------------------------------
-- Securely hide a frame (with hook to prevent it from re-showing)
---------------------------------------------------------------------------
HA.hookedFrames = {}

function HA:SecureHideFrame(frame, frameName)
    if not frame then return false end

    local reveal = self:GetSetting("mouseoverReveal")

    local success, err = pcall(function()
        if reveal then
            -- Mouseover mode: only set alpha to 0, keep frame shown for mouse events
            frame:SetAlpha(0)
            frame:Show()
        else
            frame:Hide()
            frame:SetAlpha(0)
        end
    end)

    if not success then
        self:FeedbackError("ERROR_FRAME_PROTECTED", frameName)
        return false
    end

    -- Also try to unregister events so the frame doesn't re-trigger itself
    -- (skip when mouseover reveal is on - frame needs to process mouse events)
    if not reveal then
        pcall(function()
            if frame.UnregisterAllEvents then
                -- Store original events so we can re-register on show
                if not self._savedEvents then self._savedEvents = {} end
                -- Only unregister if we haven't already saved events for this frame
                if not self._savedEvents[frameName] then
                    self._savedEvents[frameName] = true
                end
                frame:UnregisterAllEvents()
            end
        end)
    end

    -- Set up mouseover hooks if enabled
    if reveal then
        self:SetupMouseoverReveal(frame, frameName)
    end

    -- Hook Show(), SetShown(), and SetAlpha() to prevent re-appearing
    if not self.hookedFrames[frameName] then
        local hookSuccess = pcall(function()
            hooksecurefunc(frame, "Show", function(f)
                if HA:IsFading(frameName) then return end
                if HA.db and HA.db.hiddenFrames and HA.db.hiddenFrames[frameName] then
                    if not InCombatLockdown() then
                        if HA:GetSetting("mouseoverReveal") then
                            -- Keep shown but ensure alpha stays correct
                            if not HA._mouseoverHovered[frameName] then
                                f:SetAlpha(0)
                            end
                        else
                            f:Hide()
                            f:SetAlpha(0)
                        end
                    end
                end
            end)
            hooksecurefunc(frame, "SetShown", function(f, shown)
                if HA:IsFading(frameName) then return end
                if shown and HA.db and HA.db.hiddenFrames and HA.db.hiddenFrames[frameName] then
                    if not InCombatLockdown() then
                        if HA:GetSetting("mouseoverReveal") then
                            if not HA._mouseoverHovered[frameName] then
                                f:SetAlpha(0)
                            end
                        else
                            f:Hide()
                            f:SetAlpha(0)
                        end
                    end
                end
            end)
            -- Hook SetAlpha so Blizzard's layout system can't reset opacity
            hooksecurefunc(frame, "SetAlpha", function(f, alpha)
                if HA:IsFading(frameName) then return end
                if HA._mouseoverHovered and HA._mouseoverHovered[frameName] then return end
                if alpha and alpha > 0 and HA.db and HA.db.hiddenFrames and HA.db.hiddenFrames[frameName] then
                    if not InCombatLockdown() then
                        f:SetAlpha(0)
                    end
                end
            end)
        end)

        if hookSuccess then
            self.hookedFrames[frameName] = true
            self:DebugLog("Hooked frame: " .. frameName)
        else
            self:FeedbackError("ERROR_HOOK_FAILED", frameName)
            self:DebugLog("Hook FAILED for: " .. frameName)
        end
    end

    return true
end

---------------------------------------------------------------------------
-- Securely show a frame
---------------------------------------------------------------------------
function HA:SecureShowFrame(frame, frameName)
    if not frame then return end

    -- Clear mouseover hover state
    self._mouseoverHovered[frameName] = nil

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
-- Combat auto-hide: secure state drivers (immune to taint)
---------------------------------------------------------------------------
HA._combatStateDrivers = {}  -- frameName -> true if RegisterStateDriver active

-- Register a secure state driver for combat visibility (must be called outside combat)
function HA:RegisterCombatStateDriver(frameName)
    if InCombatLockdown() then return false end
    if self._combatStateDrivers[frameName] then return true end

    local frame = self:GetFrameByName(frameName)
    if not frame then return false end

    local ok = pcall(RegisterStateDriver, frame, "visibility", "[combat] hide; show")
    if ok then
        self._combatStateDrivers[frameName] = true
        self:DebugLog("Registered combat state driver for: " .. frameName)
        return true
    end
    return false
end

-- Unregister a combat state driver (must be called outside combat)
function HA:UnregisterCombatStateDriver(frameName)
    if InCombatLockdown() then return false end
    if not self._combatStateDrivers[frameName] then return true end

    local frame = self:GetFrameByName(frameName)
    if frame then
        pcall(UnregisterStateDriver, frame, "visibility")
        -- Restore visibility if not permanently hidden
        if not (self.db and self.db.hiddenFrames and self.db.hiddenFrames[frameName]) then
            pcall(function() frame:Show() end)
        end
    end
    self._combatStateDrivers[frameName] = nil
    self:DebugLog("Unregistered combat state driver for: " .. frameName)
    return true
end

-- Reapply all combat state drivers (after login/reload)
function HA:ReapplyCombatStateDrivers()
    if not self.db or not self.db.combatHideFrames then return end
    if InCombatLockdown() then return end

    for frameName, _ in pairs(self.db.combatHideFrames) do
        -- Only register state drivers for frames not permanently hidden
        if not self.db.hiddenFrames[frameName] then
            self:RegisterCombatStateDriver(frameName)
        end
    end
end

---------------------------------------------------------------------------
-- Combat auto-hide: hide tagged frames on combat start
---------------------------------------------------------------------------
HA._combatHiddenNow = nil

function HA:ApplyCombatHides()
    if not self.db or not self.db.combatHideFrames then return end
    self._combatHiddenNow = {}
    for frameName, _ in pairs(self.db.combatHideFrames) do
        -- Only hide frames that are currently visible and not already hidden by the user
        if not self.db.hiddenFrames[frameName] then
            -- If a state driver is registered, it handles hiding automatically
            if self._combatStateDrivers[frameName] then
                self._combatHiddenNow[frameName] = "statedriver"
            else
                local frame = self:GetFrameByName(frameName)
                if frame and frame:IsShown() then
                    local ok = pcall(function() frame:Hide() end)
                    -- Fallback: if Hide() was blocked by taint, use alpha as backup
                    if not ok or frame:IsShown() then
                        pcall(function() frame:SetAlpha(0) end)
                        self._combatHiddenNow[frameName] = "alpha"
                    else
                        self._combatHiddenNow[frameName] = "hide"
                    end
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- Combat auto-hide: restore frames after combat ends
---------------------------------------------------------------------------
function HA:RevertCombatHides()
    if not self._combatHiddenNow then return end
    for frameName, hideMethod in pairs(self._combatHiddenNow) do
        -- Only restore if the user didn't manually hide it during combat
        if not self.db.hiddenFrames[frameName] then
            if hideMethod == "statedriver" then
                -- State driver handles show automatically, nothing to do
            else
                local frame = self:GetFrameByName(frameName)
                if frame then
                    local alpha = self:GetFrameAlpha(frameName)
                    pcall(function()
                        frame:SetAlpha(alpha)
                        frame:Show()
                    end)
                end
            end
        end
    end
    self._combatHiddenNow = nil
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
        elseif entry.action == "hidecvar" then
            self:HideCVar(entry.cvar)
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
    if self.db and self.db.hiddenTextures then
        for _ in pairs(self.db.hiddenTextures) do
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

    -- Improvement #8: Limit to 50 entries to avoid chat flood
    local MAX_DISPLAY = 50
    local i = 1
    for frameName, _ in pairs(self.db.hiddenFrames) do
        if i > MAX_DISPLAY then break end
        self:Print(L["LIST_ENTRY"]:format(i, frameName))
        i = i + 1
    end
    if self.db.hiddenTextures and i <= MAX_DISPLAY then
        for textureName, _ in pairs(self.db.hiddenTextures) do
            if i > MAX_DISPLAY then break end
            self:Print(L["LIST_ENTRY"]:format(i, textureName .. " |cff555560(Texture)|r"))
            i = i + 1
        end
    end
    if count > MAX_DISPLAY then
        self:Print((L["LIST_TRUNCATED"] or "|cff888888...and %d more. Use /hide toggle to see all.|r"):format(count - MAX_DISPLAY))
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
            if not HA then return end
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

---------------------------------------------------------------------------
-- Texture/Region hiding system
---------------------------------------------------------------------------

-- Hook a texture/region to prevent re-showing
function HA:HookTexture(region, textureName)
    if self.hookedFrames[textureName] then return end
    local ok = pcall(function()
        hooksecurefunc(region, "Show", function(r)
            if HA.db and HA.db.hiddenTextures and HA.db.hiddenTextures[textureName] then
                pcall(function() r:Hide(); r:SetAlpha(0) end)
            end
        end)
        if region.SetShown then
            hooksecurefunc(region, "SetShown", function(r, shown)
                if shown and HA.db and HA.db.hiddenTextures and HA.db.hiddenTextures[textureName] then
                    pcall(function() r:Hide(); r:SetAlpha(0) end)
                end
            end)
        end
        hooksecurefunc(region, "SetAlpha", function(r, alpha)
            if alpha and alpha > 0 and HA.db and HA.db.hiddenTextures and HA.db.hiddenTextures[textureName] then
                pcall(function() r:SetAlpha(0) end)
            end
        end)
    end)
    if ok then self.hookedFrames[textureName] = true end
end

-- Hide a texture/region by name
function HA:HideTexture(textureName)
    if not textureName or textureName == "" then return false end
    if not self.db or not self.db.hiddenTextures then return false end
    if self.db.hiddenTextures[textureName] then return false end

    local region = self:GetRegionByName(textureName)
    if not region then
        self:FeedbackFrameNotFound(textureName)
        return false
    end

    local ok = pcall(function()
        region:Hide()
        region:SetAlpha(0)
    end)
    if not ok then return false end

    self.db.hiddenTextures[textureName] = true
    self:HookTexture(region, textureName)

    local entry = self._catalogIndex[textureName]
    local displayName = entry and self:GetCatalogLabel(entry) or textureName
    self:FeedbackHide(displayName)
    PushUndo({ type = "texture", action = "hide", texture = textureName })
    PushRecent(textureName)
    if self.RefreshFrameList then self:RefreshFrameList() end
    return true
end

-- Show a texture/region by name
function HA:ShowTexture(textureName)
    if not textureName or textureName == "" then return false end
    if not self.db or not self.db.hiddenTextures then return false end
    if not self.db.hiddenTextures[textureName] then return false end

    self.db.hiddenTextures[textureName] = nil

    local region = self:GetRegionByName(textureName)
    if region then
        pcall(function()
            region:SetAlpha(1)
            region:Show()
        end)
    end

    local entry = self._catalogIndex[textureName]
    local displayName = entry and self:GetCatalogLabel(entry) or textureName
    self:FeedbackShow(displayName)
    PushUndo({ type = "texture", action = "show", texture = textureName })
    if self.RefreshFrameList then self:RefreshFrameList() end
    return true
end

-- Reapply hidden textures after login/reload
function HA:ReapplyHiddenTextures()
    if not self.db or not self.db.hiddenTextures then return end

    local failed = {}
    for textureName, _ in pairs(self.db.hiddenTextures) do
        local region = self:GetRegionByName(textureName)
        if region then
            pcall(function() region:Hide(); region:SetAlpha(0) end)
            self:HookTexture(region, textureName)
        else
            table.insert(failed, textureName)
        end
    end

    -- Retry failed textures after a short delay
    if #failed > 0 then
        C_Timer.After(2.0, function()
            if not HA.db then return end
            for _, textureName in ipairs(failed) do
                local region = HA:GetRegionByName(textureName)
                if region then
                    pcall(function() region:Hide(); region:SetAlpha(0) end)
                    HA:HookTexture(region, textureName)
                end
            end
        end)
    end
end

---------------------------------------------------------------------------
-- Undo / Redo public API
---------------------------------------------------------------------------
local function DoUndoRedo(srcStack, dstStack, isUndo)
    local L = HA.L
    if #srcStack == 0 then
        local emptyKey = isUndo and "UNDO_EMPTY" or "REDO_EMPTY"
        local emptyFallback = isUndo and "Nothing to undo." or "Nothing to redo."
        HA:Print(L[emptyKey] or emptyFallback)
        return false
    end

    local action = table.remove(srcStack)
    table.insert(dstStack, action)

    -- For undo: reverse the action (hide->show, show->hide)
    -- For redo: re-apply the action as-is
    local effectiveAction
    if isUndo then
        effectiveAction = (action.action == "hide") and "show" or "hide"
    else
        effectiveAction = action.action
    end

    local hiddenKey = isUndo and "UNDO_HIDDEN" or "REDO_HIDDEN"
    local shownKey  = isUndo and "UNDO_SHOWN"  or "REDO_SHOWN"
    local hiddenFallback = isUndo and "Undo: hidden |cffff8800%s|r" or "Redo: hidden |cffff8800%s|r"
    local shownFallback  = isUndo and "Undo: shown |cff00ff00%s|r"  or "Redo: shown |cff00ff00%s|r"

    if action.type == "frame" then
        if effectiveAction == "show" then
            HA.db.hiddenFrames[action.name] = nil
            local frame = HA:GetFrameByName(action.name)
            if frame then HA:SecureShowFrame(frame, action.name) end
            HA:ChatMsg((L[shownKey] or shownFallback):format(action.name))
        else
            local frame = HA:GetFrameByName(action.name)
            if frame then HA:SecureHideFrame(frame, action.name) end
            HA.db.hiddenFrames[action.name] = true
            HA:ChatMsg((L[hiddenKey] or hiddenFallback):format(action.name))
        end
    elseif action.type == "cvar" then
        if effectiveAction == "show" then
            pcall(SetCVar, action.cvar, "1")
            HA.db.hiddenCVars[action.cvar] = nil
            HA:ChatMsg((L[shownKey] or shownFallback):format(action.cvar))
        else
            pcall(SetCVar, action.cvar, "0")
            HA.db.hiddenCVars[action.cvar] = true
            HA:ChatMsg((L[hiddenKey] or hiddenFallback):format(action.cvar))
        end
    elseif action.type == "texture" then
        if effectiveAction == "show" then
            HA:ShowTexture(action.texture)
        else
            HA:HideTexture(action.texture)
        end
    end

    if HA.RefreshFrameList then HA:RefreshFrameList() end
    return true
end

function HA:Undo()
    return DoUndoRedo(self._undoStack, self._redoStack, true)
end

function HA:Redo()
    return DoUndoRedo(self._redoStack, self._undoStack, false)
end

function HA:GetRecentlyHidden()
    return self._recentlyHidden
end

---------------------------------------------------------------------------
-- Preset profiles
---------------------------------------------------------------------------
HA.PRESET_PROFILES = {
    {
        id = "minimalist",
        label = "Minimalist UI",
        labelDE = "Minimalistische UI",
        labelFR = "Interface minimaliste",
        labelES = "Interfaz minimalista",
        labelRU = "Минимальный интерфейс",
        labelIT = "Interfaccia minimalista",
        frames = {
            "MinimapCluster", "BuffFrame", "DebuffFrame",
            "ChatFrame1", "GeneralDockManager", "ChatFrameMenuButton",
            "DurabilityFrame", "QueueStatusButton",
            "MicroMenuContainer", "BagBar",
            "ObjectiveTrackerFrame",
        },
    },
    {
        id = "pvp_clean",
        label = "PvP Clean",
        labelDE = "PvP Aufgeräumt",
        labelFR = "JcJ épuré",
        labelES = "JcJ limpio",
        labelRU = "PvP чисто",
        labelIT = "PvP pulito",
        frames = {
            "BuffFrame", "DebuffFrame", "ObjectiveTrackerFrame",
            "ChatFrame1", "GeneralDockManager",
            "BossBanner", "AlertFrame", "ZoneTextFrame", "SubZoneTextFrame",
            "DurabilityFrame", "UIErrorsFrame",
        },
    },
    {
        id = "healer",
        label = "Healer Setup",
        labelDE = "Heiler Setup",
        labelFR = "Configuration guérisseur",
        labelES = "Configuración sanador",
        labelRU = "Настройка хилера",
        labelIT = "Configurazione guaritore",
        frames = {
            "ObjectiveTrackerFrame", "BossBanner",
            "ZoneTextFrame", "SubZoneTextFrame",
            "ChatFrame1", "GeneralDockManager",
            "DurabilityFrame", "UIErrorsFrame", "RaidWarningFrame",
        },
    },
    {
        id = "screenshot",
        label = "Screenshot Mode",
        labelDE = "Screenshot-Modus",
        labelFR = "Mode capture d'écran",
        labelES = "Modo captura de pantalla",
        labelRU = "Режим скриншота",
        labelIT = "Modalità screenshot",
        frames = {
            "PlayerFrame", "TargetFrame", "FocusFrame", "PetFrame",
            "MainMenuBar", "MultiBarBottomLeft", "MultiBarBottomRight",
            "MultiBarRight", "MultiBarLeft",
            "MinimapCluster", "BuffFrame", "DebuffFrame",
            "ChatFrame1", "GeneralDockManager", "ChatFrameMenuButton",
            "ObjectiveTrackerFrame", "MicroMenuContainer", "BagBar",
            "StanceBar", "DurabilityFrame",
        },
    },
}

function HA:GetPresetLabel(preset)
    if preset.custom then return preset.label end
    local lang = self._currentLanguage or "enUS"
    if lang == "deDE" and preset.labelDE then return preset.labelDE end
    if lang == "frFR" and preset.labelFR then return preset.labelFR end
    if lang == "esES" and preset.labelES then return preset.labelES end
    if lang == "ruRU" and preset.labelRU then return preset.labelRU end
    if lang == "itIT" and preset.labelIT then return preset.labelIT end
    return preset.label
end

---------------------------------------------------------------------------
-- Get all presets (built-in + custom)
---------------------------------------------------------------------------
function HA:GetAllPresets()
    local all = {}
    for _, preset in ipairs(self.PRESET_PROFILES) do
        table.insert(all, preset)
    end
    if self.db and self.db.customPresets then
        for id, data in pairs(self.db.customPresets) do
            table.insert(all, {
                id     = id,
                label  = data.label or id,
                frames = data.frames or {},
                custom = true,
            })
        end
    end
    return all
end

---------------------------------------------------------------------------
-- Save current hidden frames as a custom preset
---------------------------------------------------------------------------
function HA:SaveCustomPreset(name)
    local L = self.L
    if not name or name == "" then
        self:Print(L["PROFILE_NAME_REQUIRED"] or "Please enter a name.")
        return false
    end
    if not self.db then return false end

    -- Collect currently hidden frame names
    local frames = {}
    if self.db.hiddenFrames then
        for frameName, _ in pairs(self.db.hiddenFrames) do
            table.insert(frames, frameName)
        end
    end
    if #frames == 0 then
        self:Print(L["PRESET_SAVE_EMPTY"] or "No hidden frames to save as preset.")
        return false
    end

    -- Generate a safe ID from the name
    local id = "custom_" .. name:gsub("[^%w]", "_"):lower()

    self.db.customPresets[id] = {
        label  = name,
        frames = frames,
    }
    self:ChatMsg((L["PRESET_SAVED"] or "Preset |cff00cc66%s|r saved with %d frames."):format(name, #frames))
    return true
end

---------------------------------------------------------------------------
-- Delete a custom preset
---------------------------------------------------------------------------
function HA:DeleteCustomPreset(presetId)
    if not self.db or not self.db.customPresets then return false end
    if not self.db.customPresets[presetId] then return false end

    local name = self.db.customPresets[presetId].label or presetId
    self.db.customPresets[presetId] = nil
    self:ChatMsg((self.L["PRESET_DELETED"] or "Preset |cffff4444%s|r deleted."):format(name))
    return true
end

---------------------------------------------------------------------------
-- Get the effective frames list for a preset (custom override or default)
---------------------------------------------------------------------------
function HA:GetPresetFrames(presetId)
    -- Custom override takes priority
    if self.db and self.db.customPresets and self.db.customPresets[presetId] then
        return self.db.customPresets[presetId].frames or {}
    end
    -- Fall back to built-in
    for _, preset in ipairs(self.PRESET_PROFILES) do
        if preset.id == presetId then
            return preset.frames
        end
    end
    return {}
end

---------------------------------------------------------------------------
-- Update frames list for a preset (creates custom override for built-ins)
---------------------------------------------------------------------------
function HA:UpdatePresetFrames(presetId, frames)
    if not self.db then return false end

    -- For built-in presets: create/update a custom override
    if not self.db.customPresets[presetId] then
        -- Find the built-in preset to get label
        local label = presetId
        for _, preset in ipairs(self.PRESET_PROFILES) do
            if preset.id == presetId then
                label = self:GetPresetLabel(preset)
                break
            end
        end
        self.db.customPresets[presetId] = { label = label, frames = {} }
    end
    self.db.customPresets[presetId].frames = frames
    return true
end

---------------------------------------------------------------------------
-- Reset a built-in preset to its default frames
---------------------------------------------------------------------------
function HA:ResetPresetToDefault(presetId)
    if not self.db or not self.db.customPresets then return false end
    -- Only makes sense for built-in presets that have a custom override
    for _, preset in ipairs(self.PRESET_PROFILES) do
        if preset.id == presetId then
            self.db.customPresets[presetId] = nil
            self:ChatMsg((self.L["PRESET_RESET"] or "Preset |cff00cc66%s|r reset to default."):format(self:GetPresetLabel(preset)))
            return true
        end
    end
    return false
end

---------------------------------------------------------------------------
-- Check if a built-in preset has a custom override
---------------------------------------------------------------------------
function HA:IsPresetCustomized(presetId)
    return self.db and self.db.customPresets and self.db.customPresets[presetId] ~= nil
end

---------------------------------------------------------------------------
-- Apply a preset (built-in or custom)
---------------------------------------------------------------------------
function HA:ApplyPreset(presetId, confirmed)
    -- Search built-in presets
    local preset
    for _, p in ipairs(self.PRESET_PROFILES) do
        if p.id == presetId then
            preset = p
            break
        end
    end
    -- Search custom presets
    if not preset and self.db and self.db.customPresets and self.db.customPresets[presetId] then
        local data = self.db.customPresets[presetId]
        preset = { id = presetId, label = data.label or presetId, frames = data.frames or {}, custom = true }
    end

    if not preset then return false end

    -- Confirm before applying (slash command only, UI passes confirmed=true)
    if not confirmed then
        if self._pendingPreset == presetId then
            self._pendingPreset = nil
        else
            self._pendingPreset = presetId
            self:Print((self.L["PRESET_CONFIRM"] or "|cffffcc00Warning|r: This will show all currently hidden frames first. Repeat |cff00cc66/hide preset %s|r to confirm."):format(presetId))
            C_Timer.After(10, function()
                if HA._pendingPreset == presetId then
                    HA._pendingPreset = nil
                end
            end)
            return true
        end
    end

    -- Show all current hidden frames first
    self:ShowAllFrames()
    -- Apply preset frames (use GetPresetFrames for custom overrides)
    local frames = self:GetPresetFrames(presetId)
    for _, frameName in ipairs(frames) do
        self:HideFrame(frameName)
    end
    self:ChatMsg((self.L["PRESET_APPLIED"] or "Preset |cff00cc66%s|r applied."):format(self:GetPresetLabel(preset)))
    return true
end

---------------------------------------------------------------------------
-- Wildcard hide: /hide hide Player* (improvement #23)
---------------------------------------------------------------------------
function HA:HideByPattern(pattern)
    if not pattern or pattern == "" then return 0 end

    local count = 0
    -- Convert glob pattern (* only) to Lua pattern
    local luaPattern = "^" .. pattern:gsub("%%", "%%%%"):gsub("%*", ".*"):gsub("%?", ".") .. "$"

    for _, entry in ipairs(self.FRAME_CATALOG) do
        local itemName = entry.name or entry.cvar or entry.texture
        if itemName and itemName:match(luaPattern) then
            if entry.name and not self.db.hiddenFrames[itemName] then
                self:HideFrame(itemName)
                count = count + 1
            elseif entry.cvar and not self.db.hiddenCVars[itemName] then
                self:HideCVar(itemName)
                count = count + 1
            elseif entry.texture and not self.db.hiddenTextures[itemName] then
                self:HideTexture(itemName)
                count = count + 1
            end
        end
    end

    if count > 0 then
        self:Print((self.L["WILDCARD_HIDDEN"] or "Hidden |cff00cc66%d|r frames matching pattern |cffffffff%s|r."):format(count, pattern))
    else
        self:Print((self.L["WILDCARD_NO_MATCH"] or "No frames found matching pattern |cffffffff%s|r."):format(pattern))
    end
    return count
end

---------------------------------------------------------------------------
-- Auto-save timer (improvement #24)
-- Saves current state to an "AutoSave" profile every 5 minutes
---------------------------------------------------------------------------
function HA:StartAutoSave()
    if self._autoSaveTimer then return end
    self._autoSaveTimer = C_Timer.NewTicker(300, function()
        if not HA.db then return end
        local count = HA:GetHiddenCount()
        if count > 0 then
            HA.db.profiles["_AutoSave"] = {
                hiddenFrames   = HA:DeepCopy(HA.db.hiddenFrames),
                hiddenCVars    = HA:DeepCopy(HA.db.hiddenCVars or {}),
                hiddenTextures = HA:DeepCopy(HA.db.hiddenTextures or {}),
                frameAlphas    = HA:DeepCopy(HA.db.frameAlphas or {}),
                settings       = HA:DeepCopy(HA.db.settings),
                savedTime      = time(),
            }
            HA:DebugLog("Auto-saved current state (" .. count .. " frames)")
        end
    end)
end
