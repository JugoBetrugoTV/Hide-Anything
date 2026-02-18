--[[
    HideAnything - FrameSelector.lua
    Frame picker: hover over any UI element to identify and hide it.
    Toggle with /hide picker or right-click the floating button.
]]

local AddonName, HA = ...

---------------------------------------------------------------------------
-- Picker overlay frame
---------------------------------------------------------------------------
local picker = CreateFrame("Frame", "HideAnythingFramePicker", UIParent)
picker:SetFrameStrata("FULLSCREEN_DIALOG")
picker:SetFrameLevel(500)
picker:SetAllPoints()
picker:EnableMouse(true)
picker:Hide()

-- Highlight box around hovered frame
local highlight = CreateFrame("Frame", nil, picker, "BackdropTemplate")
highlight:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
})
highlight:SetBackdropBorderColor(0, 0.78, 0.38, 0.9)
highlight:Hide()

local highlightGlow = highlight:CreateTexture(nil, "BACKGROUND")
highlightGlow:SetAllPoints()
highlightGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
highlightGlow:SetColorTexture(0, 0.78, 0.38, 0.12)

-- Name label
local nameLabel = picker:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
nameLabel:SetPoint("TOP", picker, "TOP", 0, -20)

-- Instruction label
local instructionLabel = picker:CreateFontString(nil, "OVERLAY", "GameFontNormal")
instructionLabel:SetPoint("TOP", nameLabel, "BOTTOM", 0, -6)
instructionLabel:SetTextColor(0.7, 0.7, 0.7)

-- Semi-transparent background to indicate picker mode
local bg = picker:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetTexture("Interface\\Buttons\\WHITE8X8")
bg:SetColorTexture(0, 0, 0, 0.15)

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------
local currentFrameName = nil
local currentFrame = nil
local isProtected = false

---------------------------------------------------------------------------
-- Find the top-level named frame under cursor
---------------------------------------------------------------------------
local function GetNamedFrameUnderCursor()
    local frame = GetMouseFocus()
    if not frame or frame == WorldFrame or frame == UIParent then
        return nil, nil
    end

    -- Walk up parent chain to find a named frame
    local f = frame
    local maxDepth = 20
    while f and maxDepth > 0 do
        local name = f:GetName()
        if name and name ~= "" and name ~= "UIParent" and name ~= "WorldFrame" then
            -- Skip our own frames
            if name == "HideAnythingFramePicker" or name == "HideAnythingOptionsFrame"
               or name == "HideAnythingHighlighter" or name == "HideAnythingAlphaPopup" then
                return nil, nil
            end
            return name, f
        end
        f = f:GetParent()
        maxDepth = maxDepth - 1
    end
    return nil, nil
end

---------------------------------------------------------------------------
-- Update highlight position
---------------------------------------------------------------------------
local function UpdateHighlight()
    local name, frame = GetNamedFrameUnderCursor()

    if name and frame then
        currentFrameName = name
        currentFrame = frame

        local left, bottom, width, height = frame:GetRect()
        if left and width and width > 0 and height > 0 then
            highlight:ClearAllPoints()
            highlight:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left - 3, bottom - 3)
            highlight:SetSize(width + 6, height + 6)

            -- Check if protected
            isProtected = HA.PROTECTED_FRAMES[name] or false

            if isProtected then
                highlight:SetBackdropBorderColor(1, 0.2, 0.1, 0.9)
                highlightGlow:SetColorTexture(1, 0.1, 0, 0.1)
                nameLabel:SetText("|cffff4444" .. name .. "|r  |cffff6666(protected)|r")
            elseif HA.db and HA.db.hiddenFrames[name] then
                highlight:SetBackdropBorderColor(1, 0.6, 0, 0.9)
                highlightGlow:SetColorTexture(1, 0.5, 0, 0.1)
                nameLabel:SetText("|cffffaa00" .. name .. "|r  |cffffcc44(already hidden)|r")
            else
                highlight:SetBackdropBorderColor(0, 0.78, 0.38, 0.9)
                highlightGlow:SetColorTexture(0, 0.78, 0.38, 0.12)
                nameLabel:SetText("|cff00c761" .. name .. "|r")
            end
            highlight:Show()
        else
            highlight:Hide()
            currentFrameName = nil
            currentFrame = nil
        end
    else
        highlight:Hide()
        nameLabel:SetText("|cff888888" .. (HA.L["PICKER_HOVER_HINT"] or "Hover over a UI element...") .. "|r")
        currentFrameName = nil
        currentFrame = nil
        isProtected = false
    end
end

---------------------------------------------------------------------------
-- OnUpdate (throttled)
---------------------------------------------------------------------------
local elapsed = 0
picker:SetScript("OnUpdate", function(self, dt)
    elapsed = elapsed + dt
    if elapsed < 0.05 then return end
    elapsed = 0
    UpdateHighlight()
end)

---------------------------------------------------------------------------
-- Click handlers
---------------------------------------------------------------------------
picker:SetScript("OnMouseDown", function(self, button)
    if button == "RightButton" then
        HA:DeactivateFramePicker()
        return
    end

    if button == "LeftButton" and currentFrameName then
        if isProtected then
            HA:FeedbackProtected(currentFrameName)
            return
        end
        if HA.db and HA.db.hiddenFrames[currentFrameName] then
            HA:FeedbackAlreadyHidden(currentFrameName)
            return
        end

        -- Hide the frame
        HA:DeactivateFramePicker()
        HA:HideFrame(currentFrameName)

        -- Refresh UI if open
        if HA.RefreshFrameList then
            HA:RefreshFrameList()
        end
    end
end)

---------------------------------------------------------------------------
-- ESC to cancel
---------------------------------------------------------------------------
picker:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
        self:SetPropagateKeyboardInput(false)
        HA:DeactivateFramePicker()
    else
        self:SetPropagateKeyboardInput(true)
    end
end)

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------
function HA:ActivateFramePicker()
    local L = self.L

    if InCombatLockdown() then
        self:FeedbackCombatError()
        return
    end

    instructionLabel:SetText(L["PICKER_INSTRUCTIONS"] or "|cff00c761Left-Click|r to hide  |  |cffff4444Right-Click|r or |cffff4444ESC|r to cancel")
    nameLabel:SetText("|cff888888" .. (L["PICKER_HOVER_HINT"] or "Hover over a UI element...") .. "|r")

    picker:Show()
    picker:EnableKeyboard(true)
    self._pickerActive = true
    self:ChatMsg(L["PICKER_ACTIVATED"] or "|cff00c761Frame Picker|r activated. Click a frame to hide it.")
end

function HA:DeactivateFramePicker()
    picker:Hide()
    picker:EnableKeyboard(false)
    highlight:Hide()
    currentFrameName = nil
    currentFrame = nil
    isProtected = false
    self._pickerActive = false
end

function HA:ToggleFramePicker()
    if self._pickerActive then
        self:DeactivateFramePicker()
    else
        self:ActivateFramePicker()
    end
end

function HA:IsFramePickerActive()
    return self._pickerActive or false
end
