local _, AUI = ...
local Q = {offset=0, skipped={}}
AUI:RegisterModule("QuestWorkspace", Q)

local function Public(value)
    return not (issecretvalue and issecretvalue(value))
end
local function Call(fn, ...)
    if type(fn) ~= "function" then return end
    local ok,a,b,c=pcall(fn,...)
    if ok and Public(a) and Public(b) and Public(c) then return a,b,c end
end
local function Text(parent,x,y,width,font)
    local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontNormalSmall")
    t:SetPoint("TOPLEFT",x,y); t:SetWidth(width); t:SetJustifyH("LEFT")
    return t
end
local function Accent()
    if AUI.AccentColor then return AUI:AccentColor()end
    local _,class=UnitClass("player")
    local color=RAID_CLASS_COLORS[class]
    return color and color.r or .7,color and color.g or .7,color and color.b or 1
end

-- Presentation-only semantic accents. Preserve native links/colours intact.
function Q:LinkQuestToChat(id)
    if not(IsShiftKeyDown and IsShiftKeyDown())then return false end
    local link=Call(GetQuestLink,id)
    if type(link)~="string"or link==""then return false end
    local chat=ChatFrameUtil
    if chat and type(chat.InsertLink)=="function"then
        if not chat.InsertLink(link)and type(chat.OpenChat)=="function"then chat.OpenChat(link)end
    elseif not Call(ChatEdit_InsertLink,link)and type(ChatFrame_OpenChat)=="function"then ChatFrame_OpenChat(link)end
    return true
end
function Q:HighlightObjective(value)
    if type(value)~="string" or not Public(value) then return "" end
    if value:find("|",1,true) then return value end
    local text=value:gsub("(%d+)%s*/%s*(%d+)",function(have,need)
        local colour=tonumber(have)>=tonumber(need) and "b5cea8" or "dcdcaa"
        return "|cff"..colour..have.."/"..need.."|r"
    end)
    -- Native objective labels have a target before a colon; prose stays neutral.
    text=text:gsub("^([^:\n]+):", "|cff9cdcfe%1|r:")
    text=text:gsub("^(Kill )", "|cffc586c0%1|r")
    text=text:gsub("^(Collect )", "|cffc586c0%1|r")
    text=text:gsub("^(Deliver )", "|cffc586c0%1|r")
    return text
end

-- Subtle title accents retain the class-coloured section headings.
function Q:QuestTitle(entry)
    local title=entry and entry.title or ""
    if not entry or not entry.id then return title end
    local level=entry.level
    if not level then
        local locations=AUI.modules.QuestLocations
        local db=locations and locations:Database()
        if db then level=Call(db.Quest.Get,entry.id,"questLevel")end
    end
    local r,g,b=.89,.91,.95
    if entry.availability=="unknown" then r,g,b=.68,.70,.73
    elseif type(level)=="number" and level>0 then
        local player=Call(UnitLevel,"player")or level
        local delta=level-player
        if delta>=5 then r,g,b=.92,.64,.63
        elseif delta>=3 then r,g,b=.94,.77,.60
        elseif delta>=-2 then r,g,b=.91,.87,.64
        elseif delta>=-7 then r,g,b=.68,.84,.69
        else r,g,b=.65,.67,.70 end
    end
    local tag=Call(C_QuestLog.GetQuestTagInfo,entry.id)
    local elite=entry.elite or tag and Public(tag.tagID) and tag.tagID==(Enum.QuestTag and Enum.QuestTag.Elite or 1)
    local badge=entry.complete and "|TInterface\\RaidFrame\\ReadyCheck-Ready:12:12:0:0|t " or ""
    local extra=elite and " |cffd4b98c[Elite]|r" or ""
    return badge..("|cff%02x%02x%02x%s|r"):format(math.floor(r*255),math.floor(g*255),math.floor(b*255),title)..extra
end

-- Quest 116 requirements cross-checked against ATT Forever Redridge records.
-- Locations are descriptive references from the Forever quest description,
-- not tested vendor coordinates. Merchant hints require an actual offered item.
local dryTimes={
    {id=1939,name="Skin of Sweet Rum",place="Goldshire · Barkeep Dobbins"},
    {id=1941,name="Cask of Merlot",place="Stormwind · Gallina Winery"},
    {id=1942,name="Bottle of Moonshine",place="Darkshire · Barkeep Hann"},
    {id=1262,name="Keg of Thunderbrew",place="Westfall · Grimbooze Thunderbrew; quest exchange"},
}

