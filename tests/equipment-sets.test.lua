unpack = table.unpack
function strtrim(value) return (value or ""):match("^%s*(.-)%s*$") end

local Frame = {}; Frame.__index = Frame
function Frame:SetBackdrop(value) self.backdrop=value end
function Frame:SetBackdropColor(...) self.background={...} end
function Frame:SetBackdropBorderColor(...) self.border={...} end
function Frame:SetPoint(...) self.point={...} end
function Frame:ClearAllPoints() self.point=nil; self.cleared=true end
function Frame:SetParent(parent) self.parent=parent end
function Frame:SetSize(w,h) self.width=w; self.height=h end
function Frame:SetID(value) self.id=value end
function Frame:GetID() return self.id end
function Frame:SetWidth(w) self.width=w end
function Frame:SetHeight(h) self.height=h end
function Frame:SetText(value) self.text=value end
function Frame:GetText() return self.text end
function Frame:SetTextColor(...) self.color={...} end
function Frame:SetJustifyH(value) self.justify=value end
function Frame:SetTexCoord(...) self.texcoord={...} end
function Frame:SetTexture(value) self.texture=value end
function Frame:SetShown(value) self.shown=value end
function Frame:Show() self.shown=true end
function Frame:Hide() self.shown=false end
function Frame:IsShown() return self.shown end
function Frame:SetEnabled(value) self.enabled=value end
function Frame:IsEnabled() return self.enabled end
function Frame:SetFocus() self.focused=true end
function Frame:HighlightText() self.highlighted=true end
function Frame:SetScript(name, callback) self.scripts[name]=callback end
function Frame:GetScript(name) return self.scripts[name] end
function Frame:GetParent() return self.parent end
function Frame:Click() if self.scripts.OnClick then self.scripts.OnClick(self) end end
function Frame:GetFrameLevel() return self.frameLevel or 10 end
function Frame:SetFrameLevel(value) self.frameLevel=value end
function Frame:SetFrameStrata(value) self.frameStrata=value end
function Frame:RegisterEvent(event) self.registered=self.registered or {}; self.registered[event]=true end
function Frame:UnregisterEvent(event) self.unregistered=self.unregistered or {}; self.unregistered[event]=true; if self.registered then self.registered[event]=nil end end
function Frame:IsMouseOver() return self.mouseOver end
function Frame:RegisterForClicks(...) self.clicks={...} end
function Frame:RegisterForDrag(...) self.drags={...} end
function Frame:SetScrollChild(child) self.child=child end
function Frame:SetDesaturated(value) self.desaturated=value end
function Frame:SetVertexColor(...) self.vertex={...} end
function Frame:SetAlpha(value) self.alpha=value end
function Frame:SetAtlas(value) self.atlas=value end
function Frame:CreateFontString() return setmetatable({parent=self,scripts={},shown=true,enabled=true},Frame) end
function Frame:CreateTexture() return setmetatable({parent=self,scripts={},shown=true,enabled=true},Frame) end
function CreateFrame(_,name,parent,template) return setmetatable({name=name,parent=parent,template=template,scripts={},shown=true,enabled=true},Frame) end

