local _,AUI=...
local P={revision=0}
AUI:RegisterModule("Professions",P)
local function public(v)return not(issecretvalue and issecretvalue(v))end
local function num(v)return public(v)and type(v)=="number"and v==v and v>=0 and v<1e12 end
local function read(fn,...)
 if type(fn)~="function"then return end
 local ok,a,b,c,d,e,f,g,h,i,j,k,l,m,n=pcall(fn,...)
 if ok and public(a)and public(b)and public(c)and public(d)and public(e)and public(f)and public(g)and public(h)and public(i)and public(j)and public(k)and public(l)and public(m)and public(n)then return a,b,c,d,e,f,g,h,i,j,k,l,m,n end
end
local function copy(t)local r={};for k,v in pairs(t or {})do r[k]=type(v)=="table"and copy(v)or v end;return r end
function P:Data()
 if not self.data then self.data=AUI:LoadProfessionFacts()end
 return self.data
end
function P:Store()
 local s=ProjectRuthlessCharDB.professions
 if not s then s={observations={},prices={},plans={},skillOverrides={}};ProjectRuthlessCharDB.professions=s end
 return s
end
function P:MarketKey()
 local a=AUI.modules.AuctionHouse;return a and a:MarketKey()or "unavailable"
end
function P:PriceSettings()
 local s=self:Store();local scope=self:MarketKey()
 s.prices[scope]=s.prices[scope]or {items={}}
 -- At most the same four realm/faction scopes as auction history.
 local n=0;for _ in pairs(s.prices)do n=n+1 end
 if n>4 then for key in pairs(s.prices)do if key~=scope then s.prices[key]=nil;break end end end
 return s.prices[scope]
end
function P:SetPrice(id,value)
 if not num(id)or id<1 or(value~=nil and not num(value))then return false end
 local items=self:PriceSettings().items;local n=0;for _ in pairs(items)do n=n+1 end
 if value~=nil and items[id]==nil and n>=1000 then return false,"Remove a manual price first (1,000 maximum)."end
 items[id]=value;self.revision=self.revision+1;return true
end
function P:SetFee(value)
 if value~=nil and(not num(value)or value>100)then return false end
 self:PriceSettings().fee=value;return true
end
function P:Skills()
 local result={}
 if GetProfessions and GetProfessionInfo then
  local indices={read(GetProfessions)}
  for _,index in pairs(indices)do
   if num(index)then
    local name,icon,rank,max,_,_,skillID=read(GetProfessionInfo,index)
    if num(skillID)and num(rank)and num(max)then result[skillID]={name=name,icon=icon,rank=rank,max=max,index=index}end
   end
  end
 end
 return result
end
function P:Skill(id)
 local skill=self:Skills()[id];if skill then return skill.rank,skill.max,true end
 local v=self:Store().skillOverrides[id];return num(v)and v or 1,300,false
end
function P:ItemName(id)
 local fact=self:Data().items[id]
 return read(C_Item and C_Item.GetItemNameByID,id)or fact and fact.name or ("Item #"..id)
end
function P:Owned(id)
 -- Bank quantities use the client's last available bank cache, not an assertion
 -- that every bank/character is currently loaded.
 local count=read(C_Item and C_Item.GetItemCount or GetItemCount,id,true,false,true)
 return num(count)and count or 0
