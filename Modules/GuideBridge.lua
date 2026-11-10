local _,AUI=...
-- Optional route protocol and old RUI settings are isolated here. Product text
-- and native/RUI quest behavior do not depend on a provider brand.
local B={}
AUI.GuideBridge=B
local function Public(v)return not(issecretvalue and issecretvalue(v))end
local function Call(fn,...)
 if type(fn)~="function"then return end
 local ok,a,b=pcall(fn,...);if ok and Public(a)and Public(b)then return a,b end
end
local function DisplayText(region)
 local value=region and Call(region.GetText,region);return type(value)=="string"and value or ""
end
function B:Normalize(id)return id=="Wisp"and "External"or id end
function B:Available()return ForeverWispFrame~=nil end
function B:MatchesAddon(name)return name=="ForeverWisp"end
function B:Route()return ForeverWispFrame and ForeverWispFrame.route end
function B:LegacyEnabled(q)return q.useExternalGuide~=false and q.useWisp~=false end
function B:SettingKey(section,key)
 if section=="questWorkspace"and key=="useWisp"then return "useExternalGuide"end;return key
end

function B:Read(workspace)
    if ProjectRuthlessDB and not ProjectRuthlessDB.questWorkspace.guideSource and not self:LegacyEnabled(ProjectRuthlessDB.questWorkspace) then return end
    local f=ForeverWispFrame
    local p=f and f.route
    if not p or not Call(f.IsShown,f) or not Call(p.IsShown,p) then return end
    local target=DisplayText(p.heading)
    if target=="" then return end
    local quest=DisplayText(p.guide)
    local guide={source="External",target=target,quest=quest,phase=DisplayText(p.meta),count=DisplayText(p.count),instruction=DisplayText(p.instruction),next={}}
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
    local locations=AUI.modules.QuestLocations;local db=locations and locations:Database()
    if name~=workspace.guideName then
        workspace.guideName=name;workspace.guideQuestID=nil
        for _,entry in ipairs(workspace.entries or {}) do if entry.title==name then workspace.guideQuestID=entry.id;break end end
        if not workspace.guideQuestID and db and db.Quest then
            local ids=Call(db.Quest.IdsByName,name)
            if ids and #ids==1 then workspace.guideQuestID=ids[1] end
        end
    end
    guide.id=workspace.guideQuestID
    return guide
end

function B:Navigation(workspace)
    if workspace.guide and workspace.guide.source and workspace.guide.source~="External"then return false end
    local f=ForeverWispNavigation
    if not f or not Call(f.IsShown,f) or type(f.GetRegions)~="function" then return false end
    local cached=workspace.guideNavigationRegions
    if not cached or workspace.guideNavigationFrame~=f then
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
        cached={arrow=arrow,labels=labels};workspace.guideNavigationRegions=cached;workspace.guideNavigationFrame=f
    end
    local arrow,labels=cached.arrow,cached.labels
    local distance,destination
    -- The supported protocol orders distance, destination and optional note.
    if #labels~=3 and #labels~=2 then return false end
    distance=DisplayText(labels[1]);destination=DisplayText(labels[2])
    if distance=="" and destination=="" then return false end
    workspace.distance:SetText(distance);workspace.destination:SetText(destination)
    local angle=arrow and Call(arrow.GetRotation,arrow)
    if type(angle)=="number" and Public(angle) and ProjectRuthlessDB.questWorkspace.showArrow~=false then
        workspace.arrow:SetRotation(angle);workspace.arrow:Show()
        workspace.guideBearing=angle+(Call(GetPlayerFacing) or 0)
    end
    return true
end

function B:Action(workspace,name)
 if InCombatLockdown()then return end
 if workspace.guide and workspace.guide.source and workspace.guide.source~="External"then return end
 local p=self:Route();local button=p and p[name]
 if button and Call(button.IsShown,button)and Call(button.IsEnabled,button)then
  Call(Call(button.GetScript,button,"OnClick"),button,"LeftButton");workspace:Refresh()
 end
end
function B:OpenBrowser()
 if InCombatLockdown()then return end
 local p=self:Route();local button=p and p.chapter
 if button then Call(Call(button.GetScript,button,"OnClick"),button,"LeftButton")end
end
