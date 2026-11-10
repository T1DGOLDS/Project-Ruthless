local _,AUI=...
local D=AUI.modules.DungeonAtlas
local legacyLoad,legacyRender,legacyHide=D.Load,D.Render,D.Hide
local function read(fn,...)
 if type(fn)~="function"then return end
 local ok,a,b=pcall(fn,...);if ok and not(issecretvalue and (issecretvalue(a)or issecretvalue(b)))then return a,b end
end
local function name(text)return (text or ""):gsub("|T.-|t",""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")end
function D:Load()
 if not RUI_DungeonSource and not RUI_DungeonData and C_AddOns then read(C_AddOns.LoadAddOn,"ProjectRuthless_DungeonData")end
 local source=RUI_DungeonSource
 if not source then
  local catalog,message=legacyLoad(self)
  if catalog then for i=#catalog,1,-1 do local range=catalog[i].record.LevelRange;if (range[3]or 999)>60 then table.remove(catalog,i)end end end
  return catalog,message
 end
 if self.catalogSource==source then return self.catalog end
 self.catalogSource=source;self.metadata=source;self.data=source.records;self.catalog={}
 for key,record in pairs(source.records)do
  local entry={key=key,name=record.name,record=record};local terms={record.name}
  for _,boss in ipairs(record.items)do terms[#terms+1]=boss.name
   for _,item in ipairs(boss.loot.NORMAL)do local fact=source.itemFacts[item[2]];if fact then terms[#terms+1]=fact.name end end
  end
  entry.search=table.concat(terms," "):lower();self.catalog[#self.catalog+1]=entry
 end
 table.sort(self.catalog,function(a,b)local x,y=a.record.LevelRange[2],b.record.LevelRange[2];return x==y and a.name<b.name or x<y end)
 return self.catalog
end
local oldMapIDs=D.MapIDs
function D:MapIDs(record)if not record.MapID then return {}end;return oldMapIDs(self,record)end
function D:Hide()
 legacyHide(self)
 local pins=AUI.modules.MapPins;if pins then pins:RemoveAllWorldMapIcons(self)end
 for _,tab in ipairs(self.journalTabs or {})do tab:Hide()end
 for _,label in ipairs(self.journalSummaries or {})do label:Hide()end
 for _,control in ipairs({self.journalSummary,self.journalSearch,self.lootFilter})do if control then control:Hide()end end
 if self.pickupIcon then self.pickupIcon:Hide()end
end
function D:JournalRow(q,index,text,click,item,note)
 local row=self.rows[index]
 if not row then row=AUI:CreateButton(q.mapContent);self.rows[index]=row end
 local width=math.max(100,q.mapContent:GetWidth());local lines=select(2,text:gsub("\n",""))+1
 local height=math.max(34,lines*16+12)
 row:SetSize(width,height);row:SetText(text)
 if row.label and row.label.GetStringHeight then height=math.max(height,(row.label:GetStringHeight()or 0)+12);row:SetHeight(height)end
 row:ClearAllPoints();row:SetPoint("TOPLEFT",0,-self.journalY)
 self.journalY=self.journalY+height+5;row.item=item;row.note=note;row.spell=nil
 row:SetScript("OnClick",click or function()end)
 row:SetScript("OnEnter",function(button)
  if not button.item and not button.note and not button.spell then return end
  GameTooltip:SetOwner(button,"ANCHOR_RIGHT")
  if button.spell then GameTooltip:SetSpellByID(button.spell)elseif button.item then GameTooltip:SetItemByID(button.item)end
  if button.note then GameTooltip:AddLine(button.note,.75,.8,.9,true)end
  GameTooltip:Show()
 end)
 row:SetScript("OnLeave",function()GameTooltip:Hide()end);row:Show()
end
function D:Summary(q,text)
 self.journalSummaries=self.journalSummaries or {};self.summaryCount=(self.summaryCount or 0)+1
 local label=self.journalSummaries[self.summaryCount]
 if not label then label=q.mapContent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");self.journalSummaries[self.summaryCount]=label;label:SetJustifyH("LEFT");local a=AUI.modules.Accessibility;if a then a:RegisterText(label)end end
 label:ClearAllPoints();label:SetPoint("TOPLEFT",2,-self.journalY);label:SetWidth(math.max(100,q.mapContent:GetWidth()-4));label:SetText(text);label:Show()
 self.journalY=self.journalY+(label:GetStringHeight()or 40)+14
end
function D:Tabs(q)
 self.journalTabs=self.journalTabs or {}
 local width=(q.mapContent:GetWidth()-8)/3
 for i,tab in ipairs({{"Overview","Overview"},{"Maps","Maps"},{"Bosses","Bosses"},{"Loot","Loot"},{"Quests","Quests"},{"Preparation","Prepare"}})do
  local button=self.journalTabs[i]
  if not button then button=AUI:CreateButton(q.mapContent);self.journalTabs[i]=button end
  local key=tab[1];button:SetSize(width,28);button:ClearAllPoints();button:SetPoint("TOPLEFT",((i-1)%3)*(width+4),-math.floor((i-1)/3)*32)
  button:SetText((self.view==key and "› "or "")..tab[2]);button:SetScript("OnClick",function()self.view=key;self.boss=nil;self.quest=nil;q:RenderMapPage()end);button:Show()
 end
 self.journalY=72
end
function D:ItemName(id)
 local cached=read(C_Item and C_Item.GetItemInfo,id)
 local fact=self.metadata and self.metadata.itemFacts[id]
 return cached or fact and fact.name or ("Item "..id)
end
function D:QuestStatus(q,quest)
 if read(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted,quest.id)==true then return "Completed"end
 for _,entry in ipairs(q.entries or {})do if entry.id==quest.id then return entry.complete and "Ready to turn in"or "In quest log"end end
 local level=read(UnitLevel,"player")
 if quest.pickupLevel and type(level)=="number"and level<quest.pickupLevel then return "Pickup guidance: level "..quest.pickupLevel end
 return "Check quest giver"
end
function D:RelevantQuest(quest)
 local faction=read(UnitFactionGroup,"player")
 if quest.side==1 and faction=="Horde"or quest.side==2 and faction=="Alliance"then return false end
 local _,class=read(UnitClass,"player")
 -- Class tokens below are masks from Wowhead, not the enum class ID.
 local bits={WARRIOR=1,PALADIN=2,HUNTER=4,ROGUE=8,PRIEST=16,SHAMAN=64,MAGE=128,WARLOCK=256,DRUID=1024}
 local bit=bits[class]
 if bit and quest.classMask and quest.classMask>0 and quest.classMask%(bit*2)<bit then return false end
 return true
end
function D:ShowPickup(quest)
 local data=AUI.modules.QuestData
 if data and data.GetDatabase then data:GetDatabase()end
 local map=data and data.mapNames and data.mapNames[quest.pickupZone]
 if type(map)~="number"and quest.pickupZone and data and data.mapNames then
  local function normal(s)return s:lower():gsub("^the ",""):gsub("^city of ",""):gsub(" city$","")end
  local matched
  for label,id in pairs(data.mapNames)do if type(id)=="number"and normal(label)==normal(quest.pickupZone)then
   if matched and matched~=id then matched=false;break end;matched=id
  end end
  map=matched
 end
 if type(map)~="number"or not quest.coordinates then AUI:Print("Pickup coordinates for a verified map are not recorded. See the quest's pickup information.");return end
 WorldMapFrame:SetMapID(map)
 local canvas=WorldMapFrame:GetCanvas()
 if not self.pickupIcon then
  self.pickupIcon=CreateFrame("Frame",nil,canvas);self.pickupIcon:SetSize(24,24);self.pickupIcon:EnableMouse(false)
  local icon=self.pickupIcon:CreateTexture(nil,"ARTWORK");icon:SetAllPoints();icon:SetAtlas("QuestNormal")
 end
 self.pickupPoint={quest=quest.id,map=map,x=quest.coordinates[1]/100,y=quest.coordinates[2]/100}
 self:DrawPickup()
end
function D:DrawPickup()
 local point=self.pickupPoint;local pins=AUI.modules.MapPins
 if point and self.pickupIcon and pins and self.quest and self.quest.id==point.quest and (self.view=="Quests"or self.view=="Preparation")then
  pins:AddWorldMapIconMap(self,self.pickupIcon,point.map,point.x,point.y)
 end
end
function D:CopySource(url)
 if not self.sourceDialog then
  local f=CreateFrame("Frame","RUIDungeonSourceDialog",UIParent,"BackdropTemplate");self.sourceDialog=f;f:SetSize(560,110);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG")
  if UISpecialFrames then table.insert(UISpecialFrames,"RUIDungeonSourceDialog")end
  f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1});AUI:StyleSurface(f,"window",nil,"Options")
  local title=f:CreateFontString(nil,"OVERLAY","GameFontNormal");title:SetPoint("TOPLEFT",12,-12);title:SetText("Wowhead source · Ctrl+C to copy")
  local edit=CreateFrame("EditBox",nil,f,"InputBoxTemplate");edit:SetPoint("TOPLEFT",16,-42);edit:SetSize(524,24);edit:SetAutoFocus(false);self.sourceEdit=edit
  local close=AUI:CreateButton(f);close:SetSize(80,24);close:SetPoint("BOTTOMRIGHT",-12,8);close:SetText("Close");close:SetScript("OnClick",function()f:Hide()end)
  edit:SetScript("OnEscapePressed",function()f:Hide()end)
 end
 self.sourceDialog:Show();self.sourceEdit:SetText(url);self.sourceEdit:SetFocus();self.sourceEdit:HighlightText()
end
function D:Render(q)
 if not RUI_DungeonSource then self:Load();if not RUI_DungeonSource then return legacyRender(self,q)end end
 self:Hide();q.mapCopy:SetText("");local catalog,message=self:Load();if not catalog then q.mapCopy:SetText(message);return end
 local index=0;self.journalY=0;self.summaryCount=0
 local function row(text,fn,item,note)index=index+1;self:JournalRow(q,index,text,fn,item,note)end
 local function rerender()q:RenderMapPage()end
 local function itemRow(id,boss)
  local rate=boss and boss.dropRates and boss.dropRates[id]
  local percent=type(rate)=="table"and rate.percent
  local note=type(percent)=="number"and percent>=0 and percent<=100 and (("Published drop rate: %g%%"):format(percent).."\n"..(rate.source or ""))or "Drop rate is not published in the recorded Forever source; unknown is not 0%."
  local fact=self.metadata.itemFacts[id]or {};local label=self:ItemName(id)
  if fact.reqlevel then label=label.." · level "..fact.reqlevel end
  if boss and self.view=="Loot"then label=label.."\n"..name(boss.name)end
  row(label,function()local _,link=read(C_Item and C_Item.GetItemInfo,id);if link and HandleModifiedItemClick then HandleModifiedItemClick(link)end end,id,note)
 end
 if not self.selected then
  q.mapHeading:SetText("Dungeon atlas · Forever")
  self:Summary(q,"Browse by level. Search dungeon, boss or recorded item names. Details pending marks information not published yet.")
  if not self.journalSearch then
   local box=CreateFrame("EditBox",nil,q.mapContent,"SearchBoxTemplate");self.journalSearch=box;box:SetAutoFocus(false)
   box:SetScript("OnTextChanged",function(edit)
    if SearchBoxTemplate_OnTextChanged then SearchBoxTemplate_OnTextChanged(edit)end
    local value=edit:GetText():lower();if value==self.searchText then return end;self.searchText=value
    if not self.searchQueued then self.searchQueued=true;C_Timer.After(.15,function()self.searchQueued=nil;if q.mapPage=="Dungeon atlas"and q.mapPanel:IsVisible()then rerender()end end)end
   end)
  end
  self.journalSearch:ClearAllPoints();self.journalSearch:SetPoint("TOPLEFT",4,-self.journalY);self.journalSearch:SetSize(q.mapContent:GetWidth()-8,24);self.journalSearch:Show();self.journalY=self.journalY+34
  for _,entry in ipairs(catalog)do if (entry.search or entry.name:lower()):find(self.searchText or "",1,true)then local chosen=entry
   local range=entry.record.LevelRange
   row(entry.name.."\nLevels "..range[2].."–"..range[3]..(entry.record.coverage=="unpublished"and " · details pending"or ""),function()self.selected=chosen;self.view="Overview";self.boss=nil;self.quest=nil;self.localFloor=nil;self.nativeFloor=nil;rerender()end)
  end end
  if index==0 then row("No matching dungeons, bosses or items")end
 else
  local record=self.selected.record;q.mapHeading:SetText(self.selected.name)
  if q.SetMapBack then q:SetMapBack(self.boss and "‹ Bosses"or self.quest and "‹ Quests"or "‹ Dungeons",function()
   if self.boss then self.boss=nil elseif self.quest then self.quest=nil else self.selected=nil end;rerender()
  end)end
  self.view=self.view or "Overview";self:Tabs(q)
  local range=record.LevelRange
  if self.view=="Overview"then
   self:Summary(q,("Recommended levels %s–%s\n%d bosses · %d associated quests\nReviewed %s · Wowhead Forever"):format(range[2],range[3],#record.items,#record.quests,record.reviewed))
   row("View maps",function()self.view="Maps";rerender()end)
   row("Prepare quests and entry items",function()self.view="Preparation";rerender()end)
   if record.coverage=="unpublished"then self:Summary(q,"This dungeon is announced, but its public journal has no recorded bosses, loot or map identity yet. No data from another expansion is substituted.")end
   row("Copy source link",function()self:CopySource(record.source)end)
  elseif self.view=="Maps"then
   local floors=self:MapIDs(record)
   local valid=false
   for _,floor in ipairs(floors)do local chosen=floor;if self.nativeFloor==chosen.mapID then valid=true end;row("Floor · "..chosen.name,function()self.nativeFloor=chosen.mapID;self:OpenMap(chosen.mapID);self:DrawPins()end)end
   if #floors==0 then
    local localFloors=self:LocalFloors(record)
    for _,floor in ipairs(localFloors)do local chosen=floor;row("Reference map · "..chosen.label,function()self.localFloor=chosen.key;self:ShowLocalMap(chosen.key)end)end
    if #localFloors>0 then self.localFloor=self.localFloor or localFloors[1].key;self:ShowLocalMap(self.localFloor)
    else self:Summary(q,"A verified floor map is not available for this dungeon. Map artwork and coordinates will not be guessed.")end
   else
    if not valid then self.nativeFloor=floors[1].mapID end
    if read(WorldMapFrame.GetMapID,WorldMapFrame)~=self.nativeFloor then self:OpenMap(self.nativeFloor)end
   end
  elseif self.view=="Bosses"then
   if self.boss then
    local boss=record.items[self.boss]
    self:Summary(q,name(boss.name).."\nAbilities and recorded drops. Hover items for tooltips and rate availability.")
    for _,id in ipairs(boss.spells or {})do local fact=self.metadata.spellFacts[id];row(fact and fact.name or ("Ability #"..id),nil,nil,"Recorded encounter ability #"..id);self.rows[index].spell=id end
    for _,entry in ipairs(boss.loot.NORMAL)do itemRow(entry[2],boss)end
    if #boss.loot.NORMAL==0 then row("No published loot for this encounter")end
   else for i,boss in ipairs(record.items)do local number=i;row(i.." · "..name(boss.name),function()self.boss=number;rerender()end)end
    if #record.items==0 then row("Boss details have not been published")end
   end
  elseif self.view=="Loot"then
   self:Summary(q,"Recorded Forever loot · hover for item details. Drop rates are shown only when supplied by a matching source.")
   local seen={};for _,boss in ipairs(record.items)do for _,entry in ipairs(boss.loot.NORMAL)do if not seen[entry[2]]then seen[entry[2]]=true;itemRow(entry[2],boss)end end end
   if not next(seen)then row("No published loot for this dungeon")end
  elseif self.view=="Quests"or self.view=="Preparation"then
   if self.quest then
    local quest=self.quest;local text=quest.name.."\n"..self:QuestStatus(q,quest)
    if quest.pickupLevel then text=text.."\nPublished pickup level: "..quest.pickupLevel end
    text=text.."\nPickup: "..(quest.giver and quest.giver.name or quest.pickupKind=="drop"and "Looted quest starter"or "Location not recorded")
    if quest.pickupZone then text=text.."\n"..quest.pickupZone end
    if quest.coordinates then text=text..(" · %.1f, %.1f"):format(quest.coordinates[1],quest.coordinates[2])end
    self:Summary(q,text)
    if quest.relatedQuests then for _,id in ipairs(quest.relatedQuests)do local title=read(C_QuestLog and C_QuestLog.GetTitleForQuestID,id)or "Quest #"..id;row("Related chain · "..title,nil,nil,"The source links this quest; this does not assert an immediate prerequisite.")end end
    for _,item in ipairs(quest.relatedItems or {})do row("Related item · "..item.name,nil,item.id,"Check this item's role with the quest giver before travelling.")end
    if quest.coordinates then row("Show pickup on map",function()self:ShowPickup(quest)end)end
    row("Share quest",function()local _,reason=q:ShareDungeonQuest(quest.id);if reason then AUI:Print(reason)end end)
    row("Copy quest source",function()self:CopySource(quest.source or record.source)end)
   else
    if self.view=="Preparation"then
     self:Summary(q,"Check access items and collect your quests before travelling. An item held by another party member or an alternative unlock can be sufficient.")
     for _,item in ipairs(record.preparation or {})do local count=read(C_Item and C_Item.GetItemCount,item.id,true,false,true)
      row(item.name.."\n"..(type(count)=="number"and ("You own: "..count)or "Owned count unavailable"),nil,item.id,item.note)
      self:Summary(q,item.note)
     end
     if not record.preparation then self:Summary(q,"No additional access-item requirement is recorded in this source. Check class quests and special summons before the run.")end
    else self:Summary(q,"Your faction/class quests · completed quests stay labelled. Pickup guidance is not a guarantee that prerequisites are met.")end
    local count=0
    for _,quest in ipairs(record.quests)do if self:RelevantQuest(quest)then count=count+1;local chosen=quest
     row(quest.name.."\n"..self:QuestStatus(q,quest)..(quest.pickupZone and " · "..quest.pickupZone or ""),function()self.quest=chosen;rerender()end)
    end end
    if count==0 then row("No matching quest records for your faction/class")end
   end
  end
 end
 q.mapContent:SetHeight(math.max(200,self.journalY+12));self:DrawPins();self:DrawPickup()
 if not self.itemEvents then
  self.itemEvents=CreateFrame("Frame");self.itemEvents:SetScript("OnEvent",function()
   if not self.itemRefreshQueued then self.itemRefreshQueued=true;C_Timer.After(.2,function()self.itemRefreshQueued=nil;if q.mapPage=="Dungeon atlas"and q.mapPanel:IsVisible()then rerender()end end)end
  end)
  q.mapPanel:HookScript("OnHide",function()self.itemEvents:UnregisterEvent("GET_ITEM_INFO_RECEIVED");self:Hide()end)
 end
 self.itemEvents:RegisterEvent("GET_ITEM_INFO_RECEIVED")
end