end
function P:Price(id)
 local manual=self:PriceSettings().items[id]
 if num(manual)then return manual,{source="manual",time=time(),manual=true}end
 local a=AUI.modules.AuctionHouse
 if not a then return nil,{source="No auction data"}end
 local best
 for _,q in pairs(a.quotes or {})do
  if q.key and q.key.itemID==id and num(q.minimum)and num(q.time)and(not best or q.time>best.time)then best=q end
 end
 if best then return best.minimum,{source="auction search",time=best.time,partial=not best.complete,quantity=best.quantity,variant=not best.commodity}end
 local market=a:Market();local newest
 for _,q in pairs(market.items or {})do
  local last=q.samples and q.samples[#q.samples]
  if q.key and q.key.itemID==id and last and num(last.last)and num(q.time)and(not newest or q.time>newest.time)then newest=q end
 end
 if newest then return newest.samples[#newest.samples].last,{source="saved search",time=newest.time,partial=newest.partial,variant=true}end
 local snapshot=market.fullSnapshot;local row=snapshot and snapshot.items and snapshot.items[id]
 if row and num(row.price)then return row.price,{source="market scan (all variants, includes own listings)",time=snapshot.time,partial=snapshot.partial,quantity=row.quantity,variant=true}end
 return nil,{source="No auction price"}
end
function P:PurchasePrice(id,allowVendor)
 local value,meta=self:Price(id)
 -- Public library buy prices are a labelled vendor alternative, never a claim
 -- of current stock, discounts, or access. Currency-only offers are not money.
 local fact=self:Data().items[id]
 if allowVendor and fact and num(fact.vendorBuy)and fact.vendorBuy>0 and(not value or fact.vendorBuy<value)then
  return fact.vendorBuy,{source="published vendor price; check stock",vendor=true,time=0}
 end
 return value,meta
end
function P:Recipes(id)
 self.catalogs=self.catalogs or {}
 local cached=self.catalogs[id]
 if cached and cached.revision==self.revision then return cached.rows end
 local rows,byID={},{}
 local prof=self:Data().professions[id]
 for _,fact in ipairs(prof and prof.recipes or {})do local r=copy(fact);rows[#rows+1]=r;byID[r.id]=r end
 local ownedProfession=self:Skills()[id]~=nil
 for rid,observed in pairs(self:Store().observations[id]or {})do
  local r=byID[rid]
  if not r then r={id=rid,name=observed.name};rows[#rows+1]=r;byID[rid]=r end
  for k,v in pairs(observed)do r[k]=type(v)=="table"and copy(v)or v end
  if not ownedProfession then r.learned=nil end
 end
 table.sort(rows,function(a,b)local x,y=a.skill or 9999,b.skill or 9999;return x==y and a.name<b.name or x<y end)
 self.catalogs[id]={rows=rows,revision=self.revision};return rows
end
function P:KnownRecipe(r)
 return r and r.learned==true
end
function P:RecipeForItem(id,visited)
 if not self.outputIndex or self.outputRevision~=self.revision then
  self.outputIndex={};self.outputRevision=self.revision
  for prof in pairs(self:Data().professions)do for _,r in ipairs(self:Recipes(prof))do
   if r.output and r.learned and r.materials and r.yield and r.yield>0 then
    self.outputIndex[r.output]=self.outputIndex[r.output]or {};table.insert(self.outputIndex[r.output],r)
   end
  end end
 end
 return self.outputIndex[id]or {}
end
function P:Materials(recipe,crafts,options,seen,depth)
 options=options or {};seen=seen or {};depth=depth or 0
 if depth>12 or seen[recipe.id]then return nil,"Circular or overly deep material recipe."end
 if not recipe.materials or recipe.materialsIncomplete then return nil,"Open this recipe in native crafting to verify its materials."end
 seen[recipe.id]=true
 local value,missing,warnings,shopping=0,{}, {},{}
 for _,m in ipairs(recipe.materials)do
  local qty=m.quantity*crafts;local price,meta=self:PurchasePrice(m.id,options.vendor)
  local buyPrice=price;local usedRecipe
  if options.intermediates then
   for _,sub in ipairs(self:RecipeForItem(m.id))do
    if not seen[sub.id]and sub.yield==sub.yieldMax and not sub.cooldown then
     local cost=self:Materials(sub,math.ceil(qty/sub.yield),options,seen,depth+1)
     if cost and cost.total and(not price or cost.total<price*qty)then
      price=cost.total/qty;meta={source="craft "..sub.name,time=time()};usedRecipe=cost
      for warning in pairs(cost.warnings)do warnings[warning]=true end
     end
    end
   end
  end
  if price==nil then missing[#missing+1]=self:ItemName(m.id)
  else value=value+qty*price end
  local need=math.max(0,qty-self:Owned(m.id))
  shopping[#shopping+1]={id=m.id,quantity=qty,need=need,price=price,buyPrice=buyPrice,meta=meta,craft=usedRecipe}
  if meta.partial then warnings["Partial price data"]=true end
  if meta.variant then warnings["Item variants / own listings may affect the estimate"]=true end
  if meta.time and meta.time>0 and time()-meta.time>86400 then warnings["Prices older than 24 hours"]=true end
  if meta.quantity and meta.quantity<need then warnings["Observed supply is below the required quantity"]=true end
  if meta.vendor then warnings["Vendor alternative assumes stock and access"]=true end
 end
 seen[recipe.id]=nil
 local cash=0;local cashKnown=true
 for _,m in ipairs(shopping)do if m.need>0 then if m.buyPrice then cash=cash+m.need*m.buyPrice else cashKnown=false end end end
 return {total=#missing==0 and value or nil,cash=cashKnown and cash or nil,missing=missing,warnings=warnings,shopping=shopping}
end
function P:Tradable(id)
 local name,_,_,_,_,_,_,_,_,_,_,_,_,bind=read(C_Item and C_Item.GetItemInfo or GetItemInfo,id)
 if not name then return nil end
 if not num(bind)then return nil end
 return bind==0 or bind==2 or bind==3
end
function P:Estimate(recipe,crafts,options)
 local result,why=self:Materials(recipe,crafts,options)
 if not result then return {reason=why}end
 result.yield=recipe.yield;result.unlock=recipe.source;result.output=recipe.output
 if not recipe.output then result.reason="Enchant / service: set a service value separately; there is no auction item.";return result end
 if not num(recipe.yield)or recipe.yield<1 then result.reason="Output quantity unverified. Open this recipe in native crafting.";return result end
 if recipe.yieldMax and recipe.yieldMax~=recipe.yield then result.warnings["Variable output: uses the minimum yield"]=true end
 local trade=self:Tradable(recipe.output)
 if trade~=true then result.reason=trade==false and "Bound / non-tradeable output: no auction margin."or "Output binding unverified. Load its item tooltip first.";return result end
 local sale,meta=self:Price(recipe.output);result.salePrice=sale;result.saleMeta=meta
 if meta.partial then result.warnings["Partial output price"]=true end
 if meta.variant then result.warnings["Output price may be for another item variant"]=true end
 if meta.time and time()-meta.time>86400 then result.warnings["Output price older than 24 hours"]=true end
 if not sale then result.reason="No saved auction price for the output.";return result end
 result.gross=sale*recipe.yield*crafts
 local fee=self:PriceSettings().fee
 if fee==nil then result.reason="Set the auction sale fee below to calculate a net listing margin.";return result end
 result.net=result.gross*(1-fee/100)
 if result.total then result.margin=result.net-result.total end
 if #result.missing>0 then result.reason="Missing material prices: "..table.concat(result.missing,", ")end
 return result
end
function P:AddPlan(recipe,crafts)
 if not num(crafts)or crafts<1 or crafts>9999 or crafts%1~=0 then return false,"Enter 1–9,999 whole crafts."end
 local plans=self:Store().plans;local count=0;for _ in pairs(plans)do count=count+1 end
 if not plans[recipe.id]and count>=100 then return false,"Remove a plan first (100 maximum)."end
 plans[recipe.id]={recipe=copy(recipe),crafts=crafts};return true,"Added to this character's crafting plan."
end
function P:Shopping()
 local byID,gaps={},{}
 for _,plan in pairs(self:Store().plans)do
  if not plan.recipe.materials or plan.recipe.materialsIncomplete then gaps[#gaps+1]=plan.recipe.name
  else for _,m in ipairs(plan.recipe.materials)do byID[m.id]=(byID[m.id]or 0)+m.quantity*plan.crafts end end
 end
 local rows={};for id,qty in pairs(byID)do rows[#rows+1]={id=id,name=self:ItemName(id),quantity=qty,need=math.max(0,qty-self:Owned(id))}end
 table.sort(rows,function(a,b)return a.name<b.name end);return rows,gaps
end
function P:ExportShopping()
 local a=AUI.modules.AuctionHouse;if not a then return false,"Auction tools unavailable."end
 local rows,gaps=self:Shopping();if #gaps>0 then return false,"Unverified materials: "..table.concat(gaps,", ")end
 if #rows>100 then return false,"Split this plan into smaller shopping lists (100 materials maximum)."end
 local ok,why=a:NewList("Profession materials");if not ok then return ok,why end
 -- Replace our generated list, never append stale requirements to it.
 a:Store().lists["Profession materials"]={}
 for _,m in ipairs(rows)do a:AddToList("Profession materials",{itemID=m.id,term=m.name,quantity=m.quantity})end
 return true,"Auction shopping list updated. Owned materials are deducted there."
end
function P:ObserveRecipe(id,profession)
 local api=C_TradeSkillUI
 local info=read(api and api.GetRecipeInfo,id)
 if not info or not public(info.name)or type(info.name)~="string"or not public(info.learned)then return end
 local r={id=id,name=info.name,learned=info.learned==true,observed=time()}
 local source=read(api.GetRecipeSourceText,id)
 if public(source)and type(source)=="string"and #source>0 and #source<2000 then
  r.source=source;r.sourceOrigin="native crafting"
  if source:find("Vendor",1,true)then r.sourceKind="Vendor"end
 end
 local cooldown=read(api.GetRecipeCooldown,id)
 if num(cooldown)then r.cooldown=cooldown>0 end
 local requirements=read(api.GetRecipeRequirements,id)
 if type(requirements)=="table"then
  r.requirements={}
  for i,requirement in ipairs(requirements)do
   if i>30 then break end
   if public(requirement.name)and type(requirement.name)=="string"and public(requirement.met)then
    r.requirements[#r.requirements+1]={name=requirement.name,met=requirement.met==true}
   end
  end
 end
 if num(info.icon)then r.icon=info.icon end
 local schematic=read(api.GetRecipeSchematic,id,false)
 if schematic and public(schematic.reagentSlotSchematics)then
  r.materials={};r.materialsIncomplete=false
  for _,slot in ipairs(schematic.reagentSlotSchematics or {})do
   if not public(slot.required)then r.materialsIncomplete=true
   elseif slot.required then
    local reagents=public(slot.reagents)and slot.reagents or {}
    if #reagents~=1 or not num(reagents[1].itemID)or not num(slot.quantityRequired)then r.materialsIncomplete=true
    elseif slot.quantityRequired>0 then r.materials[#r.materials+1]={id=reagents[1].itemID,quantity=slot.quantityRequired}end
   end
  end
  if num(schematic.quantityMin)and schematic.quantityMin>0 then r.yield=schematic.quantityMin end
  if num(schematic.quantityMax)then r.yieldMax=schematic.quantityMax end
  if num(schematic.outputItemID)then r.output=schematic.outputItemID end
 end
 local output=read(api.GetRecipeOutputItemData,id)
 if output and num(output.itemID)then r.output=output.itemID end
 if public(info.supportsQualities)and info.supportsQualities then r.materialsIncomplete=true end
 local s=self:Store();s.observations[profession]=s.observations[profession]or {};local cache=s.observations[profession]
 if not r.source and cache[id]then r.source=cache[id].source;r.sourceOrigin=cache[id].sourceOrigin end
 if cache[id]==nil then local n=0;for _ in pairs(cache)do n=n+1 end;if n>=1500 then return end end
 cache[id]=r;self.revision=self.revision+1
end
function P:CurrentNativeProfession()
 local api=C_TradeSkillUI;if not api then return end
 if read(api.IsTradeSkillLinked)==true or read(api.IsTradeSkillGuild)==true or read(api.IsNPCCrafting)==true then return end
 local info=read(api.GetBaseProfessionInfo)or read(api.GetChildProfessionInfo)
 if not info or not num(info.professionID)then return end
 local id=info.professionID;if not self:Data().professions[id]then return end
 -- Only record learned state for a profession owned by this character.
 if not self:Skills()[id]then return end
 return id
end
function P:Observe()
 if InCombatLockdown()or not self.nativeOpen then self.pendingObserve=self.nativeOpen;return end
 local id=self:CurrentNativeProfession();if not id then return end
 local ids,seen={},{}
 for _,r in ipairs(self:Data().professions[id].recipes)do ids[#ids+1]=r.id;seen[r.id]=true end
 for _,rid in ipairs(read(C_TradeSkillUI.GetFilteredRecipeIDs)or {})do if num(rid)and not seen[rid]and #ids<2000 then ids[#ids+1]=rid;seen[rid]=true end end
 self.job={profession=id,ids=ids,index=1};self:ObserveBatch()
end
function P:ObserveBatch()
 local job=self.job;if not job then return end
 if not self.nativeOpen or InCombatLockdown()or self:CurrentNativeProfession()~=job.profession then self.job=nil;self.pendingObserve=self.nativeOpen;return end
 local start=read(debugprofilestop)
 for _=1,20 do
  local id=job.ids[job.index];if not id then self.job=nil;if self.RefreshVisible then self:RefreshVisible()end;return end
  self:ObserveRecipe(id,job.profession);job.index=job.index+1
  if start and(read(debugprofilestop)or start)-start>=2 then break end
 end
 C_Timer.After(0,function()if self.job==job then self:ObserveBatch()end end)
end
function P:QueueObserve()
 if self.observeQueued then return end;self.observeQueued=true
 C_Timer.After(.2,function()self.observeQueued=nil;self:Observe()end)
end
function P:OnPlayerLogin()
 if self.InstallEntryPoints then self:InstallEntryPoints()end
 local frame=CreateFrame("Frame");self.events=frame
 for _,e in ipairs({"TRADE_SKILL_SHOW","TRADE_SKILL_CLOSE","TRADE_SKILL_LIST_UPDATE","TRADE_SKILL_DATA_SOURCE_CHANGED","PLAYER_REGEN_ENABLED","SKILL_LINES_CHANGED","BAG_UPDATE_DELAYED","GET_ITEM_INFO_RECEIVED","ITEM_SEARCH_RESULTS_UPDATED","COMMODITY_SEARCH_RESULTS_UPDATED","ADDON_LOADED"})do frame:RegisterEvent(e)end
 frame:SetScript("OnEvent",function(_,event,addon)
  if event=="ADDON_LOADED"then
   if addon=="Blizzard_ProfessionsBook"or addon=="Blizzard_Professions"or addon=="Blizzard_MicroMenu"then self:InstallEntryPoints()end
   return
  elseif event=="TRADE_SKILL_SHOW"then self.nativeOpen=true;self:QueueObserve()
  elseif event=="TRADE_SKILL_CLOSE"then self.nativeOpen=nil;self.job=nil
  elseif event=="PLAYER_REGEN_ENABLED"then if self.pendingObserve then self.pendingObserve=nil;self:QueueObserve()end
  elseif event=="TRADE_SKILL_LIST_UPDATE"or event=="TRADE_SKILL_DATA_SOURCE_CHANGED"then if self.nativeOpen then self:QueueObserve()end
  else
   if event=="SKILL_LINES_CHANGED"then self.revision=self.revision+1 end
   if not self.panel or not self.panel:IsVisible()then return end
   if not self.refreshQueued then self.refreshQueued=true;C_Timer.After(.2,function()self.refreshQueued=nil;if self.RefreshVisible then self:RefreshVisible()end end)end
  end
 end)
end
