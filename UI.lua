--[[
    HideAnything - UI.lua
    Complete Config UI with realtime toggles, live status, animated switches,
    per-sound controls, test buttons, and instant-apply for every setting.
    5 tabs: General, Feedback, Hidden Frames, Profiles, About
]]

local AddonName, HA = ...

---------------------------------------------------------------------------
-- Layout constants
---------------------------------------------------------------------------
local PANEL_WIDTH   = 580
local PANEL_HEIGHT  = 540
local TAB_HEIGHT    = 28
local INSET         = 14
local ROW_HEIGHT    = 26
local TOGGLE_W      = 40
local TOGGLE_H      = 20
local SECTION_GAP   = 12

---------------------------------------------------------------------------
-- All toggle widgets (for bulk refresh)
---------------------------------------------------------------------------
local allToggles = {}
local statusWidgets = {}

---------------------------------------------------------------------------
-- Main panel
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

-- Draggable title bar
local titleBar = CreateFrame("Frame", nil, panel)
titleBar:SetHeight(36)
titleBar:SetPoint("TOPLEFT", 0, 0)
titleBar:SetPoint("TOPRIGHT", 0, 0)
titleBar:EnableMouse(true)
titleBar:RegisterForDrag("LeftButton")
titleBar:SetScript("OnDragStart", function() panel:StartMoving() end)
titleBar:SetScript("OnDragStop",  function() panel:StopMovingOrSizing() end)

local titleText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("TOP", 0, -14)

local versionText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
versionText:SetPoint("TOPRIGHT", -40, -18)
versionText:SetTextColor(0.5, 0.5, 0.5)

-- Close button
local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -2, -2)
closeBtn:SetScript("OnClick", function() panel:Hide() end)

---------------------------------------------------------------------------
-- Tab system
---------------------------------------------------------------------------
local tabs = {}
local tabContents = {}
local activeTab = nil

local function CreateTab(index, text)
    local tab = CreateFrame("Button", "HideAnythingTab" .. index, panel, "BackdropTemplate")
    tab:SetSize(105, TAB_HEIGHT)
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
    tab:SetScript("OnClick", function() HA:SelectTab(index) end)
    tabs[index] = tab
    return tab
end

local function CreateTabContent(index)
    local c = CreateFrame("ScrollFrame", "HideAnythingTabScroll" .. index, panel, "UIPanelScrollFrameTemplate")
    c:SetPoint("TOPLEFT", INSET, -76)
    c:SetPoint("BOTTOMRIGHT", -INSET - 22, INSET)
    c:Hide()

    local child = CreateFrame("Frame", "HideAnythingTabChild" .. index, c)
    child:SetWidth(PANEL_WIDTH - INSET * 2 - 30)
    child:SetHeight(1) -- grows dynamically
    c:SetScrollChild(child)

    tabContents[index] = { scroll = c, child = child, rows = {} }
    return child
end

function HA:SelectTab(index)
    for i, tab in pairs(tabs) do
        if i == index then
            tab:SetBackdropColor(0, 0.6, 0.3, 0.5)
            tab.label:SetTextColor(1, 1, 1)
            tabContents[i].scroll:Show()
        else
            tab:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
            tab.label:SetTextColor(0.6, 0.6, 0.6)
            tabContents[i].scroll:Hide()
        end
    end
    activeTab = index
    if index == 3 then self:RefreshHiddenList() end
    if index == 4 then self:RefreshProfileList() end
end

---------------------------------------------------------------------------
-- WIDGET: Section Header with colored line
---------------------------------------------------------------------------
local function CreateSectionHeader(parent, yOff, text)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, yOff)
    header:SetText("|cff00cc66" .. text .. "|r")

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    line:SetPoint("RIGHT", parent, "RIGHT", -4, 0)
    line:SetColorTexture(0, 0.8, 0.4, 0.4)

    return yOff - 20
end

