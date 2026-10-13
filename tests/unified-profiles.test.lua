unpack=table.unpack
local busy=false;function InCombatLockdown()return busy end
local frames={};function CreateFrame()local f={};function f:RegisterEvent()end;function f:SetScript(_,fn)self.event=fn end;frames[#frames+1]=f;return f end
local AUI={modules={},isForever=true}
function AUI:RegisterModule(name,module)self.modules[name]=module end
function AUI:ApplyWindowSettings()self.applies=(self.applies or 0)+1 end
function AUI:RefreshBackgrounds()end;function AUI:Print(message)self.message=message end
local function clone(v)if type(v)~='table'then return v end;local t={};for k,value in pairs(v)do t[k]=clone(value)end;return t end
ProjectRuthlessDB={general={windowScale=1,windowOpacity=1},spellbook={pinnedSpells={['123']=true}},questWorkspace={guideSource='CustomGuide'},errorLog={enabled=true,maxEntries=50}}
ProjectRuthlessCharDB={layoutEditor={elements={player={x=1,y=2,scale=1,width=250,height=80}}},authoredGuide={step=5},trainingOffers={private=true}}
local position={x=20,y=30,width=250,height=80,scale=1,nativeSettings={[0]=true,[1]=2}}
local chat={{id=1,name='General\ntext',size=14,r=0,g=0,b=0,a=.5,locked=true,docked=true,uninteractable=false,selected=true,messages={'SAY','GUILD'},channels={'General',1},position=position}}
local editor={}
function editor:Store()return ProjectRuthlessCharDB.layoutEditor end
function editor:Snapshot()local t=clone(self:Store().elements);t.__art={blizzardArt=self:Store().blizzardArt==true};t.__chat=clone(chat);return t end
function editor:AccountLayouts()return ProjectRuthlessDB.layoutProfiles or {layouts={}}end
function editor:Restore(layout)self.restored=clone(layout);local t=clone(layout);t.__chat=nil;t.__art=nil;self:Store().elements=t;self:Store().blizzardArt=layout.__art and layout.__art.blizzardArt end
function editor:Save()end;function editor:Load()end;function editor:ProfileMenu()end;function editor:DefaultProfileMenu()end;function editor:SetDefaultProfile()end
AUI.modules.LayoutEditor=editor
assert(load(PROFILES_SOURCE))('ProjectRuthless',AUI)
local old=AUI.modules.Profiles:Export()
ProjectRuthlessDB.settingsProfiles={Same=old}
ProjectRuthlessDB.layoutProfiles={layouts={Same={target=clone(position)}},default='Same'}
local native={lockActionBars=true,countdownForCooldowns=false,PICKUPACTION='SHIFT',PROXY_SHOW_ACTIONBAR_2=true};local writes=0
Settings={GetSetting=function(key)if native[key]==nil then return end;return {GetValue=function()return native[key]end,SetValue=function(_,v)native[key]=v;writes=writes+1 end}end}
assert(load(UNIFIEDPROFILES_SOURCE))('ProjectRuthless',AUI)
local p=AUI.modules.UnifiedProfiles;p:InitializeCharacter()
assert(p:Store().entries['Settings: Same']and p:Store().entries['Layout: Same'])
assert(ProjectRuthlessDB.settingsProfiles.Same==old and ProjectRuthlessDB.layoutProfiles.layouts.Same.target.x==20)
assert(ProjectRuthlessCharDB.layoutEditor.elements.player.x==1 and p:Store().default=='Layout: Same')
local names=#p:Names();p:Migrate();assert(#p:Names()==names)
assert(editor:Save('Complete'));assert(p:Store().entries.Complete.full)
assert(p:Store().entries.Complete.settings:find('guideSource=CustomGuide',1,true))
ProjectRuthlessDB.general.windowScale=.8;ProjectRuthlessDB.general.colorR=.4;ProjectRuthlessDB.general.colorG=.5;ProjectRuthlessDB.general.colorB=.6
ProjectRuthlessCharDB.layoutEditor.elements.player.x=99;ProjectRuthlessCharDB.ruiBags={autoSort=true,columns=8};native.lockActionBars=false
assert(editor:Load('Complete'));assert(ProjectRuthlessDB.general.windowScale==1 and ProjectRuthlessDB.general.colorR==nil)
assert(ProjectRuthlessCharDB.layoutEditor.elements.player.x==1 and native.lockActionBars==true and writes==1)
assert(ProjectRuthlessCharDB.authoredGuide.step==5 and ProjectRuthlessCharDB.trainingOffers.private)
assert(p:Restore());assert(ProjectRuthlessDB.general.windowScale==.8 and ProjectRuthlessCharDB.layoutEditor.elements.player.x==99 and native.lockActionBars==false)
assert(p:Load('Complete'));local text=p:Export();local decoded,err=p:Parse(text);assert(decoded,err)
assert(decoded.layout.__chat[1].name=='General\ntext'and decoded.layout.player.x==1 and decoded.native.PICKUPACTION=='SHIFT')
assert(decoded.layout.__chat[1].position.nativeSettings[0]==true and decoded.pins['123'])
assert(not text:find('authoredGuide',1,true)and not text:find('trainingOffers',1,true))
local before=ProjectRuthlessDB.general.windowScale;busy=true
assert(not p:Import(text)and not p:Load('Complete')and not p:Save('Blocked'))
assert(ProjectRuthlessDB.general.windowScale==before and not p:Store().entries.Blocked);busy=false
assert(not p:Parse(text..'\nroot/s76657273696f6e=n:2'))
assert(not p:Parse('RUI_PROFILE_2\nroot=t:\nroot/s76657273696f6e=n:3'))
assert(not p:Parse('return os.execute("bad")'))
assert(not p:Parse(string.rep('x',262145)))
local invalid=clone(decoded);invalid.layout.player.scale=0;assert(not p:Validate(invalid))
invalid=clone(decoded);invalid.native.unknown=true;assert(not p:Validate(invalid))
invalid=clone(decoded);invalid.bags.columns=500;assert(not p:Validate(invalid))
assert(p:Import('RUI_SETTINGS_1\ngeneral.windowScale=1.1'));assert(ProjectRuthlessDB.general.windowScale==1.1)
assert(p:Save('Complete'));assert(#p:Store().history==1);assert(p:RecoverSaved());assert(ProjectRuthlessDB.general.windowScale==1)
assert(p:SetDefault('Complete'));ProjectRuthlessCharDB={};p:InitializeCharacter()
assert(ProjectRuthlessCharDB.activeProfile=='Complete'and ProjectRuthlessCharDB.layoutEditor.elements.player.x==1 and #ProjectRuthlessCharDB.pendingLayoutChat==1)
ProjectRuthlessCharDB.layoutEditor.elements.player.x=77;assert(p:Store().entries.Complete.layout.player.x==1)
p:OnPlayerLogin();ProjectRuthlessDB.general.windowScale=.9;frames[#frames].event()
ProjectRuthlessDB.general.windowScale=1.2;p:InitializeCharacter();assert(ProjectRuthlessDB.general.windowScale==.9)
assert(p:SetDefault(nil));assert(not p:Store().default)
ProjectRuthlessCharDB={layoutEditor={elements={},layouts={Same={target={x=91,y=30,width=250,height=80,scale=1}}}}}
p:InitializeCharacter();assert(p:Store().entries['Layout: Same (2)'].layout.target.x==91)
assert(p:Store().entries['Layout: Same'].layout.target.x==20)
local after=#p:Names();p:InitializeCharacter();assert(#p:Names()==after)
print('PASS: lossless distinct legacy migration, one settings/layout/chat save/load, native proxies, pins, colour reset, undo/recovery, complete default, character working copy, bounded non-executable import and combat no-write guard')
