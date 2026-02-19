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
local showHiddenOnly = false  -- filter to show only hidden items
local collapsedSections = {} -- collapsed section state (by label)

-- Debounce timer for RefreshFrameList
local refreshPending = false
local REFRESH_THROTTLE = 0.05

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
-- Gradient helper (Retail 10.0+ and Classic compatible)
---------------------------------------------------------------------------
local function ApplyGradient(tex, orientation, r1, g1, b1, a1, r2, g2, b2, a2)
    if tex.SetGradient then
        local ok = pcall(function()
            tex:SetGradient(orientation, CreateColor(r1, g1, b1, a1), CreateColor(r2, g2, b2, a2))
        end)
        if ok then return end
    end
    if tex.SetGradientAlpha then
        pcall(tex.SetGradientAlpha, tex, orientation, r1, g1, b1, a1, r2, g2, b2, a2)
    end
end

-- Helper: create a horizontal gradient bar texture
local function CreateGradientBar(parent, layer, height, anchor, r, g, b, alphaFrom, alphaTo, orientation)
    local tex = parent:CreateTexture(nil, layer or "ARTWORK")
    tex:SetHeight(height or 2)
    if anchor == "TOP" then
        tex:SetPoint("TOPLEFT", parent, "TOPLEFT", 3, -3)
        tex:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -3, -3)
    elseif anchor == "BOTTOM" then
        tex:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 3, 3)
        tex:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -3, 3)
    end
    tex:SetColorTexture(1, 1, 1, 1)
    ApplyGradient(tex, orientation or "VERTICAL", r, g, b, alphaFrom or 0.15, r, g, b, alphaTo or 0)
    return tex
end

---------------------------------------------------------------------------
-- Text truncation helper
---------------------------------------------------------------------------
local MAX_LABEL_CHARS = 32

local function TruncateText(text, maxLen)
    maxLen = maxLen or MAX_LABEL_CHARS
    if not text then return "" end
    -- Strip color codes for length check
    local plain = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    if #plain <= maxLen then return text end
    -- Improvement #18: handle edge case where name < 3 chars
    local cutLen = math.max(1, maxLen - 2)
    local truncated = strsub(plain, 1, cutLen) .. ".."
    return truncated
end

---------------------------------------------------------------------------
-- Search highlighting helper
---------------------------------------------------------------------------
local function HighlightSearch(text, filter)
    if not filter or filter == "" then return text end
    local lower = strlower(text)
    local start, stop = strfind(lower, filter, 1, true)
    if not start then return text end
    local before = strsub(text, 1, start - 1)
    local match  = strsub(text, start, stop)
    local after  = strsub(text, stop + 1)
    return before .. "|cffFFFF00" .. match .. "|r" .. after
end

---------------------------------------------------------------------------
-- Right-click context menu
---------------------------------------------------------------------------
local contextMenu = CreateFrame("Frame", "HideAnythingContextMenu", UIParent, "BackdropTemplate")
contextMenu:SetSize(180, 10)
contextMenu:SetFrameStrata("FULLSCREEN_DIALOG")
contextMenu:SetFrameLevel(300)
contextMenu:SetBackdrop(BD_POPUP)
contextMenu:SetBackdropColor(0.08, 0.08, 0.10, 0.97)
contextMenu:SetBackdropBorderColor(0.30, 0.30, 0.33, 1)
contextMenu:EnableMouse(true)
contextMenu:Hide()
contextMenu._items = {}

local function ClearContextMenu()
    for _, item in ipairs(contextMenu._items) do
        item:Hide()
    end
    wipe(contextMenu._items)
    contextMenu:Hide()
end

local function AddContextItem(text, onClick)
    local idx = #contextMenu._items + 1
    local item = CreateFrame("Button", nil, contextMenu)
    item:SetSize(170, 22)
    item:SetPoint("TOPLEFT", contextMenu, "TOPLEFT", 5, -5 - (idx - 1) * 22)

    local lbl = item:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("LEFT", 6, 0)
    lbl:SetText(text)
    lbl:SetTextColor(0.85, 0.85, 0.88)

    local hover = item:CreateTexture(nil, "BACKGROUND")
    hover:SetAllPoints()
    hover:SetTexture("Interface\\Buttons\\WHITE8X8")
    hover:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0)

    item:SetScript("OnEnter", function() hover:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.15) end)
    item:SetScript("OnLeave", function() hover:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0) end)
    item:SetScript("OnClick", function()
        ClearContextMenu()
        if onClick then onClick() end
    end)

    contextMenu._items[idx] = item
    contextMenu:SetHeight(10 + idx * 22)
end

local function ShowContextMenu(frameName, anchor)
    ClearContextMenu()

    local L = HA.L
    local isHidden = HA.db.hiddenFrames[frameName]
    local isCombat = HA.db.combatHideFrames[frameName]

    if isHidden then
        AddContextItem("|cff00ff00" .. (L["UI_BTN_SHOW"] or "Show") .. "|r", function()
            HA:ShowFrame(frameName)
        end)
    else
        AddContextItem("|cffff4444" .. (L["UI_BTN_HIDE"] or "Hide") .. "|r", function()
            HA:HideFrame(frameName)
        end)
    end

    AddContextItem((isCombat and "|cff00ff00@|r " or "|cff555560@|r ") .. (L["CFG_COMBAT_HIDE"] or "Combat Auto-Hide"), function()
        if isCombat then
            HA.db.combatHideFrames[frameName] = nil
        else
            HA.db.combatHideFrames[frameName] = true
        end
        HA:RefreshFrameList()
    end)

    AddContextItem((L["ALPHA_TITLE"] or "Opacity") .. "...", function()
        HA:ShowAlphaPopup(frameName, anchor)
    end)

    AddContextItem("|cffff8888" .. (L["UI_RESET_ALPHA"] or "Reset Alpha") .. "|r", function()
        HA:SetFrameAlpha(frameName, 1.0)
        HA:RefreshFrameList()
    end)

    contextMenu:ClearAllPoints()
    if anchor then
        contextMenu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)
    else
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        contextMenu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    end
    contextMenu:Show()
end

-- Hide context menu when clicking elsewhere
contextMenu:SetScript("OnLeave", function(self)
    C_Timer.After(0.3, function()
        if not self:IsMouseOver() then
            ClearContextMenu()
        end
    end)
end)

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
        row:SetScript("OnMouseDown", nil)
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

-- Inner top glow (accent color fading down)
local topGlow = panel:CreateTexture(nil, "BORDER")
topGlow:SetHeight(35)
topGlow:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
topGlow:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -4)
topGlow:SetColorTexture(1, 1, 1, 1)
ApplyGradient(topGlow, "VERTICAL", ACCENT_R, ACCENT_G, ACCENT_B, 0.07, 0, 0, 0, 0)

-- Inner bottom glow
local botGlow = panel:CreateTexture(nil, "BORDER")
botGlow:SetHeight(18)
botGlow:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 4, 4)
botGlow:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4, 4)
botGlow:SetColorTexture(1, 1, 1, 1)
ApplyGradient(botGlow, "VERTICAL", 0, 0, 0, 0, ACCENT_R, ACCENT_G, ACCENT_B, 0.05)

-- Side accent lines
local leftAccent = panel:CreateTexture(nil, "BORDER")
leftAccent:SetWidth(1)
leftAccent:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -40)
leftAccent:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 4, 28)
leftAccent:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.1)

local rightAccent = panel:CreateTexture(nil, "BORDER")
rightAccent:SetWidth(1)
rightAccent:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -40)
rightAccent:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4, 28)
rightAccent:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.1)

-- Draggable title bar
local titleBar = CreateFrame("Frame", nil, panel)
titleBar:SetHeight(40)
titleBar:SetPoint("TOPLEFT", 0, 0)
titleBar:SetPoint("TOPRIGHT", 0, 0)
titleBar:EnableMouse(true)
titleBar:RegisterForDrag("LeftButton")
titleBar:SetScript("OnDragStart", function() panel:StartMoving() end)
titleBar:SetScript("OnDragStop",  function() panel:StopMovingOrSizing() end)

