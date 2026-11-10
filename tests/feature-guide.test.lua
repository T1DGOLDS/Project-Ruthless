local frames,timers={},{}
local combat=false
local scale=1
local Widget={}
Widget.__index=Widget
function Widget:SetSize(w,h)self.width=w;self.height=h end
function Widget:SetHeight(h)self.height=h end
function Widget:SetWidth(w)self.width=w end
function Widget:GetWidth()return self.width or 100 end
function Widget:GetHeight()return self.height or 20 end
function Widget:SetPoint(...)self.points=self.points or {};self.points[#self.points+1]={...}end
function Widget:SetFrameStrata(v)self.strata=v end
function Widget:SetClampedToScreen(v)self.clamped=v end
function Widget:SetBackdrop(v)self.backdrop=v end
function Widget:SetBackdropColor(...)end
function Widget:SetBackdropBorderColor(...)end
function Widget:SetJustifyH(v)end
function Widget:SetTextColor(...)end
function Widget:SetAtlas(v)self.atlas=v end
function Widget:SetText(v)self.text=v end
function Widget:GetStringHeight()
 local width=self.width or 492;local lines=0
 for line in ((self.text or '')..'\n'):gmatch('(.-)\n')do lines=lines+math.max(1,math.ceil(#line/math.max(1,math.floor(width/(7*(self.textScale or 1))))))end
 return lines*15*(self.textScale or 1)
end
function Widget:SetScript(k,v)self.scripts[k]=v end
function Widget:GetScript(k)return self.scripts[k]end
function Widget:RegisterEvent(k)self.events[k]=true end
function Widget:UnregisterEvent(k)self.events[k]=nil end
function Widget:UnregisterAllEvents()self.events={}end
function Widget:SetScale(v)self.scale=v end
function Widget:SetEnabled(v)self.enabled=v end
function Widget:IsEnabled()return self.enabled~=false end
function Widget:EnableKeyboard(v)self.keyboard=v end
function Widget:SetPropagateKeyboardInput(v)self.propagate=v end
function Widget:SetShown(v)if v then self:Show()else self:Hide()end end
function Widget:Show()local old=self.shown;self.shown=true;if not old and self.scripts.OnShow then self.scripts.OnShow(self)end end
function Widget:Hide()local old=self.shown;self.shown=false;if old and self.scripts.OnHide then self.scripts.OnHide(self)end end
function Widget:IsShown()return self.shown end
local function widget(name,parent)
 local f=setmetatable({name=name,parent=parent,scripts={},events={},enabled=true,shown=true},Widget);frames[#frames+1]=f;if name then _G[name]=f end;return f
end
function Widget:CreateFontString(name,layer,font)return widget(name,self)end
function Widget:CreateTexture(name,layer)return widget(name,self)end
function CreateFrame(kind,name,parent)return widget(name,parent)end
UIParent=widget('UIParent');UIParent:SetSize(1920,1080)
function InCombatLockdown()return combat end
function IsShiftKeyDown()return false end
C_Timer={After=function(delay,callback)timers[#timers+1]=callback end}
local AUI={isForever=true,modules={}}
function AUI:RegisterModule(name,value)self.modules[name]=value end
function AUI:StyleSurface()end
function AUI:AccentColor()return .3,.6,1 end
function AUI:CreateButton(parent)return widget(nil,parent)end
AUI.modules.Accessibility={RegisterText=function(_,font)font.textScale=scale end,FitWindow=function(_,frame,requested)return math.min(requested,(UIParent:GetWidth()-32)/frame:GetWidth(),(UIParent:GetHeight()-32)/frame:GetHeight())end}
local opened={};AUI.modules.Menu={Show=function(_,page)opened[#opened+1]=page end}
ProjectRuthlessDB={general={}};ProjectRuthlessCharDB={firstRun={eligible=true,complete=false}}
assert(load(SOURCE))('RUI',AUI);assert(load(FIRST_RUN))('RUI',AUI)
local G=AUI.modules.FeatureGuide
assert(#G.tour==4 and #G.topics>=20)
-- Existing setup state/layout is not modified by the introduction.
AUI.modules.FirstRun:OnPlayerLogin();assert(#timers==0 and #opened==0 and not ProjectRuthlessCharDB.firstRun.complete)
G:OnPlayerLogin();assert(#timers==1 and G.frame==nil)
combat=true;timers[1]();assert(G.frame==nil and G.pending=='automatic'and G.events.events.PLAYER_REGEN_ENABLED)
combat=false;G.events.scripts.OnEvent(G.events,'PLAYER_REGEN_ENABLED')
assert(G.frame:IsShown()and G.frame.strata=='DIALOG'and G.frame.points[1][1]=='CENTER'and G.page==1)
assert(not G.events.events.PLAYER_REGEN_ENABLED and G.pending==nil and not G.back:IsEnabled())
G.next.scripts.OnClick();assert(G.page==2 and G.back:IsEnabled())
combat=true;G.events.scripts.OnEvent(G.events,'PLAYER_REGEN_DISABLED');assert(not G.frame:IsShown()and G.pendingPage==2)
combat=false;G.events.scripts.OnEvent(G.events,'PLAYER_REGEN_ENABLED');assert(G.frame:IsShown()and G.page==2 and G.pendingPage==nil)
G.back.scripts.OnClick();assert(G.page==1)
local controls=#frames
for _=1,8 do G:Show(true)end
assert(#frames==controls and #UISpecialFrames==1,'reopening must reuse assets and Escape registration')
G.frame.scripts.OnKeyDown(G.frame,'TAB');assert(G.keyboardIndex==1 and G.frame.propagate==false)
G.frame.scripts.OnKeyDown(G.frame,'RIGHT');assert(G.page==2)
GetCurrentKeyBoardFocus=function()return {}end
G.frame.scripts.OnKeyDown(G.frame,'ENTER');assert(G.page==2 and G.frame.propagate)
GetCurrentKeyBoardFocus=nil
G.frame.scripts.OnKeyDown(G.frame,'ESCAPE');assert(not G.frame:IsShown()and G.keyboardIndex==nil)
-- Opt out applies immediately across character/profile changes, while manual
-- replay and unchecking make the feature available without resetting a layout.
G:Show(true);local check=G.keyboardControls[5];check.scripts.OnClick();assert(G:Store().dontShowAgain and G.tick.shown)
G.frame:Hide();assert(not G:Show(false)and not G.frame:IsShown())
ProjectRuthlessCharDB={activeProfile='Other character'};ProjectRuthlessDB.general={windowScale=.9}
assert(not G:Show(false));assert(G:Show(true));check.scripts.OnClick();assert(not G:Store().dontShowAgain)
G:OpenGuide();assert(opened[#opened]=='features'and not G.frame:IsShown())
-- Measured content expands, then fits a small screen at large text size.
UIParent:SetSize(800,600)
for _,font in ipairs({G.copy,G.heading})do font.textScale=1.5 end
for i=1,#G.tour do G.page=i;G:Render();assert(G.frame:GetHeight()*G.frame.scale<=568.01);assert(110+G.copy:GetStringHeight()<G.frame:GetHeight()-160)end
UIParent:SetSize(700,500);G:Show(true);G.events.scripts.OnEvent(G.events,'DISPLAY_SIZE_CHANGED');assert(G.frame:GetHeight()*G.frame.scale<=468.01)
-- The settings guide uses the same canonical flow/search registration and
-- provides unique contextual destinations for every described feature.
local flow={panel={},actions={},sections={},checks={}}
function flow:Action(label,fn,description)local b=widget();b.callback=fn;b.description=description;self.actions[#self.actions+1]={label=label,button=b};return b end
function flow:Section(title)self.sections[#self.sections+1]=title end
function flow:Note(text)assert(type(text)=='string'and #text>50)end
function flow:Check(label,description,get,set)self.checks[#self.checks+1]={get=get,set=set}end
function flow:Reflow()self.reflowed=true end
local searches={}
AUI.modules.SettingsRegistry={Register=function(_,page,button,label,description,y,kind,section,key)assert(page=='features'and not searches[label]);searches[label]={description=description,key=key}end}
local menu={CreateFlowPage=function(_,parent,id)assert(id=='features');return flow end,SelectTab=function(_,page)opened[#opened+1]=page end}
assert(G:BuildSettings(menu,{})==flow.panel and flow.reflowed)
assert(#flow.sections==#G.topics and #flow.actions==#G.topics+2)
local count=0;for _,row in pairs(searches)do count=count+1;assert(#row.description>100 and row.key)end;assert(count==#G.topics)
flow.actions[1].button.callback();assert(opened[#opened]=='errors')
flow.actions[3].button.callback();assert(opened[#opened]==G.topics[1].page)
flow.checks[1].set(true);assert(G:Store().dontShowAgain);flow.checks[1].set(false);assert(not G:Store().dontShowAgain)
assert(not ProjectRuthlessDB.profilesV2,'welcome does not create or apply profiles')
print('PASS: centered four-page intro, combat deferral, account opt-out/manual replay, setup coexistence, keyboard/Escape, asset reuse, large-text screen fitting and complete contextual settings guide')
