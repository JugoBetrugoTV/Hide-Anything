--[[
    HideAnything - Profiles.lua
    Profile management: save, load, delete, list, export, import
]]

local AddonName, HA = ...

---------------------------------------------------------------------------
-- Save current hidden frames as a profile
---------------------------------------------------------------------------
function HA:SaveProfile(name, overwrite)
    local L = self.L

    if not name or name == "" then
        self:Print(L["PROFILE_NAME_REQUIRED"])
        return
    end

    -- Check if profile already exists
    if self.db.profiles[name] and not overwrite then
        self:Print(L["PROFILE_EXISTS"]:format(name))
        return
    end

    -- Save profile
    self.db.profiles[name] = {
        hiddenFrames = self:DeepCopy(self.db.hiddenFrames),
        settings     = self:DeepCopy(self.db.settings),
    }

    local count = self:GetHiddenCount()
    self:Print(L["PROFILE_SAVED"]:format(name, count))
    self:PlayFeedbackSound("success")

    -- Refresh UI if open
    if self.RefreshProfileList then
        self:RefreshProfileList()
    end
end

---------------------------------------------------------------------------
-- Load a profile
---------------------------------------------------------------------------
function HA:LoadProfile(name)
    local L = self.L

    if not name or name == "" then
        self:Print(L["PROFILE_NAME_REQUIRED"])
        return
    end

    local profile = self.db.profiles[name]
    if not profile then
        self:Print(L["PROFILE_NOT_FOUND"]:format(name))
        self:PlayFeedbackSound("error")
        return
    end

    -- Combat check
    if self.inCombat or InCombatLockdown() then
        self:FeedbackCombatError()
        return
    end

    -- First show all currently hidden frames
    for frameName, _ in pairs(self.db.hiddenFrames) do
        local frame = self:GetFrameByName(frameName)
        if frame then
            self:SecureShowFrame(frame, frameName)
        end
    end

    -- Apply profile hidden frames
    self.db.hiddenFrames = self:DeepCopy(profile.hiddenFrames or {})

    -- Apply profile settings (merge, don't overwrite completely)
    if profile.settings then
        for k, v in pairs(profile.settings) do
            self.db.settings[k] = v
        end
    end

    self.db.activeProfile = name

    -- Re-hide all frames from the loaded profile
    self:ReapplyHiddenFrames()

    local count = self:GetHiddenCount()
    self:FeedbackProfileLoaded(name, count)

    -- Refresh UI if open
    if self.RefreshHiddenList then
        self:RefreshHiddenList()
    end
    if self.RefreshProfileList then
        self:RefreshProfileList()
    end
end

---------------------------------------------------------------------------
-- Delete a profile
---------------------------------------------------------------------------
function HA:DeleteProfile(name)
    local L = self.L

    if not name or name == "" then
        self:Print(L["PROFILE_NAME_REQUIRED"])
        return
    end

    if not self.db.profiles[name] then
        self:Print(L["PROFILE_NOT_FOUND"]:format(name))
        self:PlayFeedbackSound("error")
        return
    end

    self.db.profiles[name] = nil

    if self.db.activeProfile == name then
        self.db.activeProfile = nil
    end

    self:Print(L["PROFILE_DELETED"]:format(name))
    self:PlayFeedbackSound("success")

    -- Refresh UI if open
    if self.RefreshProfileList then
        self:RefreshProfileList()
    end
end

---------------------------------------------------------------------------
-- List all profiles
---------------------------------------------------------------------------
function HA:ListProfiles()
    local L = self.L

    local count = 0
    for _ in pairs(self.db.profiles) do
        count = count + 1
    end

    if count == 0 then
        self:Print(L["PROFILE_NO_PROFILES"])
        return
    end

    self:Print(L["PROFILE_LIST_HEADER"]:format(count))

    local i = 1
    for name, data in pairs(self.db.profiles) do
        local frameCount = 0
        if data.hiddenFrames then
            for _ in pairs(data.hiddenFrames) do
                frameCount = frameCount + 1
            end
        end

        local active = (self.db.activeProfile == name) and " |cff00ff00<active>|r" or ""
        self:Print(L["PROFILE_LIST_ENTRY"]:format(i, name .. active, frameCount))
        i = i + 1
    end
end

---------------------------------------------------------------------------
-- Export a profile to a string (simple serialization)
---------------------------------------------------------------------------
function HA:ExportProfile(name)
    local L = self.L

    if not name or name == "" then
        self:Print(L["PROFILE_NAME_REQUIRED"])
        return
    end

    local profile = self.db.profiles[name]
    if not profile then
        self:Print(L["PROFILE_NOT_FOUND"]:format(name))
        self:PlayFeedbackSound("error")
        return
    end

    -- Simple serialization: name|frame1,frame2,frame3,...
    local frames = {}
    if profile.hiddenFrames then
        for frameName, _ in pairs(profile.hiddenFrames) do
            table.insert(frames, frameName)
        end
    end

    local data = "HA1:" .. name .. "|" .. table.concat(frames, ",")

    -- Base64-like encoding isn't available, so we'll just show the raw data
    self:ShowExportDialog(data)
    self:Print(L["PROFILE_EXPORTED"]:format(name))
    self:PlayFeedbackSound("success")
end

---------------------------------------------------------------------------
-- Import a profile from a string
---------------------------------------------------------------------------
function HA:ImportProfile(data)
    local L = self.L

    if not data or data == "" then
        self:Print(L["PROFILE_IMPORT_ERROR"])
        self:PlayFeedbackSound("error")
        return
    end

    -- Parse format: HA1:name|frame1,frame2,frame3,...
    local prefix, rest = strsplit(":", data, 2)
    if prefix ~= "HA1" or not rest then
        self:Print(L["ERROR_IMPORT_PARSE"])
        self:PlayFeedbackSound("error")
        return
    end

    local name, frameList = strsplit("|", rest, 2)
    if not name or name == "" then
        self:Print(L["ERROR_IMPORT_PARSE"])
        self:PlayFeedbackSound("error")
        return
    end

    local hiddenFrames = {}
    if frameList and frameList ~= "" then
        local frameNames = { strsplit(",", frameList) }
        for _, frameName in ipairs(frameNames) do
            frameName = strtrim(frameName)
            if frameName ~= "" then
                hiddenFrames[frameName] = true
            end
        end
    end

    local frameCount = 0
    for _ in pairs(hiddenFrames) do
        frameCount = frameCount + 1
    end

    -- Save as a new profile
    self.db.profiles[name] = {
        hiddenFrames = hiddenFrames,
        settings     = self:DeepCopy(self.db.settings),
    }

    self:Print(L["PROFILE_IMPORTED"]:format(name, frameCount))
    self:PlayFeedbackSound("success")

    -- Refresh UI if open
    if self.RefreshProfileList then
        self:RefreshProfileList()
    end
end
