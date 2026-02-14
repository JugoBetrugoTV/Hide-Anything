--[[
    HideAnything - UI.lua
    Config UI with frame catalog toggles, search/filter,
    alpha/opacity popup, frame highlighting (per-row button),
    profile management, and settings.
    3 tabs: Frames, Profiles, About

    PERFORMANCE: Uses frame pooling - rows are recycled, never destroyed.
]]

local AddonName, HA = ...

---------------------------------------------------------------------------
-- Layout constants
---------------------------------------------------------------------------
local PANEL_WIDTH   = 580
local PANEL_HEIGHT  = 560
local TAB_HEIGHT    = 30
local INSET         = 12
local ROW_HEIGHT    = 30
local TOGGLE_W      = 44
local TOGGLE_H      = 22
local ACCENT_R, ACCENT_G, ACCENT_B = 0, 0.78, 0.38  -- #00c761
local ACCENT_DIM_R, ACCENT_DIM_G, ACCENT_DIM_B = 0, 0.55, 0.27

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------
local tabContents = {}
local activeTab = nil
local searchFilter = ""  -- current search text

---------------------------------------------------------------------------
-- Reusable backdrop tables (avoid garbage)
---------------------------------------------------------------------------
local BD_PANEL = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile     = false, edgeSize = 14,
    insets   = { left = 3, right = 3, top = 3, bottom = 3 },
}
local BD_ROW_ALT = { bgFile = "Interface\\Buttons\\WHITE8X8" }
local BD_TOGGLE = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 8,
    insets   = { left = 2, right = 2, top = 2, bottom = 2 },
}
local BD_ALPHA_BTN = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 8,
    insets   = { left = 2, right = 2, top = 2, bottom = 2 },
}
local BD_POPUP = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile     = false, edgeSize = 14,
    insets   = { left = 3, right = 3, top = 3, bottom = 3 },
}
local BD_SEARCH = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 10,
    insets   = { left = 3, right = 3, top = 3, bottom = 3 },
}
local BD_SECTION = { bgFile = "Interface\\Buttons\\WHITE8X8" }
local BD_CARD = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 10,
    insets   = { left = 2, right = 2, top = 2, bottom = 2 },
}

---------------------------------------------------------------------------
-- Frame pool for catalog rows
---------------------------------------------------------------------------
local frameRowPool = {}
local frameRowPoolSize = 0
local activeRows = {}

local function AcquireRow(parent)
    local row
    if frameRowPoolSize > 0 then
        row = frameRowPool[frameRowPoolSize]
        frameRowPool[frameRowPoolSize] = nil
        frameRowPoolSize = frameRowPoolSize - 1
        row:SetParent(parent)
        row:ClearAllPoints()
        row:Show()
    else
        row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        row:SetSize(parent:GetWidth(), ROW_HEIGHT)

        -- Pre-create all child widgets once
        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("LEFT", row, "LEFT", 10, 0)
        lbl:SetJustifyH("LEFT")
        row._label = lbl

        local tech = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        tech:SetPoint("LEFT", lbl, "RIGHT", 6, 0)
        tech:SetJustifyH("LEFT")
        row._techName = tech

        -- Combat auto-hide button
        local combatBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
        combatBtn:SetSize(22, 20)
        combatBtn:SetPoint("RIGHT", row, "RIGHT", -156, 0)
        combatBtn:SetBackdrop(BD_ALPHA_BTN)
        local combatText = combatBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        combatText:SetPoint("CENTER")
        combatBtn._text = combatText
        row._combatBtn = combatBtn

        -- Eye button for highlight
        local eyeBtn = CreateFrame("Button", nil, row)
        eyeBtn:SetSize(22, 22)
        eyeBtn:SetPoint("RIGHT", row, "RIGHT", -128, 0)
        local eyeText = eyeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        eyeText:SetPoint("CENTER")
        eyeBtn._text = eyeText
        row._eyeBtn = eyeBtn

        -- Alpha button
        local alphaBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
        alphaBtn:SetSize(42, 20)
        alphaBtn:SetPoint("RIGHT", row, "RIGHT", -58, 0)
        alphaBtn:SetBackdrop(BD_ALPHA_BTN)
        local alphaText = alphaBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        alphaText:SetPoint("CENTER")
        alphaBtn._text = alphaText
        row._alphaBtn = alphaBtn

        -- Toggle button (pill shape)
        local toggleBg = CreateFrame("Button", nil, row, "BackdropTemplate")
        toggleBg:SetSize(TOGGLE_W, TOGGLE_H)
        toggleBg:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        toggleBg:SetBackdrop(BD_TOGGLE)
        local knob = toggleBg:CreateTexture(nil, "OVERLAY")
        knob:SetSize(TOGGLE_H - 6, TOGGLE_H - 6)
        knob:SetTexture("Interface\\Buttons\\WHITE8X8")
        toggleBg._knob = knob
        row._toggleBg = toggleBg

        -- Show button (for custom hidden frames)
        local showBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        showBtn:SetSize(74, 22)
        showBtn:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        row._showBtn = showBtn

        -- Hover highlight
        local hoverTex = row:CreateTexture(nil, "BACKGROUND")
        hoverTex:SetAllPoints()
        hoverTex:SetTexture("Interface\\Buttons\\WHITE8X8")
        hoverTex:SetVertexColor(ACCENT_R, ACCENT_G, ACCENT_B, 0)
        row._hoverTex = hoverTex

        row:EnableMouse(true)
    end
    table.insert(activeRows, row)
    return row
end

local function ReleaseAllRows()
    for i = #activeRows, 1, -1 do
        local row = activeRows[i]
        row:Hide()
        row:SetScript("OnEnter", nil)
        row:SetScript("OnLeave", nil)
        row._label:SetText("")
        row._techName:SetText("")
        row._combatBtn:SetScript("OnClick", nil)
        row._combatBtn:SetScript("OnEnter", nil)
        row._combatBtn:SetScript("OnLeave", nil)
        row._combatBtn:Hide()
        row._eyeBtn:SetScript("OnClick", nil)
        row._eyeBtn:Hide()
        row._alphaBtn:SetScript("OnClick", nil)
        row._alphaBtn:SetScript("OnEnter", nil)
        row._alphaBtn:SetScript("OnLeave", nil)
        row._alphaBtn:Hide()
        row._toggleBg:SetScript("OnClick", nil)
        row._toggleBg:Hide()
        row._showBtn:SetScript("OnClick", nil)
        row._showBtn:Hide()
        row._hoverTex:SetVertexColor(ACCENT_R, ACCENT_G, ACCENT_B, 0)
        row:SetBackdrop(nil)
        frameRowPoolSize = frameRowPoolSize + 1
        frameRowPool[frameRowPoolSize] = row
        activeRows[i] = nil
    end
end

---------------------------------------------------------------------------
-- Simple frame pool for section headers / misc
---------------------------------------------------------------------------
local miscPool = {}
local miscPoolSize = 0
local activeMisc = {}

local function AcquireMiscFrame(parent)
    local f
    if miscPoolSize > 0 then
        f = miscPool[miscPoolSize]
        miscPool[miscPoolSize] = nil
        miscPoolSize = miscPoolSize - 1
        f:SetParent(parent)
        f:ClearAllPoints()
        f:Show()
    else
        f = CreateFrame("Frame", nil, parent)
    end
    table.insert(activeMisc, f)
    return f
end

local function ReleaseAllMisc()
    for i = #activeMisc, 1, -1 do
        local f = activeMisc[i]
        f:Hide()
        miscPoolSize = miscPoolSize + 1
        miscPool[miscPoolSize] = f
        activeMisc[i] = nil
    end
end

---------------------------------------------------------------------------
-- Font string pool for section headers
---------------------------------------------------------------------------
local fontPool = {}
local fontPoolSize = 0
local activeFonts = {}

