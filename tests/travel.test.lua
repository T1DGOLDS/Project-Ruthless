local AUI={isForever=true,modules={}}
function AUI:RegisterModule(k,v)self.modules[k]=v end
ProjectRuthlessDB={mapQuests={}}
function issecretvalue(v)return v=="SECRET"end
local dead=false
function UnitIsDeadOrGhost()return dead end
local function vec(x,y)return {GetXY=function()return x,y end}end
assert(load(DATA))('RUI',AUI);assert(load(HEALERS))('RUI',AUI);assert(load(FLIGHTS))('RUI',AUI);assert(load(MINIMAP))('RUI',AUI)
local H=AUI.modules.SpiritHealers
local base=H:Locations(1436);assert(#base>0)
C_DeathInfo={GetGraveyardsForMap=function()return {{position=vec(base[1].x,base[1].y),name='Native graveyard'}}end,GetDeathReleasePosition=function()return vec(.1,.2)end}
assert(#H:Locations(1436)==#base,'deduplicate native vs recorded locations')
dead=true;local live=H:Locations(1436);assert(#live==#base+1 and live[#live].release)
C_DeathInfo.GetGraveyardsForMap=function()error('not available')end
C_DeathInfo.GetDeathReleasePosition=function()return 'SECRET'end
assert(#H:Locations(1436)==#base,'restricted APIs must retain safe static locations')
ProjectRuthlessDB.mapQuests.showSpiritHealers=false;assert(#H:Locations(1436)==0);ProjectRuthlessDB.mapQuests.showSpiritHealers=true
-- Verify the geometry by independently classifying a physical-space grid.
local points={{x=.15,y=.2},{x=.75,y=.2},{x=.4,y=.8}}
local function inside(poly,x,y)
 for i,v in ipairs(poly)do local n=poly[i==#poly and 1 or i+1];if (n[1]-v[1])*(y-v[2])-(n[2]-v[2])*(x-v[1])< -1e-9 then return false end end
 return true
end
for i,p in ipairs(points)do local poly=H:Region(points,i,3,1)
 for _,v in ipairs(poly)do assert(v[1]>=-1e-9 and v[1]<=1+1e-9 and v[2]>=-1e-9 and v[2]<=1+1e-9)end
 for x=.01,.99,.07 do for y=.01,.99,.07 do
  if inside(poly,x,y)then local own=((x-p.x)*3)^2+(y-p.y)^2
   for _,other in ipairs(points)do assert(own<=((x-other.x)*3)^2+(y-other.y)^2+1e-8)end
  end
 end end
end
print('PASS: healer facts, native/static deduplication, ghost destination, restricted API fallback, clipped physical-distance regions')
local acquired,removed,providers={},0,0
function CreateFromMixins(...)local result={};for i=1,select('#',...)do for k,v in pairs(select(i,...))do result[k]=v end end;return result end
WorldMapFrame={GetMapID=function()return 1436 end,IsShown=function()return true end,
 RemoveAllPinsByTemplate=function(_,template)assert(template=='RUISpiritHealerPinTemplate');removed=removed+1 end,
 AcquirePin=function(_,template,p)assert(template=='RUISpiritHealerPinTemplate');acquired[#acquired+1]=p end,
 AddDataProvider=function(self,p)p.owningMap=self;providers=providers+1 end}
MapCanvasDataProviderMixin={GetMap=function(self)return self.owningMap end};MapCanvasPinMixin={SetPosition=function()end}
H:Install();H:Install();H.provider:RefreshAllData();assert(providers==1 and removed==1 and #acquired==#base)
ProjectRuthlessDB.mapQuests.showSpiritHealers=false;acquired={};H:ApplySettings();assert(#acquired==0 and removed==2)
ProjectRuthlessDB.mapQuests.showSpiritHealers=true
assert(RUISpiritHealerPinMixin.OnClick==nil and RUISpiritHealerPinMixin.SetPosition)
print('PASS: idempotent native map provider, disabled cleanup isolates RUI pins, passive healer markers')

local now,taxi,atDest=0,false,true
function GetTime()return now end;function GetServerTime()return 1000+now end
function UnitOnTaxi()return taxi end;function UnitFactionGroup()return 'Alliance'end
function GetBuildInfo()return '1.60.1','70000' end
local F=AUI.modules.FlightTimer
local function widget()return setmetatable({shown=false},{__index=function(t,k)
 if k=='Show'then return function()t.shown=true end elseif k=='Hide'then return function()t.shown=false end
 elseif k=='SetText'then return function(_,v)t.text=v end elseif k=='SetShown'then return function(_,v)t.shown=v end else return function()end end
end})end
F.frame=widget();F.driver=widget();F.label=widget();F.time=widget();F.detail=widget();F.progress=widget()
local origin={id=2,name='Origin',map=1,x=.1,y=.2};local dest={id=4,name='Destination',map=1,x=.5,y=.5}
local key=F:Key(origin,dest,'2>4','unknown-perk')
local reference=F:Expected({origin=origin,destination=dest,key=key,factor=1});assert(reference and reference>0)
C_Map={GetPlayerMapPosition=function()return atDest and vec(.5,.5)or vec(.1,.1)end,GetMapWorldSize=function()return 10000,10000 end}
F.pending={origin=origin,destination=dest,key=key,factor=1,perk='unknown-perk',selected=now};F.driver:Show()
F:Tick();assert(not F.frame.shown and F.driver.shown)
taxi=true;now=1;F:Tick();assert(F.frame.shown and F.detail.text=='Estimate'and F.time.text:find('~',1,true))
now=35;F:Tick();taxi=false;F:Tick();assert(not F.driver.shown and ProjectRuthlessDB.flightTimes[key].seconds==34)
local duration,source=F:Expected({origin=origin,destination=dest,key=key,factor=1});assert(duration==34 and source=='Measured')
-- Cancelled boarding and interrupted trips must never replace a valid sample.
F.pending={selected=now};now=50;F:Tick();assert(not F.driver.shown)
F.pending={origin=origin,destination=dest,key=key,factor=1,perk='unknown-perk',selected=now};taxi=true;F:Tick();now=65;taxi=false;atDest=false;F:Tick();assert(ProjectRuthlessDB.flightTimes[key].seconds==34)
-- Reloading mid-air has no full-trip start: display elapsed only, never learn it.
taxi=true;F:Tick();assert(F.flight.partial and F.detail.text:find('Since reload',1,true));now=80;taxi=false;atDest=true;F:Tick();assert(ProjectRuthlessDB.flightTimes[key].seconds==34)
-- A restricted state is not a landing, and disabling discards partial samples.
taxi=true;F.pending={origin=origin,destination=dest,key=key,factor=1,perk='unknown-perk',selected=now};F:Tick();taxi='SECRET';now=90;F:Tick();assert(F.flight)
ProjectRuthlessDB.mapQuests.flightTimer=false;F:ApplySettings();assert(not F.flight and not F.driver.shown and ProjectRuthlessDB.flightTimes[key].seconds==34)
ProjectRuthlessDB.mapQuests.flightTimer=true
assert(key~=F:Key(origin,dest,'2>3>4','unknown-perk')and key~=F:Key(origin,dest,'2>4','fast'))
-- Actual destination identifiers are captured from the native taxi map.
function GetTaxiMapID()return 1 end;function NumTaxiNodes()return 2 end
C_TaxiMap={GetAllTaxiNodes=function()return {{slotIndex=1,nodeID=2,position=vec(.1,.2)},{slotIndex=2,nodeID=4,position=vec(.5,.5)}}end}
function TaxiNodeName(i)return i==1 and 'Origin'or 'Destination'end
function TaxiNodeGetType(i)return i==1 and 'CURRENT'or 'REACHABLE'end
F:Snapshot();assert(F.origin.id==2 and F.slots[2].id==4 and F.slots[2].y==.5)
function GetNumRoutes()return 1 end
taxi=false;F:Selected(2);assert(F.pending.destination.id==4 and F.pending.key==key)
function GetNumRoutes()return nil end
F:Selected(2);assert(F.pending and not F.pending.key,'unavailable hop evidence must not teach an exact route')
print('PASS: taxi boarding/cancel, reference vs measured ETA, validated landing, route/perk keys, interrupted/reloaded/restricted-state handling and no idle driver')

local M=AUI.modules.ForeverMinimap;local combat=false
function InCombatLockdown()return combat end
Minimap=widget();Minimap.GetMaskTexture=function()return 'round-mask'end;Minimap.SetMaskTexture=function(_,v)Minimap.mask=v end
MinimapCompassTexture=widget();MinimapCompassTextureUnderlay=widget()
MinimapCompassTexture.SetAlpha=function(_,v)MinimapCompassTexture.alpha=v end
MinimapCompassTextureUnderlay.SetAlpha=function(_,v)MinimapCompassTextureUnderlay.alpha=v end
MinimapCluster={};M.border=widget()
local rings={}
for _,name in ipairs({'SetArchBlobRingScalar','SetArchBlobRingAlpha','SetQuestBlobRingScalar','SetQuestBlobRingAlpha','SetTaskBlobRingScalar','SetTaskBlobRingAlpha'})do Minimap[name]=function(_,value)rings[name]=value end end
M:ApplySettings();assert(M:IsSquare()and Minimap.mask:find('WHITE8X8',1,true)and M.border.shown and MinimapCompassTexture.alpha==0)
assert(rings.SetQuestBlobRingAlpha==0 and rings.SetTaskBlobRingScalar==0 and rings.SetArchBlobRingAlpha==0)
Minimap.mask='native-reset';M:ApplySettings();assert(Minimap.mask~='native-reset')
ProjectRuthlessDB.mapQuests.squareMinimap=false;M:ApplySettings();assert(Minimap.mask=='round-mask'and not M.border.shown and MinimapCompassTexture.alpha==0)
AUI.modules.ForeverStyle={BlizzardArtEnabled=function()return true end};M:ApplySettings();assert(MinimapCompassTexture.alpha==1)
combat=true;ProjectRuthlessDB.mapQuests.squareMinimap=true;M:ApplySettings();assert(M.pending and Minimap.mask=='round-mask')
combat=false;M:ApplySettings();assert(M:IsSquare()and M.border.shown and not M.pending)
M.originalMask=nil;Minimap.GetMaskTexture=nil;ProjectRuthlessDB.mapQuests.squareMinimap=false
M:ApplySettings();assert(Minimap.mask=='ui-hud-minimap-frame-generic-mask','Forever has no required mask getter')
print('PASS: square/round mask, thin border, native-reset recovery, art preference and combat deferral')

assert(load(REPAIR))('RUI',AUI);local R=AUI.modules.RepairReminder
R.frame=widget();R.frame.IsShown=function()return R.frame.shown end;R.title=widget();R.detail=widget()
ProjectRuthlessDB.general={repairThreshold=30}
local current,restricted=40,false
function GetInventoryItemDurability(slot)if restricted then return 'SECRET',100 end;if slot==1 then return current,100 elseif slot==5 then return 90,100 end end
local messages,sounds=0,0
function AUI:Print()messages=messages+1 end
UIErrorsFrame={AddMessage=function()end};SOUNDKIT={IG_MAINMENU_OPTION_CHECKBOX_ON=1};function PlaySound()sounds=sounds+1 end
DurabilityFrame={alpha=1,GetAlpha=function(self)return self.alpha end,SetAlpha=function(self,v)self.alpha=v end}
R:Refresh();assert(not R.frame.shown and messages==0 and DurabilityFrame.alpha==0)
current=29;R:Refresh();assert(R.frame.shown and R.title.text:find('29%%')and messages==1)
R:Refresh();assert(messages==1 and sounds==0)
current=0;R:Refresh();assert(messages==2 and R.title.text:find('broken',1,true));R:Refresh();assert(messages==2)
restricted=true;R:Refresh();assert(R.frame.shown and R.detail.text:find('unavailable',1,true)and messages==2)
restricted=false;current=100;R:Refresh();assert(not R.frame.shown)
ProjectRuthlessDB.general.repairSound=true;current=20;R:Refresh();assert(messages==3 and sounds==1)
ProjectRuthlessDB.general.repairIndicator=false;R:Refresh();assert(not R.frame.shown and DurabilityFrame.alpha==1)
print('PASS: lowest equipped durability, threshold/broken alerts, no repeated reminders, secret fallback, repair reset, sound opt-in and native indicator restoration')
