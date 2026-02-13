--[[
    HideAnything - Locales.lua
    German (deDE) & English (enUS) localization
    All error texts, UI labels, audio hint descriptions, tooltips
]]

local AddonName, HA = ...

HA.L = {}
local L = HA.L

-- Detect client locale
local locale = GetLocale()

---------------------------------------------------------------------------
-- English (default / fallback)
---------------------------------------------------------------------------
-- General
L["ADDON_LOADED"]            = "|cff00cc66Hide|rAnything|r v%s loaded. Type |cff00cc66/ha|r for help."
L["ADDON_NAME"]              = "HideAnything"
L["VERSION"]                 = "Version"

-- Slash command help
L["HELP_HEADER"]             = "|cff00cc66HideAnything|r Commands:"
L["HELP_TOGGLE"]             = "|cff00cc66/ha toggle|r - Toggle the options panel"
L["HELP_PICK"]               = "|cff00cc66/ha pick|r - Start frame picker mode"
L["HELP_SHOW_ALL"]           = "|cff00cc66/ha showall|r - Show all hidden frames"
L["HELP_HIDE"]               = "|cff00cc66/ha hide <frame>|r - Hide a specific frame by name"
L["HELP_SHOW"]               = "|cff00cc66/ha show <frame>|r - Show a specific frame by name"
L["HELP_LIST"]               = "|cff00cc66/ha list|r - List all currently hidden frames"
L["HELP_RESET"]              = "|cff00cc66/ha reset|r - Reset all settings to defaults"
L["HELP_PROFILE"]            = "|cff00cc66/ha profile <name>|r - Load a profile"
L["HELP_PROFILES"]           = "|cff00cc66/ha profiles|r - List all saved profiles"
L["HELP_LOCK"]               = "|cff00cc66/ha lock|r - Lock all hidden frames (prevent accidental show)"
L["HELP_UNLOCK"]             = "|cff00cc66/ha unlock|r - Unlock all hidden frames"
L["HELP_STATUS"]             = "|cff00cc66/ha status|r - Show addon status"
L["HELP_MINIMAP"]            = "|cff00cc66/ha minimap|r - Toggle minimap button"

-- Frame Picker
L["PICKER_STARTED"]          = "Frame picker |cff00ff00activated|r. Hover over a UI element and |cff00cc66LEFT-CLICK|r to hide it. |cffff0000RIGHT-CLICK|r or |cffff0000ESC|r to cancel."
L["PICKER_STOPPED"]          = "Frame picker |cffff4444deactivated|r."
L["PICKER_TOOLTIP_TITLE"]    = "HideAnything - Frame Picker"
L["PICKER_TOOLTIP_NAME"]     = "Frame: |cffffffff%s|r"
L["PICKER_TOOLTIP_TYPE"]     = "Type: |cffffffff%s|r"
L["PICKER_TOOLTIP_PARENT"]   = "Parent: |cffffffff%s|r"
L["PICKER_TOOLTIP_SIZE"]     = "Size: |cffffffff%.0f x %.0f|r"
L["PICKER_TOOLTIP_HINT"]     = "|cff00cc66Left-Click|r to hide  |  |cffff4444Right-Click|r to cancel"
L["PICKER_NO_FRAME"]         = "No valid frame found under cursor."
L["PICKER_PROTECTED"]        = "Cannot hide |cffff4444%s|r - this frame is protected by Blizzard."
L["PICKER_ALREADY_HIDDEN"]   = "|cffffffff%s|r is already hidden."

-- Hide / Show
L["FRAME_HIDDEN"]            = "Hidden: |cffff8800%s|r"
L["FRAME_SHOWN"]             = "Shown: |cff00ff00%s|r"
L["FRAME_NOT_FOUND"]         = "Frame |cffff4444%s|r not found."
L["FRAME_NOT_HIDDEN"]        = "Frame |cffffffff%s|r is not currently hidden."
L["ALL_FRAMES_SHOWN"]        = "All |cff00ff00%d|r hidden frames are now visible again."
L["NO_FRAMES_HIDDEN"]        = "No frames are currently hidden."

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
L["STATUS_FEEDBACK_SOUND"]   = "Sound feedback: |cffffffff%s|r"
L["STATUS_FEEDBACK_CHAT"]    = "Chat feedback: |cffffffff%s|r"
L["STATUS_FEEDBACK_SCREEN"]  = "Screen feedback: |cffffffff%s|r"