local function AcquireFont(parent, template)
    local fs
    if fontPoolSize > 0 then
        fs = fontPool[fontPoolSize]
        fontPool[fontPoolSize] = nil
        fontPoolSize = fontPoolSize - 1
        fs:SetParent(parent)
        fs:ClearAllPoints()
        fs:Show()
    else
        fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormalSmall")
    end
    table.insert(activeFonts, fs)
    return fs
end

local function ReleaseAllFonts()
    for i = #activeFonts, 1, -1 do
        local fs = activeFonts[i]
        fs:Hide()
        fs:SetText("")
        fontPoolSize = fontPoolSize + 1
        fontPool[fontPoolSize] = fs
        activeFonts[i] = nil
    end
end

---------------------------------------------------------------------------
-- Texture pool for lines
---------------------------------------------------------------------------
local texPool = {}
local texPoolSize = 0
local activeTextures = {}

local function AcquireTexture(parent)
    local tex
    if texPoolSize > 0 then
        tex = texPool[texPoolSize]
        texPool[texPoolSize] = nil
        texPoolSize = texPoolSize - 1
        tex:ClearAllPoints()
        tex:Show()
    else
        tex = parent:CreateTexture(nil, "ARTWORK")
    end
    table.insert(activeTextures, tex)
    return tex
end

local function ReleaseAllTextures()
    for i = #activeTextures, 1, -1 do
        local tex = activeTextures[i]
        tex:Hide()
        texPoolSize = texPoolSize + 1
        texPool[texPoolSize] = tex
        activeTextures[i] = nil
    end
end

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

panel:SetBackdrop(BD_PANEL)
panel:SetBackdropColor(0.08, 0.08, 0.10, 0.97)
panel:SetBackdropBorderColor(0.25, 0.25, 0.28, 1)

-- Top accent stripe
local accentStripe = panel:CreateTexture(nil, "OVERLAY")
accentStripe:SetHeight(2)
accentStripe:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
accentStripe:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -4)
accentStripe:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.9)

-- Draggable title bar
local titleBar = CreateFrame("Frame", nil, panel)
titleBar:SetHeight(40)
titleBar:SetPoint("TOPLEFT", 0, 0)
titleBar:SetPoint("TOPRIGHT", 0, 0)
titleBar:EnableMouse(true)
titleBar:RegisterForDrag("LeftButton")
titleBar:SetScript("OnDragStart", function() panel:StartMoving() end)
titleBar:SetScript("OnDragStop",  function() panel:StopMovingOrSizing() end)

-- Title with colored addon name
local titleText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("TOPLEFT", 16, -14)

local versionText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
versionText:SetPoint("LEFT", titleText, "RIGHT", 8, 0)
versionText:SetTextColor(0.45, 0.45, 0.5)

-- Close button
local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -2, -2)
closeBtn:SetScript("OnClick", function()
    panel:Hide()
    HA:UnhighlightFrame()
end)

panel:SetScript("OnHide", function()
    HA:UnhighlightFrame()
end)

---------------------------------------------------------------------------
-- Status bar (bottom)
---------------------------------------------------------------------------
local statusBar = CreateFrame("Frame", nil, panel, "BackdropTemplate")
statusBar:SetHeight(24)
statusBar:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 4, 4)
statusBar:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4, 4)
statusBar:SetBackdrop(BD_SECTION)
statusBar:SetBackdropColor(0.06, 0.06, 0.08, 0.8)

local statusText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
statusText:SetPoint("LEFT", statusBar, "LEFT", 10, 0)
statusText:SetTextColor(0.5, 0.5, 0.55)

local function UpdateStatusBar()
    local count = HA:GetHiddenCount()
    local L = HA.L
    statusText:SetText(L["STATUS_HIDDEN_COUNT"]:format(count))
end

---------------------------------------------------------------------------
-- Tab system (underline style)
---------------------------------------------------------------------------
local tabs = {}

local function CreateTab(index, text)
    local tab = CreateFrame("Button", "HideAnythingTab" .. index, panel)
    tab:SetSize(PANEL_WIDTH / 3 - 10, TAB_HEIGHT)

    local label = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER", 0, 0)
    label:SetText(text)
    tab.label = label

    -- Underline indicator
    local underline = tab:CreateTexture(nil, "OVERLAY")
    underline:SetHeight(2)
    underline:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 8, 0)
    underline:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -8, 0)
    underline:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 1)
    underline:Hide()
    tab._underline = underline

    -- Hover effect
    tab:SetScript("OnEnter", function(self)
        if activeTab ~= index then
            self.label:SetTextColor(0.85, 0.85, 0.85)
        end
    end)
    tab:SetScript("OnLeave", function(self)
        if activeTab ~= index then
            self.label:SetTextColor(0.5, 0.5, 0.55)
        end
    end)

    tab:SetScript("OnClick", function() HA:SelectTab(index) end)
    tabs[index] = tab
    return tab
end

local function CreateTabContent(index)
    local c = CreateFrame("ScrollFrame", "HideAnythingTabScroll" .. index, panel, "UIPanelScrollFrameTemplate")
    c:SetPoint("TOPLEFT", INSET, -80)
    c:SetPoint("BOTTOMRIGHT", -INSET - 22, INSET + 28)
    c:Hide()

    local child = CreateFrame("Frame", "HideAnythingTabChild" .. index, c)
    child:SetWidth(PANEL_WIDTH - INSET * 2 - 30)
    child:SetHeight(1)
    c:SetScrollChild(child)

    tabContents[index] = { scroll = c, child = child }
    return child
end

-- Tab separator line
local tabSeparator = panel:CreateTexture(nil, "ARTWORK")
tabSeparator:SetHeight(1)
tabSeparator:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -74)
tabSeparator:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -74)
tabSeparator:SetColorTexture(0.2, 0.2, 0.22, 0.8)

function HA:SelectTab(index)
    for i, tab in pairs(tabs) do
        if i == index then
            tab.label:SetTextColor(1, 1, 1)
            tab._underline:Show()
            tabContents[i].scroll:Show()
        else
            tab.label:SetTextColor(0.5, 0.5, 0.55)
            tab._underline:Hide()
            tabContents[i].scroll:Hide()
        end
    end
    activeTab = index
    if index == 1 then self:RefreshFrameList() end
    if index == 2 then self:RefreshProfileList() end
end

---------------------------------------------------------------------------
-- WIDGET: Button (styled)
---------------------------------------------------------------------------
local function CreateStyledButton(parent, width, height, text, onClick)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height or 26)
    btn:SetBackdrop(BD_TOGGLE)
    btn:SetBackdropColor(0.15, 0.15, 0.18, 1)
    btn:SetBackdropBorderColor(0.3, 0.3, 0.33, 1)

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER")
    label:SetText(text)
    label:SetTextColor(0.9, 0.9, 0.9)
    btn._label = label

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(ACCENT_DIM_R, ACCENT_DIM_G, ACCENT_DIM_B, 0.6)
        self:SetBackdropBorderColor(ACCENT_R, ACCENT_G, ACCENT_B, 0.8)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.18, 1)
        self:SetBackdropBorderColor(0.3, 0.3, 0.33, 1)
    end)
    btn:SetScript("OnClick", onClick)
    return btn
end

---------------------------------------------------------------------------
-- WIDGET: Opacity slider popup (reusable singleton)
---------------------------------------------------------------------------
local alphaPopup = CreateFrame("Frame", "HideAnythingAlphaPopup", UIParent, "BackdropTemplate")
alphaPopup:SetSize(230, 105)
alphaPopup:SetFrameStrata("FULLSCREEN_DIALOG")
alphaPopup:SetFrameLevel(200)
alphaPopup:SetBackdrop(BD_POPUP)
alphaPopup:SetBackdropColor(0.08, 0.08, 0.10, 0.97)
alphaPopup:SetBackdropBorderColor(0.25, 0.25, 0.28, 1)
alphaPopup:SetMovable(true)
alphaPopup:EnableMouse(true)
alphaPopup:SetClampedToScreen(true)
alphaPopup:Hide()

