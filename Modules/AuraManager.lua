local _,AUI=...
local M={groups={},styled=setmetatable({},{__mode="k"}),art=setmetatable({},{__mode="k"})}
AUI:RegisterModule("AuraManager",M)
local defaults={playerBuffs=false,playerDebuffs=false,targetDebuffs=false,focus=false,focusSpell=0,iconSize=30,spacing=3,limit=8,expirationFirst=true,partyBuffs=true,partyDebuffs=true,partyDispels=true,expiring=true,expirationThreshold=30,styleCooldowns=true}
M.defaults=defaults
M.templates={{key="playerBuffs",label="Player buffs",unit="player",filter="HELPFUL",y=140},{key="playerDebuffs",label="Player debuffs",unit="player",filter="HARMFUL",y=100},{key="targetDebuffs",label="Your target debuffs",unit="target",filter="HARMFUL|PLAYER",y=60},{key="focus",label="Focus buff",unit="player",filter="HELPFUL",y=20}}
M.viewers={{name="EssentialCooldownViewer",label="Essential cooldowns"},{name="UtilityCooldownViewer",label="Utility cooldowns"},{name="BuffIconCooldownViewer",label="Tracked buff icons"},{name="BuffBarCooldownViewer",label="Tracked buff bars"}}
local function read(fn,...)
 if type(fn)~="function"then return end
 local ok,v=pcall(fn,...);if ok and not(issecretvalue and issecretvalue(v))then return v end
end
function M:Settings()
 ProjectRuthlessDB.auraManager=ProjectRuthlessDB.auraManager or {}
 local s=ProjectRuthlessDB.auraManager
 for k,v in pairs(defaults)do if s[k]==nil then s[k]=v end end
 return s
end
function M:CooldownCapability()
 if not C_CooldownViewer or type(C_CooldownViewer.IsCooldownViewerAvailable)~="function"then return false,"Native cooldown viewer API is unavailable."end
 local ok,available,reason=pcall(C_CooldownViewer.IsCooldownViewerAvailable)
 if not ok or issecretvalue and issecretvalue(available)then return false,"Native cooldown capability could not be read."end
 if available~=true then return false,type(reason)=="string"and not(issecretvalue and issecretvalue(reason))and reason or "The game has disabled cooldown viewing for this character."end
 return true
end
function M:CooldownEnabled()
 return C_CVar and read(C_CVar.GetCVarBool,"cooldownViewerEnabled")==true
end
function M:SetCooldownEnabled(enabled)
 if InCombatLockdown()then return false,"Change native cooldown activation after combat."end
 local ok,reason=self:CooldownCapability();if enabled and not ok then return false,reason end
 local option=Settings and Settings.GetSetting and Settings.GetSetting("cooldownViewerEnabled")
 if not option then return false,"Native cooldown activation setting is unavailable. Use the game's cooldown settings."end
 local success=pcall(option.SetValue,option,enabled==true)
 return success,success and "Native cooldown preference updated."or "The game rejected the cooldown preference."
end
function M:CaptureCooldowns()
 local data=C_CooldownViewer and read(C_CooldownViewer.GetLayoutData)
 local _,class=UnitClass("player")
 if type(data)=="string"and #data<=65536 and type(class)=="string"then return {class=class,data=data}end
end
function M:RestoreCooldowns(snapshot)
 if not snapshot then return true end
 if InCombatLockdown()then return false,"Cooldown layout restoration waits until combat ends."end
 local _,class=UnitClass("player")
 if snapshot.class~=class then return false,"Cooldown spell layouts belong to another class; this character's native layout was kept."end
 if not C_CooldownViewer or type(C_CooldownViewer.SetLayoutData)~="function"then return false,"Native cooldown layout storage is unavailable."end
 local current=read(C_CooldownViewer.GetLayoutData)
 if current==snapshot.data then return true end
 -- Only the documented opaque storage API. Never enter native render/update
 -- methods or access the viewer's secured aura-instance maps from addon Lua.
 local ok=pcall(C_CooldownViewer.SetLayoutData,snapshot.data)
 if not ok then return false,"The game rejected cooldown layout restoration; the profile recovery snapshot is retained."end
 self.reloadNeeded=true
 return true,"Cooldown layout stored. Reload to refresh Blizzard's cached viewer configuration."
