--[[
    HideAnything - Feedback.lua
    Chat feedback system - all user notifications go through here
]]

local AddonName, HA = ...

local PREFIX = "|cff00cc66HA|r: "

---------------------------------------------------------------------------
-- Print to chat (with addon prefix)
---------------------------------------------------------------------------
function HA:Print(msg)
    if msg then
        DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. msg)
    end
end

---------------------------------------------------------------------------
-- Chat feedback (respects setting)
---------------------------------------------------------------------------
function HA:ChatMsg(msg)
    if self:GetSetting("chatEnabled") and msg then
        self:Print(msg)
    end
end

---------------------------------------------------------------------------
-- Combined feedback functions
---------------------------------------------------------------------------

function HA:FeedbackHide(frameName)
    local L = self.L
    self:ChatMsg(L["FRAME_HIDDEN"]:format(frameName))
end

function HA:FeedbackShow(frameName)
    local L = self.L
    self:ChatMsg(L["FRAME_SHOWN"]:format(frameName))
end

function HA:FeedbackError(errorKey, ...)
    local L = self.L
    local msg = L[errorKey]
    if msg then
        if select("#", ...) > 0 then
            msg = msg:format(...)
        end
        self:Print(msg)
    end
end

function HA:FeedbackProfileLoaded(profileName, frameCount)
    local L = self.L
    self:ChatMsg(L["PROFILE_LOADED"]:format(profileName, frameCount))
end

function HA:FeedbackLock()
    local L = self.L
    self:ChatMsg(L["FRAMES_LOCKED"])
end

function HA:FeedbackUnlock()
    local L = self.L
    self:ChatMsg(L["FRAMES_UNLOCKED"])
end

function HA:FeedbackShowAll(count)
    local L = self.L
    self:ChatMsg(L["ALL_FRAMES_SHOWN"]:format(count))
end

function HA:FeedbackReset()
    local L = self.L
    self:ChatMsg(L["RESET_DONE"])
end

function HA:FeedbackProtected(frameName)
    local L = self.L
    self:Print(L["PICKER_PROTECTED"]:format(frameName))
end

function HA:FeedbackAlreadyHidden(frameName)
    local L = self.L
    self:Print(L["PICKER_ALREADY_HIDDEN"]:format(frameName))
end

function HA:FeedbackCombatError()
    local L = self.L
    self:Print(L["ERROR_COMBAT"])
end

function HA:FeedbackFrameNotFound(frameName)
    local L = self.L
    self:Print(L["FRAME_NOT_FOUND"]:format(frameName))
end

function HA:FeedbackNoFramesHidden()
    local L = self.L
    self:Print(L["NO_FRAMES_HIDDEN"])
end