-- Accent stripe on popup
local popupStripe = alphaPopup:CreateTexture(nil, "OVERLAY")
popupStripe:SetHeight(2)
popupStripe:SetPoint("TOPLEFT", alphaPopup, "TOPLEFT", 4, -4)
popupStripe:SetPoint("TOPRIGHT", alphaPopup, "TOPRIGHT", -4, -4)
popupStripe:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.7)

local alphaTitle = alphaPopup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
alphaTitle:SetPoint("TOP", 0, -12)

local alphaLabel = alphaPopup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
alphaLabel:SetPoint("TOP", 0, -32)

local alphaSlider = CreateFrame("Slider", "HideAnythingAlphaSlider", alphaPopup, "OptionsSliderTemplate")
alphaSlider:SetSize(190, 16)
alphaSlider:SetPoint("TOP", 0, -54)
alphaSlider:SetMinMaxValues(0, 100)
alphaSlider:SetValueStep(5)
alphaSlider:SetObeyStepOnDrag(true)
alphaSlider.Low:SetText("0%")
alphaSlider.High:SetText("100%")

local alphaCloseBtn = CreateFrame("Button", nil, alphaPopup, "UIPanelCloseButton")
alphaCloseBtn:SetPoint("TOPRIGHT", -1, -1)
alphaCloseBtn:SetSize(24, 24)
alphaCloseBtn:SetScript("OnClick", function() alphaPopup:Hide() end)

alphaPopup.currentFrame = nil

alphaSlider:SetScript("OnValueChanged", function(self, value)
    local L = HA.L
    value = math.floor(value + 0.5)
    alphaLabel:SetText(L["ALPHA_LABEL"]:format(value))
    if alphaPopup.currentFrame then
        HA:SetFrameAlpha(alphaPopup.currentFrame, value / 100)
    end
end)

function HA:ShowAlphaPopup(frameName, anchorFrame)
    local L = self.L
    alphaPopup.currentFrame = frameName
    alphaTitle:SetText("|cff00c761" .. frameName .. "|r")

    local currentAlpha = self:GetFrameAlpha(frameName)
    local pct = math.floor(currentAlpha * 100 + 0.5)
    alphaSlider:SetValue(pct)
    alphaLabel:SetText(L["ALPHA_LABEL"]:format(pct))

    alphaPopup:ClearAllPoints()
    if anchorFrame then
        alphaPopup:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 4, 0)
    else
        alphaPopup:SetPoint("CENTER")
    end
    alphaPopup:Show()
end

---------------------------------------------------------------------------
-- Search filter matching
---------------------------------------------------------------------------
local function MatchesFilter(entry, filter)
    if filter == "" then return true end
    local lowerFilter = strlower(filter)
    if entry.label and strfind(strlower(entry.label), lowerFilter, 1, true) then return true end
    if entry.labelDE and strfind(strlower(entry.labelDE), lowerFilter, 1, true) then return true end
    if entry.name and strfind(strlower(entry.name), lowerFilter, 1, true) then return true end
    if entry.cvar and strfind(strlower(entry.cvar), lowerFilter, 1, true) then return true end
    return false
end

local function SectionHasVisibleChildren(catalog, sectionIndex, filter)
    for i = sectionIndex + 1, #catalog do
        local entry = catalog[i]
        if entry.section then break end
        if not HA:IsEntryAvailable(entry) then
            -- skip entries not for this edition
        elseif filter == "" or MatchesFilter(entry, filter) then
            return true
        end
    end
    return false
end

---------------------------------------------------------------------------
-- Helper: configure a toggle knob
---------------------------------------------------------------------------
local function SetToggleState(toggleBg, knob, isOn)
    if isOn then
        toggleBg:SetBackdropColor(ACCENT_R, ACCENT_G, ACCENT_B, 1.0)
        toggleBg:SetBackdropBorderColor(ACCENT_R, ACCENT_G + 0.15, ACCENT_B + 0.1, 0.8)
        knob:ClearAllPoints()
        knob:SetPoint("RIGHT", toggleBg, "RIGHT", -3, 0)
        knob:SetColorTexture(1, 1, 1, 0.95)
    else
        toggleBg:SetBackdropColor(0.22, 0.08, 0.08, 1.0)
        toggleBg:SetBackdropBorderColor(0.45, 0.12, 0.12, 0.8)
        knob:ClearAllPoints()
        knob:SetPoint("LEFT", toggleBg, "LEFT", 3, 0)
        knob:SetColorTexture(0.65, 0.65, 0.65, 0.9)
    end
end

---------------------------------------------------------------------------
-- Helper: row hover handlers
---------------------------------------------------------------------------
local function RowOnEnter(self)
    if self._hoverTex then
        self._hoverTex:SetVertexColor(ACCENT_R, ACCENT_G, ACCENT_B, 0.07)
    end
end

local function RowOnLeave(self)
    if self._hoverTex then
        self._hoverTex:SetVertexColor(ACCENT_R, ACCENT_G, ACCENT_B, 0)
    end
    GameTooltip:Hide()
end

---------------------------------------------------------------------------
-- Settings rows (created once, never pooled)
---------------------------------------------------------------------------
local searchBox = nil
local searchIcon = nil

