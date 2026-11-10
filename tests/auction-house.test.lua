unpack=table.unpack
local timers={};local busy=false;local now=100000;local created=0
local function flush()
 local loops=0
 while #timers>0 do loops=loops+1;assert(loops<30,'refresh loop');local pending=timers;timers={};for _,fn in ipairs(pending)do fn()end end
end
C_Timer={After=function(_,fn)timers[#timers+1]=fn end}
function time()return now end
function date()return '08 Nov'end
function InCombatLockdown()return busy end
local secret={};function issecretvalue(value)return value==secret end
function GetBuildInfo()return '1.60.1','70862','',16001 end
local realm='Test realm';function GetRealmName()return realm end
function UnitFactionGroup()return 'Alliance'end
local prototype={};prototype.__index=prototype
local function frame(parent)
 created=created+1;local value=setmetatable({shown=true,scripts={},parent=parent,w=800,h=538,scale=1,events={},text='',children={}},prototype)
 if parent then parent.children=parent.children or {};parent.children[#parent.children+1]=value end
 return value
end
function prototype:SetPoint(...)self.point={...}end
function prototype:ClearAllPoints()self.point=nil end
function prototype:SetParent(parent)self.parent=parent end;function prototype:GetParent()return self.parent end
function prototype:SetSize(w,h)self.w=w;self.h=h end
function prototype:SetWidth(w)self.w=w end;function prototype:SetHeight(h)self.h=h end
function prototype:GetWidth()return self.w end;function prototype:GetHeight()return self.h end
function prototype:SetScale(value)self.scale=value end;function prototype:GetScale()return self.scale end
function prototype:GetEffectiveScale()return self.scale end
function prototype:SetFrameStrata(value)self.strata=value end;function prototype:GetFrameStrata()return self.strata or 'DIALOG'end
function prototype:SetFrameLevel(value)self.level=value end;function prototype:GetFrameLevel()return self.level or 5 end
function prototype:SetAllPoints()end;function prototype:SetBackdrop()end
function prototype:SetBackdropBorderColor()end;function prototype:SetBackdropColor()end
function prototype:SetTexture(texture)self.texture=texture end;function prototype:GetTexture()return self.texture end
function prototype:GetAtlas()return self.atlas end;function prototype:SetAtlas(atlas)self.atlas=atlas end
function prototype:SetTexCoord()end;function prototype:SetAlpha(alpha)self.alpha=alpha end
function prototype:SetText(value)self.text=tostring(value);if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self,true)end end
function prototype:GetText()return self.text end
function prototype:SetFont(face,size)self.face=face;self.fontSize=size end
function prototype:GetFont()return self.face or 'Font',self.fontSize or 12 end
function prototype:SetWordWrap()end
function prototype:SetFontString()end;function prototype:SetTextColor()end;function prototype:SetJustifyH()end;function prototype:SetSpacing()end
function prototype:SetAutoFocus()end;function prototype:SetMaxLetters()end;function prototype:SetNumeric()end;function prototype:ClearFocus()end
function prototype:EnableMouse()end;function prototype:SetMovable()end;function prototype:SetClampedToScreen()end
function prototype:RegisterForDrag()end;function prototype:RegisterForClicks()end
function prototype:StartMoving()self.moving=true end;function prototype:StopMovingOrSizing()self.moving=false end
function prototype:SetScript(event,fn)self.scripts[event]=fn end
function prototype:HookScript(event,fn)local old=self.scripts[event];self.scripts[event]=function(...)if old then old(...)end;fn(...)end end
function prototype:IsShown()return self.shown end;prototype.IsVisible=prototype.IsShown
function prototype:Show()local prior=self.shown;self.shown=true;if not prior and self.scripts.OnShow then self.scripts.OnShow(self)end end
function prototype:Hide()local prior=self.shown;self.shown=false;if prior and self.scripts.OnHide then self.scripts.OnHide(self)end end
function prototype:SetShown(value)if value then self:Show()else self:Hide()end end
function prototype:CreateFontString()return frame(self)end;function prototype:CreateTexture()return frame(self)end
function prototype:RegisterEvent(event)self.events[event]=true end;function prototype:UnregisterAllEvents()self.events={}end
function CreateFrame(_,name,parent)local value=frame(parent);if name then _G[name]=value end;return value end
function hooksecurefunc(owner,method,callback)
 local original=assert(owner[method]);owner[method]=function(...)local result={original(...)};callback(...);return table.unpack(result)end
end
UIParent=frame();UIParent.w=1920;UIParent.h=1080
UISpecialFrames={}
local AUI={modules={},isForever=true}
function AUI:RegisterModule(name,value)self.modules[name]=value end
assert(load(SETTINGSREGISTRY_SOURCE))('RUI',AUI)
function AUI:CreateButton(parent)return frame(parent)end
function AUI:StyleSurface()end;function AUI:PaintBackground()end
function AUI:AccentColor()return .6,.4,.7 end
function AUI:Print(message)self.message=message end
local deferred={}
function AUI:AfterCombat(key,fn)if busy then deferred[key]=fn else fn()end end
function AUI:QueueRefresh(owner)
 if owner.queued then return end;owner.queued=true
 C_Timer.After(0,function()owner.queued=nil;if owner.frame and owner.frame:IsShown()then owner:Refresh()end end)
end
ProjectRuthlessDB={};ProjectRuthlessCharDB={activeProfile='Existing profile'}
local stock={ [731]=3,[729]=1 };local itemCalls=0
C_Item={GetItemCount=function(id,bank,charges,reagent)assert(bank and not charges and reagent);itemCalls=itemCalls+1;return stock[id]or 0 end,
 GetItemIconByID=function(id)return id end,GetItemInfo=function(id)
  local values={[1]=id==731 and 'Murloc Eye'or 'Item '..id,[2]='item:'..id,[14]=0}
  return table.unpack(values,1,14)
 end}
local completed={};C_QuestLog={GetAllCompletedQuestIDs=function()return completed end,
 GetTitleForQuestID=function(id)return id==38 and 'Westfall Stew'or 'Observed quest'end,
 GetLogIndexForQuestID=function()return 1 end,GetInfo=function()return {level=13,zoneOrSort=40}end}
local backendCalls=0;local ready=true;local nativeQueries={};local resultReads=0;local full=true
local key={itemID=731,itemLevel=0,itemSuffix=0,battlePetSpeciesID=0}
local results={
 {itemKey=key,quantity=2,buyoutAmount=200,containsOwnerItem=false},
 {itemKey=key,quantity=10,buyoutAmount=800,containsOwnerItem=true},
 {itemKey={itemID=731,itemLevel=1},quantity=1,buyoutAmount=1,containsOwnerItem=false},
}
local commodities={{quantity=10,unitPrice=12,containsOwnerItem=true,numOwnerItems=2}}
local owned={{auctionID=9001,itemKey=key,quantity=4,buyoutAmount=800}}
local cancelled={}
C_AuctionHouse={IsThrottledMessageSystemReady=function()return ready end,MakeItemKey=function(id)return {itemID=id,itemLevel=0,itemSuffix=0,battlePetSpeciesID=0}end,
 GetItemKeyInfo=function()return {isCommodity=false}end,
 GetNumItemSearchResults=function()return #results end,GetItemSearchResultInfo=function(_,index)resultReads=resultReads+1;return results[index]end,
 GetNumCommoditySearchResults=function()return #commodities end,GetCommoditySearchResultInfo=function(_,index)return commodities[index]end,
 HasFullItemSearchResults=function()return full end,HasFullCommoditySearchResults=function()return full end,
 GetNumOwnedAuctions=function()return #owned end,GetOwnedAuctionInfo=function(index)return owned[index]end,
 GetItemKeyFromItem=function(item)return item.key end,
 CancelAuction=function(id)cancelled[#cancelled+1]=id end,GetCancelCost=function()return 15 end,
 PlaceBid=function()error('unexpected purchase')end,PostItem=function()error('unexpected post')end,PostCommodity=function()error('unexpected post')end}
AuctionHouseFrameDisplayMode={Buy={},Auctions={},ItemSell={}}
AuctionHouseSearchContext={AllAuctions=1}
g_auctionHouseFilters={minLevel=0,maxLevel=0,filters={[2]=true,[4]=false}}
AuctionHouseFrame=frame(UIParent)
function AuctionHouseFrame:SetDisplayMode(mode)self.mode=mode end
function AuctionHouseFrame:GetDisplayMode()return self.mode end
function AuctionHouseFrame:QueryAll()backendCalls=backendCalls+1 end
function AuctionHouseFrame:SendBrowseQuery(term,min,max,filters)backendCalls=backendCalls+1;nativeQueries[#nativeQueries+1]={term=term,min=min,max=max,filters=filters}end
function AuctionHouseFrame:SelectBrowseResult(result)backendCalls=backendCalls+1;self.selected=result.itemKey end
AuctionHouseFrame.SearchBar=frame(AuctionHouseFrame);local search=AuctionHouseFrame.SearchBar
search.SearchBox=frame(search)
function search:SetSearchText(value)self.SearchBox:SetText(value)end
function search:UpdateClearFiltersButton()end
function search:StartSearch()
 local filters={};for id,value in pairs(g_auctionHouseFilters.filters)do if value then filters[#filters+1]=id end end
 AuctionHouseFrame:SendBrowseQuery(self.SearchBox:GetText(),g_auctionHouseFilters.minLevel,g_auctionHouseFilters.maxLevel,filters)
end
AuctionHouseFrame.CategoriesList=frame()
function AuctionHouseFrame.CategoriesList:SetSelectedCategory(value)self.category=value end
local sale=frame(AuctionHouseFrame);AuctionHouseFrame.ItemSellFrame=sale
AuctionHouseFrame.CommoditiesSellFrame=frame();AuctionHouseFrame.CommoditiesSellFrame.shown=false
local commoditySale=AuctionHouseFrame.CommoditiesSellFrame
function commoditySale:GetItem()return nil end;function commoditySale:SetItem()end
sale.item={key=key};sale.priceWrites=0
sale.QuantityInput=frame();sale.QuantityInput.quantity=5
function sale.QuantityInput:SetQuantity(value)self.quantity=value end
sale.PriceInput=frame();function sale.PriceInput:SetAmount(value)sale.priceWrites=sale.priceWrites+1;self.amount=value end
sale.Duration=frame();sale.Duration.duration=2
function sale.Duration:SetDuration(value)self.duration=value end
function sale:GetItem()return self.item end;function sale:SetItem(value)self.item=value end
function sale:GetQuantity()return self.QuantityInput.quantity end
function sale:GetDuration()return self.Duration.duration end
function sale:GetMaxQuantity()return 4 end
function sale:UpdatePostState()self.updated=true end
local choices
MenuUtil={CreateContextMenu=function(_,build)
 choices={};build(nil,{CreateButton=function(_,name,callback)choices[#choices+1]={name=name,callback=callback}end})
end}
local popup
function StaticPopup_Show(name,_,_,data)popup=frame();popup.which=name;popup.data=data;popup.MoneyFrame={}end
function MoneyFrame_Update(_,cost)assert(cost==15)end
StaticPopupDialogs={};assert(load(CANCEL_DIALOG))()

assert(load(QUESTSUPPLYDATA_SOURCE))('ProjectRuthless',AUI)
assert(load(QUESTSUPPLIES_SOURCE))('ProjectRuthless',AUI)
assert(load(AUCTIONHOUSE_SOURCE))('ProjectRuthless',AUI)
assert(load(AUCTIONMARKET_SOURCE))('ProjectRuthless',AUI)
assert(load(AUCTIONHOUSEUI_SOURCE))('ProjectRuthless',AUI)
local a,q,ui=AUI.modules.AuctionHouse,AUI.modules.QuestSupplies,AUI.modules.AuctionHouseUI
assert(AUI.modules.QuestSupplyData.data==nil,'catalogue must not allocate on login')
q:OnPlayerLogin();a:OnPlayerLogin();assert(backendCalls==0 and not ui.frame)
local nativeRoot=AuctionHouseFrame;AuctionHouseFrame=nil
a.events.scripts.OnEvent(nil,'AUCTION_HOUSE_SHOW');flush();assert(not ui.frame)
AuctionHouseFrame=nativeRoot;nativeRoot.shown=false
a.events.scripts.OnEvent(nil,'ADDON_LOADED','Blizzard_AuctionHouseUI');flush();assert(not ui.frame)
nativeRoot:Show();flush();assert(ui.frame and ui.frame:GetParent()==nativeRoot)
a.events.scripts.OnEvent(nil,'AUCTION_HOUSE_CLOSED');ui.frame:Hide()
local queued=#timers
for _=1,100 do a.events.scripts.OnEvent(nil,'ADDON_LOADED','UnrelatedAddon')end
assert(#timers==queued and backendCalls==0)
assert(#a:Checks()==1 and AUI.modules.QuestSupplyData.data==nil,'diagnostics summary stays lazy')

local catalogue=AUI.modules.QuestSupplyData:Get();local total,reference,unknown,_,withheld=q:Coverage()
assert(withheld==92 and catalogue.clientDeclaredRecords==6706)
assert(total==6614 and reference==363 and unknown==3079)
local rows=q:Rows(40,'Westfall Stew',false);assert(#rows==4)
for _,row in ipairs(rows)do assert(row.source:find('Classic reference',1,true));if row.itemID==731 then assert(row.quantity==3 and row.need==0)end end
itemCalls=0;q:Rows(0,'',false);assert(itemCalls<=323,'one inventory lookup per distinct candidate, not per quest')
completed={38};assert(#q:Rows(40,'Westfall Stew',false)==0);completed={}
function GetQuestID()return 38 end;function GetNumQuestItems()return 1 end
function GetQuestItemLink()return 'item:731'end
function GetQuestItemInfo()return 'Murloc Eye',1,8 end
q.events.scripts.OnEvent(nil,'QUEST_PROGRESS');rows=q:Rows(40,'Westfall Stew',false)
assert(#rows==1 and rows[1].quantity==8 and rows[1].need==5 and rows[1].source=='Forever turn-in observed')
local observed=q:Store().quests[38]
GetQuestItemLink=function()return nil end;q:ObserveProgress();assert(q:Store().quests[38]==observed,'partial results must not overwrite confirmed requirements')
busy=true;q:ObserveProgress();busy=false
print('PASS: full client-record ledger, multi-zone reference supplies, batched inventory counts, completion filter and authoritative native turn-in observations')

assert(not a:ApplyQuery({term='Murloc Eye'},true))
search:SetSearchText('Murloc Eye');g_auctionHouseFilters.minLevel=5;g_auctionHouseFilters.maxLevel=20
a.events.scripts.OnEvent(nil,'AUCTION_HOUSE_SHOW');flush();assert(a.open and ui.frame and backendCalls==0)
assert(a:SaveSearch(nil,true));assert(a:SetDefault())
a.events.scripts.OnEvent(nil,'AUCTION_HOUSE_CLOSED');local beforeDefault=backendCalls
search:SetSearchText('Other');g_auctionHouseFilters.minLevel=0
a.events.scripts.OnEvent(nil,'AUCTION_HOUSE_SHOW');flush()
assert(search.SearchBox:GetText()=='Murloc Eye'and g_auctionHouseFilters.minLevel==5 and backendCalls==beforeDefault,'default restore must not send a query')
local current=a:CurrentQuery();assert(current.filters[2]==true and current.filters[4]==false)
assert(a:ApplyQuery({term='Linen Cloth',minLevel=1,maxLevel=15,filters={[7]=true,[2]=false}},true));flush()
assert(nativeQueries[#nativeQueries].term=='Linen Cloth'and g_auctionHouseFilters.filters[7]and not g_auctionHouseFilters.filters[2])
assert(#a:Store().history==1,'native search history hook receives self and the actual query')
local calls=backendCalls;ready=false;assert(not a:ApplyQuery({term='Throttled'},true)and backendCalls==calls);ready=true
assert(not a:ApplyQuery({term='Invalid',minLevel=30,maxLevel=10},true)and backendCalls==calls)
assert(a:NewList('Westfall'));assert(not a:NewList(''))
assert(a:AddToList('Westfall',{term='Murloc Eye',itemID=731,quantity=6,maxPrice=120}))
assert(a:ListNeed(a:Store().lists.Westfall[1])==3)
assert(a:AddToList('Westfall',{term='Murloc Eye',itemID=731,quantity=6}))
assert(a:Store().lists.Westfall[1].maxPrice==120)
assert(not a:AddToList('Westfall',{term='Bad',quantity=1.5}))
assert(a:ParseMoney('2g 50s 2c')==25002 and a:ParseMoney('1.5g')==15000 and a:ParseMoney('42')==42)
assert(a:ParseMoney('')==nil and a:ParseMoney('-1g')==nil and a:ParseMoney('2g3g')==nil)
local exported=a:ExportList('Westfall');assert(exported:match('RUI_SHOPPING_1'))
local copyText=exported:gsub('Westfall','Imported Westfall',1)
assert(a:ImportList(copyText)and a:Store().lists['Imported Westfall'][1].maxPrice==120)
assert(not a:ImportList(copyText))
assert(not a:ImportList('RUI_SHOPPING_1\nInvalid import\n731\t2\t10\tMurloc Eye\ninvalid'))
assert(not a:Store().lists['Invalid import']);a.listName='Westfall'
assert(a:SearchNext()and AuctionHouseFrame.selected.itemID==731)
ready=false;local cursor=a.listCursor;assert(not a:SearchNext()and a.listCursor==cursor);ready=true
local history=a:Store().history
for i=1,40 do a:RememberQuery({term='Item '..i})end
assert(#history==30)
print('PASS: character search/default/filter persistence, throttle/closed-house guards, bounded recent history and inventory-aware shopping targets')

for _=1,100 do a.events.scripts.OnEvent(nil,'ITEM_SEARCH_RESULTS_UPDATED',key)end
local beforeReads=resultReads;flush();assert(resultReads-beforeReads==3,'result bursts coalesce')
local quote=a.quotes[a:ItemKey(key)]
assert(quote.minimum==80 and quote.competition==100 and quote.complete)
assert(a:RememberSale());sale.QuantityInput.quantity=30;assert(a:ApplySaleDefaults(sale)and sale:GetQuantity()==4 and sale:GetDuration()==2)
assert(a:SuggestSale()and sale.PriceInput.amount==100)
a:Store().preferences.undercut=1;assert(a:SuggestSale()and sale.PriceInput.amount==99)
now=now+61;calls=sale.priceWrites;assert(not a:SuggestSale()and sale.priceWrites==calls)
full=false;a:ObserveResults(key,false);assert(not a:SuggestSale()and sale.priceWrites==calls);full=true
sale.item={key={itemID=732,itemLevel=0}};assert(not a:SuggestSale());sale.item={key=key}
a:ObserveResults(key,false)
local mine=a:OwnedRows();assert(mine[1].undercut)
assert(a:CancelOwned(9001)and popup.which=='CANCEL_AUCTION'and #cancelled==0)
StaticPopupDialogs.CANCEL_AUCTION.OnShow(popup,popup.data);assert(#cancelled==0)
-- Cancelling the confirmation has no side effect. Accepting uses Blizzard's real callback.
popup=nil;assert(a:CancelOwned(9001));StaticPopupDialogs.CANCEL_AUCTION.OnAccept(popup,popup.data)
assert(#cancelled==1 and cancelled[1]==9001)
Enum={AuctionStatus={Sold=2}}
owned[1].status=2;popup=nil;assert(not a:CancelOwned(9001)and not popup)
owned[1].status=0;owned[1].buyoutAmount=nil;assert(a:OwnedRows()[1].bidOnly and a:CancelOwned(9001))
owned={};popup=nil;assert(not a:CancelOwned(9001)and not popup)
local commodityKey={itemID=732,itemLevel=0,itemSuffix=0,battlePetSpeciesID=0}
a:ObserveResults(commodityKey,true);assert(a.quotes[a:ItemKey(commodityKey)].competition==12)
commodities[1].containsAccountItem=true;a:ObserveResults(commodityKey,true);assert(a.quotes[a:ItemKey(commodityKey)].competition==nil)
commodities[1].containsAccountItem=false
for i=1,20 do now=now+86400;a:ObserveResults(key,false)end
assert(#a:Market().items[a:ItemKey(key)].samples==14)
local originalMarket=a:MarketKey();realm='Other realm';assert(next(a:Market().items)==nil);realm='Test realm';assert(a:MarketKey()==originalMarket)
busy=true;calls=sale.priceWrites;assert(a:SuggestSale()and sale.priceWrites==calls+1);busy=false
print('PASS: exact-variant stack/unit comparisons, owner exclusion, fresh/complete quote gate, bounded realm history, saved sale defaults and real native cancel confirmation')

ui:SetMode('saved');flush();ui.frame.actions[2].scripts.OnClick();assert(a:Store().default)
ui.frame.actions[3].scripts.OnClick();assert(not a:Store().default)
ui:SetMode('lists');flush();a.listName='Westfall';ui:Refresh()
local entry=ui.currentRows[1];ui:EditTarget(entry)
ui.targetEditor.qty:SetText('9');ui.targetEditor.cap:SetText('110')
-- First editor button is found through its position and the parent's recorded creation below.
assert(ui.targetEditor.entry.shopping.quantity==6)
local saveButton
for _,child in ipairs(ui.targetEditor.children)do if child.text=='Save'then saveButton=child end end
assert(saveButton);saveButton.scripts.OnClick()
assert(a:Store().lists.Westfall[1].quantity==9 and a:Store().lists.Westfall[1].maxPrice==110)
ui:EditTarget(entry);ui.targetEditor.qty:SetText('12')
a:NewList('Other list');saveButton.scripts.OnClick()
assert(a:Store().lists.Westfall[1].quantity==12 and #a:Store().lists['Other list']==0,'editor must retain original list identity')
a.listName='Westfall'
ui:SetMode('supplies');flush();assert(ui.frame.context.text:find('All zones',1,true))
ui.frame.filter:SetText('Westfall Stew');flush();assert(#ui.currentRows==1 and ui.currentRows[1].quantity==8)
ui.frame.rows[1].scripts.OnClick(ui.frame.rows[1],'LeftButton');assert(AuctionHouseFrame.selected.itemID==731)
ui.frame.actions[2].scripts.OnClick();flush();assert(a:Store().lists[a.listName][1].quantity==8)
ui:SetMode('prices');flush();assert(#ui.currentRows>=1)
ProjectRuthlessDB.auctionHouse.trackPrices=false;local reads=resultReads;a:QueueResults(key,false);flush();assert(resultReads==reads)
assert(not a:SuggestSale());ProjectRuthlessDB.auctionHouse.trackPrices=true
ProjectRuthlessDB.auctionHouse.retainHistory=false;local countHistory=#a:Store().history;a:RememberQuery({term='Do not retain'});assert(#a:Store().history==countHistory)
ProjectRuthlessDB.auctionHouse.retainHistory=true
ProjectRuthlessDB.accessibility={textScale=1.5};ui:Refresh();assert(ui.perPage==2)
ProjectRuthlessDB.accessibility.textScale=1;ui:Refresh();assert(ui.perPage==3)
local frameCount=created
for _=1,100 do a.events.scripts.OnEvent(nil,'BAG_UPDATE_DELAYED')end
flush();assert(created==frameCount,'refreshes must reuse rows and controls')
a.events.scripts.OnEvent(nil,'AUCTION_HOUSE_CLOSED');assert(not a.open and next(a.quotes)==nil)
calls=backendCalls;assert(not a:SearchEntry({name='Murloc Eye',itemID=731})and backendCalls==calls)
ui:Show('supplies');flush();assert(ui.frame:GetParent()==UIParent)
local char=ProjectRuthlessCharDB;ProjectRuthlessCharDB={};assert(#a:Store().saved==0 and next(a:Store().lists)==nil);ProjectRuthlessCharDB=char
ui.frame:Hide();local timerCount=#timers
for _=1,100 do a.events.scripts.OnEvent(nil,'BAG_UPDATE_DELAYED')end
assert(#timers==timerCount,'closed tools must not queue inventory rendering')
print('PASS: live UI controls switch modes, edit shopping targets, create zone lists, select native listings, reuse widgets and prevent offline transactions')

-- Meter cosmetics never enter native combat-data paths or replace its interaction scripts.
local nativeUpdates=0;local nativeClick=function()nativeUpdates=nativeUpdates+1 end
local row=frame();row.StatusBar=frame();row.StatusBar.Name=frame();row.StatusBar.Value=frame();row.StatusBar.Background=frame();row.StatusBar.BackgroundEdge=frame()
local barTexture=frame();barTexture.texture='NativeTexture';barTexture.atlas='NativeAtlas'
function row.StatusBar:GetStatusBarTexture()return barTexture end
function row.StatusBar:SetStatusBarTexture(asset)assert(not busy);self.asset=asset;barTexture.atlas=nil;barTexture.texture=asset end
row.scripts.OnClick=nativeClick
local scroll=frame();function scroll:ForEachFrame(callback)callback(row)end
local callbacks={};ScrollUtil={AddInitializedFrameCallback=function(_,fn,owner)callbacks[#callbacks+1]=function(entry)fn(owner,entry)end end}
DamageMeterSessionWindow1=frame();DamageMeterSessionWindow1.Header=frame();DamageMeterSessionWindow1.MinimizeContainer={ScrollBox=scroll}
DamageMeter={SetupSessionWindow=function()error('native setup must not be called')end}
C_DamageMeter={IsDamageMeterAvailable=function()return true end,GetCombatSession=function()error('combat data must stay native')end}
local enabled=false;C_CVar={GetCVarBool=function()return enabled end}
Settings={GetSetting=function()return {SetValue=function(_,value)enabled=value end}end}
assert(load(FOREVERMETERS_SOURCE))('ProjectRuthless',AUI)
local meter=AUI.modules.ForeverMeters;meter:OnPlayerLogin();flush()
assert(not enabled,'existing profile activation stays unchanged')
assert(row.StatusBar.asset=='Interface\\Buttons\\WHITE8X8'and row.scripts.OnClick==nativeClick)
ProjectRuthlessDB.meterStyle={textSize=15};meter:ApplySettings();assert(row.StatusBar.Name.fontSize==15 and #callbacks==1)
ProjectRuthlessDB.meterStyle.flatBars=false;meter:ApplySettings();assert(row.StatusBar.asset=='NativeTexture'and barTexture.atlas=='NativeAtlas')
ProjectRuthlessDB.meterStyle.flatBars=true;meter:ApplySettings()
busy=true;local asset=row.StatusBar.asset;callbacks[1](row);flush();assert(deferred.nativeMeters and row.StatusBar.asset==asset)
busy=false;deferred.nativeMeters();assert(row.scripts.OnClick==nativeClick)
row.scripts.OnClick();assert(nativeUpdates==1)
print('PASS: RUI meter chrome/rows retain native live data and clicks, apply font settings, register once and defer cosmetics through combat')

function prototype:GetStringHeight()return 16 end
function prototype:SetScrollChild(child)self.scrollChild=child end
function AUI:CreateSmoothScrollFrame(parent)return frame(parent)end
AUI.Theme={border={.1,.1,.1,1},text={1,1,1},muted={.6,.6,.6}}
function AUI:SettingsChanged(section,key)self.changedSection=section;self.changedKey=key end
assert(load(MENU_SOURCE))('RUI',AUI);local menu=AUI.modules.Menu
menu.buildingPage='auctionhouse';menu:CreateAuctionOptions(frame())
assert(#menu.optionControls==4)
local toggle=menu.optionControls[1];local prior=ProjectRuthlessDB.auctionHouse.autoOpen
-- Invoke the actual settings control, including its module-scoped refresh route.
toggle.scripts.OnClick(toggle)
assert(ProjectRuthlessDB.auctionHouse.autoOpen==not prior and AUI.changedSection=='AuctionHouse')
ProjectRuthlessDB.general={backgroundAuction=.5}
assert(load(PROFILES_SOURCE))('RUI',AUI);local preferences=AUI.modules.Profiles
local profile=preferences:Export();local parsed=assert(preferences:Parse(profile))
assert(parsed.auctionHouse.autoOpen==not prior and parsed.meterStyle.textSize==15 and parsed.general.backgroundAuction==.5)
local lists=a:Store().lists;assert(preferences:Import(profile));assert(a:Store().lists==lists)
print('PASS: searchable auction-settings controls use scoped refresh; RUI profiles carry presentation/behaviour preferences without moving character trading data')

-- Exercise the actual inspected native mode switch against the integrated shell.
do
 local previousRoot=AuctionHouseFrame
 assert(load(NATIVE_AUCTION_DISPLAY))()
 AuctionHouseFrameDialogs={};AuctionHouseFramePopups={};PanelTemplates_SetTab=function()end
 local root=frame(UIParent);AuctionHouseFrame=root
 root.tabsForDisplayMode={};root.SetDisplayMode=AuctionHouseFrameMixin.SetDisplayMode
 function root:GetDisplayMode()return self.displayMode end
 function root:UpdateTitle()end
 for _,mode in pairs(AuctionHouseFrameDisplayMode)do for _,key in ipairs(mode)do root[key]=root[key]or frame(root)end end
 function root:GetCategoriesList()return self.CategoriesList end
 function root.CategoriesList:IsWoWTokenCategorySelected()return false end
 for _,key in ipairs({'ItemSellFrame','CommoditiesSellFrame','WoWTokenSellFrame'})do root[key].GetItem=function(self)return self.item end end
 for index,key in ipairs({'BuyTab','SellTab','AuctionsTab'})do
  local tab=frame(root);root[key]=tab
  local mode=index==1 and AuctionHouseFrameDisplayMode.Buy or index==2 and AuctionHouseFrameDisplayMode.ItemSell or AuctionHouseFrameDisplayMode.Auctions
  tab.scripts.OnClick=function()root:SetDisplayMode(mode)end
 end
 local stored={elements={}}
 AUI.modules.LayoutEditor={Store=function()return stored end,Capture=function(_,window)return {x=157,y=-83,scale=window:GetScale(),width=window:GetWidth(),height=window:GetHeight()}end}
 a.open=true;root:SetDisplayMode(AuctionHouseFrameDisplayMode.Buy)
 assert(load(AUCTIONHOUSEUI_SOURCE))('ProjectRuthless',AUI);ui=AUI.modules.AuctionHouseUI
 ui:Attach();assert(not ui.frame:IsShown()and ui.frame:GetParent()==root)
 local nativeClick=root.BuyTab.scripts.OnClick
 ui.bottomTabs.settings.scripts.OnClick();assert(ui.settings:IsShown()and not ui.frame:IsShown()and not root.SearchBar:IsShown())
 local before=ProjectRuthlessDB.auctionHouse.retainHistory
 ui.settings.controls[2].button.scripts.OnClick();assert(ProjectRuthlessDB.auctionHouse.retainHistory==not before)
 ui.bottomTabs.tools.scripts.OnClick();assert(ui.frame:IsShown()and not ui.settings:IsShown())
 root.BuyTab.scripts.OnClick();assert(root.SearchBar:IsShown()and not ui.frame:IsShown()and root.BuyTab.scripts.OnClick==nativeClick)
 -- Selected native sale survives switching to Prices; stale/changed items do not.
 root.ItemSellFrame.item={id=731};root.SellTab.scripts.OnClick();ui:SetMode('prices')
 assert(not root.ItemSellFrame:IsShown()and a:SaleFrame()==root.ItemSellFrame)
 root.ItemSellFrame.item={id=999};assert(not a:SaleFrame())
 -- Drag actual handlers, then simulate native panel manager reanchoring.
 ui.dragHandle.scripts.OnDragStart();assert(root.moving)
 ui.dragHandle.scripts.OnDragStop();assert(not root.moving and stored.elements.auctionHouse.x==157)
 root:SetPoint('TOPLEFT',UIParent,'TOPLEFT',20,-20);flush()
 assert(root.point[1]=='CENTER'and root.point[4]==157 and root.point[5]==-83)
 busy=true;ui.dragHandle.scripts.OnDragStart();assert(not root.moving);busy=false
 root:Hide();assert(not ui.frame:IsShown()and not ui.settings:IsShown())
 root:Show();flush();assert(root.point[4]==157)
 a.open=false;AuctionHouseFrame=previousRoot;AUI.modules.LayoutEditor=nil
end
print('PASS: integrated bottom tabs execute native display lifecycle, preserve native click handlers, persist whole-window dragging and keep settings inline')

-- One native full-market request, batched indexing and entirely local searches.
do
 local m=AUI.modules.AuctionMarket;m:OnPlayerLogin()
 local replicateCalls,infoCalls=0,0
 C_AuctionHouse.ReplicateItems=function()replicateCalls=replicateCalls+1 end
 local rows={}
 for i=1,2001 do rows[i]={name=i%2==0 and 'Silk Cloth'or 'Linen Cloth',id=i%2==0 and 4306 or 2589,count=10,buyout=i%2==0 and 2000 or 1000}end
 rows[2002]={name='Bid only',id=123,count=1,buyout=0}
 C_AuctionHouse.GetNumReplicateItems=function()return #rows end
 C_AuctionHouse.GetReplicateItemInfo=function(index)
  infoCalls=infoCalls+1;local r=rows[index+1]
  return r.name,1,r.count,1,true,1,'',0,0,r.buyout,0,nil,nil,nil,nil,0,r.id,true
 end
 a.open=true;AuctionHouseFrame.shown=true
 assert(m:Request()and replicateCalls==1);assert(not m:Request()and replicateCalls==1)
 m.events.scripts.OnEvent(nil,'REPLICATE_ITEM_LIST_UPDATE')
 assert(infoCalls==1000 and m.job and m.job.index==1000,'scan work must yield after at most 1000 rows')
 flush();assert(infoCalls==2002 and not m.job)
 local snapshot=m:Snapshot();assert(snapshot.unique==3 and snapshot.read==2002 and not snapshot.partial)
 assert(snapshot.items[2589].price==100 and snapshot.items[4306].price==200 and snapshot.items[123].price==nil)
 local calls=backendCalls;local hits=m:Rows('silk');assert(#hits==1 and hits[1].id==4306)
 for _=1,100 do assert(m:Rows('silk')==hits)end
 assert(backendCalls==calls and infoCalls==2002 and replicateCalls==1)
 m.sort="price";local sorted=m:Rows('');assert(sorted[1].id==2589 and sorted[#sorted].id==123)
 m.sort="quantity";sorted=m:Rows('');assert(sorted[1].id==2589)
 m.sort=nil
 assert(not m:Request()and replicateCalls==1,'local cooldown avoids repeated full scans')
 -- No response preserves the old cache and makes the failure visible.
 now=now+901;assert(m:Request());now=now+46;flush()
 assert(not m.job and m:Snapshot()==snapshot and m:Status():find('No full%-market response'))
 now=now+61;assert(m:Request());m.events.scripts.OnEvent(nil,'AUCTION_HOUSE_CLOSED')
 assert(not m.job and m:Snapshot()==snapshot)
 -- A replacement remains atomic until indexing finishes; invalid rows are labelled.
 now=now+61;rows[2]={name='Bad',id=secret,count=1,buyout=1}
 assert(m:Request());m:Receive();assert(m:Snapshot()==snapshot)
 flush();assert(m:Snapshot().partial and m:Snapshot().skipped==1)
 a.open=false;assert(not m:Request());a.open=true
 m.nextRequest=nil;busy=true;assert(not m:Request());busy=false
 assert(replicateCalls==4)
 -- Under load, the 2ms budget yields before the 1000-row ceiling.
 local profileClock=0;local readInfo=C_AuctionHouse.GetReplicateItemInfo
 debugprofilestop=function()return profileClock end
 C_AuctionHouse.GetReplicateItemInfo=function(...)profileClock=profileClock+.03;return readInfo(...)end
 now=now+901;m.nextRequest=nil;assert(m:Request());m:Receive()
 assert(m.job and m.job.index==100)
 flush();assert(not m.job)
 debugprofilestop=nil
end
print('PASS: full-market scan uses one native replication request, yields bounded batches, caches local price search and preserves prior data on timeout/cancel with partial-data disclosure')
