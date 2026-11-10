-- Review the constructed settings, not a second copy of the layout algorithm.
do
 local registry=AUI.modules.SettingsRegistry
 assert(#registry.sections==14)
 local ids={}
 for _,section in ipairs(registry.sections)do assert(not ids[section.id]);ids[section.id]=true end
 assert(not ids.backgrounds and not ids.setup and not ids.compatibility and not ids.status)
 assert(registry:NavigationPage("backgrounds")=="general"and registry:NavigationPage("setup")=="profiles")
 assert(registry:NavigationPage("errorlog")=="errors")
 -- Include the optional runtime surfaces with safe service fakes.
 local previousManager,previousCVar=AUI.modules.AuraManager,C_CVar
 local previousMeters,previousProfiles=AUI.modules.ForeverMeters,AUI.modules.UnifiedProfiles
 local previousRepair=AUI.modules.RepairReminder;AUI.modules.RepairReminder={Preview=function()end}
 AUI.modules.ForeverMeters={Enabled=function()return false end,SetEnabled=function()return true end,Show=function()end}
 AUI.modules.UnifiedProfiles={SetDefault=function()end,Store=function()return {default=string.rep("Long profile name ",4)}end}
 local aura={iconSize=24,spacing=3,limit=12,focusSpell=0,expirationThreshold=30}
 ProjectRuthlessDB.auraManager=aura
 AUI.modules.AuraManager={
  Settings=function()return ProjectRuthlessDB.auraManager end,
  CooldownEnabled=function()return false end,Checks=function()return {{status="INFO",message="Test status",setting="Auras"}}end,
  ApplySettings=function()end,SetCooldownEnabled=function()return true end,
  OpenNative=function()end,Preview=function()end,Preset=function()end}
 C_CVar={GetCVar=function()return "1"end,SetCVar=function()end}
 if not AUI.modules.Accessibility then assert(load(ACCESSIBILITY_SOURCE))("ProjectRuthless",AUI)end
 assert(load(AURAOPTIONS_SOURCE))("ProjectRuthless",AUI)
 settingsMenu.pageBuilders.auras="CreateAuraOptions"
 settingsMenu.pageBuilders.auctionhouse="CreateAuctionOptions"
 settingsMenu.pageBuilders.accessibility="CreateAccessibilityOptions"
 AUI.modules.Professions=AUI.modules.Professions or {Show=function()end,SelectView=function()end}
 settingsMenu.pageBuilders.professions="CreateProfessionsOptions"
 assert(load(FEATUREGUIDE_SOURCE))("ProjectRuthless",AUI);settingsMenu.pageBuilders.features="CreateFeatureGuide"
 for _,id in ipairs({"auras","auctionhouse","accessibility","health","profiles","features","professions"})do
  if settingsMenu.panels[id]then settingsMenu.panels[id]:Hide()end
  settingsMenu.buildingPage=id;settingsMenu[settingsMenu.pageBuilders[id]](settingsMenu,settingsMenu.content);settingsMenu.panels[id]:Hide()
 end
 settingsMenu.buildingPage=nil
 local oldMeasure=Frame.GetStringHeight
 local textScale=1
 Frame.GetStringHeight=function(self)
  local size=12*textScale;local width=self.w or 600;local lines=0
  for line in ((self.text or "").."\n"):gmatch("(.-)\n")do lines=lines+math.max(1,math.ceil(#line/math.max(8,math.floor(width/(size*.55)))))end
  return lines*size*1.15
 end
 local reviewed,controls=0,0
 local reviewSections={};for _,section in ipairs(registry.sections)do reviewSections[#reviewSections+1]=section end;reviewSections[#reviewSections+1]={id="features"}
 for _,scale in ipairs({1,1.25,1.5})do
  textScale=scale
  for _,section in ipairs(reviewSections)do
   local panel=settingsMenu.panels[section.id]
   if panel and panel.flow then
    local flow=panel.flow;flow:Reflow()
    local bottom
    for _,row in ipairs(flow.rows)do
     assert(row.control:GetHeight()==row.height)
     assert(not bottom or row.y<=bottom-8,"Overlapping controls on "..section.id)
     bottom=row.y-row.height
     if row.control.description then
      local required=row.control.label:GetStringHeight()+row.control.description:GetStringHeight()+26
      assert(row.height>=required,"Clipped description on "..section.id)
     end
    end
    assert(flow.content:GetHeight()>=-flow.y,"Scroll extent clips "..section.id)
    if scale==1 then reviewed=reviewed+1;controls=controls+#flow.rows end
   end
  end
 end
 assert(reviewed==15 and controls>90,"Reviewed "..reviewed.." pages / "..controls.." controls")
 textScale=1;Frame.GetStringHeight=oldMeasure;settingsMenu:ReflowPages()
 -- Cached pages must read and write the newly active profile's tables.
 local oldMap=ProjectRuthlessDB.mapQuests;local oldGeneral=ProjectRuthlessDB.general
 local marker=registry:Search("Show quest markers")[1]
 ProjectRuthlessDB.mapQuests={enabled=false}
 assert(marker.control.getter()==false)
 marker.control.setter(true)
 assert(ProjectRuthlessDB.mapQuests.enabled and ProjectRuthlessDB.mapQuests~=oldMap)
 local proxy=settingsMenu:LiveSettings("general")
 ProjectRuthlessDB.general={windowScale=.9}
 assert(proxy.windowScale==.9);proxy.windowScale=1.1;assert(ProjectRuthlessDB.general.windowScale==1.1 and oldGeneral.windowScale~=1.1)
 ProjectRuthlessDB.mapQuests=oldMap;ProjectRuthlessDB.general=oldGeneral
 -- Choices expose all choices rather than cycling through hidden states.
 local choice=registry:Search("Backpack columns")[1];assert(choice and choice.kind=="choice")
 local oldMenu=MenuUtil;local offered={}
 MenuUtil={CreateContextMenu=function(_,builder)
  builder(nil,{CreateTitle=function()end,CreateRadio=function(_,caption,selected,choose)offered[#offered+1]={caption,selected,choose}end})
 end}
 choice.control:Fire("OnClick");assert(#offered==3 and offered[1][1]=="8 columns")
 offered[3][3]();assert(AUI.modules.ForeverStyle:BagSettings().columns==12)
 MenuUtil=oldMenu
 -- Every search result still has one exact, registered destination.
 local seen={}
 for _,row in ipairs(registry.controls)do assert(not seen[row.id]);seen[row.id]=true;assert(row.control and settingsMenu.pageBuilders[row.page])end
 for _,row in ipairs(registry:Search("animated portraits"))do assert(row.page~="setup","Wizard drafts must not duplicate real settings in search")end
 local rows=registry:Search("dot");assert(#rows>0 and rows[1].page=="auras")
 local before=#registry.controls;settingsMenu:SearchControls("party");settingsMenu:SearchControls("opacity");assert(#registry.controls==before)
 local report={"page\tkind\tlabel\trefresh_target\tkey"}
 for _,row in ipairs(registry.controls)do report[#report+1]=table.concat({row.page,row.kind or "",row.label,row.section or "",row.key or ""},"\t")end
 SETTINGS_AUDIT_TSV=table.concat(report,"\n")
 AUI.modules.AuraManager=previousManager;C_CVar=previousCVar
 AUI.modules.ForeverMeters=previousMeters;AUI.modules.UnifiedProfiles=previousProfiles
 AUI.modules.RepairReminder=previousRepair
 print(("PASS: %d real settings pages / %d flow controls reviewed at 100/125/150%% text; no overlap/clipping, complete scroll ranges, live profile bindings, explicit choices, unique searchable destinations and wizard exclusion"):format(reviewed,controls))
end
