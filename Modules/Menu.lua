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

function Menu:CreateOptionsPanel(parent, eyebrow, title, description)
    local panel=CreateFrame("Frame",nil,parent); panel:SetAllPoints()
    local overline=AddLabel(panel,eyebrow,"TOPLEFT",panel,"TOPLEFT",18,-18,"GameFontNormalSmall"); overline:SetTextColor(unpack(COLORS.muted))
    AddLabel(panel,title,"TOPLEFT",panel,"TOPLEFT",18,-44,"GameFontNormalHuge")
    local copy=AddLabel(panel,description,"TOPLEFT",panel,"TOPLEFT",18,-76,"GameFontNormalSmall"); copy:SetWidth(610); copy:SetJustifyH("LEFT"); copy:SetTextColor(unpack(COLORS.muted))
    return panel
end

function Menu:CreateCheckbox(parent,label,description,y,getter,setter,section)
    local button=CreateFrame("Button",nil,parent,"BackdropTemplate"); button:SetSize(610,48); button:SetPoint("TOPLEFT",18,y); ApplyBackdrop(button,{0.035,0.039,0.052,0.92})
    button.box=CreateFrame("Frame",nil,button,"BackdropTemplate"); button.box:SetSize(20,20); button.box:SetPoint("LEFT",10,0); ApplyBackdrop(button.box,{0.02,0.023,0.032,1})
    button.tick=button.box:CreateTexture(nil,"ARTWORK"); button.tick:SetAtlas("common-icon-checkmark"); button.tick:SetSize(14,14); button.tick:SetPoint("CENTER")
    button.label=AddLabel(button,label,"TOPLEFT",button,"TOPLEFT",42,-8,"GameFontNormal")
    button.description=AddLabel(button,description,"TOPLEFT",button,"TOPLEFT",42,-27,"GameFontNormalSmall"); button.description:SetTextColor(unpack(COLORS.muted))
    button.getter=getter; button.setter=setter
    button.RefreshValue=function(self) local checked=self.getter(); self.tick:SetShown(checked); local r,g,b=GetAccentColor(); self.box:SetBackdropBorderColor(checked and r or COLORS.border[1],checked and g or COLORS.border[2],checked and b or COLORS.border[3],1) end
    button:SetScript("OnClick",function(self) self.setter(not self.getter()); AUI:SettingsChanged(section); Menu:Refresh() end)
    button:SetScript("OnEnter",function(self) self:SetBackdropColor(0.055,0.060,0.078,0.96) end); button:SetScript("OnLeave",function(self) self:SetBackdropColor(0.035,0.039,0.052,0.92) end)
    self.optionControls=self.optionControls or {}; self.optionControls[#self.optionControls+1]=button
    return button
end

function Menu:CreateSlider(parent,label,description,y,minimum,maximum,step,formatter,getter,setter,section)
    local holder=CreateFrame("Frame",nil,parent,"BackdropTemplate"); holder:SetSize(610,70); holder:SetPoint("TOPLEFT",18,y); ApplyBackdrop(holder,{0.035,0.039,0.052,0.92})
    holder.label=AddLabel(holder,label,"TOPLEFT",holder,"TOPLEFT",12,-9,"GameFontNormal"); holder.value=AddLabel(holder,"","TOPRIGHT",holder,"TOPRIGHT",-12,-9,"GameFontNormal")
    holder.description=AddLabel(holder,description,"TOPLEFT",holder,"TOPLEFT",12,-29,"GameFontNormalSmall"); holder.description:SetTextColor(unpack(COLORS.muted))
    local slider=CreateFrame("Slider",nil,holder,"BackdropTemplate"); slider:SetPoint("BOTTOMLEFT",12,10); slider:SetSize(586,10); slider:SetOrientation("HORIZONTAL"); slider:SetMinMaxValues(minimum,maximum); slider:SetValueStep(step); slider:SetObeyStepOnDrag(true); ApplyBackdrop(slider,{0.018,0.021,0.029,1})
    slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    local thumb=slider:GetThumbTexture(); thumb:SetSize(14,18)
    local r,g,b=GetAccentColor(); thumb:SetVertexColor(r,g,b,1)
    slider:SetScript("OnValueChanged",function(_,value)
        value=math.max(minimum,math.min(maximum,minimum+math.floor((value-minimum)/step+0.5)*step))
        holder.value:SetText(formatter(value))
        if not Menu.refreshing then setter(value); if not (label=="Window scale" and holder.dragging) then AUI:SettingsChanged(section) end end
    end)
    slider:HookScript("OnMouseDown",function() holder.dragging=true end)
    local function FinishDrag() if holder.dragging then holder.dragging=false; AUI:SettingsChanged(section) end end
    slider:HookScript("OnMouseUp",FinishDrag); slider:HookScript("OnHide",FinishDrag)
    holder.getter=getter; holder.RefreshValue=function(self) local value=self.getter(); slider:SetValue(value); self.value:SetText(formatter(value)) end
    self.optionControls=self.optionControls or {}; self.optionControls[#self.optionControls+1]=holder
    return holder
end

function Menu:CreateAction(parent,text,x,y,width,callback)
    local button=AUI:CreateButton(parent); button:SetSize(width or 130,26); button:SetPoint("TOPLEFT",x,y); button:SetText(text); button:SetScript("OnClick",callback); return button
end

function Menu:CreateGeneralPanel(parent)
    local panel=self:CreateOptionsPanel(parent,"CORE SETTINGS","General","Shared presentation settings for every Project Ruthless window.")
    self:CreateSlider(panel,"Window scale","Scale Ruthless windows; Talents also fits within your screen.",-116,0.75,1.25,0.01,function(v)return ("%d%%"):format(math.floor(v*100+0.5))end,function()return ProjectRuthlessDB.general.windowScale end,function(v)ProjectRuthlessDB.general.windowScale=v end,"General")
    self:CreateSlider(panel,"Window opacity","Fade complete Project Ruthless windows without affecting the rest of the UI.",-194,0.65,1,0.05,function(v)return ("%d%%"):format(math.floor(v*100+0.5))end,function()return ProjectRuthlessDB.general.windowOpacity end,function(v)ProjectRuthlessDB.general.windowOpacity=v end,"General")
    local note=AddLabel(panel,"Settings are account-wide. Character-specific state is kept separately where it makes sense.","TOPLEFT",panel,"TOPLEFT",20,-286,"GameFontNormalSmall"); note:SetWidth(590); note:SetJustifyH("LEFT"); note:SetTextColor(unpack(COLORS.muted))
    self.panels.general=panel
end

function Menu:CreateCharacterOptions(parent)
    local panel=self:CreateOptionsPanel(parent,"PLAYER PANEL","Character","Control the standalone Character replacement opened by the normal Character button and keybind.")
    self:CreateCheckbox(panel,"Enable experimental Character workspace","Use the Ruthless Paper Doll workspace. Blizzard's Character frame is the stable default.",-116,function()return ProjectRuthlessDB.character.replaceBlizzard end,function(v)ProjectRuthlessDB.character.replaceBlizzard=v end,"Character")
    self:CreateCheckbox(panel,"Show item-level badges","Display compact item levels over equipped gear slots.",-172,function()return ProjectRuthlessDB.character.showItemLevels end,function(v)ProjectRuthlessDB.character.showItemLevels=v end,"Character")
    self:CreateCheckbox(panel,"Show progress summary","Display Mythic+, raid, and rated-PvP progress beside the character identity.",-228,function()return ProjectRuthlessDB.character.showProgress end,function(v)ProjectRuthlessDB.character.showProgress=v end,"Character")
    self:CreateAction(panel,"Open Character",18,-300,140,function() if AUI.modules.Character then AUI.modules.Character:Toggle(true) end end)
    self.panels.character=panel
end

function Menu:CreateSpellbookOptions(parent)
    local panel=self:CreateOptionsPanel(parent,"ABILITIES & MACROS","Spellbook","Choose how aggressively Project Ruthless restores the pre-TWW Spellbook workflow.")
    self:CreateCheckbox(panel,"Replace the Professions book button","Open the Project Ruthless Spellbook from the normal book micro button.",-116,function()return ProjectRuthlessDB.spellbook.replaceProfessions end,function(v)ProjectRuthlessDB.spellbook.replaceProfessions=v end,"Spellbook")
    self:CreateCheckbox(panel,"Remove Spellbook from Talents","Keep Talents focused and route Spellbook requests to the standalone window.",-172,function()return ProjectRuthlessDB.spellbook.separateFromTalents end,function(v)ProjectRuthlessDB.spellbook.separateFromTalents=v end,"Spellbook")
    self:CreateCheckbox(panel,"Show other-specialization spells","Keep unavailable spec abilities visible as dimmed reference entries.",-228,function()return ProjectRuthlessDB.spellbook.showOffSpec end,function(v)ProjectRuthlessDB.spellbook.showOffSpec=v end,"Spellbook")
    self:CreateCheckbox(panel,"Highlight abilities missing from bars","Use Blizzard's missing-action-bar glow on relevant active abilities.",-284,function()return ProjectRuthlessDB.spellbook.highlightMissing end,function(v)ProjectRuthlessDB.spellbook.highlightMissing=v end,"Spellbook")
    self:CreateCheckbox(panel,"Macro autocomplete","Suggest live slash commands, conditionals, and learned spells in the macro editor.",-340,function()return ProjectRuthlessDB.spellbook.macroAutocomplete end,function(v)ProjectRuthlessDB.spellbook.macroAutocomplete=v end,"Spellbook")
    self:CreateAction(panel,"Open Spellbook",18,-412,140,function() if AUI.modules.Spellbook then AUI.modules.Spellbook:Show("class") end end)
    self.panels.spellbook=panel
end

function Menu:CreateHealthOptions(parent)
    local panel=self:CreateOptionsPanel(parent,"COMBAT FEEDBACK","Health warning","Configure the full-screen low-health warning.")
    self:CreateCheckbox(panel,"Enable low-health glow","Show the progressive red edge warning as health falls.",-116,function()return ProjectRuthlessDB.lowHealthGlow.enabled end,function(v)ProjectRuthlessDB.lowHealthGlow.enabled=v end,"LowHealthGlow")
    self:CreateSlider(panel,"Starting health","The warning begins below this health percentage.",-172,0.10,0.60,0.05,function(v)return ("%d%%"):format(math.floor(v*100+0.5))end,function()return ProjectRuthlessDB.lowHealthGlow.threshold end,function(v)ProjectRuthlessDB.lowHealthGlow.threshold=v end,"LowHealthGlow")
    self:CreateSlider(panel,"Maximum intensity","Maximum opacity reached at critically low health.",-250,0.10,0.80,0.05,function(v)return ("%d%%"):format(math.floor(v*100+0.5))end,function()return ProjectRuthlessDB.lowHealthGlow.maxAlpha end,function(v)ProjectRuthlessDB.lowHealthGlow.maxAlpha=v end,"LowHealthGlow")
    self:CreateAction(panel,"Preview glow",18,-338,130,function() if AUI.modules.LowHealthGlow then AUI.modules.LowHealthGlow:Preview() end end)
    self.panels.health=panel
end

function Menu:CreateTalentsOptions(parent)
    local panel=self:CreateOptionsPanel(parent,"BUILDS & SPECIALIZATION","Talents","A compact workspace with native talent trees, specialization choices, and a clean loadout list.")
    self:CreateCheckbox(panel,"Use compact Talents","Use the Ruthless layout on the normal Talents button and keybind.",-116,function()return ProjectRuthlessDB.talents.enabled end,function(v)ProjectRuthlessDB.talents.enabled=v end,"Talents")
    self:CreateAction(panel,"Open Talents",18,-184,140,function() if AUI.modules.Talents then AUI.modules.Talents:Show() end end)
    local note=AddLabel(panel,"Save copy names a copy of your current build. Manage opens rename, delete, and action-bar options. Changes made during combat apply after combat ends.","TOPLEFT",panel,"TOPLEFT",20,-232,"GameFontNormalSmall")
    note:SetWidth(580); note:SetJustifyH("LEFT"); note:SetTextColor(unpack(COLORS.muted))
    self.panels.talents=panel
end

function Menu:CreateAchievementsOptions(parent)
    local panel=self:CreateOptionsPanel(parent,"ACHIEVEMENTS & STATISTICS","Achievements","Turn Blizzard's Statistics tab into a useful overview of your character and account progress.")
    self:CreateCheckbox(panel,"Use the Statistics dashboard","Open Statistics on the Ruthless overview while retaining every Blizzard detail category.",-116,function()return ProjectRuthlessDB.achievements.enabled end,function(v)ProjectRuthlessDB.achievements.enabled=v end,"Achievements")
    self:CreateAction(panel,"Open Statistics",18,-184,140,function() if AUI.modules.Achievements then AUI.modules.Achievements:Show() end end)
    local note=AddLabel(panel,"The dashboard uses Blizzard's live achievement, title, and statistics records. Browse details returns to the complete native category list.","TOPLEFT",panel,"TOPLEFT",20,-232,"GameFontNormalSmall")
    note:SetWidth(580); note:SetJustifyH("LEFT"); note:SetTextColor(unpack(COLORS.muted))
    self.panels.achievements=panel
end

function Menu:CreateCompatibilityOptions(parent)
    local panel=self:CreateOptionsPanel(parent,"ADDON COEXISTENCE","Compatibility","Compatibility switches for the existing UI while Project Ruthless replaces it piece by piece.")
    self:CreateCheckbox(panel,"ElvUI safe-tooltip mode","Keep ElvUI's tooltip module and Blizzard tooltip skin disabled to avoid tooltip taint.",-116,function()return ProjectRuthlessDB.elvui.safeTooltip end,function(v)ProjectRuthlessDB.elvui.safeTooltip=v end,"ElvUICompat")
    local note=AddLabel(panel,"Enabling this applies immediately. Disabling it stops future enforcement but does not rewrite your ElvUI profile.","TOPLEFT",panel,"TOPLEFT",20,-184,"GameFontNormalSmall"); note:SetWidth(590); note:SetJustifyH("LEFT"); note:SetTextColor(unpack(COLORS.muted))
    self.panels.compatibility=panel
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
    local panel = self:CreateOptionsPanel(parent,"DIAGNOSTICS","Error log","Capture Lua errors quietly and keep enough history to diagnose addon problems.")
    self:CreateCheckbox(panel,"Enable error capture","Record Lua failures and group repeated chat notices.",-108,function()return ProjectRuthlessDB.errorLog.enabled end,function(v)ProjectRuthlessDB.errorLog.enabled=v end,"ErrorLog")
    self:CreateSlider(panel,"Maximum retained errors","Oldest entries are removed when the history reaches this size.",-164,10,200,10,function(v)return tostring(math.floor(v+0.5))end,function()return ProjectRuthlessDB.errorLog.maxEntries end,function(v)ProjectRuthlessDB.errorLog.maxEntries=math.floor(v+0.5); local entries=ProjectRuthlessDB.errorLog.entries; while #entries>ProjectRuthlessDB.errorLog.maxEntries do table.remove(entries,1) end end,"ErrorLog")
    self:CreateAction(panel,"Clear error log",18,-244,130,function() if AUI.modules.ErrorLog then AUI.modules.ErrorLog:HandleCommand("clear") end end)

    local scroll = AUI:CreateSmoothScrollFrame(panel)
    scroll:SetPoint("TOPLEFT", 12, -282)
    scroll:SetPoint("BOTTOMRIGHT", -12, 12)

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
    AUI:ConfigureScrollingEditBox(editBox,scroll,1)

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
    frame:SetSize(920, 620)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetScript("OnShow", function()
        self:Refresh()
    end)
    ApplyBackdrop(frame, COLORS.window, {r,g,b,0.8})
    frame:Hide()

    local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    header:SetPoint("TOPLEFT",1,-1); header:SetPoint("TOPRIGHT",-1,-1); header:SetHeight(64)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() frame:StartMoving() end)
    header:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
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
    self.optionControls = {}
    self:CreateGeneralPanel(content)
    self:CreateCharacterOptions(content)
    self:CreateSpellbookOptions(content)
    self:CreateTalentsOptions(content)
    self:CreateAchievementsOptions(content)
    self:CreateHealthOptions(content)
    self:CreateCompatibilityOptions(content)
    self:CreateErrorsPanel(content)
    self:CreateStatusPanel(content)
    self:CreateTab("general", "General", 1)
    self:CreateTab("character", "Character", 2)
    self:CreateTab("spellbook", "Spellbook", 3)
    self:CreateTab("talents", "Talents", 4)
    self:CreateTab("achievements", "Achievements", 5)
    self:CreateTab("health", "Health warning", 6)
    self:CreateTab("compatibility", "Compatibility", 7)
    self:CreateTab("errors", "Diagnostics", 8)
    self:CreateTab("status", "About", 9)
    AUI:ApplyWindowSettings()
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
    self.refreshing=true
    for _,control in ipairs(self.optionControls or {}) do if control.RefreshValue then control:RefreshValue() end end
    self.refreshing=false
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
    self:SelectTab(tab or self.selectedTab or "general")
    self.frame:Show()
    self.frame:Raise()
end
