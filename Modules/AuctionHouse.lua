local _, AUI = ...
local A = {quotes={},mode="saved",page=1}
AUI:RegisterModule("AuctionHouse", A)
local function public(v) return not (issecretvalue and issecretvalue(v)) end
local function number(v) return public(v) and type(v)=="number" and v==v and v>=0 and v<1e14 end
local function read(fn,...)
    if type(fn)~="function" then return end
    local ok,v=pcall(fn,...);if ok and public(v) then return v end
end
local function copy(v)
    if type(v)~="table" then return v end
    local result={};for k,x in pairs(v) do result[k]=copy(x) end;return result
end
local function text(v,limit)
    if not public(v) or type(v)~="string" then return end
    v=v:gsub("[%c]",""):match("^%s*(.-)%s*$")
    if #v>0 and #v<=(limit or 100) then return v end
end
function A:Store()
    local s=ProjectRuthlessCharDB.auctionHouse
    if not s then s={saved={},history={},lists={},saleDefaults={},preferences={duration=2,undercut=0}};ProjectRuthlessCharDB.auctionHouse=s end
    return s
end
function A:Ready()
    if not self.open or not AuctionHouseFrame or not AuctionHouseFrame:IsShown() then return false,"Visit an auctioneer to search, buy or sell." end
    if C_AuctionHouse and C_AuctionHouse.IsThrottledMessageSystemReady and not read(C_AuctionHouse.IsThrottledMessageSystemReady) then return false,"The auction house is busy. Try again when it is ready." end
    return true
end
function A:NormalizeQuery(query)
    if type(query)~="table" then return end
    local term=text(query.term)
    if not term then return end
    local min=number(query.minLevel) and math.floor(query.minLevel) or 0
    local max=number(query.maxLevel) and math.floor(query.maxLevel) or 0
    if min>999 or max>999 or max>0 and min>max then return end
    local filters={}
    for key,value in pairs(query.filters or {}) do
        if type(key)=="number" and key>=0 and key<100 and type(value)=="boolean" then filters[key]=value end
    end
    return {term=term,minLevel=min,maxLevel=max,filters=filters}
end
function A:CurrentQuery()
    local frame=AuctionHouseFrame
    local search=frame and frame.SearchBar
    local term=search and search.SearchBox and read(search.SearchBox.GetText,search.SearchBox)
    local filters=g_auctionHouseFilters or {}
    return self:NormalizeQuery({term=term,minLevel=filters.minLevel,maxLevel=filters.maxLevel,filters=filters.filters})
