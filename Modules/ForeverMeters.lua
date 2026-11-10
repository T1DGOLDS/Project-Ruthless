local _,AUI=...
local M={windows=setmetatable({},{__mode="k"}),rows=setmetatable({},{__mode="k"}),scrolls=setmetatable({},{__mode="k"}),art=setmetatable({},{__mode="k"})}
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
function M:StyleRow(row)
 if not row or not row.StatusBar then return end
 if InCombatLockdown()then self.rows[row]=true;return end
 local bar=row.StatusBar
 local settings=ProjectRuthlessDB.meterStyle or {}
 local texture=read(bar.GetStatusBarTexture,bar)
 if not self.art[row]then self.art[row]={asset=texture and read(texture.GetTexture,texture),atlas=texture and read(texture.GetAtlas,texture)}end
 if settings.flatBars~=false then bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
 else
  local original=self.art[row]
  if original.asset then bar:SetStatusBarTexture(original.asset)end
  texture=read(bar.GetStatusBarTexture,bar)
  if texture and original.atlas then texture:SetAtlas(original.atlas)end
 end
 if bar.Background then bar.Background:SetAlpha(0)end
 if bar.BackgroundEdge then bar.BackgroundEdge:SetAlpha(0)end
 local size=type(settings.textSize)=="number"and math.max(9,math.min(18,settings.textSize))or nil
 for _,font in ipairs({bar.Name,bar.Value})do
  if font and type(font.GetFont)=="function"then
   local face,nativeSize=font:GetFont();if face then font:SetFont(face,size or nativeSize or 11,"OUTLINE")end
  end
 end
 self.rows[row]=false
end
function M:WatchScroll(scroll)
 if not scroll or not ScrollUtil then return end
 if not self.scrolls[scroll]then
 self.scrolls[scroll]=true
 ScrollUtil.AddInitializedFrameCallback(scroll,function(_,row)
  -- A post-initializer observer queues cosmetics outside the native data callback.
  -- It never receives or inspects elementData, sorting keys or combat values.
  self.rows[row]=true;self:QueueStyle()
 end,self)
 end
 if type(scroll.ForEachFrame)=="function"then scroll:ForEachFrame(function(row)self:StyleRow(row)end)end
end
function M:QueueStyle()
 if InCombatLockdown()then
  if not self.combatQueued then
   self.combatQueued=true
   AUI:AfterCombat("nativeMeters",function()self.combatQueued=nil;self:ApplySettings()end)
  end
  return
 end
 if self.queued then return end
 self.queued=true
 C_Timer.After(0,function()self.queued=nil;self:ApplySettings()end)
end
function M:StyleSource(window)
 local container=window.MinimizeContainer
 local source=container and container.SourceWindow
 if not source then return end
 self:WatchScroll(source.ScrollBox)
 if not self.windows[source]then
  local surface=CreateFrame("Frame",nil,source,"BackdropTemplate")
  surface:SetAllPoints(source);surface:EnableMouse(false)
  surface:SetFrameLevel(source:GetFrameLevel())
  surface:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  AUI:StyleSurface(surface,"window",1,"Meters");surface:SetBackdropBorderColor(.18,.2,.24,1)
  self.windows[source]=surface
  if source.Background then source.Background:SetAlpha(0)end
 end
end
function M:Show()
 if InCombatLockdown()then AUI:Print("Use the meter's type and fight selectors while playing. Open RUI meter setup after combat.");return end
 local ok,message=self:SetEnabled(true)
 if not ok then AUI:Print(message);return end
 self:ApplySettings()
 if not self.help then
  local panel=CreateFrame("Frame","RUIMeterHelp",UIParent,"BackdropTemplate");self.help=panel
  panel:SetSize(510,330);panel:SetPoint("CENTER");panel:SetFrameStrata("DIALOG")
  panel:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  AUI:StyleSurface(panel,"window",1,"Meters");panel:SetBackdropBorderColor(AUI:AccentColor())
  local label=panel:CreateFontString(nil,"OVERLAY","GameFontNormalLarge");label:SetPoint("TOPLEFT",18,-16);label:SetText("RUI · Combat meter")
  local body=panel:CreateFontString(nil,"OVERLAY","GameFontNormal");body:SetPoint("TOPLEFT",18,-54);body:SetWidth(474);body:SetJustifyH("LEFT");body:SetSpacing(5)
  body:SetText("Live combat updates use Forever's own damage engine.\n\nType selector: damage, DPS, healing, HPS, damage taken, interrupts, dispels and deaths.\n\nFight selector: current fight, overall or a previous fight.\n\nClick a player to inspect their spell breakdown. Shift-click pins the breakdown open.\n\nThe meter's settings button provides additional windows, reset, lock, icons and native display options. RUI Edit Mode saves placement.")
  local close=AUI:CreateButton(panel);close:SetPoint("BOTTOMRIGHT",-16,14);close:SetSize(90,24);close:SetText("Close");close:SetScript("OnClick",function()panel:Hide()end)
  UISpecialFrames=UISpecialFrames or {};table.insert(UISpecialFrames,"RUIMeterHelp")
 end
 self.help:Show()
end
function M:ApplySettings()
 if InCombatLockdown()then AUI:AfterCombat("nativeMeters",function()self:ApplySettings()end);return end
 self.combatQueued=nil
 -- Observe on-demand secondary windows without entering native setup/render paths.
 if DamageMeter and type(DamageMeter.SetupSessionWindow)=="function"and not self.hooked then
  self.hooked=true
  hooksecurefunc(DamageMeter,"SetupSessionWindow",function()
   self:QueueStyle()
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
   local container=window.MinimizeContainer
   if container then
    self:WatchScroll(container.ScrollBox)
    if container.LocalPlayerEntry then self:StyleRow(container.LocalPlayerEntry)end
   end
   self:StyleSource(window)
   if type(window.OnStyleChanged)=="function"and not self.windows[window].watchStyle then
    self.windows[window].watchStyle=true
    hooksecurefunc(window,"OnStyleChanged",function()self:QueueStyle()end)
   end
  end
 end
 for row,pending in pairs(self.rows)do if pending then self:StyleRow(row)end end
end
function M:Checks()
 local available,reason=self:Available()
 if not available then return {{status="WARNING",message=reason or "Native damage meters are unavailable in this client.",setting="Utilities > Damage meter"}}end
 if not self:Enabled()then return {{status="INFO",message="Native damage meters are off by choice. RUI does not control external meters.",setting="Utilities > Enable native damage meter"}}end
 return {}
end
function M:OnPlayerLogin()
 if ProjectRuthlessCharDB and not ProjectRuthlessCharDB.ruiMeterInitialized and not ProjectRuthlessCharDB.activeProfile then
  local function activate()
   local ok=self:SetEnabled(true)
   if ok then ProjectRuthlessCharDB.ruiMeterInitialized=true end
  end
  AUI:AfterCombat("initialMeter",activate)
 end
 self:ApplySettings()
 local events=CreateFrame("Frame");self.events=events
 events:RegisterEvent("ADDON_LOADED");events:RegisterEvent("CVAR_UPDATE");events:RegisterEvent("PLAYER_REGEN_ENABLED")
 events:SetScript("OnEvent",function(_,event,name)
  if event=="ADDON_LOADED"and name~="Blizzard_DamageMeter"or event=="CVAR_UPDATE"and name~="damageMeterEnabled"then return end
  self:QueueStyle()
 end)
end
