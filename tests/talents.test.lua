-- Strict frame mock: unknown methods fail instead of silently passing.
unpack=table.unpack
function tContains(values,value) for _,v in ipairs(values) do if v==value then return true end end return false end
local Frame={}; Frame.__index=Frame
function Frame:SetScript(k,v) self.scripts[k]=v end
function Frame:HookScript(k,v) local old=self.scripts[k]; self.scripts[k]=function(...) if old then old(...) end; v(...) end end
function Frame:Fire(k,...) if self.scripts[k] then self.scripts[k](self,...) end end
function Frame:SetSize(w,h) self.w=w; self.h=h; self:Fire("OnSizeChanged",w,h) end
function Frame:SetWidth(w) self.w=w end
function Frame:SetHeight(h) self.h=h end
function Frame:GetWidth() return self.w end
function Frame:GetHeight() return self.h end
function Frame:SetScale(s) self.scale=s end
function Frame:GetScale() return self.scale end
function Frame:GetEffectiveScale() return self.scale*(self.parent and self.parent:GetEffectiveScale() or 1) end
function Frame:SetAlpha(a) self.alpha=a end
function Frame:GetAlpha() return self.alpha end
function Frame:SetPoint(...) self.points[1]={...} end
function Frame:ClearAllPoints() self.points={} end
function Frame:GetNumPoints() return #self.points end
function Frame:GetPoint(i) return unpack(self.points[i]) end
function Frame:GetParent() return self.parent end
function Frame:SetParent(parent) self.parent=parent end
function Frame:SetAllPoints() end
function Frame:GetTop() return 100 end
function Frame:SetShown(v) local changed=self.shown~=v; self.shown=v; if changed then self:Fire(v and "OnShow" or "OnHide") end end
function Frame:Show() self:SetShown(true) end
function Frame:Hide() self:SetShown(false) end
function Frame:IsShown() return self.shown end
function Frame:SetEnabled(v) self.enabled=v end
function Frame:IsEnabled() return self.enabled end
function Frame:SetText(v) self.text=v; self:Fire("OnTextChanged") end
function Frame:GetText() return self.text end
function Frame:SetFrameLevel(v) self.level=v end
function Frame:GetFrameLevel() return self.level end
function Frame:SetScrollChild(v) self.child=v end
function Frame:GetScrollChild() return self.child end
function Frame:GetVerticalScrollRange() return math.max(0,(self.child and self.child.h or 0)-self.h) end
function Frame:SetVerticalScroll(v) self.offset=v; self:Fire("OnVerticalScroll") end
function Frame:GetVerticalScroll() return self.offset end
function Frame:ClearFocus() self.focus=false end
function Frame:SetBackdropBorderColor(...) self.border={...} end
function Frame:SetTextColor(...) self.color={...} end
for _,name in ipairs({"SetBackdrop","SetBackdropColor","SetFontString","SetJustifyH","SetTexture","SetAtlas","EnableMouseWheel","EnableMouse","RegisterForDrag","RegisterForClicks","SetAutoFocus","SetMaxLetters","RegisterEvent","SetVertexColor","SetColorTexture"}) do Frame[name]=function() end end
function CreateFrame(kind,name,parent)
    return setmetatable({parent=parent,kind=kind,name=name,scripts={},w=100,h=100,scale=1,alpha=1,level=1,shown=true,enabled=true,points={},text="",offset=0},Frame)
end
function Frame:CreateFontString() return CreateFrame("FontString",nil,self) end
function Frame:CreateTexture() local t=CreateFrame("Texture",nil,self); t.GetScale=false; t.SetScale=false; return t end
function hooksecurefunc(object,key,fn)
    local original=assert(object[key],key)
    object[key]=function(...) local result={original(...)}; fn(...); return unpack(result) end
