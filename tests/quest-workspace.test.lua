function hooksecurefunc(obj,key,callback)local old=obj[key];obj[key]=function(...)local result=old(...);callback(...);return result end end
local AUI={modules={}}
math.atan2=math.atan
function AUI:RegisterModule(name,module) self.modules[name]=module end
assert(load('local _, AUI=...\n'..RUNTIME_SOURCE))('ProjectRuthless',AUI)
local secret={}
function issecretvalue(v) return v==secret end
local combat=false
function InCombatLockdown() return combat end
local quests={{isHeader=true},{questID=10,title='Far'},{questID=20,title='Near'},{questID=30,title='Done'}}
C_QuestLog={GetNumQuestLogEntries=function() return #quests end,GetInfo=function(i)return quests[i]end,IsComplete=function(id)return id==30 end,GetDistanceSqToQuest=function(id)return id==20 and 4 or id==30 and 9 or 100 end,GetQuestObjectives=function()return {{text='1/3 collected'}}end,GetTitleForQuestID=function()return 'Near'end,GetNextWaypoint=function()return 1,.6,.5 end}
C_Map={GetBestMapForUnit=function()return 1 end,GetPlayerMapPosition=function()return {GetXY=function()return .5,.5 end}end,GetMapWorldSize=function()return 1000,1000 end}
function GetPlayerFacing()return 0 end
assert(load(QUEST_SOURCE))('ProjectRuthless',AUI)
local q=AUI.modules.QuestWorkspace
local originalRefresh=q.Refresh
local entries=q:Collect(); assert(#entries==3 and entries[1].id==20 and entries[2].complete)
q.selected=10; assert(q:Collect()[1].id==10)
q.skipped[10]=true; assert(#q:Collect()==2)
quests[4]=nil; assert(#q:Collect()==1)
local function label()return {SetText=function(self,text)self.text=text end}end
q.frame={};q.destination=label();q.distance=label();q.arrow={Hide=function(self)self.shown=false end,Show=function(self)self.shown=true end,SetRotation=function(self,r)self.rotation=r end}
q.selected=20;q:Navigate();assert(q.arrow.shown and q.distance.text:find('100 yd',1,true))
combat=true;q:Navigate();assert(q.arrow.shown and q.distance.text:find('100 yd',1,true))
combat=false;C_Map.GetBestMapForUnit=function()return 2 end;q:Navigate();assert(not q.arrow.shown)
C_Map.GetBestMapForUnit=function()return secret end;q:Navigate();assert(not q.arrow.shown)
print('PASS: nearest quest ordering, selected destination, skip, completed/removed quests, navigation distance, combat and secret/cross-map fallbacks')
local tracked=false; local calls={}
C_QuestLog.GetQuestWatchType=function()return tracked and 1 or nil end
C_QuestLog.AddQuestWatch=function(id,kind)calls.add={id,kind};tracked=true end
C_QuestLog.RemoveQuestWatch=function(id)calls.remove=id;tracked=false end
Enum={QuestWatchType={Manual=1}}
q.Refresh=function()end
q:ToggleTracking(20);assert(calls.add[1]==20 and calls.add[2]==1)
q:ToggleTracking(20);assert(calls.remove==20)
C_SuperTrack={SetSuperTrackedQuestID=function(id)calls.selected=id end}
UiMapPoint={CreateFromCoordinates=function(map,x,y)return {map=map,x=x,y=y}end}
C_Map.SetUserWaypoint=function(point)calls.point=point end
q:SetWaypoint(20);assert(calls.selected==20 and calls.point.map==1 and calls.point.x==.6)
local afterCombat=AUI.AfterCombat;local deferredWaypoint
AUI.AfterCombat=function(_,key,fn)assert(key=="questWaypoint");deferredWaypoint=fn end
combat=true;calls={};q:ToggleTracking(20);q:SetWaypoint(20);assert(next(calls)==nil and q.selected==20 and deferredWaypoint)
AUI.AfterCombat=afterCombat
print('PASS: native track/untrack, selected quest and map waypoint APIs, combat write restrictions')
combat=false
function UnitFactionGroup()return 'Alliance'end
C_QuestLog.IsQuestFlaggedCompleted=function()return false end
C_Item={GetItemCount=function(id)return id==1941 and 1 or 0 end}
function GetMerchantNumItems()return 2 end
function GetMerchantItemLink(i)return i==1 and 'item:1939:0' or 'item:1941:0'end
assert(#q:SupplyAdvice(true)==1 and q:SupplyAdvice(true)[1]:find('Sweet Rum'))
assert(#q:SupplyAdvice(false)==4)
C_QuestLog.IsQuestFlaggedCompleted=function()return true end;assert(#q:SupplyAdvice(true)==0)
print('PASS: supply reminders require an offered missing item and stop after quest completion')

local nodes={}
local function node(parent)
    local n={parent=parent,shown=true,scripts={}}
    local methods={SetSize=function(self,w,h)self.width=w;self.height=h end,SetHeight=function(self,h)self.height=h end,SetWidth=function(self,w)self.width=w end,
    SetText=function(self,t)self.text=t end,GetText=function(self)return self.text end,SetTextColor=function(self,r,g,b)self.color={r,g,b}end,
    SetPoint=function(self,...)self.point={...}end,SetScript=function(self,k,v)self.scripts[k]=v end,
    Hide=function(self)self.shown=false end,Show=function(self)self.shown=true end,SetShown=function(self,v)self.shown=v end,IsShown=function(self)return self.shown end,IsVisible=function(self)return self.shown and (not rawget(self,"parent") or self.parent:IsVisible())end,HookScript=function(self,k,fn)local old=self.scripts[k];self.scripts[k]=function(...)if old then old(...)end;fn(...)end end,
    GetFrameLevel=function()return 1 end,GetFontString=function(self)return self.font end}
    methods.CreateFontString=function(self)return node(self)end;methods.CreateTexture=methods.CreateFontString
    setmetatable(n,{__index=function(_,key)return methods[key] or function()end end});nodes[#nodes+1]=n;return n
end
UIParent=node();WorldMapFrame=node()
function CreateFrame(_,_,parent)return node(parent)end
function UnitClass()return 'Warlock','WARLOCK'end
RAID_CLASS_COLORS={WARLOCK={r=.58,g=.51,b=.79}}
ProjectRuthlessDB={questWorkspace={enabled=true,showArrow=true,opacity=.52,locked=false}}
ProjectRuthlessCharDB={}
function AUI:CreateButton(parent)local b=node(parent);b.font=node(b);return b end
C_Timer={After=function()end}
local intervalTimers={}
C_Timer.NewTicker=function(interval,fn)local t={interval=interval,fn=fn};function t:Cancel()self.cancelled=true end;intervalTimers[#intervalTimers+1]=t;return t end
local trackerLayout={elements={quests={x=120,y=-60,scale=.85}}};local trackerAttached=0
AUI.modules.LayoutEditor={Attach=function(_,id,_,frame)if id=="quests"then trackerAttached=trackerAttached+1;frame.savedLayoutApplied=true end end,Capture=function()return {x=200,y=-90,scale=.85}end,Store=function()return trackerLayout end}
q.frame=nil;q:OnPlayerLogin();q.Refresh=originalRefresh;q:Refresh()
assert(trackerAttached==1 and q.frame.savedLayoutApplied)
q.frame.GetPoint=function()return "TOPLEFT",UIParent,"TOPLEFT",200,-90 end
q.frame.scripts.OnDragStop();assert(trackerLayout.elements.quests.x==200 and ProjectRuthlessCharDB.questPanelPosition.x==200)
AUI.modules.LayoutEditor=nil
print('PASS: tracker attaches saved layout during creation without opening editor; direct drag synchronizes the same save')
assert(q.frame.height>200 and q.frame.height<450 and #q.rows==3)
assert(q.currentTitle.color[1]==.96 and q.distance.color[3]==.79)
assert(q.mapPanel.parent==WorldMapFrame and not q.mapPanel:IsShown())
for _,row in ipairs(q.rows)do assert(rawget(row,'track')==nil and rawget(row,'skip')==nil)end
q.mapPage='Tools';q:RenderMapPage();assert(q.mapControls[1]:IsShown() and not q.mapControls[4]:IsShown())
q.mapPage='Settings';q:RenderMapPage();assert(not q.mapControls[1]:IsShown() and q.mapControls[7]:IsShown())
print('PASS: compact class-coloured overlay, separate map-parented tools/settings controls, and no repeated quest action bars')
-- Installed Wisp display: guide selection must replace the nearest active quest.
local function copy(text,size)
    return {GetText=function()return text end,GetFont=function()return 'font',size end,GetObjectType=function()return 'FontString'end}
end
local actionCalls=0
local function guideButton()
    return {IsShown=function()return true end,IsEnabled=function()return true end,GetScript=function()return function()actionCalls=actionCalls+1 end end}
end
local route={heading=copy('Verna Furlbrow'),guide=copy('Westfall Stew'),meta=copy('ACCEPT QUEST'),count=copy('Step 2 / 47'),instruction=copy('Check the broken wagon.'),upNext={IsShown=function()return true end,rows={{IsShown=function()return true end,quest=copy('Accept The Forgotten Heirloom'),npc=copy('Farmer Furlbrow')}}},back=guideButton(),next=guideButton()}
ForeverWispFrame={route=route,IsShown=function()return true end};route.IsShown=function()return true end
local navArrow={GetObjectType=function()return 'Texture'end,GetTexture=function()return 'Interface\\AddOns\\ForeverWisp\\Media\\Arrow.tga'end,IsShown=function()return true end,GetRotation=function()return 1.25 end}
ForeverWispNavigation={IsShown=function()return true end,GetRegions=function()return navArrow,copy('120 yd',22),copy('Via Lakeshire',12) end}
q:Refresh();assert(q.currentTitle.text=='Westfall Stew' and q.summary.text:find('Check the broken wagon'))
assert(q.rows[1].title.text:find('Forgotten Heirloom') and rawget(q.rows[1],'entry')==nil)
assert(q.distance.text=='120 yd' and q.destination.text=='Via Lakeshire' and q.arrow.shown)
q:GuideAction('next');assert(actionCalls==1)
combat=true;q:GuideAction('back');assert(actionCalls==1);combat=false
navArrow.GetRotation=function()return secret end;q:Navigate();assert(not q.arrow.shown)
ProjectRuthlessDB.questWorkspace.useWisp=false;q:Refresh();assert(not q.guide and q.currentTitle.text:find('Near',1,true))
ProjectRuthlessDB.questWorkspace.useWisp=nil
ForeverWispFrame=nil;ForeverWispNavigation=nil
print('PASS: Wisp current guide, up-next, cross-zone travel arrow, explicit step callbacks, combat blocking, secret angle and fallback')

assert(load(LOCATIONS_SOURCE))('ProjectRuthless',AUI)
local locations=AUI.modules.QuestLocations
UnitRace=UnitRace or function()return 'Human','Human',1 end
UnitLevel=UnitLevel or function()return 13 end
C_QuestLog.IsQuestFlaggedCompleted=function()return false end
local records={
 Quest={ [20]={objectives={{{100}},{{200}},{{300}}}}, [30]={finishedBy={{101}}}, [40]={startedBy={{102}}} },
 Npc={ [100]={name='Gnoll',spawns={[12]={{25,50},{25,50},{-1,-1}}}}, [101]={name='Turn-in NPC',spawns={[12]={{10,10}}}}, [102]={name='Verna',spawns={[12]={{20,20}}}} },
 Object={ [200]={name='Tools',spawns={[12]={{40,40}}}}, [201]={name='Chest',spawns={[12]={{50,50}}}} },
 Item={ [300]={npcDrops={100},objectDrops={201},itemDrops={301}}, [301]={itemDrops={300}} }
}
LibQuestieDB={RequireContract=function(v)return v==3 end,Support={Get=function()return {private={areaIdToUiMapId='return {[12]=2}',areaIdToUiMapIdOverride='return {[12]=1}'}}end}}
for kind,data in pairs(records) do LibQuestieDB[kind]={Get=function(id,key)return data[id] and data[id][key] end} end
local points=locations:Build({{id=20,title='Near'},{id=30,title='Done',complete=true}},20,{id=40,quest='Westfall Stew'})
assert(#points==6 and points[1].current)
local originalGet=LibQuestieDB.Quest.Get
local cachedReads=0
LibQuestieDB.Quest.Get=function(...)local _,key=...;if key=="objectives"or key=="startedBy"or key=="finishedBy"then cachedReads=cachedReads+1 end;return originalGet(...)end
local cachedPoints=locations:Build({{id=20,title='Renamed'},{id=30,title='Done',complete=true}},30,{id=40,quest='Westfall Stew'})
assert(cachedReads==0 and #cachedPoints==6 and cachedPoints[1].questID==30 and cachedPoints[1].current)
assert(points[1].current and points[1].quest=='Near')
LibQuestieDB.Quest.Get=originalGet
print('PASS: unchanged quest source data incurs zero database reads; selection copies do not mutate cached points')

local names={};for _,p in ipairs(points)do names[p.name]=true;assert(p.x>=0 and p.x<=1 and p.y>=0 and p.y<=1)end
assert(names.Gnoll and names.Tools and names.Chest and names['Turn-in NPC'] and names.Verna)
local addedWorld,addedMini,clears=0,0,0
local pins={RemoveMinimapIcon=function()end,RemoveWorldMapIcon=function()end,RemoveAllWorldMapIcons=function()clears=clears+1 end,RemoveAllMinimapIcons=function()clears=clears+1 end,AddWorldMapIconMap=function(_,owner,icon,map,x,y)assert(map==1);addedWorld=addedWorld+1 end,AddMinimapIconMap=function()addedMini=addedMini+1 end}
LibStub=function(name)assert(name=='HereBeDragons-Pins-2.0');return pins end
Minimap=node()
q.entries={{id=20,title='Near'},{id=30,title='Done',complete=true}};q.selected=20;q.guide=nil
locations:Refresh(q,true);assert(addedWorld==1 and addedMini==1,tostring(addedWorld)..":"..tostring(addedMini))
locations:Refresh(q);assert(addedWorld==1)
q.selected=30;locations:Refresh(q);assert(addedWorld==1 and addedMini==1 and clears==0)
ProjectRuthlessDB.questWorkspace.enabled=false;locations:Refresh(q);assert(clears==2 and not locations.pool[1].mini:IsShown())
LibQuestieDB=nil;assert(#locations:Build({},20)==0)
print('PASS: database contract, mob/object/item sources, cyclic container protection, duplicate/sentinel removal, guide accept and turn-in pins, both maps, selection change and disable cleanup')
-- Visual indicators cannot select quests or write waypoints, even in combat.
for _,pair in ipairs(locations.pool)do assert(pair.mini.scripts.OnClick==nil)end
for _,icon in ipairs(locations.worldPool)do assert(icon.scripts.OnClick==nil)end
print('PASS: visual map/minimap indicators have no action handlers')
-- Native quests can navigate across zones on the same continent.
ProjectRuthlessDB.questWorkspace.enabled=true;q.guide=nil;q.selected=20
C_Map.GetBestMapForUnit=function()return 2 end
C_Map.GetPlayerMapPosition=function()return {GetXY=function()return .5,.5 end}end
function CreateVector2D(x,y)return {x=x,y=y}end
C_Map.GetWorldPosFromMapPos=function(map) return 0,{GetXY=function()return map==2 and 100 or 200,300 end}end
q:Navigate();assert(q.arrow.shown and q.distance.text:find('100 yd',1,true))
C_Map.GetWorldPosFromMapPos=function(map)return map,{GetXY=function()return 0,0 end}end
q:Navigate();assert(not q.arrow.shown and q.distance.text:find('continent'))
print('PASS: native navigation across neighboring zones, separate-continent fallback')

LibQuestieDB={RequireContract=function()return true end,Support={Get=function()return {private={areaIdToUiMapId={[12]=1}}}end}}
for kind,data in pairs(records)do LibQuestieDB[kind]={Get=function(id,key)return data[id] and data[id][key]end}end
local selectedMap;WorldMapFrame.SetMapID=function(_,id)selectedMap=id end
q.entries={{id=20,title='Near'},{id=30,title='Done',complete=true}};q.selected=20
locations:Refresh(q,true)
local summary=locations:WorldMarkers(locations.points)
assert(#summary==3 and summary[1].kind=='Collect' and summary[2].kind=='Kill' and summary[3].kind=='Turn in')
assert(locations.pool[1].mini.width==15 and locations.pool[1].mini.height==15)
local turnin;for _,icon in ipairs(locations.worldPool)do if icon.point.questID==30 then turnin=icon end end
assert(turnin and turnin.width==20)
for _,icon in pairs(locations.activeWorld)do assert(icon.scripts.OnClick==nil)end
local hidden=false;locations.areaPool={{Hide=function()hidden=true end}};locations:DrawSelectedArea();assert(hidden)
locations:SelectQuest(30);assert(selectedMap==1)
local viewed;function QuestMapFrame_ShowQuestDetails(id)viewed=id end
assert(turnin.scripts.OnClick==nil)
ProjectRuthlessDB.questWorkspace.enabled=false;locations:Refresh(q,true);assert(#locations.points==0 and not locations.worldPool[1]:IsShown())
print('PASS: main map supplements native blue areas with passive objective/pickup/turn-in indicators; custom shading stays hidden')
-- Native GetTexture returns numeric file IDs, not paths.
ProjectRuthlessDB.questWorkspace.enabled=true;ProjectRuthlessDB.questWorkspace.useWisp=nil
ForeverWispFrame={route=route,IsShown=function()return true end}
navArrow.GetTexture=function()return 987654 end;navArrow.GetSize=function()return 96,96 end;navArrow.GetRotation=function()return .75 end
ForeverWispNavigation={IsShown=function()return true end,GetRegions=function()return navArrow,copy('100 yd',12),copy('Target',12),copy('Note',10)end}
q:Refresh();assert(q.arrow.shown and q.distance.text=='100 yd')
print('PASS: live-style numeric arrow texture and configurable distance font')
local completed,onQuest={},{}
C_QuestLog.IsQuestFlaggedCompleted=function(id)return completed[id] or false end
C_QuestLog.IsOnQuest=function(id)return onQuest[id] or false end
local questData={requiredLevel=10,questLevel=12}
local db={Quest={Get=function(_,key)return questData[key]end}}
assert(locations:Eligible(50,db,13))
onQuest[50]=true;assert(not locations:Eligible(50,db,13));onQuest[50]=nil
completed[50]=true;assert(not locations:Eligible(50,db,13));completed[50]=nil
questData.preQuestGroup={2,3};completed[2]=true;assert(not locations:Eligible(50,db,13));completed[3]=true;assert(locations:Eligible(50,db,13))
questData.requiredRaces=1;assert(not locations:Eligible(50,db,13));questData.requiredRaces=0
questData.requiredSkill={1,50};assert(not locations:Eligible(50,db,13));questData.requiredSkill=nil
questData.requiredLevel=20;assert(not locations:Eligible(50,db,13))
print('PASS: available quests exclude active/completed/underlevel, unmet chains/races and unverified skill gates')
records.Quest[40].requiredLevel=10;records.Quest[40].questLevel=12
LibQuestieDB={RequireContract=function()return true end,Support={Get=function()return {private={areaIdToUiMapId={[12]=1}}}end}}
for kind,data in pairs(records)do LibQuestieDB[kind]={Get=function(id,key)return data[id] and data[id][key]end}end
LibQuestieDB.Quest.GetAllIds=function()return {20,40}end
function UnitLevel()return 13 end
function UnitRace()return 'Human','Human',1 end
locations:ScanOffers();assert(#locations.offers==1 and locations.offers[1].id==40)
local acceptMarker
for _,icon in ipairs(locations.worldPool)do if icon.point.kind=='Accept' then acceptMarker=icon end end
assert(acceptMarker)
assert(acceptMarker.scripts.OnClick==nil)
print('PASS: pickup marker is visual only and does not open quest panels')
-- Selected quest areas exclude pickups/turn-ins and other quests.
local cells=locations:AreaCells({{map=1,current=true,x=.2,y=.3,kind='Npc'},{map=1,current=true,x=.201,y=.301,kind='Collect'},{map=1,current=false,x=.8,y=.8,kind='Npc'},{map=1,current=true,x=.5,y=.5,kind='Turn in'}},1)
assert(#cells==1)
C_Map.GetBestMapForUnit=function()return 1 end
C_Map.GetPlayerMapPosition=function()return {GetXY=function()return .2,.2 end}end
C_Map.GetMapWorldSize=function()return 1000,1000 end
locations.points={{map=1,questID=20,x=.25,y=.25},{map=1,questID=40,x=.3,y=.3}}
q.entries={{id=20,title='Near',detail='1/3 collected'},{id=30,title='Elsewhere'}}
function IsInInstance()return false end
local nearby=locations:ContextRows(q);assert(#nearby==2 and nearby[1].id==20 and nearby[2].accept)
LibQuestieDB.Support.Get=function()return {private={areaIdToUiMapId={[12]=1},dungeons={[999]={'Hall of Thanes',{998}}}}}end
records.Quest[30].zoneOrSort=998
function IsInInstance()return true end
function GetRealZoneText()return 'Hall of Thanes'end
C_Map.GetMapInfo=function()return {mapType=3}end
local dungeon,inside=locations:ContextRows(q);assert(inside and #dungeon==1 and dungeon[1].id==30)
q.trackedDungeons[999]=true;q:RenderContext();assert(q.dungeonRows[1].entry.id==30)
combat=true;q.dungeonRows[1].scripts.OnClick();assert(q.manualFocus);combat=false;q.manualFocus=nil
quests[#quests+1]={questID=30,title='Elsewhere'}
q.dungeonRows[1].scripts.OnClick();assert(q.manualFocus and q.selected==30 and not q.guide)
q.returnGuide.scripts.OnClick();assert(not q.manualFocus and q.guide)
function IsInInstance()return false end
locations.points={{map=1,questID=40,x=.3,y=.3,name='Verna'}}
q:RenderContext();q.contextRows[1].scripts.OnClick();assert(q.manualPickup and q.selected==40)
assert(q.currentTitle.text:find(q.manualPickup.title,1,true))
print('PASS: selected-objective area isolation, nearby active quests and pickups, live dungeon alias matching without outdoor leakage, quest rerouting and Guide return')
q.manualFocus=nil;q.manualPickup=nil;q.tripArea=nil
route.objectives={copy={objectives={{IsShown=function()return true end,name=copy('Harvest Watcher'),counter=copy('6/20')}}}}
route.along={IsShown=function()return true end,rows={{IsShown=function()return true end,objectives={{IsShown=function()return true end,name=copy('Handful of Oats'),counter=copy('6/8')}}}}}
q:Refresh();assert(q.objectiveCopy.text:find('Harvest Watcher  6/20',1,true) and q.objectiveCopy.text:find('Along the way',1,true))
local withObjectives=q.frame.height
route.objectives=nil;route.along=nil;q:Refresh();assert(q.frame.height<withObjectives)
q.entries={{id=30,title='Dungeon task',detail='0/3 collected'}}
local trips=locations:TripRecommendations(q);assert(#trips==1 and trips[1].area==999 and trips[1].count==1)
q:RenderContext();assert(q.tripSuggestion and not q.tripButton:IsShown())
q.tripButton.scripts.OnClick();assert(q.tripArea==999 and q.dungeonRows[1].entry.id==30)
q.returnGuide.scripts.OnClick();assert(q.tripArea==nil)
-- Temporarily hidden Wisp arrow/frame still exposes a valid readable bearing.
ForeverWispNavigation.IsShown=function()return true end;navArrow.IsShown=function()return false end
q:Refresh();assert(q.arrow.shown)
print('PASS: live guide counters/along-the-way tasks, content-driven layout, independent dungeon recommendation/view and hidden-source compass continuity')
q.manualFocus=true;q.guide=nil;q.selected=20
C_QuestLog.GetLogIndexForQuestID=function(id)return id==20 and 2 or nil end
function GetQuestLogSpecialItemLink(index)return index==2 and '|cffffffff|Hitem:123|h[Quest Gizmo]|h|r' end
function GetQuestLogSpecialItemInfo()return '|cffffffff|Hitem:123|h[Quest Gizmo]|h|r',456 end
q:RenderQuestItems();assert(q.itemRows[1].item.link:find('Quest Gizmo') and q.itemRows[1]:IsShown())
local clicked;function HandleModifiedItemClick(link)clicked=link;return true end
q.itemRows[1].scripts.OnClick(q.itemRows[1]);assert(clicked:find('item:123'))
local used
HandleModifiedItemClick=function()return false end
function UseQuestLogSpecialItem(index)used=index end
q.itemRows[1].scripts.OnClick(q.itemRows[1]);assert(used==2)
C_QuestLog.GetLogIndexForQuestID=function()return 7 end
GetQuestLogSpecialItemInfo=function(index)return index==7 and '|cffffffff|Hitem:123|h[Quest Gizmo]|h|r',456 end
q.itemRows[1].scripts.OnClick(q.itemRows[1]);assert(used==7)
used=nil
GetQuestLogSpecialItemInfo=function()return nil end;q.itemRows[1].scripts.OnClick(q.itemRows[1]);assert(used==nil)
GetQuestLogSpecialItemInfo=function()return nil end;GetQuestLogSpecialItemLink=function()return nil end;q:RenderQuestItems();assert(not q.itemRows[1]:IsShown())
print('PASS: native quest-item icon/link, modified-click linking and stale-item cleanup native item use, current log-index resolution and stale-item cleanup')

-- Per-dungeon opt-in, pickup/breadcrumb classification and dismissal.
q.tripArea=nil;q.trackedDungeons={};q.dungeonDismissed={}
records.Quest[40].zoneOrSort=999
locations.offers={{id=40,title='Dungeon pickup',accept=true}}
q.entries={{id=30,title='Held dungeon quest',detail='0/3'}}
q:RenderDungeons();assert(q.pendingDungeon.area==999 and q.pendingDungeon.held==1 and q.pendingDungeon.pickups==1)
q.trackDungeonButton.scripts.OnClick();assert(q.trackedDungeons[999] and q.dungeonRows[1]:IsShown())
q:TrackDungeon(999,false);q:RenderDungeons();assert(not q.pendingDungeon and not q.dungeonRows[1]:IsShown())
q.dungeonDismissed[999]=nil;q:RenderDungeons();q.dismissDungeonButton.scripts.OnClick();assert(q.dungeonDismissed[999] and not q.trackedDungeons[999])
q.mapPage='Dungeons';q:RenderMapPage();q.dungeonMapButtons[1].scripts.OnClick();assert(q.trackedDungeons[999])
q.dungeonMapButtons[1].scripts.OnClick();assert(not q.trackedDungeons[999])
print('PASS: per-dungeon held/pickup prompt, tracking, dismissal and map manager toggles')

q.manualFocus=nil;q.manualPickup=nil
route.objectives={copy={objectives={{IsShown=function()return true end,name=copy('Harvest Watcher'),counter=copy('6/20')}}}}
q:Refresh();assert(q.objectiveDisplayRows[1].name.text=='Harvest Watcher' and q.objectiveDisplayRows[1].count.text==q:HighlightObjective('6/20'))
print('PASS: objective names and progress counts render in separate aligned columns')

-- Dungeon classification is cached until quest/offer snapshots change.
local originalGet=LibQuestieDB.Quest.Get
local databaseReads=0
LibQuestieDB.Quest.Get=function(...)databaseReads=databaseReads+1;return originalGet(...)end
locations.dungeonCache=nil
local cached=locations:DungeonCatalog(q);local firstReads=databaseReads;assert(firstReads>0)
for i=1,20 do assert(locations:DungeonCatalog(q)==cached)end
assert(databaseReads==firstReads)
local previousOffers=locations.offers;locations.offers={}
assert(locations:DungeonCatalog(q)~=cached and databaseReads>firstReads)
locations.offers=previousOffers;LibQuestieDB.Quest.Get=originalGet
local navigations,contents=0,0
local originalNavigate,originalContext=q.Navigate,q.RenderContext
q.Navigate=function()navigations=navigations+1 end;q.RenderContext=function()contents=contents+1 end
assert(q.frame.scripts.OnUpdate==nil)
for i=1,3 do intervalTimers[1].fn()end
assert(navigations==3 and contents==0)
intervalTimers[2].fn();assert(contents==1)
q.Navigate=originalNavigate;q.RenderContext=originalContext
local opened
function ShowUIPanel(frame)opened=frame;frame:Show()end
q.mapPanel:Hide();q.menuButton.scripts.OnClick();assert(opened==WorldMapFrame and q.mapPanel:IsShown() and q.mapPage=='Dungeons')
combat=true;opened=nil;q.menuButton.scripts.OnClick();assert(opened==WorldMapFrame);combat=false
print('PASS: repeated dungeon reads cached, changed offers invalidate cache, compass ticks avoid content work, menu opens map dungeon controls')

q:Refresh()
local oldRenderContext=q.RenderContext
local oldRenderItems=q.RenderQuestItems
local redraws,itemUpdates=0,0
q.RenderContext=function()redraws=redraws+1 end
q.RenderQuestItems=function()itemUpdates=itemUpdates+1 end
q:Refresh(true);q:Refresh(true)
assert(redraws==0 and itemUpdates==2)
q.RenderContext=oldRenderContext;q.RenderQuestItems=oldRenderItems
print('PASS: unchanged loot snapshots skip context/layout redraws while refreshing usable quest items')

questData.requiredLevel=10;questData.requiredSkill={182,50}
locations.professionRanks={}
assert(not locations:Eligible(50,db,13))
locations.professionRanks={[182]=49};assert(not locations:Eligible(50,db,13))
locations.professionRanks={[182]=50};assert(locations:Eligible(50,db,13))
locations.professionRanks=nil
local eligible,reason,unknown=locations:Eligible(50,db,13)
assert(not eligible and unknown and reason:find('Profession'))
questData.requiredSkill=nil;questData.requiredLevel=20
local allowed,levelReason,uncertain=locations:Eligible(50,db,13)
assert(not allowed and not uncertain and levelReason=='Requires level 20')
questData.requiredLevel=10;questData.requiredRaces=4294967296
assert(locations:Eligible(50,db,13,4294967296))
assert(not locations:Eligible(50,db,13,1))
print('PASS: missing/low profession skills and underlevel quests are blocked, unavailable profession evidence is uncertain, high race bits do not truncate')
questData.requiredRaces=nil;questData.requiredLevel=1;questData.questLevel=12;questData.zoneOrSort=-61;questData.requiredClasses=nil
assert(not locations:Eligible(50,db,13,nil,128))
assert(locations:Eligible(50,db,13,nil,256))
local _,classReason,classUnknown=locations:Eligible(50,db,13,nil,nil)
assert(classUnknown and classReason:find('Class',1,true))
questData.zoneOrSort=12;questData.requiredClasses=256
assert(not locations:Eligible(50,db,13,nil,128));assert(locations:Eligible(50,db,13,nil,256))
questData.requiredClasses=nil;questData.zoneOrSort=-121
local _,professionReason,professionUnknown=locations:Eligible(50,db,13,nil,128)
assert(professionUnknown and professionReason:find('Profession',1,true))
questData.requiredSkill={164,50};locations.professionRanks={}
assert(not locations:Eligible(50,db,13,nil,128))
locations.professionRanks={[164]=50};assert(locations:Eligible(50,db,13,nil,128))
questData.zoneOrSort=nil;questData.requiredSkill=nil;locations.professionRanks=nil
print('PASS: class-sort-only and explicit class restrictions exclude other classes; profession-sort-only gates stay uncertain, explicit skills exclude unlearned professions')
LibQuestieDB.Quest.Get=function(id,key)return records.Quest[id]and records.Quest[id][key]end
LibQuestieDB.Item.Get=function(id,key)return records.Item[id]and records.Item[id][key]end
q.entries={{id=20,title='Westfall Stew'}}
locations:UpdateTooltipIndex(q)
UnitGUID=function()return 'Creature-0-0-0-0-100-000000' end
strsplit=function(_,value)return value:match('([^-]+)%-([^-]+)%-([^-]+)%-([^-]+)%-([^-]+)%-([^-]+)%-([^-]+)')end
C_Item.GetItemNameByID=function(id)return id==300 and 'Stringy Vulture Meat' end
C_QuestLog.GetQuestObjectives=function()return {{text='1/3 Stringy Vulture Meat',objectID=300,finished=false}}end
local tooltipLines={}
local tip={GetUnit=function()return 'Fleshripper','mouseover'end,AddLine=function(_,text)tooltipLines[#tooltipLines+1]=text end}
locations:AddUnitTooltip(tip)
assert(tooltipLines[1]=='Westfall Stew' and tooltipLines[2]=='1/3 Stringy Vulture Meat')
print('PASS: quest item droppers show held-quest item progress on unit tooltips')

local grouped,raiding=true,false
IsInGroup=function()return grouped end;IsInRaid=function()return raiding end
local sent={};SendChatMessage=function(message,channel)assert(channel=='PARTY');sent[#sent+1]=message end
local progress={{text='2/3 Stringy Vulture Meat',objectID=300,type='item',finished=false},{text='0/1 Kill target',objectID=100,type='monster',finished=false}}
local questDone=false
C_QuestLog.GetNumQuestLogEntries=function()return 1 end
C_QuestLog.GetInfo=function()return {questID=20,title='Westfall Stew',isHeader=false}end
C_QuestLog.GetQuestObjectives=function()return progress end
C_QuestLog.IsComplete=function()return questDone end
q.partyQuestState=nil;q:AnnounceQuestProgress();assert(#sent==0)
progress[1].text='3/3 Stringy Vulture Meat';progress[1].finished=true
q:AnnounceQuestProgress();assert(#sent==1 and sent[1]:find('3/3 Stringy Vulture Meat',1,true))
q:AnnounceQuestProgress();assert(#sent==1)
questDone=true;progress[2].finished=true;q:AnnounceQuestProgress()
assert(#sent==2 and sent[2]:find('ready to turn in',1,true))
q:AnnounceQuestProgress();assert(#sent==2)
q.partyQuestState=nil;q:AnnounceQuestProgress();assert(#sent==2)
questDone=false;progress[1].finished=false;q:AnnounceQuestProgress()
grouped=false;progress[1].finished=true;q:AnnounceQuestProgress();assert(#sent==2)
grouped=true;q:AnnounceQuestProgress();assert(#sent==2)
raiding=true;questDone=true;q:AnnounceQuestProgress();assert(#sent==2)
print('PASS: party objective/quest completion announces once; reload, solo completion, later group joins and raids remain silent')

local s=ProjectRuthlessDB.questWorkspace
s.prepWestfall=true;UnitLevel=function()return 14 end;UnitFactionGroup=function()return 'Alliance'end
C_QuestLog.IsQuestFlaggedCompleted=function()return false end
C_Item.GetItemCount=function(id)return id==255007 and 4 or 0 end
local prep=q:WestfallPrep();assert(#prep==3 and prep[1]=='10 × Golem Isospring' and prep[3]=='10 × Rough Dynamite')
C_QuestLog.IsQuestFlaggedCompleted=function(id)return id==92909 end
assert(#q:WestfallPrep()==1)
UnitLevel=function()return 7 end;assert(#q:WestfallPrep()==0)
local choices,rewards,progressCalls=0,{},0
GetNumQuestChoices=function()return choices end
GetQuestReward=function(choice)rewards[#rewards+1]=choice end
IsQuestCompletable=function()return true end;CompleteQuest=function()progressCalls=progressCalls+1 end
s.autoHandIn=false;q:AutoHandIn('QUEST_COMPLETE');assert(#rewards==0)
s.autoHandIn=true;q:AutoHandIn('QUEST_PROGRESS');assert(progressCalls==1)
q:AutoHandIn('QUEST_COMPLETE');assert(rewards[1]==0)
choices=1;q:AutoHandIn('QUEST_COMPLETE');assert(rewards[2]==1)
choices=2;q:AutoHandIn('QUEST_COMPLETE');assert(#rewards==2)
combat=true;q:AutoHandIn('QUEST_PROGRESS');assert(progressCalls==1);combat=false
print('PASS: upcoming Westfall supplies use remaining counts/completion/level gates; auto hand-in is opt-in, combat-safe and leaves multiple reward choices manual')

local supplyQuests={[1000]={zoneOrSort=10,objectives={[3]={{5000,nil,3}}}},[1001]={zoneOrSort=10,objectives={[3]={{5001,nil,2}}}},[1002]={zoneOrSort=10,objectives={[3]={{5002,nil,4}}}}}
local supplyDB={Quest={Get=function(id,key)return supplyQuests[id]and supplyQuests[id][key]end},Item={Get=function(id,key)if key=='name'then return 'Supply '..id elseif key=='vendors'then return id==5002 and {123}or {}end end}}
local oldDatabase=locations.Database;local oldEligibility=locations.PlayerEligibility
locations.Database=function()return supplyDB end;locations.PlayerEligibility=function()return true end
locations.offerCandidates={1001,1002};q.entries={{id=1000,title='Zone quest'}};q.guide=nil
C_QuestLog.IsQuestFlaggedCompleted=function()return false end
C_Item.GetItemCount=function(id)return id==5000 and 1 or 0 end
C_Item.GetItemInfo=function(id)return 'item',nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,id==5001 and 1 or 0 end
local supplies=q:ZonePreparation();assert(#supplies==2)
assert(table.concat(supplies,';'):find('2 × Supply 5000 · AH',1,true))
assert(table.concat(supplies,';'):find('4 × Supply 5002 · vendor',1,true))
local cached=q.prepRecords;q:ZonePreparation();assert(q.prepRecords==cached)
locations.Database=oldDatabase;locations.PlayerEligibility=oldEligibility
print('PASS: generic zone preparation finds future vendor/tradeable objectives, excludes soulbound drops, subtracts inventory and caches requirements')

assert(load(DUNGEON_SOURCE))('ProjectRuthless',AUI)
local atlas=AUI.modules.DungeonAtlas
local dungeonRecord={InstanceID=36,MapID=1581,LevelRange={10,17,26},items={{name='Boss',npcID=100}},LoadDifficulty=1}
local dungeonData={Deadmines={name='The Deadmines',InstanceID=36,MapID=1581,LevelRange={10,17,26},items=dungeonRecord.items,LoadDifficulty=1}}
AtlasLoot={ItemDB={Get=function()return dungeonData end,GetItemTable=function()return {{1,5000},{2,'header'},{3,5000},{4,5002}}end}}
C_AddOns={IsAddOnLoaded=function()return true end,LoadAddOn=function()error('already loaded')end}
RUI_DungeonData=dungeonData;dungeonData.Deadmines.items[1].loot={NORMAL={{1,5000},{2,5000},{3,5002}}}
local catalog=atlas:Load();assert(#catalog==1 and catalog[1].name=='The Deadmines')
locations.mapping[1581]=1
C_Map.GetMapGroupID=function()return 9 end
C_Map.GetMapGroupMembersInfo=function()return {{mapID=1,name='Upper'},{mapID=2,name='Lower'}}end
C_Map.GetMapArtLayers=function(id)if id==1 or id==2 then return {{layerWidth=1000,layerHeight=700}}end end
assert(#atlas:MapIDs(dungeonRecord)==2)
local savedInfo=C_Map.GetMapInfo;C_Map.GetMapInfo=function(id)if id==1 then return nil end;return savedInfo(id)end
assert(#atlas:MapIDs(dungeonRecord)==1 and atlas:MapIDs(dungeonRecord)[1].mapID==2)
assert(not atlas:OpenMap(999));C_Map.GetMapInfo=savedInfo

local bossPoints=atlas:BossPoints(dungeonRecord.items[1]);assert(#bossPoints==1 and bossPoints[1].map==1)
assert(atlas:BossPoints(dungeonRecord.items[1])==bossPoints)
local atlasRows={};atlas.Row=function(_,_,i,text,click,item)atlasRows[#atlasRows+1]={text=text,click=click,item=item}end
atlas.DrawPins=function()end
q.mapPage='Dungeon atlas';atlas:Render(q);assert(atlasRows[1].text:find('The Deadmines',1,true))
atlas.selected=catalog[1];atlas.view='Bosses';atlas.boss=1;atlasRows={};atlas:Render(q)
local lootCount=0;for _,row in ipairs(atlasRows)do if row.item then lootCount=lootCount+1 end end;assert(lootCount==2)
combat=true;assert(atlas:Load()==catalog);assert(atlas:OpenMap(1));atlasRows={};atlas:Render(q);assert(#atlasRows>0);combat=false
print('PASS: dungeon library, native multi-floor selection, real boss coordinates/cache, unique numeric loot rows and combat browsing')


local previousBuild,previousAreas=locations.Build,locations.DrawAreas
locations.Build=function()return {}end;locations.DrawAreas=function()end
locations.offers={};locations.signature=nil
q.entries={};q.guide={id=20,questIDs={[20]=true}}
locations:Refresh(q);local firstSignature=locations.signature
q.guide.questIDs[99]=true;locations:Refresh(q)
assert(locations.signature~=firstSignature)
local secondSignature=locations.signature;q.guide.questIDs={[99]=true,[20]=true};locations:Refresh(q)
assert(locations.signature==secondSignature)
locations.Build,locations.DrawAreas=previousBuild,previousAreas
print('PASS: keyed guide quest sets invalidate marker state; insertion order cannot cause redundant invalidation')

-- Reproduce a native list trying to reopen while custom settings occupy its region.
q.nativeMapLog=node(WorldMapFrame)
function q.nativeMapLog:SetAlpha(value)self.alpha=value end
function q.nativeMapLog:Hide()error('Custom sidebar must not trigger the native quest-log OnHide lifecycle')end
q:SelectMapPage('Settings');assert(q.mapPanel:IsShown()and q.nativeMapLog:IsShown()and q.nativeMapLog.alpha==0 and q.mapTabBar:IsShown())
q.nativeMapLog:Show();q:SyncMapPage();assert(q.nativeMapLog:IsShown()and q.nativeMapLog.alpha==0)
q:SelectMapPage('Quests');assert(not q.mapPanel:IsShown()and q.nativeMapLog:IsShown()and q.nativeMapLog.alpha==1 and q.mapTabBar:IsShown())
local nativePoints=q.nativeMapLog.points;local nativeShow=q.nativeMapLog.Show
q.nativeMapLog.Show=function()error('Combat browsing cannot show native frames')end
q.nativeMapLog.ClearAllPoints=function()error('Combat browsing cannot reanchor native frames')end
combat=true;for _,page in ipairs({'Tools','Settings','Quests','Supplies'})do q:SelectMapPage(page);assert(q.mapPage==page and q.mapPanel:IsShown()==(page~='Quests'))end;combat=false
q.nativeMapLog.Show=nativeShow;q.nativeMapLog.ClearAllPoints=nil
print('PASS: persistent top tabs and exclusive native quest/custom option views survive native re-show; combat tabs browse without native layout writes')
local cursorX,cursorY=900,100;GetCursorPosition=function()return cursorX,cursorY end
function WorldMapFrame:GetScale()return rawget(self,"scale") or 1 end
function WorldMapFrame:GetEffectiveScale()return self:GetScale()end
function WorldMapFrame:SetScale(scale)self.scale=scale end
function WorldMapFrame:GetLeft()return 10 end
function WorldMapFrame:GetTop()return 500 end
function WorldMapFrame:GetWidth()return rawget(self,"width")or 900 end
function WorldMapFrame:GetHeight()return rawget(self,"height")or 500 end
function UIParent:GetEffectiveScale()return 1 end
local editorState={elements={map={width=780,height=460}}}
AUI.modules.LayoutEditor={targets={map=true},Capture=function(_,map)return {x=0,y=0,scale=map:GetScale(),width=map:GetWidth(),height=map:GetHeight()}end,Store=function()return editorState end}
q.mapResize.scripts.OnMouseDown(q.mapResize,'LeftButton');assert(q.mapResize.scripts.OnUpdate)
cursorX,cursorY=1080,100;q.mapResize.scripts.OnUpdate();assert(WorldMapFrame:GetWidth()==1080 and WorldMapFrame:GetHeight()==500 and WorldMapFrame:GetScale()==1)
q.mapResize.scripts.OnMouseUp();assert(q.mapResize.scripts.OnUpdate==nil and ProjectRuthlessCharDB.mapSize.width==1080)
assert(editorState.elements.map.width==1080 and editorState.elements.map.height==500 and ProjectRuthlessCharDB.mapScale==1)
AUI.modules.LayoutEditor=nil
WorldMapFrame:SetSize(900,500);q:ApplyMapScale();assert(WorldMapFrame:GetWidth()==1080 and WorldMapFrame:GetHeight()==500)
q.mapResize.scripts.OnMouseDown(q.mapResize,'LeftButton');cursorY=0;q.mapResize.scripts.OnUpdate();assert(WorldMapFrame:GetWidth()==1080 and WorldMapFrame:GetHeight()==600);q.mapResize.scripts.OnMouseUp()
combat=true;q.mapResize.scripts.OnMouseDown(q.mapResize,'LeftButton');assert(q.mapResize.scripts.OnUpdate==nil);combat=false
print('PASS: independent width/height resize without text scaling, saved dimensions, handler stop and combat block')
do
 local oldTimer,oldForever,oldHide=C_Timer.After,AUI.isForever,HideUIPanel
 local timers={};C_Timer.After=function(_,fn)timers[#timers+1]=fn end
 local nativeToggles=0
 function WorldMapFrame:HandleUserActionToggleSelf()nativeToggles=nativeToggles+1;if self:IsShown()then self:Hide()else self:Show()end end
 local nativeToggle=WorldMapFrame.HandleUserActionToggleSelf
 HideUIPanel=function(map)map:Hide()end;AUI.isForever=true
 q.mapPersistenceInstalled=nil;q.mapRestoreQueued=nil;q:InstallMapPersistence();assert(WorldMapFrame.HandleUserActionToggleSelf==nativeToggle)
 ProjectRuthlessCharDB.mapScale=.85;ProjectRuthlessCharDB.mapSize={width=1200,height=650}
 WorldMapFrame:Show();WorldMapFrame:SetSize(900,500);WorldMapFrame:SetScale(1)
 assert(#timers==1 and WorldMapFrame:GetWidth()==900)
 local pending=timers;timers={};for _,fn in ipairs(pending)do fn()end
 assert(WorldMapFrame:GetWidth()==1200 and WorldMapFrame:GetHeight()==650 and WorldMapFrame:GetScale()==.85 and #timers==0)
 for _,page in ipairs({'Quests','Settings','Dungeons'})do q:SelectMapPage(page);WorldMapFrame:Show();WorldMapFrame:HandleUserActionToggleSelf();assert(not WorldMapFrame:IsShown())end
 WorldMapFrame:HandleUserActionToggleSelf();assert(WorldMapFrame:IsShown()and nativeToggles==4)
 combat=true;WorldMapFrame:HandleUserActionToggleSelf();WorldMapFrame:HandleUserActionToggleSelf();assert(WorldMapFrame:IsShown()and WorldMapFrame.HandleUserActionToggleSelf==nativeToggle);combat=false
 q:SelectMapPage('Quests');C_Timer.After=oldTimer;AUI.isForever=oldForever;HideUIPanel=oldHide
 q.mapRestoreQueued=nil
 print('PASS: late native size/scale reset restores saved dimensions once without recursion; native M toggle identity remains intact for combat opening/closing')
end


local art=node();art.alpha=1;function art:SetAlpha(value)self.alpha=value end;function art:SetColorTexture(r,g,b,a)self.flat={r,g,b,a}end
local vignette=node();function vignette:SetAlpha(value)self.alpha=value end
WorldMapFrame.OverscrollBG={Texture=art,TopLeftVignette=vignette}
local mapPixels={alpha=1};WorldMapFrame.ScrollContainer={mapPixels=mapPixels,Child={TiledBackground=art}}
q:StyleMap();local shell=WorldMapFrame.ruthlessShellBackground;q:StyleMap();assert(WorldMapFrame.ruthlessShellBackground==shell);assert(art.flat and art.alpha==1 and vignette.alpha==0 and mapPixels.alpha==1)
for _,tab in ipairs(q.mapTabs)do assert(tab.parent==q.mapTabBar)end
assert(q.mapTabBar.parent==WorldMapFrame and q.mapPanel.parent==WorldMapFrame)
print('PASS: wood/vignette art is replaced without touching map pixels; map and menu share the same scaling parent')

local originalCatalog=locations.DungeonCatalog
locations.DungeonCatalog=function()return {{area=1581,entries={{id=10},{id=20},{id=30,accept=true},{id=40}}}}end
C_QuestLog.IsPushableQuest=function(id)return id~=40 end
C_QuestLog.GetLogIndexForQuestID=function(id)return id+100 end
local shareCalls={};QuestLogPushQuest=function(index)shareCalls[#shareCalls+1]=index end
IsInGroup=function()return true end
assert(q:ShareDungeon(1581));assert(shareCalls[1]==110)
local ok,_,remaining=q:ShareDungeon(1581);assert(ok and shareCalls[2]==120 and remaining==0)
assert(#shareCalls==2)
combat=true;assert(not q:ShareDungeonQuest(10));combat=false
IsInGroup=function()return false end;assert(not q:ShareDungeonQuest(10));assert(#shareCalls==2)
IsInGroup=function()return true end;assert(not q:ShareDungeonQuest(40))
locations.DungeonCatalog=originalCatalog
print('PASS: explicit sequential dungeon sharing uses live native indices; pickups/unshareable/solo/combat are excluded')
local nativeScroll=node();nativeScroll.SearchBox=node();nativeScroll.SettingsDropdown=node()
q.nativeMapLog.QuestsFrame=node();q.nativeMapLog.QuestsFrame.ScrollFrame=nativeScroll;QuestLogCount=node()
q:LayoutMap();local sidebar=q.mapTabBar.width
assert(sidebar>=340 and sidebar<=420 and nativeScroll.SearchBox.width+QuestLogCount.width+28<=sidebar)
assert(nativeScroll.SearchBox.point[2]==q.nativeMapLog and nativeScroll.point[2]==q.nativeMapLog)
assert(q.mapContent.width==sidebar-44 and q.mapTabs[1].width==(sidebar-20)/3-4)
print('PASS: native search/count fit inside responsive sidebar; tab/content widths reflow together')

local highlighted=q:HighlightObjective("Stringy Vulture Meat: 1/3")
assert(highlighted:find("|cff9cdcfeStringy Vulture Meat|r:",1,true))
assert(highlighted:find("|cffdcdcaa1/3|r",1,true))
assert(q:HighlightObjective("3/3")=="|cffb5cea83/3|r")
assert(q:HighlightObjective(highlighted)==highlighted)
local link="|Hitem:123|h[Quest item]|h";assert(q:HighlightObjective(link)==link)
assert(q:HighlightObjective("Walk to Stormwind")=="Walk to Stormwind")
print('PASS: semantic objective accents preserve links, prose and repeated rendering')

local refreshSaved=q.Refresh;local syncSaved=q.SyncMapPage
q.Refresh=function()end;q.SyncMapPage=function()end
ObjectiveTrackerFrame={alpha=.8,GetAlpha=function(self)return self.alpha end,SetAlpha=function(self,a)self.alpha=a end,Hide=function()error('Native tracker Hide must not be called')end,Show=function()error('Native tracker Show must not be called')end}
ProjectRuthlessDB.questWorkspace.enabled=true;q:ApplySettings();assert(ObjectiveTrackerFrame.alpha==0)
ObjectiveTrackerFrame:SetAlpha(1);assert(ObjectiveTrackerFrame.alpha==0)
combat=true;ObjectiveTrackerFrame:SetAlpha(.4);assert(ObjectiveTrackerFrame.alpha==0);combat=false
ProjectRuthlessDB.questWorkspace.enabled=false;q:ApplySettings();assert(ObjectiveTrackerFrame.alpha==.8)
ObjectiveTrackerFrame:SetAlpha(.6);assert(ObjectiveTrackerFrame.alpha==.6)
q.Refresh=refreshSaved;q.SyncMapPage=syncSaved;ObjectiveTrackerFrame=nil
print('PASS: tracker rendering suppression restores alpha without native visibility mutations')

assert(load(BUNDLED_DUNGEON_SOURCE))()
AtlasLoot=nil
local dbCount=0;local deadmines
for _,record in pairs(RUI_DungeonData)do dbCount=dbCount+1;if record.MapID==1581 then deadmines=record end end
assert(dbCount>=35 and deadmines and #deadmines.items>0)
atlas.catalog=nil;assert(#atlas:Load()>=35)
local localFloors=atlas:LocalFloors(deadmines);assert(#localFloors>=2)
assert(localFloors[1].key=='CL_TheDeadmines')
assert(#atlas:LocalFloors({AtlasMapFile='missing-map'})==0)
local viewer=node();viewer:SetSize(600,400);function viewer:GetWidth()return 600 end;function viewer:GetHeight()return 400 end;local image=node();function image:SetTexture(value)self.path=value end
atlas.localFrame=viewer;atlas.localTexture=image
assert(atlas:ShowLocalMap(localFloors[1].key));assert(image.width==364 and image.height==364 and image.path:find('CL_TheDeadmines',1,true))
atlas:Hide();assert(not viewer:IsShown())
print('PASS: bundled dungeon catalog/loot works with no AtlasLoot; local maps validate and fit without fake player coordinates')

local abandoned={};local selectedQuest=10
quests={{questID=10,title='Grey',level=1},{questID=20,title='Green',level=15},{questID=30,title='Locked grey',level=1}}
C_QuestLog.GetNumQuestLogEntries=function()return #quests end;C_QuestLog.GetInfo=function(i)return quests[i]end
GetQuestDifficultyColor=function(level)return level==1 and {r=.5,g=.5,b=.5}or {r=.2,g=1,b=.2}end
C_QuestLog.CanAbandonQuest=function(id)return id~=30 end
C_QuestLog.GetSelectedQuest=function()return selectedQuest end
C_QuestLog.SetSelectedQuest=function(id)selectedQuest=id end
C_QuestLog.SetAbandonQuest=function()end
C_QuestLog.AbandonQuest=function()abandoned[#abandoned+1]=selectedQuest end
local saveRender=q.RenderMapPage;local saveRefresh=q.Refresh;q.RenderMapPage=function()end;q.Refresh=function()end
q.greyReview=nil;q:ClearGreyQuests();assert(#q.greyReview==1 and #abandoned==0)
combat=true;q:ClearGreyQuests();assert(#abandoned==0);combat=false
q:ClearGreyQuests();assert(#abandoned==1 and abandoned[1]==10 and q.greyReview==nil)
q.RenderMapPage=saveRender;q.Refresh=saveRefresh
print('PASS: grey quest abandonment reviews first, rechecks native eligibility and blocks combat')

assert(load(AUTHORED_DATA_SOURCE))('ProjectRuthless',AUI)
assert(load(AUTHORED_SOURCE))('ProjectRuthless',AUI)
local authored=AUI.modules.AuthoredGuides
ProjectRuthlessCharDB.authoredGuide=nil;assert(authored:Read(q)==nil and authored.routes==nil)
local routes=authored:Catalog();assert(#routes==36)
local zones={};local ids={}
for _,route in ipairs(routes)do
    assert(route.min>=1 and route.max<=30 and #route.hubs>=1)
    assert(route.kind==nil or route.kind=='detour')
    if route.kind~='detour'then assert(#route.hubs>=2)end
    zones[route.area]=true
    for _,hub in ipairs(route.hubs)do assert(#hub.note>80 and #hub.quests>0);for _,id in ipairs(hub.quests)do assert(authored.facts[tostring(id)]and authored.facts[tostring(id)].min<=30);ids[id]=true end end
end
local zoneCount=0;for _ in pairs(zones)do zoneCount=zoneCount+1 end;assert(zoneCount==20)
local questCount=0;for _ in pairs(ids)do questCount=questCount+1 end;assert(questCount==673)
for faction,areas in pairs({Alliance={44,38,148,10,11,331,406,400},Horde={17,130,331,406,267,400}})do
    for _,area in ipairs(areas)do
        local found=false
        for _,route in ipairs(routes)do if route.faction==faction and route.area==area and route.min>=20 and route.kind~='detour'then found=true end end
        assert(found,'Missing twenties route: '..faction..' '..area)
    end
end
local savedRefresh=q.Refresh;local savedDatabase=locations.Database;local savedEligibility=locations.PlayerEligibility
q.Refresh=function()end;q.entries={};q.entriesSignature='authored1'
local done={};local reads=0;C_QuestLog.IsQuestFlaggedCompleted=function(id)reads=reads+1;return done[id]or false end
UnitFactionGroup=function()return 'Alliance'end;UnitLevel=function()return 1 end
locations.Database=function()return LibQuestieDB end
locations.PlayerEligibility=function(_,id)return id==7,'Prerequisite incomplete',false end
assert(not authored:Start('durotar'))
assert(authored:Start('elwynn'));local guide=authored:Read(q);assert(guide.source=='RUI'and guide.id==7 and guide.phase=='PICK UP')
local before=reads;assert(authored:Read(q)==guide and reads==before)
q.entries={{id=7,title='Kobold Camp Cleanup',complete=false,detail='0/10 Kobolds'}};q.entriesSignature='authored2'
guide=authored:Read(q);assert(guide.id==7 and guide.phase=='CURRENT OBJECTIVE'and #guide.objectives==1)
q.entries[1].complete=true;q.entriesSignature='authored3';guide=authored:Read(q);assert(guide.phase=='TURN IN')
done[7]=true;q.entries={};q.entriesSignature='authored4';guide=authored:Read(q);assert(guide.id~=7)
authored:Action('skip');assert(ProjectRuthlessCharDB.authoredGuide.skipped[guide.id])
combat=true;local chapter=ProjectRuthlessCharDB.authoredGuide.chapter;authored:Action('next');assert(ProjectRuthlessCharDB.authoredGuide.chapter==chapter+1);combat=false
for _,id in ipairs(authored.byID.elwynn.hubs[1].quests)do done[id]=true end
q.entriesSignature='authored5';guide=authored:Read(q);assert(guide.chapter==2)
authored:Action('pause');assert(authored:Read(q)==nil);authored:Action('pause');assert(authored:Read(q))
authored:Action('stop');assert(authored:Read(q)==nil)
local savedSync=q.SyncMapPage;local savedSelect=q.SelectMapPage
q.SyncMapPage=function()end;q.SelectMapPage=function(self,page)self.mapPage=page end
ProjectRuthlessCharDB.authoredGuide=nil;done={};q.entries={};q.entriesSignature='requirements1'
locations.Database=function()return nil end
assert(authored:Start('elwynn'));guide=authored:Read(q)
assert(guide.phase=='CHECK QUEST GIVER'and guide.availability=='unknown')
assert(guide.routeNote and #guide.instruction<#guide.routeNote and q.mapPage=='Chapters')
authored:Action('stepOptions');assert(q.mapPage=='Chapters')
UnitLevel=function()return 8 end;assert(authored:Start('westfall'));guide=authored:Read(q)
assert(guide.phase=='REQUIREMENTS'and guide.instruction:find('Requires level',1,true))
UnitLevel=function()return 12 end;q.entriesSignature='requirements2'
locations.Database=function()return LibQuestieDB end
locations.PlayerEligibility=function()return false,'Requires Blacksmithing',false end
guide=authored:Read(q);assert(guide.phase=='REQUIREMENTS'and guide.instruction:find('Requires Blacksmithing',1,true))
locations.PlayerEligibility=function()return false,'Skill data unavailable',true end
locations.offers={};guide=authored:Read(q);assert(guide.availability=='unknown'and guide.phase=='CHECK QUEST GIVER')
q:LayoutMap();authored:RenderBrowser(q,'Chapters')
assert(q.mapCopy.text:find(guide.routeNote,1,true)and authored.rows[1].point[3]<=-120)
local state=ProjectRuthlessCharDB.authoredGuide;local chapter=state.chapter
authored:Start('westfall',chapter);assert(ProjectRuthlessCharDB.authoredGuide==state)
authored:Action('stop');q.SyncMapPage=savedSync;q.SelectMapPage=savedSelect
-- Continuations use the same pickup/objective/turn-in flow and cannot bypass faction or level gates.
UnitLevel=function()return 20 end;UnitFactionGroup=function()return 'Alliance'end
done={};q.entries={};q.entriesSignature='continuation1';locations.offers={}
locations.PlayerEligibility=function()return true,nil,false end
assert(authored:Start('duskwood'));guide=authored:Read(q);assert(guide.id==56 and guide.phase=='PICK UP')
q.entries={{id=56,title='The Night Watch',complete=false,detail='0/8 Skeletons'}};q.entriesSignature='continuation2'
guide=authored:Read(q);assert(guide.id==5 and guide.phase=='PICK UP')
for _,id in ipairs(authored.byID.duskwood.hubs[1].quests)do done[id]=true end
q.entries={};q.entriesSignature='continuation3';guide=authored:Read(q);assert(guide.chapter==2 and guide.id==57)
assert(not authored:Start('hillsbrad-horde'))
UnitFactionGroup=function()return 'Horde'end;UnitLevel=function()return 29 end
assert(authored:Start('thousand-needles-horde',4));guide=authored:Read(q);assert(guide.id==5151 and #guide.next==3)
UnitLevel=function()return 27 end;q.entriesSignature='continuation4'
assert(authored:Start('thousand-needles-horde',4));guide=authored:Read(q)
assert(guide.id==5151) -- still eligible; minimums, not the route's suggested range, gate pickups
done[5151]=true;q.entriesSignature='continuation5';guide=authored:Read(q);assert(guide.phase=='REQUIREMENTS')
authored:Action('stop')
q.Refresh=savedRefresh;locations.Database=savedDatabase;locations.PlayerEligibility=savedEligibility
print('PASS: authored route notes scroll above controls; level/profession blocks and absent/uncertain data never claim pickup availability')
print('PASS: 36 original routes/detours cover 20 zones and 673 verified quests; level 20–30 coverage, progression, completion, requirements, faction, skip/pause/combat and unchanged-read caching')

-- Shared status is cached until relevant input changes; pickup relevance is separate from acceptance.
local statusReads=0;local statusFields={requiredLevel=1,questLevel=1}
local statusDB={Quest={Get=function(_,key)statusReads=statusReads+1;return statusFields[key]end}}
UnitClass=function()return 'Warlock','WARLOCK',9 end;UnitRace=function()return 'Human','Human',1 end;UnitLevel=function()return 30 end
C_QuestLog.IsOnQuest=function()return false end;C_QuestLog.IsQuestFlaggedCompleted=function()return false end
locations:InvalidateAvailability();local status=locations:PlayerStatus(900,statusDB)
assert(status.status=='available');local beforeStatus=statusReads
assert(locations:PlayerStatus(900,statusDB)==status and statusReads==beforeStatus)
statusFields.requiredClasses=128;locations:InvalidateAvailability();status=locations:PlayerStatus(900,statusDB)
assert(status.status=='locked'and status.reason:find('class',1,true))
statusFields.requiredClasses=nil;statusFields.preQuestGroup={901};locations:InvalidateAvailability()
assert(locations:PlayerStatus(900,statusDB).reason:find('901',1,true));statusFields.preQuestGroup=nil
statusFields.requiredMinRep={72,3000};C_Reputation={GetFactionDataByID=function()return {currentStanding=2999}end}
locations:InvalidateAvailability();assert(locations:PlayerStatus(900,statusDB).status=='locked')
C_Reputation.GetFactionDataByID=function()return {currentStanding=3000}end
locations:InvalidateAvailability();assert(locations:PlayerStatus(900,statusDB).status=='available')
C_Reputation=nil;locations:InvalidateAvailability();assert(locations:PlayerStatus(900,statusDB).status=='uncertain')
statusFields.requiredMinRep=nil;statusFields.requiredSpell=123;IsPlayerSpell=function()return false end
locations:InvalidateAvailability();assert(locations:PlayerStatus(900,statusDB).status=='locked')
IsPlayerSpell=function()return true end;locations:InvalidateAvailability();assert(locations:PlayerStatus(900,statusDB).status=='available')
statusFields.requiredSpell=nil;statusFields.requiredSourceItems={123};C_Item.GetItemCount=function()return 0 end
locations:InvalidateAvailability();assert(locations:PlayerStatus(900,statusDB).reason:find('123',1,true))
C_Item.GetItemCount=function()return 1 end;locations:InvalidateAvailability();assert(locations:PlayerStatus(900,statusDB).status=='available')
locations:InvalidateAvailability();combat=true;beforeStatus=statusReads
assert(locations:PlayerStatus(900,statusDB).status=='uncertain'and statusReads==beforeStatus);combat=false
assert(locations:PlayerStatus(900,nil).status=='uncertain')
print('PASS: shared status cache invalidation, class/prerequisite/reputation/spell/item reasons; no evaluation in combat; quest difficulty does not masquerade as acceptance')


RegisterGameMenuEscHandler=function()error("RUI must not register into the secure Escape chain")end
UISpecialFrames={}
AUI.isForever=true;q.mapPersistenceInstalled=nil
q:InstallMapPersistence()
assert(#UISpecialFrames==1 and UISpecialFrames[1]=="WorldMapFrame")
q.mapPersistenceInstalled=nil;q:InstallMapPersistence();assert(#UISpecialFrames==1)
print("PASS: map uses standard special-frame Escape cleanup, registers once, and leaves secure Escape handlers untouched")

-- Direction is one selected same-zone cue, positioned by HBD, with no writes.
C_Map.GetBestMapForUnit=function()return 1 end
C_Map.GetPlayerMapPosition=function()return {GetXY=function()return .2,.2 end}end
local near={questID=20,map=1,x=.3,y=.2,current=true,kind='Npc'}
assert(locations:DirectionPoint({{questID=20,map=2,x=.2,y=.2,current=true},near,{questID=20,map=1,x=.9,y=.9,current=true}})==near)
local floatEdge
pins.AddMinimapIconMap=function(_,owner,icon,map,x,y,parent,edge)floatEdge=edge end
Minimap.GetWidth=function()return 200 end;Minimap.GetHeight=function()return 200 end
locations:UpdateDirection(near);assert(floatEdge==true and locations.direction.scripts.OnClick==nil)
local arrow=locations.direction.texture
function arrow:SetAlpha(value)self.opacity=value end
function arrow:SetRotation(value)self.angle=value end
locations.direction:SetPoint('CENTER',Minimap,'CENTER',90,0)
assert(arrow.opacity==1 and math.abs(arrow.angle+math.pi/2)<.001)
locations.direction:SetPoint('CENTER',Minimap,'CENTER',0,0);assert(arrow.opacity==0)
locations:UpdateDirection(nil);assert(not locations.direction:IsShown())
C_Map.GetBestMapForUnit=function()return nil end;assert(locations:DirectionPoint({near})==nil)
print('PASS: selected objective edge direction, near-point selection, rotation, arrival hiding and unknown/cross-map fallback; no polling or map writes')
ProjectRuthlessDB.questWorkspace.enabled=true
C_QuestLog.GetNextWaypointForMap=function()return .3,.2 end
locations.points={near};locations:DrawAreas();assert(next(locations.activeWorld)==nil)
C_QuestLog.GetNextWaypointForMap=nil
locations:DrawAreas();assert(next(locations.activeWorld)==nil)
for _,pair in pairs(locations.activeMini)do assert(pair.mini.point.kind=="Accept"or pair.mini.point.kind=="Turn in")end
print('PASS: spawn dots omitted while native areas and direction remain; native quest waypoint markers take priority over supplemental world indicators')

local linked,opened;local shift=true
IsShiftKeyDown=function()return shift end
GetQuestLink=function(id)return id==20 and "|Hquest:20|h[Near]|h"end
ChatFrameUtil={InsertLink=function(link)linked=link;return false end,OpenChat=function(link)opened=link end}
assert(q:LinkQuestToChat(20)and linked==opened and linked:find("quest:20",1,true))
shift=false;linked=nil;assert(not q:LinkQuestToChat(20)and linked==nil)
shift=true;assert(not q:LinkQuestToChat(999))
print('PASS: Shift-click quest inserts a native chat link or opens a draft; ordinary click and missing links unchanged')

-- Objective symbols use recorded sources, match only live unfinished objectives,
-- and remain independent of native waypoints/blue areas.
C_QuestLog.GetQuestObjectives=function()return {{type='monster',objectID=100,finished=false},{type='object',objectID=200,finished=false},{type='item',objectID=300,finished=false}}end
local spawns=locations:Build({{id=20,title='Near'}},20)
local markers=locations:ObjectiveMarkers(spawns)
local kinds={};for _,p in ipairs(markers)do kinds[p.markerKind]=true end
assert(#markers==4 and kinds.kill and kinds.loot and kinds.interact)
locations.points=spawns;locations:DrawAreas()
assert(next(locations.activeWorld))
for _,icon in pairs(locations.activeWorld)do assert(icon.scripts.OnClick==nil and icon.point.markerKind)end
C_QuestLog.GetQuestObjectives=function()return {{type='monster',objectID=100,finished=true},{type='object',objectID=200,finished=secret},{type='item',objectID=300,finished=false}}end
markers=locations:ObjectiveMarkers(spawns);assert(#markers==2)
for _,p in ipairs(markers)do assert(p.markerKind=='loot' or p.markerKind=='interact')end
C_QuestLog.GetQuestObjectives=function()return {}end
assert(#locations:ObjectiveMarkers(spawns)==0)
local appends={};IsInGroup=function()return true end
local partyTip={AppendInfo=function(_,getter,id,omit,ignore)appends[#appends+1]={getter,id,omit,ignore}end}
locations:AddObjectTooltip(partyTip,{lines={{questID=20},{questID=20},{questID=secret},{questID=30}}})
assert(#appends==2 and appends[1][1]=='GetQuestPartyProgress'and appends[1][3]and appends[1][4])
IsInGroup=function()return false end;locations:AddPartyProgress(partyTip,{[20]=true});assert(#appends==2)
print('PASS: cog/bag/sword source markers, completed/restricted omission, passive world placement and native party tooltip append with deduplication')

local nativeSelected,nativeTracked,selectionWrites,trackingWrites=0,0,0,0
C_QuestLog.GetLogIndexForQuestID=function(id)return id==20 or id==30 end
C_QuestLog.GetSelectedQuest=function()return nativeSelected end
C_QuestLog.SetSelectedQuest=function(id)nativeSelected=id;selectionWrites=selectionWrites+1 end
C_SuperTrack.GetSuperTrackedQuestID=function()return nativeTracked end
C_SuperTrack.SetSuperTrackedQuestID=function(id)nativeTracked=id;trackingWrites=trackingWrites+1 end
q.currentQuestID=20;IsInGroup=function()return false end
q:SyncMapObjective();assert(nativeSelected==20 and nativeTracked==20)
q:SyncMapObjective();assert(selectionWrites==1 and trackingWrites==1)
combat=true;q.currentQuestID=30;q:SyncMapObjective();assert(nativeSelected==20 and q.pendingMapObjective)
combat=false;q:SyncMapObjective();assert(nativeSelected==30 and nativeTracked==30 and not q.pendingMapObjective)
q.currentQuestID=999;q:SyncMapObjective();assert(nativeSelected==30)
q.currentQuestID=secret;q:SyncMapObjective();assert(nativeSelected==30)
q.currentQuestID=20;nativeSelected=30;nativeTracked=30;q:SyncMapObjective();assert(nativeSelected==20 and nativeTracked==20)
print('PASS: current tracker objective synchronizes native selected/supertracked map quest, avoids redundant writes, omits pickups/restricted IDs and defers combat')

local savedSource=ProjectRuthlessDB.questWorkspace.guideSource
ProjectRuthlessDB.questWorkspace.guideSource='RUI';q.manualFocus=nil
assert(q:ReadGuide().phase=='GUIDE STOPPED') -- explicit stop never silently takes Wisp or restarts
assert(q:RegisterGuideProvider('test','Test guide',function()return {quest='Test',target='Hub',phase='Step',count='1',instruction='Walk',objectives={},next={}}end))
ProjectRuthlessDB.questWorkspace.guideSource='test';assert(q:ReadGuide().source=='test')
ProjectRuthlessDB.questWorkspace.guideSource='missing';assert(q:ReadGuide()==nil and q:GuideSourceLabel():find('not connected',1,true))
ProjectRuthlessDB.questWorkspace.guideSource='Wisp';local savedWisp=ForeverWispFrame;ForeverWispFrame=nil;assert(q:GuideSourceLabel():find('not running',1,true));ForeverWispFrame=savedWisp
ProjectRuthlessDB.questWorkspace.guideSource=savedSource
print('PASS: explicit default/provider choice, registered external readers, unavailable-source fallback and no silent provider replacement')

local savedMap=C_Map.GetBestMapForUnit;local savedInfo=C_Map.GetMapInfo
local savedEntries=q.entries;local savedLevel=UnitLevel;local savedFaction=UnitFactionGroup;local savedEligibility=locations.PlayerEligibility
local savedMapping=locations.mapping;local savedState=ProjectRuthlessCharDB.authoredGuide
local sourceBefore=ProjectRuthlessDB.questWorkspace.guideSource
ProjectRuthlessDB.questWorkspace.guideSource='RUI';ProjectRuthlessCharDB.authoredGuide=nil
locations.mapping={[12]=37};C_Map.GetBestMapForUnit=function()return 37 end;C_Map.GetMapInfo=function()return {name='Elwynn Forest'}end
UnitLevel=function()return 1 end;UnitFactionGroup=function()return 'Alliance'end
locations.PlayerEligibility=function(_,id)return id==7 or id==15,'Prerequisite incomplete',false end
combat=false;done={};q.entries={};q.entriesSignature='autoguide1';q.manualFocus=true
local routeGuide=q:ReadGuide();assert(routeGuide.source=='RUI'and routeGuide.route=='elwynn'and routeGuide.phase=='PICK UP'and routeGuide.id==7)
assert(routeGuide.next[1].id==15 and routeGuide.next[1].detail=='PICK UP')
q.selected=999;assert(q:ReadGuide().id==7) -- selection cannot replace active route
q.manualPickup={id=7,title='Kobold Camp Cleanup',detail='Pick up quest'};q.entries={q.manualPickup};q.entriesSignature='autoguide2'
assert(q:ReadGuide().phase=='PICK UP') -- previewing a pickup is not acceptance
q.manualPickup=nil;q.entries={{id=7,title='Kobold Camp Cleanup',complete=false}};q.entriesSignature='autoguide3'
assert(q:ReadGuide().id==15 and q:ReadGuide().phase=='PICK UP') -- gather available batch before objectives
q.entries[2]={id=15,title='Investigate Echo Ridge',complete=false};q.entriesSignature='autoguide4'
assert(q:ReadGuide().id==7 and q:ReadGuide().phase=='CURRENT OBJECTIVE')
authored:Action('pause');assert(q:ReadGuide().phase=='GUIDE PAUSED');authored:Action('stop');assert(q:ReadGuide().phase=='GUIDE STOPPED')
ProjectRuthlessCharDB.authoredGuide=nil;locations.mapping={};C_Map.GetMapInfo=function()return {name='Unsupported zone'}end
assert(q:ReadGuide().phase=='CHOOSE A GUIDE')
-- Boundary levels must enter the continuation, not restart a level 10–20 route.
local savedCompleted=C_QuestLog.IsQuestFlaggedCompleted
C_QuestLog.IsQuestFlaggedCompleted=function(id)return done[id]or false end
UnitLevel=function()return 20 end;UnitFactionGroup=function()return 'Horde'end
locations.mapping={[17]=10};C_Map.GetBestMapForUnit=function()return 10 end
C_Map.GetMapInfo=function()return {name='The Barrens'}end
q.entries={};q.entriesSignature='barrens20';ProjectRuthlessCharDB.authoredGuide=nil
assert(q:ReadGuide().route=='barrens-horde-20')
-- An existing saved route/chapter/skip set stays deliberately selected.
local remembered={route='barrens',chapter=2,skipped={[843]=true},revision=7}
ProjectRuthlessCharDB.authoredGuide=remembered;authored:EnsureStarted(q)
assert(ProjectRuthlessCharDB.authoredGuide==remembered and remembered.route=='barrens'and remembered.chapter==2 and remembered.skipped[843])
-- Sparse visits do not silently become the user's main leveling route.
UnitFactionGroup=function()return 'Alliance'end;UnitLevel=function()return 28 end
locations.mapping={[267]=20};C_Map.GetBestMapForUnit=function()return 20 end
C_Map.GetMapInfo=function()return {name='Hillsbrad Foothills'}end
ProjectRuthlessCharDB.authoredGuide=nil;q.entriesSignature='southshore-detour'
assert(q:ReadGuide().phase=='CHOOSE A GUIDE')
assert(authored:Start('hillsbrad-alliance-30'))
locations.PlayerEligibility=function()return true,nil,false end
assert(q:ReadGuide().id==536 and q:ReadGuide().phase=='PICK UP')
q.entries={{id=536,title='Down the Coast',complete=false,detail='1/10 Torn Fin Tidehunters'}};q.entriesSignature='southshore-progress'
assert(q:ReadGuide().phase=='CURRENT OBJECTIVE')
q.entries={};done[536]=true;q.entriesSignature='southshore-complete'
assert(q:ReadGuide().phase=='ROUTE COMPLETE')
authored:RenderBrowser(q,'Library')
local labelled=false;for _,row in ipairs(authored.rows)do if row.text and row.text:find('Optional detour',1,true)then labelled=true end end
assert(labelled,'Library must distinguish short detours from leveling routes')
C_QuestLog.IsQuestFlaggedCompleted=savedCompleted
q.entries=savedEntries;UnitLevel=savedLevel;UnitFactionGroup=savedFaction;locations.PlayerEligibility=savedEligibility;locations.mapping=savedMapping
C_Map.GetBestMapForUnit=savedMap;C_Map.GetMapInfo=savedInfo;ProjectRuthlessCharDB.authoredGuide=savedState;ProjectRuthlessDB.questWorkspace.guideSource=sourceBefore;q.manualFocus=nil
print('PASS: RUI supported-zone auto start, ordered pickups and objectives independent of selection, pickup preview isolation, explicit pause/stop and unsupported-zone route prompt')

-- A previously disabled native master switch must recover from the visible RUI option.
assert(load(MAP_SETTINGS_SOURCE))('ProjectRuthless',AUI)
local mapSettings=AUI.modules.MapQuests
local savedCVar=SetCVar;local cv={questPOI='0'}
SetCVar=function(key,value)cv[key]=value end
ProjectRuthlessDB.mapQuests={enabled=true,showLocalStories=true,showTrivial=true,showAccountCompleted=false}
mapSettings:ApplySettings();assert(cv.questPOI=='1'and cv.questPOILocalStory=='1')
combat=true;ProjectRuthlessDB.mapQuests.enabled=false;mapSettings:ApplySettings()
assert(cv.questPOI=='1'and mapSettings.pendingApply)
combat=false;mapSettings:ApplySettings();assert(cv.questPOI=='0'and not mapSettings.pendingApply)
ProjectRuthlessDB.mapQuests.enabled=true;mapSettings:ApplySettings();assert(cv.questPOI=='1')
SetCVar=savedCVar
print('PASS: native quest marker master switch recovers from saved Off, follows the RUI option, and defers combat writes')
