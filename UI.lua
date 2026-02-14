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
local tabContents = {}
local activeTab = nil
local searchFilter = ""  -- current search text

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
        lbl:SetPoint("LEFT", row, "LEFT", 8, 0)
        lbl:SetJustifyH("LEFT")
        row._label = lbl

        local tech = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        tech:SetPoint("LEFT", lbl, "RIGHT", 4, 0)
        tech:SetJustifyH("LEFT")
        row._techName = tech

        -- Eye button for highlight
        local eyeBtn = CreateFrame("Button", nil, row)
        eyeBtn:SetSize(20, 20)
        eyeBtn:SetPoint("RIGHT", row, "RIGHT", -100, 0)
        local eyeText = eyeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        eyeText:SetPoint("CENTER")
        eyeBtn._text = eyeText
        row._eyeBtn = eyeBtn

        -- Alpha button
        local alphaBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
        alphaBtn:SetSize(38, 18)
        alphaBtn:SetPoint("RIGHT", row, "RIGHT", -54, 0)
        alphaBtn:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        local alphaText = alphaBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        alphaText:SetPoint("CENTER")
        alphaBtn._text = alphaText
        row._alphaBtn = alphaBtn

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
        toggleBg._knob = knob
        row._toggleBg = toggleBg

        -- Show button (for custom hidden frames)
        local showBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        showBtn:SetSize(70, 20)
        showBtn:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        row._showBtn = showBtn

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
        -- Reparent not possible for textures, just reuse from same parent
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
closeBtn:SetScript("OnClick", function()
    panel:Hide()
    HA:UnhighlightFrame()
end)

-- Also unhighlight when panel hides
panel:SetScript("OnHide", function()
    HA:UnhighlightFrame()
end)

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

    tabContents[index] = { scroll = c, child = child }
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
-- WIDGET: Opacity slider popup (reusable singleton)
---------------------------------------------------------------------------
local alphaPopup = CreateFrame("Frame", "HideAnythingAlphaPopup", UIParent, "BackdropTemplate")
alphaPopup:SetSize(220, 100)
alphaPopup:SetFrameStrata("FULLSCREEN_DIALOG")
alphaPopup:SetFrameLevel(200)
alphaPopup:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile     = true, tileSize = 32, edgeSize = 24,
    insets   = { left = 6, right = 6, top = 6, bottom = 6 },
})
alphaPopup:SetMovable(true)
alphaPopup:EnableMouse(true)
alphaPopup:SetClampedToScreen(true)
alphaPopup:Hide()

local alphaTitle = alphaPopup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
alphaTitle:SetPoint("TOP", 0, -12)

local alphaLabel = alphaPopup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
alphaLabel:SetPoint("TOP", 0, -30)

local alphaSlider = CreateFrame("Slider", "HideAnythingAlphaSlider", alphaPopup, "OptionsSliderTemplate")
alphaSlider:SetSize(180, 16)
alphaSlider:SetPoint("TOP", 0, -52)
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
    alphaTitle:SetText("|cff00cc66" .. frameName .. "|r")

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
    if filter == "" then return true end
    for i = sectionIndex + 1, #catalog do
        local entry = catalog[i]
        if entry.section then break end
        if MatchesFilter(entry, filter) then return true end
    end
    return false
end

---------------------------------------------------------------------------
-- Helper: configure a toggle knob
---------------------------------------------------------------------------
local function SetToggleState(toggleBg, knob, isOn)
    if isOn then
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

---------------------------------------------------------------------------
-- Settings rows (created once, never pooled)
---------------------------------------------------------------------------
local settingsFrame = nil
local searchBox = nil
local searchIcon = nil

