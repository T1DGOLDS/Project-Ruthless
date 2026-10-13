local _,AUI=...
local R={controls={},byID={}}
AUI:RegisterModule("SettingsRegistry",R)
R.sections={
 {id="general",label="Appearance"},{id="unitframes",label="Unit frames"},
 {id="actionbars",label="Action bars"},{id="spellbook",label="Spellbook & macros"},
 {id="chat",label="Chat"},{id="bags",label="Bags & inventory"},
 {id="mapquests",label="Map & quests"},{id="health",label="Utilities"},
 {id="profiles",label="Profiles"},{id="errors",label="Help & diagnostics"},
 {id="compatibility",label="Compatibility"},{id="status",label="About"},
 {id="backgrounds",label="Backgrounds"}}
table.insert(R.sections,10,{id="accessibility",label="Accessibility"})
table.insert(R.sections,11,{id="setup",label="Quick setup"})
local synonyms={opacity="transparency transparent alpha fade charcoal shadow",background="colour color panel backdrop",party="group grouped member teammate",scale="size zoom",cooldown="cd timer countdown",profile="layout setup default character account",chat="tabs channels messages",bag="inventory backpack sort",health="hp life warning",spell="ability skill macro",quest="guide route journey waypoint",art="blizzard gryphon decoration trim",record="cpu performance lag spikes report bug"}
function R:Register(page,control,label,description,y,kind)
 if not page or not control then return end
 local id=page..":"..label:lower():gsub("[^%w]+","_")
 local row=self.byID[id]
 if not row then row={id=id};self.controls[#self.controls+1]=row;self.byID[id]=row end
 row.page=page;row.control=control;row.label=label;row.description=description or "";row.y=y or 0;row.kind=kind
 local terms=(page.." "..label.." "..row.description):lower()
 for word,aliases in pairs(synonyms)do if terms:find(word,1,true)then terms=terms.." "..aliases end end
 row.terms=terms
 return row
end
function R:Search(query)
 local words={};for word in (query or ""):lower():gmatch("%S+")do words[#words+1]=word end
 if #words==0 then return {}end
 local results={}
 for _,row in ipairs(self.controls)do
  local matches=true;for _,word in ipairs(words)do if not row.terms:find(word,1,true)then matches=false;break end end
  if matches then results[#results+1]=row end
 end
 table.sort(results,function(a,b)
  local aExact=a.label:lower():find(query:lower(),1,true)~=nil
  local bExact=b.label:lower():find(query:lower(),1,true)~=nil
  if aExact~=bExact then return aExact end
  return a.label==b.label and a.id<b.id or a.label<b.label
 end)
 return results
end
function AUI:BackgroundColor(key,r,g,b)
 if ProjectRuthlessDB and (ProjectRuthlessDB.accessibility or {}).highContrast then return .018,.020,.024 end
 local s=ProjectRuthlessDB and ProjectRuthlessDB.general or {}
 local suffix=key and s["customColor"..key]and key or ""
 local red,green,blue=s["colorR"..suffix],s["colorG"..suffix],s["colorB"..suffix]
 if suffix~=""and (red==nil or green==nil or blue==nil)then red,green,blue=s.colorR,s.colorG,s.colorB end
 if type(red)=="number"and type(green)=="number"and type(blue)=="number"then return red,green,blue end
 return r or .035,g or .039,b or .052
end
-- Definitions own stored paths and refresh targets. Rendering and search consume
-- the same metadata; new settings need one declaration rather than a second index.
R.definitions={
 {page="unitframes",key="partyGrouped",section="general",label="Shared party background",description="Use one party panel. Turn off for a compact block per character.",kind="boolean",refresh="ForeverHUD"},
 {page="bags",key="autoSort",section="ruiBags",character=true,label="Auto-sort bags when opened",description="Use Blizzard sorting when the backpack opens; waits for combat to end.",kind="boolean",refresh="ForeverStyle"},
}
for _,row in ipairs({
 {"reducedMotion","Reduce RUI motion","Use immediate scrolling and static portraits; remove missing-spell pulsing."},
 {"highContrast","High-contrast backgrounds","Use dark neutral backgrounds with at least 90% background opacity. Saved colours are retained."},
 {"animatedPortraits","Animated portraits","Use live 3D portraits. Reduced motion overrides this choice."},
})do R.definitions[#R.definitions+1]={page="accessibility",key=row[1],section="accessibility",label=row[2],description=row[3],kind="boolean",refresh="Accessibility"}end
function R:Get(definition)
 local db=definition.character and ProjectRuthlessCharDB or ProjectRuthlessDB
 return (db[definition.section]or {})[definition.key]
end
function R:Set(definition,value)
 if definition.kind=="boolean"and type(value)~="boolean"then return false end
 local db=definition.character and ProjectRuthlessCharDB or ProjectRuthlessDB
 db[definition.section]=db[definition.section]or {};db[definition.section][definition.key]=value
 AUI:SettingsChanged(definition.refresh,definition.key);return true
end
