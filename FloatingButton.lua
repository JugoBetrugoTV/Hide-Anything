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
    GameTooltip:AddLine(L["MINIMAP_TOOLTIP_RIGHT"] or "|cff00cc66Right-Click|r: Frame Picker", 1, 1, 1)
    GameTooltip:AddLine(L["MINIMAP_TOOLTIP_SHIFT"], 1, 1, 1)
    GameTooltip:AddLine(L["MINIMAP_TOOLTIP_DRAG"] or "|cff888888Drag|r to move", 1, 1, 1)

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
    elseif button == "RightButton" then
        HA:ToggleFramePicker()
    end
end)

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------
-- Improvement #25: frame count badge
local badge = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
badge:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, -2)
badge:SetJustifyH("RIGHT")
badge:Hide()

function HA:UpdateFloatingBadge()
    if not self.db then return end
    local count = self:GetHiddenCount()
    if count > 0 then
        badge:SetText("|cffffffff" .. count .. "|r")
        badge:Show()
    else
        badge:Hide()
    end
end

function HA:InitFloatingButton()
    -- Restore saved position or center on first start
    if self.db and self.db.floatingButton then
        local pos = self.db.floatingButton
        if pos.point and pos.relPoint and pos.x and pos.y then
            btn:ClearAllPoints()
            btn:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
        end
    else
        -- Improvement #15: First start safety - use TOPRIGHT if UIScale is very small
        local scale = UIParent:GetEffectiveScale()
        local point, yOff
        if scale < 0.5 then
            point, yOff = "TOPRIGHT", -40
        else
            point, yOff = "CENTER", 200
        end

        btn:ClearAllPoints()
        btn:SetPoint(point, UIParent, point, point == "TOPRIGHT" and -40 or 0, yOff)
        btn:SetSize(48, 48)
        label:SetFontObject(GameFontNormal)
        label:SetText("|cff00cc66HA|r")

        -- Pulse animation to draw attention on first start
        local pulseGroup = btn:CreateAnimationGroup()
        local pulseOut = pulseGroup:CreateAnimation("Scale")
        pulseOut:SetScale(1.15, 1.15)
        pulseOut:SetDuration(0.5)
        pulseOut:SetOrder(1)
        pulseOut:SetSmoothing("IN_OUT")
        local pulseIn = pulseGroup:CreateAnimation("Scale")
        pulseIn:SetScale(1/1.15, 1/1.15)
        pulseIn:SetDuration(0.5)
        pulseIn:SetOrder(2)
        pulseIn:SetSmoothing("IN_OUT")
        pulseGroup:SetLooping("REPEAT")
        pulseGroup:Play()

        -- Stop pulsing after 6 seconds and shrink to normal size
        C_Timer.After(6, function()
            if not btn or not pulseGroup then return end
            pulseGroup:Stop()
            btn:SetSize(36, 36)
            label:SetFontObject(GameFontNormalSmall)
            label:SetText("|cff00cc66HA|r")
        end)
    end

    -- Improvement #15: Verify button is on-screen after 1s, reposition if not
    C_Timer.After(1, function()
        if not btn:IsVisible() then return end
        local left, bottom, width, height = btn:GetRect()
        if not left then return end
        local screenW, screenH = UIParent:GetWidth(), UIParent:GetHeight()
        if left < 0 or bottom < 0 or (left + (width or 36)) > screenW or (bottom + (height or 36)) > screenH then
            btn:ClearAllPoints()
            btn:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -40, -40)
            HA:DebugLog("Floating button was off-screen, repositioned to TOPRIGHT")
        end
    end)

    btn:Show()
    self:UpdateFloatingBadge()
end
