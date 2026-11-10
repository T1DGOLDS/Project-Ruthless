local _,AUI=...
local R={};AUI:RegisterModule("RepairReminder",R)
local function read(fn,...)
 if type(fn)~="function"then return end
 local ok,a,b=pcall(fn,...)
 if ok and not(issecretvalue and (issecretvalue(a)or issecretvalue(b)))then return a,b end
end
local function number(v)return type(v)=="number"and v==v and math.abs(v)<1e9 end
function R:Settings()return ProjectRuthlessDB.general or {}end
function R:Snapshot()
 local rule=Enum and Enum.GameRule and Enum.GameRule.RepairArmorDisabled
 if rule and read(C_GameRules and C_GameRules.IsGameRuleActive,rule)then return 100,{},true end
 if type(GetInventoryItemDurability)~="function"then return end
 local lowest,items=100,{}
 for slot=1,19 do
  local ok,current,maximum=pcall(GetInventoryItemDurability,slot)
  if not ok or issecretvalue and (issecretvalue(current)or issecretvalue(maximum))then return end
  if number(current)and number(maximum)and maximum>0 then
   local percent=math.max(0,math.min(100,current/maximum*100));lowest=math.min(lowest,percent)
   items[#items+1]={slot=slot,percent=percent}
  end
 end
 table.sort(items,function(a,b)return a.percent<b.percent end)
 return lowest,items
end
function R:SuppressNative(enabled)
 if not DurabilityFrame or InCombatLockdown()then return end
 if enabled then
  if self.nativeAlpha==nil then self.nativeAlpha=read(DurabilityFrame.GetAlpha,DurabilityFrame)or 1 end
  DurabilityFrame:SetAlpha(0)
 elseif self.nativeAlpha~=nil then DurabilityFrame:SetAlpha(self.nativeAlpha);self.nativeAlpha=nil end
end
function R:Refresh()
 local s=self:Settings();local enabled=s.repairIndicator~=false
 if not enabled then self:SuppressNative(false);if self.frame then self.frame:Hide()end;self.wasLow=nil;return end
 local lowest,items,disabled=self:Snapshot()
 if not lowest then
  if self.frame and self.frame:IsShown()then self.title:SetText("Check equipment");self.detail:SetText("Durability unavailable")else self:SuppressNative(false)end
  return
 end
 self:SuppressNative(true)
 self.items=items;self.lowest=lowest
 local threshold=math.max(5,math.min(75,tonumber(s.repairThreshold)or 30))
 local low=not disabled and lowest<=threshold
 if low then
  self:Create();local broken=lowest==0
  local r,g,b=1,broken and .2 or .75,.2
  self.title:SetText(broken and "Equipment broken · 0%"or ("Repair needed · %.0f%%"):format(lowest))
  self.title:SetTextColor(r,g,b);self.frame:SetBackdropBorderColor(r,g,b,.9)
  self.detail:SetText("Drag to move · Item details");self.frame:Show()
  -- Crossing the threshold (or logging in low) alerts once. Repairing resets
  -- it, while repeated inventory events and reopening a vendor remain quiet.
  if (not self.wasLow or broken and not self.wasBroken)and s.repairReminder~=false then
   local message=broken and "Equipment broken — visit a repair vendor."or ("Repair reminder: lowest equipped item is %.0f%%."):format(lowest)
   AUI:Print(message)
   if UIErrorsFrame then UIErrorsFrame:AddMessage(message,r,g,b,1)end
   if s.repairSound==true and PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON,"Master")end
  end
 elseif self.frame then self.frame:Hide()end
 self.wasLow=low;self.wasBroken=lowest==0 and low
end
function R:Create()
 if self.frame then return end
 local f=CreateFrame("Frame","RUIRepairReminder",UIParent,"BackdropTemplate");self.frame=f
 f:SetSize(266,54);f:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-30,-224);f:SetFrameStrata("MEDIUM")
 f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1});AUI:StyleSurface(f,"window",nil,"Options")
 local icon=f:CreateTexture(nil,"ARTWORK");icon:SetSize(28,28);icon:SetPoint("LEFT",7,0);icon:SetTexture("Interface\\Icons\\Trade_BlackSmithing");icon:SetTexCoord(.07,.93,.07,.93)
 self.title=f:CreateFontString(nil,"OVERLAY","GameFontNormal");self.title:SetPoint("TOPLEFT",42,-6);self.title:SetPoint("TOPRIGHT",-6,-6);self.title:SetJustifyH("LEFT")
 self.detail=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");self.detail:SetPoint("BOTTOMLEFT",42,6);self.detail:SetPoint("BOTTOMRIGHT",-6,6);self.detail:SetJustifyH("LEFT")
 local access=AUI.modules.Accessibility
 for _,font in ipairs({self.title,self.detail})do font:SetWordWrap(false);if access then access:RegisterText(font)end end
 f:SetMovable(true);f:SetClampedToScreen(true);f:EnableMouse(true);f:RegisterForDrag("LeftButton")
 local editor=AUI.modules.LayoutEditor;editor:Attach("repair","Repair warning",f)
 f:SetScript("OnDragStart",function()f:StartMoving()end)
 f:SetScript("OnDragStop",function()f:StopMovingOrSizing();local position=editor:Capture(f);if position then editor:Store().elements.repair=position end end)
 f:SetScript("OnEnter",function()
  GameTooltip:SetOwner(f,"ANCHOR_LEFT");GameTooltip:SetText("Equipment durability")
  for _,item in ipairs(self.items or {})do
   local link=read(GetInventoryItemLink,"player",item.slot)
   GameTooltip:AddDoubleLine(type(link)=="string"and link or ("Equipment slot "..item.slot),("%.0f%%"):format(item.percent),1,1,1,1,item.percent==0 and .2 or .8,.3)
  end
  GameTooltip:AddLine("Drag to move. Threshold and reminders: RUI Settings > Combat & utilities.",.7,.75,.8,true);GameTooltip:Show()
 end)
 f:SetScript("OnLeave",function()GameTooltip:Hide()end);f:Hide()
end
function R:Preview()
 self:Create();self.title:SetText("Repair warning · Preview");self.detail:SetText("Drag to move · Position saves");self.frame:Show()
 C_Timer.After(10,function()self:Refresh()end)
end
function R:ApplySettings()self:Refresh()end
function R:OnPlayerLogin()
 if not AUI.isForever then return end
 self:Create();self.events=CreateFrame("Frame")
 for _,event in ipairs({"UPDATE_INVENTORY_DURABILITY","UPDATE_INVENTORY_ALERTS","PLAYER_EQUIPMENT_CHANGED","PLAYER_ENTERING_WORLD","MERCHANT_SHOW","MERCHANT_CLOSED","PLAYER_REGEN_ENABLED","ADDON_LOADED"})do self.events:RegisterEvent(event)end
 self.events:SetScript("OnEvent",function(_,event,name)
  if event=="ADDON_LOADED"and name~="Blizzard_DurabilityFrame"then return end
  if self.queued then return end;self.queued=true
  C_Timer.After(.1,function()self.queued=nil;self:Refresh()end)
 end)
 self:Refresh()
end