local westfallSupplies={
    {id=255007,count=14,quest=92909,name="Golem Isospring"},
    {id=255010,count=5,quest=92909,name="Harvester Gyrostabilizer"},
    {id=4358,count=10,quest=92749,name="Rough Dynamite"},
}
function Q:WestfallPrep()
    if Call(UnitFactionGroup,"player")~="Alliance"then return {}end
    local level=Call(UnitLevel,"player")or 0
    if level<9 or level>22 then return {}end
    local settings=ProjectRuthlessDB.questWorkspace
    local route=settings.prepWestfall==true
    local locations=AUI.modules.QuestLocations;local db=locations and locations:Database()
    for _,entry in ipairs(self.entries or {})do if db and Call(db.Quest.Get,entry.id,"zoneOrSort")==40 then route=true;break end end
    local guide=self.guide
    if guide and ((guide.target or "").." "..(guide.quest or "").." "..(guide.instruction or "")):lower():find("westfall",1,true)then route=true end
    if not route then return {}end
    local lines={}
    for _,item in ipairs(westfallSupplies)do
        if Call(C_QuestLog.IsQuestFlaggedCompleted,item.quest)~=true then
            local have=Call(C_Item and C_Item.GetItemCount,item.id,false)or 0
            if have<item.count then lines[#lines+1]=(item.count-have).." × "..item.name end
        end
    end
    return lines
end
-- Static requirements cache by route/log/offer snapshot; inventory stays live.
function Q:ZonePreparation()
    local locations=AUI.modules.QuestLocations;local db=locations and locations:Database()
    if not db or not db.Item then return {}end
    local settings=ProjectRuthlessDB.questWorkspace
    local guide=self.guide
    local key=tostring(db)..":"..tostring(Call(UnitLevel,"player"))..":"..tostring(locations.offers)..":"..tostring(self.entries)..":"..tostring(locations.offerCandidates)..":"..tostring(guide and guide.id)..":"..tostring(self.prepRouteRevision or 0)
    if self.prepRecordsKey~=key then
        local zones,ids={},{}
        for _,entry in ipairs(self.entries or {})do ids[entry.id]=true;local zone=Call(db.Quest.Get,entry.id,"zoneOrSort");if zone then zones[zone]=true end end
        if guide and guide.id then ids[guide.id]=true;local zone=Call(db.Quest.Get,guide.id,"zoneOrSort");if zone then zones[zone]=true end end
        for id in pairs(guide and guide.futureQuestIDs or {})do ids[id]=true;local zone=Call(db.Quest.Get,id,"zoneOrSort");if zone then zones[zone]=true end end
        for _,id in ipairs(locations.offerCandidates or {})do
            local zone=Call(db.Quest.Get,id,"zoneOrSort")
            local map=zone and locations.mapping and locations.mapping[zone]
            if zones[zone]or map and settings.prepMaps and settings.prepMaps[map]then
                local eligible,_,uncertain=locations:PlayerEligibility(id,db,true)
                if eligible or uncertain then ids[id]=true end
            end
        end
        local records={}
        for id in pairs(ids)do
            local objectives=Call(db.Quest.Get,id,"objectives")or {}
            for _,row in ipairs(objectives[3]or {})do
                if type(row[1])=="number"and type(row[3])=="number"and row[3]>0 then
                    records[#records+1]={id=row[1],count=row[3],quest=id,name=Call(db.Item.Get,row[1],"name")or ("Item "..row[1]),vendors=Call(db.Item.Get,row[1],"vendors")or {}}
                end
            end
        end
        self.prepRecords=records;self.prepRecordsKey=key
    end
    local totals={}
    for _,item in ipairs(self.prepRecords or {})do
        if Call(C_QuestLog.IsQuestFlaggedCompleted,item.quest)~=true then
            local bind
            if C_Item and C_Item.GetItemInfo then
                local ok,_,_,_,_,_,_,_,_,_,_,_,_,_,binding=pcall(C_Item.GetItemInfo,item.id)
                if ok and Public(binding)then bind=binding end
            end
            local vendor=#item.vendors>0
            if vendor or bind==0 or bind==2 or bind==3 then
                local total=totals[item.id]or {name=item.name,count=0,vendor=vendor};totals[item.id]=total;total.count=total.count+item.count
            end
        end
    end
    local lines={}
    for id,item in pairs(totals)do
        local have=Call(C_Item and C_Item.GetItemCount,id,false)or 0
        if have<item.count then lines[#lines+1]=(item.count-have).." × "..item.name..(item.vendor and " · vendor"or " · AH")end
    end
    table.sort(lines)
    return lines
end
function Q:PreparationLines()
    local lines=self:ZonePreparation()
    for _,line in ipairs(self:WestfallPrep())do
        local duplicate=false
        for _,existing in ipairs(lines)do if existing:find(line:match("× (.+)"),1,true)then duplicate=true;break end end
        if not duplicate then lines[#lines+1]=line.." · AH"end
    end
    return lines
end

function Q:UpdatePreparation()
    local locations=AUI.modules.QuestLocations
    local map=Call(C_Map.GetBestMapForUnit,"player")
    local cities={[84]=true,[85]=true,[87]=true,[88]=true,[89]=true,[90]=true}
    local city=cities[map]or self.prepAuctionOpen
    local lines=city and self:PreparationLines()or {}
    local fullCount=#lines
    while #lines>5 do table.remove(lines)end
    if fullCount>5 then lines[#lines+1]="+"..(fullCount-5).." more · Map → Supplies"end
    if not self.prepCopy then self.prepCopy=Text(self.frame,12,0,268);self.prepCopy:SetTextColor(.85,.87,.9)end
    self.prepCopy:SetText(#lines>0 and "|cff9ba3b5PREPARE · UPCOMING QUESTS|r\n"..table.concat(lines,"\n")or "")
    self.prepCopy:SetShown(#lines>0)
    local key=table.concat(lines,";")
    if city and #lines>0 and key~=self.lastPrepNotice then AUI:Print("Upcoming quest supplies: "..table.concat(lines,", "))end
    local changed=self.prepSignature~=key;self.prepSignature=key
    self.lastPrepNotice=city and key or nil
    return changed
end
function Q:AutoHandIn(event)
    if not ProjectRuthlessDB.questWorkspace.autoHandIn or InCombatLockdown()then return end
    if event=="QUEST_PROGRESS" and Call(IsQuestCompletable)==true then
        if CompleteQuest then CompleteQuest()end
    elseif event=="QUEST_COMPLETE" then
        local choices=Call(GetNumQuestChoices)
        if choices==0 or choices==1 then if GetQuestReward then GetQuestReward(choices==1 and 1 or 0)end end
    end
end

function Q:SupplyAdvice(merchantOnly)
    if Call(C_QuestLog.IsQuestFlaggedCompleted,116)==true then return {} end
    local faction=Call(UnitFactionGroup,"player")
    if faction~="Alliance" then return {} end
    local offered={}
    if merchantOnly then
        for i=1,Call(GetMerchantNumItems) or 0 do
            local link=Call(GetMerchantItemLink,i)
            local id=type(link)=="string" and tonumber(link:match("item:(%d+)"))
            if id then offered[id]=true end
        end
    end
    local lines={}
    for _,item in ipairs(dryTimes) do
        local count=Call(C_Item and C_Item.GetItemCount,item.id,false) or 0
        if not merchantOnly or (offered[item.id] and count<1) then
            lines[#lines+1]=(count>=1 and "✓ " or "Need 1 · ")..item.name.."\n"..item.place
        end
    end
    return lines
end

function Q:ToggleTracking(id)
    if InCombatLockdown() then return end
    if Call(C_QuestLog.GetQuestWatchType,id)~=nil then
        Call(C_QuestLog.RemoveQuestWatch,id)
    else
        Call(C_QuestLog.AddQuestWatch,id,Enum.QuestWatchType.Manual)
    end
    self:Refresh()
end

function Q:SyncMapObjective()
    local id=self.currentQuestID
    if not ProjectRuthlessDB.questWorkspace.enabled or type(id)~="number"or not Public(id)or id<=0 then self.syncedMapObjective=nil;return end
    -- Pickup suggestions are not held quests and cannot be selected in the native log.
    if type(C_QuestLog.GetLogIndexForQuestID)=="function"and not Call(C_QuestLog.GetLogIndexForQuestID,id)then return end
    local locations=AUI.modules.QuestLocations
    if locations then locations.selectedQuest=id end
    if InCombatLockdown()then self.pendingMapObjective=true;return end
    self.pendingMapObjective=nil
    local selected=Call(C_QuestLog.GetSelectedQuest)
    local tracked=Call(C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID)
    if selected~=id and (selected~=nil or self.syncedMapObjective~=id)then Call(C_QuestLog.SetSelectedQuest,id)end
    if tracked~=id and (tracked~=nil or self.syncedMapObjective~=id)then Call(C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID,id)end
    self.syncedMapObjective=id
end
function Q:SetWaypoint(id)
    self.selected=id; self.offset=0
    if InCombatLockdown()then
        AUI:AfterCombat("questWaypoint",function()
            if self.selected==id and Call(C_QuestLog.GetLogIndexForQuestID,id)then self:SetWaypoint(id)end
        end)
        self:Refresh();return
    end
    Call(C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID,id)
    local map,x,y=Call(C_QuestLog.GetNextWaypoint,id)
    if map and x and y and UiMapPoint and C_Map.SetUserWaypoint then
        local point=UiMapPoint.CreateFromCoordinates(map,x,y)
        Call(C_Map.SetUserWaypoint,point)
    end
    self:Refresh()
end

function Q:Collect()
    local entries={}
    local count=Call(C_QuestLog.GetNumQuestLogEntries) or 0
    for i=1,count do
        local info=Call(C_QuestLog.GetInfo,i)
        if info and Public(info.questID) and Public(info.title) and Public(info.isHeader) and not info.isHeader and info.questID then
            local id=info.questID
            if not self.skipped[id] then
                local complete=Call(C_QuestLog.IsComplete,id)
                local distance=Call(C_QuestLog.GetDistanceSqToQuest,id)
                local lines={}
                for _,objective in ipairs(Call(C_QuestLog.GetQuestObjectives,id) or {}) do
                    if Public(objective.text) and objective.text then lines[#lines+1]=objective.text end
                end
                entries[#entries+1]={id=id,title=info.title,level=Public(info.level) and info.level or nil,elite=Public(info.isElite) and info.isElite or nil,complete=complete==true,distance=type(distance)=="number" and distance or math.huge,detail=complete and "Ready to turn in" or table.concat(lines," • ")}
            end
        end
    end
    table.sort(entries,function(a,b)
        if a.id==self.selected then return true end
        if b.id==self.selected then return false end
        if a.distance~=b.distance then return a.distance<b.distance end
        return a.id<b.id
    end)
    return entries
end


-- Read only the installed Wisp UI. Wisp owns route content and progression.
local function DisplayText(region)
    local value=region and Call(region.GetText,region)
    return type(value)=="string" and value or ""
end
-- Providers return presentation data; their engines retain routing/progression ownership.
function Q:RegisterGuideProvider(id,label,reader)
    if type(id)~="string"or type(label)~="string"or type(reader)~="function"then return false end
    self.guideProviders=self.guideProviders or {};self.guideProviders[id]={label=label,read=reader};return true
end
function Q:GuideSources()
    local sources={{id="RUI",label="RUI default"},{id="Wisp",label="Wisp"}}
    local extra={};for id,provider in pairs(self.guideProviders or {})do extra[#extra+1]={id=id,label=provider.label}end
    table.sort(extra,function(a,b)return a.label<b.label end);for _,source in ipairs(extra)do sources[#sources+1]=source end
    return sources
end
function Q:GuideSourceLabel()
    local id=ProjectRuthlessDB.questWorkspace.guideSource or "RUI"
    for _,source in ipairs(self:GuideSources())do if source.id==id then return source.label..(id=="Wisp"and not ForeverWispFrame and " (not running)"or "")end end
    return id.." (not connected)"
end
function Q:CycleGuideSource()
    local sources=self:GuideSources();local current=ProjectRuthlessDB.questWorkspace.guideSource or "RUI";local nextIndex=1
    for i,source in ipairs(sources)do if source.id==current then nextIndex=i%#sources+1;break end end
    ProjectRuthlessDB.questWorkspace.guideSource=sources[nextIndex].id
    self.manualFocus=nil;self.manualPickup=nil;self.guide=nil;self:Refresh()
end
function Q:ReadGuide()
    local source=ProjectRuthlessDB.questWorkspace.guideSource
    if self.manualFocus and source~="RUI"then return end
    local authored=AUI.modules.AuthoredGuides
    if source and source~="Wisp"and source~="RUI"then
        local provider=self.guideProviders and self.guideProviders[source]
        local guide=provider and Call(provider.read,self)
        if type(guide)=="table"then guide.source=source;return guide end
        return
    end
    if source~="Wisp"then
        if source=="RUI"and authored then authored:EnsureStarted(self)end
        local own=authored and authored:Read(self);if own then return own end
    end
    if source=="RUI"then
        local state=ProjectRuthlessCharDB.authoredGuide or {}
        return {source="RUI",phase=state.paused and "GUIDE PAUSED"or state.stopped and "GUIDE STOPPED"or "CHOOSE A GUIDE",count="",quest="Leveling guide",target="",instruction=state.route and "Map → Chapters to resume your guide."or "Map → Library to choose a leveling route.",objectives={},next={}}
    end
    return self:ReadWispGuide()
end
function Q:ReadWispGuide()
    if ProjectRuthlessDB and not ProjectRuthlessDB.questWorkspace.guideSource and ProjectRuthlessDB.questWorkspace.useWisp==false then return end
    local f=ForeverWispFrame
    local p=f and f.route
    if not p or not Call(f.IsShown,f) or not Call(p.IsShown,p) then return end
    local target=DisplayText(p.heading)
    if target=="" then return end
    local quest=DisplayText(p.guide)
    local guide={source="Wisp",target=target,quest=quest,phase=DisplayText(p.meta),count=DisplayText(p.count),instruction=DisplayText(p.instruction),next={}}
    local upcoming=p.upNext
    if upcoming and Call(upcoming.IsShown,upcoming) then
        for _,row in ipairs(upcoming.rows or {}) do
            if Call(row.IsShown,row) then guide.next[#guide.next+1]={title=DisplayText(row.quest),detail=DisplayText(row.npc)} end
        end
    end
    guide.objectives={}
    guide.questIDs={}
    local seen={}
    local function readObjectives(parent,along)
        for _,row in ipairs(parent and parent.objectives or {})do
            if Call(row.IsShown,row) then
                local step=row.entry and row.entry.sourceStep
                local id=step and step.completion and step.completion.questId
                if type(id)=="number" and Public(id)then guide.questIDs[id]=true end
                local name,counter=DisplayText(row.name),DisplayText(row.counter)
                local key=name..counter
                if name~="" and not seen[key]then seen[key]=true;guide.objectives[#guide.objectives+1]=(along and "Along the way · " or "")..name..(counter~="" and "  "..counter or "")end
            end
        end
    end
    readObjectives(p.objectives and p.objectives.copy)
    for _,section in ipairs({p.along or {},p.batch or {}})do
        if Call(section.IsShown,section)then for _,row in ipairs(section.rows or {})do if Call(row.IsShown,row)then readObjectives(row,section==p.along)end end end
    end
    -- Match only an exact localized name; never guess between duplicate names.
    local name=quest:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
    local db=LibQuestieDB
    if name~=self.guideName then
        self.guideName=name;self.guideQuestID=nil
        for _,entry in ipairs(self.entries or {}) do if entry.title==name then self.guideQuestID=entry.id;break end end
        if not self.guideQuestID and db and db.Quest then
            local ids=Call(db.Quest.IdsByName,name)
            if ids and #ids==1 then self.guideQuestID=ids[1] end
        end
    end
    guide.id=self.guideQuestID
    return guide
end
function Q:RenderGuide(guide)
    self.guide=guide
    if not guide then return false end
    self.phase:SetText(guide.phase..(guide.count~="" and (" · "..guide.count) or ""))
    local titleEntry={id=guide.id,title=guide.quest~="" and guide.quest or guide.target,level=guide.level,availability=guide.availability}
    for _,entry in ipairs(self.entries or {})do if entry.id==guide.id then titleEntry=entry;break end end
    self.currentQuestID=titleEntry.id;self.currentTitle:SetText(self:QuestTitle(titleEntry))
    if guide.source=="RUI"and AUI.modules.QuestLocations then AUI.modules.QuestLocations.selectedQuest=guide.id end
    self:SyncMapObjective()
    self.summary:SetText(guide.instruction)
    if self.objectiveCopy then self.objectiveCopy:SetText(table.concat(guide.objectives or {},"\n"))end
    self.nearbyHeading:SetText("UP NEXT · GUIDE")
    self.empty:Hide()
    for i,row in ipairs(self.rows) do
        local entry=guide.next[i];row.entry=nil;row:SetShown(entry~=nil)
        if entry then row.title:SetText(self:QuestTitle(entry));row.detail:SetText(self:HighlightObjective(entry.detail)) end
    end
    return true
end
function Q:GuideNavigation()
    if self.guide and self.guide.source and self.guide.source~="Wisp"then return false end
    local f=ForeverWispNavigation
    if not f or not Call(f.IsShown,f) or type(f.GetRegions)~="function" then return false end
    local cached=self.guideNavigationRegions
    if not cached or self.guideNavigationFrame~=f then
        local ok,regions=pcall(function()return {f:GetRegions()}end)
        if not ok then return false end
        local arrow
        local labels={}
        for _,region in ipairs(regions) do
            local kind=Call(region.GetObjectType,region)
            if kind=="Texture" then
                local texture=Call(region.GetTexture,region)
                local width,height=Call(region.GetSize,region)
                -- GetTexture returns a numeric file ID in the live client.
                if (width==96 and height==96) or (type(texture)=="string" and texture:lower():match("[/\\]arrow%.tga$")) then arrow=region end
            elseif kind=="FontString" then
                labels[#labels+1]=region
            end
        end
        if #labels~=3 and #labels~=2 then return false end
        cached={arrow=arrow,labels=labels};self.guideNavigationRegions=cached;self.guideNavigationFrame=f
    end
    local arrow,labels=cached.arrow,cached.labels
    local distance,destination
    -- Wisp 0.28 creates distance, destination, note in this order; text size is user configurable.
    if #labels~=3 and #labels~=2 then return false end
    distance=DisplayText(labels[1]);destination=DisplayText(labels[2])
    if distance=="" and destination=="" then return false end
    self.distance:SetText(distance);self.destination:SetText(destination)
    local angle=arrow and Call(arrow.GetRotation,arrow)
    if type(angle)=="number" and Public(angle) and ProjectRuthlessDB.questWorkspace.showArrow~=false then
        self.arrow:SetRotation(angle);self.arrow:Show()
        self.guideBearing=angle+(Call(GetPlayerFacing) or 0)
    end
    return true
end
function Q:GuideAction(name)
    if self.guide and self.guide.source=="RUI"then AUI.modules.AuthoredGuides:Action(name);return end
    -- External provider callbacks may change protected state.
    if InCombatLockdown() then return end
    if self.guide and self.guide.source and self.guide.source~="Wisp"then return end
    local p=ForeverWispFrame and ForeverWispFrame.route
    local button=p and p[name]
    if button and Call(button.IsShown,button) and Call(button.IsEnabled,button) then
        local handler=Call(button.GetScript,button,"OnClick")
        Call(handler,button,"LeftButton")
        self:Refresh()
    end
end

function Q:Refresh(skipUnchanged)
    if not self.frame or not self.frame:IsShown() then return end
    local entries=self:Collect()
    local parts={}
    for _,entry in ipairs(entries)do parts[#parts+1]=tostring(entry.id)..":"..tostring(entry.complete)..":"..tostring(entry.title)..":"..tostring(entry.detail)..":"..tostring(entry.level)..":"..tostring(entry.elite)end
    local signature=table.concat(parts,"|")
    if skipUnchanged and signature==self.entriesSignature then self:RenderQuestItems();if self:UpdatePreparation()then self:LayoutContent()end;return end
    if signature~=self.entriesSignature then self.entries=entries;self.entriesSignature=signature end
    if self.manualPickup then
        local accepted=false;for _,entry in ipairs(self.entries)do if entry.id==self.manualPickup.id then accepted=true end end
        if accepted then self.manualPickup=nil else self.entries[#self.entries+1]=self.manualPickup end
    end
    local found=false
    for _,entry in ipairs(self.entries) do if entry.id==self.selected then found=true end end
    if not found then self.selected=self.entries[1] and self.entries[1].id end
    local current
    local nearby={}
    for _,entry in ipairs(self.entries) do if entry.id==self.selected then current=entry elseif type(entry.distance)=="number"and entry.distance<=500*500 then nearby[#nearby+1]=entry end end
    self.currentQuestID=current and current.id;self.currentTitle:SetText(current and self:QuestTitle(current) or "No active quest")
    self.phase:SetText(current and (current.complete and "TURN IN" or "CURRENT OBJECTIVE") or "QUESTS")
    self.summary:SetText(current and (current.detail~="" and current.detail or "Check the quest log for objective details.") or "Accept a quest to start.")
    self.offset=math.max(0,math.min(self.offset,math.max(0,#nearby-3)))
    for i,row in ipairs(self.rows) do
        local entry=nearby[self.offset+i]; row.entry=entry; row:SetShown(entry~=nil)
        if entry then
            row.title:SetText(self:QuestTitle(entry))
            row.detail:SetText(entry.complete and "Ready to turn in" or entry.detail)
        end
    end
    if self.objectiveCopy then self.objectiveCopy:SetText("")end
    self.nearbyHeading:SetText("NEARBY")
    self.empty:SetShown(#self.entries==0)
    self:RenderGuide(self:ReadGuide())
    self:SyncMapObjective()
    if self.RefreshPins then self:RefreshPins() end
    self:RenderContext()
    self:Navigate()
    if self.mapPanel and self.mapPanel:IsShown() then self:RenderMapPage() end
end

function Q:Navigate()
    if not self.frame then return end
    self.arrow:Hide()
    if self.guide and self:GuideNavigation() and self.arrow:IsShown() then return end
    if self.guide and self.guide.source=="RUI"and not self.guide.id then self.distance:SetText(self.guide.phase);self.destination:SetText(self.guide.instruction);return end
    local targetID=self.guide and self.guide.source=="RUI"and self.guide.id or self.selected
    if not targetID then self.destination:SetText("Select a quest destination");self.distance:SetText("");return end
    local title=Call(C_QuestLog.GetTitleForQuestID,targetID) or "Quest destination"
    local waypointText=Call(C_QuestLog.GetNextWaypointText,targetID)
    self.destination:SetText(type(waypointText)=="string" and waypointText~="" and waypointText or title)
    local map,x,y=Call(C_QuestLog.GetNextWaypoint,targetID)
    if self.manualPickup and self.manualPickup.id==targetID and self.manualPickup.point then local p=self.manualPickup.point;map,x,y=p.map,p.x,p.y;self.destination:SetText(p.name) end
    local playerMap=Call(C_Map.GetBestMapForUnit,"player")
    if (not map or not x or not y) and AUI.modules.QuestLocations then
        local point=AUI.modules.QuestLocations:Destination(self.guide and self.guide.id or self.selected)
        if point then map,x,y=point.map,point.x,point.y;self.destination:SetText(point.name)end
    end
    local pos=playerMap and Call(C_Map.GetPlayerMapPosition,playerMap,"player")
    if not map or not pos or not Public(x) or not Public(y) then self.distance:SetText("Another area · use Map"); return end
    local px,py=Call(pos.GetXY,pos)
    local width,height=Call(C_Map.GetMapWorldSize,map)
    local facing=Call(GetPlayerFacing)
    if not px or not width or not height or not facing then self.distance:SetText("Location unavailable"); return end
    local dx,dy
    if map~=playerMap then
        local pc,pw=Call(C_Map.GetWorldPosFromMapPos,playerMap,pos)
        local tc,tw
        if CreateVector2D then tc,tw=Call(C_Map.GetWorldPosFromMapPos,map,CreateVector2D(x,y)) end
        if not pw or not tw or pc~=tc then self.distance:SetText("Another continent · use Map");return end
        local ax,ay=Call(pw.GetXY,pw);local bx,by=Call(tw.GetXY,tw)
        if not ax or not ay or not bx or not by then self.distance:SetText("Location unavailable");return end
        dx,dy=-(by-ay),-(bx-ax)
    else dx,dy=(x-px)*width,(y-py)*height end
    local distance=math.sqrt(dx*dx+dy*dy)
    self.distance:SetText(distance<25 and "Near destination · check surroundings" or ("%.0f yd · %.1f, %.1f"):format(distance,x*100,y*100))
    if distance>=25 and (not ProjectRuthlessDB or ProjectRuthlessDB.questWorkspace.showArrow~=false) then self.arrow:SetRotation(math.atan2(-dx,-dy)-facing); self.arrow:Show() end
end

function Q:RenderMapPage()
    if not self.mapCopy then return end
    self:LayoutMap()
    local page=self.mapPage or "Quests"
    local atlas=AUI.modules.DungeonAtlas
    if atlas then atlas:Hide()end
    local authored=AUI.modules.AuthoredGuides
    if authored then authored:HideBrowser()end
    if authored and (page=="Library"or page=="Chapters")then authored:RenderBrowser(self,page);return end
    if page=="Dungeon atlas"and atlas then
        for _,control in ipairs(self.mapControls or {})do control:Hide()end
        for _,button in ipairs(self.dungeonMapButtons or {})do button:Hide();if button.share and type(button.share)~="function"then button.share:Hide()end end
        self.mapScroll:ClearAllPoints();self.mapScroll:SetPoint("TOPLEFT",12,-42);self.mapScroll:SetPoint("BOTTOMRIGHT",-30,12)
        atlas:Render(self);return
    end
    self.mapContent:SetHeight(1500)
    self.mapHeading:SetText(page)
    for _,tab in ipairs(self.mapTabs or {})do
        local r,g,b=Accent();tab:SetBackdropBorderColor(r,g,b,tab.page==page and .9 or .22)
        if AUI.PaintBackground then AUI:PaintBackground(tab,"Map",.025,.028,.035)else tab:SetBackdropColor(.025,.028,.035,tab.page==page and 1 or .8)end
    end
    if self.mapScroll then self.mapScroll:ClearAllPoints();self.mapScroll:SetPoint("TOPLEFT",12,-42);self.mapScroll:SetPoint("BOTTOMRIGHT",-30,(page=="Tools"and 240 or page=="Settings"and 200) or false or (page=="Chapters"or page=="Library"or page=="Professions")and 82 or 12) end
    for _,button in ipairs(self.dungeonMapButtons or {})do button:Hide()end
    if page=="Dungeons" then
        self.mapCopy:SetText("")
        local locations=AUI.modules.QuestLocations
        local catalog=locations and locations:DungeonCatalog(self) or {}
        self.dungeonMapButtons=self.dungeonMapButtons or {}
        if #catalog==0 then self.mapCopy:SetText("No eligible dungeon quests are currently known for this character.")end
        for i,group in ipairs(catalog)do
            local button=self.dungeonMapButtons[i]
            if not button then button=AUI:CreateButton(self.mapContent);button:SetSize(250,44);self.dungeonMapButtons[i]=button end
            button:SetPoint("TOPLEFT",0,-(i-1)*78);button:SetText((self.trackedDungeons[group.area] and "Untrack · " or "Track · ")..group.name.."\n"..group.held.." in log · "..group.pickups.." pickups")
            button:SetScript("OnClick",function()self:TrackDungeon(group.area,not self.trackedDungeons[group.area]);self:RenderMapPage()end);button:Show()
            if not button.share or type(button.share)=="function"then button.share=AUI:CreateButton(self.mapContent);button.share:SetHeight(24)end
            button.share:ClearAllPoints();button.share:SetPoint("TOPLEFT",button,"BOTTOMLEFT",0,-3);button.share:SetPoint("RIGHT",button,"RIGHT",0,0)
            button.share:SetText("Share dungeon quests")
            button.share:SetScript("OnClick",function()
                local ok,message,remaining=self:ShareDungeon(group.area)
                if AUI.Print then AUI:Print(message)end
                if ok then button.share:SetText(remaining>0 and ("Share next · "..remaining.." remaining")or "Shared · Share again")end
            end)
            button.share:Show()
            self.mapContent:SetHeight(math.max(1,#catalog*78))
        end
    elseif page=="Quest details" then
        self.mapCopy:SetText(self.questDetails or "Select a quest marker.")
    elseif self.guide and (page=="Chapters" or page=="Library" or page=="Professions") then
        self.mapCopy:SetText("Installed ForeverWisp guide\n\n"..self.guide.quest.."\n"..self.guide.target.."\n\n"..self.guide.instruction.."\n\nUse Open guide browser below for Wisp chapters, library and profession controls. Wisp retains your saved progress.")
    elseif page=="Quests" then
        local lines={}
        for _,entry in ipairs(self:Collect()) do lines[#lines+1]=self:QuestTitle(entry).."\n|cffdddde2"..entry.detail.."|r" end
        self.mapCopy:SetText(table.concat(lines,"\n\n"))
    elseif page=="Tools" then
        self.mapCopy:SetText("Current quest\n\n"..(Call(C_QuestLog.GetTitleForQuestID,self.selected) or "None selected").."\n\nUse the controls below to track, skip or restore quests. Skipping does not abandon the quest.")
    elseif page=="Settings" then
        local settings=ProjectRuthlessDB.questWorkspace
        self.mapCopy:SetText(("The compact panel uses your class colour.\n\nDrag its header to position it. Scroll nearby quests to browse; click one to follow it.\n\nArrow: %s\nBackground: %d%%\nPosition: %s"):format(settings.showArrow and "On" or "Off",math.floor((AUI.BackgroundOpacity and AUI:BackgroundOpacity("Quest")or settings.opacity)*100),settings.locked and "Locked" or "Unlocked"))
    elseif page=="Professions" then
        self.mapCopy:SetText("Profession companions and gathering routes are not available in this build. They will live here alongside the quest guide.")
    elseif page=="Supplies" then
        local lines=self:SupplyAdvice(false)
        local prep=self:PreparationLines()
        local sections={}
        if #prep>0 then sections[#sections+1]="PREPARE · UPCOMING QUESTS\n\n"..table.concat(prep,"\n").."\n\nUpcoming route supplies; the quests may still require prerequisites."end
        if #lines>0 then sections[#sections+1]="PREPARE · DRY TIMES\n\n"..table.concat(lines,"\n\n")end
        self.mapCopy:SetText(#sections>0 and table.concat(sections,"\n\n")or "No known supplies missing. Enable Prepare for Westfall in Settings to plan that route before accepting its quests.")
    else
        self.mapCopy:SetText("Original 1–20 guides are being authored. No guide chapters are installed yet.\n\nYour active quests remain available in the Quests tab.")
    end
    for _,control in ipairs(self.mapControls) do control:Hide() end
    if page=="Settings" then
        for index,i in ipairs({4,5,6,7,12,14,13})do self.mapControls[i]:ClearAllPoints();self.mapControls[i]:SetPoint("BOTTOMLEFT",12,10+(7-index)*25)end
        self.mapControls[13]:ClearAllPoints();self.mapControls[13]:SetPoint("BOTTOMLEFT",12,10)
        self.mapControls[14]:ClearAllPoints();self.mapControls[14]:SetPoint("BOTTOMLEFT",12,35)
        self.mapControls[12]:ClearAllPoints();self.mapControls[12]:SetPoint("BOTTOMLEFT",12,60)
        self.mapControls[13]:SetText("Auto hand-in: "..(ProjectRuthlessDB.questWorkspace.autoHandIn and "On"or "Off"))
        self.mapControls[15]:ClearAllPoints();self.mapControls[15]:SetPoint("BOTTOMLEFT",12,185)
        self.mapControls[14]:SetText("Prepare for Westfall: "..(ProjectRuthlessDB.questWorkspace.prepWestfall and "On"or "Auto"))
    end
    if page=="Tools" then
        for i=1,3 do self.mapControls[i]:ClearAllPoints();self.mapControls[i]:SetPoint("BOTTOMLEFT",12,160+(3-i)*25);self.mapControls[i]:Show()end
        self.mapControls[16]:ClearAllPoints();self.mapControls[16]:SetPoint("BOTTOMLEFT",12,10);self.mapControls[16]:Show()
        self.mapControls[16]:SetText(self.greyReview and #self.greyReview>0 and ("Confirm abandon · "..#self.greyReview.." grey quests")or "Review grey quests to abandon")
        if self.greyReview then
            local lines={"Abandon grey quests", "Review this list before confirming. Quest progress and associated quest items may be lost."}
            for _,entry in ipairs(self.greyReview)do lines[#lines+1]=entry.title end
            if #self.greyReview==0 then lines[#lines+1]="No abandonable grey quests.";self.mapControls[16]:Hide()end
            self.mapCopy:SetText(table.concat(lines,"\n\n"))
        end
    elseif page=="Settings" then for i=4,7 do self.mapControls[i]:Show() end;self.mapControls[12]:Show();self.mapControls[13]:Show();self.mapControls[14]:Show();self.mapControls[15]:Show()
    elseif self.guide and (page=="Chapters" or page=="Library" or page=="Professions") then self.mapControls[11]:Show() end
    if self.guide and page=="Tools" then
        local own=self.guide.source=="RUI"
        self.mapControls[8]:SetText(own and "Previous guide chapter"or "Previous guide step")
        self.mapControls[9]:SetText(own and "Next guide chapter"or "Next guide step")
        self.mapControls[10]:SetText(own and "RUI chapter options"or "Guide step options")
        for i=8,11 do self.mapControls[i]:ClearAllPoints();self.mapControls[i]:SetPoint("BOTTOMLEFT",12,35+(11-i)*25);self.mapControls[i]:Show() end end
end

function Q:GreyQuests()
    local list={}
    for i=1,Call(C_QuestLog.GetNumQuestLogEntries)or 0 do
        local entry=Call(C_QuestLog.GetInfo,i)
        if entry and Public(entry.questID) and Public(entry.level) and not entry.isHeader and type(entry.level)=="number"and entry.level>0 then
            local colour=Call(GetQuestDifficultyColor,entry.level)
            if type(colour)=="table"and type(colour.r)=="number"and type(colour.g)=="number"and type(colour.b)=="number"and Public(colour.r)and Public(colour.g)and Public(colour.b)and colour.r<=.55 and colour.g<=.55 and colour.b<=.55 and Call(C_QuestLog.CanAbandonQuest,entry.questID)==true then
                list[#list+1]={id=entry.questID,title=entry.title or tostring(entry.questID)}
            end
        end
    end
    return list
end
function Q:ClearGreyQuests()
    if InCombatLockdown()then return end
    if not self.greyReview then
        self.greyReview=self:GreyQuests();self:RenderMapPage();return
    end
    local eligible={};for _,entry in ipairs(self:GreyQuests())do eligible[entry.id]=true end
    local selected=Call(C_QuestLog.GetSelectedQuest)
    for _,entry in ipairs(self.greyReview)do
        if InCombatLockdown()then break end
        if eligible[entry.id]then
            C_QuestLog.SetSelectedQuest(entry.id);C_QuestLog.SetAbandonQuest();C_QuestLog.AbandonQuest()
        end
    end
    if selected and Call(C_QuestLog.GetLogIndexForQuestID,selected)then C_QuestLog.SetSelectedQuest(selected)end
    self.greyReview=nil;self:Refresh();self:RenderMapPage()
end
function Q:OpenDungeonMenu()
    if WorldMapFrame and ShowUIPanel then ShowUIPanel(WorldMapFrame)end
    if not InCombatLockdown()then self:InstallMap()end;self.mapPage="Dungeons"
    if self.mapPanel then self:SelectMapPage("Dungeons")end
end

function Q:SelectMapPage(page)
    if page~="Tools"then self.greyReview=nil end
    self.mapPage=page;self:SyncMapPage()
    if page=="Quests"and AUI.modules.DungeonAtlas then AUI.modules.DungeonAtlas:Hide()end
    if page~="Quests"then self:RenderMapPage()end
end
function Q:SyncMapPage()
    if self.syncingMap or not self.mapPanel then return end
    local combat=InCombatLockdown()
    if combat then AUI:AfterCombat("mapPage",function()self:SyncMapPage()end)end
    self.syncingMap=true
    local enabled=ProjectRuthlessDB.questWorkspace.enabled
    local quests=(self.mapPage or "Quests")=="Quests"
    self.mapTabBar:SetShown(enabled)
    if self.mapResize then self.mapResize:SetShown(enabled)end
    self.mapPanel:SetShown(enabled and not quests)
    local log=self.nativeMapLog
    if log then
        if enabled then
            if not combat then
                log:ClearAllPoints();log:SetPoint("TOPLEFT",self.mapTabBar,"BOTTOMLEFT",0,0)
                log:SetPoint("BOTTOMRIGHT",WorldMapFrame,"BOTTOMRIGHT",-8,12)
            end
            -- OnHide closes native quest details and clears map focus. Keep its
            -- data lifecycle alive behind our opaque sidebar on custom pages.
            log:SetAlpha(quests and 1 or 0);log:EnableMouse(quests);if not combat then log:Show()end
            local questsFrame=log.QuestsFrame
            local scroll=questsFrame and type(questsFrame)~="function"and questsFrame.ScrollFrame
            local search=scroll and type(scroll)~="function"and scroll.SearchBox
            if not quests and search and type(search.ClearFocus)=="function"then search:ClearFocus()end
        else
            if not combat and self.nativeLogPoints then log:ClearAllPoints();for _,point in ipairs(self.nativeLogPoints)do log:SetPoint(unpack(point))end end
            log:SetAlpha(1);log:EnableMouse(true);if not combat then log:Show()end
        end
    end
    for _,tab in ipairs(self.mapTabs or {})do
        local r,g,b=Accent();tab:SetBackdropBorderColor(r,g,b,tab.page==(self.mapPage or "Quests")and .9 or .22)
    end
    self:LayoutMap()
    self.syncingMap=nil
end
function Q:LayoutMap()
    if self.layingOutMap or not self.mapTabBar or InCombatLockdown()then return end
    self.layingOutMap=true
    local map=WorldMapFrame
    local width=Call(map.GetWidth,map)or 944
    local sidebar=math.max(340,math.min(420,width*.34))
    self.mapTabBar:SetWidth(sidebar)
    local column=(sidebar-20)/3
    for i,tab in ipairs(self.mapTabs or {})do
        tab:SetWidth(column-4);tab:ClearAllPoints()
        tab:SetPoint("TOPLEFT",self.mapTabBar,"TOPLEFT",8+((i-1)%3)*column,-8-math.floor((i-1)/3)*26)
    end
    -- Keep the map viewport separate even when native quest visibility changes.
    local spacer=map.TitleCanvasSpacerFrame
    if spacer and type(spacer)~="function"then spacer:SetPoint("BOTTOMRIGHT",map,"TOPRIGHT",-sidebar-20,-60)end
    local container=map.ScrollContainer
    if container and type(container)~="function"and container.ClearAllPoints then
        container:ClearAllPoints();container:SetPoint("TOPLEFT",map,"TOPLEFT",8,-62)
        container:SetPoint("BOTTOMRIGHT",map,"BOTTOMRIGHT",-sidebar-20,12)
    end
    local log=self.nativeMapLog
    local quests=log and log.QuestsFrame
    if quests and type(quests)~="function"then
        quests:ClearAllPoints();quests:SetAllPoints(log)
        local scroll=quests.ScrollFrame
        if scroll and type(scroll)~="function"then
            scroll:ClearAllPoints();scroll:SetPoint("TOPLEFT",log,"TOPLEFT",12,-38);scroll:SetPoint("BOTTOMRIGHT",log,"BOTTOMRIGHT",-28,12)
            local search=scroll.SearchBox
            if search and type(search)~="function"then
                search:ClearAllPoints();search:SetPoint("TOPLEFT",log,"TOPLEFT",12,-8);search:SetWidth(sidebar-140)
                if QuestLogCount then QuestLogCount:SetWidth(100);QuestLogCount:ClearAllPoints();QuestLogCount:SetPoint("TOPLEFT",search,"TOPRIGHT",4,0)end
            end
            if scroll.SettingsDropdown and type(scroll.SettingsDropdown)~="function"then scroll.SettingsDropdown:ClearAllPoints();scroll.SettingsDropdown:SetPoint("TOPRIGHT",log,"TOPRIGHT",-6,-8)end
        end
    end
    local details=log and log.DetailsFrame
    if details and type(details)~="function"then
        details:ClearAllPoints();details:SetAllPoints(log)
        if details.Bg and type(details.Bg)~="function"then details.Bg:ClearAllPoints();details.Bg:SetAllPoints(details)end
        local body=details.ScrollFrame
        if body and type(body)~="function"then
            body:ClearAllPoints();body:SetPoint("TOPLEFT",details,"TOPLEFT",12,-42);body:SetPoint("BOTTOMRIGHT",details,"BOTTOMRIGHT",-28,140)
            if body.Contents and type(body.Contents)~="function"then body.Contents:SetWidth(sidebar-44)end
        end
        local rewards=details.RewardsFrameContainer
        if rewards and type(rewards)~="function"then rewards:SetWidth(sidebar-24);if rewards.RewardsFrame and type(rewards.RewardsFrame)~="function"then rewards.RewardsFrame:SetWidth(sidebar-24)end end
        for i,key in ipairs({"AbandonButton","ShareButton","TrackButton"})do
            local button=details[key]
            if button and type(button)~="function"then button:ClearAllPoints();button:SetPoint("BOTTOMLEFT",details,"BOTTOMLEFT",12+(i-1)*(sidebar-24)/3,4);button:SetWidth((sidebar-24)/3-4)end
        end
    end
    if self.mapContent then self.mapContent:SetWidth(sidebar-44)end
    if self.mapCopy then self.mapCopy:SetWidth(sidebar-44)end
    for _,control in ipairs(self.mapControls or {})do control:SetWidth(sidebar-24)end
    for _,button in ipairs(self.dungeonMapButtons or {})do button:SetWidth(sidebar-44)end
    if type(map.OnFrameSizeChanged)=="function"then map:OnFrameSizeChanged()end
    self.layingOutMap=nil
end
function Q:ApplyMapScale()
    if not WorldMapFrame or not ProjectRuthlessDB.questWorkspace.enabled or InCombatLockdown()then return end
    if self.applyingMapState then return end
    self.applyingMapState=true
    local scale=ProjectRuthlessCharDB.mapScale
    if type(scale)=="number"and scale>=.55 and scale<=1.5 then WorldMapFrame:SetScale(scale)end
    local size=ProjectRuthlessCharDB.mapSize
    if type(size)=="table"and type(size.width)=="number"and type(size.height)=="number"then
        WorldMapFrame:SetSize(math.max(780,math.min(2400,size.width)),math.max(460,math.min(1600,size.height)))
    end
    self:LayoutMap()
    self.applyingMapState=nil
end
function Q:QueueMapRestore()
    if self.applyingMapState or self.mapRestoreQueued or (self.mapResize and self.mapResize.resizing==true)or not ProjectRuthlessDB.questWorkspace.enabled then return end
    if not ProjectRuthlessCharDB.mapSize and not ProjectRuthlessCharDB.mapScale then return end
    self.mapRestoreQueued=true
    C_Timer.After(0,function()
        self.mapRestoreQueued=nil
        if WorldMapFrame and WorldMapFrame:IsShown()and not InCombatLockdown()and not (self.mapResize and self.mapResize.resizing==true)then self:ApplyMapScale()end
    end)
end
function Q:InstallMapPersistence()
    local map=WorldMapFrame
    if self.mapPersistenceInstalled then return end
    self.mapPersistenceInstalled=true
    -- Do not register addon callbacks into the shared secure Escape chain.
    -- Standard special-frame cleanup closes the map before world target cleanup.
    if AUI.isForever and UISpecialFrames then
        local registered=false
        for _,name in ipairs(UISpecialFrames)do if name=="WorldMapFrame"then registered=true;break end end
        if not registered then UISpecialFrames[#UISpecialFrames+1]="WorldMapFrame"end
    end
    for _,method in ipairs({"SetSize","SetWidth","SetHeight","SetScale","SynchronizeDisplayState","SetQuestLogPanelShown"})do
        if type(map[method])=="function"then hooksecurefunc(map,method,function()self:QueueMapRestore()end)end
    end
    -- Preserve the native toggle identity: an addon wrapper taints ShowUIPanel in combat.

end
function Q:InstallMapResize()
    local map=WorldMapFrame
    if self.mapResize then return end
    local grip=AUI:CreateButton(map);grip:SetSize(22,22);grip:SetPoint("BOTTOMRIGHT",-1,1);grip:SetText("+")
    grip:SetFrameStrata(self.mapTabBar:GetFrameStrata());grip:SetFrameLevel(map:GetFrameLevel()+220);self.mapResize=grip
    local function stop()
        local wasResizing=grip.resizing
        grip:SetScript("OnUpdate",nil);grip.resizing=nil
        if wasResizing and not InCombatLockdown()then
            ProjectRuthlessCharDB.mapSize={width=map:GetWidth(),height=map:GetHeight()}
            ProjectRuthlessCharDB.mapScale=map:GetScale()
            local editor=AUI.modules.LayoutEditor
            if editor and editor.targets.map then
                local value=editor:Capture(map)
                if value then editor:Store().elements.map=value end
            end
        end
    end
    grip:SetScript("OnMouseDown",function(_,button)
        if button~="LeftButton"or InCombatLockdown()then return end
        local x,y=GetCursorPosition();local effective=map:GetEffectiveScale()
        local left,top=map:GetLeft(),map:GetTop();local width,height=map:GetWidth(),map:GetHeight()
        if not left or not top or not width or not height or width<=0 or height<=0 then return end
        local base=map:GetScale();local parentScale=UIParent:GetEffectiveScale()
        map:ClearAllPoints();map:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left*effective/parentScale/base,top*effective/parentScale/base)
        local maxWidth=math.max(780,(Call(UIParent.GetWidth,UIParent)or 2400)/base-24)
        local maxHeight=math.max(460,(Call(UIParent.GetHeight,UIParent)or 1600)/base-24)
        grip.resizing=true
        grip:SetScript("OnUpdate",function()
            if InCombatLockdown()then stop();return end
            local cx,cy=GetCursorPosition()
            map:SetSize(math.max(780,math.min(maxWidth,width+(cx-x)/effective)),math.max(460,math.min(maxHeight,height+(y-cy)/effective)))
            self:LayoutMap()
        end)
    end)
    grip:SetScript("OnMouseUp",stop);grip:HookScript("OnHide",stop);map:HookScript("OnHide",stop)
end

local function MapBackground(texture,opacity)
    if AUI.PaintBackground then AUI:PaintBackground(texture,"Map",.025,.028,.035,true)
    else texture:SetColorTexture(.025,.028,.035,opacity)end
end
function Q:StyleMap()
    if InCombatLockdown()or not WorldMapFrame or not ProjectRuthlessDB.questWorkspace.enabled then return end
    local map=WorldMapFrame
    local r,g,b=Accent()
    local opacity=AUI.BackgroundOpacity and AUI:BackgroundOpacity("Map")or math.max(.72,ProjectRuthlessDB.questWorkspace.opacity or .52)
    -- Paint only the shell; canvas textures and all map pins remain native.
    if not map.ruthlessShellBackground or type(map.ruthlessShellBackground)=="function" then
        local bg=map:CreateTexture(nil,"BACKGROUND",nil,-8);bg:SetAllPoints()
        map.ruthlessShellBackground=bg
    end
    MapBackground(map.ruthlessShellBackground,opacity)
    local viewport=map.ScrollContainer
    local child=viewport and type(viewport)~="function" and viewport.Child
    local tiled=child and type(child)~="function" and child.TiledBackground
    if tiled and type(tiled)~="function" then MapBackground(tiled,opacity)end
    local overscroll=map.OverscrollBG
    if overscroll and type(overscroll)~="function"then
        for _,key in ipairs({"Texture","TopLeftVignette","TopRightVignette","BottomLeftVignette","BottomRightVignette"})do
            local region=overscroll[key];if region and type(region)~="function"then
                if key=="Texture"then region:SetColorTexture(.025,.028,.035,1);region:SetAlpha(1)else region:SetAlpha(0)end
            end
        end
    end
    local function flatten(frame)
        if not frame or type(frame)=="function" then return end
        frame.ruthlessMapStyled=true
        for _,key in ipairs({"NineSlice","PortraitContainer","PortraitFrame","Portrait","InsetBorderTop","Border","TopDetail"})do
            local region=frame[key]
            if region and type(region)~="function" and region.SetAlpha then region:SetAlpha(0)end
        end
    end
    local function tint(frame)
        if not frame or type(frame)=="function" or not frame.GetRegions then return end
        for _,region in ipairs({frame:GetRegions()})do
            local kind=region:GetObjectType()
            if kind=="Texture" then region:SetDesaturated(true);region:SetVertexColor(r,g,b,.65)
            elseif kind=="FontString" then region:SetTextColor(r,g,b)end
        end
    end
    local function quietHeader(header)
        if not header.ruthlessHeaderRule then
            for _,region in ipairs({header:GetRegions()})do
                if region:GetObjectType()=="Texture"then region:SetAlpha(0)end
            end
            local rule=header:CreateTexture(nil,"BACKGROUND")
            rule:SetPoint("BOTTOMLEFT",0,0);rule:SetPoint("BOTTOMRIGHT",0,0);rule:SetHeight(1);rule:SetColorTexture(r,g,b,.28)
            header.ruthlessHeaderRule=rule
        end
        for _,region in ipairs({header:GetRegions()})do
            if region:GetObjectType()=="FontString"then region:SetFontObject("GameFontNormal");region:SetTextColor(r,g,b)
            elseif region~=header.ruthlessHeaderRule then region:SetAlpha(0)end
        end
    end
    local function surface(frame)
        if not frame or type(frame)=="function" then return end
        flatten(frame)
        if not frame.ruthlessMapSurface then
            local skin=CreateFrame("Frame",nil,frame,"BackdropTemplate")
            skin:SetAllPoints();skin:SetFrameLevel(frame:GetFrameLevel());skin:EnableMouse(false)
            skin:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
            local top=skin:CreateTexture(nil,"BACKGROUND");top:SetPoint("TOPLEFT",1,-1);top:SetPoint("TOPRIGHT",-1,-1);top:SetHeight(24);top:SetColorTexture(.025,.028,.035,.98)
            local bottom=skin:CreateTexture(nil,"BACKGROUND");bottom:SetPoint("BOTTOMLEFT",1,1);bottom:SetPoint("BOTTOMRIGHT",-1,1);bottom:SetHeight(20);bottom:SetColorTexture(.025,.028,.035,.98)
            AUI:StyleSurface(skin,"window",.96,"Map");skin:SetBackdropBorderColor(r,g,b,.45)
            frame.ruthlessMapSurface=skin
        end
    end
    local border=map.BorderFrame
    surface(border)
    if border and type(border)~="function" and border.GetRegions then
        for _,region in ipairs({border:GetRegions()})do if region:GetObjectType()=="Texture"then region:SetAlpha(0)end end
    end
    if border and type(border)~="function" then
        local title=border.TitleText or border.TitleContainer and border.TitleContainer.TitleText
        if title and type(title)~="function" then title:SetTextColor(r,g,b)end
    end
    if border and type(border)~="function"then
        tint(border.CloseButton)
        local sizing=border.MaximizeMinimizeFrame
        if sizing then tint(sizing.MaximizeButton);tint(sizing.MinimizeButton)end
    end
    local nav=map.NavBar
    local function cleanNavigation(frame,depth)
        if not frame or type(frame)=="function"then return end
        if frame.GetRegions then for _,region in ipairs({frame:GetRegions()})do
            if region:GetObjectType()=="Texture"then region:SetAlpha(0)elseif region:GetObjectType()=="FontString"then region:SetTextColor(.88,.89,.93)end
        end end
        if depth>0 and frame.GetChildren then for _,child in ipairs({frame:GetChildren()})do cleanNavigation(child,depth-1)end end
    end
    cleanNavigation(nav,2)
    local log=map.QuestLog or QuestMapFrame
    local function cleanField(frame)
        if not frame or type(frame)=="function" or not frame.GetRegions then return end
        for _,region in ipairs({frame:GetRegions()})do
            if region:GetObjectType()=="Texture" and region~=frame.ruthlessFieldBackground then region:SetAlpha(0)end
        end
        if not frame.ruthlessFieldBackground or type(frame.ruthlessFieldBackground)=="function" then
            local bg=frame:CreateTexture(nil,"BACKGROUND",nil,-8);bg:SetAllPoints();MapBackground(bg,opacity)
            frame.ruthlessFieldBackground=bg
        end
    end
    if log and type(log)~="function" then
        cleanField(log)
        local quests=log.QuestsFrame
        local scroll=quests and quests.ScrollFrame
        if scroll then
            if scroll.Background then MapBackground(scroll.Background,opacity)end
            cleanField(scroll.SearchBox);cleanField(QuestLogCount)
            local bar=scroll.ScrollBar
            tint(bar)
            if bar and type(bar)~="function"then
                tint(bar.ScrollUpButton);tint(bar.ScrollDownButton);tint(bar.Track)
                if bar.Track then tint(bar.Track.Thumb)end
                local thumb=bar.GetThumbTexture and bar:GetThumbTexture()
                if thumb then thumb:SetDesaturated(true);thumb:SetVertexColor(r,g,b,.65)end
            end
            flatten(scroll.BorderFrame)
        end
        local details=quests and quests.DetailsFrame or log.DetailsFrame
        if details then
            if details.Bg and type(details.Bg)~="function"then details.Bg:ClearAllPoints();details.Bg:SetAllPoints(details);details.Bg:SetColorTexture(.025,.028,.035,.96)end
            flatten(details.BorderFrame)
            self:StyleQuestDetails(details)
        end
    end
    self:SyncMapPage()
    local scroll=QuestScrollFrame
    if scroll and scroll.titleFramePool then
        for button in scroll.titleFramePool:EnumerateActive()do
            local id=button.questID
            local title=id and Call(C_QuestLog.GetTitleForQuestID,id)
            if title and button.Text then
                button.Text:SetFontObject("GameFontNormalSmall")
                button.Text:SetText(self:QuestTitle({id=id,title=title,complete=Call(C_QuestLog.IsComplete,id)==true}))
            end
            if button.HighlightTexture then button.HighlightTexture:SetVertexColor(r,g,b,.25)end
            local checkbox=button.Checkbox
            if checkbox and checkbox.CheckMark then checkbox.CheckMark:SetDesaturated(true);checkbox.CheckMark:SetVertexColor(r,g,b,.65)end
        end
    end
    if scroll and scroll.objectiveFramePool and type(scroll.objectiveFramePool)~="function" then
        for line in scroll.objectiveFramePool:EnumerateActive()do
            if line.Text and type(line.Text)~="function"then
                local text=line.Text:GetText()
                if Public(text) and type(text)=="string"then line.Text:SetText(self:HighlightObjective(text))end
                line.Text:SetTextColor(.88,.9,.94)
            end
        end
    end
    if scroll and scroll.headerFramePool then
        for header in scroll.headerFramePool:EnumerateActive()do
            quietHeader(header)
        end
    end
end

function Q:StyleQuestDetails(details)
    local r,g,b=Accent()
    local function paint(frame,depth)
        if not frame or type(frame)=="function"then return end
        if frame.GetRegions then for _,region in ipairs({frame:GetRegions()})do
            if region:GetObjectType()=="FontString"then region:SetFontObject("GameFontHighlightSmall");region:SetTextColor(.88,.9,.94)
            elseif region:GetObjectType()=="Texture"then region:SetAlpha(0)end
        end end
        if depth>0 and frame.GetChildren then for _,child in ipairs({frame:GetChildren()})do paint(child,depth-1)end end
    end
    paint(details.BackFrame,1)
    if details.SealMaterialBG and type(details.SealMaterialBG)~="function"then details.SealMaterialBG:SetAlpha(0)end
    local rewards=details.RewardsFrameContainer
    local frame=rewards and type(rewards)~="function"and rewards.RewardsFrame
    paint(frame,0) -- Only reward decoration: item/money/XP children retain their icons.
    local scroll=details.ScrollFrame
    if scroll and type(scroll)~="function"and scroll.Contents and type(scroll.Contents)~="function"then
        local contents=scroll.Contents
        local function readable(frame,depth)
            if not frame or type(frame)=="function"then return end
            if frame.GetRegions then for _,region in ipairs({frame:GetRegions()})do
                if region:GetObjectType()=="FontString"then region:SetFontObject("GameFontHighlightSmall");region:SetTextColor(.88,.9,.94)end
            end end
            if depth>0 and frame.GetChildren then for _,child in ipairs({frame:GetChildren()})do readable(child,depth-1)end end
        end
        readable(contents,3)
        if contents.GetRegions then for _,region in ipairs({contents:GetRegions()})do
            if region:GetObjectType()=="FontString"then region:SetTextColor(.88,.9,.94);region:SetFontObject("GameFontHighlightSmall")end
        end end
    end
    for _,key in ipairs({"QuestInfoTitleHeader","QuestInfoDescriptionHeader","QuestInfoRewardsHeader","QuestInfoObjectivesHeader"})do
        local text=_G[key];if text and type(text)~="function" and text.GetParent and scroll and text:GetParent()==scroll.Contents then text:SetFontObject("GameFontNormal");text:SetTextColor(r,g,b)end
    end
    for _,key in ipairs({"AbandonButton","ShareButton","TrackButton"})do paint(details[key],0)end
end

function Q:InstallMap()
    self:StyleMap()
    if self.mapPanel or not WorldMapFrame then return end
    local map=WorldMapFrame
    map:HookScript("OnShow",function()self:StyleMap();if self.mapPage=="Dungeon atlas"then self:RenderMapPage()end end)
    if hooksecurefunc and QuestMapFrame_ShowQuestDetails then hooksecurefunc("QuestMapFrame_ShowQuestDetails",function()self:StyleMap();self:LayoutMap()end)end
    if hooksecurefunc and QuestLogQuests_Update then hooksecurefunc("QuestLogQuests_Update",function()if map:IsShown()then self:StyleMap()end end)end
    local r,g,b=Accent()
    local nativeLog=map.QuestLog or QuestMapFrame
    if type(nativeLog)=="function"then nativeLog=nil end
    self.nativeMapLog=nativeLog
    if nativeLog and nativeLog.GetNumPoints then
        self.nativeLogPoints={}
        for i=1,nativeLog:GetNumPoints()do self.nativeLogPoints[i]={nativeLog:GetPoint(i)}end
    end
    local tabs=CreateFrame("Frame",nil,map,"BackdropTemplate")
    tabs:SetPoint("TOPRIGHT",map,"TOPRIGHT",-8,-60);tabs:SetSize(292,82)
    tabs:SetFrameStrata(nativeLog and nativeLog:GetFrameStrata() or map:GetFrameStrata());tabs:SetFrameLevel(map:GetFrameLevel()+210)
    tabs:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});AUI:StyleSurface(tabs,"window",math.max(.72,ProjectRuthlessDB.questWorkspace.opacity or .52),"Map")
    self.mapTabBar=tabs
    local panel=CreateFrame("Frame",nil,map,"BackdropTemplate")
    panel:SetPoint("TOPLEFT",tabs,"BOTTOMLEFT",0,0);panel:SetPoint("BOTTOMRIGHT",map,"BOTTOMRIGHT",-8,12)
    panel:SetFrameStrata(tabs:GetFrameStrata());panel:SetFrameLevel(map:GetFrameLevel()+200);panel:EnableMouse(true)
    panel:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    AUI:StyleSurface(panel,"window",math.max(.72,ProjectRuthlessDB.questWorkspace.opacity or .52),"Map");panel:SetBackdropBorderColor(r,g,b,.35);panel:Hide();self.mapPanel=panel
    panel:SetScript("OnShow",function()self:SyncMapPage()end)
    if nativeLog then
        nativeLog:HookScript("OnShow",function()self:SyncMapPage()end)
    end
    self.mapTabs={}
    for i,name in ipairs({"Quests","Chapters","Library","Professions","Tools","Settings","Supplies","Dungeons","Dungeon atlas"}) do
        local tab=AUI:CreateButton(tabs); tab:SetSize(90,22); tab:SetPoint("TOPLEFT",8+((i-1)%3)*94,-8-math.floor((i-1)/3)*26); tab:SetText(name);tab.page=name;self.mapTabs[#self.mapTabs+1]=tab
        tab:SetScript("OnClick",function()self:SelectMapPage(name)end)
    end
    self.mapHeading=Text(panel,12,-12,276,"GameFontNormalLarge"); self.mapHeading:SetTextColor(r,g,b)
    local scroll=CreateFrame("ScrollFrame",nil,panel,"UIPanelScrollFrameTemplate");self.mapScroll=scroll
    scroll:SetPoint("TOPLEFT",12,-42); scroll:SetPoint("BOTTOMRIGHT",-30,120)
    local content=CreateFrame("Frame",nil,scroll);self.mapContent=content; content:SetSize(254,1500); scroll:SetScrollChild(content)
    self.mapCopy=Text(content,0,0,250); self.mapCopy:SetTextColor(.88,.88,.9)
    self.mapControls={}
    local specs={{"Track / untrack",function() if self.selected then self:ToggleTracking(self.selected); self:RenderMapPage() end end},{"Skip current",function() if self.selected then self.skipped[self.selected]=true; self:Refresh(); self:RenderMapPage() end end},{"Restore skipped",function() wipe(self.skipped); self:Refresh(); self:RenderMapPage() end},{"Quest marker settings",function() AUI.modules.Menu:Show("mapquests") end}}
    specs[5]={"Toggle direction arrow",function() local s=ProjectRuthlessDB.questWorkspace; s.showArrow=not s.showArrow; self:Navigate(); self:RenderMapPage() end}
    specs[6]={"Change background opacity",function() local s=ProjectRuthlessDB.questWorkspace; s.opacity=s.opacity<.4 and .52 or s.opacity<.7 and .75 or .25; ProjectRuthlessDB.general.backgroundQuest=s.opacity; if AUI.RefreshBackgrounds then AUI:RefreshBackgrounds()end; self:RenderMapPage() end}
    specs[7]={"Lock / unlock position",function() local s=ProjectRuthlessDB.questWorkspace; s.locked=not s.locked; self:RenderMapPage() end}
    specs[8]={"Previous guide step",function() self:GuideAction("back") end}
    specs[9]={"Next guide step",function() self:GuideAction("next") end}
    specs[10]={"Guide step options",function() self:GuideAction("stepOptions") end}
    specs[11]={"Open guide browser",function()
        if self.guide and self.guide.source=="RUI"then self:SelectMapPage("Chapters");return end
        local p=ForeverWispFrame and ForeverWispFrame.route
        local button=p and p.chapter
        if button then Call(Call(button.GetScript,button,"OnClick"),button,"LeftButton") end
    end}
    specs[12]={"Choose guide source",function()self:CycleGuideSource();self:RenderMapPage()end}
    specs[13]={"Auto hand-in: toggle",function()local s=ProjectRuthlessDB.questWorkspace;s.autoHandIn=not s.autoHandIn;self:RenderMapPage()end}
    specs[14]={"Prepare for Westfall: toggle",function()local s=ProjectRuthlessDB.questWorkspace;s.prepWestfall=not s.prepWestfall;self:RenderContext();self:RenderMapPage()end}
    specs[15]={"Prepare for displayed zone: toggle",function()
        local map=Call(WorldMapFrame.GetMapID,WorldMapFrame);if not map then return end
        local s=ProjectRuthlessDB.questWorkspace;s.prepMaps=s.prepMaps or {};s.prepMaps[map]=not s.prepMaps[map]or nil
        self.prepRouteRevision=(self.prepRouteRevision or 0)+1;self:RenderContext();self:RenderMapPage()
    end}
    specs[16]={"Review grey quests to abandon",function()self:ClearGreyQuests()end}
    for i,spec in ipairs(specs) do local control=AUI:CreateButton(panel); control:SetSize(270,22); control:SetPoint("BOTTOMLEFT",12,10+(i<=3 and (7-i)*25 or i>=8 and (11-i)*25 or (8-i)*25)); control:SetText(spec[1]); control:SetScript("OnClick",spec[2]); self.mapControls[i]=control end
    if hooksecurefunc and type(map.UpdateSpacerFrameAnchoring)=="function"then hooksecurefunc(map,"UpdateSpacerFrameAnchoring",function()self:LayoutMap()end)end
    self:InstallMapResize();self:InstallMapPersistence()
    map:HookScript("OnShow",function()self:ApplyMapScale();self:SyncMapPage()end)
    map:HookScript("OnSizeChanged",function()self:SyncMapPage()end)
    self:SyncMapPage()
end




function Q:QuestItems()
    local ids={}
    if self.guide then for id in pairs(self.guide.questIDs or {})do ids[id]=true end;if self.guide.id then ids[self.guide.id]=true end
    elseif self.selected then ids[self.selected]=true end
    local items={};local seen={}
    for id in pairs(ids)do
        local index=Call(C_QuestLog.GetLogIndexForQuestID,id)
        local link,texture
        if index then link,texture=Call(GetQuestLogSpecialItemInfo,index)end
        if type(link)~='string' then texture=link;link=index and Call(GetQuestLogSpecialItemLink,index)end
        if type(link)=="string" and not seen[link]then seen[link]=true;items[#items+1]={link=link,texture=texture,id=id,index=index}end
    end
    table.sort(items,function(a,b)return a.id<b.id end)
    return items
end
function Q:RenderQuestItems()
    if not self.itemRows then return end
    for _,row in ipairs(self.itemRows)do row:Hide()end
    for i,item in ipairs(self:QuestItems())do
        local row=self.itemRows[i]
        if not row then
            row=CreateFrame("Button",nil,self.frame);row:SetSize(268,24)
            row.icon=row:CreateTexture(nil,"ARTWORK");row.icon:SetSize(22,22);row.icon:SetPoint("LEFT",0,0)
            row.label=Text(row,28,-3,236);row.label:SetTextColor(1,.82,.3)
            row:SetScript("OnEnter",function(button)if button.item then GameTooltip:SetOwner(button,"ANCHOR_RIGHT");GameTooltip:SetHyperlink(button.item.link);GameTooltip:Show()end end)
            row:SetScript("OnLeave",function()GameTooltip:Hide()end)
            row:SetScript("OnClick",function(button)
                local link=button.item and button.item.link;if not link then return end
                if HandleModifiedItemClick and HandleModifiedItemClick(link)then return end
                local index=Call(C_QuestLog.GetLogIndexForQuestID,button.item.id)
                local currentLink=index and Call(GetQuestLogSpecialItemInfo,index)
                if index and currentLink==link and type(UseQuestLogSpecialItem)=="function"then UseQuestLogSpecialItem(index)end
            end)
            self.itemRows[i]=row
        end
        row.item=item;row.icon:SetTexture(item.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.label:SetText(item.link);row:Show()
    end
end

function Q:LayoutContent()
    local function height(region,minimum,maximum)
        local measured=Call(region.GetStringHeight,region)
        local text=DisplayText(region):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
        local lines=1;for _ in text:gmatch("\n")do lines=lines+1 end
        if type(measured)~="number" or measured<=0 then measured=math.max(lines,math.ceil(#text/45))*13 end
        return math.max(minimum,math.min(maximum,measured))
    end
    local y=72
    self.phase:ClearAllPoints();self.phase:SetPoint("TOPLEFT",12,-y);y=y+18
    self.currentTitle:ClearAllPoints();self.currentTitle:SetPoint("TOPLEFT",12,-y)
    local titleHeight=height(self.currentTitle,20,40);self.currentTitle:SetHeight(titleHeight);y=y+titleHeight+6
    self.summary:ClearAllPoints();self.summary:SetPoint("TOPLEFT",12,-y)
    local summaryHeight=height(self.summary,14,64);self.summary:SetHeight(summaryHeight);y=y+summaryHeight+8
    local objectiveText=DisplayText(self.objectiveCopy)
    self.objectiveScroll:SetShown(objectiveText~="")
    if objectiveText~="" then
        self.objectiveCopy:Hide()
        self.objectiveDisplayRows=self.objectiveDisplayRows or {}
        local fullHeight=0
        local along=false
        local used=0
        for line in objectiveText:gmatch("[^\n]+")do
            local isAlong=line:find("Along the way · ",1,true)==1
            if isAlong and not along then
                self.alongHeading=self.alongHeading or Text(self.objectiveContent,0,0,254)
                self.alongHeading:ClearAllPoints();self.alongHeading:SetPoint("TOPLEFT",0,-fullHeight)
                self.alongHeading:SetText("ALONG THE WAY");self.alongHeading:SetTextColor(.6,.65,.72);self.alongHeading:Show()
                fullHeight=fullHeight+20;along=true
            end
            used=used+1
            local row=self.objectiveDisplayRows[used]
            if not row then row={name=Text(self.objectiveContent,0,0,202),count=Text(self.objectiveContent,204,0,50)};row.count:SetJustifyH("RIGHT");self.objectiveDisplayRows[used]=row end
            local clean=isAlong and line:sub(#"Along the way · "+1) or line
            local name,count=clean:match("^(.-)%s+(%d+/%d+)$")
            row.name:SetText(self:HighlightObjective(name or clean));row.count:SetText(self:HighlightObjective(count or ""))
            row.name:SetTextColor(.88,.9,.94);row.count:SetTextColor(.96,.96,.98)
            row.name:ClearAllPoints();row.name:SetPoint("TOPLEFT",0,-fullHeight)
            row.count:ClearAllPoints();row.count:SetPoint("TOPLEFT",204,-fullHeight)
            row.name:Show();row.count:Show()
            fullHeight=fullHeight+math.max(22,height(row.name,14,42)+6)
        end
        if self.alongHeading then self.alongHeading:SetShown(along)end
        for i=used+1,#self.objectiveDisplayRows do self.objectiveDisplayRows[i].name:Hide();self.objectiveDisplayRows[i].count:Hide()end
        local visible=math.min(154,fullHeight)
        self.objectiveScroll:ClearAllPoints();self.objectiveScroll:SetPoint("TOPLEFT",12,-y);self.objectiveScroll:SetSize(254,visible)
        self.objectiveContent:SetSize(254,fullHeight);self.objectiveCopy:SetHeight(fullHeight);y=y+visible+10
    end
    for _,row in ipairs(self.itemRows or {})do if row:IsShown()then row:ClearAllPoints();row:SetPoint("TOPLEFT",12,-y);y=y+28 end end
    self.nearbyHeading:ClearAllPoints();self.nearbyHeading:SetPoint("TOPLEFT",12,-y);y=y+18
    for _,row in ipairs(self.rows)do if row:IsShown()then row:ClearAllPoints();row:SetPoint("TOPLEFT",12,-y);y=y+29 end end
    if self.prepCopy and self.prepCopy:IsShown()then
        self.prepCopy:ClearAllPoints();self.prepCopy:SetPoint("TOPLEFT",12,-y)
        local prepHeight=height(self.prepCopy,28,90);self.prepCopy:SetHeight(prepHeight);y=y+prepHeight+10
    end
    y=y+8;self.contextHeading:ClearAllPoints();self.contextHeading:SetPoint("TOPLEFT",12,-y);y=y+18
    local count=0
    for _,row in ipairs(self.contextRows)do if row:IsShown()then row:ClearAllPoints();row:SetPoint("TOPLEFT",12,-y);y=y+29;count=count+1 end end
    self.contextEmpty:ClearAllPoints();self.contextEmpty:SetPoint("TOPLEFT",12,-y)
    if count==0 then y=y-18 end
    if self.dungeonHeading:IsShown()then
        y=y+10;self.dungeonHeading:ClearAllPoints();self.dungeonHeading:SetPoint("TOPLEFT",12,-y);y=y+19
        for _,row in ipairs(self.dungeonRows)do if row:IsShown()then row:ClearAllPoints();row:SetPoint("TOPLEFT",12,-y);y=y+34 end end
    end
    if self.dungeonPrompt:IsShown()then
        y=y+10;self.dungeonPrompt:ClearAllPoints();self.dungeonPrompt:SetPoint("TOPLEFT",12,-y);y=y+36
        self.trackDungeonButton:ClearAllPoints();self.trackDungeonButton:SetPoint("TOPLEFT",12,-y)
        self.dismissDungeonButton:ClearAllPoints();self.dismissDungeonButton:SetPoint("TOPLEFT",152,-y);y=y+28
    end
    if self.tripButton:IsShown()then self.tripButton:ClearAllPoints();self.tripButton:SetPoint("TOPLEFT",12,-y-5);y=y+32 end
    self.frame:SetHeight(y+12)
end


function Q:TrackDungeon(area,enabled)
    self.trackedDungeons[area]=enabled and true or nil
    self.dungeonDismissed[area]=true;self.dungeonOffset=0;self.pendingDungeon=nil
    self:RenderContext()
end
function Q:ShareDungeonQuest(id)
    if InCombatLockdown()then return false,"Share quests outside combat."end
    if Call(IsInGroup)~=true then return false,"Join a party to share quests."end
    if Call(C_QuestLog.IsPushableQuest,id)~=true then return false,"This quest cannot be shared."end
    local index=Call(C_QuestLog.GetLogIndexForQuestID,id)
    if type(index)~="number"or index<=0 or type(QuestLogPushQuest)~="function"then return false,"Quest sharing is unavailable."end
    local ok=pcall(QuestLogPushQuest,index)
    if not ok then return false,"WoW could not share this quest."end
    return true,"Share sent: "..(Call(C_QuestLog.GetTitleForQuestID,id)or tostring(id))..". Wait for your party to respond."
end
function Q:ShareDungeon(area)
    local locations=AUI.modules.QuestLocations
    local catalog=locations and locations:DungeonCatalog(self)or {}
    local ids={}
    for _,group in ipairs(catalog)do if group.area==area then
        for _,entry in ipairs(group.entries)do if not entry.accept and Call(C_QuestLog.IsPushableQuest,entry.id)==true then ids[#ids+1]=entry.id end end
    end end
    table.sort(ids)
    if #ids==0 then return false,"No held quests in this dungeon can be shared."end
    self.dungeonShareState=self.dungeonShareState or {}
    local signature=table.concat(ids,":");local state=self.dungeonShareState[area]
    if not state or state.signature~=signature or state.next>#ids then state={signature=signature,next=1};self.dungeonShareState[area]=state end
    local ok,message=self:ShareDungeonQuest(ids[state.next])
    if ok then state.next=state.next+1 end
    return ok,message,ok and #ids-state.next+1 or #ids
end

function Q:RenderDungeons()
    if not self.dungeonRows then return end
    local locations=AUI.modules.QuestLocations
    local catalog=locations and locations:DungeonCatalog(self) or {}
    local rows=locations and locations:DungeonRows(self) or {}
    self.dungeonOffset=math.max(0,math.min(self.dungeonOffset or 0,math.max(0,#rows-3)))
    self.dungeonHeading:SetShown(#rows>0)
    self.dungeonHeading:SetText("DUNGEONS"..(#rows>3 and " · scroll" or ""))
    for i,row in ipairs(self.dungeonRows)do
        local entry=rows[self.dungeonOffset+i];row.entry=entry;row:SetShown(entry~=nil)
        if entry then row.title:SetText(self:QuestTitle(entry));row.detail:SetText(self:HighlightObjective(entry.detail));row.dungeonArea=nil end
        if row.share then row.share:SetShown(entry~=nil and not entry.accept and Call(C_QuestLog.IsPushableQuest,entry.id)==true and Call(IsInGroup)==true)end
    end
    local map=Call(C_Map.GetBestMapForUnit,"player")
    self.pendingDungeon=nil
    for _,group in ipairs(catalog)do
        local zone=locations.mapping and locations.mapping[group.zone]
        if not self.trackedDungeons[group.area] and not self.dungeonDismissed[group.area] and (group.held>0 or group.pickups>0 or zone==map)then self.pendingDungeon=group;break end
    end
    self.dungeonPrompt:SetShown(self.pendingDungeon~=nil)
    self.trackDungeonButton:SetShown(self.pendingDungeon~=nil);self.dismissDungeonButton:SetShown(self.pendingDungeon~=nil)
    if self.pendingDungeon then self.dungeonPrompt:SetText("Track "..self.pendingDungeon.name.."?\n"..self.pendingDungeon.held.." in log · "..self.pendingDungeon.pickups.." ready to pick up")end
end

function Q:RenderContext()
    if not self.contextRows then return end
    local locations=AUI.modules.QuestLocations
    local entries,inside
    if locations then entries,inside=locations:ContextRows(self) end
    entries=entries or {}
    if inside then entries={}end
    self.contextOffset=math.max(0,math.min(self.contextOffset or 0,math.max(0,#entries-3)))
    self.contextHeading:SetText(("NEARBY")..(#entries>3 and " · scroll" or ""))
    for i,row in ipairs(self.contextRows)do
        local entry=entries[self.contextOffset+i];row.entry=entry;row:SetShown(entry~=nil)
        if entry then row.title:SetText(self:QuestTitle(entry));row.detail:SetText(entry.detail)end
    end
    self.contextEmpty:SetShown(false)
    self.contextHeading:SetShown(#entries>0)
    self.contextEmpty:SetText(inside and "No matching dungeon quests found in your log or available pickups." or "No recorded quests or pickups within 500 yards.")
    self.returnGuide:SetShown(self.manualFocus==true or self.tripArea~=nil)
    local catalog=locations and locations:DungeonCatalog(self) or {}
    local first=catalog[1]
    self.tripSuggestion=first and first.held>0 and {area=first.area,name=first.name,count=first.held} or nil
    self.tripButton:Hide()
    if self.tripSuggestion then self.tripButton:SetText(self.tripSuggestion.name.." · "..self.tripSuggestion.count.." quests · View")end
    self:RenderQuestItems()
    self:UpdatePreparation()
    self:RenderDungeons()
    self:LayoutContent()
end

function Q:SuppressNativeTracker()
    local tracker=ObjectiveTrackerFrame
    if not tracker or (tracker.IsForbidden and tracker:IsForbidden())then return end
    self.nativeTrackerStates=self.nativeTrackerStates or setmetatable({},{__mode="k"})
    local state=self.nativeTrackerStates[tracker]
    if not state then
        state={};self.nativeTrackerStates[tracker]=state
        local function suppress()
            if state.applying or not ProjectRuthlessDB.questWorkspace.enabled then return end
            state.applying=true;tracker:SetAlpha(0);state.applying=nil
        end
        hooksecurefunc(tracker,"SetAlpha",suppress)
        if tracker.HookScript then tracker:HookScript("OnShow",suppress)end
    end
    if ProjectRuthlessDB.questWorkspace.enabled then
        if state.alpha==nil then
            local alpha=tracker:GetAlpha()
            state.alpha=Public(alpha)and type(alpha)=="number"and alpha or 1
        end
        state.applying=true;tracker:SetAlpha(0);state.applying=nil
    elseif state.alpha~=nil then
        state.applying=true;tracker:SetAlpha(state.alpha);state.applying=nil;state.alpha=nil
    end
end

function Q:ApplySettings()
    local enabled=ProjectRuthlessDB.questWorkspace.enabled
    if self.events then
        for _,event in ipairs(self.eventNames)do if enabled then self.events:RegisterEvent(event)else self.events:UnregisterEvent(event)end end
    end
    if enabled and not self.frame then self:CreateWorkspace();self:InstallMap()end
    if not self.frame then return end
    self:SyncMapPage()
    self.frame:SetShown(enabled)
    if InCombatLockdown() then self.pending=true;AUI:AfterCombat("questSettings",function()self:ApplySettings()end);return end
    self.pending=nil
    self:SuppressNativeTracker()
    self:Refresh()
end

function Q:CreateWorkspace()
    if self.frame then return end
    local f=CreateFrame("Frame","ProjectRuthlessQuestWorkspace",UIParent,"BackdropTemplate")
    f:SetSize(292,450); f:SetPoint("RIGHT",UIParent,"RIGHT",-34,45)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    local r,g,b=Accent()
    AUI:StyleSurface(f,"window",math.max(.72,ProjectRuthlessDB.questWorkspace.opacity),"Quest"); f:SetBackdropBorderColor(r,g,b,.22)
    local accent=f:CreateTexture(nil,"ARTWORK");accent:SetColorTexture(r,g,b,.9);accent:SetPoint("TOPLEFT",1,-1);accent:SetPoint("TOPRIGHT",-1,-1);accent:SetHeight(2)
    f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function() if not ProjectRuthlessDB.questWorkspace.locked then f:StartMoving() end end)
    f:SetScript("OnDragStop",function()
        f:StopMovingOrSizing()
        local point,_,relativePoint,x,y=f:GetPoint()
        ProjectRuthlessCharDB.questPanelPosition={point=point,relativePoint=relativePoint,x=x,y=y}
        local editor=AUI.modules.LayoutEditor
        if editor then
            editor:Attach("quests","Quest tracker",f)
            local value=editor:Capture(f)
            if value then editor:Store().elements.quests=value end
        end
    end)
    local saved=ProjectRuthlessCharDB.questPanelPosition
    if saved then f:ClearAllPoints(); f:SetPoint(saved.point,UIParent,saved.relativePoint,saved.x,saved.y) end
    self.frame=f
    local editor=AUI.modules.LayoutEditor
    if editor then editor:Attach("quests","Quest tracker",f)end
    local heading=Text(f,56,-10,224,"GameFontNormal"); heading:SetText("Quests"); heading:SetTextColor(r,g,b)
    self.phase=Text(f,12,-83,260); self.phase:SetTextColor(r,g,b)
    self.currentTitle=Text(f,12,-101,268,"GameFontNormalLarge"); self.currentTitle:SetHeight(34); self.currentTitle:SetTextColor(.96,.96,.97)
    local titleHit=CreateFrame("Button",nil,f);titleHit:SetAllPoints(self.currentTitle)
    titleHit:SetScript("OnClick",function()if self.currentQuestID then self:LinkQuestToChat(self.currentQuestID)end end)
    self.summary=Text(f,12,-139,268); self.summary:SetHeight(60); self.summary:SetTextColor(.92,.92,.94)
    self.destination=Text(f,56,-49,224); self.destination:SetHeight(28); self.destination:SetTextColor(.85,.85,.88)
    self.distance=Text(f,56,-29,224,"GameFontNormal"); self.distance:SetTextColor(r,g,b)
    self.arrow=f:CreateTexture(nil,"ARTWORK"); self.arrow:SetSize(36,36); self.arrow:SetPoint("TOPLEFT",10,-10)
    self.arrow:SetTexture("Interface\\Minimap\\MinimapArrow")
    self.arrow:SetVertexColor(r,g,b)
    local nearby=Text(f,12,-207,268); self.nearbyHeading=nearby; nearby:SetText("NEARBY"); nearby:SetTextColor(r,g,b)
    self.rows={}
    for i=1,3 do
        local row=CreateFrame("Button",nil,f); row:SetSize(268,28); row:SetPoint("TOPLEFT",12,-225-(i-1)*29)
        row.title=Text(row,0,0,264); row.title:SetTextColor(.89,.91,.95)
        row.detail=Text(row,0,-13,264); row.detail:SetTextColor(.78,.78,.8); row.detail:SetHeight(12)
        row:RegisterForClicks("LeftButtonUp","RightButtonUp")
        row:SetScript("OnClick",function(_,button)
            if not row.entry then return end
            if self:LinkQuestToChat(row.entry.id)then return end
            if button=="LeftButton" then self:SetWaypoint(row.entry.id) end
        end)
        self.rows[i]=row
    end
    self.itemRows={}
    self.objectiveScroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate")
    self.objectiveContent=CreateFrame("Frame",nil,self.objectiveScroll);self.objectiveContent:SetSize(254,1);self.objectiveScroll:SetScrollChild(self.objectiveContent)
    self.objectiveCopy=Text(self.objectiveContent,0,0,254);self.objectiveCopy:SetTextColor(.88,.9,.94);self.objectiveCopy:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",12,"");self.objectiveCopy:SetSpacing(5)
    self.tripButton=AUI:CreateButton(f);self.tripButton:SetSize(268,24)
    self.tripButton:SetScript("OnClick",function()if not self.tripSuggestion then return end;self.tripArea=self.tripSuggestion.area;self.contextOffset=0;self:RenderContext()end);self.tripButton:Hide()
    self.contextHeading=Text(f,12,-320,268);self.contextHeading:SetTextColor(r,g,b)
    self.contextRows={}
    for i=1,3 do
        local row=CreateFrame("Button",nil,f);row:SetSize(268,28);row:SetPoint("TOPLEFT",12,-340-(i-1)*29)
        row.title=Text(row,0,0,264);row.title:SetTextColor(r,g,b);row.detail=Text(row,0,-13,264);row.detail:SetHeight(12)
        row:SetScript("OnClick",function()
            local entry=row.entry;if entry and self:LinkQuestToChat(entry.id)then return end;if not entry then return end
            self.manualFocus=true;self.manualPickup=nil
            if entry.accept then self.manualPickup={id=entry.id,title=entry.title,detail="Pick up quest",distance=entry.distance,point=entry.point}end
            self:SetWaypoint(entry.id);self:RenderContext()
        end)
        row:EnableMouseWheel(true);row:SetScript("OnMouseWheel",function(_,delta)self.contextOffset=(self.contextOffset or 0)-delta;self:RenderContext()end)
        self.contextRows[i]=row
    end
    self.dungeonHeading=Text(f,12,-340,268);self.dungeonHeading:SetTextColor(r,g,b)
    self.dungeonRows={}
    for i=1,3 do
        local row=CreateFrame("Button",nil,f);row:SetSize(268,32)
        row.title=Text(row,0,0,264,"GameFontHighlight");row.detail=Text(row,0,-16,264);row.detail:SetHeight(14);row.detail:SetTextColor(.67,.7,.76)
        row:SetScript("OnClick",function()
            local entry=row.entry;if entry and self:LinkQuestToChat(entry.id)then return end;if not entry then return end
            self.manualFocus=true;self.manualPickup=entry.accept and {id=entry.id,title=entry.title,detail="Pick up quest",point=entry.point} or nil
            self:SetWaypoint(entry.id)
        end)
        row:EnableMouseWheel(true);row:SetScript("OnMouseWheel",function(_,delta)self.dungeonOffset=(self.dungeonOffset or 0)-delta;self:RenderContext()end)
        row.share=AUI:CreateButton(row);row.share:SetSize(44,16);row.share:SetPoint("TOPRIGHT",0,0);row.share:SetText("Share")
        row.title:SetWidth(214)
        row.share:SetScript("OnClick",function()if row.entry then local _,message=self:ShareDungeonQuest(row.entry.id);if AUI.Print then AUI:Print(message)end end end)
        self.dungeonRows[i]=row
    end
    self.dungeonPrompt=Text(f,12,-340,268);self.dungeonPrompt:SetHeight(34);self.dungeonPrompt:SetTextColor(.93,.85,.65)
    self.trackDungeonButton=AUI:CreateButton(f);self.trackDungeonButton:SetSize(130,22);self.trackDungeonButton:SetText("Track dungeon")
    self.trackDungeonButton:SetScript("OnClick",function()if self.pendingDungeon then self:TrackDungeon(self.pendingDungeon.area,true)end end)
    self.dismissDungeonButton=AUI:CreateButton(f);self.dismissDungeonButton:SetSize(128,22);self.dismissDungeonButton:SetText("Not now")
    self.dismissDungeonButton:SetScript("OnClick",function()if self.pendingDungeon then self.dungeonDismissed[self.pendingDungeon.area]=true;self:RenderContext()end end)
    self.contextEmpty=Text(f,12,-340,268);self.contextEmpty:SetHeight(46)
    self.menuButton=AUI:CreateButton(f);self.menuButton:SetSize(48,18);self.menuButton:SetPoint("TOPRIGHT",-8,-8);self.menuButton:SetText("Menu")
    self.menuButton:SetScript("OnClick",function()self:OpenDungeonMenu()end)
    self.returnGuide=AUI:CreateButton(f);self.returnGuide:SetSize(48,18);self.returnGuide:SetPoint("TOPRIGHT",-60,-8);self.returnGuide:SetText("Guide")
    self.returnGuide:SetScript("OnClick",function()self.manualFocus=nil;self.manualPickup=nil;self.tripArea=nil;if AUI.modules.QuestLocations then AUI.modules.QuestLocations.selectedQuest=nil end;self:Refresh()end);self.returnGuide:Hide()
    self.empty=Text(f,12,-92,266); self.empty:SetText("No quests displayed. Accept a quest or restore hidden quests below.")
    f:EnableMouseWheel(true); f:SetScript("OnMouseWheel",function(_,delta) self.offset=self.offset-delta; self:Refresh() end)
    local lastMap,lastX,lastY
    AUI:BindInterval(f,.25,function()self:Navigate()end)
    AUI:BindInterval(f,2,function()
        local guide=self:ReadGuide()
        local parts={guide and guide.target or "",guide and guide.quest or "",guide and guide.phase or "",guide and guide.count or "",guide and guide.instruction or "",tostring(guide and guide.id)}
        if guide then
            for _,text in ipairs(guide.objectives or {})do parts[#parts+1]=text end
            for _,row in ipairs(guide.next or {})do parts[#parts+1]=row.title;parts[#parts+1]=row.detail end
        end
        local signature=table.concat(parts,"\031")
        local changed=signature~=self.lastGuideSignature;self.lastGuideSignature=signature
        if changed then
            if self.guide and not guide then self.guide=nil;self:Refresh()else self:RenderGuide(guide);if self.RefreshPins then self:RefreshPins()end;self:RenderContext()end
        end
        local map=Call(C_Map.GetBestMapForUnit,"player")
        local position=Call(C_Map.GetPlayerMapPosition,map,"player")
        local x,y
        if position then local ok,px,py=pcall(position.GetXY,position);if ok and Public(px)and Public(py)then x,y=px,py end end
        if not changed and (map~=lastMap or x and y and (not lastX or math.abs(x-lastX)+math.abs(y-lastY)>.002))then self:RenderContext()end
        lastMap,lastX,lastY=map,x,y
    end)
end

-- Establish a silent baseline, then announce only unfinished -> finished edges.
-- Runs with the existing batched quest refresh, never on a polling timer.
function Q:AnnounceQuestProgress()
    if not C_QuestLog then return end
    local previous=self.partyQuestState or {}
    local nextState={}
    local party=Call(IsInGroup)==true and Call(IsInRaid)~=true
    local count=Call(C_QuestLog.GetNumQuestLogEntries)or 0
    for i=1,count do
        local info=Call(C_QuestLog.GetInfo,i)
        if info and Public(info.questID)and Public(info.isHeader)and Public(info.title)and not info.isHeader and info.questID then
            local id=info.questID
            local state={objectives={},complete=Call(C_QuestLog.IsComplete,id)==true}
            local before=previous[id]
            local finished={}
            for index,objective in ipairs(Call(C_QuestLog.GetQuestObjectives,id)or {})do
                if Public(objective.finished)and Public(objective.text)and Public(objective.objectID)and Public(objective.type)then
                    local key=tostring(objective.type)..":"..tostring(objective.objectID)..":"..index
                    state.objectives[key]=objective.finished==true
                    if before and before.objectives[key]==false and objective.finished==true and type(objective.text)=="string"then finished[#finished+1]=objective.text end
                end
            end
            nextState[id]=state
            if party and before and (not before.complete and state.complete or #finished>0)then
                local message="[RUI] "..(info.title or "Quest")..": "..(state.complete and "Complete — ready to turn in!" or table.concat(finished,"; "))
                -- Keep the chat payload short without splitting a UTF-8 character.
                if #message>240 then message=message:sub(1,237):gsub("[\194-\244][\128-\191]*$","").."..."end
                if SendChatMessage then SendChatMessage(message,"PARTY")end
            end
        end
    end
    self.partyQuestState=nextState
end

function Q:OnPlayerLogin()
    if ProjectRuthlessDB.questWorkspace.enabled then self:AnnounceQuestProgress()end
    self.trackedDungeons=ProjectRuthlessCharDB.trackedDungeons or {}
    self.dungeonDismissed=ProjectRuthlessCharDB.dungeonDismissed or {}
    ProjectRuthlessCharDB.trackedDungeons=self.trackedDungeons;ProjectRuthlessCharDB.dungeonDismissed=self.dungeonDismissed
    self.skipped=ProjectRuthlessCharDB.skippedQuestWorkspace or {}
    ProjectRuthlessCharDB.skippedQuestWorkspace=self.skipped
    local events=CreateFrame("Frame")
    self.eventNames={"QUEST_LOG_UPDATE","QUEST_ACCEPTED","QUEST_REMOVED","QUEST_TURNED_IN","QUEST_POI_UPDATE","PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","ADDON_LOADED","MERCHANT_SHOW","MERCHANT_UPDATE","BAG_UPDATE_DELAYED","ZONE_CHANGED_NEW_AREA","PLAYER_LEVEL_UP","QUEST_PROGRESS","QUEST_COMPLETE","AUCTION_HOUSE_SHOW","AUCTION_HOUSE_CLOSED","GET_ITEM_INFO_RECEIVED"}
    events:SetScript("OnEvent",function(_,event)
        if not ProjectRuthlessDB.questWorkspace.enabled then return end
        if event=="AUCTION_HOUSE_SHOW"then self.prepAuctionOpen=true elseif event=="AUCTION_HOUSE_CLOSED"then self.prepAuctionOpen=nil end
        if event=="QUEST_PROGRESS"or event=="QUEST_COMPLETE"then self:AutoHandIn(event);return end
        if event=="PLAYER_REGEN_ENABLED" and self.pending then self:ApplySettings()end
        if event=="PLAYER_REGEN_ENABLED"and self.pendingMapObjective then self:SyncMapObjective()end
        if event=="ADDON_LOADED"or event=="QUEST_ACCEPTED"or event=="QUEST_REMOVED"then self.guideName=nil end
        if event=="ADDON_LOADED" then self:InstallMap();self:SuppressNativeTracker()end
        if event=="MERCHANT_SHOW" or event=="MERCHANT_UPDATE" then
            local advice=self:SupplyAdvice(true)
            local key=table.concat(advice,";")
            if #advice>0 and key~=self.lastSupplyNotice then self.lastSupplyNotice=key; AUI:Print("Buy for Dry Times: "..key:gsub("\n"," · ")) end
        end
        -- Quest and bag events arrive across several frames during looting/dialogue.
        -- Give the native log time to settle before rebuilding the tracker once.
        if event~="QUEST_LOG_UPDATE" and event~="BAG_UPDATE_DELAYED" and event~="QUEST_POI_UPDATE" then self.eventRefreshForced=true end
        if not self.eventRefreshQueued then
            self.eventRefreshQueued=true
            C_Timer.After(.35,function()
                self.eventRefreshQueued=nil
                local skipUnchanged=not self.eventRefreshForced
                self.eventRefreshForced=nil
                if ProjectRuthlessDB.questWorkspace.enabled then self:AnnounceQuestProgress();self:Refresh(skipUnchanged)end
            end)
        end
    end)
    self.events=events
    self:ApplySettings()
end


