--[[
    HideAnything - Config.lua
    Saved variables, defaults, database initialization, frame catalog
    Edition detection and cross-version compatibility

    Supported editions:
      Retail (Midnight)  |  Classic Era  |  TBC Anniversary  |  MoP Classic
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
        if pid == 5 then return "tbc", 4 end  -- TBC Anniversary
    end
    -- Fallback: interface version
    local _, _, _, tocVer = GetBuildInfo()
    tocVer = tocVer or 0
    if tocVer >= 50000 and tocVer < 60000 then return "mop", 8 end
    if tocVer >= 20000 and tocVer < 30000 then return "tbc", 4 end
    if tocVer >= 10000 and tocVer < 20000 then return "classic", 2 end
    return "retail", 1
end

HA.edition, HA.editionBit = DetectEdition()

-- Edition bitmask constants  (used in FRAME_CATALOG .ed field)
local R   = 1   -- Retail  (Midnight / The War Within / etc.)
local C   = 2   -- Classic Era
local T   = 4   -- TBC Anniversary
local M   = 8   -- MoP Classic
local ALL = R+C+T+M            -- 15
local CL  = C+T+M              -- 14  (all classic variants)
local TBC_UP = T+M+R           -- 13  (TBC and later, incl. Retail)
local MOP_UP = M+R              -- 9  (MoP Classic + Retail)

HA.ED_ALL = ALL

-- Edition display info
HA.EDITION_NAMES = {
    retail  = "Retail",
    classic = "Classic Era",
    tbc     = "TBC Anniversary",
    mop     = "MoP Classic",
}

HA.EDITION_COLORS = {
    retail  = "3399ff",
    classic = "ffcc00",
    tbc     = "00cc44",
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
    if ed == MOP_UP then return "MoP+", "66dd88" end
    return nil, nil
end

---------------------------------------------------------------------------
-- Default settings
---------------------------------------------------------------------------
HA.DEFAULTS = {
    hiddenFrames    = {},
    hiddenCVars     = {},
    frameAlphas     = {},
    combatHideFrames = {},   -- frames to auto-hide during combat
    hiddenTextures  = {},    -- hidden texture/region elements

    settings = {
        locked           = false,
        showMinimap      = true,
        chatEnabled      = true,
        highlightEnabled = true,
        fadeEnabled      = false,
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
    ["GossipFrame"]          = true,
    ["QuestFrame"]           = true,
    ["MerchantFrame"]        = true,
    ["LootFrame"]            = true,
    ["HideAnythingOptionsFrame"] = true,
}

---------------------------------------------------------------------------
-- Curated frame catalog
-- .ed = edition bitmask  (default ALL if omitted)
---------------------------------------------------------------------------
HA.FRAME_CATALOG = {

    ---------------------------------------------------------------------------
    -- Unit Frames
    ---------------------------------------------------------------------------
    { section = true, label = "Unit Frames",            labelDE = "Einheiten-Frames",           labelFR = "Cadres d'unités",            labelES = "Marcos de unidades",         labelRU = "Фреймы юнитов",             labelIT = "Riquadri unità" },
    { name = "PlayerFrame",               label = "Player Frame",               labelDE = "Spieler-Frame",              labelFR = "Cadre du joueur",            labelES = "Marco del jugador",          labelRU = "Фрейм игрока",             labelIT = "Riquadro giocatore" },
    { name = "TargetFrame",               label = "Target Frame",               labelDE = "Ziel-Frame",                 labelFR = "Cadre de cible",             labelES = "Marco del objetivo",         labelRU = "Фрейм цели",               labelIT = "Riquadro bersaglio" },
    { name = "TargetFrameToT",            label = "Target of Target",           labelDE = "Ziel des Ziels",             labelFR = "Cible de la cible",          labelES = "Objetivo del objetivo",      labelRU = "Цель цели",                 labelIT = "Bersaglio del bersaglio" },
    { name = "FocusFrame",                label = "Focus Frame",                labelDE = "Fokus-Frame",                labelFR = "Cadre de focalisation",      labelES = "Marco de enfoque",           labelRU = "Фрейм фокуса",             labelIT = "Riquadro focus" },
    { name = "FocusFrameToT",             label = "Focus Target of Target",     labelDE = "Fokusziel des Ziels",        labelFR = "Cible de la cible focalisée", labelES = "Objetivo del objetivo enfocado", labelRU = "Цель цели фокуса",      labelIT = "Bersaglio del bersaglio focus" },
    { name = "PetFrame",                  label = "Pet Frame",                  labelDE = "Begleiter-Frame",            labelFR = "Cadre du familier",          labelES = "Marco de mascota",           labelRU = "Фрейм питомца",            labelIT = "Riquadro famiglio" },
    { name = "PartyFrame",                label = "Party Frames",               labelDE = "Gruppen-Frames",             labelFR = "Cadres de groupe",           labelES = "Marcos de grupo",            labelRU = "Фреймы группы",            labelIT = "Riquadri gruppo" },
    { name = "CompactRaidFrameContainer", label = "Raid Frames",                labelDE = "Raid-Frames",                labelFR = "Cadres de raid",             labelES = "Marcos de banda",            labelRU = "Фреймы рейда",             labelIT = "Riquadri raid",              ed = MOP_UP },
    { name = "CompactRaidFrameManager",   label = "Raid Frame Manager",         labelDE = "Raid-Frame Manager",         labelFR = "Gestionnaire de raid",       labelES = "Gestor de marcos de banda",  labelRU = "Менеджер фреймов рейда",   labelIT = "Gestore riquadri raid",      ed = MOP_UP },
    { name = "BossTargetFrameContainer",  label = "Boss Frames",                labelDE = "Boss-Frames",                labelFR = "Cadres de boss",             labelES = "Marcos de jefe",             labelRU = "Фреймы боссов",            labelIT = "Riquadri boss",              ed = MOP_UP },
    { name = "ArenaEnemyFramesContainer", label = "Arena Enemy Frames",         labelDE = "Arena-Gegner-Frames",        labelFR = "Cadres ennemis d'arène",     labelES = "Marcos de enemigos de arena", labelRU = "Фреймы противников арены", labelIT = "Riquadri nemici arena",      ed = TBC_UP },
    { name = "RuneFrame",                 label = "Death Knight Runes",         labelDE = "Todesritter-Runen",          labelFR = "Runes du chevalier de la mort", labelES = "Runas del caballero de la Muerte", labelRU = "Руны рыцаря смерти",  labelIT = "Rune del cavaliere della morte", ed = MOP_UP },
    { name = "ClassPowerBar",             label = "Class Power Bar",            labelDE = "Klassen-Energieleiste",      labelFR = "Barre d'énergie de classe",  labelES = "Barra de poder de clase",    labelRU = "Панель ресурса класса",     labelIT = "Barra potere classe",           ed = R },
    { name = "ClassNameplateManaBarFrame", label = "Class Nameplate Mana",      labelDE = "Klassen-Namensplakette Mana", labelFR = "Mana plaque de nom",        labelES = "Mana placa de nombre",       labelRU = "Мана табличка класса",      labelIT = "Mana targhetta classe",         ed = R },

    ---------------------------------------------------------------------------
    -- Action Bars
    ---------------------------------------------------------------------------
    { section = true, label = "Action Bars",            labelDE = "Aktionsleisten",             labelFR = "Barres d'action",            labelES = "Barras de acción",           labelRU = "Панели действий",           labelIT = "Barre azione" },
    { name = "MainMenuBar",              label = "Main Action Bar",            labelDE = "Hauptaktionsleiste",         labelFR = "Barre d'action principale",  labelES = "Barra de acción principal",  labelRU = "Главная панель действий",   labelIT = "Barra azione principale" },
    { name = "MultiBarBottomLeft",       label = "Action Bar 2",              labelDE = "Aktionsleiste 2",            labelFR = "Barre d'action 2",           labelES = "Barra de acción 2",          labelRU = "Панель действий 2",         labelIT = "Barra azione 2" },
    { name = "MultiBarBottomRight",      label = "Action Bar 3",              labelDE = "Aktionsleiste 3",            labelFR = "Barre d'action 3",           labelES = "Barra de acción 3",          labelRU = "Панель действий 3",         labelIT = "Barra azione 3" },
    { name = "MultiBarRight",            label = "Right Action Bar",          labelDE = "Rechte Aktionsleiste",       labelFR = "Barre d'action droite",      labelES = "Barra de acción derecha",    labelRU = "Правая панель действий",    labelIT = "Barra azione destra" },
    { name = "MultiBarLeft",             label = "Right Action Bar 2",        labelDE = "Rechte Aktionsleiste 2",     labelFR = "Barre d'action droite 2",    labelES = "Barra de acción derecha 2",  labelRU = "Правая панель действий 2",  labelIT = "Barra azione destra 2" },
    { name = "MultiBar5",               label = "Action Bar 5",              labelDE = "Aktionsleiste 5",             labelFR = "Barre d'action 5",           labelES = "Barra de acción 5",          labelRU = "Панель действий 5",         labelIT = "Barra azione 5",             ed = R },
    { name = "MultiBar6",               label = "Action Bar 6",              labelDE = "Aktionsleiste 6",             labelFR = "Barre d'action 6",           labelES = "Barra de acción 6",          labelRU = "Панель действий 6",         labelIT = "Barra azione 6",             ed = R },
    { name = "MultiBar7",               label = "Action Bar 7",              labelDE = "Aktionsleiste 7",             labelFR = "Barre d'action 7",           labelES = "Barra de acción 7",          labelRU = "Панель действий 7",         labelIT = "Barra azione 7",             ed = R },
    { name = "StanceBar",                label = "Stance / Form Bar",         labelDE = "Haltungsleiste",             labelFR = "Barre de postures",          labelES = "Barra de posturas",          labelRU = "Панель стоек",              labelIT = "Barra posizioni" },
    { name = "PetActionBar",             label = "Pet Action Bar",            labelDE = "Begleiter-Aktionsleiste",    labelFR = "Barre d'action du familier", labelES = "Barra de acción de mascota", labelRU = "Панель действий питомца",   labelIT = "Barra azione famiglio" },
    { name = "ExtraAbilityContainer",    label = "Extra Action Button",       labelDE = "Extra-Aktionsknopf",          labelFR = "Bouton d'action bonus",      labelES = "Botón de acción extra",      labelRU = "Доп. кнопка действия",      labelIT = "Pulsante azione extra",      ed = MOP_UP },
    { name = "EncounterBar",             label = "Encounter Bar",             labelDE = "Begegnungsleiste",            labelFR = "Barre de rencontre",         labelES = "Barra de encuentro",         labelRU = "Панель столкновения",       labelIT = "Barra incontro",             ed = R },
    { name = "OverrideActionBar",        label = "Override / Vehicle Bar",    labelDE = "Override-/Fahrzeugleiste",    labelFR = "Barre de véhicule",          labelES = "Barra de vehículo",          labelRU = "Панель транспорта",         labelIT = "Barra veicolo",              ed = MOP_UP },
    { name = "PossessActionBar",         label = "Possess Bar",               labelDE = "Besitz-Leiste",              labelFR = "Barre de possession",        labelES = "Barra de posesión",          labelRU = "Панель подчинения",         labelIT = "Barra possessione" },
    { name = "MainMenuBarLeftEndCap",  label = "Left Bar Gryphon",          labelDE = "Linker Leisten-Greif",        labelFR = "Griffon gauche",             labelES = "Grifo izquierdo",            labelRU = "Левый грифон",              labelIT = "Grifone sinistro",           ed = CL },
    { name = "MainMenuBarRightEndCap", label = "Right Bar Gryphon",         labelDE = "Rechter Leisten-Greif",       labelFR = "Griffon droit",              labelES = "Grifo derecho",              labelRU = "Правый грифон",             labelIT = "Grifone destro",             ed = CL },

    ---------------------------------------------------------------------------
    -- Bars & Menus
    ---------------------------------------------------------------------------
    { section = true, label = "Bars & Menus",           labelDE = "Leisten & Menüs",            labelFR = "Barres et menus",            labelES = "Barras y menús",             labelRU = "Панели и меню",             labelIT = "Barre e menu" },
    { name = "MicroButtonAndBagsBar",    label = "Micro Menu & Bags",         labelDE = "Mikromenü & Taschen",         labelFR = "Micro menu et sacs",         labelES = "Micro menú y bolsas",        labelRU = "Микроменю и сумки",         labelIT = "Micro menu e borse",         ed = CL },
    { name = "MicroMenuContainer",       label = "Micro Menu",                labelDE = "Mikromenü",                   labelFR = "Micro menu",                 labelES = "Micro menú",                 labelRU = "Микроменю",                 labelIT = "Micro menu",                 ed = R },
    { name = "BagBar",                   label = "Bag Bar",                   labelDE = "Taschenleiste",               labelFR = "Barre de sacs",              labelES = "Barra de bolsas",            labelRU = "Панель сумок",              labelIT = "Barra borse",                ed = R },
    { name = "BagsBar",                  label = "Bags Bar (alt)",            labelDE = "Taschenleiste (alt)",          labelFR = "Barre de sacs (alt)",        labelES = "Barra de bolsas (alt)",      labelRU = "Панель сумок (альт.)",      labelIT = "Barra borse (alt)",          ed = R },
    { name = "BackpackBar",              label = "Backpack Bar",              labelDE = "Rucksack-Leiste",             labelFR = "Barre de sac à dos",         labelES = "Barra de mochila",           labelRU = "Панель рюкзака",            labelIT = "Barra zaino",                ed = R },
    { name = "MainMenuBarBackpackButton",label = "Backpack Button",           labelDE = "Rucksack-Button",             labelFR = "Bouton sac à dos",           labelES = "Botón de mochila",           labelRU = "Кнопка рюкзака",            labelIT = "Pulsante zaino",             ed = CL },
    { name = "StatusTrackingBarManager", label = "XP / Rep Bar",              labelDE = "EP / Ruf-Leiste",            labelFR = "Barre XP / Réputation",      labelES = "Barra de XP / Reputación",   labelRU = "Панель опыта / репутации",  labelIT = "Barra PE / Reputazione" },
    { name = "PlayerCastingBarFrame",    label = "Cast Bar",                  labelDE = "Zauberleiste",               labelFR = "Barre d'incantation",        labelES = "Barra de lanzamiento",       labelRU = "Полоса заклинаний",         labelIT = "Barra incantesimo" },
    { name = "CastingBarFrame",          label = "Cast Bar (Classic)",        labelDE = "Zauberleiste (Classic)",      labelFR = "Barre d'incantation (Classic)", labelES = "Barra de lanzamiento (Classic)", labelRU = "Полоса заклинаний (Classic)", labelIT = "Barra incantesimo (Classic)", ed = CL },
    { name = "EditModeManagerFrame",     label = "Edit Mode Bar",             labelDE = "Bearbeitungsmodus-Leiste",    labelFR = "Barre du mode édition",      labelES = "Barra de modo edición",      labelRU = "Панель режима редактирования", labelIT = "Barra modalità modifica", ed = R },
    { name = "HelpMicroButton",        label = "Help Button",               labelDE = "Hilfe-Button",               labelFR = "Bouton d'aide",              labelES = "Botón de ayuda",             labelRU = "Кнопка помощи",             labelIT = "Pulsante aiuto" },
    { name = "StoreMicroButton",       label = "Store Button",              labelDE = "Shop-Button",                 labelFR = "Bouton boutique",            labelES = "Botón de tienda",            labelRU = "Кнопка магазина",           labelIT = "Pulsante negozio",           ed = R },
    { name = "ContainerFrameCombinedBags", label = "Combined Bags",         labelDE = "Kombinierte Taschen",         labelFR = "Sacs combinés",              labelES = "Bolsas combinadas",          labelRU = "Объединённые сумки",        labelIT = "Borse combinate",            ed = R },

    ---------------------------------------------------------------------------
    -- Chat
    ---------------------------------------------------------------------------
    { section = true, label = "Chat",                   labelDE = "Chat",                       labelFR = "Chat",                       labelES = "Chat",                       labelRU = "Чат",                       labelIT = "Chat" },
    { name = "ChatFrame1",               label = "Chat Window (Main)",        labelDE = "Chat-Fenster (Haupt)",       labelFR = "Fenêtre de chat (principal)", labelES = "Ventana de chat (principal)", labelRU = "Окно чата (основное)",     labelIT = "Finestra chat (principale)" },
    { name = "ChatFrame2",               label = "Chat Window 2 (Combat Log)",labelDE = "Chat-Fenster 2 (Kampflog)",  labelFR = "Fenêtre de chat 2 (Journal)", labelES = "Ventana de chat 2 (Registro)", labelRU = "Окно чата 2 (Журнал боя)", labelIT = "Finestra chat 2 (Registro)" },
    { name = "ChatFrame3",               label = "Chat Window 3",             labelDE = "Chat-Fenster 3",             labelFR = "Fenêtre de chat 3",          labelES = "Ventana de chat 3",          labelRU = "Окно чата 3",               labelIT = "Finestra chat 3" },
    { name = "ChatFrame4",               label = "Chat Window 4",             labelDE = "Chat-Fenster 4",             labelFR = "Fenêtre de chat 4",          labelES = "Ventana de chat 4",          labelRU = "Окно чата 4",               labelIT = "Finestra chat 4" },
    { name = "ChatFrame5",               label = "Chat Window 5",             labelDE = "Chat-Fenster 5",             labelFR = "Fenêtre de chat 5",          labelES = "Ventana de chat 5",          labelRU = "Окно чата 5",               labelIT = "Finestra chat 5" },
    { name = "ChatFrame6",               label = "Chat Window 6",             labelDE = "Chat-Fenster 6",             labelFR = "Fenêtre de chat 6",          labelES = "Ventana de chat 6",          labelRU = "Окно чата 6",               labelIT = "Finestra chat 6" },
    { name = "ChatFrame7",               label = "Chat Window 7",             labelDE = "Chat-Fenster 7",             labelFR = "Fenêtre de chat 7",          labelES = "Ventana de chat 7",          labelRU = "Окно чата 7",               labelIT = "Finestra chat 7" },
    { name = "GeneralDockManager",       label = "Chat Tab Bar",              labelDE = "Chat-Tab-Leiste",            labelFR = "Barre d'onglets du chat",    labelES = "Barra de pestañas del chat", labelRU = "Панель вкладок чата",       labelIT = "Barra schede chat" },
    { name = "ChatFrameMenuButton",      label = "Chat Menu Button",          labelDE = "Chat-Menü-Button",           labelFR = "Bouton menu du chat",        labelES = "Botón menú del chat",        labelRU = "Кнопка меню чата",          labelIT = "Pulsante menu chat" },
    { name = "QuickJoinToastButton",     label = "Quick Join Button",         labelDE = "Schnellbeitritt-Button",      labelFR = "Bouton de ralliement",       labelES = "Botón de unión rápida",      labelRU = "Кнопка быстрого входа",     labelIT = "Pulsante unione rapida",     ed = R },
    { name = "CombatLogQuickButtonFrame",label = "Combat Log Buttons",        labelDE = "Kampflog-Buttons",           labelFR = "Boutons du journal de combat", labelES = "Botones del registro de combate", labelRU = "Кнопки журнала боя",  labelIT = "Pulsanti registro di combattimento" },
    { name = "VoiceChatHeadsetButton",   label = "Voice Chat Button",         labelDE = "Sprachchat-Button",           labelFR = "Bouton chat vocal",          labelES = "Botón de chat de voz",       labelRU = "Кнопка голосового чата",    labelIT = "Pulsante chat vocale",       ed = R },
    { cvar = "chatBubbles",              label = "Chat Bubbles",              labelDE = "Chat-Blasen",                labelFR = "Bulles de chat",             labelES = "Burbujas de chat",           labelRU = "Облачка чата",              labelIT = "Fumetti chat" },
    { cvar = "chatBubblesParty",         label = "Party Chat Bubbles",        labelDE = "Gruppen-Chat-Blasen",        labelFR = "Bulles de chat de groupe",   labelES = "Burbujas de chat de grupo",  labelRU = "Облачка чата группы",       labelIT = "Fumetti chat di gruppo" },

    ---------------------------------------------------------------------------
    -- Buffs & Auras
    ---------------------------------------------------------------------------
    { section = true, label = "Buffs & Auras",          labelDE = "Buffs & Auren",              labelFR = "Buffs et auras",             labelES = "Buffs y auras",              labelRU = "Баффы и ауры",             labelIT = "Buff e aure" },
    { name = "BuffFrame",                label = "Buffs",                     labelDE = "Buffs",                      labelFR = "Buffs",                      labelES = "Buffs",                      labelRU = "Баффы",                     labelIT = "Buff" },
    { name = "DebuffFrame",              label = "Debuffs",                   labelDE = "Debuffs",                    labelFR = "Débuffs",                    labelES = "Debuffs",                    labelRU = "Дебаффы",                   labelIT = "Debuff" },
    { name = "TotemFrame",               label = "Totems",                    labelDE = "Totems",                     labelFR = "Totems",                     labelES = "Tótems",                     labelRU = "Тотемы",                    labelIT = "Totem" },
    { cvar = "showCastableBuffs",       label = "Castable Buffs (Target)",   labelDE = "Zauberwirksame Buffs (Ziel)", labelFR = "Buffs lançables (Cible)",   labelES = "Buffs lanzables (Objetivo)", labelRU = "Применимые баффы (Цель)",   labelIT = "Buff lanciabili (Bersaglio)" },
    { cvar = "showDispelDebuffs",       label = "Dispellable Debuffs (Target)", labelDE = "Bannbare Debuffs (Ziel)",  labelFR = "Débuffs dissipables (Cible)", labelES = "Debuffs disipables (Objetivo)", labelRU = "Рассеиваемые дебаффы (Цель)", labelIT = "Debuff dissolvibili (Bersaglio)" },

    ---------------------------------------------------------------------------
    -- Combat Text (CVar-based)
    ---------------------------------------------------------------------------
    { section = true, label = "Combat Text",            labelDE = "Kampftext",                  labelFR = "Texte de combat",            labelES = "Texto de combate",           labelRU = "Боевой текст",              labelIT = "Testo di combattimento" },
    { cvar = "floatingCombatTextCombatDamage",    label = "Damage Numbers",          labelDE = "Schadenszahlen",             labelFR = "Chiffres de dégâts",         labelES = "Números de daño",            labelRU = "Числа урона",               labelIT = "Numeri danno" },
    { cvar = "floatingCombatTextCombatHealing",   label = "Healing Numbers",         labelDE = "Heilungszahlen",             labelFR = "Chiffres de soins",          labelES = "Números de curación",        labelRU = "Числа исцеления",           labelIT = "Numeri cura" },
    { cvar = "enableFloatingCombatText",          label = "Incoming Combat Text",    labelDE = "Eingehender Kampftext",      labelFR = "Texte de combat entrant",    labelES = "Texto de combate entrante",  labelRU = "Входящий боевой текст",     labelIT = "Testo combattimento in arrivo" },
    { cvar = "floatingCombatTextDodgeParryMiss",  label = "Dodge / Parry / Miss",    labelDE = "Ausweichen / Parieren / Verfehlt", labelFR = "Esquive / Parade / Raté", labelES = "Esquivar / Parar / Fallar", labelRU = "Уклонение / Парирование / Промах", labelIT = "Schivata / Parata / Mancato" },
    { cvar = "floatingCombatTextComboPoints",     label = "Combo Points",            labelDE = "Kombopunkte",                labelFR = "Points de combo",            labelES = "Puntos de combo",            labelRU = "Очки приёмов",              labelIT = "Punti combo" },
    { cvar = "floatingCombatTextEnergyGains",     label = "Energy / Mana / Rage",    labelDE = "Energie / Mana / Wut",       labelFR = "Énergie / Mana / Rage",      labelES = "Energía / Maná / Rabia",     labelRU = "Энергия / Мана / Ярость",   labelIT = "Energia / Mana / Rabbia" },
    { cvar = "floatingCombatTextRepChanges",      label = "Reputation Changes",      labelDE = "Ruf-Änderungen",             labelFR = "Changements de réputation",  labelES = "Cambios de reputación",      labelRU = "Изменения репутации",       labelIT = "Variazioni reputazione" },
    { cvar = "floatingCombatTextHonorGains",      label = "Honor Gains",             labelDE = "Ehre-Gewinn",                labelFR = "Gains d'honneur",            labelES = "Ganancias de honor",         labelRU = "Получение чести",           labelIT = "Guadagni onore" },
    { cvar = "floatingCombatTextReactives",       label = "Reactive Abilities",      labelDE = "Reaktive Fähigkeiten",       labelFR = "Capacités réactives",        labelES = "Habilidades reactivas",      labelRU = "Реактивные способности",    labelIT = "Abilità reattive" },
    { cvar = "floatingCombatTextAuras",           label = "Buff / Debuff Gain",      labelDE = "Buff-/Debuff-Gewinn",        labelFR = "Gain de buff / débuff",      labelES = "Ganancia de buff / debuff",  labelRU = "Получение баффов / дебаффов", labelIT = "Guadagno buff / debuff" },
    { cvar = "floatingCombatTextLowManaHealth",   label = "Low Health / Mana Warn",  labelDE = "Wenig Leben/Mana Warnung",   labelFR = "Alerte vie / mana bas",      labelES = "Aviso de salud / maná bajo", labelRU = "Мало здоровья / маны",      labelIT = "Avviso salute / mana bassi" },
    { cvar = "floatingCombatTextCombatState",     label = "Enter / Leave Combat",    labelDE = "Kampf betreten/verlassen",   labelFR = "Entrée / Sortie de combat",  labelES = "Entrar / Salir de combate",  labelRU = "Вход / Выход из боя",       labelIT = "Inizio / Fine combattimento" },
    { cvar = "floatingCombatTextFriendlyHealers", label = "Healer Names",            labelDE = "Heiler-Namen",               labelFR = "Noms des soigneurs",         labelES = "Nombres de sanadores",       labelRU = "Имена лекарей",             labelIT = "Nomi guaritori" },

    ---------------------------------------------------------------------------
    -- Nameplates (CVar-based)
    ---------------------------------------------------------------------------
    { section = true, label = "Nameplates",             labelDE = "Namensplaketten",            labelFR = "Barres de nom",              labelES = "Placas de nombre",           labelRU = "Таблички имён",             labelIT = "Targhette nome" },
    { cvar = "nameplateShowAll",              label = "All Nameplates",              labelDE = "Alle Namensplaketten",       labelFR = "Toutes les barres de nom",   labelES = "Todas las placas de nombre", labelRU = "Все таблички",              labelIT = "Tutte le targhette" },
    { cvar = "nameplateShowFriends",          label = "Friendly Nameplates",         labelDE = "Freundliche Namensplaketten", labelFR = "Barres de nom amicales",    labelES = "Placas de nombre amistosas", labelRU = "Таблички союзников",        labelIT = "Targhette amichevoli" },
    { cvar = "nameplateShowEnemies",          label = "Enemy Nameplates",            labelDE = "Feindliche Namensplaketten", labelFR = "Barres de nom ennemies",    labelES = "Placas de nombre enemigas",  labelRU = "Таблички противников",      labelIT = "Targhette nemiche" },
    { cvar = "nameplateShowSelf",             label = "Personal Resource Bar",       labelDE = "Eigene Ressourcenanzeige",   labelFR = "Barre de ressource personnelle", labelES = "Barra de recursos personal", labelRU = "Личная панель ресурсов", labelIT = "Barra risorse personale" },
    { cvar = "nameplateShowFriendlyNPCs",     label = "Friendly NPC Nameplates",     labelDE = "Freundliche NPC-Namensplaketten", labelFR = "Barres de nom PNJ alliés", labelES = "Placas de NPC amistosos",   labelRU = "Таблички дружественных НИП", labelIT = "Targhette PNG amichevoli" },
    { cvar = "nameplateShowEnemyMinions",     label = "Enemy Pet Nameplates",        labelDE = "Gegner-Pet-Namensplaketten", labelFR = "Barres de nom familiers ennemis", labelES = "Placas de mascotas enemigas", labelRU = "Таблички питомцев врагов", labelIT = "Targhette famigli nemici" },
    { cvar = "nameplateShowEnemyMinus",       label = "Trivial Enemy Nameplates",    labelDE = "Triviale Gegner-Namensplaketten", labelFR = "Barres de nom ennemis insignifiants", labelES = "Placas de enemigos triviales", labelRU = "Таблички неопасных врагов", labelIT = "Targhette nemici insignificanti" },
    { cvar = "nameplateShowFriendlyGuardians",label = "Friendly Guardian Nameplates",labelDE = "Freundl. Wächter-Namensplaketten", labelFR = "Barres de nom gardiens alliés", labelES = "Placas de guardianes amistosos", labelRU = "Таблички дружественных стражей", labelIT = "Targhette guardiani amichevoli" },
    { cvar = "nameplateShowFriendlyMinions",  label = "Friendly Pet Nameplates",     labelDE = "Freundl. Begleiter-Namensplaketten", labelFR = "Barres de nom familiers alliés", labelES = "Placas de mascotas amistosas", labelRU = "Таблички дружественных питомцев", labelIT = "Targhette famigli amichevoli" },
    { cvar = "nameplateShowFriendlyTotems",   label = "Friendly Totem Nameplates",   labelDE = "Freundl. Totem-Namensplaketten", labelFR = "Barres de nom totems alliés", labelES = "Placas de tótems amistosos", labelRU = "Таблички дружественных тотемов", labelIT = "Targhette totem amichevoli" },
    { cvar = "ShowClassColorInNameplate",          label = "Enemy Class Colors (Plates)", labelDE = "Gegner-Klassenfarben (Plaketten)", labelFR = "Couleurs de classe ennemies (Barres)", labelES = "Colores de clase enemigos (Placas)", labelRU = "Цвета классов врагов (Таблички)", labelIT = "Colori classe nemici (Targhette)" },
    { cvar = "ShowClassColorInFriendlyNameplate",  label = "Friendly Class Colors (Plates)", labelDE = "Freundl. Klassenfarben (Plaketten)", labelFR = "Couleurs de classe alliées (Barres)", labelES = "Colores de clase amistosos (Placas)", labelRU = "Цвета классов союзников (Таблички)", labelIT = "Colori classe amichevoli (Targhette)" },
    { cvar = "nameplateResourceOnTarget",           label = "Resource on Target Plate",    labelDE = "Ressource auf Ziel-Plakette",       labelFR = "Ressource sur la barre cible", labelES = "Recurso en placa del objetivo", labelRU = "Ресурс на табличке цели", labelIT = "Risorsa su targhetta bersaglio", ed = R },
    { cvar = "nameplateShowDebuffsOnFriendly",      label = "Debuffs on Friendly Plates",  labelDE = "Debuffs auf freundl. Plaketten",    labelFR = "Débuffs sur barres alliées",  labelES = "Debuffs en placas amistosas", labelRU = "Дебаффы на табличках союзников", labelIT = "Debuff su targhette amichevoli", ed = R },
    { cvar = "nameplateMinScale",                   label = "Nameplate Min Scale",         labelDE = "Namensplaketten Min-Skalierung",    labelFR = "Échelle min barres de nom",   labelES = "Escala mín placas",          labelRU = "Мин. масштаб табличек",        labelIT = "Scala min targhette",           ed = R },
    { cvar = "nameplateMaxScale",                   label = "Nameplate Max Scale",         labelDE = "Namensplaketten Max-Skalierung",    labelFR = "Échelle max barres de nom",   labelES = "Escala máx placas",          labelRU = "Макс. масштаб табличек",       labelIT = "Scala max targhette",           ed = R },

    ---------------------------------------------------------------------------
    -- Names & Titles (CVar-based)
    ---------------------------------------------------------------------------
    { section = true, label = "Names & Titles",         labelDE = "Namen & Titel",              labelFR = "Noms et titres",             labelES = "Nombres y títulos",          labelRU = "Имена и звания",            labelIT = "Nomi e titoli" },
    { cvar = "UnitNameOwn",                   label = "Own Name",                    labelDE = "Eigener Name",               labelFR = "Nom propre",                 labelES = "Nombre propio",              labelRU = "Своё имя",                  labelIT = "Nome proprio" },
    { cvar = "UnitNameNPC",                   label = "NPC Names",                   labelDE = "NPC-Namen",                  labelFR = "Noms des PNJ",               labelES = "Nombres de NPC",             labelRU = "Имена НИП",                 labelIT = "Nomi PNG" },
    { cvar = "UnitNamePlayerGuild",           label = "Guild Names",                 labelDE = "Gildennamen",                labelFR = "Noms de guilde",             labelES = "Nombres de hermandad",       labelRU = "Названия гильдий",          labelIT = "Nomi gilda" },
    { cvar = "UnitNameGuildTitle",            label = "Guild Titles",                labelDE = "Gildentitel",                labelFR = "Titres de guilde",           labelES = "Títulos de hermandad",       labelRU = "Звания гильдий",            labelIT = "Titoli gilda" },
    { cvar = "UnitNamePlayerPVPTitle",        label = "PvP Titles",                  labelDE = "PvP-Titel",                  labelFR = "Titres JcJ",                 labelES = "Títulos JcJ",                labelRU = "PvP-звания",                labelIT = "Titoli PvP" },
    { cvar = "UnitNameFriendlyPlayerName",    label = "Friendly Player Names",       labelDE = "Freundliche Spielernamen",   labelFR = "Noms des joueurs alliés",    labelES = "Nombres de jugadores amistosos", labelRU = "Имена дружественных игроков", labelIT = "Nomi giocatori amichevoli" },
    { cvar = "UnitNameFriendlyPetName",       label = "Friendly Pet Names",          labelDE = "Freundliche Begleiternamen", labelFR = "Noms des familiers alliés",  labelES = "Nombres de mascotas amistosas", labelRU = "Имена дружественных питомцев", labelIT = "Nomi famigli amichevoli" },
    { cvar = "UnitNameFriendlyMinionName",    label = "Friendly Minion Names",       labelDE = "Freundl. Dienernamen",       labelFR = "Noms des serviteurs alliés", labelES = "Nombres de esbirros amistosos", labelRU = "Имена дружественных приспешников", labelIT = "Nomi servitori amichevoli" },
    { cvar = "UnitNameFriendlyGuardianName",  label = "Friendly Guardian Names",     labelDE = "Freundl. Wächternamen",      labelFR = "Noms des gardiens alliés",   labelES = "Nombres de guardianes amistosos", labelRU = "Имена дружественных стражей", labelIT = "Nomi guardiani amichevoli" },
    { cvar = "UnitNameFriendlyTotemName",     label = "Friendly Totem Names",        labelDE = "Freundl. Totemnamen",        labelFR = "Noms des totems alliés",     labelES = "Nombres de tótems amistosos", labelRU = "Имена дружественных тотемов", labelIT = "Nomi totem amichevoli" },
    { cvar = "UnitNameEnemyPlayerName",       label = "Enemy Player Names",          labelDE = "Feindliche Spielernamen",    labelFR = "Noms des joueurs ennemis",   labelES = "Nombres de jugadores enemigos", labelRU = "Имена вражеских игроков",  labelIT = "Nomi giocatori nemici" },
    { cvar = "UnitNameEnemyPetName",          label = "Enemy Pet Names",             labelDE = "Feindliche Begleiternamen",  labelFR = "Noms des familiers ennemis", labelES = "Nombres de mascotas enemigas", labelRU = "Имена вражеских питомцев", labelIT = "Nomi famigli nemici" },
    { cvar = "UnitNameEnemyMinionName",       label = "Enemy Minion Names",          labelDE = "Feindl. Dienernamen",        labelFR = "Noms des serviteurs ennemis", labelES = "Nombres de esbirros enemigos", labelRU = "Имена вражеских приспешников", labelIT = "Nomi servitori nemici" },
    { cvar = "UnitNameEnemyGuardianName",     label = "Enemy Guardian Names",        labelDE = "Feindl. Wächternamen",       labelFR = "Noms des gardiens ennemis",  labelES = "Nombres de guardianes enemigos", labelRU = "Имена вражеских стражей", labelIT = "Nomi guardiani nemici" },
    { cvar = "UnitNameNonCombatCreatureName", label = "Critter Names",               labelDE = "Tierchennamen",              labelFR = "Noms des bestioles",         labelES = "Nombres de criaturas",       labelRU = "Имена зверушек",            labelIT = "Nomi bestioline" },

    ---------------------------------------------------------------------------
    -- Sound (CVar-based)
    ---------------------------------------------------------------------------
    { section = true, label = "Sound",                  labelDE = "Sound",                      labelFR = "Son",                        labelES = "Sonido",                     labelRU = "Звук",                      labelIT = "Suono" },
    { cvar = "Sound_EnableAllSound",      label = "Master Sound",              labelDE = "Gesamtton",                  labelFR = "Son principal",              labelES = "Sonido principal",           labelRU = "Общий звук",                labelIT = "Audio principale" },
    { cvar = "Sound_EnableErrorSpeech",   label = "Error Speech",              labelDE = "Fehler-Stimme",              labelFR = "Voix d'erreur",              labelES = "Voz de error",               labelRU = "Голос ошибок",              labelIT = "Voce errori" },
    { cvar = "Sound_EnableMusic",         label = "Music",                     labelDE = "Musik",                      labelFR = "Musique",                    labelES = "Música",                     labelRU = "Музыка",                    labelIT = "Musica" },
    { cvar = "Sound_EnableSFX",           label = "Sound Effects",             labelDE = "Sound-Effekte",              labelFR = "Effets sonores",             labelES = "Efectos de sonido",          labelRU = "Звуковые эффекты",          labelIT = "Effetti sonori" },
    { cvar = "Sound_EnableAmbience",      label = "Ambience",                  labelDE = "Umgebungsgeräusche",         labelFR = "Ambiance",                   labelES = "Ambiente",                   labelRU = "Окружение",                 labelIT = "Ambiente" },
    { cvar = "Sound_EnableDialog",        label = "NPC Dialog Voice",          labelDE = "NPC-Dialog-Stimmen",         labelFR = "Voix de dialogue PNJ",       labelES = "Voz de diálogo de NPC",      labelRU = "Голос диалогов НИП",        labelIT = "Voce dialoghi PNG" },
    { cvar = "Sound_EnableEmoteSounds",   label = "Emote Sounds",              labelDE = "Emote-Sounds",               labelFR = "Sons d'emotes",              labelES = "Sonidos de gestos",          labelRU = "Звуки эмоций",              labelIT = "Suoni emote" },
    { cvar = "Sound_EnablePetSounds",   label = "Pet Sounds",                labelDE = "Begleiter-Sounds",           labelFR = "Sons de familier",           labelES = "Sonidos de mascota",         labelRU = "Звуки питомцев",            labelIT = "Suoni famiglio" },

    ---------------------------------------------------------------------------
    -- Gameplay Options (CVar-based)
    ---------------------------------------------------------------------------
    { section = true, label = "Gameplay Options",       labelDE = "Gameplay-Optionen",          labelFR = "Options de jeu",             labelES = "Opciones de juego",          labelRU = "Игровые настройки",         labelIT = "Opzioni di gioco" },
    { cvar = "autoLootDefault",               label = "Auto-Loot",                   labelDE = "Automatisches Plündern",     labelFR = "Butin automatique",          labelES = "Botín automático",           labelRU = "Автодобыча",                labelIT = "Bottino automatico" },
    { cvar = "autoSelfCast",                  label = "Auto Self-Cast",              labelDE = "Automatischer Selbstzauber", labelFR = "Auto-ciblage personnel",     labelES = "Autolanzamiento",            labelRU = "Автоприменение на себя",    labelIT = "Auto-lancio su di sé" },
    { cvar = "autoDismountFlying",            label = "Auto-Dismount (Flying)",      labelDE = "Automatisch Absitzen (Flug)", labelFR = "Auto-descente de monture (Vol)", labelES = "Auto-desmontar (Vuelo)",  labelRU = "Автоспешивание (Полёт)",    labelIT = "Auto-smonta (Volo)" },
    { cvar = "autoUnshift",                   label = "Auto-Unshift Form",           labelDE = "Automatisch Form ablegen",   labelFR = "Auto-annulation de forme",   labelES = "Auto-cancelar forma",        labelRU = "Автосмена формы",           labelIT = "Auto-annulla forma" },
    { cvar = "lootUnderMouse",                label = "Loot at Mouse Position",      labelDE = "Beute an Mausposition",      labelFR = "Butin à la position du curseur", labelES = "Botín en posición del ratón", labelRU = "Добыча у курсора",       labelIT = "Bottino alla posizione del mouse" },
    { cvar = "deselectOnClick",               label = "Deselect on Click",           labelDE = "Auswahl bei Klick aufheben", labelFR = "Désélectionner au clic",     labelES = "Deseleccionar al hacer clic", labelRU = "Снять выделение по клику", labelIT = "Deseleziona al clic" },
    { cvar = "stopAutoAttackOnTargetChange",  label = "Stop Attack on Target Change",labelDE = "Angriff bei Zielwechsel stoppen", labelFR = "Arrêter l'attaque au changement de cible", labelES = "Detener ataque al cambiar objetivo", labelRU = "Остановить атаку при смене цели", labelIT = "Ferma attacco al cambio bersaglio" },
    { cvar = "lockActionBars",                label = "Lock Action Bars",            labelDE = "Aktionsleisten sperren",     labelFR = "Verrouiller les barres",     labelES = "Bloquear barras de acción",  labelRU = "Заблокировать панели",      labelIT = "Blocca barre azione" },
    { cvar = "alwaysShowActionBars",          label = "Always Show Action Bars",     labelDE = "Aktionsleisten immer anzeigen", labelFR = "Toujours afficher les barres", labelES = "Mostrar barras siempre",  labelRU = "Всегда показывать панели",  labelIT = "Mostra sempre barre azione" },
    { cvar = "countdownForCooldowns",         label = "Cooldown Numbers",            labelDE = "Abklingzeit-Zahlen",         labelFR = "Nombres de recharge",        labelES = "Números de reutilización",   labelRU = "Числа перезарядки",         labelIT = "Numeri recupero" },
    { cvar = "ActionButtonUseKeyDown",        label = "Cast on Key Down",            labelDE = "Zauber bei Tastendruck",     labelFR = "Lancer à l'appui de touche", labelES = "Lanzar al presionar tecla",  labelRU = "Каст при нажатии клавиши",  labelIT = "Lancia alla pressione tasto" },
    { cvar = "autoQuestWatch",                label = "Auto Quest Watch",            labelDE = "Automatische Quest-Verfolgung", labelFR = "Suivi de quête automatique", labelES = "Seguimiento de misión auto", labelRU = "Автоотслеживание заданий", labelIT = "Tracciamento missioni auto" },
    { cvar = "autoQuestProgress",             label = "Auto Quest Progress",         labelDE = "Automatischer Quest-Fortschritt", labelFR = "Progression de quête auto", labelES = "Progreso de misión auto",  labelRU = "Автопрогресс заданий",      labelIT = "Progresso missioni auto" },
    { cvar = "interactOnLeftClick",           label = "Interact on Left-Click",      labelDE = "Interaktion bei Linksklick",  labelFR = "Interagir au clic gauche",   labelES = "Interactuar con clic izquierdo", labelRU = "Взаимодействие по ЛКМ", labelIT = "Interagisci con clic sinistro", ed = R },
    { cvar = "instantQuestText",              label = "Instant Quest Text",          labelDE = "Sofortiger Quest-Text",      labelFR = "Texte de quête instantané",  labelES = "Texto de misión instantáneo", labelRU = "Мгновенный текст заданий", labelIT = "Testo missione istantaneo" },
    { cvar = "predictedHealth",               label = "Predicted Health",            labelDE = "Vorhergesagte Gesundheit",   labelFR = "Vie prédite",                labelES = "Salud predicha",             labelRU = "Предсказанное здоровье",    labelIT = "Salute prevista" },
    { cvar = "scriptErrors",                  label = "Lua Error Display",           labelDE = "Lua-Fehleranzeige",          labelFR = "Affichage des erreurs Lua",  labelES = "Mostrar errores Lua",        labelRU = "Отображение ошибок Lua",    labelIT = "Visualizza errori Lua" },

    ---------------------------------------------------------------------------
    -- Raid & Party (CVar-based)
    ---------------------------------------------------------------------------
    { section = true, label = "Raid & Party",           labelDE = "Raid & Gruppe",              labelFR = "Raid et groupe",             labelES = "Banda y grupo",              labelRU = "Рейд и группа",            labelIT = "Raid e gruppo" },
    { cvar = "raidFramesDisplayPowerBars",    label = "Raid Power Bars",             labelDE = "Raid-Energieleisten",         labelFR = "Barres de puissance du raid", labelES = "Barras de poder de banda",  labelRU = "Полоски ресурсов рейда",    labelIT = "Barre potere raid",          ed = MOP_UP },
    { cvar = "raidFramesDisplayClassColor",   label = "Raid Class Colors",           labelDE = "Raid-Klassenfarben",          labelFR = "Couleurs de classe du raid", labelES = "Colores de clase de banda",  labelRU = "Цвета классов в рейде",     labelIT = "Colori classe raid",         ed = MOP_UP },
    { cvar = "useCompactPartyFrames",         label = "Compact Party Frames",        labelDE = "Kompakte Gruppenframes",      labelFR = "Cadres de groupe compacts",  labelES = "Marcos de grupo compactos",  labelRU = "Компактные фреймы группы",  labelIT = "Riquadri gruppo compatti",   ed = MOP_UP },
    { cvar = "showPartyPets",                 label = "Show Party Pets",             labelDE = "Gruppen-Begleiter anzeigen", labelFR = "Afficher les familiers du groupe", labelES = "Mostrar mascotas de grupo", labelRU = "Показать питомцев группы", labelIT = "Mostra famigli del gruppo" },
    { cvar = "showArenaEnemyFrames",          label = "Arena Enemy Frames",          labelDE = "Arena-Gegnerframes",          labelFR = "Cadres ennemis d'arène",     labelES = "Marcos de enemigos de arena", labelRU = "Фреймы противников арены", labelIT = "Riquadri nemici arena",      ed = TBC_UP },

    ---------------------------------------------------------------------------
    -- Social & Chat Options (CVar-based)
    ---------------------------------------------------------------------------
    { section = true, label = "Social & Chat Options",  labelDE = "Soziales & Chat-Optionen",   labelFR = "Social et options de chat",  labelES = "Social y opciones de chat",  labelRU = "Социальное и чат",          labelIT = "Social e opzioni chat" },
    { cvar = "profanityFilter",               label = "Profanity Filter",            labelDE = "Schimpfwortfilter",          labelFR = "Filtre de grossièretés",     labelES = "Filtro de groserías",        labelRU = "Фильтр нецензурной лексики", labelIT = "Filtro volgarità" },
    { cvar = "spamFilter",                    label = "Spam Filter",                 labelDE = "Spam-Filter",                labelFR = "Filtre anti-spam",           labelES = "Filtro de spam",             labelRU = "Фильтр спама",             labelIT = "Filtro spam" },
    { cvar = "guildMemberNotify",             label = "Guild Online Notifications",  labelDE = "Gilden-Online-Meldungen",    labelFR = "Notifications de guilde en ligne", labelES = "Notificaciones de hermandad en línea", labelRU = "Уведомления о входе в гильдию", labelIT = "Notifiche gilda online" },
    { cvar = "blockTrades",                   label = "Block Trades",                labelDE = "Handel blockieren",          labelFR = "Bloquer les échanges",       labelES = "Bloquear intercambios",      labelRU = "Блокировать обмены",        labelIT = "Blocca scambi" },
    { cvar = "blockChannelInvites",           label = "Block Channel Invites",       labelDE = "Kanaleinladungen blockieren", labelFR = "Bloquer les invitations de canal", labelES = "Bloquear invitaciones de canal", labelRU = "Блокировать приглашения в каналы", labelIT = "Blocca inviti canale" },
    { cvar = "showToastOnline",               label = "Friend Online Toast",         labelDE = "Freund-Online-Meldung",      labelFR = "Notification ami en ligne",  labelES = "Notificación de amigo en línea", labelRU = "Уведомление о друге онлайн", labelIT = "Notifica amico online" },
    { cvar = "showToastOffline",              label = "Friend Offline Toast",        labelDE = "Freund-Offline-Meldung",     labelFR = "Notification ami hors ligne", labelES = "Notificación de amigo desconectado", labelRU = "Уведомление о друге офлайн", labelIT = "Notifica amico offline" },
    { cvar = "showToastBroadcast",            label = "Broadcast Toast",             labelDE = "Broadcast-Meldung",          labelFR = "Notification de diffusion",  labelES = "Notificación de difusión",   labelRU = "Уведомление о трансляции",  labelIT = "Notifica broadcast" },
    { cvar = "showToastFriendRequest",        label = "Friend Request Toast",        labelDE = "Freundschaftsanfrage-Meldung", labelFR = "Notification demande d'ami", labelES = "Notificación de solicitud de amistad", labelRU = "Уведомление о запросе дружбы", labelIT = "Notifica richiesta amicizia" },
    { cvar = "removeChatDelay",               label = "Remove Chat Delay",           labelDE = "Chat-Verzögerung entfernen", labelFR = "Supprimer le délai du chat", labelES = "Eliminar retraso del chat",  labelRU = "Убрать задержку чата",      labelIT = "Rimuovi ritardo chat" },

    ---------------------------------------------------------------------------
    -- Map & Navigation
    ---------------------------------------------------------------------------
    { section = true, label = "Map & Navigation",       labelDE = "Karte & Navigation",         labelFR = "Carte et navigation",        labelES = "Mapa y navegación",          labelRU = "Карта и навигация",         labelIT = "Mappa e navigazione" },
    { name = "MinimapCluster",           label = "Minimap",                   labelDE = "Minimap",                    labelFR = "Minicarte",                  labelES = "Minimapa",                   labelRU = "Мини-карта",                labelIT = "Minimappa" },
    { name = "GameTimeFrame",            label = "Calendar Button",           labelDE = "Kalender-Button",            labelFR = "Bouton calendrier",          labelES = "Botón de calendario",        labelRU = "Кнопка календаря",          labelIT = "Pulsante calendario" },
    { name = "TimeManagerClockButton",   label = "Clock",                     labelDE = "Uhr",                        labelFR = "Horloge",                    labelES = "Reloj",                      labelRU = "Часы",                      labelIT = "Orologio" },
    { name = "MiniMapMailFrame",         label = "Mail Notification",         labelDE = "Post-Benachrichtigung",      labelFR = "Notification de courrier",   labelES = "Notificación de correo",     labelRU = "Уведомление о почте",       labelIT = "Notifica posta" },
    { name = "MiniMapInstanceDifficulty", label = "Instance Difficulty",      labelDE = "Instanz-Schwierigkeit",      labelFR = "Difficulté d'instance",      labelES = "Dificultad de instancia",    labelRU = "Сложность подземелья",      labelIT = "Difficoltà istanza" },
    { name = "MiniMapTracking",          label = "Tracking Button",           labelDE = "Tracking-Button",            labelFR = "Bouton de pistage",          labelES = "Botón de rastreo",           labelRU = "Кнопка отслеживания",       labelIT = "Pulsante tracciamento" },
    { name = "ObjectiveTrackerFrame",    label = "Quest / Objective Tracker", labelDE = "Quest-Tracker",              labelFR = "Suivi des quêtes",           labelES = "Rastreador de misiones",     labelRU = "Трекер заданий",            labelIT = "Tracciatore missioni" },
    { name = "MinimapZoneTextButton",    label = "Zone Name (Minimap)",       labelDE = "Zonenname (Minimap)",        labelFR = "Nom de zone (Minicarte)",    labelES = "Nombre de zona (Minimapa)",  labelRU = "Название зоны (Мини-карта)", labelIT = "Nome zona (Minimappa)" },
    { name = "AddonCompartmentFrame",    label = "Addon Compartment",         labelDE = "Addon-Fach",                  labelFR = "Compartiment d'addons",      labelES = "Compartimento de addons",    labelRU = "Отсек аддонов",             labelIT = "Scomparto addon",            ed = R },

    ---------------------------------------------------------------------------
    -- Alerts & Notifications
    ---------------------------------------------------------------------------
    { section = true, label = "Alerts & Info",          labelDE = "Meldungen & Info",           labelFR = "Alertes et info",            labelES = "Alertas e info",             labelRU = "Оповещения и инфо",         labelIT = "Avvisi e info" },
    { name = "BossBanner",               label = "Boss Banner",               labelDE = "Boss-Banner",                 labelFR = "Bannière de boss",           labelES = "Estandarte de jefe",         labelRU = "Баннер босса",              labelIT = "Stendardo boss",             ed = MOP_UP },
    { name = "AlertFrame",               label = "Achievement Alerts",        labelDE = "Erfolgs-Meldungen",          labelFR = "Alertes de hauts faits",     labelES = "Alertas de logros",          labelRU = "Оповещения достижений",     labelIT = "Avvisi imprese" },
    { name = "TalkingHeadFrame",         label = "Talking Head",              labelDE = "Sprechender Kopf",            labelFR = "Tête parlante",              labelES = "Cabeza parlante",            labelRU = "Говорящая голова",           labelIT = "Testa parlante",             ed = R },
    { name = "ZoneTextFrame",            label = "Zone Text",                 labelDE = "Zonentext",                  labelFR = "Texte de zone",              labelES = "Texto de zona",              labelRU = "Текст зоны",                labelIT = "Testo zona" },
    { name = "SubZoneTextFrame",         label = "Sub Zone Text",             labelDE = "Unterzonentext",             labelFR = "Texte de sous-zone",         labelES = "Texto de subzona",           labelRU = "Текст подзоны",             labelIT = "Testo sottozona" },
    { name = "LossOfControlFrame",       label = "Loss of Control",           labelDE = "Kontrollverlust",             labelFR = "Perte de contrôle",          labelES = "Pérdida de control",         labelRU = "Потеря контроля",           labelIT = "Perdita di controllo",       ed = MOP_UP },
    { name = "GroupLootContainer",       label = "Loot Rolls",                labelDE = "Beutewürfe",                 labelFR = "Jets de butin",              labelES = "Tiradas de botín",           labelRU = "Розыгрыши добычи",          labelIT = "Tiri bottino" },
    { name = "BonusRollFrame",           label = "Bonus Roll",                labelDE = "Bonuswurf",                   labelFR = "Jet bonus",                  labelES = "Tirada de bonificación",     labelRU = "Бонусный бросок",           labelIT = "Tiro bonus",                 ed = MOP_UP },
    { name = "SpellActivationOverlayFrame", label = "Spell Proc Overlays",    labelDE = "Zauber-Proc-Overlays",        labelFR = "Effets de proc de sort",     labelES = "Superposiciones de proc",    labelRU = "Оверлеи проков заклинаний", labelIT = "Overlay proc incantesimi",   ed = MOP_UP },
    { name = "GhostFrame",              label = "Spirit Release",             labelDE = "Geistfreilassung",           labelFR = "Libération d'esprit",        labelES = "Liberación de espíritu",     labelRU = "Освобождение духа",         labelIT = "Rilascio spirito" },
    { name = "TimerTracker",             label = "BG / Arena Timer",          labelDE = "BG-/Arena-Timer",            labelFR = "Chrono CdB / Arène",         labelES = "Temporizador CdB / Arena",   labelRU = "Таймер ПБ / Арены",         labelIT = "Timer CdB / Arena" },
    { name = "MirrorTimerContainer",     label = "Breath / Fatigue Timer",    labelDE = "Atem-/Ermüdungs-Timer",      labelFR = "Chrono souffle / fatigue",   labelES = "Temporizador aliento / fatiga", labelRU = "Таймер дыхания / усталости", labelIT = "Timer respiro / fatica" },
    { name = "UIErrorsFrame",            label = "Error Text (red)",          labelDE = "Fehlertext (rot)",           labelFR = "Texte d'erreur (rouge)",     labelES = "Texto de error (rojo)",      labelRU = "Текст ошибок (красный)",    labelIT = "Testo errore (rosso)" },
    { name = "RaidWarningFrame",         label = "Raid Warning Text",         labelDE = "Raid-Warnungstext",          labelFR = "Texte d'alerte de raid",     labelES = "Texto de aviso de banda",    labelRU = "Текст предупреждения рейда", labelIT = "Testo avviso raid" },
    { name = "RaidBossEmoteFrame",       label = "Boss Emote Text",           labelDE = "Boss-Emote-Text",            labelFR = "Texte d'emote du boss",      labelES = "Texto de gesto del jefe",    labelRU = "Текст эмоций босса",        labelIT = "Testo emote boss" },
    { name = "LevelUpDisplay",           label = "Level Up Animation",        labelDE = "Level-Up-Animation",          labelFR = "Animation de montée de niveau", labelES = "Animación de subida de nivel", labelRU = "Анимация повышения уровня", labelIT = "Animazione salita di livello", ed = R },
    { name = "WorldStateAlwaysUpFrame", label = "World State Info",          labelDE = "Weltstatus-Info",             labelFR = "Info état du monde",         labelES = "Info de estado del mundo",   labelRU = "Информация о состоянии мира", labelIT = "Info stato del mondo",     ed = CL },

    ---------------------------------------------------------------------------
    -- Widgets & Misc
    ---------------------------------------------------------------------------
    { section = true, label = "Widgets & Misc",         labelDE = "Widgets & Sonstiges",        labelFR = "Widgets et divers",          labelES = "Widgets y otros",            labelRU = "Виджеты и прочее",          labelIT = "Widget e varie" },
    { name = "UIWidgetTopCenterContainerFrame",    label = "Top Center Widgets",  labelDE = "Obere Widgets",              labelFR = "Widgets centre haut",        labelES = "Widgets centro superior",    labelRU = "Виджеты сверху по центру",  labelIT = "Widget centro superiore",    ed = R },
    { name = "UIWidgetBelowMinimapContainerFrame", label = "Minimap Widgets",     labelDE = "Minimap-Widgets",            labelFR = "Widgets de minicarte",       labelES = "Widgets de minimapa",        labelRU = "Виджеты мини-карты",        labelIT = "Widget minimappa",           ed = R },
    { name = "UIWidgetCenterScreenContainerFrame", label = "Center Screen Widgets", labelDE = "Bildschirmmitte-Widgets", labelFR = "Widgets centre écran",      labelES = "Widgets centro de pantalla", labelRU = "Виджеты центра экрана",     labelIT = "Widget centro schermo",      ed = R },
    { name = "DurabilityFrame",          label = "Durability",                labelDE = "Haltbarkeit",                labelFR = "Durabilité",                 labelES = "Durabilidad",                labelRU = "Прочность",                 labelIT = "Durabilità" },
    { name = "VehicleSeatIndicator",     label = "Vehicle Seat",              labelDE = "Fahrzeugsitz",                labelFR = "Siège de véhicule",          labelES = "Asiento de vehículo",        labelRU = "Место в транспорте",        labelIT = "Posto veicolo",              ed = MOP_UP },
    { name = "QueueStatusButton",        label = "Queue Status Eye",          labelDE = "Warteschlangen-Auge",        labelFR = "Oeil de file d'attente",     labelES = "Ojo de estado de cola",      labelRU = "Глаз статуса очереди",      labelIT = "Occhio stato coda" },
    { name = "PlayerPowerBarAlt",        label = "Alternate Power Bar",       labelDE = "Alternative Energieleiste",  labelFR = "Barre de puissance alternative", labelES = "Barra de poder alternativa", labelRU = "Альтернативная панель ресурсов", labelIT = "Barra potere alternativa" },
    { name = "OrderHallCommandBar",      label = "Order Hall Bar",            labelDE = "Ordenshallen-Leiste",          labelFR = "Barre du sanctuaire de classe", labelES = "Barra del salón de la orden", labelRU = "Панель зала ордена",     labelIT = "Barra sala dell'ordine",     ed = R },
    { name = "ExpansionLandingPageMinimapButton",  label = "Expansion Landing Button", labelDE = "Erweiterungs-Landungstaste", labelFR = "Bouton d'extension",         labelES = "Botón de expansión",         labelRU = "Кнопка дополнения",         labelIT = "Pulsante espansione",        ed = R },
    { name = "TicketStatusFrame",        label = "GM Ticket Status",          labelDE = "GM-Ticket-Status",           labelFR = "Statut du ticket MJ",        labelES = "Estado del ticket GM",       labelRU = "Статус тикета ГМ",          labelIT = "Stato ticket GM" },
    { name = "StreamingIcon",            label = "Streaming Indicator",       labelDE = "Streaming-Anzeige",           labelFR = "Indicateur de streaming",    labelES = "Indicador de streaming",     labelRU = "Индикатор стриминга",       labelIT = "Indicatore streaming",       ed = R },
    { name = "MainStatusTrackingBarContainer", label = "Status Bar Container", labelDE = "Statusleisten-Container",    labelFR = "Conteneur de barres d'état", labelES = "Contenedor de barras de estado", labelRU = "Контейнер полос состояния", labelIT = "Contenitore barre stato", ed = R },

    ---------------------------------------------------------------------------
    -- PvP
    ---------------------------------------------------------------------------
    { section = true, label = "PvP",                   labelDE = "PvP",                        labelFR = "JcJ",                        labelES = "JcJ",                        labelRU = "PvP",                       labelIT = "PvP" },
    { name = "PVPReadyDialog",           label = "PvP Ready Popup",           labelDE = "PvP-Bereit-Popup",           labelFR = "Popup JcJ prêt",             labelES = "Popup JcJ listo",            labelRU = "Всплывающее окно PvP",      labelIT = "Popup PvP pronto" },
    { name = "BattlefieldMapFrame",      label = "Battleground Map",          labelDE = "Schlachtfeldkarte",          labelFR = "Carte du champ de bataille", labelES = "Mapa del campo de batalla",  labelRU = "Карта поля боя",            labelIT = "Mappa campo di battaglia" },
    { name = "PVPMicroButton",           label = "PvP Button",                labelDE = "PvP-Button",                 labelFR = "Bouton JcJ",                 labelES = "Botón JcJ",                  labelRU = "Кнопка PvP",                labelIT = "Pulsante PvP",                  ed = CL },

    ---------------------------------------------------------------------------
    -- Tutorials (CVar-based)
    ---------------------------------------------------------------------------
    { section = true, label = "Tutorials",              labelDE = "Tutorials",                  labelFR = "Tutoriels",                  labelES = "Tutoriales",                 labelRU = "Обучение",                  labelIT = "Tutorial" },
    { cvar = "showTutorials",            label = "Tutorial Popups",           labelDE = "Tutorial-Popups",            labelFR = "Popups de tutoriel",         labelES = "Popups de tutorial",         labelRU = "Всплывающие подсказки",     labelIT = "Popup tutorial" },
    { cvar = "showGameTips",             label = "Loading Screen Tips",       labelDE = "Ladebildschirm-Tipps",       labelFR = "Astuces de chargement",      labelES = "Consejos de pantalla de carga", labelRU = "Советы на экране загрузки", labelIT = "Suggerimenti schermata di caricamento" },

    ---------------------------------------------------------------------------
    -- HUD Options (CVar-based)
    ---------------------------------------------------------------------------
    { section = true, label = "HUD Options",            labelDE = "HUD-Optionen",               labelFR = "Options ATH",                labelES = "Opciones HUD",               labelRU = "Настройки HUD",             labelIT = "Opzioni HUD" },
    { cvar = "showTargetCastbar",        label = "Target Cast Bar",           labelDE = "Ziel-Zauberleiste",          labelFR = "Barre d'incantation de la cible", labelES = "Barra de lanzamiento del objetivo", labelRU = "Полоса заклинаний цели", labelIT = "Barra incantesimo bersaglio" },
    { cvar = "showVKeyCastbar",          label = "Focus Cast Bar",            labelDE = "Fokus-Zauberleiste",         labelFR = "Barre d'incantation du focus", labelES = "Barra de lanzamiento del enfoque", labelRU = "Полоса заклинаний фокуса", labelIT = "Barra incantesimo focus" },
    { cvar = "showTargetOfTarget",       label = "Target of Target",          labelDE = "Ziel des Ziels",             labelFR = "Cible de la cible",          labelES = "Objetivo del objetivo",      labelRU = "Цель цели",                 labelIT = "Bersaglio del bersaglio" },
    { cvar = "fullSizeFocusFrame",       label = "Full Size Focus Frame",     labelDE = "Fokus-Frame Vollgröße",      labelFR = "Cadre de focus taille réelle", labelES = "Marco de enfoque tamaño completo", labelRU = "Полноразмерный фрейм фокуса", labelIT = "Riquadro focus dimensione intera" },
    { cvar = "doNotFlashLowHealthWarning", label = "Low Health Flash",        labelDE = "Warnung: Wenig Leben",       labelFR = "Flash de vie basse",         labelES = "Destello de salud baja",     labelRU = "Мигание при низком здоровье", labelIT = "Lampeggio salute bassa" },
    { cvar = "empowerTapControls",      label = "Empower Tap Controls",      labelDE = "Empower-Tap-Steuerung",       labelFR = "Contrôles de puissance",     labelES = "Controles de potenciación",  labelRU = "Управление усилением",      labelIT = "Controlli potenziamento",    ed = R },
    { cvar = "reticleOnTargetCastBar",  label = "Reticle on Target Cast Bar", labelDE = "Fadenkreuz auf Ziel-Zauberleiste", labelFR = "Réticule sur barre de lancement", labelES = "Retículo en barra de lanzamiento", labelRU = "Прицел на полосе каста цели", labelIT = "Reticolo su barra lancio",    ed = R },

    ---------------------------------------------------------------------------
    -- Visual Effects (CVar-based)
    ---------------------------------------------------------------------------
    { section = true, label = "Visual Effects",         labelDE = "Visuelle Effekte",           labelFR = "Effets visuels",             labelES = "Efectos visuales",           labelRU = "Визуальные эффекты",        labelIT = "Effetti visivi" },
    { cvar = "ffxGlow",                  label = "Full Screen Glow",          labelDE = "Vollbild-Leuchten",          labelFR = "Lueur plein écran",          labelES = "Resplandor de pantalla completa", labelRU = "Полноэкранное свечение", labelIT = "Bagliore schermo intero" },
    { cvar = "ffxDeath",                 label = "Death Effect",              labelDE = "Todeseffekt",                labelFR = "Effet de mort",              labelES = "Efecto de muerte",           labelRU = "Эффект смерти",             labelIT = "Effetto morte" },
    { cvar = "movieSubtitle",            label = "Movie Subtitles",           labelDE = "Film-Untertitel",            labelFR = "Sous-titres des cinématiques", labelES = "Subtítulos de cinemáticas", labelRU = "Субтитры роликов",         labelIT = "Sottotitoli filmati" },

    ---------------------------------------------------------------------------
    -- Accessibility (CVar-based)
    ---------------------------------------------------------------------------
    { section = true, label = "Accessibility",          labelDE = "Barrierefreiheit",           labelFR = "Accessibilité",              labelES = "Accesibilidad",              labelRU = "Доступность",               labelIT = "Accessibilità" },
    { cvar = "colorblindMode",           label = "Colorblind Mode",           labelDE = "Farbenblind-Modus",          labelFR = "Mode daltonien",             labelES = "Modo daltónico",             labelRU = "Режим дальтонизма",         labelIT = "Modalità daltonico" },
    { cvar = "enableMovePad",            label = "Move Pad",                  labelDE = "Bewegungsfeld",              labelFR = "Pavé de déplacement",        labelES = "Panel de movimiento",        labelRU = "Панель движения",           labelIT = "Pad di movimento" },
    { cvar = "useUiScale",               label = "UI Scale",                  labelDE = "UI-Skalierung",              labelFR = "Échelle de l'interface",     labelES = "Escala de interfaz",         labelRU = "Масштаб интерфейса",        labelIT = "Scala interfaccia" },

    ---------------------------------------------------------------------------
    -- Decorations (Textures / Regions)
    ---------------------------------------------------------------------------
    { section = true, label = "Decorations",           labelDE = "Dekorationen",               labelFR = "Décorations",                labelES = "Decoraciones",               labelRU = "Декорации",                 labelIT = "Decorazioni" },
    { texture = "MinimapBorder",                label = "Minimap Border",            labelDE = "Minimap-Rahmen",             labelFR = "Bordure de minicarte",       labelES = "Borde del minimapa",         labelRU = "Рамка мини-карты",          labelIT = "Bordo minimappa" },
    { texture = "MinimapNorthTag",              label = "Minimap North Indicator",   labelDE = "Minimap-Nordanzeige",        labelFR = "Indicateur nord de minicarte", labelES = "Indicador norte del minimapa", labelRU = "Индикатор севера мини-карты", labelIT = "Indicatore nord minimappa" },
    { texture = "MainMenuBarTexture0",          label = "Action Bar Art (Left)",     labelDE = "Aktionsleisten-Art (Links)",     labelFR = "Art de barre (Gauche)",      labelES = "Arte de barra (Izquierda)",  labelRU = "Оформление панели (Лево)",  labelIT = "Arte barra (Sinistra)",      ed = CL },
    { texture = "MainMenuBarTexture1",          label = "Action Bar Art (Right)",    labelDE = "Aktionsleisten-Art (Rechts)",    labelFR = "Art de barre (Droite)",      labelES = "Arte de barra (Derecha)",    labelRU = "Оформление панели (Право)", labelIT = "Arte barra (Destra)",        ed = CL },
    { texture = "MainMenuBarTexture2",          label = "Bottom Bar Art (Left)",     labelDE = "Untere Leisten-Art (Links)",     labelFR = "Art barre inférieure (Gauche)", labelES = "Arte barra inferior (Izquierda)", labelRU = "Оформление нижней панели (Лево)", labelIT = "Arte barra inferiore (Sinistra)", ed = CL },
    { texture = "MainMenuBarTexture3",          label = "Bottom Bar Art (Right)",    labelDE = "Untere Leisten-Art (Rechts)",    labelFR = "Art barre inférieure (Droite)", labelES = "Arte barra inferior (Derecha)", labelRU = "Оформление нижней панели (Право)", labelIT = "Arte barra inferiore (Destra)", ed = CL },
    { texture = "SlidingActionBarTexture0",     label = "Bonus Bar Art (Left)",      labelDE = "Bonusleisten-Art (Links)",       labelFR = "Art barre bonus (Gauche)",   labelES = "Arte barra bonus (Izquierda)", labelRU = "Оформление бонус-панели (Лево)", labelIT = "Arte barra bonus (Sinistra)", ed = CL },
    { texture = "SlidingActionBarTexture1",     label = "Bonus Bar Art (Right)",     labelDE = "Bonusleisten-Art (Rechts)",      labelFR = "Art barre bonus (Droite)",   labelES = "Arte barra bonus (Derecha)", labelRU = "Оформление бонус-панели (Право)", labelIT = "Arte barra bonus (Destra)", ed = CL },
    { texture = "StanceBarLeft",                label = "Stance Bar Art (Left)",     labelDE = "Haltungsleisten-Art (Links)", labelFR = "Art barre de postures (Gauche)", labelES = "Arte barra posturas (Izquierda)", labelRU = "Оформление панели стоек (Лево)", labelIT = "Arte barra posizioni (Sinistra)" },
    { texture = "StanceBarMiddle",              label = "Stance Bar Art (Middle)",   labelDE = "Haltungsleisten-Art (Mitte)", labelFR = "Art barre de postures (Centre)", labelES = "Arte barra posturas (Centro)", labelRU = "Оформление панели стоек (Центр)", labelIT = "Arte barra posizioni (Centro)" },
    { texture = "StanceBarRight",               label = "Stance Bar Art (Right)",    labelDE = "Haltungsleisten-Art (Rechts)", labelFR = "Art barre de postures (Droite)", labelES = "Arte barra posturas (Derecha)", labelRU = "Оформление панели стоек (Право)", labelIT = "Arte barra posizioni (Destra)" },
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
    if type(db.combatHideFrames) ~= "table" then
        db.combatHideFrames = {}
    end
    if type(db.hiddenTextures) ~= "table" then
        db.hiddenTextures = {}
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
    local lang = self._currentLanguage or GetLocale()
    if lang == "deDE" and entry.labelDE then return entry.labelDE end
    if lang == "frFR" and entry.labelFR then return entry.labelFR end
    if lang == "esES" and entry.labelES then return entry.labelES end
    if lang == "esMX" and entry.labelES then return entry.labelES end
    if lang == "ruRU" and entry.labelRU then return entry.labelRU end
    if lang == "itIT" and entry.labelIT then return entry.labelIT end
    return entry.label
end
