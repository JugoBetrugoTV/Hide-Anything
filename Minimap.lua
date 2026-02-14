--[[
    HideAnything - Minimap.lua
    Minimap button using LibDBIcon-1.0
    Falls back to direct LDB data object if LibDBIcon is unavailable
]]

local AddonName, HA = ...

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------
function HA:InitMinimap()
    -- LDB must be initialized first (called from Core.lua OnInitialize)
    if not self.ldbObject then
        self:InitLDB()
    end

    local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)

    if LDBIcon and self.ldbObject then
        -- Register with LibDBIcon (uses self.db.minimap for saved position)
        if not LDBIcon:IsRegistered("HideAnything") then
            LDBIcon:Register("HideAnything", self.ldbObject, self.db.minimap)
        end

        if self.db.minimap.hide then
            LDBIcon:Hide("HideAnything")
        else
            LDBIcon:Show("HideAnything")
        end
    end
end

function HA:ToggleMinimapButton()
    local L = self.L
    if not self.db or not self.db.minimap then return end

    self.db.minimap.hide = not self.db.minimap.hide

    local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
    if LDBIcon and LDBIcon:IsRegistered("HideAnything") then
        if self.db.minimap.hide then
            LDBIcon:Hide("HideAnything")
        else
            LDBIcon:Show("HideAnything")
        end
    end

    if self.db.minimap.hide then
        self:Print(L["MINIMAP_HIDDEN"])
    else
        self:Print(L["MINIMAP_SHOWN"])
    end
end

function HA:ShowMinimapButton()
    if self.db and self.db.minimap then
        self.db.minimap.hide = false
    end
    local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
    if LDBIcon and LDBIcon:IsRegistered("HideAnything") then
        LDBIcon:Show("HideAnything")
    end
end

function HA:HideMinimapButton()
    if self.db and self.db.minimap then
        self.db.minimap.hide = true
    end
    local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
    if LDBIcon and LDBIcon:IsRegistered("HideAnything") then
        LDBIcon:Hide("HideAnything")
    end
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
