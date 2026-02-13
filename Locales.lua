--[[
    HideAnything - Locales.lua
    German (deDE) & English (enUS) localization
]]

local AddonName, HA = ...

-- Startup diagnostic
HA._loaded = true
C_Timer.After(3, function()
    if HA._loaded and not HA._initDone then
        print("|cffff8800[HideAnything]|r Addon files loaded but initialization failed! Check /console scriptErrors 1")
    end
end)

HA.L = {}
local L = HA.L
local locale = GetLocale()

---------------------------------------------------------------------------
-- English (default)
---------------------------------------------------------------------------
-- General
L["ADDON_LOADED"]            = "|cff00cc66Hide|rAnything|r v%s loaded. Type |cff00cc66/ha|r for help."
L["ADDON_NAME"]              = "HideAnything"
L["VERSION"]                 = "Version"

-- Slash command help
L["HELP_HEADER"]             = "|cff00cc66HideAnything|r Commands:"
L["HELP_TOGGLE"]             = "|cff00cc66/ha toggle|r - Toggle the options panel"
L["HELP_SHOW_ALL"]           = "|cff00cc66/ha showall|r - Show all hidden frames"
L["HELP_HIDE"]               = "|cff00cc66/ha hide <frame>|r - Hide a specific frame by name"
L["HELP_SHOW"]               = "|cff00cc66/ha show <frame>|r - Show a specific frame by name"
L["HELP_LIST"]               = "|cff00cc66/ha list|r - List all currently hidden frames"
L["HELP_RESET"]              = "|cff00cc66/ha reset|r - Reset all settings to defaults"
L["HELP_PROFILE"]            = "|cff00cc66/ha profile <name>|r - Load a profile"
L["HELP_PROFILES"]           = "|cff00cc66/ha profiles|r - List all saved profiles"
L["HELP_LOCK"]               = "|cff00cc66/ha lock|r - Lock all hidden frames"
L["HELP_UNLOCK"]             = "|cff00cc66/ha unlock|r - Unlock all hidden frames"
L["HELP_STATUS"]             = "|cff00cc66/ha status|r - Show addon status"
L["HELP_MINIMAP"]            = "|cff00cc66/ha minimap|r - Toggle minimap button"

-- Hide / Show
L["FRAME_HIDDEN"]            = "Hidden: |cffff8800%s|r"
L["FRAME_SHOWN"]             = "Shown: |cff00ff00%s|r"
L["FRAME_NOT_FOUND"]         = "Frame |cffff4444%s|r not found."
L["FRAME_NOT_HIDDEN"]        = "Frame |cffffffff%s|r is not currently hidden."
L["ALL_FRAMES_SHOWN"]        = "All |cff00ff00%d|r hidden frames are now visible again."
L["NO_FRAMES_HIDDEN"]        = "No frames are currently hidden."

-- Frame states (tooltips)
L["FRAME_STATE_HIDDEN"]      = "Currently hidden"
L["FRAME_STATE_VISIBLE"]     = "Currently visible"
L["FRAME_NOT_LOADED"]        = "Frame not loaded yet"

-- Protected
L["PICKER_PROTECTED"]        = "Cannot hide |cffff4444%s|r - this frame is protected."
L["PICKER_ALREADY_HIDDEN"]   = "|cffffffff%s|r is already hidden."

-- List
L["LIST_HEADER"]             = "|cff00cc66Hidden frames|r (%d):"
L["LIST_ENTRY"]              = "  |cffff8800%d.|r %s"

-- Profiles
L["PROFILE_SAVED"]           = "Profile |cff00cc66%s|r saved with %d hidden frames."
L["PROFILE_LOADED"]          = "Profile |cff00cc66%s|r loaded (%d frames hidden)."
L["PROFILE_DELETED"]         = "Profile |cffff4444%s|r deleted."
L["PROFILE_NOT_FOUND"]       = "Profile |cffff4444%s|r not found."
L["PROFILE_EXISTS"]          = "Profile |cffffffff%s|r already exists. Use |cff00cc66/ha profile overwrite <name>|r to overwrite."
L["PROFILE_LIST_HEADER"]     = "|cff00cc66Saved profiles|r (%d):"
L["PROFILE_LIST_ENTRY"]      = "  |cffff8800%d.|r %s |cff888888(%d frames)|r"
L["PROFILE_NO_PROFILES"]     = "No saved profiles."
L["PROFILE_EXPORTED"]        = "Profile |cff00cc66%s|r exported to clipboard."
L["PROFILE_IMPORTED"]        = "Profile |cff00cc66%s|r imported with %d frames."
L["PROFILE_IMPORT_ERROR"]    = "|cffff4444Error|r: Could not import profile. Invalid data."
L["PROFILE_NAME_REQUIRED"]   = "Please provide a profile name."