end
function M:InitializeIcon(button,size,harmful)
 button:SetSize(size,size)
 local background=button:CreateTexture(nil,"BACKGROUND",nil,-1);background:SetAllPoints(button);AUI:PaintBackground(background,"Auras",.035,.039,.052,true)
 local border=button:CreateTexture(nil,"BACKGROUND");border:SetAllPoints(button);border:SetColorTexture(harmful and .65 or .18,harmful and .22 or .2,harmful and .22 or .24,1)
 local icon=button:CreateTexture(nil,"ARTWORK");icon:SetPoint("TOPLEFT",1,-1);icon:SetPoint("BOTTOMRIGHT",-1,1);icon:SetTexCoord(.07,.93,.07,.93)
 local cooldown=CreateFrame("Cooldown",nil,button,"CooldownFrameTemplate");cooldown:SetAllPoints(button);cooldown:SetDrawEdge(false);cooldown:SetHideCountdownNumbers(false)
 cooldown:GetCountdownFontString():SetFont(STANDARD_TEXT_FONT,math.max(8,math.floor(size*.32)),"OUTLINE")
 local count=button:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");count:SetPoint("BOTTOMRIGHT",-1,1)
 button:SetIcon(icon);button:SetDurationCooldown(cooldown);button:SetApplicationCount(count)
 button:SetTooltipAnchorPoint("ANCHOR_RIGHT");button:SetHideTooltipInCombat(false)
end
function M:ApplyGroups()
 if type(CustomAuraContainerGroupDefaultOptions)~="table"then return end
 local s=self:Settings();local editor=AUI.modules.LayoutEditor
 for index,template in ipairs(self.templates)do
  local group=self.groups[template.key]
  local enabled=s[template.key]and (template.key~="focus"or s.focusSpell>0)
  if enabled and not group then
   local anchor=CreateFrame("Frame",nil,UIParent);anchor:SetSize(300,60);anchor:SetPoint("CENTER",UIParent,"CENTER",0,180-(index-1)*(s.iconSize*math.ceil(s.limit/8)+s.spacing+12))
   local container=CreateFrame("AuraContainer",nil,anchor,"CustomAuraContainerTemplate")
   container:SetPoint("TOPLEFT",anchor,"TOPLEFT");container:SetUnit(template.unit)
   local size=30;local harmful=template.filter:find("HARMFUL")~=nil
   container:AddAuraGroup("rui",template.filter,{maxFrameCount=s.limit,initializeFrame=function(button)self:InitializeIcon(button,size,harmful)end})
   group={anchor=anchor,container=container};self.groups[template.key]=group
   editor:Attach("aura_"..template.key,template.label,anchor)
  end
  local signature=table.concat({tostring(enabled),s.iconSize,s.spacing,s.limit,tostring(s.expirationFirst),template.key=="focus"and s.focusSpell or 0},":")
  if group and group.applied~=signature then
   local c=group.container
   c:SetEnabled(false)
   -- Use supported native inbound APIs, never scan UNIT_AURA data in RUI.
   c:SetAuraGroupMaxFrameCount("rui",s.limit)
   c:SetAuraGroupCandidateFilters("rui",template.key=="focus"and {includeSpellIDs={[s.focusSpell]=true}}or nil)
   c:SetAuraGroupSortMethod("rui",s.expirationFirst and AuraContainerSortMethod.Expiration or AuraContainerSortMethod.Default,AuraContainerSortDirection.Normal)
   local spacing=s.spacing*30/s.iconSize
   c:SetScale(s.iconSize/30);group.anchor:SetSize((s.iconSize+s.spacing)*math.min(s.limit,8),s.iconSize*math.ceil(s.limit/8)+s.spacing)
   c:SetFlowLayoutMaximumLineSize((30+spacing)*math.min(s.limit,8))
   c:SetAuraGroupLayout("rui",{elementWidth=30,elementHeight=30,elementSpacing=spacing,lineSpacing=spacing})
   c:SetEnabled(enabled==true);group.anchor:SetShown(enabled==true)
   group.applied=signature
  end
 end
