local _, AUI = ...

local Character = { slots = {}, setRows = {}, statRows = {}, titleRows = {}, filteredTitles = {} }
AUI:RegisterModule("Character", Character)

local LEFT_SLOTS = { 1, 2, 3, 15, 5, 4, 19, 9 }
local RIGHT_SLOTS = { 10, 6, 7, 8, 11, 12, 13, 14 }
local COLORS = {
    surface = { 0.035, 0.039, 0.052, 0.92 }, inset = { 0.025, 0.028, 0.038, 0.78 },
    border = { 0.16, 0.17, 0.21, 0.9 }, text = { 0.91, 0.92, 0.96, 1 }, muted = { 0.52, 0.55, 0.64, 1 },
}

local function Surface(frame, background, border)
    frame:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1 })
    frame:SetBackdropColor(unpack(background or COLORS.surface))
    frame:SetBackdropBorderColor(unpack(border or COLORS.border))
end

local function Label(parent, text, size)
    local font = size == "large" and "GameFontNormalLarge" or size == "small" and "GameFontNormalSmall" or "GameFontNormal"
    local label = parent:CreateFontString(nil, "OVERLAY", font)
    label:SetText(text or "")
    label:SetTextColor(unpack(COLORS.text))
    return label
end

local function Clamp(value, low, high) return math.max(low, math.min(high, value)) end
local function AccentColor()
    local _, class = UnitClass("player")
    local color = class and RAID_CLASS_COLORS[class]
    return color and color.r or 0.5, color and color.g or 0.35, color and color.b or 0.94
end
local function SafeValue(callback, fallback)
    local ok, value = pcall(callback)
    return ok and type(value) == "number" and value or (fallback or 0)
end
local function Number(value, decimals)
    local ok, text = pcall(function()
        if decimals then return ("%." .. decimals .. "f"):format(value or 0) end
        local rounded = math.floor((value or 0) + 0.5)
        return BreakUpLargeNumbers and BreakUpLargeNumbers(rounded) or tostring(rounded)
    end)
    return ok and text or "Restricted"
end
local function Percent(value)
    local ok, text = pcall(string.format, "%.1f%%", value or 0)
    return ok and text or "Restricted"
end
local function GetStaticPopupEditBox(popup)
    if not popup then return nil end
    return popup.editBox or popup.EditBox
end
local function ClickStaticPopupAccept(editBox)
    local popup = editBox and editBox.GetParent and editBox:GetParent()
    if not popup then return end
    local button = popup.button1 or popup.Button1
    if button and button.Click then button:Click() end
end
local function ApplyWeaponState(model)
    if model and model.SetSheathed then model:SetSheathed(model.weaponSheathed == true, false) end
    if model and model.weaponButton then
        model.weaponButton.label:SetText(model.weaponSheathed and "Draw" or "Sheathe")
    end
end

function Character:ConfigureGearFlyout(parent)
    parent.flyoutSettings = {
        onClickFunc = _G.PaperDollFrameItemFlyoutButton_OnClick,
        getItemsFunc = _G.PaperDollFrameItemFlyout_GetItems,
        postGetItemsFunc = _G.PaperDollFrameItemFlyout_PostGetItems,
        hasPopouts = true,
        parent = self.frame or parent,
        anchorX = 0,
        anchorY = -3,
        verticalAnchorX = 0,
        verticalAnchorY = 0,
    }
end

function Character:CreateItemSlot(parent, slotID, point, x, y, tooltipAnchor)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetID(slotID)
    button:SetSize(38, 38)
    button:SetPoint(point, parent, point, x, y)
    Surface(button, COLORS.surface)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPLEFT", 2, -2); button.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.badge = CreateFrame("Frame", nil, button, "BackdropTemplate")
    button.badge:SetSize(30, 14); button.badge:SetPoint("BOTTOMRIGHT", -2, 2)
    button.badge:SetFrameLevel(button:GetFrameLevel() + 3)
    Surface(button.badge, { 0.018, 0.020, 0.027, 0.96 })
    button.level = button.badge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.level:SetPoint("CENTER"); button.level:SetTextColor(0.94, 0.95, 0.98, 1)
    button.id = slotID; button.slotID = slotID; button.tooltipAnchor = tooltipAnchor
    button.checkRelic = false
    button.SetTooltipAnchor = PaperDollItemSlotButtonBaseMixin.SetTooltipAnchor
    button:RegisterForDrag("LeftButton")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", function(self, mouseButton)
        if IsModifiedClick() then PaperDollItemSlotButton_OnModifiedClick(self, mouseButton)
        else PaperDollItemSlotButton_OnClick(self, mouseButton) end
    end)
    button:SetScript("OnDragStart", function(self) PaperDollItemSlotButton_OnClick(self, "LeftButton") end)
    button:SetScript("OnReceiveDrag", function(self) PaperDollItemSlotButton_OnClick(self, "LeftButton") end)
    button:SetScript("OnEnter", PaperDollItemSlotButton_OnEnter)
    button:SetScript("OnLeave", PaperDollItemSlotButton_OnLeave)
    button:SetScript("OnEvent", function(self, event)
        if event == "MODIFIER_STATE_CHANGED" and IsModifiedClick("SHOWITEMFLYOUT") and self:IsMouseOver() then
            PaperDollItemSlotButton_OnEnter(self)
        end
    end)
    button.UpdateTooltip = PaperDollItemSlotButton_OnEnter
    self.slots[#self.slots + 1] = button
end

function Character:ResetModelView()
    local model = self.panel and self.panel.model
    if not model then return end
    model.facing, model.camScale, model.panX, model.panZ = 0, 1, 0, 0
    model:SetFacing(0); model:SetCamDistanceScale(1); model:SetPosition(0, 0, 0)
    ApplyWeaponState(model)
end

function Character:ConfigureModel(model)
    model.weaponSheathed = false
    model:SetUnit("player"); model:SetPortraitZoom(0)
    ApplyWeaponState(model)
    model:SetScript("OnModelLoaded", function(self)
        ApplyWeaponState(self)
        C_Timer.After(0, function() ApplyWeaponState(self) end)
    end)
    model:EnableMouse(true); model:EnableMouseWheel(true)
    model.facing, model.camScale, model.panX, model.panZ = 0, 1, 0, 0
    model:SetScript("OnMouseWheel", function(self, delta)
        self.camScale = Clamp((self.camScale or 1) - delta * 0.08, 0.55, 1.8)
        self:SetCamDistanceScale(self.camScale)
    end)
    model:SetScript("OnMouseDown", function(self, button)
        self.rotating = button == "LeftButton"
        self.panning = button == "RightButton"
        self.lastCursorX, self.lastCursorY = GetCursorPosition()
    end)
    model:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then self.rotating = false end
        if button == "RightButton" then self.panning = false end
    end)
    model:SetScript("OnHide", function(self) self.rotating, self.panning = false, false end)
    model:SetScript("OnUpdate", function(self)
        if not self.rotating and not self.panning then return end
        local x, y = GetCursorPosition()
        local dx, dy = x - (self.lastCursorX or x), y - (self.lastCursorY or y)
        if self.rotating then
            self.facing = (self.facing or 0) + dx * 0.012
            self:SetFacing(self.facing)
        else
            self.panX = Clamp((self.panX or 0) + dx * 0.0025, -1.2, 1.2)
            self.panZ = Clamp((self.panZ or 0) + dy * 0.0025, -1.2, 1.2)
            self:SetPosition(0, self.panX, self.panZ)
        end
        self.lastCursorX, self.lastCursorY = x, y
    end)
