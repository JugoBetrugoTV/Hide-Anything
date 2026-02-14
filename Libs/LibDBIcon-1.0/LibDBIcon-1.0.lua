-- LibDBIcon-1.0 - Minimap icon management using LibDataBroker
-- License: Public Domain / CC0

local MAJOR, MINOR = "LibDBIcon-1.0", 56
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

lib.objects  = lib.objects  or {}
lib.buttons  = lib.buttons  or {}
lib.savedDBs = lib.savedDBs or {}
lib.tooltip  = lib.tooltip  or GameTooltip

local LDB = LibStub("LibDataBroker-1.1")

---------------------------------------------------------------------------
-- Default minimap position
---------------------------------------------------------------------------
local DEFAULT_DB = { minimapPos = 220, hide = false, lock = false }

---------------------------------------------------------------------------
-- Position math
---------------------------------------------------------------------------
local MINIMAP_RADIUS = 80

local function UpdatePosition(button, db)
    local angle = math.rad(db.minimapPos or DEFAULT_DB.minimapPos)
    local x = math.cos(angle) * MINIMAP_RADIUS
    local y = math.sin(angle) * MINIMAP_RADIUS
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

---------------------------------------------------------------------------
-- Dragging
---------------------------------------------------------------------------
local function OnDragStart(self)
    self.isDragging = true
    self:SetScript("OnUpdate", function(btn)
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale
        local angle = math.deg(math.atan2(cy - my, cx - mx))
        local db = lib.savedDBs[btn.name]
        if db then
            db.minimapPos = angle
        end
        UpdatePosition(btn, db or DEFAULT_DB)
    end)
end

local function OnDragStop(self)
    self.isDragging = false
    self:SetScript("OnUpdate", nil)
end

---------------------------------------------------------------------------
-- Click handler
---------------------------------------------------------------------------
local function OnClick(self, button)
    local obj = lib.objects[self.name]
    if obj and obj.OnClick then
        obj.OnClick(self, button)
    end
end

---------------------------------------------------------------------------
-- Tooltip
---------------------------------------------------------------------------
local function OnEnter(self)
    if self.isDragging then return end
    local obj = lib.objects[self.name]
    if obj and obj.OnTooltipShow then
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:ClearLines()
        obj.OnTooltipShow(GameTooltip)
        GameTooltip:Show()
    end
end

local function OnLeave(self)
    GameTooltip:Hide()
end

---------------------------------------------------------------------------
-- Create a minimap button
---------------------------------------------------------------------------
local function CreateButton(name, obj, db)
    local button = CreateFrame("Button", "LibDBIcon10_" .. name, Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:SetMovable(true)
    button:SetClampedToScreen(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button.name = name
    button.isDragging = false

    -- Icon
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexture(obj.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    button.icon = icon

    -- Border
    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(54, 54)
    overlay:SetPoint("CENTER")
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    -- Background
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(24, 24)
    bg:SetPoint("CENTER")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    -- Scripts
    button:SetScript("OnClick", OnClick)
    button:SetScript("OnEnter", OnEnter)
    button:SetScript("OnLeave", OnLeave)
    button:SetScript("OnDragStart", OnDragStart)
    button:SetScript("OnDragStop", OnDragStop)

    UpdatePosition(button, db or DEFAULT_DB)

    return button
end

---------------------------------------------------------------------------
-- Update icon from LDB object
---------------------------------------------------------------------------
local function UpdateIcon(name)
    local button = lib.buttons[name]
    local obj = lib.objects[name]
    if button and obj and button.icon then
        button.icon:SetTexture(obj.icon)
    end
end

-- Listen for icon attribute changes
LDB.RegisterCallback(lib, "LibDataBroker_AttributeChanged", function(event, name, key, value, dataobj)
    if key == "icon" and lib.buttons[name] then
        UpdateIcon(name)
    end
end)

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

function lib:Register(name, obj, db)
    if self.buttons[name] then return end

    -- Ensure db has defaults
    if db then
        if db.minimapPos == nil then db.minimapPos = DEFAULT_DB.minimapPos end
        if db.hide == nil then db.hide = DEFAULT_DB.hide end
    else
        db = CopyTable(DEFAULT_DB)
    end

    self.objects[name]  = obj
    self.savedDBs[name] = db

    local button = CreateButton(name, obj, db)
    self.buttons[name] = button

    if db.hide then
        button:Hide()
    else
        button:Show()
    end
end

function lib:Show(name)
    local button = self.buttons[name]
    local db = self.savedDBs[name]
    if button then
        button:Show()
        if db then db.hide = false end
    end
end

function lib:Hide(name)
    local button = self.buttons[name]
    local db = self.savedDBs[name]
    if button then
        button:Hide()
        if db then db.hide = true end
    end
end

function lib:IsRegistered(name)
    return self.buttons[name] ~= nil
end

function lib:GetMinimapButton(name)
    return self.buttons[name]
end

function lib:Refresh(name)
    local db = self.savedDBs[name]
    local button = self.buttons[name]
    if button and db then
        UpdatePosition(button, db)
        if db.hide then button:Hide() else button:Show() end
    end
end

function lib:GetMinimapButtonDB(name)
    return self.savedDBs[name]
end