-- Lock
L["FRAMES_LOCKED"]           = "All hidden frames are now |cffff4444locked|r."
L["FRAMES_UNLOCKED"]         = "All hidden frames are now |cff00ff00unlocked|r."

-- Reset
L["RESET_CONFIRM"]           = "Are you sure you want to reset |cffff4444all|r HideAnything settings? Type |cff00cc66/ha reset confirm|r to confirm."
L["RESET_DONE"]              = "All settings have been |cffff4444reset|r to defaults."

-- Status
L["STATUS_HEADER"]           = "|cff00cc66HideAnything|r Status:"
L["STATUS_HIDDEN_COUNT"]     = "Hidden frames: |cffffffff%d|r"
L["STATUS_LOCKED"]           = "Lock mode: |cffff4444LOCKED|r"
L["STATUS_UNLOCKED"]         = "Lock mode: |cff00ff00UNLOCKED|r"
L["STATUS_PROFILE"]          = "Active profile: |cffffffff%s|r"
L["STATUS_MINIMAP"]          = "Minimap button: |cffffffff%s|r"
L["STATUS_ON"]               = "|cff00ff00ON|r"
L["STATUS_OFF"]              = "|cffff4444OFF|r"

-- Errors
L["ERROR_COMBAT"]            = "|cffff4444Error|r: Cannot modify UI elements during combat."
L["ERROR_UNKNOWN_CMD"]       = "|cffff4444Unknown command|r: |cffffffff%s|r. Type |cff00cc66/ha|r for help."
L["ERROR_FRAME_NIL"]         = "|cffff4444Error|r: Frame reference is nil."
L["ERROR_FRAME_PROTECTED"]   = "|cffff4444Error|r: Frame |cffffffff%s|r is protected and cannot be modified in combat."
L["ERROR_DB_CORRUPT"]        = "|cffff4444Error|r: Saved data appears corrupt. Resetting to defaults."
L["ERROR_HOOK_FAILED"]       = "|cffff4444Warning|r: Could not hook frame |cffffffff%s|r. It may reappear after reload."
L["ERROR_EXPORT_FAILED"]     = "|cffff4444Error|r: Export failed."
L["ERROR_IMPORT_PARSE"]      = "|cffff4444Error|r: Import failed. Data format not recognized."

-- Minimap
L["MINIMAP_SHOWN"]           = "Minimap button |cff00ff00shown|r."
L["MINIMAP_HIDDEN"]          = "Minimap button |cffff4444hidden|r."
L["MINIMAP_TOOLTIP_TITLE"]   = "|cff00cc66Hide|rAnything"
L["MINIMAP_TOOLTIP_LEFT"]    = "|cff00cc66Left-Click|r: Toggle options"
L["MINIMAP_TOOLTIP_SHIFT"]   = "|cff8888ffShift-Click|r: Show all hidden frames"
L["MINIMAP_TOOLTIP_DRAG"]    = "|cff888888Drag|r to move"

-- Options Panel / UI
L["UI_TITLE"]                = "HideAnything Options"
L["UI_FRAMES"]               = "Frames"
L["UI_PROFILES"]             = "Profiles"
L["UI_ABOUT"]                = "About"

L["UI_BTN_SHOW_ALL"]         = "Show All"
L["UI_BTN_HIDE"]             = "Hide"
L["UI_BTN_SHOW"]             = "Show"
L["UI_BTN_SAVE_PROFILE"]     = "Save Profile"
L["UI_BTN_LOAD_PROFILE"]     = "Load Profile"
L["UI_BTN_DELETE_PROFILE"]   = "Delete Profile"
L["UI_BTN_EXPORT"]           = "Export"
L["UI_BTN_IMPORT"]           = "Import"
L["UI_BTN_RESET"]            = "Reset All"
L["UI_BTN_CLOSE"]            = "Close"

