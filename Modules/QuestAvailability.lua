local _,AUI=...
local P={}
AUI:RegisterModule("QuestAvailability",P)
local eventSorts={[-404]=true,[-402]=true,[-378]=true,[-376]=true,[-375]=true,[-374]=true,[-370]=true,[-369]=true,[-366]=true,[-364]=true,[-41]=true,[-22]=true,[-21]=true,[-368]=true,[-365]=true}
local function read(fn,...)
 if type(fn)~="function"then return end
 local ok,a,b,c=pcall(fn,...)
 if ok and not(issecretvalue and (issecretvalue(a)or issecretvalue(b)or issecretvalue(c)))then return a,b,c end
end
function P:Invalidate()self.cache=nil;self.character=nil end
function P:Data()
 local source=AUI.modules.QuestPickupData
 return source and source:Get()
end
function P:Record(id)
 local data=self:Data();if not data then return end
 local faction=read(UnitFactionGroup,"player")
 return data.dynamic[faction]and data.dynamic[faction][id]or data.quests[id]
end
function P:Character()
 if self.character then return self.character end
 local data=self:Data();if not data then return end
 local _,_,race=read(UnitRace,"player");local _,_,class=read(UnitClass,"player")
 local level=read(UnitLevel,"player")
 if type(level)~="number"or type(race)~="number"or type(class)~="number"then return end
 local locations=AUI.modules.QuestLocations
 if locations then locations:ReadProfessions()end
 self.character={level=level,race=data.raceMasks[race],class=2^(class-1)}
 return self.character
end
function P:Status(id)
 local row=self:Record(id)
 if not row then return end
 if row.clientKnown==false then return {status="uncertain",reason="Not confirmed in the installed Forever quest catalogue"}end
 if self.cache and self.cache[id]then return self.cache[id]end
 if InCombatLockdown()then return {status="uncertain",reason="Availability refresh waits until combat ends"}end
 if eventSorts[row.zoneOrSort]then return {status="uncertain",reason="Event availability requires a current game offer"}end
 local c=self:Character();local locations=AUI.modules.QuestLocations
 if not c or not locations or not c.race then return {status="uncertain",reason="Character requirements unavailable"}end
 if type(row.requiredLevel)=="number"and row.requiredLevel>c.level then return {status="locked",reason="Requires level "..row.requiredLevel}end
 for _,gate in ipairs({{row.requiredRaces,c.race},{row.requiredClasses,c.class}})do
  if gate[1]and gate[1]~=0 and math.floor(gate[1]/gate[2])%2==0 then return {status="locked",reason="Quest is for another race or class"}end
 end
 local held=read(C_QuestLog and C_QuestLog.IsOnQuest,id);local completed=read(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted,id)
 if held==nil or completed==nil then return {status="uncertain",reason="Quest state is unavailable"}end
 if held or completed then return {status="locked",reason=held and "Already in quest log"or "Already completed"}end
 self.cache=self.cache or {}
 local db={Quest={Get=function(qid,key)local record=qid==id and row or self:Record(qid);return record and record[key]end}}
 local eligible,reason,unknown=locations:Eligible(id,db,c.level,c.race,c.class)
 if eligible and row.startItems and #row.sites==0 then
  locations.hasSourceRequirements=true
  eligible=false;reason="Requires a quest-starting item"
  for _,item in ipairs(row.startItems)do
   local count=read(C_Item and C_Item.GetItemCount or GetItemCount,item,false,false)
   if type(count)=="number"and count>0 then eligible=true;reason=nil;break end
  end
 end
 local result={status=eligible and "available"or unknown and "uncertain"or "locked",reason=reason or "Pickup requirements met"}
 self.cache[id]=result;return result
