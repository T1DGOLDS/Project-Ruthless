local _, AUI = ...
local Q = {}
AUI:RegisterModule("QuestSupplies", Q)

local function public(value) return not (issecretvalue and issecretvalue(value)) end
local function number(value) return public(value) and type(value)=="number" and value==value and value>=0 and value<1e12 end
local function read(fn, ...)
    if type(fn)~="function" then return end
    local ok, value=pcall(fn, ...)
    if ok and public(value) then return value end
end
function Q:Store()
    ProjectRuthlessDB.questSupplyObservations=ProjectRuthlessDB.questSupplyObservations or {quests={},items={}}
    return ProjectRuthlessDB.questSupplyObservations
end
function Q:Owned(itemID)
    local count=read(C_Item and C_Item.GetItemCount,itemID,true,false,true)
    return number(count) and count or 0
end
function Q:Item(itemID)
    local observed=self:Store().items[itemID]
    local reference=AUI.modules.QuestSupplyData:Get().items[itemID]
    return observed or reference or {name="Item "..itemID}
end
function Q:ObserveItem(itemID)
    if InCombatLockdown() or not number(itemID) then return end
    local fn=C_Item and C_Item.GetItemInfo
    if type(fn)~="function" then return end
    local result={pcall(fn,itemID)}
    local name,binding=result[2],result[15]
    if result[1] and public(name) and type(name)=="string" and number(binding) then
        local prior=self:Store().items[itemID]
        if not prior or prior.name~=name or prior.binding~=binding then
            self:Store().items[itemID]={name=name,binding=binding,source="Forever client"}
            self.revision=(self.revision or 0)+1
            if AUI.modules.AuctionHouse then AUI.modules.AuctionHouse:QueueRefresh()end
        end
        return self:Store().items[itemID]
    end
end
function Q:RequestItem(itemID)
    if InCombatLockdown() or not C_Item or not C_Item.RequestLoadItemDataByID then return end
    self.requests=self.requests or {}
    if not self.requests[itemID] and read(C_Item.IsItemDataCachedByID,itemID)==false then
        self.requests[itemID]=true;C_Item.RequestLoadItemDataByID(itemID)
    end