end

function Character:CreateStatRow(parent, index)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetPoint("TOPLEFT", 0, -(index - 1) * 22); row:SetPoint("TOPRIGHT", 0, -(index - 1) * 22); row:SetHeight(22)
    row.name = Label(row, "", "small"); row.name:SetPoint("LEFT", 8, 0)
    row.value = Label(row, "", "small"); row.value:SetPoint("RIGHT", -8, 0); row.value:SetJustifyH("RIGHT")
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        if not self.tooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.tooltip.title or self.name:GetText(), 1, 0.82, 0, 1)
        if self.tooltip.body then GameTooltip:AddLine(self.tooltip.body, 1, 1, 1, true) end
        if self.tooltip.detail then GameTooltip:AddLine(self.tooltip.detail, 0.65, 0.68, 0.75, true) end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    self.statRows[index] = row
    return row
end

function Character:SetStats(entries)
    for index, entry in ipairs(entries) do
        local row = self.statRows[index] or self:CreateStatRow(self.statsContent, index)
        if entry.section then
            row:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8X8" }); row:SetBackdropColor(0.07, 0.075, 0.095, 0.96)
            local r, g, b = AccentColor()
            row.name:SetText(entry.section:upper()); row.name:SetTextColor(r, g, b, 1); row.value:SetText("")
            row.tooltip = nil
        else
            row:SetBackdrop(nil); row.name:SetText(entry.name); row.name:SetTextColor(0.74, 0.76, 0.82, 1)
            row.value:SetText(entry.value); row.value:SetTextColor(unpack(COLORS.text))
            row.tooltip = entry.tooltip
        end
        row:Show()
    end
    for index = #entries + 1, #self.statRows do self.statRows[index]:Hide() end
    self.statsContent:SetHeight(math.max(1, #entries * 22))
end

function Character:CreateSetRow(parent, index)
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetHeight(38); row:SetPoint("TOPLEFT", 0, -(index - 1) * 42); row:SetPoint("TOPRIGHT", 0, -(index - 1) * 42)
    Surface(row, COLORS.inset)
    row.icon = row:CreateTexture(nil, "ARTWORK"); row.icon:SetSize(28, 28); row.icon:SetPoint("LEFT", 5, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.name = Label(row, ""); row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 6)
    row.count = Label(row, "", "small"); row.count:SetPoint("LEFT", row.icon, "RIGHT", 8, -8); row.count:SetTextColor(unpack(COLORS.muted))
    row:RegisterForClicks("LeftButtonUp")
    row:SetScript("OnClick", function(self)
        if self.setID then Character:SelectEquipmentSet(self.setID) end
    end)
    row:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.09, 0.095, 0.12, 0.96)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:AddLine(self.setName or "Equipment set", 1, 1, 1)
        GameTooltip:AddLine("Select this set, then use the actions below.", 0.55, 0.72, 1); GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(self.setID == Character.selectedSetID and {0.10,0.075,0.10,0.96} or COLORS.inset))
        GameTooltip_Hide()
    end)
    self.setRows[index] = row
end

function Character:IsEquipmentSetActionAllowed(action, setID)
    if InCombatLockdown() then AUI:Print("Equipment sets cannot be changed during combat."); return false end
    if UnitCastingInfo("player") or UnitChannelInfo("player") then AUI:Print("Finish casting before changing equipment sets."); return false end
    if C_EquipmentSet.CanUseEquipmentSets and not C_EquipmentSet.CanUseEquipmentSets() then AUI:Print("Equipment sets are unavailable right now."); return false end
    if not setID then AUI:Print("Select an equipment set first."); return false end
    if action == "equip" and C_EquipmentSet.EquipmentSetContainsLockedItems and C_EquipmentSet.EquipmentSetContainsLockedItems(setID) then
        AUI:Print("That equipment set contains locked items."); return false
    end
    return true
end

function Character:SelectEquipmentSet(setID)
    if not setID or not C_EquipmentSet.GetEquipmentSetInfo(setID) then return end
    self.selectedSetID = setID
    self:RefreshSets()
end

function Character:WithIgnoredSlots(setID, action)
    if not C_EquipmentSet.ClearIgnoredSlotsForSave then return action() end
    C_EquipmentSet.ClearIgnoredSlotsForSave()
    local ignored = setID and C_EquipmentSet.GetIgnoredSlots and C_EquipmentSet.GetIgnoredSlots(setID)
    if ignored then
        for slotID, isIgnored in pairs(ignored) do
            if isIgnored then C_EquipmentSet.IgnoreSlotForSave(slotID) end
        end
    end
    local ok, result = pcall(action)
    C_EquipmentSet.ClearIgnoredSlotsForSave()
    if not ok then error(result) end
    return result
end

function Character:CreateEquipmentSet(name, icon)
    if InCombatLockdown() then AUI:Print("Equipment sets cannot be created during combat."); return end
    if C_EquipmentSet.CanUseEquipmentSets and not C_EquipmentSet.CanUseEquipmentSets() then AUI:Print("Equipment sets are unavailable right now."); return end
    local maximum = _G.MAX_EQUIPMENT_SETS_PER_PLAYER or 10
    if C_EquipmentSet.GetNumEquipmentSets() >= maximum then AUI:Print("You have reached the equipment set limit."); return end
    name = strtrim(name or "")
    if name == "" then AUI:Print("Enter a name for the new equipment set."); return end
    if C_EquipmentSet.GetEquipmentSetID(name) then AUI:Print("An equipment set with that name already exists."); return end
    self:WithIgnoredSlots(nil, function()
        -- Match Blizzard's default new-set behavior: do not save shirt or tabard.
        C_EquipmentSet.IgnoreSlotForSave(4); C_EquipmentSet.IgnoreSlotForSave(19)
        C_EquipmentSet.CreateEquipmentSet(name, icon)
    end)
end

function Character:SaveEquipmentSet(setID)
    if not self:IsEquipmentSetActionAllowed("save", setID) then return end
    local _, icon = C_EquipmentSet.GetEquipmentSetInfo(setID)
    self:WithIgnoredSlots(setID, function() C_EquipmentSet.SaveEquipmentSet(setID, icon) end)
end

function Character:EquipEquipmentSet(setID)
    if not self:IsEquipmentSetActionAllowed("equip", setID) then return end
    C_EquipmentSet.UseEquipmentSet(setID)
end

function Character:RenameEquipmentSet(setID, name, icon)
    if not self:IsEquipmentSetActionAllowed("rename", setID) then return end
    name = strtrim(name or "")
    if name == "" then AUI:Print("Enter a name for the equipment set."); return end
    local existing = C_EquipmentSet.GetEquipmentSetID(name)
    if existing and existing ~= setID then AUI:Print("An equipment set with that name already exists."); return end
    local _, currentIcon = C_EquipmentSet.GetEquipmentSetInfo(setID)
    C_EquipmentSet.ModifyEquipmentSet(setID, name, icon or currentIcon)
