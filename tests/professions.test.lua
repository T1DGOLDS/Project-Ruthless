local A={modules={},isForever=true};function A:RegisterModule(k,v)self.modules[k]=v end
local timers,frames={},{};local combat=false;local clock=100000;local owned={};local binds={};local unlearned=false
function time()return clock end
function InCombatLockdown()return combat end
function issecretvalue(v)return type(v)=="table"and v.secret==true end
function GetProfessions()if not unlearned then return 1,2,nil,3,4,5 end end
function GetProfessionInfo(index)
 local ids={197,333,356,185,129};local names={"Tailoring","Enchanting","Fishing","Cooking","First Aid"}
 return names[index],1,100,300,1,0,ids[index]
end
C_Item={GetItemCount=function(id)return owned[id]or 0 end,GetItemNameByID=function(id)return 'Item '..id end,
 GetItemInfo=function(id)if binds[id]==nil then return end;return 'Item '..id,nil,1,1,1,'Type','Sub',1,'',1,1,7,9,binds[id]end,
 RequestLoadItemDataByID=function()end}
C_Timer={After=function(_,fn)timers[#timers+1]=fn end}
local function drain()local count=0;while #timers>0 do count=count+1;assert(count<1000);table.remove(timers,1)()end end
local market={items={},fullSnapshot={time=clock,items={}}}
A.modules.AuctionHouse={quotes={},MarketKey=function()return 'realm:Alliance'end,Market=function()return market end}
local ah=A.modules.AuctionHouse
ProjectRuthlessDB={};ProjectRuthlessCharDB={}
assert(load(DATA))('RUI',A);assert(load(MODEL))('RUI',A);local P=A.modules.Professions
assert(P.data==nil and ProjectRuthlessCharDB.professions==nil,'No catalog allocation on module load')
local facts=P:Data();assert(facts.professions[129]and facts.professions[356]and facts.professions[197])
assert(P:Skill(129)==100,'First Aid in sixth return must not be lost')
-- Exact math: output quantities, material opportunity cost, bank stock and sale fee.
local r={id=90001,name='Fixture',output=3,yield=2,yieldMax=2,materials={{id=1,quantity=4},{id=2,quantity=1}}}
P:SetPrice(1,100);P:SetPrice(2,50);P:SetPrice(3,400);binds[3]=2;owned[1]=5
local e=P:Estimate(r,3);assert(e.margin==nil and e.reason:find('sale fee'))
P:SetFee(5);e=P:Estimate(r,3);assert(e.total==1350 and e.cash==850 and e.gross==2400 and e.net==2280 and e.margin==930)
P:SetPrice(2,nil);e=P:Estimate(r,3);assert(e.total==nil and e.margin==nil and #e.missing==1,'Unknown input must never become zero cost')
owned[2]=3;e=P:Estimate(r,3);assert(e.cash==700 and e.total==nil,'Owned stock avoids extra cash but does not invent value')
P:SetPrice(2,50);binds[3]=1;e=P:Estimate(r,1);assert(e.margin==nil and e.reason:find('non%-tradeable'))
binds[3]=nil;assert(P:Estimate(r,1).reason:find('binding unverified'));binds[3]=2
local service={id=90002,name='Enchant',materials={{id=1,quantity=1}}};assert(P:Estimate(service,1).reason:find('service'))
local noYield={id=90003,name='Unverified',output=3,materials={}};assert(P:Estimate(noYield,1).reason:find('quantity unverified'))
-- Source thresholds are never substituted for recipe unlocks, and public quotes
-- from another realm, Wowhead averages or absent native inventory are not used.
assert(P:Price(979797)==nil);assert(P:SetFee(101)==false);assert(P:SetPrice(1,-1)==false)
P:SetPrice(1,nil);ah.quotes.a={key={itemID=1},minimum=13,quantity=2,time=clock-90000,complete=false,commodity=true}
local price,meta=P:Price(1);assert(price==13 and meta.partial)
e=P:Estimate(r,3);assert(e.warnings['Prices older than 24 hours']and e.warnings['Observed supply is below the required quantity'])
ah.quotes={};market.items.x={key={itemID=1},time=clock,samples={{last=17}}};assert(P:Price(1)==17,'Saved quote history uses the last observed sample')
market.items={};market.fullSnapshot.items[1]={price=19,quantity=2};price,meta=P:Price(1);assert(price==19 and meta.variant)
P:SetPrice(1,0);assert(P:Price(1)==0,'An explicit manual zero is allowed; an absent price is not zero')
local oldKey=ah.MarketKey;ah.MarketKey=function()return 'another:Alliance'end;assert(P:PriceSettings().items[1]==nil);ah.MarketKey=oldKey
-- Learned intermediate craft/buy comparison, excess batch yield, missing data,
-- recursion protection and warning propagation.
P:SetPrice(1,100);P:SetPrice(7,10);local sub={id=90004,name='Sub',output=1,yield=3,yieldMax=3,learned=true,materials={{id=7,quantity=2}}}
P:Store().observations[197]={[90004]=sub};P.revision=P.revision+1
e=P:Estimate(r,1,{intermediates=true});assert(e.total==90 and e.cash==0,'Two batches cost 40, direct reagent costs 50; direct cash retains owned stock')
sub.materials={{id=1,quantity=1}};P.revision=P.revision+1
local cycle,why=P:Materials(sub,1,{}, {[90004]=true});assert(cycle==nil and why:find('Circular'))
P:Store().observations[197]={};P.revision=P.revision+1
-- Plans aggregate before deducting inventory. Re-export replaces only our list.
assert(P:AddPlan(r,2));assert(not P:AddPlan(r,0));assert(not P:AddPlan(r,1.5))
local r2={id=90005,name='Other',materials={{id=1,quantity=3}}};P:AddPlan(r2,1)
local rows=P:Shopping();local m;for _,v in ipairs(rows)do if v.id==1 then m=v end end;assert(m.quantity==11 and m.need==6)
local lists={Keep={{term='untouched'}}};ah.Store=function()return {lists=lists}end;ah.NewList=function(_,name)lists[name]=lists[name]or {};return true end
ah.AddToList=function(_,name,entry)lists[name][#lists[name]+1]=entry end
assert(P:ExportShopping());assert(#lists.Keep==1 and #lists['Profession materials']==2);assert(P:ExportShopping());assert(#lists['Profession materials']==2)
-- Bounded native recording only while this character's crafting is open,
-- with restricted values and ambiguous reagent choices contained.
local calls=0;local nativeID=197
C_TradeSkillUI={GetBaseProfessionInfo=function()return {professionID=nativeID}end,
 GetRecipeInfo=function(id)calls=calls+1;return {name='Observed '..id,learned=true,icon=1}end,
 GetRecipeSchematic=function()return {quantityMin=2,quantityMax=2,outputItemID=3,reagentSlotSchematics={{required=true,quantityRequired=4,reagents={{itemID=1}}}}}end,
 GetRecipeOutputItemData=function()return {itemID=3}end,GetFilteredRecipeIDs=function()return {90009}end}
P:Observe();assert(calls==0);P.nativeOpen=true;combat=true;P:Observe();assert(calls==0 and P.pendingObserve)
combat=false;P:Observe();assert(calls<=20 and P.job);P.nativeOpen=nil;drain();assert(not P.job)
P.nativeOpen=true;P:ObserveRecipe(90009,197);assert(P:Store().observations[197][90009].yield==2)
C_TradeSkillUI.GetRecipeSchematic=function()return {quantityMin=1,quantityMax=1,reagentSlotSchematics={{required=true,quantityRequired=4,reagents={{itemID=1},{itemID=2}}}}}end
P:ObserveRecipe(90010,197);assert(P:Store().observations[197][90010].materialsIncomplete)
C_TradeSkillUI.GetRecipeInfo=function()return {name='secret',learned={secret=true}}end
P:ObserveRecipe(90011,197);assert(P:Store().observations[197][90011]==nil)
nativeID=164;assert(P:CurrentNativeProfession()==nil,'Do not record someone else\'s profession learned state')
-- Lazy, reusable integrated UI with every profession and view, pagination,
-- native combat guard, manual estimates and shopping controls exercised.
local W={};W.__index=W
function W:SetSize(w,h)self.width=w;self.height=h end
function W:SetWidth(w)self.width=w end
function W:SetHeight(h)self.height=h end
function W:GetWidth()return self.width or 664 end
function W:GetHeight()return self.height or 300 end
function W:GetParent()return self.parent end
function W:GetFrameLevel()return 3 end
function W:SetScript(k,v)self.scripts[k]=v end
function W:SetText(v)self.text=tostring(v or '')end
function W:GetText()return self.text or ''end
function W:GetStringHeight()return 300 end
function W:Show()local old=self.shown;self.shown=true;if not old and self.scripts.OnShow then self.scripts.OnShow(self)end end
function W:Hide()local old=self.shown;self.shown=false;if old and self.scripts.OnHide then self.scripts.OnHide(self)end end
function W:IsShown()return self.shown end
function W:IsVisible()return self.shown and(not self.parent or self.parent:IsVisible())end
function W:SetEnabled(v)self.enabled=v end
function W:SetShown(v)self.shown=v end
for _,m in ipairs({'SetPoint','SetAllPoints','ClearAllPoints','SetFrameLevel','SetAutoFocus','SetMaxLetters','SetJustifyH','SetTextColor','SetWordWrap','SetTexture','SetSpacing','SetVerticalScroll','SetScrollChild','SetClipsChildren','ClearFocus','RegisterEvent','SetFrameStrata','SetClampedToScreen','SetMovable','EnableMouse','RegisterForDrag','SetColorTexture','Raise','StartMoving','StopMovingOrSizing'})do W[m]=function()end end
function W:SetScale(v)self.scale=v end
function W:SetAlpha(v)self.alpha=v end
function W:GetEffectiveScale()return self.scale or 1 end
function W:SetPoint(...)self.point={...}end
local function frame(parent)local f=setmetatable({shown=true,scripts={},parent=parent},W);frames[#frames+1]=f;return f end
function W:CreateFontString()return frame(self)end
function W:CreateTexture()return frame(self)end
function CreateFrame(_,name,parent)local f=frame(parent);f.name=name;return f end
function A:CreateButton(parent)local b=frame(parent);b.label=frame(b);return b end
function A:CreateSmoothScrollFrame(parent)return frame(parent)end
function A:StyleSurface()end
function A:AccentColor()return .2,.6,1 end
A.modules.Accessibility={RegisterText=function()end,FitWindow=function(_,_,scale)return scale end}
UIParent=frame();UISpecialFrames={}
local spellbook=frame(UIParent)
A.modules.Spellbook={frame=spellbook,Show=function()error('Professions must never open Spellbook')end}
local positions={elements={}};local attached={}
A.modules.LayoutEditor={Attach=function(_,id,name,f)attached[id]=f end,Capture=function()return {x=18,y=42,scale=1,width=700,height=650}end,Store=function()return positions end,Apply=function(_,id,value)attached[id]:SetPoint('CENTER',UIParent,'CENTER',value.x,value.y)end}
assert(load(UI))('RUI',A);P:Show();assert(P.profession and P.panel:IsVisible())
assert(P.frame.name=='ProjectRuthlessProfessionsFrame'and P.frame.parent==UIParent and P.panel.parent==P.frame)
assert(attached.professions==P.frame and #UISpecialFrames==1 and spellbook:IsShown())
local n=#frames;P:Show();assert(#frames==n,'Reopen must reuse frames')
P.frame:Hide();assert(spellbook:IsShown(),'Closing Professions must not close Spellbook');P:Show()
local oldPlan=P:Store().plans;local oldPrices=P:Store().prices
local originalCalls,hooks=0,0
ToggleProfessionsBook=function()originalCalls=originalCalls+1 end
ProfessionMicroButton={UpdateMicroButton=function()end,SetPushed=function(b)b.pushed=true end,SetNormal=function(b)b.pushed=false end}
hooksecurefunc=function(_,_,callback)hooks=hooks+1;P.microCallback=callback end
P:InstallEntryPoints();P:InstallEntryPoints();assert(hooks==1)
ToggleProfessionsBook();assert(not P.frame:IsShown()and spellbook:IsShown())
positions.elements.professions={x=18,y=42,scale=1,width=700,height=650}
combat=true;ToggleProfessionsBook();assert(P.frame:IsShown()and ProfessionMicroButton.pushed and originalCalls==0)
assert(P.frame.point[4]==18 and P.frame.point[5]==42,'Combat opening must restore the owned window position')
ToggleProfessionsBook();assert(not P.frame:IsShown()and not ProfessionMicroButton.pushed);combat=false;P:Show()
assert(P:Store().plans==oldPlan and P:Store().prices==oldPrices,'Moving the window must preserve character profession data')
P:ToggleProfessions();assert(#P.profChoices==12)
for id in pairs(facts.professions)do
 P:SelectProfession(id)
 for _,view in ipairs({'Recipes','Leveling','Sources','Profit','Shopping'})do P:SelectView(view)end
end
P:SelectProfession(197);P:SelectView('Profit');P:SelectRecipe(r);assert(P.detail:GetText():find('Listing margin'))
combat=true;P:OpenNative();assert(P.status:GetText():find('after combat'));combat=false
local crafts=0;Enum={SpellBookSpellBank={Player=0}}
C_SpellBook={GetSpellBookItemInfo=function()return {name='Tailoring'}end,CastSpellBookItem=function()crafts=crafts+1 end}
P:OpenNative();assert(crafts==1 and not P.frame:IsShown()and spellbook:IsShown(),'Opening crafting closes only Professions')
P:Show()
P:SelectView('Shopping');P:RenderShopping();assert(P.export:IsShown())
print('PASS: profession data, 12-profession UI, accounting, price provenance, binding, inventory, shopping and native/combat boundaries')