-- Errors
L["ERROR_COMBAT"]            = "|cffff4444Error|r: Cannot modify UI elements during combat. Try again after combat."
L["ERROR_UNKNOWN_CMD"]       = "|cffff4444Unknown command|r: |cffffffff%s|r. Type |cff00cc66/ha|r for help."
L["ERROR_FRAME_NIL"]         = "|cffff4444Error|r: Frame reference is nil."
L["ERROR_FRAME_PROTECTED"]   = "|cffff4444Error|r: Frame |cffffffff%s|r is Blizzard-protected and cannot be modified in combat."
L["ERROR_DB_CORRUPT"]        = "|cffff4444Error|r: Saved data appears corrupt. Resetting to defaults."
L["ERROR_HOOK_FAILED"]       = "|cffff4444Warning|r: Could not hook frame |cffffffff%s|r. It may reappear after reload."
L["ERROR_EXPORT_FAILED"]     = "|cffff4444Error|r: Export failed. Could not serialize profile data."
L["ERROR_IMPORT_PARSE"]      = "|cffff4444Error|r: Import failed. Data format not recognized."

-- Minimap
L["MINIMAP_SHOWN"]           = "Minimap button |cff00ff00shown|r."
L["MINIMAP_HIDDEN"]          = "Minimap button |cffff4444hidden|r."
L["MINIMAP_TOOLTIP_TITLE"]   = "|cff00cc66Hide|rAnything"
L["MINIMAP_TOOLTIP_LEFT"]    = "|cff00cc66Left-Click|r: Toggle options"
L["MINIMAP_TOOLTIP_RIGHT"]   = "|cffff8800Right-Click|r: Frame picker"
L["MINIMAP_TOOLTIP_SHIFT"]   = "|cff8888ffShift-Click|r: Show all hidden frames"
L["MINIMAP_TOOLTIP_DRAG"]    = "|cff888888Drag|r to move"

-- Options Panel / UI
L["UI_TITLE"]                = "HideAnything Options"
L["UI_GENERAL"]              = "General"
L["UI_FEEDBACK"]             = "Feedback"
L["UI_HIDDEN_FRAMES"]        = "Hidden Frames"
L["UI_PROFILES"]             = "Profiles"
L["UI_ABOUT"]                = "About"

L["UI_ENABLE_SOUND"]         = "Enable sound feedback"
L["UI_ENABLE_SOUND_TT"]      = "Play a sound when hiding or showing frames."
L["UI_ENABLE_CHAT"]          = "Enable chat messages"
L["UI_ENABLE_CHAT_TT"]       = "Show status messages in the chat window."
L["UI_ENABLE_SCREEN"]        = "Enable on-screen messages"
L["UI_ENABLE_SCREEN_TT"]     = "Show floating text on screen when hiding/showing frames."
L["UI_ENABLE_ERROR"]         = "Enable error speech"
L["UI_ENABLE_ERROR_TT"]      = "Play Blizzard error speech for important errors."
L["UI_SOUND_HIDE"]           = "Hide sound"
L["UI_SOUND_SHOW"]           = "Show sound"
L["UI_SOUND_ERROR"]          = "Error sound"
L["UI_SOUND_SUCCESS"]        = "Success sound"
L["UI_SOUND_PICKER"]         = "Picker sound"
L["UI_SHOW_MINIMAP"]         = "Show minimap button"
L["UI_SHOW_MINIMAP_TT"]      = "Show or hide the minimap button."
L["UI_LOCK_HIDDEN"]          = "Lock hidden frames"
L["UI_LOCK_HIDDEN_TT"]       = "Prevent accidentally showing hidden frames. They can only be restored via commands or the options panel."
L["UI_AUTO_HIDE"]            = "Auto-hide on login"
L["UI_AUTO_HIDE_TT"]         = "Automatically re-hide frames when you log in or reload UI."
L["UI_CONFIRM_HIDE"]         = "Confirm before hiding"
L["UI_CONFIRM_HIDE_TT"]      = "Show a confirmation dialog before hiding a frame."

