local _,AUI=...
local D={mapping={},nativeOffers={},requested={}}
AUI:RegisterModule("QuestData",D)
local function read(fn,...)
 if type(fn)~="function"then return end
 local ok,a,b,c=pcall(fn,...)
 if ok and not(issecretvalue and (issecretvalue(a)or issecretvalue(b)or issecretvalue(c)))then return a,b,c end
end
local function field(row,key)return row and read(function()return row[key]end)end
function D:ResolveMaps(routes)
 local map=read(C_Map and C_Map.GetBestMapForUnit,"player")
 local info=map and read(C_Map.GetMapInfo,map)
 local root=map
 for _=1,10 do
  if not info or not field(info,"parentMapID")or info.parentMapID==0 then break end
  root=info.parentMapID;info=read(C_Map.GetMapInfo,root)
 end
 if root==self.mapRoot then return end;self.mapRoot=root
 local children=root and read(C_Map.GetMapChildrenInfo,root,nil,true)or {}
 local names={}
 for _,entry in ipairs(children or {})do
  local name,id,kind=field(entry,"name"),field(entry,"mapID"),field(entry,"mapType")
  if name and id and (kind==3 or kind==4)then if names[name]~=nil then names[name]=false else names[name]=id end end
 end
 for _,route in ipairs(routes)do
  local name=read(C_Map.GetAreaInfo,route.area)or route.name
  if names[name]then self.mapping[route.area]=names[name]end
 end
 self.mapNames=names
end
function D:MapForArea(area,name)
 self:GetDatabase()
 local localized=read(C_Map and C_Map.GetAreaInfo,area)or name
 local map=self.mapping[area]or self.mapNames and self.mapNames[localized]
 if map then self.mapping[area]=map end;return map
