local _, AUI = ...

local LowHealthGlow = {}
AUI:RegisterModule("LowHealthGlow", LowHealthGlow)

local function GetSettings()
    return ProjectRuthlessDB and ProjectRuthlessDB.lowHealthGlow
end

function LowHealthGlow:CreateOverlay()
    if self.frame then return end

    local frame = CreateFrame("Frame", "ProjectRuthlessLowHealthGlow", UIParent)
    frame:SetAllPoints(UIParent)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(1)
    frame:EnableMouse(false)
    frame:SetAlpha(0)

    local texture = frame:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints(frame)
    texture:SetTexture("Interface\\FullScreenTextures\\LowHealth")
    texture:SetVertexColor(1, 0.04, 0.04, 1)
    texture:SetBlendMode("ADD")

    self.frame = frame
    self.texture = texture
end

function LowHealthGlow:CreateAlphaCurve()
    local settings = GetSettings()
    local curve = C_CurveUtil.CreateCurve()
    curve:SetType(Enum.LuaCurveType.Linear)
    curve:AddPoint(0, settings.maxAlpha)
    curve:AddPoint(settings.threshold * 0.12, settings.maxAlpha * 0.92)
    curve:AddPoint(settings.threshold * 0.28, settings.maxAlpha * 0.66)
    curve:AddPoint(settings.threshold * 0.50, settings.maxAlpha * 0.30)
    curve:AddPoint(settings.threshold * 0.75, settings.maxAlpha * 0.08)
    curve:AddPoint(settings.threshold, 0)
    curve:AddPoint(1, 0)
    self.alphaCurve = curve
end

function LowHealthGlow:ApplySettings()
    self:CreateOverlay()
    self:CreateAlphaCurve()
    self:Update()
end

function LowHealthGlow:Update()
    local settings = GetSettings()
    if not settings or not settings.enabled or UnitIsDeadOrGhost("player") then
        self.frame:SetAlpha(0)
        return
    end

    local alpha = UnitHealthPercent("player", true, self.alphaCurve)
    self.frame:SetAlpha(alpha)
end

function LowHealthGlow:Preview()
    self:CreateOverlay()
    if UnitIsDeadOrGhost("player") then
        self.frame:SetAlpha(0)
        AUI:Print("Low-health glow stays hidden while dead or ghosted.")
        return
    end
    self.frame:SetAlpha(GetSettings().maxAlpha)
    C_Timer.After(3, function()
        self:Update()
    end)
end

function LowHealthGlow:HandleCommand(command)
    local settings = GetSettings()
    command = strtrim(command or ""):lower()

    if command == "test" then
        AUI:Print("Previewing the maximum 40% low-health glow for 3 seconds.")
        self:Preview()
    elseif command == "on" then
        settings.enabled = true
        self:Update()
        AUI:Print("Low-health glow enabled.")
    elseif command == "off" then
        settings.enabled = false
        self:Update()
        AUI:Print("Low-health glow disabled.")
    else
        AUI:Print("Health-glow commands: /pr healthglow test, /pr healthglow on, /pr healthglow off")
    end
end

function LowHealthGlow:OnPlayerLogin()
    self:CreateOverlay()
    self:CreateAlphaCurve()
    self:Update()

    self.frame:RegisterUnitEvent("UNIT_HEALTH", "player")
    self.frame:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.frame:RegisterEvent("PLAYER_ALIVE")
    self.frame:RegisterEvent("PLAYER_DEAD")
    self.frame:SetScript("OnEvent", function()
        self:Update()
    end)
end
