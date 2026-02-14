--[[
    HideAnything - Config.lua
    Saved variables, defaults, database initialization, frame catalog
    Edition detection and cross-version compatibility
]]

local AddonName, HA = ...

---------------------------------------------------------------------------
-- Edition detection
---------------------------------------------------------------------------
local function DetectEdition()
    local pid = WOW_PROJECT_ID
    if pid then
        if pid == (WOW_PROJECT_MAINLINE or 1) then return "retail", 1 end
        if pid == (WOW_PROJECT_CLASSIC or 2) then return "classic", 2 end
        if pid == 5 then return "tbc", 4 end
        if pid == (WOW_PROJECT_WRATH_CLASSIC or 11) then return "wrath", 8 end
        if pid == 14 then return "cata", 16 end
    end
    local _, _, _, tocVer = GetBuildInfo()
    tocVer = tocVer or 0
    if tocVer >= 50000 and tocVer < 60000 then return "mop", 32 end
    if tocVer >= 40000 and tocVer < 50000 then return "cata", 16 end
    if tocVer >= 30000 and tocVer < 40000 then return "wrath", 8 end
    if tocVer >= 20000 and tocVer < 30000 then return "tbc", 4 end
    if tocVer >= 10000 and tocVer < 20000 then return "classic", 2 end
    return "retail", 1
end

HA.edition, HA.editionBit = DetectEdition()

-- Edition bitmask constants (used in FRAME_CATALOG .ed field)
local R   = 1   -- Retail
local C   = 2   -- Classic Era
local T   = 4   -- TBC Anniversary
local W   = 8   -- Wrath Classic
local X   = 16  -- Cata Classic
local M   = 32  -- MoP Classic
local ALL = R+C+T+W+X+M        -- 63
local CL  = C+T+W+X+M          -- All Classic variants
local TBC_UP   = T+W+X+M+R     -- TBC and later (including Retail)
local WRATH_UP = W+X+M+R       -- Wrath and later
local CATA_UP  = X+M+R         -- Cata and later

HA.ED_ALL = ALL

-- Edition display info
HA.EDITION_NAMES = {
    retail  = "Retail",
    classic = "Classic Era",
    tbc     = "TBC Anniversary",
    wrath   = "Wrath Classic",
    cata    = "Cata Classic",
    mop     = "MoP Classic",
}

HA.EDITION_COLORS = {
    retail  = "3399ff",
    classic = "ffcc00",
    tbc     = "00cc44",
    wrath   = "88aaff",
    cata    = "ff6600",
    mop     = "66dd88",
}

function HA:IsEntryAvailable(entry)
    local ed = entry.ed or ALL
    return bit.band(ed, self.editionBit) > 0
end

function HA:GetEditionTag(entry)
    local ed = entry.ed
    if not ed or ed == ALL then return nil, nil end
    if ed == R then return "Retail", "3399ff" end
    if ed == CL then return "Classic", "ffcc00" end
    if ed == TBC_UP then return "TBC+", "00cc44" end
    if ed == WRATH_UP then return "Wrath+", "88aaff" end
    if ed == CATA_UP then return "Cata+", "ff6600" end
    return nil, nil
end

