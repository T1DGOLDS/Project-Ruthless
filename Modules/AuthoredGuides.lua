local _,AUI=...
local G={rows={}}
AUI:RegisterModule("AuthoredGuides",G)
local function read(fn,...)
    if type(fn)~="function"then return end
    local ok,value=pcall(fn,...)
    if ok and not(issecretvalue and issecretvalue(value))then return value end
end
function G:Catalog()
    if not self.routes then
        self.routes,self.facts=AUI.CreateAuthoredGuides();self.byID={}
        if AUI.AddZephrasGuides then AUI.AddZephrasGuides(self.routes,self.facts)end
        for _,route in ipairs(self.routes)do self.byID[route.id]=route end
    end
    return self.routes
end
function G:State()
    self:Catalog()
    ProjectRuthlessCharDB.authoredGuide=ProjectRuthlessCharDB.authoredGuide or {chapter=1,skipped={}}
    local state=ProjectRuthlessCharDB.authoredGuide
    state.skipped=state.skipped or {}
    return state,self.byID[state.route]
end
local function matchesRace(route)
    return not route.race or read(function()local _,token=UnitRace("player");return token end)==route.race
end
function G:BrowseRoutes(allLevels)
    local faction=read(UnitFactionGroup,"player");local level=read(UnitLevel,"player")or 1
    local map=C_Map and read(C_Map.GetBestMapForUnit,"player")
    local info=map and C_Map.GetMapInfo and read(C_Map.GetMapInfo,map)
    local list={}
    for _,route in ipairs(self:Catalog())do
        if route.faction==faction and matchesRace(route)and (allLevels or route.min<=level+3 and route.max>=level-3)then list[#list+1]=route end
    end
    table.sort(list,function(a,b)
        local hereA=a.mapID==map or info and a.name==info.name
        local hereB=b.mapID==map or info and b.name==info.name
        if not not hereA~=not not hereB then return not not hereA end
        if a.min~=b.min then return a.min<b.min end
        if a.max~=b.max then return a.max<b.max end
        return a.name==b.name and a.id<b.id or a.name<b.name
    end)
    return list
end
function G:StepInstruction(id,phase,hub,db,reason)
    if phase=="blocked"then return reason or "Check the requirements before continuing."end
    local giver
    if id and db and db.Quest and db.Quest.Get and (phase=="accept"or phase=="uncertain"or phase=="turn")then
        local actors=read(db.Quest.Get,id,phase=="turn"and "finishedBy"or "startedBy")
        local npc=type(actors)=="table"and type(actors[1])=="table"and actors[1][1]
        if npc and db.Npc and db.Npc.Get then giver=read(db.Npc.Get,npc,"name")end
    end
    local place=hub and hub.name or "the marked area"
    local who=type(giver)=="string"and giver or "the quest giver"
    if phase=="accept"then return "Pick up this quest from "..who.." · "..place.."."end
    if phase=="uncertain"then return "Check "..who.." · "..place..". "..(reason or "Pickup availability is not verified.")end
    if phase=="turn"then return "Return to "..who.." · "..place.." to hand in this quest."end
    if phase=="objective"then return "Complete this quest's objectives below · "..place.."."end
    return "Chapter finished. Open Guides to choose where to continue."
end
function G:Start(id,chapter)
    self:Catalog();local route=self.byID[id]
    if not route or route.faction~=read(UnitFactionGroup,"player")or not matchesRace(route)then return false end
    local state=self:State()
    if state.route~=id then state.skipped={}end
    state.route=id;state.chapter=math.max(1,math.min(#route.hubs,chapter or 1));state.paused=nil;state.stopped=nil
    local q=AUI.modules.QuestWorkspace
    q.manualFocus=nil;q.manualPickup=nil
    if AUI.modules.QuestLocations then AUI.modules.QuestLocations.selectedQuest=nil end
    state.revision=(state.revision or 0)+1;q.mapPage="Chapters";q:SyncMapPage();q:Refresh();return true
end
function G:Action(action)
    local state,route=self:State();if not route then return end
    if action=="stepOptions"or action=="open"then AUI.modules.QuestWorkspace:SelectMapPage("Chapters");return end
    if action=="back"then state.chapter=math.max(1,(state.chapter or 1)-1)
    elseif action=="skip"and self.currentID then state.skipped[self.currentID]=true
    elseif action=="next"then state.chapter=math.min(#route.hubs,(state.chapter or 1)+1)
    elseif action=="pause"then state.paused=not state.paused
    elseif action=="stop"then state.route=nil;state.stopped=true;state.paused=nil;self.currentID=nil end
    state.revision=(state.revision or 0)+1;AUI.modules.QuestWorkspace:Refresh()
end
-- Auto-start only an unconfigured RUI guide in the player's supported zone.
-- Explicit stops/pauses and external provider choices remain deliberate.
function G:EnsureStarted(q)
    local state,active=self:State()
    if active or state.stopped then return end
    local faction=read(UnitFactionGroup,"player");local level=read(UnitLevel,"player")or 1
    local locations=AUI.modules.QuestLocations;local mapping=locations and locations.mapping
    local map=C_Map and read(C_Map.GetBestMapForUnit,"player")
    local maps,names={},{}
    for _=1,4 do
        if not map then break end
        maps[map]=true
        local info=C_Map.GetMapInfo and read(C_Map.GetMapInfo,map)
        if not info then break end
        names[info.name or ""]=true;map=info.parentMapID
    end
    local candidate
    for _,route in ipairs(self:Catalog())do
        if not route.draft and route.kind~="detour"and route.faction==faction and level>=route.min and level<=route.max and matchesRace(route) and (maps[route.mapID]or mapping and maps[mapping[route.area]]or names[route.name])then
            if not candidate or route.min>candidate.min then candidate=route end
        end
    end
    -- At a shared boundary (for example level 20), prefer the continuation.
    -- Small optional trips never take over an unconfigured leveling guide.
    if candidate then
        local route=candidate
        local chapter=1
        if not route.hubs[1].loops then
            for i,hub in ipairs(route.hubs)do if level>=hub.min then chapter=i end end
            -- Continue the chapter containing already-held route quests.
            local held={};for _,entry in ipairs(q.entries or {})do if entry~=q.manualPickup then held[entry.id]=true end end
            for i,hub in ipairs(route.hubs)do
                local found=false;for _,id in ipairs(hub.quests)do if held[id]then found=true;break end end
                if found then chapter=i;break end
            end
        end
        state.route=route.id;state.chapter=chapter;state.revision=(state.revision or 0)+1
    end
end
function G:Read(q)
    if not ProjectRuthlessCharDB.authoredGuide or not ProjectRuthlessCharDB.authoredGuide.route then return end
    local state,route=self:State()
    if not route or state.paused or not matchesRace(route)then return end
    local level=read(UnitLevel,"player")or 1
    local locations=AUI.modules.QuestLocations
    local db=locations and locations.Database and locations:Database()
    local key=tostring(state.route)..":"..tostring(state.chapter)..":"..tostring(state.revision)..":"..tostring(q.entriesSignature)..":"..level..":"..tostring(db)..":"..tostring(locations and locations.offers)..":"..tostring(locations and locations.availabilityRevision)
    if self.readKey==key then return self.readCache end
    local held={};for _,entry in ipairs(q.entries or {})do if entry~=q.manualPickup then held[entry.id]=entry end end
    local statusCache={};local function statusRaw(id)
        if state.skipped[id]or read(C_QuestLog.IsQuestFlaggedCompleted,id)==true then return "done"end
        if held[id]then return held[id].complete and "turn"or "objective"end
        local fact=self.facts[tostring(id)]
        if level<fact.min then return "blocked","Requires level "..fact.min end
        if db and locations and locations.PlayerEligibility then
            local eligible,reason,unknown=locations:PlayerEligibility(id,db)
            if not eligible and not unknown then return "blocked",reason or "Requirements not met"end
            if unknown then return "uncertain",reason or "Confirm availability with the quest giver"end
        else return "uncertain","Quest requirements are unverified; check the quest giver"end
        return "accept"
    end
    local function status(id)
        if not statusCache[id]then local mode,reason=statusRaw(id);statusCache[id]={mode,reason}end
        return statusCache[id][1],statusCache[id][2]
    end
    local chapter=state.chapter or 1
    local chosen,phase,reason,hub,pending,group
    local function collect(quests,ordered)
        local buckets={accept={},objective={},turn={},uncertain={},blocked={}}
        -- An unverified pickup cannot displace work the player actually has.
        -- Collect confirmed nearby offers first, then objectives/turn-ins;
        -- uncertain and blocked alternatives remain available in chapter detail.
        local order={"accept","objective","turn","uncertain","blocked"}
        local steps={}
        for _,id in ipairs(quests)do
            local mode,why=status(id)
            if mode~="done"then buckets[mode][#buckets[mode]+1]={id=id,reason=why,mode=mode}end
        end
        for _,mode in ipairs(order)do
            for _,step in ipairs(buckets[mode])do steps[#steps+1]=step end
        end
        return steps
    end
    for advance=1,#route.hubs do
        hub=route.hubs[chapter]
        pending={}
        for _,loop in ipairs(hub.loops or {hub})do
            pending=collect(loop.quests,hub.loops~=nil)
            if pending[1]then group=loop;break end
        end
        local step=pending[1]
        if step then chosen,phase,reason=step.id,step.mode,step.reason end
        if chosen or chapter==#route.hubs then break end
        chapter=chapter+1
    end
    state.chapter=chapter;self.currentID=chosen
    local fact=chosen and self.facts[tostring(chosen)]
    local names={accept="PICK UP",objective="CURRENT OBJECTIVE",turn="TURN IN",uncertain="CHECK QUEST GIVER",blocked="REQUIREMENTS",done="ROUTE COMPLETE"}
    local guide={source="RUI",id=chosen,phase=names[phase or "done"],quest=fact and fact.title or route.name.." complete",target=hub.name,count=chapter.." / "..#route.hubs,instruction=hub.note:match("^.-%.")or hub.note,routeNote=hub.note,objectives={},next={},questIDs={},futureQuestIDs={}}
    if not chosen and hub.loops and next(state.skipped)then
        guide.phase="ROUTE REVIEW";guide.quest="Review skipped quests";guide.instruction="Check the chapter list for any skipped steps you still need."
    end
    guide.stepNote=group and group.note or hub.note
    guide.instruction=self:StepInstruction(chosen,phase,hub,db,reason)
    if fact then guide.level=fact.level;guide.availability=phase=="uncertain"and "unknown"or nil end
    for _,id in ipairs((group or hub).quests)do
        local mode=status(id)
        if mode~="done"then guide.questIDs[id]=true end
        if mode=="objective"and id==chosen then
            local entry=held[id];guide.objectives[#guide.objectives+1]=entry.title.."  "..(entry.detail or "")
        end

    end
    for _,step in ipairs(pending)do
        if step.id~=chosen and #guide.next<3 then
            local nextFact=self.facts[tostring(step.id)]
            guide.next[#guide.next+1]={id=step.id,title=nextFact.title,level=nextFact.level,detail=step.reason or names[step.mode],availability=step.mode=="uncertain"and "unknown"or nil}
        end
    end
    for i=chapter,math.min(#route.hubs,chapter+1)do for _,id in ipairs(route.hubs[i].quests)do if status(id)~="done"then guide.futureQuestIDs[id]=true end end end
    guide.route=route.id;guide.chapter=chapter
    self.readKey=key;self.readCache=guide
    return guide
end
function G:HideBrowser()
    for _,row in ipairs(self.rows)do row:Hide()end
end
function G:RenderBrowser(q,page)
    self:HideBrowser();q.mapCopy:SetText("")
    for _,control in ipairs(q.mapControls or {})do control:Hide()end
    q.mapScroll:ClearAllPoints();q.mapScroll:SetPoint("TOPLEFT",12,-42);q.mapScroll:SetPoint("BOTTOMRIGHT",-30,12)
    local state,active=self:State();local index=0;local offset=0
    local function row(text,click)
        index=index+1;local button=self.rows[index]
        if not button then button=AUI:CreateButton(q.mapContent);self.rows[index]=button end
        button:ClearAllPoints();button:SetPoint("TOPLEFT",0,-offset-(index-1)*48);button:SetSize(read(q.mapContent.GetWidth,q.mapContent)or 300,42);button:SetText(text)
        button:SetScript("OnClick",function()click();q:RenderMapPage()end);button:Show()
    end
    if page=="Chapters"and active then
        if q.SetMapBack then q:SetMapBack("‹ Guides",function()q:ReturnMapPage("Library")end)end
        q.mapHeading:SetText(active.name.." · Chapters")
        local hub=active.hubs[state.chapter or 1]
        local guide=self:Read(q)
        local copy={hub.name,"Levels "..hub.min.."–"..hub.max.." · Chapter "..(state.chapter or 1).." of "..#active.hubs}
        if guide then copy[#copy+1]=(guide.phase or "Current step").." · "..(guide.quest or "").."\n"..(guide.instruction or "")end
        local settings=ProjectRuthlessDB.questWorkspace
        if settings.guideDetail then copy[#copy+1]=hub.note end
        if hub.loops and settings.guideDetail then
            for index,loop in ipairs(hub.loops)do
                local titles={}
                for _,id in ipairs(loop.quests)do titles[#titles+1]=self.facts[tostring(id)].title end
                copy[#copy+1]=index..". "..table.concat(titles," + ")
            end
            if #hub.optional>0 then
                local titles={}
                for _,id in ipairs(hub.optional)do titles[#titles+1]=self.facts[tostring(id)].title end
                copy[#copy+1]="Side quests: "..table.concat(titles,", ")
            end
        end
        q.mapCopy:SetText(table.concat(copy,"\n\n"))
        offset=math.max(120,(read(q.mapCopy.GetStringHeight,q.mapCopy)or 108)+12)
        row(settings.guideDetail and "Guide detail: Expanded"or "Guide detail: Current step",function()settings.guideDetail=not settings.guideDetail;q:Refresh()end)
        row(settings.guideUpcoming~=false and "Upcoming step: Show"or "Upcoming step: Hide",function()settings.guideUpcoming=settings.guideUpcoming==false;q:Refresh()end)
        row(settings.guideOtherQuests==true and "Other active quests: Show"or "Other active quests: Hide",function()settings.guideOtherQuests=not settings.guideOtherQuests;q:Refresh()end)
        if not q.SetMapBack then row("‹ All guides",function()q:SelectMapPage("Library")end)end
        row(state.paused and "Resume RUI guide"or "Pause RUI guide",function()self:Action("pause")end)
        row("Stop RUI guide",function()self:Action("stop")end)
        if AUI.modules.QuestProgression then
            row("View quests in progression",function()AUI.modules.QuestProgression:Open("route:"..active.id)end)
        end
        for i,hub in ipairs(active.hubs)do local chapter=i;row((i==state.chapter and "› "or "")..i.." · "..hub.name.."\nLevels "..hub.min.."–"..hub.max,function()self:Start(active.id,chapter)end)end
        row("Skip current guide quest · keeps quest in log",function()self:Action("skip")end)
    else
        q.mapHeading:SetText("Leveling guides")
        if AUI.modules.QuestData then
            q.mapCopy:SetText("Choose a route for your faction and level. Your current zone is first. RUI routes are original and still need live route validation; unknown pickup requirements stay labelled.")
            offset=math.max(100,(read(q.mapCopy.GetStringHeight,q.mapCopy)or 84)+16)
        end
        if active then row("Current guide · "..active.name,function()q:SelectMapPage("Chapters")end)end
        row(self.showAllLevels and "Level filter: All routes"or "Level filter: Near my level",function()self.showAllLevels=not self.showAllLevels end)
        local routes=self:BrowseRoutes(self.showAllLevels)
        if #routes==0 then row("No nearby route · Show all levels",function()self.showAllLevels=true end)end
        for _,route in ipairs(routes)do
                local id=route.id
                row(route.name.." · "..route.min.."–"..route.max.."\n"..(route.kind=="detour"and "Optional detour"or #route.hubs.." authored chapters")..(route.draft and " · live check pending"or "")..(state.route==id and " · active"or ""),function()self:Start(id)end)
        end
    end
    q.mapContent:SetHeight(math.max(1,offset+index*48))
end
