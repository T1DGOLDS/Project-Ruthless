local output=print
unpack=table.unpack;SlashCmdList={};UISpecialFrames={}
local now,busy,frames,memoryRefresh=0,false,{},0
function GetTime()return now end
function GetBuildInfo()return '1.60.1','70235','',16001 end
function InCombatLockdown()return busy end
function date()return '2026-10-13 12:00:00'end
function strtrim(s)return s end
function print()end
local secret=setmetatable({},{__lt=function()error('secret comparison')end})
function issecretvalue(value)return value==secret end
C_Timer={NewTicker=function(_,fn)local t={fn=fn};function t:Cancel()self.cancelled=true end;return t end}
local frame={};frame.__index=frame
function frame:RegisterEvent(event)self.events[event]=true end
function frame:UnregisterEvent(event)self.events[event]=nil end
function frame:UnregisterAllEvents()self.events={}end
function frame:SetScript(event,fn)self.scripts[event]=fn end
function frame:SetScale()self.scales=(self.scales or 0)+1 end
function frame:SetAlpha()self.alphas=(self.alphas or 0)+1 end
function frame:SetBackdropColor()self.paints=(self.paints or 0)+1 end
function CreateFrame()local f=setmetatable({scripts={},events={}},frame);frames[#frames+1]=f;return f end
C_AddOns={GetAddOnMetadata=function()return '0.14.0-beta.73'end,IsAddOnLoaded=function(name)return name=='ElvUI'end,UpdateAddOnMemoryUsage=function()memoryRefresh=memoryRefresh+1 end,GetAddOnMemoryUsage=function()return 100 end}
local cpu=1
Enum={AddOnProfilerMetric={RecentAverageTime=1,PeakTime=2,CountTimeOver5Ms=3,CountTimeOver50Ms=4}}
C_AddOnProfiler={IsEnabled=function()return true end,GetAddOnMetric=function(_,metric)return metric==1 and cpu or now end}
function GetFramerate()return 60 end
local AUI={};assert(load(CORE_SOURCE))('ProjectRuthless',AUI)
local coreEvents=frames[1];local order={}
AUI:RegisterModule('First',{OnAddonLoaded=function()order[#order+1]='old'end})
AUI:RegisterModule('Second',{OnAddonLoaded=function()order[#order+1]='second'end})
AUI:RegisterModule('First',{OnAddonLoaded=function()order[#order+1]='first'end})
ElvUI={{private={tooltip={enable=true},skins={blizzard={tooltip=true}}}}}
coreEvents.scripts.OnEvent(coreEvents,'ADDON_LOADED','ProjectRuthless')
assert(table.concat(order,',')=='first,second'and #AUI.moduleOrder==2)
assert(AUI.GetElvUI==nil and ElvUI[1].private.tooltip.enable and ElvUI[1].private.skins.blizzard.tooltip)
local unrelated,hud,layout=0,0,0
AUI.modules.ErrorLog={ApplySettings=function()unrelated=unrelated+1 end,GetFormattedText=function()return 'example error'end}
AUI.modules.ForeverHUD={ApplySettings=function()hud=hud+1 end}
AUI.modules.LayoutEditor={Apply=function()layout=layout+1 end}
AUI.modules.Menu={frame=CreateFrame()};ProjectRuthlessCharDB.layoutEditor={elements={player={}}}
AUI:SettingsChanged('ErrorLog');assert(unrelated==1 and hud==0 and layout==0 and AUI.modules.Menu.frame.scales==nil)
local party,chat=CreateFrame(),CreateFrame();AUI:PaintBackground(party,'Party',0,0,0);AUI:PaintBackground(chat,'Chat',0,0,0)
AUI:SettingsChanged('Backgrounds','Party');assert(party.paints==2 and chat.paints==1 and hud==0 and layout==0)
AUI:SettingsChanged('General','windowOpacity');assert(AUI.modules.Menu.frame.alphas==1 and AUI.modules.Menu.frame.scales==nil and layout==0)
assert(load(DIAGNOSTICS_SOURCE))('ProjectRuthless',AUI)
local D=AUI.modules.Diagnostics;local before=#frames;D:OnPlayerLogin();assert(#frames==before and not D.timer)
CustomAuraContainerGroupDefaultOptions={}
D:Start();assert(D.session and D.timer and #D.session.samples==1 and memoryRefresh==1)
assert(D.session.firstMemoryKB==300)
busy=true;now=40;D:Sample();assert(memoryRefresh==1)
cpu=secret;D:Sample();assert(D.session.samples[#D.session.samples].cpu==nil)
cpu=2;busy=false
for i=1,600 do now=now+2;D:Sample();D.events.scripts.OnUpdate(D.events,.1)end
assert(#D.session.samples==240 and D.session.frames==600 and D.session.framesOver50==600)
assert(memoryRefresh<50)
local report=D:Report('steps: open map');assert(report:find('steps: open map',1,true)and report:find('example error',1,true)and report:find('POSSIBLE CONFLICT',1,true)and report:find('allocation counts are not exposed',1,true))
assert(ElvUI[1].private.tooltip.enable)
local timer=D.timer;D:Stop();assert(timer.cancelled and not D.session and not D.events.scripts.OnUpdate and not next(D.events.events)and not D:Store().enabled)
timer.fn();assert(not D.session)
for i=1,7 do D:Start();D:Stop()end;assert(#D:Store().sessions==5)
D:Start();D.events.scripts.OnEvent(D.events,'PLAYER_LOGOUT');assert(D:Store().enabled and not D.session);D:OnPlayerLogin();assert(D.session);D:Stop()
local oldProfiler=C_AddOnProfiler;C_AddOnProfiler=nil;assert(D:Metric(AUI.name,'RecentAverageTime')==nil);D:Start();assert(D.session.samples[1].cpu==nil);D:Stop();C_AddOnProfiler=oldProfiler
local oldMemory=C_AddOns.GetAddOnMemoryUsage;C_AddOns.GetAddOnMemoryUsage=function()return secret end;assert(D:Memory()==nil);C_AddOns.GetAddOnMemoryUsage=oldMemory
output('PASS: deterministic module replacement/order; scoped settings and backgrounds; no ElvUI mutation; disabled recorder idle; bounded samples/sessions; secret/missing metrics; paced memory, combat, stop/reload, conflict attribution and copyable report.')