-- Title area background gradient
local titleBg = panel:CreateTexture(nil, "BACKGROUND", nil, 1)
titleBg:SetHeight(40)
titleBg:SetPoint("TOPLEFT", panel, "TOPLEFT", 4, -4)
titleBg:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -4)
titleBg:SetColorTexture(1, 1, 1, 1)
ApplyGradient(titleBg, "HORIZONTAL", ACCENT_R * 0.3, ACCENT_G * 0.3, ACCENT_B * 0.3, 0.12, 0, 0, 0, 0)

-- Title with colored addon name
local titleText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("TOPLEFT", 16, -14)

-- Version badge with accent background
local verBadge = CreateFrame("Frame", nil, panel, "BackdropTemplate")
verBadge:SetSize(52, 16)
verBadge:SetPoint("LEFT", titleText, "RIGHT", 8, 0)
verBadge:SetBackdrop(BD_TOGGLE)
verBadge:SetBackdropColor(ACCENT_R, ACCENT_G, ACCENT_B, 0.15)
verBadge:SetBackdropBorderColor(ACCENT_R, ACCENT_G, ACCENT_B, 0.3)

local versionText = verBadge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
versionText:SetPoint("CENTER")
versionText:SetTextColor(ACCENT_R, ACCENT_G, ACCENT_B)

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

-- Resize grip (bottom-right corner)
panel:SetResizable(true)
panel:SetResizeBounds(440, 400, 900, 900)

local resizeGrip = CreateFrame("Button", nil, panel)
resizeGrip:SetSize(16, 16)
resizeGrip:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -4, 4)
resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizeGrip:SetScript("OnMouseDown", function()
    panel:StartSizing("BOTTOMRIGHT")
end)
resizeGrip:SetScript("OnMouseUp", function()
    panel:StopMovingOrSizing()
    -- Refresh layout after resize
    if panel.initialized then
        HA:RefreshFrameList()
    end
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

-- Status bar top accent line
local statusLine = statusBar:CreateTexture(nil, "OVERLAY")
statusLine:SetHeight(1)
statusLine:SetPoint("TOPLEFT", statusBar, "TOPLEFT", 0, 0)
statusLine:SetPoint("TOPRIGHT", statusBar, "TOPRIGHT", 0, 0)
statusLine:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.25)

-- Status bar gradient glow above
local statusGlow = statusBar:CreateTexture(nil, "ARTWORK")
statusGlow:SetHeight(6)
statusGlow:SetPoint("BOTTOMLEFT", statusBar, "TOPLEFT", 0, 0)
statusGlow:SetPoint("BOTTOMRIGHT", statusBar, "TOPRIGHT", 0, 0)
statusGlow:SetColorTexture(1, 1, 1, 1)
ApplyGradient(statusGlow, "VERTICAL", ACCENT_R, ACCENT_G, ACCENT_B, 0, ACCENT_R, ACCENT_G, ACCENT_B, 0.06)

-- Status bar accent dot
local statusDot = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
statusDot:SetPoint("LEFT", statusBar, "LEFT", 8, 0)
statusDot:SetText("|cff00c761>|r")

local statusText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
statusText:SetPoint("LEFT", statusDot, "RIGHT", 4, 0)
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

    -- Glow behind underline (soft diffused light)
    local underGlow = tab:CreateTexture(nil, "ARTWORK")
    underGlow:SetHeight(10)
    underGlow:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 4, -2)
    underGlow:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -4, -2)
    underGlow:SetColorTexture(1, 1, 1, 1)
    ApplyGradient(underGlow, "VERTICAL", 0, 0, 0, 0, ACCENT_R, ACCENT_G, ACCENT_B, 0.18)
    underGlow:Hide()
    tab._underGlow = underGlow

    -- Hover highlight background
    local hoverBg = tab:CreateTexture(nil, "BACKGROUND")
    hoverBg:SetAllPoints(tab)
    hoverBg:SetColorTexture(1, 1, 1, 0.04)
    hoverBg:Hide()
    tab._hoverBg = hoverBg

    -- Hover effect
    tab:SetScript("OnEnter", function(self)
        if activeTab ~= index then
            self.label:SetTextColor(0.85, 0.85, 0.85)
            self._hoverBg:Show()
        end
    end)
    tab:SetScript("OnLeave", function(self)
        if activeTab ~= index then
            self.label:SetTextColor(0.5, 0.5, 0.55)
        end
        self._hoverBg:Hide()
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

-- Tab separator glow (subtle gradient below the separator)
local tabSepGlow = panel:CreateTexture(nil, "BORDER")
tabSepGlow:SetHeight(8)
tabSepGlow:SetPoint("TOPLEFT", tabSeparator, "BOTTOMLEFT", 0, 0)
tabSepGlow:SetPoint("TOPRIGHT", tabSeparator, "BOTTOMRIGHT", 0, 0)
tabSepGlow:SetColorTexture(1, 1, 1, 1)
ApplyGradient(tabSepGlow, "VERTICAL", ACCENT_R, ACCENT_G, ACCENT_B, 0.05, 0, 0, 0, 0)

function HA:SelectTab(index)
    for i, tab in pairs(tabs) do
        if i == index then
            tab.label:SetTextColor(1, 1, 1)
            tab._underline:Show()
            if tab._underGlow then tab._underGlow:Show() end
            tabContents[i].scroll:Show()
        else
            tab.label:SetTextColor(0.5, 0.5, 0.55)
            tab._underline:Hide()
            if tab._underGlow then tab._underGlow:Hide() end
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
    btn:SetBackdropColor(0.13, 0.13, 0.16, 1)
    btn:SetBackdropBorderColor(0.28, 0.28, 0.32, 1)

    -- Left accent stripe
    local stripe = btn:CreateTexture(nil, "ARTWORK")
    stripe:SetWidth(2)
    stripe:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
    stripe:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 2, 2)
    stripe:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.35)
    btn._stripe = stripe

    -- Top highlight shimmer
    local shimmer = btn:CreateTexture(nil, "ARTWORK")
    shimmer:SetHeight(1)
    shimmer:SetPoint("TOPLEFT", btn, "TOPLEFT", 3, -2)
    shimmer:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -3, -2)
    shimmer:SetColorTexture(1, 1, 1, 0.04)
    btn._shimmer = shimmer

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER", 2, 0)
    label:SetText(text)
    label:SetTextColor(0.88, 0.88, 0.92)
    btn._label = label

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(ACCENT_DIM_R, ACCENT_DIM_G, ACCENT_DIM_B, 0.5)
        self:SetBackdropBorderColor(ACCENT_R, ACCENT_G, ACCENT_B, 0.7)
        self._stripe:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.8)
        self._shimmer:SetColorTexture(1, 1, 1, 0.08)
        self._label:SetTextColor(1, 1, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.13, 0.13, 0.16, 1)
        self:SetBackdropBorderColor(0.28, 0.28, 0.32, 1)
        self._stripe:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.35)
        self._shimmer:SetColorTexture(1, 1, 1, 0.04)
        self._label:SetTextColor(0.88, 0.88, 0.92)
    end)
    btn:SetScript("OnMouseDown", function(self)
        self:SetBackdropColor(ACCENT_R, ACCENT_G, ACCENT_B, 0.3)
        self._stripe:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 1)
    end)
    btn:SetScript("OnMouseUp", function(self)
        self:SetBackdropColor(ACCENT_DIM_R, ACCENT_DIM_G, ACCENT_DIM_B, 0.5)
        self._stripe:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.8)
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
    if entry.texture and strfind(strlower(entry.texture), lowerFilter, 1, true) then return true end
    return false
end

local function IsEntryHidden(entry)
    if entry.name then
        return HA.db and HA.db.hiddenFrames and HA.db.hiddenFrames[entry.name] == true
    elseif entry.cvar then
        return HA.db and HA.db.hiddenCVars and HA.db.hiddenCVars[entry.cvar] == true
    elseif entry.texture then
        return HA.db and HA.db.hiddenTextures and HA.db.hiddenTextures[entry.texture] == true
    end
    return false
end

