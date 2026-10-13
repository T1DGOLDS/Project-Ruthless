local _,AUI=...
local P={};AUI:RegisterModule("Profiles",P)
-- Only presentation/behaviour preferences travel; progress, macro backups,
-- diagnostics, character positions and dependency state remain local.
local spec={
 general={windowScale={.75,1.25},windowOpacity={.65,1},partyGrouped=true},
 character={replaceBlizzard=true,showItemLevels=true,showProgress=true},
 spellbook={replaceProfessions=true,separateFromTalents=true,showOffSpec=true,highlightMissing=true,macroAutocomplete=true,autoUpdateRanks=true},
 talents={enabled=true},achievements={enabled=true},
 mapQuests={enabled=true,showLocalStories=true,showTrivial=true,showAccountCompleted=true},
 questWorkspace={enabled=true,showArrow=true,locked=true,autoHandIn=true,prepWestfall=true,useWisp=true,opacity={.25,1}},
 lowHealthGlow={enabled=true,threshold={.05,.95},maxAlpha={0,1}}
}
spec.general.backgroundOpacity={0,1}
spec.errorLog={enabled=true,maxEntries={10,200}}
spec.accessibility={textScale={1,1.5},reducedMotion=true,highContrast=true,animatedPortraits=true}
for _,key in ipairs({"Quest","Player","Target","Party","Chat","ActionBars","XP","Micro","BagButtons","Backpack","Meters","Map","Spellbook","Cast","Options","Professions"})do spec.general["background"..key]={-1,1}end
for _,channel in ipairs({"R","G","B"})do
 spec.general["color"..channel]={0,1}
 for _,key in ipairs({"Quest","Player","Target","Party","Chat","ActionBars","XP","Micro","BagButtons","Backpack","Meters","Map","Spellbook","Cast","Options","Professions"})do
  spec.general["color"..channel..key]={0,1};spec.general["customColor"..key]=true
 end
end
spec.questWorkspace.guideSource={identifier=true}
local function valid(rule,value)
 if rule==true then return type(value)=="boolean"end
 if rule.identifier then return type(value)=="string"and #value<=40 and value:match("^[%w_%-]+$")~=nil end
 if rule.values then return type(value)=="string"and rule.values[value]==true end
 if rule[1]==-1 and type(value)=="number"and value<0 then return value==-1 end
 return type(value)=="number"and value==value and value>=rule[1]and value<=rule[2]
end
function P:Export()
 local lines={"RUI_SETTINGS_1"}
 for section,fields in pairs(spec)do
  for key,rule in pairs(fields)do
   local value=ProjectRuthlessDB[section]and ProjectRuthlessDB[section][key]
   if valid(rule,value)then lines[#lines+1]=section.."."..key.."="..tostring(value)end
  end
 end
 table.sort(lines,function(a,b)if a=="RUI_SETTINGS_1"then return true end;if b=="RUI_SETTINGS_1"then return false end;return a<b end)
 return table.concat(lines,"\n")
end
function P:Parse(text)
 if type(text)~="string"or #text>16384 then return nil,"Settings text is missing or too large."end
 text=text:gsub("\r","")
 local first=true;local settings={};local count=0
 for line in text:gmatch("[^\n]+")do
  if first then if line~="RUI_SETTINGS_1"then return nil,"Unsupported settings version."end;first=false
  else
   local section,key,raw=line:match("^(%a+)%.(%a+)=(.+)$")
   local rule=section and spec[section]and spec[section][key]
   -- Accept this retired field in old exports, without applying or exporting it.
   if section=="elvui"and key=="safeTooltip"then rule=true end
   if not rule then return nil,"Unknown setting: "..line end
   local value;if type(rule)=="table"and (rule.values or rule.identifier)then value=raw elseif raw=="true"then value=true elseif raw=="false"then value=false else value=tonumber(raw)end
   if not valid(rule,value)then return nil,"Invalid value: "..section.."."..key end
   settings[section]=settings[section]or {}
   if settings[section][key]~=nil then return nil,"Duplicate setting: "..section.."."..key end
   settings[section][key]=value;count=count+1
  end
 end
 if first or count==0 then return nil,"No settings found."end
 return settings
end
function P:Import(text)
 if InCombatLockdown()then return false,"Apply settings outside combat."end
 local settings,err=self:Parse(text);if not settings then return false,err end
 -- Validate everything before writing anything. Keep one reversible pre-import snapshot.
 ProjectRuthlessDB.settingsBackup=self:Export()
 for section,values in pairs(settings)do
  if section~="elvui"then
  ProjectRuthlessDB[section]=ProjectRuthlessDB[section]or {}
  for key,value in pairs(values)do ProjectRuthlessDB[section][key]=value end
  end
 end
 return true,"Settings applied. Reload to refresh all windows."
end
function P:Save(name)
 name=type(name)=="string"and name:match("^%s*(.-)%s*$")or ""
 if #name<1 or #name>40 then return false,"Use a profile name of 1–40 characters."end
 ProjectRuthlessDB.settingsProfiles=ProjectRuthlessDB.settingsProfiles or {}
 local count=0;for _ in pairs(ProjectRuthlessDB.settingsProfiles)do count=count+1 end
 if count>=20 and not ProjectRuthlessDB.settingsProfiles[name]then return false,"Maximum 20 profiles."end
 ProjectRuthlessDB.settingsProfiles[name]=self:Export();return true,"Saved "..name
end
function P:Load(name)
 local text=ProjectRuthlessDB.settingsProfiles and ProjectRuthlessDB.settingsProfiles[name]
 if not text then return false,"No saved profile with that name."end
 return self:Import(text)
end
function P:Restore()
 local backup=ProjectRuthlessDB.settingsBackup
 if not backup then return false,"No previous settings to restore."end
 return self:Import(backup)
end
