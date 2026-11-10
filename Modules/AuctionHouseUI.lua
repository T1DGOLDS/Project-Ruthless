local _,AUI=...

local U={nativeSkins=setmetatable({},{__mode="k"}),buttonSkins=setmetatable({},{__mode="k"})}

AUI:RegisterModule("AuctionHouseUI",U)

local function service()return AUI.modules.AuctionHouse end

local function supplies()return AUI.modules.QuestSupplies end

local function money(value)

 if type(value)~="number"then return "No quote"end

 if GetMoneyString then return GetMoneyString(math.floor(value))end

 return tostring(math.floor(value)).."c"

end

local function label(parent,value,x,y,width,font)

 local text=parent:CreateFontString(nil,"OVERLAY",font or "GameFontNormalSmall")

 text:SetPoint("TOPLEFT",x,y);text:SetWidth(width);text:SetJustifyH("LEFT");text:SetText(value)

 if AUI.modules.Accessibility then AUI.modules.Accessibility:RegisterText(text)end

 return text

end

local function tip(frame,lines)

 if not GameTooltip then return end

 GameTooltip:SetOwner(frame,"ANCHOR_LEFT")

 for index,line in ipairs(lines)do

  if index==1 then GameTooltip:SetText(line)else GameTooltip:AddLine(line,.8,.82,.87,true)end

 end

 GameTooltip:Show()

end

function U:Message(ok,message)

 if self.frame then self.frame.message:SetText(message or (ok and "Saved."or "This action is unavailable."))end

end

function U:QueueRefresh()

 self.dirty=true

 if self.frame and self.frame:IsVisible()then AUI:QueueRefresh(self)end

end

function U:Menu(anchor,choices)

 if MenuUtil and MenuUtil.CreateContextMenu then

  MenuUtil.CreateContextMenu(anchor,function(_,root)

   for _,choice in ipairs(choices)do root:CreateButton(choice[1],choice[2])end

  end)

 end

end

function U:Button(parent,title,x,y,width,callback)

 local button=AUI:CreateButton(parent);button:SetPoint("TOPLEFT",x,y);button:SetSize(width,22);button:SetText(title)

 button:SetScript("OnClick",function()self:Message(callback())end)

 return button

end

function U:StyleInput(box)

 if box.SetBackdrop then

  box:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})

  AUI:StyleSurface(box,"surface",1,"Auction");box:SetBackdropBorderColor(.18,.2,.24,1)

  if box.SetFontObject then box:SetFontObject("GameFontHighlightSmall")end

  if box.SetTextInsets then box:SetTextInsets(6,6,2,2)end

 end

end

function U:SkinButton(button)

 if not button or self.buttonSkins[button]then return end

 for _,method in ipairs({"GetNormalTexture","GetPushedTexture","GetDisabledTexture"})do

  if type(button[method])=="function"then local texture=button[method](button);if texture then texture:SetAlpha(0)end end

 end

 for _,key in ipairs({"Left","Middle","Right","LeftDisabled","MiddleDisabled","RightDisabled","LeftActive","MiddleActive","RightActive"})do

  local texture=button[key];if texture and texture.SetAlpha then texture:SetAlpha(0)end

 end

 local surface=CreateFrame("Frame",nil,button,"BackdropTemplate");surface:SetAllPoints(button);surface:EnableMouse(false);surface:SetFrameLevel(math.max(0,button:GetFrameLevel()-1))

 surface:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})

 AUI:StyleSurface(surface,"surface",1,"Auction");surface:SetBackdropBorderColor(.18,.2,.24,1)

 self.buttonSkins[button]=surface

end

function U:SetMode(mode)

 local a=service();a.mode=mode;a.page=1

 if self.frame then
  self.frame.filter:SetText("")
  if self.embedded then self:SelectPage(mode=="market"and "market"or "tools")end
 end
 self:Refresh()

end

