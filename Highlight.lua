--[[
    HideAnything - Highlight.lua
    Frame highlight system: shows a glowing border around
    the actual game frame when hovering over a catalog row
]]

local AddonName, HA = ...

---------------------------------------------------------------------------
-- Highlight overlay frame (reusable singleton)
---------------------------------------------------------------------------
local highlighter = CreateFrame("Frame", "HideAnythingHighlighter", UIParent, "BackdropTemplate")
highlighter:SetFrameStrata("TOOLTIP")
highlighter:SetFrameLevel(999)
highlighter:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets   = { left = 4, right = 4, top = 4, bottom = 4 },
})
highlighter:SetBackdropBorderColor(0, 1, 0.5, 0.9)
highlighter:Hide()

-- Inner glow texture
local glow = highlighter:CreateTexture(nil, "BACKGROUND")
glow:SetAllPoints()
glow:SetTexture("Interface\\Buttons\\WHITE8X8")
glow:SetColorTexture(0, 0.8, 0.4, 0.15)

-- Label showing the frame name
local nameLabel = highlighter:CreateFontString(nil, "OVERLAY", "GameFontNormal")
nameLabel:SetPoint("TOP", highlighter, "BOTTOM", 0, -2)
nameLabel:SetTextColor(0, 0.8, 0.4, 1)

---------------------------------------------------------------------------
-- Show highlight around a game frame
---------------------------------------------------------------------------
function HA:HighlightFrame(frameName)
    if not frameName or frameName == "" then
        self:UnhighlightFrame()
        return
    end

    local frame = self:GetFrameByName(frameName)
    if not frame or not frame.GetCenter or not frame:IsShown() then
        -- If frame is hidden, show a faint outline at its position if possible
        if frame and frame.GetRect then
            local left, bottom, width, height = frame:GetRect()
            if left and width and width > 0 and height > 0 then
                highlighter:ClearAllPoints()
                highlighter:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left - 4, bottom - 4)
                highlighter:SetSize(width + 8, height + 8)
                highlighter:SetBackdropBorderColor(1, 0.4, 0.2, 0.7)
                glow:SetColorTexture(1, 0.3, 0.1, 0.1)
                nameLabel:SetText("|cffff6633" .. frameName .. " (hidden)|r")
                highlighter:Show()
                return
            end
        end
        self:UnhighlightFrame()
        return
    end

    local left, bottom, width, height = frame:GetRect()
    if not left or not width or width == 0 or height == 0 then
        self:UnhighlightFrame()
        return
    end

    highlighter:ClearAllPoints()
    highlighter:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left - 4, bottom - 4)
    highlighter:SetSize(width + 8, height + 8)
    highlighter:SetBackdropBorderColor(0, 1, 0.5, 0.9)
    glow:SetColorTexture(0, 0.8, 0.4, 0.15)
    nameLabel:SetText("|cff00cc66" .. frameName .. "|r")
    highlighter:Show()
end

---------------------------------------------------------------------------
-- Hide highlight
---------------------------------------------------------------------------
function HA:UnhighlightFrame()
    highlighter:Hide()
end