end

function Character:DeleteEquipmentSet(setID)
    if not self:IsEquipmentSetActionAllowed("delete", setID) then return end
    C_EquipmentSet.DeleteEquipmentSet(setID)
    if self.selectedSetID == setID then self.selectedSetID = nil end
end

function Character:ShowNewEquipmentSetDialog()
    if InCombatLockdown() then AUI:Print("Equipment sets cannot be created during combat."); return end
    if C_EquipmentSet.CanUseEquipmentSets and not C_EquipmentSet.CanUseEquipmentSets() then AUI:Print("Equipment sets are unavailable right now."); return end
    local maximum = _G.MAX_EQUIPMENT_SETS_PER_PLAYER or 10
    if C_EquipmentSet.GetNumEquipmentSets() >= maximum then AUI:Print("You have reached the equipment set limit."); return end
    if self:ShowNativeEquipmentSetPopup("new") then return end
    StaticPopup_Show("PROJECT_RUTHLESS_NEW_EQUIPMENT_SET")
end

function Character:ShowNativeEquipmentSetPopup(mode, setID)
    if not (_G.GearManagerPopupFrame and _G.IconSelectorPopupFrameModes) then return false end
    if mode == "edit" and not setID then return false end
    if GearManagerPopupFrame.SetParent then
        GearManagerPopupFrame:SetParent(UIParent)
        GearManagerPopupFrame:ClearAllPoints()
        GearManagerPopupFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        GearManagerPopupFrame:SetFrameStrata("DIALOG")
        GearManagerPopupFrame:SetFrameLevel(100)
    end
    if mode == "new" then
        GearManagerPopupFrame.mode = IconSelectorPopupFrameModes.New
        if PaperDollFrame and PaperDollFrame.EquipmentManagerPane then PaperDollFrame.EquipmentManagerPane.selectedSetID = nil end
        if PaperDollFrame_ClearIgnoredSlots then PaperDollFrame_ClearIgnoredSlots() end
        if PaperDollFrame_IgnoreSlot then PaperDollFrame_IgnoreSlot(4); PaperDollFrame_IgnoreSlot(19) end
    else
        local name = C_EquipmentSet.GetEquipmentSetInfo(setID)
        GearManagerPopupFrame.mode = IconSelectorPopupFrameModes.Edit
        GearManagerPopupFrame.setID = setID
        GearManagerPopupFrame.origName = name or ""
        if PaperDollFrame and PaperDollFrame.EquipmentManagerPane then PaperDollFrame.EquipmentManagerPane.selectedSetID = setID end
    end
    GearManagerPopupFrame:Show()
    return true
end

function Character:CreateModeButton(parent, text, x, mode, width)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 106, 26); button:SetPoint("TOPLEFT", x, -62); Surface(button, COLORS.inset)
    button.label = Label(button, text, "small"); button.label:SetPoint("CENTER")
    button:SetScript("OnClick", function() Character:SelectMode(mode) end)
    return button
end

function Character:CreateTitleRow(parent, index)
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetHeight(28); row:SetPoint("TOPLEFT", 0, -(index - 1) * 30); row:SetPoint("TOPRIGHT", 0, -(index - 1) * 30)
    Surface(row, COLORS.inset)
    row.favorite = CreateFrame("Button", nil, row)
    row.favorite:SetSize(18, 18); row.favorite:SetPoint("LEFT", 5, 0)
    row.favorite.icon = row.favorite:CreateTexture(nil, "ARTWORK"); row.favorite.icon:SetAllPoints(); row.favorite.icon:SetAtlas("PetJournal-FavoritesIcon")
    row.favorite:SetScript("OnClick", function()
        local titles = AUI.modules.Titles
        if titles and row.titleID and row.titleID > 0 then titles:ToggleFavorite(row.titleID); Character:RefreshTitles(true) end
    end)
    row.name = Label(row, "", "small"); row.name:SetPoint("LEFT", 28, 0); row.name:SetPoint("RIGHT", -8, 0); row.name:SetJustifyH("LEFT")
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnClick", function(self, mouseButton)
        local titles = AUI.modules.Titles
        if not titles then return end
        if mouseButton == "RightButton" and self.titleID and self.titleID > 0 then
            titles:BuildAchievementMatches()
            local match = titles.achievementMatches[self.titleID]
            if match and match.id then titles:OpenAchievement(match.id) end
        else
            titles:Equip(self.titleID); Character:Refresh()
        end
    end)
    row:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.09, 0.095, 0.12, 0.96)
        local titles = AUI.modules.Titles
        if titles then titles:ShowTitleTooltip(self, self.titleID) end
    end)
    row:SetScript("OnLeave", function(self) self:SetBackdropColor(unpack(COLORS.inset)); GameTooltip_Hide() end)
    self.titleRows[index] = row
end