---------------------------------------------------------------------------
-- WIDGET: Realtime Toggle Switch (custom drawn, green/red, animated)
---------------------------------------------------------------------------
local function CreateToggle(parent, yOff, label, tooltipText, settingKey, onChangeCallback)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(parent:GetWidth(), 28)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOff)

    -- Label
    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetPoint("LEFT", row, "LEFT", 8, 0)
    lbl:SetText(label)
    lbl:SetWidth(parent:GetWidth() - TOGGLE_W - 80)
    lbl:SetJustifyH("LEFT")

    -- Toggle background (pill shape using backdrop)
    local toggleBg = CreateFrame("Button", nil, row, "BackdropTemplate")
    toggleBg:SetSize(TOGGLE_W, TOGGLE_H)
    toggleBg:SetPoint("RIGHT", row, "RIGHT", -46, 0)
    toggleBg:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })

    -- Knob (inner circle)
    local knob = toggleBg:CreateTexture(nil, "OVERLAY")
    knob:SetSize(TOGGLE_H - 4, TOGGLE_H - 4)
    knob:SetTexture("Interface\\Buttons\\WHITE8X8")

    -- Status text (ON / OFF)
    local statusLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusLabel:SetPoint("LEFT", toggleBg, "RIGHT", 6, 0)

    -- State management
    local function UpdateVisual(checked)
        if checked then
            toggleBg:SetBackdropColor(0.0, 0.65, 0.3, 1.0)
            toggleBg:SetBackdropBorderColor(0.0, 0.8, 0.4, 0.8)
            knob:SetPoint("RIGHT", toggleBg, "RIGHT", -2, 0)
            knob:ClearAllPoints()
            knob:SetPoint("RIGHT", toggleBg, "RIGHT", -2, 0)
            knob:SetColorTexture(1, 1, 1, 0.95)
            statusLabel:SetText(HA.L["CFG_TOGGLE_ON"])
        else
            toggleBg:SetBackdropColor(0.35, 0.1, 0.1, 1.0)
            toggleBg:SetBackdropBorderColor(0.6, 0.15, 0.15, 0.8)
            knob:ClearAllPoints()
            knob:SetPoint("LEFT", toggleBg, "LEFT", 2, 0)
            knob:SetColorTexture(0.7, 0.7, 0.7, 0.9)
            statusLabel:SetText(HA.L["CFG_TOGGLE_OFF"])
        end
    end

    toggleBg:SetScript("OnClick", function()
        local current = HA:GetSetting(settingKey)
        local newVal = not current
        HA:SetSetting(settingKey, newVal)
        UpdateVisual(newVal)

        -- Play a click sound as immediate feedback
        if newVal then
            PlaySound(8624, "Master") -- IG_MAINMENU_OPTION_CHECKBOX_ON
        else
            PlaySound(8625, "Master") -- IG_MAINMENU_OPTION_CHECKBOX_OFF
        end

        -- Notify change in chat
        local L = HA.L
        if HA:GetSetting("chatEnabled") then
            HA:Print(L["CFG_CHANGED"]:format(label, newVal and L["CFG_TOGGLE_ON"] or L["CFG_TOGGLE_OFF"]))
        end

        -- Custom callback for side effects
        if onChangeCallback then
            onChangeCallback(newVal)
        end

        -- Refresh all status widgets
        HA:RefreshStatusWidgets()
    end)

    -- Tooltip
    if tooltipText then
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(label, 0, 0.8, 0.4)
            GameTooltip:AddLine(tooltipText, 1, 1, 1, true)
            GameTooltip:AddLine(" ")
            local val = HA:GetSetting(settingKey)
            GameTooltip:AddLine("Status: " .. (val and "|cff00ff00ON|r" or "|cffff4444OFF|r"), 1, 1, 1)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    -- Store for refresh
    local widget = {
        settingKey = settingKey,
        update = UpdateVisual,
        row = row,
    }
    table.insert(allToggles, widget)

    return yOff - 30, widget
end

