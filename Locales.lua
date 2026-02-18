--[[
    HideAnything - Locales.lua
    Localization: English, German, French, Spanish, Russian, Italian
    Table-based structure for runtime language switching
]]

local AddonName, HA = ...

-- Startup diagnostic
HA._loaded = true
C_Timer.After(3, function()
    if HA._loaded and not HA._initDone then
        print("|cffff8800[HideAnything]|r Addon files loaded but initialization failed! Check /console scriptErrors 1")
    end
end)

---------------------------------------------------------------------------
-- Language system
---------------------------------------------------------------------------
HA.LOCALES = {}
HA.L = {}

HA.LANGUAGE_NAMES = {
    auto = "Auto",
    enUS = "English",
    deDE = "Deutsch",
    frFR = "Français",
    esES = "Español",
    ruRU = "Русский",
    itIT = "Italiano",
}
HA.LANGUAGE_ORDER = { "auto", "enUS", "deDE", "frFR", "esES", "ruRU", "itIT" }

---------------------------------------------------------------------------
-- English (base language - all keys must exist here)
---------------------------------------------------------------------------
HA.LOCALES["enUS"] = {
    -- General
    ADDON_LOADED             = "|cff00cc66Hide|rAnything|r v%s loaded. Type |cff00cc66/hide|r for help.",
    ADDON_NAME               = "HideAnything",
    VERSION                  = "Version",

    -- Slash command help
    HELP_HEADER              = "|cff00cc66HideAnything|r Commands:",
    HELP_TOGGLE              = "|cff00cc66/hide toggle|r - Toggle the options panel",
    HELP_SHOW_ALL            = "|cff00cc66/hide showall|r - Show all hidden frames",
    HELP_HIDE                = "|cff00cc66/hide hide <frame>|r - Hide a specific frame by name",
    HELP_SHOW                = "|cff00cc66/hide show <frame>|r - Show a specific frame by name",
    HELP_LIST                = "|cff00cc66/hide list|r - List all currently hidden frames",
    HELP_RESET               = "|cff00cc66/hide reset|r - Reset all settings to defaults",
    HELP_PROFILE             = "|cff00cc66/hide profile <name>|r - Load a profile",
    HELP_PROFILES            = "|cff00cc66/hide profiles|r - List all saved profiles",
    HELP_LOCK                = "|cff00cc66/hide lock|r - Lock all hidden frames",
    HELP_UNLOCK              = "|cff00cc66/hide unlock|r - Unlock all hidden frames",
    HELP_STATUS              = "|cff00cc66/hide status|r - Show addon status",
    HELP_MINIMAP             = "|cff00cc66/hide minimap|r - Toggle minimap button",
    HELP_ALPHA               = "|cff00cc66/hide alpha <frame> <0-100>|r - Set frame opacity",
    HELP_UNDO                = "|cff00cc66/hide undo|r - Undo last action (Ctrl+Z)",
    HELP_REDO                = "|cff00cc66/hide redo|r - Redo last undone action (Ctrl+Y)",
    HELP_PICKER              = "|cff00cc66/hide picker|r - Toggle frame picker mode (Ctrl+P)",
    HELP_PRESET              = "|cff00cc66/hide preset <name>|r - Apply a preset profile",

    -- Hide / Show
    FRAME_HIDDEN             = "Hidden: |cffff8800%s|r",
    FRAME_SHOWN              = "Shown: |cff00ff00%s|r",
    FRAME_NOT_FOUND          = "Frame |cffff4444%s|r not found.",
    FRAME_NOT_HIDDEN         = "Frame |cffffffff%s|r is not currently hidden.",
    ALL_FRAMES_SHOWN         = "All |cff00ff00%d|r hidden frames are now visible again.",
    NO_FRAMES_HIDDEN         = "No frames are currently hidden.",

    -- Alpha / Opacity
    ALPHA_SET                = "Opacity of |cff00cc66%s|r set to |cffffffff%d%%|r.",
    ALPHA_RESET              = "Opacity of |cff00cc66%s|r reset to 100%%.",
    ALPHA_TITLE              = "Opacity",
    ALPHA_LABEL              = "Opacity: %d%%",
    ALPHA_TOOLTIP            = "Set frame transparency (0%% = invisible, 100%% = fully visible)",

    -- Frame states (tooltips)
    FRAME_STATE_HIDDEN       = "Currently hidden",
    FRAME_STATE_VISIBLE      = "Currently visible",
    FRAME_STATE_ALPHA        = "Opacity: %d%%",
    FRAME_NOT_LOADED         = "Frame not loaded yet",

    -- Search
    SEARCH_PLACEHOLDER       = "Search frames...",

    -- Protected
    PICKER_PROTECTED         = "Cannot hide |cffff4444%s|r - this frame is protected.",
    PICKER_ALREADY_HIDDEN    = "|cffffffff%s|r is already hidden.",

    -- List
    LIST_HEADER              = "|cff00cc66Hidden frames|r (%d):",
    LIST_ENTRY               = "  |cffff8800%d.|r %s",

    -- Profiles
    PROFILE_SAVED            = "Profile |cff00cc66%s|r saved with %d hidden frames.",
    PROFILE_LOADED           = "Profile |cff00cc66%s|r loaded (%d frames hidden).",
    PROFILE_DELETED          = "Profile |cffff4444%s|r deleted.",
    PROFILE_NOT_FOUND        = "Profile |cffff4444%s|r not found.",
    PROFILE_EXISTS           = "Profile |cffffffff%s|r already exists. Use |cff00cc66/hide profile overwrite <name>|r to overwrite.",
    PROFILE_LIST_HEADER      = "|cff00cc66Saved profiles|r (%d):",
    PROFILE_LIST_ENTRY       = "  |cffff8800%d.|r %s |cff888888(%d frames)|r",
    PROFILE_NO_PROFILES      = "No saved profiles.",
    PROFILE_EXPORTED         = "Profile |cff00cc66%s|r exported to clipboard.",
    PROFILE_IMPORTED         = "Profile |cff00cc66%s|r imported with %d frames.",
    PROFILE_IMPORT_ERROR     = "|cffff4444Error|r: Could not import profile. Invalid data.",
    PROFILE_NAME_REQUIRED    = "Please provide a profile name.",

    -- Lock
    FRAMES_LOCKED            = "All hidden frames are now |cffff4444locked|r.",
    FRAMES_UNLOCKED          = "All hidden frames are now |cff00ff00unlocked|r.",

    -- Reset
    RESET_CONFIRM            = "Are you sure you want to reset |cffff4444all|r HideAnything settings? Type |cff00cc66/hide reset confirm|r to confirm.",
    RESET_DONE               = "All settings have been |cffff4444reset|r to defaults.",

    -- Status
    STATUS_HEADER            = "|cff00cc66HideAnything|r Status:",
    STATUS_HIDDEN_COUNT      = "Hidden frames: |cffffffff%d|r",
    STATUS_LOCKED            = "Lock mode: |cffff4444LOCKED|r",
    STATUS_UNLOCKED          = "Lock mode: |cff00ff00UNLOCKED|r",
    STATUS_PROFILE           = "Active profile: |cffffffff%s|r",
    STATUS_MINIMAP           = "Minimap button: |cffffffff%s|r",
    STATUS_ON                = "|cff00ff00ON|r",
    STATUS_OFF               = "|cffff4444OFF|r",

    -- Errors
    ERROR_COMBAT             = "|cffff4444Error|r: Cannot modify UI elements during combat.",
    ERROR_UNKNOWN_CMD        = "|cffff4444Unknown command|r: |cffffffff%s|r. Type |cff00cc66/hide|r for help.",
    ERROR_FRAME_NIL          = "|cffff4444Error|r: Frame reference is nil.",
    ERROR_FRAME_PROTECTED    = "|cffff4444Error|r: Frame |cffffffff%s|r is protected and cannot be modified in combat.",
    ERROR_DB_CORRUPT         = "|cffff4444Error|r: Saved data appears corrupt. Resetting to defaults.",
    ERROR_HOOK_FAILED        = "|cffff4444Warning|r: Could not hook frame |cffffffff%s|r. It may reappear after reload.",
    ERROR_CVAR_FAILED        = "|cffff4444Error|r: Could not set CVar |cffffffff%s|r.",
    ERROR_EXPORT_FAILED      = "|cffff4444Error|r: Export failed.",
    ERROR_IMPORT_PARSE       = "|cffff4444Error|r: Import failed. Data format not recognized.",

    -- Minimap
    MINIMAP_SHOWN            = "Minimap button |cff00ff00shown|r.",
    MINIMAP_HIDDEN           = "Minimap button |cffff4444hidden|r.",
    MINIMAP_TOOLTIP_TITLE    = "|cff00cc66Hide|rAnything",
    MINIMAP_TOOLTIP_LEFT     = "|cff00cc66Left-Click|r: Toggle options",
    MINIMAP_TOOLTIP_RIGHT    = "|cff00cc66Right-Click|r: Frame Picker",
    MINIMAP_TOOLTIP_SHIFT    = "|cff8888ffShift-Click|r: Show all hidden frames",
    MINIMAP_TOOLTIP_DRAG     = "|cff888888Drag|r to move",

    -- Options Panel / UI
    UI_TITLE                 = "HideAnything Options",
    UI_FRAMES                = "Frames",
    UI_PROFILES              = "Profiles",
    UI_ABOUT                 = "About",

    UI_BTN_SHOW_ALL          = "Show All",
    UI_BTN_HIDE              = "Hide",
    UI_BTN_SHOW              = "Show",
    UI_BTN_SAVE_PROFILE      = "Save Profile",
    UI_BTN_LOAD_PROFILE      = "Load Profile",
    UI_BTN_DELETE_PROFILE    = "Delete Profile",
    UI_BTN_EXPORT            = "Export",
    UI_BTN_IMPORT            = "Import",
    UI_BTN_RESET             = "Reset All",
    UI_BTN_CLOSE             = "Close",

    UI_CONFIRM_RESET         = "Reset ALL settings?\nAll hidden frames will be shown and all profiles will be deleted.",
    UI_CONFIRM_YES           = "Yes, Reset",
    UI_CONFIRM_NO            = "Cancel",

    -- Config UI section headers
    CFG_HEADER_SETTINGS      = "Settings",
    CFG_HEADER_FRAMES        = "UI Frames",
    CFG_HEADER_CUSTOM        = "Custom Frame (by name)",
    CFG_HEADER_CUSTOM_HIDDEN = "Other Hidden Frames",

    CFG_TOGGLE_ON            = "|cff00ff00ON|r",
    CFG_TOGGLE_OFF           = "|cffff4444OFF|r",

    CFG_MINIMAP_BTN          = "Minimap Button",
    CFG_MINIMAP_BTN_TT       = "Show or hide the minimap button.",
    CFG_LOCK_MODE            = "Lock Mode",
    CFG_LOCK_MODE_TT         = "When locked, hidden frames cannot be restored. Only the config panel or /hide unlock can restore them.",
    CFG_HIGHLIGHT            = "Highlight Frames",
    CFG_HIGHLIGHT_TT         = "Highlight the actual game frame when hovering over a catalog row.",
    CFG_HIGHLIGHT_ENABLED    = "Frame Highlighting",
    CFG_HIGHLIGHT_ENABLED_TT = "Enable the eye button to highlight frames on screen. When disabled, the eye button is hidden.",
    CFG_CHAT_FEEDBACK        = "Chat Feedback",
    CFG_CHAT_FEEDBACK_TT     = "Show messages in chat when hiding or showing frames.",
    CFG_FADE_ANIM            = "Fade Animation",
    CFG_FADE_ANIM_TT         = "Smoothly fade frames in and out instead of hiding them instantly.",
    CFG_EDITION_LABEL        = "Edition",
    CFG_COMBAT_HIDE          = "Combat Auto-Hide",
    CFG_COMBAT_HIDE_TT       = "Automatically hide this frame when entering combat and show it again after.",

    -- Language (new)
    CFG_LANGUAGE             = "Language",
    CFG_LANGUAGE_TT          = "Select addon display language. Reopen the panel to apply.",

    -- About
    ABOUT_DESC               = "lets you hide any UI element with a simple toggle.",
    ABOUT_FEATURES           = "Features:",
    ABOUT_F1                 = "Toggle list of 120+ UI frames, CVars & textures",
    ABOUT_F2                 = "Hide any frame by name, hide chat completely",
    ABOUT_F3                 = "Opacity slider per frame",
    ABOUT_F4                 = "Profiles: save, load, delete, export/import",
    ABOUT_F5                 = "Search & filter, frame highlight on hover",
    ABOUT_F6                 = "Combat auto-hide: hide specific frames in fight",
    ABOUT_F7                 = "Edition support: Classic, TBC, MoP Classic, Retail",
    ABOUT_F8                 = "LibDataBroker plugin for bar addons",
    ABOUT_F9                 = "Combat protection & secure hooks",
    ABOUT_F10                = "Texture & decoration hiding",
    ABOUT_COMMANDS_LABEL     = "Commands:",
    ABOUT_CONFIG_LABEL       = "Config:",

    -- About stats (new)
    ABOUT_STATS_TITLE        = "Quick Stats",
    ABOUT_STATS_HIDDEN       = "Hidden: |cffffffff%d|r",
    ABOUT_STATS_PROFILES     = "Profiles: |cffffffff%d|r",
    ABOUT_STATS_CATALOG      = "Catalog: |cffffffff%d+|r",

    -- Undo / Redo
    UNDO_EMPTY               = "Nothing to undo.",
    REDO_EMPTY               = "Nothing to redo.",
    UNDO_SHOWN               = "Undo: shown |cff00ff00%s|r",
    UNDO_HIDDEN              = "Undo: hidden |cffff8800%s|r",
    REDO_SHOWN               = "Redo: shown |cff00ff00%s|r",
    REDO_HIDDEN              = "Redo: hidden |cffff8800%s|r",

    -- Frame Picker
    PICKER_ACTIVATED         = "|cff00c761Frame Picker|r activated. Click a frame to hide it.",
    PICKER_HOVER_HINT        = "Hover over a UI element...",
    PICKER_INSTRUCTIONS      = "|cff00c761Left-Click|r to hide  |  |cffff4444Right-Click|r or |cffff4444ESC|r to cancel",

    -- Presets
    PRESETS_HEADER           = "Presets",
    PRESET_APPLIED           = "Preset |cff00cc66%s|r applied.",
}