function Character:RefreshTitles(resetScroll)
    local titles = AUI.modules.Titles
    if not titles or not self.titlesView then return end
    self.filteredTitles = titles:GetEarnedTitles(self.titleSearchText)
    local activeID = titles.currentTitleID
    if activeID == nil then activeID = GetCurrentTitle and GetCurrentTitle() or 0 end
    for index = #self.titleRows + 1, #self.filteredTitles do self:CreateTitleRow(self.titlesContent, index) end
    for index, row in ipairs(self.titleRows) do
        local entry = self.filteredTitles[index]
        if entry then
            row.titleID = entry.id; row.name:SetText(entry.name)
            local favorite = titles:IsFavorite(entry.id)
            row.favorite:SetShown(entry.id > 0)
            row.favorite.icon:SetDesaturated(not favorite); row.favorite.icon:SetAlpha(favorite and 1 or 0.24)
            local active = entry.id == activeID
            row.name:SetTextColor(active and 1 or 0.9, active and 0.82 or 0.9, active and 0.2 or 0.9)
            row:SetBackdropBorderColor(active and 1 or COLORS.border[1], active and 0.72 or COLORS.border[2], active and 0.15 or COLORS.border[3], active and 0.9 or COLORS.border[4])
            row:Show()
        else row.titleID=nil; row:Hide() end
    end
    self.titlesContent:SetHeight(math.max(1, #self.filteredTitles * 30))
    self.titlesView.empty:SetShown(#self.filteredTitles == 0)
    self.titlesView.sortButton.label:SetText(titles:GetSortMode() == "recent" and "Chrono" or "A–Z")
    if resetScroll and self.titlesScroll then self.titlesScroll.targetScroll = 0; self.titlesScroll:SetVerticalScroll(0) end
end

function Character:SelectMode(mode)
    self.mode = mode
    self.statsView:SetShown(mode == "stats"); self.titlesView:SetShown(mode == "titles"); self.setsView:SetShown(mode == "sets")
    for id, button in pairs(self.modeButtons) do
        if id == mode then button:SetBackdropColor(0.10, 0.075, 0.10, 0.96) else button:SetBackdropColor(unpack(COLORS.inset)) end
    end
    self:Refresh()
end

function Character:CreateSetsView(details)
    local setsView = CreateFrame("Frame", nil, details)
    setsView:SetPoint("TOPLEFT", 12, -102); setsView:SetPoint("BOTTOMRIGHT", -12, 12)
    local newSet = AUI:CreateButton(setsView); newSet:SetSize(104, 26); newSet:SetPoint("TOPLEFT"); newSet:SetText("+  New set")
    newSet:SetScript("OnClick", function() Character:ShowNewEquipmentSetDialog() end)
    self.newSetButton = newSet
    local selected = Label(setsView, "Select a set to manage it.", "small")
    selected:SetPoint("LEFT", newSet, "RIGHT", 9, 0); selected:SetPoint("RIGHT", -2, 0); selected:SetJustifyH("RIGHT"); selected:SetTextColor(unpack(COLORS.muted))
    setsView.selected = selected

    local actionBar = CreateFrame("Frame", nil, setsView)
    actionBar:SetPoint("BOTTOMLEFT"); actionBar:SetPoint("BOTTOMRIGHT"); actionBar:SetHeight(58)
    local save = AUI:CreateButton(actionBar); save:SetSize(108, 26); save:SetPoint("TOPLEFT"); save:SetText("Save current")
    local equip = AUI:CreateButton(actionBar); equip:SetSize(108, 26); equip:SetPoint("TOPRIGHT"); equip:SetText("Equip")
    local rename = AUI:CreateButton(actionBar); rename:SetSize(108, 26); rename:SetPoint("BOTTOMLEFT"); rename:SetText("Rename")
    local delete = AUI:CreateButton(actionBar); delete:SetSize(108, 26); delete:SetPoint("BOTTOMRIGHT"); delete:SetText("Delete")
    save:SetScript("OnClick", function()
        local setID = Character.selectedSetID
        if not Character:IsEquipmentSetActionAllowed("save", setID) then return end
        local name = C_EquipmentSet.GetEquipmentSetInfo(setID)
        StaticPopup_Show("PROJECT_RUTHLESS_SAVE_EQUIPMENT_SET", name or "this set", nil, setID)
    end)
    equip:SetScript("OnClick", function() Character:EquipEquipmentSet(Character.selectedSetID) end)
    rename:SetScript("OnClick", function()
        local setID = Character.selectedSetID
        if not Character:IsEquipmentSetActionAllowed("rename", setID) then return end
        if Character:ShowNativeEquipmentSetPopup("edit", setID) then return end
        local name = C_EquipmentSet.GetEquipmentSetInfo(setID)
        StaticPopup_Show("PROJECT_RUTHLESS_RENAME_EQUIPMENT_SET", name or "", nil, setID)
    end)
    delete:SetScript("OnClick", function()
        local setID = Character.selectedSetID
        if not Character:IsEquipmentSetActionAllowed("delete", setID) then return end
        local name = C_EquipmentSet.GetEquipmentSetInfo(setID)
        StaticPopup_Show("PROJECT_RUTHLESS_DELETE_EQUIPMENT_SET", name or "this set", nil, setID)
    end)
    self.setActions = {save=save, equip=equip, rename=rename, delete=delete}

    local scroll = AUI:CreateSmoothScrollFrame(setsView)
    scroll:SetPoint("TOPLEFT", 0, -34); scroll:SetPoint("BOTTOMRIGHT", 0, 64)
    local content = CreateFrame("Frame", nil, scroll); content:SetWidth(220); content:SetHeight(1); scroll:SetScrollChild(content)
    self.setsScroll, self.setsContent = scroll, content
    setsView.empty = Label(setsView, "No equipment sets yet.", "small")
    setsView.empty:SetPoint("TOPLEFT", 8, -44); setsView.empty:SetWidth(210); setsView.empty:SetJustifyH("LEFT"); setsView.empty:SetTextColor(unpack(COLORS.muted))

    if not StaticPopupDialogs.PROJECT_RUTHLESS_NEW_EQUIPMENT_SET then
        StaticPopupDialogs.PROJECT_RUTHLESS_NEW_EQUIPMENT_SET = {
            text="Name the new equipment set", button1="Create", button2=CANCEL or "Cancel", hasEditBox=true, maxLetters=16,
            OnShow=function(popup)
                local editBox = GetStaticPopupEditBox(popup)
                if editBox then editBox:SetText(""); editBox:SetFocus() end
            end,
            OnAccept=function(popup)
                local editBox = GetStaticPopupEditBox(popup)
                Character:CreateEquipmentSet(editBox and editBox:GetText() or "")
            end,
            EditBoxOnEnterPressed=ClickStaticPopupAccept,
            EditBoxOnEscapePressed=function(editBox) editBox:GetParent():Hide() end,
            timeout=0, whileDead=true, hideOnEscape=true, preferredIndex=3,
        }
    end
    if not StaticPopupDialogs.PROJECT_RUTHLESS_SAVE_EQUIPMENT_SET then
        StaticPopupDialogs.PROJECT_RUTHLESS_SAVE_EQUIPMENT_SET = {
            text="Save your currently equipped gear to |cffffffff%s|r?", button1="Save", button2=CANCEL or "Cancel",
            OnAccept=function(_, setID) Character:SaveEquipmentSet(setID) end,
            timeout=0, whileDead=true, hideOnEscape=true, preferredIndex=3,
        }
    end
    if not StaticPopupDialogs.PROJECT_RUTHLESS_RENAME_EQUIPMENT_SET then
        StaticPopupDialogs.PROJECT_RUTHLESS_RENAME_EQUIPMENT_SET = {
            text="Rename equipment set", button1="Rename", button2=CANCEL or "Cancel", hasEditBox=true, maxLetters=16,
            OnShow=function(popup, data)
                local editBox = GetStaticPopupEditBox(popup)
                if not editBox then return end
                local setID = data or popup.data
                local name = setID and C_EquipmentSet.GetEquipmentSetInfo(setID)
                editBox:SetText(name or "")
                editBox:HighlightText()
                editBox:SetFocus()
            end,
            OnAccept=function(popup, setID)
                local editBox = GetStaticPopupEditBox(popup)
                Character:RenameEquipmentSet(setID, editBox and editBox:GetText() or "")
            end,
            EditBoxOnEnterPressed=ClickStaticPopupAccept,
            EditBoxOnEscapePressed=function(editBox) editBox:GetParent():Hide() end,
            timeout=0, whileDead=true, hideOnEscape=true, preferredIndex=3,
        }
    end
    if not StaticPopupDialogs.PROJECT_RUTHLESS_DELETE_EQUIPMENT_SET then
        StaticPopupDialogs.PROJECT_RUTHLESS_DELETE_EQUIPMENT_SET = {
            text="Delete equipment set |cffffffff%s|r?", button1=DELETE, button2=CANCEL,
            OnAccept=function(_, setID) Character:DeleteEquipmentSet(setID) end,
            timeout=0, whileDead=true, hideOnEscape=true, preferredIndex=3,
        }
    end
    self.setsView = setsView
    return setsView
end

function Character:CreatePanel(parent)
    local panel = CreateFrame("Frame", nil, parent); panel:SetAllPoints()
    local heading = Label(panel, "", "large"); heading:SetPoint("TOPLEFT", 8, -4); panel.heading = heading
    local hr, hg, hb = AccentColor(); heading:SetTextColor(hr, hg, hb, 1)
    panel.identity = Label(panel, "", "small"); panel.identity:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -5)
    panel.identity:SetTextColor(unpack(COLORS.muted))

    local summary = CreateFrame("Frame", nil, panel)
    summary:SetSize(358, 44); summary:SetPoint("TOPRIGHT", -2, -2)
    local summaryItems = { {"mplus","MYTHIC+"}, {"raid","RAID"}, {"pvp","PVP"} }
    for index, item in ipairs(summaryItems) do
        local cell = CreateFrame("Frame", nil, summary)
        cell:SetSize(116, 40); cell:SetPoint("TOPLEFT", 3 + (index - 1) * 118, -2)
        cell.label = Label(cell, item[2], "small"); cell.label:SetPoint("TOPLEFT", 6, -4); cell.label:SetTextColor(hr, hg, hb, 1)
        cell.value = Label(cell, "—", "small"); cell.value:SetPoint("BOTTOMLEFT", 6, 4)
        summary[item[1]] = cell
    end
    summary:EnableMouse(true)
    summary:SetScript("OnEnter", function(self) Character:ShowProgressTooltip(self) end)
    summary:SetScript("OnLeave", GameTooltip_Hide)
    panel.summary = summary
    local gear = CreateFrame("Frame", nil, panel, "BackdropTemplate"); gear:SetSize(390, 476); gear:SetPoint("TOPLEFT", 8, -52)
    Surface(gear, COLORS.inset)
    self:ConfigureGearFlyout(gear)
    local model = CreateFrame("DressUpModel", nil, gear); model:SetPoint("TOPLEFT", 48, -8); model:SetPoint("BOTTOMRIGHT", -48, 55)
    self:ConfigureModel(model); panel.model = model
    local reset = CreateFrame("Button", nil, gear, "BackdropTemplate"); reset:SetSize(24, 22); reset:SetPoint("BOTTOMRIGHT", -7, 6)
    Surface(reset, COLORS.surface); reset:SetBackdropBorderColor(hr, hg, hb, 0.7)
    reset.icon = reset:CreateTexture(nil, "ARTWORK"); reset.icon:SetSize(14, 14); reset.icon:SetPoint("CENTER")
    reset.icon:SetAtlas("common-icon-rotateleft"); reset.icon:SetVertexColor(hr, hg, hb); reset.icon:SetAlpha(0.7)
    reset:SetScript("OnEnter", function(self) self:SetBackdropColor(0.10, 0.075, 0.10, 0.96); self.icon:SetAlpha(1) end)
    reset:SetScript("OnLeave", function(self) self:SetBackdropColor(unpack(COLORS.surface)); self.icon:SetAlpha(0.7) end)
    reset:SetScript("OnClick", function() Character:ResetModelView() end)
    local weapon = AUI:CreateButton(gear); weapon:SetSize(60, 22); weapon:SetPoint("RIGHT", reset, "LEFT", -5, 0); weapon:SetText("Sheathe")
    weapon:SetScript("OnClick", function()
        model.weaponSheathed = not model.weaponSheathed
        ApplyWeaponState(model)
    end)
    model.weaponButton = weapon
    for index, slotID in ipairs(LEFT_SLOTS) do self:CreateItemSlot(gear, slotID, "TOPLEFT", 8, -8 - (index - 1) * 51, "ANCHOR_RIGHT") end
    for index, slotID in ipairs(RIGHT_SLOTS) do self:CreateItemSlot(gear, slotID, "TOPRIGHT", -8, -8 - (index - 1) * 51, "ANCHOR_LEFT") end
    self:CreateItemSlot(gear, 16, "BOTTOM", -23, 38, "ANCHOR_RIGHT")
    self:CreateItemSlot(gear, 17, "BOTTOM", 23, 38, "ANCHOR_LEFT")

    local details = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    details:SetPoint("TOPLEFT", gear, "TOPRIGHT", 12, 0); details:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -2, 0)
    Surface(details, COLORS.surface)
    local equipment = Label(details, "EQUIPMENT", "small"); equipment:SetPoint("TOPLEFT", 12, -12)
    local ar, ag, ab = AccentColor(); equipment:SetTextColor(ar, ag, ab, 1)
    details.itemLevel = Label(details, ""); details.itemLevel:SetPoint("TOPLEFT", 12, -32)
    self.modeButtons = {
        stats=self:CreateModeButton(details, "Stats", 12, "stats", 58),
        titles=self:CreateModeButton(details, "Titles", 74, "titles", 58),
        sets=self:CreateModeButton(details, "Equipment sets", 136, "sets", 98),
    }
    local statsView = CreateFrame("Frame", nil, details); statsView:SetPoint("TOPLEFT", 12, -96); statsView:SetPoint("BOTTOMRIGHT", -12, 12)
    local scroll = AUI:CreateSmoothScrollFrame(statsView)
    scroll:SetPoint("TOPLEFT"); scroll:SetPoint("BOTTOMRIGHT")
    local statsContent = CreateFrame("Frame", nil, scroll); statsContent:SetWidth(220); statsContent:SetHeight(1); scroll:SetScrollChild(statsContent)
    self.statsView, self.statsContent = statsView, statsContent
    local titlesView = CreateFrame("Frame", nil, details); titlesView:SetPoint("TOPLEFT", 12, -102); titlesView:SetPoint("BOTTOMRIGHT", -12, 12)
    local titleSearch = CreateFrame("EditBox", nil, titlesView, "SearchBoxTemplate")
    titleSearch:SetSize(142, 24); titleSearch:SetPoint("TOPLEFT", 0, 0)
    titleSearch:SetScript("OnTextChanged", function(box)
        SearchBoxTemplate_OnTextChanged(box); Character.titleSearchText = box:GetText(); Character:RefreshTitles(true)
    end)
    local titleSort = AUI:CreateButton(titlesView)
    titleSort:SetSize(72, 24); titleSort:SetPoint("TOPRIGHT", 0, 0); titleSort:SetText("A–Z")
    titleSort:SetScript("OnClick", function()
        if AUI.modules.Titles then AUI.modules.Titles:ToggleSortMode(); Character:RefreshTitles(true) end
    end)
    titlesView.sortButton = titleSort
    local titleScroll = AUI:CreateSmoothScrollFrame(titlesView)
    titleScroll:SetPoint("TOPLEFT", 0, -32); titleScroll:SetPoint("BOTTOMRIGHT")
    self.titlesScroll = titleScroll
    local titleList = CreateFrame("Frame", nil, titleScroll); titleList:SetWidth(220); titleList:SetHeight(1); titleScroll:SetScrollChild(titleList)
    self.titlesContent = titleList
    titlesView.empty = Label(titlesView, "No earned titles match this search.", "small")
    titlesView.empty:SetPoint("TOPLEFT", 8, -40); titlesView.empty:SetTextColor(unpack(COLORS.muted)); titlesView.empty:Hide()
    self.titlesView = titlesView
    self:CreateSetsView(details)

    panel.details = details
    panel:SetScript("OnShow", function() Character:Refresh() end)
    panel:SetScript("OnUpdate", function(_, elapsed)
        Character.liveElapsed = (Character.liveElapsed or 0) + elapsed
        if Character.liveElapsed >= 0.25 then Character.liveElapsed = 0; Character:RefreshLiveStats() end
    end)
    self.panel = panel; self:SelectMode("stats")
    return panel
end

function Character:GetStatEntries()
    local _, strength = UnitStat("player", 1); local _, agility = UnitStat("player", 2)
    local _, stamina = UnitStat("player", 3); local _, intellect = UnitStat("player", 4)
    local _, armor = UnitArmor("player")
    local minDamage, maxDamage = UnitDamage("player")
    local function Tip(title, body, detail) return {title=title, body=body, detail=detail} end
    local masteryName, masteryDescription
    local masterySpellID = GetMasterySpell and GetMasterySpell()
    if masterySpellID then
        if C_Spell and C_Spell.GetSpellInfo then
            local info = C_Spell.GetSpellInfo(masterySpellID); masteryName = info and info.name
            masteryDescription = C_Spell.GetSpellDescription and C_Spell.GetSpellDescription(masterySpellID)
        elseif GetSpellInfo then masteryName = GetSpellInfo(masterySpellID) end
    end
    local masteryRating = GetCombatRating and CR_MASTERY and GetCombatRating(CR_MASTERY)
    return {
        {section="Core stats"}, {name="Strength",value=Number(strength),tooltip=Tip("Strength", "Your primary attribute when your specialization uses Strength. It increases the power of relevant attacks.")}, {name="Agility",value=Number(agility),tooltip=Tip("Agility", "Your primary attribute when your specialization uses Agility. It increases the power of relevant attacks.")},
        {name="Intellect",value=Number(intellect)}, {name="Stamina",value=Number(stamina)},
        {section="Offence"}, {name="Weapon damage",value=Number(minDamage).." – "..Number(maxDamage),tooltip=Tip("Weapon damage", "The damage range of your currently equipped weapon after active modifiers.")},
        {name="Critical strike",value=Percent(GetCritChance and GetCritChance() or 0),tooltip=Tip("Critical strike", "Your chance for attacks and healing effects to critically strike for increased effect.")},
        {name="Haste",value=Percent(GetHaste and GetHaste() or 0),tooltip=Tip("Haste", "Speeds up attacks and spell casting, and reduces the cooldown or tick interval of abilities that scale with haste.")},
        {name="Mastery",value=Percent(GetMasteryEffect and GetMasteryEffect() or 0),tooltip=Tip(masteryName and ("Mastery: "..masteryName) or "Mastery", masteryDescription or "Improves the specialization-specific effect granted by your Mastery.", masteryRating and ("Mastery rating: "..Number(masteryRating)) or nil)},
        {name="Versatility",value=Percent(GetCombatRatingBonus and GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) or 0),tooltip=Tip("Versatility", "Increases damage and healing done and also reduces damage taken.")},
        {name="Damage reduction",value=Percent(GetCombatRatingBonus and GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_TAKEN) or 0),tooltip=Tip("Damage reduction", "The damage reduction currently granted by Versatility.")},
        {section="Defence"}, {name="Armour",value=Number(armor),tooltip=Tip("Armour", "Reduces physical damage taken. Its exact effect depends on the level of your attacker.")}, {name="Dodge",value=Percent(GetDodgeChance and GetDodgeChance() or 0),tooltip=Tip("Dodge", "Your chance to completely avoid an incoming melee attack.")},
        {name="Parry",value=Percent(GetParryChance and GetParryChance() or 0),tooltip=Tip("Parry", "Your chance to parry an incoming melee attack.")}, {name="Block",value=Percent(GetBlockChance and GetBlockChance() or 0),tooltip=Tip("Block", "Your chance to block part of an incoming melee attack while using a shield.")},
        {section="Tertiary & movement"}, {name="Leech",value=Percent(GetLifesteal and GetLifesteal() or 0),tooltip=Tip("Leech", "Returns a portion of your damage and healing as healing to you.")},
        {name="Avoidance",value=Percent(GetAvoidance and GetAvoidance() or 0),tooltip=Tip("Avoidance", "Reduces damage taken from area-of-effect attacks.")}, {name="Speed bonus",value=Percent(GetSpeed and GetSpeed() or 0),tooltip=Tip("Speed bonus", "Movement-speed bonus supplied by gear and effects.")},
        {name="Current movement",value="--",tooltip=Tip("Current movement", "Your live movement speed, including the movement state and temporary effects active right now.")}, {name="Run speed",value="--",tooltip=Tip("Run speed", "Your current maximum ground movement speed.")}, {name="Flight speed",value="--",tooltip=Tip("Flight speed", "Your current maximum flying speed.")}, {name="Swim speed",value="--",tooltip=Tip("Swim speed", "Your current maximum swimming speed.")},
    }
