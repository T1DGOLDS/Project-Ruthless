local _,AUI=...
local D={rows={},pins={}}
AUI:RegisterModule("DungeonAtlas",D)
local function safe(fn,...)
    if type(fn)~="function"then return end
    local ok,a,b=pcall(fn,...)
    if ok and not (issecretvalue and (issecretvalue(a)or issecretvalue(b)))then return a,b end
end
local function clean(text)return (type(text)=="string"and text or ""):gsub("|T.-|t",""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")end
local localMapNames="BlackfathomDeeps BlackfathomDeepsEnt BlackrockDepths BlackrockMountainEnt BlackwingLair CL_BlackfathomDeepsA CL_BlackfathomDeepsB CL_BlackfathomDeepsC CL_BlackfathomDeepsEnt CL_BlackrockDepths CL_BlackrockMountainEnt CL_BlackrockSpireLower CL_BlackrockSpireUpper CL_BlackwingLair CL_DireMaulEast CL_DireMaulEnt CL_DireMaulNorth CL_DireMaulWest CL_Gnomeregan CL_GnomereganEnt CL_Maraudon CL_MaraudonEnt CL_MoltenCore CL_Naxxramas CL_OnyxiasLair CL_RagefireChasm CL_RazorfenDowns CL_RazorfenKraul CL_ScarletMonasteryEnt CL_Scholomance CL_ShadowfangKeep CL_SMArmory CL_SMCathedral CL_SMGraveyard CL_SMLibrary CL_Stratholme CL_TheDeadmines CL_TheDeadminesEnt CL_TheRuinsofAhnQiraj CL_TheStockade CL_TheSunkenTemple CL_TheSunkenTempleEnt CL_TheTempleofAhnQiraj CL_Uldaman CL_UldamanEnt CL_WailingCaverns CL_WailingCavernsEnt CL_ZulFarrak CL_ZulGurub DireMaulEast DireMaulEnt DireMaulNorth DireMaulWest Gnomeregan GnomereganEnt LowerBlackrockSpire Maraudon MaraudonEnt MoltenCore RagefireChasm RazorfenDowns RazorfenKraul ScarletHalls ScarletMonastery ScarletMonasteryEnt Scholomance ShadowfangKeep StratholmeCrusader StratholmeGauntlet TheDeadminesA TheDeadminesB TheDeadminesEnt TheRuinsofAhnQiraj TheStockade TheSunkenTemple TheSunkenTempleEnt TheTempleofAhnQiraj Uldaman UldamanEnt WailingCaverns WailingCavernsEnt ZulFarrak AuchAuchenaiCrypts AuchindounEnt AuchManaTombs AuchSethekkHalls AuchShadowLabyrinth BlackTempleBasement BlackTempleStart BlackTempleTop CavernsOfTimeEnt CFRSerpentshrineCavern CFRTheSlavePens CFRTheSteamvault CFRTheUnderbog CL_AuchAuchenaiCrypts CL_AuchindounEnt CL_AuchManaTombs CL_AuchSethekkHalls CL_AuchShadowLabyrinth CL_BlackTempleBasement CL_BlackTempleStart CL_BlackTempleTop CL_CFRSerpentshrineCavern CL_CFRTheSlavePens CL_CFRTheSteamvault CL_CFRTheUnderbog CL_CoilfangReservoirEnt CL_CoTEnt CL_GruulsLair CL_HCBloodFurnace CL_HCHellfireRamparts CL_HCMagtheridonsLair CL_HCTheShatteredHalls CL_KarazhanEnd CL_KarazhanEnt CL_KarazhanStart CL_MagistersTerrace CL_SunwellPlateau CL_TempestKeepArcatraz CL_TempestKeepBotanica CL_TempestKeepMechanar CL_TempestKeepTheEye CoilfangReservoirEnt CoTBlackMorass CoTHyjal CoTHyjalEnt CoTOldHillsbrad CoTOldStratholme GruulsLair HCBloodFurnace HCHellfireRamparts HCMagtheridonsLair HCTheShatteredHalls HellfireCitadelEnt KarazhanEnd KarazhanEnt KarazhanStart MagistersTerrace SunwellPlateau TempestKeepArcatraz TempestKeepBotanica TempestKeepEnt TempestKeepMechanar TempestKeepTheEye WL_CoTEnt ZulAman"
function D:LocalFloors(record)
    if not self.localAssets then
        self.localAssets={};for name in localMapNames:gmatch("%S+")do self.localAssets[name]=true end
    end
    local floors,seen={},{}
    local function add(files)
        if type(files)=="string"then files={files}end
        for _,name in ipairs(type(files)=="table"and files or {})do
            if self.localAssets[name] and not seen[name]then
                seen[name]=true;floors[#floors+1]={key=name,label=name:find("Ent$") and "Entrance"or name:gsub("^CL_","")}
            end
        end
    end
    add(record.AtlasMapFile)
    for _,boss in ipairs(record.items or {})do add(boss.AtlasMapFile)end
    if #floors==0 then add(record.AtlasMapFile_AL)end
    return floors
end
function D:LayoutLocalMap()
    if not self.localFrame or not self.localFrame:IsShown()then return end
    local size=math.max(1,math.min(self.localFrame:GetWidth()-16,self.localFrame:GetHeight()-36))
    self.localTexture:SetSize(size,size)
end
function D:ShowLocalMap(key)
    if not self.localAssets or not self.localAssets[key]then return false end
    if not self.localFrame then
        local f=CreateFrame("Frame",nil,WorldMapFrame,"BackdropTemplate")
        f:SetPoint("TOPLEFT",WorldMapFrame.ScrollContainer,"TOPLEFT",0,0)
        f:SetPoint("BOTTOMRIGHT",WorldMapFrame.ScrollContainer,"BOTTOMRIGHT",0,0)
        f:SetFrameStrata(WorldMapFrame:GetFrameStrata());f:SetFrameLevel(WorldMapFrame:GetFrameLevel()+190)
        f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});AUI:StyleSurface(f,"window",1)
        local t=f:CreateTexture(nil,"ARTWORK");t:SetPoint("CENTER",0,10);self.localTexture=t
        local label=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        label:SetPoint("BOTTOM",0,10);label:SetText("Reference map · player position unavailable");label:SetTextColor(.6,.65,.72)
        f:SetScript("OnSizeChanged",function()self:LayoutLocalMap()end)
        f:SetScript("OnHide",function()t:SetTexture(nil)end)
        self.localFrame=f
    end
    self.localFrame:Show()
    self.localTexture:SetTexture("Interface\\AddOns\\ProjectRuthless\\Assets\\DungeonMaps\\"..key)
    self:LayoutLocalMap()
    return true
