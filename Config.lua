--[[
    HideAnything - Config.lua
    Saved variables, defaults, database initialization
]]

local AddonName, HA = ...

---------------------------------------------------------------------------
-- Default settings
---------------------------------------------------------------------------
HA.DEFAULTS = {
    -- Hidden frames: { ["FrameName"] = true, ... }
    hiddenFrames = {},

    -- Settings
    settings = {
        locked          = false,
        autoHide        = true,
        confirmHide     = false,
        showMinimap     = true,

        -- Feedback toggles
        soundEnabled    = true,
        chatEnabled     = true,
        screenEnabled   = true,
        errorSpeech     = true,

        -- Per-action sound toggles
        soundHideEnabled    = true,
        soundShowEnabled    = true,
        soundErrorEnabled   = true,
        soundSuccessEnabled = true,
        soundPickerEnabled  = true,
        soundLockEnabled    = true,

        -- Sound file IDs (SOUNDKIT numeric IDs)
        sounds = {
            hide        = 838,    -- SOUNDKIT.IG_ABILITY_ICON_DROP
            show        = 839,    -- SOUNDKIT.IG_CHARACTER_INFO_OPEN
            error       = 846,    -- SOUNDKIT.IG_QUEST_LOG_ABANDON_QUEST
            success     = 880,    -- SOUNDKIT.IG_PLAYER_INVITE
            pickerStart = 850,    -- SOUNDKIT.IG_MAINMENU_OPEN
            pickerStop  = 851,    -- SOUNDKIT.IG_MAINMENU_CLOSE
            lock        = 856,    -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
            unlock      = 857,    -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
            profileLoad = 841,    -- SOUNDKIT.IG_CHARACTER_INFO_TAB
            reset       = 853,    -- SOUNDKIT.IG_MAINMENU_LOGOUT
        },
    },

    -- Profiles
    profiles = {},

    -- Active profile name (nil = no profile)
    activeProfile = nil,

    -- Minimap button position
    minimap = {
        minimapPos = 220,
        hide = false,
    },
}

---------------------------------------------------------------------------
-- Protected frames that should never be hidden
---------------------------------------------------------------------------
HA.PROTECTED_FRAMES = {
    ["UIParent"]             = true,
    ["WorldFrame"]           = true,
    ["UIErrorsFrame"]        = true,
    ["StaticPopup1"]         = true,
    ["StaticPopup2"]         = true,
    ["StaticPopup3"]         = true,
    ["StaticPopup4"]         = true,
    ["GameTooltip"]          = true,
    ["DropDownList1"]        = true,
    ["DropDownList2"]        = true,
    ["ChatFrame1"]           = true,
    ["GossipFrame"]          = true,
    ["QuestFrame"]           = true,
    ["MerchantFrame"]        = true,
    ["LootFrame"]            = true,
    ["HideAnythingOptionsFrame"] = true,
}

---------------------------------------------------------------------------
-- Initialize database
---------------------------------------------------------------------------
function HA:InitDB()
    local L = self.L

    -- Create or load saved variables
    if not HideAnythingDB then
        HideAnythingDB = {}
    end

    local db = HideAnythingDB

    -- Deep-copy defaults for missing keys
    self:EnsureDefaults(db, self.DEFAULTS)

    -- Validate data integrity
    if type(db.hiddenFrames) ~= "table" then
        self:Print(L["ERROR_DB_CORRUPT"])
        db.hiddenFrames = {}
    end
    if type(db.settings) ~= "table" then
        self:Print(L["ERROR_DB_CORRUPT"])
        db.settings = self:DeepCopy(self.DEFAULTS.settings)
    end
    if type(db.profiles) ~= "table" then
        db.profiles = {}
    end

    self.db = db
end

---------------------------------------------------------------------------
-- Ensure all default values exist in the target table (recursive)
---------------------------------------------------------------------------
function HA:EnsureDefaults(target, defaults)
    for k, v in pairs(defaults) do
        if target[k] == nil then
            if type(v) == "table" then
                target[k] = self:DeepCopy(v)
            else
                target[k] = v
            end
        elseif type(v) == "table" and type(target[k]) == "table" then
            self:EnsureDefaults(target[k], v)
        end
    end
end

---------------------------------------------------------------------------
-- Deep copy a table
---------------------------------------------------------------------------
function HA:DeepCopy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        if type(v) == "table" then
            copy[k] = self:DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

---------------------------------------------------------------------------
-- Reset all settings to defaults
---------------------------------------------------------------------------
function HA:ResetDB()
    HideAnythingDB = self:DeepCopy(self.DEFAULTS)
    self.db = HideAnythingDB
end

---------------------------------------------------------------------------
-- Get a setting value
---------------------------------------------------------------------------
function HA:GetSetting(key)
    return self.db and self.db.settings and self.db.settings[key]
end

---------------------------------------------------------------------------
-- Set a setting value
---------------------------------------------------------------------------
function HA:SetSetting(key, value)
    if self.db and self.db.settings then
        self.db.settings[key] = value
    end
end