local function CreateSettingsBlock(parent)
    local L = HA.L
    local block = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    block:SetWidth(parent:GetWidth())
    block:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    block:SetBackdrop(BD_CARD)
    block:SetBackdropColor(0.09, 0.09, 0.11, 0.7)
    block:SetBackdropBorderColor(0.20, 0.20, 0.23, 0.6)

    -- Accent stripe at top of card
    local stripe = block:CreateTexture(nil, "OVERLAY")
    stripe:SetHeight(2)
    stripe:SetPoint("TOPLEFT", block, "TOPLEFT", 3, -3)
    stripe:SetPoint("TOPRIGHT", block, "TOPRIGHT", -3, -3)
    stripe:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.6)

    local y = -12

    -- Settings header
    local hdr = block:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    hdr:SetPoint("TOPLEFT", block, "TOPLEFT", 12, y)
    hdr:SetText("|cff00c761" .. L["CFG_HEADER_SETTINGS"] .. "|r")

    -- Edition badge next to header
    local edName = HA.EDITION_NAMES[HA.edition] or "Unknown"
    local edColor = HA.EDITION_COLORS[HA.edition] or "888888"
    local edBadge = block:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    edBadge:SetPoint("LEFT", hdr, "RIGHT", 10, 0)
    edBadge:SetText("|cff" .. edColor .. edName .. "|r")

    y = y - 8
    local hdrLine = block:CreateTexture(nil, "ARTWORK")
    hdrLine:SetHeight(1)
    hdrLine:SetPoint("TOPLEFT", hdr, "BOTTOMLEFT", 0, -4)
    hdrLine:SetPoint("RIGHT", block, "RIGHT", -12, 0)
    hdrLine:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.25)
    y = y - 20

    -- Settings toggle factory with description text
    local function MakeSettingsToggle(yPos, labelText, descText, getSetting, toggleFunc)
        local rowHeight = 38
        local row = CreateFrame("Frame", nil, block)
        row:SetSize(block:GetWidth() - 20, rowHeight)
        row:SetPoint("TOPLEFT", block, "TOPLEFT", 10, yPos)

        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("TOPLEFT", row, "TOPLEFT", 6, -4)
        lbl:SetText(labelText)
        lbl:SetTextColor(0.9, 0.9, 0.92)

        local desc = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        desc:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, -2)
        desc:SetText("|cff555560" .. descText .. "|r")
        desc:SetWidth(row:GetWidth() - TOGGLE_W - 30)
        desc:SetJustifyH("LEFT")

        local toggleBg = CreateFrame("Button", nil, row, "BackdropTemplate")
        toggleBg:SetSize(TOGGLE_W, TOGGLE_H)
        toggleBg:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        toggleBg:SetBackdrop(BD_TOGGLE)
        local knob = toggleBg:CreateTexture(nil, "OVERLAY")
        knob:SetSize(TOGGLE_H - 6, TOGGLE_H - 6)
        knob:SetTexture("Interface\\Buttons\\WHITE8X8")

        local function Refresh()
            SetToggleState(toggleBg, knob, getSetting())
        end
        Refresh()

        toggleBg:SetScript("OnClick", function()
            toggleFunc()
            Refresh()
            -- Refresh frame list if highlight setting changed
            if HA.RefreshFrameList then HA:RefreshFrameList() end
        end)

        -- Separator line
        local sep = row:CreateTexture(nil, "ARTWORK")
        sep:SetHeight(1)
        sep:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
        sep:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
        sep:SetColorTexture(0.18, 0.18, 0.20, 0.5)

        return yPos - rowHeight
    end

    y = MakeSettingsToggle(y, L["CFG_MINIMAP_BTN"], L["CFG_MINIMAP_BTN_TT"],
        function() return HA:GetSetting("showMinimap") end,
        function()
            local val = not HA:GetSetting("showMinimap")
            HA:SetSetting("showMinimap", val)
            if val then HA:ShowMinimapButton() else HA:HideMinimapButton() end
        end)

    y = MakeSettingsToggle(y, L["CFG_LOCK_MODE"], L["CFG_LOCK_MODE_TT"],
        function() return HA:GetSetting("locked") end,
        function() HA:SetSetting("locked", not HA:GetSetting("locked")) end)

    y = MakeSettingsToggle(y, L["CFG_CHAT_FEEDBACK"], L["CFG_CHAT_FEEDBACK_TT"],
        function() return HA:GetSetting("chatEnabled") end,
        function() HA:SetSetting("chatEnabled", not HA:GetSetting("chatEnabled")) end)

    -- Search bar with styled background
    y = y - 6
    local searchBg = CreateFrame("Frame", nil, block, "BackdropTemplate")
    searchBg:SetHeight(28)
    searchBg:SetPoint("TOPLEFT", block, "TOPLEFT", 10, y)
    searchBg:SetPoint("RIGHT", block, "RIGHT", -10, 0)
    searchBg:SetBackdrop(BD_SEARCH)
    searchBg:SetBackdropColor(0.06, 0.06, 0.08, 0.9)
    searchBg:SetBackdropBorderColor(0.22, 0.22, 0.25, 0.8)

    searchIcon = searchBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchIcon:SetPoint("LEFT", searchBg, "LEFT", 10, 0)
    searchIcon:SetText("|cff555560" .. L["SEARCH_PLACEHOLDER"] .. "|r")

    searchBox = CreateFrame("EditBox", "HideAnythingSearchBox", searchBg)
    searchBox:SetSize(searchBg:GetWidth() - 20, 20)
    searchBox:SetPoint("LEFT", searchBg, "LEFT", 10, 0)
    searchBox:SetPoint("RIGHT", searchBg, "RIGHT", -10, 0)
    searchBox:SetFontObject(GameFontNormal)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(50)
    searchBox:SetTextColor(0.9, 0.9, 0.95)

    searchBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        searchFilter = strtrim(text or "")
        if searchFilter ~= "" then
            searchIcon:Hide()
        else
            searchIcon:Show()
        end
        if self.refreshTimer then self.refreshTimer:Cancel() end
        self.refreshTimer = C_Timer.NewTimer(0.2, function()
            HA:RefreshFrameList()
        end)
    end)
    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        searchFilter = ""
        searchIcon:Show()
        self:ClearFocus()
        HA:RefreshFrameList()
    end)
    searchBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    searchBox:SetScript("OnEditFocusGained", function()
        searchBg:SetBackdropBorderColor(ACCENT_R, ACCENT_G, ACCENT_B, 0.6)
    end)
    searchBox:SetScript("OnEditFocusLost", function()
        searchBg:SetBackdropBorderColor(0.22, 0.22, 0.25, 0.8)
    end)

    y = y - 38

    block:SetHeight(math.abs(y) + 4)
    return block, y
end

---------------------------------------------------------------------------
-- BUILD: Tab 1 - Frame List with Toggles
---------------------------------------------------------------------------
local settingsBlock = nil
local settingsHeight = 0

local function BuildFramesTab(parent)
    settingsBlock, settingsHeight = CreateSettingsBlock(parent)
    tabContents[1].listParent = parent
end