---------------------------------------------------------------------------
-- WIDGET: Sound Row (toggle + test button)
---------------------------------------------------------------------------
local function CreateSoundRow(parent, yOff, label, tooltipText, settingKey, soundKey)
    local nextY, widget = CreateToggle(parent, yOff, label, tooltipText, settingKey)

    -- Test button
    local testBtn = CreateFrame("Button", nil, widget.row, "UIPanelButtonTemplate")
    testBtn:SetSize(44, 18)
    testBtn:SetPoint("RIGHT", widget.row, "RIGHT", -4, 0)

    local testLabel = testBtn:GetFontString()
    if testLabel then testLabel:SetFontObject("GameFontNormalSmall") end
    testBtn:SetText(HA.L["CFG_TEST_SOUND"])

    testBtn:SetScript("OnClick", function()
        HA:ForcePlaySound(soundKey)
    end)

    -- Move the status label to make room
    -- (The test button sits at the far right, status label just before the toggle)

    return nextY
end

---------------------------------------------------------------------------
-- WIDGET: Status Indicator (live-updating value display)
---------------------------------------------------------------------------
local function CreateStatusRow(parent, yOff, label, updateFunc)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(parent:GetWidth(), 22)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOff)

    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("LEFT", row, "LEFT", 12, 0)
    lbl:SetText(label)
    lbl:SetTextColor(0.7, 0.7, 0.7)

    local val = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    val:SetPoint("RIGHT", row, "RIGHT", -12, 0)

    -- Colored background bar
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)

    local widget = {
        label = lbl,
        value = val,
        updateFunc = updateFunc,
        row = row,
    }
    table.insert(statusWidgets, widget)
    return yOff - 24
end

---------------------------------------------------------------------------
-- WIDGET: Button
---------------------------------------------------------------------------
local function CreateButton(parent, xOff, yOff, width, text, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width, 26)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff, yOff)
    btn:SetText(text)
    btn:SetScript("OnClick", onClick)
    return btn
end

---------------------------------------------------------------------------
-- Refresh all toggle visuals from current settings
---------------------------------------------------------------------------
local function RefreshAllToggles()
    for _, w in ipairs(allToggles) do
        if w.settingKey and w.update then
            local val = HA:GetSetting(w.settingKey)
            w.update(val and true or false)
        end
    end
end

---------------------------------------------------------------------------
-- Refresh status widgets
---------------------------------------------------------------------------
function HA:RefreshStatusWidgets()
    for _, w in ipairs(statusWidgets) do
        if w.updateFunc then
            w.updateFunc(w.value)
        end
    end
end