---------------------------------------------------------------------------
-- Default settings
---------------------------------------------------------------------------
HA.DEFAULTS = {
    hiddenFrames = {},
    hiddenCVars = {},
    frameAlphas = {},

    settings = {
        locked           = false,
        showMinimap      = true,
        chatEnabled      = true,
        highlightEnabled = true,
    },

    profiles = {},
    activeProfile = nil,

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
-- Curated frame catalog
-- .ed = edition bitmask (default ALL if omitted)
---------------------------------------------------------------------------
HA.FRAME_CATALOG = {

    ---------------------------------------------------------------------------
    -- Unit Frames
    ---------------------------------------------------------------------------
    { section = true, label = "Unit Frames",            labelDE = "Einheiten-Frames" },
    { name = "PlayerFrame",               label = "Player Frame",               labelDE = "Spieler-Frame" },
    { name = "TargetFrame",               label = "Target Frame",               labelDE = "Ziel-Frame" },
    { name = "TargetFrameToT",            label = "Target of Target",           labelDE = "Ziel des Ziels" },
    { name = "FocusFrame",                label = "Focus Frame",                labelDE = "Fokus-Frame",                ed = TBC_UP },
    { name = "FocusFrameToT",             label = "Focus Target of Target",     labelDE = "Fokusziel des Ziels",        ed = TBC_UP },
    { name = "PetFrame",                  label = "Pet Frame",                  labelDE = "Begleiter-Frame" },
    { name = "PartyFrame",                label = "Party Frames",               labelDE = "Gruppen-Frames" },
    { name = "CompactRaidFrameContainer", label = "Raid Frames",                labelDE = "Raid-Frames",                ed = CATA_UP },
    { name = "CompactRaidFrameManager",   label = "Raid Frame Manager",         labelDE = "Raid-Frame Manager",         ed = CATA_UP },
    { name = "BossTargetFrameContainer",  label = "Boss Frames",                labelDE = "Boss-Frames",                ed = WRATH_UP },
    { name = "ArenaEnemyFramesContainer", label = "Arena Enemy Frames",         labelDE = "Arena-Gegner-Frames",        ed = TBC_UP },

    ---------------------------------------------------------------------------
    -- Action Bars
    ---------------------------------------------------------------------------
    { section = true, label = "Action Bars",            labelDE = "Aktionsleisten" },
    { name = "MainMenuBar",              label = "Main Action Bar",            labelDE = "Hauptaktionsleiste" },
    { name = "MultiBarBottomLeft",       label = "Action Bar 2",              labelDE = "Aktionsleiste 2" },
    { name = "MultiBarBottomRight",      label = "Action Bar 3",              labelDE = "Aktionsleiste 3" },
    { name = "MultiBarRight",            label = "Right Action Bar",          labelDE = "Rechte Aktionsleiste" },
    { name = "MultiBarLeft",             label = "Right Action Bar 2",        labelDE = "Rechte Aktionsleiste 2" },
    { name = "MultiBar5",               label = "Action Bar 5",              labelDE = "Aktionsleiste 5",             ed = R },
    { name = "MultiBar6",               label = "Action Bar 6",              labelDE = "Aktionsleiste 6",             ed = R },
    { name = "MultiBar7",               label = "Action Bar 7",              labelDE = "Aktionsleiste 7",             ed = R },
    { name = "StanceBar",                label = "Stance / Form Bar",         labelDE = "Haltungsleiste" },
    { name = "PetActionBar",             label = "Pet Action Bar",            labelDE = "Begleiter-Aktionsleiste" },
    { name = "ExtraAbilityContainer",    label = "Extra Action Button",       labelDE = "Extra-Aktionsknopf" },
    { name = "EncounterBar",             label = "Encounter Bar",             labelDE = "Begegnungsleiste",            ed = R },
    { name = "OverrideActionBar",        label = "Override / Vehicle Bar",    labelDE = "Override-/Fahrzeugleiste",    ed = CATA_UP },

    ---------------------------------------------------------------------------
    -- Bars & Menus
    ---------------------------------------------------------------------------
    { section = true, label = "Bars & Menus",           labelDE = "Leisten & Menus" },
    { name = "MicroButtonAndBagsBar",    label = "Micro Menu & Bags",         labelDE = "Mikromenü & Taschen",         ed = CL },
    { name = "MicroMenuContainer",       label = "Micro Menu",                labelDE = "Mikromenü",                   ed = R },
    { name = "BagBar",                   label = "Bag Bar",                   labelDE = "Taschenleiste",               ed = R },
    { name = "BagsBar",                  label = "Bags Bar (alt)",            labelDE = "Taschenleiste (alt)",          ed = R },
    { name = "BackpackBar",              label = "Backpack Bar",              labelDE = "Rucksack-Leiste",             ed = R },
    { name = "MainMenuBarBackpackButton",label = "Backpack Button",           labelDE = "Rucksack-Button",             ed = CL },
    { name = "StatusTrackingBarManager", label = "XP / Rep Bar",              labelDE = "EP / Ruf-Leiste" },
    { name = "PlayerCastingBarFrame",    label = "Cast Bar",                  labelDE = "Zauberleiste" },
    { name = "EditModeManagerFrame",     label = "Edit Mode Bar",             labelDE = "Bearbeitungsmodus-Leiste",    ed = R },

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
    -- Names & Titles (CVar-based)
    ---------------------------------------------------------------------------
    { section = true, label = "Names & Titles",         labelDE = "Namen & Titel" },
    { cvar = "UnitNameOwn",                   label = "Own Name",                    labelDE = "Eigener Name" },
    { cvar = "UnitNameNPC",                   label = "NPC Names",                   labelDE = "NPC-Namen" },
    { cvar = "UnitNamePlayerGuild",           label = "Guild Names",                 labelDE = "Gildennamen" },
    { cvar = "UnitNamePlayerPVPTitle",        label = "PvP Titles",                  labelDE = "PvP-Titel" },
    { cvar = "UnitNameFriendlyPlayerName",    label = "Friendly Player Names",       labelDE = "Freundliche Spielernamen" },
    { cvar = "UnitNameFriendlyPetName",       label = "Friendly Pet Names",          labelDE = "Freundliche Begleiternamen" },
    { cvar = "UnitNameEnemyPlayerName",       label = "Enemy Player Names",          labelDE = "Feindliche Spielernamen" },
    { cvar = "UnitNameEnemyPetName",          label = "Enemy Pet Names",             labelDE = "Feindliche Begleiternamen" },
    { cvar = "UnitNameNonCombatCreatureName", label = "Critter Names",               labelDE = "Tierchennamen" },

    ---------------------------------------------------------------------------
    -- Sound (CVar-based)
    ---------------------------------------------------------------------------
    { section = true, label = "Sound",                  labelDE = "Sound" },
    { cvar = "Sound_EnableAllSound",      label = "Master Sound",              labelDE = "Gesamtton" },
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
    -- Gameplay Options (CVar-based)
    ---------------------------------------------------------------------------
    { section = true, label = "Gameplay Options",       labelDE = "Gameplay-Optionen" },
    { cvar = "autoLootDefault",               label = "Auto-Loot",                   labelDE = "Automatisches Plündern" },
    { cvar = "autoSelfCast",                  label = "Auto Self-Cast",              labelDE = "Automatischer Selbstzauber" },
    { cvar = "autoDismountFlying",            label = "Auto-Dismount (Flying)",      labelDE = "Automatisch Absitzen (Flug)" },
    { cvar = "autoUnshift",                   label = "Auto-Unshift Form",           labelDE = "Automatisch Form ablegen" },
    { cvar = "lootUnderMouse",                label = "Loot at Mouse Position",      labelDE = "Beute an Mausposition" },
    { cvar = "deselectOnClick",               label = "Deselect on Click",           labelDE = "Auswahl bei Klick aufheben" },
    { cvar = "stopAutoAttackOnTargetChange",  label = "Stop Attack on Target Change",labelDE = "Angriff bei Zielwechsel stoppen" },
    { cvar = "lockActionBars",                label = "Lock Action Bars",            labelDE = "Aktionsleisten sperren" },
    { cvar = "alwaysShowActionBars",          label = "Always Show Action Bars",     labelDE = "Aktionsleisten immer anzeigen" },
    { cvar = "countdownForCooldowns",         label = "Cooldown Numbers",            labelDE = "Abklingzeit-Zahlen" },
    { cvar = "interactOnLeftClick",           label = "Interact on Left-Click",      labelDE = "Interaktion bei Linksklick",  ed = R },

    ---------------------------------------------------------------------------
    -- Raid & Party (CVar-based)
    ---------------------------------------------------------------------------
    { section = true, label = "Raid & Party",           labelDE = "Raid & Gruppe" },
    { cvar = "raidFramesDisplayPowerBars",    label = "Raid Power Bars",             labelDE = "Raid-Energieleisten",         ed = CATA_UP },
    { cvar = "raidFramesDisplayClassColor",   label = "Raid Class Colors",           labelDE = "Raid-Klassenfarben",          ed = CATA_UP },
    { cvar = "useCompactPartyFrames",         label = "Compact Party Frames",        labelDE = "Kompakte Gruppenframes",      ed = CATA_UP },
    { cvar = "showPartyPets",                 label = "Show Party Pets",             labelDE = "Gruppen-Begleiter anzeigen" },
    { cvar = "showArenaEnemyFrames",          label = "Arena Enemy Frames",          labelDE = "Arena-Gegnerframes",          ed = TBC_UP },

    ---------------------------------------------------------------------------
    -- Social & Chat Options (CVar-based)
    ---------------------------------------------------------------------------
    { section = true, label = "Social & Chat Options",  labelDE = "Soziales & Chat-Optionen" },
    { cvar = "profanityFilter",               label = "Profanity Filter",            labelDE = "Schimpfwortfilter" },
    { cvar = "spamFilter",                    label = "Spam Filter",                 labelDE = "Spam-Filter" },
    { cvar = "guildMemberNotify",             label = "Guild Online Notifications",  labelDE = "Gilden-Online-Meldungen" },
    { cvar = "blockTrades",                   label = "Block Trades",                labelDE = "Handel blockieren" },
    { cvar = "blockChannelInvites",           label = "Block Channel Invites",       labelDE = "Kanaleinladungen blockieren" },

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
    { name = "UIWidgetTopCenterContainerFrame",    label = "Top Center Widgets",  labelDE = "Obere Widgets",              ed = R },
    { name = "UIWidgetBelowMinimapContainerFrame", label = "Minimap Widgets",     labelDE = "Minimap-Widgets",            ed = R },
    { name = "DurabilityFrame",          label = "Durability",                labelDE = "Haltbarkeit" },
    { name = "VehicleSeatIndicator",     label = "Vehicle Seat",              labelDE = "Fahrzeugsitz" },
    { name = "QueueStatusButton",        label = "Queue Status Eye",          labelDE = "Warteschlangen-Auge" },
    { name = "PlayerPowerBarAlt",        label = "Alternate Power Bar",       labelDE = "Alternative Energieleiste" },
    { name = "OrderHallCommandBar",      label = "Order Hall Bar",            labelDE = "Ordenshallen-Leiste",          ed = R },
    { name = "UIWidgetCenterScreenContainerFrame", label = "Center Screen Widgets", labelDE = "Bildschirmmitte-Widgets", ed = R },
    { name = "ExpansionLandingPageMinimapButton",  label = "Expansion Landing Button", labelDE = "Erweiterungs-Landungstaste", ed = R },

    ---------------------------------------------------------------------------
    -- Tutorials (CVar-based)
    ---------------------------------------------------------------------------
    { section = true, label = "Tutorials",              labelDE = "Tutorials" },
    { cvar = "showTutorials",            label = "Tutorial Popups",           labelDE = "Tutorial-Popups" },

    ---------------------------------------------------------------------------
    -- HUD Options (CVar-based)
    ---------------------------------------------------------------------------
    { section = true, label = "HUD Options",            labelDE = "HUD-Optionen" },
    { cvar = "showTargetCastbar",        label = "Target Cast Bar",           labelDE = "Ziel-Zauberleiste" },
    { cvar = "showVKeyCastbar",          label = "Focus Cast Bar",            labelDE = "Fokus-Zauberleiste" },
    { cvar = "showTargetOfTarget",       label = "Target of Target",          labelDE = "Ziel des Ziels" },
    { cvar = "doNotFlashLowHealthWarning", label = "Low Health Flash",        labelDE = "Warnung: Wenig Leben" },

    ---------------------------------------------------------------------------
    -- Accessibility (CVar-based)
    ---------------------------------------------------------------------------
    { section = true, label = "Accessibility",          labelDE = "Barrierefreiheit" },
    { cvar = "colorblindMode",           label = "Colorblind Mode",           labelDE = "Farbenblind-Modus" },
    { cvar = "enableMovePad",            label = "Move Pad",                  labelDE = "Bewegungsfeld" },
}

---------------------------------------------------------------------------
-- Initialize database
---------------------------------------------------------------------------
function HA:InitDB()
    local L = self.L

    if not HideAnythingDB then
        HideAnythingDB = {}
    end

    local db = HideAnythingDB

    self:EnsureDefaults(db, self.DEFAULTS)

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
