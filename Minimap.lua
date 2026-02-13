--[[
    HideAnything - Minimap.lua
    Minimap button: draggable, left/right/shift-click, tooltip
]]

local AddonName, HA = ...

---------------------------------------------------------------------------
-- Minimap button frame
---------------------------------------------------------------------------
local minimapButton = CreateFrame("Button", "HideAnythingMinimapButton", Minimap)
minimapButton:SetSize(32, 32)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFrameLevel(8)
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
minimapButton:SetMovable(true)
minimapButton:SetClampedToScreen(true)
minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapButton:RegisterForDrag("LeftButton")
minimapButton:Hide()

-- Icon
local icon = minimapButton:CreateTexture(nil, "ARTWORK")
icon:SetSize(20, 20)
icon:SetPoint("CENTER")
icon:SetTexture("Interface\\Icons\\INV_Misc_Eye_02")

-- Border
local overlay = minimapButton:CreateTexture(nil, "OVERLAY")
overlay:SetSize(54, 54)
overlay:SetPoint("CENTER")
overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

-- Background
local bg = minimapButton:CreateTexture(nil, "BACKGROUND")
bg:SetSize(24, 24)
bg:SetPoint("CENTER")
bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

---------------------------------------------------------------------------
-- Position around the minimap circle
---------------------------------------------------------------------------
local function UpdatePosition()
    local pos = HA.db and HA.db.minimap and HA.db.minimap.minimapPos or 220
    local angle = math.rad(pos)
    local x = math.cos(angle) * 80
    local y = math.sin(angle) * 80
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

---------------------------------------------------------------------------
-- Dragging logic
---------------------------------------------------------------------------
local isDragging = false

minimapButton:SetScript("OnDragStart", function(self)
    isDragging = true
    self:SetScript("OnUpdate", function(self)
        local mx, my = Minimap:GetCenter()
        local cx, cy = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale
        local angle = math.deg(math.atan2(cy - my, cx - mx))
        if HA.db and HA.db.minimap then
            HA.db.minimap.minimapPos = angle
        end
        UpdatePosition()
    end)
end)

minimapButton:SetScript("OnDragStop", function(self)
    isDragging = false
    self:SetScript("OnUpdate", nil)
end)

---------------------------------------------------------------------------
-- Click handler
---------------------------------------------------------------------------
minimapButton:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        if IsShiftKeyDown() then
            HA:ShowAllFrames()
        else
            HA:ToggleOptionsPanel()
        end
    end
end)

---------------------------------------------------------------------------
-- Tooltip
---------------------------------------------------------------------------
minimapButton:SetScript("OnEnter", function(self)
    if isDragging then return end
    local L = HA.L
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine(L["MINIMAP_TOOLTIP_TITLE"])
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["MINIMAP_TOOLTIP_LEFT"], 1, 1, 1)
    GameTooltip:AddLine(L["MINIMAP_TOOLTIP_SHIFT"], 1, 1, 1)
    GameTooltip:AddLine(L["MINIMAP_TOOLTIP_DRAG"], 1, 1, 1)

    local count = HA:GetHiddenCount()
    if count > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(HA.L["STATUS_HIDDEN_COUNT"]:format(count), 1, 0.82, 0)
    end

    GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------
function HA:InitMinimap()
    UpdatePosition()
    if self.db and self.db.minimap and not self.db.minimap.hide then
        minimapButton:Show()
    else
        minimapButton:Hide()
    end
end

function HA:ToggleMinimapButton()
    local L = self.L
    if not self.db or not self.db.minimap then return end

    self.db.minimap.hide = not self.db.minimap.hide
    if self.db.minimap.hide then
        minimapButton:Hide()
        self:Print(L["MINIMAP_HIDDEN"])
    else
        minimapButton:Show()
        UpdatePosition()
        self:Print(L["MINIMAP_SHOWN"])
    end
end

function HA:ShowMinimapButton()
    if self.db and self.db.minimap then
        self.db.minimap.hide = false
    end
    minimapButton:Show()
    UpdatePosition()
end

function HA:HideMinimapButton()
    if self.db and self.db.minimap then
        self.db.minimap.hide = true
    end
    minimapButton:Hide()
end

---------------------------------------------------------------------------
-- Addon Compartment (WoW 11.x minimap dropdown list)
-- Global functions referenced by ## AddonCompartmentFunc in TOC
---------------------------------------------------------------------------
function HideAnything_OnAddonCompartmentClick(addonName, button)
    HA:ToggleOptionsPanel()
end

function HideAnything_OnAddonCompartmentEnter(addonName, menuButton)
    if menuButton and type(menuButton) == "table" and menuButton.GetObjectType then
        GameTooltip:SetOwner(menuButton, "ANCHOR_RIGHT")
    else
        GameTooltip:SetOwner(Minimap, "ANCHOR_BOTTOMLEFT")
    end
    GameTooltip:ClearLines()
    GameTooltip:AddLine(HA.L["MINIMAP_TOOLTIP_TITLE"])
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(HA.L["MINIMAP_TOOLTIP_LEFT"], 1, 1, 1)
    local count = HA:GetHiddenCount()
    if count > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(HA.L["STATUS_HIDDEN_COUNT"]:format(count), 1, 0.82, 0)
    end
    GameTooltip:Show()
end

function HideAnything_OnAddonCompartmentLeave(addonName, menuButton)
    GameTooltip:Hide()
end

-- InitMinimap is called from Core.lua OnInitialize directly
