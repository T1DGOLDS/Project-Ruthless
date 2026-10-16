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
function G:Start(id,chapter)
    self:Catalog();local route=self.byID[id]
    if not route or route.faction~=read(UnitFactionGroup,"player")then return false end
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
        if route.kind~="detour"and route.faction==faction and level>=route.min and level<=route.max and (mapping and maps[mapping[route.area]]or names[route.name])then
            if not candidate or route.min>candidate.min then candidate=route end
        end
    end
    -- At a shared boundary (for example level 20), prefer the continuation.
    -- Small optional trips never take over an unconfigured leveling guide.
    if candidate then
        local route=candidate
        local chapter=1
        for i,hub in ipairs(route.hubs)do if level>=hub.min then chapter=i end end
        -- Continue the chapter containing already-held route quests.
        local held={};for _,entry in ipairs(q.entries or {})do if entry~=q.manualPickup then held[entry.id]=true end end
        for i,hub in ipairs(route.hubs)do
            local found=false;for _,id in ipairs(hub.quests)do if held[id]then found=true;break end end
            if found then chapter=i;break end
        end
        state.route=route.id;state.chapter=chapter;state.revision=(state.revision or 0)+1
    end
end
function G:Read(q)
    if not ProjectRuthlessCharDB.authoredGuide or not ProjectRuthlessCharDB.authoredGuide.route then return end
    local state,route=self:State()
    if not route or state.paused then return end
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
    local chosen,phase,reason,hub,pending
    for advance=1,#route.hubs do
        hub=route.hubs[chapter]
        local buckets={accept={},objective={},turn={},uncertain={},blocked={}};pending={}
        for _,id in ipairs(hub.quests)do local mode,why=status(id);if mode~="done"then buckets[mode][#buckets[mode]+1]={id=id,reason=why}end end
        for _,mode in ipairs({"accept","objective","turn","uncertain","blocked"})do
            for _,step in ipairs(buckets[mode])do pending[#pending+1]={id=step.id,mode=mode,reason=step.reason}end
            if not chosen and buckets[mode][1]then chosen=buckets[mode][1].id;phase=mode;reason=buckets[mode][1].reason end
        end
        if chosen or chapter==#route.hubs then break end
        chapter=chapter+1
    end
    state.chapter=chapter;self.currentID=chosen
    local fact=chosen and self.facts[tostring(chosen)]
    local names={accept="PICK UP",objective="CURRENT OBJECTIVE",turn="TURN IN",uncertain="CHECK QUEST GIVER",blocked="REQUIREMENTS",done="ROUTE COMPLETE"}
    local guide={source="RUI",id=chosen,phase=names[phase or "done"],quest=fact and fact.title or route.name.." complete",target=hub.name,count=chapter.." / "..#route.hubs,instruction=hub.note:match("^.-%.")or hub.note,routeNote=hub.note,objectives={},next={},questIDs={},futureQuestIDs={}}
    if reason then guide.instruction=reason..". "..guide.instruction end
    if fact then guide.level=fact.level;guide.availability=phase=="uncertain"and "unknown"or nil end
    for _,id in ipairs(hub.quests)do
        local mode=status(id)
        if mode~="done"then guide.questIDs[id]=true end
        if mode=="objective"then
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
        q.mapHeading:SetText(active.name.." · Chapters")
        local hub=active.hubs[state.chapter or 1]
        q.mapCopy:SetText(hub.name.."\n\n"..hub.note)
        offset=math.max(120,(read(q.mapCopy.GetStringHeight,q.mapCopy)or 108)+12)
        row(state.paused and "Resume RUI guide"or "Pause RUI guide",function()self:Action("pause")end)
        row("Stop RUI guide",function()self:Action("stop")end)
        if AUI.modules.QuestProgression then
            row("View quests in progression",function()AUI.modules.QuestProgression:Open("route:"..active.id)end)
        end
        for i,hub in ipairs(active.hubs)do local chapter=i;row((i==state.chapter and "› "or "")..i.." · "..hub.name.."\nLevels "..hub.min.."–"..hub.max,function()self:Start(active.id,chapter)end)end
        row("Skip current guide quest · keeps quest in log",function()self:Action("skip")end)
    else
        q.mapHeading:SetText("RUI · 1–30 guides")
        if AUI.modules.QuestData then
            q.mapCopy:SetText("Ordered RUI routes with native quest offers. Missing spawn locations and pickup requirements are not inferred; check the quest giver when prompted.")
            offset=math.max(100,(read(q.mapCopy.GetStringHeight,q.mapCopy)or 84)+16)
        end
        local faction=read(UnitFactionGroup,"player")
        for _,route in ipairs(self:Catalog())do
            if route.faction==faction then
                local id=route.id
                row(route.name.." · "..route.min.."–"..route.max.."\n"..(route.kind=="detour"and "Optional detour"or #route.hubs.." authored chapters")..(state.route==id and " · active"or ""),function()self:Start(id)end)
            end
        end
    end
    q.mapContent:SetHeight(math.max(1,offset+index*48))
end
