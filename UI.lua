--[[
    HideAnything - UI.lua
    Config UI with frame catalog toggles, confirmation dialog,
    profile management, and settings.
    3 tabs: Frames, Profiles, About
]]

local AddonName, HA = ...

---------------------------------------------------------------------------
-- Layout constants
---------------------------------------------------------------------------
local PANEL_WIDTH   = 540
local PANEL_HEIGHT  = 520
local TAB_HEIGHT    = 28
local INSET         = 14
local ROW_HEIGHT    = 28
local TOGGLE_W      = 40
local TOGGLE_H      = 20

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------
local allToggles = {}
local tabContents = {}
local activeTab = nil

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

local function CreateTab(index, text)
    local tab = CreateFrame("Button", "HideAnythingTab" .. index, panel, "BackdropTemplate")
    tab:SetSize(140, TAB_HEIGHT)
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
    child:SetHeight(1)
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
    if index == 1 then self:RefreshFrameList() end
    if index == 2 then self:RefreshProfileList() end
end

---------------------------------------------------------------------------
-- WIDGET: Section Header
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
-- Confirmation dialog for hiding a frame
---------------------------------------------------------------------------
local confirmDialog = CreateFrame("Frame", "HideAnythingConfirmDialog", UIParent, "BackdropTemplate")
confirmDialog:SetSize(360, 160)
confirmDialog:SetPoint("CENTER")
confirmDialog:SetFrameStrata("FULLSCREEN_DIALOG")
confirmDialog:SetFrameLevel(200)
confirmDialog:SetMovable(true)
confirmDialog:EnableMouse(true)
confirmDialog:SetClampedToScreen(true)
confirmDialog:Hide()

confirmDialog:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile     = true, tileSize = 32, edgeSize = 32,
    insets   = { left = 8, right = 8, top = 8, bottom = 8 },
})

local confirmTitle = confirmDialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
confirmTitle:SetPoint("TOP", 0, -20)

local confirmText = confirmDialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
confirmText:SetPoint("TOP", 0, -50)
confirmText:SetWidth(300)
confirmText:SetJustifyH("CENTER")

local confirmFrameName = confirmDialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
confirmFrameName:SetPoint("TOP", 0, -75)
confirmFrameName:SetWidth(300)
confirmFrameName:SetJustifyH("CENTER")

local confirmYes = CreateFrame("Button", nil, confirmDialog, "UIPanelButtonTemplate")
confirmYes:SetSize(120, 28)
confirmYes:SetPoint("BOTTOMLEFT", 40, 16)

local confirmNo = CreateFrame("Button", nil, confirmDialog, "UIPanelButtonTemplate")
confirmNo:SetSize(120, 28)
confirmNo:SetPoint("BOTTOMRIGHT", -40, 16)
confirmNo:SetScript("OnClick", function() confirmDialog:Hide() end)

-- Draggable
local confirmDrag = CreateFrame("Frame", nil, confirmDialog)
confirmDrag:SetHeight(30)
confirmDrag:SetPoint("TOPLEFT", 0, 0)
confirmDrag:SetPoint("TOPRIGHT", 0, 0)
confirmDrag:EnableMouse(true)
confirmDrag:RegisterForDrag("LeftButton")
confirmDrag:SetScript("OnDragStart", function() confirmDialog:StartMoving() end)
confirmDrag:SetScript("OnDragStop",  function() confirmDialog:StopMovingOrSizing() end)

-- ESC to close confirm dialog
confirmDialog:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
        self:Hide()
        self:SetPropagateKeyboardInput(false)
    else
        self:SetPropagateKeyboardInput(true)
    end
end)

function HA:ShowConfirmHideDialog(frameName, displayLabel, onConfirm)
    local L = self.L
    confirmTitle:SetText(L["CONFIRM_HIDE_TITLE"])
    confirmText:SetText(L["CONFIRM_HIDE_TEXT"])
    confirmFrameName:SetText("|cffff8800" .. displayLabel .. "|r |cff888888(" .. frameName .. ")|r")
    confirmYes:SetText(L["UI_CONFIRM_YES"])
    confirmNo:SetText(L["UI_CONFIRM_NO"])
    confirmYes:SetScript("OnClick", function()
        confirmDialog:Hide()
        if onConfirm then onConfirm() end
    end)
    confirmDialog:Show()
    confirmDialog:EnableKeyboard(true)
end

---------------------------------------------------------------------------
-- BUILD: Tab 1 - Frame List with Toggles
---------------------------------------------------------------------------
local function BuildFramesTab(parent)
    tabContents[1].listParent = parent
