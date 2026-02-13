--[[
    HideAnything - Config.lua
    Saved variables, defaults, database initialization, frame catalog
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
        locked      = false,
        showMinimap = true,
        chatEnabled = true,
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
-- Curated frame catalog: frames available for toggling in the UI
---------------------------------------------------------------------------
HA.FRAME_CATALOG = {
    { name = "PlayerFrame",               label = "Player Frame",               labelDE = "Spieler-Frame" },
    { name = "TargetFrame",               label = "Target Frame",               labelDE = "Ziel-Frame" },
    { name = "FocusFrame",                label = "Focus Frame",                labelDE = "Fokus-Frame" },
    { name = "PetFrame",                  label = "Pet Frame",                  labelDE = "Begleiter-Frame" },
    { name = "MinimapCluster",            label = "Minimap",                    labelDE = "Minimap" },
    { name = "BuffFrame",                 label = "Buffs",                      labelDE = "Buffs" },
    { name = "DebuffFrame",              label = "Debuffs",                    labelDE = "Debuffs" },
    { name = "ObjectiveTrackerFrame",     label = "Quest / Objective Tracker",  labelDE = "Quest-Tracker" },
    { name = "PlayerCastingBarFrame",     label = "Cast Bar",                   labelDE = "Zauberleiste" },
    { name = "MicroButtonAndBagsBar",     label = "Micro Menu & Bags",          labelDE = "Mikromenü & Taschen" },
    { name = "StatusTrackingBarManager",  label = "XP / Rep Bar",              labelDE = "EP / Ruf-Leiste" },
    { name = "CompactRaidFrameContainer", label = "Raid Frames",               labelDE = "Raid-Frames" },
    { name = "BossBanner",               label = "Boss Banner",                labelDE = "Boss-Banner" },
    { name = "ZoneTextFrame",            label = "Zone Text",                  labelDE = "Zonentext" },
    { name = "SubZoneTextFrame",         label = "Sub Zone Text",              labelDE = "Unterzonentext" },
    { name = "DurabilityFrame",          label = "Durability",                 labelDE = "Haltbarkeit" },
    { name = "VehicleSeatIndicator",     label = "Vehicle Seat",               labelDE = "Fahrzeugsitz" },
    { name = "TalkingHeadFrame",         label = "Talking Head",               labelDE = "Sprechender Kopf" },
    { name = "AlertFrame",               label = "Achievement Alerts",         labelDE = "Erfolgs-Meldungen" },
    { name = "TotemFrame",               label = "Totems",                     labelDE = "Totems" },
    { name = "GameTimeFrame",            label = "Calendar Button",            labelDE = "Kalender-Button" },
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

---------------------------------------------------------------------------
-- Get localized catalog label
---------------------------------------------------------------------------
function HA:GetCatalogLabel(entry)
    if GetLocale() == "deDE" and entry.labelDE then
        return entry.labelDE
    end
    return entry.label
end