function U:Create()

 if self.frame then return self.frame end

 local frame=CreateFrame("Frame","RUIAuctionTools",UIParent,"BackdropTemplate");self.frame=frame

 frame:SetSize(340,566);frame:SetClampedToScreen(true);frame:SetFrameStrata("DIALOG")

 frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})

 AUI:StyleSurface(frame,"window",1,"Auction");frame:SetBackdropBorderColor(AUI:AccentColor())

 frame.title=label(frame,"RUI · AUCTION HOUSE",12,-10,280,"GameFontNormal")

 frame.close=self:Button(frame,"×",310,-5,22,function()frame:Hide();return true,""end)

 frame.tabs={}

 for index,tab in ipairs({{"saved","Searches"},{"lists","Shopping"},{"supplies","Quest supplies"},{"prices","Prices / Sell"}})do

  local id=tab[1]

  frame.tabs[id]=self:Button(frame,tab[2],12+(index-1)*80,-34,77,function()self:SetMode(id);return true,""end)

 end

 local filter=CreateFrame("EditBox",nil,frame,"BackdropTemplate");frame.filter=filter;self:StyleInput(filter)

 filter:SetPoint("TOPLEFT",17,-65);filter:SetSize(306,20);filter:SetAutoFocus(false);filter:SetMaxLetters(100)

 frame.filterHint=label(filter,"Filter entries…",6,-5,300)

 frame.filterHint:SetTextColor(.5,.53,.6)

 filter:SetScript("OnEscapePressed",function(box)box:ClearFocus()end)

 filter:SetScript("OnTextChanged",function()

  frame.filterHint:SetShown(filter:GetText()=="")

  self.filterSerial=(self.filterSerial or 0)+1;local serial=self.filterSerial

  C_Timer.After(.15,function()if self.filterSerial==serial and frame:IsShown()then service().page=1;self:Refresh()end end)

 end)

 frame.context=self:Button(frame,"",12,-93,316,function()self:ContextMenu();return true,""end)

 frame.actions={}

 for i=1,3 do

  local actionIndex=i

  frame.actions[i]=self:Button(frame,"",12+(i-1)*107,-121,102,function()return self:Action(actionIndex)end)

 end

 frame.summary=label(frame,"",12,-150,316)

 frame.summary:SetHeight(46);frame.summary:SetTextColor(.65,.68,.75)

 frame.rows={}

 for index=1,5 do

  local row=AUI:CreateButton(frame);frame.rows[index]=row

  row:SetPoint("TOPLEFT",12,-202-(index-1)*55);row:SetSize(316,52)

  row.icon=row:CreateTexture(nil,"ARTWORK");row.icon:SetPoint("LEFT",6,0);row.icon:SetSize(28,28);row.icon:SetTexCoord(.07,.93,.07,.93)

  row.title=label(row,"",42,-4,266)

  row.detail=label(row,"",42,-20,266);row.detail:SetTextColor(.72,.74,.79)

  row.source=label(row,"",42,-35,266);row.source:SetTextColor(.64,.67,.73)

  row:RegisterForClicks("LeftButtonUp","RightButtonUp")

  row:SetScript("OnClick",function(_,button)self:ClickRow(row.entry,button)end)

  row:HookScript("OnEnter",function()self:RowTooltip(row)end)

  row:HookScript("OnLeave",function()if GameTooltip then GameTooltip:Hide()end end)

 end

 frame.previous=self:Button(frame,"‹",12,-480,30,function()service().page=math.max(1,service().page-1);self:Refresh();return true,""end)

 frame.pageLabel=label(frame,"",52,-484,222)

 frame.next=self:Button(frame,"›",298,-480,30,function()service().page=math.min(self.maxPage or 1,service().page+1);self:Refresh();return true,""end)

 frame.message=label(frame,"",12,-509,316);frame.message:SetHeight(50);frame.message:SetTextColor(.74,.78,.84)

 frame:RegisterForDrag("LeftButton");frame:SetMovable(true);frame:EnableMouse(true)

 frame:SetScript("OnDragStart",function()if frame:GetParent()==UIParent and not InCombatLockdown()then frame:StartMoving()end end)

 frame:SetScript("OnDragStop",function()

  frame:StopMovingOrSizing()

  if frame:GetParent()==UIParent and AUI.modules.LayoutEditor then

   local editor=AUI.modules.LayoutEditor;local value=editor:Capture(frame)

   if value then editor:Store().elements.auctionTools=value end

  end

 end)

 frame:HookScript("OnHide",function()self.filterSerial=(self.filterSerial or 0)+1 end)

 UISpecialFrames=UISpecialFrames or {};table.insert(UISpecialFrames,"RUIAuctionTools")

 return frame

end

