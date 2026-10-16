
unpack=table.unpack
C_Timer={After=function(_,fn)fn()end}
local busy=false;function InCombatLockdown()return busy end
local AUI={modules={}};function AUI:RegisterModule(n,m)self.modules[n]=m end
function AUI:BackgroundOpacity()return .8 end
function AUI:StyleSurface(f,role,opacity)f.surfaceRole=role;f.surfaceOpacity=opacity end;function AUI:AccentColor()return .8,.6,.9 end;function AUI:Print()end
local prototype={};prototype.__index=function(_,k)return prototype[k]or function()end end
local function frame()return setmetatable({x=0,y=0,w=300,h=200,scale=1,shown=true,scripts={}},prototype)end
function prototype:UnregisterAllEvents()self.eventsRetired=true end
function prototype:SetScript(k,v)self.scripts[k]=v end
function prototype:HookScript(k,v)local old=self.scripts[k];self.scripts[k]=function(...)if old then old(...)end;v(...)end end
function prototype:SetPoint(point,anchor,relative,x,y)self.point={point,anchor,relative,x or 0,y or 0};if point=='CENTER'then self.x=x or 0;self.y=y or 0 end end
function prototype:GetPoint(index)if index==2 then return end;return table.unpack(self.point or {'CENTER',UIParent,'CENTER',self.x,self.y})end
function prototype:SetSize(w,h)self.w=w;self.h=h end
function prototype:SetWidth(w)self.w=w end
function prototype:SetShown(v)if v then self:Show()else self:Hide()end end
function prototype:GetFrameLevel()return rawget(self,'frameLevel')or 1 end
function prototype:SetFrameLevel(value)self.frameLevel=value end
function prototype:SetFixedFrameStrata(value)self.fixedStrata=value end
function prototype:SetFixedFrameLevel(value)self.fixedLevel=value end
function prototype:SetFrameStrata(value)self.strata=value end
function prototype:SetClipsChildren(value)self.clips=value end
function prototype:SetModelDrawLayer(value)self.modelLayer=value end
function prototype:SetIgnoreParentAlpha(value)self.ignoreAlpha=value end
function prototype:SetFont(font,size,flags)self.fontSize=size end
function prototype:GetCountdownFontString()if not rawget(self,'countdownFont')then self.countdownFont=frame()end;return self.countdownFont end
function prototype:GetWidth()return self.w end;function prototype:GetHeight()return self.h end
function prototype:GetScale()return self.scale end;function prototype:GetEffectiveScale()return self.scale end
function prototype:SetScale(s)self.scale=s end
function prototype:GetCenter()return 500/self.scale+self.x,400/self.scale+self.y end
function prototype:IsShown()return self.shown end
function prototype:Show()self.shown=true;if self.scripts.OnShow then self.scripts.OnShow(self)end end
function prototype:Hide()self.shown=false;if self.scripts.OnHide then self.scripts.OnHide(self)end end
function prototype:SetText(t)self.text=t end;function prototype:GetText()return self.text or ''end
function prototype:CreateFontString()return frame()end;function prototype:CreateTexture()return frame()end
function CreateFrame(kind,name,parent,template)
    local f=frame();f.widgetKind=kind;f.template=template
    if kind=='AuraContainer'then
        f.groups={};f.SetUnit=function(self,unit)self.unitToken=unit end
        f.SetEnabled=function(self,value)self.enabled=value end
        f.AddAuraGroup=function(self,key,filter,options)
            local button=frame();self.groups[key]={filter=filter,options=options,button=button};options.initializeFrame(button)
        end
    end
    return f
end
CustomAuraContainerGroupDefaultOptions={}
function prototype:SetIcon(icon)self.boundIcon=icon end
function prototype:SetDurationCooldown(cooldown)self.boundCooldown=cooldown end
function prototype:SetApplicationCount(count)self.boundCount=count end
function prototype:SetAttribute(key,value)self.attributes=rawget(self,'attributes')or {};self.attributes[key]=value end
function AUI:CreateButton()return frame()end
function hooksecurefunc(obj,key,callback)if type(obj)=="string"then callback=key;key=obj;obj=_G end;local old=obj[key];obj[key]=function(...)old(...);callback(...)end end
UIParent=frame();UIParent.w=1000;UIParent.h=800
ProjectRuthlessCharDB={};ProjectRuthlessDB={general={partyGrouped=false},questWorkspace={opacity=.8}}
assert(load(SOURCE))('RUI',AUI);local e=AUI.modules.LayoutEditor
assert(not e.frame and next(e.targets)==nil)
local target=frame();AUI.modules.QuestWorkspace={frame=target,LayoutMap=function()end}
e:Show();assert(e.frame:IsShown()and e.movers.quests:IsShown())
e.selected='quests';e:Change('x',100);assert(e:Store().elements.quests.x==100)
e:Change('scale',.2);assert(math.abs(e:Capture(target).x-100)<.001)
e:Undo();assert(target:GetScale()==1 and e:Capture(target).x==100)
assert(e:Save('My layout'));e:Change('x',20);assert(e:Load('My layout')and e:Capture(target).x==100)
local x,y=e:Snap('quests',5,6);assert(x==0 and y==0)
e:Close(true);assert(not e.frame:IsShown()and e:Capture(target).x==0)
e:Show();e.selected='quests';busy=true;local before=e:Capture(target).x;e:Change('x',20);assert(e:Capture(target).x==before and not e:Save('Combat'))
busy=false;e:Close();e:OnPlayerLogin()
assert(not e.frame.scripts.OnUpdate)
print('PASS: layout editor constructs on demand; anchors/inspector, scaling coordinates, snap, saved layouts, undo/cancel and combat restrictions')