---------------------------------------------------------------------------
-- BUILD: Tab 1 - General Settings
---------------------------------------------------------------------------
local function BuildGeneralTab(parent)
    local L = HA.L
    local y = -4

    -- Section: General
    y = CreateSectionHeader(parent, y, L["CFG_HEADER_GENERAL"])
    y = y - 4

    y = select(1, CreateToggle(parent, y, L["CFG_MINIMAP_BTN"], L["CFG_MINIMAP_BTN_TT"], "showMinimap", function(val)
        if val then
            HA:ShowMinimapButton()
        else
            HA:HideMinimapButton()
        end
    end))

    y = select(1, CreateToggle(parent, y, L["CFG_LOCK_MODE"], L["CFG_LOCK_MODE_TT"], "locked"))

    y = select(1, CreateToggle(parent, y, L["CFG_AUTO_REHIDE"], L["CFG_AUTO_REHIDE_TT"], "autoHide"))

    y = select(1, CreateToggle(parent, y, L["CFG_CONFIRM_DLG"], L["CFG_CONFIRM_DLG_TT"], "confirmHide"))

    -- Section: Quick Actions
    y = y - SECTION_GAP
    y = CreateSectionHeader(parent, y, L["CFG_HEADER_QUICK"])
    y = y - 6

    local btnW = 150
    CreateButton(parent, 8, y, btnW, L["UI_BTN_PICK"], function()
        panel:Hide()
        HA:StartPicker()
    end)
    CreateButton(parent, 8 + btnW + 8, y, btnW, L["UI_BTN_SHOW_ALL"], function()
        HA:ShowAllFrames()
    end)
    CreateButton(parent, 8 + (btnW + 8) * 2, y, btnW, L["UI_BTN_RESET"], function()
        StaticPopup_Show("HIDEANYTHING_CONFIRM_RESET")
    end)
    y = y - 34

    -- Section: Live Status
    y = y - SECTION_GAP
    y = CreateSectionHeader(parent, y, L["CFG_HEADER_STATUS"])
    y = y - 4

    y = CreateStatusRow(parent, y, L["CFG_STATUS_FRAMES"], function(val)
        local count = HA:GetHiddenCount()
        if count > 0 then
            val:SetText("|cffff8800" .. count .. "|r")
        else
            val:SetText("|cff00ff000|r")
        end
    end)

    y = CreateStatusRow(parent, y, L["CFG_STATUS_PROFILES"], function(val)
        local count = 0
        if HA.db and HA.db.profiles then
            for _ in pairs(HA.db.profiles) do count = count + 1 end
        end
        val:SetText("|cffffffff" .. count .. "|r")
    end)

    y = CreateStatusRow(parent, y, L["CFG_STATUS_LOCK"], function(val)
        if HA:GetSetting("locked") then
            val:SetText("|cffff4444LOCKED|r")
        else
            val:SetText("|cff00ff00UNLOCKED|r")
        end
    end)

    y = CreateStatusRow(parent, y, L["CFG_STATUS_COMBAT"], function(val)
        if HA.inCombat then
            val:SetText("|cffff4444YES|r")
        else
            val:SetText("|cff00ff00No|r")
        end
    end)

    y = CreateStatusRow(parent, y, L["STATUS_PROFILE"], function(val)
        local profile = HA.db and HA.db.activeProfile or "none"
        val:SetText("|cffffffff" .. (profile or "none") .. "|r")
    end)

    y = y - 10
    local hint = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)
    hint:SetText(L["CFG_APPLY_INSTANT"])
    y = y - 20

    parent:SetHeight(math.abs(y) + 10)
end

---------------------------------------------------------------------------
-- BUILD: Tab 2 - Feedback Settings
---------------------------------------------------------------------------
local function BuildFeedbackTab(parent)
    local L = HA.L
    local y = -4

    -- Section: Master Feedback Toggles
    y = CreateSectionHeader(parent, y, L["CFG_HEADER_FEEDBACK"])
    y = y - 4

    y = select(1, CreateToggle(parent, y, L["CFG_SOUND_MASTER"], L["CFG_SOUND_MASTER_TT"], "soundEnabled"))
    y = select(1, CreateToggle(parent, y, L["CFG_CHAT_MSG"],     L["CFG_CHAT_MSG_TT"],     "chatEnabled"))
    y = select(1, CreateToggle(parent, y, L["CFG_SCREEN_MSG"],   L["CFG_SCREEN_MSG_TT"],   "screenEnabled"))
    y = select(1, CreateToggle(parent, y, L["CFG_ERROR_VOICE"],  L["CFG_ERROR_VOICE_TT"],  "errorSpeech"))

    -- Section: Per-Action Sound Toggles
    y = y - SECTION_GAP
    y = CreateSectionHeader(parent, y, L["CFG_HEADER_SOUND"])
    y = y - 4

    y = CreateSoundRow(parent, y, L["CFG_SND_HIDE_ENABLED"],    L["CFG_SND_ON_HIDE_TT"],    "soundHideEnabled",    "hide")
    y = CreateSoundRow(parent, y, L["CFG_SND_SHOW_ENABLED"],    L["CFG_SND_ON_SHOW_TT"],    "soundShowEnabled",    "show")
    y = CreateSoundRow(parent, y, L["CFG_SND_ERROR_ENABLED"],   L["CFG_SND_ON_ERROR_TT"],   "soundErrorEnabled",   "error")
    y = CreateSoundRow(parent, y, L["CFG_SND_SUCCESS_ENABLED"], L["CFG_SND_ON_SUCCESS_TT"], "soundSuccessEnabled", "success")
    y = CreateSoundRow(parent, y, L["CFG_SND_PICKER_ENABLED"],  L["CFG_SND_ON_PICKER_TT"],  "soundPickerEnabled",  "pickerStart")
    y = CreateSoundRow(parent, y, L["CFG_SND_LOCK_ENABLED"],    L["CFG_SND_ON_LOCK_TT"],    "soundLockEnabled",    "lock")

    -- Hint
    y = y - SECTION_GAP
    local hint = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)
    hint:SetText("|cff888888" .. L["CFG_TEST_SOUND"] .. ": " .. "Click the test button to preview each sound.|r")
    y = y - 20

    parent:SetHeight(math.abs(y) + 10)