end
function D:GetDatabase()
 local guides=AUI.modules.AuthoredGuides
 if not guides then return end
 local routes=guides:Catalog();self:ResolveMaps(routes)
 if self.database then return self.database end
 local records,factions,ids={},{},{}
 for id,fact in pairs(guides.facts or {})do
  id=tonumber(id);records[id]={name=fact.title,requiredLevel=fact.min,questLevel=fact.level};ids[#ids+1]=id
 end
 for _,route in ipairs(routes)do for _,hub in ipairs(route.hubs)do for _,id in ipairs(hub.quests)do
  local row=records[id]
  if row then row.zoneOrSort=row.zoneOrSort or route.area;factions[id]=factions[id]or {};factions[id][route.faction]=true end
 end end end
 local dungeons={}
 for _,chain in ipairs(AUI.CreateQuestProgression and AUI.CreateQuestProgression()or {})do
  if chain.kind=="dungeon"then dungeons[chain.areaID]={chain.name,{}}end
  for _,node in ipairs(chain.nodes)do
   if not records[node.id]then records[node.id]={name=node.title,requiredLevel=node.minLevel};ids[#ids+1]=node.id end
   if node.dungeon then records[node.id].zoneOrSort=chain.areaID end
   records[node.id].preQuestGroup=node.requires;factions[node.id]=factions[node.id]or {};factions[node.id][chain.faction]=true
   for _,parent in ipairs(node.requires or {})do
    if records[parent]then local row=records[parent];row.childQuests=row.childQuests or {};row.childQuests[#row.childQuests+1]=node.id end
   end
  end
 end
 table.sort(ids)
 self.records=records;self.factions=factions
 local db={owned=true,Quest={Get=function(id,key)return records[id]and records[id][key]end,GetAllIds=function()return ids end},Support={Get=function()return {private={areaIdToUiMapId=self.mapping,dungeons=dungeons}}end}}
 db.Quest.IdsByName=function(name)
  local result={};for _,id in ipairs(ids)do if records[id].name==name then result[#result+1]=id end end;return result
 end
 db.Offers=function()return self:Offers()end
 db.Status=function(id)return self:Status(id)end
 db.Points=function(quests,selected,guide)return self:Points(quests,selected,guide)end
 self.database=db;return db
end
function D:Offers()
 local map=read(C_Map and C_Map.GetBestMapForUnit,"player")
 local maps={};if map then maps[map]=true end
 local displayed=WorldMapFrame and read(WorldMapFrame.GetMapID,WorldMapFrame)
 if displayed then maps[displayed]=true end
 local settings=ProjectRuthlessDB.mapQuests or {}
 local rows,seen={},{};self.nativeOffers={}
 for mapID in pairs(maps)do
  if not self.requested[mapID]and C_QuestLine and C_QuestLine.RequestQuestLinesForMap then self.requested[mapID]=true;read(C_QuestLine.RequestQuestLinesForMap,mapID)end
  for _,offer in ipairs(read(C_QuestLine and C_QuestLine.GetAvailableQuestLines,mapID)or {})do
   local id,name=field(offer,"questID"),field(offer,"questName")
   if type(id)=="number"and id>0 and type(name)=="string"and not seen[id]and field(offer,"inProgress")==false
    and field(offer,"isHidden")==false and (field(offer,"isLocalStory")~=true or settings.showLocalStories~=false)
    and (field(offer,"isAccountCompleted")~=true or settings.showAccountCompleted==true)then
    seen[id]=true
    local start=field(offer,"startMapID");if type(start)~="number"or start<=0 then start=mapID end
    local row={id=id,title=name,accept=true,availability="available",map=start,x=field(offer,"x"),y=field(offer,"y")}
    rows[#rows+1]=row;self.nativeOffers[id]=row
   end
  end
 end
 table.sort(rows,function(a,b)return a.id<b.id end);return rows
end
function D:Status(id)
 local held=read(C_QuestLog and C_QuestLog.IsOnQuest,id)
 local completed=read(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted,id)
 if held==true then return {status="locked",reason="Already in quest log"}end
 if completed==true then return {status="locked",reason="Already completed"}end
 if held==nil or completed==nil then return {status="uncertain",reason="Quest state is unavailable; confirm with the quest giver"}end
 local row=self.records and self.records[id]
 local level=read(UnitLevel,"player")
 if row and level and row.requiredLevel and row.requiredLevel>level then return {status="locked",reason="Requires level "..row.requiredLevel}end
 local faction=read(UnitFactionGroup,"player")
 if self.factions and self.factions[id]and faction and not self.factions[id][faction]then return {status="locked",reason="Quest is for another faction"}end
 for _,required in ipairs(row and row.preQuestGroup or {})do
  local completed=read(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted,required)
  if completed==false then return {status="locked",reason="Complete prerequisite quest "..required}end
  if completed~=true then return {status="uncertain",reason="Prerequisite completion could not be verified"}end
 end
 if self.nativeOffers[id]then return {status="available",reason="Advertised by the native quest-offer feed"}end
 return {status="uncertain",reason="Pickup requirements not recorded; confirm with the quest giver"}
end
function D:Points(quests,selected,guide)
 local points,seen={},{}
 local function append(id,title,accept,complete)
  if seen[id]then return end;seen[id]=true
  local offer=accept and self.nativeOffers[id]
  local map,x,y=offer and offer.map,offer and offer.x,offer and offer.y
  if not map then map,x,y=read(C_QuestLog and C_QuestLog.GetNextWaypoint,id)end
  if type(map)=="number"and map>0 and type(x)=="number"and type(y)=="number"and x>=0 and x<=1 and y>=0 and y<=1 then
   points[#points+1]={questID=id,quest=title,name=title,map=map,x=x,y=y,current=id==selected,kind=accept and "Accept"or complete and "Turn in"or "Native"}
  end
 end
 for _,entry in ipairs(quests or {})do append(entry.id,entry.title,entry.accept,entry.complete)end
 if guide and guide.id then append(guide.id,guide.quest,true)end
 for _,entry in pairs(self.nativeOffers)do append(entry.id,entry.title,true)end
 return points
end
function D:Checks()
 return {{status="INFO",message="Quest data uses native offers/waypoints and RUI-authored routes. Full spawn, pickup-gate and dungeon-location coverage is not bundled; missing information stays unverified.",setting="Map > Library / quest details"}}
end
