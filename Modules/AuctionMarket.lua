local _,AUI=...
local M={serial=0}
AUI:RegisterModule("AuctionMarket",M)
local function public(v)return not(issecretvalue and issecretvalue(v))end
local function numeric(v)return public(v)and type(v)=="number"and v==v and v>=0 and v<1e14 end
local function read(fn,...)
 if type(fn)~="function"then return end
 local ok,v=pcall(fn,...);if ok and public(v)then return v end
end
function M:Snapshot()return AUI.modules.AuctionHouse:Market().fullSnapshot end
function M:Status()
 if self.job then
  return self.job.phase=="waiting"and "Waiting for Blizzard's full-market snapshot…"or ("Indexing %d / %d listings…"):format(self.job.index,self.job.total)
 end
 local snapshot=self:Snapshot()
 if self.message then return self.message..(snapshot and " Previous snapshot remains available."or "")end
 if snapshot then return ("%s · %d listings · %d items · %d min old. Includes your listings; variants share an item-ID price."):format(snapshot.partial and "Partial snapshot"or "Market snapshot",snapshot.read,snapshot.unique,math.max(0,math.floor((time()-snapshot.time)/60)))end
 return self.message or "No full-market snapshot. Visit an auctioneer and choose Scan market."
end
function M:Notify()
 local ui=AUI.modules.AuctionHouseUI
 if ui and ui.frame and ui.frame:IsVisible()and AUI.modules.AuctionHouse.mode=="market"then ui.frame.message:SetText(self:Status())end
end
function M:Request()
 local a=AUI.modules.AuctionHouse;local ok,why=a:Ready();if not ok then return false,why end
 if InCombatLockdown()then return false,"Start a market scan outside combat. Cached prices remain available."end
 if self.job then return false,self:Status()end
 if type(C_AuctionHouse.ReplicateItems)~="function"or type(C_AuctionHouse.GetReplicateItemInfo)~="function"then return false,"This client does not expose the full-market snapshot API. Normal native searches remain available."end
 local wait=(self.nextRequest or 0)-time()
 if wait>0 then return false,("Scan available in %d seconds. Search the cached snapshot meanwhile."):format(wait)end
 self.serial=self.serial+1
 local job={token=self.serial,phase="waiting",started=time(),scope=a:MarketKey()};self.job=job
 self.nextRequest=time()+60
 local sent,problem=pcall(C_AuctionHouse.ReplicateItems)
 if not sent then self.job=nil;self.message="Blizzard declined the market scan; previous prices are retained.";return false,self.message end
 C_Timer.After(45,function()
  if self.job==job and job.phase=="waiting"and time()-job.started>=45 then
   self.job=nil;self.message="No full-market response from Blizzard. Cached prices were retained; try again when the server permits."
   self:Notify()
  end
 end)
 self:Notify();return true,self:Status()
end
function M:Receive()
 local job=self.job;if not job or job.phase~="waiting"then return end
 if job.scope~=AUI.modules.AuctionHouse:MarketKey()then self:Cancel();return end
 local total=read(C_AuctionHouse.GetNumReplicateItems)
 if not numeric(total)then self.job=nil;self.message="Market response unavailable; previous prices retained.";self:Notify();return end
 job.phase="indexing";job.total=math.min(total,250000);job.partial=total>job.total
 job.index=0;job.items={};job.unique=0;job.skipped=0;job.scope=AUI.modules.AuctionHouse:MarketKey()
 self:Step(job)
end
function M:Step(job)
 if self.job~=job then return end
 local a=AUI.modules.AuctionHouse
 if not a.open or a:MarketKey()~=job.scope then self:Cancel();return end
 local diagnostics=AUI.modules.Diagnostics;local started=diagnostics and diagnostics:BeginWork()
 local before=job.index;local clock=read(debugprofilestop);if not numeric(clock)then clock=nil end
 local limit=math.min(job.total,job.index+1000);local stop=before
 for index=before,limit-1 do
  local ok,name,icon,count,quality,usable,level,levelType,minBid,minIncrement,buyout,bid,highBidder,bidderName,owner,ownerName,sale,itemID,complete=pcall(C_AuctionHouse.GetReplicateItemInfo,index)
  if ok and numeric(itemID)and itemID>0 and numeric(count)and count>0 and numeric(buyout)and numeric(sale)and sale==0 then
   if not public(complete)or complete~=true or not public(name)or type(name)~="string"or name==""then job.partial=true end
   local row=job.items[itemID]
   if not row and job.unique<30000 then
    local title=public(name)and type(name)=="string"and name~=""and name or ("Item #"..itemID)
    row={id=itemID,name=title,query=title:lower(),quantity=0,listings=0};job.items[itemID]=row;job.unique=job.unique+1
   end
   if row then
    row.quantity=row.quantity+count;row.listings=row.listings+1
    if buyout>0 then local unit=buyout/count;row.price=row.price and math.min(row.price,unit)or unit end
   else job.partial=true end
  else job.skipped=job.skipped+1 end
  stop=index+1
  if clock and (stop-before)%100==0 then
   local elapsed=read(debugprofilestop)
   if numeric(elapsed)and elapsed-clock>=2 then break end
  end
 end
 job.index=stop
 if started then diagnostics:EndWork("AuctionMarket.Index",started,stop-before)end
 self:Notify()
 if stop<job.total then C_Timer.After(0,function()self:Step(job)end);return end
 local snapshot={time=time(),items=job.items,read=job.total,unique=job.unique,skipped=job.skipped,partial=job.partial or job.skipped>0}
 a:Market().fullSnapshot=snapshot
 self.job=nil;self.nextRequest=time()+900;self.message=nil;self.cache=nil
 a:QueueRefresh();self:Notify()
end
function M:Cancel()
 if not self.job then return end
 self.job=nil;self.serial=self.serial+1;self.message="Scan stopped. Previous market prices were retained.";self:Notify()
end
function M:Clear()
 self:Cancel();AUI.modules.AuctionHouse:Market().fullSnapshot=nil;self.cache=nil;self.message="Cached market prices cleared.";AUI.modules.AuctionHouse:QueueRefresh()
end
function M:Rows(query)
 query=(query or ""):lower();local snapshot=self:Snapshot()
 if self.cache and self.cache.snapshot==snapshot and self.cache.query==query and self.cache.sort==self.sort then return self.cache.rows end
 local rows={}
 for id,row in pairs(snapshot and snapshot.items or {})do
  if query==""or row.query:find(query,1,true)or tostring(id)==query then rows[#rows+1]=row end
 end
 table.sort(rows,function(x,y)
  if self.sort=="price"and x.price~=y.price then return (x.price or math.huge)<(y.price or math.huge)end
  if self.sort=="quantity"and x.quantity~=y.quantity then return x.quantity>y.quantity end
  if x.name==y.name then return x.id<y.id end;return x.name<y.name
 end)
 self.cache={snapshot=snapshot,query=query,sort=self.sort,rows=rows};return rows
end
function M:OnPlayerLogin()
 local events=CreateFrame("Frame");self.events=events
 events:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE");events:RegisterEvent("AUCTION_HOUSE_CLOSED")
 events:SetScript("OnEvent",function(_,event)if event=="REPLICATE_ITEM_LIST_UPDATE"then self:Receive()else self:Cancel()end end)
end