end

---------------------------------------------------------------------------
-- BUILD: Tab 3 - Hidden Frames List
---------------------------------------------------------------------------
local function BuildHiddenTab(parent)
    local L = HA.L

    local listHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    listHeader:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -4)
    tabContents[3].listHeader = listHeader

    tabContents[3].listParent = parent
end

function HA:RefreshHiddenList()
    local L = self.L
    local tc = tabContents[3]
    if not tc or not tc.listParent then return end

    local parent = tc.listParent
    local count = self:GetHiddenCount()

    tc.listHeader:SetText(L["LIST_HEADER"]:format(count))

    -- Clear old rows
    for _, row in ipairs(tc.rows) do
        row:Hide()
    end
    wipe(tc.rows)

    local y = -28
    if count == 0 then
        local empty = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        empty:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)
        empty:SetText(L["NO_FRAMES_HIDDEN"])
        empty:SetTextColor(0.5, 0.5, 0.5)

        local holder = CreateFrame("Frame", nil, parent)
        holder:SetSize(1, 1)
        holder.fontString = empty
        table.insert(tc.rows, holder)
        parent:SetHeight(60)
        return
    end

    local i = 0
    for frameName, _ in pairs(self.db.hiddenFrames) do
        local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        row:SetSize(parent:GetWidth(), ROW_HEIGHT)
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)

        if i % 2 == 0 then
            row:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background" })
            row:SetBackdropColor(0.15, 0.15, 0.15, 0.5)
        end

        -- Index + name
        local nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameLabel:SetPoint("LEFT", row, "LEFT", 8, 0)
        nameLabel:SetText("|cffff8800" .. (i + 1) .. ".|r " .. frameName)
        nameLabel:SetWidth(parent:GetWidth() - 100)
        nameLabel:SetJustifyH("LEFT")

        -- Show button
        local showBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        showBtn:SetSize(74, 20)
        showBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        showBtn:SetText(L["UI_BTN_REMOVE"])
        showBtn:SetScript("OnClick", function()
            HA:ShowFrame(frameName)
            HA:RefreshStatusWidgets()
        end)

        HA:AddTooltip(showBtn, L["UI_BTN_REMOVE"], L["UI_BTN_REMOVE_TT"])

        table.insert(tc.rows, row)
        y = y - (ROW_HEIGHT + 2)
        i = i + 1
    end

    parent:SetHeight(math.abs(y) + 10)
end

