local _,AUI=...
local P={};AUI:RegisterModule("UnifiedProfiles",P)
local settings=AUI.modules.Profiles
local editor=AUI.modules.LayoutEditor
local function copy(value)
 if type(value)~="table"then return value end
 local result={};for k,v in pairs(value)do result[k]=copy(v)end;return result
end
local function finite(n)return type(n)=="number"and n==n and math.abs(n)<10000 end
local nativeRules={lockActionBars="boolean",countdownForCooldowns="boolean",PICKUPACTION="modifier"}
for i=2,8 do nativeRules["PROXY_SHOW_ACTIONBAR_"..i]="boolean"end
function P:CaptureNative()
 local values={}
 if not Settings or not Settings.GetSetting then return values end
 for name in pairs(nativeRules)do local option=Settings.GetSetting(name)
  if option then local ok,value=pcall(option.GetValue,option)
   if ok and not(issecretvalue and issecretvalue(value))and (type(value)=="boolean"or type(value)=="string")then values[name]=value end
  end
 end
 return values
end
function P:ApplyNative(values)
 local missing=0
 for name,value in pairs(values or {})do
  local option=Settings and Settings.GetSetting and Settings.GetSetting(name)
  if option then
   local ok=pcall(function()
    local current=option:GetValue()
    if issecretvalue and issecretvalue(current)then error("Native preference unavailable")end
    if current~=value then option:SetValue(value)end
   end)
   if not ok then missing=missing+1 end
  else missing=missing+1 end
 end
 return missing
end
local function nameOf(name)
 name=type(name)=="string"and name:match("^%s*(.-)%s*$")or ""
 if #name<1 or #name>64 or name:find("[%c]")then return end
 return name
end
function P:Store()
 ProjectRuthlessDB.profilesV2=ProjectRuthlessDB.profilesV2 or {version=2,entries={}}
 return ProjectRuthlessDB.profilesV2
