--[[
    HideAnything - SlashCommands.lua
    All slash commands: /hide, /hideanything
]]

local AddonName, HA = ...

---------------------------------------------------------------------------
-- Register slash commands
---------------------------------------------------------------------------
SLASH_HIDEANYTHING1 = "/hide"
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

    elseif cmd == "undo" or cmd == "z" then
        HA:Undo()

    elseif cmd == "redo" or cmd == "y" then
        HA:Redo()

    elseif cmd == "picker" or cmd == "pick" or cmd == "select" then
        HA:ToggleFramePicker()

    elseif cmd == "preset" then
        if args == "" then
            HA:Print("|cff00cc66Available presets:|r")
            for _, preset in ipairs(HA.PRESET_PROFILES) do
                HA:Print("  |cff00cc66/hide preset " .. preset.id .. "|r - " .. HA:GetPresetLabel(preset))
            end
        else
            if not HA:ApplyPreset(args) then
                HA:Print(L["ERROR_UNKNOWN_CMD"]:format("preset " .. args))
            end
        end

    -- Improvement #14: debug mode toggle
    elseif cmd == "debug" then
        HA:ToggleDebug()

    -- Improvement #23: wildcard hide
    elseif cmd == "hideall" or cmd == "hidepattern" then
        if args == "" then
            HA:Print("|cff00cc66/hide hideall <pattern>|r - Hide frames matching a wildcard pattern (e.g. Player*)")
        else
            HA:HideByPattern(args)
        end

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
    self:Print(L["HELP_UNDO"] or "|cff00cc66/hide undo|r - Undo last action")
    self:Print(L["HELP_REDO"] or "|cff00cc66/hide redo|r - Redo last undone action")
    self:Print(L["HELP_PICKER"] or "|cff00cc66/hide picker|r - Toggle frame picker mode")
    self:Print(L["HELP_PRESET"] or "|cff00cc66/hide preset <name>|r - Apply a preset profile")
    self:Print(L["HELP_HIDEALL"] or "|cff00cc66/hide hideall <pattern>|r - Hide frames matching wildcard (e.g. Player*)")
    self:Print(L["HELP_DEBUG"] or "|cff00cc66/hide debug|r - Toggle verbose debug logging")
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

    local profile = (self.db and self.db.activeProfile) or "none"
    self:Print(L["STATUS_PROFILE"]:format(profile))

    local minimapOn = self.db and self.db.minimap and not self.db.minimap.hide
    self:Print(L["STATUS_MINIMAP"]:format(minimapOn and L["STATUS_ON"] or L["STATUS_OFF"]))

    -- Show debug mode status
    if HA._debugMode then
        self:Print("|cffffcc00Debug mode|r: |cff00ff00ON|r")
    end
end

---------------------------------------------------------------------------
-- Keyboard shortcut handler (improvement #3)
-- Ctrl+Z = Undo, Ctrl+Y = Redo, Ctrl+P = Picker
-- Each shortcut can be individually disabled in settings
-- Only active when not typing in an edit box
---------------------------------------------------------------------------
local shortcutFrame = CreateFrame("Frame", "HideAnythingShortcuts", UIParent)
shortcutFrame:EnableKeyboard(true)
shortcutFrame:SetPropagateKeyboardInput(true)
shortcutFrame:SetScript("OnKeyDown", function(self, key)
    -- Don't steal input from edit boxes / chat
    local focus = GetCurrentKeyBoardFocus()
    if focus then
        self:SetPropagateKeyboardInput(true)
        return
    end

    local ctrl = IsControlKeyDown()
    if not ctrl then
        self:SetPropagateKeyboardInput(true)
        return
    end

    if key == "Z" and HA:GetSetting("keyUndo") ~= false then
        self:SetPropagateKeyboardInput(false)
        HA:Undo()
    elseif key == "Y" and HA:GetSetting("keyRedo") ~= false then
        self:SetPropagateKeyboardInput(false)
        HA:Redo()
    elseif key == "P" and HA:GetSetting("keyPicker") ~= false then
        self:SetPropagateKeyboardInput(false)
        HA:ToggleFramePicker()
    else
        self:SetPropagateKeyboardInput(true)
    end
end)
