local _, AUI = ...
AUI = ProjectRuthless or AUI

local Menu = {
    tabs = {},
    panels = {},
}
AUI:RegisterModule("Menu", Menu)

local COLORS = AUI.Theme
local function GetAccentColor()
    return AUI:AccentColor()
end
local function ApplyBackdrop(frame, background, border)
    frame:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1 })
    if AUI.isForever then AUI:StyleSurface(frame,"window",background[4],"Options")else frame:SetBackdropColor(unpack(background))end
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
    button:SetScript("OnEnter",function(self) self:SetBackdropColor(0.055,0.060,0.078,AUI.isForever and AUI:BackgroundOpacity("Options")or .96) end); button:SetScript("OnLeave",function(self) self:SetBackdropColor(0.035,0.039,0.052,AUI.isForever and AUI:BackgroundOpacity("Options")or .92) end)
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

function Menu:CreateProfilesPanel(parent)
    local panel=self:CreateOptionsPanel(parent,"PERSONAL SETTINGS","Profiles","Save a setup or share settings. Quest progress and character positions stay on this character.")
    local name=CreateFrame("EditBox",nil,panel,"InputBoxTemplate");name:SetAutoFocus(false);name:SetSize(250,24);name:SetPoint("TOPLEFT",24,-116);name:SetMaxLetters(40);name:SetText("My setup")
    local status=AddLabel(panel,"","TOPLEFT",panel,"TOPLEFT",20,-184,"GameFontNormalSmall");status:SetWidth(590);status:SetJustifyH("LEFT")
    local scroll=AUI:CreateSmoothScrollFrame(panel);scroll:SetPoint("TOPLEFT",18,-220);scroll:SetSize(610,240)
    local edit=CreateFrame("EditBox",nil,scroll);edit:SetMultiLine(true);edit:SetAutoFocus(false);edit:SetFontObject(ChatFontNormal);edit:SetWidth(580);edit:SetTextInsets(8,8,8,8);edit:SetMaxLetters(16384)
    edit:SetScript("OnEscapePressed",function(box)box:ClearFocus()end);scroll:SetScrollChild(edit);AUI:ConfigureScrollingEditBox(edit,scroll,240)
    local profiles=AUI.modules.Profiles
    local function result(ok,message)status:SetText(message);if ok then Menu:Refresh()end end
    self:CreateAction(panel,"Save",18,-152,100,function()result(profiles:Save(name:GetText()))end)
    self:CreateAction(panel,"Load",124,-152,100,function()result(profiles:Load(name:GetText()))end)
    self:CreateAction(panel,"Export",230,-152,100,function()edit:SetText(profiles:Export());edit:SetFocus();edit:HighlightText();status:SetText("Copy these settings to share them.")end)
    self:CreateAction(panel,"Import",336,-152,100,function()result(profiles:Import(edit:GetText()))end)
    self:CreateAction(panel,"Undo import",442,-152,140,function()result(profiles:Restore())end)
    self:CreateAction(panel,"Reload UI",18,-480,140,function()ReloadUI()end)
    self.panels.profiles=panel
end

