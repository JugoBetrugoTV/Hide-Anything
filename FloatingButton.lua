--[[
    HideAnything - FloatingButton.lua
    Small draggable "HA" button on screen - always visible fallback
    Left-click: open config, Right-click: picker, Shift-click: show all
    Draggable to any position, saved between sessions
]]

local AddonName, HA = ...

---------------------------------------------------------------------------
-- Floating button
---------------------------------------------------------------------------
local btn = CreateFrame("Button", "HideAnythingFloatingButton", UIParent, "BackdropTemplate")
btn:SetSize(36, 36)
btn:SetPoint("TOP", UIParent, "TOP", 0, -20)
btn:SetFrameStrata("HIGH")
btn:SetFrameLevel(200)
btn:SetMovable(true)
btn:SetClampedToScreen(true)
btn:EnableMouse(true)
btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
btn:RegisterForDrag("LeftButton")

-- Visual style: dark rounded box with green border
btn:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets   = { left = 2, right = 2, top = 2, bottom = 2 },
})
btn:SetBackdropColor(0.05, 0.05, 0.05, 0.85)
btn:SetBackdropBorderColor(0, 0.8, 0.4, 0.9)

-- "HA" text label
local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
label:SetPoint("CENTER", 0, 0)
label:SetText("|cff00cc66HA|r")

-- Hover highlight
btn:SetScript("OnEnter", function(self)
    self:SetBackdropBorderColor(0.2, 1.0, 0.5, 1.0)
    self:SetBackdropColor(0.1, 0.15, 0.1, 0.95)

    local L = HA.L
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("|cff00cc66Hide|rAnything", 1, 1, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["MINIMAP_TOOLTIP_LEFT"], 1, 1, 1)
    GameTooltip:AddLine(L["MINIMAP_TOOLTIP_SHIFT"], 1, 1, 1)
    GameTooltip:AddLine("|cff888888Drag|r to move", 1, 1, 1)

    local count = HA:GetHiddenCount()
    if count > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(HA.L["STATUS_HIDDEN_COUNT"]:format(count), 1, 0.82, 0)
    end
    GameTooltip:Show()
end)

btn:SetScript("OnLeave", function(self)
    self:SetBackdropBorderColor(0, 0.8, 0.4, 0.9)
    self:SetBackdropColor(0.05, 0.05, 0.05, 0.85)
    GameTooltip:Hide()
end)

---------------------------------------------------------------------------
-- Dragging (save position)
---------------------------------------------------------------------------
btn:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

btn:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- Save position
    if HA.db then
        local point, _, relPoint, x, y = self:GetPoint()
        HA.db.floatingButton = {
            point    = point,
            relPoint = relPoint,
            x        = x,
            y        = y,
        }
    end
end)

---------------------------------------------------------------------------
-- Click handler
---------------------------------------------------------------------------
btn:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        if IsShiftKeyDown() then
            HA:ShowAllFrames()
        else
            HA:ToggleOptionsPanel()
        end
    end
end)

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------
function HA:InitFloatingButton()
    -- Restore saved position
    if self.db and self.db.floatingButton then
        local pos = self.db.floatingButton
        if pos.point and pos.relPoint and pos.x and pos.y then
            btn:ClearAllPoints()
            btn:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
        end
    end
    btn:Show()
end
