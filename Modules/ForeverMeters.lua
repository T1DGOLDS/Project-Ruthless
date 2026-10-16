local _,AUI=...
local M={windows=setmetatable({},{__mode="k"})}
AUI:RegisterModule("ForeverMeters",M)
local function read(fn,...)
 if type(fn)~="function"then return end
 local ok,a,b=pcall(fn,...)
 if ok and not(issecretvalue and (issecretvalue(a)or issecretvalue(b)))then return a,b end
end
function M:Available()
 return read(C_DamageMeter and C_DamageMeter.IsDamageMeterAvailable)
end
function M:Enabled()return read(C_CVar and C_CVar.GetCVarBool,"damageMeterEnabled")==true end
function M:SetEnabled(enabled)
 if InCombatLockdown()then return false,"Change damage meter activation after combat."end
 local available,reason=self:Available()
 if enabled and not available then return false,reason or "Native damage meters are unavailable in this client."end
 local option=Settings and Settings.GetSetting and Settings.GetSetting("damageMeterEnabled")
 if not option then return false,"Native damage meter activation setting is unavailable."end
 local ok=pcall(option.SetValue,option,enabled==true)
 return ok,ok and "Native damage meter preference updated."or "The game rejected the damage meter preference."
end
function M:ApplySettings()
 if InCombatLockdown()then AUI:AfterCombat("nativeMeters",function()self:ApplySettings()end);return end
 -- Observe on-demand secondary windows without entering native setup/render paths.
 if DamageMeter and type(DamageMeter.SetupSessionWindow)=="function"and not self.hooked then
  self.hooked=true
  hooksecurefunc(DamageMeter,"SetupSessionWindow",function()
   if not self.queued then self.queued=true;C_Timer.After(0,function()self.queued=nil;self:ApplySettings()end)end
  end)
 end
 for index=1,3 do
  local window=_G["DamageMeterSessionWindow"..index]
  if window and not(issecretvalue and issecretvalue(window))then
   local surface=self.windows[window]
   if not surface then
    -- Only static chrome. Never request, sort or refresh native combat records.
    surface=CreateFrame("Frame",nil,window,"BackdropTemplate");surface:SetAllPoints(window);surface:EnableMouse(false)
    surface:SetFrameLevel(window:GetFrameLevel());surface:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    local background=window:CreateTexture(nil,"BACKGROUND",nil,-7);background:SetAllPoints(window);AUI:PaintBackground(background,"Meters",.025,.028,.035,true)
    surface:SetBackdropBorderColor(.18,.2,.24,1);AUI:StyleSurface(surface,"window",1,"Meters");self.windows[window]=surface
    if window.Header then window.Header:SetAlpha(0)end
    local background=window.MinimizeContainer and window.MinimizeContainer.Background
    if background then background:SetAlpha(0)end
   end
   local editor=AUI.modules.LayoutEditor
   if editor then editor:Attach("nativeMeter"..index,"Damage meter "..index,window,nil,{skipNativeSettings=true})end
  end
 end
end
function M:Checks()
 local available,reason=self:Available()
 if not available then return {{status="WARNING",message=reason or "Native damage meters are unavailable in this client.",setting="Utilities > Damage meter"}}end
 if not self:Enabled()then return {{status="INFO",message="Native damage meters are off by choice. RUI does not control external meters.",setting="Utilities > Enable native damage meter"}}end
 return {}
end
function M:OnPlayerLogin()
 self:ApplySettings()
 local events=CreateFrame("Frame");self.events=events
 events:RegisterEvent("ADDON_LOADED");events:RegisterEvent("CVAR_UPDATE")
 events:SetScript("OnEvent",function(_,event,name)
  if event=="ADDON_LOADED"and name~="Blizzard_DamageMeter"or event=="CVAR_UPDATE"and name~="damageMeterEnabled"then return end
  if not self.queued then self.queued=true;C_Timer.After(0,function()self.queued=nil;self:ApplySettings()end)end
 end)
end
