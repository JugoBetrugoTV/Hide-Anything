--[[
    HideAnything - UI.lua
    Main options panel with tabs: General, Feedback, Hidden Frames, Profiles, About
]]

local AddonName, HA = ...

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------
local PANEL_WIDTH  = 520
local PANEL_HEIGHT = 480
local TAB_HEIGHT   = 28
local CONTENT_INSET = 12
local ROW_HEIGHT   = 26

---------------------------------------------------------------------------
-- Main panel frame
---------------------------------------------------------------------------
local panel = CreateFrame("Frame", "HideAnythingOptionsFrame", UIParent, "BackdropTemplate")
panel:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
panel:SetPoint("CENTER")
panel:SetMovable(true)
panel:EnableMouse(true)
panel:SetClampedToScreen(true)
panel:SetFrameStrata("DIALOG")
panel:SetFrameLevel(100)
panel:Hide()

panel:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile     = true, tileSize = 32, edgeSize = 32,
    insets   = { left = 8, right = 8, top = 8, bottom = 8 },
})

-- Title bar
local titleBar = CreateFrame("Frame", nil, panel)
titleBar:SetHeight(32)
titleBar:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
titleBar:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
titleBar:EnableMouse(true)
titleBar:RegisterForDrag("LeftButton")
titleBar:SetScript("OnDragStart", function() panel:StartMoving() end)
titleBar:SetScript("OnDragStop", function() panel:StopMovingOrSizing() end)

local titleText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("TOP", panel, "TOP", 0, -12)

-- Close button
local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -2, -2)
closeBtn:SetScript("OnClick", function() panel:Hide() end)

-- Version text
local versionText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
versionText:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -36, -16)
versionText:SetTextColor(0.5, 0.5, 0.5)

---------------------------------------------------------------------------
-- Tab system
---------------------------------------------------------------------------
local tabs = {}
local tabContents = {}
local activeTab = nil

local function CreateTab(index, text)
    local tab = CreateFrame("Button", "HideAnythingTab" .. index, panel, "BackdropTemplate")
    tab:SetSize(95, TAB_HEIGHT)
    tab:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 16, edgeSize = 12,
        insets   = { left = 3, right = 3, top = 3, bottom = 3 },
    })

    local label = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER")
    label:SetText(text)
    tab.label = label

    tab:SetScript("OnClick", function()
        HA:SelectTab(index)
    end)

    tabs[index] = tab
    return tab
end

local function CreateTabContent(index)
    local content = CreateFrame("Frame", "HideAnythingTabContent" .. index, panel)
    content:SetPoint("TOPLEFT", panel, "TOPLEFT", CONTENT_INSET, -72)
    content:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -CONTENT_INSET, CONTENT_INSET)
    content:Hide()
    tabContents[index] = content
    return content
end

function HA:SelectTab(index)
    for i, tab in pairs(tabs) do
        if i == index then
            tab:SetBackdropColor(0, 0.6, 0.3, 0.5)
            tab.label:SetTextColor(1, 1, 1)
            tabContents[i]:Show()
        else
            tab:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
            tab.label:SetTextColor(0.6, 0.6, 0.6)
            tabContents[i]:Hide()
        end
    end
    activeTab = index

    -- Refresh hidden frames list when switching to tab 3
    if index == 3 then
        self:RefreshHiddenList()
    end
end

---------------------------------------------------------------------------
-- Helper: create a checkbox
---------------------------------------------------------------------------
local function CreateCheckbox(parent, yOffset, label, tooltipText, settingKey)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, yOffset)

    local text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    text:SetText(label)

    cb:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        HA:SetSetting(settingKey, checked)
        if checked then
            HA:PlayFeedbackSound("lock")
        else
            HA:PlayFeedbackSound("unlock")
        end
    end)

    if tooltipText then
        cb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(label, 0, 0.8, 0.4)
            GameTooltip:AddLine(tooltipText, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    cb.settingKey = settingKey
    return cb
end

---------------------------------------------------------------------------
-- Helper: create a button
---------------------------------------------------------------------------
local function CreateButton(parent, xOffset, yOffset, width, text, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width, 24)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, yOffset)
    btn:SetText(text)
    btn:SetScript("OnClick", onClick)
    return btn
