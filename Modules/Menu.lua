local _, AUI = ...

local Menu = {
    tabs = {},
    panels = {},
}
AUI:RegisterModule("Menu", Menu)

local COLORS = { window = {0.025,0.028,0.038,0.98}, sidebar = {0.035,0.039,0.052,0.99}, surface = {0.065,0.070,0.090,0.96}, border = {0.16,0.17,0.21,0.9}, text = {0.91,0.92,0.96,1}, muted = {0.52,0.55,0.64,1} }
local function GetAccentColor()
    local _, class = UnitClass("player")
    local color = class and RAID_CLASS_COLORS[class]
    if color then return color.r, color.g, color.b end
    return 0.50, 0.35, 0.94
end
local function ApplyBackdrop(frame, background, border)
    frame:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1 })
    frame:SetBackdropColor(unpack(background))
    frame:SetBackdropBorderColor(unpack(border or COLORS.border))
end

local function AddLabel(parent, text, anchor, relativeTo, relativePoint, x, y, fontObject)
    local label = parent:CreateFontString(nil, "OVERLAY", fontObject or "GameFontNormal")
    label:SetPoint(anchor, relativeTo or parent, relativePoint or anchor, x or 0, y or 0)
    label:SetText(text)
    label:SetTextColor(unpack(COLORS.text))
    return label
end

function Menu:CreateStatusPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()

    local eyebrow = AddLabel(panel, "SYSTEM OVERVIEW", "TOPLEFT", panel, "TOPLEFT", 18, -18, "GameFontNormalSmall")
    eyebrow:SetTextColor(unpack(COLORS.muted))
    AddLabel(panel, "Interface status", "TOPLEFT", panel, "TOPLEFT", 18, -44, "GameFontNormalHuge")

    panel.versionLabel = AddLabel(panel, "", "TOPLEFT", panel, "TOPLEFT", 18, -92)
    panel.elvLabel = AddLabel(panel, "", "TOPLEFT", panel, "TOPLEFT", 18, -120)
    panel.tooltipLabel = AddLabel(panel, "", "TOPLEFT", panel, "TOPLEFT", 18, -148)
    panel.errorLabel = AddLabel(panel, "", "TOPLEFT", panel, "TOPLEFT", 18, -176)

    local hint = AddLabel(panel, "Use the tabs below to inspect Project Ruthless. The Errors tab is copyable.", "BOTTOMLEFT", panel, "BOTTOMLEFT", 18, 18, "GameFontDisable")
    hint:SetWidth(520)
    hint:SetJustifyH("LEFT")

    self.panels.status = panel
end

function Menu:CreateErrorsPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()

    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -12)
    scroll:SetPoint("BOTTOMRIGHT", -30, 12)

    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(520)
    editBox:SetTextInsets(8, 8, 8, 8)
    editBox:SetScript("OnEscapePressed", function()
        self.frame:Hide()
    end)
    scroll:SetScrollChild(editBox)

    panel.editBox = editBox
    self.panels.errors = panel
end

function Menu:CreateTab(id, text, index)
    local r, g, b = GetAccentColor()
    local tab = CreateFrame("Button", self.frame:GetName() .. "Tab" .. index, self.sidebar)
    tab:SetID(index)
    tab:SetSize(184, 42)
    tab.label = AddLabel(tab, text, "LEFT", tab, "LEFT", 20, 0, "GameFontNormal")
    tab.label:SetTextColor(unpack(COLORS.muted))
    tab.highlight = tab:CreateTexture(nil, "BACKGROUND")
    tab.highlight:SetAllPoints(); tab.highlight:SetColorTexture(r,g,b,0.08); tab.highlight:Hide()
    tab.accent = tab:CreateTexture(nil, "ARTWORK")
    tab.accent:SetColorTexture(r,g,b,1); tab.accent:SetPoint("TOPLEFT"); tab.accent:SetPoint("BOTTOMLEFT"); tab.accent:SetWidth(3); tab.accent:Hide()
    tab:SetScript("OnClick", function()
        self:SelectTab(id)
    end)

    if index == 1 then
        tab:SetPoint("TOPLEFT", self.sidebar, "TOPLEFT", 12, -92)
    else
        tab:SetPoint("TOPLEFT", self.tabs[index - 1], "BOTTOMLEFT", 0, -4)
    end

    tab:SetScript("OnEnter", function(button) button.highlight:Show() end)
    tab:SetScript("OnLeave", function(button) if not button.selected then button.highlight:Hide() end end)
    self.tabs[index] = tab
    tab.panelID = id
