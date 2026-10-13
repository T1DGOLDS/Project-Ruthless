unpack=table.unpack
local timers={}
C_Timer={After=function(_,fn)timers[#timers+1]=fn end}
local function flush()local pending=timers;timers={};for _,fn in ipairs(pending)do fn()end end
local frames=0
local Frame={};Frame.__index=Frame
function Frame:SetScript(k,v)self.scripts[k]=v end
function Frame:GetScript(k)return self.scripts[k]end
function Frame:HookScript(k,v)local old=self.scripts[k];self.scripts[k]=function(...)if old then old(...)end;v(...)end end
function Frame:Fire(k,...)if self.scripts[k]then self.scripts[k](self,...)end end
function Frame:SetShown(v)local changed=self.shown~=v;self.shown=v;if changed then self:Fire(v and 'OnShow'or 'OnHide')end end
function Frame:Show()self:SetShown(true)end
function Frame:Hide()self:SetShown(false)end
function Frame:IsShown()return self.shown end
function Frame:IsVisible()return self.shown and (not self.parent or self.parent:IsVisible())end
function Frame:RegisterEvent(e)self.events[e]=true end
function Frame:RegisterUnitEvent(e,u)self.events[e]=u end
function Frame:UnregisterEvent(e)self.events[e]=nil end
function Frame:UnregisterAllEvents()self.events={}end
function Frame:SetSize(w,h)self.w=w;self.h=h;self:Fire('OnSizeChanged',w,h)end
function Frame:SetWidth(w)self.w=w end
function Frame:SetHeight(h)self.h=h end
function Frame:GetWidth()return self.w end
function Frame:GetHeight()return self.h end
function Frame:SetScrollChild(child)self.child=child end
function Frame:GetScrollChild()return self.child end
function Frame:GetVerticalScrollRange()return math.max(0,(self.child and self.child.h or 0)-self.h)end
function Frame:GetVerticalScroll()return self.offset end
function Frame:SetVerticalScroll(v)self.offset=v;self:Fire('OnVerticalScroll',v)end
function Frame:SetText(v)self.text=v end
function Frame:GetText()return self.text end
function Frame:GetName()return self.name end
function Frame:SetAlpha(v)self.alpha=v end
function Frame:GetTop()return 100 end
function Frame:GetEffectiveScale()return 1 end
function Frame:GetFrameLevel()return 1 end
function Frame:CreateFontString()return CreateFrame('FontString',nil,self)end
function Frame:CreateTexture()return CreateFrame('Texture',nil,self)end
for _,name in ipairs({'SetBackdrop','SetBackdropColor','SetBackdropBorderColor','SetPoint','ClearAllPoints','EnableMouseWheel','EnableMouse','RegisterForDrag','RegisterForClicks','SetTextColor','SetFontString','SetVertexColor','SetTexture','SetBlendMode','SetFrameLevel','SetFrameStrata','SetAutoFocus','SetMaxLetters','SetAllPoints','SetColorTexture','SetUnit','SetPortraitZoom','SetSheathed','SetFacing','SetPosition','SetCamDistanceScale','SetScale','SetClampedToScreen','SetMovable','SetID','SetAtlas','Raise'})do Frame[name]=function()end end
function CreateFrame(kind,name,parent)frames=frames+1;return setmetatable({kind=kind,name=name,parent=parent,scripts={},events={},shown=true,w=100,h=100,offset=0,text=''},Frame)end
UIParent=CreateFrame('Frame');UISpecialFrames={};SlashCmdList={};tinsert=table.insert
C_AddOns={GetAddOnMetadata=function()return 'test'end};RAID_CLASS_COLORS={WARRIOR={r=1,g=.5,b=.2}}
function UnitClass()return 'Warrior','WARRIOR',1 end
function UnitRace()return 'Human','Human',1 end
function time()return 123 end
function UnitName()return 'Tester'end
function InCombatLockdown()return false end
function GetCursorPosition()return 10,20 end
function strtrim(v)return (v or ''):match('^%s*(.-)%s*$')end
function hooksecurefunc(...)end
local AUI={};assert(load(CORE_SOURCE))('ProjectRuthless',AUI)
ProjectRuthlessDB={general={windowScale=1,windowOpacity=1},spellbook={showOffSpec=true,pinnedSpells={},state={scroll={}}},questWorkspace={enabled=false},lowHealthGlow={enabled=false,threshold=.3,maxAlpha=.4},titles={favorites={},knownAtInstall={},firstSeen={}},elvui={}}
ProjectRuthlessCharDB={}
local view=CreateFrame('Frame');local owner={frame=view,calls=0,Refresh=function(self)self.calls=self.calls+1 end}
for i=1,100 do AUI:QueueRefresh(owner)end
assert(#timers==1);flush();assert(owner.calls==1)
AUI:QueueRefresh(owner);view:Hide();flush();assert(owner.calls==1)
view:Show();AUI:QueueRefresh(owner);flush();assert(owner.calls==2)
local parent=CreateFrame('Frame');parent:Hide();local child=CreateFrame('Frame',nil,parent)
local subscription=CreateFrame('Frame');AUI:BindVisibleEvents(child,subscription,{'UNIT_STATS','PLAYER_REGEN_ENABLED'})
assert(next(subscription.events)==nil)
parent:Show();child:Fire('OnShow');assert(subscription.events.UNIT_STATS=='player')
child:Hide();assert(next(subscription.events)==nil)
print('PASS: 100-event burst becomes one refresh; hidden/hidden-parent callbacks skip work; visible-only events unregister and reopen')
local scroll=AUI:CreateSmoothScrollFrame(UIParent);scroll:SetSize(100,100);local content=CreateFrame('Frame');content:SetHeight(500);scroll:SetScrollChild(content)
assert(scroll:GetScript('OnUpdate')==nil)
scroll:Fire('OnMouseWheel',-3);assert(scroll:GetScript('OnUpdate'))
for i=1,100 do if scroll:GetScript('OnUpdate')then scroll:Fire('OnUpdate',.1)end end
assert(scroll:GetScript('OnUpdate')==nil and math.abs(scroll:GetVerticalScroll()-90)<.1)
scroll:ScrollTo(200,false);assert(scroll:GetScript('OnUpdate'));scroll:Hide();assert(scroll:GetScript('OnUpdate')==nil)
scroll:Show();assert(scroll:GetScript('OnUpdate')==nil and scroll:GetVerticalScroll()==200)
print('PASS: smooth scroll has no idle handler, converges, stops on hide and restores on reopen')
assert(load(CHARACTERV2_SOURCE))('ProjectRuthless',AUI)
local character=AUI.modules.Character;local model=CreateFrame('PlayerModel');character:ConfigureModel(model)
assert(model:GetScript('OnUpdate')==nil);model:Fire('OnMouseDown','LeftButton');assert(model:GetScript('OnUpdate'));model:Fire('OnMouseUp','LeftButton');assert(model:GetScript('OnUpdate')==nil)
model:Fire('OnMouseDown','RightButton');model:Hide();assert(model:GetScript('OnUpdate')==nil)
character:OnPlayerLogin();assert(character.events.events.UNIT_STATS==nil and not character.panel)
print('PASS: character model only polls during dragging; unopened character UI has no display events')
assert(load(SPELLBOOK_SOURCE))('ProjectRuthless',AUI)
local book=AUI.modules.Spellbook
Enum={SpellBookSkillLineIndex={General=1,Class=2,MainSpec=3},SpellBookSpellBank={Player=1}}
C_SpellBook={GetNumSpellBookSkillLines=function()return 3 end}
do
 local wasForever=AUI.isForever;AUI.isForever=true
 ProjectRuthlessCharDB=ProjectRuthlessCharDB or {}
 Enum.SpellBookItemType={Spell=1,FutureSpell=2,Flyout=3}
 C_SpellBook.GetSpellBookSkillLineInfo=function()return {name='Class',numSpellBookItems=2,itemIndexOffset=0}end
 C_SpellBook.GetSpellBookItemInfo=function(slot)return {name=slot==1 and 'Known'or 'Future',spellID=slot,itemType=slot==1 and 1 or 2}end
 C_SpellBook.GetSpellBookItemName=function(slot)return slot==1 and 'Known'or 'Future',slot==1 and 'Rank 1'or 'Rank 2'end
 C_SpellBook.GetSpellBookItemLevelLearned=function(slot)return slot==1 and 1 or 20 end
 local groups={};book:AddSkillLine(groups,2);assert(#groups[1].items==2)
 local future=groups[1].items[2];assert(future.future and future.rank=='Rank 2'and future.requiredLevel==20)
 assert(book:SpellDetail(future):find('Cost unknown',1,true))
 GetNumTrainerServices=function()return 21 end
 local reads=0;GetTrainerServiceInfo=function(i)reads=reads+1;return i==21 and 'Future'or 'Other','unavailable',1,20,'Rank 2'end
 GetTrainerServiceCost=function()return 12500 end
 book:CaptureTrainingPrices();assert(reads==0);flush();assert(reads==20);flush();assert(reads==21)
 book:TrainingMetadata(future);assert(book:SpellDetail(future)=='Rank 2 · Level 20 · 1g 25s 0c')
 book.spellFilter='missing';assert(not book:MatchesSpellFilter(future));book.spellFilter=nil
 book:CaptureTrainingPrices();book.trainingRevision=book.trainingRevision+1;local before=reads;flush();assert(reads==before)
 book.mode='class';book.groupCache=nil
 local catalog=book:GetGroups();local extra=catalog[#catalog]
 assert(extra.items[1].name=='Other'and extra.items[1].requiredLevel==20 and extra.items[1].trainingCost==12500 and #extra.items==1)
 -- Reproduce a pre-offer-cache character: old prices alone must become visible.
 local priceCache=ProjectRuthlessCharDB.trainingPrices
 ProjectRuthlessCharDB.trainingPrices={['Known\031Rank 1']={cost=1},['Known\031Rank 0']={cost=2},['Recovered\031Rank 3']={cost=7000}}
 book.groupCache=nil;catalog=book:GetGroups();extra=catalog[#catalog]
 local recovered;for _,item in ipairs(extra.items)do assert(item.name~='Known');if item.name=='Recovered'then recovered=item end end
 assert(recovered and recovered.legacyTraining and recovered.requiredLevel==nil and recovered.trainingCost==7000)
 book.spellFilter='future';assert(book:MatchesSpellFilter(recovered)and not book:MatchesSpellFilter({future=false}));book.spellFilter=nil
 ProjectRuthlessCharDB.trainingPrices=priceCache
 -- Native per-level skills work before a trainer visit, in paced batches and once.
 local oldSpell=C_Spell;local levelReads=0;C_Spell={GetSpellInfo=function()return {name='Native next',iconID=9}end,GetSpellSubtext=function()return 'Rank 4'end}
 C_SpellBook.GetCurrentLevelSpells=function(level)levelReads=levelReads+1;return level==30 and {900}or {}end
 book.futureSkills=nil;book:RequestFutureSkills();assert(levelReads==0);flush();assert(levelReads==20);flush();assert(levelReads==40);flush();assert(levelReads==60 and #book.futureSkills==1)
 book:RequestFutureSkills();assert(levelReads==60)
 book.groupCache=nil;catalog=book:GetGroups();local nativeNext
 for _,group in ipairs(catalog)do for _,item in ipairs(group.items)do if item.name=='Native next'then nativeNext=item end end end
 assert(nativeNext and nativeNext.requiredLevel==30 and nativeNext.trainingCost==nil)
 C_SpellBook.GetCurrentLevelSpells=nil;C_Spell=oldSpell;book.futureSkills=nil;book.groupCache=nil
 -- Missing price metadata must not erase an otherwise valid future offer.
 GetNumTrainerServices=function()return 1 end
 GetTrainerServiceInfo=function()return 'Costless','unavailable',7,40,'Rank 1'end
 GetTrainerServiceCost=function()return nil end
 book:CaptureTrainingPrices();flush();assert(ProjectRuthlessCharDB.trainingOffers['Costless\031Rank 1'].requiredLevel==40)
 assert(ProjectRuthlessCharDB.trainingOffers['Costless\031Rank 1'].trainingCost==nil)
 -- Future ranks stay in their native spec; levels precede names, unknowns last.
 local savedDB=ProjectRuthlessCharDB
 ProjectRuthlessCharDB={trainingOffers={
  ['Rend\031Rank 3']={name='Rend',rank='Rank 3',future=true,trainingCost=100},
  ['Block\031Rank 2']={name='Block',rank='Rank 2',future=true,requiredLevel=18},
  ['Unmapped\031Rank 1']={name='Unmapped',rank='Rank 1',future=true},
 },trainingPrices={['Rend\031Rank 4']={cost=200}}}
 book.futureSkills={{name='Rend',rank='Rank 3',spellID=300,requiredLevel=24,future=true},
  {name='Rend',rank='Rank 4',spellID=400,requiredLevel=36,future=true}}
 local ordered={{name='Arms',items={{name='Rend',rank='Rank 2',requiredLevel=10},
  {name='Alpha',requiredLevel=20},{name='Early',requiredLevel=1}}},
  {name='Protection',items={{name='Block',rank='Rank 1',requiredLevel=8}}}}
 book:FutureTraining(ordered)
 assert(#ordered==3 and ordered[1].name=='Arms'and ordered[2].name=='Protection')
 assert(ordered[1].items[1].name=='Early'and ordered[1].items[2].name=='Rend'and ordered[1].items[3].name=='Alpha')
 assert(ordered[1].items[4].requiredLevel==24 and ordered[1].items[4].trainingCost==100)
 assert(ordered[1].items[5].requiredLevel==36 and ordered[1].items[5].trainingCost==200)
 assert(ordered[2].items[2].name=='Block'and ordered[2].items[2].requiredLevel==18)
 assert(ordered[3].items[1].name=='Unmapped'and ordered[3].items[1].requiredLevel==nil)
 -- Spec observations persist, and exact-rank native level lookup enriches records.
 C_Spell={GetSpellInfo=function()return {spellID=500,iconID=5}end,
  GetSpellSubtext=function()return 'Rank 5'end,GetSpellLevelLearned=function(id)assert(id==500);return 48 end}
 ProjectRuthlessCharDB.trainingOffers={};ProjectRuthlessCharDB.trainingPrices={['Rend\031Rank 5']={cost=300},['Rend\031Rank 6']={cost=400}}
 book.futureSkills={};local restored={};book:FutureTraining(restored)
 assert(restored[1].name=='Arms'and restored[1].items[1].requiredLevel==48)
 assert(restored[1].items[2].requiredLevel==nil) -- Different rank must not inherit 48.
 C_Spell=oldSpell;ProjectRuthlessCharDB=savedDB;book.futureSkills=nil;book.groupCache=nil
 print('PASS: spec groups merge learned/future ranks in level order, preserve prices, retain unknowns and reject wrong-rank levels')
 local oldToggle,oldShow=book.Toggle,book.Show
 book.Toggle=function()return 'rui-toggle'end;book.Show=function()return 'rui-show'end
 local native=0
 PlayerSpellsUtil={FrameTabs={SpellBook=1,ClassTalents=2},ToggleSpellBookFrame=function()native=native+1 end,TogglePlayerSpellsFrame=function()native=native+1 end,OpenToSpellBookTab=function()native=native+1 end}
 ProjectRuthlessDB.spellbook.separateFromTalents=false
 book:InstallPlayerSpellsRedirects()
 assert(PlayerSpellsUtil.ToggleSpellBookFrame()=='rui-toggle')
 assert(PlayerSpellsUtil.TogglePlayerSpellsFrame(1)=='rui-toggle')
 local beforeCombat=InCombatLockdown;InCombatLockdown=function()return true end
 assert(PlayerSpellsUtil.ToggleSpellBookFrame()=='rui-toggle'and PlayerSpellsUtil.TogglePlayerSpellsFrame(1)=='rui-toggle')
 InCombatLockdown=beforeCombat
 PlayerSpellsUtil.TogglePlayerSpellsFrame(2);assert(native==1)
 book.Toggle=oldToggle;book.Show=oldShow;book.groupCache=nil
 AUI.isForever=wasForever
 print('PASS: future spells retain rank/level, honest unknown prices, persistent trainer cost, 20-row batches, cancellation and exclusion from missing-bar filter')
end
local scans=0
book.AddSkillLine=function(_,groups,index)scans=scans+1;groups[#groups+1]={name='Group',items={{spellID=index,name='Spell'}}}end
book.mode='class';book:GetGroups();local initial=scans
for i=1,50 do book:GetGroups()end;assert(scans==initial)
ProjectRuthlessDB.spellbook.pinnedSpells['2']=true;assert(book:GetGroups()[1].pinnedGroup)
ProjectRuthlessDB.spellbook.pinnedSpells['2']=nil;assert(not book:GetGroups()[1].pinnedGroup)
ProjectRuthlessDB.spellbook.showOffSpec=false;book:GetGroups();assert(scans>initial)
local barQueries=0;C_ActionBar={FindSpellActionButtons=function()barQueries=barQueries+1;return {}end}
for i=1,50 do assert(book:GetActionBarState(2)==false)end;assert(barQueries==1)
book.InstallMicroButton=function()end;book.InstallPlayerSpellsRedirects=function()end;book.SeparateFromTalents=function()end
book.frame=CreateFrame('Frame');book.frame:Hide();book:OnPlayerLogin();assert(book.events.events.ACTIONBAR_SLOT_CHANGED==nil)
book.events:Fire('OnEvent','SPELLS_CHANGED');assert(book.groupCache==nil and next(book.actionBarState)==nil)
book.frame:Show();assert(book.events.events.ACTIONBAR_SLOT_CHANGED)
local refreshes=0;book.Refresh=function()refreshes=refreshes+1 end
for i=1,100 do book.events:Fire('OnEvent','ACTIONBAR_SLOT_CHANGED')end
flush();assert(refreshes==1)
book.frame:Hide();assert(book.events.events.ACTIONBAR_SLOT_CHANGED==nil)
print('PASS: spell groups reuse data; pins/settings/spell events invalidate correctly; false action-bar results cache; visible event bursts coalesce')
assert(load(LOWHEALTHGLOW_SOURCE))('ProjectRuthless',AUI)
local glow=AUI.modules.LowHealthGlow;local before=frames;glow:OnPlayerLogin();assert(not glow.frame and frames==before)
local curves=0
C_CurveUtil={CreateCurve=function()curves=curves+1;return {SetType=function()end,AddPoint=function()end}end};Enum.LuaCurveType={Linear=1}
function UnitIsDeadOrGhost()return false end
function UnitHealthPercent()return .1 end
ProjectRuthlessDB.lowHealthGlow.enabled=true;glow:ApplySettings();assert(glow.frame.events.UNIT_HEALTH=='player')
glow:ApplySettings();assert(curves==1)
ProjectRuthlessDB.lowHealthGlow.threshold=.4;glow:ApplySettings();assert(curves==2)
ProjectRuthlessDB.lowHealthGlow.enabled=false;glow:ApplySettings();assert(next(glow.frame.events)==nil and glow.frame.alpha==0)
print('PASS: disabled glow creates no frame/texture/curve; enabling binds player events and disabling removes them')
assert(load(QUESTWORKSPACE_SOURCE))('ProjectRuthless',AUI);assert(load(QUESTLOCATIONS_SOURCE))('ProjectRuthless',AUI)
local q=AUI.modules.QuestWorkspace;local locations=AUI.modules.QuestLocations;q:OnPlayerLogin();locations:OnPlayerLogin()
assert(not q.frame and not q.mapPanel and next(q.events.events)==nil and next(locations.events.events)==nil)
local reads=0;LibQuestieDB={RequireContract=function()reads=reads+1;return true end};locations:ScanOffers();assert(reads==0)
print('PASS: disabled quest workspace creates no tracker/map assets, registers no quest/location events and performs no database scan')
assert(load(MENU_SOURCE))('ProjectRuthless',AUI)
local menu=AUI.modules.Menu;menu:Create();assert(next(menu.panels)==nil)
local realProfileBuilder=menu.CreateProfilesPanel
local built={};for id,method in pairs(menu.pageBuilders)do menu[method]=function(self,parent)built[id]=(built[id]or 0)+1;self.panels[id]=CreateFrame('Frame',nil,parent)end end
menu:SelectTab('general');menu:SelectTab('general');menu:SelectTab('health')
assert(built.general==1 and built.health==1 and built.errors==nil and built.spellbook==nil)
print('PASS: settings shell builds no pages; selected pages build once; unused pages remain unallocated')
assert(load(TITLES_SOURCE))('ProjectRuthless',AUI)
local titles=AUI.modules.Titles;local titleReads=0
function GetNumTitles()return 2 end
function IsTitleKnown()titleReads=titleReads+1;return true end
function GetTitleName(id)return id==1 and '%s the Tester'or '%s the Second'end
local first=titles:GetEarnedTitles('');local reads=titleReads;for i=1,20 do titles:GetEarnedTitles('tester')end;assert(titleReads==reads)
assert(#titles:GetEarnedTitles('tester')==2)
titles:ScanForNewTitles();titles:GetEarnedTitles('');assert(titleReads>reads)
print('PASS: title search uses cached known names and invalidates when learned titles change')

-- Cancellation never lets an old scan clear a newer scan's state.
timers={}
function UnitLevel()return 10 end
C_QuestLog={IsOnQuest=function()return false end,IsQuestFlaggedCompleted=function()return false end}
local ids={};for i=1,101 do ids[i]=i end
local highest,allReads=0,0
LibQuestieDB={RequireContract=function()return true end,Quest={GetAllIds=function()allReads=allReads+1;return ids end,Get=function(id,key)highest=math.max(highest,id);if key=="requiredLevel"then return 1 elseif key=="questLevel"then return 10 elseif key=="name"then return "Quest "..id end end}}
locations.Refresh=function()end
ProjectRuthlessDB.questWorkspace.enabled=true;locations.enabled=true
locations:ScanOffers();assert(highest==25 and #timers==1)
local obsolete=timers[1];timers={}
ProjectRuthlessDB.questWorkspace.enabled=false;locations:SetEnabled()
ProjectRuthlessDB.questWorkspace.enabled=true;locations:SetEnabled();timers={}
locations:ScanOffers();obsolete();assert(locations.scanning)
for i=1,8 do flush()end
assert(#locations.offers==101 and #locations.offerCandidates==101 and not locations.scanning)
local firstAllReads=allReads;locations:ScanOffers();for i=1,8 do flush()end;assert(allReads==firstAllReads)
print('PASS: offer discovery yields after 25 quests, cancelled work cannot clear a new scan, cached candidates avoid repeated full-ID fetches')
local savedCombat=InCombatLockdown;local savedAfter=C_Timer.After;local busy=false;local delays={}
InCombatLockdown=function()return busy end
C_Timer.After=function(delay,fn)delays[#delays+1]=delay;timers[#timers+1]=fn end
timers={};locations:ScanOffers();local highestBefore=highest;busy=true;flush()
assert(not locations.scanning and locations.scanPending and highest==highestBefore and #timers==0)
locations:ScanOffers();assert(#timers==0 and highest==highestBefore)
locations.events:Fire('OnEvent','PLAYER_REGEN_DISABLED');busy=false
locations.events:Fire('OnEvent','PLAYER_REGEN_ENABLED');assert(delays[#delays]==3 and locations.scanResting)
locations:ScanOffers();assert(not locations.scanning)
flush();assert(locations.scanning and not locations.scanResting)
for i=1,8 do flush()end;assert(not locations.scanning)
locations.hasSourceRequirements=nil;timers={};locations.events:Fire('OnEvent','BAG_UPDATE_DELAYED');assert(#timers==0)
local clock=0;debugprofilestop=function()clock=clock+3;return clock end
timers={};locations:ScanOffers();assert(locations.scanning and #timers==1)
debugprofilestop=nil;for i=1,8 do flush()end
InCombatLockdown=savedCombat;C_Timer.After=savedAfter
print('PASS: scans suspend in combat with no polling, wait three seconds on exit, resume in paced batches; ordinary loot does not scan; time budget yields')

if BASELINE_UPDATE_SOURCE then
    local function cadence(source)
        local counts={navigation=0,guide=0,context=0,pins=0}
        local guide={target="Target",quest="Quest",phase="Objectives",count="1 / 3",instruction="Do the quest",objectives={"Item 0/1"},next={}}
        local target={guide=guide,ReadGuide=function()counts.guide=counts.guide+1;return guide end,Navigate=function()counts.navigation=counts.navigation+1 end,RenderGuide=function()end,RefreshPins=function()counts.pins=counts.pins+1 end,RenderContext=function()counts.context=counts.context+1 end,Refresh=function()error("unexpected full refresh")end}
        local frame=CreateFrame("Frame")
        local tickers={}
        local runtime={BindInterval=function(_,view,interval,fn)tickers[#tickers+1]={interval=interval,fn=fn,elapsed=0}end}
        assert(load('local self,f,AUI=...;local function Public()return true end;local function Call(fn,...)if fn then return fn(...)end end;\n'..source))(target,frame,runtime)
        C_Map={GetBestMapForUnit=function()return 1 end,GetPlayerMapPosition=function()return {GetXY=function()return .5,.5 end}end}
        for i=1,1200 do frame:Fire('OnUpdate',.05);for _,ticker in ipairs(tickers)do ticker.elapsed=ticker.elapsed+.05;if ticker.elapsed>=ticker.interval-.00001 then ticker.elapsed=0;ticker.fn()end end end
        return counts
    end
    local old,new=cadence(BASELINE_UPDATE_SOURCE),cadence(CURRENT_UPDATE_SOURCE)
    assert(new.guide<old.guide and new.context<old.context and new.navigation<old.navigation)
    print(('BENCHMARK: stationary 60-second tracker simulation: guide reads %d -> %d; context/layout passes %d -> %d; compass updates %d -> %d'):format(old.guide,new.guide,old.context,new.context,old.navigation,new.navigation))
    local baseline={};assert(load(BASELINE_CORE_SOURCE))('Baseline',baseline)
    local oldScroll=baseline:CreateSmoothScrollFrame(UIParent)
    local idleCalls=0
    local handler=oldScroll:GetScript('OnUpdate')
    for i=1,1200 do if handler then idleCalls=idleCalls+1;handler(oldScroll,.05)end end
    local newScroll=AUI:CreateSmoothScrollFrame(UIParent)
    assert(newScroll:GetScript('OnUpdate')==nil)
    print(('BENCHMARK: settled visible scrollbar, 60 seconds at 20 FPS: %d -> 0 update callbacks'):format(idleCalls))
end

local metricCalls=0;local messages={}
AUI.Print=function(_,message)messages[#messages+1]=message end
C_AddOnProfiler={GetAddOnMetric=function(name,metric)assert(name=='ProjectRuthless');metricCalls=metricCalls+1;return metric==1 and .025 or .2 end}
Enum.AddOnProfilerMetric={RecentAverageTime=1,PeakTime=4}
assert(metricCalls==0);AUI:ShowPerformance();assert(metricCalls==2 and messages[#messages]:find('0.025',1,true))
C_AddOnProfiler=nil;AUI:ShowPerformance();assert(messages[#messages]:find('unavailable'))
print('PASS: CPU snapshot reads native metrics only on demand and handles missing profiler')

-- Mode selection and individual macro tools create their own UI once.
book.scroll=CreateFrame('ScrollFrame');book.searchBox=CreateFrame('EditBox');book.filterButton=CreateFrame('Button');book.pinHint=CreateFrame('Frame')
local macroBuilds,iconBuilds,templateBuilds,backupBuilds=0,0,0,0
book.CreateMacroView=function(self)macroBuilds=macroBuilds+1;self.macroView=CreateFrame('Frame')end
book:SelectMode('class');assert(macroBuilds==0)
book:SelectMode('macros');book:SelectMode('class');book:SelectMode('macros');assert(macroBuilds==1)
book.CreateMacroIconPicker=function(self)iconBuilds=iconBuilds+1;self.iconPicker=CreateFrame('Frame');self.iconSearch=CreateFrame('EditBox')end
book.RefreshMacroIconPicker=function()end
book:ShowMacroIconPicker();assert(iconBuilds==0)
book.selectedMacro=1;book:ShowMacroIconPicker();book:ShowMacroIconPicker();assert(iconBuilds==1)
book.CreateMacroTemplatePanel=function(self)templateBuilds=templateBuilds+1;self.templatePanel=CreateFrame('Frame')end
book:ShowMacroTemplates();book:ShowMacroTemplates();assert(templateBuilds==1)
book.CreateMacroBackupPanel=function(self)backupBuilds=backupBuilds+1;self.backupPanel=CreateFrame('Frame');self.backupScroll={ScrollTo=function()end}end
book.RefreshMacroBackups=function()end;book:ShowMacroBackups();book:ShowMacroBackups();assert(backupBuilds==1)
print('PASS: macro editor, 96-icon picker, templates and history construct only on their first use')

local regionReads=0;local bearing=.5
q.arrow=CreateFrame('Texture');function q.arrow:SetRotation(v)self.rotation=v end
q.distance=CreateFrame('FontString');q.destination=CreateFrame('FontString')
local sourceArrow={GetObjectType=function()return 'Texture'end,GetTexture=function()return 1 end,GetSize=function()return 96,96 end,GetRotation=function()return bearing end}
local sourceDistance=CreateFrame('FontString');sourceDistance:SetText('100 yd');function sourceDistance:GetObjectType()return 'FontString'end
local sourceDestination=CreateFrame('FontString');sourceDestination:SetText('Target');function sourceDestination:GetObjectType()return 'FontString'end
ForeverWispNavigation={IsShown=function()return true end,GetRegions=function()regionReads=regionReads+1;return sourceArrow,sourceDistance,sourceDestination end}
for i=1,50 do assert(q:GuideNavigation())end;assert(regionReads==1 and q.arrow.rotation==.5)
bearing=1.5;sourceDistance:SetText('80 yd');q:GuideNavigation();assert(regionReads==1 and q.arrow.rotation==1.5 and q.distance.text=='80 yd')
ForeverWispNavigation={IsShown=function()return true end,GetRegions=function()regionReads=regionReads+1;return sourceArrow,sourceDistance,sourceDestination end}
q:GuideNavigation();assert(regionReads==2)
print('PASS: compass region discovery is cached while live bearing/text stay fresh; replacing the source frame invalidates it')

-- Demand timer lifecycle: no per-frame handler, cancellable hide, safe reopen.
local intervalTimers={}
C_Timer.NewTicker=function(interval,fn)local t={interval=interval,fn=fn};function t:Cancel()self.cancelled=true end;intervalTimers[#intervalTimers+1]=t;return t end
local intervalView=CreateFrame('Frame');local intervalCalls=0
AUI:BindInterval(intervalView,.25,function()intervalCalls=intervalCalls+1 end)
assert(intervalView:GetScript('OnUpdate')==nil and #intervalTimers==1)
intervalTimers[1].fn();assert(intervalCalls==1)
intervalView:Hide();assert(intervalTimers[1].cancelled)
intervalView:Show();assert(#intervalTimers==2)
intervalView.parent=CreateFrame('Frame');intervalView.parent:Hide();intervalTimers[2].fn();assert(intervalTimers[2].cancelled and intervalCalls==1)
print('PASS: native interval timers stop on hide/hidden-parent and restart without frame-rate Lua dispatch')
assert(load(PROFILES_SOURCE))('ProjectRuthless',AUI)
local profiles=AUI.modules.Profiles
ProjectRuthlessDB.general.windowScale=1;ProjectRuthlessDB.questWorkspace.enabled=false
local exported=profiles:Export();assert(profiles:Parse(exported))
assert(not profiles:Import('RUI_SETTINGS_1\ngeneral.windowScale=100'))
assert(not profiles:Import('RUI_SETTINGS_1\ngeneral.windowScale=1.1\ngeneral.windowScale=1'))
assert(not profiles:Import('RUI_SETTINGS_1\ngeneral.windowScale=1.1\nunknown.enabled=true'))
assert(ProjectRuthlessDB.general.windowScale==1)
assert(profiles:Save('Review'));assert(profiles:Import('RUI_SETTINGS_1\ngeneral.windowScale=1.1'))
assert(ProjectRuthlessDB.general.windowScale==1.1);assert(profiles:Restore());assert(ProjectRuthlessDB.general.windowScale==1)
ProjectRuthlessDB.general.windowScale=.9;assert(profiles:Load('Review'));assert(ProjectRuthlessDB.general.windowScale==1)
local savedCombat=InCombatLockdown;InCombatLockdown=function()return true end
assert(not profiles:Import(exported));InCombatLockdown=savedCombat
assert(not profiles:Parse('return os.execute("bad")'));assert(not profiles:Save(string.rep('x',41)))
ProjectRuthlessDB.elvui={safeTooltip=true}
assert(profiles:Import('RUI_SETTINGS_1\ngeneral.windowScale=1\nelvui.safeTooltip=false'))
assert(ProjectRuthlessDB.elvui.safeTooltip==true and not profiles:Export():find('elvui',1,true))
print('PASS: settings roundtrip, named profiles, atomic invalid-import rejection, version/range/duplicate checks, undo and combat block')

for _,method in ipairs({'SetJustifyH','SetAutoFocus','SetMaxLetters','SetMultiLine','SetFontObject','SetTextInsets','SetFont','ClearFocus'})do Frame[method]=function()end end
function Frame:GetFont()return 'Fonts/FRIZQT__.TTF',12,''end
function Frame:GetTextInsets()return 0,0,0,0 end
function Frame:GetStringHeight()return 12 end
AUI.modules.Menu.CreateProfilesPanel=realProfileBuilder
AUI.modules.Menu:SelectTab('profiles')
assert(AUI.modules.Menu.panels.profiles and AUI.modules.Menu.selectedTab=='profiles')
print('PASS: Profiles page constructs with real shared scrolling editor APIs')
local combatCallbackCount=0;local wasCombat=InCombatLockdown
function geterrorhandler()return function(err)error(err)end end
InCombatLockdown=function()return true end
AUI:AfterCombat('render',function()combatCallbackCount=combatCallbackCount+10 end)
AUI:AfterCombat('render',function()combatCallbackCount=combatCallbackCount+1 end)
assert(combatCallbackCount==0 and AUI.combatEvents.events.PLAYER_REGEN_ENABLED)
InCombatLockdown=wasCombat;AUI.combatEvents:Fire('OnEvent','PLAYER_REGEN_ENABLED')
assert(combatCallbackCount==1 and not AUI.combatEvents.events.PLAYER_REGEN_ENABLED)
print('PASS: keyed combat render queue replaces stale work and unregisters after drain')

local realMenu=AUI.modules.Menu;local loadCount=0
local originalLoader=C_AddOns.LoadAddOn
assert(load(MENULOADER_SOURCE))('ProjectRuthless',AUI)
assert(AUI.modules.Menu.frame==nil and loadCount==0)
C_AddOns.LoadAddOn=function(name)assert(name=='ProjectRuthless_Options');loadCount=loadCount+1;AUI.modules.Menu=realMenu;return true end
AUI.modules.Menu:Show('profiles');assert(loadCount==1 and AUI.modules.Menu==realMenu)
C_AddOns.LoadAddOn=originalLoader
print('PASS: unopened options have only a loader; first settings request loads and delegates to the real menu')


menu:FilterTabs('dungeon');local visibleTabs=0;for _,tab in ipairs(menu.tabs)do if tab:IsShown()then visibleTabs=visibleTabs+1;assert(tab.panelID=='mapquests')end end;assert(visibleTabs==1)
menu:FilterTabs('');for _,tab in ipairs(menu.tabs)do assert(tab:IsShown())end
print('PASS: plain-text settings navigation search filters and restores all tabs')

-- Forever shell excludes unsupported pages, including stale direct navigation.
AUI.isForever=true
local foreverMenu=AUI.modules.Menu
foreverMenu.frame=nil;foreverMenu.tabs={};foreverMenu.panels={}
foreverMenu:Create()
assert(#foreverMenu.tabs==11 and foreverMenu.pageBuilders.actionbars=="CreateActionBarOptions")
for i,tab in ipairs(foreverMenu.tabs)do assert(tab.panelID~="character" and tab.panelID~="achievements")end
assert(foreverMenu.pageBuilders.character==nil and foreverMenu.pageBuilders.achievements==nil)
foreverMenu:SelectTab("character");assert(foreverMenu.selectedTab=="general")
foreverMenu:SelectTab("achievements");assert(foreverMenu.selectedTab=="general")
print("PASS: Forever settings omit Character/Achievements, keep contiguous tabs and redirect stale links")


-- Real shared opacity policy: inherited defaults, overrides, zero, reset and untouched text alpha.
do
 local oldSettings=ProjectRuthlessDB.general;ProjectRuthlessDB.general={}
 local oldQuest=ProjectRuthlessDB.questWorkspace.opacity;ProjectRuthlessDB.questWorkspace.opacity=.75
 assert(AUI:BackgroundOpacity("Player")==.75)
 local surface=CreateFrame("Frame");local alpha;surface.SetBackdropColor=function(_,r,g,b,a)alpha=a end
 AUI:StyleSurface(surface,"window",.98,"Player");assert(alpha==.75)
 ProjectRuthlessDB.general.backgroundOpacity=.4;AUI:RefreshBackgrounds();assert(alpha==.4)
 ProjectRuthlessDB.general.backgroundPlayer=.9;AUI:RefreshBackgrounds();assert(alpha==.9 and AUI:BackgroundOpacity("Quest")==.4)
 ProjectRuthlessDB.general.backgroundPlayer=0;AUI:RefreshBackgrounds();assert(alpha==0)
 ProjectRuthlessDB.general.backgroundPlayer=-1;AUI:RefreshBackgrounds();assert(alpha==.4)
 local settings=AUI.modules.Profiles:Export();assert(settings:find('general.backgroundOpacity=0.4',1,true)and settings:find('general.backgroundPlayer=-1',1,true))
 assert(AUI.modules.Profiles:Parse(settings));assert(not AUI.modules.Profiles:Parse('RUI_SETTINGS_1\ngeneral.backgroundPlayer=-0.5'))
 ProjectRuthlessDB.general=oldSettings;ProjectRuthlessDB.questWorkspace.opacity=oldQuest
 local oldSlider,oldCheck,oldAction=foreverMenu.CreateSlider,foreverMenu.CreateCheckbox,foreverMenu.CreateAction
 local sliders,checks=0,0
 foreverMenu.CreateSlider=function(_,_,label,description,y,min,max,step,formatter,getter,setter)sliders=sliders+1;assert(min==0 and max==1 and step==.01 and type(getter())=='number');return {}end
 foreverMenu.CreateCheckbox=function()checks=checks+1 end;foreverMenu.CreateAction=function()end
 foreverMenu:CreateBackgroundOptions(foreverMenu.content);assert(sliders==#AUI.backgroundGroups+1 and checks==#AUI.backgroundGroups)
 foreverMenu.CreateSlider,foreverMenu.CreateCheckbox,foreverMenu.CreateAction=oldSlider,oldCheck,oldAction
 print('PASS: inherited quest opacity, background-only global/individual/zero/reset updates, profile roundtrip validation and complete scrollable background controls')
end