end
function M:ApplyParty()
 local hud=AUI.modules.ForeverHUD;if not hud then return end
 local s=self:Settings()
 for id,row in pairs(hud.registered or {})do if id:match("^party")and row.ruiAuras then
  for index,container in ipairs(row.ruiAuras)do container:SetEnabled(index==1 and s.partyBuffs or index==2 and s.partyDebuffs or index==3 and s.partyDispels)end
 end end
end
function M:SkinCooldowns()
 if not self:Settings().styleCooldowns then return end
 for _,entry in ipairs(self.viewers)do
  local viewer=_G[entry.name];local pool=viewer and viewer.itemFramePool
  if pool and type(pool.EnumerateActive)=="function"then
   for item in pool:EnumerateActive()do
    if not(issecretvalue and issecretvalue(item))then
    if not self.styled[item]then
     local surface=CreateFrame("Frame",nil,item,"BackdropTemplate");surface:SetAllPoints(item);surface:EnableMouse(false)
     surface:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1});surface:SetBackdropBorderColor(.2,.22,.27,1)
     self.styled[item]=surface
    end
    self.styled[item]:Show()
    -- Cosmetic regions only. No native GetAura/Refresh/SetCooldown calls.
    local ok,regions=pcall(function()return {item:GetRegions()}end)
    for _,region in ipairs(ok and regions or {})do
     if not(issecretvalue and issecretvalue(region))and type(region.GetAtlas)=="function"and read(region.GetAtlas,region)=="UI-HUD-CoolDownManager-IconOverlay"then
      if self.art[region]==nil then self.art[region]=read(region.GetAlpha,region)or 1 end
      region:SetAlpha(0)
     end
    end
    end
   end
  end
 end
end
function M:ApplySettings(key)
 self:Settings()
 if InCombatLockdown()then self.pending=true;AUI:AfterCombat("auraManager",function()self:ApplySettings()end);return end
 self.pending=nil
 if key and key:match("^party")then self:ApplyParty();return end
 local buffs=AUI.modules.ForeverExpiringBuffs
 if key=="expiring"or key=="expirationThreshold"then if buffs and buffs.ApplySettings then buffs:ApplySettings()end;return end
 self:ApplyGroups();self:ApplyParty();self:SkinCooldowns()
 if not self:Settings().styleCooldowns then
  for _,surface in pairs(self.styled)do surface:Hide()end
  for region,alpha in pairs(self.art)do region:SetAlpha(alpha)end
 end
 local editor=AUI.modules.LayoutEditor
 if editor then for _,entry in ipairs(self.viewers)do
  local viewer=_G[entry.name]
  if viewer then editor:Attach("cd_"..entry.name,entry.label,viewer,nil,{skipNativeSettings=true})end
 end end
 if buffs and buffs.ApplySettings then buffs:ApplySettings()end
end
function M:Preset(name)
 local s=self:Settings()
 if name=="combat"then s.playerBuffs=false;s.playerDebuffs=true;s.targetDebuffs=true;s.focus=false
 elseif name=="buffs"then s.playerBuffs=true;s.playerDebuffs=true;s.targetDebuffs=false;s.focus=false
 elseif name=="minimal"then s.playerBuffs=false;s.playerDebuffs=false;s.targetDebuffs=false;s.focus=false end
 self:ApplySettings()
