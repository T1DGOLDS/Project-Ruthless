local _,AUI=...
local I={}
AUI:RegisterModule("ForeverInventory",I)
local function public(v)return not(issecretvalue and issecretvalue(v))end
local function count(id)
 local n=C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(id)
 if public(n)and type(n)=="number"and n>=0 and n<=1000 then return n end
 return 0
end
function I:IsReagent(id)
 return public(id)and type(id)=="number"and ContainerFrame_IsReagentBag and ContainerFrame_IsReagentBag(id)==true
end
function I:AppendItems(frame)
 local items=frame.Items or {}
 local baseline=#items
 if self.enabled==false then frame.size=baseline;return end
 if InCombatLockdown()and frame.IsProtected and frame:IsProtected()then
  frame.size=baseline
  AUI:AfterCombat("reagentBagItems",function()self:Refresh()end);return
 end
 -- Detect the actual native caller's contract from its initialized buttons.
 -- Current Forever supplies (containerFrame, bag, slot); older clients used
 -- (bag, slot). Do not guess from the game version or the addon source pin.
 local native=items[1]
 if not native then frame.size=baseline;return end
 local withContainer=native.containerFrame==frame
 local present={}
 for _,button in ipairs(items)do
  if button.GetBagID and button.GetID then
   local bag,slot=button:GetBagID(),button:GetID()
   if public(bag)and public(slot)and type(bag)=="number"and type(slot)=="number"then present[bag..":"..slot]=true end
  end
 end
 local ok,problem=pcall(function()
  for bag=0,NUM_TOTAL_BAG_FRAMES or 5 do
   if self:IsReagent(bag)then
    for slot=count(bag),1,-1 do
     if not present[bag..":"..slot]then
      local button=frame:AcquireNewItemButton()
      if withContainer then button:Initialize(frame,bag,slot)else button:Initialize(bag,slot)end
      if button:GetBagID()~=bag or button:GetID()~=slot then error("Invalid native reagent item identity")end
     end
    end
   end
  end
 end)
 if not ok then
  -- Keep native enumerators consistent even if a future client changes again.
  -- Never advertise slots that have no valid native button behind them.
  for index=#items,baseline+1,-1 do
   local button=table.remove(items,index)
   if frame.itemButtonPool and frame.itemButtonPool.Release then frame.itemButtonPool:Release(button)
   elseif button.Hide then button:Hide()end
  end
  self.enabled=false;self.lastFailure=tostring(problem)
  AUI:Print("Reagent merge unavailable: the backpack is preserved. Open the reagent bag separately.")
 end
 frame.size=#items
end
function I:Refresh()
 local frame=ContainerFrameCombinedBags
 if not frame or not self.installed or not frame:IsShown()then return end
 if InCombatLockdown()then AUI:AfterCombat("reagentBagRefresh",function()self:Refresh()end);return end
 -- Generate through the original native pool/update path, preserving every
 -- button's bag/slot identity, item handlers, search, cooldowns and tooltips.
 if ContainerFrame_GenerateFrame then ContainerFrame_GenerateFrame(frame,0,0)end
end
function I:Install()
 if self.installed or not AUI.isForever then return end
 if InCombatLockdown()then AUI:AfterCombat("reagentBagInstall",function()self:Install()end);return end
 local frame,manager=ContainerFrameCombinedBags,ContainerFrameSettingsManager
 if not frame or not manager or not C_Container or not ContainerFrame_IsReagentBag
  or type(frame.UpdateItemSlots)~="function"or type(frame.AcquireNewItemButton)~="function"
  or type(frame.MatchesBagID)~="function"or type(frame.IsBagOpen)~="function"
  or type(frame.SetBagSize)~="function"or type(manager.IsUsingCombinedBags)~="function"then return end
 self.installed=true;self.enabled=true
 local matches=frame.MatchesBagID
 frame.MatchesBagID=function(owner,id)return self.enabled~=false and self:IsReagent(id)or matches(owner,id)end
 local open=frame.IsBagOpen
 frame.IsBagOpen=function(owner,id)if self.enabled~=false and self:IsReagent(id)and owner:IsShown()then return id end;return open(owner,id)end
 local combined=manager.IsUsingCombinedBags
 manager.IsUsingCombinedBags=function(owner,id)
  if self.enabled~=false and self:IsReagent(id)then return combined(owner)end
  return combined(owner,id)
 end
 hooksecurefunc(frame,"UpdateItemSlots",function(owner)self:AppendItems(owner)end)
 -- Close only duplicate held reagent windows; bank and other containers retain
 -- their native routing. Future opens resolve through the combined manager.
 for index=1,NUM_CONTAINER_FRAMES or 13 do
  local individual=_G["ContainerFrame"..index]
  if manager:IsUsingCombinedBags()and individual and individual~=frame and individual.GetBagID and self:IsReagent(individual:GetBagID())then individual:Hide()end
 end
 self:Refresh()
end
function I:OnPlayerLogin()
 self:Install()
 local events=CreateFrame("Frame");self.events=events;events:RegisterEvent("ADDON_LOADED")
 events:SetScript("OnEvent",function(_,_,name)if name=="Blizzard_UIPanels_Game"then self:Install()end end)
end