---------------------------------------------------------------------------
-- German (deDE)
---------------------------------------------------------------------------
HA.LOCALES["deDE"] = {
    -- General
    ADDON_LOADED             = "|cff00cc66Hide|rAnything|r v%s geladen. Tippe |cff00cc66/hide|r für Hilfe.",

    -- Slash command help
    HELP_HEADER              = "|cff00cc66HideAnything|r Befehle:",
    HELP_TOGGLE              = "|cff00cc66/hide toggle|r - Optionsfenster öffnen/schließen",
    HELP_SHOW_ALL            = "|cff00cc66/hide showall|r - Alle versteckten Frames anzeigen",
    HELP_HIDE                = "|cff00cc66/hide hide <frame>|r - Einen Frame nach Name verstecken",
    HELP_SHOW                = "|cff00cc66/hide show <frame>|r - Einen Frame nach Name anzeigen",
    HELP_LIST                = "|cff00cc66/hide list|r - Alle versteckten Frames auflisten",
    HELP_RESET               = "|cff00cc66/hide reset|r - Alle Einstellungen zurücksetzen",
    HELP_PROFILE             = "|cff00cc66/hide profile <name>|r - Profil laden",
    HELP_PROFILES            = "|cff00cc66/hide profiles|r - Alle gespeicherten Profile auflisten",
    HELP_LOCK                = "|cff00cc66/hide lock|r - Alle versteckten Frames sperren",
    HELP_UNLOCK              = "|cff00cc66/hide unlock|r - Alle versteckten Frames entsperren",
    HELP_STATUS              = "|cff00cc66/hide status|r - Addon-Status anzeigen",
    HELP_MINIMAP             = "|cff00cc66/hide minimap|r - Minimap-Button umschalten",
    HELP_ALPHA               = "|cff00cc66/hide alpha <frame> <0-100>|r - Frame-Deckkraft setzen",

    -- Hide / Show
    FRAME_HIDDEN             = "Versteckt: |cffff8800%s|r",
    FRAME_SHOWN              = "Angezeigt: |cff00ff00%s|r",
    FRAME_NOT_FOUND          = "Frame |cffff4444%s|r nicht gefunden.",
    FRAME_NOT_HIDDEN         = "Frame |cffffffff%s|r ist momentan nicht versteckt.",
    ALL_FRAMES_SHOWN         = "Alle |cff00ff00%d|r versteckten Frames sind jetzt wieder sichtbar.",
    NO_FRAMES_HIDDEN         = "Es sind keine Frames versteckt.",

    -- Alpha / Opacity
    ALPHA_SET                = "Deckkraft von |cff00cc66%s|r auf |cffffffff%d%%|r gesetzt.",
    ALPHA_RESET              = "Deckkraft von |cff00cc66%s|r auf 100%% zurückgesetzt.",
    ALPHA_TITLE              = "Deckkraft",
    ALPHA_LABEL              = "Deckkraft: %d%%",
    ALPHA_TOOLTIP            = "Frame-Transparenz einstellen (0%% = unsichtbar, 100%% = voll sichtbar)",

    -- Frame states (tooltips)
    FRAME_STATE_HIDDEN       = "Momentan versteckt",
    FRAME_STATE_VISIBLE      = "Momentan sichtbar",
    FRAME_STATE_ALPHA        = "Deckkraft: %d%%",
    FRAME_NOT_LOADED         = "Frame noch nicht geladen",

    -- Search
    SEARCH_PLACEHOLDER       = "Frames suchen...",

    -- Protected
    PICKER_PROTECTED         = "Kann |cffff4444%s|r nicht verstecken - dieser Frame ist geschützt.",
    PICKER_ALREADY_HIDDEN    = "|cffffffff%s|r ist bereits versteckt.",

    -- List
    LIST_HEADER              = "|cff00cc66Versteckte Frames|r (%d):",
    LIST_ENTRY               = "  |cffff8800%d.|r %s",

    -- Profiles
    PROFILE_SAVED            = "Profil |cff00cc66%s|r gespeichert mit %d versteckten Frames.",
    PROFILE_LOADED           = "Profil |cff00cc66%s|r geladen (%d Frames versteckt).",
    PROFILE_DELETED          = "Profil |cffff4444%s|r gelöscht.",
    PROFILE_NOT_FOUND        = "Profil |cffff4444%s|r nicht gefunden.",
    PROFILE_EXISTS           = "Profil |cffffffff%s|r existiert bereits. Nutze |cff00cc66/hide profile overwrite <name>|r zum Überschreiben.",
    PROFILE_LIST_HEADER      = "|cff00cc66Gespeicherte Profile|r (%d):",
    PROFILE_LIST_ENTRY       = "  |cffff8800%d.|r %s |cff888888(%d Frames)|r",
    PROFILE_NO_PROFILES      = "Keine gespeicherten Profile.",
    PROFILE_EXPORTED         = "Profil |cff00cc66%s|r in die Zwischenablage exportiert.",
    PROFILE_IMPORTED         = "Profil |cff00cc66%s|r importiert mit %d Frames.",
    PROFILE_IMPORT_ERROR     = "|cffff4444Fehler|r: Profil konnte nicht importiert werden. Ungültige Daten.",
    PROFILE_NAME_REQUIRED    = "Bitte gib einen Profilnamen an.",

    -- Lock
    FRAMES_LOCKED            = "Alle versteckten Frames sind jetzt |cffff4444gesperrt|r.",
    FRAMES_UNLOCKED          = "Alle versteckten Frames sind jetzt |cff00ff00entsperrt|r.",

    -- Reset
    RESET_CONFIRM            = "Bist du sicher, dass du |cffff4444alle|r Einstellungen zurücksetzen willst? Tippe |cff00cc66/hide reset confirm|r.",
    RESET_DONE               = "Alle Einstellungen wurden auf |cffff4444Standardwerte|r zurückgesetzt.",

    -- Status
    STATUS_HEADER            = "|cff00cc66HideAnything|r Status:",
    STATUS_HIDDEN_COUNT      = "Versteckte Frames: |cffffffff%d|r",
    STATUS_LOCKED            = "Sperrmodus: |cffff4444GESPERRT|r",
    STATUS_UNLOCKED          = "Sperrmodus: |cff00ff00ENTSPERRT|r",
    STATUS_PROFILE           = "Aktives Profil: |cffffffff%s|r",
    STATUS_MINIMAP           = "Minimap-Button: |cffffffff%s|r",
    STATUS_ON                = "|cff00ff00AN|r",
    STATUS_OFF               = "|cffff4444AUS|r",

    -- Errors
    ERROR_COMBAT             = "|cffff4444Fehler|r: UI-Elemente können im Kampf nicht verändert werden.",
    ERROR_UNKNOWN_CMD        = "|cffff4444Unbekannter Befehl|r: |cffffffff%s|r. Tippe |cff00cc66/hide|r für Hilfe.",
    ERROR_FRAME_NIL          = "|cffff4444Fehler|r: Frame-Referenz ist nil.",
    ERROR_FRAME_PROTECTED    = "|cffff4444Fehler|r: Frame |cffffffff%s|r ist geschützt und kann im Kampf nicht verändert werden.",
    ERROR_DB_CORRUPT         = "|cffff4444Fehler|r: Gespeicherte Daten scheinen beschädigt zu sein. Setze auf Standardwerte zurück.",
    ERROR_HOOK_FAILED        = "|cffff4444Warnung|r: Frame |cffffffff%s|r konnte nicht gehookt werden.",
    ERROR_CVAR_FAILED        = "|cffff4444Fehler|r: CVar |cffffffff%s|r konnte nicht gesetzt werden.",
    ERROR_EXPORT_FAILED      = "|cffff4444Fehler|r: Export fehlgeschlagen.",
    ERROR_IMPORT_PARSE       = "|cffff4444Fehler|r: Import fehlgeschlagen. Datenformat nicht erkannt.",

    -- Minimap
    MINIMAP_SHOWN            = "Minimap-Button |cff00ff00angezeigt|r.",
    MINIMAP_HIDDEN           = "Minimap-Button |cffff4444versteckt|r.",
    MINIMAP_TOOLTIP_TITLE    = "|cff00cc66Hide|rAnything",
    MINIMAP_TOOLTIP_LEFT     = "|cff00cc66Linksklick|r: Optionen umschalten",
    MINIMAP_TOOLTIP_SHIFT    = "|cff8888ffShift-Klick|r: Alle versteckten Frames anzeigen",
    MINIMAP_TOOLTIP_DRAG     = "|cff888888Ziehen|r zum Verschieben",

    -- Options Panel / UI
    UI_TITLE                 = "HideAnything Optionen",
    UI_FRAMES                = "Frames",
    UI_PROFILES              = "Profile",
    UI_ABOUT                 = "Info",

    UI_BTN_SHOW_ALL          = "Alle anzeigen",
    UI_BTN_HIDE              = "Verstecken",
    UI_BTN_SHOW              = "Anzeigen",
    UI_BTN_SAVE_PROFILE      = "Profil speichern",
    UI_BTN_LOAD_PROFILE      = "Profil laden",
    UI_BTN_DELETE_PROFILE    = "Profil löschen",
    UI_BTN_EXPORT            = "Exportieren",
    UI_BTN_IMPORT            = "Importieren",
    UI_BTN_RESET             = "Alles zurücksetzen",
    UI_BTN_CLOSE             = "Schließen",

    UI_CONFIRM_RESET         = "ALLE Einstellungen zurücksetzen?\nAlle versteckten Frames werden angezeigt und alle Profile gelöscht.",
    UI_CONFIRM_YES           = "Ja, zurücksetzen",
    UI_CONFIRM_NO            = "Abbrechen",

    -- Config UI section headers
    CFG_HEADER_SETTINGS      = "Einstellungen",
    CFG_HEADER_FRAMES        = "UI-Frames",
    CFG_HEADER_CUSTOM        = "Eigener Frame (per Name)",
    CFG_HEADER_CUSTOM_HIDDEN = "Andere versteckte Frames",

    CFG_TOGGLE_ON            = "|cff00ff00AN|r",
    CFG_TOGGLE_OFF           = "|cffff4444AUS|r",

    CFG_MINIMAP_BTN          = "Minimap-Button",
    CFG_MINIMAP_BTN_TT       = "Zeigt oder versteckt den Minimap-Button.",
    CFG_LOCK_MODE            = "Sperrmodus",
    CFG_LOCK_MODE_TT         = "Wenn gesperrt, können versteckte Frames nicht wiederhergestellt werden.",
    CFG_HIGHLIGHT            = "Frames hervorheben",
    CFG_HIGHLIGHT_TT         = "Hebt den tatsächlichen Frame hervor, wenn du mit der Maus über einen Katalogeintrag fährst.",
    CFG_HIGHLIGHT_ENABLED    = "Frame-Hervorhebung",
    CFG_HIGHLIGHT_ENABLED_TT = "Aktiviert den Augen-Button zum Hervorheben von Frames. Wenn deaktiviert, wird der Augen-Button ausgeblendet.",
    CFG_CHAT_FEEDBACK        = "Chat-Rückmeldung",
    CFG_CHAT_FEEDBACK_TT     = "Zeigt Nachrichten im Chat beim Verstecken oder Anzeigen von Frames.",
    CFG_FADE_ANIM            = "Ein-/Ausblenden",
    CFG_FADE_ANIM_TT         = "Frames sanft ein- und ausblenden statt sofort zu verstecken.",
    CFG_EDITION_LABEL        = "Edition",
    CFG_COMBAT_HIDE          = "Kampf-Auto-Verstecken",
    CFG_COMBAT_HIDE_TT       = "Diesen Frame automatisch im Kampf verstecken und danach wieder anzeigen.",

    -- Language (new)
    CFG_LANGUAGE             = "Sprache",
    CFG_LANGUAGE_TT          = "Addon-Anzeigesprache wählen. Panel erneut öffnen zum Anwenden.",

    -- About
    ABOUT_DESC               = "versteckt beliebige UI-Elemente per einfachem Toggle.",
    ABOUT_FEATURES           = "Funktionen:",
    ABOUT_F1                 = "Toggle-Liste mit 120+ UI-Frames, CVars & Texturen",
    ABOUT_F2                 = "Beliebigen Frame per Name verstecken, Chat komplett ausblenden",
    ABOUT_F3                 = "Deckkraft-Regler pro Frame",
    ABOUT_F4                 = "Profile: speichern, laden, löschen, Export/Import",
    ABOUT_F5                 = "Suche & Filter, Frame-Hervorhebung",
    ABOUT_F6                 = "Kampf-Auto-Verstecken: bestimmte Frames im Fight ausblenden",
    ABOUT_F7                 = "Editions-Support: Classic, TBC, MoP Classic, Retail",
    ABOUT_F8                 = "LibDataBroker-Plugin für Leistenaddons",
    ABOUT_F9                 = "Kampfschutz & sichere Hooks",
    ABOUT_F10                = "Texturen & Dekorationen verstecken",
    ABOUT_COMMANDS_LABEL     = "Befehle:",
    ABOUT_CONFIG_LABEL       = "Konfiguration:",

    -- About stats (new)
    ABOUT_STATS_TITLE        = "Statistiken",
    ABOUT_STATS_HIDDEN       = "Versteckt: |cffffffff%d|r",
    ABOUT_STATS_PROFILES     = "Profile: |cffffffff%d|r",
    ABOUT_STATS_CATALOG      = "Katalog: |cffffffff%d+|r",

    -- Undo / Redo
    UNDO_EMPTY               = "Nichts rückgängig zu machen.",
    REDO_EMPTY               = "Nichts wiederherzustellen.",
    UNDO_SHOWN               = "Rückgängig: |cff00ff00%s|r angezeigt",
    UNDO_HIDDEN              = "Rückgängig: |cffff8800%s|r versteckt",
    REDO_SHOWN               = "Wiederherstellen: |cff00ff00%s|r angezeigt",
    REDO_HIDDEN              = "Wiederherstellen: |cffff8800%s|r versteckt",

    -- Frame Picker
    PICKER_ACTIVATED         = "|cff00c761Frame-Picker|r aktiviert. Klicke einen Frame um ihn zu verstecken.",
    PICKER_HOVER_HINT        = "Fahre über ein UI-Element...",
    PICKER_INSTRUCTIONS      = "|cff00c761Linksklick|r zum Verstecken  |  |cffff4444Rechtsklick|r oder |cffff4444ESC|r zum Abbrechen",

    -- Presets
    PRESETS_HEADER           = "Vorlagen",
    PRESET_APPLIED           = "Vorlage |cff00cc66%s|r angewendet.",

    MINIMAP_TOOLTIP_RIGHT    = "|cff00cc66Rechtsklick|r: Frame-Picker",
    HELP_UNDO                = "|cff00cc66/hide undo|r - Letzte Aktion rückgängig machen (Strg+Z)",
    HELP_REDO                = "|cff00cc66/hide redo|r - Letzte Aktion wiederherstellen (Strg+Y)",
    HELP_PICKER              = "|cff00cc66/hide picker|r - Frame-Picker umschalten (Strg+P)",
    HELP_PRESET              = "|cff00cc66/hide preset <name>|r - Vorlage anwenden",
}