L["UI_BTN_PICK"]             = "Pick Frame"
L["UI_BTN_SHOW_ALL"]         = "Show All"
L["UI_BTN_SAVE_PROFILE"]     = "Save Profile"
L["UI_BTN_LOAD_PROFILE"]     = "Load Profile"
L["UI_BTN_DELETE_PROFILE"]   = "Delete Profile"
L["UI_BTN_EXPORT"]           = "Export"
L["UI_BTN_IMPORT"]           = "Import"
L["UI_BTN_RESET"]            = "Reset All"
L["UI_BTN_CLOSE"]            = "Close"
L["UI_BTN_REMOVE"]           = "Show"
L["UI_BTN_REMOVE_TT"]        = "Click to show this hidden frame again."

L["UI_CONFIRM_RESET"]        = "Reset ALL settings?\nAll hidden frames will be shown and all profiles will be deleted."
L["UI_CONFIRM_YES"]          = "Yes, Reset"
L["UI_CONFIRM_NO"]           = "Cancel"

-- Audio hint descriptions
L["AUDIO_HIDE"]              = "Frame hidden"
L["AUDIO_SHOW"]              = "Frame restored"
L["AUDIO_ERROR"]             = "Action failed"
L["AUDIO_PICKER_START"]      = "Picker activated"
L["AUDIO_PICKER_STOP"]       = "Picker deactivated"
L["AUDIO_PROFILE_LOAD"]      = "Profile loaded"
L["AUDIO_RESET"]             = "Settings reset"
L["AUDIO_LOCK"]              = "Frames locked"
L["AUDIO_UNLOCK"]            = "Frames unlocked"

-- Config UI (realtime toggles)
L["CFG_HEADER_GENERAL"]      = "General Settings"
L["CFG_HEADER_FEEDBACK"]     = "Feedback & Notifications"
L["CFG_HEADER_SOUND"]        = "Sound Settings"
L["CFG_HEADER_ADVANCED"]     = "Advanced"
L["CFG_HEADER_QUICK"]        = "Quick Actions"
L["CFG_HEADER_STATUS"]       = "Live Status"

L["CFG_TOGGLE_ON"]           = "|cff00ff00ON|r"
L["CFG_TOGGLE_OFF"]          = "|cffff4444OFF|r"
L["CFG_CHANGED"]             = "Setting changed: |cffffffff%s|r %s"

L["CFG_MINIMAP_BTN"]         = "Minimap Button"
L["CFG_MINIMAP_BTN_TT"]      = "Show or hide the minimap button. Takes effect immediately."
L["CFG_LOCK_MODE"]           = "Lock Mode"
L["CFG_LOCK_MODE_TT"]        = "When locked, hidden frames cannot be accidentally restored. Only the config panel or /ha unlock can restore them."
L["CFG_AUTO_REHIDE"]         = "Auto Re-Hide on Login"
L["CFG_AUTO_REHIDE_TT"]      = "Automatically re-hide all saved frames when you log in or reload the UI."
L["CFG_CONFIRM_DLG"]         = "Confirm Before Hiding"
L["CFG_CONFIRM_DLG_TT"]      = "Show a confirmation popup before hiding a frame via the picker."