end
function M:Checks()
 local s=self:Settings();local rows={}
 local function add(status,text,setting)rows[#rows+1]={status=status,message=text,setting="Auras & cooldowns > "..setting}end
 local capable,reason=self:CooldownCapability()
 if not capable then add("WARNING",reason,"Native cooldowns")elseif not self:CooldownEnabled()then add("INFO","Native cooldown displays are off by choice.","Enable native cooldowns")end
 if type(CustomAuraContainerGroupDefaultOptions)~="table"then add("WARNING","Secure native aura containers are unavailable; custom groups cannot render.","Aura groups")end
 if s.focus and s.focusSpell==0 then add("WARNING","Focus buff is on but no spell ID is configured.","Focus spell ID")end
 if s.focus then add("INFO","Focus matches an exact spell ID/rank on friendly helpful auras. Secret or unsupported matches are rejected by Blizzard.","Focus buff")end
 if not s.partyDispels then add("INFO","Large party dispel indicators are off by choice.","Party dispel emphasis")end
 if not s.playerBuffs and not s.playerDebuffs and not s.targetDebuffs and not s.focus then add("INFO","Custom aura groups are off by choice. Choose a preset or enable a group.","Aura presets")end
 if self.pending then add("INFO","Presentation edits are queued until combat ends.","Pending edits")end
 if self.reloadNeeded then add("INFO","A profile restored native cooldown storage. Reload to refresh the native cached layout.","Profiles")end
 if s.expiring then add("INFO","Expiring-buff timing is available only while aura timing is public; restricted timing is never guessed.","Expiring self buffs")end
 local data=C_CooldownViewer and read(C_CooldownViewer.GetLayoutData)
 if type(data)=="string"and #data>65536 then add("WARNING","Native cooldown data exceeds the profile snapshot limit; it remains in the game but is not included in RUI profile sharing.","Profiles")end
 return rows
end
function M:OpenNative()
 if InCombatLockdown()then AUI:Print("Spell selection and alert editing are available after combat. RUI settings and previews remain browsable.");return end
 if CooldownViewerSettings and type(CooldownViewerSettings.TogglePanel)=="function"then
  CooldownViewerSettings:TogglePanel()
  local style=AUI.modules.ForeverStyle;if style and style.SkinNativeDialog then style:SkinNativeDialog(CooldownViewerSettings,"Auras")end
 else AUI:Print("Native cooldown settings are unavailable in this client.")end
end
function M:Preview()
 if self.preview then self.preview:SetShown(not self.preview:IsShown());return end
 local f=CreateFrame("Frame",nil,UIParent,"BackdropTemplate");self.preview=f
 f:SetSize(380,160);f:SetPoint("CENTER",UIParent,"CENTER",0,210);f:SetFrameStrata("DIALOG")
 f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1});AUI:StyleSurface(f,"window",1,"Auras")
 local title=f:CreateFontString(nil,"OVERLAY","GameFontNormal");title:SetPoint("TOPLEFT",12,-12);title:SetText("RUI aura preview · sample values")
 local access=AUI.modules.Accessibility;if access then access:RegisterText(title)end
 local size=self:Settings().iconSize
 for i,texture in ipairs({"Spell_Holy_WordFortitude","Spell_Nature_Rejuvenation","Spell_Shadow_ShadowWordPain"})do
  local icon=f:CreateTexture(nil,"ARTWORK");icon:SetPoint("TOPLEFT",12+(i-1)*math.max(size+8,88),-42);icon:SetSize(size,size);icon:SetTexture("Interface\\Icons\\"..texture)
  local label=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");label:SetPoint("TOP",icon,"BOTTOM",0,-4);label:SetText(i==1 and "12s"or i==2 and "2 stacks"or "Debuff")
 end
 local bar=CreateFrame("StatusBar",nil,f);bar:SetPoint("BOTTOMLEFT",12,18);bar:SetSize(250,14);bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8");bar:SetMinMaxValues(0,1);bar:SetValue(.65);bar:SetStatusBarColor(AUI:AccentColor())
 local close=AUI:CreateButton(f);close:SetPoint("BOTTOMRIGHT",-12,12);close:SetSize(90,24);close:SetText("Close");close:SetScript("OnClick",function()f:Hide()end)
end
function M:OnPlayerLogin()
 self:Settings();self:ApplySettings()
 local events=CreateFrame("Frame");self.events=events
 for _,event in ipairs({"ADDON_LOADED","PLAYER_SPECIALIZATION_CHANGED","SPELLS_CHANGED","CVAR_UPDATE","PLAYER_REGEN_ENABLED"})do events:RegisterEvent(event)end
 events:SetScript("OnEvent",function(_,event,name)
  if event=="ADDON_LOADED"and name~="Blizzard_CooldownViewer"and name~="Blizzard_AuraContainer"then return end
  if event=="CVAR_UPDATE"and name~="cooldownViewerEnabled"then return end
  if self.queued then return end;self.queued=true
  C_Timer.After(.1,function()self.queued=nil;self:ApplySettings()end)
 end)
end