---------------------------------------------------------------------------
-- BUILD: Tab 4 - Profiles
---------------------------------------------------------------------------
local function BuildProfilesTab(parent)
    local L = HA.L

    -- Input
    local inputLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    inputLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -8)
    inputLabel:SetText("|cff00cc66Profile Name:|r")

    local inputBox = CreateFrame("EditBox", "HideAnythingProfileInput", parent, "InputBoxTemplate")
    inputBox:SetSize(200, 24)
    inputBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 120, -4)
    inputBox:SetAutoFocus(false)
    inputBox:SetMaxLetters(30)
    inputBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    inputBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    tabContents[4].inputBox = inputBox

    -- Buttons row 1
    local btnW = 130
    CreateButton(parent, 8,           -38, btnW, L["UI_BTN_SAVE_PROFILE"], function()
        local name = inputBox:GetText()
        if name and name ~= "" then HA:SaveProfile(name); HA:RefreshProfileList(); HA:RefreshStatusWidgets()
        else HA:Print(L["PROFILE_NAME_REQUIRED"]) end
    end)
    CreateButton(parent, 8 + btnW + 6, -38, btnW, L["UI_BTN_LOAD_PROFILE"], function()
        local name = inputBox:GetText()
        if name and name ~= "" then HA:LoadProfile(name); HA:RefreshStatusWidgets()
        else HA:Print(L["PROFILE_NAME_REQUIRED"]) end
    end)
    CreateButton(parent, 8 + (btnW + 6) * 2, -38, btnW, L["UI_BTN_DELETE_PROFILE"], function()
        local name = inputBox:GetText()
        if name and name ~= "" then HA:DeleteProfile(name); HA:RefreshProfileList(); HA:RefreshStatusWidgets()
        else HA:Print(L["PROFILE_NAME_REQUIRED"]) end
    end)

    -- Buttons row 2
    CreateButton(parent, 8,           -70, btnW, L["UI_BTN_EXPORT"], function()
        local name = inputBox:GetText()
        if name and name ~= "" then HA:ExportProfile(name)
        else HA:Print(L["PROFILE_NAME_REQUIRED"]) end
    end)
    CreateButton(parent, 8 + btnW + 6, -70, btnW, L["UI_BTN_IMPORT"], function()
        HA:ShowImportDialog()
    end)

    -- Profile list header
    local profileListHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    profileListHeader:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -108)
    tabContents[4].profileListHeader = profileListHeader
    tabContents[4].listParent = parent
    tabContents[4].listStartY = -130
end

function HA:RefreshProfileList()
    local L = self.L
    local tc = tabContents[4]
    if not tc or not tc.listParent then return end

    local parent = tc.listParent

    local profileCount = 0
    if self.db and self.db.profiles then
        for _ in pairs(self.db.profiles) do profileCount = profileCount + 1 end
    end

    tc.profileListHeader:SetText(L["PROFILE_LIST_HEADER"]:format(profileCount))

    -- Clear old rows
    for _, row in ipairs(tc.rows) do
        row:Hide()
    end
    wipe(tc.rows)

    local y = tc.listStartY or -130

    if profileCount == 0 then
        local emptyLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        emptyLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)
        emptyLabel:SetText(L["PROFILE_NO_PROFILES"])
        emptyLabel:SetTextColor(0.5, 0.5, 0.5)

        local holder = CreateFrame("Frame", nil, parent)
        holder:SetSize(1, 1)
        holder.fontString = emptyLabel
        table.insert(tc.rows, holder)
        parent:SetHeight(math.abs(y) + 30)
        return
    end

    local i = 0
    for profileName, profileData in pairs(self.db.profiles) do
        local frameCount = 0
        if profileData.hiddenFrames then
            for _ in pairs(profileData.hiddenFrames) do frameCount = frameCount + 1 end
        end

        local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        row:SetSize(parent:GetWidth(), ROW_HEIGHT)
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)

        if i % 2 == 0 then
            row:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background" })
            row:SetBackdropColor(0.15, 0.15, 0.15, 0.5)
        end

        local active = (self.db.activeProfile == profileName) and " |cff00ff00*|r" or ""
        local nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameLabel:SetPoint("LEFT", row, "LEFT", 8, 0)
        nameLabel:SetText("|cff00cc66" .. profileName .. "|r" .. active .. " |cff888888(" .. frameCount .. " frames)|r")

        -- Load button
        local loadBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        loadBtn:SetSize(52, 20)
        loadBtn:SetPoint("RIGHT", row, "RIGHT", -60, 0)
        loadBtn:SetText("Load")
        loadBtn:SetScript("OnClick", function()
            HA:LoadProfile(profileName)
            if tc.inputBox then tc.inputBox:SetText(profileName) end
            HA:RefreshProfileList()
            HA:RefreshStatusWidgets()
        end)

        -- Delete button
        local delBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        delBtn:SetSize(52, 20)
        delBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        delBtn:SetText("Del")
        delBtn:SetScript("OnClick", function()
            HA:DeleteProfile(profileName)
            HA:RefreshProfileList()
            HA:RefreshStatusWidgets()
        end)

        table.insert(tc.rows, row)
        y = y - (ROW_HEIGHT + 2)
        i = i + 1
    end

    parent:SetHeight(math.abs(y) + 10)
