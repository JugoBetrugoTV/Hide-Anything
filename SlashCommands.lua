--[[
    HideAnything - SlashCommands.lua
    All slash commands: /ha, /hideanything
]]

local AddonName, HA = ...

---------------------------------------------------------------------------
-- Register slash commands
---------------------------------------------------------------------------
SLASH_HIDEANYTHING1 = "/ha"
SLASH_HIDEANYTHING2 = "/hideanything"

SlashCmdList["HIDEANYTHING"] = function(msg)
    local L = HA.L

    msg = msg and strtrim(msg) or ""
    local cmd, args = strsplit(" ", msg, 2)
    cmd = strlower(cmd or "")
    args = args and strtrim(args) or ""

    if cmd == "" or cmd == "help" then
        HA:PrintHelp()

    elseif cmd == "toggle" or cmd == "options" or cmd == "config" or cmd == "opt" then
        HA:ToggleOptionsPanel()

    elseif cmd == "hide" then
        if args == "" then
            HA:Print(L["HELP_HIDE"])
        else
            HA:HideFrame(args)
        end

    elseif cmd == "show" then
        if args == "" then
            HA:Print(L["HELP_SHOW"])
        else
            HA:ShowFrame(args)
        end

    elseif cmd == "showall" or cmd == "show-all" or cmd == "restore" then
        HA:ShowAllFrames()

    elseif cmd == "list" or cmd == "ls" then
        HA:ListHiddenFrames()

    elseif cmd == "lock" then
        HA:LockFrames()

    elseif cmd == "unlock" then
        HA:UnlockFrames()

    elseif cmd == "reset" then
        if args == "confirm" then
            HA:ConfirmReset()
        else
            HA:RequestReset()
        end

    elseif cmd == "profile" then
        if args == "" then
            HA:Print(L["HELP_PROFILE"])
        else
            local subCmd, profileName = strsplit(" ", args, 2)
            subCmd = strlower(subCmd or "")
            profileName = profileName and strtrim(profileName) or ""

            if subCmd == "save" then
                if profileName ~= "" then HA:SaveProfile(profileName)
                else HA:Print(L["PROFILE_NAME_REQUIRED"]) end

            elseif subCmd == "load" then
                if profileName ~= "" then HA:LoadProfile(profileName)
                else HA:Print(L["PROFILE_NAME_REQUIRED"]) end

            elseif subCmd == "delete" or subCmd == "del" or subCmd == "remove" then
                if profileName ~= "" then HA:DeleteProfile(profileName)
                else HA:Print(L["PROFILE_NAME_REQUIRED"]) end

            elseif subCmd == "overwrite" then
                if profileName ~= "" then HA:SaveProfile(profileName, true)
                else HA:Print(L["PROFILE_NAME_REQUIRED"]) end

            elseif subCmd == "export" then
                if profileName ~= "" then HA:ExportProfile(profileName)
                else HA:Print(L["PROFILE_NAME_REQUIRED"]) end

            else
                HA:LoadProfile(args)
            end
        end

    elseif cmd == "profiles" then
        HA:ListProfiles()

    elseif cmd == "status" or cmd == "info" then
        HA:PrintStatus()

    elseif cmd == "alpha" or cmd == "opacity" then
        if args == "" then
            HA:Print(L["HELP_ALPHA"])
        else
            local frameName, pctStr = strsplit(" ", args, 2)
            frameName = strtrim(frameName or "")
            pctStr = strtrim(pctStr or "")
            local pct = tonumber(pctStr)
            if frameName ~= "" and pct then
                pct = math.max(0, math.min(100, pct))
                HA:SetFrameAlpha(frameName, pct / 100)
            else
                HA:Print(L["HELP_ALPHA"])
            end
        end

    elseif cmd == "minimap" then
        HA:ToggleMinimapButton()

    else
        HA:Print(L["ERROR_UNKNOWN_CMD"]:format(cmd))
    end
end

---------------------------------------------------------------------------
-- Print help
---------------------------------------------------------------------------
function HA:PrintHelp()
    local L = self.L
    self:Print(L["HELP_HEADER"])
    self:Print(L["HELP_TOGGLE"])
    self:Print(L["HELP_SHOW_ALL"])
    self:Print(L["HELP_HIDE"])
    self:Print(L["HELP_SHOW"])
    self:Print(L["HELP_LIST"])
    self:Print(L["HELP_LOCK"])
    self:Print(L["HELP_UNLOCK"])
    self:Print(L["HELP_PROFILE"])
    self:Print(L["HELP_PROFILES"])
    self:Print(L["HELP_RESET"])
    self:Print(L["HELP_STATUS"])
    self:Print(L["HELP_MINIMAP"])
    self:Print(L["HELP_ALPHA"])
end

---------------------------------------------------------------------------
-- Print status
---------------------------------------------------------------------------
function HA:PrintStatus()
    local L = self.L
    self:Print(L["STATUS_HEADER"])
    self:Print(L["STATUS_HIDDEN_COUNT"]:format(self:GetHiddenCount()))

    if self:GetSetting("locked") then
        self:Print(L["STATUS_LOCKED"])
    else
        self:Print(L["STATUS_UNLOCKED"])
    end

    local profile = self.db and self.db.activeProfile or "none"
    self:Print(L["STATUS_PROFILE"]:format(profile or "none"))

    local minimapOn = self.db and self.db.minimap and not self.db.minimap.hide
    self:Print(L["STATUS_MINIMAP"]:format(minimapOn and L["STATUS_ON"] or L["STATUS_OFF"]))
end
