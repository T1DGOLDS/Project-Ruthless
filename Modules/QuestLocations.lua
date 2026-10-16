local _, AUI = ...
local L={pool={}}
AUI:RegisterModule("QuestLocations",L)
local function Read(fn,...)
    if type(fn)~="function" then return end
    local ok,value=pcall(fn,...)
    if ok and not (issecretvalue and issecretvalue(value)) then return value end
end
function L:Database()
    local data=AUI.modules.QuestData
    return data and data:GetDatabase()
end
function L:Build(quests,selected,guide)
    local db=self:Database()
    if not db then return {} end
    if db.Points then self.mapping=AUI.modules.QuestData.mapping;return db.Points(quests,selected,guide)end
    if self.mappingDB~=db then
        self.locationCache={}
        local zones=Read(db.Support and db.Support.Get,"ZoneDB")
        local private=zones and zones.private or {}
        self.mapping={}
        for area,map in pairs(private.areaIdToUiMapId or {}) do self.mapping[area]=map end
        for area,map in pairs(private.areaIdToUiMapIdOverride or {}) do self.mapping[area]=map end
        self.mappingDB=db
    end
    local mapping=self.mapping
    local points,seen={},{}
    local objectiveID,objectiveType
    local function addSpawns(spawns,name,kind,quest)
        for area,coords in pairs(spawns or {}) do
            local map=mapping[area]
            if type(map)=="number" then
                for _,coord in ipairs(coords) do
                    local x,y=coord[1],coord[2]
                    -- Database points are already Forever coordinates; no second projection.
                    if type(x)=="number" and type(y)=="number" and x>=0 and y>=0 and x<=100 and y<=100 then
                        local key=quest.id..":"..kind..":"..map..":"..x..":"..y
                        if not seen[key] then
                            seen[key]=true
                            points[#points+1]={map=map,x=x/100,y=y/100,name=name,kind=kind,questID=quest.id,quest=quest.title,current=quest.id==selected,phase=coord[3],objectiveID=objectiveID,objectiveType=objectiveType}
                        end
                    end
                end
            end
        end
    end
    local function entity(kind,id,quest,role)
        local data=db[kind]
        if not data then return end
        addSpawns(Read(data.Get,id,"spawns"),Read(data.Get,id,"name") or tostring(id),role or kind,quest)
    end
    local function item(id,quest,visited)
        visited=visited or {}; if visited[id] then return end;visited[id]=true
        local data=db.Item
        if not data then return end
        for _,npc in ipairs(Read(data.Get,id,"npcDrops") or {}) do entity("Npc",npc,quest,"Collect") end
        for _,obj in ipairs(Read(data.Get,id,"objectDrops") or {}) do entity("Object",obj,quest,"CollectObject") end
        for _,npc in ipairs(Read(data.Get,id,"vendors") or {}) do entity("Npc",npc,quest,"Vendor") end
        for _,container in ipairs(Read(data.Get,id,"itemDrops") or {}) do item(container,quest,visited) end
    end
    local function actors(list,quest,role)
        for _,id in ipairs(list[1] or {}) do entity("Npc",id,quest,role) end
        for _,id in ipairs(list[2] or {}) do entity("Object",id,quest,role) end
    end
    local all={};for _,quest in ipairs(quests) do all[#all+1]=quest end
    if guide and guide.id then
        local found=false;for _,quest in ipairs(all) do if quest.id==guide.id then found=true end end
        if not found then all[#all+1]={id=guide.id,title=guide.quest,accept=true} end
    end
    local active={}
    for _,quest in ipairs(all) do active[quest.id]=true end
    for _,quest in ipairs(self.offers or {}) do if not active[quest.id] then all[#all+1]=quest end end
    for _,quest in ipairs(all) do
        objectiveID=nil;objectiveType=nil
        local allowed=true
        if quest.accept and not quest.availability then
            local eligible,reason,unknown=self:PlayerEligibility(quest.id,db)
            allowed=eligible or unknown
            quest.availability=unknown and "unknown" or "available";quest.reason=reason
        end
        if allowed then
        local cacheKey=quest.id..":"..(quest.accept and "accept" or quest.complete and "complete" or "objectives")
        local cached=self.locationCache[cacheKey]
        local first=#points+1
        if cached then
            for _,source in ipairs(cached) do
                local point={}
                for key,value in pairs(source) do point[key]=value end
                point.quest=quest.title;point.current=quest.id==selected;point.availability=quest.availability;point.reason=quest.reason
                points[#points+1]=point
            end
        elseif quest.accept or quest.complete then
            actors(Read(db.Quest.Get,quest.id,quest.accept and "startedBy" or "finishedBy") or {},quest,quest.accept and "Accept" or "Turn in")
        else
            local objectives=Read(db.Quest.Get,quest.id,"objectives") or {}
            for _,row in ipairs(objectives[1] or {}) do objectiveID=row[1];objectiveType="monster";entity("Npc",row[1],quest) end
            for _,row in ipairs(objectives[2] or {}) do objectiveID=row[1];objectiveType="object";entity("Object",row[1],quest) end
            for _,row in ipairs(objectives[3] or {}) do objectiveID=row[1];objectiveType="item";item(row[1],quest) end
            objectiveID=nil;objectiveType=nil
            for _,row in ipairs(objectives[5] or {}) do for _,id in ipairs(row[1] or {}) do entity("Npc",id,quest) end end
            local trigger=Read(db.Quest.Get,quest.id,"triggerEnd")
            if trigger then addSpawns(trigger[2],trigger[1] or "Objective area","Area",quest) end
        end
        for i=first,#points do points[i].availability=quest.availability;points[i].reason=quest.reason end
        if not cached then
            local sources={}
            for i=first,#points do sources[#sources+1]=points[i] end
            self.locationCache[cacheKey]=sources
        end
        end
    end
    table.sort(points,function(a,b) if a.current~=b.current then return a.current end;return a.questID<b.questID end)
    return points
end
function L:PointKey(p)
    return table.concat({p.questID,p.kind,p.map,p.x,p.y},":")
end
function L:Clear()
    if self.direction then self.direction:Hide()end
    self.points={}
    self.activeMini={};self.freeMini={}
    for _,pair in ipairs(self.pool)do self.freeMini[#self.freeMini+1]=pair end
    self.activeWorld={};self.freeWorld={}
    for _,icon in ipairs(self.worldPool or {})do self.freeWorld[#self.freeWorld+1]=icon end
    if self.pins then self.pins:RemoveAllWorldMapIcons(self);self.pins:RemoveAllMinimapIcons(self) end
    for _,pair in ipairs(self.pool) do if pair.world then pair.world:Hide() end;pair.mini:Hide() end
    for _,icon in ipairs(self.worldPool or {})do icon:Hide()end
    for _,texture in ipairs(self.areaPool or {})do texture:Hide()end
end
function L:Icon(parent)
    local icon=CreateFrame("Frame",nil,parent)
    icon.worldMarker=false;icon:EnableMouse(false);icon:SetSize(14,14)
    icon.texture=icon:CreateTexture(nil,"ARTWORK");icon.texture:SetAllPoints()
    return icon
end
-- Shared visual vocabulary for map spawn markers and nameplate hints.
function L:ObjectiveTexture(kind)
    local textures={loot="Interface\\Icons\\INV_Misc_Bag_10",kill="Interface\\Icons\\INV_Sword_04",interact="Interface\\Cursor\\Interact"}
    return textures[kind]
end
function L:ObjectiveMarkers(points)
    local markers,objectives,seen={},{},{}
    for _,p in ipairs(points or {})do
        local kind=p.kind=="Collect"and "loot"or (p.kind=="Object"or p.kind=="CollectObject")and "interact"or p.kind=="Npc"and "kill"
        if kind and p.objectiveID and p.objectiveType then
            if not objectives[p.questID]then objectives[p.questID]=Read(C_QuestLog.GetQuestObjectives,p.questID)or {}end
            local active=false
            for _,o in ipairs(objectives[p.questID])do
                local id=Read(function()return o.objectID end)
                local finished=Read(function()return o.finished end)
                local objectiveType=Read(function()return o.type end)
                if id==p.objectiveID and finished==false and objectiveType==p.objectiveType then active=true;break end
            end
            local key=p.questID..":"..kind..":"..p.map..":"..p.x..":"..p.y
            if active and not seen[key]then
                seen[key]=true;local marker={};for k,v in pairs(p)do marker[k]=v end
                marker.markerKind=kind;markers[#markers+1]=marker
            end
        end
    end
    return markers
end
function L:StyleIndicator(icon,p,world)
    local symbol=p.kind=="Accept"or p.kind=="Turn in"
    local size=p.markerKind and (world and 14 or 12)or symbol and (world and 20 or 15)or (world and (p.current and 18 or 13)or (p.current and 10 or 7))
    icon:SetSize(size,size)
    icon.texture:SetTexture(p.markerKind and self:ObjectiveTexture(p.markerKind)or p.kind=="Turn in"and "Interface\\GossipFrame\\ActiveQuestIcon"or p.kind=="Accept"and "Interface\\GossipFrame\\AvailableQuestIcon"or "Interface\\AddOns\\ProjectRuthless\\Assets\\QuestObjective")
    icon.texture:SetDesaturated(p.availability=="unknown")
    icon.texture:SetVertexColor(1,1,1);icon:SetAlpha(p.availability=="unknown"and .45 or p.current and 1 or .7)
end
function L:DirectionPoint(points)
    local map=C_Map and Read(C_Map.GetBestMapForUnit,"player")
    if not map then return end
    local pos=Read(C_Map.GetPlayerMapPosition,map,"player")
    local px,py
    if pos then local ok,x,y=pcall(pos.GetXY,pos);if ok and not(issecretvalue and (issecretvalue(x)or issecretvalue(y)))then px,py=x,y end end
    local best,distance
    for _,point in ipairs(points or {})do
        if point.current and (not map or point.map==map)then
            local d=type(px)=="number"and type(py)=="number"and (point.x-px)^2+(point.y-py)^2 or 0
            if not best or d<distance then best=point;distance=d end
        end
    end
    return best
end
function L:UpdateDirection(point)
    if self.direction then self.pins:RemoveMinimapIcon(self,self.direction);self.direction:Hide()end
    if not point then return end
    if not self.direction then
        local icon=self:Icon(Minimap);self.direction=icon;icon:SetSize(18,18)
        icon.texture:SetTexture("Interface\\Minimap\\MinimapArrow");icon.texture:SetVertexColor(.3,.7,1)
        hooksecurefunc(icon,"SetPoint",function(_,anchor,relative,relativePoint,x,y)
            if relative~=Minimap then return end
            local width,height=Read(Minimap.GetWidth,Minimap),Read(Minimap.GetHeight,Minimap)
            if not width or not height or width<=0 or height<=0 or (issecretvalue and (issecretvalue(x)or issecretvalue(y)))or type(x)~="number"or type(y)~="number"then return end
            local nx,ny=math.abs(x)/(width/2),math.abs(y)/(height/2)
            local shape=Read(GetMinimapShape)or "ROUND"
            local edge=(shape=="SQUARE"and math.max(nx,ny)or math.sqrt(nx*nx+ny*ny))>=.89
            icon.texture:SetAlpha(edge and 1 or 0)
            if edge then icon.texture:SetRotation((math.atan2 or math.atan)(y,x)-math.pi/2)end
        end)
    end
    self.direction.point=point;self.direction.texture:SetAlpha(0)
    self.pins:AddMinimapIconMap(self,self.direction,point.map,point.x,point.y,true,true)
end
function L:Refresh(q,force)
    local enabled=ProjectRuthlessDB.questWorkspace.enabled
    local signature=tostring(q.entriesSignature)..":"..tostring(enabled)..":"..tostring(self.selectedQuest or (q.guide and q.guide.id or q.selected))
    for _,entry in ipairs(q.entries or {}) do signature=signature..":"..entry.id..":"..tostring(entry.complete) end
    local guideIDs={}
    for id,active in pairs(q.guide and q.guide.questIDs or {})do if active then guideIDs[#guideIDs+1]=id end end
    table.sort(guideIDs)
    for _,id in ipairs(guideIDs)do signature=signature..":guide:"..id end
    for _,offer in ipairs(self.offers or {})do signature=signature..":offer:"..offer.id..":"..tostring(offer.availability)..":"..tostring(offer.reason) end
    if not force and self.signature==signature then return end
    self.signature=signature
    if not enabled then self:Clear();return end
    local pins=AUI.modules.MapPins
    self.pins=pins
    if not pins or not self:Database() then self.signature=nil;return end
    self.points=self:Build(q.entries or {},self.selectedQuest or (q.guide and q.guide.id or q.selected),q.guide)
    local _,class=UnitClass("player");local color=RAID_CLASS_COLORS[class] or {r=.7,g=.7,b=1}
    self.activeMini=self.activeMini or {};self.freeMini=self.freeMini or {}
    local desired={}
    local miniPoints=self:ObjectiveMarkers(self.points)
    for _,p in ipairs(miniPoints)do desired[self:PointKey(p)]=true end
    for _,p in ipairs(self.points)do if p.kind=="Accept"or p.kind=="Turn in"then miniPoints[#miniPoints+1]=p;desired[self:PointKey(p)]=true end end
    for key,pair in pairs(self.activeMini)do
        if not desired[key]then self.pins:RemoveMinimapIcon(self,pair.mini);pair.mini:Hide();self.activeMini[key]=nil;self.freeMini[#self.freeMini+1]=pair end
    end
    for _,p in ipairs(miniPoints) do
        local key=self:PointKey(p)
        local pair=self.activeMini[key]
        local fresh=not pair
        if not pair then
            pair=table.remove(self.freeMini)
            if not pair then pair={mini=self:Icon(Minimap)};self.pool[#self.pool+1]=pair end
            self.activeMini[key]=pair
        end
        for _,icon in pairs(pair) do
            icon.point=p;self:StyleIndicator(icon,p,false)
        end
        if fresh then pins:AddMinimapIconMap(self,pair.mini,p.map,p.x,p.y,true,false)end
    end
    self:UpdateDirection(self:DirectionPoint(self.points))
    self:DrawAreas()
end

-- Compact world-map summaries retain one actual recorded point per type/quest/zone.
function L:WorldMarkers(points)
    local groups={}
    for _,p in ipairs(points or {}) do
        local kind=p.kind=="Turn in" and "Turn in" or p.kind=="Accept" and "Accept" or (p.kind=="Object" or p.kind=="Collect" or p.kind=="CollectObject" or p.kind=="Vendor") and "Collect" or p.kind=="Npc" and "Kill" or "Area"
        local key=p.questID..":"..p.map..":"..kind
        local group=groups[key]
        if not group then group={points={},x=0,y=0,kind=kind};groups[key]=group end
        group.points[#group.points+1]=p;group.x=group.x+p.x;group.y=group.y+p.y
    end
    local markers={}
    for _,group in pairs(groups) do
        local x,y=group.x/#group.points,group.y/#group.points
        local best,nearest
        for _,p in ipairs(group.points) do
            local distance=(p.x-x)^2+(p.y-y)^2
            if not nearest or distance<nearest then best,nearest=p,distance end
        end
        local marker={};for k,v in pairs(best)do marker[k]=v end
        marker.kind=group.kind;markers[#markers+1]=marker
    end
    table.sort(markers,function(a,b)if a.questID~=b.questID then return a.questID<b.questID end;if a.map~=b.map then return a.map<b.map end;return a.kind<b.kind end)
    return markers
end
function L:DrawAreas()
    -- Kept as the map-refresh entry point; there is no shaded overlay now.
    if not self.pins or not ProjectRuthlessDB.questWorkspace.enabled then return end
    self.worldPool=self.worldPool or {}
    self:DrawSelectedArea()
    self.activeWorld=self.activeWorld or {};self.freeWorld=self.freeWorld or {}
    local markers=self:ObjectiveMarkers(self.points)
    local nativeLocations={}
    for _,point in ipairs(self:WorldMarkers(self.points))do
        local key=point.questID..":"..point.map
        if nativeLocations[key]==nil then
            local native=false
            if C_QuestLog and type(C_QuestLog.GetNextWaypointForMap)=="function"then
                local ok,x,y=pcall(C_QuestLog.GetNextWaypointForMap,point.questID,point.map)
                native=ok and not(issecretvalue and (issecretvalue(x)or issecretvalue(y)))and type(x)=="number"and type(y)=="number"
            end
            nativeLocations[key]=native
        end
        if point.kind=="Accept"or point.kind=="Turn in"and not nativeLocations[key]then markers[#markers+1]=point end
    end
    local desired={}
    for _,p in ipairs(markers)do desired[self:PointKey(p)]=true end
    for key,icon in pairs(self.activeWorld)do
        if not desired[key]then self.pins:RemoveWorldMapIcon(self,icon);icon:Hide();self.activeWorld[key]=nil;self.freeWorld[#self.freeWorld+1]=icon end
    end
    for _,p in ipairs(markers)do
        local key=self:PointKey(p);local icon=self.activeWorld[key];local fresh=not icon
        if not icon then
            icon=table.remove(self.freeWorld)
            if not icon then icon=self:Icon(WorldMapFrame);icon.worldMarker=true;self.worldPool[#self.worldPool+1]=icon end
            self.activeWorld[key]=icon
        end
        icon.point=p;self:StyleIndicator(icon,p,true)
        if fresh then self.pins:AddWorldMapIconMap(self,icon,p.map,p.x,p.y,0)end
    end
end

function L:AreaCells(points,map)
    local cells,seen={},{}
    for _,p in ipairs(points or {})do
        if p.current and p.map==map and p.kind~="Turn in" and p.kind~="Accept" then
            local x,y=math.min(23,math.floor(p.x*24)),math.min(23,math.floor(p.y*24))
            local key=x..":"..y
            if not seen[key]then seen[key]=true;cells[#cells+1]={x=x/24,y=y/24,size=1/24}end
        end
    end
    return cells
end
function L:DrawSelectedArea()
    -- Objective areas belong to the native blue-circle provider.
    for _,texture in ipairs(self.areaPool or {})do texture:Hide()end
    self.areaDrawPoints=nil
end


function L:DungeonCatalog(q)
    local db=self:Database();if not db then return {}end
    if self.dungeonCache and self.dungeonCacheEntries==q.entries and self.dungeonCacheOffers==self.offers and self.dungeonCacheDB==db then return self.dungeonCache end
    local zones=Read(db.Support.Get,"ZoneDB")
    local all={};for _,entry in ipairs(q.entries or {})do all[#all+1]=entry end
    for _,entry in ipairs(self.offers or {})do all[#all+1]=entry end
    -- Resolve relationships once per quest, rather than once per dungeon.
    local questAreas={}
    for _,entry in ipairs(all)do
        if not questAreas[entry.id]then
            local areas={};questAreas[entry.id]=areas
            local own=Read(db.Quest.Get,entry.id,"zoneOrSort");if own then areas[own]=true end
            local target=Read(db.Quest.Get,entry.id,"breadcrumbForQuestId")
            if not target or target==0 then target=Read(db.Quest.Get,entry.id,"nextQuestInChain")end
            if target and target~=0 then local area=Read(db.Quest.Get,target,"zoneOrSort");if area then areas[area]=true end end
            for _,child in ipairs(Read(db.Quest.Get,entry.id,"childQuests")or {})do
                local area=Read(db.Quest.Get,child,"zoneOrSort");if area then areas[area]=true end
            end
        end
    end
    local result={}
    for area,dungeon in pairs(zones and zones.private and zones.private.dungeons or {})do
        local areas={[area]=true};for _,alias in ipairs(dungeon[2] or {})do areas[alias]=true end
        local group={area=area,name=dungeon[1],zone=dungeon[3],entries={},held=0,pickups=0}
        local seen={}
        for _,entry in ipairs(all)do
            local related=false
            for candidate in pairs(questAreas[entry.id])do if areas[candidate]then related=true;break end end
            if related and not seen[entry.id]then
                seen[entry.id]=true;group.entries[#group.entries+1]=entry
                if entry.accept then group.pickups=group.pickups+1 else group.held=group.held+1 end
            end
        end
        if #group.entries>0 then result[#result+1]=group end
    end
    table.sort(result,function(a,b)if a.held~=b.held then return a.held>b.held end;return a.name<b.name end)
    self.dungeonCache=result;self.dungeonCacheEntries=q.entries;self.dungeonCacheOffers=self.offers;self.dungeonCacheDB=db
    return result
end
function L:DungeonRows(q)
    local rows={}
    for _,group in ipairs(self:DungeonCatalog(q))do
        if (q.trackedDungeons and q.trackedDungeons[group.area]) or q.tripArea==group.area then
            for _,entry in ipairs(group.entries)do
                local row={};for key,value in pairs(entry)do row[key]=value end
                row.dungeon=group.name;row.detail=entry.accept and entry.availability=="unknown" and "Uncertain · "..(entry.reason or "check requirements") or (entry.accept and "Pick up · " or "In log · ")..(entry.detail or group.name)
                row.point=self:Destination(entry.id);rows[#rows+1]=row
            end
        end
    end
    return rows
end

function L:TripRecommendations(q)
    local db=self:Database();if not db then return {}end
    local zones=Read(db.Support.Get,"ZoneDB")
    local trips={}
    for area,dungeon in pairs(zones and zones.private and zones.private.dungeons or {})do
        local areas={[area]=true};for _,alias in ipairs(dungeon[2] or {})do areas[alias]=true end
        local count=0
        for _,quest in ipairs(q.entries or {})do if areas[Read(db.Quest.Get,quest.id,"zoneOrSort")]then count=count+1 end end
        if count>0 then trips[#trips+1]={area=area,name=dungeon[1],count=count}end
    end
    table.sort(trips,function(a,b)if a.count~=b.count then return a.count>b.count end;return a.name<b.name end)
    return trips
end
function L:Destination(id)
    local map=Read(C_Map.GetBestMapForUnit,"player")
    local best
    for _,point in ipairs(self.points or {})do if point.questID==id and (not best or point.map==map and best.map~=map)then best=point end end
    return best
end

function L:ContextRows(q)
    local map=Read(C_Map.GetBestMapForUnit,"player")
    local inside=Read(IsInInstance)
    if q.tripArea then inside=true end
    local mapInfo=map and Read(C_Map.GetMapInfo,map)
    local instanceMap=mapInfo and mapInfo.mapType==4
    local dungeonAreas={}
    local db=self:Database()
    if inside and db then
        local zones=Read(db.Support.Get,"ZoneDB")
        local name=Read(GetRealZoneText) or Read(GetInstanceInfo)
        for area,entry in pairs(zones and zones.private and zones.private.dungeons or {})do
            if entry[1]==name then dungeonAreas[area]=true;for _,alias in ipairs(entry[2] or {})do dungeonAreas[alias]=true end end
        end
    end
    if q.tripArea then
        dungeonAreas[q.tripArea]=true
        local zones=db and Read(db.Support.Get,"ZoneDB")
        local entry=zones and zones.private and zones.private.dungeons and zones.private.dungeons[q.tripArea]
        for _,alias in ipairs(entry and entry[2] or {})do dungeonAreas[alias]=true end
    end
    local distances,nearest={},{}
    local pos=map and Read(C_Map.GetPlayerMapPosition,map,"player")
    local px,py,width,height
    if pos then local ok,x,y=pcall(pos.GetXY,pos);if ok and not (issecretvalue and (issecretvalue(x) or issecretvalue(y)))then px,py=x,y end end
    if map and C_Map.GetMapWorldSize then local ok,w,h=pcall(C_Map.GetMapWorldSize,map);if ok and not (issecretvalue and (issecretvalue(w) or issecretvalue(h)))then width,height=w,h end end
    for _,point in ipairs(self.points or {})do
        if point.map==map then
            local distance=px and py and width and height and math.sqrt(((point.x-px)*width)^2+((point.y-py)*height)^2) or math.huge
            if not distances[point.questID] or distance<distances[point.questID]then distances[point.questID]=distance;nearest[point.questID]=point end
        end
    end
    local rows={};local seen={}
    local function append(entry)
        if seen[entry.id]then return end;seen[entry.id]=true
        local dungeon=db and dungeonAreas[Read(db.Quest.Get,entry.id,"zoneOrSort")]
        if inside and (dungeon or instanceMap and distances[entry.id]) or not inside and distances[entry.id] and distances[entry.id]<=500 then
            rows[#rows+1]={id=entry.id,title=entry.title,level=entry.level,elite=entry.elite,complete=entry.complete,availability=entry.availability,accept=entry.accept,detail=entry.accept and (entry.availability=="unknown" and "Uncertain · "..(entry.reason or "check requirements") or "Pick up quest") or entry.detail or (entry.complete and "Ready to turn in" or "Dungeon objective"),point=nearest[entry.id],distance=distances[entry.id] or math.huge}
        end
    end
    for _,entry in ipairs(q.entries or {})do append(entry)end
    for _,entry in ipairs(self.offers or {})do append(entry)end
    table.sort(rows,function(a,b)if a.distance~=b.distance then return a.distance<b.distance end;return a.id<b.id end)
    return rows,inside==true
end

-- Known quest-sort categories can carry class/profession evidence.
local classSortMasks={[-81]=1,[-141]=2,[-261]=4,[-162]=8,[-262]=16,[-372]=32,[-82]=64,[-161]=128,[-61]=256,[-395]=512,[-263]=1024}
local professionSorts={[-121]=164,[-182]=165,[-181]=171,[-264]=197,[-201]=202,[-373]=755,[-371]=773,[-24]=182,[-324]=129,[-304]=185,[-101]=356,[-377]=794,[-398]=762}
function L:Eligible(id,db,level,raceMask,classMask,preparation)
    local get=db.Quest.Get
    local function field(key)return Read(get,id,key)end
    if Read(C_QuestLog.IsOnQuest,id)then return false,"Already in quest log"end
    if Read(C_QuestLog.IsQuestFlaggedCompleted,id)then return false,"Already completed"end
    local required=field("requiredLevel")
    if type(required)~="number" then return false,"Minimum level unknown",true end
    if required>level then return false,"Requires level "..required end
    local max=field("requiredMaxLevel");if max and max>0 and level>max then return false,"Maximum level "..max end
    local sort=field("zoneOrSort")
    local sortedClass=classSortMasks[sort]
    if sortedClass then
        if not classMask then return false,"Class requirement not verified",true end
        if sortedClass~=classMask then return false,"Quest is for another class"end
    end
    for _,entry in ipairs({{"requiredRaces",raceMask},{"requiredClasses",classMask}})do
        local mask=field(entry[1])
        if mask and mask~=0 and not entry[2] then return false,"Character requirement not verified: "..entry[1],true end
        if mask and mask~=0 and (not entry[2] or math.floor(mask/entry[2])%2==0)then return false,entry[1]=="requiredClasses"and "Quest is for another class"or "Race requirement not met" end
    end
    if not preparation then
    for _,quest in ipairs(field("preQuestGroup") or {})do if Read(C_QuestLog.IsQuestFlaggedCompleted,quest)~=true then return false,"Complete prerequisite quest "..quest end end
    local single=field("preQuestSingle") or {}
    if #single>0 then local met=false;for _,quest in ipairs(single)do if Read(C_QuestLog.IsQuestFlaggedCompleted,quest)==true then met=true end end;if not met then return false,"Complete one prerequisite: "..table.concat(single,", ") end end
    end
    for _,quest in ipairs(field("exclusiveTo") or {})do if Read(C_QuestLog.IsOnQuest,quest) or Read(C_QuestLog.IsQuestFlaggedCompleted,quest) then return false,"Conflicts with quest "..quest end end
    local parent=field("parentQuest");if parent and parent~=0 and Read(C_QuestLog.IsOnQuest,parent)~=true then return false,"Requires active quest "..parent end
    local from=field("availableStartingWith");if from and from~=0 and not Read(C_QuestLog.IsOnQuest,from) and not Read(C_QuestLog.IsQuestFlaggedCompleted,from) then return false,"Requires quest "..from end
    for _,key in ipairs({"availableUntilCompleted","nextQuestInChain","disabledByQuest"})do local quest=field(key);if quest and quest>0 and (Read(C_QuestLog.IsOnQuest,quest) or Read(C_QuestLog.IsQuestFlaggedCompleted,quest))then return false,"Unavailable while quest "..quest.." is active or completed" end end
    local skill=field("requiredSkill")
    if type(skill)=="table" and skill[1] and skill[1]~=0 then
        local ranks=self.professionRanks
        if not ranks then return false,"Profession requirement not verified",true end
        if not ranks[skill[1]] then return false,"Requires profession "..skill[1] end
        if ranks[skill[1]]<(skill[2] or 1) then return false,"Requires profession skill "..(skill[2] or 1) end
    elseif skill and type(skill)~="table" and skill~=0 then return false,"Profession requirement not verified",true end
    -- Category alone cannot prove a skill threshold or whether this is a learn-profession introduction.
    if professionSorts[sort]and not(type(skill)=="table"and skill[1]and skill[1]~=0)then
        return false,"Profession quest; acceptance requirements not verified",true
    end
    for _,key in ipairs({"requiredMinRep","requiredMaxRep"})do
        local gate=field(key)
        if type(gate)=="table"and next(gate)then
            local data=C_Reputation and Read(C_Reputation.GetFactionDataByID,gate[1])
            local standing=data and data.currentStanding
            if type(standing)~="number"or (issecretvalue and issecretvalue(standing))or type(gate[2])~="number"then return false,"Reputation requirement not verified",true end
            if key=="requiredMinRep"and standing<gate[2]then return false,"Requires reputation "..gate[2].." with faction "..gate[1]end
            if key=="requiredMaxRep"and standing>=gate[2]then return false,"Reputation too high with faction "..gate[1]end
        end
    end
    local sources=field("requiredSourceItems")
    if type(sources)=="table"and next(sources)then self.hasSourceRequirements=true end
    for _,item in ipairs(type(sources)=="table"and sources or {})do
        local count=Read(C_Item and C_Item.GetItemCount or GetItemCount,item,false,false)
        if type(count)~="number"then return false,"Required item not verified: "..item,true end
        if count<1 then return false,"Requires item "..item end
    end
    for _,key in ipairs({"requiredSpell","requiredSpecialization"})do
        local spell=field(key)
        if spell and spell~=0 then
            local known=Read(IsPlayerSpell or IsSpellKnown,spell)
            if known==false then return false,"Requires spell or specialization "..spell end
            if known~=true then return false,"Spell or specialization not verified: "..spell,true end
        end
    end
    for _,key in ipairs({"requiredRanks","specialFlags"})do
        local value=field(key)
        if type(value)=="table"and next(value)or type(value)=="number"and value~=0 then return false,"Requirement not verified: "..key,true end
    end
    return true
end
function L:ReadProfessions()
    if not GetProfessions or not GetProfessionInfo then self.professionRanks=nil;return end
    local ok,indices=pcall(function()return {GetProfessions()}end)
    if not ok then self.professionRanks=nil;return end
    local ranks={}
    for _,index in pairs(indices)do
        local valid,name,_,rank,_,_,_,id=pcall(GetProfessionInfo,index)
        if not valid or (issecretvalue and (issecretvalue(rank)or issecretvalue(id)))then self.professionRanks=nil;return end
        if type(id)~="number"or type(rank)~="number"then self.professionRanks=nil;return end
        ranks[id]=rank
    end
    self.professionRanks=ranks
end
-- All pickup surfaces share one cached result; only relevance filtering is surface-specific.
function L:InvalidateAvailability()
    if InCombatLockdown()or self.scanResting then self.availabilityDirty=true;return end
    self.availabilityDirty=nil
    self.availabilityRevision=(self.availabilityRevision or 0)+1
    self.availabilityCache=nil;self.characterRequirements=nil
end
function L:PlayerStatus(id,db,preparation)
    if not db then return {status="uncertain",reason="Quest database unavailable"}end
    if db.Status then return db.Status(id,preparation)end
    local character=self.characterRequirements
    if not character or character.db~=db then
        local race,class
        local ok,_,_,value=pcall(UnitRace,"player");if ok and not(issecretvalue and issecretvalue(value))then race=value end
        ok,_,_,value=pcall(UnitClass,"player");if ok and not(issecretvalue and issecretvalue(value))then class=value end
        character={db=db,level=Read(UnitLevel,"player")or 0,race=db.Enum and db.Enum.raceMaskById and db.Enum.raceMaskById[race],class=type(class)=="number"and 2^(class-1)or nil}
        self.characterRequirements=character
    end
    self.availabilityCache=self.availabilityCache or {}
    local key=tostring(id)..(preparation and ":prep"or ":pickup")
    local cached=self.availabilityCache[key]
    if cached and cached.db==db then return cached end
    if InCombatLockdown()or self.scanResting then self.scanPending=true;return {status="uncertain",reason="Confirm availability with the quest giver"}end
    local eligible,reason,unknown=self:Eligible(id,db,character.level,character.race,character.class,preparation)
    local result={db=db,status=eligible and "available"or unknown and "uncertain"or "locked",reason=reason}
    self.availabilityCache[key]=result;return result
end
function L:PlayerEligibility(id,db,preparation)
    local result=self:PlayerStatus(id,db,preparation)
    return result.status=="available",result.reason,result.status=="uncertain"
end
function L:ScanOffers()
    if not ProjectRuthlessDB.questWorkspace.enabled then return end
    if InCombatLockdown()or self.scanResting then self.scanPending=true;return end
    self.scanPending=nil
    local db=self:Database()
    if not db then return end
    if db.Offers then
        local diagnostics=AUI.modules.Diagnostics;local started=diagnostics and diagnostics:BeginWork()
        local offers=db.Offers()
        local changed=self.offers==nil or #offers~=#self.offers
        if not changed then for i,row in ipairs(offers)do local old=self.offers[i];if row.id~=old.id or row.title~=old.title or row.map~=old.map or row.x~=old.x or row.y~=old.y then changed=true;break end end end
        if changed then self:InvalidateAvailability();self.offers=offers;self:Refresh(AUI.modules.QuestWorkspace);AUI:QueueRefresh(AUI.modules.QuestWorkspace)end
        if started then diagnostics:EndWork("Native quest offers",started,#offers)end
        return
    end
    if self.scanning then self.rescanOffers=true;return end
    local level=Read(UnitLevel,"player")
    if not level then return end
    local reuse=self.offerCandidates and self.candidateDB==db and self.candidateLevel==level
    local ids=reuse and self.offerCandidates or Read(db.Quest.GetAllIds)
    if not ids then return end
    local candidates=reuse and self.offerCandidates or {}
    local _,_,race=UnitRace("player");local _,_,class=UnitClass("player")
    local bits=bit or bit32
    local raceMask=db.Enum and db.Enum.raceMaskById and db.Enum.raceMaskById[race]
    local classMask=class and 2^(class-1)
    self:ReadProfessions();self:InvalidateAvailability()
    local offers={};self.scanning=true
    local generation=self.scanGeneration or 0
    local index=1
    local function batch()
        if generation~=(self.scanGeneration or 0)then return end
        if not ProjectRuthlessDB.questWorkspace.enabled then self.scanning=nil;return end
        if InCombatLockdown()or self.scanResting then self.scanning=nil;self.scanPending=true;return end
        local started=Read(debugprofilestop)
        for i=index,math.min(#ids,index+24)do
            local id=ids[i]
            local levelEligible=reuse
            if not reuse then
                local required=Read(db.Quest.Get,id,"requiredLevel")
                local questLevel=Read(db.Quest.Get,id,"questLevel")
                levelEligible=type(required)=="number" and required<=level and (not questLevel or questLevel<=0 or questLevel<=level+5 and questLevel>=level-7)
                if levelEligible then candidates[#candidates+1]=id end
            end
            if levelEligible then
                local eligible,reason,unknown=self:PlayerEligibility(id,db)
                if eligible or unknown then offers[#offers+1]={id=id,title=Read(db.Quest.Get,id,"name")or "Quest pickup",accept=true,availability=unknown and "unknown" or "available",reason=reason}end
            end
            index=i+1
            local now=started and Read(debugprofilestop)
            if now and now-started>=2 then break end
        end
        if index<=#ids then C_Timer.After(.1,batch)
        else self.offerCandidates=candidates;self.candidateDB=db;self.candidateLevel=level;self.scanning=nil
            local changed=#offers~=#(self.offers or {})
            if not changed then for i,offer in ipairs(offers)do if offer.id~=self.offers[i].id or offer.availability~=self.offers[i].availability or offer.reason~=self.offers[i].reason then changed=true;break end end end
            if changed then self.offers=offers;self:Refresh(AUI.modules.QuestWorkspace);AUI:QueueRefresh(AUI.modules.QuestWorkspace)end
            if self.rescanOffers then self.rescanOffers=nil;C_Timer.After(1,function()self:ScanOffers()end)end end
    end
    batch()
end
function L:SelectQuest(id)
    if not ProjectRuthlessDB.questWorkspace.enabled then return end
    if type(id)~="number" or id<=0 or InCombatLockdown() then return end
    local q=AUI.modules.QuestWorkspace
    self.selectedQuest=id
    self:Refresh(q,true)
    -- Prefer the zone with the most recorded objective locations.
    local counts,best,bestCount={},nil,0
    for _,p in ipairs(self.points or {}) do
        if p.current then counts[p.map]=(counts[p.map] or 0)+1 end
    end
    for map,count in pairs(counts) do if count>bestCount or count==bestCount and (not best or map<best) then best,bestCount=map,count end end
    if not best and C_QuestLog.GetNextWaypoint then best=Read(C_QuestLog.GetNextWaypoint,id) end
    if best and WorldMapFrame and WorldMapFrame:IsShown() then
        Read(WorldMapFrame.SetMapID,WorldMapFrame,best)
    end
    self:DrawAreas()
end

function L:SetEnabled()
    local enabled=ProjectRuthlessDB.questWorkspace.enabled
    if self.events then for _,event in ipairs(self.eventNames)do if enabled then self.events:RegisterEvent(event)else self.events:UnregisterEvent(event)end end end
    if enabled and not self.enabled then
        self.enabled=true
        local generation=self.scanGeneration or 0
        C_Timer.After(1,function()if self.enabled and generation==(self.scanGeneration or 0)then self:ScanOffers()end end)
    elseif not enabled and self.enabled then
        self.scanResting=nil;self.scanPending=nil;self.combatScanRevision=(self.combatScanRevision or 0)+1
        self.enabled=false;self.scanGeneration=(self.scanGeneration or 0)+1;self.scanning=nil;self.rescanOffers=nil
    end
end

-- Index only held quests on a changed log snapshot; hovering never scans the database.
function L:UpdateTooltipIndex(q)
    if not ProjectRuthlessDB.questWorkspace.enabled then self.tooltipIndex={};self.tooltipEntries=nil;return end
    local db=self:Database()
    if not db or self.tooltipEntries==q.entries and self.tooltipDB==db then return end
    self.tooltipEntries=q.entries;self.tooltipDB=db
    local index={}
    local function add(npc,entry,item)
        index[npc]=index[npc]or {}
        local key=entry.id..":"..tostring(item or 0)
        index[npc][key]={id=entry.id,title=entry.title,item=item}
    end
    for _,entry in ipairs(q.entries or {})do
        if not entry.complete and not entry.accept then
            local objectives=Read(db.Quest.Get,entry.id,"objectives")or {}
            for _,row in ipairs(objectives[1]or {})do add(row[1],entry)end
            local visited={}
            local function drops(item)
                if visited[item]then return end;visited[item]=true
                for _,npc in ipairs(Read(db.Item.Get,item,"npcDrops")or {})do add(npc,entry,item)end
                for _,container in ipairs(Read(db.Item.Get,item,"itemDrops")or {})do drops(container)end
            end
            if db.Item then for _,row in ipairs(objectives[3]or {})do drops(row[1])end end
        end
    end
    self.tooltipIndex=index
end
function L:AddPartyProgress(tooltip,ids)
    if not ProjectRuthlessDB.questWorkspace.enabled or Read(IsInGroup)~=true or type(tooltip.AppendInfo)~="function"then return end
    for id in pairs(ids or {})do
        if type(id)=="number"and id>0 then tooltip:AppendInfo("GetQuestPartyProgress",id,true,true)end
    end
end
function L:AddObjectTooltip(tooltip,data)
    local ids={}
    for _,line in ipairs(data and data.lines or {})do
        local id=Read(function()return line.questID end)
        if type(id)=="number"and id>0 then ids[id]=true end
    end
    self:AddPartyProgress(tooltip,ids)
end
function L:AddUnitTooltip(tooltip,data)
    if not ProjectRuthlessDB.questWorkspace.enabled then return end
    local ok,_,unit=pcall(tooltip.GetUnit,tooltip)
    if not ok or type(unit)~="string" then return end
    local guid=Read(UnitGUID,unit)
    if type(guid)~="string" then return end
    local kind,_,_,_,_,npc=strsplit("-",guid)
    if kind~="Creature" and kind~="Vehicle" then return end
    local rows=self.tooltipIndex and self.tooltipIndex[tonumber(npc)]
    if not rows then self:AddObjectTooltip(tooltip,data);return end
    local partyIDs={}
    for _,row in pairs(rows)do
        partyIDs[row.id]=true
        local name=row.item and Read(C_Item and C_Item.GetItemNameByID,row.item)
        local objectives=Read(C_QuestLog.GetQuestObjectives,row.id)or {}
        local detail
        for _,objective in ipairs(objectives)do
            if not (issecretvalue and (issecretvalue(objective.finished)or issecretvalue(objective.objectID)or issecretvalue(objective.text))) and not objective.finished and (not row.item or objective.objectID==row.item or name and type(objective.text)=="string" and objective.text:find(name,1,true))then detail=objective.text;break end
        end
        if detail then
            tooltip:AddLine(row.title,1,.82,0)
            tooltip:AddLine(detail,1,1,1,true)
        end
    end
    self:AddPartyProgress(tooltip,partyIDs)
end
function L:OnPlayerLogin()
    local q=AUI.modules.QuestWorkspace
    if not q then return end
    q.RefreshPins=function(workspace)self:UpdateTooltipIndex(workspace);self:Refresh(workspace)end
    local original=q.ApplySettings
    q.ApplySettings=function(workspace,...)original(workspace,...);self:SetEnabled();self:Refresh(workspace,true)end
    local events=CreateFrame("Frame")
    self.eventNames={"PLAYER_ENTERING_WORLD","QUESTLINE_UPDATE","QUEST_ACCEPTED","QUEST_REMOVED","QUEST_TURNED_IN","PLAYER_LEVEL_UP","SKILL_LINES_CHANGED","UPDATE_FACTION","SPELLS_CHANGED","BAG_UPDATE_DELAYED","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED"}
    events:SetScript("OnEvent",function(_,event)
        if not ProjectRuthlessDB.questWorkspace.enabled then return end
        if event=="PLAYER_REGEN_DISABLED"then
            self.scanResting=true;self.scanPending=true;self.combatScanRevision=(self.combatScanRevision or 0)+1;return
        elseif event=="PLAYER_REGEN_ENABLED"then
            self.scanResting=true
            local revision=self.combatScanRevision or 0
            C_Timer.After(3,function()
                if revision~=(self.combatScanRevision or 0)or InCombatLockdown()then return end
                self.scanResting=nil
                if self.scanPending then self:ScanOffers()end
            end)
            return
        elseif event=="BAG_UPDATE_DELAYED"and not self.hasSourceRequirements then return end
        self:InvalidateAvailability()
        if not self.offerQueued then self.offerQueued=true;C_Timer.After(1,function()self.offerQueued=nil;if ProjectRuthlessDB.questWorkspace.enabled then self:ScanOffers()end end)end
    end)
    self.events=events
    self:SetEnabled()
    if hooksecurefunc then
        if QuestMapFrame_ShowQuestDetails then hooksecurefunc("QuestMapFrame_ShowQuestDetails",function(id)self:SelectQuest(id)end) end
        hooksecurefunc(q,"SetWaypoint",function(_,id)self:SelectQuest(id)end)
    end
    -- RUI positions visual markers; native quest pins/areas remain untouched.
    if WorldMapFrame then
        WorldMapFrame:HookScript("OnShow",function()q:SyncMapObjective();self:DrawAreas()end)
        WorldMapFrame:HookScript("OnSizeChanged",function()self:DrawSelectedArea()end)
        if hooksecurefunc and WorldMapFrame.SetMapID then hooksecurefunc(WorldMapFrame,"SetMapID",function()self:DrawSelectedArea()end)end
    end
    if GameTooltip and not self.tooltipHooked then
        self.tooltipHooked=true
        if TooltipDataProcessor and Enum.TooltipDataType then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit,function(tooltip,data)self:AddUnitTooltip(tooltip,data)end)
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Object,function(tooltip,data)self:AddObjectTooltip(tooltip,data)end)
        elseif GameTooltip.HookScript then
            GameTooltip:HookScript("OnTooltipSetUnit",function(tooltip)self:AddUnitTooltip(tooltip)end)
        end
    end
    self:UpdateTooltipIndex(q)
    self:Refresh(q,true)
end