local function SectionHasVisibleChildren(catalog, sectionIndex, filter)
    for i = sectionIndex + 1, #catalog do
        local entry = catalog[i]
        if entry.section then break end
        if not HA:IsEntryAvailable(entry) then
            -- skip entries not for this edition
        elseif showHiddenOnly and not IsEntryHidden(entry) then
            -- skip non-hidden when filter active
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

    y = MakeSettingsToggle(y, L["CFG_FADE_ANIM"], L["CFG_FADE_ANIM_TT"],
        function() return HA:GetSetting("fadeEnabled") end,
        function() HA:SetSetting("fadeEnabled", not HA:GetSetting("fadeEnabled")) end)

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

    -- "Hidden Only" filter toggle
    y = y - 32
    local filterRow = CreateFrame("Frame", nil, block)
    filterRow:SetSize(block:GetWidth() - 20, 24)
    filterRow:SetPoint("TOPLEFT", block, "TOPLEFT", 10, y)

    local filterLabel = filterRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    filterLabel:SetPoint("LEFT", filterRow, "LEFT", 6, 0)
    filterLabel:SetText("|cff888890" .. (L["UI_FILTER_HIDDEN_ONLY"] or "Show only hidden") .. "|r")

    local filterToggleBg = CreateFrame("Button", nil, filterRow, "BackdropTemplate")
    filterToggleBg:SetSize(TOGGLE_W - 6, TOGGLE_H - 4)
    filterToggleBg:SetPoint("LEFT", filterLabel, "RIGHT", 8, 0)
    filterToggleBg:SetBackdrop(BD_TOGGLE)
    local filterKnob = filterToggleBg:CreateTexture(nil, "OVERLAY")
    filterKnob:SetSize(TOGGLE_H - 10, TOGGLE_H - 10)
    filterKnob:SetTexture("Interface\\Buttons\\WHITE8X8")
    SetToggleState(filterToggleBg, filterKnob, showHiddenOnly)

    filterToggleBg:SetScript("OnClick", function()
        showHiddenOnly = not showHiddenOnly
        SetToggleState(filterToggleBg, filterKnob, showHiddenOnly)
        if showHiddenOnly then
            filterLabel:SetText("|cffff8800" .. (L["UI_FILTER_HIDDEN_ONLY"] or "Show only hidden") .. "|r")
        else
            filterLabel:SetText("|cff888890" .. (L["UI_FILTER_HIDDEN_ONLY"] or "Show only hidden") .. "|r")
        end
        HA:RefreshFrameList()
    end)

    y = y - 10

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
    -- Debounce: coalesce rapid calls
    if refreshPending then return end
    refreshPending = true
    C_Timer.After(REFRESH_THROTTLE, function()
        refreshPending = false
        HA:DoRefreshFrameList()
    end)
end