end

function HA:RefreshFrameList()
    local L = self.L
    local tc = tabContents[1]
    if not tc or not tc.listParent then return end

    local parent = tc.listParent

    -- Clear old rows
    for _, row in ipairs(tc.rows) do
        row:Hide()
    end
    wipe(tc.rows)

    local y = -4

    -- Section: Settings
    y = CreateSectionHeader(parent, y, L["CFG_HEADER_SETTINGS"])
    y = y - 4

    -- Minimap toggle
    do
        local row = CreateFrame("Frame", nil, parent)
        row:SetSize(parent:GetWidth(), 28)
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)

        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("LEFT", row, "LEFT", 8, 0)
        lbl:SetText(L["CFG_MINIMAP_BTN"])

        local toggleBg = CreateFrame("Button", nil, row, "BackdropTemplate")
        toggleBg:SetSize(TOGGLE_W, TOGGLE_H)
        toggleBg:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        toggleBg:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        local knob = toggleBg:CreateTexture(nil, "OVERLAY")
        knob:SetSize(TOGGLE_H - 4, TOGGLE_H - 4)
        knob:SetTexture("Interface\\Buttons\\WHITE8X8")

        local function UpdateMinimapToggle()
            local on = self:GetSetting("showMinimap")
            if on then
                toggleBg:SetBackdropColor(0.0, 0.65, 0.3, 1.0)
                toggleBg:SetBackdropBorderColor(0.0, 0.8, 0.4, 0.8)
                knob:ClearAllPoints()
                knob:SetPoint("RIGHT", toggleBg, "RIGHT", -2, 0)
                knob:SetColorTexture(1, 1, 1, 0.95)
            else
                toggleBg:SetBackdropColor(0.35, 0.1, 0.1, 1.0)
                toggleBg:SetBackdropBorderColor(0.6, 0.15, 0.15, 0.8)
                knob:ClearAllPoints()
                knob:SetPoint("LEFT", toggleBg, "LEFT", 2, 0)
                knob:SetColorTexture(0.7, 0.7, 0.7, 0.9)
            end
        end
        UpdateMinimapToggle()

        toggleBg:SetScript("OnClick", function()
            local val = not self:GetSetting("showMinimap")
            self:SetSetting("showMinimap", val)
            if val then self:ShowMinimapButton() else self:HideMinimapButton() end
            UpdateMinimapToggle()
        end)

        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(L["CFG_MINIMAP_BTN"], 0, 0.8, 0.4)
            GameTooltip:AddLine(L["CFG_MINIMAP_BTN_TT"], 1, 1, 1, true)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)

        table.insert(tc.rows, row)
        y = y - 30
    end

    -- Lock toggle
    do
        local row = CreateFrame("Frame", nil, parent)
        row:SetSize(parent:GetWidth(), 28)
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)

        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("LEFT", row, "LEFT", 8, 0)
        lbl:SetText(L["CFG_LOCK_MODE"])

        local toggleBg = CreateFrame("Button", nil, row, "BackdropTemplate")
        toggleBg:SetSize(TOGGLE_W, TOGGLE_H)
        toggleBg:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        toggleBg:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        local knob = toggleBg:CreateTexture(nil, "OVERLAY")
        knob:SetSize(TOGGLE_H - 4, TOGGLE_H - 4)
        knob:SetTexture("Interface\\Buttons\\WHITE8X8")

        local function UpdateLockToggle()
            local on = self:GetSetting("locked")
            if on then
                toggleBg:SetBackdropColor(0.35, 0.1, 0.1, 1.0)
                toggleBg:SetBackdropBorderColor(0.6, 0.15, 0.15, 0.8)
                knob:ClearAllPoints()
                knob:SetPoint("RIGHT", toggleBg, "RIGHT", -2, 0)
                knob:SetColorTexture(1, 0.3, 0.3, 0.95)
            else
                toggleBg:SetBackdropColor(0.0, 0.65, 0.3, 1.0)
                toggleBg:SetBackdropBorderColor(0.0, 0.8, 0.4, 0.8)
                knob:ClearAllPoints()
                knob:SetPoint("LEFT", toggleBg, "LEFT", 2, 0)
                knob:SetColorTexture(0.7, 0.7, 0.7, 0.9)
            end
        end
        UpdateLockToggle()

        toggleBg:SetScript("OnClick", function()
            local val = not self:GetSetting("locked")
            self:SetSetting("locked", val)
            UpdateLockToggle()
        end)

        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(L["CFG_LOCK_MODE"], 0, 0.8, 0.4)
            GameTooltip:AddLine(L["CFG_LOCK_MODE_TT"], 1, 1, 1, true)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)

        table.insert(tc.rows, row)
        y = y - 30
    end

    -- Section: Frame Catalog
    y = y - 8
    y = CreateSectionHeader(parent, y, L["CFG_HEADER_FRAMES"])
    y = y - 4

    for i, entry in ipairs(self.FRAME_CATALOG) do
        local frameName = entry.name
        local displayLabel = self:GetCatalogLabel(entry)
        local isHidden = self.db.hiddenFrames[frameName] == true
        local frameExists = self:GetFrameByName(frameName) ~= nil

        local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        row:SetSize(parent:GetWidth(), ROW_HEIGHT)
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)

        if i % 2 == 0 then
            row:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background" })
            row:SetBackdropColor(0.15, 0.15, 0.15, 0.3)
        end

        -- Label
        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("LEFT", row, "LEFT", 8, 0)
        if not frameExists then
            lbl:SetText("|cff666666" .. displayLabel .. "|r")
        else
            lbl:SetText(displayLabel)
        end
        lbl:SetWidth(parent:GetWidth() * 0.45)
        lbl:SetJustifyH("LEFT")

        -- Technical name
        local techName = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        techName:SetPoint("LEFT", lbl, "RIGHT", 4, 0)
        techName:SetText("|cff888888" .. frameName .. "|r")
        techName:SetWidth(parent:GetWidth() * 0.3)
        techName:SetJustifyH("LEFT")

        -- Toggle button
        local toggleBg = CreateFrame("Button", nil, row, "BackdropTemplate")
        toggleBg:SetSize(TOGGLE_W, TOGGLE_H)
        toggleBg:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        toggleBg:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 },
        })

        local knob = toggleBg:CreateTexture(nil, "OVERLAY")
        knob:SetSize(TOGGLE_H - 4, TOGGLE_H - 4)
        knob:SetTexture("Interface\\Buttons\\WHITE8X8")

        -- Visual: visible = green (toggle right), hidden = red (toggle left)
        if isHidden then
            toggleBg:SetBackdropColor(0.35, 0.1, 0.1, 1.0)
            toggleBg:SetBackdropBorderColor(0.6, 0.15, 0.15, 0.8)
            knob:ClearAllPoints()
            knob:SetPoint("LEFT", toggleBg, "LEFT", 2, 0)
            knob:SetColorTexture(0.7, 0.7, 0.7, 0.9)
        else
            toggleBg:SetBackdropColor(0.0, 0.65, 0.3, 1.0)
            toggleBg:SetBackdropBorderColor(0.0, 0.8, 0.4, 0.8)
            knob:ClearAllPoints()
            knob:SetPoint("RIGHT", toggleBg, "RIGHT", -2, 0)
            knob:SetColorTexture(1, 1, 1, 0.95)
        end

        if frameExists then
            toggleBg:SetScript("OnClick", function()
                if isHidden then
                    HA:ShowFrame(frameName)
                else
                    if HA:GetSetting("confirmHide") then
                        HA:ShowConfirmHideDialog(frameName, displayLabel, function()
                            HA:HideFrame(frameName)
                        end)
                    else
                        HA:HideFrame(frameName)
                    end
                end
            end)
        else
            toggleBg:SetBackdropColor(0.2, 0.2, 0.2, 0.5)
            toggleBg:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.5)
            knob:SetColorTexture(0.4, 0.4, 0.4, 0.5)
        end

        -- Tooltip
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(displayLabel, 0, 0.8, 0.4)
            GameTooltip:AddLine(frameName, 0.5, 0.5, 0.5)
            if not frameExists then
                GameTooltip:AddLine(L["FRAME_NOT_LOADED"], 1, 0.5, 0)
            elseif isHidden then
                GameTooltip:AddLine(L["FRAME_STATE_HIDDEN"], 1, 0.3, 0.3)
            else
                GameTooltip:AddLine(L["FRAME_STATE_VISIBLE"], 0, 1, 0)
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)

        table.insert(tc.rows, row)
        y = y - (ROW_HEIGHT + 1)
    end

    -- Custom hidden frames (not in catalog)
    local customHidden = {}
    local catalogNames = {}
    for _, entry in ipairs(self.FRAME_CATALOG) do
        catalogNames[entry.name] = true
    end
    for frameName, _ in pairs(self.db.hiddenFrames) do
        if not catalogNames[frameName] then
            table.insert(customHidden, frameName)
        end
    end

    if #customHidden > 0 then
        y = y - 8
        y = CreateSectionHeader(parent, y, L["CFG_HEADER_CUSTOM_HIDDEN"])
        y = y - 4

        for i, frameName in ipairs(customHidden) do
            local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
            row:SetSize(parent:GetWidth(), ROW_HEIGHT)
            row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)

            if i % 2 == 0 then
                row:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background" })
                row:SetBackdropColor(0.15, 0.15, 0.15, 0.3)
            end

            local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lbl:SetPoint("LEFT", row, "LEFT", 8, 0)
            lbl:SetText("|cffff8800" .. frameName .. "|r")
            lbl:SetWidth(parent:GetWidth() - 90)
            lbl:SetJustifyH("LEFT")

            local showBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            showBtn:SetSize(70, 20)
            showBtn:SetPoint("RIGHT", row, "RIGHT", -8, 0)
            showBtn:SetText(L["UI_BTN_SHOW"])
            showBtn:SetScript("OnClick", function()
                HA:ShowFrame(frameName)
            end)

            table.insert(tc.rows, row)
            y = y - (ROW_HEIGHT + 1)
        end
    end

    -- Custom frame input
    y = y - 8
    y = CreateSectionHeader(parent, y, L["CFG_HEADER_CUSTOM"])
    y = y - 6

    local inputRow = CreateFrame("Frame", nil, parent)
    inputRow:SetSize(parent:GetWidth(), 30)
    inputRow:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)

    local inputBox = CreateFrame("EditBox", "HideAnythingCustomInput", inputRow, "InputBoxTemplate")
    inputBox:SetSize(280, 24)
    inputBox:SetPoint("LEFT", inputRow, "LEFT", 8, 0)
    inputBox:SetAutoFocus(false)
    inputBox:SetMaxLetters(100)
    inputBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    inputBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    local hideBtn = CreateFrame("Button", nil, inputRow, "UIPanelButtonTemplate")
    hideBtn:SetSize(80, 24)
    hideBtn:SetPoint("LEFT", inputBox, "RIGHT", 8, 0)
    hideBtn:SetText(L["UI_BTN_HIDE"])
    hideBtn:SetScript("OnClick", function()
        local name = inputBox:GetText()
        if name and name ~= "" then
            if HA:GetSetting("confirmHide") then
                HA:ShowConfirmHideDialog(name, name, function()
                    HA:HideFrame(name)
                    inputBox:SetText("")
                end)
            else
                HA:HideFrame(name)
                inputBox:SetText("")
            end
        end
    end)

    table.insert(tc.rows, inputRow)
    y = y - 36

    -- Action buttons
    y = y - 4
    local btnW = 140

    local actionRow = CreateFrame("Frame", nil, parent)
    actionRow:SetSize(parent:GetWidth(), 30)
    actionRow:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)

    local showAllBtn = CreateFrame("Button", nil, actionRow, "UIPanelButtonTemplate")
    showAllBtn:SetSize(btnW, 26)
    showAllBtn:SetPoint("LEFT", actionRow, "LEFT", 8, 0)
    showAllBtn:SetText(L["UI_BTN_SHOW_ALL"])
    showAllBtn:SetScript("OnClick", function()
        HA:ShowAllFrames()
    end)

    local resetBtn = CreateFrame("Button", nil, actionRow, "UIPanelButtonTemplate")
    resetBtn:SetSize(btnW, 26)
    resetBtn:SetPoint("LEFT", showAllBtn, "RIGHT", 8, 0)
    resetBtn:SetText(L["UI_BTN_RESET"])
    resetBtn:SetScript("OnClick", function()
        StaticPopup_Show("HIDEANYTHING_CONFIRM_RESET")
    end)

    table.insert(tc.rows, actionRow)
    y = y - 36

    parent:SetHeight(math.abs(y) + 10)