end
function D:Load()
    if not RUI_DungeonData and C_AddOns and C_AddOns.LoadAddOn then safe(C_AddOns.LoadAddOn,"ProjectRuthless_DungeonData")end
    local data=RUI_DungeonData
    if not data then return nil,"RUI Dungeon Data is unavailable. Enable the bundled ProjectRuthless_DungeonData addon."end
    local api={GetItemTable=function(_,_,key,index)
        local boss=data[key]and data[key].items[index]
        local loot=boss and boss.loot or {}
        return loot[self.difficulty or "NORMAL"]or loot.NORMAL or loot["20RAID"]or loot["40RAID"]or loot["10RAID"]or loot["25RAID"]or {}
    end}
    self.api=api;self.data=data
    if not self.catalog then
        self.catalog={}
        for key,record in pairs(data)do
            if type(record)=="table"and record.InstanceID and record.items and record.LevelRange then
                self.catalog[#self.catalog+1]={key=key,name=clean(record.name),record=record}
            end
        end
        table.sort(self.catalog,function(a,b)return a.name<b.name end)
    end
    return self.catalog
end
function D:Hide()
    if self.localFrame then self.localFrame:Hide()end
    if self.itemEvents then self.itemEvents:UnregisterEvent("GET_ITEM_INFO_RECEIVED")end
    for _,row in ipairs(self.rows)do row:Hide()end
    for _,pin in ipairs(self.pins)do pin:Hide()end
end
-- Zone IDs from external databases are not proof of native map availability.
function D:UsableMap(id)
    if type(id)~="number" or id<=0 then return false end
    local info=safe(C_Map.GetMapInfo,id)
    local layers=safe(C_Map.GetMapArtLayers,id)
    local layer=type(layers)=="table" and layers[1]
    return type(info)=="table" and type(layer)=="table" and type(layer.layerWidth)=="number" and layer.layerWidth>0 and type(layer.layerHeight)=="number" and layer.layerHeight>0
end
function D:OpenMap(id)
    if not self:UsableMap(id) then return false end
    WorldMapFrame:SetMapID(id)
    return true
end
function D:MapIDs(record)
    local locations=AUI.modules.QuestLocations
    if not locations then return {}end
    if not locations.mapping then locations:Build({})end
    local data=AUI.modules.QuestData
    local map=data and data.MapForArea and data:MapForArea(record.MapID,clean(record.name))or locations.mapping and locations.mapping[record.MapID]
    if not map then return {}end
    local floors=safe(C_Map.GetMapGroupMembersInfo,safe(C_Map.GetMapGroupID,map))or {}
    if #floors==0 then local info=safe(C_Map.GetMapInfo,map);floors={{mapID=map,name=info and info.name or "Dungeon floor"}}end
    local usable={}
    for _,floor in ipairs(floors)do if self:UsableMap(floor.mapID)then usable[#usable+1]=floor end end
    return usable
end
function D:BossPoints(boss)
    local locations=AUI.modules.QuestLocations;local db=locations and locations:Database()
    self.bossPointCache=self.bossPointCache or {}
    local cache=self.bossPointCache[boss]
    if cache and cache.db==db then return cache.points end
    local result,seen={},{}
    if not db or not boss.npcID then return result end
    local ids=type(boss.npcID)=="table"and boss.npcID or {boss.npcID}
    for _,id in ipairs(ids)do
        for area,coords in pairs(safe(db.Npc.Get,id,"spawns")or {})do
            local map=locations.mapping and locations.mapping[area]
            for _,coord in ipairs(coords)do
                if map and type(coord[1])=="number"and type(coord[2])=="number"and coord[1]>=0 and coord[1]<=100 and coord[2]>=0 and coord[2]<=100 then
                    local key=map..":"..coord[1]..":"..coord[2]
                    if not seen[key]then seen[key]=true;result[#result+1]={map=map,x=coord[1]/100,y=coord[2]/100}end
                end
            end
        end
    end
    self.bossPointCache[boss]={db=db,points=result}
    return result
end
function D:DrawPins()
    for _,pin in ipairs(self.pins)do pin:Hide()end
    if self.localFrame and self.localFrame:IsShown()then return end
    local q=AUI.modules.QuestWorkspace
    if not self.selected or not q or q.mapPage~="Dungeon atlas"or not q.mapPanel or not q.mapPanel:IsVisible()then return end
    local canvas=safe(WorldMapFrame.GetCanvas,WorldMapFrame);local map=safe(WorldMapFrame.GetMapID,WorldMapFrame)
    if not canvas then return end
    local floorMatches=false
    for _,floor in ipairs(self:MapIDs(self.selected.record))do if floor.mapID==map then floorMatches=true end end
    if not floorMatches then return end
    local n=0
    for index,boss in ipairs(self.selected.record.items)do
        for _,point in ipairs(self:BossPoints(boss))do
            if point.map==map then
                n=n+1;local pin=self.pins[n]
                if not pin then
                    pin=AUI:CreateButton(canvas);pin:SetSize(22,22);self.pins[n]=pin
                    pin:SetScript("OnClick",function(button)self.boss=button.boss;q:RenderMapPage()end)
                    pin:SetScript("OnEnter",function(button)GameTooltip:SetOwner(button,"ANCHOR_RIGHT");GameTooltip:SetText(clean(button.bossName));GameTooltip:AddLine("Click for loot",.8,.8,.8);GameTooltip:Show()end)
                    pin:SetScript("OnLeave",function()GameTooltip:Hide()end)
                end
                pin.boss=index;pin.bossName=boss.name;pin:SetText(tostring(index));pin:ClearAllPoints()
                pin:SetPoint("CENTER",canvas,"TOPLEFT",point.x*canvas:GetWidth(),-point.y*canvas:GetHeight());pin:Show()
            end
        end
    end
end
function D:Row(q,index,text,click,item)
    local row=self.rows[index]
    if not row then row=AUI:CreateButton(q.mapContent);self.rows[index]=row;row:SetSize(250,34)end
    row:ClearAllPoints();row:SetPoint("TOPLEFT",0,-(index-1)*39);row:SetText(text);row.item=item
    row:SetScript("OnClick",function(...)click(...)end)
    row:SetScript("OnEnter",function(button)if button.item then GameTooltip:SetOwner(button,"ANCHOR_RIGHT");GameTooltip:SetItemByID(button.item);GameTooltip:Show()end end)
    row:SetScript("OnLeave",function()GameTooltip:Hide()end);row:Show()
end
function D:Render(q)
    self:Hide();q.mapCopy:SetText("")
    local catalog,error=self:Load()
    if not catalog then q.mapCopy:SetText(error);return end
    local index=0
    local function row(text,click,item)index=index+1;self:Row(q,index,text,click,item)end
    if not self.selected then
        q.mapHeading:SetText("Dungeon atlas")
        for _,entry in ipairs(catalog)do
            local chosen=entry
            local range=entry.record.LevelRange
            row(entry.name.." · "..tostring(range[2]or "?").."–"..tostring(range[3]or "?"),function()
                self.selected=chosen;self.boss=nil;self.localFloor=nil;self.view="Bosses"
                local floors=self:MapIDs(chosen.record)
                if floors[1]then self:OpenMap(floors[1].mapID)end
                if #floors==0 and AUI.modules.QuestProgression then
                    for _,chain in ipairs(AUI.modules.QuestProgression:Catalog())do
                        if chain.areaID==chosen.record.MapID then AUI.modules.QuestProgression:Open(chain.key);return end
                    end
                end
                q:RenderMapPage()
            end)
        end
    else
        local record=self.selected.record
        q.mapHeading:SetText(self.selected.name)
        row("‹ All dungeons",function()self.selected=nil;self.boss=nil;q:RenderMapPage()end)
        row(self.view=="Quests"and "View bosses & loot"or "View dungeon quests",function()self.view=self.view=="Quests"and "Bosses"or "Quests";self.boss=nil;q:RenderMapPage()end)
        local progression=AUI.modules.QuestProgression
        if progression then
            for _,chain in ipairs(progression:Catalog())do
                if chain.areaID==record.MapID then local key=chain.key
                    row("Quest preparation flowchart",function()progression:Open(key)end)
                end
            end
        end
        local floors=self:MapIDs(record)
        for _,floor in ipairs(floors)do local mapID=floor.mapID;row("Floor · "..(floor.name or tostring(mapID)),function()self:OpenMap(mapID);self:DrawPins()end)end
        if #floors==0 then
            local localFloors=self:LocalFloors(record)
            if #localFloors>0 then
                local valid=false;for _,floor in ipairs(localFloors)do if floor.key==self.localFloor then valid=true end end
                if not valid then self.localFloor=localFloors[1].key end
                self:ShowLocalMap(self.localFloor)
                for _,floor in ipairs(localFloors)do
                    local key=floor.key
                    row((key==self.localFloor and "✓ "or "").."Map · "..floor.label,function()self.localFloor=key;q:RenderMapPage()end)
                end
            else
                row("No bundled map for this dungeon",function()end)
                if progression then row("Browse quest progression",function()progression:Open()end)end
            end
        end
        if self.view=="Quests"then
            local locations=AUI.modules.QuestLocations
            row(q.trackedDungeons[record.MapID]and "Untrack dungeon quests"or "Track dungeon quests",function()q:TrackDungeon(record.MapID,not q.trackedDungeons[record.MapID]);q:RenderMapPage()end)
            local count=0
            for _,group in ipairs(locations and locations:DungeonCatalog(q)or {})do
                if group.area==record.MapID or group.name==self.selected.name then
                    for _,entry in ipairs(group.entries)do
                        count=count+1;local quest=entry
                        row(q:QuestTitle(quest).."\n"..(quest.accept and "Pick up"or quest.complete and "Ready to turn in"or "Objectives"),function()
                            q.selected=quest.id;q.tripArea=record.MapID;q:Refresh()
                            if locations then locations:SelectQuest(quest.id)end
                            if not quest.accept and QuestMapFrame_ShowQuestDetails then q:SelectMapPage("Quests");QuestMapFrame_ShowQuestDetails(quest.id)end
                        end)
                    end
                end
            end
            if count==0 then row("No quests recorded here · coverage incomplete",function()end)end
        elseif self.boss then
            local boss=record.items[self.boss]
            if boss.loot and boss.loot.HEROIC then row("Loot · "..(self.difficulty or "NORMAL"),function()self.difficulty=self.difficulty=="HEROIC"and "NORMAL"or "HEROIC";q:RenderMapPage()end)end
            row("‹ Boss list",function()self.boss=nil;q:RenderMapPage()end)
            row(clean(boss.name)..(#self:BossPoints(boss)==0 and " · location unrecorded"or ""),function()end)
            local loot=safe(self.api.GetItemTable,self.api,nil,self.selected.key,self.boss,record.LoadDifficulty or 1)or {}
            local count=0;local seen={}
            for _,entry in ipairs(loot)do
                local item=entry[2]
                if type(item)=="number"and item>0 and not seen[item]then
                    seen[item]=true;count=count+1
                    local name,link=safe(C_Item.GetItemInfo,item)
                    row(link or name or ("Item "..item.." · loading"),function()local _,current=safe(C_Item.GetItemInfo,item);if current and HandleModifiedItemClick then HandleModifiedItemClick(current)end end,item)
                end
            end
            if count==0 then row("No loot table recorded for this entry",function()end)end
        else
            for i,boss in ipairs(record.items)do local number=i;row(i.." · "..clean(boss.name),function()self.boss=number;q:RenderMapPage()end)end
        end
    end
    q.mapContent:SetHeight(math.max(400,index*39));self:DrawPins()
    if not self.itemEvents then
        local events=CreateFrame("Frame");self.itemEvents=events
        events:SetScript("OnEvent",function()if not self.itemRefreshQueued then self.itemRefreshQueued=true;C_Timer.After(.2,function()self.itemRefreshQueued=nil;if q.mapPage=="Dungeon atlas"and q.mapPanel:IsVisible()then q:RenderMapPage()end end)end end)
        q.mapPanel:HookScript("OnHide",function()events:UnregisterEvent("GET_ITEM_INFO_RECEIVED");self:Hide()end)
    end
    self.itemEvents:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    if not self.hooked then
        self.hooked=true
        if hooksecurefunc and WorldMapFrame.SetMapID then hooksecurefunc(WorldMapFrame,"SetMapID",function()self:DrawPins()end)end
        WorldMapFrame:HookScript("OnSizeChanged",function()self:DrawPins()end)
    end
end