end

---------------------------------------------------------------------------
-- Build the panel contents
---------------------------------------------------------------------------
local function BuildPanel()
    local L = HA.L

    titleText:SetText(L["UI_TITLE"])
    versionText:SetText("v" .. HA.version)

    -- Create tabs
    local tabNames = { L["UI_GENERAL"], L["UI_FEEDBACK"], L["UI_HIDDEN_FRAMES"], L["UI_PROFILES"], L["UI_ABOUT"] }
    for i, name in ipairs(tabNames) do
        local tab = CreateTab(i, name)
        tab:SetPoint("TOPLEFT", panel, "TOPLEFT", CONTENT_INSET + (i - 1) * 99, -38)
        CreateTabContent(i)
    end

    ---------------------------------------------------------------------------
    -- Tab 1: General
    ---------------------------------------------------------------------------
    local general = tabContents[1]

    local cb1 = CreateCheckbox(general, -8,  L["UI_SHOW_MINIMAP"],  L["UI_SHOW_MINIMAP_TT"],  "showMinimap")
    local cb2 = CreateCheckbox(general, -36, L["UI_LOCK_HIDDEN"],   L["UI_LOCK_HIDDEN_TT"],   "locked")
    local cb3 = CreateCheckbox(general, -64, L["UI_AUTO_HIDE"],     L["UI_AUTO_HIDE_TT"],     "autoHide")
    local cb4 = CreateCheckbox(general, -92, L["UI_CONFIRM_HIDE"],  L["UI_CONFIRM_HIDE_TT"],  "confirmHide")

    -- Buttons
    CreateButton(general, 8, -140, 130, L["UI_BTN_PICK"], function()
        panel:Hide()
        HA:StartPicker()
    end)

    CreateButton(general, 146, -140, 130, L["UI_BTN_SHOW_ALL"], function()
        HA:ShowAllFrames()
    end)

    CreateButton(general, 284, -140, 130, L["UI_BTN_RESET"], function()
        StaticPopup_Show("HIDEANYTHING_CONFIRM_RESET")
    end)

    -- Store checkboxes for refresh
    general.checkboxes = { cb1, cb2, cb3, cb4 }

    ---------------------------------------------------------------------------
    -- Tab 2: Feedback
    ---------------------------------------------------------------------------
    local feedback = tabContents[2]

    local fb1 = CreateCheckbox(feedback, -8,  L["UI_ENABLE_SOUND"],  L["UI_ENABLE_SOUND_TT"],  "soundEnabled")
    local fb2 = CreateCheckbox(feedback, -36, L["UI_ENABLE_CHAT"],   L["UI_ENABLE_CHAT_TT"],   "chatEnabled")
    local fb3 = CreateCheckbox(feedback, -64, L["UI_ENABLE_SCREEN"], L["UI_ENABLE_SCREEN_TT"], "screenEnabled")
    local fb4 = CreateCheckbox(feedback, -92, L["UI_ENABLE_ERROR"],  L["UI_ENABLE_ERROR_TT"],  "errorSpeech")

    -- Sound test section
    local soundHeader = feedback:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    soundHeader:SetPoint("TOPLEFT", feedback, "TOPLEFT", 12, -132)
    soundHeader:SetText("|cff00cc66Sound Test:|r")

    local soundNames = { "hide", "show", "error", "success", "pickerStart", "lock" }
    local soundLabels = {
        L["UI_SOUND_HIDE"], L["UI_SOUND_SHOW"], L["UI_SOUND_ERROR"],
        L["UI_SOUND_SUCCESS"], L["UI_SOUND_PICKER"], "Lock/Unlock"
    }
    for i, key in ipairs(soundNames) do
        local row = math.ceil(i / 3)
        local col = ((i - 1) % 3)
        CreateButton(feedback, 12 + col * 160, -150 - (row - 1) * 32, 150, soundLabels[i], function()
            local sounds = HA.db and HA.db.settings and HA.db.settings.sounds
            if sounds and sounds[key] then
                PlaySound(sounds[key], "Master")
            end
        end)
    end

    feedback.checkboxes = { fb1, fb2, fb3, fb4 }

    ---------------------------------------------------------------------------
    -- Tab 3: Hidden Frames (scrollable list)
    ---------------------------------------------------------------------------
    local hidden = tabContents[3]

    local listHeader = hidden:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    listHeader:SetPoint("TOPLEFT", hidden, "TOPLEFT", 12, -8)
    hidden.listHeader = listHeader

    -- Scroll frame for the list
    local scrollFrame = CreateFrame("ScrollFrame", "HideAnythingScrollFrame", hidden, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", hidden, "TOPLEFT", 8, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", hidden, "BOTTOMRIGHT", -28, 8)

    local scrollChild = CreateFrame("Frame", "HideAnythingScrollChild", scrollFrame)
    scrollChild:SetSize(PANEL_WIDTH - 60, 1) -- height grows dynamically
    scrollFrame:SetScrollChild(scrollChild)

    hidden.scrollChild = scrollChild
    hidden.rows = {}

    ---------------------------------------------------------------------------
    -- Tab 4: Profiles
    ---------------------------------------------------------------------------
    local profiles = tabContents[4]

    -- Profile name input
    local inputLabel = profiles:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    inputLabel:SetPoint("TOPLEFT", profiles, "TOPLEFT", 12, -12)
    inputLabel:SetText("|cff00cc66Profile Name:|r")

    local inputBox = CreateFrame("EditBox", "HideAnythingProfileInput", profiles, "InputBoxTemplate")
    inputBox:SetSize(200, 24)
    inputBox:SetPoint("TOPLEFT", profiles, "TOPLEFT", 120, -8)
    inputBox:SetAutoFocus(false)
    inputBox:SetMaxLetters(30)
    inputBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    inputBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    profiles.inputBox = inputBox

    -- Profile buttons
    CreateButton(profiles, 12,  -44, 120, L["UI_BTN_SAVE_PROFILE"], function()
        local name = inputBox:GetText()
        if name and name ~= "" then
            HA:SaveProfile(name)
        else
            HA:Print(L["PROFILE_NAME_REQUIRED"])
        end
    end)

    CreateButton(profiles, 140, -44, 120, L["UI_BTN_LOAD_PROFILE"], function()
        local name = inputBox:GetText()
        if name and name ~= "" then
            HA:LoadProfile(name)
        else
            HA:Print(L["PROFILE_NAME_REQUIRED"])
        end
    end)

    CreateButton(profiles, 268, -44, 120, L["UI_BTN_DELETE_PROFILE"], function()
        local name = inputBox:GetText()
        if name and name ~= "" then
            HA:DeleteProfile(name)
        else
            HA:Print(L["PROFILE_NAME_REQUIRED"])
        end
    end)

    CreateButton(profiles, 12,  -76, 120, L["UI_BTN_EXPORT"], function()
        local name = inputBox:GetText()
        if name and name ~= "" then
            HA:ExportProfile(name)
        else
            HA:Print(L["PROFILE_NAME_REQUIRED"])
        end
    end)

    CreateButton(profiles, 140, -76, 120, L["UI_BTN_IMPORT"], function()
        HA:ShowImportDialog()
    end)

    -- Profile list
    local profileListHeader = profiles:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    profileListHeader:SetPoint("TOPLEFT", profiles, "TOPLEFT", 12, -116)
    profiles.profileListHeader = profileListHeader

    local profileScroll = CreateFrame("ScrollFrame", "HideAnythingProfileScrollFrame", profiles, "UIPanelScrollFrameTemplate")
    profileScroll:SetPoint("TOPLEFT", profiles, "TOPLEFT", 8, -136)
    profileScroll:SetPoint("BOTTOMRIGHT", profiles, "BOTTOMRIGHT", -28, 8)

    local profileScrollChild = CreateFrame("Frame", nil, profileScroll)
    profileScrollChild:SetSize(PANEL_WIDTH - 60, 1)
    profileScroll:SetScrollChild(profileScrollChild)

    profiles.scrollChild = profileScrollChild
    profiles.rows = {}

    ---------------------------------------------------------------------------
    -- Tab 5: About
    ---------------------------------------------------------------------------
    local about = tabContents[5]

    local aboutTitle = about:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    aboutTitle:SetPoint("TOPLEFT", about, "TOPLEFT", 12, -12)
    aboutTitle:SetText("|cff00cc66Hide|r|cffffffffAnything|r")

    local aboutVersion = about:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    aboutVersion:SetPoint("TOPLEFT", aboutTitle, "BOTTOMLEFT", 0, -8)
    aboutVersion:SetText(L["VERSION"] .. ": |cffffffff" .. HA.version .. "|r")

    local aboutAuthor = about:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    aboutAuthor:SetPoint("TOPLEFT", aboutVersion, "BOTTOMLEFT", 0, -8)
    aboutAuthor:SetText("Author: |cffffffffJugoBetrugoTV|r")

    local aboutDesc = about:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    aboutDesc:SetPoint("TOPLEFT", aboutAuthor, "BOTTOMLEFT", 0, -16)
    aboutDesc:SetWidth(PANEL_WIDTH - 40)
    aboutDesc:SetJustifyH("LEFT")
    aboutDesc:SetText(
        "|cff00cc66Hide Anything|r allows you to hide any UI element in World of Warcraft.\n\n" ..
        "Features:\n" ..
        "  - |cffffffffClick-to-hide|r frame picker with visual highlight\n" ..
        "  - |cffffffffPersistent|r hidden frames across sessions\n" ..
        "  - |cffffffffProfile system|r for saving/loading configurations\n" ..
        "  - |cffffffffExport/Import|r profiles to share with friends\n" ..
        "  - |cffffffffAudio feedback|r with customizable sounds\n" ..
        "  - |cffffffffChat & screen|r messages for all actions\n" ..
        "  - |cffffffffLock mode|r to prevent accidental changes\n" ..
        "  - |cffffffffCombat protection|r with automatic queue\n" ..
        "  - |cffffffffMinimap button|r for quick access\n" ..
        "  - |cffffffffGerman & English|r localization\n\n" ..
        "Commands: |cff00cc66/ha|r or |cff00cc66/hideanything|r"
    )

    ---------------------------------------------------------------------------
    -- Select default tab
    ---------------------------------------------------------------------------
    HA:SelectTab(1)