function HA:RefreshFrameList()
    local L = self.L
    local tc = tabContents[1]
    if not tc or not tc.listParent then return end

    local parent = tc.listParent

    -- Release pooled objects
    ReleaseAllRows()
    ReleaseAllMisc()
    ReleaseAllFonts()
    ReleaseAllTextures()

    -- Start below the settings block
    local y = settingsHeight - 8

    -- Prominent "Frames hervorheben" toggle button
    local hlEnabled = self:GetSetting("highlightEnabled")
    local hlRow = AcquireMiscFrame(parent)
    hlRow:SetSize(parent:GetWidth() - 16, 30)
    hlRow:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)

    local hlBg = AcquireTexture(parent)
    hlBg:SetAllPoints(hlRow)
    if hlEnabled then
        hlBg:SetColorTexture(0.05, 0.20, 0.12, 0.7)
    else
        hlBg:SetColorTexture(0.12, 0.12, 0.14, 0.5)
    end

    local hlLabel = AcquireFont(parent, "GameFontNormal")
    hlLabel:SetPoint("LEFT", hlRow, "LEFT", 10, 0)
    if hlEnabled then
        hlLabel:SetText("|cff00ff66@|r  |cff00cc66" .. L["CFG_HIGHLIGHT_ENABLED"] .. "|r")
    else
        hlLabel:SetText("|cff555560@|r  |cff888888" .. L["CFG_HIGHLIGHT_ENABLED"] .. "|r")
    end

    local hlToggleBg = CreateFrame("Button", nil, hlRow, "BackdropTemplate")
    hlToggleBg:SetSize(TOGGLE_W, TOGGLE_H)
    hlToggleBg:SetPoint("RIGHT", hlRow, "RIGHT", -6, 0)
    hlToggleBg:SetBackdrop(BD_TOGGLE)
    local hlKnob = hlToggleBg:CreateTexture(nil, "OVERLAY")
    hlKnob:SetSize(TOGGLE_H - 6, TOGGLE_H - 6)
    hlKnob:SetTexture("Interface\\Buttons\\WHITE8X8")
    SetToggleState(hlToggleBg, hlKnob, hlEnabled)
    hlToggleBg:SetScript("OnClick", function()
        HA:SetSetting("highlightEnabled", not HA:GetSetting("highlightEnabled"))
        if not HA:GetSetting("highlightEnabled") then
            HA:UnhighlightFrame()
        end
        HA:RefreshFrameList()
    end)

    hlRow:EnableMouse(true)
    hlRow:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L["CFG_HIGHLIGHT_ENABLED"], ACCENT_R, ACCENT_G, ACCENT_B)
        GameTooltip:AddLine(L["CFG_HIGHLIGHT_ENABLED_TT"], 1, 1, 1, true)
        GameTooltip:Show()
    end)
    hlRow:SetScript("OnLeave", function() GameTooltip:Hide() end)

    y = y - 36

    -- Section: Frame Catalog header
    local catHdr = AcquireFont(parent, "GameFontNormal")
    catHdr:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, y)
    catHdr:SetText("|cff00c761" .. L["CFG_HEADER_FRAMES"] .. "|r")
    local catLine = AcquireTexture(parent)
    catLine:SetHeight(1)
    catLine:SetPoint("TOPLEFT", catHdr, "BOTTOMLEFT", 0, -3)
    catLine:SetPoint("RIGHT", parent, "RIGHT", -10, 0)
    catLine:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.3)
    y = y - 26

    local rowIndex = 0

    for catIndex, entry in ipairs(self.FRAME_CATALOG) do

        -- Skip entries not available in current edition
        if not entry.section and not self:IsEntryAvailable(entry) then
            -- skip

        -- Section header
        elseif entry.section then
            if SectionHasVisibleChildren(self.FRAME_CATALOG, catIndex, searchFilter) then
                y = y - 8
                local sectionLabel = self:GetCatalogLabel(entry)

                local secBg = AcquireMiscFrame(parent)
                secBg:SetSize(parent:GetWidth(), 20)
                secBg:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)

                local secHeader = AcquireFont(parent, "GameFontNormalSmall")
                secHeader:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, y - 3)
                secHeader:SetText("|cff70a890" .. sectionLabel .. "|r")

                local secLine = AcquireTexture(parent)
                secLine:SetHeight(1)
                secLine:SetPoint("TOPLEFT", secHeader, "BOTTOMLEFT", 0, -2)
                secLine:SetPoint("RIGHT", parent, "RIGHT", -10, 0)
                secLine:SetColorTexture(0.35, 0.55, 0.45, 0.25)
                y = y - 20
            end

        -- CVar-based toggle
        elseif entry.cvar then
            if MatchesFilter(entry, searchFilter) then
                local cvarName = entry.cvar
                local displayLabel = self:GetCatalogLabel(entry)
                local isHidden = self.db.hiddenCVars[cvarName] == true
                rowIndex = rowIndex + 1

                local row = AcquireRow(parent)
                row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)

                if rowIndex % 2 == 0 then
                    row:SetBackdrop(BD_ROW_ALT)
                    row:SetBackdropColor(0.12, 0.12, 0.14, 0.35)
                end

                row._label:SetText(displayLabel)
                row._label:SetTextColor(0.85, 0.85, 0.88)
                row._label:SetWidth(parent:GetWidth() * 0.42)

                -- Edition tag + CVar badge
                local edTag, edColor = self:GetEditionTag(entry)
                local techStr = "|cff555560CVar|r"
                if edTag then
                    techStr = "|cff" .. edColor .. edTag .. "|r |cff555560CVar|r"
                end
                row._techName:SetText(techStr)
                row._techName:SetWidth(parent:GetWidth() * 0.25)

                row._combatBtn:Hide()
                row._eyeBtn:Hide()
                row._alphaBtn:Hide()
                row._showBtn:Hide()

                row._toggleBg:Show()
                SetToggleState(row._toggleBg, row._toggleBg._knob, not isHidden)

                row._toggleBg:SetScript("OnClick", function()
                    if isHidden then
                        HA:ShowCVar(cvarName)
                    else
                        HA:HideCVar(cvarName)
                    end
                end)

                row:SetScript("OnEnter", function(self)
                    RowOnEnter(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:AddLine(displayLabel, ACCENT_R, ACCENT_G, ACCENT_B)
                    GameTooltip:AddLine("CVar: " .. cvarName, 0.5, 0.5, 0.5)
                    if edTag then
                        GameTooltip:AddLine(edTag, 0.5, 0.5, 0.5)
                    end
                    if isHidden then
                        GameTooltip:AddLine(L["FRAME_STATE_HIDDEN"], 1, 0.3, 0.3)
                    else
                        GameTooltip:AddLine(L["FRAME_STATE_VISIBLE"], 0.3, 1, 0.3)
                    end
                    GameTooltip:Show()
                end)
                row:SetScript("OnLeave", RowOnLeave)

                y = y - (ROW_HEIGHT + 1)
            end

        -- Frame-based toggle
        elseif entry.name then
            if MatchesFilter(entry, searchFilter) then
                local frameName = entry.name
                local displayLabel = self:GetCatalogLabel(entry)
                local isHidden = self.db.hiddenFrames[frameName] == true
                local frameExists = self:GetFrameByName(frameName) ~= nil
                local frameAlpha = self:GetFrameAlpha(frameName)
                rowIndex = rowIndex + 1

                local row = AcquireRow(parent)
                row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)

                if rowIndex % 2 == 0 then
                    row:SetBackdrop(BD_ROW_ALT)
                    row:SetBackdropColor(0.12, 0.12, 0.14, 0.35)
                end

                if not frameExists then
                    row._label:SetText("|cff555560" .. displayLabel .. "|r")
                else
                    row._label:SetText(displayLabel)
                    row._label:SetTextColor(0.85, 0.85, 0.88)
                end
                row._label:SetWidth(parent:GetWidth() * 0.33)

                -- Edition tag + frame name
                local edTag, edColor = self:GetEditionTag(entry)
                local techStr = "|cff555560" .. frameName .. "|r"
                if edTag then
                    techStr = "|cff" .. edColor .. edTag .. "|r " .. techStr
                end
                row._techName:SetText(techStr)
                row._techName:SetWidth(parent:GetWidth() * 0.18)

                -- Combat auto-hide button
                local isCombatHide = self.db.combatHideFrames and self.db.combatHideFrames[frameName]
                row._combatBtn:Show()
                if isCombatHide then
                    row._combatBtn:SetBackdropColor(0.35, 0.15, 0.08, 0.8)
                    row._combatBtn:SetBackdropBorderColor(0.6, 0.25, 0.1, 0.8)
                    row._combatBtn._text:SetText("|cfffe4422C|r")
                else
                    row._combatBtn:SetBackdropColor(0.10, 0.10, 0.12, 0.5)
                    row._combatBtn:SetBackdropBorderColor(0.22, 0.22, 0.25, 0.5)
                    row._combatBtn._text:SetText("|cff555560C|r")
                end
                row._combatBtn:SetScript("OnClick", function()
                    if not HA.db.combatHideFrames then HA.db.combatHideFrames = {} end
                    if HA.db.combatHideFrames[frameName] then
                        HA.db.combatHideFrames[frameName] = nil
                    else
                        HA.db.combatHideFrames[frameName] = true
                    end
                    HA:RefreshFrameList()
                end)
                row._combatBtn:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:AddLine(L["CFG_COMBAT_HIDE"], ACCENT_R, ACCENT_G, ACCENT_B)
                    GameTooltip:AddLine(L["CFG_COMBAT_HIDE_TT"], 1, 1, 1, true)
                    GameTooltip:Show()
                end)
                row._combatBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

                -- Eye button (highlight toggle) - always visible when highlight enabled
                if hlEnabled then
                    row._eyeBtn:Show()
                    local isHighlighted = (HA._highlightedFrame == frameName)
                    if isHighlighted then
                        row._eyeBtn._text:SetText("|cff00ff66@|r")
                    else
                        row._eyeBtn._text:SetText("|cff555560@|r")
                    end
                    row._eyeBtn:SetScript("OnClick", function()
                        if HA._highlightedFrame == frameName then
                            HA:UnhighlightFrame()
                            HA:RefreshFrameList()
                        else
                            HA:HighlightFrame(frameName)
                            HA:RefreshFrameList()
                        end
                    end)
                    row._eyeBtn:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:AddLine(L["CFG_HIGHLIGHT"], ACCENT_R, ACCENT_G, ACCENT_B)
                        GameTooltip:AddLine(L["CFG_HIGHLIGHT_TT"], 1, 1, 1, true)
                        GameTooltip:Show()
                    end)
                    row._eyeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
                else
                    row._eyeBtn:Hide()
                end

                -- Alpha button
                local alphaPct = math.floor(frameAlpha * 100 + 0.5)
                row._alphaBtn:Show()
                row._showBtn:Hide()

                if alphaPct < 100 then
                    row._alphaBtn:SetBackdropColor(0.12, 0.28, 0.45, 0.8)
                    row._alphaBtn:SetBackdropBorderColor(0.2, 0.4, 0.65, 0.8)
                    row._alphaBtn._text:SetText("|cff6699cc" .. alphaPct .. "%%|r")
                else
                    row._alphaBtn:SetBackdropColor(0.10, 0.10, 0.12, 0.5)
                    row._alphaBtn:SetBackdropBorderColor(0.22, 0.22, 0.25, 0.5)
                    row._alphaBtn._text:SetText("|cff555560" .. alphaPct .. "%%|r")
                end

                if frameExists then
                    row._alphaBtn:SetScript("OnClick", function(self)
                        HA:ShowAlphaPopup(frameName, self)
                    end)
                    row._alphaBtn:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:AddLine(L["ALPHA_TITLE"], ACCENT_R, ACCENT_G, ACCENT_B)
                        GameTooltip:AddLine(L["ALPHA_TOOLTIP"], 1, 1, 1, true)
                        GameTooltip:Show()
                    end)
                    row._alphaBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
                else
                    row._alphaBtn:SetScript("OnClick", nil)
                    row._alphaBtn:SetScript("OnEnter", nil)
                    row._alphaBtn:SetScript("OnLeave", nil)
                end

                -- Toggle button
                row._toggleBg:Show()
                if frameExists then
                    SetToggleState(row._toggleBg, row._toggleBg._knob, not isHidden)
                    row._toggleBg:SetScript("OnClick", function()
                        if isHidden then
                            HA:ShowFrame(frameName)
                        else
                            HA:HideFrame(frameName)
                        end
                    end)
                else
                    row._toggleBg:SetBackdropColor(0.15, 0.15, 0.17, 0.5)
                    row._toggleBg:SetBackdropBorderColor(0.22, 0.22, 0.25, 0.5)
                    row._toggleBg._knob:ClearAllPoints()
                    row._toggleBg._knob:SetPoint("LEFT", row._toggleBg, "LEFT", 3, 0)
                    row._toggleBg._knob:SetColorTexture(0.35, 0.35, 0.38, 0.5)
                    row._toggleBg:SetScript("OnClick", nil)
                    row._alphaBtn:SetBackdropColor(0.08, 0.08, 0.10, 0.3)
                    row._alphaBtn:SetBackdropBorderColor(0.15, 0.15, 0.18, 0.3)
                end

                -- Row tooltip with hover
                row:SetScript("OnEnter", function(self)
                    RowOnEnter(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:AddLine(displayLabel, ACCENT_R, ACCENT_G, ACCENT_B)
                    GameTooltip:AddLine(frameName, 0.5, 0.5, 0.5)
                    if edTag then
                        GameTooltip:AddLine(edTag, 0.5, 0.5, 0.5)
                    end
                    if not frameExists then
                        GameTooltip:AddLine(L["FRAME_NOT_LOADED"], 1, 0.5, 0)
                    elseif isHidden then
                        GameTooltip:AddLine(L["FRAME_STATE_HIDDEN"], 1, 0.3, 0.3)
                    else
                        GameTooltip:AddLine(L["FRAME_STATE_VISIBLE"], 0.3, 1, 0.3)
                    end
                    if frameAlpha < 1.0 then
                        GameTooltip:AddLine(L["FRAME_STATE_ALPHA"]:format(math.floor(frameAlpha * 100)), 0.4, 0.6, 0.85)
                    end
                    GameTooltip:Show()
                end)
                row:SetScript("OnLeave", RowOnLeave)

                y = y - (ROW_HEIGHT + 1)
            end
        end
    end

    -- Custom hidden frames (not in catalog)
    local customHidden = {}
    local catalogNames = {}
    for _, entry in ipairs(self.FRAME_CATALOG) do
        if entry.name then catalogNames[entry.name] = true end
    end
    for frameName, _ in pairs(self.db.hiddenFrames) do
        if not catalogNames[frameName] then
            table.insert(customHidden, frameName)
        end
    end

    if #customHidden > 0 then
        y = y - 10
        local chdr = AcquireFont(parent, "GameFontNormal")
        chdr:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, y)
        chdr:SetText("|cff00c761" .. L["CFG_HEADER_CUSTOM_HIDDEN"] .. "|r")
        local cline = AcquireTexture(parent)
        cline:SetHeight(1)
        cline:SetPoint("TOPLEFT", chdr, "BOTTOMLEFT", 0, -3)
        cline:SetPoint("RIGHT", parent, "RIGHT", -10, 0)
        cline:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.3)
        y = y - 26

        for i, frameName in ipairs(customHidden) do
            local row = AcquireRow(parent)
            row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)

            if i % 2 == 0 then
                row:SetBackdrop(BD_ROW_ALT)
                row:SetBackdropColor(0.12, 0.12, 0.14, 0.35)
            end

            row._label:SetText("|cffcc8800" .. frameName .. "|r")
            row._label:SetWidth(parent:GetWidth() - 100)
            row._techName:SetText("")
            row._eyeBtn:Hide()
            row._alphaBtn:Hide()
            row._toggleBg:Hide()

            row._showBtn:Show()
            row._showBtn:SetText(L["UI_BTN_SHOW"])
            row._showBtn:SetScript("OnClick", function()
                HA:ShowFrame(frameName)
            end)

            row:SetScript("OnEnter", RowOnEnter)
            row:SetScript("OnLeave", RowOnLeave)

            y = y - (ROW_HEIGHT + 1)
        end
    end

    -- Custom frame input
    y = y - 10
    local ciHdr = AcquireFont(parent, "GameFontNormal")
    ciHdr:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, y)
    ciHdr:SetText("|cff00c761" .. L["CFG_HEADER_CUSTOM"] .. "|r")
    local ciLine = AcquireTexture(parent)
    ciLine:SetHeight(1)
    ciLine:SetPoint("TOPLEFT", ciHdr, "BOTTOMLEFT", 0, -3)
    ciLine:SetPoint("RIGHT", parent, "RIGHT", -10, 0)
    ciLine:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.3)
    y = y - 28

    -- Reuse a persistent input row (created once)
    if not tc.customInputRow then
        local inputRow = CreateFrame("Frame", nil, parent)
        inputRow:SetSize(parent:GetWidth(), 32)

        local inputBg = CreateFrame("Frame", nil, inputRow, "BackdropTemplate")
        inputBg:SetHeight(28)
        inputBg:SetPoint("LEFT", inputRow, "LEFT", 8, 0)
        inputBg:SetPoint("RIGHT", inputRow, "RIGHT", -100, 0)
        inputBg:SetBackdrop(BD_SEARCH)
        inputBg:SetBackdropColor(0.06, 0.06, 0.08, 0.9)
        inputBg:SetBackdropBorderColor(0.22, 0.22, 0.25, 0.8)

        local inputBox = CreateFrame("EditBox", "HideAnythingCustomInput", inputBg)
        inputBox:SetSize(inputBg:GetWidth() - 16, 20)
        inputBox:SetPoint("LEFT", inputBg, "LEFT", 8, 0)
        inputBox:SetPoint("RIGHT", inputBg, "RIGHT", -8, 0)
        inputBox:SetFontObject(GameFontNormal)
        inputBox:SetAutoFocus(false)
        inputBox:SetMaxLetters(100)
        inputBox:SetTextColor(0.9, 0.9, 0.95)
        inputBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        inputBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

        inputBox:SetScript("OnEditFocusGained", function()
            inputBg:SetBackdropBorderColor(ACCENT_R, ACCENT_G, ACCENT_B, 0.6)
        end)
        inputBox:SetScript("OnEditFocusLost", function()
            inputBg:SetBackdropBorderColor(0.22, 0.22, 0.25, 0.8)
        end)

        local hideBtn = CreateStyledButton(inputRow, 80, 28, L["UI_BTN_HIDE"], function()
            local name = inputBox:GetText()
            if name and name ~= "" then
                HA:HideFrame(name)
                inputBox:SetText("")
            end
        end)
        hideBtn:SetPoint("RIGHT", inputRow, "RIGHT", -8, 0)

        tc.customInputRow = inputRow
    end

    tc.customInputRow:ClearAllPoints()
    tc.customInputRow:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    tc.customInputRow:Show()
    y = y - 40

    -- Action buttons (persistent)
    if not tc.actionRow then
        local actionRow = CreateFrame("Frame", nil, parent)
        actionRow:SetSize(parent:GetWidth(), 34)

        local showAllBtn = CreateStyledButton(actionRow, 150, 28, L["UI_BTN_SHOW_ALL"], function()
            HA:ShowAllFrames()
        end)
        showAllBtn:SetPoint("LEFT", actionRow, "LEFT", 8, 0)

        local resetBtn = CreateStyledButton(actionRow, 150, 28, L["UI_BTN_RESET"], function()
            StaticPopup_Show("HIDEANYTHING_CONFIRM_RESET")
        end)
        resetBtn:SetPoint("LEFT", showAllBtn, "RIGHT", 10, 0)
        -- Red tint for reset
        resetBtn:SetBackdropBorderColor(0.45, 0.2, 0.2, 1)
        resetBtn._label:SetTextColor(1, 0.6, 0.6)
        resetBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.35, 0.08, 0.08, 0.8)
            self:SetBackdropBorderColor(0.6, 0.15, 0.15, 1)
        end)
        resetBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.15, 0.15, 0.18, 1)
            self:SetBackdropBorderColor(0.45, 0.2, 0.2, 1)
        end)

        tc.actionRow = actionRow
    end

    tc.actionRow:ClearAllPoints()
    tc.actionRow:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    tc.actionRow:Show()
    y = y - 40

    parent:SetHeight(math.abs(y) + 10)

    -- Update status bar
    UpdateStatusBar()
