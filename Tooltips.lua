--[[
    HideAnything - Tooltips.lua
    Tooltip helper utilities for the addon
]]

local AddonName, HA = ...

---------------------------------------------------------------------------
-- Show a standard tooltip anchored to a frame
---------------------------------------------------------------------------
function HA:ShowTooltip(owner, title, ...)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()

    if title then
        GameTooltip:AddLine(title, 0, 0.8, 0.4)
    end

    local lines = { ... }
    for i = 1, #lines do
        if lines[i] and lines[i] ~= "" then
            GameTooltip:AddLine(lines[i], 1, 1, 1, true)
        end
    end

    GameTooltip:Show()
end

---------------------------------------------------------------------------
-- Hide tooltip
---------------------------------------------------------------------------
function HA:HideTooltip()
    GameTooltip:Hide()
end

---------------------------------------------------------------------------
-- Create a tooltip-enabled region mixin
-- Usage: HA:AddTooltip(frame, title, line1, line2, ...)
---------------------------------------------------------------------------
function HA:AddTooltip(frame, title, ...)
    if not frame then return end

    local lines = { ... }

    frame:SetScript("OnEnter", function(self)
        HA:ShowTooltip(self, title, unpack(lines))
    end)

    frame:SetScript("OnLeave", function(self)
        HA:HideTooltip()
    end)
end