function HA:DoRefreshFrameList()
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

    -- Recently Hidden quick access
    local recent = HA.GetRecentlyHidden and HA:GetRecentlyHidden() or {}
    if #recent > 0 and searchFilter == "" and not showHiddenOnly then
        local recentHdr = AcquireFont(parent, "GameFontNormalSmall")
        recentHdr:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, y)
        recentHdr:SetText("|cff888890" .. (L["UI_RECENTLY_HIDDEN"] or "Recently Hidden") .. ":|r")
        y = y - 16

        for ri = 1, math.min(5, #recent) do
            local recentName = recent[ri]
            local isStillHidden = (self.db.hiddenFrames[recentName] == true) or (self.db.hiddenCVars and self.db.hiddenCVars[recentName] == true) or (self.db.hiddenTextures and self.db.hiddenTextures[recentName] == true)
            local recentRow = AcquireMiscFrame(parent)
            recentRow:SetSize(parent:GetWidth(), 20)
            recentRow:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y)
            recentRow:EnableMouse(true)

            local rLabel = AcquireFont(parent, "GameFontNormalSmall")
            rLabel:SetPoint("LEFT", recentRow, "LEFT", 0, 0)
            if isStillHidden then
                rLabel:SetText("|cffff8800" .. TruncateText(recentName, 35) .. "|r")
            else
                rLabel:SetText("|cff555560" .. TruncateText(recentName, 35) .. "|r")
            end

            local rBtn = AcquireFont(parent, "GameFontNormalSmall")
            rBtn:SetPoint("RIGHT", recentRow, "RIGHT", -10, 0)
            if isStillHidden then
                rBtn:SetText("|cff00ff66" .. (L["UI_BTN_SHOW"] or "Show") .. "|r")
            else
                rBtn:SetText("|cff555560-|r")
            end

            recentRow:SetScript("OnMouseDown", function()
                if isStillHidden then
                    -- Try showing as frame first, then cvar, then texture
                    if self.db.hiddenFrames[recentName] then
                        HA:ShowFrame(recentName)
                    elseif self.db.hiddenCVars and self.db.hiddenCVars[recentName] then
                        HA:ShowCVar(recentName)
                    elseif self.db.hiddenTextures and self.db.hiddenTextures[recentName] then
                        HA:ShowTexture(recentName)
                    end
                end
            end)

            y = y - 20
        end

        local recentLine = AcquireTexture(parent)
        recentLine:SetHeight(1)
        recentLine:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, y - 2)
        recentLine:SetPoint("RIGHT", parent, "RIGHT", -10, 0)
        recentLine:SetColorTexture(0.25, 0.25, 0.28, 0.4)
        y = y - 8
    end

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
    local currentSection = nil

    for catIndex, entry in ipairs(self.FRAME_CATALOG) do

        -- Skip entries not available in current edition
        if not entry.section and not self:IsEntryAvailable(entry) then
            -- skip

        -- Skip entries in collapsed sections
        elseif not entry.section and currentSection and collapsedSections[currentSection] and searchFilter == "" then
            -- skip collapsed children (but don't collapse when searching)

        -- Section header
        elseif entry.section then
            if SectionHasVisibleChildren(self.FRAME_CATALOG, catIndex, searchFilter) then
                y = y - 8
                local sectionLabel = self:GetCatalogLabel(entry)
                local sectionKey = entry.label -- use English label as key
                local isCollapsed = collapsedSections[sectionKey]

                local secBg = AcquireMiscFrame(parent)
                secBg:SetSize(parent:GetWidth(), 22)
                secBg:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
                secBg:EnableMouse(true)

                -- Collapse/expand arrow
                local arrow = isCollapsed and "|cff70a890>|r " or "|cff70a890v|r "
                local secHeader = AcquireFont(parent, "GameFontNormalSmall")
                secHeader:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, y - 3)
                secHeader:SetText(arrow .. "|cff70a890" .. sectionLabel .. "|r")

                local secLine = AcquireTexture(parent)
                secLine:SetHeight(1)
                secLine:SetPoint("TOPLEFT", secHeader, "BOTTOMLEFT", 0, -2)
                secLine:SetPoint("RIGHT", parent, "RIGHT", -10, 0)
                secLine:SetColorTexture(0.35, 0.55, 0.45, 0.25)

                -- Click to collapse/expand
                secBg:SetScript("OnMouseDown", function()
                    collapsedSections[sectionKey] = not collapsedSections[sectionKey]
                    HA:RefreshFrameList()
                end)
                secBg:SetScript("OnEnter", function(self)
                    secHeader:SetText(arrow .. "|cffaaddbb" .. sectionLabel .. "|r")
                end)
                secBg:SetScript("OnLeave", function(self)
                    secHeader:SetText(arrow .. "|cff70a890" .. sectionLabel .. "|r")
                end)

                y = y - 22
            end
            currentSection = entry.label

        -- CVar-based toggle
        elseif entry.cvar then
            if showHiddenOnly and not IsEntryHidden(entry) then
                -- skip non-hidden when filter active
            elseif MatchesFilter(entry, searchFilter) then
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

                row._label:SetText(HighlightSearch(displayLabel, searchFilter))
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
            if showHiddenOnly and not IsEntryHidden(entry) then
                -- skip non-hidden when filter active
            elseif MatchesFilter(entry, searchFilter) then
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
                    row._label:SetText("|cff555560" .. HighlightSearch(displayLabel, searchFilter) .. "|r")
                else
                    row._label:SetText(HighlightSearch(displayLabel, searchFilter))
                    row._label:SetTextColor(0.85, 0.85, 0.88)
                end
                row._label:SetWidth(parent:GetWidth() * 0.33)

                -- Right-click context menu
                row:RegisterForDrag()
                row:SetScript("OnMouseDown", function(self, button)
                    if button == "RightButton" and frameExists then
                        ShowContextMenu(frameName, self)
                    end
                end)

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

                -- Alpha / Opacity button
                local alphaPct = math.floor(frameAlpha * 100 + 0.5)
                row._alphaBtn:Show()
                row._showBtn:Hide()

                if alphaPct < 100 then
                    row._alphaBtn:SetBackdropColor(0.12, 0.28, 0.45, 0.9)
                    row._alphaBtn:SetBackdropBorderColor(0.2, 0.5, 0.75, 0.9)
                    row._alphaBtn._text:SetText("|cff88bbee" .. alphaPct .. "%%|r")
                else
                    row._alphaBtn:SetBackdropColor(0.14, 0.14, 0.16, 0.8)
                    row._alphaBtn:SetBackdropBorderColor(0.30, 0.30, 0.34, 0.8)
                    row._alphaBtn._text:SetText("|cff999999" .. alphaPct .. "%%|r")
                end

                if frameExists then
                    row._alphaBtn:SetScript("OnClick", function(self)
                        HA:ShowAlphaPopup(frameName, self)
                    end)
                    row._alphaBtn:SetScript("OnEnter", function(self)
                        self:SetBackdropColor(ACCENT_DIM_R, ACCENT_DIM_G, ACCENT_DIM_B, 0.5)
                        self:SetBackdropBorderColor(ACCENT_R, ACCENT_G, ACCENT_B, 0.7)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:AddLine(L["ALPHA_TITLE"], ACCENT_R, ACCENT_G, ACCENT_B)
                        GameTooltip:AddLine(L["ALPHA_TOOLTIP"], 1, 1, 1, true)
                        GameTooltip:Show()
                    end)
                    row._alphaBtn:SetScript("OnLeave", function(self)
                        if alphaPct < 100 then
                            self:SetBackdropColor(0.12, 0.28, 0.45, 0.9)
                            self:SetBackdropBorderColor(0.2, 0.5, 0.75, 0.9)
                        else
                            self:SetBackdropColor(0.14, 0.14, 0.16, 0.8)
                            self:SetBackdropBorderColor(0.30, 0.30, 0.34, 0.8)
                        end
                        GameTooltip:Hide()
                    end)
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
                    row._alphaBtn:SetBackdropColor(0.10, 0.10, 0.12, 0.4)
                    row._alphaBtn:SetBackdropBorderColor(0.20, 0.20, 0.23, 0.4)
                    row._alphaBtn._text:SetText("|cff666666" .. alphaPct .. "%%|r")
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
        -- Texture/Region toggle
        elseif entry.texture then
            if showHiddenOnly and not IsEntryHidden(entry) then
                -- skip non-hidden when filter active
            elseif MatchesFilter(entry, searchFilter) then
                local textureName = entry.texture
                local displayLabel = self:GetCatalogLabel(entry)
                local isHidden = self.db.hiddenTextures and self.db.hiddenTextures[textureName] == true
                local regionExists = self:GetRegionByName(textureName) ~= nil
                rowIndex = rowIndex + 1

                local row = AcquireRow(parent)
                row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)

                if rowIndex % 2 == 0 then
                    row:SetBackdrop(BD_ROW_ALT)
                    row:SetBackdropColor(0.12, 0.12, 0.14, 0.35)
                end

                if not regionExists then
                    row._label:SetText("|cff555560" .. HighlightSearch(displayLabel, searchFilter) .. "|r")
                else
                    row._label:SetText(HighlightSearch(displayLabel, searchFilter))
                    row._label:SetTextColor(0.85, 0.85, 0.88)
                end
                row._label:SetWidth(parent:GetWidth() * 0.42)

                -- Edition tag + Texture badge
                local edTag, edColor = self:GetEditionTag(entry)
                local techStr = "|cff886644Texture|r"
                if edTag then
                    techStr = "|cff" .. edColor .. edTag .. "|r |cff886644Texture|r"
                end
                row._techName:SetText(techStr)
                row._techName:SetWidth(parent:GetWidth() * 0.25)

                row._combatBtn:Hide()
                row._eyeBtn:Hide()
                row._alphaBtn:Hide()
                row._showBtn:Hide()

                row._toggleBg:Show()
                if regionExists then
                    SetToggleState(row._toggleBg, row._toggleBg._knob, not isHidden)
                    row._toggleBg:SetScript("OnClick", function()
                        if isHidden then
                            HA:ShowTexture(textureName)
                        else
                            HA:HideTexture(textureName)
                        end
                    end)
                else
                    row._toggleBg:SetBackdropColor(0.15, 0.15, 0.17, 0.5)
                    row._toggleBg:SetBackdropBorderColor(0.22, 0.22, 0.25, 0.5)
                    row._toggleBg._knob:ClearAllPoints()
                    row._toggleBg._knob:SetPoint("LEFT", row._toggleBg, "LEFT", 3, 0)
                    row._toggleBg._knob:SetColorTexture(0.35, 0.35, 0.38, 0.5)
                    row._toggleBg:SetScript("OnClick", nil)
                end

                row:SetScript("OnEnter", function(self)
                    RowOnEnter(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:AddLine(displayLabel, ACCENT_R, ACCENT_G, ACCENT_B)
                    GameTooltip:AddLine("Texture: " .. textureName, 0.5, 0.5, 0.5)
                    if edTag then
                        GameTooltip:AddLine(edTag, 0.5, 0.5, 0.5)
                    end
                    if not regionExists then
                        GameTooltip:AddLine(L["FRAME_NOT_LOADED"], 1, 0.5, 0)
                    elseif isHidden then
                        GameTooltip:AddLine(L["FRAME_STATE_HIDDEN"], 1, 0.3, 0.3)
                    else
                        GameTooltip:AddLine(L["FRAME_STATE_VISIBLE"], 0.3, 1, 0.3)
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
    local catalogTextures = {}
    for _, entry in ipairs(self.FRAME_CATALOG) do
        if entry.name then catalogNames[entry.name] = true end
        if entry.texture then catalogTextures[entry.texture] = true end
    end
    for frameName, _ in pairs(self.db.hiddenFrames) do
        if not catalogNames[frameName] then
            table.insert(customHidden, frameName)
        end
    end
    if self.db.hiddenTextures then
        for textureName, _ in pairs(self.db.hiddenTextures) do
            if not catalogTextures[textureName] then
                table.insert(customHidden, textureName .. " |cff886644(Texture)|r")
            end
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

            local truncName = TruncateText(frameName, 40)
            row._label:SetText("|cffcc8800" .. truncName .. "|r")
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

            row:SetScript("OnEnter", function(self)
                RowOnEnter(self)
                if truncName ~= frameName then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:AddLine(frameName, 0.8, 0.53, 0)
                    GameTooltip:Show()
                end
            end)
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
        resetBtn._stripe:SetColorTexture(0.6, 0.15, 0.15, 0.5)
        resetBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.35, 0.08, 0.08, 0.8)
            self:SetBackdropBorderColor(0.6, 0.15, 0.15, 1)
            self._stripe:SetColorTexture(0.8, 0.15, 0.15, 0.9)
            self._shimmer:SetColorTexture(1, 0.3, 0.3, 0.08)
            self._label:SetTextColor(1, 0.7, 0.7)
        end)
        resetBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.13, 0.13, 0.16, 1)
            self:SetBackdropBorderColor(0.45, 0.2, 0.2, 1)
            self._stripe:SetColorTexture(0.6, 0.15, 0.15, 0.5)
            self._shimmer:SetColorTexture(1, 1, 1, 0.04)
            self._label:SetTextColor(1, 0.6, 0.6)
        end)

        tc.actionRow = actionRow
    end

    -- Improvement #11: search result count
    if searchFilter ~= "" or showHiddenOnly then
        local countLabel = AcquireFont(parent, "GameFontNormalSmall")
        countLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, y)
        local filterInfo = ""
        if searchFilter ~= "" then filterInfo = " '" .. searchFilter .. "'" end
        if showHiddenOnly then filterInfo = filterInfo .. (searchFilter ~= "" and " + hidden only" or " hidden only") end
        countLabel:SetText("|cff888890" .. (L["UI_SEARCH_RESULTS"] or "Found %d results"):format(rowIndex) .. filterInfo .. "|r")
        y = y - 18
    end

    tc.actionRow:ClearAllPoints()
    tc.actionRow:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)
    tc.actionRow:Show()
    y = y - 40

    parent:SetHeight(math.abs(y) + 10)

    -- Update status bar
    UpdateStatusBar()

    -- Improvement #25: update floating button badge
    if HA.UpdateFloatingBadge then HA:UpdateFloatingBadge() end