local map=frame();e:Attach('map','Map',map,true)
e.selected='map';e:Change('width',600);e:Change('height',350);e:Change('scale',.15)
assert(ProjectRuthlessCharDB.mapSize.width==900 and ProjectRuthlessCharDB.mapSize.height==810)
assert(math.abs(ProjectRuthlessCharDB.mapScale-1.15)<.001)
map:SetSize(780,460);map:SetScale(1);map:Hide();map:Show()
assert(map:GetWidth()==900 and map:GetHeight()==810 and math.abs(map:GetScale()-1.15)<.001)
print('PASS: editor map size and scale persist and restore on reopen')
local timers={};C_Timer={After=function(delay,fn)timers[#timers+1]={delay=delay,fn=fn}end}
local function flush()local pending=timers;timers={};for _,timer in ipairs(pending)do timer.fn()end end
AUI.isForever=true;NUM_CHAT_WINDOWS=1
PlayerFrame=frame();MinimapCluster=frame();ChatFrame1=frame();PlayerCastingBarFrame=frame();PlayerCastingBarFrame:Hide()
TargetFrame=frame();FocusFrame=frame();PetFrame=frame();BuffFrame=frame();DebuffFrame=frame();MainActionBar=frame()
UnitName=function(unit)return unit end;UnitHealth=function()return 75 end;UnitHealthMax=function()return 100 end
UnitPower=function()return 20 end;UnitPowerMax=function()return 40 end
RegisterStateDriver=function(f,state,condition)f.stateDrivers=rawget(f,'stateDrivers')or {};f.stateDrivers[state]=condition end
assert(load(HUD_SOURCE))('RUI',AUI);local hud=AUI.modules.ForeverHUD;hud:OnPlayerLogin()
e:Show();assert(e.targets.player and e.targets.minimap and e.targets.chat1)
assert(not e.targets.castplayer and not hud.registered.castplayer and not PlayerCastingBarFrame:IsShown())
assert(not e.targets.buffs.border:IsShown()and not e.targets.debuffs.border:IsShown())
assert(e.movers.buffs:IsShown()and e.movers.debuffs:IsShown())
e:Close();assert(not e.movers.buffs:IsShown()and not e.movers.debuffs:IsShown())
assert(not e.targets.buffs.border:IsShown()and not e.targets.debuffs.border:IsShown())
e:Show()
assert(e.pageCount>1);e.page=2;e:Refresh();assert(e.selectors[1].id)
e.selected='player';e:Change('x',64);e:Change('scale',.1);assert(#timers==0)
PlayerFrame:SetPoint('CENTER',UIParent,'CENTER',300,0);assert(#timers==1);flush()
assert(math.abs(e:Capture(PlayerFrame).x-64)<.001 and #timers==0)
busy=true;hud.events.scripts.OnEvent(hud.events,'PLAYER_REGEN_DISABLED');PlayerFrame:SetPoint('CENTER',UIParent,'CENTER',200,0)
assert(#timers==0);busy=false;hud.events.scripts.OnEvent(hud.events,'PLAYER_REGEN_ENABLED');assert(timers[1].delay==3)
flush();assert(math.abs(e:Capture(PlayerFrame).x-64)<.001 and #timers==0)
assert(not hud.events.scripts.OnUpdate)
print('PASS: Forever HUD registration, native cast bars excluded from addon movers, paged selectors, saved anchors, combat pause/grace and no idle polling')

function prototype:GetFrameLevel()return 2 end
function prototype:SetStatusBarColor(r,g,b)self.color={r,g,b}end
function prototype:SetAlpha(a)self.alpha=a end
function prototype:SetStatusBarTexture(t)self.barTexture=t;self.flatWrites=(rawget(self,"flatWrites")or 0)+1 end
function prototype:SetTexture(t)self.texturePath=t end
function prototype:SetAtlas(t)self.texturePath=t end
function prototype:GetStatusBarTexture()return self.texture end
function prototype:ClearModel()self.modelUnit=nil;self.cleared=true end
function prototype:SetUnit(unit,blend)assert(self.cleared);self.cleared=nil;self.blend=blend;self.modelUnit=unit;self.modelUpdates=(rawget(self,"modelUpdates")or 0)+1 end
local function unitParts(native,player)
 local health=frame();health.texture=frame();local power=frame();power.texture=frame();local portrait=frame()
 local main={HealthBarsContainer=frame(),ManaBar=power,Name=frame(),LevelText=frame()}
 main.HealthBarsContainer.HealthBar=health
 if player then main.ManaBarArea={ManaBar=power}end
 local content=frame()
 if player then content.PlayerFrameContentMain=main;native.PlayerFrameContent=content;native.PlayerFrameContainer={PlayerPortrait=portrait}
 else content.TargetFrameContentMain=main;native.TargetFrameContent=content;native.TargetFrameContainer={Portrait=portrait};function native:CheckClassification()main.HealthBarsContainer:SetSize(125,12)end end
 native.ruiPortrait=false;native.ruiPainting=false
 return health,power,portrait
end
local health,power,portrait=unitParts(PlayerFrame,true);hud:StyleUnit('player',PlayerFrame)
assert(PlayerFrame.ruiPortrait.modelUnit=='player'and portrait.alpha==0)
assert(health.barTexture=='Interface\\Buttons\\WHITE8X8'and power.barTexture==health.barTexture)
assert(health:GetWidth()==300 and power:GetWidth()==184 and power:GetHeight()==12)
unitParts(TargetFrame,false);hud:StyleUnit('target',TargetFrame)
local model=TargetFrame.ruiPortrait;local count=model.modelUpdates
hud.events.scripts.OnEvent(hud.events,'PLAYER_TARGET_CHANGED');assert(model.modelUpdates==count+1 and model.modelUnit=='target')
busy=true;local old=PlayerFrame:GetWidth();PlayerFrame:SetSize(280,82);hud:StyleUnit('player',PlayerFrame);assert(PlayerFrame:GetWidth()==280);busy=false
print('PASS: original 3D player/target portraits, flat native resource/health textures, target-change model refresh and no protected style changes in combat')
assert(health.color[1]==.22 and power.color[3]==.85)
UnitPowerType=function()return 1,'RAGE'end
hud.events.scripts.OnEvent(hud.events,'UNIT_DISPLAYPOWER','player');assert(power.color[1]==.85 and power.color[3]==.18)
health:SetStatusBarColor(1,1,1);assert(health.color[1]==.22 and health.color[2]==.65)
print('PASS: health/resource colours survive native white resets and resource type changes without health-value reads')

local targetContent=TargetFrame.TargetFrameContent;local contextual=frame();local auras=frame();contextual.Auras=auras;targetContent.TargetFrameContentContextual=contextual
function auras:SetFlowLayoutMirroredVertically(v)self.mirrored=v end
function auras:SetFlowLayoutMaximumLineSize(v)self.lineWidth=v end
function auras:SetNumConstrainedFlowLayoutLines(v)self.constrained=v end
function auras:SetPoint(point,relative,relativePoint,x,y)self.anchor={point,relative,relativePoint,x,y}end
ProjectRuthlessCharDB.layoutEditor.elements.target=nil;PlayerFrame:SetScale(.8);hud:StyleUnit('target',TargetFrame)
assert(TargetFrame:GetScale()==.8 and auras.mirrored and auras.lineWidth==236 and auras.constrained==0)
assert(auras.anchor[1]=='BOTTOMLEFT'and auras.anchor[2]==TargetFrame and auras.anchor[3]=='TOPLEFT'and auras.anchor[5]==8)
ProjectRuthlessCharDB.layoutEditor.elements.target={scale=1.2};TargetFrame:SetScale(1.2);hud:StyleUnit('target',TargetFrame);assert(TargetFrame:GetScale()==1.2)
assert(not e.targets.player.border:IsShown()and not e.targets.target.border:IsShown())
print('PASS: target auras anchor above the frame; default target scale follows player while explicit target scale stays; duplicate heavy outlines hidden')

local playerMain=PlayerFrame.PlayerFrameContent.PlayerFrameContentMain
local targetMain=TargetFrame.TargetFrameContent.TargetFrameContentMain
local playerFlash=frame();local targetFlash=frame();local status=frame();local reputation=frame()
PlayerFrame.PlayerFrameContainer.FrameFlash=playerFlash;TargetFrame.TargetFrameContainer.Flash=targetFlash
playerMain.StatusTexture=status;targetMain.ReputationColor=reputation
targetMain.HealthBarsContainer.LeftText=frame();targetMain.HealthBarsContainer.RightText=frame();targetMain.HealthBarsContainer.HealthBarText=frame()
targetMain.ManaBar.LeftText=frame();targetMain.ManaBar.RightText=frame();targetMain.ManaBar.ManaBarText=frame()
for _,label in ipairs({targetMain.HealthBarsContainer.RightText,targetMain.ManaBar.RightText})do
 function label:SetPoint(point,relative,relativePoint,x,y)self.anchor={point,relative,relativePoint,x,y}end
end
hud:StyleUnit('player',PlayerFrame);hud:StyleUnit('target',TargetFrame)
busy=true
for _,art in ipairs({playerFlash,targetFlash,status,reputation})do
 art:SetAtlas('native-glow');assert(rawget(art,'texturePath')==nil)
 art:SetTexture('native-glow');assert(rawget(art,'texturePath')==nil)
 art:SetAlpha(1);assert(rawget(art,'texturePath')==nil)
end
local targetHealth=targetMain.HealthBarsContainer.HealthBar;local writes=targetHealth.flatWrites
targetHealth.texture:SetAtlas('native-slanted-fill');assert(targetHealth.flatWrites==writes+1)
assert(targetMain.HealthBarsContainer.RightText.anchor[2]==targetHealth)
assert(targetMain.ManaBar.RightText.anchor[2]==targetMain.ManaBar)
busy=false
targetMain.HealthBarsContainer:SetSize(126,20)
TargetFrame:Update()
assert(targetMain.HealthBarsContainer:GetWidth()==184 and targetMain.HealthBarsContainer:GetHeight()==22)
print('PASS: combat/status art stays empty through native atlas/texture/alpha resets; flat fill survives native atlas changes; bar labels stay inside bars')

Enum={StatusBarInterpolation={Immediate=0},StatusBarTimerDirection={ElapsedTime=0,RemainingTime=1}}
local casts={player={name='Shadow Bolt',icon=1},target={name='Fireball',icon=2}}
local channels={}
local restrictedDuration=setmetatable({},{__index=function()error('secret duration must not be inspected')end})
issecretvalue=function(value)return rawequal(value,restrictedDuration)end
function UnitCastingInfo(unit)local c=casts[unit];if c then return c.name,nil,c.icon end end
function UnitChannelInfo(unit)local c=channels[unit];if c then return c.name,nil,c.icon end end
function UnitCastingDuration()return restrictedDuration end
function UnitChannelDuration()return restrictedDuration end
function prototype:SetTimerDuration(duration,interpolation,direction)self.timer={duration,interpolation,direction}end
function prototype:SetValue(value)self.fillValue=value end
TargetFrameSpellBar=frame();PlayerCastingBarFrame.eventsRetired=false;TargetFrameSpellBar.eventsRetired=false
hud:CreateCastBars()
local playerCast=hud.castFrames.castplayer;local targetCast=hud.castFrames.casttarget
assert(playerCast~=targetCast and playerCast:IsShown()and targetCast:IsShown())
assert(playerCast.label.text=='Shadow Bolt'and targetCast.label.text=='Fireball')
assert(playerCast.fill.timer[1]==restrictedDuration and targetCast.fill.timer[3]==0)
assert(PlayerCastingBarFrame.alpha==0 and PlayerCastingBarFrame.scripts.OnEvent==nil)
assert(PlayerCastingBarFrame.eventsRetired and TargetFrameSpellBar.eventsRetired)
local oldFlow=auras.SetFlowLayoutMaximumLineSize
auras.SetFlowLayoutMaximumLineSize=function()error('anchor pass must not dirty layout')end
hud:LayoutTargetAuras(TargetFrame,true)
auras.SetFlowLayoutMaximumLineSize=oldFlow
print('PASS: native duplicate casts receive no events; aura anchor pass does not mutate flow layout')
local mapWidth=ProjectRuthlessCharDB.mapSize.width
assert(e:Apply('castplayer',{x=-100,y=-200,scale=1.1,width=310,height=28}))
assert(e:Apply('casttarget',{x=200,y=-180,scale=.9,width=240,height=20}))
assert(playerCast:GetWidth()==310 and playerCast:GetHeight()==28 and targetCast:GetWidth()==240)
assert(ProjectRuthlessCharDB.mapSize.width==mapWidth)
e.selected='casttarget';e:Resize('width',1);e:Resize('height',1)
assert(targetCast:GetWidth()==250 and targetCast:GetHeight()==22 and playerCast:GetWidth()==310)
e:Store().elements.castplayer=e:Capture(playerCast)
playerCast:SetSize(100,14);playerCast:Hide();playerCast:Show();assert(playerCast:GetWidth()==310)
busy=true;casts.target=nil;channels.target={name='Drain Life',icon=3}
targetCast.scripts.OnEvent(targetCast,'PLAYER_TARGET_CHANGED')
assert(targetCast.label.text=='Drain Life'and targetCast.fill.timer[3]==1)
channels.target=nil;targetCast.scripts.OnEvent(targetCast,'UNIT_SPELLCAST_CHANNEL_STOP');assert(not targetCast:IsShown())
casts.target={name='Restricted cast',icon=4}
targetCast.fill.SetTimerDuration=function()error('duration withheld by client')end
targetCast.scripts.OnEvent(targetCast,'UNIT_SPELLCAST_START')
assert(targetCast:IsShown()and targetCast.label.text=='Restricted cast'and targetCast.fill.fillValue==0)
casts.player=nil;playerCast.scripts.OnEvent(playerCast,'UNIT_SPELLCAST_STOP');assert(not playerCast:IsShown())
assert(not playerCast.scripts.OnUpdate and not targetCast.scripts.OnUpdate)
busy=false;issecretvalue=nil
print('PASS: independent owned player/target cast bars; native timer rendering of uninspected durations, channels/stop/target changes, separate persistent dimensions and no polling')
GetNetStats=function()return 0,0,40,120 end
hud:UpdateCastLatency(playerCast,1000,4000,false,nil)
assert(playerCast.latencyMs==120 and playerCast.castSeconds==3 and playerCast.latencyText.text=='120 ms')
local usable=playerCast:GetWidth()-playerCast.icon:GetWidth()-4
assert(math.abs(playerCast.latency:GetWidth()-usable*.04)<.001)
hud:UpdateCastLatency(targetCast,1000,5000,true,nil)
assert(targetCast.castChannel and targetCast.latencyMs==120)
issecretvalue=function(value)return rawequal(value,restrictedDuration)end
hud:UpdateCastLatency(targetCast,restrictedDuration,restrictedDuration,true,restrictedDuration)
assert(targetCast.latency:GetWidth()==2 and targetCast.latencyText.text=='120 ms')
issecretvalue=nil
GetNetStats=function()return 0,0,0,0 end
hud:UpdateCastLatency(playerCast,1000,4000,false,nil)
assert(not playerCast.latency:IsShown())
print('PASS: red latency zones use world latency and cast duration, support channels, hide for zero latency and avoid restricted-duration arithmetic')
casts.target={name='Cancelled but still returned',icon=4}
issecretvalue=function(value)return rawequal(value,restrictedDuration)end
local castQueries=0;local castingInfo=UnitCastingInfo
UnitCastingInfo=function(unit)castQueries=castQueries+1;return castingInfo(unit)end
for _,event in ipairs({'UNIT_SPELLCAST_STOP','UNIT_SPELLCAST_FAILED','UNIT_SPELLCAST_FAILED_QUIET','UNIT_SPELLCAST_INTERRUPTED','UNIT_SPELLCAST_CHANNEL_STOP'})do
 targetCast.scripts.OnEvent(targetCast,'UNIT_SPELLCAST_START','target','cast-a',1,10)
 local reads=castQueries
 targetCast.scripts.OnEvent(targetCast,event,'target','cast-a',1,10)
 assert(not targetCast:IsShown()and targetCast.label.text==''and castQueries==reads)
 targetCast.scripts.OnEvent(targetCast,'UNIT_SPELLCAST_DELAYED','target','cast-a',1,10)
 assert(not targetCast:IsShown()and castQueries==reads)
end
targetCast.scripts.OnEvent(targetCast,'UNIT_SPELLCAST_START','target','cast-new',1,12)
targetCast.scripts.OnEvent(targetCast,'UNIT_SPELLCAST_STOP','target','cast-old',1,11)
assert(targetCast:IsShown())
TargetFrame:Hide();assert(not targetCast:IsShown())
targetCast.scripts.OnEvent(targetCast,'UNIT_SPELLCAST_START','target','cast-new',1,12)
UnitExists=function(unit)return unit~='target'end
targetCast.scripts.OnEvent(targetCast,'PLAYER_TARGET_CHANGED')
assert(not targetCast:IsShown())
UnitExists=nil
print('PASS: stop/failure/interrupt/channel end hides immediately despite stale cast info; late updates do not resurrect; older stop cannot hide newer public-ID cast; target disappearance hides its cast bar')

local secretWidth=setmetatable({},{__sub=function()error("secret geometry arithmetic")end})
local oldSecret=issecretvalue;issecretvalue=function(v)return rawequal(v,secretWidth)or oldSecret(v)end
local oldWidth=playerCast.GetWidth;playerCast.GetWidth=function()return secretWidth end
hud:LayoutCastLatency(playerCast)
assert(playerCast.latency:GetWidth()==2)
playerCast.GetWidth=oldWidth
local oldIconWidth=playerCast.icon.GetWidth;playerCast.icon.GetWidth=function()return secretWidth end
hud:LayoutCastLatency(playerCast);assert(playerCast.latency:GetWidth()==2)
playerCast.icon.GetWidth=oldIconWidth;issecretvalue=oldSecret
print("PASS: secret cast and icon geometry uses a thin latency marker without arithmetic")

local portraitModel=TargetFrame.ruiPortrait
local originalBind=portraitModel.SetUnit
portraitModel.SetUnit=function()return false end
hud:RefreshPortraits("target");assert(rawget(portraitModel,"modelUnit")==nil)
portraitModel.SetUnit=originalBind
hud:RefreshPortraits("target");assert(portraitModel.modelUnit=="target"and portraitModel.blend==false)
TargetFrame:Hide();hud:RefreshPortraits("target");assert(portraitModel.modelUnit=="target")
print("PASS: portrait rebinding clears stale models, disables blending and refreshes across hidden frame transitions; denied binding never retains old identity")

local castHeight=playerCast.GetHeight
local priorSecret=issecretvalue
issecretvalue=function(v)return rawequal(v,secretWidth)or priorSecret(v)end
playerCast.GetHeight=function()return secretWidth end
playerCast.scripts.OnSizeChanged(playerCast)
playerCast.GetHeight=castHeight;issecretvalue=priorSecret
TargetFrame:Show();busy=false
TargetFrame:CheckClassification()
assert(targetMain.HealthBarsContainer:GetWidth()==184)
print("PASS: restricted cast resize performs no geometry arithmetic; classification refresh restores target bar width")

-- Forever presentation touches artwork only, never gameplay state or placement.
function prototype:GetObjectType()return 'Frame'end
function prototype:GetFrameLevel()return 5 end
function prototype:GetChildren()return table.unpack(rawget(self,'children')or {})end
function prototype:EnableMouse(value)self.mouseEnabled=value end
function prototype:SetStatusBarTexture(value)self.statusTexture=value end
function prototype:SetTexCoord(...)self.coords={...}end
ActionButton1=frame();ActionButton1.icon=frame();ActionButton1.HotKey=frame()
local secureClick=function()end;ActionButton1:SetScript('OnClick',secureClick)
ChatFrame1=frame();ChatFrame1Tab=frame()
MainStatusTrackingBarContainer=frame();local xp=frame();xp.StatusBar=frame();xp.StatusBar.Background=frame();xp.ExhaustionLevelFillBar=frame()
MainStatusTrackingBarContainer.children={xp}
local meter={baseframe=frame()}
function meter:SetBackgroundColor(r,g,b)self.bg={r,g,b}end
function meter:SetBackgroundAlpha(value)self.bgAlpha=value end
Details={GetAllInstances=function()return {meter}end,CreateInstance=function()end}
AUI.isForever=true;busy=false
assert(load(STYLE_SOURCE))('RUI',AUI)
local style=AUI.modules.ForeverStyle
local profession=frame();profession.Background=frame();profession.StatusBar=frame()
profession.StatusBar.Background=frame();profession.StatusBar.Border=frame();profession.StatusBar.Fill=frame()
local professionButton=frame();professionButton.IconTexture=frame();professionButton.IconTextureOverlay=frame();professionButton.Flash=frame()
local professionClick=function()end;professionButton:SetScript('OnClick',professionClick);profession.spellButtons={professionButton}
style:ProfessionCard(profession,false)
assert(professionButton.IconTexture.coords[1]==.07 and professionButton.scripts.OnClick==professionClick)
assert(professionButton.IconTexture.point[2]==-3 and professionButton.IconTexture.point[3]==3)
assert(style.surfaces[professionButton]and style.surfaces[profession.StatusBar])
assert(not style.surfaces[profession.StatusBar.Fill])
print('PASS: native profession icons stay bounded in their buttons; click handlers and native rank fill retained')
local actionX,chatWidth=ActionButton1.x,ChatFrame1:GetWidth()
style:Apply()
assert(ActionButton1.scripts.OnClick==secureClick and ActionButton1.x==actionX and ChatFrame1:GetWidth()==chatWidth)
assert(style.surfaces[ActionButton1].mouseEnabled==false and style.surfaces[ChatFrame1]and not style.surfaces[meter.baseframe])
assert(xp.StatusBar.statusTexture=='Interface\\Buttons\\WHITE8X8'and meter.bgAlpha==nil)
local function surfaceCount()local n=0;for _ in pairs(style.surfaces)do n=n+1 end;return n end
local count=surfaceCount();style:Apply();assert(surfaceCount()==count)
busy=true;local combatButton=frame();ActionButton2=combatButton;style:Apply();assert(style.buttons[combatButton]==nil and style.pending)
busy=false;style.resting=true;style:Apply();assert(style.buttons[combatButton]==nil)
style.resting=nil;style:Apply();assert(style.buttons[combatButton])
AUI.isForever=false;ActionButton3=frame();style:Apply();assert(style.buttons[ActionButton3]==nil)
print('PASS: Forever surfaces preserve clicks/values/positions, reuse assets and defer combat/grace; external meters remain untouched')

-- Precise coordinates use the same screen units regardless of element scale.
AUI.isForever=true;busy=false;e:Show();e.selected='quests'
e:SetCoordinate('x','123.5');e:SetCoordinate('y','-42.25')
assert(math.abs(e:Capture(target).x-123.5)<.001 and math.abs(e:Capture(target).y+42.25)<.001)
local oldX=e:Capture(target).x;e:SetCoordinate('x','not a number');assert(e:Capture(target).x==oldX)
local all=e.targets;e.targets={quests=all.quests};e.gridSize=16;e.snapping=true
local sx,sy=e:Snap('quests',123,59);assert(sx==128 and sy==64)
e:UpdateGrid();local lineCount=#e.gridLines;e:UpdateGrid();assert(#e.gridLines==lineCount)
e:Close();assert(not e.gridFrame:IsShown());e.targets=all
assert(e.targets.chat1 and not e.targets.chat2 and not e.targets.chat5)
FocusFrame:Hide();e:Show();assert(not e.movers.focus:IsShown())
HUD_EDIT_MODE_MENU='Edit Mode';GameMenuFrame=frame()
local nativeClick=function()error('Native editor must not open')end
function GameMenuFrame:InitButtons()local b=frame();b:SetText(HUD_EDIT_MODE_MENU);b:SetScript('OnClick',nativeClick);self.buttons={b}end
local hideCount=0;function HideUIPanel(f)hideCount=hideCount+1;f:Hide()end
e:InstallGameMenuEntry();GameMenuFrame:InitButtons();assert(GameMenuFrame.buttons[1]:GetText()=='RUI Edit Mode')
GameMenuFrame.buttons[1].scripts.OnClick();assert(hideCount==1 and e.frame:IsShown())
busy=true;GameMenuFrame.buttons[1].scripts.OnClick();assert(hideCount==1);busy=false
function prototype:SetTexture(value)self.texture=value end
-- Static art cannot reappear when native state code reapplies an atlas.
ActionButton4=frame();ActionButton4.SlotArt=frame();ActionButton4.NormalTexture=frame()
ChatFrame1EditBox=frame();ChatFrame1EditBoxLeft=frame();ChatFrame1EditBoxFocusMid=frame()
MainStatusTrackingBarContainer.BarFrameTexture=frame()
style:Apply();ActionButton4.SlotArt:SetAtlas('blizzard-art');ChatFrame1EditBoxLeft:SetTexture('blizzard-art')
assert(rawget(ActionButton4.SlotArt,'texture')==nil and rawget(ChatFrame1EditBoxLeft,'texture')==nil)
assert(style.surfaces[ChatFrame1EditBox]and rawget(MainStatusTrackingBarContainer.BarFrameTexture,'texture')==nil)
print('PASS: exact decimal coordinates, adjustable cached grid, one chat dock, inactive preview filtering, RUI menu entry/combat guard and persistent static-art removal')

do
 local oldXP,oldMax,oldRest,oldTooltip=UnitXP,UnitXPMax,GetXPExhaustion,GameTooltip
 local current,maximum,rested=250,1000,400
 UnitXP=function()return current end;UnitXPMax=function()return maximum end;GetXPExhaustion=function()return rested end
 local xp=frame();xp.StatusBar=frame();xp.StatusBar:SetWidth(200);xp.ExhaustionLevelFillBar=frame();xp.ExhaustionTick=frame()
 function xp.ExhaustionTick:UpdateTickPosition()end
 style:TrackingBar(xp);local fill=xp.ruthlessRestedFill
 assert(fill:IsShown()and math.abs(fill:GetWidth()-80)<.001)
 assert(fill.point[4]==50)
 current=900;rested=500;xp.ExhaustionTick:UpdateTickPosition();assert(math.abs(fill:GetWidth()-20)<.001)
 local amount;GameTooltip={AddDoubleLine=function(_,label,value)assert(label=='Rested bonus XP');amount=value end,Show=function()end}
 xp.scripts.OnEnter(xp);assert(tostring(amount)=='500')
 rested=0;style:UpdateRestedXP(xp);assert(not fill:IsShown())
 rested=secretWidth;style:UpdateRestedXP(xp);assert(not fill:IsShown())
 rested=200;maximum=0;style:UpdateRestedXP(xp);assert(not fill:IsShown())
 maximum=1000;current=400;busy=true;style:UpdateRestedXP(xp);assert(fill:IsShown()and math.abs(fill:GetWidth()-40)<.001);busy=false
 UnitXP,UnitXPMax,GetXPExhaustion,GameTooltip=oldXP,oldMax,oldRest,oldTooltip
 print('PASS: rested XP segment starts at current XP, clamps overflowing bonus, updates in combat, hides zero/restricted values and adds full numerical bonus to native tooltip')
end

local clock=100;function GetTime()return clock end
local scans=0
C_UnitAuras={GetAuraDataByIndex=function()scans=scans+1;return nil end,GetAuraDataByAuraInstanceID=function()return nil end}
function prototype:SetCooldown(start,duration)self.startTime=start;self.duration=duration end
assert(load(BUFF_SOURCE))('RUI',AUI);local expiring=AUI.modules.ForeverExpiringBuffs
expiring:OnPlayerLogin()
expiring:Remember({auraInstanceID=1,isHelpful=true,expirationTime=125,duration=60,icon=123})
expiring:Remember({auraInstanceID=2,isHelpful=true,expirationTime=145,duration=60,icon=124})
expiring:Remember({auraInstanceID=3,isHelpful=false,expirationTime=120,duration=60,icon=125})
expiring:Render();assert(#expiring.icons==1 and expiring.icons[1].texture.texture==123)
clock=116;expiring:Render();assert(#expiring.icons==2)
clock=126;expiring:Render();assert(not expiring.icons[2]:IsShown()and expiring.icons[1].texture.texture==124)
local scanCount=scans;busy=true;expiring:Update({isFullUpdate=true});assert(scans==scanCount and expiring.needsScan)
expiring:Update({removedAuraInstanceIDs={2}});expiring:Render();assert(not expiring.icons[1]:IsShown())
local previousSecret=issecretvalue;issecretvalue=function(v)return rawequal(v,secretWidth)or previousSecret(v)end
expiring:Remember({auraInstanceID=4,isHelpful=true,expirationTime=secretWidth,duration=60});assert(not expiring.auras[4]);issecretvalue=previousSecret
busy=false
local restrictedAuras=true;C_Secrets={ShouldAurasBeSecret=function()return restrictedAuras end}
local auraQueries=0;C_UnitAuras.GetAuraDataByAuraInstanceID=function()auraQueries=auraQueries+1;error('Restricted aura query')end
expiring:Scan();expiring:Update({updatedAuraInstanceIDs={4}});assert(scans==scanCount and auraQueries==0 and expiring.needsScan)
restrictedAuras=false;expiring:Update({isFullUpdate=true});assert(scans>scanCount and not expiring.needsScan);C_Secrets=nil
print('PASS: expiring helpful buffs cross the 30-second threshold, expire/remove cleanly, omit debuffs/restricted timing and defer full scans in combat')

local nativeElement=frame();nativeElement.system=1;nativeElement.settingDisplayInfoMap={[1]={}};nativeElement.nativeValue=12
function nativeElement:GetSettingValue(setting)return self.nativeValue end
EditModeManagerFrame={OnSystemSettingChange=function(_,f,setting,value)f.nativeValue=value end}
e:Attach('native-test','Native settings',nativeElement);e:Show();e.selected='native-test'
local original=e:Capture(nativeElement);assert(original.nativeSettings[1]==12)
EditModeSystemSettingsDialog=frame()
function EditModeSystemSettingsDialog:AttachToSystemFrame(f)self.attachedToSystem=f;self:Show()end
function EditModeSystemSettingsDialog:OnSettingValueChanged(setting,value)EditModeManagerFrame:OnSystemSettingChange(self.attachedToSystem,setting,value)end
e:OpenNativeSettings();EditModeSystemSettingsDialog:OnSettingValueChanged(1,6)
assert(e:Store().elements['native-test'].nativeSettings[1]==6)
e:Apply('native-test',original);assert(nativeElement.nativeValue==12)
e:Save('Native settings');nativeElement.nativeValue=3;e:Load('Native settings');assert(nativeElement.nativeValue==12)
e:Close();assert(not EditModeSystemSettingsDialog:IsShown())
AUI.Theme={text={.8,.8,.8},muted={.6,.6,.6},border={.2,.2,.2}}
function AUI:CreateSmoothScrollFrame()return frame()end
assert(load(MENU_SOURCE))('RUI',AUI);local menu=AUI.modules.Menu;menu.optionControls={};menu.panels={}
function menu:CreateOptionsPanel()return frame()end
local checks={};function menu:CreateCheckbox(parent,label,description,y,getter,setter)checks[#checks+1]={getter=getter,setter=setter}end
function menu:CreateAction()return frame()end
local settingValues={PROXY_SHOW_ACTIONBAR_2=false};local setCount=0
Settings={GetSetting=function(name)return {GetValue=function()return settingValues[name]end,SetValue=function(_,value)settingValues[name]=value;setCount=setCount+1 end}end}
menu:CreateActionBarOptions(frame());assert(#checks==9 and checks[1].getter()==false)
checks[1].setter(true);assert(settingValues.PROXY_SHOW_ACTIONBAR_2 and setCount==1)
busy=true;checks[1].setter(false);assert(settingValues.PROXY_SHOW_ACTIONBAR_2 and setCount==1);busy=false
print('PASS: native element settings preview/save/load through RUI and native bar setting proxies retain combat guard and registered callbacks')

local own,left,right=frame(),frame(),frame();own:SetSize(100,50);left:SetSize(100,50);right:SetSize(100,50)
left.x=0;right.x=400;local priorTargets=e.targets;e.targets={own={frame=own},left={frame=left},right={frame=right}}
e.gridSize=8;e.snapping=true
local equalX=e:Snap('own',205,0);assert(equalX==200)
e.targets={own={frame=own},left={frame=left}};left:SetSize(200,50)
local edgeX=e:Snap('own',49,0);assert(edgeX==50)
e.targets=priorTargets
local oldWidth=own.GetWidth;own.GetWidth=function()return secretWidth end
local previousSecret=issecretvalue;issecretvalue=function(v)return rawequal(v,secretWidth)or previousSecret(v)end
assert(e:Capture(own)==nil);own.GetWidth=oldWidth;issecretvalue=previousSecret
print('PASS: nearest edge alignment and equal-gap placement; restricted geometry is omitted safely')

AUI.modules.QuestLocations={tooltipIndex={[100]={{id=10,item=300}},[101]={{id=11}}},UpdateTooltipIndex=function()end,SetEnabled=function()end}
local objectives={[10]={{objectID=300,type='item',finished=false}},[11]={{objectID=101,type='monster',finished=false}}}
C_QuestLog={GetQuestObjectives=function(id)return objectives[id]end}
local npc=100;UnitGUID=function()return 'Creature-0-0-0-0-'..npc..'-000000'end
local classification='normal';UnitClassification=function()return classification end
assert(load(HINT_SOURCE))('RUI',AUI);local hints=AUI.modules.ForeverNameplateHints
hints:OnPlayerLogin();assert(hints:Kind('nameplate1')=='loot')
npc=101;assert(hints:Kind('nameplate1')=='kill')
classification='elite';assert(hints:Kind('nameplate1')=='elite')
npc=100;assert(hints:Kind('nameplate1')=='loot')
objectives[10][1].finished=true;hints:Build();classification='normal';assert(hints:Kind('nameplate1')==nil)
local priorSecret=issecretvalue;UnitGUID=function()return secretWidth end;issecretvalue=function(v)return rawequal(v,secretWidth)or priorSecret(v)end
assert(hints:Kind('nameplate1')==nil);issecretvalue=priorSecret
print('PASS: cached nameplate hints distinguish needed loot/kill, elite skull, completed objectives and restricted identities without per-plate quest scanning')

-- Native bag skin leaves Blizzard item interactions and indicators intact.
local bag=frame();bag.CloseButton=frame();bag.SearchBox=frame();bag.SearchBox.Left=frame();bag.Bg=frame();bag.PortraitContainer=frame();bag.PortraitContainer.portrait=frame();bag.PortraitContainer.portrait:SetTexture("bag art");bag.TitleContainer=frame();bag.TitleContainer.TitleText=frame()
local slot=frame();slot.icon=frame();slot.ItemSlotBackground=frame();slot.ItemSlotBackground:SetTexture("leather");slot.IconBorder=frame();slot.IconBorder:SetTexture("quality");slot.IconQuestTexture=frame();slot.JunkIcon=frame();slot.Cooldown=frame()
local itemClick=function()end;slot:SetScript('OnClick',itemClick)
bag.EnumerateItems=function()return ipairs({slot})end;bag.EnumerateValidItems=bag.EnumerateItems;bag.Update=function()end
local bagMenuClick=function()end;bag.PortraitButton=frame();bag.PortraitButton:SetScript("OnClick",bagMenuClick)
ContainerFrameCombinedBags=bag
function UpdateContainerFrameAnchors()bag:SetPoint("CENTER",UIParent,"CENTER",410,-290)end
local bagX,bagWidth=bag.x,bag:GetWidth();style:Inventory()
assert(style.surfaces[bag]and style.surfaces[slot]and style.surfaces[bag.SearchBox])
assert(bag.PortraitButton.scripts.OnClick==bagMenuClick and style.surfaces[bag.PortraitButton])
assert(slot.scripts.OnClick==itemClick and bag.x==bagX and bag:GetWidth()==394)
assert(slot.IconBorder.texture=="quality")
assert(rawget(slot.ItemSlotBackground,"texture")==nil and rawget(bag.PortraitContainer.portrait,"texture")==nil and bag.Bg.alpha==0)
assert(not style.surfaces[slot.IconQuestTexture]and not style.surfaces[slot.Cooldown])
bag.Update();assert(style.inventoryFrames[bag])
busy=true;local second=frame();style:InventoryItem(second);assert(not style.buttons[second]and style.pending)
busy=false;style:InventoryItem(second);assert(style.buttons[second])
print('PASS: native bag styling preserves clicks, layout and quest/cooldown indicators; combat styling deferred')

-- Owned party presentation must never enter native pooled unit/aura update paths.
local oldParty=PartyFrame;PartyFrame=frame();PartyFrame.MemberFrame1=frame()
local nativeMember=PartyFrame.MemberFrame1
local function forbiddenNative()error('RUI must not call native party initialization, layout or unit updates')end
PartyFrame.Layout=forbiddenNative;PartyFrame.UpdatePartyFrames=forbiddenNative
nativeMember.Setup=forbiddenNative;nativeMember.UpdateArt=forbiddenNative;nativeMember.UpdateMember=forbiddenNative
hud.partySuppressed=nil;hud.resting=nil;hud:DiscoverParty()
assert(PartyFrame.alpha==0 and not rawget(nativeMember,'ruiPortrait')and not e.targets.party1)
assert(hud.partyFrame.surfaceOpacity==math.max(.72,ProjectRuthlessDB.questWorkspace.opacity)and hud.partyFrame.strata=="LOW")
local member=hud.registered.party1
assert(member~=nativeMember and member.ruiPortrait and member.ruiSurface)
assert(e.targets.party.frame==hud.partyFrame and hud.partyFrame~=PartyFrame and e.targets.party.preview)
assert(hud.partyFrame:GetWidth()==230 and hud.partyFrame:GetHeight()==398)
assert(member.stateDrivers.visibility=='[@party1,exists] show; hide')
assert(hud.partyFrame.stateDrivers.visibility=='[group:party,nogroup:raid] show; hide')
assert(not e.targets.party0 and member:GetWidth()==224 and member.ManaBar:GetWidth()==166)
assert(member.ruiSurface:GetWidth()==224 and member.ruiSurface:GetHeight()==56 and member.ruiSurface.alpha==1)
hud:StyleUnit("player",PlayerFrame);assert(PlayerFrame:GetHeight()==64 and PlayerFrame.ruiPortraitBox:GetWidth()==52)
ProjectRuthlessDB.general.partyGrouped=true;hud:ApplySettings();assert(member.ruiSurface.alpha==0 and hud.partyFrame.ruiAccent:IsShown())
ProjectRuthlessDB.general.partyGrouped=false;hud:ApplySettings();assert(member.ruiSurface.alpha==1 and not hud.partyFrame.ruiAccent:IsShown())
assert(PartyFrame.Layout==forbiddenNative and nativeMember.UpdateArt==forbiddenNative)
PartyFrame:SetAlpha(1);assert(PartyFrame.alpha==0)
local savedHealth,savedMax,savedPower,savedPowerMax=UnitHealth,UnitHealthMax,UnitPower,UnitPowerMax
local opaque=setmetatable({},{__eq=function()error('secret compare')end,__lt=function()error('secret order')end,__div=function()error('secret divide')end})
UnitHealth=function()return opaque end;UnitHealthMax=UnitHealth;UnitPower=UnitHealth;UnitPowerMax=UnitHealth
function prototype:SetMinMaxValues(lo,hi)self.minimum=lo;self.maximum=hi end
function prototype:SetValue(v)self.value=v end
local priorPowerText=member.ManaBar.RightText.text
busy=true;member.scripts.OnEvent(member,'UNIT_HEALTH','party1')
assert(rawequal(member.HealthBarContainer.HealthBar.value,opaque)and rawequal(member.HealthBarContainer.HealthBar.maximum,opaque))
assert(rawequal(member.ManaBar.RightText.text,priorPowerText),'health event must not repaint power')
member.scripts.OnEvent(member,'UNIT_POWER_UPDATE','party1')
assert(rawequal(member.ManaBar.RightText.text,opaque))
local before=hud.partyFrame:GetWidth();hud:DiscoverParty();assert(hud.partyFrame:GetWidth()==before and hud.needsDiscovery)
busy=false;UnitHealth,UnitHealthMax,UnitPower,UnitPowerMax=savedHealth,savedMax,savedPower,savedPowerMax
-- Native inbound aura containers handle all aura reads, cooldowns and tooltips.
local auraReads=0;C_UnitAuras={GetAuraSlots=function()auraReads=auraReads+1;error('forbidden aura scan')end,GetAuraDataByIndex=function()auraReads=auraReads+1;error('forbidden aura scan')end}
for i=0,4 do
    local row=hud.registered['party'..i];local unit=i==0 and 'player'or 'party'..i
    assert(#row.ruiAuras==3)
    assert(row.ruiPortrait.fixedStrata==false and row.ruiPortrait.fixedLevel==false and row.ruiPortrait.modelLayer=="ARTWORK"and row.ruiPortrait.ignoreAlpha==false and row.ruiPortraitBox.clips)
    for j,container in ipairs(row.ruiAuras)do
        local group=container.groups.party
        assert(container.widgetKind=='AuraContainer'and container.template=='CustomAuraContainerTemplate'and container.unitToken==unit and container.enabled)
        assert(group.filter==(j==1 and 'HELPFUL'or 'HARMFUL')and group.options.maxFrameCount==(j==3 and 2 or 4))
        assert(container.point[3]=='TOPRIGHT'and container.fixedStrata==false)
        assert(group.button.w==(j==3 and 28 or 16)and group.button.boundCooldown.countdownFont.fontSize==(j==3 and 10 or 8))
        if j==2 then assert(group.options.candidateFilters.excludeDispelTypes.Magic)elseif j==3 then assert(group.options.candidateFilters.includeDispelTypes.Magic)end
        assert(group.button.boundIcon and group.button.boundCooldown and group.button.boundCount)
    end
    assert(row.ruiPet.attributes.unit==(i==0 and 'pet'or 'partypet'..i))
    assert(row.ruiPet.attributes.type1=='target'and row.ruiPet.attributes.type2=='togglemenu')
end
local pet=member.ruiPet
busy=true;UnitHealth=function()return opaque end;UnitHealthMax=UnitHealth;UnitPower=UnitHealth;UnitPowerMax=UnitHealth
pet.scripts.OnEvent(pet,'UNIT_HEALTH','partypet1');assert(rawequal(pet.ruiHealth.value,opaque)and rawequal(pet.ruiPower.maximum,opaque))
busy=false;UnitHealth,UnitHealthMax,UnitPower,UnitPowerMax=savedHealth,savedMax,savedPower,savedPowerMax
local ready='waiting';GetReadyCheckStatus=function()return ready end
member.scripts.OnEvent(member,'READY_CHECK');assert(member.ruiReady:IsShown()and member.ruiReady.texturePath=='UI-LFG-PendingMark-Raid')
ready='ready';member.scripts.OnEvent(member,'READY_CHECK_CONFIRM');assert(member.ruiReady.texturePath=='UI-LFG-ReadyMark-Raid')
ready=nil;member.scripts.OnEvent(member,'READY_CHECK_FINISHED');assert(member.ruiReady:IsShown());local finish=timers[#timers].fn
ready='waiting';member.scripts.OnEvent(member,'READY_CHECK');finish();assert(member.ruiReady:IsShown()) -- old timeout cannot hide new check
member.scripts.OnEvent(member,'READY_CHECK_FINISHED');assert(member.ruiReady.texturePath=='UI-LFG-DeclineMark-Raid');timers[#timers].fn();assert(not member.ruiReady:IsShown())
ready='notready';member.scripts.OnEvent(member,'READY_CHECK_CONFIRM');assert(member.ruiReady.texturePath=='UI-LFG-DeclineMark-Raid')
member.scripts.OnEvent(member,'GROUP_ROSTER_UPDATE');assert(not member.ruiReady:IsShown()and auraReads==0)
GetReadyCheckStatus=nil;C_UnitAuras=nil
PartyFrame=oldParty
print('PASS: native inbound party aura groups/renderer binding, owned secure pets with opaque combat values, ready check lifecycle/timeout isolation and no addon aura reads')
print('PASS: owned five-row party group, secure visibility drivers, native pool untouched and opaque health/power rendered without arithmetic in combat')
do
 local tot=hud.targetOfTarget;assert(tot and e.targets.targettarget and hud.registered.targettarget==tot)
 assert(tot.attributes.unit=='targettarget'and tot.attributes.type1=='target'and tot.attributes.type2=='togglemenu')
 assert(tot.stateDrivers.visibility=='[@targettarget,exists] show; hide')
 local oldName=UnitName;UnitName=function(unit)assert(unit=='targettarget');return 'Target victim'end
 tot.scripts.OnEvent(tot,'UNIT_TARGET','target');assert(tot.Name.text=='Target victim')
 local before=tot.w;busy=true;UnitHealth=function()return opaque end;UnitHealthMax=UnitHealth;UnitPower=UnitHealth;UnitPowerMax=UnitHealth
 tot.scripts.OnEvent(tot,'UNIT_HEALTH','targettarget');assert(rawequal(tot.ruiHealth.value,opaque)and tot.w==before)
 tot.scripts.OnEvent(tot,'UNIT_POWER_UPDATE','targettarget');assert(rawequal(tot.ruiPower.maximum,opaque)and tot.w==before)
 busy=false;UnitName=oldName;UnitHealth,UnitHealthMax,UnitPower,UnitPowerMax=savedHealth,savedMax,savedPower,savedPowerMax
 local count=hud.targetOfTarget;hud:CreateTargetOfTarget();assert(hud.targetOfTarget==count)
 print('PASS: owned target-of-target secure clicks/visibility, saved mover, target victim changes and opaque health/power during combat without native initialization')
end


local sorts=0;C_Container={SortBags=function()sorts=sorts+1 end,GetContainerNumFreeSlots=function()return 2 end}
style:BagSettings().autoSort=true;bag:Show();assert(sorts==1)
bag.Update();assert(sorts==1)
busy=true;style:SortOnOpen(bag);assert(sorts==1 and style.pendingBagSort==bag)
busy=false;style:SortOnOpen(bag);assert(sorts==2 and not style.pendingBagSort)
style:BagSettings().autoSort=false;style:SortOnOpen(bag);assert(sorts==2)
style:BagSettings().columns=8;style:InventoryLayout(bag);assert(bag:GetWidth()==318 and slot:GetWidth()==36)
local menuCallback;Menu={ModifyMenu=function(tag,callback)assert(tag=='MENU_CONTAINER_FRAME_COMBINED');menuCallback=callback end}
style:BagMenu();assert(menuCallback)
local settingsShortcut;local root={CreateDivider=function()end,CreateTitle=function()end,CreateCheckbox=function()error('Bag options have one settings owner')end,CreateButton=function(_,label,callback)assert(label=='RUI bag settings');settingsShortcut=callback end}
menuCallback(nil,root);assert(type(settingsShortcut)=='function')
print('PASS: compact top-left inventory measures to contents; auto-sort toggles persist and run on opening only, defer in combat; native bag menu extended')

local oldChar,oldAccount=ProjectRuthlessCharDB,ProjectRuthlessDB.layoutProfiles
ProjectRuthlessDB.layoutProfiles=nil
ProjectRuthlessCharDB={layoutEditor={elements={},layouts={Main={quests={x=120,y=-80,scale=1,width=300,height=400}}},active='Main'}}
local shared=e:AccountLayouts();assert(shared.layouts.Main and shared.default==nil)
assert(e:SetDefaultProfile('Main'));assert(shared.default=='Main')
ProjectRuthlessCharDB={};e:InitializeCharacter()
assert(e:Store().active=='Main'and e:Store().elements.quests.x==120)
e:Store().elements.quests.x=999;assert(shared.layouts.Main.quests.x==120)
e:InitializeCharacter();assert(e:Store().elements.quests.x==999)
ProjectRuthlessCharDB={layoutEditor={elements={quests={x=42}},layouts={}}};e:InitializeCharacter();assert(e:Store().elements.quests.x==42)
local menuNames={};local oldMenu=MenuUtil
MenuUtil={CreateContextMenu=function(_,builder)builder(nil,{CreateTitle=function()end,CreateRadio=function(_,label)menuNames[#menuNames+1]=label end})end}
e:ProfileMenu({});assert(#menuNames==1 and menuNames[1]:find('Main',1,true))
assert(e:Save('Other'));assert(shared.default=='Main');assert(e:Load('Other'));assert(shared.default=='Main')
assert(e:SetDefaultProfile(nil));assert(shared.default==nil and shared.defaultChosen)
MenuUtil=oldMenu;ProjectRuthlessCharDB=oldChar;ProjectRuthlessDB.layoutProfiles=oldAccount
print('PASS: account layout migration/default, first-character initialization before attachment, independent copies, existing-character preservation and dropdown entries')

-- Actual native swing events own timing; casts/channels have priority.
Enum.PlayerSwingType={MainHand=0,OffHand=1,Ranged=2}
local swingNow=100;GetTime=function()return swingNow end
casts.player=nil;channels.player=nil;hud:StopCast('player')
hud:SwingEvent('PLAYER_SWING',2,0);assert(playerCast.swingActive and playerCast:IsShown()and hud.swingEnd==102)
swingNow=101;playerCast.scripts.OnUpdate();assert(playerCast.latencyText.text:match('^1.0 s') and playerCast.latencyMs>=0)
hud:SwingEvent('PLAYER_SWING',9,1);local offCast=hud.castFrames.castoffhand;assert(hud.swingEnd==102 and hud.offSwingEnd==110 and offCast.swingActive and e.targets.castoffhand.preview)
casts.player={name='Heal',icon=1};hud:RefreshCast('player');assert(playerCast.castActive and not playerCast.swingActive and not playerCast.scripts.OnUpdate)
hud:SwingEvent('PLAYER_SWING',3,0);assert(playerCast.castActive and hud.swingEnd==104)
casts.player=nil;hud:StopCast('player');assert(playerCast.swingActive)
swingNow=105;playerCast.scripts.OnUpdate();assert(not playerCast:IsShown()and not playerCast.scripts.OnUpdate and offCast:IsShown())
hud:SwingEvent('PLAYER_SWING',2,2);assert(playerCast.label.text=='Auto shot')
local swingEnd=hud.swingEnd;local offEnd=hud.offSwingEnd
for _,event in ipairs({'PLAYER_TARGET_CHANGED','PLAYER_LEAVE_COMBAT','STOP_AUTOREPEAT_SPELL'})do hud:SwingEvent(event);assert(playerCast:IsShown()and hud.swingEnd==swingEnd and hud.offSwingEnd==offEnd)end
hud:CastEvent('player','UNIT_SPELLCAST_STOP','HeroicStrikeQueued',78);assert(playerCast:IsShown()and playerCast.swingActive and playerCast.scripts.OnUpdate and hud.swingEnd==swingEnd)
hud:CastEvent('player','UNIT_SPELLCAST_START','HeroicStrikeQueued',78);assert(playerCast:IsShown()and playerCast.swingActive and playerCast.scripts.OnUpdate and hud.swingEnd==swingEnd) -- no timed cast: keep native swing
playerCast.castActive=true;casts.player=nil;channels.player=nil
hud:SwingEvent('PLAYER_SWING',2,0);assert(playerCast:IsShown()and playerCast.swingActive and not playerCast.castActive) -- stale queued ability reconciled against native casting state
hud:SwingEvent('PLAYER_DEAD');assert(not playerCast:IsShown()and not offCast:IsShown()and not offCast.scripts.OnUpdate)
hud:SwingEvent('PLAYER_SWING',secretWidth,0);assert(not hud.swingEnd)
print('PASS: native swing timing, off-hand isolation, cast priority/resume, ranged label, expiry/stop, restricted duration')

-- Account profiles save window subscriptions and create missing tabs only once.
local chatInfo={{'General',14,0,0,0,.5,true,true,true,false},{'Combat Log',12,0,0,0,.2,true,true,true,false},{'Guild',16,.1,.2,.3,.6,true,true,true,false}}
for id=1,5 do local f=frame();_G['ChatFrame'..id]=f;f.messages={'SAY','GUILD'};f.channels={'General',1};f.id=id;f.isTemporary=false
 function f:RemoveAllMessageGroups()self.messages={}end;function f:AddMessageGroup(g)table.insert(self.messages,g)end
 function f:RemoveAllChannels()self.channels={}end;function f:AddChannel(c)table.insert(self.channels,c);table.insert(self.channels,1)end
end
ChatFrame4.isTemporary=true;chatInfo[4]={'Whisper',12,0,0,0,0,true,false,false,false}
FCF_GetChatWindowInfo=function(id)return table.unpack(chatInfo[id]or {'',12,0,0,0,0,false,false,false,false})end
GetChatWindowMessages=function(id)return table.unpack(_G['ChatFrame'..id].messages)end
GetChatWindowChannels=function(id)return table.unpack(_G['ChatFrame'..id].channels)end
FCF_SetWindowName=function(f,n)chatInfo[f.id][1]=n end
FCF_SetWindowColor=function(f,r,g,b)f.color={r,g,b}end;FCF_SetWindowAlpha=function(f,a)f.alpha=a end
FCF_SetChatWindowFontSize=function(_,f,n)f.fontSize=n end
FCF_SetLocked=function(f,v)f.locked=v end;FCF_SetUninteractable=function(f,v)f.uninteractable=v end
FCF_DockFrame=function(f)f.isDocked=true end;FCF_UnDockFrame=function(f)f.isDocked=false end
local created=0;FCF_OpenNewWindow=function(name)created=created+1;chatInfo[3]={'Guild',12,0,0,0,0,true,false,true,false};return ChatFrame3 end
local tabs=e:CaptureChat();assert(#tabs==3 and tabs[3].name=='Guild'and tabs[3].size==16)
chatInfo[3][7]=false;chatInfo[3][9]=false;ChatFrame3.messages={};assert(e:RestoreChat(tabs))
assert(created==1 and ChatFrame3.messages[2]=='GUILD'and ChatFrame3.fontSize==16 and ChatFrame3.alpha==.6)
assert(e:RestoreChat(tabs)and created==1)
busy=true;assert(not e:RestoreChat(tabs));busy=false
print('PASS: saved chat filters/channels/font/appearance, temporary tab exclusion, missing tab creation, repeat-load idempotence and combat guard')

GENERAL_CHAT_DOCK={};DEFAULT_CHAT_FRAME=ChatFrame1
FCFDock_GetChatFrames=function()return {ChatFrame1,ChatFrame3,ChatFrame2}end
FCFDock_GetSelectedWindow=function()return ChatFrame3 end
local selected;FCFDock_SelectWindow=function(_,f)selected=f end
local dockOrder={};FCF_DockFrame=function(f,index)f.isDocked=true;dockOrder[#dockOrder+1]={f,index}end
local savedTabs=e:CaptureChat();assert(savedTabs[2].dockIndex==3 and savedTabs[3].selected)
assert(e:RestoreChat(savedTabs));assert(dockOrder[2][1]==ChatFrame3 and dockOrder[2][2]==2 and selected==ChatFrame3)
local previousChar=ProjectRuthlessCharDB;local previousProfiles=ProjectRuthlessDB.layoutProfiles
ProjectRuthlessDB.layoutProfiles={layouts={Chat={quests={x=10,y=20,scale=1,width=300,height=200},__chat=savedTabs}},default='Chat',defaultChosen=true}
ProjectRuthlessCharDB={};e:InitializeCharacter()
assert(not e:Store().elements.__chat and #ProjectRuthlessCharDB.pendingLayoutChat==3)
ProjectRuthlessCharDB.pendingLayoutChat[3].name='Changed';assert(savedTabs[3].name=='Guild')
ProjectRuthlessCharDB=previousChar;ProjectRuthlessDB.layoutProfiles=previousProfiles
print('PASS: native dock order/selection and independently cloned new-character chat setup')

-- Realistic texture regions nested under Forever's frame-based end caps.
local function artTexture(asset)
 local t=frame();function t:GetObjectType()return 'Texture'end
 function t:GetAtlas()return rawget(self,"atlas")end;function t:GetTexture()return rawget(self,"texture")end
 function t:SetAtlas(a)self.atlas=a;self.texture=nil end
 function t:SetTexture(a)self.texture=a;self.atlas=nil end
 t:SetAtlas(asset);return t
end
MainActionBar=frame();MainActionBar.EndCaps=frame();MainActionBar.EndCaps.LeftEndCap=frame();MainActionBar.EndCaps.RightEndCap=frame()
local leftArt,rightArt=artTexture('gryphon-left'),artTexture('gryphon-right')
MainActionBar.EndCaps.LeftEndCap.Texture=leftArt;MainActionBar.EndCaps.RightEndCap.Texture=rightArt
MainActionBar.EndCaps.children={MainActionBar.EndCaps.LeftEndCap,MainActionBar.EndCaps.RightEndCap}
MainActionBar.EndCaps.LeftEndCap.GetRegions=function()return leftArt end;MainActionBar.EndCaps.RightEndCap.GetRegions=function()return rightArt end
MicroMenu=frame();MicroMenu.BackgroundArt=artTexture('micro-background')
local artButton=frame();artButton.NormalTexture=artTexture('gold-border');artButton.icon=artTexture('ability-icon')
artButton.GetNormalTexture=function(f)return f.NormalTexture end
artButton.SetNormalAtlas=function(f,a)f.NormalTexture:SetAtlas(a)end
ActionButton6=artButton
local beforeArtChar=ProjectRuthlessCharDB;local beforeArtProfiles=ProjectRuthlessDB.layoutProfiles
ProjectRuthlessCharDB={layoutEditor={elements={},layouts={},active='Art'}};ProjectRuthlessDB.layoutProfiles={layouts={Art={}}}
style.resting=nil;style:Apply()
assert(not style:BlizzardArtEnabled()and not leftArt:GetAtlas()and not rightArt:GetAtlas()and not artButton.NormalTexture:GetAtlas())
assert(artButton.icon:GetAtlas()=='ability-icon'and not MicroMenu.BackgroundArt:GetAtlas())
leftArt:SetAtlas('new-gryphon');artButton:SetNormalAtlas('native-border-refresh')
assert(not leftArt:GetAtlas()and not artButton.NormalTexture:GetAtlas())
assert(style:SetBlizzardArt(true));assert(leftArt:GetAtlas()=='new-gryphon'and rightArt:GetAtlas()=='gryphon-right'and artButton.NormalTexture:GetAtlas()=='native-border-refresh')
assert(ProjectRuthlessDB.layoutProfiles.layouts.Art.__art.blizzardArt)
local artState=e:Snapshot();assert(artState.__art.blizzardArt)
busy=true;assert(not style:SetBlizzardArt(false)and style:BlizzardArtEnabled());busy=false
assert(style:SetBlizzardArt(false));assert(not leftArt:GetAtlas()and not rightArt:GetAtlas())
-- Loading a legacy snapshot defaults to no art; new snapshots carry the choice.
e:Restore(artState);style:Apply();assert(style:BlizzardArtEnabled()and leftArt:GetAtlas()=='new-gryphon'and not e:Store().elements.__art)
e:Restore({});style:Apply();assert(not style:BlizzardArtEnabled()and not leftArt:GetAtlas())
ProjectRuthlessCharDB=beforeArtChar;ProjectRuthlessDB.layoutProfiles=beforeArtProfiles
print('PASS: nested end caps/menu trim removed by default, native atlas refresh suppressed, optional art restored, gameplay icons retained, profile serialization/legacy default and combat guard')

-- Native default positioning must be disabled before protected layout passes.
local oldManager=EditModeManagerFrame;local calls=0
local nativeBar=frame();nativeBar.system=1;nativeBar.systemInfo={isInDefaultPosition=true,anchorInfo={}}
function nativeBar:BreakFromFrameManager()self.managed=false end
EditModeManagerFrame={UpdateSystemAnchorInfo=function(_,f)
    assert(not busy);calls=calls+1
    local point,relative,relativePoint,x,y=f:GetPoint(1)
    f.systemInfo.anchorInfo={point=point,relativeTo=relative,relativePoint=relativePoint,offsetX=x*f:GetScale(),offsetY=y*f:GetScale()}
    f.systemInfo.isInDefaultPosition=false
end}
e:Attach('combat-bar','Combat bar',nativeBar)
assert(e:Apply('combat-bar',{x=112,y=-228,scale=.8}))
assert(not nativeBar.systemInfo.isInDefaultPosition and nativeBar.managed==false)
assert(nativeBar.systemInfo.anchorInfo.point=='CENTER'and nativeBar.systemInfo.anchorInfo.offsetX==112)
local function nativeReanchor()
    if nativeBar.systemInfo.isInDefaultPosition then nativeBar:SetPoint('CENTER',UIParent,'CENTER',700,200)
    else local a=nativeBar.systemInfo.anchorInfo;nativeBar:SetPoint(a.point,a.relativeTo,a.relativePoint,a.offsetX/nativeBar:GetScale(),a.offsetY/nativeBar:GetScale())end
end
busy=true;local writes=calls;nativeReanchor();assert(math.abs(e:Capture(nativeBar).x-112)<.001 and math.abs(e:Capture(nativeBar).y+228)<.001)
assert(not e:Apply('combat-bar',{x=900,y=100})and calls==writes)
busy=false;EditModeManagerFrame=oldManager
print('PASS: native anchor metadata leaves default stack management, survives native combat reanchor and performs no addon combat writes')

-- Backpack header drag uses the same persistent/profile layout store as movers.
assert(e.targets.backpack.frame==bag and style.bagDragHeader)
local header=style.bagDragHeader;style.resting=nil
function bag:StartMoving()self.moving=true end
function bag:StopMovingOrSizing()self.moving=false end
header.scripts.OnDragStart();assert(bag.moving)
bag:SetPoint('CENTER',UIParent,'CENTER',-137,89);header.scripts.OnDragStop()
assert(not bag.moving and e:Store().elements.backpack.x==-137 and e:Store().elements.backpack.y==89)
UpdateContainerFrameAnchors();assert(bag.x==-137 and bag.y==89)
bag:Hide();bag:SetPoint('CENTER',UIParent,'CENTER',0,0);bag:Show();assert(bag.x==-137 and bag.y==89)
e:Save('Backpack position');e:Store().elements.backpack.x=42;e:Load('Backpack position');assert(bag.x==-137)
busy=true;header.scripts.OnDragStart();assert(not bag.moving);bag:SetPoint('CENTER',UIParent,'CENTER',5,5);style:RestoreBackpackPosition();assert(bag.x==5)
busy=false;style:RestoreBackpackPosition();assert(bag.x==-137)
print('PASS: Backpack free dragging persists on reopen, native reanchor and saved profile load, with combat guard')

local oldNet=GetNetStats;GetNetStats=function()return 0,0,50,240 end
swingNow=300;hud:SwingEvent('PLAYER_SWING',2,0)
assert(playerCast.latency:IsShown()and playerCast.latencyMs==240 and playerCast.castSeconds==2)
assert(math.abs(playerCast.latency:GetWidth()-(playerCast:GetWidth()-playerCast.icon:GetWidth()-4)*.12)<.001)
hud:SwingEvent('PLAYER_SWING',4,1);assert(offCast.latency:IsShown()and offCast.castSeconds==4 and offCast.latencyMs==240)
hud:SwingEvent('PLAYER_SWING',3,2);assert(playerCast.label.text=='Auto shot'and playerCast.castSeconds==3)
GetNetStats=function()return 0,0,0,0 end;hud:SwingEvent('PLAYER_SWING',2,0);assert(not playerCast.latency:IsShown())
hud:StopSwing();GetNetStats=oldNet
print('PASS: main-hand, independent off-hand and ranged latency bands scale to their own duration and hide at zero latency')

-- Failure-only provenance diagnostics neither read nor replace native cooldowns.
assert(load(ERROR_SOURCE))('RUI',AUI);local errors=AUI.modules.ErrorLog
local taintChecks=0;issecurevariable=function(owner,key)taintChecks=taintChecks+1;if owner==ActionButton1 and key=='action'then return false,'ProjectRuthless'end;return true end
ActionButton1=frame();function ActionButton1:SetCooldown()error('must never invoke native cooldown')end
ProjectRuthlessDB.errorLog={enabled=true,entries={},maxEntries=10}
date=function()return '2026-10-10'end;debugstack=function()return 'native ActionButton stack'end
errors:Record('bad argument to SetCooldown: Secret values only allowed during untainted execution')
assert(ProjectRuthlessDB.errorLog.entries[1].actionBarTaint:find('ActionButton1.action = ProjectRuthless',1,true))
local count=taintChecks;errors:Record('Unrelated failure');assert(taintChecks==count)
print('PASS: cooldown error reports include bounded read-only taint provenance, unrelated errors do not scan')
do
 local oldDiscover,oldParty,oldTarget=hud.Discover,hud.DiscoverParty,hud.CreateTargetOfTarget
 local calls=0;hud.Discover=function()calls=calls+1 end;hud.DiscoverParty=hud.Discover;hud.CreateTargetOfTarget=hud.Discover
 local resting=hud.resting;hud.resting=nil;busy=false
 hud.events.scripts.OnEvent(hud.events,'ADDON_LOADED','UnrelatedAddon');assert(calls==0)
 hud.events.scripts.OnEvent(hud.events,'ADDON_LOADED','Blizzard_UnitFrame');assert(calls==3)
 hud.Discover,hud.DiscoverParty,hud.CreateTargetOfTarget=oldDiscover,oldParty,oldTarget;hud.resting=resting
 print('PASS: unrelated addon loads skip HUD discovery; relevant native loads retain discovery')
end