end

---------------------------------------------------------------------------
-- BUILD: Tab 2 - Profiles
---------------------------------------------------------------------------
local function BuildProfilesTab(parent)
    local L = HA.L

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
    tabContents[2].inputBox = inputBox

    local btnW = 130
    CreateButton(parent, 8,           -38, btnW, L["UI_BTN_SAVE_PROFILE"], function()
        local name = inputBox:GetText()
        if name and name ~= "" then HA:SaveProfile(name); HA:RefreshProfileList()
        else HA:Print(L["PROFILE_NAME_REQUIRED"]) end
    end)
    CreateButton(parent, 8 + btnW + 6, -38, btnW, L["UI_BTN_LOAD_PROFILE"], function()
        local name = inputBox:GetText()
        if name and name ~= "" then HA:LoadProfile(name)
        else HA:Print(L["PROFILE_NAME_REQUIRED"]) end
    end)
    CreateButton(parent, 8 + (btnW + 6) * 2, -38, btnW, L["UI_BTN_DELETE_PROFILE"], function()
        local name = inputBox:GetText()
        if name and name ~= "" then HA:DeleteProfile(name); HA:RefreshProfileList()
        else HA:Print(L["PROFILE_NAME_REQUIRED"]) end
    end)

    CreateButton(parent, 8,           -70, btnW, L["UI_BTN_EXPORT"], function()
        local name = inputBox:GetText()
        if name and name ~= "" then HA:ExportProfile(name)
        else HA:Print(L["PROFILE_NAME_REQUIRED"]) end
    end)
    CreateButton(parent, 8 + btnW + 6, -70, btnW, L["UI_BTN_IMPORT"], function()
        HA:ShowImportDialog()
    end)

    local profileListHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    profileListHeader:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -108)
    tabContents[2].profileListHeader = profileListHeader
    tabContents[2].listParent = parent
    tabContents[2].listStartY = -130