L["CFG_SOUND_MASTER"]        = "Sound Effects"
L["CFG_SOUND_MASTER_TT"]     = "Master toggle for all addon sound effects. Disable to silence everything."
L["CFG_CHAT_MSG"]            = "Chat Messages"
L["CFG_CHAT_MSG_TT"]         = "Show colored status messages in the chat window for hide/show/lock/profile actions."
L["CFG_SCREEN_MSG"]          = "On-Screen Text"
L["CFG_SCREEN_MSG_TT"]       = "Show floating text notifications on screen (like error messages) for actions."
L["CFG_ERROR_VOICE"]         = "Error Voice / Speech"
L["CFG_ERROR_VOICE_TT"]      = "Play Blizzard's error voice for critical errors (combat lockdown, protected frames)."

L["CFG_SND_ON_HIDE"]         = "Sound: Hide Frame"
L["CFG_SND_ON_HIDE_TT"]      = "Play this sound when a frame is hidden."
L["CFG_SND_ON_SHOW"]         = "Sound: Show Frame"
L["CFG_SND_ON_SHOW_TT"]      = "Play this sound when a frame is shown."
L["CFG_SND_ON_ERROR"]        = "Sound: Error"
L["CFG_SND_ON_ERROR_TT"]     = "Play this sound when an error occurs."
L["CFG_SND_ON_SUCCESS"]      = "Sound: Success"
L["CFG_SND_ON_SUCCESS_TT"]   = "Play this sound on successful actions (profile saved, etc)."
L["CFG_SND_ON_PICKER"]       = "Sound: Picker Start"
L["CFG_SND_ON_PICKER_TT"]    = "Play this sound when the frame picker is activated."
L["CFG_SND_ON_LOCK"]         = "Sound: Lock/Unlock"
L["CFG_SND_ON_LOCK_TT"]      = "Play this sound when frames are locked or unlocked."

L["CFG_INDIVIDUAL_SOUNDS"]   = "Per-Action Sounds"
L["CFG_INDIVIDUAL_SOUNDS_TT"]= "Enable or disable individual sound effects per action type."
L["CFG_SND_HIDE_ENABLED"]    = "Hide Sound"
L["CFG_SND_SHOW_ENABLED"]    = "Show Sound"
L["CFG_SND_ERROR_ENABLED"]   = "Error Sound"
L["CFG_SND_SUCCESS_ENABLED"] = "Success Sound"
L["CFG_SND_PICKER_ENABLED"]  = "Picker Sound"
L["CFG_SND_LOCK_ENABLED"]    = "Lock Sound"

L["CFG_TEST_SOUND"]          = "Test"
L["CFG_PREVIEW"]             = "Preview"

L["CFG_STATUS_FRAMES"]       = "Hidden Frames"
L["CFG_STATUS_PROFILES"]     = "Saved Profiles"
L["CFG_STATUS_LOCK"]         = "Lock Mode"
L["CFG_STATUS_COMBAT"]       = "In Combat"

L["CFG_APPLY_INSTANT"]       = "All changes apply |cff00ff00instantly|r - no reload required!"