end

function Character:RefreshLiveStats()
    if not self.panel or not self.panel:IsShown() or self.mode ~= "stats" then return end
    local current, run, flight, swim = GetUnitSpeed("player")
    local function Movement(value) return Percent(SafeValue(function() return value / 7 * 100 end)) end
    local values = { ["Current movement"]=Movement(current), ["Run speed"]=Movement(run), ["Flight speed"]=Movement(flight), ["Swim speed"]=Movement(swim) }
    for _, row in ipairs(self.statRows) do local name=row.name:GetText(); if values[name] then row.value:SetText(values[name]) end end
end

function Character:RefreshGear()
    local qualities = {}
    for _, button in ipairs(self.slots) do
        local texture = GetInventoryItemTexture("player", button.slotID); local link = GetInventoryItemLink("player", button.slotID)
        button.icon:SetTexture(texture or 134400); button.icon:SetDesaturated(not texture)
        local quality = GetInventoryItemQuality("player", button.slotID); local color = quality and ITEM_QUALITY_COLORS[quality]
        if quality and button.slotID ~= 4 and button.slotID ~= 19 then qualities[quality] = (qualities[quality] or 0) + 1 end
        button:SetBackdropBorderColor(color and color.r or COLORS.border[1], color and color.g or COLORS.border[2], color and color.b or COLORS.border[3], 1)
        local itemLevel
        if link and C_Item and C_Item.GetDetailedItemLevelInfo then itemLevel=C_Item.GetDetailedItemLevelInfo(link)
        elseif link and GetDetailedItemLevelInfo then itemLevel=GetDetailedItemLevelInfo(link) end
        button.level:SetText(itemLevel and tostring(itemLevel) or ""); button.badge:SetShown(itemLevel ~= nil and ProjectRuthlessDB.character.showItemLevels)
    end
    local dominant, count = 1, 0
    for quality, qualityCount in pairs(qualities) do
        if qualityCount > count or (qualityCount == count and quality > dominant) then dominant, count = quality, qualityCount end
    end
    self.dominantQuality = dominant
