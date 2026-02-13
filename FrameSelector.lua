--[[
    HideAnything - FrameSelector.lua
    Interactive frame picker: mouse-over highlight, tooltip, click to hide
]]

local AddonName, HA = ...

HA.pickerActive = false

---------------------------------------------------------------------------
-- Picker overlay frame (highlight rectangle)
---------------------------------------------------------------------------
local pickerOverlay = CreateFrame("Frame", "HideAnythingPickerOverlay", UIParent)
pickerOverlay:SetFrameStrata("TOOLTIP")
pickerOverlay:SetFrameLevel(999)
pickerOverlay:Hide()

-- Green highlight border
local border = pickerOverlay:CreateTexture(nil, "OVERLAY")
border:SetAllPoints()
border:SetColorTexture(0, 0.8, 0.4, 0.15) -- semi-transparent green fill

-- Border edges
local function CreateBorderEdge(parent, point1, rel1, point2, rel2, w, h)
    local edge = parent:CreateTexture(nil, "OVERLAY")
    edge:SetColorTexture(0, 0.8, 0.4, 0.8) -- solid green border
    edge:SetPoint(point1, parent, rel1)
    edge:SetPoint(point2, parent, rel2)
    if w then edge:SetWidth(w) end
    if h then edge:SetHeight(h) end
    return edge
end

CreateBorderEdge(pickerOverlay, "TOPLEFT", "TOPLEFT", "TOPRIGHT", "TOPRIGHT", nil, 2)
CreateBorderEdge(pickerOverlay, "BOTTOMLEFT", "BOTTOMLEFT", "BOTTOMRIGHT", "BOTTOMRIGHT", nil, 2)
CreateBorderEdge(pickerOverlay, "TOPLEFT", "TOPLEFT", "BOTTOMLEFT", "BOTTOMLEFT", 2, nil)
CreateBorderEdge(pickerOverlay, "TOPRIGHT", "TOPRIGHT", "BOTTOMRIGHT", "BOTTOMRIGHT", 2, nil)

-- Label at top
local pickerLabel = pickerOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
pickerLabel:SetPoint("BOTTOM", pickerOverlay, "TOP", 0, 4)
pickerLabel:SetTextColor(0, 0.8, 0.4)

---------------------------------------------------------------------------
-- Picker tooltip (custom GameTooltip usage)
---------------------------------------------------------------------------
local function ShowPickerTooltip(frame)
    local L = HA.L
    local name = HA:GetFrameName(frame)
    local objType = frame:GetObjectType() or "Unknown"
    local parent = frame:GetParent()
    local parentName = parent and (parent:GetName() or "Anonymous") or "none"
    local w, h = frame:GetSize()

    GameTooltip:SetOwner(pickerOverlay, "ANCHOR_BOTTOMRIGHT", 10, 10)
    GameTooltip:ClearLines()
    GameTooltip:AddLine(L["PICKER_TOOLTIP_TITLE"], 0, 0.8, 0.4)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["PICKER_TOOLTIP_NAME"]:format(name), 1, 1, 1)
    GameTooltip:AddLine(L["PICKER_TOOLTIP_TYPE"]:format(objType), 1, 1, 1)
    GameTooltip:AddLine(L["PICKER_TOOLTIP_PARENT"]:format(parentName), 1, 1, 1)
    GameTooltip:AddLine(L["PICKER_TOOLTIP_SIZE"]:format(w or 0, h or 0), 1, 1, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["PICKER_TOOLTIP_HINT"], 1, 1, 1)
    GameTooltip:Show()
end