end

---------------------------------------------------------------------------
-- BUILD: Tab 2 - Profiles
---------------------------------------------------------------------------
local function BuildProfilesTab(parent)
    local L = HA.L

    -- Profile name input area
    local inputCard = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    inputCard:SetSize(parent:GetWidth(), 110)
    inputCard:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -4)
    inputCard:SetBackdrop(BD_SECTION)
    inputCard:SetBackdropColor(0.10, 0.10, 0.12, 0.5)

    local inputLabel = inputCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    inputLabel:SetPoint("TOPLEFT", inputCard, "TOPLEFT", 12, -10)
    inputLabel:SetText("|cff00c761Profile Name:|r")

    local inputBg = CreateFrame("Frame", nil, inputCard, "BackdropTemplate")
    inputBg:SetSize(parent:GetWidth() - 140, 28)
    inputBg:SetPoint("TOPLEFT", inputCard, "TOPLEFT", 126, -6)
    inputBg:SetBackdrop(BD_SEARCH)
    inputBg:SetBackdropColor(0.06, 0.06, 0.08, 0.9)
    inputBg:SetBackdropBorderColor(0.22, 0.22, 0.25, 0.8)

    local inputBox = CreateFrame("EditBox", "HideAnythingProfileInput", inputBg)
    inputBox:SetSize(inputBg:GetWidth() - 16, 20)
    inputBox:SetPoint("LEFT", inputBg, "LEFT", 8, 0)
    inputBox:SetPoint("RIGHT", inputBg, "RIGHT", -8, 0)
    inputBox:SetFontObject(GameFontNormal)
    inputBox:SetAutoFocus(false)
    inputBox:SetMaxLetters(30)
    inputBox:SetTextColor(0.9, 0.9, 0.95)
    inputBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    inputBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    inputBox:SetScript("OnEditFocusGained", function()
        inputBg:SetBackdropBorderColor(ACCENT_R, ACCENT_G, ACCENT_B, 0.6)
    end)
    inputBox:SetScript("OnEditFocusLost", function()
        inputBg:SetBackdropBorderColor(0.22, 0.22, 0.25, 0.8)
    end)
    tabContents[2].inputBox = inputBox

    -- Button row 1
    local btnW = 130
    local btnY = -42
    local btn1 = CreateStyledButton(inputCard, btnW, 26, L["UI_BTN_SAVE_PROFILE"], function()
        local name = inputBox:GetText()
        if name and name ~= "" then HA:SaveProfile(name); HA:RefreshProfileList()
        else HA:Print(L["PROFILE_NAME_REQUIRED"]) end
    end)
    btn1:SetPoint("TOPLEFT", inputCard, "TOPLEFT", 10, btnY)

    local btn2 = CreateStyledButton(inputCard, btnW, 26, L["UI_BTN_LOAD_PROFILE"], function()
        local name = inputBox:GetText()
        if name and name ~= "" then HA:LoadProfile(name)
        else HA:Print(L["PROFILE_NAME_REQUIRED"]) end
    end)
    btn2:SetPoint("LEFT", btn1, "RIGHT", 6, 0)

    local btn3 = CreateStyledButton(inputCard, btnW, 26, L["UI_BTN_DELETE_PROFILE"], function()
        local name = inputBox:GetText()
        if name and name ~= "" then HA:DeleteProfile(name); HA:RefreshProfileList()
        else HA:Print(L["PROFILE_NAME_REQUIRED"]) end
    end)
    btn3:SetPoint("LEFT", btn2, "RIGHT", 6, 0)
    btn3:SetBackdropBorderColor(0.45, 0.2, 0.2, 1)
    btn3._label:SetTextColor(1, 0.6, 0.6)
    btn3:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.35, 0.08, 0.08, 0.8)
        self:SetBackdropBorderColor(0.6, 0.15, 0.15, 1)
    end)
    btn3:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.18, 1)
        self:SetBackdropBorderColor(0.45, 0.2, 0.2, 1)
    end)

    -- Button row 2
    btnY = btnY - 32
    local btn4 = CreateStyledButton(inputCard, btnW, 26, L["UI_BTN_EXPORT"], function()
        local name = inputBox:GetText()
        if name and name ~= "" then HA:ExportProfile(name)
        else HA:Print(L["PROFILE_NAME_REQUIRED"]) end
    end)
    btn4:SetPoint("TOPLEFT", inputCard, "TOPLEFT", 10, btnY)

    local btn5 = CreateStyledButton(inputCard, btnW, 26, L["UI_BTN_IMPORT"], function()
        HA:ShowImportDialog()
    end)
    btn5:SetPoint("LEFT", btn4, "RIGHT", 6, 0)

    -- Profile list area
    local profileListHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    profileListHeader:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -124)
    tabContents[2].profileListHeader = profileListHeader
    tabContents[2].listParent = parent
    tabContents[2].listStartY = -148
    tabContents[2].rows = {}
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

    tc.profileListHeader:SetText("|cff00c761" .. L["PROFILE_LIST_HEADER"]:format(profileCount) .. "|r")

    for _, row in ipairs(tc.rows) do
        row:Hide()
    end
    wipe(tc.rows)

    local y = tc.listStartY or -148

    if profileCount == 0 then
        local holder = CreateFrame("Frame", nil, parent)
        holder:SetSize(1, 1)
        local emptyLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        emptyLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y)
        emptyLabel:SetText(L["PROFILE_NO_PROFILES"])
        emptyLabel:SetTextColor(0.4, 0.4, 0.45)
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
        row:SetSize(parent:GetWidth(), ROW_HEIGHT + 2)
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)

        if i % 2 == 0 then
            row:SetBackdrop(BD_ROW_ALT)
            row:SetBackdropColor(0.12, 0.12, 0.14, 0.35)
        end

        -- Hover highlight
        local hoverTex = row:CreateTexture(nil, "BACKGROUND")
        hoverTex:SetAllPoints()
        hoverTex:SetTexture("Interface\\Buttons\\WHITE8X8")
        hoverTex:SetVertexColor(ACCENT_R, ACCENT_G, ACCENT_B, 0)
        row:EnableMouse(true)
        row:SetScript("OnEnter", function()
            hoverTex:SetVertexColor(ACCENT_R, ACCENT_G, ACCENT_B, 0.07)
        end)
        row:SetScript("OnLeave", function()
            hoverTex:SetVertexColor(ACCENT_R, ACCENT_G, ACCENT_B, 0)
        end)

        local active = (self.db.activeProfile == profileName) and " |cff00ff66*|r" or ""
        local nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameLabel:SetPoint("LEFT", row, "LEFT", 12, 0)
        nameLabel:SetText("|cff00c761" .. profileName .. "|r" .. active .. " |cff555560(" .. frameCount .. " frames)|r")

        local loadBtn = CreateStyledButton(row, 56, 22, "Load", function()
            HA:LoadProfile(profileName)
            if tc.inputBox then tc.inputBox:SetText(profileName) end
            HA:RefreshProfileList()
        end)
        loadBtn:SetPoint("RIGHT", row, "RIGHT", -66, 0)

        local delBtn = CreateStyledButton(row, 56, 22, "Del", function()
            HA:DeleteProfile(profileName)
            HA:RefreshProfileList()
        end)
        delBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        delBtn:SetBackdropBorderColor(0.45, 0.2, 0.2, 1)
        delBtn._label:SetTextColor(1, 0.6, 0.6)
        delBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.35, 0.08, 0.08, 0.8)
            self:SetBackdropBorderColor(0.6, 0.15, 0.15, 1)
        end)
        delBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.15, 0.15, 0.18, 1)
            self:SetBackdropBorderColor(0.45, 0.2, 0.2, 1)
        end)

        table.insert(tc.rows, row)
        y = y - (ROW_HEIGHT + 3)
        i = i + 1
    end

    parent:SetHeight(math.abs(y) + 10)