local AUI = {modules={}, messages={}}
function AUI:RegisterModule(name, module) self.modules[name]=module end
function AUI:Print(message) self.messages[#self.messages+1]=message end
function AUI:CreateButton(parent) return CreateFrame("Button",nil,parent) end
function AUI:CreateSmoothScrollFrame(parent) return CreateFrame("ScrollFrame",nil,parent) end

RAID_CLASS_COLORS={PALADIN={r=.96,g=.55,b=.73}}
function UnitClass() return "Paladin", "PALADIN" end
local combat, casting, locked = false, false, false
function InCombatLockdown() return combat end
function UnitCastingInfo() return casting and "Cast" or nil end
function UnitChannelInfo() return nil end
local nativeFlyoutClicks, nativeFlyoutQueries, nativeClicks, nativeModifiedClicks, nativeEnters, nativeLeaves = 0, 0, 0, 0, 0, 0
GameTooltip={SetOwner=function(_, owner, anchor) GameTooltip.owner=owner; GameTooltip.anchor=anchor end,AddLine=function() end,Show=function() GameTooltip.shown=true end,Hide=function() GameTooltip.hidden=true end}
function GameTooltip_Hide() end
function GetInventoryItemLink(_, slotID) return slotID == 1 and "item:head" or nil end
function GetInventoryItemTexture(_, slotID) return slotID == 1 and 136243 or nil end
function PaperDollFrameItemFlyout_GetItems() nativeFlyoutQueries=nativeFlyoutQueries+1 end
function PaperDollFrameItemFlyoutButton_OnClick() nativeFlyoutClicks=nativeFlyoutClicks+1 end
function PaperDollFrameItemFlyout_PostGetItems() end
PaperDollItemSlotButtonBaseMixin={SetTooltipAnchor=function(self, tooltip) tooltip.owner=self end}
function PaperDollItemSlotButton_OnClick() nativeClicks=nativeClicks+1 end
function PaperDollItemSlotButton_OnModifiedClick() nativeModifiedClicks=nativeModifiedClicks+1 end
function PaperDollItemSlotButton_OnEnter() nativeEnters=nativeEnters+1 end
function PaperDollItemSlotButton_OnLeave() nativeLeaves=nativeLeaves+1 end
CANCEL="Cancel"; DELETE="Delete"; MAX_EQUIPMENT_SETS_PER_PLAYER=20
StaticPopupDialogs={}
local popups={}
function StaticPopup_Show(kind, arg1, _, data)
    local popup = CreateFrame("Frame")
    popup.kind=kind; popup.arg1=arg1; popup.data=data
    local dialog = StaticPopupDialogs[kind]
    if dialog and dialog.hasEditBox then popup.EditBox=CreateFrame("EditBox",nil,popup) end
    popup.Button1=CreateFrame("Button",nil,popup)
    popup.Button1:SetScript("OnClick", function() if dialog and dialog.OnAccept then dialog.OnAccept(popup, popup.data) end end)
    if dialog and dialog.OnShow then dialog.OnShow(popup, popup.data) end
    popups[#popups+1]=popup
    return popup
end

local records={
    [1]={name="Raid",icon=111,equipped=false,items=16,equippedItems=8,ignored={[4]=true,[19]=true}},
    [2]={name="Mythic+",icon=222,equipped=true,items=16,equippedItems=16,ignored={[4]=true}},
}
local ids={1,2}; local calls={clear=0,ignore={},create={},save={},use={},modify={},delete={}}
local function hasIgnoredSlot(slot)
    for _, value in ipairs(calls.ignore) do if value == slot then return true end end
    return false
end
C_EquipmentSet={}
function C_EquipmentSet.CanUseEquipmentSets() return true end
function C_EquipmentSet.GetNumEquipmentSets() return #ids end
function C_EquipmentSet.GetEquipmentSetIDs() return ids end
function C_EquipmentSet.GetEquipmentSetID(name)
    for id, record in pairs(records) do if record.name==name then return id end end
end
function C_EquipmentSet.GetEquipmentSetInfo(id)
    local record=records[id]
    if not record then return nil end
    return record.name,record.icon,id,record.equipped,record.items,record.equippedItems,record.items,0,0
end
function C_EquipmentSet.GetIgnoredSlots(id) return records[id] and records[id].ignored end
function C_EquipmentSet.ClearIgnoredSlotsForSave() calls.clear=calls.clear+1 end
function C_EquipmentSet.IgnoreSlotForSave(slot) calls.ignore[#calls.ignore+1]=slot end
function C_EquipmentSet.CreateEquipmentSet(name,icon) calls.create[#calls.create+1]={name,icon} end
function C_EquipmentSet.SaveEquipmentSet(id,icon) calls.save[#calls.save+1]={id,icon} end
function C_EquipmentSet.UseEquipmentSet(id) calls.use[#calls.use+1]=id end
function C_EquipmentSet.ModifyEquipmentSet(id,name,icon) calls.modify[#calls.modify+1]={id,name,icon}; records[id].name=name end
function C_EquipmentSet.DeleteEquipmentSet(id) calls.delete[#calls.delete+1]=id; records[id]=nil; for index,value in ipairs(ids) do if value==id then table.remove(ids,index); break end end end
function C_EquipmentSet.EquipmentSetContainsLockedItems() return locked end

assert(load(CHARACTER_SOURCE))("ProjectRuthless",AUI)
local Character=AUI.modules.Character

local gear=CreateFrame("Frame")
Character:ConfigureGearFlyout(gear)
assert(gear.flyoutSettings.parent==gear and gear.flyoutSettings.hasPopouts, "gear must expose native flyout settings")
assert(gear.flyoutSettings.getItemsFunc==PaperDollFrameItemFlyout_GetItems, "flyout item lookup must use Blizzard's PaperDoll callback")
assert(gear.flyoutSettings.onClickFunc==PaperDollFrameItemFlyoutButton_OnClick, "flyout clicks must use Blizzard's PaperDoll callback")
Character:CreateItemSlot(gear,1,"TOPLEFT",0,0,"ANCHOR_RIGHT")
local slot=Character.slots[#Character.slots]
assert(slot:GetID()==1 and slot.id==1, "equipment slots must expose their inventory slot ID to Blizzard's flyout")
assert(slot.SetTooltipAnchor==PaperDollItemSlotButtonBaseMixin.SetTooltipAnchor, "slot must expose Blizzard's tooltip-anchor mixin")
assert(slot.scripts.OnEnter==PaperDollItemSlotButton_OnEnter and slot.scripts.OnLeave==PaperDollItemSlotButton_OnLeave, "hover must use Blizzard's PaperDoll handlers")
slot.scripts.OnDragStart(slot); slot.scripts.OnReceiveDrag(slot); assert(nativeClicks==2, "drag/drop must use Blizzard's PaperDoll click handler")
function IsModifiedClick(kind) return kind==nil end
slot.scripts.OnClick(slot,"RightButton"); assert(nativeModifiedClicks==1, "modified clicks must use Blizzard's socket and item-link handler")
function IsModifiedClick(kind) return false end
slot.scripts.OnClick(slot,"RightButton"); assert(nativeClicks==3, "ordinary clicks must use Blizzard's inventory handler")

IconSelectorPopupFrameModes={New="new",Edit="edit"}
PaperDollFrame={EquipmentManagerPane={}}
local clearedIgnored, ignoredDefaults = false, {}
function PaperDollFrame_ClearIgnoredSlots() clearedIgnored=true end
function PaperDollFrame_IgnoreSlot(slotID) ignoredDefaults[#ignoredDefaults+1]=slotID end
GearManagerPopupFrame=CreateFrame("Frame")
UIParent=CreateFrame("Frame")
Character.frame=CreateFrame("Frame")
assert(Character:ShowNativeEquipmentSetPopup("new"), "native gear manager popup must be used when available")
assert(GearManagerPopupFrame.mode==IconSelectorPopupFrameModes.New and GearManagerPopupFrame.shown, "New set must open Blizzard's icon-capable popup")
assert(GearManagerPopupFrame.parent==UIParent and GearManagerPopupFrame.frameStrata=="DIALOG" and GearManagerPopupFrame.frameLevel==100, "native popup must retain a standalone Blizzard layout above the Ruthless frame")
assert(clearedIgnored and ignoredDefaults[1]==4 and ignoredDefaults[2]==19, "native new-set popup must keep shirt/tabard ignored")
assert(Character:ShowNativeEquipmentSetPopup("edit",1), "Rename must be able to open Blizzard's icon-capable popup")
assert(GearManagerPopupFrame.mode==IconSelectorPopupFrameModes.Edit and GearManagerPopupFrame.setID==1 and GearManagerPopupFrame.origName=="Raid", "native edit popup must receive the selected set")
assert(PaperDollFrame.EquipmentManagerPane.selectedSetID==1, "native edit popup must mirror the selected equipment set")
GearManagerPopupFrame=nil
IconSelectorPopupFrameModes=nil
PaperDollFrame=nil

local holder=CreateFrame("Frame")
Character:CreateSetsView(holder)
Character:RefreshSets()
assert(#Character.setRows==2 and Character.setsContent.height==84)
assert(not Character.setActions.save:IsEnabled())

Character.setRows[1].scripts.OnClick(Character.setRows[1])
assert(Character.selectedSetID==1 and #calls.save==0 and #calls.use==0, "selecting a row must not mutate equipment")
assert(Character.setActions.save:IsEnabled() and Character.setsView.selected.text=="Selected: Raid")

Character.setActions.save.scripts.OnClick(Character.setActions.save)
assert(popups[#popups].kind=="PROJECT_RUTHLESS_SAVE_EQUIPMENT_SET" and #calls.save==0, "Save must require confirmation")
StaticPopupDialogs.PROJECT_RUTHLESS_SAVE_EQUIPMENT_SET.OnAccept(nil,1)
assert(#calls.save==1 and calls.save[1][1]==1 and calls.save[1][2]==111, "confirmed save must preserve the set icon")
assert(calls.clear==2 and hasIgnoredSlot(4) and hasIgnoredSlot(19), "save must restore ignored slots")

local saved=#calls.save
Character.setActions.save.scripts.OnClick(Character.setActions.save)
assert(#calls.save==saved, "opening then cancelling Save must not write")
Character.setActions.equip.scripts.OnClick(Character.setActions.equip)
assert(#calls.use==1 and calls.use[1]==1, "Equip action must use the selected set")
locked=true; Character.setActions.equip.scripts.OnClick(Character.setActions.equip); assert(#calls.use==1, "locked sets must not equip"); locked=false

Character.setActions.rename.scripts.OnClick(Character.setActions.rename)
assert(popups[#popups].kind=="PROJECT_RUTHLESS_RENAME_EQUIPMENT_SET" and #calls.modify==0, "Rename must require its dialog")
assert(popups[#popups].EditBox.text=="Raid", "Rename dialog must show the selected set name")
local renamePopup={EditBox=CreateFrame("EditBox"), data=1}; renamePopup.EditBox:SetText("Raid updated")
StaticPopupDialogs.PROJECT_RUTHLESS_RENAME_EQUIPMENT_SET.OnShow(renamePopup,1)
assert(renamePopup.EditBox.text=="Raid", "Rename dialog must show the current name")
renamePopup.EditBox:SetText("Raid updated")
StaticPopupDialogs.PROJECT_RUTHLESS_RENAME_EQUIPMENT_SET.OnAccept(renamePopup,1)
assert(#calls.modify==1 and calls.modify[1][1]==1 and calls.modify[1][2]=="Raid updated" and calls.modify[1][3]==111, "Rename must preserve the icon")
Character:RenameEquipmentSet(1,"Mythic+"); assert(#calls.modify==1, "duplicate names must not overwrite")

Character.setActions.delete.scripts.OnClick(Character.setActions.delete)
assert(popups[#popups].kind=="PROJECT_RUTHLESS_DELETE_EQUIPMENT_SET" and #calls.delete==0, "Delete must require confirmation")
StaticPopupDialogs.PROJECT_RUTHLESS_DELETE_EQUIPMENT_SET.OnAccept(nil,1)
assert(#calls.delete==1 and Character.selectedSetID==nil, "confirmed delete must clear the selection")

Character.newSetButton.scripts.OnClick(Character.newSetButton)
assert(popups[#popups].kind=="PROJECT_RUTHLESS_NEW_EQUIPMENT_SET" and #calls.create==0, "New set must open the visible Create dialog")
assert(popups[#popups].EditBox.text=="", "New set dialog must clear the live StaticPopup edit box")
local enterClicked=false
local enterPopup=CreateFrame("Frame")
enterPopup.Button1=CreateFrame("Button",nil,enterPopup)
enterPopup.Button1:SetScript("OnClick", function() enterClicked=true end)
local enterEditBox=CreateFrame("EditBox",nil,enterPopup)
StaticPopupDialogs.PROJECT_RUTHLESS_NEW_EQUIPMENT_SET.EditBoxOnEnterPressed(enterEditBox)
assert(enterClicked, "Enter must click the live StaticPopup accept button")
local createPopup={EditBox=CreateFrame("EditBox")}; createPopup.EditBox:SetText("New loadout")
StaticPopupDialogs.PROJECT_RUTHLESS_NEW_EQUIPMENT_SET.OnAccept(createPopup)
assert(#calls.create==1 and calls.create[1][1]=="New loadout", "Create must call Blizzard exactly once")
assert(calls.ignore[#calls.ignore-1]==4 and calls.ignore[#calls.ignore]==19, "new sets must default to ignoring shirt and tabard")
local creates=#calls.create; combat=true; Character:CreateEquipmentSet("Blocked"); assert(#calls.create==creates, "combat blocks Create")
Character.selectedSetID=2; Character.setActions.save.scripts.OnClick(Character.setActions.save); assert(#calls.save==saved, "combat blocks Save before popup")
combat=false; casting=true; Character:EquipEquipmentSet(2); assert(#calls.use==1, "casting blocks Equip"); casting=false
MAX_EQUIPMENT_SETS_PER_PLAYER=1; Character:CreateEquipmentSet("At limit"); assert(#calls.create==creates, "set limits block Create"); MAX_EQUIPMENT_SETS_PER_PLAYER=20

for id=3,12 do records[id]={name="Set "..id,icon=id,equipped=false,items=16,equippedItems=0,ignored={}}; ids[#ids+1]=id end
Character:RefreshSets()
assert(#Character.setRows==11 and Character.setsContent.height==462, "all equipment sets must be available through the scroll list")
print("PASS: native PaperDoll slot callbacks, standalone icon popup, and control-driven equipment selection, confirmation, save, equip, rename, delete, ignored slots, blocked states, and full-list scrolling")