-- Use Blizzard's registered settings, including its server-toggle cache and callbacks.
function Menu:CreateActionBarOptions(parent)
    local panel=self:CreateOptionsPanel(parent,"HUD SETTINGS","Action bars","Native bar visibility and behavior, presented in RUI. Layout and snapping live in RUI Edit Mode.")
    local scroll=AUI:CreateSmoothScrollFrame(panel);scroll:SetPoint("TOPLEFT",0,-105);scroll:SetSize(650,380)
    local content=CreateFrame("Frame",nil,scroll);content:SetSize(650,620);scroll:SetScrollChild(content)
    local function setting(name)return Settings and Settings.GetSetting and Settings.GetSetting(name)end
    for i=2,8 do
        local variable="PROXY_SHOW_ACTIONBAR_"..i
        self:CreateCheckbox(content,"Action bar "..i,"Show this bar; placement is saved in Edit Mode.",-8-(i-2)*56,
            function()local option=setting(variable);return option and option:GetValue()or false end,
            function(value)if InCombatLockdown()then AUI:Print("Change action bars after combat.");return end;local option=setting(variable);if option then option:SetValue(value)end end)
    end
    for i,row in ipairs({{"lockActionBars","Lock action bars"},{"countdownForCooldowns","Show cooldown numbers"}})do
        local variable,label=row[1],row[2]
        self:CreateCheckbox(content,label,"Uses the game's existing setting.",-400-(i-1)*56,
            function()local option=setting(variable);return option and option:GetValue()or false end,
            function(value)if InCombatLockdown()then return end;local option=setting(variable);if option then option:SetValue(value)end end)
    end
    self:CreateAction(content,"Pickup key: cycle",18,-520,180,function()
        if InCombatLockdown()then return end
        local option=setting("PICKUPACTION");if not option then return end
        local keys={"SHIFT","CTRL","ALT","NONE"};local current=option:GetValue();local nextKey=1
        for i,key in ipairs(keys)do if key==current then nextKey=i%#keys+1;break end end
        option:SetValue(keys[nextKey]);Menu:Refresh()
    end)
    local keyLabel=AddLabel(content,"","TOPLEFT",content,"TOPLEFT",210,-526,"GameFontNormalSmall")
    keyLabel.getter=function()local option=setting("PICKUPACTION");return option and option:GetValue()or "SHIFT"end
    keyLabel.RefreshValue=function(label)label:SetText("Current pickup modifier: "..label.getter())end
    self.optionControls[#self.optionControls+1]=keyLabel
    self:CreateAction(panel,"Edit RUI layout",18,-495,180,function()self.frame:Hide();AUI.modules.LayoutEditor:Show()end)
    self.panels.actionbars=panel
end

function Menu:CreateGeneralPanel(parent)
    local panel=self:CreateOptionsPanel(parent,"CORE SETTINGS","General","Shared presentation settings for every Project Ruthless window.")
    self:CreateSlider(panel,"Window scale","Scale Ruthless windows; Talents also fits within your screen.",-116,0.75,1.25,0.01,function(v)return ("%d%%"):format(math.floor(v*100+0.5))end,function()return ProjectRuthlessDB.general.windowScale end,function(v)ProjectRuthlessDB.general.windowScale=v end,"General")
    self:CreateSlider(panel,"Window opacity","Fade complete Project Ruthless windows without affecting the rest of the UI.",-194,0.65,1,0.05,function(v)return ("%d%%"):format(math.floor(v*100+0.5))end,function()return ProjectRuthlessDB.general.windowOpacity end,function(v)ProjectRuthlessDB.general.windowOpacity=v end,"General")
    local note=AddLabel(panel,"Settings are account-wide. Character-specific state is kept separately where it makes sense.","TOPLEFT",panel,"TOPLEFT",20,-286,"GameFontNormalSmall"); note:SetWidth(590); note:SetJustifyH("LEFT"); note:SetTextColor(unpack(COLORS.muted))
    self:CreateAction(panel,"Edit RUI layout",20,-340,180,function()AUI.modules.LayoutEditor:Show()end)
    if AUI.isForever then self:CreateAction(panel,"Leveling history",208,-340,180,function()AUI.modules.LevelHistory:Show()end)end
    if AUI.isForever then self:CreateCheckbox(panel,"Show Blizzard decorative art","Restore stock borders and trim on RUI-skinned controls. Saved with the active layout profile.",-390,function()return AUI.modules.ForeverStyle:BlizzardArtEnabled()end,function(v)AUI.modules.ForeverStyle:SetBlizzardArt(v)end,"ForeverStyle")end
    if AUI.isForever then self:CreateCheckbox(panel,"Grouped party panel","Off: one compact block per character. On: one shared panel. Move the party together in Edit Mode.",-444,function()return ProjectRuthlessDB.general.partyGrouped==true end,function(v)ProjectRuthlessDB.general.partyGrouped=v end,"ForeverHUD")end
    self.panels.general=panel
end

function Menu:CreateBackgroundOptions(parent)
    local panel=self:CreateOptionsPanel(parent,"HUD SETTINGS","Backgrounds","One charcoal opacity across RUI. Individual overrides affect backgrounds only; text and icons stay clear.")
    local scroll=AUI:CreateSmoothScrollFrame(panel);scroll:SetPoint("TOPLEFT",0,-105);scroll:SetSize(650,395)
    local content=CreateFrame("Frame",nil,scroll);content:SetSize(650,1800);scroll:SetScrollChild(content)
    local percent=function(v)return ("%d%%"):format(math.floor(v*100+.5))end
    self:CreateSlider(content,"Global background opacity","Used by every element unless its override is enabled.",-8,0,1,.01,percent,function()return AUI:BackgroundOpacity()end,function(v)ProjectRuthlessDB.general.backgroundOpacity=v end,"Backgrounds")
    self:CreateAction(content,"Reset all to global",18,-88,180,function()
        for _,group in ipairs(AUI.backgroundGroups)do ProjectRuthlessDB.general["background"..group[1]]=-1 end
        AUI:SettingsChanged("Backgrounds");self:Refresh()
    end)
    for i,group in ipairs(AUI.backgroundGroups)do
        local key,label=group[1],group[2];local field="background"..key;local y=-126-(i-1)*132
        self:CreateCheckbox(content,label.." override","Off follows the global slider.",y,
            function()return type(ProjectRuthlessDB.general[field])=="number"and ProjectRuthlessDB.general[field]>=0 end,
            function(enabled)ProjectRuthlessDB.general[field]=enabled and AUI:BackgroundOpacity(key)or -1;self:Refresh()end,"Backgrounds")
        self:CreateSlider(content,label.." opacity","Moving this slider enables its individual override.",y-52,0,1,.01,percent,
            function()return AUI:BackgroundOpacity(key)end,function(v)ProjectRuthlessDB.general[field]=v end,"Backgrounds")
    end
    content:SetHeight(140+#AUI.backgroundGroups*132);self.panels.backgrounds=panel
end

function Menu:CreateCharacterOptions(parent)
    local panel=self:CreateOptionsPanel(parent,"PLAYER PANEL","Character","Control the standalone Character replacement opened by the normal Character button and keybind.")
    if AUI.isForever then
        local note=AddLabel(panel,"WoW Forever uses its native Character window in this beta build. Open it with Forever's Character button or keybind; launching it from addon code taints protected health values in the current beta.","TOPLEFT",panel,"TOPLEFT",20,-124,"GameFontNormal")
        note:SetWidth(580); note:SetJustifyH("LEFT"); note:SetTextColor(unpack(COLORS.muted))
        self.panels.character=panel
        return
    end
    self:CreateCheckbox(panel,"Enable experimental Character workspace","Use the Ruthless Paper Doll workspace. Blizzard's Character frame is the stable default.",-116,function()return ProjectRuthlessDB.character.replaceBlizzard end,function(v)ProjectRuthlessDB.character.replaceBlizzard=v end,"Character")
    self:CreateCheckbox(panel,"Show item-level badges","Display compact item levels over equipped gear slots.",-172,function()return ProjectRuthlessDB.character.showItemLevels end,function(v)ProjectRuthlessDB.character.showItemLevels=v end,"Character")
    self:CreateCheckbox(panel,"Show progress summary","Display Mythic+, raid, and rated-PvP progress beside the character identity.",-228,function()return ProjectRuthlessDB.character.showProgress end,function(v)ProjectRuthlessDB.character.showProgress=v end,"Character")
    self:CreateAction(panel,"Open Character",18,-300,140,function() if AUI.modules.Character then AUI.modules.Character:Toggle(true) end end)
    self.panels.character=panel
end

function Menu:CreateSpellbookOptions(parent)
    local panel=self:CreateOptionsPanel(parent,"ABILITIES & MACROS","Spellbook","Choose how aggressively Project Ruthless restores the pre-TWW Spellbook workflow.")
    if AUI.isForever then
        self:CreateCheckbox(panel,"Use the Ruthless Spellbook and macros","Open the Ruthless workspace from Forever's dedicated Spellbook button and keybind.",-116,function()return ProjectRuthlessDB.spellbook.separateFromTalents end,function(v)ProjectRuthlessDB.spellbook.separateFromTalents=v end,"Spellbook")
    else
        self:CreateCheckbox(panel,"Replace the Professions book button","Open the Project Ruthless Spellbook from the normal book micro button.",-116,function()return ProjectRuthlessDB.spellbook.replaceProfessions end,function(v)ProjectRuthlessDB.spellbook.replaceProfessions=v end,"Spellbook")
        self:CreateCheckbox(panel,"Remove Spellbook from Talents","Keep Talents focused and route Spellbook requests to the standalone window.",-172,function()return ProjectRuthlessDB.spellbook.separateFromTalents end,function(v)ProjectRuthlessDB.spellbook.separateFromTalents=v end,"Spellbook")
    end
    self:CreateCheckbox(panel,"Show other-specialization spells","Keep unavailable spec abilities visible as dimmed reference entries.",-228,function()return ProjectRuthlessDB.spellbook.showOffSpec end,function(v)ProjectRuthlessDB.spellbook.showOffSpec=v end,"Spellbook")
    self:CreateCheckbox(panel,"Highlight abilities missing from bars","Use Blizzard's missing-action-bar glow on relevant active abilities.",-284,function()return ProjectRuthlessDB.spellbook.highlightMissing end,function(v)ProjectRuthlessDB.spellbook.highlightMissing=v end,"Spellbook")
    self:CreateCheckbox(panel,"Macro autocomplete","Suggest live slash commands, conditionals, and learned spells in the macro editor.",-340,function()return ProjectRuthlessDB.spellbook.macroAutocomplete end,function(v)ProjectRuthlessDB.spellbook.macroAutocomplete=v end,"Spellbook")
    self:CreateCheckbox(panel,"Automatically update macro spell ranks","Upgrade explicit older ranks when you learn a new rank; keep the previous macro in History.",-396,function()return ProjectRuthlessDB.spellbook.autoUpdateRanks end,function(v)ProjectRuthlessDB.spellbook.autoUpdateRanks=v end)
    self:CreateAction(panel,"Open Spellbook",18,-468,140,function() if AUI.modules.Spellbook then AUI.modules.Spellbook:Show("class") end end)
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
    if AUI.isForever then
        local note=AddLabel(panel,"Forever's Camelot talent window uses primary and secondary spec groups instead of Retail's specialization/loadout layout. Project Ruthless leaves that native window intact; open it with Forever's Talents button or keybind.","TOPLEFT",panel,"TOPLEFT",20,-124,"GameFontNormal")
        note:SetWidth(580); note:SetJustifyH("LEFT"); note:SetTextColor(unpack(COLORS.muted))
        self.panels.talents=panel
        return
    end
    self:CreateCheckbox(panel,"Use compact Talents","Use the Ruthless layout on the normal Talents button and keybind.",-116,function()return ProjectRuthlessDB.talents.enabled end,function(v)ProjectRuthlessDB.talents.enabled=v end,"Talents")
    self:CreateAction(panel,"Open Talents",18,-184,140,function() if AUI.modules.Talents then AUI.modules.Talents:Show() end end)
    local note=AddLabel(panel,"Save copy names a copy of your current build. Manage opens rename, delete, and action-bar options. Changes made during combat apply after combat ends.","TOPLEFT",panel,"TOPLEFT",20,-232,"GameFontNormalSmall")
    note:SetWidth(580); note:SetJustifyH("LEFT"); note:SetTextColor(unpack(COLORS.muted))
    self.panels.talents=panel
end

function Menu:CreateAchievementsOptions(parent)
    local panel=self:CreateOptionsPanel(parent,"ACHIEVEMENTS & STATISTICS","Achievements","Turn Blizzard's Statistics tab into a useful overview of your character and account progress.")
    if AUI.isForever then
        local note=AddLabel(panel,"Blizzard's Achievement UI is not exposed as a Camelot addon in the current Forever beta. The Ruthless Statistics dashboard stays disabled instead of trying to load a Retail-only frame.","TOPLEFT",panel,"TOPLEFT",20,-124,"GameFontNormal")
        note:SetWidth(580); note:SetJustifyH("LEFT"); note:SetTextColor(unpack(COLORS.muted))
        self.panels.achievements=panel
        return
    end
    self:CreateCheckbox(panel,"Use the Statistics dashboard","Open Statistics on the Ruthless overview while retaining every Blizzard detail category.",-116,function()return ProjectRuthlessDB.achievements.enabled end,function(v)ProjectRuthlessDB.achievements.enabled=v end,"Achievements")
    self:CreateAction(panel,"Open Statistics",18,-184,140,function() if AUI.modules.Achievements then AUI.modules.Achievements:Show() end end)
    local note=AddLabel(panel,"The dashboard uses Blizzard's live achievement, title, and statistics records. Browse details returns to the complete native category list.","TOPLEFT",panel,"TOPLEFT",20,-232,"GameFontNormalSmall")
    note:SetWidth(580); note:SetJustifyH("LEFT"); note:SetTextColor(unpack(COLORS.muted))
    self.panels.achievements=panel
end

function Menu:CreateMapQuestOptions(parent)
    local panel=self:CreateOptionsPanel(parent,"WORLD NAVIGATION","Map & quests","Show the complete quest picture that WoW Forever provides to the main map.")
    self:CreateCheckbox(panel,"Show quest markers","Enable the lightweight native quest-map layer.",-116,function()return ProjectRuthlessDB.mapQuests.enabled end,function(v)ProjectRuthlessDB.mapQuests.enabled=v end,"MapQuests")
    self:CreateCheckbox(panel,"Show local stories","Include optional side-story quest lines that Forever normally hides behind a map filter.",-172,function()return ProjectRuthlessDB.mapQuests.showLocalStories end,function(v)ProjectRuthlessDB.mapQuests.showLocalStories=v end,"MapQuests")
    self:CreateCheckbox(panel,"Show low-level quests","Include trivial quests below your current level.",-228,function()return ProjectRuthlessDB.mapQuests.showTrivial end,function(v)ProjectRuthlessDB.mapQuests.showTrivial=v end,"MapQuests")
    self:CreateCheckbox(panel,"Show account-completed quests","Include quest starts already completed by another character on the account.",-284,function()return ProjectRuthlessDB.mapQuests.showAccountCompleted end,function(v)ProjectRuthlessDB.mapQuests.showAccountCompleted=v end,"MapQuests")
    self:CreateCheckbox(panel,"Compact quest workspace (preview)","One nearby-sorted quest list with navigation at the top. Replaces the Blizzard tracker while enabled.",-340,function()return ProjectRuthlessDB.questWorkspace.enabled end,function(v)ProjectRuthlessDB.questWorkspace.enabled=v end,"QuestWorkspace")
    local note=AddLabel(panel,"Native quest pins and blue objective areas follow Show quest markers. Original RUI hub guides through level 30 are available in Map > Library.","TOPLEFT",panel,"TOPLEFT",20,-408,"GameFontNormalSmall")
    note:SetWidth(590); note:SetJustifyH("LEFT"); note:SetTextColor(unpack(COLORS.muted))
    local guideButton
    guideButton=self:CreateAction(panel,"Guide source",20,-455,260,function()
        local workspace=AUI.modules.QuestWorkspace;workspace:CycleGuideSource();guideButton:SetText("Guide: "..workspace:GuideSourceLabel())
    end)
    guideButton:SetText("Guide: "..AUI.modules.QuestWorkspace:GuideSourceLabel())
    self.panels.mapquests=panel
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
    panel.dependencies=AddLabel(panel,"","TOPLEFT",panel,"TOPLEFT",18,-220);panel.dependencies:SetWidth(580);panel.dependencies:SetJustifyH("LEFT")

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
    index=#self.tabs+1
    local r, g, b = GetAccentColor()
    local tab = CreateFrame("Button", self.frame:GetName() .. "Tab" .. index, self.sidebar)
    tab:SetID(index)
    tab:SetSize(184, 36)
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
    tab.searchText=(text.." "..id):lower()
end

function Menu:FilterTabs(query)
    query=(query or ""):lower()
    local aliases={backgrounds="charcoal opacity transparency global individual shadows",general="scale opacity",profiles="save load import export undo",mapquests="guide dungeon quest tracker arrow waypoint supplies preparation handin",errors="diagnostics lag cpu errors",spellbook="macro ranks professions spells",health="glow warning threshold"}
    local index=0
    for _,tab in ipairs(self.tabs)do
        local text=tab.searchText.." "..(aliases[tab.panelID]or "")
        local matches=true
        for word in query:gmatch("%S+")do if not text:find(word,1,true)then matches=false;break end end
        tab:SetShown(matches)
        if matches then tab:ClearAllPoints();tab:SetPoint("TOPLEFT",self.sidebar,"TOPLEFT",12,-90-index*40);index=index+1 end
    end
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
    header:SetScript("OnDragStart", function()frame:StartMoving()end)
    header:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local point,_,relativePoint,x,y=frame:GetPoint()
        ProjectRuthlessCharDB.menuPosition={point=point,relativePoint=relativePoint,x=x,y=y}
    end)
    local saved=ProjectRuthlessCharDB.menuPosition
    if saved then frame:ClearAllPoints();frame:SetPoint(saved.point,UIParent,saved.relativePoint,saved.x,saved.y)end
    ApplyBackdrop(header, COLORS.surface, {0,0,0,0})
    local line = header:CreateTexture(nil,"ARTWORK"); line:SetColorTexture(r,g,b,1); line:SetPoint("BOTTOMLEFT"); line:SetPoint("BOTTOMRIGHT"); line:SetHeight(2)
    local mark = AddLabel(header,"RUI","LEFT",header,"LEFT",18,0,"GameFontNormalHuge"); mark:SetTextColor(r,g,b,1)
    AddLabel(header,"RUTHLESS UI","LEFT",mark,"RIGHT",16,0,"GameFontNormalLarge")
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
    if UISpecialFrames then
        local registered=false
        for _,name in ipairs(UISpecialFrames)do if name=="ProjectRuthlessMenuFrame"then registered=true;break end end
        if not registered then UISpecialFrames[#UISpecialFrames+1]="ProjectRuthlessMenuFrame"end
    end
    self.sidebar = sidebar
    self.content = content
    self.optionControls = {}
    local search=CreateFrame("EditBox",nil,sidebar,"InputBoxTemplate");search:SetAutoFocus(false);search:SetMaxLetters(80);search:SetSize(174,24);search:SetPoint("TOPLEFT",20,-18)
    search:SetScript("OnEscapePressed",function(box)box:SetText("");box:ClearFocus()end)
    search:SetScript("OnTextChanged",function(box)self:FilterTabs(box:GetText())end)
    self.search=search
    self.pageBuilders={profiles="CreateProfilesPanel",general="CreateGeneralPanel",character="CreateCharacterOptions",spellbook="CreateSpellbookOptions",talents="CreateTalentsOptions",achievements="CreateAchievementsOptions",mapquests="CreateMapQuestOptions",health="CreateHealthOptions",compatibility="CreateCompatibilityOptions",errors="CreateErrorsPanel",status="CreateStatusPanel"}
    if AUI.isForever then
        self.pageBuilders.character=nil
        self.pageBuilders.achievements=nil
        self.pageBuilders.actionbars="CreateActionBarOptions"
        self.pageBuilders.backgrounds="CreateBackgroundOptions"
    end
    self:CreateTab("general", "General", 1)
    if AUI.isForever then self:CreateTab("actionbars", "Action bars", 2)end
    if not AUI.isForever then self:CreateTab("character", "Character", 2)end
    self:CreateTab("spellbook", "Spellbook", 3)
    self:CreateTab("talents", "Talents", 4)
    if not AUI.isForever then self:CreateTab("achievements", "Achievements", 5)end
    self:CreateTab("mapquests", "Map & quests", 6)
    self:CreateTab("health", "Health warning", 7)
    self:CreateTab("compatibility", "Compatibility", 8)
    self:CreateTab("errors", "Diagnostics", 9)
    self:CreateTab("status", "About", 10)
    self:CreateTab("profiles", "Profiles", 11)
    if AUI.isForever then self:CreateTab("backgrounds","Backgrounds",12)end
    self:FilterTabs("")
    AUI:ApplyWindowSettings()
end

function Menu:Refresh()
    if not self.frame then
        return
    end

    if self.selectedTab=="status" then
        local E=AUI:GetElvUI()
        local _,errorCount=AUI.modules.ErrorLog:GetFormattedText()
        local panel=self.panels.status
        panel.versionLabel:SetText("RUI version: "..tostring(AUI.version))
        local lines={"OPTIONAL DATA & GUIDES"}
        local function state(label,available,missing)lines[#lines+1]=label..": "..(available and "Ready" or missing)end
        state("Quest locations",LibQuestieDB~=nil,"Install/enable QuestieDB")
        state("Leveling guide",ForeverWispFrame~=nil,"Install/enable ForeverWisp")
        state("Dungeon loot",AtlasLoot~=nil,"Install/enable AtlasLootClassic")
        state("Waypoint provider",TomTom~=nil,"Native navigation available")
        panel.dependencies:SetText(table.concat(lines,"\n"))
        panel.elvLabel:SetText("ElvUI detected: "..tostring(E and E.version or "not loaded"))
        panel.tooltipLabel:SetText("Safe tooltip compatibility: "..(ProjectRuthlessDB.elvui.safeTooltip and "Enabled"or "Disabled"))
        panel.errorLabel:SetText(("Captured Lua errors: %d"):format(errorCount))
    elseif self.selectedTab=="errors" then
        local errorText=AUI.modules.ErrorLog:GetFormattedText()
        self.panels.errors.editBox:SetText(errorText);self.panels.errors.editBox:SetCursorPosition(0)
    end
    self.refreshing=true
    for _,control in ipairs(self.optionControls or {}) do if control.RefreshValue and control:IsVisible() then control:RefreshValue() end end
    self.refreshing=false
end

function Menu:SelectTab(id)
    self:Create()
    if not self.pageBuilders[id]then id="general"end
    if not self.panels[id]then self[self.pageBuilders[id]](self,self.content)end

    for _, tab in ipairs(self.tabs) do
        local selected = tab.panelID == id
        if self.panels[tab.panelID]then self.panels[tab.panelID]:SetShown(selected)end
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
