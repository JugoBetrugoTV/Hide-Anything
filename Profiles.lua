--[[
    HideAnything - Profiles.lua
    Profile management: save, load, delete, list, export (HA2 format), import
    HA2 format includes: version, frames, cvars, alphas
    Still supports importing legacy HA1 format
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
        hiddenCVars  = self:DeepCopy(self.db.hiddenCVars or {}),
        frameAlphas  = self:DeepCopy(self.db.frameAlphas or {}),
        settings     = self:DeepCopy(self.db.settings),
    }

    local count = self:GetHiddenCount()
    self:Print(L["PROFILE_SAVED"]:format(name, count))

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

    -- Restore currently hidden CVars
    if self.db.hiddenCVars then
        for cvarName, _ in pairs(self.db.hiddenCVars) do
            pcall(SetCVar, cvarName, "1")
        end
    end

    -- Reset all frame alphas
    if self.db.frameAlphas then
        for frameName, _ in pairs(self.db.frameAlphas) do
            local frame = self:GetFrameByName(frameName)
            if frame then
                pcall(function() frame:SetAlpha(1) end)
            end
        end
    end

    -- Apply profile hidden frames, CVars, and alphas
    self.db.hiddenFrames = self:DeepCopy(profile.hiddenFrames or {})
    self.db.hiddenCVars  = self:DeepCopy(profile.hiddenCVars or {})
    self.db.frameAlphas  = self:DeepCopy(profile.frameAlphas or {})

    -- Apply profile settings (merge, don't overwrite completely)
    if profile.settings then
        for k, v in pairs(profile.settings) do
            self.db.settings[k] = v
        end
    end

    self.db.activeProfile = name

    -- Re-hide all frames and CVars from the loaded profile
    self:ReapplyHiddenFrames()
    self:ReapplyHiddenCVars()
    self:ReapplyFrameAlphas()

    local count = self:GetHiddenCount()
    self:FeedbackProfileLoaded(name, count)

    -- Refresh UI if open
    if self.RefreshFrameList then
        self:RefreshFrameList()
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
        return
    end

    self.db.profiles[name] = nil

    if self.db.activeProfile == name then
        self.db.activeProfile = nil
    end

    self:Print(L["PROFILE_DELETED"]:format(name))

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
-- Export a profile (HA2 format with frames, cvars, alphas, version)
-- Format: HA2:name|F:frame1,frame2|C:cvar1,cvar2|A:frame1=50,frame2=75|V:1.1.0
-- Still produces HA1 if no CVars/Alphas for backwards compat
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
        return
    end

    -- Collect frames
    local frames = {}
    if profile.hiddenFrames then
        for frameName, _ in pairs(profile.hiddenFrames) do
            table.insert(frames, frameName)
        end
    end

    -- Collect CVars
    local cvars = {}
    if profile.hiddenCVars then
        for cvarName, _ in pairs(profile.hiddenCVars) do
            table.insert(cvars, cvarName)
        end
    end

    -- Collect alphas (stored as frameName=percentage)
    local alphas = {}
    if profile.frameAlphas then
        for frameName, alpha in pairs(profile.frameAlphas) do
            table.insert(alphas, frameName .. "=" .. math.floor(alpha * 100))
        end
    end

    -- Build HA2 export string
    local parts = { "HA2:" .. name }

    if #frames > 0 then
        table.insert(parts, "F:" .. table.concat(frames, ","))
    end

    if #cvars > 0 then
        table.insert(parts, "C:" .. table.concat(cvars, ","))
    end

    if #alphas > 0 then
        table.insert(parts, "A:" .. table.concat(alphas, ","))
    end

    table.insert(parts, "V:" .. self.version)

    local data = table.concat(parts, "|")

    self:ShowExportDialog(data)
    self:Print(L["PROFILE_EXPORTED"]:format(name))
end

---------------------------------------------------------------------------
-- Import a profile from a string (supports HA1 and HA2 formats)
---------------------------------------------------------------------------
function HA:ImportProfile(data)
    local L = self.L

    if not data or data == "" then
        self:Print(L["PROFILE_IMPORT_ERROR"])
        return
    end

    data = strtrim(data)

    -- Detect format
    if strfind(data, "^HA2:") then
        self:ImportProfileHA2(data)
    elseif strfind(data, "^HA1:") then
        self:ImportProfileHA1(data)
    else
        self:Print(L["ERROR_IMPORT_PARSE"])
    end
end

---------------------------------------------------------------------------
-- Import HA1 format (legacy): HA1:name|frame1,frame2,frame3,...
---------------------------------------------------------------------------
function HA:ImportProfileHA1(data)
    local L = self.L

    local prefix, rest = strsplit(":", data, 2)
    if prefix ~= "HA1" or not rest then
        self:Print(L["ERROR_IMPORT_PARSE"])
        return
    end

    local name, frameList = strsplit("|", rest, 2)
    if not name or name == "" then
        self:Print(L["ERROR_IMPORT_PARSE"])
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
        hiddenCVars  = {},
        frameAlphas  = {},
        settings     = self:DeepCopy(self.db.settings),
    }

    self:Print(L["PROFILE_IMPORTED"]:format(name, frameCount))

    if self.RefreshProfileList then
        self:RefreshProfileList()
    end
end

---------------------------------------------------------------------------
-- Import HA2 format: HA2:name|F:frames|C:cvars|A:alphas|V:version
---------------------------------------------------------------------------
function HA:ImportProfileHA2(data)
    local L = self.L

    -- Remove prefix "HA2:"
    local rest = data:sub(5)
    if not rest or rest == "" then
        self:Print(L["ERROR_IMPORT_PARSE"])
        return
    end

    -- Split by pipe
    local segments = { strsplit("|", rest) }
    if #segments < 1 then
        self:Print(L["ERROR_IMPORT_PARSE"])
        return
    end

    -- First segment is the profile name
    local name = strtrim(segments[1])
    if name == "" then
        self:Print(L["ERROR_IMPORT_PARSE"])
        return
    end

    local hiddenFrames = {}
    local hiddenCVars = {}
    local frameAlphas = {}

    -- Parse remaining segments
    for i = 2, #segments do
        local seg = strtrim(segments[i])
        local segType, segData = strsplit(":", seg, 2)

        if segType == "F" and segData and segData ~= "" then
            -- Frames
            local frameNames = { strsplit(",", segData) }
            for _, frameName in ipairs(frameNames) do
                frameName = strtrim(frameName)
                if frameName ~= "" then
                    hiddenFrames[frameName] = true
                end
            end

        elseif segType == "C" and segData and segData ~= "" then
            -- CVars
            local cvarNames = { strsplit(",", segData) }
            for _, cvarName in ipairs(cvarNames) do
                cvarName = strtrim(cvarName)
                if cvarName ~= "" then
                    hiddenCVars[cvarName] = true
                end
            end

        elseif segType == "A" and segData and segData ~= "" then
            -- Alphas (format: frameName=percentage)
            local alphaEntries = { strsplit(",", segData) }
            for _, entry in ipairs(alphaEntries) do
                entry = strtrim(entry)
                local aName, aPct = strsplit("=", entry, 2)
                if aName and aPct then
                    aName = strtrim(aName)
                    aPct = tonumber(strtrim(aPct))
                    if aName ~= "" and aPct then
                        frameAlphas[aName] = aPct / 100
                    end
                end
            end

        -- V: is version info, we just ignore it on import
        end
    end

    local frameCount = 0
    for _ in pairs(hiddenFrames) do frameCount = frameCount + 1 end
    for _ in pairs(hiddenCVars) do frameCount = frameCount + 1 end

    -- Save as a new profile
    self.db.profiles[name] = {
        hiddenFrames = hiddenFrames,
        hiddenCVars  = hiddenCVars,
        frameAlphas  = frameAlphas,
        settings     = self:DeepCopy(self.db.settings),
    }

    self:Print(L["PROFILE_IMPORTED"]:format(name, frameCount))

    if self.RefreshProfileList then
        self:RefreshProfileList()
    end
end