end

function Character:RefreshSets()
    local setIDs = C_EquipmentSet.GetEquipmentSetIDs() or {}
    local selectedExists = false
    for _, setID in ipairs(setIDs) do if setID == self.selectedSetID then selectedExists = true; break end end
    if self.selectedSetID and not selectedExists then self.selectedSetID = nil end
    self.setsView.empty:SetShown(#setIDs == 0)
    for index = #self.setRows + 1, #setIDs do self:CreateSetRow(self.setsContent, index) end
    for index, row in ipairs(self.setRows) do
        local setID = setIDs[index]
        if setID then
            local name, icon, _, equipped, numItems, numEquipped = C_EquipmentSet.GetEquipmentSetInfo(setID)
            row.setID=setID; row.setName=name; row.icon:SetTexture(icon or 134400)
            row.name:SetText((equipped and "|cff65d68a" or "|cffe8eaf5")..(name or "Unnamed set").."|r")
            row.count:SetText(("%d/%d equipped"):format(numEquipped or 0, numItems or 0))
            local selected = setID == self.selectedSetID
            local r, g, b = AccentColor()
            row:SetBackdropColor(unpack(selected and {0.10,0.075,0.10,0.96} or COLORS.inset))
            row:SetBackdropBorderColor(selected and r or COLORS.border[1], selected and g or COLORS.border[2], selected and b or COLORS.border[3], selected and 0.95 or COLORS.border[4])
            row:Show()
        else row.setID=nil; row.setName=nil; row:Hide() end
    end
    self.setsContent:SetHeight(math.max(1, #setIDs * 42))
    local name, _, _, equipped = self.selectedSetID and C_EquipmentSet.GetEquipmentSetInfo(self.selectedSetID)
    if self.selectedSetID and name then
        self.setsView.selected:SetText((equipped and "Equipped: " or "Selected: ") .. name)
    else
        self.setsView.selected:SetText("Select a set to manage it.")
    end
    local canAct = self.selectedSetID ~= nil and not InCombatLockdown() and not UnitCastingInfo("player") and not UnitChannelInfo("player")
    for _, button in pairs(self.setActions or {}) do button:SetEnabled(canAct) end
end

function Character:GetRaiderProfile()
    if not (_G.RaiderIO and _G.RaiderIO.GetProfile) then return nil end
    local ok, profile = pcall(_G.RaiderIO.GetProfile, "player")
    return ok and profile or nil
end

function Character:GetPvPRatings()
    local ratings = {}
    local ratingNames = {}
    local function AddRating(name, value)
        if type(value) == "table" then value = value.rating or value.personalRating or value.currentRating end
        if type(value) == "number" and value > 0 then
            local existing = ratingNames[name]
            if existing then existing.rating = math.max(existing.rating, value)
            else
                local entry = { name=name, rating=value }; ratings[#ratings + 1] = entry; ratingNames[name] = entry
            end
        end
    end

    local getter = (C_PvP and C_PvP.GetPersonalRatedInfo) or _G.GetPersonalRatedInfo
    if not getter then table.sort(ratings, function(a, b) return a.rating > b.rating end); return ratings end
    local brackets, seen = {}, {}
    -- Blizzard's own Conquest panel uses this button order and its private bracket
    -- index array. Modern Solo Shuffle and Blitz are indices 7 and 9, not enum IDs.
    local names = { "Solo", "Blitz", "2v2", "3v3", "Rated BG" }
    local indexes = _G.CONQUEST_BRACKET_INDEXES or { 7, 9, 1, 2, 4 }
    for index, name in ipairs(names) do
        local bracketID = indexes[index]
        if type(bracketID) == "number" then brackets[#brackets + 1] = { name, bracketID } end
    end
    -- Scan the complete client payload as a compatibility net for future brackets.
    for bracketID = 1, 9 do brackets[#brackets + 1] = { "Rated PvP", bracketID } end
    for _, bracket in ipairs(brackets) do
        if not seen[bracket[2]] then
            seen[bracket[2]] = true
            local ok, rating = pcall(getter, bracket[2])
            if ok then AddRating(bracket[1], rating) end
        end
    end
    table.sort(ratings, function(a, b) return a.rating > b.rating end)
    return ratings
end

function Character:GetProgressData()
    local profile = self:GetRaiderProfile()
    local ratingSummary = C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary and C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
    local mplus = ratingSummary and ratingSummary.currentSeasonScore or 0
    local keystone = profile and profile.mythicKeystoneProfile
    if mplus == 0 and keystone then mplus = keystone.currentScore or 0 end
    local bestKey = keystone and keystone.maxDungeonLevel or 0

    local raidEntries = {}
    local difficultyNames = { [14]="N", [15]="H", [16]="M", [17]="LFR" }
    local raidProfile = profile and profile.raidProfile
    for _, raid in ipairs(raidProfile and raidProfile.raidProgress or {}) do
        if raid.current and not raid.isMainProgress then
            for _, group in ipairs(raid.progress or {}) do
                if not group.obsolete and (group.kills or 0) > 0 then
                    raidEntries[#raidEntries + 1] = {
                        name=raid.raid.shortName or "Current raid", kills=group.kills or 0,
                        bosses=raid.raid.bossCount or 0, difficulty=difficultyNames[group.difficulty] or tostring(group.difficulty),
                        difficultyID=group.difficulty or 0,
                    }
                end
            end
        end
    end
    table.sort(raidEntries, function(a, b)
        if a.difficultyID ~= b.difficultyID then return a.difficultyID > b.difficultyID end
        return a.kills > b.kills
    end)
    return { profile=profile, mplus=mplus, bestKey=bestKey, raids=raidEntries, pvp=self:GetPvPRatings() }
end

function Character:RefreshSummary()
    self.panel.summary:SetShown(ProjectRuthlessDB.character.showProgress)
    if not ProjectRuthlessDB.character.showProgress then return end
    local data = self:GetProgressData()
    self.progressData = data
    local summary = self.panel.summary
    summary.mplus.value:SetText(data.mplus > 0 and (Number(data.mplus) .. (data.bestKey > 0 and "  •  +" .. data.bestKey or "")) or "Unrated")
    local r, g, b = 1, 1, 1
    if data.mplus > 0 and _G.RaiderIO and _G.RaiderIO.GetScoreColor then
        local ok, cr, cg, cb = pcall(_G.RaiderIO.GetScoreColor, data.mplus)
        if ok and cr then r, g, b = cr, cg, cb end
    end
    summary.mplus.value:SetTextColor(r, g, b, 1)
    local raid = data.raids[1]
    summary.raid.value:SetText(raid and (("%d/%d %s"):format(raid.kills, raid.bosses, raid.difficulty)) or "No progress")
    local pvp = data.pvp[1]
    summary.pvp.value:SetText(pvp and (pvp.name .. "  " .. pvp.rating) or "Unrated")
    if pvp then
        local quality = pvp.rating >= 2400 and 5 or pvp.rating >= 2100 and 4 or pvp.rating >= 1800 and 3 or pvp.rating >= 1400 and 2 or 1
        local color = ITEM_QUALITY_COLORS[quality]
        summary.pvp.value:SetTextColor(color.r, color.g, color.b, 1)
    else summary.pvp.value:SetTextColor(unpack(COLORS.text)) end
end

function Character:CreateWindow()
    if self.frame then return end
    local frame=CreateFrame("Frame","ProjectRuthlessCharacterFrame",UIParent,"BackdropTemplate")
    frame:SetSize(710,620); frame:SetPoint("CENTER"); frame:SetFrameStrata("DIALOG"); frame:SetClampedToScreen(true); frame:SetMovable(true); frame:EnableMouse(true)
    Surface(frame,{0.025,0.028,0.038,0.98})
    local header=CreateFrame("Frame",nil,frame,"BackdropTemplate"); header:SetPoint("TOPLEFT",1,-1); header:SetPoint("TOPRIGHT",-1,-1); header:SetHeight(64); Surface(header,COLORS.surface,{0,0,0,0})
    header:EnableMouse(true); header:RegisterForDrag("LeftButton"); header:SetScript("OnDragStart",function() frame:StartMoving() end); header:SetScript("OnDragStop",function() frame:StopMovingOrSizing() end)
    local r,g,b=AccentColor(); local line=header:CreateTexture(nil,"ARTWORK"); line:SetColorTexture(r,g,b,1); line:SetPoint("BOTTOMLEFT"); line:SetPoint("BOTTOMRIGHT"); line:SetHeight(2)
    local mark=Label(header,"PR","large"); mark:SetPoint("LEFT",16,0); mark:SetTextColor(r,g,b,1)
    local title=Label(header,"CHARACTER","large"); title:SetPoint("LEFT",mark,"RIGHT",16,0)
    local close=CreateFrame("Button",nil,header); close:SetSize(40,40); close:SetPoint("RIGHT",-4,0); close.label=Label(close,"×","large"); close.label:SetPoint("CENTER",0,1); close:SetScript("OnClick",function() frame:Hide() end)
    local content=CreateFrame("Frame",nil,frame); content:SetPoint("TOPLEFT",12,-76); content:SetPoint("BOTTOMRIGHT",-12,12)
    self.frame=frame; self:CreatePanel(content)
    frame:SetScript("OnShow",function() Character:Refresh(); if CharacterMicroButton and CharacterMicroButton.SetPushed then CharacterMicroButton:SetPushed() end end)
    frame:SetScript("OnHide",function() if CharacterMicroButton and CharacterMicroButton.SetNormal then CharacterMicroButton:SetNormal() end end)
    tinsert(UISpecialFrames,"ProjectRuthlessCharacterFrame"); AUI:ApplyWindowSettings(); frame:Hide()
end

function Character:Toggle(onlyShow)
    self:CreateWindow()
    if onlyShow then self.frame:Show() else self.frame:SetShown(not self.frame:IsShown()) end
    if self.frame:IsShown() then self.frame:Raise() end
end

function Character:InstallReplacement()
    if self.replacementInstalled or type(_G.ToggleCharacter)~="function" then return end
    self.replacementInstalled=true; self.originalToggleCharacter=_G.ToggleCharacter
    _G.ToggleCharacter=function(tab,onlyShow)
        if tab=="PaperDollFrame" and ProjectRuthlessDB.character.replaceBlizzard then
            if CharacterFrame and CharacterFrame:IsShown() then HideUIPanel(CharacterFrame) end
            Character:Toggle(onlyShow)
        else
            if Character.frame and Character.frame:IsShown() then Character.frame:Hide() end
            Character.originalToggleCharacter(tab,onlyShow)
        end
    end
end

function Character:ApplySettings()
    if self.frame then
        if not ProjectRuthlessDB.character.replaceBlizzard and self.frame:IsShown() then self.frame:Hide() end
        self:Refresh()
    end
end

function Character:ShowProgressTooltip(owner)
    local data = self.progressData or self:GetProgressData()
    GameTooltip:SetOwner(owner, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:AddLine((UnitName("player") or "Character") .. " — Current progress", 1, 1, 1)
    GameTooltip:AddDoubleLine("Mythic+ rating", data.mplus > 0 and Number(data.mplus) or "Unrated", 0.7,0.7,0.75, 1,1,1)
    GameTooltip:AddDoubleLine("Best key", data.bestKey > 0 and ("+" .. data.bestKey) or "None", 0.7,0.7,0.75, 1,1,1)
    for _, raid in ipairs(data.raids) do
        GameTooltip:AddDoubleLine(raid.name, ("%d/%d %s"):format(raid.kills, raid.bosses, raid.difficulty), 0.7,0.7,0.75, 1,1,1)
    end
    for _, bracket in ipairs(data.pvp) do
        GameTooltip:AddDoubleLine(bracket.name, tostring(bracket.rating), 0.7,0.7,0.75, 1,1,1)
    end
    if #data.raids == 0 and #data.pvp == 0 then GameTooltip:AddLine("No rated raid or PvP data available.", 0.55,0.55,0.62) end
    GameTooltip:AddLine(data.profile and "Raider.IO data available" or "Raider.IO profile data unavailable", 0.45,0.6,0.9)
    GameTooltip:Show()
end

function Character:Refresh()
    local panel=self.panel; if not panel then return end
    local playerName = UnitName("player") or "Unknown"
    local titles = AUI.modules.Titles
    local titleID = titles and titles.currentTitleID
    if titleID == nil then titleID = GetCurrentTitle and GetCurrentTitle() or 0 end
    local title = titleID > 0 and GetTitleName and GetTitleName(titleID)
    local displayName = playerName
    if title and title ~= "" then
        if title:find("%%s") then
            local ok, formatted = pcall(string.format, title, playerName); if ok then displayName = formatted end
        else displayName = title .. " " .. playerName end
    end
    panel.heading:SetText(displayName)
    local specIndex = GetSpecialization and GetSpecialization()
    local specName = specIndex and select(2, GetSpecializationInfo(specIndex))
    panel.identity:SetText(("Level %d %s %s"):format(UnitLevel("player") or 0, specName or "", UnitClass("player") or ""))
    panel.model:SetUnit("player")
    ApplyWeaponState(panel.model)
    C_Timer.After(0, function() ApplyWeaponState(panel.model) end)
    self:RefreshGear(); self:RefreshSummary()
    local average, equipped=GetAverageItemLevel(); panel.details.itemLevel:SetText(("Equipped item level  %.1f"):format(tonumber(equipped or average) or 0))
    local qualityColor = ITEM_QUALITY_COLORS[self.dominantQuality or 1]
    panel.details.itemLevel:SetTextColor(qualityColor.r, qualityColor.g, qualityColor.b, 1)
    if self.mode=="stats" then self:SetStats(self:GetStatEntries()); self:RefreshLiveStats()
    elseif self.mode=="titles" then self:RefreshTitles()
    else self:RefreshSets() end
end

function Character:OnPlayerLogin()
    if self.events then return end
    local events=CreateFrame("Frame")
    for _, event in ipairs({"PLAYER_EQUIPMENT_CHANGED","EQUIPMENT_SETS_CHANGED","EQUIPMENT_SWAP_FINISHED","PLAYER_REGEN_ENABLED","UNIT_SPELLCAST_STOP","UNIT_SPELLCAST_CHANNEL_STOP","COMBAT_RATING_UPDATE","MASTERY_UPDATE","UNIT_STATS","PVP_RATED_STATS_UPDATE"}) do events:RegisterEvent(event) end
    events:RegisterEvent("ADDON_LOADED")
    events:SetScript("OnEvent", function(_,event,addon)
        if event=="ADDON_LOADED" and addon=="Blizzard_UIPanels_Game" then Character:InstallReplacement()
        elseif Character.panel and Character.panel:IsShown() then C_Timer.After(0,function() Character:Refresh() end) end
    end)
    self:InstallReplacement()
    if RequestRatedInfo then RequestRatedInfo() end
    self.events=events
end