end

function Menu:Create()
    if self.frame then
        return
    end

    local r, g, b = GetAccentColor()
    local frame = CreateFrame("Frame", "ProjectRuthlessMenuFrame", UIParent, "BackdropTemplate")
    frame:SetSize(820, 560)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetScript("OnShow", function()
        self:Refresh()
    end)
    ApplyBackdrop(frame, COLORS.window, {r,g,b,0.8})
    frame:Hide()

    local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    header:SetPoint("TOPLEFT",1,-1); header:SetPoint("TOPRIGHT",-1,-1); header:SetHeight(64)
    ApplyBackdrop(header, COLORS.surface, {0,0,0,0})
    local line = header:CreateTexture(nil,"ARTWORK"); line:SetColorTexture(r,g,b,1); line:SetPoint("BOTTOMLEFT"); line:SetPoint("BOTTOMRIGHT"); line:SetHeight(2)
    local mark = AddLabel(header,"PR","LEFT",header,"LEFT",18,0,"GameFontNormalHuge"); mark:SetTextColor(r,g,b,1)
    AddLabel(header,"PROJECT RUTHLESS","LEFT",mark,"RIGHT",16,0,"GameFontNormalLarge")
    local close = CreateFrame("Button",nil,header); close:SetSize(42,42); close:SetPoint("RIGHT",-5,0)
    close.label = AddLabel(close,"×","CENTER",close,"CENTER",0,1,"GameFontNormalHuge"); close.label:SetTextColor(unpack(COLORS.muted))
    close:SetScript("OnClick",function() frame:Hide() end)

    local sidebar = CreateFrame("Frame",nil,frame,"BackdropTemplate")
    sidebar:SetPoint("TOPLEFT",1,-65); sidebar:SetPoint("BOTTOMLEFT",1,1); sidebar:SetWidth(210)
    ApplyBackdrop(sidebar,COLORS.sidebar,{0,0,0,0})
    local navTitle=AddLabel(sidebar,"CONTROL CENTRE","TOPLEFT",sidebar,"TOPLEFT",30,-58,"GameFontNormalSmall"); navTitle:SetTextColor(unpack(COLORS.muted))

    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 24, -24)
    content:SetPoint("BOTTOMRIGHT", -24, 24)

    self.frame = frame
    self.sidebar = sidebar
    self.content = content
    self:CreateStatusPanel(content)
    self:CreateErrorsPanel(content)
    if AUI.modules.Titles then
        self.panels.titles = AUI.modules.Titles:CreatePanel(content)
    end
    self:CreateTab("status", "Status", 1)
    self:CreateTab("errors", "Errors", 2)
    self:CreateTab("titles", "Titles", 3)
end

function Menu:Refresh()
    if not self.frame then
        return
    end

    local E = AUI:GetElvUI()
    local elvVersion = E and E.version or "not loaded"
    local tooltipState = ProjectRuthlessDB.elvui.safeTooltip and "Enabled" or "Disabled"
    local errorModule = AUI.modules.ErrorLog
    local errorText, errorCount = errorModule:GetFormattedText()

    self.panels.status.versionLabel:SetText("Project Ruthless version: " .. tostring(AUI.version))
    self.panels.status.elvLabel:SetText("ElvUI detected: " .. tostring(elvVersion))
    self.panels.status.tooltipLabel:SetText("Safe tooltip compatibility: " .. tooltipState)
    self.panels.status.errorLabel:SetText(("Captured Lua errors: %d"):format(errorCount))
    self.panels.errors.editBox:SetText(errorText)
    self.panels.errors.editBox:SetCursorPosition(0)
    if AUI.modules.Titles and self.panels.titles then
        AUI.modules.Titles:Refresh()
    end
end

function Menu:SelectTab(id)
    self:Create()

    for _, tab in ipairs(self.tabs) do
        local selected = tab.panelID == id
        self.panels[tab.panelID]:SetShown(selected)
        tab.selected=selected
        tab.accent:SetShown(selected)
        tab.highlight:SetShown(selected)
        tab.label:SetTextColor(unpack(selected and COLORS.text or COLORS.muted))
    end

    self.selectedTab = id
    self:Refresh()
end

function Menu:Show(tab)
    self:Create()
    self:SelectTab(tab or self.selectedTab or "status")
    self.frame:Show()
    self.frame:Raise()
end