---------------------------------------------------------------------------
-- Find the best frame under cursor
---------------------------------------------------------------------------
local function GetFrameUnderCursor()
    local frame = GetMouseFocus and GetMouseFocus()
    -- In 11.0+ GetMouseFocus might be deprecated; use GetMouseFoci
    if not frame and GetMouseFoci then
        local foci = GetMouseFoci()
        frame = foci and foci[1]
    end

    if not frame or frame == WorldFrame or frame == UIParent then
        return nil
    end

    -- Walk up to find a named or meaningful parent
    local current = frame
    local maxDepth = 10
    while current and maxDepth > 0 do
        local name = current:GetName()
        if name and name ~= "" and not HA:IsProtectedFrame(name) then
            return current
        end
        -- If the frame has no name, check if parent has one
        local parent = current:GetParent()
        if parent and parent ~= UIParent and parent ~= WorldFrame then
            local pName = parent:GetName()
            if pName and pName ~= "" and not HA:IsProtectedFrame(pName) then
                return parent
            end
        end
        current = current:GetParent()
        maxDepth = maxDepth - 1
    end

    return frame
end

---------------------------------------------------------------------------
-- Picker OnUpdate: highlight frame under cursor
---------------------------------------------------------------------------
local lastHighlighted = nil

local function PickerOnUpdate(self, elapsed)
    local frame = GetFrameUnderCursor()

    if frame and frame ~= pickerOverlay and frame ~= lastHighlighted then
        lastHighlighted = frame
        local name = HA:GetFrameName(frame)

        -- Position overlay on top of the frame
        pickerOverlay:ClearAllPoints()
        pickerOverlay:SetPoint("TOPLEFT", frame, "TOPLEFT")
        pickerOverlay:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
        pickerOverlay:Show()
        pickerLabel:SetText(name)

        -- Show tooltip
        ShowPickerTooltip(frame)
    elseif not frame then
        lastHighlighted = nil
        pickerOverlay:Hide()
        GameTooltip:Hide()
    end
end

---------------------------------------------------------------------------
-- Picker click handler frame (catches mouse clicks)
---------------------------------------------------------------------------
local pickerClickFrame = CreateFrame("Button", "HideAnythingPickerClickFrame", UIParent)
pickerClickFrame:SetAllPoints(UIParent)
pickerClickFrame:SetFrameStrata("FULLSCREEN_DIALOG")
pickerClickFrame:SetFrameLevel(998)
pickerClickFrame:EnableMouse(true)
pickerClickFrame:Hide()

pickerClickFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")

pickerClickFrame:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        -- Hide the frame under cursor
        local frame = GetFrameUnderCursor()
        if frame then
            local name = HA:GetFrameName(frame)
            HA:StopPicker()
            HA:HideFrame(name)
        else
            HA:Print(HA.L["PICKER_NO_FRAME"])
            HA:PlayFeedbackSound("error")
        end
    elseif button == "RightButton" then
        -- Cancel picker
        HA:StopPicker()
    end
end)

pickerClickFrame:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
        HA:StopPicker()
        self:SetPropagateKeyboardInput(false)
    else
        self:SetPropagateKeyboardInput(true)
    end
end)

---------------------------------------------------------------------------
-- Start picker mode
---------------------------------------------------------------------------
function HA:StartPicker()
    if self.inCombat or InCombatLockdown() then
        self:FeedbackCombatError()
        return
    end

    if self.pickerActive then
        self:StopPicker()
        return
    end

    self.pickerActive = true
    pickerClickFrame:Show()
    pickerClickFrame:EnableKeyboard(true)
    pickerOverlay:SetScript("OnUpdate", PickerOnUpdate)
    pickerOverlay:Show()

    self:FeedbackPickerStart()
end

---------------------------------------------------------------------------
-- Stop picker mode
---------------------------------------------------------------------------
function HA:StopPicker()
    if not self.pickerActive then return end

    self.pickerActive = false
    pickerClickFrame:Hide()
    pickerClickFrame:EnableKeyboard(false)
    pickerOverlay:SetScript("OnUpdate", nil)
    pickerOverlay:Hide()
    pickerLabel:SetText("")
    lastHighlighted = nil
    GameTooltip:Hide()

    self:FeedbackPickerStop()
end