end
function A:QueryID(q)
    local keys={};for key,value in pairs(q.filters) do if value then keys[#keys+1]=key end end;table.sort(keys)
    return q.term:lower()..":"..q.minLevel..":"..q.maxLevel..":"..table.concat(keys,",")
end
function A:RememberQuery(query)
    if (ProjectRuthlessDB.auctionHouse or {}).retainHistory==false then return end
    local q=self:NormalizeQuery(query);if not q then return end
    local s=self:Store();local id=self:QueryID(q)
    for index=#s.history,1,-1 do if self:QueryID(s.history[index])==id then table.remove(s.history,index) end end
    q.time=time();table.insert(s.history,1,q)
    while #s.history>30 do table.remove(s.history) end
    self:QueueRefresh()
end
function A:SaveSearch(query,favourite)
    local q=self:NormalizeQuery(query or self:CurrentQuery());if not q then return false,"Enter a search in the auction house first." end
    local saved=self:Store().saved;local id=self:QueryID(q)
    for _,entry in ipairs(saved) do if self:QueryID(entry)==id then entry.favourite=not entry.favourite;self:QueueRefresh();return true,"Favourite updated." end end
    if #saved>=100 then return false,"Remove a saved search before adding another (100 maximum)." end
    q.favourite=favourite==true;saved[#saved+1]=q;self:QueueRefresh();return true,"Search and filters saved for this character."
end
function A:SetDefault(query)
    local q=self:NormalizeQuery(query or self:CurrentQuery());if not q then return false,"Enter a search before saving its filters." end
    self:Store().default=q;return true,"Default search and filters saved. Opening the auction house restores them without starting a search."
end
function A:ApplyQuery(query,run)
    local q=self:NormalizeQuery(query);if not q then return false,"Invalid search or level range." end
    if run then local ok,why=self:Ready();if not ok then return false,why end end
    local frame=AuctionHouseFrame
    if not self.open or not frame or not frame.SearchBar then return false,"Visit an auctioneer to restore this search." end
    frame:SetDisplayMode(AuctionHouseFrameDisplayMode.Buy)
    if frame.CategoriesList then frame.CategoriesList:SetSelectedCategory(nil) end
    g_auctionHouseFilters=g_auctionHouseFilters or {}
    g_auctionHouseFilters.minLevel=q.minLevel;g_auctionHouseFilters.maxLevel=q.maxLevel;g_auctionHouseFilters.filters=copy(q.filters)
    frame.SearchBar:SetSearchText(q.term)
    if frame.SearchBar.UpdateClearFiltersButton then frame.SearchBar:UpdateClearFiltersButton() end
    if run then frame.SearchBar:StartSearch() end
    return true,run and ("Searching "..q.term) or "Search restored."
end
function A:NewList(name)
    name=text(name,40);if not name then return false,"Use a list name of 1–40 characters." end
    local lists=self:Store().lists;local count=0;for _ in pairs(lists) do count=count+1 end
    if not lists[name] and count>=30 then return false,"Maximum 30 shopping lists." end
    lists[name]=lists[name] or {};self.listName=name;self.page=1;self:QueueRefresh();return true,"Shopping list selected."
end
function A:AddToList(name,entry)
    local list=self:Store().lists[name]
    if not list then return false,"Create or select a shopping list first." end
    local query=text(entry.term or entry.name)
    local qty=tonumber(entry.quantity) or 1;local cap=tonumber(entry.maxPrice) or 0
    if not query or not number(qty) or qty<1 or qty>9999 or qty%1~=0 or not number(cap) or cap>1e12 or cap%1~=0 then return false,"Use a valid search, whole quantity and non-negative price cap." end
    for _,item in ipairs(list) do
        if entry.itemID and item.itemID==entry.itemID or not entry.itemID and not item.itemID and item.term:lower()==query:lower()then
            item.term=query;item.quantity=qty;if entry.maxPrice~=nil then item.maxPrice=cap end;self:QueueRefresh();return true,"Shopping target updated."
        end
    end
    if #list>=100 then return false,"Maximum 100 entries per shopping list." end
    list[#list+1]={term=query,itemID=number(entry.itemID) and entry.itemID or nil,quantity=qty,maxPrice=cap}
    self:QueueRefresh();return true,"Added to shopping list."
end
function A:ListNeed(entry)
    if not entry.itemID then return entry.quantity end
    return math.max(0,entry.quantity-AUI.modules.QuestSupplies:Owned(entry.itemID))
end
function A:ParseMoney(value)
    value=type(value)=="string" and value:lower():gsub("%s","") or ""
    if value:match("^%d+$")then local amount=tonumber(value);if number(amount)and amount<=1e12 then return amount end;return end
    local sum,seen=0,{}
    local remainder=value:gsub("(%d+%.?%d*)([gsc])",function(amount,unit)
        if seen[unit]then return "invalid"end
        seen[unit]=true;sum=sum+tonumber(amount)*({g=10000,s=100,c=1})[unit];return ""
    end)
    if value~="" and remainder=="" and number(sum) and sum<=1e12 then return math.floor(sum+.5)end
end
function A:ExportList(name)
    local list=self:Store().lists[name]
    if not list then return nil,"Select a shopping list first." end
    local lines={"RUI_SHOPPING_1",name}
    for _,entry in ipairs(list)do lines[#lines+1]=table.concat({entry.itemID or 0,entry.quantity,entry.maxPrice or 0,entry.term},"\t")end
    return table.concat(lines,"\n")
end
function A:ImportList(blob)
    if type(blob)~="string" or #blob>20000 then return false,"List text is missing or too large."end
    local lines={};for line in blob:gsub("\r",""):gmatch("[^\n]+")do lines[#lines+1]=line end
    if lines[1]~="RUI_SHOPPING_1" then return false,"Unsupported shopping-list format."end
    local name=text(lines[2],40)
    if not name or self:Store().lists[name] then return false,"Use a new list name on the second line. Existing lists are preserved."end
    local parsed={};local seen={}
    for index=3,#lines do
        local id,quantity,cap,term=lines[index]:match("^(%d+)\t(%d+)\t(%d+)\t(.+)$")
        id,quantity,cap=tonumber(id),tonumber(quantity),tonumber(cap)
        term=text(term)
        if not term or not number(id) or id>1e8 or not number(quantity) or quantity<1 or quantity>9999
            or not number(cap) or cap>1e12 then return false,"Invalid entry on line "..index..". Nothing was imported."end
        local identity=id>0 and tostring(id)or ("query:"..term:lower())
        if seen[identity] then return false,"Duplicate list entry. Nothing was imported."end
        seen[identity]=true;parsed[#parsed+1]={itemID=id>0 and id or nil,quantity=quantity,maxPrice=cap,term=term}
    end
    if #parsed==0 or #parsed>100 then return false,"Use a list with 1–100 entries."end
    local count=0;for _ in pairs(self:Store().lists)do count=count+1 end
    if count>=30 then return false,"Maximum 30 shopping lists."end
    -- Validate the entire data-only document before changing the character store.
    self:Store().lists[name]=parsed;self.listName=name;self.page=1;self:QueueRefresh()
    return true,"Shopping list imported. Review its targets and price caps."
end
function A:SearchNext()
    local list=self:Store().lists[self.listName] or {}
    local start=self.listCursor or 0
    for offset=1,#list do
        local index=(start+offset-1)%#list+1;local entry=list[index]
        if self:ListNeed(entry)>0 then
            local ok,why=self:SearchEntry(entry)
            if ok then self.listCursor=index end
            return ok,why
        end
    end
    return false,"No missing items in the selected list."
end
function A:SearchEntry(entry)
    local ok,why=self:Ready();if not ok then return false,why end
    self.activeShopping=entry
    if entry.itemID and C_AuctionHouse.MakeItemKey then
        local key=C_AuctionHouse.MakeItemKey(entry.itemID)
        if key and read(C_AuctionHouse.GetItemKeyInfo,key) then
            AuctionHouseFrame:SetDisplayMode(AuctionHouseFrameDisplayMode.Buy)
            AuctionHouseFrame:SelectBrowseResult({itemKey=key,minPrice=0})
            self:RememberQuery({term=entry.term or entry.name})
            return true,"Showing listings. Check quantity and total before confirming a purchase."
        end
    end
    return self:ApplyQuery({term=entry.term or entry.name},true)
end
function A:MarketKey()
    return (read(GetRealmName) or "Unknown realm")..":"..(read(UnitFactionGroup,"player") or "Unknown faction")
end
function A:ItemKey(key)
    if not key or not number(key.itemID) or key.itemID==0 then return end
    return table.concat({key.itemID,key.itemLevel or 0,key.itemSuffix or 0,key.battlePetSpeciesID or 0},":")
end
function A:Market()
    ProjectRuthlessDB.auctionMarkets=ProjectRuthlessDB.auctionMarkets or {}
    local markets=ProjectRuthlessDB.auctionMarkets;local key=self:MarketKey()
    if not markets[key] then
        local count,oldest=0
        for k,value in pairs(markets) do count=count+1;if not oldest or value.last<markets[oldest].last then oldest=k end end
        if count>=4 then markets[oldest]=nil end
        markets[key]={last=time(),items={}}
    end
    markets[key].last=time();return markets[key]
end
function A:ObserveResults(key,commodity)
    if not self.open or (ProjectRuthlessDB.auctionHouse or {}).trackPrices==false then return end
    if not key or not number(key.itemID) then return end
    local count=read(commodity and C_AuctionHouse.GetNumCommoditySearchResults or C_AuctionHouse.GetNumItemSearchResults,commodity and key.itemID or key)
    if not number(count) then return end
    local signature=self:ItemKey(key)
    local minimum,competition,quantity
    quantity=0
    for index=1,math.min(500,count) do
        local row=read(commodity and C_AuctionHouse.GetCommoditySearchResultInfo or C_AuctionHouse.GetItemSearchResultInfo,commodity and key.itemID or key,index)
        if row and number(row.quantity) and row.quantity>0 and (commodity or self:ItemKey(row.itemKey)==signature) then
            local price=commodity and row.unitPrice or row.buyoutAmount
            if number(price) and price>0 then
                local unit=commodity and price or price/row.quantity
                minimum=minimum and math.min(minimum,unit) or unit;quantity=quantity+row.quantity
                local owned=row.containsOwnerItem or row.containsAccountItem
                if not owned or commodity and not row.containsAccountItem and number(row.numOwnerItems) and row.quantity>row.numOwnerItems then
                    competition=competition and math.min(competition,unit) or unit
                end
            end
        end
    end
    local full=read(commodity and C_AuctionHouse.HasFullCommoditySearchResults or C_AuctionHouse.HasFullItemSearchResults,commodity and key.itemID or key)==true and count<=500
    local quote={key=copy(key),time=time(),minimum=minimum,competition=competition,quantity=quantity,complete=full,commodity=commodity}
    if not self.quotes[signature]then
        local count,oldest=0
        for id,value in pairs(self.quotes)do count=count+1;if not oldest or value.time<self.quotes[oldest].time then oldest=id end end
        if count>=200 then self.quotes[oldest]=nil end
    end
    self.quotes[signature]=quote;self.lastQuote=quote
    if minimum then
        local market=self:Market();local items=market.items
        if not items[signature] then
            local size,oldest=0
            for id,row in pairs(items) do size=size+1;if not oldest or row.time<items[oldest].time then oldest=id end end
            if size>=500 then items[oldest]=nil end
            items[signature]={key=copy(key),samples={}}
        end
        local record=items[signature];record.time=quote.time;record.partial=not full
        local day=math.floor(quote.time/86400);local last=record.samples[#record.samples]
        if last and last.day==day then last.low=math.min(last.low,minimum);last.last=minimum;last.time=quote.time
        else record.samples[#record.samples+1]={day=day,low=minimum,last=minimum,time=quote.time} end
        while #record.samples>14 do table.remove(record.samples,1) end
        AUI.modules.QuestSupplies:ObserveItem(key.itemID)
    end
    self:QueueRefresh()
end
function A:SaleFrame()
    local root=AuctionHouseFrame;if not root then return end
    for _,sale in ipairs({root.CommoditiesSellFrame,root.ItemSellFrame}) do
        if sale:IsShown() and read(sale.GetItem,sale) then return sale end
    end
    local ui=AUI.modules.AuctionHouseUI
    if ui and ui.activePage=="tools"and self.mode=="prices"and ui.lastSaleFrame
        and root:GetDisplayMode()==ui.toolsDisplayMode and read(ui.lastSaleFrame.GetItem,ui.lastSaleFrame)==ui.lastSaleItem then
        return ui.lastSaleFrame
    end
end
function A:RememberSale()
    local sale=self:SaleFrame();if not sale then return false,"Select an item on the Sell tab first." end
    local key=read(C_AuctionHouse.GetItemKeyFromItem,sale:GetItem())
    if not key or not number(key.itemID) then return false,"Item information is unavailable." end
    local qty=read(sale.GetQuantity,sale);local duration=read(sale.GetDuration,sale)
    if not number(qty) or not number(duration) or duration<1 or duration>3 then return false,"Complete the selling quantity and duration first." end
    local defaults=self:Store().saleDefaults;local count=0
    for _ in pairs(defaults) do count=count+1 end
    if count>=200 and not defaults[key.itemID] then return false,"Maximum 200 saved item selling preferences." end
    defaults[key.itemID]={quantity=qty,duration=duration}
    return true,"Quantity and duration saved for this item. Prices always use a fresh quote."
end
function A:ForgetSale()
    local sale=self:SaleFrame();local item=sale and read(sale.GetItem,sale)
    local key=item and read(C_AuctionHouse.GetItemKeyFromItem,item)
    if not key then return false,"Select an item in Sell first."end
    self:Store().saleDefaults[key.itemID]=nil
    return true,"Saved item quantity/duration removed. New-item defaults remain."
end
function A:ApplySaleDefaults(sale)
    if InCombatLockdown() then return false end
    local item=read(sale.GetItem,sale);local key=item and read(C_AuctionHouse.GetItemKeyFromItem,item)
    local saved=key and self:Store().saleDefaults[key.itemID]
    if not key then return false end
    if not saved then sale.Duration:SetDuration(self:Store().preferences.duration or 2);return true end
    local max=read(sale.GetMaxQuantity,sale)
    if not number(max) or max<1 then return false end
    sale.Duration:SetDuration(saved.duration)
    sale.QuantityInput:SetQuantity(math.min(max,saved.quantity))
    sale:UpdatePostState()
    return true
end
function A:SuggestSale()
    local ready,why=self:Ready();if not ready then return false,why end
    if (ProjectRuthlessDB.auctionHouse or {}).trackPrices==false then return false,"Enable price observations in Auction house settings before filling a quote."end
    local sale=self:SaleFrame();local item=sale and read(sale.GetItem,sale)
    local key=item and read(C_AuctionHouse.GetItemKeyFromItem,item)
    local quote=key and self.quotes[self:ItemKey(key)]
    if not quote or not quote.complete or not quote.competition or time()-quote.time>60 then return false,"Wait for a complete, fresh comparison for this exact item." end
    local discount=tonumber(self:Store().preferences.undercut) or 0
    local unit=math.max(1,math.floor(quote.competition-discount))
    -- Native item selling displays per-item price. This edits fields, never posts.
    sale.PriceInput:SetAmount(unit);sale:UpdatePostState()
    return true,"Price filled from competing listings. Review the deposit and total, then use the native Post button."
end
function A:ShowOwned()
    local ready,why=self:Ready();if not ready then return false,why end
    self.ownedView=true
    if AuctionHouseFrame:GetDisplayMode()==AuctionHouseFrameDisplayMode.Auctions then
        AuctionHouseFrame:QueryAll(AuctionHouseSearchContext.AllAuctions)
    else AuctionHouseFrame:SetDisplayMode(AuctionHouseFrameDisplayMode.Auctions) end
    self:QueueRefresh();return true,"My auctions refreshed. Click an item for its competing listings."
end
function A:QueueResults(key,commodity)
    if (ProjectRuthlessDB.auctionHouse or {}).trackPrices==false then return end
    local signature=self:ItemKey(key);if not signature then return end
    self.pendingResults=self.pendingResults or {};self.pendingResults[signature]={key=copy(key),commodity=commodity}
    if self.resultsQueued then return end
    self.resultsQueued=true
    C_Timer.After(0,function()
        self.resultsQueued=nil;local pending=self.pendingResults;self.pendingResults={}
        if not self.open then return end
        for _,request in pairs(pending)do self:ObserveResults(request.key,request.commodity)end
    end)
end
function A:OwnedRows()
    local result={};local count=read(C_AuctionHouse and C_AuctionHouse.GetNumOwnedAuctions) or 0
    for index=1,math.min(500,count) do
        local row=read(C_AuctionHouse.GetOwnedAuctionInfo,index)
        if row and row.itemKey and number(row.quantity) and row.quantity>0 and number(row.auctionID)and row.auctionID>0
            and not (Enum and Enum.AuctionStatus and row.status==Enum.AuctionStatus.Sold)then
            local quote=self.quotes[self:ItemKey(row.itemKey)]
            local price=number(row.buyoutAmount)and row.buyoutAmount>0 and row.buyoutAmount/row.quantity or nil
            result[#result+1]={auctionID=row.auctionID,key=copy(row.itemKey),price=price,quantity=row.quantity,
                bidOnly=price==nil,competition=quote and quote.competition,fresh=quote and quote.complete and time()-quote.time<=60,
                undercut=price and quote and quote.complete and quote.competition and quote.competition<price and time()-quote.time<=60}
        end
    end
    return result
end
function A:CancelOwned(auctionID)
    local ready,why=self:Ready();if not ready then return false,why end
    -- Revalidate ownership immediately before opening Blizzard's fee/confirmation dialog.
    for _,row in ipairs(self:OwnedRows()) do
        if row.auctionID==auctionID then StaticPopup_Show("CANCEL_AUCTION",nil,nil,{auctionID=auctionID});return true,"Review the native cancellation fee and confirm or cancel." end
    end
    return false,"This auction is no longer in your owned listings. Refresh My auctions."
end
function A:QueueRefresh()
    local ui=AUI.modules.AuctionHouseUI
    if ui then ui:QueueRefresh() end
end
function A:Checks()
    local total,reference,unknown,observed,withheld=AUI.modules.QuestSupplies:Coverage()
    return {{status="INFO",setting="Auction house > Quest supplies",message=("Quest supplies: %d readable records, %d Classic purchase references, %d without reference requirements, %d Forever turn-ins observed, %d encrypted records not read. Reference requirements/eligibility remain unverified."):format(total,reference,unknown,observed,withheld)}}
end
function A:ApplySettings()
    local ui=AUI.modules.AuctionHouseUI
    if ui then
        if self.open then ui:Attach()end
        ui:ApplySettings()
    end
end
function A:QueuePresent()
    if self.presentQueued then return end
    self.presentQueued=true
    C_Timer.After(0,function()
        self.presentQueued=nil
        if not self.open or not AuctionHouseFrame or not AuctionHouseFrame:IsShown()then return end
        local ui=AUI.modules.AuctionHouseUI
        ui:Attach()
        if not self.defaultApplied then
            local default=self:Store().default
            if default then self.defaultApplied=self:ApplyQuery(default,false)else self.defaultApplied=true end
        end
        if not self.openingPageApplied then
            self.openingPageApplied=true
            if (ProjectRuthlessDB.auctionHouse or {}).autoOpen~=false then ui:SelectPage("tools")end
        end
    end)
end
function A:WatchNative()
    local root=AuctionHouseFrame
    if not root or self.watchedNative==root then return end
    self.watchedNative=root
    root:HookScript("OnShow",function()if self.open then self:QueuePresent()end end)
end
function A:OnPlayerLogin()
    ProjectRuthlessDB.auctionHouse=ProjectRuthlessDB.auctionHouse or {}
    for _,key in ipairs({"autoOpen","retainHistory","autoSaleDefaults","trackPrices"})do
        if ProjectRuthlessDB.auctionHouse[key]==nil then ProjectRuthlessDB.auctionHouse[key]=true end
    end
    local events=CreateFrame("Frame");self.events=events
    self:WatchNative()
    for _,event in ipairs({"ADDON_LOADED","AUCTION_HOUSE_SHOW","AUCTION_HOUSE_CLOSED","ITEM_SEARCH_RESULTS_UPDATED","COMMODITY_SEARCH_RESULTS_UPDATED","OWNED_AUCTIONS_UPDATED","BAG_UPDATE_DELAYED"}) do events:RegisterEvent(event) end
    events:SetScript("OnEvent",function(_,event,key)
        if event=="AUCTION_HOUSE_SHOW" then
            self.open=true;self.defaultApplied=nil;self.openingPageApplied=nil;self:WatchNative();self:QueuePresent()
        elseif event=="ADDON_LOADED"then
            if key=="Blizzard_AuctionHouseUI"then self:WatchNative();self:QueuePresent()end
        elseif event=="AUCTION_HOUSE_CLOSED" then self.open=false;self.quotes={};self.lastQuote=nil;self.activeShopping=nil
        elseif event=="ITEM_SEARCH_RESULTS_UPDATED" then self:QueueResults(key,false)
        elseif event=="COMMODITY_SEARCH_RESULTS_UPDATED" then
            if number(key) then self:QueueResults({itemID=key,itemLevel=0,itemSuffix=0,battlePetSpeciesID=0},true) end
        else if event=="BAG_UPDATE_DELAYED"then self.inventoryRevision=(self.inventoryRevision or 0)+1 end;self:QueueRefresh() end
    end)
end