end

---------------------------------------------------------------------------
-- BUILD: Tab 3 - About
---------------------------------------------------------------------------
local function BuildAboutTab(parent)
    local L = HA.L
    local y = -12

    -- Logo / title area
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
    title:SetText("|cff00c761Hide|r|cffffffffAnything|r")
    y = y - 26

    local ver = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ver:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
    ver:SetText(L["VERSION"] .. ": |cffffffff" .. HA.version .. "|r")
    y = y - 20

    local author = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    author:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
    author:SetText("Author: |cffffffffJugoBetrugoTV|r")
    y = y - 12

    -- Separator
    local sep = parent:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
    sep:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
    sep:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.3)
    y = y - 16

    local desc = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
    desc:SetWidth(parent:GetWidth() - 32)
    desc:SetJustifyH("LEFT")
    desc:SetSpacing(3)
    desc:SetText(
        "|cff00c761Hide Anything|r " .. L["ABOUT_DESC"] .. "\n\n" ..
        "|cff00c761" .. L["ABOUT_FEATURES"] .. "|r\n" ..
        "  |cff70a890-|r " .. L["ABOUT_F1"] .. "\n" ..
        "  |cff70a890-|r " .. L["ABOUT_F2"] .. "\n" ..
        "  |cff70a890-|r " .. L["ABOUT_F3"] .. "\n" ..
        "  |cff70a890-|r " .. L["ABOUT_F4"] .. "\n" ..
        "  |cff70a890-|r " .. L["ABOUT_F5"] .. "\n" ..
        "  |cff70a890-|r " .. L["ABOUT_F6"] .. "\n" ..
        "  |cff70a890-|r " .. L["ABOUT_F7"] .. "\n" ..
        "  |cff70a890-|r " .. L["ABOUT_F8"] .. "\n" ..
        "  |cff70a890-|r " .. L["ABOUT_F9"] .. "\n\n" ..
        "|cff70a890Commands:|r |cff00c761/ha|r or |cff00c761/hideanything|r\n" ..
        "|cff70a890Config:|r   |cff00c761/ha toggle|r\n\n" ..
        "|cff70a890Edition:|r  |cff" .. (HA.EDITION_COLORS[HA.edition] or "ffffff") .. (HA.EDITION_NAMES[HA.edition] or "Unknown") .. "|r"
    )

    parent:SetHeight(320)