end

---------------------------------------------------------------------------
-- BUILD: Tab 5 - About
---------------------------------------------------------------------------
local function BuildAboutTab(parent)
    local L = HA.L
    local y = -8

    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)
    title:SetText("|cff00cc66Hide|r|cffffffffAnything|r")
    y = y - 22

    local ver = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ver:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)
    ver:SetText(L["VERSION"] .. ": |cffffffff" .. HA.version .. "|r")
    y = y - 18

    local author = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    author:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)
    author:SetText("Author: |cffffffffJugoBetrugoTV|r")
    y = y - 24

    local desc = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)
    desc:SetWidth(parent:GetWidth() - 24)
    desc:SetJustifyH("LEFT")
    desc:SetText(
        "|cff00cc66Hide Anything|r allows you to hide any UI element in World of Warcraft.\n\n" ..
        "Features:\n" ..
        "  |cffffffff-|r Click-to-hide frame picker with visual highlight\n" ..
        "  |cffffffff-|r Persistent hidden frames across sessions\n" ..
        "  |cffffffff-|r Profile system (save/load/delete/export/import)\n" ..
        "  |cffffffff-|r Full Config UI with |cff00ff00realtime toggles|r\n" ..
        "  |cffffffff-|r Per-action sound control with test buttons\n" ..
        "  |cffffffff-|r Chat, screen & error voice feedback\n" ..
        "  |cffffffff-|r Lock mode to prevent accidental changes\n" ..
        "  |cffffffff-|r Combat protection with automatic queue\n" ..
        "  |cffffffff-|r Minimap button with quick actions\n" ..
        "  |cffffffff-|r German & English localization\n\n" ..
        "Commands: |cff00cc66/ha|r or |cff00cc66/hideanything|r\n" ..
        "Config:   |cff00cc66/ha toggle|r or |cff00cc66/ha config|r"
    )

    parent:SetHeight(320)
end

---------------------------------------------------------------------------
-- Build everything
---------------------------------------------------------------------------
local function BuildPanel()
    local L = HA.L

    titleText:SetText(L["UI_TITLE"])
    versionText:SetText("v" .. HA.version)

    -- Create tabs
    local tabNames = { L["UI_GENERAL"], L["UI_FEEDBACK"], L["UI_HIDDEN_FRAMES"], L["UI_PROFILES"], L["UI_ABOUT"] }
    for i, name in ipairs(tabNames) do
        local tab = CreateTab(i, name)
        tab:SetPoint("TOPLEFT", panel, "TOPLEFT", INSET + (i - 1) * 109, -42)
        CreateTabContent(i)
    end

    -- Build each tab's content
    BuildGeneralTab(tabContents[1].child)
    BuildFeedbackTab(tabContents[2].child)
    BuildHiddenTab(tabContents[3].child)
    BuildProfilesTab(tabContents[4].child)
    BuildAboutTab(tabContents[5].child)

    -- Default tab
    HA:SelectTab(1)
end