---------------------------------------------------------------------------
-- French (frFR)
---------------------------------------------------------------------------
HA.LOCALES["frFR"] = {
    -- General
    ADDON_LOADED             = "|cff00cc66Hide|rAnything|r v%s chargé. Tapez |cff00cc66/hide|r pour l'aide.",

    -- Slash command help
    HELP_HEADER              = "|cff00cc66HideAnything|r Commandes :",
    HELP_TOGGLE              = "|cff00cc66/hide toggle|r - Ouvrir/fermer le panneau d'options",
    HELP_SHOW_ALL            = "|cff00cc66/hide showall|r - Afficher tous les cadres masqués",
    HELP_HIDE                = "|cff00cc66/hide hide <cadre>|r - Masquer un cadre par nom",
    HELP_SHOW                = "|cff00cc66/hide show <cadre>|r - Afficher un cadre par nom",
    HELP_LIST                = "|cff00cc66/hide list|r - Lister les cadres masqués",
    HELP_RESET               = "|cff00cc66/hide reset|r - Réinitialiser tous les paramètres",
    HELP_PROFILE             = "|cff00cc66/hide profile <nom>|r - Charger un profil",
    HELP_PROFILES            = "|cff00cc66/hide profiles|r - Lister les profils sauvegardés",
    HELP_LOCK                = "|cff00cc66/hide lock|r - Verrouiller les cadres masqués",
    HELP_UNLOCK              = "|cff00cc66/hide unlock|r - Déverrouiller les cadres masqués",
    HELP_STATUS              = "|cff00cc66/hide status|r - Afficher le statut de l'addon",
    HELP_MINIMAP             = "|cff00cc66/hide minimap|r - Afficher/masquer le bouton minicarte",
    HELP_ALPHA               = "|cff00cc66/hide alpha <cadre> <0-100>|r - Définir l'opacité du cadre",

    -- Hide / Show
    FRAME_HIDDEN             = "Masqué : |cffff8800%s|r",
    FRAME_SHOWN              = "Affiché : |cff00ff00%s|r",
    FRAME_NOT_FOUND          = "Cadre |cffff4444%s|r introuvable.",
    FRAME_NOT_HIDDEN         = "Le cadre |cffffffff%s|r n'est pas masqué actuellement.",
    ALL_FRAMES_SHOWN         = "Les |cff00ff00%d|r cadres masqués sont de nouveau visibles.",
    NO_FRAMES_HIDDEN         = "Aucun cadre n'est masqué actuellement.",

    -- Alpha / Opacity
    ALPHA_SET                = "Opacité de |cff00cc66%s|r définie à |cffffffff%d%%|r.",
    ALPHA_RESET              = "Opacité de |cff00cc66%s|r réinitialisée à 100%%.",
    ALPHA_TITLE              = "Opacité",
    ALPHA_LABEL              = "Opacité : %d%%",
    ALPHA_TOOLTIP            = "Définir la transparence du cadre (0%% = invisible, 100%% = entièrement visible)",

    -- Frame states (tooltips)
    FRAME_STATE_HIDDEN       = "Actuellement masqué",
    FRAME_STATE_VISIBLE      = "Actuellement visible",
    FRAME_STATE_ALPHA        = "Opacité : %d%%",
    FRAME_NOT_LOADED         = "Cadre pas encore chargé",

    -- Search
    SEARCH_PLACEHOLDER       = "Rechercher des cadres...",

    -- Protected
    PICKER_PROTECTED         = "Impossible de masquer |cffff4444%s|r - ce cadre est protégé.",
    PICKER_ALREADY_HIDDEN    = "|cffffffff%s|r est déjà masqué.",

    -- List
    LIST_HEADER              = "|cff00cc66Cadres masqués|r (%d) :",
    LIST_ENTRY               = "  |cffff8800%d.|r %s",

    -- Profiles
    PROFILE_SAVED            = "Profil |cff00cc66%s|r sauvegardé avec %d cadres masqués.",
    PROFILE_LOADED           = "Profil |cff00cc66%s|r chargé (%d cadres masqués).",
    PROFILE_DELETED          = "Profil |cffff4444%s|r supprimé.",
    PROFILE_NOT_FOUND        = "Profil |cffff4444%s|r introuvable.",
    PROFILE_EXISTS           = "Le profil |cffffffff%s|r existe déjà. Utilisez |cff00cc66/hide profile overwrite <nom>|r pour écraser.",
    PROFILE_LIST_HEADER      = "|cff00cc66Profils sauvegardés|r (%d) :",
    PROFILE_LIST_ENTRY       = "  |cffff8800%d.|r %s |cff888888(%d cadres)|r",
    PROFILE_NO_PROFILES      = "Aucun profil sauvegardé.",
    PROFILE_EXPORTED         = "Profil |cff00cc66%s|r exporté dans le presse-papiers.",
    PROFILE_IMPORTED         = "Profil |cff00cc66%s|r importé avec %d cadres.",
    PROFILE_IMPORT_ERROR     = "|cffff4444Erreur|r : Impossible d'importer le profil. Données invalides.",
    PROFILE_NAME_REQUIRED    = "Veuillez fournir un nom de profil.",

    -- Lock
    FRAMES_LOCKED            = "Tous les cadres masqués sont maintenant |cffff4444verrouillés|r.",
    FRAMES_UNLOCKED          = "Tous les cadres masqués sont maintenant |cff00ff00déverrouillés|r.",

    -- Reset
    RESET_CONFIRM            = "Êtes-vous sûr de vouloir réinitialiser |cffff4444tous|r les paramètres ? Tapez |cff00cc66/hide reset confirm|r pour confirmer.",
    RESET_DONE               = "Tous les paramètres ont été |cffff4444réinitialisés|r par défaut.",

    -- Status
    STATUS_HEADER            = "|cff00cc66HideAnything|r Statut :",
    STATUS_HIDDEN_COUNT      = "Cadres masqués : |cffffffff%d|r",
    STATUS_LOCKED            = "Mode verrouillage : |cffff4444VERROUILLÉ|r",
    STATUS_UNLOCKED          = "Mode verrouillage : |cff00ff00DÉVERROUILLÉ|r",
    STATUS_PROFILE           = "Profil actif : |cffffffff%s|r",
    STATUS_MINIMAP           = "Bouton minicarte : |cffffffff%s|r",
    STATUS_ON                = "|cff00ff00ACTIVÉ|r",
    STATUS_OFF               = "|cffff4444DÉSACTIVÉ|r",

    -- Errors
    ERROR_COMBAT             = "|cffff4444Erreur|r : Impossible de modifier l'interface pendant le combat.",
    ERROR_UNKNOWN_CMD        = "|cffff4444Commande inconnue|r : |cffffffff%s|r. Tapez |cff00cc66/hide|r pour l'aide.",
    ERROR_FRAME_NIL          = "|cffff4444Erreur|r : La référence du cadre est nil.",
    ERROR_FRAME_PROTECTED    = "|cffff4444Erreur|r : Le cadre |cffffffff%s|r est protégé et ne peut pas être modifié en combat.",
    ERROR_DB_CORRUPT         = "|cffff4444Erreur|r : Les données sauvegardées semblent corrompues. Réinitialisation par défaut.",
    ERROR_HOOK_FAILED        = "|cffff4444Attention|r : Impossible de hooker le cadre |cffffffff%s|r. Il peut réapparaître après rechargement.",
    ERROR_CVAR_FAILED        = "|cffff4444Erreur|r : Impossible de définir le CVar |cffffffff%s|r.",
    ERROR_EXPORT_FAILED      = "|cffff4444Erreur|r : L'export a échoué.",
    ERROR_IMPORT_PARSE       = "|cffff4444Erreur|r : L'import a échoué. Format de données non reconnu.",

    -- Minimap
    MINIMAP_SHOWN            = "Bouton minicarte |cff00ff00affiché|r.",
    MINIMAP_HIDDEN           = "Bouton minicarte |cffff4444masqué|r.",
    MINIMAP_TOOLTIP_TITLE    = "|cff00cc66Hide|rAnything",
    MINIMAP_TOOLTIP_LEFT     = "|cff00cc66Clic gauche|r : Ouvrir les options",
    MINIMAP_TOOLTIP_SHIFT    = "|cff8888ffShift-Clic|r : Afficher tous les cadres masqués",
    MINIMAP_TOOLTIP_DRAG     = "|cff888888Glisser|r pour déplacer",

    -- Options Panel / UI
    UI_TITLE                 = "HideAnything Options",
    UI_FRAMES                = "Cadres",
    UI_PROFILES              = "Profils",
    UI_ABOUT                 = "À propos",

    UI_BTN_SHOW_ALL          = "Tout afficher",
    UI_BTN_HIDE              = "Masquer",
    UI_BTN_SHOW              = "Afficher",
    UI_BTN_SAVE_PROFILE      = "Sauvegarder le profil",
    UI_BTN_LOAD_PROFILE      = "Charger le profil",
    UI_BTN_DELETE_PROFILE    = "Supprimer le profil",
    UI_BTN_EXPORT            = "Exporter",
    UI_BTN_IMPORT            = "Importer",
    UI_BTN_RESET             = "Tout réinitialiser",
    UI_BTN_CLOSE             = "Fermer",

    UI_CONFIRM_RESET         = "Réinitialiser TOUS les paramètres ?\nTous les cadres masqués seront affichés et tous les profils supprimés.",
    UI_CONFIRM_YES           = "Oui, réinitialiser",
    UI_CONFIRM_NO            = "Annuler",

    -- Config UI section headers
    CFG_HEADER_SETTINGS      = "Paramètres",
    CFG_HEADER_FRAMES        = "Cadres d'interface",
    CFG_HEADER_CUSTOM        = "Cadre personnalisé (par nom)",
    CFG_HEADER_CUSTOM_HIDDEN = "Autres cadres masqués",

    CFG_TOGGLE_ON            = "|cff00ff00ACTIVÉ|r",
    CFG_TOGGLE_OFF           = "|cffff4444DÉSACTIVÉ|r",

    CFG_MINIMAP_BTN          = "Bouton minicarte",
    CFG_MINIMAP_BTN_TT       = "Afficher ou masquer le bouton minicarte.",
    CFG_LOCK_MODE            = "Mode verrouillage",
    CFG_LOCK_MODE_TT         = "Quand verrouillé, les cadres masqués ne peuvent pas être restaurés.",
    CFG_HIGHLIGHT            = "Surbrillance des cadres",
    CFG_HIGHLIGHT_TT         = "Surligner le cadre de jeu au survol d'une ligne du catalogue.",
    CFG_HIGHLIGHT_ENABLED    = "Surbrillance des cadres",
    CFG_HIGHLIGHT_ENABLED_TT = "Activer le bouton œil pour surligner les cadres à l'écran. Si désactivé, le bouton œil est masqué.",
    CFG_CHAT_FEEDBACK        = "Messages dans le chat",
    CFG_CHAT_FEEDBACK_TT     = "Afficher des messages dans le chat lors du masquage ou de l'affichage des cadres.",
    CFG_FADE_ANIM            = "Animation de fondu",
    CFG_FADE_ANIM_TT         = "Faire apparaître et disparaître les cadres en fondu au lieu de les masquer instantanément.",
    CFG_EDITION_LABEL        = "Édition",
    CFG_COMBAT_HIDE          = "Masquage auto en combat",
    CFG_COMBAT_HIDE_TT       = "Masquer automatiquement ce cadre en combat et le réafficher après.",

    -- Language (new)
    CFG_LANGUAGE             = "Langue",
    CFG_LANGUAGE_TT          = "Sélectionner la langue d'affichage. Réouvrir le panneau pour appliquer.",

    -- About
    ABOUT_DESC               = "permet de masquer n'importe quel élément d'interface d'un simple clic.",
    ABOUT_FEATURES           = "Fonctionnalités :",
    ABOUT_F1                 = "Liste de plus de 120 cadres, CVars & textures",
    ABOUT_F2                 = "Masquer n'importe quel cadre par nom, masquer le chat",
    ABOUT_F3                 = "Curseur d'opacité par cadre",
    ABOUT_F4                 = "Profils : sauvegarder, charger, supprimer, exporter/importer",
    ABOUT_F5                 = "Recherche & filtre, surbrillance au survol",
    ABOUT_F6                 = "Masquage auto en combat : masquer certains cadres en combat",
    ABOUT_F7                 = "Support des éditions : Classic, TBC, MoP Classic, Retail",
    ABOUT_F8                 = "Plugin LibDataBroker pour les barres d'addons",
    ABOUT_F9                 = "Protection de combat & hooks sécurisés",
    ABOUT_F10                = "Masquage des textures & décorations",
    ABOUT_COMMANDS_LABEL     = "Commandes :",
    ABOUT_CONFIG_LABEL       = "Configuration :",

    -- About stats (new)
    ABOUT_STATS_TITLE        = "Statistiques",
    ABOUT_STATS_HIDDEN       = "Masqués : |cffffffff%d|r",
    ABOUT_STATS_PROFILES     = "Profils : |cffffffff%d|r",
    ABOUT_STATS_CATALOG      = "Catalogue : |cffffffff%d+|r",

    UNDO_EMPTY               = "Rien à annuler.",
    REDO_EMPTY               = "Rien à rétablir.",
    UNDO_SHOWN               = "Annulé : |cff00ff00%s|r affiché",
    UNDO_HIDDEN              = "Annulé : |cffff8800%s|r masqué",
    REDO_SHOWN               = "Rétabli : |cff00ff00%s|r affiché",
    REDO_HIDDEN              = "Rétabli : |cffff8800%s|r masqué",
    PICKER_ACTIVATED         = "|cff00c761Sélecteur|r activé. Cliquez sur un cadre pour le masquer.",
    PICKER_HOVER_HINT        = "Survolez un élément d'interface...",
    PICKER_INSTRUCTIONS      = "|cff00c761Clic gauche|r masquer  |  |cffff4444Clic droit|r ou |cffff4444ÉCHAP|r annuler",
    PRESETS_HEADER           = "Préréglages",
    PRESET_APPLIED           = "Préréglage |cff00cc66%s|r appliqué.",
    MINIMAP_TOOLTIP_RIGHT    = "|cff00cc66Clic droit|r : Sélecteur de cadre",
}