end

---------------------------------------------------------------------------
-- Build everything
---------------------------------------------------------------------------
local function BuildPanel()
    local L = HA.L

    titleText:SetText("|cff00c761Hide|r|cffffffffAnything|r")
    versionText:SetText("v" .. HA.version)

    local tabNames = { L["UI_FRAMES"], L["UI_PROFILES"], L["UI_ABOUT"] }
    local tabWidth = (PANEL_WIDTH - INSET * 2) / #tabNames
    for i, name in ipairs(tabNames) do
        local tab = CreateTab(i, name)
        tab:SetSize(tabWidth, TAB_HEIGHT)
        tab:SetPoint("TOPLEFT", panel, "TOPLEFT", INSET + (i - 1) * tabWidth, -42)
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
    dialog:SetSize(440, 280)
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:SetBackdrop(BD_POPUP)
    dialog:SetBackdropColor(0.08, 0.08, 0.10, 0.97)
    dialog:SetBackdropBorderColor(0.25, 0.25, 0.28, 1)

    -- Accent stripe
    local stripe = dialog:CreateTexture(nil, "OVERLAY")
    stripe:SetHeight(2)
    stripe:SetPoint("TOPLEFT", dialog, "TOPLEFT", 4, -4)
    stripe:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -4, -4)
    stripe:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.9)

    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText("|cff00c761Export Profile|r")

    local sf = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 16, -44)
    sf:SetPoint("BOTTOMRIGHT", -32, 48)

    local eb = CreateFrame("EditBox", nil, sf)
    eb:SetMultiLine(true)
    eb:SetFontObject(ChatFontNormal)
    eb:SetWidth(380)
    eb:SetText(data)
    eb:HighlightText()
    eb:SetAutoFocus(true)
    sf:SetScrollChild(eb)

    local btn = CreateStyledButton(dialog, 90, 26, HA.L["UI_BTN_CLOSE"], function()
        dialog:Hide()
    end)
    btn:SetPoint("BOTTOM", 0, 14)

    eb:SetScript("OnEscapePressed", function() dialog:Hide() end)
end

---------------------------------------------------------------------------
-- Import dialog
---------------------------------------------------------------------------
function HA:ShowImportDialog()
    local dialog = CreateFrame("Frame", "HideAnythingImportFrame", UIParent, "BackdropTemplate")
    dialog:SetSize(440, 280)
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:SetBackdrop(BD_POPUP)
    dialog:SetBackdropColor(0.08, 0.08, 0.10, 0.97)
    dialog:SetBackdropBorderColor(0.25, 0.25, 0.28, 1)

    -- Accent stripe
    local stripe = dialog:CreateTexture(nil, "OVERLAY")
    stripe:SetHeight(2)
    stripe:SetPoint("TOPLEFT", dialog, "TOPLEFT", 4, -4)
    stripe:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -4, -4)
    stripe:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.9)

    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText("|cff00c761Import Profile|r")

    local sf = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 16, -44)
    sf:SetPoint("BOTTOMRIGHT", -32, 48)

    local eb = CreateFrame("EditBox", nil, sf)
    eb:SetMultiLine(true)
    eb:SetFontObject(ChatFontNormal)
    eb:SetWidth(380)
    eb:SetAutoFocus(true)
    sf:SetScrollChild(eb)

    local importBtn = CreateStyledButton(dialog, 90, 26, HA.L["UI_BTN_IMPORT"], function()
        HA:ImportProfile(eb:GetText())
        dialog:Hide()
        HA:RefreshProfileList()
    end)
    importBtn:SetPoint("BOTTOMLEFT", 70, 14)

    local closeBtn = CreateStyledButton(dialog, 90, 26, HA.L["UI_BTN_CLOSE"], function()
        dialog:Hide()
    end)
    closeBtn:SetPoint("BOTTOMRIGHT", -70, 14)

    eb:SetScript("OnEscapePressed", function() dialog:Hide() end)
end

---------------------------------------------------------------------------
-- ESC to close
---------------------------------------------------------------------------
tinsert(UISpecialFrames, "HideAnythingOptionsFrame")