end

---------------------------------------------------------------------------
-- BUILD: Tab 2 - Profiles
---------------------------------------------------------------------------
local function BuildProfilesTab(parent)
    local L = HA.L

    -- Profile name input area
    local inputCard = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    inputCard:SetSize(parent:GetWidth(), 134)
    inputCard:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -4)
    inputCard:SetBackdrop(BD_CARD)
    inputCard:SetBackdropColor(0.09, 0.09, 0.11, 0.7)
    inputCard:SetBackdropBorderColor(0.20, 0.20, 0.23, 0.6)

    -- Card accent stripe
    local cardStripe = inputCard:CreateTexture(nil, "OVERLAY")
    cardStripe:SetHeight(2)
    cardStripe:SetPoint("TOPLEFT", inputCard, "TOPLEFT", 3, -3)
    cardStripe:SetPoint("TOPRIGHT", inputCard, "TOPRIGHT", -3, -3)
    cardStripe:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.45)

    -- Left accent bar
    local cardLeftBar = inputCard:CreateTexture(nil, "OVERLAY")
    cardLeftBar:SetWidth(2)
    cardLeftBar:SetPoint("TOPLEFT", inputCard, "TOPLEFT", 3, -5)
    cardLeftBar:SetPoint("BOTTOMLEFT", inputCard, "BOTTOMLEFT", 3, 3)
    cardLeftBar:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.25)

    -- Inner top glow
    local cardInnerGlow = inputCard:CreateTexture(nil, "BORDER")
    cardInnerGlow:SetHeight(12)
    cardInnerGlow:SetPoint("TOPLEFT", inputCard, "TOPLEFT", 3, -3)
    cardInnerGlow:SetPoint("TOPRIGHT", inputCard, "TOPRIGHT", -3, -3)
    cardInnerGlow:SetColorTexture(1, 1, 1, 1)
    ApplyGradient(cardInnerGlow, "VERTICAL", ACCENT_R, ACCENT_G, ACCENT_B, 0.06, 0, 0, 0, 0)

    local inputLabel = inputCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    inputLabel:SetPoint("TOPLEFT", inputCard, "TOPLEFT", 12, -10)
    inputLabel:SetText("|cff00c761" .. (L["UI_PROFILE_NAME"] or "Profile Name:") .. "|r")

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
        if name and name ~= "" then
            HA._pendingDeleteProfile = name
            StaticPopupDialogs["HIDEANYTHING_CONFIRM_DELETE_PROFILE"].text = (L["UI_CONFIRM_DELETE_PROFILE"] or "Delete profile |cffff4444%s|r?"):format(name)
            StaticPopupDialogs["HIDEANYTHING_CONFIRM_DELETE_PROFILE"].button1 = L["UI_CONFIRM_YES"]
            StaticPopupDialogs["HIDEANYTHING_CONFIRM_DELETE_PROFILE"].button2 = L["UI_CONFIRM_NO"]
            StaticPopup_Show("HIDEANYTHING_CONFIRM_DELETE_PROFILE")
        else HA:Print(L["PROFILE_NAME_REQUIRED"]) end
    end)
    btn3:SetPoint("LEFT", btn2, "RIGHT", 6, 0)
    btn3:SetBackdropBorderColor(0.45, 0.2, 0.2, 1)
    btn3._label:SetTextColor(1, 0.6, 0.6)
    btn3._stripe:SetColorTexture(0.6, 0.15, 0.15, 0.5)
    btn3:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.35, 0.08, 0.08, 0.8)
        self:SetBackdropBorderColor(0.6, 0.15, 0.15, 1)
        self._stripe:SetColorTexture(0.8, 0.15, 0.15, 0.9)
        self._shimmer:SetColorTexture(1, 0.3, 0.3, 0.08)
        self._label:SetTextColor(1, 0.7, 0.7)
    end)
    btn3:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.13, 0.13, 0.16, 1)
        self:SetBackdropBorderColor(0.45, 0.2, 0.2, 1)
        self._stripe:SetColorTexture(0.6, 0.15, 0.15, 0.5)
        self._shimmer:SetColorTexture(1, 1, 1, 0.04)
        self._label:SetTextColor(1, 0.6, 0.6)
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

    -- Separator line before presets
    btnY = btnY - 30
    local presetSep = inputCard:CreateTexture(nil, "ARTWORK")
    presetSep:SetHeight(1)
    presetSep:SetPoint("TOPLEFT", inputCard, "TOPLEFT", 10, btnY + 4)
    presetSep:SetPoint("TOPRIGHT", inputCard, "TOPRIGHT", -10, btnY + 4)
    presetSep:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.15)

    local presetLabel = inputCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    presetLabel:SetPoint("TOPLEFT", inputCard, "TOPLEFT", 12, btnY)
    presetLabel:SetText("|cff00c761" .. (L["PRESETS_HEADER"] or "Presets") .. ":|r")

    -- "Save current as preset" button next to label
    local savePresetBtn = CreateStyledButton(inputCard, 170, 20, L["PRESET_SAVE_CURRENT"] or "Save current as Preset", function()
        local name = inputBox:GetText()
        if name and name ~= "" then
            HA:SaveCustomPreset(name)
            HA:RefreshPresetButtons()
        else
            HA:Print(L["PROFILE_NAME_REQUIRED"])
        end
    end)
    savePresetBtn:SetPoint("LEFT", presetLabel, "RIGHT", 8, 0)

    -- Dynamic preset container (rebuilt on refresh)
    local presetContainer = CreateFrame("Frame", nil, parent)
    presetContainer:SetSize(parent:GetWidth(), 1)
    presetContainer:SetPoint("TOPLEFT", inputCard, "BOTTOMLEFT", 0, -6)
    tabContents[2].presetContainer = presetContainer
    tabContents[2].presetWidgets = {}

    -- Profile list area (positioned dynamically in RefreshPresetButtons)
    local profileListHeader = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tabContents[2].profileListHeader = profileListHeader
    tabContents[2].listParent = parent
    tabContents[2].rows = {}
end

---------------------------------------------------------------------------
-- Refresh preset buttons (dynamic, supports custom presets)
---------------------------------------------------------------------------
function HA:RefreshPresetButtons()
    local tc = tabContents[2]
    if not tc or not tc.presetContainer then return end

    local L = self.L
    local container = tc.presetContainer

    -- Clear old widgets
    for _, widget in ipairs(tc.presetWidgets) do
        widget:Hide()
    end
    wipe(tc.presetWidgets)

    local allPresets = self:GetAllPresets()
    local y = 0
    local x = 10
    local maxW = container:GetWidth() or 500
    local rowH = 24
    local btnW = 120

    for _, preset in ipairs(allPresets) do
        local label = self:GetPresetLabel(preset)

        -- Wrap to next row if needed
        if x + btnW + (preset.custom and 26 or 0) > maxW then
            x = 10
            y = y - (rowH + 4)
        end

        -- Preset apply button (left-click = apply, right-click = edit)
        local presetBtn = CreateStyledButton(container, btnW, rowH, label, nil)
        presetBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        local pid = preset.id
        presetBtn:SetScript("OnClick", function(_, button)
            if button == "RightButton" then
                HA:ShowPresetEditDialog(pid)
            else
                HA:ApplyPreset(pid, true)
            end
        end)
        presetBtn:SetPoint("TOPLEFT", container, "TOPLEFT", x, y)

        -- Show customized indicator for built-in presets with overrides
        if not preset.custom and HA:IsPresetCustomized(pid) then
            local modIcon = presetBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            modIcon:SetPoint("TOPRIGHT", presetBtn, "TOPRIGHT", -3, -2)
            modIcon:SetText("|cffffcc00*|r")
        end

        table.insert(tc.presetWidgets, presetBtn)

        -- Custom preset: mark with accent color and add delete "x" button
        if preset.custom then
            presetBtn._stripe:SetColorTexture(0.9, 0.65, 0.1, 0.5)
            presetBtn._label:SetTextColor(1, 0.9, 0.6)

            local delX = CreateFrame("Button", nil, container)
            delX:SetSize(22, rowH)
            delX:SetPoint("LEFT", presetBtn, "RIGHT", 2, 0)

            local delLabel = delX:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            delLabel:SetPoint("CENTER")
            delLabel:SetText("|cffff4444x|r")

            delX:SetScript("OnEnter", function() delLabel:SetText("|cffff6666x|r") end)
            delX:SetScript("OnLeave", function() delLabel:SetText("|cffff4444x|r") end)
            delX:SetScript("OnClick", function()
                HA:DeleteCustomPreset(preset.id)
                HA:RefreshPresetButtons()
            end)

            table.insert(tc.presetWidgets, delX)
            x = x + btnW + 28
        else
            x = x + btnW + 6
        end
    end

    -- Update container height and reposition profile list
    local containerHeight = math.abs(y) + rowH + 8
    container:SetHeight(containerHeight)

    local listY = -(168 + containerHeight + 10)
    if tc.profileListHeader then
        tc.profileListHeader:SetPoint("TOPLEFT", tc.listParent, "TOPLEFT", 10, listY)
    end
    tc.listStartY = listY - 24