---------------------------------------------------------------------------
-- Spanish (esES / esMX)
---------------------------------------------------------------------------
HA.LOCALES["esES"] = {
    -- General
    ADDON_LOADED             = "|cff00cc66Hide|rAnything|r v%s cargado. Escribe |cff00cc66/hide|r para ayuda.",

    -- Slash command help
    HELP_HEADER              = "|cff00cc66HideAnything|r Comandos:",
    HELP_TOGGLE              = "|cff00cc66/hide toggle|r - Abrir/cerrar el panel de opciones",
    HELP_SHOW_ALL            = "|cff00cc66/hide showall|r - Mostrar todos los marcos ocultos",
    HELP_HIDE                = "|cff00cc66/hide hide <marco>|r - Ocultar un marco por nombre",
    HELP_SHOW                = "|cff00cc66/hide show <marco>|r - Mostrar un marco por nombre",
    HELP_LIST                = "|cff00cc66/hide list|r - Listar marcos ocultos",
    HELP_RESET               = "|cff00cc66/hide reset|r - Restablecer todos los ajustes",
    HELP_PROFILE             = "|cff00cc66/hide profile <nombre>|r - Cargar un perfil",
    HELP_PROFILES            = "|cff00cc66/hide profiles|r - Listar perfiles guardados",
    HELP_LOCK                = "|cff00cc66/hide lock|r - Bloquear marcos ocultos",
    HELP_UNLOCK              = "|cff00cc66/hide unlock|r - Desbloquear marcos ocultos",
    HELP_STATUS              = "|cff00cc66/hide status|r - Mostrar estado del addon",
    HELP_MINIMAP             = "|cff00cc66/hide minimap|r - Mostrar/ocultar botón del minimapa",
    HELP_ALPHA               = "|cff00cc66/hide alpha <marco> <0-100>|r - Establecer opacidad del marco",

    -- Hide / Show
    FRAME_HIDDEN             = "Oculto: |cffff8800%s|r",
    FRAME_SHOWN              = "Mostrado: |cff00ff00%s|r",
    FRAME_NOT_FOUND          = "Marco |cffff4444%s|r no encontrado.",
    FRAME_NOT_HIDDEN         = "El marco |cffffffff%s|r no está oculto actualmente.",
    ALL_FRAMES_SHOWN         = "Los |cff00ff00%d|r marcos ocultos son visibles de nuevo.",
    NO_FRAMES_HIDDEN         = "No hay marcos ocultos actualmente.",

    -- Alpha / Opacity
    ALPHA_SET                = "Opacidad de |cff00cc66%s|r establecida a |cffffffff%d%%|r.",
    ALPHA_RESET              = "Opacidad de |cff00cc66%s|r restablecida a 100%%.",
    ALPHA_TITLE              = "Opacidad",
    ALPHA_LABEL              = "Opacidad: %d%%",
    ALPHA_TOOLTIP            = "Establecer transparencia del marco (0%% = invisible, 100%% = totalmente visible)",

    -- Frame states (tooltips)
    FRAME_STATE_HIDDEN       = "Actualmente oculto",
    FRAME_STATE_VISIBLE      = "Actualmente visible",
    FRAME_STATE_ALPHA        = "Opacidad: %d%%",
    FRAME_NOT_LOADED         = "Marco aún no cargado",

    -- Search
    SEARCH_PLACEHOLDER       = "Buscar marcos...",

    -- Protected
    PICKER_PROTECTED         = "No se puede ocultar |cffff4444%s|r - este marco está protegido.",
    PICKER_ALREADY_HIDDEN    = "|cffffffff%s|r ya está oculto.",

    -- List
    LIST_HEADER              = "|cff00cc66Marcos ocultos|r (%d):",
    LIST_ENTRY               = "  |cffff8800%d.|r %s",

    -- Profiles
    PROFILE_SAVED            = "Perfil |cff00cc66%s|r guardado con %d marcos ocultos.",
    PROFILE_LOADED           = "Perfil |cff00cc66%s|r cargado (%d marcos ocultos).",
    PROFILE_DELETED          = "Perfil |cffff4444%s|r eliminado.",
    PROFILE_NOT_FOUND        = "Perfil |cffff4444%s|r no encontrado.",
    PROFILE_EXISTS           = "El perfil |cffffffff%s|r ya existe. Usa |cff00cc66/hide profile overwrite <nombre>|r para sobrescribir.",
    PROFILE_LIST_HEADER      = "|cff00cc66Perfiles guardados|r (%d):",
    PROFILE_LIST_ENTRY       = "  |cffff8800%d.|r %s |cff888888(%d marcos)|r",
    PROFILE_NO_PROFILES      = "No hay perfiles guardados.",
    PROFILE_EXPORTED         = "Perfil |cff00cc66%s|r exportado al portapapeles.",
    PROFILE_IMPORTED         = "Perfil |cff00cc66%s|r importado con %d marcos.",
    PROFILE_IMPORT_ERROR     = "|cffff4444Error|r: No se pudo importar el perfil. Datos inválidos.",
    PROFILE_NAME_REQUIRED    = "Por favor, proporciona un nombre de perfil.",

    -- Lock
    FRAMES_LOCKED            = "Todos los marcos ocultos están ahora |cffff4444bloqueados|r.",
    FRAMES_UNLOCKED          = "Todos los marcos ocultos están ahora |cff00ff00desbloqueados|r.",

    -- Reset
    RESET_CONFIRM            = "¿Estás seguro de querer restablecer |cffff4444todos|r los ajustes? Escribe |cff00cc66/hide reset confirm|r para confirmar.",
    RESET_DONE               = "Todos los ajustes han sido |cffff4444restablecidos|r a los valores predeterminados.",

    -- Status
    STATUS_HEADER            = "|cff00cc66HideAnything|r Estado:",
    STATUS_HIDDEN_COUNT      = "Marcos ocultos: |cffffffff%d|r",
    STATUS_LOCKED            = "Modo bloqueo: |cffff4444BLOQUEADO|r",
    STATUS_UNLOCKED          = "Modo bloqueo: |cff00ff00DESBLOQUEADO|r",
    STATUS_PROFILE           = "Perfil activo: |cffffffff%s|r",
    STATUS_MINIMAP           = "Botón del minimapa: |cffffffff%s|r",
    STATUS_ON                = "|cff00ff00ACTIVADO|r",
    STATUS_OFF               = "|cffff4444DESACTIVADO|r",

    -- Errors
    ERROR_COMBAT             = "|cffff4444Error|r: No se pueden modificar elementos de interfaz durante el combate.",
    ERROR_UNKNOWN_CMD        = "|cffff4444Comando desconocido|r: |cffffffff%s|r. Escribe |cff00cc66/hide|r para ayuda.",
    ERROR_FRAME_NIL          = "|cffff4444Error|r: La referencia del marco es nil.",
    ERROR_FRAME_PROTECTED    = "|cffff4444Error|r: El marco |cffffffff%s|r está protegido y no puede modificarse en combate.",
    ERROR_DB_CORRUPT         = "|cffff4444Error|r: Los datos guardados parecen corruptos. Restableciendo valores predeterminados.",
    ERROR_HOOK_FAILED        = "|cffff4444Advertencia|r: No se pudo hookar el marco |cffffffff%s|r. Puede reaparecer tras recargar.",
    ERROR_CVAR_FAILED        = "|cffff4444Error|r: No se pudo establecer el CVar |cffffffff%s|r.",
    ERROR_EXPORT_FAILED      = "|cffff4444Error|r: La exportación falló.",
    ERROR_IMPORT_PARSE       = "|cffff4444Error|r: La importación falló. Formato de datos no reconocido.",

    -- Minimap
    MINIMAP_SHOWN            = "Botón del minimapa |cff00ff00mostrado|r.",
    MINIMAP_HIDDEN           = "Botón del minimapa |cffff4444oculto|r.",
    MINIMAP_TOOLTIP_TITLE    = "|cff00cc66Hide|rAnything",
    MINIMAP_TOOLTIP_LEFT     = "|cff00cc66Clic izquierdo|r: Abrir opciones",
    MINIMAP_TOOLTIP_SHIFT    = "|cff8888ffShift-Clic|r: Mostrar todos los marcos ocultos",
    MINIMAP_TOOLTIP_DRAG     = "|cff888888Arrastrar|r para mover",

    -- Options Panel / UI
    UI_TITLE                 = "HideAnything Opciones",
    UI_FRAMES                = "Marcos",
    UI_PROFILES              = "Perfiles",
    UI_ABOUT                 = "Acerca de",

    UI_BTN_SHOW_ALL          = "Mostrar todo",
    UI_BTN_HIDE              = "Ocultar",
    UI_BTN_SHOW              = "Mostrar",
    UI_BTN_SAVE_PROFILE      = "Guardar perfil",
    UI_BTN_LOAD_PROFILE      = "Cargar perfil",
    UI_BTN_DELETE_PROFILE    = "Eliminar perfil",
    UI_BTN_EXPORT            = "Exportar",
    UI_BTN_IMPORT            = "Importar",
    UI_BTN_RESET             = "Restablecer todo",
    UI_BTN_CLOSE             = "Cerrar",

    UI_CONFIRM_RESET         = "¿Restablecer TODOS los ajustes?\nTodos los marcos ocultos se mostrarán y todos los perfiles se eliminarán.",
    UI_CONFIRM_YES           = "Sí, restablecer",
    UI_CONFIRM_NO            = "Cancelar",

    -- Config UI section headers
    CFG_HEADER_SETTINGS      = "Ajustes",
    CFG_HEADER_FRAMES        = "Marcos de interfaz",
    CFG_HEADER_CUSTOM        = "Marco personalizado (por nombre)",
    CFG_HEADER_CUSTOM_HIDDEN = "Otros marcos ocultos",

    CFG_TOGGLE_ON            = "|cff00ff00ACTIVADO|r",
    CFG_TOGGLE_OFF           = "|cffff4444DESACTIVADO|r",

    CFG_MINIMAP_BTN          = "Botón del minimapa",
    CFG_MINIMAP_BTN_TT       = "Mostrar u ocultar el botón del minimapa.",
    CFG_LOCK_MODE            = "Modo bloqueo",
    CFG_LOCK_MODE_TT         = "Cuando está bloqueado, los marcos ocultos no se pueden restaurar.",
    CFG_HIGHLIGHT            = "Resaltar marcos",
    CFG_HIGHLIGHT_TT         = "Resaltar el marco del juego al pasar el ratón por una fila del catálogo.",
    CFG_HIGHLIGHT_ENABLED    = "Resaltado de marcos",
    CFG_HIGHLIGHT_ENABLED_TT = "Activar el botón de ojo para resaltar marcos en pantalla. Si está desactivado, el botón de ojo se oculta.",
    CFG_CHAT_FEEDBACK        = "Mensajes en el chat",
    CFG_CHAT_FEEDBACK_TT     = "Mostrar mensajes en el chat al ocultar o mostrar marcos.",
    CFG_FADE_ANIM            = "Animación de fundido",
    CFG_FADE_ANIM_TT         = "Desvanecer los marcos suavemente en lugar de ocultarlos al instante.",
    CFG_EDITION_LABEL        = "Edición",
    CFG_COMBAT_HIDE          = "Auto-ocultar en combate",
    CFG_COMBAT_HIDE_TT       = "Ocultar automáticamente este marco al entrar en combate y mostrarlo después.",

    -- Language (new)
    CFG_LANGUAGE             = "Idioma",
    CFG_LANGUAGE_TT          = "Seleccionar idioma del addon. Reabrir el panel para aplicar.",

    -- About
    ABOUT_DESC               = "permite ocultar cualquier elemento de interfaz con un simple clic.",
    ABOUT_FEATURES           = "Características:",
    ABOUT_F1                 = "Lista de más de 120 marcos, CVars y texturas",
    ABOUT_F2                 = "Ocultar cualquier marco por nombre, ocultar el chat",
    ABOUT_F3                 = "Control de opacidad por marco",
    ABOUT_F4                 = "Perfiles: guardar, cargar, eliminar, exportar/importar",
    ABOUT_F5                 = "Búsqueda y filtro, resaltado de marcos al pasar el ratón",
    ABOUT_F6                 = "Auto-ocultar en combate: ocultar marcos durante el combate",
    ABOUT_F7                 = "Soporte de ediciones: Classic, TBC, MoP Classic, Retail",
    ABOUT_F8                 = "Plugin LibDataBroker para barras de addons",
    ABOUT_F9                 = "Protección de combate y hooks seguros",
    ABOUT_F10                = "Ocultación de texturas y decoraciones",
    ABOUT_COMMANDS_LABEL     = "Comandos:",
    ABOUT_CONFIG_LABEL       = "Configuración:",

    -- About stats (new)
    ABOUT_STATS_TITLE        = "Estadísticas",
    ABOUT_STATS_HIDDEN       = "Ocultos: |cffffffff%d|r",
    ABOUT_STATS_PROFILES     = "Perfiles: |cffffffff%d|r",
    ABOUT_STATS_CATALOG      = "Catálogo: |cffffffff%d+|r",

    UNDO_EMPTY               = "Nada que deshacer.",
    REDO_EMPTY               = "Nada que rehacer.",
    UNDO_SHOWN               = "Deshacer: |cff00ff00%s|r mostrado",
    UNDO_HIDDEN              = "Deshacer: |cffff8800%s|r oculto",
    REDO_SHOWN               = "Rehacer: |cff00ff00%s|r mostrado",
    REDO_HIDDEN              = "Rehacer: |cffff8800%s|r oculto",
    PICKER_ACTIVATED         = "|cff00c761Selector|r activado. Haz clic en un marco para ocultarlo.",
    PICKER_HOVER_HINT        = "Pasa sobre un elemento de interfaz...",
    PICKER_INSTRUCTIONS      = "|cff00c761Clic izquierdo|r ocultar  |  |cffff4444Clic derecho|r o |cffff4444ESC|r cancelar",
    PRESETS_HEADER           = "Preajustes",
    PRESET_APPLIED           = "Preajuste |cff00cc66%s|r aplicado.",
    MINIMAP_TOOLTIP_RIGHT    = "|cff00cc66Clic derecho|r: Selector de marco",
}