end
UIParent=CreateFrame("Frame"); UIParent:SetSize(1920,1080)
RAID_CLASS_COLORS={DRUID={r=1,g=0.5,b=0}}
function UnitClass() return "Druid","DRUID" end
local combat=false; local casting=false; local inspecting=false; local writes=0; local spec=1; local specCount=4
function GetNumSpecializations() return specCount end
function InCombatLockdown() return combat end
function UnitCastingInfo() return casting and "Cast" or nil end
function UnitChannelInfo() return nil end
C_AddOns={GetAddOnMetadata=function() return "test" end}
SlashCmdList={}; C_Timer={After=function(_,fn) fn() end}
ProjectRuthlessDB={enabled=true,talents={enabled=true},general={windowScale=1,windowOpacity=1}}
C_SpecializationInfo={GetSpecialization=function() return spec end,CanPlayerUseTalentSpecUI=function() return true end,
    GetSpecializationInfo=function(i) assert(i>=1 and i<=specCount,"out of range spec"); return 100+i,"Spec "..i,"Description",1000+i end,
    SetSpecialization=function(i) writes=writes+1; spec=i; return true end}
TALENT_FRAME_DROP_DOWN_NEW_LOADOUT="New"; TALENT_FRAME_DROP_DOWN_IMPORT="Import"; TALENT_FRAME_DROP_DOWN_EXPORT_CLIPBOARD="Export"
local AUI={}; assert(load(CORE_SOURCE))("ProjectRuthless",AUI)
assert(load(TALENTS_SOURCE))("ProjectRuthless",AUI)
local T=AUI.modules.Talents
local f=CreateFrame("Frame"); f:SetSize(1618,883); f:SetPoint("TOP",0,-41)
f.specTabID=1; f.talentTabID=2; f.spellBookTabID=3; f.tab=2
function f:GetTab() return self.tab end
function f:SetTab(tab) self.tab=tab end
local available=true
function f:IsTabAvailable() return available end
function f:IsInspecting() return inspecting end
function f:SetInspecting(v) inspecting=v; if self.TalentsFrame then self.TalentsFrame.LoadSystem:SetShown(not v) end end
function f:UpdateTabs() end
function f:SetMinimized() end
local confirmation
function f:CheckConfirmResetAction(ok,cancel)
    if self.TalentsFrame.pending then confirmation={ok,cancel} else ok() end