end

function HA:RefreshProfileList()
    local L = self.L
    local tc = tabContents[2]
    if not tc or not tc.listParent then return end

    local parent = tc.listParent
    local profileCount = 0
    if self.db and self.db.profiles then
        for _ in pairs(self.db.profiles) do profileCount = profileCount + 1 end
    end

    tc.profileListHeader:SetText(L["PROFILE_LIST_HEADER"]:format(profileCount))

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

        local loadBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        loadBtn:SetSize(52, 20)
        loadBtn:SetPoint("RIGHT", row, "RIGHT", -60, 0)
        loadBtn:SetText("Load")
        loadBtn:SetScript("OnClick", function()
            HA:LoadProfile(profileName)
            if tc.inputBox then tc.inputBox:SetText(profileName) end
            HA:RefreshProfileList()
        end)

        local delBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        delBtn:SetSize(52, 20)
        delBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        delBtn:SetText("Del")
        delBtn:SetScript("OnClick", function()
            HA:DeleteProfile(profileName)
            HA:RefreshProfileList()
        end)

        table.insert(tc.rows, row)
        y = y - (ROW_HEIGHT + 2)
        i = i + 1
    end

    parent:SetHeight(math.abs(y) + 10)
end

---------------------------------------------------------------------------
-- BUILD: Tab 3 - About
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
        "|cff00cc66Hide Anything|r " .. L["ABOUT_DESC"] .. "\n\n" ..
        L["ABOUT_FEATURES"] .. "\n" ..
        "  |cffffffff-|r " .. L["ABOUT_F1"] .. "\n" ..
        "  |cffffffff-|r " .. L["ABOUT_F2"] .. "\n" ..
        "  |cffffffff-|r " .. L["ABOUT_F3"] .. "\n" ..
        "  |cffffffff-|r " .. L["ABOUT_F4"] .. "\n" ..
        "  |cffffffff-|r " .. L["ABOUT_F5"] .. "\n" ..
        "  |cffffffff-|r " .. L["ABOUT_F6"] .. "\n\n" ..
        "Commands: |cff00cc66/ha|r or |cff00cc66/hideanything|r\n" ..
        "Config:   |cff00cc66/ha toggle|r"
    )

    parent:SetHeight(280)
end

---------------------------------------------------------------------------
-- Build everything
---------------------------------------------------------------------------
local function BuildPanel()
    local L = HA.L

    titleText:SetText(L["UI_TITLE"])
    versionText:SetText("v" .. HA.version)

    local tabNames = { L["UI_FRAMES"], L["UI_PROFILES"], L["UI_ABOUT"] }
    for i, name in ipairs(tabNames) do
        local tab = CreateTab(i, name)
        tab:SetPoint("TOPLEFT", panel, "TOPLEFT", INSET + (i - 1) * 144, -42)
        CreateTabContent(i)
    end

    BuildFramesTab(tabContents[1].child)
    BuildProfilesTab(tabContents[2].child)
    BuildAboutTab(tabContents[3].child)

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
        HA:RefreshFrameList()
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

        self:RefreshFrameList()
        self:RefreshProfileList()
        panel:Show()
    end
end

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
