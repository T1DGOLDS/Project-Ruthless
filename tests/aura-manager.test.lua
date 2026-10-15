unpack=table.unpack or unpack
local AUI={modules={},isForever=true};ProjectRuthless=AUI;ProjectRuthlessDB={};ProjectRuthlessCharDB={}
function AUI:RegisterModule(n,m)self.modules[n]=m end;function AUI:Print(t)self.message=t end
function AUI:StyleSurface()end;function AUI:PaintBackground()end;function AUI:AccentColor()return .8,.4,.7 end
local busy=false;function InCombatLockdown()return busy end
local secret={};function issecretvalue(v)return v==secret end
local deferred={};function AUI:AfterCombat(k,fn)deferred[k]=fn end
local methods={};local frames={}
local function frame()
 local f={scripts={},shown=true};frames[#frames+1]=f;return setmetatable(f,{__index=methods})
end
for _,name in ipairs({'SetPoint','ClearAllPoints','SetSize','SetScale','SetBackdrop','SetBackdropBorderColor','EnableMouse','SetColorTexture','SetTexCoord','SetAllPoints','SetDrawEdge','SetHideCountdownNumbers','SetFont','SetTooltipAnchorPoint','SetHideTooltipInCombat','SetFrameStrata','SetText','SetWidth','SetJustifyH','SetAutoFocus','ClearFocus','SetStatusBarTexture','SetMinMaxValues','SetValue','SetStatusBarColor'})do methods[name]=function(self,...)self[name]={...}end end
-- Methods remain callable on repeat updates.
for name in pairs(methods)do local n=name;methods[n]=function(self,...)self.values=self.values or {};self.values[n]={...};if n=='SetText'then self.text=(...)end end end
function methods:CreateTexture()return frame()end;function methods:CreateFontString()return frame()end
function methods:GetCountdownFontString()return frame()end
function methods:GetStringHeight()return 220 end;function methods:GetText()return self.text end
function methods:SetHeight(h)self.height=h end
function methods:SetTexture(v)self.texture=v end
function methods:SetScript(k,fn)self.scripts[k]=fn end
function methods:HookScript(k,fn)self.scripts[k]=fn end
function methods:Show()self.shown=true end;function methods:Hide()self.shown=false end
function methods:SetShown(v)self.shown=v end;function methods:IsShown()return self.shown end
function methods:SetEnabled(v)self.enabled=v end
function methods:SetUnit(v)self.unit=v end
function methods:AddAuraGroup(key,filter,options)
 self.group={key=key,filter=filter};local button=frame();options.initializeFrame(button);self.button=button
end
function methods:SetIcon(v)self.boundIcon=v end;function methods:SetDurationCooldown(v)self.boundDuration=v end;function methods:SetApplicationCount(v)self.boundCount=v end
function methods:SetAuraGroupMaxFrameCount(_,v)self.limit=v end
function methods:SetAuraGroupCandidateFilters(_,v)self.filters=v end
function methods:SetAuraGroupSortMethod(_,v)self.sort=v end
function methods:SetFlowLayoutMaximumLineSize(v)self.line=v end
function methods:SetAuraGroupLayout(_,v)self.layout=v end
function methods:RegisterEvent()end;function methods:SetScrollChild()end
function CreateFrame()return frame()end;UIParent=frame();STANDARD_TEXT_FONT='font'
CustomAuraContainerGroupDefaultOptions={};AuraContainerSortMethod={Expiration=4,Default=0};AuraContainerSortDirection={Normal=0}
AUI.modules.LayoutEditor={targets={},Attach=function(self,id,_,f,_,options)self.targets[id]={frame=f,options=options}end,Show=function()end}
local current='original';C_CooldownViewer={IsCooldownViewerAvailable=function()return true,''end,GetLayoutData=function()return current end,SetLayoutData=function(v)current=v end}
function UnitClass()return 'Warrior','WARRIOR'end
local nativeOn=false;C_CVar={GetCVarBool=function()return nativeOn end}
Settings={GetSetting=function(name)assert(name=='cooldownViewerEnabled');return {SetValue=function(_,v)nativeOn=v end}end}
local pending={};C_Timer={After=function(_,fn)pending[#pending+1]=fn end}
assert(load(MANAGER_SOURCE))('ProjectRuthless',AUI);local m=AUI.modules.AuraManager;local s=m:Settings()
m:ApplySettings();assert(next(m.groups)==nil and not nativeOn)
m:Preset('combat');assert(m.groups.playerDebuffs.container.enabled and m.groups.targetDebuffs.container.unit=='target'and m.groups.targetDebuffs.container.group.filter=='HARMFUL|PLAYER')
local container=m.groups.playerDebuffs.container;assert(container.button.boundIcon and container.button.boundDuration and container.button.boundCount)
s.focus=true;s.focusSpell=123;s.expirationFirst=true;m:ApplySettings()
assert(m.groups.focus.container.filters.includeSpellIDs[123]and container.sort==4)
s.iconSize=40;s.spacing=4;m:ApplySettings();assert(container.values.SetScale[1]==40/30 and container.layout.elementWidth==30)
busy=true;s.playerDebuffs=false;m:ApplySettings();assert(m.pending and container.enabled and deferred.auraManager)
assert(not m:SetCooldownEnabled(true));assert(not m:RestoreCooldowns({class='WARRIOR',data='combat'}));assert(current=='original')
busy=false;deferred.auraManager();assert(not m.pending and not container.enabled)
assert(m:SetCooldownEnabled(true)and nativeOn)
local captured=m:CaptureCooldowns();assert(captured.data=='original'and captured.class=='WARRIOR')
assert(not m:RestoreCooldowns({class='MAGE',data='wrong'}));assert(current=='original')
assert(m:RestoreCooldowns({class='WARRIOR',data='saved'})and current=='saved'and m.reloadNeeded)
C_CooldownViewer.GetLayoutData=function()return secret end;assert(not m:CaptureCooldowns())
s.focusSpell=0;local found=false;for _,check in ipairs(m:Checks())do if check.status=='WARNING'and check.message:find('no spell ID')then found=true end end;assert(found)
local originalCapability=C_CooldownViewer.IsCooldownViewerAvailable;C_CooldownViewer.IsCooldownViewerAvailable=function()return false,'Unavailable for this character'end
assert(not m:CooldownCapability());C_CooldownViewer.IsCooldownViewerAvailable=originalCapability
local party={ruiAuras={frame(),frame(),frame()}};AUI.modules.ForeverHUD={registered={party1=party}}
s.partyBuffs=false;s.partyDebuffs=true;s.partyDispels=false;m:ApplySettings('partyBuffs');assert(not party.ruiAuras[1].enabled and party.ruiAuras[2].enabled and not party.ruiAuras[3].enabled)
local trim=frame();function trim:GetAtlas()return 'UI-HUD-CoolDownManager-IconOverlay'end;function trim:GetAlpha()return .8 end;function trim:SetAlpha(v)self.alpha=v end
local item=frame();function item:GetRegions()return trim,secret end
function item:SetCooldown()error('Never invoke a native live cooldown renderer from RUI')end
EssentialCooldownViewer=frame();EssentialCooldownViewer.itemFramePool={EnumerateActive=function()local i=0;return function()i=i+1;if i==1 then return item end end end}
function EssentialCooldownViewer:RefreshLayout()error('Never call native protected refresh')end
s.styleCooldowns=true;m:ApplySettings();assert(trim.alpha==0 and m.styled[item].shown)
assert(AUI.modules.LayoutEditor.targets.cd_EssentialCooldownViewer.options.skipNativeSettings)
s.styleCooldowns=false;m:ApplySettings();assert(trim.alpha==.8 and not m.styled[item].shown)
local menu={panels={},optionControls={}};AUI.modules.Menu=menu
function menu:CreateOptionsPanel()return frame()end;function AUI:CreateSmoothScrollFrame()return frame()end
function menu:CreateCheckbox(_,label,_,_,getter,setter)self[label]={get=getter,set=setter}end
function menu:CreateSlider()end;function menu:CreateAction(_,text,_,_,_,fn)local f=frame();f.click=fn;self[text]=f;return f end
function menu:Refresh()end;function menu:SelectTab()end
AUI.modules.SettingsRegistry={Register=function()end};function AUI:CreateButton()return frame()end
assert(load(AURA_OPTIONS_SOURCE))('ProjectRuthless',AUI);menu:CreateAuraOptions(frame())
assert(menu.panels.auras and menu['Check configuration']and menu['Preview samples'])
m:Preview();assert(m.preview.shown);m:Preview();assert(not m.preview.shown)
m:OnPlayerLogin();m.events.scripts.OnEvent(nil,'SPELLS_CHANGED');m.events.scripts.OnEvent(nil,'SPELLS_CHANGED');assert(#pending==1);pending[1]()
print('PASS: native aura delegates, templates, exact focus filtering, expiration sort, geometry, combat deferral, native activation, opaque class-safe cooldown storage, diagnostics, actual options construction, static previews and event coalescing')