---------------------------------------------------------------------------
-- German (deDE)
---------------------------------------------------------------------------
if locale == "deDE" then
    -- General
    L["ADDON_LOADED"]            = "|cff00cc66Hide|rAnything|r v%s geladen. Tippe |cff00cc66/ha|r für Hilfe."

    -- Slash command help
    L["HELP_HEADER"]             = "|cff00cc66HideAnything|r Befehle:"
    L["HELP_TOGGLE"]             = "|cff00cc66/ha toggle|r - Optionsfenster öffnen/schließen"
    L["HELP_PICK"]               = "|cff00cc66/ha pick|r - Frame-Picker starten"
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

    -- Frame Picker
    L["PICKER_STARTED"]          = "Frame-Picker |cff00ff00aktiviert|r. Fahre über ein UI-Element und |cff00cc66LINKSKLICK|r zum Verstecken. |cffff0000RECHTSKLICK|r oder |cffff0000ESC|r zum Abbrechen."
    L["PICKER_STOPPED"]          = "Frame-Picker |cffff4444deaktiviert|r."
    L["PICKER_TOOLTIP_TITLE"]    = "HideAnything - Frame-Picker"
    L["PICKER_TOOLTIP_NAME"]     = "Frame: |cffffffff%s|r"
    L["PICKER_TOOLTIP_TYPE"]     = "Typ: |cffffffff%s|r"
    L["PICKER_TOOLTIP_PARENT"]   = "Eltern: |cffffffff%s|r"
    L["PICKER_TOOLTIP_SIZE"]     = "Größe: |cffffffff%.0f x %.0f|r"
    L["PICKER_TOOLTIP_HINT"]     = "|cff00cc66Linksklick|r zum Verstecken  |  |cffff4444Rechtsklick|r zum Abbrechen"
    L["PICKER_NO_FRAME"]         = "Kein gültiger Frame unter dem Cursor gefunden."
    L["PICKER_PROTECTED"]        = "Kann |cffff4444%s|r nicht verstecken - dieser Frame ist von Blizzard geschützt."
    L["PICKER_ALREADY_HIDDEN"]   = "|cffffffff%s|r ist bereits versteckt."

    -- Hide / Show
    L["FRAME_HIDDEN"]            = "Versteckt: |cffff8800%s|r"
    L["FRAME_SHOWN"]             = "Angezeigt: |cff00ff00%s|r"
    L["FRAME_NOT_FOUND"]         = "Frame |cffff4444%s|r nicht gefunden."
    L["FRAME_NOT_HIDDEN"]        = "Frame |cffffffff%s|r ist momentan nicht versteckt."
    L["ALL_FRAMES_SHOWN"]        = "Alle |cff00ff00%d|r versteckten Frames sind jetzt wieder sichtbar."
    L["NO_FRAMES_HIDDEN"]        = "Es sind keine Frames versteckt."

    -- List
    L["LIST_HEADER"]             = "|cff00cc66Versteckte Frames|r (%d):"
    L["LIST_ENTRY"]              = "  |cffff8800%d.|r %s"

    -- Profiles
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

    -- Lock
    L["FRAMES_LOCKED"]           = "Alle versteckten Frames sind jetzt |cffff4444gesperrt|r."
    L["FRAMES_UNLOCKED"]         = "Alle versteckten Frames sind jetzt |cff00ff00entsperrt|r."

    -- Reset
    L["RESET_CONFIRM"]           = "Bist du sicher, dass du |cffff4444alle|r HideAnything-Einstellungen zurücksetzen willst? Tippe |cff00cc66/ha reset confirm|r zum Bestätigen."
    L["RESET_DONE"]              = "Alle Einstellungen wurden auf |cffff4444Standardwerte|r zurückgesetzt."

    -- Status
    L["STATUS_HEADER"]           = "|cff00cc66HideAnything|r Status:"
    L["STATUS_HIDDEN_COUNT"]     = "Versteckte Frames: |cffffffff%d|r"
    L["STATUS_LOCKED"]           = "Sperrmodus: |cffff4444GESPERRT|r"
    L["STATUS_UNLOCKED"]         = "Sperrmodus: |cff00ff00ENTSPERRT|r"
    L["STATUS_PROFILE"]          = "Aktives Profil: |cffffffff%s|r"
    L["STATUS_MINIMAP"]          = "Minimap-Button: |cffffffff%s|r"
    L["STATUS_ON"]               = "|cff00ff00AN|r"
    L["STATUS_OFF"]              = "|cffff4444AUS|r"
    L["STATUS_FEEDBACK_SOUND"]   = "Sound-Feedback: |cffffffff%s|r"
    L["STATUS_FEEDBACK_CHAT"]    = "Chat-Feedback: |cffffffff%s|r"
    L["STATUS_FEEDBACK_SCREEN"]  = "Bildschirm-Feedback: |cffffffff%s|r"

    -- Errors
    L["ERROR_COMBAT"]            = "|cffff4444Fehler|r: UI-Elemente können im Kampf nicht verändert werden. Versuche es nach dem Kampf erneut."
    L["ERROR_UNKNOWN_CMD"]       = "|cffff4444Unbekannter Befehl|r: |cffffffff%s|r. Tippe |cff00cc66/ha|r für Hilfe."
    L["ERROR_FRAME_NIL"]         = "|cffff4444Fehler|r: Frame-Referenz ist nil."
    L["ERROR_FRAME_PROTECTED"]   = "|cffff4444Fehler|r: Frame |cffffffff%s|r ist von Blizzard geschützt und kann im Kampf nicht verändert werden."
    L["ERROR_DB_CORRUPT"]        = "|cffff4444Fehler|r: Gespeicherte Daten scheinen beschädigt zu sein. Setze auf Standardwerte zurück."
    L["ERROR_HOOK_FAILED"]       = "|cffff4444Warnung|r: Frame |cffffffff%s|r konnte nicht gehookt werden. Er könnte nach einem Reload wieder erscheinen."
    L["ERROR_EXPORT_FAILED"]     = "|cffff4444Fehler|r: Export fehlgeschlagen. Profildaten konnten nicht serialisiert werden."
    L["ERROR_IMPORT_PARSE"]      = "|cffff4444Fehler|r: Import fehlgeschlagen. Datenformat nicht erkannt."

    -- Minimap
    L["MINIMAP_SHOWN"]           = "Minimap-Button |cff00ff00angezeigt|r."
    L["MINIMAP_HIDDEN"]          = "Minimap-Button |cffff4444versteckt|r."
    L["MINIMAP_TOOLTIP_TITLE"]   = "|cff00cc66Hide|rAnything"
    L["MINIMAP_TOOLTIP_LEFT"]    = "|cff00cc66Linksklick|r: Optionen umschalten"
    L["MINIMAP_TOOLTIP_RIGHT"]   = "|cffff8800Rechtsklick|r: Frame-Picker"
    L["MINIMAP_TOOLTIP_SHIFT"]   = "|cff8888ffShift-Klick|r: Alle versteckten Frames anzeigen"
    L["MINIMAP_TOOLTIP_DRAG"]    = "|cff888888Ziehen|r zum Verschieben"

    -- Options Panel / UI
    L["UI_TITLE"]                = "HideAnything Optionen"
    L["UI_GENERAL"]              = "Allgemein"
    L["UI_FEEDBACK"]             = "Feedback"
    L["UI_HIDDEN_FRAMES"]        = "Versteckte Frames"
    L["UI_PROFILES"]             = "Profile"
    L["UI_ABOUT"]                = "Über"

    L["UI_ENABLE_SOUND"]         = "Sound-Feedback aktivieren"
    L["UI_ENABLE_SOUND_TT"]      = "Spielt einen Sound beim Verstecken oder Anzeigen von Frames."
    L["UI_ENABLE_CHAT"]          = "Chat-Nachrichten aktivieren"
    L["UI_ENABLE_CHAT_TT"]       = "Zeigt Statusmeldungen im Chat-Fenster an."
    L["UI_ENABLE_SCREEN"]        = "Bildschirm-Meldungen aktivieren"
    L["UI_ENABLE_SCREEN_TT"]     = "Zeigt schwebenden Text auf dem Bildschirm beim Verstecken/Anzeigen."
    L["UI_ENABLE_ERROR"]         = "Fehler-Sprache aktivieren"
    L["UI_ENABLE_ERROR_TT"]      = "Spielt Blizzard-Fehlerstimme bei wichtigen Fehlern."
    L["UI_SOUND_HIDE"]           = "Versteck-Sound"
    L["UI_SOUND_SHOW"]           = "Anzeige-Sound"
    L["UI_SOUND_ERROR"]          = "Fehler-Sound"
    L["UI_SOUND_SUCCESS"]        = "Erfolgs-Sound"
    L["UI_SOUND_PICKER"]         = "Picker-Sound"
    L["UI_SHOW_MINIMAP"]         = "Minimap-Button anzeigen"
    L["UI_SHOW_MINIMAP_TT"]      = "Zeigt oder versteckt den Minimap-Button."
    L["UI_LOCK_HIDDEN"]          = "Versteckte Frames sperren"
    L["UI_LOCK_HIDDEN_TT"]       = "Verhindert versehentliches Anzeigen versteckter Frames."
    L["UI_AUTO_HIDE"]            = "Automatisch verstecken beim Login"
    L["UI_AUTO_HIDE_TT"]         = "Versteckt Frames automatisch beim Einloggen oder UI-Reload."
    L["UI_CONFIRM_HIDE"]         = "Vor dem Verstecken bestätigen"
    L["UI_CONFIRM_HIDE_TT"]      = "Zeigt einen Bestätigungsdialog vor dem Verstecken eines Frames."

    L["UI_BTN_PICK"]             = "Frame wählen"
    L["UI_BTN_SHOW_ALL"]         = "Alle anzeigen"
    L["UI_BTN_SAVE_PROFILE"]     = "Profil speichern"
    L["UI_BTN_LOAD_PROFILE"]     = "Profil laden"
    L["UI_BTN_DELETE_PROFILE"]   = "Profil löschen"
    L["UI_BTN_EXPORT"]           = "Exportieren"
    L["UI_BTN_IMPORT"]           = "Importieren"
    L["UI_BTN_RESET"]            = "Alles zurücksetzen"
    L["UI_BTN_CLOSE"]            = "Schließen"
    L["UI_BTN_REMOVE"]           = "Anzeigen"
    L["UI_BTN_REMOVE_TT"]        = "Klicke, um diesen versteckten Frame wieder anzuzeigen."

    L["UI_CONFIRM_RESET"]        = "ALLE Einstellungen zurücksetzen?\nAlle versteckten Frames werden angezeigt und alle Profile gelöscht."
    L["UI_CONFIRM_YES"]          = "Ja, zurücksetzen"
    L["UI_CONFIRM_NO"]           = "Abbrechen"

    -- Audio hint descriptions
    L["AUDIO_HIDE"]              = "Frame versteckt"
    L["AUDIO_SHOW"]              = "Frame wiederhergestellt"
    L["AUDIO_ERROR"]             = "Aktion fehlgeschlagen"
    L["AUDIO_PICKER_START"]      = "Picker aktiviert"
    L["AUDIO_PICKER_STOP"]       = "Picker deaktiviert"
    L["AUDIO_PROFILE_LOAD"]      = "Profil geladen"
    L["AUDIO_RESET"]             = "Einstellungen zurückgesetzt"
    L["AUDIO_LOCK"]              = "Frames gesperrt"
    L["AUDIO_UNLOCK"]            = "Frames entsperrt"

    -- Config UI (realtime toggles)
    L["CFG_HEADER_GENERAL"]      = "Allgemeine Einstellungen"
    L["CFG_HEADER_FEEDBACK"]     = "Feedback & Benachrichtigungen"
    L["CFG_HEADER_SOUND"]        = "Sound-Einstellungen"
    L["CFG_HEADER_ADVANCED"]     = "Erweitert"
    L["CFG_HEADER_QUICK"]        = "Schnellaktionen"
    L["CFG_HEADER_STATUS"]       = "Live-Status"

    L["CFG_TOGGLE_ON"]           = "|cff00ff00AN|r"
    L["CFG_TOGGLE_OFF"]          = "|cffff4444AUS|r"
    L["CFG_CHANGED"]             = "Einstellung geändert: |cffffffff%s|r %s"

    L["CFG_MINIMAP_BTN"]         = "Minimap-Button"
    L["CFG_MINIMAP_BTN_TT"]      = "Zeigt oder versteckt den Minimap-Button. Wirkt sofort."
    L["CFG_LOCK_MODE"]           = "Sperrmodus"
    L["CFG_LOCK_MODE_TT"]        = "Wenn gesperrt, können versteckte Frames nicht versehentlich wiederhergestellt werden."
    L["CFG_AUTO_REHIDE"]         = "Automatisch beim Login verstecken"
    L["CFG_AUTO_REHIDE_TT"]      = "Versteckt alle gespeicherten Frames automatisch beim Einloggen oder UI-Reload."
    L["CFG_CONFIRM_DLG"]         = "Vor dem Verstecken bestätigen"
    L["CFG_CONFIRM_DLG_TT"]      = "Zeigt ein Bestätigungsfenster bevor ein Frame per Picker versteckt wird."

    L["CFG_SOUND_MASTER"]        = "Sound-Effekte"
    L["CFG_SOUND_MASTER_TT"]     = "Hauptschalter für alle Sound-Effekte. Deaktivieren um alles stumm zu schalten."
    L["CFG_CHAT_MSG"]            = "Chat-Nachrichten"
    L["CFG_CHAT_MSG_TT"]         = "Zeigt farbige Statusmeldungen im Chat für Verstecken/Anzeigen/Sperren/Profil-Aktionen."
    L["CFG_SCREEN_MSG"]          = "Bildschirm-Text"
    L["CFG_SCREEN_MSG_TT"]       = "Zeigt schwebende Textmeldungen auf dem Bildschirm für Aktionen."
    L["CFG_ERROR_VOICE"]         = "Fehler-Stimme / Sprache"
    L["CFG_ERROR_VOICE_TT"]      = "Spielt Blizzards Fehlerstimme bei kritischen Fehlern (Kampfsperre, geschützte Frames)."

    L["CFG_SND_ON_HIDE"]         = "Sound: Frame verstecken"
    L["CFG_SND_ON_HIDE_TT"]      = "Spielt diesen Sound wenn ein Frame versteckt wird."
    L["CFG_SND_ON_SHOW"]         = "Sound: Frame anzeigen"
    L["CFG_SND_ON_SHOW_TT"]      = "Spielt diesen Sound wenn ein Frame angezeigt wird."
    L["CFG_SND_ON_ERROR"]        = "Sound: Fehler"
    L["CFG_SND_ON_ERROR_TT"]     = "Spielt diesen Sound wenn ein Fehler auftritt."
    L["CFG_SND_ON_SUCCESS"]      = "Sound: Erfolg"
    L["CFG_SND_ON_SUCCESS_TT"]   = "Spielt diesen Sound bei erfolgreichen Aktionen."
    L["CFG_SND_ON_PICKER"]       = "Sound: Picker-Start"
    L["CFG_SND_ON_PICKER_TT"]    = "Spielt diesen Sound wenn der Frame-Picker aktiviert wird."
    L["CFG_SND_ON_LOCK"]         = "Sound: Sperren/Entsperren"
    L["CFG_SND_ON_LOCK_TT"]      = "Spielt diesen Sound wenn Frames gesperrt oder entsperrt werden."

    L["CFG_INDIVIDUAL_SOUNDS"]   = "Individuelle Sounds"
    L["CFG_INDIVIDUAL_SOUNDS_TT"]= "Einzelne Sound-Effekte pro Aktionstyp ein-/ausschalten."
    L["CFG_SND_HIDE_ENABLED"]    = "Versteck-Sound"
    L["CFG_SND_SHOW_ENABLED"]    = "Anzeige-Sound"
    L["CFG_SND_ERROR_ENABLED"]   = "Fehler-Sound"
    L["CFG_SND_SUCCESS_ENABLED"] = "Erfolgs-Sound"
    L["CFG_SND_PICKER_ENABLED"]  = "Picker-Sound"
    L["CFG_SND_LOCK_ENABLED"]    = "Sperr-Sound"

    L["CFG_TEST_SOUND"]          = "Test"
    L["CFG_PREVIEW"]             = "Vorschau"

    L["CFG_STATUS_FRAMES"]       = "Versteckte Frames"
    L["CFG_STATUS_PROFILES"]     = "Gespeicherte Profile"
    L["CFG_STATUS_LOCK"]         = "Sperrmodus"
    L["CFG_STATUS_COMBAT"]       = "Im Kampf"

    L["CFG_APPLY_INSTANT"]       = "Alle Änderungen gelten |cff00ff00sofort|r - kein Reload nötig!"
end