L["UI_CONFIRM_RESET"]        = "Reset ALL settings?\nAll hidden frames will be shown and all profiles will be deleted."
L["UI_CONFIRM_YES"]          = "Yes, Reset"
L["UI_CONFIRM_NO"]           = "Cancel"

-- Config UI section headers
L["CFG_HEADER_SETTINGS"]     = "Settings"
L["CFG_HEADER_FRAMES"]       = "UI Frames"
L["CFG_HEADER_CUSTOM"]       = "Custom Frame (by name)"
L["CFG_HEADER_CUSTOM_HIDDEN"]= "Other Hidden Frames"

L["CFG_TOGGLE_ON"]           = "|cff00ff00ON|r"
L["CFG_TOGGLE_OFF"]          = "|cffff4444OFF|r"

L["CFG_MINIMAP_BTN"]         = "Minimap Button"
L["CFG_MINIMAP_BTN_TT"]      = "Show or hide the minimap button."
L["CFG_LOCK_MODE"]           = "Lock Mode"
L["CFG_LOCK_MODE_TT"]        = "When locked, hidden frames cannot be restored. Only the config panel or /ha unlock can restore them."

-- About
L["ABOUT_DESC"]              = "lets you hide any UI element with a simple toggle."
L["ABOUT_FEATURES"]          = "Features:"
L["ABOUT_F1"]                = "Toggle list of common UI frames"
L["ABOUT_F2"]                = "Hide any frame by name"
L["ABOUT_F3"]                = "Confirmation dialog before hiding"
L["ABOUT_F4"]                = "Profiles: save, load, delete, export/import"
L["ABOUT_F5"]                = "Minimap + floating button"
L["ABOUT_F6"]                = "Combat protection & secure hooks"