---------------------------------------------------------------------------
-- Russian (ruRU)
---------------------------------------------------------------------------
HA.LOCALES["ruRU"] = {
    -- General
    ADDON_LOADED             = "|cff00cc66Hide|rAnything|r v%s загружен. Введите |cff00cc66/hide|r для справки.",

    -- Slash command help
    HELP_HEADER              = "|cff00cc66HideAnything|r Команды:",
    HELP_TOGGLE              = "|cff00cc66/hide toggle|r - Открыть/закрыть панель настроек",
    HELP_SHOW_ALL            = "|cff00cc66/hide showall|r - Показать все скрытые фреймы",
    HELP_HIDE                = "|cff00cc66/hide hide <фрейм>|r - Скрыть фрейм по имени",
    HELP_SHOW                = "|cff00cc66/hide show <фрейм>|r - Показать фрейм по имени",
    HELP_LIST                = "|cff00cc66/hide list|r - Список скрытых фреймов",
    HELP_RESET               = "|cff00cc66/hide reset|r - Сбросить все настройки",
    HELP_PROFILE             = "|cff00cc66/hide profile <имя>|r - Загрузить профиль",
    HELP_PROFILES            = "|cff00cc66/hide profiles|r - Список сохранённых профилей",
    HELP_LOCK                = "|cff00cc66/hide lock|r - Заблокировать скрытые фреймы",
    HELP_UNLOCK              = "|cff00cc66/hide unlock|r - Разблокировать скрытые фреймы",
    HELP_STATUS              = "|cff00cc66/hide status|r - Показать статус аддона",
    HELP_MINIMAP             = "|cff00cc66/hide minimap|r - Переключить кнопку миникарты",
    HELP_ALPHA               = "|cff00cc66/hide alpha <фрейм> <0-100>|r - Установить прозрачность фрейма",

    -- Hide / Show
    FRAME_HIDDEN             = "Скрыт: |cffff8800%s|r",
    FRAME_SHOWN              = "Показан: |cff00ff00%s|r",
    FRAME_NOT_FOUND          = "Фрейм |cffff4444%s|r не найден.",
    FRAME_NOT_HIDDEN         = "Фрейм |cffffffff%s|r сейчас не скрыт.",
    ALL_FRAMES_SHOWN         = "Все |cff00ff00%d|r скрытых фреймов снова видимы.",
    NO_FRAMES_HIDDEN         = "Нет скрытых фреймов.",

    -- Alpha / Opacity
    ALPHA_SET                = "Прозрачность |cff00cc66%s|r установлена на |cffffffff%d%%|r.",
    ALPHA_RESET              = "Прозрачность |cff00cc66%s|r сброшена до 100%%.",
    ALPHA_TITLE              = "Прозрачность",
    ALPHA_LABEL              = "Прозрачность: %d%%",
    ALPHA_TOOLTIP            = "Установить прозрачность фрейма (0%% = невидимый, 100%% = полностью видимый)",

    -- Frame states (tooltips)
    FRAME_STATE_HIDDEN       = "Сейчас скрыт",
    FRAME_STATE_VISIBLE      = "Сейчас виден",
    FRAME_STATE_ALPHA        = "Прозрачность: %d%%",
    FRAME_NOT_LOADED         = "Фрейм ещё не загружен",

    -- Search
    SEARCH_PLACEHOLDER       = "Поиск фреймов...",

    -- Protected
    PICKER_PROTECTED         = "Невозможно скрыть |cffff4444%s|r - этот фрейм защищён.",
    PICKER_ALREADY_HIDDEN    = "|cffffffff%s|r уже скрыт.",

    -- List
    LIST_HEADER              = "|cff00cc66Скрытые фреймы|r (%d):",
    LIST_ENTRY               = "  |cffff8800%d.|r %s",

    -- Profiles
    PROFILE_SAVED            = "Профиль |cff00cc66%s|r сохранён (%d скрытых фреймов).",
    PROFILE_LOADED           = "Профиль |cff00cc66%s|r загружен (%d фреймов скрыто).",
    PROFILE_DELETED          = "Профиль |cffff4444%s|r удалён.",
    PROFILE_NOT_FOUND        = "Профиль |cffff4444%s|r не найден.",
    PROFILE_EXISTS           = "Профиль |cffffffff%s|r уже существует. Используйте |cff00cc66/hide profile overwrite <имя>|r для перезаписи.",
    PROFILE_LIST_HEADER      = "|cff00cc66Сохранённые профили|r (%d):",
    PROFILE_LIST_ENTRY       = "  |cffff8800%d.|r %s |cff888888(%d фреймов)|r",
    PROFILE_NO_PROFILES      = "Нет сохранённых профилей.",
    PROFILE_EXPORTED         = "Профиль |cff00cc66%s|r экспортирован в буфер обмена.",
    PROFILE_IMPORTED         = "Профиль |cff00cc66%s|r импортирован (%d фреймов).",
    PROFILE_IMPORT_ERROR     = "|cffff4444Ошибка|r: Не удалось импортировать профиль. Неверные данные.",
    PROFILE_NAME_REQUIRED    = "Пожалуйста, укажите имя профиля.",

    -- Lock
    FRAMES_LOCKED            = "Все скрытые фреймы теперь |cffff4444заблокированы|r.",
    FRAMES_UNLOCKED          = "Все скрытые фреймы теперь |cff00ff00разблокированы|r.",

    -- Reset
    RESET_CONFIRM            = "Вы уверены, что хотите сбросить |cffff4444все|r настройки? Введите |cff00cc66/hide reset confirm|r для подтверждения.",
    RESET_DONE               = "Все настройки были |cffff4444сброшены|r к значениям по умолчанию.",

    -- Status
    STATUS_HEADER            = "|cff00cc66HideAnything|r Статус:",
    STATUS_HIDDEN_COUNT      = "Скрытых фреймов: |cffffffff%d|r",
    STATUS_LOCKED            = "Режим блокировки: |cffff4444ЗАБЛОКИРОВАН|r",
    STATUS_UNLOCKED          = "Режим блокировки: |cff00ff00РАЗБЛОКИРОВАН|r",
    STATUS_PROFILE           = "Активный профиль: |cffffffff%s|r",
    STATUS_MINIMAP           = "Кнопка миникарты: |cffffffff%s|r",
    STATUS_ON                = "|cff00ff00ВКЛ|r",
    STATUS_OFF               = "|cffff4444ВЫКЛ|r",

    -- Errors
    ERROR_COMBAT             = "|cffff4444Ошибка|r: Невозможно изменить элементы интерфейса во время боя.",
    ERROR_UNKNOWN_CMD        = "|cffff4444Неизвестная команда|r: |cffffffff%s|r. Введите |cff00cc66/hide|r для справки.",
    ERROR_FRAME_NIL          = "|cffff4444Ошибка|r: Ссылка на фрейм равна nil.",
    ERROR_FRAME_PROTECTED    = "|cffff4444Ошибка|r: Фрейм |cffffffff%s|r защищён и не может быть изменён в бою.",
    ERROR_DB_CORRUPT         = "|cffff4444Ошибка|r: Сохранённые данные повреждены. Сброс к значениям по умолчанию.",
    ERROR_HOOK_FAILED        = "|cffff4444Предупреждение|r: Не удалось перехватить фрейм |cffffffff%s|r. Он может появиться после перезагрузки.",
    ERROR_CVAR_FAILED        = "|cffff4444Ошибка|r: Не удалось установить CVar |cffffffff%s|r.",
    ERROR_EXPORT_FAILED      = "|cffff4444Ошибка|r: Экспорт не удался.",
    ERROR_IMPORT_PARSE       = "|cffff4444Ошибка|r: Импорт не удался. Формат данных не распознан.",

    -- Minimap
    MINIMAP_SHOWN            = "Кнопка миникарты |cff00ff00показана|r.",
    MINIMAP_HIDDEN           = "Кнопка миникарты |cffff4444скрыта|r.",
    MINIMAP_TOOLTIP_TITLE    = "|cff00cc66Hide|rAnything",
    MINIMAP_TOOLTIP_LEFT     = "|cff00cc66ЛКМ|r: Открыть настройки",
    MINIMAP_TOOLTIP_SHIFT    = "|cff8888ffShift-Клик|r: Показать все скрытые фреймы",
    MINIMAP_TOOLTIP_DRAG     = "|cff888888Перетащите|r для перемещения",

    -- Options Panel / UI
    UI_TITLE                 = "HideAnything Настройки",
    UI_FRAMES                = "Фреймы",
    UI_PROFILES              = "Профили",
    UI_ABOUT                 = "О дополнении",

    UI_BTN_SHOW_ALL          = "Показать всё",
    UI_BTN_HIDE              = "Скрыть",
    UI_BTN_SHOW              = "Показать",
    UI_BTN_SAVE_PROFILE      = "Сохранить профиль",
    UI_BTN_LOAD_PROFILE      = "Загрузить профиль",
    UI_BTN_DELETE_PROFILE    = "Удалить профиль",
    UI_BTN_EXPORT            = "Экспорт",
    UI_BTN_IMPORT            = "Импорт",
    UI_BTN_RESET             = "Сбросить всё",
    UI_BTN_CLOSE             = "Закрыть",

    UI_CONFIRM_RESET         = "Сбросить ВСЕ настройки?\nВсе скрытые фреймы будут показаны, а все профили удалены.",
    UI_CONFIRM_YES           = "Да, сбросить",
    UI_CONFIRM_NO            = "Отмена",

    -- Config UI section headers
    CFG_HEADER_SETTINGS      = "Настройки",
    CFG_HEADER_FRAMES        = "Фреймы интерфейса",
    CFG_HEADER_CUSTOM        = "Свой фрейм (по имени)",
    CFG_HEADER_CUSTOM_HIDDEN = "Другие скрытые фреймы",

    CFG_TOGGLE_ON            = "|cff00ff00ВКЛ|r",
    CFG_TOGGLE_OFF           = "|cffff4444ВЫКЛ|r",

    CFG_MINIMAP_BTN          = "Кнопка миникарты",
    CFG_MINIMAP_BTN_TT       = "Показать или скрыть кнопку миникарты.",
    CFG_LOCK_MODE            = "Режим блокировки",
    CFG_LOCK_MODE_TT         = "В заблокированном режиме скрытые фреймы невозможно восстановить.",
    CFG_HIGHLIGHT            = "Подсветка фреймов",
    CFG_HIGHLIGHT_TT         = "Подсвечивать фрейм при наведении на строку каталога.",
    CFG_HIGHLIGHT_ENABLED    = "Подсветка фреймов",
    CFG_HIGHLIGHT_ENABLED_TT = "Включить кнопку-глаз для подсветки фреймов на экране. При отключении кнопка-глаз скрывается.",
    CFG_CHAT_FEEDBACK        = "Сообщения в чате",
    CFG_CHAT_FEEDBACK_TT     = "Показывать сообщения в чате при скрытии или показе фреймов.",
    CFG_FADE_ANIM            = "Анимация затухания",
    CFG_FADE_ANIM_TT         = "Плавное появление и исчезновение фреймов вместо мгновенного скрытия.",
    CFG_EDITION_LABEL        = "Версия",
    CFG_COMBAT_HIDE          = "Авто-скрытие в бою",
    CFG_COMBAT_HIDE_TT       = "Автоматически скрывать этот фрейм при входе в бой и показывать после.",

    -- Language (new)
    CFG_LANGUAGE             = "Язык",
    CFG_LANGUAGE_TT          = "Выбрать язык отображения аддона. Переоткройте панель для применения.",

    -- About
    ABOUT_DESC               = "позволяет скрыть любой элемент интерфейса простым переключением.",
    ABOUT_FEATURES           = "Возможности:",
    ABOUT_F1                 = "Список из 120+ фреймов, CVar и текстур",
    ABOUT_F2                 = "Скрытие любого фрейма по имени, скрытие чата",
    ABOUT_F3                 = "Ползунок прозрачности для каждого фрейма",
    ABOUT_F4                 = "Профили: сохранение, загрузка, удаление, экспорт/импорт",
    ABOUT_F5                 = "Поиск и фильтр, подсветка фреймов при наведении",
    ABOUT_F6                 = "Авто-скрытие в бою: скрытие определённых фреймов в бою",
    ABOUT_F7                 = "Поддержка версий: Classic, TBC, MoP Classic, Retail",
    ABOUT_F8                 = "Плагин LibDataBroker для панелей аддонов",
    ABOUT_F9                 = "Защита в бою и безопасные хуки",
    ABOUT_F10                = "Скрытие текстур и декораций",
    ABOUT_COMMANDS_LABEL     = "Команды:",
    ABOUT_CONFIG_LABEL       = "Настройка:",

    -- About stats (new)
    ABOUT_STATS_TITLE        = "Статистика",
    ABOUT_STATS_HIDDEN       = "Скрыто: |cffffffff%d|r",
    ABOUT_STATS_PROFILES     = "Профили: |cffffffff%d|r",
    ABOUT_STATS_CATALOG      = "Каталог: |cffffffff%d+|r",

    UNDO_EMPTY               = "Нечего отменять.",
    REDO_EMPTY               = "Нечего повторять.",
    UNDO_SHOWN               = "Отмена: |cff00ff00%s|r показан",
    UNDO_HIDDEN              = "Отмена: |cffff8800%s|r скрыт",
    REDO_SHOWN               = "Повтор: |cff00ff00%s|r показан",
    REDO_HIDDEN              = "Повтор: |cffff8800%s|r скрыт",
    PICKER_ACTIVATED         = "|cff00c761Выбор фрейма|r активирован. Нажмите на фрейм чтобы скрыть.",
    PICKER_HOVER_HINT        = "Наведите на элемент интерфейса...",
    PICKER_INSTRUCTIONS      = "|cff00c761ЛКМ|r скрыть  |  |cffff4444ПКМ|r или |cffff4444ESC|r отмена",
    PRESETS_HEADER           = "Шаблоны",
    PRESET_APPLIED           = "Шаблон |cff00cc66%s|r применён.",
    MINIMAP_TOOLTIP_RIGHT    = "|cff00cc66ПКМ|r: Выбор фрейма",
}