end
local tree=CreateFrame("Frame",nil,f); f.TalentsFrame=tree; tree:SetSize(1612,856)
tree:SetPoint("BOTTOM",0,4)
tree.configIDs={11,12,13}; tree.configIDToName={[11]="Raid",[12]="Mythic+",[13]="PVP"}
function tree:IsCommitInProgress() return self.committing or false end
function tree:HasAnyConfigChanges() return self.pending or false end
function tree:RefreshLoadoutOptions() end
function tree:UpdateConfigButtonsState() end
function tree:UpdateInspecting() end
tree.SearchBox=CreateFrame("EditBox",nil,tree); tree.SearchBox:SetPoint("LEFT",10,0)
local loadSystem=CreateFrame("Frame",nil,tree); tree.LoadSystem=loadSystem
loadSystem.selectionID=11; loadSystem.possibleSelections=tree.configIDs
-- Execute the actual Blizzard dropdown implementation.
assert(load(LOAD_SYSTEM_SOURCE))()
for k,v in pairs(DropdownLoadSystemMixin) do loadSystem[k]=v end
loadSystem.Dropdown=CreateFrame("Frame",nil,loadSystem); loadSystem.Dropdown.Update=function() end
local failLoad=false
function tree:GetParent() return f end
function tree:LoadConfigInternal(id,autoApply) assert(autoApply); writes=writes+1; self.lastSelectedConfigID=id; return not failLoad end
function tree:RollbackConfig() self.pending=false end
function tree:CheckConfirmSwapFromDefault(cb) cb() end
function tree:CheckLoadSystemTutorials() end
-- Install the exact native load callback body, including confirmation/cancel.
assert(load("return function(self) "..NATIVE_LOAD_CALLBACK.." end"))()(tree)
local disabled=false; local actions=0
loadSystem.sentinelInfos={
    {text="New",callback=function() actions=actions+1 end,disabledCallback=function() return disabled end},
    {text="Import",callback=function() actions=actions+1 end,disabledCallback=function() return disabled end},
    {text="Export group",sentinelInfos={{text="Export",callback=function() actions=actions+1 end,disabledCallback=function() return disabled end}}}
}
local edits=0
loadSystem.canEditCallback=function(id) return id~=13 end
loadSystem.editEntryCallback=function() edits=edits+1 end
loadSystem.selectionEnabledCallback=function(id,user) assert(user==true); return not disabled end
for _,key in ipairs({"NineSlice","PortraitContainer","TitleContainer","CloseButton","MaximizeMinimizeButton","TabSystem"}) do f[key]=CreateFrame("Frame",nil,f) end
f.Bg=f:CreateTexture()
PlayerSpellsFrame=f
function HideUIPanel(frame) frame:Hide() end
PlayerSpellsUtil={OpenToClassTalentsTab=function() f:SetTab(2); f:Show() end}
T:OnPlayerLogin()
assert(T.active and f:GetWidth()<1618 and f:GetHeight()<883)
assert(tree:GetParent()==f and tree:GetWidth()==1612 and tree:GetHeight()==856)
assert(writes==0 and actions==0,"opening/layout must not change talents")
for i=1,4 do assert(T.specButtons[i]:IsShown()) end
specCount=2; T:Refresh(); assert(not T.specButtons[3]:IsShown() and not T.specButtons[4]:IsShown()); specCount=4
assert(T.search==nil and #T.entries==3,"compact loadouts should not include a search field")
assert(not tree.LoadSystem:IsShown() and not tree.SearchBox:IsShown(),"native dropdown and talent search must stay hidden")
local nativeRaiderParent=loadSystem.Dropdown
RaiderIO_TalentBuildsTalentFrameShortcut=CreateFrame("Button",nil,nativeRaiderParent)
RaiderIO_TalentBuildsTalentFrameShortcut:SetPoint("BOTTOMLEFT",nativeRaiderParent,"TOPLEFT",0,16)
RaiderIO_TalentBuildsTalentFrameShortcut:SetSize(200,25)
RaiderIO_TalentBuildsTalentFrameShortcut.font=RaiderIO_TalentBuildsTalentFrameShortcut:CreateFontString()
function RaiderIO_TalentBuildsTalentFrameShortcut:GetFontString() return self.font end
T:Refresh()
assert(RaiderIO_TalentBuildsTalentFrameShortcut:GetParent()==T.sidebar and RaiderIO_TalentBuildsTalentFrameShortcut:GetWidth()==186)
local raiderRow=CreateFrame("Button")
function raiderRow:SetBackdrop(value) self.backdrop=value end
function raiderRow:SetBackdropColor(...) self.bg={...} end
function raiderRow:SetBackdropBorderColor(...) self.border={...} end
RaiderIO_TalentBuildsFrame=CreateFrame("Frame",nil,UIParent); RaiderIO_TalentBuildsFrame:SetSize(640,420)
RaiderIO_TalentBuildsFrame.NineSlice=CreateFrame("Frame",nil,RaiderIO_TalentBuildsFrame)
RaiderIO_TalentBuildsFrame.PortraitContainer=CreateFrame("Frame",nil,RaiderIO_TalentBuildsFrame)
RaiderIO_TalentBuildsFrame.TopTileStreaks=CreateFrame("Frame",nil,RaiderIO_TalentBuildsFrame)
RaiderIO_TalentBuildsFrame.Inset=CreateFrame("Frame",nil,RaiderIO_TalentBuildsFrame)
RaiderIO_TalentBuildsFrame.Bg=RaiderIO_TalentBuildsFrame:CreateTexture()
RaiderIO_TalentBuildsFrame.TitleContainer={TitleText=RaiderIO_TalentBuildsFrame:CreateFontString()}
RaiderIO_TalentBuildsFrame.CloseButton=CreateFrame("Button",nil,RaiderIO_TalentBuildsFrame)
RaiderIO_TalentBuildsFrame.ScrollBox=CreateFrame("Frame",nil,RaiderIO_TalentBuildsFrame)
RaiderIO_TalentBuildsFrame.ScrollBox.Event={OnUpdate="update"}
function RaiderIO_TalentBuildsFrame.ScrollBox:ForEachFrame(callback) callback(raiderRow) end
function RaiderIO_TalentBuildsFrame.ScrollBox:RegisterCallback(_,callback) self.callback=callback end
RaiderIO_TalentBuildsFrame:Show(); T:SkinRaiderWindow()
assert(RaiderIO_TalentBuildsFrame:GetWidth()==660 and RaiderIO_TalentBuildsFrame:GetHeight()==470)
assert(not RaiderIO_TalentBuildsFrame.NineSlice:IsShown() and raiderRow.backdrop,"Raider.IO browser must receive Ruthless chrome and rows")
assert(writes==0 and actions==0,"search/refresh must be read-only")
T:SelectLoadout(999); assert(writes==0)
disabled=true; T:SelectLoadout(12); T:RunAction("New"); assert(writes==0 and actions==0)
disabled=false; tree.lastSelectedConfigID=11; tree.pending=true
T:SelectLoadout(12); assert(confirmation and writes==0,"pending native confirmation required")
confirmation[2](); assert(loadSystem:GetSelectionID()==11 and writes==0,"cancel must preserve build")
T:SelectLoadout(12); confirmation[1](); assert(writes==1 and tree.lastSelectedConfigID==12)
tree.pending=false; failLoad=true; tree.lastSelectedConfigID=12
T:SelectLoadout(11); assert(not tree.pending); failLoad=false
local before=writes
combat=true; T:SelectLoadout(12); T:SwitchSpec(2); T:RunAction("New"); T:EditLoadout(11)
assert(writes==before and actions==0 and edits==0)
combat=false; tree.committing=true; T:SelectLoadout(12); T:SwitchSpec(2); assert(writes==before)
tree.committing=false; casting=true; T:SwitchSpec(2); assert(writes==before); casting=false
tree.pending=true; T:SwitchSpec(2); assert(writes==before); confirmation[1](); assert(spec==2 and writes==before+1)
tree.pending=false
T:EditLoadout(13); assert(edits==0); T:EditLoadout(11); assert(edits==1)
T:RunAction("New"); T:RunAction("Import"); T:RunAction("Export"); assert(actions==3)
f:SetInspecting(true)
assert(not T.active and f:GetWidth()==1618 and f:GetHeight()==883 and tree:GetScale()==1)
assert(f.Bg:IsShown() and f.CloseButton:IsShown() and not T.chrome:IsShown())
assert(not tree.LoadSystem:IsShown(),"restoration must not expose native loadouts while inspecting")
assert(RaiderIO_TalentBuildsTalentFrameShortcut:GetParent()==nativeRaiderParent,"native Raider.IO button parent must restore")
before=writes; T:SwitchSpec(1); T:SelectLoadout(11); assert(writes==before)
f:SetInspecting(false); assert(T.active)
f:SetTab(3); assert(not T.active and f:GetWidth()==1618)
f:SetTab(1); assert(T.active and f:GetTab()==2,"spec page redirects to compact selector")
ProjectRuthlessDB.talents.enabled=false; T:ApplySettings(); assert(not T.active)
ProjectRuthlessDB.talents.enabled=true; T:ApplySettings(); assert(T.active)
available=false; T:ApplySettings(); assert(not T.active,"unsupported levels retain native UI"); available=true
for _,size in ipairs({{1280,720},{1920,1080},{3440,1440}}) do
    UIParent:SetSize(size[1],size[2]); T:ApplySettings()
    assert(f:GetWidth()*f:GetScale()<=size[1]*0.94+0.01)
    assert(f:GetHeight()*f:GetScale()<=size[2]*0.90+0.01)
end
-- A settings toggle in combat is deferred and reconciled at combat end.
combat=true; ProjectRuthlessDB.talents.enabled=false; T:ApplySettings(); assert(T.active)
combat=false; T.events:Fire("OnEvent","PLAYER_REGEN_ENABLED"); assert(not T.active)
ProjectRuthlessDB.talents.enabled=true; T:ApplySettings()
-- Repeated refreshes, openings and settings never accumulate scale changes.
for i=1,20 do T:ApplySettings(); f:UpdateTabs() end
assert(tree:GetScale()==0.72 and not tree.LoadSystem:IsShown() and not tree.SearchBox:IsShown())
print("PASS: strict UI creation, 2/4 specs, clean loadout sidebar, hidden native controls, no-write browsing, native load confirmation/cancel, action restrictions, inspect/native restoration, combat deferral and viewport fitting")
