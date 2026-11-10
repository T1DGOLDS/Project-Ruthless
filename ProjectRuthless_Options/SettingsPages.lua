-- Forever settings presentation. Stored keys and feature implementations stay
-- with their owners; these pages only organise and label the existing controls.
local _,AUI=...
AUI=ProjectRuthless or AUI
local Menu=AUI.modules.Menu
function Menu:LiveSettings(section,character)
 return setmetatable({},{__index=function(_,key)
  local db=character and ProjectRuthlessCharDB or ProjectRuthlessDB
  return db[section]and db[section][key]
 end,__newindex=function(_,key,value)
  local db=character and ProjectRuthlessCharDB or ProjectRuthlessDB
  db[section]=db[section]or {};db[section][key]=value
 end})
end
local function text(parent,value,y,font)
 local label=parent:CreateFontString(nil,"OVERLAY",font or "GameFontNormalSmall")
 label:SetPoint("TOPLEFT",18,y);label:SetWidth(600);label:SetJustifyH("LEFT");label:SetText(value)
 if font then local r,g,b=AUI:AccentColor();label:SetTextColor(r,g,b,1)else label:SetTextColor(.68,.71,.77,1)end
 if AUI.modules.Accessibility then AUI.modules.Accessibility:RegisterText(label)end
 return label