---------------------------------------------------------------------------
-- Italian (itIT)
---------------------------------------------------------------------------
HA.LOCALES["itIT"] = {
    -- General
    ADDON_LOADED             = "|cff00cc66Hide|rAnything|r v%s caricato. Digita |cff00cc66/hide|r per aiuto.",

    -- Slash command help
    HELP_HEADER              = "|cff00cc66HideAnything|r Comandi:",
    HELP_TOGGLE              = "|cff00cc66/hide toggle|r - Apri/chiudi il pannello opzioni",
    HELP_SHOW_ALL            = "|cff00cc66/hide showall|r - Mostra tutti i riquadri nascosti",
    HELP_HIDE                = "|cff00cc66/hide hide <riquadro>|r - Nascondi un riquadro per nome",
    HELP_SHOW                = "|cff00cc66/hide show <riquadro>|r - Mostra un riquadro per nome",
    HELP_LIST                = "|cff00cc66/hide list|r - Elenca i riquadri nascosti",
    HELP_RESET               = "|cff00cc66/hide reset|r - Ripristina tutte le impostazioni",
    HELP_PROFILE             = "|cff00cc66/hide profile <nome>|r - Carica un profilo",
    HELP_PROFILES            = "|cff00cc66/hide profiles|r - Elenca i profili salvati",
    HELP_LOCK                = "|cff00cc66/hide lock|r - Blocca i riquadri nascosti",
    HELP_UNLOCK              = "|cff00cc66/hide unlock|r - Sblocca i riquadri nascosti",
    HELP_STATUS              = "|cff00cc66/hide status|r - Mostra lo stato dell'addon",
    HELP_MINIMAP             = "|cff00cc66/hide minimap|r - Mostra/nascondi il pulsante minimappa",
    HELP_ALPHA               = "|cff00cc66/hide alpha <riquadro> <0-100>|r - Imposta l'opacità del riquadro",

    -- Hide / Show
    FRAME_HIDDEN             = "Nascosto: |cffff8800%s|r",
    FRAME_SHOWN              = "Mostrato: |cff00ff00%s|r",
    FRAME_NOT_FOUND          = "Riquadro |cffff4444%s|r non trovato.",
    FRAME_NOT_HIDDEN         = "Il riquadro |cffffffff%s|r non è attualmente nascosto.",
    ALL_FRAMES_SHOWN         = "Tutti i |cff00ff00%d|r riquadri nascosti sono di nuovo visibili.",
    NO_FRAMES_HIDDEN         = "Nessun riquadro è attualmente nascosto.",

    -- Alpha / Opacity
    ALPHA_SET                = "Opacità di |cff00cc66%s|r impostata a |cffffffff%d%%|r.",
    ALPHA_RESET              = "Opacità di |cff00cc66%s|r ripristinata a 100%%.",
    ALPHA_TITLE              = "Opacità",
    ALPHA_LABEL              = "Opacità: %d%%",
    ALPHA_TOOLTIP            = "Imposta la trasparenza del riquadro (0%% = invisibile, 100%% = completamente visibile)",

    -- Frame states (tooltips)
    FRAME_STATE_HIDDEN       = "Attualmente nascosto",
    FRAME_STATE_VISIBLE      = "Attualmente visibile",
    FRAME_STATE_ALPHA        = "Opacità: %d%%",
    FRAME_NOT_LOADED         = "Riquadro non ancora caricato",

    -- Search
    SEARCH_PLACEHOLDER       = "Cerca riquadri...",

    -- Protected
    PICKER_PROTECTED         = "Impossibile nascondere |cffff4444%s|r - questo riquadro è protetto.",
    PICKER_ALREADY_HIDDEN    = "|cffffffff%s|r è già nascosto.",

    -- List
    LIST_HEADER              = "|cff00cc66Riquadri nascosti|r (%d):",
    LIST_ENTRY               = "  |cffff8800%d.|r %s",

    -- Profiles
    PROFILE_SAVED            = "Profilo |cff00cc66%s|r salvato con %d riquadri nascosti.",
    PROFILE_LOADED           = "Profilo |cff00cc66%s|r caricato (%d riquadri nascosti).",
    PROFILE_DELETED          = "Profilo |cffff4444%s|r eliminato.",
    PROFILE_NOT_FOUND        = "Profilo |cffff4444%s|r non trovato.",
    PROFILE_EXISTS           = "Il profilo |cffffffff%s|r esiste già. Usa |cff00cc66/hide profile overwrite <nome>|r per sovrascrivere.",
    PROFILE_LIST_HEADER      = "|cff00cc66Profili salvati|r (%d):",
    PROFILE_LIST_ENTRY       = "  |cffff8800%d.|r %s |cff888888(%d riquadri)|r",
    PROFILE_NO_PROFILES      = "Nessun profilo salvato.",
    PROFILE_EXPORTED         = "Profilo |cff00cc66%s|r esportato negli appunti.",
    PROFILE_IMPORTED         = "Profilo |cff00cc66%s|r importato con %d riquadri.",
    PROFILE_IMPORT_ERROR     = "|cffff4444Errore|r: Impossibile importare il profilo. Dati non validi.",
    PROFILE_NAME_REQUIRED    = "Inserisci un nome per il profilo.",

    -- Lock
    FRAMES_LOCKED            = "Tutti i riquadri nascosti sono ora |cffff4444bloccati|r.",
    FRAMES_UNLOCKED          = "Tutti i riquadri nascosti sono ora |cff00ff00sbloccati|r.",

    -- Reset
    RESET_CONFIRM            = "Sei sicuro di voler ripristinare |cffff4444tutte|r le impostazioni? Digita |cff00cc66/hide reset confirm|r per confermare.",
    RESET_DONE               = "Tutte le impostazioni sono state |cffff4444ripristinate|r ai valori predefiniti.",

    -- Status
    STATUS_HEADER            = "|cff00cc66HideAnything|r Stato:",
    STATUS_HIDDEN_COUNT      = "Riquadri nascosti: |cffffffff%d|r",
    STATUS_LOCKED            = "Modalità blocco: |cffff4444BLOCCATO|r",
    STATUS_UNLOCKED          = "Modalità blocco: |cff00ff00SBLOCCATO|r",
    STATUS_PROFILE           = "Profilo attivo: |cffffffff%s|r",
    STATUS_MINIMAP           = "Pulsante minimappa: |cffffffff%s|r",
    STATUS_ON                = "|cff00ff00ATTIVO|r",
    STATUS_OFF               = "|cffff4444DISATTIVO|r",

    -- Errors
    ERROR_COMBAT             = "|cffff4444Errore|r: Impossibile modificare elementi dell'interfaccia durante il combattimento.",
    ERROR_UNKNOWN_CMD        = "|cffff4444Comando sconosciuto|r: |cffffffff%s|r. Digita |cff00cc66/hide|r per aiuto.",
    ERROR_FRAME_NIL          = "|cffff4444Errore|r: Il riferimento al riquadro è nil.",
    ERROR_FRAME_PROTECTED    = "|cffff4444Errore|r: Il riquadro |cffffffff%s|r è protetto e non può essere modificato in combattimento.",
    ERROR_DB_CORRUPT         = "|cffff4444Errore|r: I dati salvati sembrano corrotti. Ripristino ai valori predefiniti.",
    ERROR_HOOK_FAILED        = "|cffff4444Attenzione|r: Impossibile agganciare il riquadro |cffffffff%s|r. Potrebbe riapparire dopo il ricaricamento.",
    ERROR_CVAR_FAILED        = "|cffff4444Errore|r: Impossibile impostare il CVar |cffffffff%s|r.",
    ERROR_EXPORT_FAILED      = "|cffff4444Errore|r: Esportazione fallita.",
    ERROR_IMPORT_PARSE       = "|cffff4444Errore|r: Importazione fallita. Formato dati non riconosciuto.",

    -- Minimap
    MINIMAP_SHOWN            = "Pulsante minimappa |cff00ff00mostrato|r.",
    MINIMAP_HIDDEN           = "Pulsante minimappa |cffff4444nascosto|r.",
    MINIMAP_TOOLTIP_TITLE    = "|cff00cc66Hide|rAnything",
    MINIMAP_TOOLTIP_LEFT     = "|cff00cc66Clic sinistro|r: Opzioni",
    MINIMAP_TOOLTIP_SHIFT    = "|cff8888ffShift-Clic|r: Mostra tutti i riquadri nascosti",
    MINIMAP_TOOLTIP_DRAG     = "|cff888888Trascina|r per spostare",

    -- Options Panel / UI
    UI_TITLE                 = "HideAnything Opzioni",
    UI_FRAMES                = "Riquadri",
    UI_PROFILES              = "Profili",
    UI_ABOUT                 = "Informazioni",

    UI_BTN_SHOW_ALL          = "Mostra tutto",
    UI_BTN_HIDE              = "Nascondi",
    UI_BTN_SHOW              = "Mostra",
    UI_BTN_SAVE_PROFILE      = "Salva profilo",
    UI_BTN_LOAD_PROFILE      = "Carica profilo",
    UI_BTN_DELETE_PROFILE    = "Elimina profilo",
    UI_BTN_EXPORT            = "Esporta",
    UI_BTN_IMPORT            = "Importa",
    UI_BTN_RESET             = "Ripristina tutto",
    UI_BTN_CLOSE             = "Chiudi",

    UI_CONFIRM_RESET         = "Ripristinare TUTTE le impostazioni?\nTutti i riquadri nascosti verranno mostrati e tutti i profili eliminati.",
    UI_CONFIRM_YES           = "Sì, ripristina",
    UI_CONFIRM_NO            = "Annulla",

    -- Config UI section headers
    CFG_HEADER_SETTINGS      = "Impostazioni",
    CFG_HEADER_FRAMES        = "Riquadri dell'interfaccia",
    CFG_HEADER_CUSTOM        = "Riquadro personalizzato (per nome)",
    CFG_HEADER_CUSTOM_HIDDEN = "Altri riquadri nascosti",

    CFG_TOGGLE_ON            = "|cff00ff00ATTIVO|r",
    CFG_TOGGLE_OFF           = "|cffff4444DISATTIVO|r",

    CFG_MINIMAP_BTN          = "Pulsante minimappa",
    CFG_MINIMAP_BTN_TT       = "Mostra o nascondi il pulsante minimappa.",
    CFG_LOCK_MODE            = "Modalità blocco",
    CFG_LOCK_MODE_TT         = "Quando bloccato, i riquadri nascosti non possono essere ripristinati.",
    CFG_HIGHLIGHT            = "Evidenzia riquadri",
    CFG_HIGHLIGHT_TT         = "Evidenzia il riquadro di gioco quando si passa col mouse su una riga del catalogo.",
    CFG_HIGHLIGHT_ENABLED    = "Evidenziazione riquadri",
    CFG_HIGHLIGHT_ENABLED_TT = "Attiva il pulsante occhio per evidenziare i riquadri sullo schermo. Se disattivato, il pulsante occhio è nascosto.",
    CFG_CHAT_FEEDBACK        = "Messaggi in chat",
    CFG_CHAT_FEEDBACK_TT     = "Mostra messaggi nella chat quando si nascondono o mostrano riquadri.",
    CFG_FADE_ANIM            = "Animazione dissolvenza",
    CFG_FADE_ANIM_TT         = "Dissolvenza graduale dei riquadri invece di nasconderli istantaneamente.",
    CFG_EDITION_LABEL        = "Edizione",
    CFG_COMBAT_HIDE          = "Nascondi auto in combattimento",
    CFG_COMBAT_HIDE_TT       = "Nasconde automaticamente questo riquadro in combattimento e lo mostra dopo.",

    -- Language (new)
    CFG_LANGUAGE             = "Lingua",
    CFG_LANGUAGE_TT          = "Seleziona la lingua dell'addon. Riapri il pannello per applicare.",

    -- About
    ABOUT_DESC               = "permette di nascondere qualsiasi elemento dell'interfaccia con un semplice clic.",
    ABOUT_FEATURES           = "Funzionalità:",
    ABOUT_F1                 = "Lista di 120+ riquadri, CVar e texture",
    ABOUT_F2                 = "Nascondi qualsiasi riquadro per nome, nascondi la chat",
    ABOUT_F3                 = "Cursore di opacità per riquadro",
    ABOUT_F4                 = "Profili: salva, carica, elimina, esporta/importa",
    ABOUT_F5                 = "Ricerca e filtro, evidenziazione al passaggio del mouse",
    ABOUT_F6                 = "Nascondi auto in combattimento: nascondi riquadri durante il combattimento",
    ABOUT_F7                 = "Supporto edizioni: Classic, TBC, MoP Classic, Retail",
    ABOUT_F8                 = "Plugin LibDataBroker per barre addon",
    ABOUT_F9                 = "Protezione combattimento e hook sicuri",
    ABOUT_F10                = "Nascondere texture e decorazioni",
    ABOUT_COMMANDS_LABEL     = "Comandi:",
    ABOUT_CONFIG_LABEL       = "Configurazione:",

    -- About stats (new)
    ABOUT_STATS_TITLE        = "Statistiche",
    ABOUT_STATS_HIDDEN       = "Nascosti: |cffffffff%d|r",
    ABOUT_STATS_PROFILES     = "Profili: |cffffffff%d|r",
    ABOUT_STATS_CATALOG      = "Catalogo: |cffffffff%d+|r",

    UNDO_EMPTY               = "Nulla da annullare.",
    REDO_EMPTY               = "Nulla da ripetere.",
    UNDO_SHOWN               = "Annullato: |cff00ff00%s|r mostrato",
    UNDO_HIDDEN              = "Annullato: |cffff8800%s|r nascosto",
    REDO_SHOWN               = "Ripeti: |cff00ff00%s|r mostrato",
    REDO_HIDDEN              = "Ripeti: |cffff8800%s|r nascosto",
    PICKER_ACTIVATED         = "|cff00c761Selettore|r attivato. Clicca su un riquadro per nasconderlo.",
    PICKER_HOVER_HINT        = "Passa sopra un elemento dell'interfaccia...",
    PICKER_INSTRUCTIONS      = "|cff00c761Clic sinistro|r nascondi  |  |cffff4444Clic destro|r o |cffff4444ESC|r annulla",
    PRESETS_HEADER           = "Predefiniti",
    PRESET_APPLIED           = "Predefinito |cff00cc66%s|r applicato.",
    MINIMAP_TOOLTIP_RIGHT    = "|cff00cc66Clic destro|r: Selettore riquadro",
}

---------------------------------------------------------------------------
-- Apply language
---------------------------------------------------------------------------
function HA:ApplyLanguage(lang)
    if not lang or lang == "auto" then
        lang = GetLocale()
    end
    if lang == "esMX" then lang = "esES" end
    if lang == "enGB" then lang = "enUS" end

    local base = self.LOCALES["enUS"]
    local target = self.LOCALES[lang]

    for k, v in pairs(base) do
        self.L[k] = (target and target[k]) or v
    end

    self._currentLanguage = lang
end

-- Initial apply with detected locale
HA:ApplyLanguage("auto")