function U:ContextMenu()

 local a=service();local choices={}

 if a.mode=="supplies"then

  for _,zone in ipairs(supplies():Zones())do

   local id=zone.id

   choices[#choices+1]={zone.name,function()a.zone=id;a.page=1;self:Refresh()end}

  end

 elseif a.mode=="lists"then

  local names={};for name in pairs(a:Store().lists)do names[#names+1]=name end;table.sort(names)

  for _,name in ipairs(names)do

   local selected=name

   choices[#choices+1]={name,function()a.listName=selected;a.listCursor=nil;a.page=1;self:Refresh()end}

  end

  if a.listName then

   choices[#choices+1]={"Remove selected list (recoverable)",function()

    local s=a:Store();s.removedList={name=a.listName,items=s.lists[a.listName]};s.lists[a.listName]=nil;a.listName=nil;self:Refresh()

   end}

  end

  if a:Store().removedList then choices[#choices+1]={"Restore removed list",function()

   local s=a:Store();local old=s.removedList

   if not s.lists[old.name]then s.lists[old.name]=old.items;s.removedList=nil;a.listName=old.name;self:Refresh()end

  end}end

  choices[#choices+1]={"Import a shopping list",function()self:TransferList("")end}

  if a.listName then choices[#choices+1]={"Export selected list",function()

   local value,message=a:ExportList(a.listName)

   if value then self:TransferList(value)else self:Message(false,message)end

  end}end

 elseif a.mode=="market"then
  choices={}
  for _,sort in ipairs({{"name","Name"},{"price","Lowest unit price"},{"quantity","Most available"}})do
   local key=sort[1];choices[#choices+1]={"Sort: "..sort[2],function()AUI.modules.AuctionMarket.sort=key;a.page=1;self:Refresh()end}
  end
  choices[#choices+1]={"Cached prices are not live purchase quotes",function()self:Message(true,AUI.modules.AuctionMarket:Status())end}
 elseif a.mode=="saved"then

  choices={{"Saved searches",function()a.recent=false;self:Refresh()end},{"Recent searches",function()a.recent=true;self:Refresh()end}}

 else

  choices={{"Observed price history",function()a.ownedView=false;self:Refresh()end},{"My auctions / undercut review",function()self:Message(a:ShowOwned());self:Refresh()end}}

  choices[#choices+1]={"Forget selected item selling preferences",function()self:Message(a:ForgetSale())end}

  for index,name in ipairs({AUCTION_DURATION_ONE or "Short",AUCTION_DURATION_TWO or "Medium",AUCTION_DURATION_THREE or "Long"})do

   local duration=index

   choices[#choices+1]={"New-item default duration: "..name,function()a:Store().preferences.duration=duration;self:Message(true,"Default duration saved for this character.")end}

  end

 end

 self:Menu(self.frame.context,choices)

end

function U:Action(index)

 local a=service();local mode=a.mode;local current=a:CurrentQuery();local filter=self.frame.filter:GetText()

 if mode=="market"then
  local market=AUI.modules.AuctionMarket
  if index==1 then return market:Request()
  elseif index==2 then market:Cancel();return true,market:Status()
  else market:Clear();self:Refresh();return true,"Cached market prices cleared."end
 elseif mode=="saved"then

  if index==1 then return a:SaveSearch(current,true)

  elseif index==2 then return a:SetDefault(current)

  else a:Store().default=nil;return true,"Default search cleared."end

 elseif mode=="lists"then

  if index==1 then local ok,message=a:NewList(filter);if ok then self.frame.filter:SetText("")end;return ok,message

  elseif index==2 then

   if not current then return false,"Enter a search in the native Buy tab first."end

   return a:AddToList(a.listName,{term=current.term,quantity=1})

  else return a:SearchNext()end

 elseif mode=="supplies"then

  if index==1 then a.showUnknown=not a.showUnknown;a.page=1;self:Refresh();return true,"Missing requirements are kept distinct from confirmed data."

  elseif index==2 then

   local name="Quest supplies · "..((AUI.modules.QuestSupplyData:Get().zones[a.zone])or "Selected zone")

   name=name:sub(1,40);local ok,message=a:NewList(name);if not ok then return ok,message end

   -- Use maximum requirement per item rather than summing mutually exclusive or repeatable quests.

   local targets={}

   for _,row in ipairs(self.currentRows or {})do if row.itemID and row.need>0 then

    local prior=targets[row.itemID];if not prior or prior.quantity<row.quantity then targets[row.itemID]=row end

   end end

   local added=0

   for _,row in pairs(targets)do

    local quantity,cap=row.quantity,nil

    for _,existing in ipairs(a:Store().lists[name])do if existing.itemID==row.itemID then quantity=math.max(quantity,existing.quantity);cap=existing.maxPrice end end

    local saved=a:AddToList(name,{term=row.name,itemID=row.itemID,quantity=quantity,maxPrice=cap})

    if saved then added=added+1 end

   end

   return true,added.." item targets added. Review references, prerequisites and quantities before buying."

  else

   return false,"Reference requirements may differ in Forever. Blue missing-data rows have no purchase action."

  end

 else

  if index==1 then return a:RememberSale()

  elseif index==2 then
   local ok,message=a:SuggestSale()
   if ok and self.embedded and self.lastNativeMode then AuctionHouseFrame:SetDisplayMode(self.lastNativeMode)end
   return ok,message

  else local p=a:Store().preferences;p.undercut=p.undercut==1 and 0 or 1;self:Refresh();return true,p.undercut==1 and "Price suggestions undercut by one copper."or "Price suggestions match the lowest competing unit price."end

 end

end

function U:DataRows()

 local a=service();local query=self.frame.filter:GetText():lower();local result={}

 local function matches(value)return query==""or value:lower():find(query,1,true)end

 if a.mode=="supplies"then

  local key=table.concat({a.zone or 0,query,tostring(a.showUnknown),supplies().revision or 0,a.inventoryRevision or 0},":")

  if self.supplyKey~=key then

   local diagnostics=AUI.modules.Diagnostics;local started=diagnostics and diagnostics:BeginWork()

   self.supplyKey=key;self.supplyRows=supplies():Rows(a.zone,query,a.showUnknown)

   if started then diagnostics:EndWork("QuestSupplies.Filter",started,AUI.modules.QuestSupplyData.summary.clientRecords)end

  end

  return self.supplyRows

 elseif a.mode=="market"then
  local source=AUI.modules.AuctionMarket:Rows(query)
  if self.marketEntries and self.marketEntries.source==source then return self.marketEntries.rows end
  for _,entry in ipairs(source)do
   result[#result+1]={kind="market",itemID=entry.id,name=entry.name,
    detail=(entry.price and money(entry.price).." per item"or "Bid-only listings").." · "..entry.quantity.." available",
    source=entry.listings.." listings · cached item-ID minimum; variants/own listings included"}
  end
  self.marketEntries={source=source,rows=result}
 elseif a.mode=="saved"then

  for index,entry in ipairs(a.recent and a:Store().history or a:Store().saved)do

   if matches(entry.term)then result[#result+1]={kind="search",index=index,query=entry,name=(entry.favourite and "★ "or "")..entry.term,

    detail=("Levels %s–%s · saved filters"):format(entry.minLevel,entry.maxLevel==0 and "any"or entry.maxLevel),source=a.recent and "Recent search · right-click to save"or "Click to search · right-click for options"}end

  end

  if not a.recent then table.sort(result,function(x,y)if x.query.favourite~=y.query.favourite then return x.query.favourite==true end;return x.name<y.name end)end

 elseif a.mode=="lists"then

  for index,entry in ipairs(a:Store().lists[a.listName]or {})do

   if matches(entry.term)then result[#result+1]={kind="list",index=index,listName=a.listName,itemID=entry.itemID,name=entry.term,shopping=entry,

    detail=("Need %d / target %d%s"):format(a:ListNeed(entry),entry.quantity,entry.maxPrice>0 and (" · cap "..money(entry.maxPrice))or ""),source="Click to search · right-click to edit target / cap"}end

  end

 elseif a.ownedView and a.open then

  for _,row in ipairs(a:OwnedRows())do

   local name=supplies():Item(row.key.itemID).name

   if matches(name)then result[#result+1]={kind="owned",owned=row,itemID=row.key.itemID,name=name,

    detail=row.quantity.." × "..money(row.price).." per item",source=row.undercut and "UNDERCUT · right-click to review cancellation"or row.fresh and "No lower competing price observed"or "No fresh complete comparison · click to check"}end

  end

 else

  local items=a:Market().items

  for _,record in pairs(items)do

   supplies():ObserveItem(record.key.itemID)

   local name=supplies():Item(record.key.itemID).name

   if matches(name)then

    local last=record.samples[#record.samples]

    result[#result+1]={kind="price",key=record.key,record=record,itemID=record.key.itemID,name=name,

     detail="Last "..money(last.last).." · observed low "..money(last.low),source=#record.samples.." recorded days · "..(date and date("%d %b %H:%M",record.time)or record.time)}

   end

  end

  table.sort(result,function(x,y)return x.record.time>y.record.time end)

 end

 return result

end

function U:Refresh()

 local frame=self.frame;if not frame or not frame:IsVisible()then return end

 local a=service();local rows=self:DataRows();self.currentRows=rows

 local mode=a.mode

 frame.filterHint:SetText(mode=="lists"and "Filter items / type a new list name…"or "Filter entries…")

 frame.filterHint:SetShown(frame.filter:GetText()=="")

 for key,button in pairs(frame.tabs)do button:SetBackdropBorderColor(key==mode and .6 or .16,key==mode and .45 or .17,key==mode and .7 or .21,1)end

 local titles

 if mode=="market"then
  frame.context:SetText("Full market · Sort: "..((AUI.modules.AuctionMarket.sort=="price"and "lowest unit price")or(AUI.modules.AuctionMarket.sort=="quantity"and "most available")or "name").." ▾")
  titles={"Scan market","Stop scan","Clear cache"}
  frame.summary:SetText("Search every item in the latest full-market snapshot locally. Prices are per item and may include different variants and your listings. Click an item to check live listings before buying.")
 elseif mode=="saved"then

  frame.context:SetText(a.recent and "Recent searches ▾"or "Saved character searches ▾")

  titles={"Save / favourite","Set default","Clear default"}

  frame.summary:SetText("Levels and native filters travel with each search. Restoring resets the category. Right-click for favourites or removal.")

 elseif mode=="lists"then

  frame.context:SetText((a.listName or "Select a shopping list").." ▾")

  titles={"New list","Add search","Search next"}

  frame.summary:SetText("Type a name above to create a list. Known items subtract bags/bank. Price caps warn only: review the purchase total.")

 elseif mode=="supplies"then

  local zone=AUI.modules.QuestSupplyData:Get().zones[a.zone]or (a.zone==-99999 and "Unclassified / missing data"or "All zones")

  frame.context:SetText(zone.." ▾");titles={a.showUnknown and "Hide audit rows"or "Show audit rows","Make list","Data notes"}

  local total,refs,unknown,observed,withheld=supplies():Coverage()

  frame.summary:SetText(("%d readable · %d Classic references\n%d gaps · %d live observations\n%d encrypted records not read\nClassic data needs Forever checks"):format(total,refs,unknown,observed,withheld))

 else

  frame.context:SetText(a.ownedView and "My auctions / undercuts ▾"or "Realm price observations ▾")

  titles={"Remember sale","Fill fresh price",a:Store().preferences.undercut==1 and "Undercut: 1c"or "Match lowest"}

  frame.summary:SetText("Select an item on Sell. Save quantity/duration or fill a fresh competing price. Posting always needs the native button.")

 end

 for index,title in ipairs(titles)do frame.actions[index]:SetText(title)end

 self:Reflow()
 local textScale=math.max(1,math.min(1.5,(ProjectRuthlessDB.accessibility or {}).textScale or 1))

 local summaryHeight=46*textScale

 local rowsTop=(self.embedded and 125 or 150)+summaryHeight+6

 local step=55*textScale

 local pageY=self.embedded and frame:GetHeight()-76 or 480
 local perPage=math.max(1,math.min(5,math.floor((pageY-rowsTop-2+3*textScale)/step)))

 self.perPage=perPage

 frame.summary:SetHeight(summaryHeight)

 self.maxPage=math.max(1,math.ceil(#rows/perPage));a.page=math.max(1,math.min(self.maxPage,a.page))

 frame.pageLabel:SetText(("%d / %d · %d entries"):format(a.page,self.maxPage,#rows))

 for index,row in ipairs(frame.rows)do

  local entry=index<=perPage and rows[(a.page-1)*perPage+index]or nil

  row:ClearAllPoints();row:SetPoint("TOPLEFT",12,-rowsTop-(index-1)*step);row:SetSize(316,52*textScale)

  row.title:ClearAllPoints();row.title:SetPoint("TOPLEFT",42,-4)

  row.detail:ClearAllPoints();row.detail:SetPoint("TOPLEFT",42,-4-16*textScale)

  row.source:ClearAllPoints();row.source:SetPoint("TOPLEFT",42,-4-31*textScale)

  for _,font in ipairs({row.title,row.detail,row.source})do font:SetWordWrap(false)end

  row.entry=entry;row:SetShown(entry~=nil)

  if entry then

   row.title:SetText(entry.name)

   row.detail:SetText(entry.detail or (entry.itemID and ((entry.need==0 and "Owned"or "Need "..entry.need).." · "..entry.title.." ["..(entry.level or "?").."]")or entry.zone))

   row.source:SetText(entry.source)

   local icon=entry.itemID and C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(entry.itemID)

   row.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_Note_01")

   if entry.itemID then supplies():ObserveItem(entry.itemID);supplies():RequestItem(entry.itemID)end

  end

 end

 if #rows==0 then frame.message:SetText(mode=="prices"and "Search an item to record its prices. Native Buy, Sell and My auctions remain available."or "No matching entries. Use the controls above to add entries or change the filter.")end

 local shopping,quote=a.activeShopping,a.lastQuote

 if shopping and quote and quote.minimum and shopping.maxPrice and shopping.maxPrice>0

  and (shopping.itemID==quote.key.itemID or not shopping.itemID and (shopping.term or ""):lower()==supplies():Item(quote.key.itemID).name:lower())then

  frame.message:SetText(quote.minimum>shopping.maxPrice and ("OVER PRICE CAP: "..money(quote.minimum).." per item. Your cap is "..money(shopping.maxPrice)..".")or ("Current lowest: "..money(quote.minimum).." per item. Review quantity and total before buying."))

 end

 if mode=="market"then frame.message:SetText(AUI.modules.AuctionMarket:Status())end
 self.dirty=nil

end

function U:RowTooltip(row)

 local e=row.entry;if not e then return end

 local lines={e.name}

 if e.questID then

  lines[#lines+1]=e.title.." · Quest "..e.questID

  lines[#lines+1]=e.zone.." · Quest level "..(e.level or "unknown").." · Minimum "..(e.minLevel or "unknown")

  if e.itemID then lines[#lines+1]=("Required %d · Owned %d (bags/bank) · Missing %d"):format(e.quantity,e.owned,e.need)end

  if e.previous and e.previous~=0 then lines[#lines+1]="Reference prerequisite quest ID: "..e.previous end

  if e.classMask and e.classMask~=0 then lines[#lines+1]="Class restriction recorded; confirm this quest is for your class."end

  lines[#lines+1]=e.source;lines[#lines+1]="Check faction, class, prerequisites and the actual Forever quest before buying reference supplies."

 elseif e.record then

  lines[#lines+1]="Observed unit prices for this realm/faction and exact item variant. Only the listings returned by your searches are recorded."

  for _,sample in ipairs(e.record.samples)do lines[#lines+1]=(date and date("%d %b",sample.time)or sample.day).." · last "..money(sample.last).." · low "..money(sample.low)end

 else lines[#lines+1]=e.detail or "";lines[#lines+1]=e.source or ""end

 tip(row,lines)

end

function U:ClickRow(e,button)

 if not e then return end

 local a=service()

 if button=="RightButton"then

  if e.kind=="search"then

   self:Menu(self.frame,{{"Save / toggle favourite",function()self:Message(a:SaveSearch(e.query,true))end},{"Remove entry",function()

    local entries=a.recent and a:Store().history or a:Store().saved

    for index=#entries,1,-1 do if a:QueryID(entries[index])==a:QueryID(e.query)then table.remove(entries,index);break end end

    self:Refresh()

   end}})

  elseif e.kind=="list"then self:EditTarget(e)

  elseif e.kind=="owned"then self:Menu(self.frame,{{"Check competing listings",function()self:Message(a:SearchEntry({itemID=e.itemID,name=e.name}))end},{"Cancel with native confirmation",function()self:Message(a:CancelOwned(e.owned.auctionID))end}})

  elseif e.itemID then

   local choices={}

   for name in pairs(a:Store().lists)do

    local target=name

    choices[#choices+1]={"Add to "..name,function()self:Message(a:AddToList(target,{term=e.name,itemID=e.itemID,quantity=e.quantity or 1}))end}

   end

   self:Menu(self.frame,choices)

  end

  return

 end

 if e.kind=="search"then self:Message(a:ApplyQuery(e.query,true))

 elseif e.shopping then self:Message(a:SearchEntry(e.shopping))

 elseif e.itemID then self:Message(a:SearchEntry({itemID=e.itemID,name=e.name,quantity=e.quantity}))

 else self:Message(false,"Requirements are not recorded. This audit row has no purchase action.")end

end

function U:EditTarget(entry)

 if not self.targetEditor then

  local panel=CreateFrame("Frame",nil,self.frame,"BackdropTemplate");self.targetEditor=panel

  panel:SetSize(300,166);panel:SetPoint("CENTER");panel:SetFrameLevel(self.frame:GetFrameLevel()+20)

  panel:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})

  AUI:StyleSurface(panel,"window",1,"Auction")

  label(panel,"Shopping target / maximum unit price",12,-12,276)

  panel.qty=CreateFrame("EditBox",nil,panel,"BackdropTemplate");panel.qty:SetPoint("TOPLEFT",18,-47);panel.qty:SetSize(75,22);panel.qty:SetAutoFocus(false);panel.qty:SetNumeric(true);self:StyleInput(panel.qty)

  panel.cap=CreateFrame("EditBox",nil,panel,"BackdropTemplate");panel.cap:SetPoint("TOPLEFT",123,-47);panel.cap:SetSize(155,22);panel.cap:SetAutoFocus(false);self:StyleInput(panel.cap)

  label(panel,"Quantity",16,-76,90);label(panel,"Cap: 2g 50s, or copper; 0 = none",120,-76,168)

  self:Button(panel,"Save",12,-112,84,function()

   local e=panel.entry;local a=service();local quantity=tonumber(panel.qty:GetText());local cap=a:ParseMoney(panel.cap:GetText())

   if not quantity or not cap then return false,"Enter a whole quantity and a price such as 2g 50s (or 0 for no cap)."end

   local ok,message=a:AddToList(e.listName,{term=e.shopping.term,itemID=e.itemID,quantity=quantity,maxPrice=cap})

   if ok then panel:Hide();self:Refresh()end;return ok,message

  end)

  self:Button(panel,"Remove",106,-112,84,function()local entries=service():Store().lists[panel.entry.listName]or {}

   for index=#entries,1,-1 do if entries[index]==panel.entry.shopping then table.remove(entries,index);break end end

   panel:Hide();self:Refresh();return true,"Entry removed."end)

  self:Button(panel,"Cancel",200,-112,84,function()panel:Hide();return true,""end)

 end

 self.targetEditor.entry=entry;self.targetEditor.qty:SetText(entry.shopping.quantity);self.targetEditor.cap:SetText(entry.shopping.maxPrice or 0);self.targetEditor:Show()

end

function U:TransferList(value)

 if not self.transfer then

  local panel=CreateFrame("Frame","RUIAuctionListTransfer",UIParent,"BackdropTemplate");self.transfer=panel

  panel:SetPoint("CENTER");panel:SetSize(480,350);panel:SetFrameStrata("FULLSCREEN_DIALOG")

  panel:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})

  AUI:StyleSurface(panel,"window",1,"Auction")

  label(panel,"Shopping list · copy or paste",16,-14,440,"GameFontNormal")

  label(panel,"The second line is the list name. Import preserves existing lists. Quantities and price caps travel with the list.",16,-44,440)

  local scroll=AUI:CreateSmoothScrollFrame(panel);scroll:SetPoint("TOPLEFT",16,-86);scroll:SetSize(448,202)

  local box=CreateFrame("EditBox",nil,scroll);panel.box=box

  box:SetMultiLine(true);box:SetAutoFocus(false);box:SetFontObject("ChatFontNormal");box:SetWidth(432);box:SetMaxLetters(20000)

  scroll:SetScrollChild(box);AUI:ConfigureScrollingEditBox(box,scroll,202)

  self:Button(panel,"Import",16,-308,110,function()

   local ok,message=service():ImportList(box:GetText());if ok then panel:Hide();self:Refresh()end

   return ok,message

  end)

  self:Button(panel,"Close",354,-308,110,function()panel:Hide();return true,""end)

  table.insert(UISpecialFrames,"RUIAuctionListTransfer")

 end

 self.transfer.box:SetText(value);self.transfer:Show();self.transfer.box:SetFocus();self.transfer.box:HighlightText()

end

function U:Skin(root)

 if InCombatLockdown()then AUI:AfterCombat("auctionSkin",function()self:Skin(root)end);return end

 if self.nativeSkins[root]then self:InstallShell(root);return end

 local style=AUI.modules.ForeverStyle

 if style then for _,key in ipairs({"NineSlice","PortraitContainer","Bg"})do if root[key]then style:ArtTree(root[key])end end end

 local surface=CreateFrame("Frame",nil,root,"BackdropTemplate");surface:SetAllPoints(root);surface:EnableMouse(false);surface:SetFrameLevel(root:GetFrameLevel())

 surface:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1});AUI:StyleSurface(surface,"window",1,"Auction");surface:SetBackdropBorderColor(.18,.2,.24,1)

 self.nativeSkins[root]=surface

 local prior

 for _,key in ipairs({"BuyTab","SellTab","AuctionsTab"})do

  local tab=root[key]

  if tab then

   self:SkinButton(tab);tab:ClearAllPoints()

   if prior then tab:SetPoint("LEFT",prior,"RIGHT",5,0)else tab:SetPoint("TOPLEFT",root,"BOTTOMLEFT",12,-4)end

   prior=tab

  end

 end

 if root.SearchBar then self:SkinButton(root.SearchBar.SearchButton)end

 for _,key in ipairs({"SearchBar","CategoriesList","BrowseResultsFrame","ItemBuyFrame","CommoditiesBuyFrame","ItemSellFrame","CommoditiesSellFrame","AuctionsFrame"})do

  local child=root[key]

  if child and child.Background and child.Background.SetAlpha then child.Background:SetAlpha(0)end
  if child and style then for _,name in ipairs({"NineSlice","BorderFrame","Bg"})do if child[name]then style:ArtTree(child[name])end end end

  if child then for _,name in ipairs({"PostButton","BuyButton","BidButton","CancelAuctionButton","RefreshButton"})do self:SkinButton(child[name])end end

 end

 if type(root.SendBrowseQuery)=="function"then hooksecurefunc(root,"SendBrowseQuery",function(_,term,min,max,filters)

  local flags={};for _,id in ipairs(filters or {})do flags[id]=true end

  service():RememberQuery({term=term,minLevel=min,maxLevel=max,filters=flags})

 end)end

 for _,sale in ipairs({root.CommoditiesSellFrame,root.ItemSellFrame})do

  if sale and type(sale.SetItem)=="function"then hooksecurefunc(sale,"SetItem",function(_,item)

   if not item then return end

   C_Timer.After(0,function()if service().open and sale:IsShown()and sale:GetItem()==item and (ProjectRuthlessDB.auctionHouse or {}).autoSaleDefaults~=false then service():ApplySaleDefaults(sale)end end)

  end)end

 end

 self:InstallShell(root)
end

function U:Attach()
 if not AuctionHouseFrame then return end
 if InCombatLockdown()then AUI:AfterCombat("auctionAttach",function()if service().open then self:Attach()end end);return end
 local root=AuctionHouseFrame;local frame=self:Create();self:Skin(root)
 self.embedded=true;frame:SetParent(root);frame:SetScale(1);frame:ClearAllPoints()
 frame:SetPoint("TOPLEFT",root,"TOPLEFT",8,-38);frame:SetSize(root:GetWidth()-16,root:GetHeight()-70)
 frame:SetFrameStrata(root:GetFrameStrata());frame:SetFrameLevel(root:GetFrameLevel()+5)
 self:RestorePlacement();self:Reflow()
 if self.activePage then self:SelectPage(self.activePage)else frame:Hide()end
end

function U:Show(mode)

 if service().open and not InCombatLockdown() then self:Attach()

 else

  self.embedded=false
  local frame=self:Create();frame:SetSize(340,566);frame:SetParent(UIParent);frame:SetFrameStrata("DIALOG");frame:ClearAllPoints();frame:SetPoint("CENTER");frame:Show()

  local editor=AUI.modules.LayoutEditor

  if editor then

   local saved=editor:Store().elements.auctionTools

   if saved then

    frame:SetScale(saved.scale or 1)

    local ratio=UIParent:GetEffectiveScale()/frame:GetEffectiveScale()

    frame:ClearAllPoints();frame:SetPoint("CENTER",UIParent,"CENTER",saved.x*ratio,saved.y*ratio)

   end

  end

 end

 self:SetMode(mode or "supplies")

end

function U:Reflow()
 local f=self.frame;if not f then return end
 local width=f:GetWidth();local embedded=self.embedded
 f.title:SetShown(not embedded);f.close:SetShown(not embedded)
 for index,key in ipairs({"saved","lists","supplies","prices"})do
  local tab=f.tabs[key];tab:SetShown(service().mode~="market")
  tab:ClearAllPoints();tab:SetPoint("TOPLEFT",12+(index-1)*(width-24)/4,embedded and -6 or -34);tab:SetWidth((width-24)/4-4)
 end
 local filterY=embedded and 38 or 65
 f.filter:ClearAllPoints();f.filter:SetPoint("TOPLEFT",12,-filterY);f.filter:SetWidth(width-24);f.filterHint:SetWidth(width-40)
 f.context:ClearAllPoints();f.context:SetPoint("TOPLEFT",12,-filterY-28);f.context:SetWidth(width-24)
 for i,b in ipairs(f.actions)do
  b:ClearAllPoints();b:SetPoint("TOPLEFT",12+(i-1)*(width-24)/3,-filterY-56);b:SetWidth((width-24)/3-5)
 end
 f.summary:ClearAllPoints();f.summary:SetPoint("TOPLEFT",12,embedded and -125 or -150);f.summary:SetWidth(width-24)
 local pageY=embedded and f:GetHeight()-76 or 480
 f.previous:ClearAllPoints();f.previous:SetPoint("TOPLEFT",12,-pageY)
 f.next:ClearAllPoints();f.next:SetPoint("TOPLEFT",width-42,-pageY)
 f.pageLabel:ClearAllPoints();f.pageLabel:SetPoint("TOPLEFT",52,-pageY-4);f.pageLabel:SetWidth(width-104)
 f.message:ClearAllPoints();f.message:SetPoint("TOPLEFT",12,-pageY-28);f.message:SetWidth(width-24);f.message:SetHeight(44)
end
function U:SelectPage(page)
 local root=AuctionHouseFrame;if not root or not service().open then return end
 if not self.embedded or not self.frame or self.frame:GetParent()~=root then
  if InCombatLockdown()then return end
  self:Attach()
 end
 self.activePage=page
 if page=="tools"or page=="market"or page=="settings"then
  local current=root:GetDisplayMode()
  if current~=self.toolsDisplayMode then
   self.lastNativeMode=current;self.lastSaleFrame=service():SaleFrame()
   self.lastSaleItem=self.lastSaleFrame and self.lastSaleFrame:GetItem()
  end
  self.toolsDisplayMode=self.toolsDisplayMode or {}
  root:SetDisplayMode(self.toolsDisplayMode)
  local title=root.TitleText or (root.TitleContainer and root.TitleContainer.TitleText)
  if title then title:SetText(page=="settings"and "Auction house · Settings"or page=="market"and "Auction house · Market prices"or "Auction house · Tools")end
  local f=self:Create()
  if page=="market"then service().mode="market"elseif service().mode=="market"then service().mode="saved"end
  f:SetShown(page~="settings");self.settings:SetShown(page=="settings")
  if page~="settings"then self:Refresh()end
 else
  self.frame:Hide();self.settings:Hide();self.activePage=nil
  local modes=AuctionHouseFrameDisplayMode
  root:SetDisplayMode(page=="sell"and modes.ItemSell or page=="auctions"and modes.Auctions or modes.Buy)
 end
 self:HighlightTabs()
end
function U:HighlightTabs()
 local mode=AuctionHouseFrame and AuctionHouseFrame:GetDisplayMode()
 local modes=AuctionHouseFrameDisplayMode
 local selected=self.activePage or (mode==modes.Auctions and "auctions"
  or (mode==modes.ItemSell or mode==modes.CommoditiesSell or mode==modes.WoWTokenSell)and "sell"or "buy")
 for id,button in pairs(self.bottomTabs or {})do
  local active=selected==id;local surface=self.buttonSkins[button]or button
  surface:SetBackdropBorderColor(active and .65 or .2,active and .5 or .22,active and .8 or .27,1)
 end
end
function U:SavePlacement()
 local root=AuctionHouseFrame;local editor=AUI.modules.LayoutEditor
 if root and editor and not InCombatLockdown()then
  local value=editor:Capture(root);if value then editor:Store().elements.auctionHouse=value end
 end
end
function U:RestorePlacement()
 local root=AuctionHouseFrame;if not root or InCombatLockdown()or self.dragging or self.placing then return end
 self.placing=true
 local editor=AUI.modules.LayoutEditor;local saved=editor and editor:Store().elements.auctionHouse
 local fit=math.min(1,(UIParent:GetWidth()-40)/root:GetWidth(),(UIParent:GetHeight()-80)/(root:GetHeight()+38))
 local scale=saved and saved.scale or fit
 root:SetScale(math.min(fit,math.max(.55,scale)));root:ClearAllPoints()
 if saved and type(saved.x)=="number"and type(saved.y)=="number"then
  local ratio=UIParent:GetEffectiveScale()/root:GetEffectiveScale()
  root:SetPoint("CENTER",UIParent,"CENTER",saved.x*ratio,saved.y*ratio)
 else root:SetPoint("CENTER",UIParent,"CENTER",0,0)end
 self.placing=nil
end
function U:QueuePlacement()
 if self.placing or self.dragging or self.placementQueued or not service().open then return end
 self.placementQueued=true
 C_Timer.After(0,function()self.placementQueued=nil;if AuctionHouseFrame and AuctionHouseFrame:IsShown()then self:RestorePlacement()end end)
end
function U:CreateSettings(root)
 if self.settings then return end
 local panel=CreateFrame("Frame",nil,root,"BackdropTemplate");self.settings=panel
 panel:SetPoint("TOPLEFT",root,"TOPLEFT",8,-38);panel:SetPoint("BOTTOMRIGHT",root,"BOTTOMRIGHT",-8,32)
 panel:SetFrameLevel(root:GetFrameLevel()+6);AUI:StyleSurface(panel,"window",1,"Auction")
 label(panel,"Auction house settings",18,-12,720,"GameFontNormal")
 label(panel,"Saved with your RUI profile. Searches, shopping lists and selling preferences stay with this character.",18,-38,720)
 panel.controls={}
 for index,row in ipairs(AUI.modules.SettingsRegistry.auctionControls)do
  local key=row[1];local y=72+(index-1)*65
  local control=self:Button(panel,"",18,-y,260,function()
   local settings=ProjectRuthlessDB.auctionHouse;settings[key]=settings[key]==false
   AUI:SettingsChanged("AuctionHouse",key);self:UpdateSettings();return true,"Setting saved."
  end)
  panel.controls[index]={button=control,key=key,title=row[2]}
  label(panel,row[3],292,-y-3,450)
 end
 self:Button(panel,"Default sale duration",18,-346,260,function()
  local prefs=service():Store().preferences;prefs.duration=prefs.duration%3+1;self:UpdateSettings();return true,"Default sale duration saved."
 end)
 panel.duration=label(panel,"",292,-351,450)
 self:Button(panel,"Reset window position",18,-386,260,function()
  local editor=AUI.modules.LayoutEditor;if editor then editor:Store().elements.auctionHouse=nil end
  self:RestorePlacement();return true,"Auction window returned to the centre."
 end)
 label(panel,"Drag the title bar to move the whole auction house. Its position persists across visits and reloads.",292,-386,450)
 panel:Hide();self:UpdateSettings()
end
function U:UpdateSettings()
 if not self.settings then return end
 for _,row in ipairs(self.settings.controls)do row.button:SetText(((ProjectRuthlessDB.auctionHouse or {})[row.key]==false and "Off · "or "On · ")..row.title)end
 local names={AUCTION_DURATION_ONE or "Short",AUCTION_DURATION_TWO or "Medium",AUCTION_DURATION_THREE or "Long"}
 self.settings.duration:SetText(names[service():Store().preferences.duration]or names[2])
end
function U:InstallShell(root)
 if self.shellInstalled then return end
 self.shellInstalled=true
 self:CreateSettings(root);self.bottomTabs={}
 if root.CloseButton then
  self:SkinButton(root.CloseButton)
  label(root.CloseButton,"×",5,-3,16,"GameFontNormal")
 end
 local title=root.TitleText or (root.TitleContainer and root.TitleContainer.TitleText)
 if title and title.SetFontObject then title:SetFontObject(GameFontNormal)end
 local width=(root:GetWidth()-24)/6
 for index,row in ipairs({{"buy","Buy","BuyTab"},{"sell","Sell","SellTab"},{"auctions","Auctions","AuctionsTab"},{"tools","Tools"},{"market","Market prices"},{"settings","Settings"}})do
  local id=row[1];local button=row[3]and root[row[3]]
  if not button then button=AUI:CreateButton(root);button:SetText(row[2]);button:SetScript("OnClick",function()self:SelectPage(id)end)end
  button:ClearAllPoints();button:SetPoint("TOPLEFT",root,"BOTTOMLEFT",12+(index-1)*width,-4);button:SetSize(width-4,28)
  self:SkinButton(button);self.bottomTabs[id]=button
  local font=button.GetFontString and button:GetFontString()
  if font and font.SetFontObject then font:SetFontObject(GameFontHighlightSmall);font:SetTextColor(AUI:AccentColor())end
  button:HookScript("OnShow",function()button:SetSize(width-4,28);self:HighlightTabs()end)
 end
 local surface=self.nativeSkins[root]
 if surface then surface:ClearAllPoints();surface:SetPoint("TOPLEFT",root,"TOPLEFT",0,0);surface:SetPoint("BOTTOMRIGHT",root,"BOTTOMRIGHT",0,-36)end
 root:SetMovable(true);root:SetClampedToScreen(true)
 local header=CreateFrame("Frame",nil,root);self.dragHandle=header
 header:SetPoint("TOPLEFT",root,"TOPLEFT",4,-2);header:SetSize(root:GetWidth()-48,28);header:EnableMouse(true);header:RegisterForDrag("LeftButton")
 header:SetScript("OnDragStart",function()if not InCombatLockdown()then self.dragging=true;root:StartMoving()end end)
 header:SetScript("OnDragStop",function()root:StopMovingOrSizing();self.dragging=nil;self:SavePlacement()end)
 root:HookScript("OnHide",function()if self.frame and self.frame:GetParent()==root then self.frame:Hide()end;self.settings:Hide();self.activePage=nil end)
 root:HookScript("OnShow",function()self:QueuePlacement()end)
 if type(root.SetPoint)=="function"then hooksecurefunc(root,"SetPoint",function()self:QueuePlacement()end)end
 if type(root.SetDisplayMode)=="function"then hooksecurefunc(root,"SetDisplayMode",function(_,mode)
  if mode~=self.toolsDisplayMode then
   self.activePage=nil;if self.frame and self.frame:GetParent()==root then self.frame:Hide()end;self.settings:Hide();self:HighlightTabs()
  end
 end)end
end

function U:ApplySettings()

 if not self.frame then return end

 AUI:StyleSurface(self.frame,"window",1,"Auction")

 for _,surface in pairs(self.nativeSkins)do AUI:StyleSurface(surface,"window",1,"Auction")end

 for _,surface in pairs(self.buttonSkins)do AUI:StyleSurface(surface,"surface",1,"Auction")end
 if self.settings then AUI:StyleSurface(self.settings,"window",1,"Auction");self:UpdateSettings()end

 self:QueueRefresh()

end