end

---------------------------------------------------------------------------
-- Refresh checkboxes from saved settings
---------------------------------------------------------------------------
local function RefreshCheckboxes()
    for _, tabContent in pairs(tabContents) do
        if tabContent.checkboxes then
            for _, cb in ipairs(tabContent.checkboxes) do
                if cb.settingKey then
                    cb:SetChecked(HA:GetSetting(cb.settingKey) and true or false)
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- Refresh hidden frames list (Tab 3)
---------------------------------------------------------------------------
function HA:RefreshHiddenList()
    local L = self.L
    local content = tabContents[3]
    if not content then return end

    local scrollChild = content.scrollChild
    local count = self:GetHiddenCount()

    content.listHeader:SetText(L["LIST_HEADER"]:format(count))

    -- Clear old rows
    for _, row in ipairs(content.rows) do
        row:Hide()
    end
    wipe(content.rows)

    -- Build rows
    local i = 0
    if self.db and self.db.hiddenFrames then
        for frameName, _ in pairs(self.db.hiddenFrames) do
            local row = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
            row:SetSize(scrollChild:GetWidth(), ROW_HEIGHT)
            row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(i * (ROW_HEIGHT + 2)))

            if i % 2 == 0 then
                row:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background" })
                row:SetBackdropColor(0.15, 0.15, 0.15, 0.5)
            end

            local nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameLabel:SetPoint("LEFT", row, "LEFT", 8, 0)
            nameLabel:SetText("|cffff8800" .. (i + 1) .. ".|r " .. frameName)
            nameLabel:SetWidth(scrollChild:GetWidth() - 90)
            nameLabel:SetJustifyH("LEFT")

            local showBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            showBtn:SetSize(70, 20)
            showBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
            showBtn:SetText(L["UI_BTN_REMOVE"])
            showBtn:SetScript("OnClick", function()
                HA:ShowFrame(frameName)
            end)

            HA:AddTooltip(showBtn, L["UI_BTN_REMOVE"], L["UI_BTN_REMOVE_TT"])

            table.insert(content.rows, row)
            i = i + 1
        end
    end

    scrollChild:SetHeight(math.max(1, i * (ROW_HEIGHT + 2)))
