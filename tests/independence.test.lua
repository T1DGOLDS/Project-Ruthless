local AUI={modules={},isForever=true,name='ProjectRuthless',version='test'}
function AUI:RegisterModule(name,module)self.modules[name]=module end
local timers,tickers,created={}, {},0
C_Timer={After=function(_,fn)timers[#timers+1]=fn end,NewTicker=function(_,fn)local t={fn=fn};function t:Cancel()self.cancelled=true end;tickers[#tickers+1]=t;return t end}
local function flush()local q=timers;timers={};for _,fn in ipairs(q)do fn()end end
local function frame()
 local f={shown=true,w=200,h=200,scripts={}}
 function f:GetWidth()return self.w end;function f:GetHeight()return self.h end
 function f:IsShown()return self.shown end;f.IsVisible=f.IsShown
 function f:Show()self.shown=true end;function f:Hide()self.shown=false end
 function f:HookScript(event,fn)self.scripts[event]=fn end
 function f:SetScript(event,fn)self.scripts[event]=fn end
 function f:ClearAllPoints()end;function f:SetPoint(...)self.point={...}end
 function f:SetParent(parent)self.parent=parent end;function f:SetAllPoints()end
 function f:SetAlpha(alpha)self.alpha=alpha end;function f:EnableMouse()end
 function f:SetFrameLevel()end;function f:GetFrameLevel()return 5 end
 function f:SetBackdrop()end;function f:SetBackdropBorderColor()end
 function f:CreateTexture()created=created+1;return frame()end
 function f:RegisterEvent()end;function f:UnregisterAllEvents()end
 return f
end
function CreateFrame()created=created+1;return frame()end
function hooksecurefunc(owner,method,callback)owner.hooks=owner.hooks or {};owner.hooks[method]=callback end
local busy=false;function InCombatLockdown()return busy end
local deferred
function AUI:AfterCombat(_,fn)if busy then deferred=fn else fn()end end
function AUI:StyleSurface()end;function AUI:PaintBackground()end
local SECRET={};function issecretvalue(v)return v==SECRET end
local map=1
WorldMapFrame=frame();Minimap=frame();local canvas=frame()
function WorldMapFrame:GetCanvas()return canvas end;function WorldMapFrame:GetMapID()return map end
function WorldMapFrame:SetMapID(id)map=id end
local function vector(x,y)return {GetXY=function()return x,y end}end
CreateVector2D=vector
local projections=0;local radius=100
C_Map={GetBestMapForUnit=function()return 1 end,GetPlayerMapPosition=function()return vector(.5,.5)end,GetMapWorldSize=function()return 1000,1000 end,
 GetWorldPosFromMapPos=function(id,pos)projections=projections+1;return id==3 and 20 or 10,pos end,
 GetMapPosFromWorldPos=function(_,pos,target)return target,pos end,
 GetMapInfo=function(id)return {mapID=id,name='Test zone',parentMapID=id==1 and 9 or 0}end,
 GetMapChildrenInfo=function()return {{mapID=1,name='Test zone',mapType=3},{mapID=2,name='The Deadmines',mapType=4}}end}
C_Minimap={GetViewRadius=function()return radius end}
C_CVar={GetCVarBool=function()return false end}
function GetMinimapShape()return 'ROUND'end
function GetPlayerFacing()return 0 end
assert(load(PINS_SOURCE))('ProjectRuthless',AUI)
local pins=AUI.modules.MapPins
local owner={};local icons={}
for i=1,100 do local icon=frame();icons[i]=icon;pins:AddWorldMapIconMap(owner,icon,1,.2,.3)end
assert(#timers==1 and #tickers==0);flush();assert(icons[1].point[4]==40 and icons[1].point[5]==-60)
map=2;pins:DrawWorld();local first=projections;pins:DrawWorld();assert(projections==first and first==101)
map=3;pins:DrawWorld();assert(not icons[1].shown);map=2
pins:RemoveAllWorldMapIcons(owner);assert(next(pins.world)==nil)
local near,far,edge=frame(),frame(),frame()
pins:AddMinimapIconMap(owner,near,1,.51,.5,true,false)
pins:AddMinimapIconMap(owner,far,1,.9,.5,true,false)
pins:AddMinimapIconMap(owner,edge,1,.9,.5,true,true)
assert(#tickers==1);pins:DrawMini();assert(near.shown and not far.shown and edge.shown)
assert(math.abs(near.point[4]-10)<.001 and math.abs(edge.point[4]-90)<.001)
C_CVar.GetCVarBool=function()return true end;GetPlayerFacing=function()return math.pi/2 end
pins:DrawMini();assert(math.abs(near.point[4])<.001 and math.abs(near.point[5]+10)<.001)
C_CVar.GetCVarBool=function()return false end
radius=SECRET;pins:DrawMini();assert(not near.shown and not edge.shown)
radius=100;Minimap:Hide();Minimap.scripts.OnHide();assert(tickers[1].cancelled)
Minimap:Show();Minimap.scripts.OnShow();assert(#tickers==2)
pins:RemoveAllMinimapIcons(owner);assert(tickers[2].cancelled and next(pins.mini)==nil)
assert(not near.scripts.OnClick)
print('PASS: 100 world registrations coalesce; cross-map transforms cache; minimap range/edge/secret/visibility cleanup; no external pin library')
local poisoned=setmetatable({},{__index=function()error('External addon was accessed')end})
LibQuestieDB=poisoned;LibStub=function()error('External library was accessed')end;Details=poisoned;_detalhes=poisoned
ProjectRuthlessDB={questWorkspace={enabled=true},mapQuests={showLocalStories=true}};ProjectRuthlessCharDB={}
function UnitLevel()return 10 end;function UnitFactionGroup()return 'Alliance'end
local held,completed={},{}
C_QuestLog={IsOnQuest=function(id)return held[id]==true end,IsQuestFlaggedCompleted=function(id)return completed[id]==true end,
 GetNextWaypoint=function(id)if id==1 then return 1,.4,.6 end end}
local offers={{questID=2,questName='Native pickup',inProgress=false,isHidden=false,isLocalStory=false,isAccountCompleted=false,startMapID=1,x=.7,y=.8},
 {questID=3,questName='Hidden',inProgress=false,isHidden=true},
 {questID=SECRET,questName='Restricted',inProgress=false,isHidden=false}}
local requests=0;C_QuestLine={GetAvailableQuestLines=function()return offers end,RequestQuestLinesForMap=function()requests=requests+1 end}
AUI.modules.AuthoredGuides={facts={['1']={title='Route quest',min=5,level=8},['2']={title='Native pickup',min=5,level=8},['4']={title='Horde quest',min=5,level=8}}}
function AUI.modules.AuthoredGuides:Catalog()return {{area=12,name='Test zone',faction='Alliance',hubs={{quests={1,2}}}},{area=13,name='Horde zone',faction='Horde',hubs={{quests={4}}}}}end
AUI.CreateQuestProgression=function()return {{kind='dungeon',areaID=1581,name='The Deadmines',faction='Alliance',nodes={{id=5,title='Dungeon quest',minLevel=5,requires={1},dungeon=true}}}}end
assert(load(DATA_SOURCE))('ProjectRuthless',AUI)
local data=AUI.modules.QuestData;local db=data:GetDatabase()
assert(db.owned and data.mapping[12]==1 and data:MapForArea(1581,'The Deadmines')==2)
assert(data:Status(1).status=='uncertain'and data:Status(4).status=='locked')
assert(data:Status(5).status=='locked');completed[1]=true;assert(data:Status(5).status=='uncertain');completed[1]=nil
local rows=data:Offers();assert(#rows==1 and data:Status(2).status=='available')
local onQuest=C_QuestLog.IsOnQuest;C_QuestLog.IsOnQuest=function()return SECRET end
assert(data:Status(2).status=='uncertain');C_QuestLog.IsOnQuest=onQuest
local before=requests;data:Offers();assert(requests==before)
held[2]=true;assert(data:Status(2).status=='locked');held[2]=nil
local points=data:Points({{id=1,title='Route quest'}},1)
assert(#points==2 and points[1].current and points[1].kind=='Native')
offers={};data:Offers();assert(data:Status(2).status=='uncertain')
assert(#data:Points({{id=99,title='Unknown'}},99)==0)
assert(load(LOCATIONS_SOURCE))('ProjectRuthless',AUI)
local locations=AUI.modules.QuestLocations
assert(locations:Database()==db and locations:PlayerStatus(1,db).status=='uncertain')
assert(#locations:Build({{id=1,title='Route quest'}},1)==1)
function AUI:QueueRefresh()end;locations.Refresh=function()end
db.Quest.GetAllIds=function()error('Native offers must not scan the catalog')end
locations:ScanOffers();assert(#locations.offers==0)
offers={ {questID=2,questName='Native pickup',inProgress=false,isHidden=false,isAccountCompleted=false,startMapID=1,x=.7,y=.8} }
locations:ScanOffers();assert(#locations.offers==1)
local same=locations.offers;local revision=locations.availabilityRevision;locations:ScanOffers();assert(locations.offers==same and locations.availabilityRevision==revision)
busy=true;offers={};locations:ScanOffers();assert(locations.scanPending and locations.offers==same);busy=false
print('PASS: owned quest provider ignores poisoned external addons; known route facts/seed prerequisites/native offers/waypoints; unknown coverage explicit; no full-catalog scans')
local attaches=0
AUI.modules.LayoutEditor={Attach=function(_,id,label,window,resize,options)assert(options.skipNativeSettings);attaches=attaches+1 end}
local enabled=false
C_DamageMeter={IsDamageMeterAvailable=function()return true end,GetCombatSession=function()error('RUI must not inspect combat records')end}
C_CVar.GetCVarBool=function()return enabled end
Settings={GetSetting=function(name)assert(name=='damageMeterEnabled');return {SetValue=function(_,v)enabled=v end}end}
DamageMeterSessionWindow1=frame();DamageMeterSessionWindow1.Header=frame();DamageMeterSessionWindow1.MinimizeContainer={Background=frame()}
DamageMeter={SetupSessionWindow=function()error('RUI must not invoke native setup')end}
assert(load(METERS_SOURCE))('ProjectRuthless',AUI)
local meters=AUI.modules.ForeverMeters;meters:OnPlayerLogin();local assetCount=created
meters:ApplySettings();assert(created==assetCount and attaches==2 and DamageMeterSessionWindow1.Header.alpha==0)
assert(meters:SetEnabled(true)and enabled)
busy=true;assert(not meters:SetEnabled(false)and enabled);meters:ApplySettings();assert(deferred);busy=false;deferred();assert(created==assetCount)
assert(DamageMeter.hooks.SetupSessionWindow)
for i=1,100 do DamageMeter.hooks.SetupSessionWindow()end;assert(#timers==1);flush();assert(created==assetCount)
print('PASS: native meter static presentation reuses assets, native activation/movers defer combat, setup observations batch without RUI combat-data calls')
assert(load(DIAGNOSTICS_SOURCE))('ProjectRuthless',AUI)
local diagnostics=AUI.modules.Diagnostics;local clock=0;function debugprofilestop()clock=clock+2;return clock end
assert(diagnostics:BeginWork()==nil)
diagnostics.session={work={}}
local start=diagnostics:BeginWork();diagnostics:EndWork('markers',start,100)
start=diagnostics:BeginWork();diagnostics:EndWork('markers',start,40)
local measured=diagnostics.session.work.markers
assert(measured.count==2 and measured.totalMS==4 and measured.maxMS==2 and measured.units==140)
diagnostics:EndWork('restricted',SECRET,100);assert(not diagnostics.session.work.restricted)
for i=1,40 do diagnostics:EndWork('operation'..i,0,1)end
local count=0;for _ in pairs(diagnostics.session.work)do count=count+1 end;assert(count==32)
print('PASS: opt-in operation measurements retain bounded call/time/record aggregates and omit missing/restricted clocks')