end

---------------------------------------------------------------------------
-- Preset Edit Dialog (right-click a preset to configure its frames)
---------------------------------------------------------------------------
local presetEditDialog = nil

function HA:ShowPresetEditDialog(presetId)
    local L = self.L

    -- Find preset info
    local presetLabel, isBuiltIn
    for _, p in ipairs(self.PRESET_PROFILES) do
        if p.id == presetId then
            presetLabel = self:GetPresetLabel(p)
            isBuiltIn = true
            break
        end
    end
    if not presetLabel and self.db.customPresets[presetId] then
        presetLabel = self.db.customPresets[presetId].label or presetId
        isBuiltIn = false
    end
    if not presetLabel then return end

    -- Get effective frames for this preset
    local presetFrames = self:GetPresetFrames(presetId)
    local frameSet = {}
    for _, f in ipairs(presetFrames) do
        frameSet[f] = true
    end

    -- Reuse or create dialog
    if presetEditDialog then
        presetEditDialog:Hide()
    end

    local dialog = CreateFrame("Frame", "HideAnythingPresetEditFrame", UIParent, "BackdropTemplate")
    dialog:SetSize(420, 460)
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("FULLSCREEN_DIALOG")
    dialog:SetBackdrop(BD_POPUP)
    dialog:SetBackdropColor(0.08, 0.08, 0.10, 0.97)
    dialog:SetBackdropBorderColor(0.25, 0.25, 0.28, 1)
    dialog:SetMovable(true)
    dialog:EnableMouse(true)
    dialog:SetClampedToScreen(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
    presetEditDialog = dialog

    -- Accent stripe
    local stripe = dialog:CreateTexture(nil, "OVERLAY")
    stripe:SetHeight(2)
    stripe:SetPoint("TOPLEFT", dialog, "TOPLEFT", 4, -4)
    stripe:SetPoint("TOPRIGHT", dialog, "TOPRIGHT", -4, -4)
    stripe:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.9)

    -- Title
    local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -14)
    title:SetText("|cff00c761" .. (L["PRESET_EDIT_TITLE"] or "Edit Preset") .. "|r")

    -- Subtitle: preset name
    local subtitle = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -4)
    subtitle:SetText("|cffffffff" .. presetLabel .. "|r")

    -- Hint text
    local hint = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("TOP", subtitle, "BOTTOM", 0, -4)
    hint:SetText("|cff888888" .. (L["PRESET_EDIT_HINT"] or "Check frames to include in this preset") .. "|r")

    -- Scrollframe for checkbox list
    local sf = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 12, -62)
    sf:SetPoint("BOTTOMRIGHT", -30, 48)

    local content = CreateFrame("Frame", nil, sf)
    content:SetWidth(sf:GetWidth())
    sf:SetScrollChild(content)

    -- Build checkbox list from FRAME_CATALOG (only frame entries)
    local checkboxes = {}
    local y = 0
    for _, entry in ipairs(self.FRAME_CATALOG) do
        if entry.section then
            -- Section header
            local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            header:SetPoint("TOPLEFT", content, "TOPLEFT", 4, y)
            header:SetText("|cff00c761" .. (self:GetCatalogLabel(entry) or entry.label or "") .. "|r")
            y = y - 18
        elseif entry.name then
            local frameName = entry.name
            local displayLabel = self:GetCatalogLabel(entry) or frameName

            local cb = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
            cb:SetSize(24, 24)
            cb:SetPoint("TOPLEFT", content, "TOPLEFT", 4, y)
            cb:SetChecked(frameSet[frameName] == true)

            local lbl = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
            lbl:SetText(displayLabel)
            lbl:SetTextColor(0.88, 0.88, 0.92)

            local tech = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            tech:SetPoint("LEFT", lbl, "RIGHT", 6, 0)
            tech:SetText("|cff666666" .. frameName .. "|r")

            cb:SetScript("OnClick", function(self)
                if self:GetChecked() then
                    frameSet[frameName] = true
                else
                    frameSet[frameName] = nil
                end
            end)

            table.insert(checkboxes, { cb = cb, name = frameName })
            y = y - 24
        end
    end
    content:SetHeight(math.abs(y) + 10)

    -- Bottom buttons
    local btnSave = CreateStyledButton(dialog, 100, 26, L["UI_BTN_SAVE"] or "Save", function()
        local newFrames = {}
        for name, _ in pairs(frameSet) do
            table.insert(newFrames, name)
        end
        table.sort(newFrames)
        HA:UpdatePresetFrames(presetId, newFrames)
        HA:ChatMsg((L["PRESET_SAVED"] or "Preset |cff00cc66%s|r saved with %d frames."):format(presetLabel, #newFrames))
        HA:RefreshPresetButtons()
        dialog:Hide()
    end)
    btnSave:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", 12, 12)

    local btnClose = CreateStyledButton(dialog, 80, 26, L["UI_BTN_CLOSE"] or "Close", function()
        dialog:Hide()
    end)
    btnClose:SetPoint("BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -12, 12)

    -- Reset to Default button (only for built-in presets that have been customized)
    if isBuiltIn and self:IsPresetCustomized(presetId) then
        local btnReset = CreateStyledButton(dialog, 130, 26, L["PRESET_RESET_BTN"] or "Reset to Default", function()
            HA:ResetPresetToDefault(presetId)
            HA:RefreshPresetButtons()
            dialog:Hide()
        end)
        btnReset:SetPoint("BOTTOM", dialog, "BOTTOM", 0, 12)
        btnReset._stripe:SetColorTexture(0.9, 0.5, 0.1, 0.5)
    end

    dialog:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:SetPropagateKeyboardInput(false)
            self:Hide()
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)

    dialog:Show()
end

function HA:RefreshProfileList()
    local L = self.L
    local tc = tabContents[2]
    if not tc or not tc.listParent then return end

    -- Refresh preset buttons first (updates dynamic layout)
    self:RefreshPresetButtons()

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
        nameLabel:SetText("|cff00c761" .. profileName .. "|r" .. active .. " |cff555560(" .. frameCount .. " " .. (L["UI_FRAMES_LOWER"] or "frames") .. ")|r")

        local loadBtn = CreateStyledButton(row, 56, 22, L["UI_BTN_LOAD"] or "Load", function()
            HA:LoadProfile(profileName)
            if tc.inputBox then tc.inputBox:SetText(profileName) end
            HA:RefreshProfileList()
        end)
        loadBtn:SetPoint("RIGHT", row, "RIGHT", -66, 0)

        local delBtn = CreateStyledButton(row, 56, 22, L["UI_BTN_DEL"] or "Del", function()
            HA._pendingDeleteProfile = profileName
            StaticPopupDialogs["HIDEANYTHING_CONFIRM_DELETE_PROFILE"].text = (L["UI_CONFIRM_DELETE_PROFILE"] or "Delete profile |cffff4444%s|r?"):format(profileName)
            StaticPopupDialogs["HIDEANYTHING_CONFIRM_DELETE_PROFILE"].button1 = L["UI_CONFIRM_YES"]
            StaticPopupDialogs["HIDEANYTHING_CONFIRM_DELETE_PROFILE"].button2 = L["UI_CONFIRM_NO"]
            StaticPopup_Show("HIDEANYTHING_CONFIRM_DELETE_PROFILE")
        end)
        delBtn:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        delBtn:SetBackdropBorderColor(0.45, 0.2, 0.2, 1)
        delBtn._label:SetTextColor(1, 0.6, 0.6)
        delBtn._stripe:SetColorTexture(0.6, 0.15, 0.15, 0.5)
        delBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.35, 0.08, 0.08, 0.8)
            self:SetBackdropBorderColor(0.6, 0.15, 0.15, 1)
            self._stripe:SetColorTexture(0.8, 0.15, 0.15, 0.9)
            self._shimmer:SetColorTexture(1, 0.3, 0.3, 0.08)
            self._label:SetTextColor(1, 0.7, 0.7)
        end)
        delBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.13, 0.13, 0.16, 1)
            self:SetBackdropBorderColor(0.45, 0.2, 0.2, 1)
            self._stripe:SetColorTexture(0.6, 0.15, 0.15, 0.5)
            self._shimmer:SetColorTexture(1, 1, 1, 0.04)
            self._label:SetTextColor(1, 0.6, 0.6)
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
    local w = parent:GetWidth()
    local y = -8

    -- Helper: create a styled card with visual effects
    local function MakeCard(yPos, height)
        local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        card:SetSize(w - 8, height)
        card:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, yPos)
        card:SetBackdrop(BD_CARD)
        card:SetBackdropColor(0.09, 0.09, 0.11, 0.7)
        card:SetBackdropBorderColor(0.20, 0.20, 0.23, 0.6)

        -- Top accent stripe
        local stripe = card:CreateTexture(nil, "OVERLAY")
        stripe:SetHeight(2)
        stripe:SetPoint("TOPLEFT", card, "TOPLEFT", 3, -3)
        stripe:SetPoint("TOPRIGHT", card, "TOPRIGHT", -3, -3)
        stripe:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.5)

        -- Left accent bar
        local leftBar = card:CreateTexture(nil, "OVERLAY")
        leftBar:SetWidth(2)
        leftBar:SetPoint("TOPLEFT", card, "TOPLEFT", 3, -5)
        leftBar:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 3, 3)
        leftBar:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.3)

        -- Inner top glow
        local innerGlow = card:CreateTexture(nil, "BORDER")
        innerGlow:SetHeight(12)
        innerGlow:SetPoint("TOPLEFT", card, "TOPLEFT", 3, -3)
        innerGlow:SetPoint("TOPRIGHT", card, "TOPRIGHT", -3, -3)
        innerGlow:SetColorTexture(1, 1, 1, 1)
        ApplyGradient(innerGlow, "VERTICAL", ACCENT_R, ACCENT_G, ACCENT_B, 0.06, 0, 0, 0, 0)

        return card
    end

    -----------------------------------------------------------------------
    -- Card 1: Title + Edition
    -----------------------------------------------------------------------
    local titleCard = MakeCard(y, 90)

    local titleText = titleCard:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOPLEFT", titleCard, "TOPLEFT", 14, -14)
    titleText:SetText("|cff00c761Hide|r|cffffffffAnything|r")

    local verBadge = CreateFrame("Frame", nil, titleCard, "BackdropTemplate")
    verBadge:SetSize(56, 18)
    verBadge:SetPoint("LEFT", titleText, "RIGHT", 8, 0)
    verBadge:SetBackdrop(BD_TOGGLE)
    verBadge:SetBackdropColor(ACCENT_R, ACCENT_G, ACCENT_B, 0.2)
    verBadge:SetBackdropBorderColor(ACCENT_R, ACCENT_G, ACCENT_B, 0.4)
    local verLabel = verBadge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    verLabel:SetPoint("CENTER")
    verLabel:SetText("|cff00c761v" .. HA.version .. "|r")

    local authorLabel = titleCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    authorLabel:SetPoint("TOPLEFT", titleCard, "TOPLEFT", 14, -38)
    authorLabel:SetText("|cff888890" .. (L["ABOUT_AUTHOR"] or "Author:") .. "|r  |cffffffffJugoBetrugoTV|r")

    -- Edition display (prominent)
    local edName = HA.EDITION_NAMES[HA.edition] or "Unknown"
    local edColor = HA.EDITION_COLORS[HA.edition] or "888888"

    local edCard = CreateFrame("Frame", nil, titleCard, "BackdropTemplate")
    edCard:SetSize(w - 36, 26)
    edCard:SetPoint("TOPLEFT", titleCard, "TOPLEFT", 12, -58)
    edCard:SetBackdrop(BD_TOGGLE)
    edCard:SetBackdropColor(0.06, 0.06, 0.08, 0.8)
    edCard:SetBackdropBorderColor(0.22, 0.22, 0.25, 0.6)

    local edIcon = edCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    edIcon:SetPoint("LEFT", edCard, "LEFT", 10, 0)
    edIcon:SetText("|cff888890" .. (L["CFG_EDITION_LABEL"] or "Edition") .. ":|r")

    local edValue = edCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    edValue:SetPoint("LEFT", edIcon, "RIGHT", 6, 0)
    edValue:SetText("|cff" .. edColor .. edName .. "|r")

    y = y - 100

    -----------------------------------------------------------------------
    -- Card: Social / Community
    -----------------------------------------------------------------------
    local socialCard = MakeCard(y, 56)

    local twitchLabel = socialCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    twitchLabel:SetPoint("TOPLEFT", socialCard, "TOPLEFT", 14, -14)
    twitchLabel:SetText("|cff9146ffTwitch|r  |cffcccccctwitch.tv/JugoBetrugoTV|r")

    local discordLabel = socialCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    discordLabel:SetPoint("TOPLEFT", socialCard, "TOPLEFT", 14, -34)
    discordLabel:SetText("|cff5865f2Discord|r  |cffccccccdiscord.gg/rv2BsbE|r")

    y = y - 64

    -----------------------------------------------------------------------
    -- Card 2: Quick Stats
    -----------------------------------------------------------------------
    local statsCard = MakeCard(y, 70)

    local statsTitle = statsCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statsTitle:SetPoint("TOPLEFT", statsCard, "TOPLEFT", 14, -12)
    statsTitle:SetText("|cff00c761" .. (L["ABOUT_STATS_TITLE"] or "Quick Stats") .. "|r")

    -- Count stats
    local hiddenCount = HA:GetHiddenCount()
    local profileCount = 0
    if HA.db and HA.db.profiles then
        for _ in pairs(HA.db.profiles) do profileCount = profileCount + 1 end
    end
    local catalogCount = 0
    for _, entry in ipairs(HA.FRAME_CATALOG) do
        if not entry.section then catalogCount = catalogCount + 1 end
    end

    local col1 = statsCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    col1:SetPoint("TOPLEFT", statsCard, "TOPLEFT", 14, -34)
    col1:SetText("|cff888890" .. (L["ABOUT_STATS_HIDDEN"] or "Hidden: |cffffffff%d|r"):format(hiddenCount))

    local col2 = statsCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    col2:SetPoint("TOPLEFT", statsCard, "TOPLEFT", 160, -34)
    col2:SetText("|cff888890" .. (L["ABOUT_STATS_PROFILES"] or "Profiles: |cffffffff%d|r"):format(profileCount))

    local col3 = statsCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    col3:SetPoint("TOPLEFT", statsCard, "TOPLEFT", 320, -34)
    col3:SetText("|cff888890" .. (L["ABOUT_STATS_CATALOG"] or "Catalog: |cffffffff%d+|r"):format(catalogCount))

    -- Lock status indicator
    local lockStatus = statsCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lockStatus:SetPoint("TOPLEFT", statsCard, "TOPLEFT", 14, -50)
    if HA:GetSetting("locked") then
        lockStatus:SetText(L["STATUS_LOCKED"])
    else
        lockStatus:SetText(L["STATUS_UNLOCKED"])
    end

    y = y - 78

    -----------------------------------------------------------------------
    -- Card 3: Features
    -----------------------------------------------------------------------
    local featCard = MakeCard(y, 168)

    local featTitle = featCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    featTitle:SetPoint("TOPLEFT", featCard, "TOPLEFT", 14, -12)
    featTitle:SetText("|cff00c761" .. L["ABOUT_FEATURES"] .. "|r")

    local featLine = featCard:CreateTexture(nil, "ARTWORK")
    featLine:SetHeight(1)
    featLine:SetPoint("TOPLEFT", featTitle, "BOTTOMLEFT", 0, -3)
    featLine:SetPoint("RIGHT", featCard, "RIGHT", -14, 0)
    featLine:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.2)

    local features = {
        L["ABOUT_F1"], L["ABOUT_F2"], L["ABOUT_F3"],
        L["ABOUT_F4"], L["ABOUT_F5"], L["ABOUT_F6"],
        L["ABOUT_F7"], L["ABOUT_F8"], L["ABOUT_F9"],
    }
    if L["ABOUT_F10"] then table.insert(features, L["ABOUT_F10"]) end

    local fy = -32
    for _, feat in ipairs(features) do
        local fl = featCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fl:SetPoint("TOPLEFT", featCard, "TOPLEFT", 14, fy)
        fl:SetWidth(w - 50)
        fl:SetJustifyH("LEFT")
        fl:SetText("|cff00c761>|r  |cffcccccc" .. feat .. "|r")
        fy = fy - 14
    end

    featCard:SetHeight(math.abs(fy) + 8)
    y = y - (math.abs(fy) + 16)

    -----------------------------------------------------------------------
    -- Card 4: Commands Reference
    -----------------------------------------------------------------------
    local cmdCard = MakeCard(y, 150)

    local cmdTitle = cmdCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cmdTitle:SetPoint("TOPLEFT", cmdCard, "TOPLEFT", 14, -12)
    cmdTitle:SetText("|cff00c761" .. (L["ABOUT_COMMANDS_LABEL"] or "Commands:") .. "|r")

    local cmdLine = cmdCard:CreateTexture(nil, "ARTWORK")
    cmdLine:SetHeight(1)
    cmdLine:SetPoint("TOPLEFT", cmdTitle, "BOTTOMLEFT", 0, -3)
    cmdLine:SetPoint("RIGHT", cmdCard, "RIGHT", -14, 0)
    cmdLine:SetColorTexture(ACCENT_R, ACCENT_G, ACCENT_B, 0.2)

    local commands = {
        { "/hide toggle",       L["HELP_TOGGLE"]:gsub("|cff00cc66/hide toggle|r %- ", "") },
        { "/hide hide <name>",  L["HELP_HIDE"]:gsub("|cff00cc66/hide hide <.-|r %- ", "") },
        { "/hide show <name>",  L["HELP_SHOW"]:gsub("|cff00cc66/hide show <.-|r %- ", "") },
        { "/hide showall",      L["HELP_SHOW_ALL"]:gsub("|cff00cc66/hide showall|r %- ", "") },
        { "/hide list",         L["HELP_LIST"]:gsub("|cff00cc66/hide list|r %- ", "") },
        { "/hide profile",      L["HELP_PROFILE"]:gsub("|cff00cc66/hide profile <.-|r %- ", "") },
        { "/hide alpha",        L["HELP_ALPHA"]:gsub("|cff00cc66/hide alpha <.-|r %- ", "") },
        { "/hide status",       L["HELP_STATUS"]:gsub("|cff00cc66/hide status|r %- ", "") },
    }

    local cy = -32
    for _, cmd in ipairs(commands) do
        local cmdLbl = cmdCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cmdLbl:SetPoint("TOPLEFT", cmdCard, "TOPLEFT", 14, cy)
        cmdLbl:SetText("|cff00c761" .. cmd[1] .. "|r")

        local cmdDesc = cmdCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cmdDesc:SetPoint("TOPLEFT", cmdCard, "TOPLEFT", 180, cy)
        cmdDesc:SetText("|cff888890" .. cmd[2] .. "|r")
        cy = cy - 14
    end

    cmdCard:SetHeight(math.abs(cy) + 8)
    y = y - (math.abs(cy) + 16)

    -----------------------------------------------------------------------
    -- Card 5: Action Buttons
    -----------------------------------------------------------------------
    local actRow = CreateFrame("Frame", nil, parent)
    actRow:SetSize(w - 8, 34)
    actRow:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, y)

    local btnConfig = CreateStyledButton(actRow, 140, 28, "|cff00c761" .. (L["UI_FRAMES"] or "Frames") .. "|r", function()
        HA:SelectTab(1)
    end)
    btnConfig:SetPoint("LEFT", actRow, "LEFT", 4, 0)

    local btnShowAll = CreateStyledButton(actRow, 140, 28, L["UI_BTN_SHOW_ALL"], function()
        HA:ShowAllFrames()
        panel:Hide()
    end)
    btnShowAll:SetPoint("LEFT", btnConfig, "RIGHT", 8, 0)

    local btnStatus = CreateStyledButton(actRow, 140, 28, L["UI_BTN_STATUS"] or "Status", function()
        HA:PrintStatus()
        panel:Hide()
    end)
    btnStatus:SetPoint("LEFT", btnShowAll, "RIGHT", 8, 0)

    y = y - 44

    -----------------------------------------------------------------------
    -- Description at bottom
    -----------------------------------------------------------------------
    local descText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    descText:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, y)
    descText:SetWidth(w - 20)
    descText:SetJustifyH("CENTER")
    descText:SetText("|cff555560" .. "|cff00c761HideAnything|r " .. L["ABOUT_DESC"] .. "|r")

    y = y - 24

    parent:SetHeight(math.abs(y) + 10)
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
StaticPopupDialogs["HIDEANYTHING_CONFIRM_DELETE_PROFILE"] = {
    text    = "",
    button1 = "",
    button2 = "",
    OnAccept = function()
        if HA._pendingDeleteProfile then
            HA:DeleteProfile(HA._pendingDeleteProfile, true)
            HA:RefreshProfileList()
            HA._pendingDeleteProfile = nil
        end
    end,
    timeout        = 0,
    whileDead      = true,
    hideOnEscape   = true,
    preferredIndex = 3,
}

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
    title:SetText("|cff00c761" .. (L["UI_EXPORT_TITLE"] or "Export Profile") .. "|r")

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

    -- Re-select all text whenever user clicks into the editbox
    eb:SetScript("OnEditFocusGained", function(self)
        self:HighlightText()
    end)

    -- Hint label
    local hint = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("BOTTOMLEFT", 16, 46)
    hint:SetText("|cff555560Ctrl+C " .. (HA.L["UI_EXPORT_HINT"] or "to copy") .. "|r")

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
    title:SetText("|cff00c761" .. (HA.L["UI_IMPORT_TITLE"] or "Import Profile") .. "|r")

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