end

---------------------------------------------------------------------------
-- Refresh profile list (Tab 4)
---------------------------------------------------------------------------
function HA:RefreshProfileList()
    local L = self.L
    local content = tabContents[4]
    if not content then return end

    local scrollChild = content.scrollChild

    -- Count profiles
    local profileCount = 0
    if self.db and self.db.profiles then
        for _ in pairs(self.db.profiles) do
            profileCount = profileCount + 1
        end
    end

    content.profileListHeader:SetText(L["PROFILE_LIST_HEADER"]:format(profileCount))

    -- Clear old rows
    for _, row in ipairs(content.rows) do
        row:Hide()
    end
    wipe(content.rows)

    if profileCount == 0 then
        local emptyLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        emptyLabel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 8, 0)
        emptyLabel:SetText(L["PROFILE_NO_PROFILES"])
        emptyLabel:SetTextColor(0.5, 0.5, 0.5)

        local emptyRow = CreateFrame("Frame", nil, scrollChild)
        emptyRow:SetSize(1, 1)
        emptyRow.fontString = emptyLabel
        table.insert(content.rows, emptyRow)
        return
    end

    local i = 0
    for profileName, profileData in pairs(self.db.profiles) do
        local frameCount = 0
        if profileData.hiddenFrames then
            for _ in pairs(profileData.hiddenFrames) do
                frameCount = frameCount + 1
            end
        end

        local row = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        row:SetSize(scrollChild:GetWidth(), ROW_HEIGHT)
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(i * (ROW_HEIGHT + 2)))

        if i % 2 == 0 then
            row:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background" })
            row:SetBackdropColor(0.15, 0.15, 0.15, 0.5)
        end

        local nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameLabel:SetPoint("LEFT", row, "LEFT", 8, 0)
        nameLabel:SetText("|cff00cc66" .. profileName .. "|r |cff888888(" .. frameCount .. " frames)|r")

        -- Load button
        local loadBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        loadBtn:SetSize(50, 20)
        loadBtn:SetPoint("RIGHT", row, "RIGHT", -60, 0)
        loadBtn:SetText("Load")
        loadBtn:SetScript("OnClick", function()
            HA:LoadProfile(profileName)
            content.inputBox:SetText(profileName)
        end)

        -- Delete button
        local delBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        delBtn:SetSize(50, 20)
        delBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        delBtn:SetText("Del")
        delBtn:SetScript("OnClick", function()
            HA:DeleteProfile(profileName)
            HA:RefreshProfileList()
        end)

        table.insert(content.rows, row)
        i = i + 1
    end

    scrollChild:SetHeight(math.max(1, i * (ROW_HEIGHT + 2)))
