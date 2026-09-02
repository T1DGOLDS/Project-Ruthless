local _, AUI = ...

local Menu = {
    tabs = {},
    panels = {},
}
AUI:RegisterModule("Menu", Menu)

local function AddLabel(parent, text, anchor, relativeTo, relativePoint, x, y, fontObject)
    local label = parent:CreateFontString(nil, "OVERLAY", fontObject or "GameFontNormal")
    label:SetPoint(anchor, relativeTo or parent, relativePoint or anchor, x or 0, y or 0)
    label:SetText(text)
    return label
end

function Menu:CreateStatusPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()

    AddLabel(panel, "Project Ruthless", "TOPLEFT", panel, "TOPLEFT", 18, -18, "GameFontNormalLarge")
    AddLabel(panel, "Personal World of Warcraft interface", "TOPLEFT", panel, "TOPLEFT", 18, -45, "GameFontHighlight")

    panel.versionLabel = AddLabel(panel, "", "TOPLEFT", panel, "TOPLEFT", 18, -92)
    panel.elvLabel = AddLabel(panel, "", "TOPLEFT", panel, "TOPLEFT", 18, -120)
    panel.tooltipLabel = AddLabel(panel, "", "TOPLEFT", panel, "TOPLEFT", 18, -148)
    panel.errorLabel = AddLabel(panel, "", "TOPLEFT", panel, "TOPLEFT", 18, -176)

    local hint = AddLabel(panel, "Use the tabs below to inspect Project Ruthless. The Errors tab is copyable.", "BOTTOMLEFT", panel, "BOTTOMLEFT", 18, 18, "GameFontDisable")
    hint:SetWidth(650)
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
    editBox:SetWidth(690)
    editBox:SetTextInsets(8, 8, 8, 8)
    editBox:SetScript("OnEscapePressed", function()
        self.frame:Hide()
    end)
    scroll:SetScrollChild(editBox)

    panel.editBox = editBox
    self.panels.errors = panel
end

function Menu:CreateTab(id, text, index)
    local tab = CreateFrame("Button", self.frame:GetName() .. "Tab" .. index, self.frame, "PanelTabButtonTemplate")
    tab:SetID(index)
    tab:SetText(text)
    tab:SetScript("OnClick", function()
        self:SelectTab(id)
    end)

    if index == 1 then
        tab:SetPoint("TOPLEFT", self.frame, "BOTTOMLEFT", 12, 2)
    else
        tab:SetPoint("LEFT", self.tabs[index - 1], "RIGHT", -14, 0)
    end

    PanelTemplates_TabResize(tab, 0)
    self.tabs[index] = tab
    tab.panelID = id
end

function Menu:Create()
    if self.frame then
        return
    end

    local frame = CreateFrame("Frame", "ProjectRuthlessMenuFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(760, 520)
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
    frame.TitleText:SetText("Project Ruthless")
    frame:Hide()

    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", 8, -30)
    content:SetPoint("BOTTOMRIGHT", -8, 8)

    self.frame = frame
    self.content = content
    self:CreateStatusPanel(content)
    self:CreateErrorsPanel(content)
    self:CreateTab("status", "Status", 1)
    self:CreateTab("errors", "Errors", 2)
    PanelTemplates_SetNumTabs(frame, #self.tabs)
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
end

function Menu:SelectTab(id)
    self:Create()

    for index, tab in ipairs(self.tabs) do
        local selected = tab.panelID == id
        self.panels[tab.panelID]:SetShown(selected)
        if selected then
            PanelTemplates_SelectTab(tab)
            PanelTemplates_SetTab(self.frame, index)
        else
            PanelTemplates_DeselectTab(tab)
        end
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