---------------------------------------------------------------------------
-- Keyboard navigation
---------------------------------------------------------------------------
panel:EnableKeyboard(true)
panel:SetPropagateKeyboardInput(true)

panel:SetScript("OnKeyDown", function(self, key)
    -- Only handle when panel is shown and no editbox is focused
    if not self:IsShown() then return end
    local focus = GetCurrentKeyBoardFocus()
    if focus then
        self:SetPropagateKeyboardInput(true)
        return
    end

    if key == "TAB" then
        -- Cycle tabs
        self:SetPropagateKeyboardInput(false)
        local nextTab = (activeTab or 1) % 3 + 1
        HA:SelectTab(nextTab)
    elseif key == "F" and IsControlKeyDown() then
        -- Focus search box
        self:SetPropagateKeyboardInput(false)
        local searchBox = _G["HideAnythingSearchBox"]
        if searchBox then searchBox:SetFocus() end
    elseif key == "Z" and IsControlKeyDown() then
        self:SetPropagateKeyboardInput(false)
        HA:Undo()
    elseif key == "Y" and IsControlKeyDown() then
        self:SetPropagateKeyboardInput(false)
        HA:Redo()
    elseif key == "P" and IsControlKeyDown() then
        self:SetPropagateKeyboardInput(false)
        HA:ToggleFramePicker()
    else
        self:SetPropagateKeyboardInput(true)
    end
end)