end

---------------------------------------------------------------------------
-- Static popup for reset confirmation
---------------------------------------------------------------------------
StaticPopupDialogs["HIDEANYTHING_CONFIRM_RESET"] = {
    text = "",
    button1 = "",
    button2 = "",
    OnAccept = function()
        HA:ConfirmReset()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

---------------------------------------------------------------------------
-- Toggle options panel
---------------------------------------------------------------------------
function HA:ToggleOptionsPanel()
    if not panel.initialized then
        BuildPanel()
        panel.initialized = true
    end

    if panel:IsShown() then
        panel:Hide()
    else
        -- Update static popup texts from localization
        local L = self.L
        StaticPopupDialogs["HIDEANYTHING_CONFIRM_RESET"].text = L["UI_CONFIRM_RESET"]
        StaticPopupDialogs["HIDEANYTHING_CONFIRM_RESET"].button1 = L["UI_CONFIRM_YES"]
        StaticPopupDialogs["HIDEANYTHING_CONFIRM_RESET"].button2 = L["UI_CONFIRM_NO"]

        RefreshCheckboxes()
        self:RefreshHiddenList()
        self:RefreshProfileList()
        panel:Show()
    end
end

---------------------------------------------------------------------------
-- Export dialog
---------------------------------------------------------------------------
function HA:ShowExportDialog(data)
    local dialog = CreateFrame("Frame", "HideAnythingExportFrame", UIParent, "BackdropTemplate")
    dialog:SetSize(400, 250)
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true, tileSize = 32, edgeSize = 32,
        insets   = { left = 8, right = 8, top = 8, bottom = 8 },
    })

    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", dialog, "TOP", 0, -16)
    title:SetText("|cff00cc66Export Profile|r")

    local scrollFrame = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", dialog, "TOPLEFT", 16, -44)
    scrollFrame:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -32, 44)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(340)
    editBox:SetText(data)
    editBox:HighlightText()
    editBox:SetAutoFocus(true)
    scrollFrame:SetScrollChild(editBox)

    local closeBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    closeBtn:SetSize(80, 24)
    closeBtn:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 12)
    closeBtn:SetText(HA.L["UI_BTN_CLOSE"])
    closeBtn:SetScript("OnClick", function() dialog:Hide() end)

    editBox:SetScript("OnEscapePressed", function() dialog:Hide() end)