end
function P:Names()
 local names={};for name in pairs(self:Store().entries)do names[#names+1]=name end;table.sort(names);return names
end
function P:Capture()
 return {version=2,full=true,settings=settings:Export(),layout=editor:Snapshot(),editorPrefs={gridSize=editor:Store().gridSize or 8,panelPosition=copy(editor:Store().panelPosition)},native=self:CaptureNative(),pins=copy(ProjectRuthlessDB.spellbook and ProjectRuthlessDB.spellbook.pinnedSpells or {}),bags={
  autoSort=(ProjectRuthlessCharDB.ruiBags or {}).autoSort==true,
  columns=(ProjectRuthlessCharDB.ruiBags or {}).columns or 10}}
end
function P:Validate(profile)
 if type(profile)~="table"or profile.version~=2 then return false,"Unsupported profile version."end
 for key in pairs(profile)do if not ({version=true,full=true,settings=true,layout=true,bags=true,legacy=true,native=true,pins=true,editorPrefs=true})[key]then return false,"Unknown profile component."end end
 if profile.full~=nil and type(profile.full)~="boolean"then return false,"Invalid profile type."end
 if profile.legacy~=nil and (type(profile.legacy)~="string"or #profile.legacy>200)then return false,"Invalid migration label."end
 if profile.full and (not profile.settings or not profile.layout or not profile.bags or not profile.native or not profile.pins)then return false,"Incomplete full profile."end
 if profile.settings then local parsed,err=settings:Parse(profile.settings);if not parsed then return false,err end end
 if not profile.settings and not profile.layout then return false,"Empty profile."end
 if profile.editorPrefs then
  local p=profile.editorPrefs
  if type(p)~="table"or not ({[8]=true,[16]=true,[32]=true})[p.gridSize]then return false,"Invalid editor grid."end
  if p.panelPosition and (type(p.panelPosition)~="table"or not finite(p.panelPosition.x)or not finite(p.panelPosition.y))then return false,"Invalid editor panel position."end
 end
 if profile.native then
  if type(profile.native)~="table"then return false,"Invalid native preferences."end
  for name,value in pairs(profile.native)do
   local rule=nativeRules[name]
   if not rule or rule=="boolean"and type(value)~="boolean"or rule=="modifier"and not ({SHIFT=true,CTRL=true,ALT=true,NONE=true})[value]then return false,"Invalid native preference."end
  end
 end
 if profile.pins then
  if type(profile.pins)~="table"then return false,"Invalid spell pins."end
  for key,value in pairs(profile.pins)do if type(key)~="string"or not key:match("^%d+$")or #key>10 or type(value)~="boolean"then return false,"Invalid spell pin."end end
 end
 local function position(v)
  if type(v)~="table"or not finite(v.x)or not finite(v.y)or not finite(v.scale)or v.scale<.1 or v.scale>3 or not finite(v.width)or v.width<=0 or not finite(v.height)or v.height<=0 then return false end
  for k in pairs(v)do if not ({x=true,y=true,scale=true,width=true,height=true,nativeSettings=true})[k]then return false end end
  if v.nativeSettings then
   if type(v.nativeSettings)~="table"then return false end
   for k,n in pairs(v.nativeSettings)do if not finite(k)or k<0 or k%1~=0 or not(type(n)=="boolean"or finite(n))then return false end end
  end
  return true
 end
 if profile.layout then
  if type(profile.layout)~="table"then return false,"Invalid layout."end
  for id,v in pairs(profile.layout)do
   if id=="__art"then
    if type(v)~="table"or type(v.blizzardArt)~="boolean"then return false,"Invalid decorative art setting."end
   elseif id=="__chat"then
    if type(v)~="table"or #v>10 then return false,"Invalid chat tabs."end
    for _,tab in ipairs(v)do
     if type(tab)~="table"or not finite(tab.id)or tab.id<1 or tab.id>10 or type(tab.name)~="string"or #tab.name>100 or not finite(tab.size)or tab.size<1 or tab.size>72 then return false,"Invalid chat tab."end
     for _,key in ipairs({"r","g","b","a"})do if not finite(tab[key])or tab[key]<0 or tab[key]>1 then return false,"Invalid chat colour."end end
     for _,key in ipairs({"locked","docked","uninteractable","selected"})do if tab[key]~=nil and type(tab[key])~="boolean"then return false,"Invalid chat flag."end end
     if tab.dockIndex and (not finite(tab.dockIndex)or tab.dockIndex<1 or tab.dockIndex>10)then return false,"Invalid chat order."end
     if tab.position and not position(tab.position)then return false,"Invalid chat position."end
     for _,key in ipairs({"messages","channels"})do
      if type(tab[key])~="table"or #tab[key]>200 then return false,"Invalid chat subscriptions."end
      for _,item in ipairs(tab[key])do if type(item)~="string"and not finite(item)then return false,"Invalid chat subscription."end end
     end
    end
   elseif type(id)~="string"or not id:match("^[%w_%-]+$")or not position(v)then return false,"Invalid element position: "..tostring(id)end
  end
 end
 if profile.bags then
  local b=profile.bags
  if type(b)~="table"or type(b.autoSort)~="boolean"or not ({[8]=true,[10]=true,[12]=true})[b.columns]then return false,"Invalid bag preferences."end
 end
 return true
end
function P:Migrate()
 local store=self:Store()
 local old=editor:AccountLayouts()
 if not store.migrated then
 for name,text in pairs(ProjectRuthlessDB.settingsProfiles or {})do
  if settings:Parse(text)then store.entries["Settings: "..name]={version=2,settings=text,legacy="Settings only — save to include your current layout and chat."}end
 end
 for name,layout in pairs(old.layouts)do
  local entry={version=2,layout=copy(layout),legacy="Layout and chat only — save to include your current settings."}
  if self:Validate(entry)then store.entries["Layout: "..name]=entry end
 end
 if old.default and store.entries["Layout: "..old.default]then store.default="Layout: "..old.default end
 store.migrated=true
 end
 -- Each character can still hold older local saves. Import on that character's
 -- first visit, preserving conflicting same-name layouts as distinct entries.
 if not ProjectRuthlessCharDB.profileLegacyMigration then
  local function equal(a,b)
   if type(a)~=type(b)then return false end;if type(a)~="table"then return a==b end
   for k,v in pairs(a)do if not equal(v,b[k])then return false end end
   for k in pairs(b)do if a[k]==nil then return false end end;return true
  end
  for name,layout in pairs((ProjectRuthlessCharDB.layoutEditor or {}).layouts or {})do
   local base="Layout: "..name;local key=base;local index=1
   while store.entries[key]and not equal(store.entries[key].layout,layout)do index=index+1;key=base.." ("..index..")"end
   local entry={version=2,layout=copy(layout),legacy="Layout and chat only — save to include your current settings."}
   if not store.entries[key]and self:Validate(entry)then store.entries[key]=entry end
  end
  ProjectRuthlessCharDB.profileLegacyMigration=true
 end
end
-- Settings remain available at their native module paths. The character's working
-- copy restores them before modules initialise; account profiles are snapshots.
function P:WriteSettings(text,full)
 local parsed=settings:Parse(text)
 if full then
  for key in pairs(ProjectRuthlessDB.general)do
   if key:match("^color[RGB]")or key:match("^customColor")or key:match("^background")then ProjectRuthlessDB.general[key]=nil end
  end
 end
 for section,values in pairs(parsed or {})do if section~="elvui"then
  ProjectRuthlessDB[section]=ProjectRuthlessDB[section]or {}
  for key,value in pairs(values)do ProjectRuthlessDB[section][key]=value end
 end end
end
function P:InitializeCharacter()
 self:Migrate()
 local char=ProjectRuthlessCharDB;local store=self:Store()
 if not char.profileVersion then
  if not char.layoutEditor and store.default then
   local profile=store.entries[store.default]
   if profile and self:Validate(profile)then
    if profile.settings then self:WriteSettings(profile.settings,profile.full)end
    if profile.layout then
     local elements=copy(profile.layout);elements.__chat=nil;elements.__art=nil
     char.layoutEditor={elements=elements,layouts={},accountMigrated=true,active=store.default,blizzardArt=profile.layout.__art and profile.layout.__art.blizzardArt or false}
     char.pendingLayoutChat=copy(profile.layout.__chat)
    end
    if profile.bags then char.ruiBags=copy(profile.bags)end
    if profile.pins then ProjectRuthlessDB.spellbook.pinnedSpells=copy(profile.pins)end
    self.pendingNative=copy(profile.native)
    if profile.editorPrefs then
     char.layoutEditor=char.layoutEditor or {elements={},layouts={},accountMigrated=true}
     char.layoutEditor.gridSize=profile.editorPrefs.gridSize;char.layoutEditor.panelPosition=copy(profile.editorPrefs.panelPosition)
    end
    char.activeProfile=store.default
   end
  end
  char.profileVersion=2
 elseif char.profileWorkingSettings then self:WriteSettings(char.profileWorkingSettings,true)
  if char.profileWorkingPins then ProjectRuthlessDB.spellbook.pinnedSpells=copy(char.profileWorkingPins)end
 end
 char.profileWorkingSettings=settings:Export()
end
function P:Save(name)
 if InCombatLockdown()then return false,"Save profiles after combat."end
 name=nameOf(name);if not name then return false,"Use a profile name of 1–64 characters."end
 local store=self:Store();local count=#self:Names()
 if count>=60 and not store.entries[name]then return false,"Maximum 60 profiles."end
 local profile=self:Capture();local ok,err=self:Validate(profile);if not ok then return false,err end
 if store.entries[name]then
  store.history=store.history or {};store.history[#store.history+1]={name=name,profile=copy(store.entries[name])}
  if #store.history>5 then table.remove(store.history,1)end
 end
 store.entries[name]=copy(profile);ProjectRuthlessCharDB.activeProfile=name;editor:Store().active=name
 return true,"Saved settings, layout and chat as "..name.."."
end
function P:Apply(profile,name)
 if InCombatLockdown()then return false,"Apply profiles after combat. Your current setup has been kept."end
 local ok,err=self:Validate(profile);if not ok then return false,err end
 local backup=self:Capture();ProjectRuthlessCharDB.profileBackup=copy(backup);ProjectRuthlessCharDB.profileBackupName=ProjectRuthlessCharDB.activeProfile
 if profile.settings then self:WriteSettings(profile.settings,profile.full)end
 if profile.bags then ProjectRuthlessCharDB.ruiBags=copy(profile.bags)end
 if profile.pins then ProjectRuthlessDB.spellbook.pinnedSpells=copy(profile.pins)end
 if profile.editorPrefs then
  editor:Store().gridSize=profile.editorPrefs.gridSize;editor.gridSize=profile.editorPrefs.gridSize
  editor:Store().panelPosition=copy(profile.editorPrefs.panelPosition)
  if editor.frame then
   editor.frame:ClearAllPoints()
   if profile.editorPrefs.panelPosition then editor.frame:SetPoint("CENTER",UIParent,"CENTER",profile.editorPrefs.panelPosition.x,profile.editorPrefs.panelPosition.y)
   else editor.frame:SetPoint("TOPLEFT",UIParent,"TOPLEFT",24,-80)end
  end
 end
 local missing=self:ApplyNative(profile.native)
 -- Persist first, then let native delegates apply supported layout/chat changes.
 if profile.layout then editor:Restore(copy(profile.layout))end
 ProjectRuthlessCharDB.activeProfile=name;editor:Store().active=name
 ProjectRuthlessCharDB.profileWorkingSettings=settings:Export()
 AUI:ApplyWindowSettings("profile");AUI:RefreshBackgrounds()
 for _,id in ipairs({"ForeverHUD","ForeverStyle","Spellbook","MapQuests","QuestWorkspace","LowHealthGlow"})do
  local module=AUI.modules[id]
  if module and type(module.ApplySettings)=="function"and not (id=="ForeverStyle"and profile.layout)then module:ApplySettings()end
 end
 if editor.name then editor.name:SetText(name or "")end
 return true,missing>0 and ("Profile applied; %d native preferences were unavailable. Check Action bars and reload outside combat."):format(missing)or profile.legacy or "Profile applied: settings, layout and chat."
end
function P:Load(name)
 local profile=self:Store().entries[name]
 if not profile then return false,"No saved profile with that name."end
 if not InCombatLockdown()and self:Validate(profile)and editor.frame and editor.frame:IsShown()then editor:Checkpoint()end
 return self:Apply(copy(profile),name)
end
function P:RecoverSaved()
 local history=self:Store().history or {};local previous=history[#history]
 if not previous then return false,"No overwritten save to recover."end
 local ok,message=self:Apply(copy(previous.profile),previous.name)
 if ok then self:Store().entries[previous.name]=copy(previous.profile);table.remove(history)end
 return ok,message
end
function P:Restore()
 local backup=ProjectRuthlessCharDB.profileBackup
 if not backup then return false,"No previous profile to restore."end
 return self:Apply(copy(backup),ProjectRuthlessCharDB.profileBackupName)
end
local function hex(s)return (s:gsub(".",function(c)return ("%02x"):format(c:byte())end))end
local function unhex(s)
 if #s%2~=0 or s:find("[^%x]")then return end
 return (s:gsub("..",function(pair)return string.char(tonumber(pair,16))end))
end
-- A bounded data format: no loadstring, executable expressions or metatables.
function P:Export()
 local lines={"RUI_PROFILE_2"}
 local function walk(value,path)
  if type(value)=="table"then
   lines[#lines+1]=path.."=t:"
   local keys={};for key in pairs(value)do keys[#keys+1]=key end
   table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
   for _,key in ipairs(keys)do walk(value[key],path.."/"..(type(key)=="number"and "n"..key or "s"..hex(key)))end
  else
   local kind=type(value)
   lines[#lines+1]=path.."="..(kind=="string"and "s:"..hex(value)or kind=="boolean"and "b:"..tostring(value)or "n:"..tostring(value))
  end
 end
 walk(self:Capture(),"root");return table.concat(lines,"\n")
end
function P:Parse(text)
 if type(text)~="string"or #text>262144 then return nil,"Profile text is missing or too large."end
 if text:sub(1,13)~="RUI_PROFILE_2"then
  local parsed,err=settings:Parse(text);if not parsed then return nil,err end
  return {version=2,settings=text,legacy="Imported settings only. Save a profile to include layout and chat."}
 end
 local root,seen=nil,{};local count=0
 for line in text:gsub("\r",""):gmatch("[^\n]+")do
  count=count+1;if count>6000 then return nil,"Too many profile fields."end
  if count>1 then
   local path,kind,raw=line:match("^(root[/ns%x%d%./%-]*)=([tsbn]):(.*)$")
   if not path or seen[path]then return nil,"Invalid or duplicate profile field."end
   seen[path]=true
   local value
   if kind=="t"then if raw~=""then return nil,"Invalid table."end;value={}
   elseif kind=="s"then value=unhex(raw);if not value then return nil,"Invalid text."end
   elseif kind=="b"then if raw~="true"and raw~="false"then return nil,"Invalid flag."end;value=raw=="true"
   else value=tonumber(raw);if not finite(value)then return nil,"Invalid number."end end
   if path=="root"then if root or type(value)~="table"then return nil,"Invalid profile root."end;root=value
   else
    if not root then return nil,"Missing profile root."end
    local parts={};for part in path:gmatch("/([^/]+)")do parts[#parts+1]=part end
    if #parts<1 or #parts>8 then return nil,"Invalid profile depth."end
    local parent=root
    for i,part in ipairs(parts)do
     local key=part:sub(1,1)=="s"and unhex(part:sub(2))or part:sub(1,1)=="n"and tonumber(part:sub(2))
     if key==nil or type(key)=="number"and (not finite(key)or key<0 or key%1~=0)then return nil,"Invalid profile key."end
     if i==#parts then if parent[key]~=nil then return nil,"Duplicate decoded field."end;parent[key]=value
     else parent=parent[key];if type(parent)~="table"then return nil,"Missing parent field."end end
    end
   end
  end
 end
 local ok,err=self:Validate(root);if not ok then return nil,err end;return root
end
function P:Import(text)
 local profile,err=self:Parse(text);if not profile then return false,err end
 return self:Apply(profile)
end
function P:SetDefault(name)
 if name and not self:Store().entries[name]then return false,"Choose a saved profile."end
 self:Store().default=name
 if editor.defaultProfile then editor.defaultProfile:SetText(name or "None")end
 return true,name and "New characters will start with "..name.."."or "New characters will use the starting setup."
end
function P:Menu(anchor,onSelected,defaultMenu)
 if not MenuUtil or not MenuUtil.CreateContextMenu then return end
 MenuUtil.CreateContextMenu(anchor,function(_,root)
  root:CreateTitle(defaultMenu and "Default for new characters"or "Saved account profiles")
  if defaultMenu then root:CreateRadio("None",function()return not self:Store().default end,function()self:SetDefault(nil);if onSelected then onSelected(nil)end end)end
  for _,name in ipairs(self:Names())do local key=name
   root:CreateRadio(key,function()return (defaultMenu and self:Store().default or ProjectRuthlessCharDB.activeProfile)==key end,function()
    local ok,message
    if defaultMenu then ok,message=self:SetDefault(key)elseif onSelected then onSelected(key);return else ok,message=self:Load(key)end
    if onSelected then onSelected(key)end
    if message then AUI:Print(message)end
   end)
  end
 end)
end
function P:OnPlayerLogin()
 if self.pendingNative then
  local missing=self:ApplyNative(self.pendingNative);self.pendingNative=nil
  if missing>0 then AUI:Print("Some default profile action-bar preferences were unavailable. Check Action bars.")end
 end
 local frame=CreateFrame("Frame");frame:RegisterEvent("PLAYER_LOGOUT")
 frame:SetScript("OnEvent",function()
  ProjectRuthlessCharDB.profileWorkingSettings=settings:Export()
  ProjectRuthlessCharDB.profileWorkingPins=copy(ProjectRuthlessDB.spellbook.pinnedSpells)
 end)
end
-- Keep legacy implementations for historical clients; Forever uses one service.
local save,load=editor.Save,editor.Load
function editor:Save(name)if AUI.isForever then return P:Save(name)end;return save(self,name)end
function editor:Load(name)if AUI.isForever then return P:Load(name)end;return load(self,name)end
local profileMenu,defaultMenu,setDefault=editor.ProfileMenu,editor.DefaultProfileMenu,editor.SetDefaultProfile
function editor:ProfileMenu(anchor)if AUI.isForever then return P:Menu(anchor)end;return profileMenu(self,anchor)end
function editor:DefaultProfileMenu(anchor)if AUI.isForever then return P:Menu(anchor,nil,true)end;return defaultMenu(self,anchor)end
function editor:SetDefaultProfile(name)if AUI.isForever then return P:SetDefault(name)end;return setDefault(self,name)end