end
function P:Maps(input)
 local maps,seen={},{}
 local function add(map)if type(map)=="number"and not seen[map]then maps[#maps+1]=map;seen[map]=true end end
 for _,map in ipairs(input)do
  add(map)
  self.children=self.children or {}
  if not self.children[map]then self.children[map]=read(C_Map and C_Map.GetMapChildrenInfo,map,nil,true)or {}end
  for _,child in ipairs(self.children[map])do add(child.mapID)end
 end
 return maps
end
function P:OnMap(row,map)
 for _,site in ipairs(row.sites)do if site[1]==map then return true end end
 local data=self:Data()
 return #row.sites==0 and row.startItems and data.maps[row.zoneOrSort]==map
end
function P:Visible(id)
 local settings=ProjectRuthlessDB.mapQuests or {}
 return not(settings.showTrivial==false and read(C_QuestLog and C_QuestLog.IsQuestTrivial,id)==true)
  and not(settings.showAccountCompleted==false and read(C_QuestLog and C_QuestLog.IsQuestFlaggedCompletedOnAccount,id)==true)
end
function P:Offers(maps)
 local result,seen={},{}
 if not WorldMapFrame or read(WorldMapFrame.IsShown,WorldMapFrame)~=true then
  local source=AUI.modules.QuestPickupData
  if not source or not source.data then return result end
  maps={read(C_Map and C_Map.GetBestMapForUnit,"player")}
 end
 local data=self:Data();if not data then return result end
 local settings=ProjectRuthlessDB.mapQuests or {}
 for _,map in ipairs(self:Maps(maps))do for _,id in ipairs(data.byMap[map]or {})do if not seen[id]and self:OnMap(self:Record(id),map)then
  seen[id]=true
  local status=self:Status(id)
  if status and status.status=="available"then
   local row=self:Record(id)
   if self:Visible(id)then
    result[#result+1]={id=id,title=row.name,level=row.questLevel,accept=true,availability="available",reason=status.reason,source="catalogue",sites=row.sites}
   end
  end
 end end end
 return result
end
function P:Browse(map,query)
 local data=self:Data();local rows={};if not data then return rows end
 query=(query or ""):lower()
 local seen={}
 for _,zone in ipairs(self:Maps({map}))do for _,id in ipairs(data.byMap[zone]or {})do if not seen[id]and self:OnMap(self:Record(id),zone)then
  seen[id]=true
  local row=self:Record(id);local status=self:Status(id)
  local match=tostring(id)==query or (row.name or ""):lower():find(query,1,true)
  if not match then for _,site in ipairs(row.sites)do if site[4]:lower():find(query,1,true)then match=true;break end end end
  if match and status and status.status=="available"and self:Visible(id)then rows[#rows+1]={id=id,row=row}end
 end end end
 local dataModule=AUI.modules.QuestData
 local byID,visibleMaps={},{}
 for _,entry in ipairs(rows)do byID[entry.id]=entry end
 for _,zone in ipairs(self:Maps({map}))do visibleMaps[zone]=true end
 for id,offer in pairs(dataModule and dataModule.nativeOffers or {})do
  if offer.source~="catalogue"and visibleMaps[offer.map]and (tostring(id)==query or offer.title:lower():find(query,1,true))then
   local sites={}
   if type(offer.x)=="number"and type(offer.y)=="number"then sites[1]={offer.map,offer.x,offer.y,"Game quest offer"}end
   local entry=byID[id]
   if entry then entry.row={name=offer.title,questLevel=offer.level,sites=sites}
   else rows[#rows+1]={id=id,row={name=offer.title,questLevel=offer.level,sites=sites}}end
  end
 end
 table.sort(rows,function(a,b)if (a.row.questLevel or 0)~=(b.row.questLevel or 0)then return (a.row.questLevel or 0)<(b.row.questLevel or 0)end;return a.row.name<b.row.name end)
 return rows
end
function P:HideBrowser()
 if self.search then self.search:Hide();self.search:ClearFocus()end
 if self.buttons then for _,button in ipairs(self.buttons)do button:Hide()end end
end
function P:Render(q)
 if self.buttons then for _,button in ipairs(self.buttons)do button:Hide()end end
 q.mapCopy:SetText("")
 for _,control in ipairs(q.mapControls or {})do control:Hide()end
 local map=read(WorldMapFrame.GetMapID,WorldMapFrame)
 local rows=self:Browse(map,self.query)
 if map~=self.browseMap or self.query~=self.browseQuery then
  if q.mapScroll.ScrollTo then q.mapScroll:ScrollTo(0,true)else q.mapScroll:SetVerticalScroll(0)end
  self.browseMap=map;self.browseQuery=self.query
 end
 q.mapHeading:SetText("Available quests · "..#rows)
 q.mapScroll:ClearAllPoints();q.mapScroll:SetPoint("TOPLEFT",12,-76);q.mapScroll:SetPoint("BOTTOMRIGHT",-30,12)
 if not self.search then
  local search=CreateFrame("EditBox",nil,q.mapPanel,"InputBoxTemplate");self.search=search
  search:SetAutoFocus(false);search:SetFontObject("GameFontHighlightSmall");search:SetHeight(22)
  search:SetPoint("TOPLEFT",18,-40);search:SetPoint("RIGHT",q.mapPanel,"RIGHT",-18,0)
  search:SetScript("OnEscapePressed",function(box)box:ClearFocus()end)
  search:SetScript("OnTextChanged",function(box,user)
   if user then self.query=box:GetText();self:Render(q)end
  end)
  search:SetText(self.query or "")
  if AUI.modules.Accessibility then AUI.modules.Accessibility:RegisterText(search)end
 end
 self.search:Show()
 self.buttons=self.buttons or {}
 local width=math.max(100,q.mapContent:GetWidth())
 if #rows==0 then
  local id=tonumber(self.query);local status=id and self:Status(id)
  local reason=id and (status and status.reason or "No pickup metadata recorded for quest #"..id)or "No available pickups match this map and search."
  q.mapCopy:SetText(reason.."\n\nSearch by quest, quest giver or quest ID. Completed quests and unmet level, race, class and prerequisite requirements are excluded.\n\nCatalogue gaps remain explicit in Help & diagnostics.")
 end
 for i,entry in ipairs(rows)do
  local row,id=entry.row,entry.id
  local button=self.buttons[i]
  if not button then button=AUI:CreateButton(q.mapContent);self.buttons[i]=button end
  local site
  for _,p in ipairs(row.sites)do if p[1]==map then site=p;break end end
  site=site or row.sites[1]
  button:ClearAllPoints();button:SetPoint("TOPLEFT",0,-(i-1)*54);button:SetSize(width,50)
  button:SetText(("[%s] %s\n%s"):format(row.questLevel or "?",row.name,site and (site[4]..(" · %.1f, %.1f"):format(site[2]*100,site[3]*100))or row.startItems and "Quest-starting item · location not recorded"or "Pickup location not supplied"))
  button:SetScript("OnClick",function()
   if q:LinkQuestToChat(id)then return end
   q.manualFocus=true;q.manualTrackedQuest=id;q.selected=id
   q.manualPickup={id=id,title=row.name,level=row.questLevel,accept=true,availability="available",detail=site and ("Pick up · "..site[4])or "Use quest-starting item"}
   local locations=AUI.modules.QuestLocations
   if locations then locations.selectedQuest=id;locations:Refresh(q,true)end
   q:Refresh()
   if site and not InCombatLockdown()and UiMapPoint and C_Map.SetUserWaypoint then
    read(C_Map.SetUserWaypoint,UiMapPoint.CreateFromCoordinates(site[1],site[2],site[3]))
   end
  end)
  button:SetScript("OnEnter",function()
   if not GameTooltip then return end
   GameTooltip:SetOwner(button,"ANCHOR_LEFT");GameTooltip:SetText(row.name)
   GameTooltip:AddLine("Quest #"..id.." · minimum level "..(row.requiredLevel or "?"),.8,.8,.8)
   GameTooltip:AddLine("Click to follow pickup · Shift-click to link",.7,.8,1);GameTooltip:Show()
  end)
  button:SetScript("OnLeave",function()if GameTooltip then GameTooltip:Hide()end end);button:Show()
 end
 q.mapContent:SetHeight(math.max(220,#rows*54))
end