local function CreateSettingsBlock(parent)
    local L = HA.L
    local block = CreateFrame("Frame", nil, parent)
    block:SetWidth(parent:GetWidth())
    block:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)

    local y = -4

    -- Settings header
    local hdr = block:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hdr:SetPoint("TOPLEFT", block, "TOPLEFT", 4, y)
    hdr:SetText("|cff00cc66" .. L["CFG_HEADER_SETTINGS"] .. "|r")
    local hdrLine = block:CreateTexture(nil, "ARTWORK")
    hdrLine:SetHeight(1)
    hdrLine:SetPoint("TOPLEFT", hdr, "BOTTOMLEFT", 0, -2)
    hdrLine:SetPoint("RIGHT", block, "RIGHT", -4, 0)
    hdrLine:SetColorTexture(0, 0.8, 0.4, 0.4)
    y = y - 24

    -- Minimap toggle
    local function MakeSettingsToggle(yPos, labelText, ttTitle, ttDesc, getSetting, toggleFunc)
        local row = CreateFrame("Frame", nil, block)
        row:SetSize(block:GetWidth(), 28)
        row:SetPoint("TOPLEFT", block, "TOPLEFT", 0, yPos)

        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lbl:SetPoint("LEFT", row, "LEFT", 8, 0)
        lbl:SetText(labelText)

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

        local function Refresh()
            SetToggleState(toggleBg, knob, getSetting())
        end
        Refresh()

        toggleBg:SetScript("OnClick", function()
            toggleFunc()
            Refresh()
        end)

        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(ttTitle, 0, 0.8, 0.4)
            GameTooltip:AddLine(ttDesc, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)

        return yPos - 30
    end

    y = MakeSettingsToggle(y, L["CFG_MINIMAP_BTN"], L["CFG_MINIMAP_BTN"], L["CFG_MINIMAP_BTN_TT"],
        function() return HA:GetSetting("showMinimap") end,
        function()
            local val = not HA:GetSetting("showMinimap")
            HA:SetSetting("showMinimap", val)
            if val then HA:ShowMinimapButton() else HA:HideMinimapButton() end
        end)

    y = MakeSettingsToggle(y, L["CFG_LOCK_MODE"], L["CFG_LOCK_MODE"], L["CFG_LOCK_MODE_TT"],
        function() return HA:GetSetting("locked") end,
        function() HA:SetSetting("locked", not HA:GetSetting("locked")) end)

    -- Search bar
    y = y - 4
    local searchRow = CreateFrame("Frame", nil, block)
    searchRow:SetSize(block:GetWidth(), 28)
    searchRow:SetPoint("TOPLEFT", block, "TOPLEFT", 0, y)

    searchIcon = searchRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchIcon:SetPoint("LEFT", searchRow, "LEFT", 8, 0)
    searchIcon:SetText("|cff888888" .. L["SEARCH_PLACEHOLDER"] .. "|r")

    searchBox = CreateFrame("EditBox", "HideAnythingSearchBox", searchRow, "InputBoxTemplate")
    searchBox:SetSize(block:GetWidth() - 20, 22)
    searchBox:SetPoint("LEFT", searchRow, "LEFT", 8, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(50)

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

    y = y - 32

    block:SetHeight(math.abs(y))
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
    local y = settingsHeight - 4

    -- Section: Frame Catalog header
    local catHdr = AcquireFont(parent, "GameFontNormal")
    catHdr:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, y)
    catHdr:SetText("|cff00cc66" .. L["CFG_HEADER_FRAMES"] .. "|r")
    local catLine = AcquireTexture(parent)
    catLine:SetHeight(1)
    catLine:SetPoint("TOPLEFT", catHdr, "BOTTOMLEFT", 0, -2)
    catLine:SetPoint("RIGHT", parent, "RIGHT", -4, 0)
    catLine:SetColorTexture(0, 0.8, 0.4, 0.4)
    y = y - 24

    local rowIndex = 0
    for catIndex, entry in ipairs(self.FRAME_CATALOG) do

        -- Section header
        if entry.section then
            if SectionHasVisibleChildren(self.FRAME_CATALOG, catIndex, searchFilter) then
                y = y - 6
                local sectionLabel = self:GetCatalogLabel(entry)
                local secHeader = AcquireFont(parent, "GameFontNormalSmall")
                secHeader:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, y)
                secHeader:SetText("|cff88bbaa" .. sectionLabel .. "|r")

                local secLine = AcquireTexture(parent)
                secLine:SetHeight(1)
                secLine:SetPoint("TOPLEFT", secHeader, "BOTTOMLEFT", 0, -1)
                secLine:SetPoint("RIGHT", parent, "RIGHT", -4, 0)
                secLine:SetColorTexture(0.4, 0.7, 0.5, 0.3)
                y = y - 16
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
                    row:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background" })
                    row:SetBackdropColor(0.15, 0.15, 0.15, 0.3)
                end

                row._label:SetText(displayLabel)
                row._label:SetWidth(parent:GetWidth() * 0.45)

                row._techName:SetText("|cff888888CVar|r")
                row._techName:SetWidth(parent:GetWidth() * 0.3)

                -- Hide eye/alpha buttons for CVars
                row._eyeBtn:Hide()
                row._alphaBtn:Hide()
                row._showBtn:Hide()

                -- Show toggle
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
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:AddLine(displayLabel, 0, 0.8, 0.4)
                    GameTooltip:AddLine("CVar: " .. cvarName, 0.5, 0.5, 0.5)
                    if isHidden then
                        GameTooltip:AddLine(L["FRAME_STATE_HIDDEN"], 1, 0.3, 0.3)
                    else
                        GameTooltip:AddLine(L["FRAME_STATE_VISIBLE"], 0, 1, 0)
                    end
                    GameTooltip:Show()
                end)
                row:SetScript("OnLeave", function() GameTooltip:Hide() end)

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
                    row:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background" })
                    row:SetBackdropColor(0.15, 0.15, 0.15, 0.3)
                end

                if not frameExists then
                    row._label:SetText("|cff666666" .. displayLabel .. "|r")
                else
                    row._label:SetText(displayLabel)
                end
                row._label:SetWidth(parent:GetWidth() * 0.35)

                row._techName:SetText("|cff888888" .. frameName .. "|r")
                row._techName:SetWidth(parent:GetWidth() * 0.18)

                -- Eye button (highlight toggle)
                row._eyeBtn:Show()
                local isHighlighted = (HA._highlightedFrame == frameName)
                if isHighlighted then
                    row._eyeBtn._text:SetText("|cff00ff00@|r")
                else
                    row._eyeBtn._text:SetText("|cff888888@|r")
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
                    GameTooltip:AddLine(L["CFG_HIGHLIGHT"], 0, 0.8, 0.4)
                    GameTooltip:AddLine(L["CFG_HIGHLIGHT_TT"], 1, 1, 1, true)
                    GameTooltip:Show()
                end)
                row._eyeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

                -- Alpha button
                local alphaPct = math.floor(frameAlpha * 100 + 0.5)
                row._alphaBtn:Show()
                row._showBtn:Hide()

                if alphaPct < 100 then
                    row._alphaBtn:SetBackdropColor(0.2, 0.4, 0.6, 0.8)
                    row._alphaBtn:SetBackdropBorderColor(0.3, 0.5, 0.8, 0.8)
                    row._alphaBtn._text:SetText("|cff88bbff" .. alphaPct .. "%%|r")
                else
                    row._alphaBtn:SetBackdropColor(0.15, 0.15, 0.15, 0.5)
                    row._alphaBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.5)
                    row._alphaBtn._text:SetText("|cff666666" .. alphaPct .. "%%|r")
                end

                if frameExists then
                    row._alphaBtn:SetScript("OnClick", function(self)
                        HA:ShowAlphaPopup(frameName, self)
                    end)
                    row._alphaBtn:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:AddLine(L["ALPHA_TITLE"], 0, 0.8, 0.4)
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
                    row._toggleBg:SetBackdropColor(0.2, 0.2, 0.2, 0.5)
                    row._toggleBg:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.5)
                    row._toggleBg._knob:ClearAllPoints()
                    row._toggleBg._knob:SetPoint("LEFT", row._toggleBg, "LEFT", 2, 0)
                    row._toggleBg._knob:SetColorTexture(0.4, 0.4, 0.4, 0.5)
                    row._toggleBg:SetScript("OnClick", nil)
                    row._alphaBtn:SetBackdropColor(0.1, 0.1, 0.1, 0.3)
                    row._alphaBtn:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.3)
                end

                -- Row tooltip
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
                    if frameAlpha < 1.0 then
                        GameTooltip:AddLine(L["FRAME_STATE_ALPHA"]:format(math.floor(frameAlpha * 100)), 0.5, 0.7, 1.0)
                    end
                    GameTooltip:Show()
                end)
                row:SetScript("OnLeave", function() GameTooltip:Hide() end)

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
        y = y - 8
        local chdr = AcquireFont(parent, "GameFontNormal")
        chdr:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, y)
        chdr:SetText("|cff00cc66" .. L["CFG_HEADER_CUSTOM_HIDDEN"] .. "|r")
        local cline = AcquireTexture(parent)
        cline:SetHeight(1)
        cline:SetPoint("TOPLEFT", chdr, "BOTTOMLEFT", 0, -2)
        cline:SetPoint("RIGHT", parent, "RIGHT", -4, 0)
        cline:SetColorTexture(0, 0.8, 0.4, 0.4)
        y = y - 24

        for i, frameName in ipairs(customHidden) do
            local row = AcquireRow(parent)
            row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)

            if i % 2 == 0 then
                row:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background" })
                row:SetBackdropColor(0.15, 0.15, 0.15, 0.3)
            end

            row._label:SetText("|cffff8800" .. frameName .. "|r")
            row._label:SetWidth(parent:GetWidth() - 90)
            row._techName:SetText("")
            row._eyeBtn:Hide()
            row._alphaBtn:Hide()
            row._toggleBg:Hide()

            row._showBtn:Show()
            row._showBtn:SetText(L["UI_BTN_SHOW"])
            row._showBtn:SetScript("OnClick", function()
                HA:ShowFrame(frameName)
            end)

            y = y - (ROW_HEIGHT + 1)
        end
    end

    -- Custom frame input
    y = y - 8
    local ciHdr = AcquireFont(parent, "GameFontNormal")
    ciHdr:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, y)
    ciHdr:SetText("|cff00cc66" .. L["CFG_HEADER_CUSTOM"] .. "|r")
    local ciLine = AcquireTexture(parent)
    ciLine:SetHeight(1)
    ciLine:SetPoint("TOPLEFT", ciHdr, "BOTTOMLEFT", 0, -2)
    ciLine:SetPoint("RIGHT", parent, "RIGHT", -4, 0)
    ciLine:SetColorTexture(0, 0.8, 0.4, 0.4)
    y = y - 26

    -- Reuse a persistent input row (created once)
    if not tc.customInputRow then
        local inputRow = CreateFrame("Frame", nil, parent)
        inputRow:SetSize(parent:GetWidth(), 30)

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
                HA:HideFrame(name)
                inputBox:SetText("")
            end
        end)

        tc.customInputRow = inputRow
    end

    tc.customInputRow:ClearAllPoints()
    tc.customInputRow:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    tc.customInputRow:Show()
    y = y - 36

    -- Action buttons (persistent)
    if not tc.actionRow then
        local actionRow = CreateFrame("Frame", nil, parent)
        actionRow:SetSize(parent:GetWidth(), 30)

        local showAllBtn = CreateFrame("Button", nil, actionRow, "UIPanelButtonTemplate")
        showAllBtn:SetSize(140, 26)
        showAllBtn:SetPoint("LEFT", actionRow, "LEFT", 8, 0)
        showAllBtn:SetText(L["UI_BTN_SHOW_ALL"])
        showAllBtn:SetScript("OnClick", function() HA:ShowAllFrames() end)

        local resetBtn = CreateFrame("Button", nil, actionRow, "UIPanelButtonTemplate")
        resetBtn:SetSize(140, 26)
        resetBtn:SetPoint("LEFT", showAllBtn, "RIGHT", 8, 0)
        resetBtn:SetText(L["UI_BTN_RESET"])
        resetBtn:SetScript("OnClick", function() StaticPopup_Show("HIDEANYTHING_CONFIRM_RESET") end)

        tc.actionRow = actionRow
    end

    tc.actionRow:ClearAllPoints()
    tc.actionRow:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    tc.actionRow:Show()
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

    tc.profileListHeader:SetText(L["PROFILE_LIST_HEADER"]:format(profileCount))

    for _, row in ipairs(tc.rows) do
        row:Hide()
    end
    wipe(tc.rows)

    local y = tc.listStartY or -130

    if profileCount == 0 then
        local holder = CreateFrame("Frame", nil, parent)
        holder:SetSize(1, 1)
        local emptyLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        emptyLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)
        emptyLabel:SetText(L["PROFILE_NO_PROFILES"])
        emptyLabel:SetTextColor(0.5, 0.5, 0.5)
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
        "  |cffffffff-|r " .. L["ABOUT_F6"] .. "\n" ..
        "  |cffffffff-|r " .. L["ABOUT_F7"] .. "\n\n" ..
        "Commands: |cff00cc66/ha|r or |cff00cc66/hideanything|r\n" ..
        "Config:   |cff00cc66/ha toggle|r"
    )

    parent:SetHeight(300)
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