end

---------------------------------------------------------------------------
-- Import dialog
---------------------------------------------------------------------------
function HA:ShowImportDialog()
    local dialog = CreateFrame("Frame", "HideAnythingImportFrame", UIParent, "BackdropTemplate")
    dialog:SetSize(400, 250)
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true, tileSize = 32, edgeSize = 32,
        insets   = { left = 8, right = 8, top = 8, bottom = 8 },
    })

    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", dialog, "TOP", 0, -16)
    title:SetText("|cff00cc66Import Profile|r")

    local scrollFrame = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", dialog, "TOPLEFT", 16, -44)
    scrollFrame:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -32, 44)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(340)
    editBox:SetAutoFocus(true)
    scrollFrame:SetScrollChild(editBox)

    local importBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    importBtn:SetSize(80, 24)
    importBtn:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 60, 12)
    importBtn:SetText(HA.L["UI_BTN_IMPORT"])
    importBtn:SetScript("OnClick", function()
        local data = editBox:GetText()
        HA:ImportProfile(data)
        dialog:Hide()
    end)

    local closeBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    closeBtn:SetSize(80, 24)
    closeBtn:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -60, 12)
    closeBtn:SetText(HA.L["UI_BTN_CLOSE"])
    closeBtn:SetScript("OnClick", function() dialog:Hide() end)

    editBox:SetScript("OnEscapePressed", function() dialog:Hide() end)
end

---------------------------------------------------------------------------
-- ESC key to close panel
---------------------------------------------------------------------------
tinsert(UISpecialFrames, "HideAnythingOptionsFrame")