end
function Q:ObserveProgress()
    if InCombatLockdown() then return end
    local id=read(GetQuestID)
    local count=read(GetNumQuestItems)
    if not number(id) or id==0 or not number(count) or count>32 then return end
    if read(C_QuestOffer and C_QuestOffer.GetHideRequiredItems)==true then return end
    local items={}
    for index=1,count do
        local link=read(GetQuestItemLink,"required",index)
        local ok,name,_,quantity=pcall(GetQuestItemInfo,"required",index)
        local item=type(link)=="string" and tonumber(link:match("item:(%d+)"))
        -- Never replace a complete observation with a partial/hidden response.
        if not ok or not item or not number(quantity) or quantity<1 then return end
        items[#items+1]={item,quantity}
        if not self:ObserveItem(item)then self:RequestItem(item)end
    end
    local reference=AUI.modules.QuestSupplyData:Get().quests[id] or {}
    local index=read(C_QuestLog and C_QuestLog.GetLogIndexForQuestID,id)
    local info=index and read(C_QuestLog.GetInfo,index)
    local zone=reference.zone
    if number(index) then
        for position=index-1,math.max(1,index-100),-1 do
            local header=read(C_QuestLog.GetInfo,position)
            if header and public(header.isHeader) and header.isHeader then
                if public(header.title)and type(header.title)=="string"then
                    local matched,ambiguous
                    for area,name in pairs(AUI.modules.QuestSupplyData:Get().zones)do
                        if name==header.title then if matched then ambiguous=true;break end;matched=area end
                    end
                    if matched and not ambiguous then zone=matched end
                end
                break
            end
        end
    end
    self:Store().quests[id]={title=read(C_QuestLog.GetTitleForQuestID,id) or reference.title or "Quest "..id,
        level=info and public(info.level) and info.level or reference.level,
        minLevel=reference.minLevel,zone=zone,items=items,status="observed",build=select(2,GetBuildInfo()),time=time(),repeatable=read(C_QuestLog.IsRepeatableQuest,id)==true or reference.repeatable}
    self.revision=(self.revision or 0)+1
    if AUI.modules.AuctionHouse then AUI.modules.AuctionHouse:QueueRefresh() end
end
function Q:Coverage()
    local module=AUI.modules.QuestSupplyData
    local data=module.summary or module:Get()
    local observed=0
    for _ in pairs(self:Store().quests) do observed=observed+1 end
    return data.clientRecords, data.counts.reference, data.counts.unknown, observed, data.withheldRecords or 0
end
function Q:Zones()
    if self.zones and self.zoneRevision==self.revision then return self.zones end
    local data=AUI.modules.QuestSupplyData:Get()
    local zones={}
    for _,quest in pairs(data.quests) do
        if quest.items and #quest.items>0 and quest.zone then zones[quest.zone]=data.zones[quest.zone] or ("Quest category "..quest.zone) end
    end
    for _,quest in pairs(self:Store().quests)do
        if quest.zone then zones[quest.zone]=data.zones[quest.zone]or ("Quest category "..quest.zone)end
    end
    local result={{id=0,name="All zones"},{id=-99999,name="Unclassified / missing data"}}
    for id,name in pairs(zones) do result[#result+1]={id=id,name=name} end
    table.sort(result,function(a,b) if a.id==0 or b.id==0 then return a.id==0 end return a.name<b.name end)
    self.zones=result;self.zoneRevision=self.revision
    return result
end
function Q:Rows(zone,query,showUnknown)
    local data=AUI.modules.QuestSupplyData:Get()
    local observations=self:Store().quests
    local result={};query=(query or ""):lower()
    local completed={}
    for _,id in ipairs(read(C_QuestLog and C_QuestLog.GetAllCompletedQuestIDs) or {})do completed[id]=true end
    local ownedCache={}

    local function add(id,base)
        local quest=observations[id] or base
        local title=quest.title or ("Quest "..id)
        local zoneName=data.zones[quest.zone] or "Unclassified"
        if zone and zone~=0 and not (zone==-99999 and not quest.zone) and zone~=quest.zone then return end
        if completed[id] and not quest.repeatable then return end
        local hasItems,unknownBinding=false,false
        for _,item in ipairs(quest.items or {}) do
            local info=self:Item(item[1])
            local binding=info.binding
            if binding==nil then unknownBinding=true end
            if binding==0 or binding==2 or binding==3 then
                hasItems=true
                local text=(title.." "..info.name.." "..zoneName.." "..id):lower()
                if query=="" or text:find(query,1,true) then
                    local owned=ownedCache[item[1]]
                    if owned==nil then owned=self:Owned(item[1]);ownedCache[item[1]]=owned end
                    result[#result+1]={questID=id,itemID=item[1],name=info.name,quantity=item[2],owned=owned,
                        need=math.max(0,item[2]-owned),title=title,zone=zoneName,level=quest.level,minLevel=quest.minLevel,
                        classMask=quest.classMask,raceMask=quest.raceMask,previous=quest.previous,source=quest.status=="observed" and "Forever turn-in observed" or "Classic reference · confirm in Forever"}
                end
            end
        end
        if showUnknown and not hasItems and (query=="" or (title.." "..id):lower():find(query,1,true)) then
            result[#result+1]={questID=id,title=title,name=title,zone=zoneName,
                source=quest.status=="unknown" and "Requirements not recorded"
                    or unknownBinding and "Turn-in items found - tradeability not recorded"
                    or quest.items and #quest.items>0 and "Required items are bound / not purchasable"
                    or quest.status=="observed" and "No item turn-in requirements observed"
                    or "Classic reference - no tradable requirements recorded"}
        end
    end
    for id,quest in pairs(data.quests) do add(id,quest) end
    for id,quest in pairs(observations) do if not data.quests[id] then add(id,quest) end end
    table.sort(result,function(a,b)
        if a.zone~=b.zone then return a.zone<b.zone end
        if (a.level or 999)~=(b.level or 999) then return (a.level or 999)<(b.level or 999) end
        if a.questID~=b.questID then return a.questID<b.questID end
        return (a.itemID or 0)<(b.itemID or 0)
    end)
    return result
end
function Q:OnPlayerLogin()
    local events=CreateFrame("Frame");self.events=events
    events:RegisterEvent("QUEST_PROGRESS")
    events:RegisterEvent("ITEM_DATA_LOAD_RESULT")
    events:SetScript("OnEvent",function(_,event,id,success)
        if event=="QUEST_PROGRESS"then self:ObserveProgress()
        elseif success==true and number(id) and self.requests and self.requests[id]then self:ObserveItem(id)end
    end)
end
