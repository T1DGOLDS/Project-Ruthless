local _, AUI = ...

local Compat = {}
AUI:RegisterModule("ElvUICompat", Compat)

function Compat:ApplySafeTooltip()
    if not ProjectRuthlessDB.elvui.safeTooltip then
        return false
    end

    local E = AUI:GetElvUI()
    if not E or type(E.private) ~= "table" then
        return false
    end

    E.private.tooltip = E.private.tooltip or {}
    E.private.skins = E.private.skins or {}
    E.private.skins.blizzard = E.private.skins.blizzard or {}

    E.private.tooltip.enable = false
    E.private.skins.blizzard.tooltip = false
    ProjectRuthlessCharDB.safeTooltipApplied = true

    return true
end

function Compat:OnAddonLoaded()
    self:ApplySafeTooltip()
end

function Compat:OnPlayerLogin()
    self:ApplySafeTooltip()
end

function Compat:ApplySettings()
    self:ApplySafeTooltip()
end
