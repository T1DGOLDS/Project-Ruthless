local AUI={modules={},isForever=true}
function AUI:RegisterModule(name,module)self.modules[name]=module end
local secret={};function issecretvalue(value)return value==secret end
local combat=false;function InCombatLockdown()return combat end
local race,class,level=1,9,15;local faction="Alliance"
function UnitRace()return "Human","Human",race end
function UnitClass()return "Warlock","WARLOCK",class end
function UnitFactionGroup()return faction end
function UnitLevel()return level end
local held,done={},{};local stateReads=0
C_QuestLog={IsOnQuest=function(id)stateReads=stateReads+1;return held[id]or false end,IsQuestFlaggedCompleted=function(id)stateReads=stateReads+1;return done[id]or false end,IsQuestTrivial=function()return false end}
local map,playerMap=1436,1429
C_Map={GetBestMapForUnit=function()return playerMap end,GetMapChildrenInfo=function(id)if id==1415 then return {{mapID=1436},{mapID=1429}}end;return {}end}
WorldMapFrame={IsShown=function()return true end,GetMapID=function()return map end}
C_QuestLine={GetAvailableQuestLines=function()return {}end,GetQuestLineInfo=function()error("Must not ask Blizzard to confirm every catalogue ID")end}
ProjectRuthlessDB={questWorkspace={enabled=true},mapQuests={enabled=true,showTrivial=true}}
local poison=setmetatable({},{__index=function()error("External addon dependency")end})
LibQuestieDB=poison;LibStub=function()error("External library dependency")end
assert(load(LOCATIONS_SOURCE))("ProjectRuthless",AUI)
assert(load(PICKUP_DATA_SOURCE))("ProjectRuthless",AUI)
assert(load(AVAILABILITY_SOURCE))("ProjectRuthless",AUI)
assert(load(DATA_SOURCE))("ProjectRuthless",AUI)
local p=AUI.modules.QuestAvailability;local d=AUI.modules.QuestData
assert(not AUI.modules.QuestPickupData.data,"Catalogue must not allocate on file load")
local offers=d:Offers();local ids={};for _,row in ipairs(offers)do ids[row.id]=row end
assert(ids[9]and ids[22]and ids[36]and ids[151],"Westfall pickups must appear even when native offer API returns nothing")
assert(ids[22].sites[1][1]==1436 and ids[22].sites[1][4]=="Salma Saldean")
local points=d:Points({},999);local present={};for _,point in ipairs(points)do present[point.questID]=true end
assert(present[9]and present[22]and present[151],"All pickups draw with no guide, no accepted quests and unrelated selection")
local discovered=d.nativeOffers;d.nativeOffers={}
local direct=d:Points({{id=22,title="Goretusk Liver Pie",accept=true}},22)
assert(#direct==1 and direct[1].map==1436 and direct[1].current,"An explicit pickup can resolve its recorded giver before the first offer refresh")
d.nativeOffers=discovered
local before=stateReads;d:Offers();assert(stateReads==before,"Unchanged map refresh must reuse eligibility results")
assert(#p:Browse(1436,"goretusk")>=1 and p:Browse(1436,"22")[1].id==22)
local byGiver=p:Browse(1436,"salma");assert(#byGiver>=1)
done[22]=true;held[9]=true;d:InvalidateOffers();offers=d:Offers();ids={};for _,row in ipairs(offers)do ids[row.id]=true end
assert(not ids[22]and not ids[9]and ids[151],"Completed and accepted quests disappear while unrelated pickups remain")
done={};held={};race=95;d:InvalidateOffers();assert(p:Status(22).status=="available","Alliance Skyborne uses bit 32, not raceID-1")
race=96;faction="Horde";d:InvalidateOffers();assert(p:Status(22).status=="locked")
race=1;faction="Alliance";level=8;d:InvalidateOffers();assert(p:Status(22).status=="locked");assert(p:Status(9).status=="available")
level=15;d:InvalidateOffers()
local data=p:Data()
data.quests[999001]={name="Fixture",requiredLevel=1,requiredClasses=1,sites={}}
assert(p:Status(999001).status=="locked")
data.quests[999001].requiredClasses=nil;data.quests[999001].preQuestGroup={1,2};p:Invalidate();done[1]=true
assert(p:Status(999001).status=="locked");done[2]=true;p:Invalidate();assert(p:Status(999001).status=="available")
data.quests[999001].preQuestGroup=nil;data.quests[999001].preQuestSingle={3,4};p:Invalidate();assert(p:Status(999001).status=="locked")
done[4]=true;p:Invalidate();assert(p:Status(999001).status=="available")
data.quests[999001].exclusiveTo={5};held[5]=true;p:Invalidate();assert(p:Status(999001).status=="locked")
data.quests[999001].preQuestSingle=nil;data.quests[999001].preQuestGroup={-4};data.quests[999001].exclusiveTo=nil
p:Invalidate();assert(p:Status(999001).status=="available","Negative grouped prerequisite requires completion of its absolute ID")
done[4]=nil;p:Invalidate();assert(p:Status(999001).status=="locked")
data.quests[999004]={name="Alternative",exclusiveTo={6},sites={}}
data.quests[999001].preQuestGroup={999004};done[6]=true;p:Invalidate();assert(p:Status(999001).status=="available")
data.quests[999001].preQuestGroup=nil;data.quests[999004]=nil
held={};data.quests[999001].exclusiveTo=nil;data.quests[999001].requiredMinRep={72,3000};p:Invalidate()
C_Reputation={GetFactionDataByID=function()return {currentStanding=2999}end};assert(p:Status(999001).status=="locked")
C_Reputation.GetFactionDataByID=function()return {currentStanding=3000}end;p:Invalidate();assert(p:Status(999001).status=="available")
data.quests[999001].requiredMinRep=nil;data.quests[999001].specialFlags=1;p:Invalidate();assert(p:Status(999001).status=="available","Repeatable flag alone is not a missing eligibility rule")
data.quests[999001].zoneOrSort=-21;p:Invalidate();assert(p:Status(999001).status=="uncertain","Inactive seasonal quests must not be asserted available from spawn records alone")
data.quests[999001].zoneOrSort=nil
held[999001]=secret;p:Invalidate();assert(p:Status(999001).status=="uncertain");held={}
combat=true;p:Invalidate();assert(p:Status(22).status=="uncertain");combat=false
data.quests[999001]=nil
map=1415;d:InvalidateOffers();offers=d:Offers();ids={};for _,row in ipairs(offers)do ids[row.id]=true end
assert(ids[22],"Browsing a continent must include child-zone pickups")
-- Faction-dependent quest givers must not leak through the union map index.
data.quests[999002]={name="Faction giver",requiredLevel=1,sites={{1436,.5,.5,"Alliance giver"}}}
data.dynamic.Horde[999002]={name="Faction giver",requiredLevel=1,sites={{1458,.5,.5,"Horde giver"}}}
data.byMap[1436][#data.byMap[1436]+1]=999002
faction="Horde";race=96;p:Invalidate();assert(#p:Browse(1436,"999002")==0)
faction="Alliance";race=1;p:Invalidate();assert(#p:Browse(1436,"999002")==1)
data.quests[999002]=nil;data.dynamic.Horde[999002]=nil;table.remove(data.byMap[1436])
-- Native offers supplement unknown metadata and override recorded restrictions.
map=1436
C_QuestLine.GetAvailableQuestLines=function()return {{questID=999003,questName="New native pickup",startMapID=1436,x=.4,y=.5}}end
d:Offers();local nativeRows=p:Browse(1436,"New native pickup");assert(#nativeRows==1 and nativeRows[1].id==999003)
C_QuestLine.GetAvailableQuestLines=function()return {}end;d:Offers()
-- Exercise the real Available page: multi-character search retains keyboard focus,
-- button pools reuse, narrow/large panels reflow, clicks follow a pickup, and leaving
-- the page clears search focus. Frame mocks do not claim live rendering proof.
local created=0
local function frame()
 created=created+1;local f={scripts={},shown=true,width=300,text="",focus=true}
 function f:SetScript(key,fn)self.scripts[key]=fn end
 function f:Show()self.shown=true end;function f:Hide()self.shown=false;self.focus=false end
 function f:ClearFocus()self.focus=false end
 function f:ClearAllPoints()end;function f:SetPoint()end
 function f:SetSize(w,h)self.width=w;self.height=h end
 function f:SetHeight(h)self.height=h end;function f:GetWidth()return self.width end
 function f:SetText(v)self.text=v end;function f:GetText()return self.text end
 function f:SetVerticalScroll(v)self.scroll=v end
 function f:SetAutoFocus()end;function f:SetFontObject()end
 return f
end
CreateFrame=frame;function AUI:CreateButton()return frame()end
local q={mapPanel=frame(),mapCopy=frame(),mapHeading=frame(),mapScroll=frame(),mapContent=frame(),mapControls={frame()}}
function q:LinkQuestToChat()return false end;function q:Refresh()self.refreshed=true end
local locations=AUI.modules.QuestLocations;local refresh=locations.Refresh;locations.Refresh=function()end
p.query="goretusk";p:Render(q);assert(p.search.shown and p.buttons[1].shown)
p.search.text="goretusk liver";p.search.focus=true;p.search.scripts.OnTextChanged(p.search,true)
assert(p.query=="goretusk liver"and p.search.focus,"Typing must not hide/recreate the search field")
local count=created;p:Render(q);assert(created==count,"Unchanged search must reuse frames")
q.mapContent.width=400;p:Render(q);assert(p.buttons[1].width==400)
p.buttons[1].scripts.OnClick();assert(q.manualPickup.id==22 and q.manualPickup.accept and q.manualTrackedQuest==22 and q.refreshed)
p:HideBrowser();assert(not p.search.shown and not p.search.focus and not p.buttons[1].shown)
locations.Refresh=refresh
print("PASS: real Westfall pickups without native offers, selection or guide; completed/accepted/level/class/race/prerequisite/exclusivity/reputation/repeatable/secret/combat filtering; cross-zone browsing/search; cached refresh")
print("PASS: faction-specific giver locations, native-only pickups, real Available page search/focus/reuse/resizing/follow and cleanup")
