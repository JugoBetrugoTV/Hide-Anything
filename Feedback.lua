--[[
    HideAnything - Feedback.lua
    Sound feedback, chat messages, on-screen floating text, error speech
    Central feedback system - all user notifications go through here
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
-- Per-action sound toggle map: soundKey -> settingKey
---------------------------------------------------------------------------
local SOUND_TOGGLE_MAP = {
    hide        = "soundHideEnabled",
    show        = "soundShowEnabled",
    error       = "soundErrorEnabled",
    success     = "soundSuccessEnabled",
    pickerStart = "soundPickerEnabled",
    pickerStop  = "soundPickerEnabled",
    lock        = "soundLockEnabled",
    unlock      = "soundLockEnabled",
    profileLoad = "soundSuccessEnabled",
    reset       = "soundErrorEnabled",
}

---------------------------------------------------------------------------
-- Play a sound by key name (e.g. "hide", "show", "error")
-- Respects both master toggle and per-action toggle
---------------------------------------------------------------------------
function HA:PlayFeedbackSound(soundKey)
    if not self:GetSetting("soundEnabled") then return end

    -- Check per-action toggle
    local toggleKey = SOUND_TOGGLE_MAP[soundKey]
    if toggleKey and self:GetSetting(toggleKey) == false then return end

    local sounds = self.db and self.db.settings and self.db.settings.sounds
    if not sounds then return end

    local soundID = sounds[soundKey]
    if soundID then
        PlaySound(soundID, "Master")
    end
end

---------------------------------------------------------------------------
-- Force-play a sound (ignores toggles, for UI preview/test)
---------------------------------------------------------------------------
function HA:ForcePlaySound(soundKey)
    local sounds = self.db and self.db.settings and self.db.settings.sounds
    if not sounds then return end

    local soundID = sounds[soundKey]
    if soundID then
        PlaySound(soundID, "Master")
    end
end

---------------------------------------------------------------------------
-- On-screen floating message (UIErrorsFrame style)
---------------------------------------------------------------------------
function HA:ScreenMsg(msg, r, g, b)
    if not self:GetSetting("screenEnabled") then return end
    if not msg then return end

    r = r or 0.0
    g = g or 0.8
    b = b or 0.4

    -- Use UIErrorsFrame for floating text
    if UIErrorsFrame then
        UIErrorsFrame:AddMessage(msg, r, g, b, 1.0)
    end
end

---------------------------------------------------------------------------
-- Error speech (Blizzard voice)
---------------------------------------------------------------------------
function HA:ErrorSpeech(errorMsg)
    if not self:GetSetting("errorSpeech") then return end
    -- UIErrorsFrame handles the red error text + voice
    if UIErrorsFrame and errorMsg then
        UIErrorsFrame:AddMessage(errorMsg, 1.0, 0.1, 0.1, 1.0)
    end
end

---------------------------------------------------------------------------
-- Combined feedback: chat + sound + screen
---------------------------------------------------------------------------

-- Frame was hidden
function HA:FeedbackHide(frameName)
    local L = self.L
    self:ChatMsg(L["FRAME_HIDDEN"]:format(frameName))
    self:PlayFeedbackSound("hide")
    self:ScreenMsg(L["AUDIO_HIDE"] .. ": " .. frameName, 1.0, 0.53, 0.0)
end

-- Frame was shown
function HA:FeedbackShow(frameName)
    local L = self.L
    self:ChatMsg(L["FRAME_SHOWN"]:format(frameName))
    self:PlayFeedbackSound("show")
    self:ScreenMsg(L["AUDIO_SHOW"] .. ": " .. frameName, 0.0, 1.0, 0.0)
end

-- Error occurred
function HA:FeedbackError(errorKey, ...)
    local L = self.L
    local msg = L[errorKey]
    if msg then
        if select("#", ...) > 0 then
            msg = msg:format(...)
        end
        self:Print(msg) -- Always print errors regardless of chat setting
        self:PlayFeedbackSound("error")
        self:ErrorSpeech(msg)
    end
end

-- Picker started
function HA:FeedbackPickerStart()
    local L = self.L
    self:ChatMsg(L["PICKER_STARTED"])
    self:PlayFeedbackSound("pickerStart")
    self:ScreenMsg(L["AUDIO_PICKER_START"], 0.0, 0.8, 0.4)
end

-- Picker stopped
function HA:FeedbackPickerStop()
    local L = self.L
    self:ChatMsg(L["PICKER_STOPPED"])
    self:PlayFeedbackSound("pickerStop")
    self:ScreenMsg(L["AUDIO_PICKER_STOP"], 1.0, 0.27, 0.27)
end

-- Profile loaded
function HA:FeedbackProfileLoaded(profileName, frameCount)
    local L = self.L
    self:ChatMsg(L["PROFILE_LOADED"]:format(profileName, frameCount))
    self:PlayFeedbackSound("profileLoad")
    self:ScreenMsg(L["AUDIO_PROFILE_LOAD"] .. ": " .. profileName, 0.0, 0.8, 0.4)
end

-- Frames locked
function HA:FeedbackLock()
    local L = self.L
    self:ChatMsg(L["FRAMES_LOCKED"])
    self:PlayFeedbackSound("lock")
    self:ScreenMsg(L["AUDIO_LOCK"], 1.0, 0.27, 0.27)
end

-- Frames unlocked
function HA:FeedbackUnlock()
    local L = self.L
    self:ChatMsg(L["FRAMES_UNLOCKED"])
    self:PlayFeedbackSound("unlock")
    self:ScreenMsg(L["AUDIO_UNLOCK"], 0.0, 1.0, 0.0)
end

-- All frames shown
function HA:FeedbackShowAll(count)
    local L = self.L
    self:ChatMsg(L["ALL_FRAMES_SHOWN"]:format(count))
    self:PlayFeedbackSound("success")
    self:ScreenMsg(L["ALL_FRAMES_SHOWN"]:format(count), 0.0, 1.0, 0.0)
end

-- Reset done
function HA:FeedbackReset()
    local L = self.L
    self:ChatMsg(L["RESET_DONE"])
    self:PlayFeedbackSound("reset")
    self:ScreenMsg(L["AUDIO_RESET"], 1.0, 0.27, 0.27)
end

-- Frame is protected error
function HA:FeedbackProtected(frameName)
    local L = self.L
    self:Print(L["PICKER_PROTECTED"]:format(frameName))
    self:PlayFeedbackSound("error")
    self:ErrorSpeech(L["PICKER_PROTECTED"]:format(frameName))
end

-- Frame already hidden
function HA:FeedbackAlreadyHidden(frameName)
    local L = self.L
    self:Print(L["PICKER_ALREADY_HIDDEN"]:format(frameName))
    self:PlayFeedbackSound("error")
end

-- Combat lockdown error
function HA:FeedbackCombatError()
    local L = self.L
    self:Print(L["ERROR_COMBAT"])
    self:PlayFeedbackSound("error")
    self:ErrorSpeech(L["ERROR_COMBAT"])
    self:ScreenMsg(L["ERROR_COMBAT"], 1.0, 0.1, 0.1)
end

-- Frame not found error
function HA:FeedbackFrameNotFound(frameName)
    local L = self.L
    self:Print(L["FRAME_NOT_FOUND"]:format(frameName))
    self:PlayFeedbackSound("error")
end

-- No frames hidden
function HA:FeedbackNoFramesHidden()
    local L = self.L
    self:Print(L["NO_FRAMES_HIDDEN"])
    self:PlayFeedbackSound("error")
end
