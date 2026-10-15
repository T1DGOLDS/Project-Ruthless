unpack=table.unpack or unpack
local AUI={modules={}};function AUI:RegisterModule(n,m)self.modules[n]=m end
function AUI:Print(text)self.message=text end
function AUI:AccentColor()return .8,.4,.7 end
function AUI:StyleSurface()end
local frames={}
local function frame(parent)
 local f={parent=parent,scripts={},shown=true,width=600,height=400,horizontal=0,vertical=0,text=""};frames[#frames+1]=f
 function f:SetSize(w,h)self.width=w;self.height=h end
 function f:GetWidth()return self.width end;function f:SetHeight(h)self.height=h end
 function f:SetPoint(...)self.point={...}end;function f:ClearAllPoints()end
 function f:SetText(text)self.text=text end;function f:GetStringHeight()return 180 end
 function f:SetScript(n,fn)self.scripts[n]=fn end
 function f:Show()self.shown=true end;function f:Hide()self.shown=false;if self.scripts.OnHide then self.scripts.OnHide()end end
 function f:IsVisible()return self.shown end
 function f:GetFrameLevel()return 1 end;function f:GetFrameStrata()return 'MEDIUM'end
 function f:SetFrameLevel()end;function f:SetFrameStrata()end;function f:EnableMouse()end;function f:EnableMouseWheel()end
 function f:SetBackdrop()end;function f:SetBackdropBorderColor()end;function f:SetColorTexture()end
 function f:CreateFontString()return frame(self)end;function f:CreateTexture()return frame(self)end
 function f:SetScrollChild(child)self.child=child end
 function f:GetHorizontalScroll()return self.horizontal end;function f:SetHorizontalScroll(v)self.horizontal=v end
 function f:GetVerticalScroll()return self.vertical end;function f:SetVerticalScroll(v)self.vertical=v end
 function f:GetHorizontalScrollRange()return math.max(0,(self.child and self.child.width or 0)-self.width)end
 function f:GetVerticalScrollRange()return math.max(0,(self.child and self.child.height or 0)-self.height)end
 function f:GetEffectiveScale()return 1 end;function f:EnableKeyboard()end;function f:SetPropagateKeyboardInput(v)self.propagate=v end
 function f:RegisterEvent(e)self.events=self.events or {};self.events[e]=true end
 return f
end
function CreateFrame(_,_,parent)return frame(parent)end
function AUI:CreateButton(parent)return frame(parent)end
WorldMapFrame=frame();WorldMapFrame.ScrollContainer=frame(WorldMapFrame)
function WorldMapFrame:SetMapID(id)self.mapID=id end
local secret={};function issecretvalue(v)return v==secret end
local held,done,ready={},{},{};local counts=0
C_QuestLog={IsOnQuest=function(id)counts=counts+1;return held[id]or false end,IsQuestFlaggedCompleted=function(id)return done[id]or false end,IsComplete=function(id)return ready[id]or false end,GetTitleForQuestID=function()end,GetQuestObjectives=function()return {{text='2/5 collected'}}end,GetNumQuestLogEntries=function()return 1 end,GetInfo=function()return {questID=900,title='Native quest',isHeader=false}end}
local faction='Alliance';function UnitFactionGroup()return faction end;function UnitLevel()return 20 end
C_Map={GetBestMapForUnit=function()return 52 end,GetMapInfo=function()return {name='Westfall'}end}
C_QuestLine={GetQuestLineInfo=function()return {questLineID=700,questLineName='Native story',questID=900,x=.4,y=.5,startMapID=52}end,GetQuestLineQuests=function()return {900,901,902}end,GetAvailableQuestLines=function()return {}end}
ProjectRuthlessCharDB={};local combat=false;function InCombatLockdown()return combat end
function IsShiftKeyDown()return false end;function GetCursorPosition()return 100,100 end
local pending={};C_Timer={After=function(_,fn)pending[#pending+1]=fn end}
local q={mapControls={},dungeonMapButtons={},mapPage='Dungeons',mapPanel=frame(),mapScroll=frame(),mapContent=frame(),mapHeading=frame(),mapCopy=frame()};AUI.modules.QuestWorkspace=q
function q:Refresh()self.refreshes=(self.refreshes or 0)+1 end
function q:SelectMapPage(page)self.mapPage=page end
function q:ShareDungeonQuest(id)self.share=id;return true,'Shared' end
assert(load(DATA_SOURCE))('ProjectRuthless',AUI);assert(load(PROGRESSION_SOURCE))('ProjectRuthless',AUI)
local p=AUI.modules.QuestProgression;local catalog=p:Catalog();local c=p:Chain('rui:deadmines')
assert(c and #c.nodes==11 and p:Chain('native:700')and p:Chain('log'))
local positions=p:Layout(c);assert(positions[166].x>positions[155].x and positions[214].x==positions[166].x)
local final=p:FindNode(c,166);local state,reason=p:Status(c,final);assert(state=='Blocked'and reason:find('prerequisite'))
done[155]=true;p:Invalidate();assert(p:Status(c,final)=='Check giver')
held[166]=true;done[166]=true;p:Invalidate();assert(p:Status(c,final)=='In progress')
ready[166]=true;p:Invalidate();assert(p:Status(c,final)=='Turn in')
held[166]=nil;p:Invalidate();assert(p:Status(c,final)=='Completed')
local b=p:FindNode(c,214);p:Follow(c,b);assert(p:Store().active==c.key and q.selected==214)
local guide=p:Guide();assert(guide.id==214 and guide.source=='RUI progression'and #guide.next==0)
local before=counts;p:Status(c,b);p:Status(c,b);assert(counts==before)
local native=p:Chain('native:700');assert(#native.nodes[2].requires==0 and p:Status(native,native.nodes[2])=='Check giver')
local saved=p:Store().known;assert(saved['native:700'].nodes[1].point.map==52)
done[214]=secret;p:Invalidate();assert(p:Status(c,b)=='Unknown');done[214]=nil
assert(not p:Layout({nodes={{id=1,requires={2}},{id=2,requires={1}}}}))
assert(not p:Layout({nodes={{id=1,requires={99}}}}))
assert(not p:Layout({nodes={{id=1},{id=1}}}))
p.selected=c.key;p.selectedQuest=166;combat=true;p:Render(q)
assert(p.frame.shown and #p.buttons==11 and #p.edges>0 and not p.canvas.scripts.OnUpdate)
assert(q.mapCopy.text:find('Gryan')and q.mapCopy.text:find('Sentinel Hill'))
p.buttons[8].scripts.OnClick();assert(p.selectedQuest==214 and q.mapCopy.text:find('Red Silk'))
local refreshes=q.refreshes;p.buttons[7].scripts.OnClick();assert(q.refreshes==refreshes) -- Browsing does not replace the active guide.
p.frame.scripts.OnKeyDown(p.frame,'RIGHT');assert(p.selectedQuest==214 and p.frame.propagate==false)
p.canvas.scripts.OnMouseDown(p.canvas,'LeftButton');assert(p.canvas.scripts.OnUpdate);p:Hide();assert(not p.canvas.scripts.OnUpdate)
combat=false;p:OnPlayerLogin();assert(not p.events and #pending==0) -- Workspace owns batching; no duplicate subscriptions.
p:Action('stop');assert(not p:Store().active and not q.manualPickup)
faction='Horde';p:Invalidate();assert(not p:Chain('rui:deadmines')and p:Chain('log'))
print('PASS: owned branching requirements, native groups without invented dependencies, active/completed distinctions, secret fallbacks, cached states, cycle/missing-ID protection, combat browsing, node details, keyboard/panning lifecycle, coalesced events and character-local focus')
