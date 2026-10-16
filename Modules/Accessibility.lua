local _,AUI=...
local A={fonts=setmetatable({},{__mode="k"})}
AUI:RegisterModule("Accessibility",A)
function A:Settings()return ProjectRuthlessDB.accessibility or {}end
function A:ReducedMotion()
 local value=self:Settings().reducedMotion
 if value~=nil then return value==true end
 if C_CVar and C_CVar.GetCVarBool then
  local ok,reduced=pcall(C_CVar.GetCVarBool,"CameraReduceUnexpectedMovement")
  local good,centered=pcall(C_CVar.GetCVarBool,"CameraKeepCharacterCentered")
  if ok and good and not(issecretvalue and (issecretvalue(reduced)or issecretvalue(centered)))then return reduced==true and centered==false end
 end
 return false
end
function A:AnimatedPortraits()return self:Settings().animatedPortraits~=false and not self:ReducedMotion()end
function A:TextScale()return math.max(1,math.min(1.5,tonumber(self:Settings().textScale)or 1))end
function A:FitWindow(frame,requested)
 if not frame or type(frame.GetWidth)~="function"or not UIParent then return requested end
 local width,height=frame:GetWidth(),frame:GetHeight()
 if type(width)~="number"or type(height)~="number"or width<=0 or height<=0 then return requested end
 return math.max(.5,math.min(requested,(UIParent:GetWidth()-32)/width,(UIParent:GetHeight()-32)/height))
end
function A:RegisterText(font)
 if not font or type(font.GetFont)~="function"then return end
 if not self.fonts[font]then
  local path,size,flags=font:GetFont()
  if type(path)~="string"or type(size)~="number"then return end
  self.fonts[font]={path=path,size=size,flags=flags}
 end
 local base=self.fonts[font];font:SetFont(base.path,base.size*self:TextScale(),base.flags)
end
function A:BindMenu(menu)
 local frame=menu.frame
 frame:EnableKeyboard(true);frame:SetPropagateKeyboardInput(true)
 frame:HookScript("OnHide",function()self.keyboardRow=nil end)
 frame:HookScript("OnKeyDown",function(_,key)
  frame:SetPropagateKeyboardInput(true)
  -- Editors retain native typing, caret, Tab and Escape behavior.
  if type(GetCurrentKeyBoardFocus)=="function"and GetCurrentKeyBoardFocus()then return end
  local registry=AUI.modules.SettingsRegistry;local rows={}
  if key=="PAGEUP"or key=="PAGEDOWN"then
   local index=1;for i,tab in ipairs(menu.tabs)do if tab.panelID==menu.selectedTab then index=i;break end end
   index=(index-1+(key=="PAGEDOWN"and 1 or -1))%#menu.tabs+1
   self.keyboardRow=nil;menu:SelectTab(menu.tabs[index].panelID);frame:SetPropagateKeyboardInput(false);return
  end
  for _,row in ipairs(registry.controls)do
   if row.page==menu.selectedTab and row.control:IsVisible()then rows[#rows+1]=row end
  end
  if key=="TAB"and #rows>0 then
   local index=0;for i,row in ipairs(rows)do if row==self.keyboardRow then index=i;break end end
   local direction=type(IsShiftKeyDown)=="function"and IsShiftKeyDown()and -1 or 1
   self.keyboardRow=rows[(index-1+direction)%#rows+1]
   menu:OpenSearchResult(self.keyboardRow);frame:SetPropagateKeyboardInput(false)
  elseif self.keyboardRow and self.keyboardRow.control:IsVisible()then
   local row=self.keyboardRow;local control=row.control
   if key=="ENTER"or key=="SPACE"then
    local script=control:GetScript("OnClick")
    if script and (not control.IsEnabled or control:IsEnabled())then script(control,"LeftButton");frame:SetPropagateKeyboardInput(false)end
   elseif (key=="LEFT"or key=="RIGHT")and control.ruiSlider then
    local slider=control.ruiSlider;slider:SetValue(slider:GetValue()+(key=="RIGHT"and 1 or -1)*control.ruiStep)
    frame:SetPropagateKeyboardInput(false)
   end
  end
 end)
end
function A:OpenNativeCategory(label)
 if type(label)~="string"then AUI:Print("This native accessibility category is unavailable in the current client.");return false end
 if not Settings or not Settings.GetCategory or not Settings.OpenToCategory then AUI:Print("Native settings are unavailable in this client.");return false end
 local category=Settings.GetCategory(label)
 if not category then AUI:Print("This native accessibility category is unavailable in the current client.");return false end
 Settings.OpenToCategory(category:GetID());return true
end
function A:ApplySettings()
 for font in pairs(self.fonts)do self:RegisterText(font)end
    local checks=AUI.modules.LiveChecks
    if checks and checks.frame and checks.frame:IsShown()then
        checks.frame:SetScale(self:FitWindow(checks.frame,(ProjectRuthlessDB.general or {}).windowScale or 1));checks:Refresh()
    end
    local diagnostics=AUI.modules.Diagnostics
    if diagnostics and diagnostics.frame and diagnostics.frame:IsShown()and diagnostics.LayoutReporter then diagnostics:LayoutReporter()end
 AUI:RefreshBackgrounds()
 AUI:ApplyWindowSettings("accessibility")
 local hud=AUI.modules.ForeverHUD
 if hud and hud.RefreshPortraits then hud:RefreshPortraits()end
 local book=AUI.modules.Spellbook
 if book and book.frame and book.frame:IsShown()and book.Refresh then book:Refresh()end
end
