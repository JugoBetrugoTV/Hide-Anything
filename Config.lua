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

    -- Frame alpha values: { ["FrameName"] = 0.5, ... } (0.0 - 1.0)
    frameAlphas = {},

    -- Settings
    settings = {
        locked      = false,
        showMinimap = true,
        chatEnabled = true,
        -- highlight setting removed: now per-row via eye button
    },

    -- Profiles
    profiles = {},

    -- Active profile name (nil = no profile)
    activeProfile = nil,

    -- Minimap button position (used by LibDBIcon)
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
    { name = "FocusFrameToT",             label = "Focus Target of Target",     labelDE = "Fokusziel des Ziels" },
    { name = "PetFrame",                  label = "Pet Frame",                  labelDE = "Begleiter-Frame" },
    { name = "PartyFrame",               label = "Party Frames",               labelDE = "Gruppen-Frames" },
    { name = "CompactRaidFrameContainer", label = "Raid Frames",               labelDE = "Raid-Frames" },
    { name = "CompactRaidFrameManager",   label = "Raid Frame Manager",         labelDE = "Raid-Frame Manager" },
    { name = "BossTargetFrameContainer",  label = "Boss Frames",               labelDE = "Boss-Frames" },
    { name = "ArenaEnemyFramesContainer", label = "Arena Enemy Frames",         labelDE = "Arena-Gegner-Frames" },

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
    { name = "OverrideActionBar",        label = "Override / Vehicle Bar",    labelDE = "Override-/Fahrzeugleiste" },
    { name = "MultiBar5",               label = "Action Bar 5",              labelDE = "Aktionsleiste 5" },
    { name = "MultiBar6",               label = "Action Bar 6",              labelDE = "Aktionsleiste 6" },
    { name = "MultiBar7",               label = "Action Bar 7",              labelDE = "Aktionsleiste 7" },

    ---------------------------------------------------------------------------
    -- Bars & Menus
    ---------------------------------------------------------------------------
    { section = true, label = "Bars & Menus",           labelDE = "Leisten & Menüs" },
    { name = "MicroButtonAndBagsBar",    label = "Micro Menu & Bags (Classic)",   labelDE = "Mikromenü & Taschen (Classic)" },
    { name = "MicroMenuContainer",       label = "Micro Menu (Retail)",           labelDE = "Mikromenü (Retail)" },
    { name = "BagBar",                   label = "Bag Bar (Retail)",              labelDE = "Taschenleiste (Retail)" },
    { name = "BagsBar",                  label = "Bags Bar (Retail alt)",         labelDE = "Taschenleiste (Retail alt)" },
    { name = "BackpackBar",             label = "Backpack Bar",                   labelDE = "Rucksack-Leiste" },
    { name = "MainMenuBarBackpackButton",label = "Backpack Button",              labelDE = "Rucksack-Button" },
    { name = "StatusTrackingBarManager", label = "XP / Rep Bar",              labelDE = "EP / Ruf-Leiste" },
    { name = "PlayerCastingBarFrame",    label = "Cast Bar",                  labelDE = "Zauberleiste" },
    { name = "EditModeManagerFrame",     label = "Edit Mode Bar",              labelDE = "Bearbeitungsmodus-Leiste" },

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
    { cvar = "floatingCombatTextCombatDamage",    label = "Damage Numbers",          labelDE = "Schadenszahlen" },
    { cvar = "floatingCombatTextCombatHealing",   label = "Healing Numbers",         labelDE = "Heilungszahlen" },
    { cvar = "enableFloatingCombatText",          label = "Incoming Combat Text",    labelDE = "Eingehender Kampftext" },
    { cvar = "floatingCombatTextDodgeParryMiss",  label = "Dodge / Parry / Miss",    labelDE = "Ausweichen / Parieren / Verfehlt" },
    { cvar = "floatingCombatTextComboPoints",     label = "Combo Points",            labelDE = "Kombopunkte" },
    { cvar = "floatingCombatTextEnergyGains",     label = "Energy / Mana / Rage",    labelDE = "Energie / Mana / Wut" },
    { cvar = "floatingCombatTextRepChanges",      label = "Reputation Changes",      labelDE = "Ruf-Änderungen" },
    { cvar = "floatingCombatTextHonorGains",      label = "Honor Gains",             labelDE = "Ehre-Gewinn" },
    { cvar = "floatingCombatTextReactives",       label = "Reactive Abilities",      labelDE = "Reaktive Fähigkeiten" },
    { cvar = "floatingCombatTextAuras",           label = "Buff / Debuff Gain",      labelDE = "Buff-/Debuff-Gewinn" },
    { cvar = "floatingCombatTextLowManaHealth",   label = "Low Health / Mana Warn",  labelDE = "Wenig Leben/Mana Warnung" },
    { cvar = "floatingCombatTextCombatState",     label = "Enter / Leave Combat",    labelDE = "Kampf betreten/verlassen" },
    { cvar = "floatingCombatTextFriendlyHealers", label = "Healer Names",            labelDE = "Heiler-Namen" },

    ---------------------------------------------------------------------------
    -- Nameplates (CVar-based)
    ---------------------------------------------------------------------------
    { section = true, label = "Nameplates",             labelDE = "Namensplaketten" },
    { cvar = "nameplateShowAll",              label = "All Nameplates",              labelDE = "Alle Namensplaketten" },
    { cvar = "nameplateShowFriends",          label = "Friendly Nameplates",         labelDE = "Freundliche Namensplaketten" },
    { cvar = "nameplateShowEnemies",          label = "Enemy Nameplates",            labelDE = "Feindliche Namensplaketten" },
    { cvar = "nameplateShowSelf",             label = "Personal Resource Bar",       labelDE = "Eigene Ressourcenanzeige" },
    { cvar = "nameplateShowFriendlyNPCs",     label = "Friendly NPC Nameplates",     labelDE = "Freundliche NPC-Namensplaketten" },
    { cvar = "nameplateShowEnemyMinions",     label = "Enemy Pet Nameplates",        labelDE = "Gegner-Pet-Namensplaketten" },
    { cvar = "nameplateShowEnemyMinus",       label = "Trivial Enemy Nameplates",    labelDE = "Triviale Gegner-Namensplaketten" },

    ---------------------------------------------------------------------------
    -- Sound (CVar-based)
    ---------------------------------------------------------------------------
    { section = true, label = "Sound",                  labelDE = "Sound" },
    { cvar = "Sound_EnableErrorSpeech",   label = "Error Speech",              labelDE = "Fehler-Stimme" },
    { cvar = "Sound_EnableMusic",         label = "Music",                     labelDE = "Musik" },
    { cvar = "Sound_EnableSFX",           label = "Sound Effects",             labelDE = "Sound-Effekte" },
    { cvar = "Sound_EnableAmbience",      label = "Ambience",                  labelDE = "Umgebungsgeräusche" },
    { cvar = "Sound_EnableDialog",        label = "NPC Dialog Voice",          labelDE = "NPC-Dialog-Stimmen" },

    ---------------------------------------------------------------------------
    -- Chat & Bubbles
    ---------------------------------------------------------------------------
    { section = true, label = "Chat & Bubbles",         labelDE = "Chat & Blasen" },
    { name = "GeneralDockManager",           label = "Chat Tab Bar",              labelDE = "Chat-Tab-Leiste" },
    { name = "ChatFrameMenuButton",          label = "Chat Menu Button",          labelDE = "Chat-Menü-Button" },
    { name = "QuickJoinToastButton",         label = "Quick Join Button",         labelDE = "Schnellbeitritt-Button" },
    { name = "CombatLogQuickButtonFrame",    label = "Combat Log Buttons",        labelDE = "Kampflog-Buttons" },
    { cvar = "chatBubbles",                  label = "Chat Bubbles",              labelDE = "Chat-Blasen" },
    { cvar = "chatBubblesParty",             label = "Party Chat Bubbles",        labelDE = "Gruppen-Chat-Blasen" },

    ---------------------------------------------------------------------------
    -- Map & Navigation
    ---------------------------------------------------------------------------
    { section = true, label = "Map & Navigation",       labelDE = "Karte & Navigation" },
    { name = "MinimapCluster",           label = "Minimap",                   labelDE = "Minimap" },
    { name = "GameTimeFrame",            label = "Calendar Button",           labelDE = "Kalender-Button" },
    { name = "TimeManagerClockButton",   label = "Clock",                     labelDE = "Uhr" },
    { name = "MiniMapMailFrame",         label = "Mail Notification",         labelDE = "Post-Benachrichtigung" },
    { name = "MiniMapInstanceDifficulty", label = "Instance Difficulty",      labelDE = "Instanz-Schwierigkeit" },
    { name = "MiniMapTracking",          label = "Tracking Button",           labelDE = "Tracking-Button" },
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
    { name = "SpellActivationOverlayFrame", label = "Spell Proc Overlays",    labelDE = "Zauber-Proc-Overlays" },
    { name = "GhostFrame",              label = "Spirit Release",             labelDE = "Geistfreilassung" },
    { name = "TimerTracker",             label = "BG / Arena Timer",          labelDE = "BG-/Arena-Timer" },
    { name = "MirrorTimerContainer",     label = "Breath / Fatigue Timer",    labelDE = "Atem-/Ermüdungs-Timer" },
    { name = "UIErrorsFrame",            label = "Error Text (red)",          labelDE = "Fehlertext (rot)" },
    { name = "RaidWarningFrame",         label = "Raid Warning Text",         labelDE = "Raid-Warnungstext" },

    ---------------------------------------------------------------------------
    -- Widgets & Misc
    ---------------------------------------------------------------------------
    { section = true, label = "Widgets & Misc",         labelDE = "Widgets & Sonstiges" },
    { name = "UIWidgetTopCenterContainerFrame",    label = "Top Center Widgets",  labelDE = "Obere Widgets" },
    { name = "UIWidgetBelowMinimapContainerFrame", label = "Minimap Widgets",     labelDE = "Minimap-Widgets" },
    { name = "DurabilityFrame",          label = "Durability",                labelDE = "Haltbarkeit" },
    { name = "VehicleSeatIndicator",     label = "Vehicle Seat",              labelDE = "Fahrzeugsitz" },
    { name = "QueueStatusButton",        label = "Queue Status Eye",          labelDE = "Warteschlangen-Auge" },
    { name = "PlayerPowerBarAlt",        label = "Alternate Power Bar",       labelDE = "Alternative Energieleiste" },
    { name = "OrderHallCommandBar",      label = "Order Hall Bar",            labelDE = "Ordenshallen-Leiste" },
    { name = "UIWidgetCenterScreenContainerFrame", label = "Center Screen Widgets", labelDE = "Bildschirmmitte-Widgets" },
    { name = "ExpansionLandingPageMinimapButton",  label = "Expansion Landing Button", labelDE = "Erweiterungs-Landungstaste" },

    ---------------------------------------------------------------------------
    -- Tutorials (CVar-based)
    ---------------------------------------------------------------------------
    { section = true, label = "Tutorials",              labelDE = "Tutorials" },
    { cvar = "showTutorials",            label = "Tutorial Popups",           labelDE = "Tutorial-Popups" },

    ---------------------------------------------------------------------------
    -- HUD Misc (CVar-based)
    ---------------------------------------------------------------------------
    { section = true, label = "HUD Options",            labelDE = "HUD-Optionen" },
    { cvar = "showTargetCastbar",        label = "Target Cast Bar",           labelDE = "Ziel-Zauberleiste" },
    { cvar = "showVKeyCastbar",          label = "Focus Cast Bar",            labelDE = "Fokus-Zauberleiste" },
    { cvar = "showTargetOfTarget",       label = "Target of Target",          labelDE = "Ziel des Ziels" },
    { cvar = "doNotFlashLowHealthWarning", label = "Low Health Flash",        labelDE = "Warnung: Wenig Leben" },
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
    if type(db.frameAlphas) ~= "table" then
        db.frameAlphas = {}
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
