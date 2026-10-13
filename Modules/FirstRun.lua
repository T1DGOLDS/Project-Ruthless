local _,AUI=...
local F={nativePlacement={}}
AUI:RegisterModule("FirstRun",F)
function F:InitializeCharacter()
 local char=ProjectRuthlessCharDB
 if char.firstRun then return end
 local profiles=ProjectRuthlessDB.profilesV2
 local legacy=ProjectRuthlessDB.layoutProfiles
 local default
 if profiles then default=profiles.default
 elseif legacy and legacy.defaultChosen then default=legacy.default end
 local fresh=not char.layoutEditor and not char.profileVersion and not char.welcomed
 char.firstRun={version=1,eligible=fresh and not default,complete=not fresh or default~=nil}
 self.useNativePlacement=fresh and not default
 if self.useNativePlacement then
  ProjectRuthlessDB.accessibility={}
  local general=ProjectRuthlessDB.general
  general.windowScale=1;general.windowOpacity=1;general.partyGrouped=false;general.backgroundOpacity=.72
  for key in pairs(general)do
   if key:match("^color[RGB]")or key:match("^customColor")or key:match("^background.+")then general[key]=nil end
  end
  general.backgroundOpacity=.72
 end
end
function F:CaptureNativePlacement()
 if not self.useNativePlacement then return end
 local editor=AUI.modules.LayoutEditor
 for id,name in pairs({party="PartyFrame",quests="ObjectiveTrackerFrame",castplayer="PlayerCastingBarFrame",casttarget="TargetFrameSpellBar"})do
  local frame=_G[name];local value=frame and editor:Capture(frame)
  if value then
   local ok,scale=pcall(frame.GetEffectiveScale,frame);local good,parentScale=pcall(UIParent.GetEffectiveScale,UIParent)
   if ok and good and not(issecretvalue and (issecretvalue(scale)or issecretvalue(parentScale)))and type(scale)=="number"and type(parentScale)=="number"and parentScale>0 then
    value.width=value.width*scale/parentScale;value.height=value.height*scale/parentScale;value.scale=1
    self.nativePlacement[id]=value
   end
  end
 end
end
function F:PlaceReplacement(id,frame)
 if not self.useNativePlacement or ProjectRuthlessCharDB.activeProfile or AUI.modules.LayoutEditor:Store().elements[id]then return end
 local v=self.nativePlacement[id];if not v then return end
 local ratio=UIParent:GetEffectiveScale()/frame:GetEffectiveScale()
 frame:ClearAllPoints()
 if id=="party"then frame:SetPoint("TOPLEFT",UIParent,"CENTER",(v.x-v.width*v.scale/2)*ratio,(v.y+v.height*v.scale/2)*ratio)
 elseif id=="quests"then frame:SetPoint("TOPRIGHT",UIParent,"CENTER",(v.x+v.width*v.scale/2)*ratio,(v.y+v.height*v.scale/2)*ratio)
 else frame:SetPoint("CENTER",UIParent,"CENTER",v.x*ratio,v.y*ratio)end
 local saved=AUI.modules.LayoutEditor:Capture(frame)
 if saved then AUI.modules.LayoutEditor:Store().elements[id]=saved end
end
function F:Finish(options)
 if InCombatLockdown()then return false,"Finish setup after combat. Your choices are kept."end
 local profiles=AUI.modules.UnifiedProfiles
 if profiles then ProjectRuthlessCharDB.profileBackup=profiles:Capture();ProjectRuthlessCharDB.profileBackupName=ProjectRuthlessCharDB.activeProfile end
 local s=ProjectRuthlessDB.accessibility or {};ProjectRuthlessDB.accessibility=s
 s.animatedPortraits=options.animatedPortraits==true;s.reducedMotion=options.reducedMotion==true
 s.highContrast=options.highContrast==true;s.textScale=options.largeText and 1.25 or 1
 ProjectRuthlessCharDB.layoutEditor.blizzardArt=false
 ProjectRuthlessCharDB.firstRun.complete=true
 AUI.modules.Accessibility:ApplySettings()
 local style=AUI.modules.ForeverStyle;if style then style:ApplySettings()end
 return true,"Setup saved. Profiles saves your whole interface; Edit Mode moves it."
end
function F:OnPlayerLogin()
 local state=ProjectRuthlessCharDB.firstRun
 if state and state.eligible and not state.complete and not ProjectRuthlessCharDB.activeProfile then
  C_Timer.After(1,function()
   if not InCombatLockdown()then AUI.modules.Menu:Show("setup")
   else
    local retry=CreateFrame("Frame")
    retry:RegisterEvent("PLAYER_REGEN_ENABLED")
    retry:SetScript("OnEvent",function()
     retry:UnregisterAllEvents()
     if not state.complete and not ProjectRuthlessCharDB.activeProfile then AUI.modules.Menu:Show("setup")end
    end)
   end
  end)
 end
end