---------------------------------------------------------------------------
-- German (deDE)
---------------------------------------------------------------------------
if locale == "deDE" then
    L["ADDON_LOADED"]            = "|cff00cc66Hide|rAnything|r v%s geladen. Tippe |cff00cc66/ha|r für Hilfe."

    L["HELP_HEADER"]             = "|cff00cc66HideAnything|r Befehle:"
    L["HELP_TOGGLE"]             = "|cff00cc66/ha toggle|r - Optionsfenster öffnen/schließen"
    L["HELP_SHOW_ALL"]           = "|cff00cc66/ha showall|r - Alle versteckten Frames anzeigen"
    L["HELP_HIDE"]               = "|cff00cc66/ha hide <frame>|r - Einen Frame nach Name verstecken"
    L["HELP_SHOW"]               = "|cff00cc66/ha show <frame>|r - Einen Frame nach Name anzeigen"
    L["HELP_LIST"]               = "|cff00cc66/ha list|r - Alle versteckten Frames auflisten"
    L["HELP_RESET"]              = "|cff00cc66/ha reset|r - Alle Einstellungen zurücksetzen"
    L["HELP_PROFILE"]            = "|cff00cc66/ha profile <name>|r - Profil laden"
    L["HELP_PROFILES"]           = "|cff00cc66/ha profiles|r - Alle gespeicherten Profile auflisten"
    L["HELP_LOCK"]               = "|cff00cc66/ha lock|r - Alle versteckten Frames sperren"
    L["HELP_UNLOCK"]             = "|cff00cc66/ha unlock|r - Alle versteckten Frames entsperren"
    L["HELP_STATUS"]             = "|cff00cc66/ha status|r - Addon-Status anzeigen"
    L["HELP_MINIMAP"]            = "|cff00cc66/ha minimap|r - Minimap-Button umschalten"

    L["FRAME_HIDDEN"]            = "Versteckt: |cffff8800%s|r"
    L["FRAME_SHOWN"]             = "Angezeigt: |cff00ff00%s|r"
    L["FRAME_NOT_FOUND"]         = "Frame |cffff4444%s|r nicht gefunden."
    L["FRAME_NOT_HIDDEN"]        = "Frame |cffffffff%s|r ist momentan nicht versteckt."
    L["ALL_FRAMES_SHOWN"]        = "Alle |cff00ff00%d|r versteckten Frames sind jetzt wieder sichtbar."
    L["NO_FRAMES_HIDDEN"]        = "Es sind keine Frames versteckt."

    L["FRAME_STATE_HIDDEN"]      = "Momentan versteckt"
    L["FRAME_STATE_VISIBLE"]     = "Momentan sichtbar"
    L["FRAME_NOT_LOADED"]        = "Frame noch nicht geladen"

    L["PICKER_PROTECTED"]        = "Kann |cffff4444%s|r nicht verstecken - dieser Frame ist geschützt."
    L["PICKER_ALREADY_HIDDEN"]   = "|cffffffff%s|r ist bereits versteckt."

    L["LIST_HEADER"]             = "|cff00cc66Versteckte Frames|r (%d):"
    L["LIST_ENTRY"]              = "  |cffff8800%d.|r %s"

    L["PROFILE_SAVED"]           = "Profil |cff00cc66%s|r gespeichert mit %d versteckten Frames."
    L["PROFILE_LOADED"]          = "Profil |cff00cc66%s|r geladen (%d Frames versteckt)."
    L["PROFILE_DELETED"]         = "Profil |cffff4444%s|r gelöscht."
    L["PROFILE_NOT_FOUND"]       = "Profil |cffff4444%s|r nicht gefunden."
    L["PROFILE_EXISTS"]          = "Profil |cffffffff%s|r existiert bereits. Nutze |cff00cc66/ha profile overwrite <name>|r zum Überschreiben."
    L["PROFILE_LIST_HEADER"]     = "|cff00cc66Gespeicherte Profile|r (%d):"
    L["PROFILE_LIST_ENTRY"]      = "  |cffff8800%d.|r %s |cff888888(%d Frames)|r"
    L["PROFILE_NO_PROFILES"]     = "Keine gespeicherten Profile."
    L["PROFILE_EXPORTED"]        = "Profil |cff00cc66%s|r in die Zwischenablage exportiert."
    L["PROFILE_IMPORTED"]        = "Profil |cff00cc66%s|r importiert mit %d Frames."
    L["PROFILE_IMPORT_ERROR"]    = "|cffff4444Fehler|r: Profil konnte nicht importiert werden. Ungültige Daten."
    L["PROFILE_NAME_REQUIRED"]   = "Bitte gib einen Profilnamen an."

    L["FRAMES_LOCKED"]           = "Alle versteckten Frames sind jetzt |cffff4444gesperrt|r."
    L["FRAMES_UNLOCKED"]         = "Alle versteckten Frames sind jetzt |cff00ff00entsperrt|r."

    L["RESET_CONFIRM"]           = "Bist du sicher, dass du |cffff4444alle|r Einstellungen zurücksetzen willst? Tippe |cff00cc66/ha reset confirm|r."
    L["RESET_DONE"]              = "Alle Einstellungen wurden auf |cffff4444Standardwerte|r zurückgesetzt."

    L["STATUS_HEADER"]           = "|cff00cc66HideAnything|r Status:"
    L["STATUS_HIDDEN_COUNT"]     = "Versteckte Frames: |cffffffff%d|r"
    L["STATUS_LOCKED"]           = "Sperrmodus: |cffff4444GESPERRT|r"
    L["STATUS_UNLOCKED"]         = "Sperrmodus: |cff00ff00ENTSPERRT|r"
    L["STATUS_PROFILE"]          = "Aktives Profil: |cffffffff%s|r"
    L["STATUS_MINIMAP"]          = "Minimap-Button: |cffffffff%s|r"
    L["STATUS_ON"]               = "|cff00ff00AN|r"
    L["STATUS_OFF"]              = "|cffff4444AUS|r"

    L["ERROR_COMBAT"]            = "|cffff4444Fehler|r: UI-Elemente können im Kampf nicht verändert werden."
    L["ERROR_UNKNOWN_CMD"]       = "|cffff4444Unbekannter Befehl|r: |cffffffff%s|r. Tippe |cff00cc66/ha|r für Hilfe."
    L["ERROR_FRAME_NIL"]         = "|cffff4444Fehler|r: Frame-Referenz ist nil."
    L["ERROR_FRAME_PROTECTED"]   = "|cffff4444Fehler|r: Frame |cffffffff%s|r ist geschützt und kann im Kampf nicht verändert werden."
    L["ERROR_DB_CORRUPT"]        = "|cffff4444Fehler|r: Gespeicherte Daten scheinen beschädigt zu sein. Setze auf Standardwerte zurück."
    L["ERROR_HOOK_FAILED"]       = "|cffff4444Warnung|r: Frame |cffffffff%s|r konnte nicht gehookt werden."
    L["ERROR_EXPORT_FAILED"]     = "|cffff4444Fehler|r: Export fehlgeschlagen."
    L["ERROR_IMPORT_PARSE"]      = "|cffff4444Fehler|r: Import fehlgeschlagen. Datenformat nicht erkannt."

    L["MINIMAP_SHOWN"]           = "Minimap-Button |cff00ff00angezeigt|r."
    L["MINIMAP_HIDDEN"]          = "Minimap-Button |cffff4444versteckt|r."
    L["MINIMAP_TOOLTIP_TITLE"]   = "|cff00cc66Hide|rAnything"
    L["MINIMAP_TOOLTIP_LEFT"]    = "|cff00cc66Linksklick|r: Optionen umschalten"
    L["MINIMAP_TOOLTIP_SHIFT"]   = "|cff8888ffShift-Klick|r: Alle versteckten Frames anzeigen"
    L["MINIMAP_TOOLTIP_DRAG"]    = "|cff888888Ziehen|r zum Verschieben"

    L["UI_TITLE"]                = "HideAnything Optionen"
    L["UI_FRAMES"]               = "Frames"
    L["UI_PROFILES"]             = "Profile"
    L["UI_ABOUT"]                = "Info"

    L["UI_BTN_SHOW_ALL"]         = "Alle anzeigen"
    L["UI_BTN_HIDE"]             = "Verstecken"
    L["UI_BTN_SHOW"]             = "Anzeigen"
    L["UI_BTN_SAVE_PROFILE"]     = "Profil speichern"
    L["UI_BTN_LOAD_PROFILE"]     = "Profil laden"
    L["UI_BTN_DELETE_PROFILE"]   = "Profil löschen"
    L["UI_BTN_EXPORT"]           = "Exportieren"
    L["UI_BTN_IMPORT"]           = "Importieren"
    L["UI_BTN_RESET"]            = "Alles zurücksetzen"
    L["UI_BTN_CLOSE"]            = "Schließen"

    L["UI_CONFIRM_RESET"]        = "ALLE Einstellungen zurücksetzen?\nAlle versteckten Frames werden angezeigt und alle Profile gelöscht."
    L["UI_CONFIRM_YES"]          = "Ja, zurücksetzen"
    L["UI_CONFIRM_NO"]           = "Abbrechen"

    L["CFG_HEADER_SETTINGS"]     = "Einstellungen"
    L["CFG_HEADER_FRAMES"]       = "UI-Frames"
    L["CFG_HEADER_CUSTOM"]       = "Eigener Frame (per Name)"
    L["CFG_HEADER_CUSTOM_HIDDEN"]= "Andere versteckte Frames"

    L["CFG_TOGGLE_ON"]           = "|cff00ff00AN|r"
    L["CFG_TOGGLE_OFF"]          = "|cffff4444AUS|r"

    L["CFG_MINIMAP_BTN"]         = "Minimap-Button"
    L["CFG_MINIMAP_BTN_TT"]      = "Zeigt oder versteckt den Minimap-Button."
    L["CFG_LOCK_MODE"]           = "Sperrmodus"
    L["CFG_LOCK_MODE_TT"]        = "Wenn gesperrt, können versteckte Frames nicht wiederhergestellt werden."

    L["ABOUT_DESC"]              = "versteckt beliebige UI-Elemente per einfachem Toggle."
    L["ABOUT_FEATURES"]          = "Funktionen:"
    L["ABOUT_F1"]                = "Toggle-Liste gängiger UI-Frames"
    L["ABOUT_F2"]                = "Beliebigen Frame per Name verstecken"
    L["ABOUT_F3"]                = "Bestätigungsdialog vor dem Verstecken"
    L["ABOUT_F4"]                = "Profile: speichern, laden, löschen, export/import"
    L["ABOUT_F5"]                = "Minimap- + Floating-Button"
    L["ABOUT_F6"]                = "Kampfschutz & sichere Hooks"
end