---------------------------------------------------------------------------
-- Static popup for reset confirmation
---------------------------------------------------------------------------
StaticPopupDialogs["HIDEANYTHING_CONFIRM_RESET"] = {
    text    = "",
    button1 = "",
    button2 = "",
    OnAccept = function()
        HA:ConfirmReset()
        RefreshAllToggles()
        HA:RefreshStatusWidgets()
        HA:RefreshHiddenList()
        HA:RefreshProfileList()
    end,
    timeout        = 0,
    whileDead      = true,
    hideOnEscape   = true,
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
        local L = self.L
        StaticPopupDialogs["HIDEANYTHING_CONFIRM_RESET"].text    = L["UI_CONFIRM_RESET"]
        StaticPopupDialogs["HIDEANYTHING_CONFIRM_RESET"].button1 = L["UI_CONFIRM_YES"]
        StaticPopupDialogs["HIDEANYTHING_CONFIRM_RESET"].button2 = L["UI_CONFIRM_NO"]

        RefreshAllToggles()
        self:RefreshStatusWidgets()
        self:RefreshHiddenList()
        self:RefreshProfileList()
        panel:Show()
    end
end

---------------------------------------------------------------------------
-- Live status ticker (updates every 2 seconds while panel is open)
---------------------------------------------------------------------------
local statusTicker = nil

panel:SetScript("OnShow", function()
    if statusTicker then statusTicker:Cancel() end
    statusTicker = C_Timer.NewTicker(2.0, function()
        if panel:IsShown() then
            HA:RefreshStatusWidgets()
        end
    end)
end)

panel:SetScript("OnHide", function()
    if statusTicker then
        statusTicker:Cancel()
        statusTicker = nil
    end
end)

---------------------------------------------------------------------------
-- Export dialog
---------------------------------------------------------------------------
function HA:ShowExportDialog(data)
    local dialog = CreateFrame("Frame", "HideAnythingExportFrame", UIParent, "BackdropTemplate")
    dialog:SetSize(420, 260)
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true, tileSize = 32, edgeSize = 32,
        insets   = { left = 8, right = 8, top = 8, bottom = 8 },
    })

    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText("|cff00cc66Export Profile|r")

    local sf = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 16, -44)
    sf:SetPoint("BOTTOMRIGHT", -32, 44)

    local eb = CreateFrame("EditBox", nil, sf)
    eb:SetMultiLine(true)
    eb:SetFontObject(ChatFontNormal)
    eb:SetWidth(360)
    eb:SetText(data)
    eb:HighlightText()
    eb:SetAutoFocus(true)
    sf:SetScrollChild(eb)

    local btn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    btn:SetSize(80, 24)
    btn:SetPoint("BOTTOM", 0, 12)
    btn:SetText(HA.L["UI_BTN_CLOSE"])
    btn:SetScript("OnClick", function() dialog:Hide() end)

    eb:SetScript("OnEscapePressed", function() dialog:Hide() end)
end

---------------------------------------------------------------------------
-- Import dialog
---------------------------------------------------------------------------
function HA:ShowImportDialog()
    local dialog = CreateFrame("Frame", "HideAnythingImportFrame", UIParent, "BackdropTemplate")
    dialog:SetSize(420, 260)
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true, tileSize = 32, edgeSize = 32,
        insets   = { left = 8, right = 8, top = 8, bottom = 8 },
    })

    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText("|cff00cc66Import Profile|r")

    local sf = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 16, -44)
    sf:SetPoint("BOTTOMRIGHT", -32, 44)

    local eb = CreateFrame("EditBox", nil, sf)
    eb:SetMultiLine(true)
    eb:SetFontObject(ChatFontNormal)
    eb:SetWidth(360)
    eb:SetAutoFocus(true)
    sf:SetScrollChild(eb)

    local importBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    importBtn:SetSize(80, 24)
    importBtn:SetPoint("BOTTOMLEFT", 60, 12)
    importBtn:SetText(HA.L["UI_BTN_IMPORT"])
    importBtn:SetScript("OnClick", function()
        HA:ImportProfile(eb:GetText())
        dialog:Hide()
        HA:RefreshProfileList()
        HA:RefreshStatusWidgets()
    end)

    local closeBtn = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    closeBtn:SetSize(80, 24)
    closeBtn:SetPoint("BOTTOMRIGHT", -60, 12)
    closeBtn:SetText(HA.L["UI_BTN_CLOSE"])
    closeBtn:SetScript("OnClick", function() dialog:Hide() end)

    eb:SetScript("OnEscapePressed", function() dialog:Hide() end)
end

---------------------------------------------------------------------------
-- ESC to close
---------------------------------------------------------------------------
tinsert(UISpecialFrames, "HideAnythingOptionsFrame")
