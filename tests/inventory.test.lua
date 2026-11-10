local busy=false;function InCombatLockdown()return busy end
local secret={};function issecretvalue(v)return v==secret end
NUM_TOTAL_BAG_FRAMES=5;NUM_CONTAINER_FRAMES=2
local sizes={[0]=16,[1]=6,[2]=8,[3]=0,[4]=0,[5]=8}
C_Container={GetContainerNumSlots=function(id)return sizes[id]or 0 end}
ContainerFrame_IsReagentBag=function(id)return id==5 end
ContainerFrame_IsGenericHeldBag=function(id)return id>=0 and id<=4 end
ContainerFrame_IsBankTab=function(id)return id>=6 end
InputUtil={IsGamepadUIEnabled=function()return false end}
ContainerFrameSettingsManager={isUsingCombinedBags=true}
assert(load(NATIVE_BAG_ROUTING))()
assert(not ContainerFrameSettingsManager:IsUsingCombinedBags(5))
local slots={};local clicks=0
ContainerFrameItemButtonMixin={};assert(load(NATIVE_ITEM_INITIALIZE))()
local function button(parent)
 local b={parent=parent,OnClick=function()clicks=clicks+1 end}
 function b:SetBagID(id)self.bag=id end;function b:GetBagID()return self.bag end
 function b:SetID(id)assert(type(id)=="number"and id>=1 and id%1==0,"SetID requires a valid slot");self.id=id end;function b:GetID()return self.id end
 function b:UpdateExtended()end;function b:GetParent()return self.parent end
 function b:CreateTexture()return {SetAllPoints=function()end,SetShown=function()end}end
 function b:Show()self.shown=true end
 b.Initialize=ContainerFrameItemButtonMixin.Initialize
 return b
end
local frame={shown=true,Items={}}
function frame:IsShown()return self.shown end;function frame:IsProtected()return self.protected==true end
function frame:IsCombinedBagContainer()return true end
function frame:MatchesBagID(id)return ContainerFrame_IsGenericHeldBag(id)end
function frame:IsBagOpen(id)if self.shown and id<=4 then return id end end
function frame:AcquireNewItemButton()local b=button(self);self.Items[#self.Items+1]=b;return b end
function frame:SetBagSize()self.size=30 end
function frame:UpdateItemSlots()
 self.Items={}
 for bag=4,0,-1 do for slot=sizes[bag],1,-1 do
  local b=self:AcquireNewItemButton()
  if CONTAINER_ARGUMENT then b:Initialize(self,bag,slot)else b:Initialize(bag,slot)end
 end end
end
if NATIVE_ITEM_SLOTS~=""then
 ContainerFrameMixin={};assert(load(NATIVE_ITEM_SLOTS))()
 function GetBagSetupIndices()return 4,0,-1 end
 function ContainerFrame_GetContainerNumSlots(id)return sizes[id]or 0 end
 function frame:ClearItems()self.Items={}end
 frame.UpdateItemSlots=ContainerFrameMixin.UpdateItemSlots
end
ContainerFrameCombinedBags=frame
local reagent={shown=true,GetBagID=function()return 5 end,Hide=function(self)self.shown=false end}
local bank={shown=true,GetBagID=function()return 6 end,Hide=function(self)self.shown=false end}
ContainerFrame1=reagent;ContainerFrame2=bank
function ContainerFrame_GenerateFrame(owner)owner:SetBagSize();owner:UpdateItemSlots()end
function hooksecurefunc(owner,key,fn)local old=owner[key];owner[key]=function(self,...)old(self,...);fn(self,...)end end
function CreateFrame()return {RegisterEvent=function()end,SetScript=function(self,_,fn)self.event=fn end}end
local pending={};local AUI={modules={},isForever=true}
function AUI:RegisterModule(id,value)self.modules[id]=value end
function AUI:Print(message)self.message=message end
function AUI:AfterCombat(id,fn)pending[id]=fn end
assert(load(INVENTORY_SOURCE))('RUI',AUI);local inventory=AUI.modules.ForeverInventory
inventory:OnPlayerLogin()
assert(inventory.installed and frame.size==38 and #frame.Items==38)
assert(not reagent.shown and bank.shown)
assert(ContainerFrameSettingsManager:IsUsingCombinedBags(5)and not ContainerFrameSettingsManager:IsUsingCombinedBags(6))
assert(frame:MatchesBagID(5)and not frame:MatchesBagID(6)and frame:IsBagOpen(5)==5)
local function verify()
 assert(frame.size==#frame.Items,"Native valid-item enumeration must never exceed live buttons")
 for index=1,frame.size do assert(frame.Items[index]and type(frame.Items[index]:GetID())=="number")end
 local seen={};for _,b in ipairs(frame.Items)do local id=b:GetBagID()..':'..b:GetID();assert(not seen[id]);seen[id]=true end
 for slot=1,sizes[5]do assert(seen['5:'..slot])end
end
verify();local handler=frame.Items[38].OnClick;handler();assert(clicks==1)
for _=1,5 do inventory:AppendItems(frame)end;assert(#frame.Items==38)
frame:UpdateItemSlots();verify();assert(#frame.Items==38)
sizes[5]=12;inventory:Refresh();assert(frame.size==42 and #frame.Items==42);verify()
sizes[5]=0;inventory:Refresh();assert(frame.size==30 and #frame.Items==30)
ContainerFrameSettingsManager.isUsingCombinedBags=false;assert(not ContainerFrameSettingsManager:IsUsingCombinedBags(5))
ContainerFrameSettingsManager.isUsingCombinedBags=true;sizes[5]=8
busy=true;frame.protected=true;frame:UpdateItemSlots();assert(#frame.Items==30 and pending.reagentBagItems)
busy=false;frame.protected=false;pending.reagentBagItems();assert(#frame.Items==38)
local wrapped=ContainerFrameSettingsManager.IsUsingCombinedBags;inventory:Install();assert(ContainerFrameSettingsManager.IsUsingCombinedBags==wrapped)
-- A future initializer failure must preserve the ordinary backpack and routing.
local acquire=frame.AcquireNewItemButton
function frame:AcquireNewItemButton()
 local b=acquire(self);local original=b.Initialize
 b.Initialize=function(owner,...)
  local args={...};local bag=CONTAINER_ARGUMENT and args[2]or args[1]
  if bag==5 then error("future incompatible initializer")end
  return original(owner,...)
 end
 return b
end
frame:SetBagSize();frame:UpdateItemSlots()
assert(inventory.enabled==false and #frame.Items==30 and frame.size==30 and AUI.message)
assert(not frame:MatchesBagID(5)and not ContainerFrameSettingsManager:IsUsingCombinedBags(5))
frame.shown=false;assert(frame:IsBagOpen(5)==nil)
print('PASS ('..CONTRACT_LABEL..'): reagent slots share native combined pool, native Initialize and retained clicks; routing excludes bank, respects split-bag mode, rebuilds without duplicates, handles bag swaps/removal and defers protected combat work')
