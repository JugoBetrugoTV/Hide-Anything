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

    -- Hidden CVars: { ["cvarName"] = true, ... }
    hiddenCVars = {},

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
    ---------------------------------------------------------------------------
    -- Unit Frames
    ---------------------------------------------------------------------------
    { section = true, label = "Unit Frames",            labelDE = "Einheiten-Frames" },
    { name = "PlayerFrame",               label = "Player Frame",               labelDE = "Spieler-Frame" },
    { name = "TargetFrame",               label = "Target Frame",               labelDE = "Ziel-Frame" },
    { name = "TargetFrameToT",            label = "Target of Target",           labelDE = "Ziel des Ziels" },
    { name = "FocusFrame",                label = "Focus Frame",                labelDE = "Fokus-Frame" },
    { name = "PetFrame",                  label = "Pet Frame",                  labelDE = "Begleiter-Frame" },
    { name = "PartyFrame",               label = "Party Frames",               labelDE = "Gruppen-Frames" },
    { name = "CompactRaidFrameContainer", label = "Raid Frames",               labelDE = "Raid-Frames" },

    ---------------------------------------------------------------------------
    -- Action Bars
    ---------------------------------------------------------------------------
    { section = true, label = "Action Bars",            labelDE = "Aktionsleisten" },
    { name = "MainMenuBar",              label = "Main Action Bar",            labelDE = "Hauptaktionsleiste" },
    { name = "MultiBarBottomLeft",       label = "Action Bar 2",              labelDE = "Aktionsleiste 2" },
    { name = "MultiBarBottomRight",      label = "Action Bar 3",              labelDE = "Aktionsleiste 3" },
    { name = "MultiBarRight",            label = "Right Action Bar",          labelDE = "Rechte Aktionsleiste" },
    { name = "MultiBarLeft",             label = "Right Action Bar 2",        labelDE = "Rechte Aktionsleiste 2" },
    { name = "StanceBar",                label = "Stance / Form Bar",         labelDE = "Haltungsleiste" },
    { name = "PetActionBar",             label = "Pet Action Bar",            labelDE = "Begleiter-Aktionsleiste" },
    { name = "ExtraAbilityContainer",    label = "Extra Action Button",       labelDE = "Extra-Aktionsknopf" },
    { name = "EncounterBar",             label = "Encounter Bar",             labelDE = "Begegnungsleiste" },

    ---------------------------------------------------------------------------
    -- Bars & Menus
    ---------------------------------------------------------------------------
    { section = true, label = "Bars & Menus",           labelDE = "Leisten & Menüs" },
    { name = "MicroButtonAndBagsBar",    label = "Micro Menu & Bags",         labelDE = "Mikromenü & Taschen" },
    { name = "StatusTrackingBarManager", label = "XP / Rep Bar",              labelDE = "EP / Ruf-Leiste" },
    { name = "PlayerCastingBarFrame",    label = "Cast Bar",                  labelDE = "Zauberleiste" },

    ---------------------------------------------------------------------------
    -- Buffs & Auras
    ---------------------------------------------------------------------------
    { section = true, label = "Buffs & Auras",          labelDE = "Buffs & Auren" },
    { name = "BuffFrame",                label = "Buffs",                     labelDE = "Buffs" },
    { name = "DebuffFrame",              label = "Debuffs",                   labelDE = "Debuffs" },
    { name = "TotemFrame",               label = "Totems",                    labelDE = "Totems" },

    ---------------------------------------------------------------------------
    -- Combat Text (CVar-based)
    ---------------------------------------------------------------------------
    { section = true, label = "Combat Text",            labelDE = "Kampftext" },
    { cvar = "floatingCombatTextCombatDamage",  label = "Damage Numbers",     labelDE = "Schadenszahlen" },
    { cvar = "floatingCombatTextCombatHealing", label = "Healing Numbers",    labelDE = "Heilungszahlen" },
    { cvar = "enableFloatingCombatText",        label = "Incoming Combat Text", labelDE = "Eingehender Kampftext" },

    ---------------------------------------------------------------------------
    -- Chat
    ---------------------------------------------------------------------------
    { section = true, label = "Chat",                   labelDE = "Chat" },
    { name = "GeneralDockManager",       label = "Chat Tab Bar",              labelDE = "Chat-Tab-Leiste" },
    { name = "ChatFrameMenuButton",      label = "Chat Menu Button",          labelDE = "Chat-Menü-Button" },
    { name = "QuickJoinToastButton",     label = "Quick Join Button",         labelDE = "Schnellbeitritt-Button" },

    ---------------------------------------------------------------------------
    -- Map & Navigation
    ---------------------------------------------------------------------------
    { section = true, label = "Map & Navigation",       labelDE = "Karte & Navigation" },
    { name = "MinimapCluster",           label = "Minimap",                   labelDE = "Minimap" },
    { name = "GameTimeFrame",            label = "Calendar Button",           labelDE = "Kalender-Button" },
    { name = "ObjectiveTrackerFrame",    label = "Quest / Objective Tracker", labelDE = "Quest-Tracker" },

    ---------------------------------------------------------------------------
    -- Alerts & Notifications
    ---------------------------------------------------------------------------
    { section = true, label = "Alerts & Info",          labelDE = "Meldungen & Info" },
    { name = "BossBanner",               label = "Boss Banner",               labelDE = "Boss-Banner" },
    { name = "AlertFrame",               label = "Achievement Alerts",        labelDE = "Erfolgs-Meldungen" },
    { name = "TalkingHeadFrame",         label = "Talking Head",              labelDE = "Sprechender Kopf" },
    { name = "ZoneTextFrame",            label = "Zone Text",                 labelDE = "Zonentext" },
    { name = "SubZoneTextFrame",         label = "Sub Zone Text",             labelDE = "Unterzonentext" },
    { name = "LossOfControlFrame",       label = "Loss of Control",           labelDE = "Kontrollverlust" },
    { name = "GroupLootContainer",       label = "Loot Rolls",                labelDE = "Beutewürfe" },

    ---------------------------------------------------------------------------
    -- Widgets & Misc
    ---------------------------------------------------------------------------
    { section = true, label = "Widgets & Misc",         labelDE = "Widgets & Sonstiges" },
    { name = "UIWidgetTopCenterContainerFrame",    label = "Top Center Widgets",  labelDE = "Obere Widgets" },
    { name = "UIWidgetBelowMinimapContainerFrame", label = "Minimap Widgets",     labelDE = "Minimap-Widgets" },
    { name = "DurabilityFrame",          label = "Durability",                labelDE = "Haltbarkeit" },
    { name = "VehicleSeatIndicator",     label = "Vehicle Seat",              labelDE = "Fahrzeugsitz" },
    { name = "QueueStatusButton",        label = "Queue Status Eye",          labelDE = "Warteschlangen-Auge" },
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
    if type(db.hiddenCVars) ~= "table" then
        db.hiddenCVars = {}
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