end
function Menu:CreateFlowPage(parent,id,title,description)
 local panel=self:CreateOptionsPanel(parent,"RUI SETTINGS",title,description)
 local scroll=AUI:CreateSmoothScrollFrame(panel);scroll:SetPoint("TOPLEFT",0,-112);scroll:SetPoint("BOTTOMRIGHT",0,8)
 local content=CreateFrame("Frame",nil,scroll);content:SetSize(650,400);scroll:SetScrollChild(content)
 local flow={panel=panel,content=content,scroll=scroll,y=-8,rows={},blocks={}};panel.flow=flow
 function flow:Space(height)local size=height or 12;self.blocks[#self.blocks+1]={kind="space",height=size};self.y=self.y-size end
 function flow:Note(value,font,padding)
  local copy=text(content,value,self.y,font);local pad=padding or 10
  self.blocks[#self.blocks+1]={kind="text",control=copy,padding=pad}
  self.y=self.y-math.max(16,copy:GetStringHeight()or 16)-pad;return copy
 end
 function flow:Section(title,description)
  if #self.rows>0 then self:Space(14)end
  self:Note(title,"GameFontNormal",10)
  if description then self:Note(description,nil,10)end
 end
 function flow:Add(control,minimum)
  local height=minimum or control:GetHeight()
  if control.description and type(control.description)~="function"then
   control.label:SetWidth(control.ruiSlider and 470 or 550)
   control.description:SetWidth(control.box and 556 or 586)
   local labelHeight=math.max(16,control.label:GetStringHeight()or 16)
   control.description:ClearAllPoints();control.description:SetPoint("TOPLEFT",control, "TOPLEFT",control.box and 42 or 12,-labelHeight-12)
   height=math.max(height,labelHeight+(control.description:GetStringHeight()or 16)+(control.ruiSlider and 40 or 26))
  end
  control:SetHeight(height);local row={kind="control",control=control,y=self.y,height=height,minimum=minimum or height};self.rows[#self.rows+1]=row;self.blocks[#self.blocks+1]=row
  self.y=self.y-height-8;content:SetHeight(math.max(400,-self.y+16));return control
 end
 function flow:Check(label,description,getter,setter,section,key)
  return self:Add(Menu:CreateCheckbox(content,label,description,self.y,getter,setter,section,key),60)
 end
 function flow:Slider(label,description,min,max,step,format,getter,setter,section,key)
  return self:Add(Menu:CreateSlider(content,label,description,self.y,min,max,step,format,getter,setter,section,key),82)
 end
 function flow:Action(label,callback,description)
  local button=self:Add(Menu:CreateAction(content,label,18,self.y,610,callback),32)
  if button.label and type(button.label)~="function"then button.label:SetWidth(590)end
  if description then self:Note(description,nil,12);content:SetHeight(math.max(400,-self.y+16))end
  return button
 end
 function flow:Choice(label,description,choices,getter,setter,section,key)
  local button=self:Action(label,function(anchor)
   if not MenuUtil or not MenuUtil.CreateContextMenu then AUI:Print("The selection menu is unavailable. Try again after reloading.");return end
   MenuUtil.CreateContextMenu(anchor,function(_,root)
    root:CreateTitle(label)
    for _,entry in ipairs(choices)do local choice=entry
     root:CreateRadio(choice[2],function()return getter()==choice[1]end,function()setter(choice[1]);if section then AUI:SettingsChanged(section,key)end;Menu:Refresh()end)
    end
   end)
  end,description)
  button.RefreshValue=function(b)
   local value=getter();local caption=tostring(value)
   for _,choice in ipairs(choices)do if choice[1]==value then caption=choice[2];break end end
   b:SetText(label..": "..caption.."  v")
  end
  Menu.optionControls[#Menu.optionControls+1]=button
  local registry=AUI.modules.SettingsRegistry
  if registry then registry:Register(Menu.buildingPage,button,label,description,self.y,"choice",section,key)end
  return button
 end
 function flow:Pair(left,right)
  self.blocks[#self.blocks+1]={kind="pair",left=left,right=right};self.y=self.y-48
 end
 function flow:Children(holder,children)
  for _,block in ipairs(self.rows)do if block.control==holder then
   block.children=children
   local registry=AUI.modules.SettingsRegistry
   for _,child in ipairs(children)do local row=registry and registry.byControl and registry.byControl[child[1]];if row then row.y=block.y+child[2]end end
   return
  end end
 end
 function flow:Reflow()
  local description=panel.ruiDescription
  local descriptionTop=76
  if panel.ruiTitle and type(panel.ruiTitle)~="function"then
   local titleTop=math.max(44,18+(panel.ruiEyebrow:GetStringHeight()or 12)+10)
   panel.ruiTitle:ClearAllPoints();panel.ruiTitle:SetPoint("TOPLEFT",18,-titleTop);panel.ruiTitle:SetWidth(610)
   descriptionTop=titleTop+(panel.ruiTitle:GetStringHeight()or 24)+12
   description:ClearAllPoints();description:SetPoint("TOPLEFT",18,-descriptionTop)
  end
  local top=description and type(description)~="function"and math.max(112,descriptionTop+(description:GetStringHeight()or 16)+16)or 112
  scroll:ClearAllPoints();scroll:SetPoint("TOPLEFT",0,-top);scroll:SetPoint("BOTTOMRIGHT",0,8)
  local y=-8
  for _,block in ipairs(self.blocks)do
   if block.kind=="space"then y=y-block.height
   elseif block.kind=="text"then
    block.control:ClearAllPoints();block.control:SetPoint("TOPLEFT",18,y)
    y=y-math.max(16,block.control:GetStringHeight()or 16)-block.padding
   elseif block.kind=="pair"then
    local height=36
    for i,control in ipairs({block.left,block.right})do
     if control.label and type(control.label)~="function"then height=math.max(height,(control.label:GetStringHeight()or 16)+12)end
     control:ClearAllPoints();control:SetPoint("TOPLEFT",i==1 and 18 or 418,y)
     local registry=AUI.modules.SettingsRegistry;local row=registry and registry.byControl and registry.byControl[control];if row then row.y=y end
    end
    block.left:SetHeight(height);block.right:SetHeight(height);y=y-height-10
   else
    local control=block.control;local height=block.minimum
    if control.description and type(control.description)~="function"then
     local labelHeight=math.max(16,control.label:GetStringHeight()or 16)
     control.description:ClearAllPoints();control.description:SetPoint("TOPLEFT",control,"TOPLEFT",control.box and 42 or 12,-labelHeight-12)
     height=math.max(height,labelHeight+(control.description:GetStringHeight()or 16)+(control.ruiSlider and 40 or 26))
    elseif control.label and type(control.label)~="function"then height=math.max(height,(control.label:GetStringHeight()or 16)+12)
    end
    control:ClearAllPoints();control:SetPoint("TOPLEFT",18,y);control:SetHeight(height);block.y=y;block.height=height
    local registry=AUI.modules.SettingsRegistry
    local row=registry and registry.byControl and registry.byControl[control];if row then row.y=y end
    for _,child in ipairs(block.children or {})do local entry=registry and registry.byControl and registry.byControl[child[1]];if entry then entry.y=y+child[2]end end
    y=y-height-8
   end
  end
  self.y=y;content:SetHeight(math.max(400,-y+16))
 end
 panel:HookScript("OnShow",function()flow:Reflow()end)
 self.panels[id]=panel;return flow
end
function Menu:ReflowPages()
 for _,panel in pairs(self.panels or {})do if panel.flow then panel.flow:Reflow()end end
 if self.frame and self.navigation then self:FilterTabs(self.search and self.search:GetText()or "")end
end
local function percent(v)return ("%d%%"):format(math.floor(v*100+.5))end
local function layout()Menu.frame:Hide();AUI.modules.LayoutEditor:Show()end
local function backgrounds()Menu:SelectTab("backgrounds")end
local function override(name,fn)
 local old=Menu[name]
 Menu[name]=function(self,...)if AUI.isForever then return fn(self,...)end;return old(self,...)end
end
override("CreateGeneralPanel",function(self,parent)
 local f=self:CreateFlowPage(parent,"general","Appearance","Global presentation, backgrounds and decorative art. Positions and sizes are saved in Edit Mode.")
 f:Section("Windows")
 f:Slider("Window scale","Resize RUI windows without changing your saved layout.",.75,1.25,.01,percent,function()return ProjectRuthlessDB.general.windowScale end,function(v)ProjectRuthlessDB.general.windowScale=v end,"General","windowScale")
 f:Slider("Window opacity","Fades window text and icons too. Use Backgrounds to change only the charcoal surface.",.65,1,.05,percent,function()return ProjectRuthlessDB.general.windowOpacity end,function(v)ProjectRuthlessDB.general.windowOpacity=v end,"General","windowOpacity")
 f:Section("Backgrounds & art")
 f:Action("Background colours & opacity",backgrounds,"One global style with optional overrides for individual frames.")
 f:Check("Show Blizzard decorative art","Restore stock decorative borders and trim. Off keeps the clean RUI appearance.",function()return AUI.modules.ForeverStyle:BlizzardArtEnabled()end,function(v)AUI.modules.ForeverStyle:SetBlizzardArt(v)end)
 f:Section("Related controls")
 f:Action("Edit layout",layout)
 f:Action("Text size, contrast & motion",function()self:SelectTab("accessibility")end)
end)
override("CreateBackgroundOptions",function(self,parent)
 local f=self:CreateFlowPage(parent,"backgrounds","Backgrounds","Global colour and opacity, followed by optional per-element overrides. These controls leave text, icons and health fills clear.")
 local s=self:LiveSettings("general")
 f:Action("Back to Appearance",function()self:SelectTab("general")end)
 f:Section("Global background style")
 f:Slider("Global background opacity","Used by every element unless its individual override is enabled.",0,1,.01,percent,function()return AUI:BackgroundOpacity()end,function(v)s.backgroundOpacity=v end,"Backgrounds")
 local left,right=self:CreateBackgroundColour(f.content,"Global",nil,f.y);f:Pair(left,right)
 f:Action("Reset all to global",function()
  for _,group in ipairs(AUI.backgroundGroups)do s["background"..group[1]]=-1;s["customColor"..group[1]]=nil end
  AUI:SettingsChanged("Backgrounds");self:Refresh()
 end,"Reset individual colour and opacity overrides while keeping the global style.")
 if (ProjectRuthlessDB.accessibility or {}).highContrast then f:Section("High contrast is on","Accessibility enforces dark backgrounds at 90% opacity or above. Your ordinary colour and opacity preferences are retained.")end
 for _,group in ipairs(AUI.backgroundGroups)do
  local key,label=group[1],group[2];local field="background"..key
  f:Section(label)
  f:Check(label.." override","Off inherits global opacity. Colour can be reset independently below.",function()return type(s[field])=="number"and s[field]>=0 end,function(v)s[field]=v and AUI:BackgroundOpacity(key)or -1 end,"Backgrounds",key)
  f:Slider(label.." opacity","Moving this slider enables the individual opacity override.",0,1,.01,percent,function()return AUI:BackgroundOpacity(key)end,function(v)s[field]=v end,"Backgrounds",key)
  left,right=self:CreateBackgroundColour(f.content,label,key,f.y);f:Pair(left,right)
 end
 f.content:SetHeight(-f.y+18)
end)
override("CreateUnitFrameOptions",function(self,parent)
 local f=self:CreateFlowPage(parent,"unitframes","Unit frames","Player, target, pet and party presentation. Your current layout and profile are preserved.")
 f:Section("Party frames")
 f:Check("Shared party background","On uses one panel; off gives each character a compact block. The party still moves together.",function()return ProjectRuthlessDB.general.partyGrouped==true end,function(v)ProjectRuthlessDB.general.partyGrouped=v end,"ForeverHUD","partyGrouped")
 f:Section("Position & appearance")
 f:Action("Move or resize unit frames",layout)
 f:Action("Unit-frame backgrounds",backgrounds)
 f:Action("Party buffs, debuffs & dispel emphasis",function()self:SelectTab("auras")end)
 f:Action("Portrait animation & reduced motion",function()self:SelectTab("accessibility")end)
end)
override("CreateBagOptions",function(self,parent)
 local f=self:CreateFlowPage(parent,"bags","Bags & inventory","Backpack layout and sorting. Item search, bag assignments and item actions use the normal bag controls.")
 f:Section("Backpack")
 f:Check("Auto-sort bags when opened","Sort with the game's normal rules when the backpack opens. Sorting waits until combat ends.",function()return AUI.modules.ForeverStyle:BagSettings().autoSort==true end,function(v)AUI.modules.ForeverStyle:BagSettings().autoSort=v end,"ForeverStyle","autoSort")
 f:Choice("Backpack columns","Choose how many item slots fit across each row.",{{8,"8 columns"},{10,"10 columns"},{12,"12 columns"}},function()return AUI.modules.ForeverStyle:BagSettings().columns or 10 end,function(v)AUI.modules.ForeverStyle:BagSettings().columns=v end,"ForeverStyle","columns")
 f:Action("Move backpack",layout,"You can also drag the backpack header; its position is saved with your layout.")
 f:Action("Backpack background",backgrounds)
end)
override("CreateChatOptions",function(self,parent)
 local f=self:CreateFlowPage(parent,"chat","Chat","Right-click a chat tab to choose messages, channels, font size and docking. Complete RUI profiles include these chat choices.")
 f:Section("Layout & appearance")
 f:Action("Move chat dock",layout)
 f:Action("Chat background colour & opacity",backgrounds)
 f:Section("Saved setup")
 f:Action("Save or load chat with a profile",function()self:SelectTab("profiles")end)
end)
override("CreateProfilesPanel",function(self,parent)
 local f=self:CreateFlowPage(parent,"profiles","Profiles","Save or apply one complete setup: settings, layout and chat. Quest progress stays with each character.")
 local profiles=AUI.modules.UnifiedProfiles or AUI.modules.Profiles
 local status=f:Note("Choose a saved profile or enter a name. Loading changes your current setup; Undo apply restores it.")
 local function result(ok,message)status:SetText(message or (ok and "Saved."or "No changes applied."));self:Refresh();if f.scroll.ScrollTo then f.scroll:ScrollTo(0,true)end end
 f:Section("Save & load")
 f:Note("Profile name")
 local name=CreateFrame("EditBox",nil,f.content,"InputBoxTemplate");name:SetSize(600,30);name:SetPoint("TOPLEFT",18,f.y);name:SetAutoFocus(false);name:SetMaxLetters(64);name:SetText(ProjectRuthlessCharDB.activeProfile or "My setup")
 AUI.modules.SettingsRegistry:Register("profiles",name,"Profile name","Name to save or load an account profile",f.y,"text")
 name:SetScript("OnEscapePressed",function(box)box:ClearFocus()end);f:Add(name,30)
 f:Action("Choose saved profile",function(anchor)
  if profiles.Menu then profiles:Menu(anchor,function(key)name:SetText(key);status:SetText("Selected "..key..". Choose Load to apply it.");f:Reflow()end)end
 end)
 f:Action("Save current setup",function()result(profiles:Save(name:GetText()))end)
 f:Action("Load selected profile",function()result(profiles:Load(name:GetText()))end)
 f:Action("Undo apply",function()result(profiles:Restore())end)
 if profiles.SetDefault then
  f:Section("New characters","Choose an account profile to apply when a new character first logs in. Existing characters keep their current setup.")
  local default=f:Action("New-character default",function(anchor)profiles:Menu(anchor,function()self:Refresh()end,true)end)
  default.RefreshValue=function(button)button:SetText("New-character default: "..(profiles:Store().default or "None"))end
  self.optionControls[#self.optionControls+1]=default
 end
 f:Section("Share or transfer a setup")
 local holder=CreateFrame("Frame",nil,f.content);holder:SetSize(610,190);f:Add(holder,190)
 local scroll=AUI:CreateSmoothScrollFrame(holder);scroll:SetAllPoints()
 local edit=CreateFrame("EditBox",nil,scroll);edit:SetMultiLine(true);edit:SetAutoFocus(false);edit:SetFontObject(ChatFontNormal);edit:SetWidth(580);edit:SetTextInsets(8,8,8,8);edit:SetMaxLetters(AUI.modules.UnifiedProfiles and 262144 or 16384)
 edit:SetScript("OnEscapePressed",function(box)box:ClearFocus()end);scroll:SetScrollChild(edit);AUI:ConfigureScrollingEditBox(edit,scroll,190)
 AUI.modules.SettingsRegistry:Register("profiles",edit,"Profile import / export text","Paste a shared setup or copy an exported setup",f.rows[#f.rows].y,"text")
 f:Children(holder,{{edit,0}})
 f:Action("Export current setup",function()edit:SetText(profiles:Export());edit:SetFocus();edit:HighlightText();status:SetText("Copy the text to share your current setup.");f:Reflow()end)
 f:Action("Import pasted setup",function()result(profiles:Import(edit:GetText()))end)
 f:Section("Recovery & setup")
 if profiles.RecoverSaved then f:Action("Recover overwritten save",function()result(profiles:RecoverSaved())end)end
 f:Action("Run quick setup",function()self:SelectTab("setup")end)
 f:Action("Reload UI",function()ReloadUI()end)
end)
override("CreateAccessibilityOptions",function(self,parent)
 local f=self:CreateFlowPage(parent,"accessibility","Accessibility","Readability and motion controls, with direct access to the game's accessibility options.")
 local access=AUI.modules.Accessibility;local registry=AUI.modules.SettingsRegistry
 f:Section("Readability & motion")
 for _,definition in ipairs(registry.definitions)do if definition.page=="accessibility"then local d=definition
  f:Check(d.label,d.description,function()
   if d.key=="animatedPortraits"then return (ProjectRuthlessDB.accessibility or {}).animatedPortraits~=false end
   if d.key=="reducedMotion"then return access:ReducedMotion()end
   return registry:Get(d)==true
  end,function(v)registry:Set(d,v)end)
 end end
 f:Slider("RUI text size","Enlarge RUI text. Long descriptions wrap; the game controls the size of native HUD text.",1,1.5,.05,percent,function()return access:TextScale()end,function(v)ProjectRuthlessDB.accessibility.textScale=v end,"Accessibility","textScale")
 f:Section("Game accessibility","These open Blizzard's own options. They are not copied into RUI profiles.")
 for _,row in ipairs({
  {"Native accessibility: general",function()return ACCESSIBILITY_GENERAL_LABEL end},
  {"Native accessibility: interface text",function()return ACCESSIBILITY_INTERFACE_LABEL end},
  {"Native colourblind options",function()return Settings and Settings.GetColorblindSettingsLabel and Settings.GetColorblindSettingsLabel()end},
  {"Native audio assist",function()return ACCESSIBILITY_AUDIO_LABEL end},
  {"Native subtitles",function()return CINEMATIC_SUBTITLES_OPTIONS_HEADER end},
 })do local d=row;f:Action(d[1],function()access:OpenNativeCategory(d[2]())end)end
 f:Section("Keyboard navigation","Tab selects controls; Enter activates them. Arrow keys adjust sliders; Page Up and Page Down change sections. Text fields keep normal editing keys.")
end)
override("CreateSetupOptions",function(self,parent)
 local f=self:CreateFlowPage(parent,"setup","Quick setup","Choose a few starting preferences. Saved positions remain intact. Changes apply only when you finish setup.")
 local access=AUI.modules.Accessibility
 local options={animatedPortraits=access:AnimatedPortraits(),reducedMotion=access:ReducedMotion(),highContrast=(ProjectRuthlessDB.accessibility or {}).highContrast==true,largeText=access:TextScale()>1}
 for _,row in ipairs({{"animatedPortraits","Animated portraits","Use live character portraits. Reduced motion uses static portraits."},{"reducedMotion","Reduced motion","Use immediate scrolling, static portraits and steady indicators."},{"largeText","Larger RUI text","Start with text at 125%. You can fine-tune it under Accessibility."},{"highContrast","High-contrast backgrounds","Darken backgrounds while keeping text and icons clear."}})do local d=row
  f:Check(d[2],d[3],function()return options[d[1]]end,function(v)options[d[1]]=v end)
 end
 local status=f:Note("",nil,28)
 f:Action("Finish setup",function()local ok,message=AUI.modules.FirstRun:Finish(options);status:SetText(message);if ok then self:SelectTab("general")end end)
 f:Action("Keep current choices",function()ProjectRuthlessCharDB.firstRun=ProjectRuthlessCharDB.firstRun or {};ProjectRuthlessCharDB.firstRun.complete=true;self:SelectTab("general")end)
 f:Action("Choose an account profile",function()self:SelectTab("profiles")end)
end)
override("CreateMapQuestOptions",function(self,parent)
 local f=self:CreateFlowPage(parent,"mapquests","Map & quests","Map filters, the side tracker and quest interaction. Browse quests, guides, progression and supplies in the main map.")
 local s=self:LiveSettings("mapQuests");local q=self:LiveSettings("questWorkspace")
 local function icon(key,label,description,getter)
  f:Check(label,description,getter or function()return s[key]~=false end,function(v)s[key]=v end,"MapQuests",key)
 end
 f:Section("Quest markers")
 icon("enabled","Show quest markers","Show native quest areas and eligible pickup markers from recorded quest-giver locations.")
 icon("showLocalStories","Show local stories","Include optional side-story quest lines supplied by the game.")
 icon("showTrivial","Show low-level quests","Include quests below your current level.")
 icon("showAccountCompleted","Show account-completed quests","Include pickups completed by another character, while excluding quests this character has completed.")
 f:Section("Travel & gathering icons")
 icon("squareMinimap","Square minimap","Use a square map with a thin RUI border. Native quest areas, tracking icons, zoom and controls remain available.")
 icon("showSpiritHealers","Spirit healer locations","Show recorded Forever healers and the game's current release destination on the world map.")
 icon("showSpiritCoverage","Estimated healer areas","Optional nearest-recorded-healer outlines. These are estimates, not guaranteed death-release boundaries; hover a healer to isolate its area.",function()return s.showSpiritCoverage==true end)
 icon("flightTimer","Flight timer","Show estimated time remaining, then learn your completed flights. Drag the timer or move it in Edit Mode. Unknown routes show elapsed time.")
 icon("showSkyborne","Skyborne racial markers","Show ley lines or elemental convergences for your Skyborne faction.")
 icon("showFlights","Flight points","Show flight-point markers supplied by the game.")
 icon("showInstances","Instance entrances","Show dungeon and raid entrances.")
 icon("trackHerbs","Herb nodes on minimap","Enable Find Herbs when your character has learned it.",function()return AUI.modules.MapQuests:GatherTracking("trackHerbs")end)
 icon("trackOre","Mining nodes on minimap","Enable Find Minerals when your character has learned it.",function()return AUI.modules.MapQuests:GatherTracking("trackOre")end)
 f:Section("Side tracker & navigation")
 f:Check("Show RUI quest tracker","Use the RUI side tracker for the current objective and active quests.",function()return q.enabled end,function(v)q.enabled=v end,"QuestWorkspace","enabled")
 f:Check("Show direction arrow","Point towards the selected objective when its location is known.",function()return q.showArrow~=false end,function(v)q.showArrow=v end,"QuestWorkspace","showArrow")
 f:Check("Lock tracker position","Turn off to drag the tracker header. Edit Mode remains available for precise placement.",function()return q.locked==true end,function(v)q.locked=v end,"QuestWorkspace","locked")
 f:Action("Move quest tracker or map",layout)
 f:Action("Tracker and map backgrounds",backgrounds)
 f:Section("Quest interaction")
 f:Check("Auto-accept quests","Accept standard offers. Hold Shift to handle dialogue manually.",function()return q.autoAccept end,function(v)q.autoAccept=v end,"QuestWorkspace","autoAccept")
 f:Check("Auto hand-in","Turn in completed quests. Multiple reward choices stay manual. Hold Shift to pause.",function()return q.autoHandIn end,function(v)q.autoHandIn=v end,"QuestWorkspace","autoHandIn")
 f:Section("Guide source")
 f:Check("Always suggest Westfall supplies","On keeps Westfall reminders available. Off uses the normal level-based suggestions; other zones are chosen in Map > Supplies.",function()return q.prepWestfall==true end,function(v)q.prepWestfall=v end,"QuestWorkspace","prepWestfall")
 local workspace=AUI.modules.QuestWorkspace;local choices={}
 for _,source in ipairs(workspace:GuideSources())do choices[#choices+1]={source.id,source.label or source.name or source.id}end
 f:Choice("Guide source","Choose whose route to follow. Quest browsing and map markers remain available independently.",choices,function()return workspace:GuideSourceID()or "RUI"end,function(v)q.guideSource=v;workspace.manualFocus=nil;workspace.manualPickup=nil;workspace.manualTrackedQuest=nil;workspace.guide=nil end,"QuestWorkspace","guideSource")
 f:Action("Browse guides in the map",function()if WorldMapFrame then WorldMapFrame:Show()end;workspace:SelectMapPage("Library")end)
end)
override("CreateSpellbookOptions",function(self,parent)
 local f=self:CreateFlowPage(parent,"spellbook","Spellbook & macros","Spell visibility and macro editing. Learned and future skills stay together in the spellbook.")
 local s=self:LiveSettings("spellbook")
 local function check(key,label,description,target)f:Check(label,description,function()return s[key]end,function(v)s[key]=v end,target or "Spellbook",key)end
 f:Section("Spellbook")
 check("separateFromTalents","Use the Ruthless Spellbook and macros","Open RUI from the spellbook button and keybind.")
 check("showOffSpec","Show other-specialization spells","Keep unavailable specialization abilities visible as dimmed reference entries.")
 check("highlightMissing","Highlight abilities missing from bars","Highlight relevant active abilities that are not on your action bars.")
 f:Section("Macros")
 check("macroAutocomplete","Macro autocomplete","Suggest slash commands, conditions and learned spells while you type.")
 check("autoUpdateRanks","Automatically update macro spell ranks","Upgrade explicit old ranks when a new rank is learned. Previous macros remain in History.","MacroRanks")
 f:Action("Open Spellbook",function()AUI.modules.Spellbook:Show("class")end)
end)

function Menu:CreateProfessionsOptions(parent)
 local f=self:CreateFlowPage(parent,"professions","Professions","Your profession tools have their own window. Use the normal Professions shortcut or micro-menu button.")
 f:Section("Recipes & learning")
 f:Action("Open Professions",function()AUI.modules.Professions:Show()end,"Browse known and future recipes, profession leveling guides, vendor recipe sources and gathering zones.")
 f:Section("Crafting value & preparation")
 f:Action("Crafting profit and auction prices",function()local p=AUI.modules.Professions;p:Show();p:SelectView("Profit")end,"Compare materials and output values with realm auction prices. Enter sale fees and see old or missing-price warnings.")
 f:Action("Profession shopping plans",function()local p=AUI.modules.Professions;p:Show();p:SelectView("Shopping")end,"Character plans aggregate materials and export a shopping list to auction tools. No crafting or purchases happen automatically.")
 f:Note("Recipe observations, prices and plans stay with this character. The window has its own saved position and scale in Edit Mode. Actual crafting still uses the native controls.")
 f:Action("Profession background",function()self:SelectTab("backgrounds")end,"Use the Professions appearance override or inherit the global background.")
end
override("CreateAuctionOptions",function(self,parent)
 local f=self:CreateFlowPage(parent,"auctionhouse","Auction house","Character searches and shopping lists stay with that character. RUI profiles include these feature preferences.")
 f:Section("Search & selling")
 for _,row in ipairs(AUI.modules.SettingsRegistry.auctionControls)do local d=row
  f:Check(d[2],d[3],function()return (ProjectRuthlessDB.auctionHouse or {})[d[1]]~=false end,function(v)ProjectRuthlessDB.auctionHouse=ProjectRuthlessDB.auctionHouse or {};ProjectRuthlessDB.auctionHouse[d[1]]=v end,"AuctionHouse",d[1])
 end
 f:Section("Shopping & appearance")
 f:Action("Quest supplies & shopping lists",function()AUI.modules.AuctionHouseUI:Show("supplies")end)
 f:Action("Auction background colour & opacity",backgrounds)
end)
override("CreateHealthOptions",function(self,parent)
 local f=self:CreateFlowPage(parent,"health","Combat & utilities","Health warnings, the damage meter and character leveling history.")
 local s=self:LiveSettings("lowHealthGlow")
 f:Section("Low-health warning")
 f:Check("Enable low-health glow","Show a red edge warning as health falls.",function()return s.enabled end,function(v)s.enabled=v end,"LowHealthGlow","enabled")
 f:Slider("Starting health","Begin the warning below this health percentage.",.1,.6,.05,percent,function()return s.threshold end,function(v)s.threshold=v end,"LowHealthGlow","threshold")
 f:Slider("Maximum intensity","Limit the warning's opacity at critically low health.",.1,.8,.05,percent,function()return s.maxAlpha end,function(v)s.maxAlpha=v end,"LowHealthGlow","maxAlpha")
 f:Action("Preview glow",function()AUI.modules.LowHealthGlow:Preview()end)
 local meters=AUI.modules.ForeverMeters
 if meters then
  f:Section("Damage meter")
  f:Check("Enable RUI damage meter","Show live combat totals, fight history and spell breakdowns.",function()return meters:Enabled()end,function(v)local _,message=meters:SetEnabled(v);if message then AUI:Print(message)end end)
  f:Check("Flat RUI meter bars","Use simple fills and tight borders while keeping class colours.",function()return (ProjectRuthlessDB.meterStyle or {}).flatBars~=false end,function(v)ProjectRuthlessDB.meterStyle=ProjectRuthlessDB.meterStyle or {};ProjectRuthlessDB.meterStyle.flatBars=v end,"ForeverMeters","flatBars")
  f:Slider("Meter text size","Set the size of names and values; presentation changes wait until combat ends.",9,18,1,tostring,function()return (ProjectRuthlessDB.meterStyle or {}).textSize or 11 end,function(v)ProjectRuthlessDB.meterStyle=ProjectRuthlessDB.meterStyle or {};ProjectRuthlessDB.meterStyle.textSize=v end,"ForeverMeters","textSize")
  f:Action("Meter controls & help",function()meters:Show()end)
  f:Action("Move damage meters",layout)
  f:Action("Meter backgrounds",backgrounds)
 end
 local repair=AUI.modules.RepairReminder
 if repair then
  local general=self:LiveSettings("general")
  f:Section("Equipment repairs")
  f:Check("Show repair warning","Show a readable, movable warning when an equipped item's durability is low. Replaces the small native armour indicator.",function()return general.repairIndicator~=false end,function(v)general.repairIndicator=v end,"RepairReminder","repairIndicator")
  f:Slider("Repair warning threshold","Warn when the lowest equipped item's durability reaches this percentage.",5,75,5,function(v)return v.."%"end,function()return general.repairThreshold or 30 end,function(v)general.repairThreshold=v end,"RepairReminder","repairThreshold")
  f:Check("Repair reminder","Display a reminder when equipment first becomes low, and again if an item breaks. Repeated durability events stay quiet.",function()return general.repairReminder~=false end,function(v)general.repairReminder=v end,"RepairReminder","repairReminder")
  f:Check("Repair reminder sound","Add a sound to the repair reminder.",function()return general.repairSound==true end,function(v)general.repairSound=v end,"RepairReminder","repairSound")
  f:Action("Preview and move repair warning",function()repair:Preview()end,"Show the warning for ten seconds so you can drag it, even when your equipment is repaired.")
 end
 f:Section("Leveling")
 f:Action("Leveling history",function()AUI.modules.LevelHistory:Show()end)
end)
override("CreateActionBarOptions",function(self,parent)
 local f=self:CreateFlowPage(parent,"actionbars","Action bars","Choose visible bars and how buttons behave. Use Edit Mode to position, resize and align them.")
 local function setting(key)return Settings and Settings.GetSetting and Settings.GetSetting(key)end
 f:Section("Visible bars")
 for i=2,8 do local id="bar"..i;local variable="PROXY_SHOW_ACTIONBAR_"..i
  f:Check("Action bar "..i,"Show this bar. Its saved position is retained when hidden.",function()
   local owned=AUI.modules.ForeverActionBars
   if owned and owned.initialized then return owned:IsEnabled(id)end
   local option=setting(variable);return option and option:GetValue()or false
  end,function(v)
   if InCombatLockdown()then AUI:Print("Change action bars after combat.");return end
   local owned=AUI.modules.ForeverActionBars
   if owned and owned.initialized then owned:SetEnabled(id,v);return end
   local option=setting(variable);if option then option:SetValue(v)end
  end)
 end
 f:Section("Button behaviour")
 for _,row in ipairs({{"lockActionBars","Lock action bars","Prevent ordinary dragging from removing abilities."},{"countdownForCooldowns","Show cooldown numbers","Show numbered countdowns on action buttons."}})do local d=row
  f:Check(d[2],d[3],function()local option=setting(d[1]);return option and option:GetValue()or false end,function(v)
   if InCombatLockdown()then AUI:Print("Change action bars after combat.");return end
   local option=setting(d[1]);if option then option:SetValue(v)end
  end)
 end
 f:Choice("Pickup modifier","Hold this key while dragging a locked action button.",{{"SHIFT","Shift"},{"CTRL","Ctrl"},{"ALT","Alt"},{"NONE","None"}},function()local option=setting("PICKUPACTION");return option and option:GetValue()or "SHIFT"end,function(v)
  if InCombatLockdown()then AUI:Print("Change action bars after combat.");return end
  local option=setting("PICKUPACTION");if option then option:SetValue(v)end
 end)
 f:Action("Edit RUI layout",layout)
end)
override("CreateErrorsPanel",function(self,parent)
 local f=self:CreateFlowPage(parent,"errors","Help & diagnostics","Find configuration problems, capture bugs and inspect recorded errors. Checks explain missing features without changing your setup.")
 f:Section("Troubleshooting")
  if AUI.modules.FeatureGuide then f:Action("RUI feature guide",function()self:SelectTab("features")end,"Discover tools, examples and the settings for features that are easy to miss.");f:Action("Replay the introduction",function()AUI.modules.FeatureGuide:Show(true)end)end
 f:Action("Bug report & configuration checks",function()AUI.modules.Diagnostics:Show()end)
 f:Action("Live acceptance checks",function()if AUI.modules.LiveChecks then AUI.modules.LiveChecks:Show()end end)
 local record=f:Action("Start performance recording",function()
  local d=AUI.modules.Diagnostics;d:HandleCommand(d.session and "record off"or "record on");self:Refresh()
 end,"Record a play session when investigating lag or intermittent errors.")
 record.RefreshValue=function(button)local d=AUI.modules.Diagnostics;button:SetText(d and d.session and "Stop performance recording"or "Start performance recording")end
 self.optionControls[#self.optionControls+1]=record
 f:Section("Error history")
 local s=self:LiveSettings("errorLog")
 f:Check("Enable error capture","Record Lua errors and group repeated chat notices.",function()return s.enabled end,function(v)s.enabled=v end,"ErrorLog","enabled")
 f:Slider("Maximum retained errors","Discard the oldest entries when the history reaches this size.",10,200,10,tostring,function()return s.maxEntries end,function(v)s.maxEntries=v;while #s.entries>v do table.remove(s.entries,1)end end,"ErrorLog","maxEntries")
 f:Action("Read or copy error log",function()self:SelectTab("errorlog")end)
 f:Action("Review possible addon conflicts",function()self:SelectTab("compatibility")end)
 f:Action("About RUI & data coverage",function()self:SelectTab("status")end)
end)
override("CreateCompatibilityOptions",function(self,parent)
 local f=self:CreateFlowPage(parent,"compatibility","Addon compatibility","Configuration checks can identify possible ownership conflicts. Another loaded addon is a clue, not proof that it caused an error.")
 f:Action("Review configuration",function()AUI.modules.Diagnostics:Show()end)
 f:Action("Live acceptance checks",function()if AUI.modules.LiveChecks then AUI.modules.LiveChecks:Show()end end)
 f:Action("Back to Help",function()self:SelectTab("errors")end)
end)
override("CreateStatusPanel",function(self,parent)
 local f=self:CreateFlowPage(parent,"status","About RUI","Installed version, capabilities and diagnostics. Data coverage is reported separately from feature configuration.")
 local panel=f.panel
 panel.versionLabel=f:Note("");panel.foundationLabel=f:Note("");panel.ownershipLabel=f:Note("");panel.errorLabel=f:Note("");panel.dependencies=f:Note("")
 f:Action("Back to Help",function()self:SelectTab("errors")end)
end)
function Menu:CreateErrorLogView(parent)
 local panel=self:CreateOptionsPanel(parent,"HELP & DIAGNOSTICS","Error log","Copy a recorded error into a bug report. Clearing this log does not change your settings.")
 self:CreateAction(panel,"Back to Help",18,-110,280,function()self:SelectTab("errors")end)
 self:CreateAction(panel,"Clear error log",308,-110,320,function()AUI.modules.ErrorLog:HandleCommand("clear");self:Refresh()end)
 local scroll=AUI:CreateSmoothScrollFrame(panel);scroll:SetPoint("TOPLEFT",18,-152);scroll:SetPoint("BOTTOMRIGHT",-18,12)
 local edit=CreateFrame("EditBox",nil,scroll);edit:SetMultiLine(true);edit:SetAutoFocus(false);edit:SetFontObject(ChatFontNormal);edit:SetWidth(580);edit:SetTextInsets(8,8,8,8)
 edit:SetScript("OnEscapePressed",function(box)box:ClearFocus()end);scroll:SetScrollChild(edit);AUI:ConfigureScrollingEditBox(edit,scroll,1)
 panel.editBox=edit;self.panels.errorlog=panel
end
override("FilterTabs",function(self,query)
 local registry=AUI.modules.SettingsRegistry
 if not registry then return end
 self.navGroups=self.navGroups or {}
 local y,index=-4,0;local parent=self.navigation or self.sidebar
 for _,tab in ipairs(self.tabs)do
  local section
  for _,candidate in ipairs(registry.sections)do if candidate.id==tab.panelID then section=candidate;break end end
  if section and section.group then
   index=index+1;local label=self.navGroups[index]
   if not label then label=text(parent,section.group,0);label:SetWidth(170);self.navGroups[index]=label end
   label:ClearAllPoints();label:SetPoint("TOPLEFT",4,y);label:SetText(section.group);label:SetTextColor(.55,.58,.65,1);label:Show();y=y-26
  end
  tab:ClearAllPoints();tab:SetPoint("TOPLEFT",parent,"TOPLEFT",0,y);tab:SetWidth(184);tab.label:SetWidth(154)
  local height=math.max(30,(tab.label:GetStringHeight()or 16)+12);tab:SetHeight(height);tab:Show();y=y-height-4
 end
 if self.navigation then self.navigation:SetHeight(-y+8)end
 self:SearchControls((query or ""):lower())
end)

function Menu:CreateFeatureGuide(parent)return AUI.modules.FeatureGuide:BuildSettings(self,parent)end
