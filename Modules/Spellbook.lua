local _, AUI = ...

local Spellbook = { displayFrames={}, tabs={} }
AUI:RegisterModule("Spellbook", Spellbook)

local COLORS = {
    background={0.025,0.028,0.038,0.98}, surface={0.035,0.039,0.052,0.96},
    inset={0.022,0.025,0.034,0.92}, border={0.16,0.17,0.21,0.95},
    text={0.91,0.92,0.96,1}, muted={0.52,0.55,0.64,1},
}

local MACRO_COMMANDS = {
    { text="#showtooltip", detail="Show the icon and tooltip for the next usable action" },
    { text="#show", detail="Show the icon for a spell or item" },
    { text="/cast", detail="Cast a spell" }, { text="/use", detail="Use an item or spell" },
    { text="/castsequence", detail="Cast a sequence of spells in order" },
    { text="/castrandom", detail="Cast a random usable spell from a list" },
    { text="/stopcasting", detail="Stop the spell currently being cast" },
    { text="/cancelaura", detail="Cancel one of your helpful auras" },
    { text="/startattack", detail="Begin attacking your target" },
    { text="/stopattack", detail="Stop attacking" },
    { text="/target", detail="Target a named unit" },
    { text="/targetexact", detail="Target an exact unit name" },
    { text="/targetenemy", detail="Target the nearest enemy" },
    { text="/targetfriend", detail="Target the nearest friendly unit" },
    { text="/targetlasttarget", detail="Return to your previous target" },
    { text="/assist", detail="Target another unit's target" },
    { text="/focus", detail="Set your focus target" },
    { text="/clearfocus", detail="Clear your focus target" },
    { text="/petattack", detail="Order your pet to attack" },
    { text="/petfollow", detail="Order your pet to follow" },
    { text="/petpassive", detail="Set your pet to passive" },
    { text="/petdefensive", detail="Set your pet to defensive" },
    { text="/equip", detail="Equip an item by name" },
    { text="/equipslot", detail="Equip an item into a numbered slot" },
    { text="/equipset", detail="Equip a saved equipment set" },
    { text="/click", detail="Click a named secure button" },
    { text="/dismount", detail="Dismount" },
    { text="/leavevehicle", detail="Leave your current vehicle" },
    { text="/run", detail="Run a Lua snippet outside combat restrictions" },
    { text="/script", detail="Alias for /run" },
}

local MACRO_CONDITIONS = {
    { text="@target", detail="Use your current target" }, { text="@focus", detail="Use your focus" },
    { text="@mouseover", detail="Use the unit under the pointer" }, { text="@player", detail="Use yourself" },
    { text="@pet", detail="Use your pet" }, { text="@cursor", detail="Place a reticle spell at the pointer" },
    { text="@none", detail="Do not choose a unit target" }, { text="help", detail="Target can be helped" },
    { text="harm", detail="Target can be attacked" }, { text="exists", detail="Target exists" },
    { text="dead", detail="Target is dead" }, { text="nodead", detail="Target is alive" },
    { text="combat", detail="You are in combat" }, { text="nocombat", detail="You are not in combat" },
    { text="mod", detail="Any modifier key is held" }, { text="mod:shift", detail="Shift is held" },
    { text="mod:ctrl", detail="Control is held" }, { text="mod:alt", detail="Alt is held" },
    { text="nomod", detail="No modifier key is held" }, { text="spec:1", detail="Specialization slot 1 is active" },
    { text="group", detail="You are in a group" }, { text="group:raid", detail="You are in a raid" },
    { text="group:party", detail="You are in a party" }, { text="nogroup", detail="You are not grouped" },
    { text="mounted", detail="You are mounted" }, { text="nomounted", detail="You are not mounted" },
    { text="flying", detail="You are flying" }, { text="noflying", detail="You are not flying" },
    { text="indoors", detail="You are indoors" }, { text="outdoors", detail="You are outdoors" },
    { text="pet", detail="You have a pet" }, { text="nopet", detail="You do not have a pet" },
    { text="stance:1", detail="Stance or form slot 1 is active" },
    { text="channeling", detail="You are channeling a spell" },
    { text="nochanneling", detail="You are not channeling" },
    { text="button:1", detail="Macro was activated with mouse button 1" },
}

local MACRO_TEMPLATES = {
    { name="Mouseover heal", body="#showtooltip SPELL\n/cast [@mouseover,help,nodead][] SPELL" },
    { name="Focus interrupt", body="#showtooltip SPELL\n/cast [@focus,harm,nodead][] SPELL" },
    { name="Modifier keys", body="#showtooltip\n/cast [mod:shift] SHIFT SPELL; [mod:ctrl] CTRL SPELL; DEFAULT SPELL" },
    { name="Help / harm", body="#showtooltip\n/cast [help,nodead] FRIENDLY SPELL; [harm,nodead] HOSTILE SPELL" },
    { name="Cursor placement", body="#showtooltip SPELL\n/cast [@cursor] SPELL" },
    { name="Cast sequence", body="#showtooltip\n/castsequence reset=target SPELL ONE, SPELL TWO" },
    { name="Cancel aura", body="#showtooltip SPELL\n/cancelaura SPELL" },
}

local SPELL_FILTERS = {
    { id="all", label="All spells" },
    { id="current", label="Current spec" },
    { id="passive", label="Passive" },
    { id="onbar", label="On bars" },
    { id="missing", label="Not on bars" },
}

local KNOWN_CONDITIONS = {}
for _, condition in ipairs(MACRO_CONDITIONS) do KNOWN_CONDITIONS[condition.text:lower()] = true end
local VALID_CONDITION_BASES = {
    help=true,harm=true,exists=true,dead=true,nodead=true,combat=true,nocombat=true,mod=true,nomod=true,
    spec=true,group=true,nogroup=true,mounted=true,nomounted=true,flying=true,noflying=true,flyable=true,
    indoors=true,outdoors=true,pet=true,nopet=true,stance=true,form=true,stealth=true,nostealth=true,
    channeling=true,nochanneling=true,button=true,known=true,noknown=true,talent=true,equipped=true,
    swimming=true,noswimming=true,vehicleui=true,novehicleui=true,petbattle=true,nopetbattle=true,
    bonusbar=true,actionbar=true,overridebar=true,possessbar=true,extrabar=true,
}

local function AccentColor()
    local _, class = UnitClass("player")
    local color = class and RAID_CLASS_COLORS[class]
    return color and color.r or 0.5, color and color.g or 0.35, color and color.b or 0.94
end

local function Surface(frame, background, border)
    frame:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1 })
    frame:SetBackdropColor(unpack(background or COLORS.surface))
    frame:SetBackdropBorderColor(unpack(border or COLORS.border))
end

local function Label(parent, text, font)
    local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormal")
    label:SetText(text or ""); label:SetTextColor(unpack(COLORS.text))
    return label
end

local function Clean(text)
    return strtrim((text or ""):gsub("[%p%c]", " "):gsub("%s+", " ")):lower()
end

local function Settings()
    return ProjectRuthlessDB.spellbook
end

local function MacroScopeForIndex(index)
    local accountMaximum=(Constants and Constants.MacroConsts and Constants.MacroConsts.MAX_ACCOUNT_MACROS) or _G.MAX_ACCOUNT_MACROS or 120
    return index and index > accountMaximum and "character" or "account"
end

local function FindSpellActionSlots(spellID)
    if not spellID or not C_ActionBar or not C_ActionBar.FindSpellActionButtons then return {} end
    local ok, slots=pcall(C_ActionBar.FindSpellActionButtons,spellID)
    return ok and slots or {}
end

local function IsSpellOnBars(spellID)
    return #FindSpellActionSlots(spellID) > 0
end

local function PlayerBank()
    return Enum.SpellBookSpellBank.Player
end

function Spellbook:AddSkillLine(groups, skillLineIndex, forceName)
    local info = C_SpellBook.GetSpellBookSkillLineInfo(skillLineIndex)
    if not info or info.shouldHide then return end
    local items = {}
    for index = 1, info.numSpellBookItems or 0 do
        local slotIndex = (info.itemIndexOffset or 0) + index
        local item = C_SpellBook.GetSpellBookItemInfo(slotIndex, PlayerBank())
        if item and item.itemType ~= Enum.SpellBookItemType.FutureSpell and (ProjectRuthlessDB.spellbook.showOffSpec or not item.isOffSpec) then
            items[#items + 1] = {
                slotIndex=slotIndex, spellBank=PlayerBank(), itemType=item.itemType,
                spellID=item.spellID, actionID=item.actionID, name=item.name,
                iconID=item.iconID, passive=item.isPassive, offSpec=item.isOffSpec, bookInfo=item,
            }
        end
    end
    if #items > 0 then groups[#groups + 1] = { name=forceName or info.name, items=items } end
end

function Spellbook:AddProfession(groups, professionIndex)
    if not professionIndex then return end
    local name, texture, rank, maxRank, numSpells, spellOffset, _, rankModifier, _, _, skillLineName = GetProfessionInfo(professionIndex)
    if not name then return end
    local items = {}
    for index = 1, numSpells or 0 do
        local slotIndex = (spellOffset or 0) + index
        local item = C_SpellBook.GetSpellBookItemInfo(slotIndex, PlayerBank())
        if item and item.itemType ~= Enum.SpellBookItemType.FutureSpell then
            items[#items + 1] = {
                slotIndex=slotIndex, spellBank=PlayerBank(), itemType=item.itemType,
                spellID=item.spellID, actionID=item.actionID, name=item.name,
                iconID=item.iconID or texture, passive=item.isPassive, bookInfo=item,
            }
        end
    end
    local shownRank = (rank or 0) + (rankModifier or 0)
    local suffix = maxRank and maxRank > 0 and (("  %d/%d"):format(shownRank, maxRank)) or ""
    groups[#groups + 1] = { name=(skillLineName or name) .. suffix, items=items, profession=true }
end

function Spellbook:GetGroups()
    local groups = {}
    if self.mode == "general" then
        self:AddSkillLine(groups, Enum.SpellBookSkillLineIndex.General, "General")
    elseif self.mode == "class" then
        self:AddSkillLine(groups, Enum.SpellBookSkillLineIndex.Class)
        local count = C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetNumSpellBookSkillLines() or Enum.SpellBookSkillLineIndex.MainSpec
        for skillLineIndex = Enum.SpellBookSkillLineIndex.MainSpec, count do self:AddSkillLine(groups, skillLineIndex) end
    else
        local prof1, prof2, archaeology, fishing, cooking = GetProfessions()
        self:AddProfession(groups, prof1); self:AddProfession(groups, prof2); self:AddProfession(groups, cooking); self:AddProfession(groups, fishing); self:AddProfession(groups, archaeology)
    end
    local pinned={}
    for _,group in ipairs(groups) do
        for _,item in ipairs(group.items) do
            item.pinned=item.spellID and Settings().pinnedSpells[tostring(item.spellID)]==true
            if item.pinned then pinned[#pinned+1]=item end
        end
    end
    if #pinned>0 then table.insert(groups,1,{name="Pinned",items=pinned,pinnedGroup=true}) end
    return groups
end

function Spellbook:MatchesSpellFilter(item)
    local filter=self.spellFilter or Settings().state.spellFilter or "all"
    if filter=="current" then return not item.offSpec end
    if filter=="passive" then return item.passive==true end
    if filter=="onbar" then return not item.passive and IsSpellOnBars(item.spellID) end
    if filter=="missing" then return not item.passive and not item.offSpec and not IsSpellOnBars(item.spellID) end
    return true
end

function Spellbook:CycleSpellFilter(delta)
    local current=self.spellFilter or "all"; local index=1
    for i,filter in ipairs(SPELL_FILTERS) do if filter.id==current then index=i break end end
    index=((index-1+(delta or 1))%#SPELL_FILTERS)+1
    self.spellFilter=SPELL_FILTERS[index].id; Settings().state.spellFilter=self.spellFilter
    self.scroll.targetScroll=0; self.scroll:SetVerticalScroll(0); self:Refresh()
end

function Spellbook:TogglePinnedSpell(spellID)
    if not spellID then return end
    local key=tostring(spellID)
    Settings().pinnedSpells[key]=not Settings().pinnedSpells[key] or nil
    self:Refresh()
end

function Spellbook:PulseActionBarLocations(spellID)
    if InCombatLockdown() then AUI:Print("Action-bar location pulses are available out of combat."); return end
    local slotSet={}
    for _,slot in ipairs(FindSpellActionSlots(spellID)) do slotSet[slot]=true end
    if not next(slotSet) then return end
    local prefixes={"ActionButton","MultiBarBottomLeftButton","MultiBarBottomRightButton","MultiBarRightButton","MultiBarLeftButton","MultiBar5Button","MultiBar6Button","MultiBar7Button"}
    local found=0
    local function Pulse(button)
        if not button or button.__prPulse then return end
        local action=button.action or button:GetAttribute("action") or button._state_action
        if not slotSet[tonumber(action)] then return end
        found=found+1
        local glow=button:CreateTexture(nil,"OVERLAY"); glow:SetAtlas("spellbook-item-unassigned-glow"); glow:SetBlendMode("ADD"); glow:SetPoint("TOPLEFT",-8,8); glow:SetPoint("BOTTOMRIGHT",8,-8)
        local anim=glow:CreateAnimationGroup(); local pulse=anim:CreateAnimation("Alpha"); pulse:SetFromAlpha(1); pulse:SetToAlpha(0); pulse:SetDuration(0.7); pulse:SetOrder(1)
        anim:SetLooping("REPEAT"); button.__prPulse=glow; anim:Play()
        C_Timer.After(2.2,function() anim:Stop(); glow:Hide(); button.__prPulse=nil end)
    end
    for _,prefix in ipairs(prefixes) do for index=1,12 do Pulse(_G[prefix..index]) end end
    for bar=1,15 do for index=1,12 do Pulse(_G["ElvUI_Bar"..bar.."Button"..index]) end end
    if found==0 then AUI:Print("The spell is assigned, but its visible button could not be located.") end
end

local function SetButtonEnabled(button, enabled)
    button:SetEnabled(enabled)
    button:SetAlpha(enabled and 1 or 0.45)
end

function Spellbook:MarkMacroDirty()
    self.macroDirty=true
    if self.saveMacroButton then self.saveMacroButton:SetText("Save *") end
end

function Spellbook:GetMacroBank()
    local accountCount, characterCount = GetNumMacros()
    local accountMaximum=(Constants and Constants.MacroConsts and Constants.MacroConsts.MAX_ACCOUNT_MACROS) or _G.MAX_ACCOUNT_MACROS or 120
    local characterMaximum=(Constants and Constants.MacroConsts and Constants.MacroConsts.MAX_CHARACTER_MACROS) or _G.MAX_CHARACTER_MACROS or 30
    if self.macroScope == "account" then return 0, accountCount or 0, accountMaximum end
    return accountMaximum, characterCount or 0, characterMaximum
end

function Spellbook:BackupMacro(index, reason)
    if not index then return end
    local name, icon, body = GetMacroInfo(index)
    if name == nil then return end
    local backups = Settings().macroBackups
    table.insert(backups, 1, {
        name=name, icon=icon or 134400, body=body or "", scope=MacroScopeForIndex(index),
        reason=reason or "Before change", savedAt=time(), character=UnitName("player"),
    })
    while #backups > 100 do table.remove(backups) end
end

function Spellbook:GetMacroEntries()
    local base, count = self:GetMacroBank()
    local query=Clean(self.macroSearchText)
    local entries={}
    for bankIndex=1,count do
        local actualIndex=base+bankIndex
        local name,icon,body=GetMacroInfo(actualIndex)
        if name and (query=="" or Clean(name):find(query,1,true) or Clean(body):find(query,1,true)) then
            entries[#entries+1]={index=actualIndex,name=name,icon=icon or 134400,body=body or ""}
        end
    end
    return entries,count
end

function Spellbook:RefreshMacroList()
    if not self.macroView then return end
    local _, _, maximum = self:GetMacroBank()
    local entries,count = self:GetMacroEntries()
    local query=Clean(self.macroSearchText)
    local listKey=self.macroScope..":"..query
    local reset=listKey~=self.macroListKey; self.macroListKey=listKey
    self.macroListScroll:SetItemCount(#entries,reset)
    self.macroOffset=self.macroListScroll:GetItemOffset()
    for rowIndex, row in ipairs(self.macroRows) do
        self.macroListScroll:PlaceItem(row,rowIndex)
        local entry=entries[self.macroOffset+rowIndex]
        row.macroIndex = entry and entry.index or nil
        row:SetShown(entry ~= nil)
        if entry then
            row.icon:SetTexture(entry.icon); row.label:SetText(entry.name)
            local selected = entry.index == self.selectedMacro
            local r,g,b = AccentColor()
            row:SetBackdropBorderColor(selected and r or COLORS.border[1], selected and g or COLORS.border[2], selected and b or COLORS.border[3], 1)
            row:SetBackdropColor(selected and 0.075 or COLORS.inset[1], selected and 0.06 or COLORS.inset[2], selected and 0.075 or COLORS.inset[3], 0.98)
        end
    end
    if query~="" then self.macroCount:SetFormattedText("%d found  •  %d / %d",#entries,count,maximum)
    else self.macroCount:SetFormattedText("%d / %d",count,maximum) end
    SetButtonEnabled(self.newMacroButton, count < maximum and not InCombatLockdown())
    local selectedName = self.selectedMacro and GetMacroInfo(self.selectedMacro)
    SetButtonEnabled(self.saveMacroButton, (selectedName ~= nil or self.newMacroDraft) and not InCombatLockdown())
    SetButtonEnabled(self.deleteMacroButton, selectedName ~= nil and not InCombatLockdown())
    SetButtonEnabled(self.revertMacroButton, (selectedName ~= nil or self.newMacroDraft) and self.macroDirty == true)
    SetButtonEnabled(self.duplicateMacroButton, selectedName ~= nil and not InCombatLockdown())
    SetButtonEnabled(self.moveMacroButton, selectedName ~= nil and not InCombatLockdown())
    if self.moveMacroButton then self.moveMacroButton:SetText(self.macroScope=="account" and "Move to Character" or "Move to Account") end
    if self.selectedMacro and not selectedName then self:SelectMacro(nil) end
end

function Spellbook:SelectMacro(index)
    self.newMacroDraft = false
    self.selectedMacro = index
    local name, icon, body
    if index then name, icon, body = GetMacroInfo(index) end
    if index and name then Settings().state.selectedMacros[self.macroScope]=index; Settings().state.selectedMacroKeys[self.macroScope]=(name or "").."\031"..(body or "") end
    self.loadingMacro = true
    self.macroName:SetText(name or "")
    self.macroEditor:SetText(body or "")
    self.macroEditor:SetCursorPosition(0)
    self.macroIcon:SetTexture(icon or 134400)
    self.selectedMacroIcon=icon or 134400
    self.loadingMacro = false; self.macroDirty = false
    self.saveMacroButton:SetText("Save")
    self.macroEmpty:SetShown(not name); self.macroDetails:SetShown(name ~= nil)
    self:UpdateMacroSuggestions(); self:AnalyseMacro(); self:RefreshMacroList()
end

function Spellbook:CollectSpellSuggestions()
    local suggestions, seen = {}, {}
    local count = C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetNumSpellBookSkillLines() or 0
    for skillLineIndex = 1, count do
        local info = C_SpellBook.GetSpellBookSkillLineInfo(skillLineIndex)
        if info and not info.shouldHide then
            for index = 1, info.numSpellBookItems or 0 do
                local slotIndex = (info.itemIndexOffset or 0) + index
                local item = C_SpellBook.GetSpellBookItemInfo(slotIndex, PlayerBank())
                if item and item.name and item.spellID and not item.isPassive and not item.isOffSpec and item.itemType ~= Enum.SpellBookItemType.FutureSpell and not seen[item.name] then
                    seen[item.name] = true
                    suggestions[#suggestions + 1] = { text=item.name, detail=info.name or "Known spell" }
                end
            end
        end
    end
    table.sort(suggestions, function(a,b) return a.text < b.text end)
    self.spellSuggestions = suggestions
end

function Spellbook:CollectMacroCommandSuggestions()
    local suggestions, seen, descriptions = {}, {}, {}
    for _, command in ipairs(MACRO_COMMANDS) do descriptions[command.text:lower()]=command.detail end
    local function Add(text, detail)
        if type(text) ~= "string" or text == "" then return end
        local key=text:lower(); if seen[key] then return end
        seen[key]=true; suggestions[#suggestions+1]={text=text,detail=detail or descriptions[key] or "Available slash command"}
    end
    for _, command in ipairs(MACRO_COMMANDS) do Add(command.text,command.detail) end
    for commandKey in pairs(SlashCmdList or {}) do
        for index=1,20 do
            local alias=_G["SLASH_"..commandKey..index]
            if not alias then break end
            Add(alias)
        end
    end
    table.sort(suggestions,function(a,b) return a.text:lower()<b.text:lower() end)
    self.macroCommandSuggestions=suggestions
end

function Spellbook:CollectMacroIconChoices()
    local choices, seen = {}, {}
    local function Add(texture,name)
        if not texture then return end
        local normalized=tonumber(texture) or texture
        if type(normalized)=="string" and not normalized:find("\\") then normalized="Interface\\Icons\\"..normalized end
        local key=tostring(normalized):lower(); if seen[key] then return end
        seen[key]=true; choices[#choices+1]={texture=normalized,name=name or tostring(texture)}
    end
    Add(self.selectedMacroIcon or 134400,"Current icon"); Add(134400,"Question mark")
    local lineCount=C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetNumSpellBookSkillLines() or 0
    for skillLineIndex=1,lineCount do
        local info=C_SpellBook.GetSpellBookSkillLineInfo(skillLineIndex)
        if info and not info.shouldHide then
            for index=1,info.numSpellBookItems or 0 do
                local item=C_SpellBook.GetSpellBookItemInfo((info.itemIndexOffset or 0)+index,PlayerBank())
                if item and item.iconID then Add(item.iconID,item.name) end
            end
        end
    end
    for slot=INVSLOT_FIRST_EQUIPPED or 1,INVSLOT_LAST_EQUIPPED or 19 do Add(GetInventoryItemTexture("player",slot),GetInventoryItemLink("player",slot) or "Equipped item") end
    local loose={}
    if GetLooseMacroIcons then pcall(GetLooseMacroIcons,loose) end
    if GetMacroIcons then pcall(GetMacroIcons,loose) end
    if GetLooseMacroItemIcons then pcall(GetLooseMacroItemIcons,loose) end
    if GetMacroItemIcons then pcall(GetMacroItemIcons,loose) end
    for _,texture in ipairs(loose) do Add(texture,tostring(texture):gsub("_"," "):lower()) end
    self.macroIconChoices=choices
end

function Spellbook:RefreshMacroIconPicker(reset)
    if not self.iconPicker then return end
    if not self.macroIconChoices then self:CollectMacroIconChoices() end
    local query=Clean(self.iconSearch and self.iconSearch:GetText())
    local filtered={}
    for _,choice in ipairs(self.macroIconChoices) do if query=="" or Clean(choice.name):find(query,1,true) then filtered[#filtered+1]=choice end end
    self.iconScroll:SetItemCount(#filtered,reset)
    self.iconOffset=self.iconScroll:GetItemOffset()
    for index,button in ipairs(self.iconButtons) do
        self.iconScroll:PlaceItem(button,index,49)
        local choice=filtered[self.iconOffset+index]; button.choice=choice; button:SetShown(choice~=nil)
        if choice then button.icon:SetTexture(choice.texture) end
    end
    self.iconCount:SetFormattedText("%d icons",#filtered)
end

function Spellbook:ShowMacroIconPicker()
    if not self.selectedMacro and not self.newMacroDraft then return end
    self.macroIconChoices=nil; self.iconSearch:SetText(""); self.iconOffset=0; self:RefreshMacroIconPicker(true); self.iconPicker:Show()
end

function Spellbook:CreateMacroIconPicker(parent)
    local picker=CreateFrame("Frame",nil,parent,"BackdropTemplate"); picker:SetPoint("TOPLEFT",194,0); picker:SetPoint("BOTTOMRIGHT"); picker:SetFrameLevel(parent:GetFrameLevel()+20); Surface(picker,COLORS.background); picker:Hide(); self.iconPicker=picker; self.iconButtons={}
    local title=Label(picker,"CHOOSE AN ICON","GameFontNormal"); title:SetPoint("TOPLEFT",10,-10)
    local close=AUI:CreateButton(picker); close:SetSize(62,22); close:SetPoint("TOPRIGHT",-8,-7); close:SetText("Close"); close:SetScript("OnClick",function() picker:Hide() end)
    local search=CreateFrame("EditBox",nil,picker,"SearchBoxTemplate"); search:SetSize(270,24); search:SetPoint("TOPLEFT",10,-38); self.iconSearch=search
    search:SetScript("OnTextChanged",function(box) SearchBoxTemplate_OnTextChanged(box); Spellbook:RefreshMacroIconPicker(true) end)
    local count=Label(picker,"0 icons","GameFontNormalSmall"); count:SetPoint("LEFT",search,"RIGHT",10,0); count:SetTextColor(unpack(COLORS.muted)); self.iconCount=count
    local grid=AUI:CreateListScroll(picker,49,8,function() Spellbook:RefreshMacroIconPicker() end); grid:SetPoint("TOPLEFT",8,-72); grid:SetPoint("BOTTOMRIGHT",-8,8); self.iconScroll=grid
    for index=1,96 do
        local column=(index-1)%8; local row=math.floor((index-1)/8)
        local button=CreateFrame("Button",nil,grid.content,"BackdropTemplate"); button:SetSize(42,42); Surface(button,COLORS.inset)
        button.icon=button:CreateTexture(nil,"ARTWORK"); button.icon:SetPoint("TOPLEFT",3,-3); button.icon:SetPoint("BOTTOMRIGHT",-3,3); button.icon:SetTexCoord(0.08,0.92,0.08,0.92)
        button:SetScript("OnClick",function(self) if not self.choice then return end; Spellbook.selectedMacroIcon=self.choice.texture; Spellbook.macroIcon:SetTexture(self.choice.texture); Spellbook:MarkMacroDirty(); Spellbook:AnalyseMacro(); Spellbook:RefreshMacroList(); picker:Hide() end)
        button:SetScript("OnEnter",function(self) if self.choice then GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:AddLine(self.choice.name,1,1,1,true); GameTooltip:Show() end end); button:SetScript("OnLeave",GameTooltip_Hide)
        self.iconButtons[index]=button
    end
end

function Spellbook:GetMacroSuggestionContext()
    if not self.selectedMacro and not self.newMacroDraft then return nil end
    local text = self.macroEditor:GetText() or ""
    local cursor = self.macroEditor:GetCursorPosition() or #text
    local before = text:sub(1, cursor)
    local line = before:match("[^\n]*$") or ""
    local lineStart = #before - #line + 1
    local token = line:match("^%s*([/#][^%s]*)$")
    if token then
        local tokenStart = lineStart + (line:find(token, 1, true) or 1) - 1
        if not self.macroCommandSuggestions then self:CollectMacroCommandSuggestions() end
        return self.macroCommandSuggestions, token:lower(), tokenStart, cursor
    end
    local condition = line:match("[%[,]%s*([^,%[%]]*)$")
    local openBracket = line:match(".*()%[")
    local closeBracket = line:match(".*()%]")
    if openBracket and (not closeBracket or openBracket > closeBracket) and condition then
        local tokenStart = lineStart + #line - #condition
        return MACRO_CONDITIONS, strtrim(condition):lower(), tokenStart, cursor
    end
    local prefix, command, arguments = line:match("^%s*([/#])([%a]+)%s+(.*)$")
    command=command and command:lower()
    if command and ((prefix == "/" and (command == "cast" or command == "use" or command == "castsequence" or command == "castrandom" or command == "cancelaura")) or (prefix == "#" and (command == "showtooltip" or command == "show"))) then
        local tail = arguments:match("([^,;]*)$") or arguments
        local stripped = tail:gsub("^%s*%b[]%s*", ""):gsub("^%s+", "")
        local tokenStart = lineStart + #line - #stripped
        if not self.spellSuggestions then self:CollectSpellSuggestions() end
        return self.spellSuggestions, strtrim(stripped):lower(), tokenStart, cursor
    end
    return nil
end

function Spellbook:UpdateMacroSuggestions()
    if not self.macroSuggestions then return end
    if not ProjectRuthlessDB.spellbook.macroAutocomplete then
        self.currentSuggestions={}; self.macroSuggestions:Hide(); if self.suggestionHint then self.suggestionHint:Hide() end
        self.macroStatus:SetFormattedText("%d / 255",self.macroEditor:GetNumLetters()); return
    end
    local source, query, replaceStart, replaceEnd = self:GetMacroSuggestionContext()
    local matches = {}
    if source then
        for _, suggestion in ipairs(source) do
            local candidate = suggestion.text:lower()
            if query == "" or candidate:find(query, 1, true) == 1 then matches[#matches + 1] = suggestion end
        end
    end
    local contextKey=tostring(source)..":"..tostring(query)
    local reset=contextKey~=self.suggestionContextKey
    self.suggestionContextKey=contextKey
    if reset then self.suggestionSelected=1 end
    self.suggestionSelected=math.max(1,math.min(self.suggestionSelected or 1,#matches > 0 and #matches or 1))
    self.suggestionScroll:SetItemCount(#matches,reset)
    self.suggestionOffset=self.suggestionScroll:GetItemOffset()
    local visible={}
    for index=1,#self.suggestionRows do visible[index]=matches[self.suggestionOffset+index] end
    self.allSuggestions=matches; self.currentSuggestions=visible; self.suggestionStart=replaceStart; self.suggestionEnd=replaceEnd
    for index, row in ipairs(self.suggestionRows) do
        self.suggestionScroll:PlaceItem(row,index)
        local suggestion = visible[index]
        row.suggestion = suggestion; row:SetShown(suggestion ~= nil)
        if suggestion then
            row.command:SetText(suggestion.text)
            local category=source==MACRO_CONDITIONS and "Condition" or source==self.spellSuggestions and "Spell" or suggestion.text:sub(1,1)=="#" and "Directive" or "Command"
            row.detail:SetText(category.."  •  "..(suggestion.detail or ""))
            local selected=(self.suggestionOffset+index)==(self.suggestionSelected or 1); local ar,ag,ab=AccentColor()
            row:SetBackdropColor(selected and ar*0.16 or COLORS.inset[1],selected and ag*0.12 or COLORS.inset[2],selected and ab*0.16 or COLORS.inset[3],0.98)
            row:SetBackdropBorderColor(selected and ar or COLORS.border[1],selected and ag or COLORS.border[2],selected and ab or COLORS.border[3],1)
        end
    end
    self.macroSuggestions:SetShown(#matches > 0)
    if self.suggestionTitle and #matches > 0 then
        local first=self.suggestionOffset+1; local last=math.min(#matches,self.suggestionOffset+#self.suggestionRows)
        self.suggestionTitle:SetFormattedText("SUGGESTIONS  %d–%d OF %d  •  ↑↓ SELECT  •  TAB TO INSERT",first,last,#matches)
    end
    if self.suggestionHint then self.suggestionHint:SetShown(#matches == 0 and (self.selectedMacro ~= nil or self.newMacroDraft)) end
    local count = self.macroEditor:GetNumLetters()
    local r,g,b = count >= 255 and 1 or COLORS.muted[1], count >= 255 and 0.3 or COLORS.muted[2], count >= 255 and 0.3 or COLORS.muted[3]
    self.macroStatus:SetFormattedText("%d / 255", count); self.macroStatus:SetTextColor(r,g,b,1)
end

function Spellbook:AcceptSelectedMacroSuggestion()
    if not self.macroSuggestions or not self.macroSuggestions:IsShown() then return false end
    local suggestion=self.allSuggestions and self.allSuggestions[self.suggestionSelected or 1]
    if suggestion then self:AcceptMacroSuggestion(suggestion); return true end
    return false
end

function Spellbook:MoveMacroSuggestion(delta)
    local suggestions=self.allSuggestions
    if not self.macroSuggestions or not self.macroSuggestions:IsShown() or not suggestions or #suggestions==0 then return false end
    self.suggestionSelected=math.max(1,math.min((self.suggestionSelected or 1)+delta,#suggestions))
    local rowHeight=self.suggestionScroll.rowHeight or 33
    local viewport=self.suggestionScroll:GetHeight()
    local itemTop=(self.suggestionSelected-1)*rowHeight
    local itemBottom=itemTop+rowHeight
    local viewTop=self.suggestionScroll.targetScroll or self.suggestionScroll:GetVerticalScroll()
    if itemTop<viewTop then
        self.suggestionScroll:ScrollTo(itemTop)
    elseif itemBottom>viewTop+viewport then
        self.suggestionScroll:ScrollTo(itemBottom-viewport)
    end
    self:UpdateMacroSuggestions()
    return true
end

function Spellbook:AcceptMacroSuggestion(suggestion)
    if not suggestion or not self.suggestionStart then return end
    local text = self.macroEditor:GetText() or ""
    local replacement = suggestion.text
    if replacement:sub(1,1) == "/" or replacement:sub(1,1) == "#" then replacement = replacement .. " " end
    local updated = text:sub(1, self.suggestionStart - 1) .. replacement .. text:sub((self.suggestionEnd or self.suggestionStart) + 1)
    self.macroEditor:SetText(updated)
    self.macroEditor:SetCursorPosition(self.suggestionStart - 1 + #replacement)
    self.macroEditor:SetFocus()
end

function Spellbook:GetKnownSpellNames()
    if not self.spellSuggestions then self:CollectSpellSuggestions() end
    local known={}
    for _,entry in ipairs(self.spellSuggestions or {}) do known[entry.text:lower()]=true end
    return known
end

function Spellbook:AnalyseMacro()
    if not self.macroEditor then return end
    local body=self.macroEditor:GetText() or ""
    local warnings={}
    local opens=select(2,body:gsub("%[","")); local closes=select(2,body:gsub("%]",""))
    if opens~=closes then warnings[#warnings+1]="Unclosed condition bracket" end
    for bracket in body:gmatch("%[([^%]]+)%]") do
        for token in bracket:gmatch("[^,]+") do
            token=strtrim(token):lower()
            local base=token:match("^([%a]+)")
            local negatedBase=base and base:sub(1,2)=="no" and base:sub(3) or nil
            if token~="" and token:sub(1,1)~="@" and not token:match("^target=") and base and not KNOWN_CONDITIONS[token] and not VALID_CONDITION_BASES[base] and not (negatedBase and VALID_CONDITION_BASES[negatedBase]) then
                warnings[#warnings+1]="Unknown condition: "..token
            end
        end
    end
    if not self.macroCommandSuggestions then self:CollectMacroCommandSuggestions() end
    local commands={}
    for _,entry in ipairs(self.macroCommandSuggestions or {}) do commands[entry.text:lower()]=true end
    local knownSpells=self:GetKnownSpellNames()
    local previewSpell
    for line in (body.."\n"):gmatch("(.-)\n") do
        local prefix,command,arguments=line:match("^%s*([/#])([%a]+)%s*(.*)$")
        if command then
            local full=(prefix..command):lower()
            if not commands[full] then warnings[#warnings+1]="Unknown command: "..full end
            local lower=command:lower()
            if (lower=="showtooltip" or lower=="show") and arguments~="" and not previewSpell then previewSpell=arguments end
            if prefix=="/" and (lower=="cast" or lower=="cancelaura" or lower=="castsequence" or lower=="castrandom") then
                local spellText=arguments:gsub("^%s*%b[]%s*",""):gsub("^reset=[^%s]+%s*","")
                for candidate in spellText:gmatch("[^,;]+") do
                    candidate=strtrim(candidate:gsub("^%s*%b[]%s*",""):gsub("!", ""))
                    if candidate~="" and candidate:lower()~="null" and not knownSpells[candidate:lower()] then warnings[#warnings+1]="Spell not found: "..candidate end
                    if not previewSpell and candidate~="" then previewSpell=candidate end
                end
            end
        end
    end
    previewSpell=previewSpell and strtrim(previewSpell:gsub("^%s*%b[]%s*",""):match("^[^,;]+") or previewSpell) or nil
    local spellInfo
    if previewSpell and C_Spell and C_Spell.GetSpellInfo then local ok,result=pcall(C_Spell.GetSpellInfo,previewSpell); if ok then spellInfo=result end end
    self.macroPreviewSpellID=spellInfo and spellInfo.spellID or nil
    self.macroWarnings=warnings
    if self.macroPreviewText then
        local scope=self.macroScope=="account" and "Account" or "Character"
        self.macroPreviewText:SetText(spellInfo and (scope.."  •  Preview: "..spellInfo.name) or (scope.." macro"))
    end
    if self.macroPreviewIcon then self.macroPreviewIcon:SetTexture((self.selectedMacroIcon==134400 and spellInfo and spellInfo.iconID) or self.selectedMacroIcon or 134400) end
    if self.macroWarning then
        if #warnings>0 then self.macroWarning:SetText("⚠ "..warnings[1]..(#warnings>1 and ("  +"..(#warnings-1)) or "")); self.macroWarning:SetTextColor(1,0.55,0.25,1)
        else self.macroWarning:SetText("No obvious syntax problems"); self.macroWarning:SetTextColor(0.35,0.85,0.45,1) end
    end
end

function Spellbook:CreateMacroCopy(scope, name, icon, body)
    if InCombatLockdown() then return nil end
    local accountCount,characterCount=GetNumMacros()
    local accountMaximum=(Constants and Constants.MacroConsts and Constants.MacroConsts.MAX_ACCOUNT_MACROS) or _G.MAX_ACCOUNT_MACROS or 120
    local characterMaximum=(Constants and Constants.MacroConsts and Constants.MacroConsts.MAX_CHARACTER_MACROS) or _G.MAX_CHARACTER_MACROS or 30
    if (scope=="account" and accountCount>=accountMaximum) or (scope=="character" and characterCount>=characterMaximum) then
        AUI:Print("That macro bank is full.")
        return nil
    end
    return CreateMacro(name=="" and " " or name,icon or 134400,body or "",scope=="character")
end

function Spellbook:SaveMacro()
    if (not self.selectedMacro and not self.newMacroDraft) or InCombatLockdown() then return end
    local name = strtrim(self.macroName:GetText() or "")
    if name == "" then name = " " end
    local newIndex
    if self.newMacroDraft then
        newIndex=self:CreateMacroCopy(self.macroScope,name,self.selectedMacroIcon,self.macroEditor:GetText())
    else
        if self.macroDirty then self:BackupMacro(self.selectedMacro,"Before save") end
        newIndex=EditMacro(self.selectedMacro,name,self.selectedMacroIcon or 134400,self.macroEditor:GetText() or "")
    end
    self.newMacroDraft=false; self.selectedMacro=newIndex or self.selectedMacro; self.macroDirty=false
    self:SelectMacro(self.selectedMacro)
end

function Spellbook:RevertMacro()
    if self.newMacroDraft then self:SelectMacro(nil)
    elseif self.selectedMacro then self:SelectMacro(self.selectedMacro) end
end

function Spellbook:CreateNewMacro()
    if InCombatLockdown() then return end
    local _, count, maximum = self:GetMacroBank()
    if count >= maximum then return end
    self.selectedMacro=nil; self.newMacroDraft=true; self.loadingMacro=true
    self.macroName:SetText(""); self.macroEditor:SetText(""); self.macroEditor:SetCursorPosition(0); self.macroIcon:SetTexture(134400); self.selectedMacroIcon=134400
    self.loadingMacro=false; self:MarkMacroDirty(); self.macroEmpty:Hide(); self.macroDetails:Show(); self:AnalyseMacro(); self:RefreshMacroList()
    self.macroName:SetFocus(); self.macroName:HighlightText()
end

function Spellbook:DeleteSelectedMacro()
    if not self.selectedMacro or InCombatLockdown() then return end
    self:BackupMacro(self.selectedMacro,"Before delete")
    DeleteMacro(self.selectedMacro); Settings().state.selectedMacros[self.macroScope]=nil; Settings().state.selectedMacroKeys[self.macroScope]=nil; self.selectedMacro=nil; self:SelectMacro(nil)
end

function Spellbook:DuplicateSelectedMacro()
    if not self.selectedMacro then return end
    local name,icon,body=GetMacroInfo(self.selectedMacro)
    if not name then return end
    local newIndex=self:CreateMacroCopy(MacroScopeForIndex(self.selectedMacro),name,icon,body)
    if newIndex then self.selectedMacro=newIndex; self:SelectMacro(newIndex) end
end

function Spellbook:MoveSelectedMacro()
    if not self.selectedMacro or InCombatLockdown() then return end
    local name,icon,body=GetMacroInfo(self.selectedMacro)
    if not name then return end
    local source=MacroScopeForIndex(self.selectedMacro)
    local destination=source=="account" and "character" or "account"
    local newIndex=self:CreateMacroCopy(destination,name,icon,body)
    if not newIndex then return end
    self:BackupMacro(self.selectedMacro,"Before move")
    DeleteMacro(self.selectedMacro)
    Settings().state.selectedMacros[source]=nil
    Settings().state.selectedMacroKeys[source]=nil
    self:SetMacroScope(destination)
    self:SelectMacro(newIndex)
end

function Spellbook:RestoreMacroBackup(backupIndex)
    local backup=Settings().macroBackups[backupIndex]
    if not backup then return end
    local newIndex=self:CreateMacroCopy(backup.scope,backup.name,backup.icon,backup.body)
    if newIndex then
        self:SetMacroScope(backup.scope); self:SelectMacro(newIndex)
        if self.backupPanel then self.backupPanel:Hide() end
        AUI:Print("Restored the saved macro as a new copy.")
    end
end

function Spellbook:CreateHeader(parent)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetHeight(24); Surface(frame, {0.055,0.058,0.075,0.98}, {0,0,0,0})
    frame.text = Label(frame, "", "GameFontNormalSmall"); frame.text:SetPoint("LEFT", 8, 0)
    local r,g,b = AccentColor(); frame.text:SetTextColor(r,g,b,1)
    return frame
end

function Spellbook:CreateSpellButton(parent)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(310, 46); Surface(button, COLORS.inset)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp"); button:RegisterForDrag("LeftButton")
    button.icon = button:CreateTexture(nil, "ARTWORK"); button.icon:SetSize(36,36); button.icon:SetPoint("LEFT",5,0); button.icon:SetTexCoord(0.08,0.92,0.08,0.92)
    button.actionBarHighlight = button:CreateTexture(nil, "OVERLAY"); button.actionBarHighlight:SetAtlas("spellbook-item-unassigned-glow"); button.actionBarHighlight:SetBlendMode("ADD")
    button.actionBarHighlight:SetPoint("TOPLEFT",button.icon,"TOPLEFT",-4,3); button.actionBarHighlight:SetPoint("BOTTOMRIGHT",button.icon,"BOTTOMRIGHT",3,-3); button.actionBarHighlight:Hide()
    button.actionBarAnim=button.actionBarHighlight:CreateAnimationGroup(); button.actionBarAnim:SetLooping("REPEAT")
    local fadeIn=button.actionBarAnim:CreateAnimation("Alpha"); fadeIn:SetFromAlpha(0.5); fadeIn:SetToAlpha(1); fadeIn:SetDuration(0.5); fadeIn:SetOrder(1)
    local fadeOut=button.actionBarAnim:CreateAnimation("Alpha"); fadeOut:SetFromAlpha(1); fadeOut:SetToAlpha(0.5); fadeOut:SetDuration(0.5); fadeOut:SetOrder(2)
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate"); button.cooldown:SetAllPoints(button.icon)
    button.name = Label(button, "", "GameFontHighlight"); button.name:SetPoint("TOPLEFT", button.icon, "TOPRIGHT", 8, -2); button.name:SetPoint("RIGHT", -48, 0); button.name:SetJustifyH("LEFT")
    button.detail = Label(button, "", "GameFontNormalSmall"); button.detail:SetPoint("BOTTOMLEFT", button.icon, "BOTTOMRIGHT", 8, 2); button.detail:SetTextColor(unpack(COLORS.muted))
    button.pin=Label(button,"★","GameFontNormalSmall"); button.pin:SetPoint("TOPRIGHT",-7,-5); button.pin:SetTextColor(1,0.78,0.2,1); button.pin:Hide()
    button.barMarker=CreateFrame("Button",nil,button,"BackdropTemplate"); button.barMarker:SetSize(34,16); button.barMarker:SetPoint("BOTTOMRIGHT",-5,4); Surface(button.barMarker,{0.04,0.08,0.055,0.98})
    button.barMarker.label=Label(button.barMarker,"BAR","GameFontNormalSmall"); button.barMarker.label:SetPoint("CENTER"); button.barMarker.label:SetTextColor(0.35,0.9,0.5,1)
    button.barMarker:SetScript("OnClick",function(marker) Spellbook:PulseActionBarLocations(marker:GetParent().spellID) end)
    button.barMarker:SetScript("OnEnter",function(marker) GameTooltip:SetOwner(marker,"ANCHOR_RIGHT"); GameTooltip:AddLine("Locate on action bars",1,1,1); GameTooltip:AddLine("Click to pulse every visible copy.",0.7,0.7,0.75); GameTooltip:Show() end); button.barMarker:SetScript("OnLeave",GameTooltip_Hide)
    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.075,0.078,0.10,0.98)
        if self.slotIndex then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if GameTooltip:SetSpellBookItem(self.slotIndex, self.spellBank) then
                if self.actionBarMissing then GameTooltip:AddLine(SPELLBOOK_SEARCH_NOT_ON_ACTIONBAR or "Not on an action bar",1,0.82,0) end
                GameTooltip:AddLine(self.pinned and "Right-click to unpin" or "Right-click to pin",0.55,0.65,0.8)
                GameTooltip:Show()
            end
        end
    end)
    button:SetScript("OnLeave", function(self) self:SetBackdropColor(unpack(COLORS.inset)); GameTooltip_Hide() end)
    button:SetScript("OnClick", function(self,mouseButton)
        if mouseButton=="RightButton" then Spellbook:TogglePinnedSpell(self.spellID)
        elseif self.slotIndex and not self.passive then C_SpellBook.CastSpellBookItem(self.slotIndex, self.spellBank) end
    end)
    button:SetScript("OnDragStart", function(self)
        if self.slotIndex and not self.passive then C_SpellBook.PickupSpellBookItem(self.slotIndex, self.spellBank) end
    end)
    return button
end

function Spellbook:AcquireDisplayFrame(kind)
    local index = #self.activeFrames + 1
    local frame = self.displayFrames[index]
    if not frame or frame.kind ~= kind then
        if frame then frame:Hide() end
        frame = kind == "header" and self:CreateHeader(self.content) or self:CreateSpellButton(self.content)
        frame.kind = kind; self.displayFrames[index] = frame
    end
    self.activeFrames[index] = frame; frame:Show()
    return frame
end

function Spellbook:Refresh()
    if not self.frame then return end
    if self.mode == "macros" then
        for _, display in ipairs(self.displayFrames) do display:Hide(); if display.actionBarAnim and display.actionBarAnim:IsPlaying() then display.actionBarAnim:Stop() end end
        self.empty:Hide(); self:RefreshMacroList()
        for id, tab in pairs(self.tabs) do
            local active = id == self.mode
            tab:SetBackdropColor(active and 0.10 or COLORS.inset[1], active and 0.075 or COLORS.inset[2], active and 0.10 or COLORS.inset[3], 0.98)
            tab.label:SetTextColor(active and 1 or COLORS.muted[1], active and 0.82 or COLORS.muted[2], active and 0.92 or COLORS.muted[3], 1)
        end
        return
    end
    self.activeFrames = {}
    local query = Clean(self.searchText)
    local y, pendingColumn = 0, 0
    for _, group in ipairs(self:GetGroups()) do
        local visible = {}
        local groupMatches = query ~= "" and Clean(group.name):find(query, 1, true)
        for _, item in ipairs(group.items) do
            if self:MatchesSpellFilter(item) and (query == "" or groupMatches or Clean(item.name):find(query, 1, true)) then visible[#visible + 1] = item end
        end
        if #visible > 0 or (group.profession and query == "") then
            if pendingColumn == 1 then y=y+50; pendingColumn=0 end
            local header = self:AcquireDisplayFrame("header")
            header:ClearAllPoints(); header:SetPoint("TOPLEFT", 0, -y); header:SetPoint("TOPRIGHT", 0, -y); header.text:SetText(group.name)
            y=y+28
            for _, item in ipairs(visible) do
                local button = self:AcquireDisplayFrame("spell")
                local column = pendingColumn
                button:ClearAllPoints(); button:SetPoint("TOPLEFT", column * 316, -y)
                button.slotIndex=item.slotIndex; button.spellBank=item.spellBank; button.passive=item.passive; button.spellID=item.spellID; button.pinned=item.pinned
                button.icon:SetTexture(item.iconID or 134400); button.name:SetText(item.name or "Unknown spell")
                button.detail:SetText(item.passive and "Passive" or item.offSpec and "Other specialization" or item.itemType == Enum.SpellBookItemType.Flyout and "Flyout" or "Ability")
                button:SetAlpha(item.offSpec and 0.42 or 1)
                button.icon:SetDesaturated(item.offSpec == true)
                local status
                if ProjectRuthlessDB.spellbook.highlightMissing and not item.passive and not item.offSpec and item.bookInfo and SpellSearchUtil and SpellSearchUtil.GetActionbarStatusForSpellBookItemInfo then
                    local ok, result=pcall(SpellSearchUtil.GetActionbarStatusForSpellBookItemInfo,item.bookInfo); if ok then status=result end
                end
                local missingStatus=ActionButtonUtil and ActionButtonUtil.ActionBarActionStatus and ActionButtonUtil.ActionBarActionStatus.MissingFromAllBars
                if status ~= nil and missingStatus ~= nil then button.actionBarMissing=status == missingStatus
                elseif ProjectRuthlessDB.spellbook.highlightMissing and not item.passive and not item.offSpec and item.spellID and C_ActionBar and C_ActionBar.FindSpellActionButtons then
                    local slots=C_ActionBar.FindSpellActionButtons(item.spellID); button.actionBarMissing=not slots or #slots == 0
                else button.actionBarMissing=false end
                local onBars=not item.passive and IsSpellOnBars(item.spellID)
                button.barMarker:SetShown(onBars); button.pin:SetShown(item.pinned==true)
                button.actionBarHighlight:SetShown(button.actionBarMissing)
                if button.actionBarMissing then if not button.actionBarAnim:IsPlaying() then button.actionBarAnim:Play() end
                elseif button.actionBarAnim:IsPlaying() then button.actionBarAnim:Stop() end
                local cooldown = C_SpellBook.GetSpellBookItemCooldown and C_SpellBook.GetSpellBookItemCooldown(item.slotIndex, item.spellBank)
                if cooldown and cooldown.duration and cooldown.duration > 0 then
                    button.cooldown:SetCooldown(cooldown.startTime or 0, cooldown.duration, cooldown.modRate or 1)
                else button.cooldown:Clear() end
                pendingColumn = 1 - pendingColumn
                if pendingColumn == 0 then y=y+50 end
            end
        end
    end
    if pendingColumn == 1 then y=y+50 end
    for index = #self.activeFrames + 1, #self.displayFrames do
        local display=self.displayFrames[index]; display:Hide()
        if display.actionBarAnim and display.actionBarAnim:IsPlaying() then display.actionBarAnim:Stop() end
    end
    self.content:SetHeight(math.max(y, 1)); self.empty:SetShown(#self.activeFrames == 0)
    if self.filterButton then
        local label="All spells"; for _,filter in ipairs(SPELL_FILTERS) do if filter.id==(self.spellFilter or "all") then label=filter.label break end end
        self.filterButton:SetText("Filter: "..label)
    end
    for id, tab in pairs(self.tabs) do
        local active = id == self.mode
        tab:SetBackdropColor(active and 0.10 or COLORS.inset[1], active and 0.075 or COLORS.inset[2], active and 0.10 or COLORS.inset[3], 0.98)
        tab.label:SetTextColor(active and 1 or COLORS.muted[1], active and 0.82 or COLORS.muted[2], active and 0.92 or COLORS.muted[3], 1)
    end
end

function Spellbook:SelectMode(mode)
    if self.mode and self.scroll then Settings().state.scroll[self.mode]=self.scroll:GetVerticalScroll() end
    self.mode=mode; Settings().state.mode=mode
    local remembered=Settings().state.scroll[mode] or 0
    self.scroll.targetScroll=remembered; self.scroll:SetVerticalScroll(remembered)
    self.scroll:SetShown(mode ~= "macros"); self.searchBox:SetShown(mode ~= "macros"); self.filterButton:SetShown(mode ~= "macros"); self.pinHint:SetShown(mode ~= "macros"); self.macroView:SetShown(mode == "macros")
    self:Refresh()
end

function Spellbook:SetMacroScope(scope)
    self.macroScope=scope; Settings().state.macroScope=scope; self.macroOffset=0; self.selectedMacro=nil; self.newMacroDraft=false
    for id,button in pairs(self.macroScopeButtons or {}) do
        local active=id==scope; local r,g,b=AccentColor()
        button:SetBackdropBorderColor(active and r or COLORS.border[1],active and g or COLORS.border[2],active and b or COLORS.border[3],1)
        button.label:SetTextColor(active and 1 or COLORS.muted[1],active and 0.82 or COLORS.muted[2],active and 0.92 or COLORS.muted[3],1)
    end
    local remembered=Settings().state.selectedMacros[scope]; local rememberedKey=Settings().state.selectedMacroKeys[scope]
    local function KeyFor(index) local name,_,body=GetMacroInfo(index); return name and ((name or "").."\031"..(body or "")) or nil end
    if not remembered or MacroScopeForIndex(remembered)~=scope or (rememberedKey and KeyFor(remembered)~=rememberedKey) then
        remembered=nil
        if rememberedKey then
            local base,count=self:GetMacroBank()
            for bankIndex=1,count do local actualIndex=base+bankIndex; if KeyFor(actualIndex)==rememberedKey then remembered=actualIndex break end end
        end
    end
    if remembered and GetMacroInfo(remembered)~=nil then self:SelectMacro(remembered) else self:SelectMacro(nil) end
    self:RefreshMacroList()
end

function Spellbook:CreateTab(parent, id, text, x, width)
    local button=CreateFrame("Button",nil,parent,"BackdropTemplate"); button:SetSize(width,28); button:SetPoint("TOPLEFT",x,-72); Surface(button,COLORS.inset)
    button.label=Label(button,text,"GameFontNormalSmall"); button.label:SetPoint("CENTER")
    button:SetScript("OnClick",function() Spellbook:SelectMode(id) end); self.tabs[id]=button
end

function Spellbook:ShowMacroTemplates()
    if not self.selectedMacro and not self.newMacroDraft then self:CreateNewMacro() end
    if self.templatePanel then self.templatePanel:Show() end
end

function Spellbook:ApplyMacroTemplate(template)
    if not template then return end
    self.macroEditor:SetText(template.body)
    self.macroEditor:SetCursorPosition(#template.body)
    self.macroEditor:SetFocus()
    self.templatePanel:Hide()
end

function Spellbook:CreateMacroTemplatePanel(parent)
    local panel=CreateFrame("Frame",nil,parent,"BackdropTemplate"); panel:SetAllPoints(); panel:SetFrameLevel(parent:GetFrameLevel()+30); Surface(panel,COLORS.background); panel:Hide(); self.templatePanel=panel
    local title=Label(panel,"MACRO STARTERS","GameFontNormal"); title:SetPoint("TOPLEFT",14,-14)
    local hint=Label(panel,"Choose a safe starting point, then replace the capitalised placeholders.","GameFontNormalSmall"); hint:SetPoint("TOPLEFT",14,-38); hint:SetTextColor(unpack(COLORS.muted))
    local close=AUI:CreateButton(panel); close:SetSize(62,22); close:SetPoint("TOPRIGHT",-12,-10); close:SetText("Close"); close:SetScript("OnClick",function() panel:Hide() end)
    for index,template in ipairs(MACRO_TEMPLATES) do
        local chosenTemplate=template
        local button=CreateFrame("Button",nil,panel,"BackdropTemplate"); button:SetSize(560,44); button:SetPoint("TOPLEFT",14,-68-(index-1)*48); Surface(button,COLORS.inset)
        local name=Label(button,template.name,"GameFontHighlight"); name:SetPoint("TOPLEFT",10,-7)
        local preview=Label(button,template.body:gsub("\n","  •  "),"GameFontNormalSmall"); preview:SetPoint("TOPLEFT",10,-25); preview:SetWidth(536); preview:SetJustifyH("LEFT"); preview:SetTextColor(unpack(COLORS.muted))
        button:SetScript("OnClick",function() Spellbook:ApplyMacroTemplate(chosenTemplate) end)
    end
end

function Spellbook:RefreshMacroBackups()
    if not self.backupPanel then return end
    local backups=Settings().macroBackups; self.backupScroll:SetItemCount(#backups); self.backupOffset=self.backupScroll:GetItemOffset()
    for index,row in ipairs(self.backupRows) do
        self.backupScroll:PlaceItem(row,index)
        local backupIndex=self.backupOffset+index; local backup=backups[backupIndex]
        row.backupIndex=backup and backupIndex or nil; row:SetShown(backup~=nil)
        if backup then
            local visibleName=strtrim(backup.name or ""); if visibleName=="" then visibleName="Untitled macro" end
            row.name:SetText(visibleName)
            row.meta:SetText((backup.scope=="account" and "Account" or "Character").."  •  "..(backup.reason or "Saved").."  •  "..date("%d %b %H:%M",backup.savedAt or time()))
            row.icon:SetTexture(backup.icon or 134400)
        end
    end
    self.backupCount:SetFormattedText("%d recovery point%s",#backups,#backups==1 and "" or "s")
end

function Spellbook:ShowMacroBackups()
    self.backupScroll:ScrollTo(0,true); self:RefreshMacroBackups(); self.backupPanel:Show()
end

function Spellbook:CreateMacroBackupPanel(parent)
    local panel=CreateFrame("Frame",nil,parent,"BackdropTemplate"); panel:SetAllPoints(); panel:SetFrameLevel(parent:GetFrameLevel()+30); Surface(panel,COLORS.background); panel:Hide(); panel:EnableMouseWheel(true); self.backupPanel=panel; self.backupRows={}
    local backupScroll=AUI:CreateListScroll(panel,41,1,function() Spellbook:RefreshMacroBackups() end); backupScroll:SetPoint("TOPLEFT",14,-66); backupScroll:SetPoint("BOTTOMRIGHT",-14,14); self.backupScroll=backupScroll
    panel:SetScript("OnMouseWheel",function(_,delta) backupScroll:GetScript("OnMouseWheel")(backupScroll,delta) end)
    local title=Label(panel,"MACRO HISTORY","GameFontNormal"); title:SetPoint("TOPLEFT",14,-14)
    local count=Label(panel,"0 recovery points","GameFontNormalSmall"); count:SetPoint("TOPLEFT",14,-38); count:SetTextColor(unpack(COLORS.muted)); self.backupCount=count
    local close=AUI:CreateButton(panel); close:SetSize(62,22); close:SetPoint("TOPRIGHT",-12,-10); close:SetText("Close"); close:SetScript("OnClick",function() panel:Hide() end)
    for index=1,13 do
        local row=CreateFrame("Button",nil,backupScroll.content,"BackdropTemplate"); row:SetSize(560,38); Surface(row,COLORS.inset)
        row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(28,28); row.icon:SetPoint("LEFT",5,0); row.icon:SetTexCoord(0.08,0.92,0.08,0.92)
        row.name=Label(row,"","GameFontHighlightSmall"); row.name:SetPoint("TOPLEFT",row.icon,"TOPRIGHT",8,-1)
        row.meta=Label(row,"","GameFontNormalSmall"); row.meta:SetPoint("BOTTOMLEFT",row.icon,"BOTTOMRIGHT",8,1); row.meta:SetTextColor(unpack(COLORS.muted))
        local restore=Label(row,"Restore copy","GameFontNormalSmall"); restore:SetPoint("RIGHT",-10,0); local ar,ag,ab=AccentColor(); restore:SetTextColor(ar,ag,ab,1)
        row:SetScript("OnClick",function(button) Spellbook:RestoreMacroBackup(button.backupIndex) end)
        row:SetScript("OnEnter",function(button) local backup=button.backupIndex and Settings().macroBackups[button.backupIndex]; if backup then GameTooltip:SetOwner(button,"ANCHOR_RIGHT"); GameTooltip:AddLine(strtrim(backup.name or "")~="" and backup.name or "Untitled macro",1,1,1); GameTooltip:AddLine(backup.body~="" and backup.body or "(empty macro)",0.8,0.8,0.85,true); GameTooltip:AddLine("Click to restore as a new copy",0.35,0.85,0.45); GameTooltip:Show() end end); row:SetScript("OnLeave",GameTooltip_Hide)
        self.backupRows[index]=row
    end
end

function Spellbook:CreateMacroView(parent)
    local view=CreateFrame("Frame",nil,parent); view:SetPoint("TOPLEFT",18,-110); view:SetPoint("BOTTOMRIGHT",-18,18); view:Hide()
    self.macroView=view; self.macroScope=Settings().state.macroScope or "character"; self.macroOffset=0; self.macroRows={}; self.suggestionRows={}

    local account=CreateFrame("Button",nil,view,"BackdropTemplate"); account:SetSize(86,25); account:SetPoint("TOPLEFT"); Surface(account,COLORS.inset)
    account.label=Label(account,"Account","GameFontNormalSmall"); account.label:SetPoint("CENTER")
    local character=CreateFrame("Button",nil,view,"BackdropTemplate"); character:SetSize(86,25); character:SetPoint("LEFT",account,"RIGHT",5,0); Surface(character,COLORS.inset)
    character.label=Label(character,"Character","GameFontNormalSmall"); character.label:SetPoint("CENTER")
    self.macroScopeButtons={account=account,character=character}
    account:SetScript("OnClick",function() Spellbook:SetMacroScope("account") end); character:SetScript("OnClick",function() Spellbook:SetMacroScope("character") end)
    local count=Label(view,"0 / 0","GameFontNormalSmall"); count:SetPoint("TOPRIGHT",-414,-8); count:SetTextColor(unpack(COLORS.muted)); self.macroCount=count

    local macroSearch=CreateFrame("EditBox",nil,view,"SearchBoxTemplate"); macroSearch:SetSize(177,24); macroSearch:SetPoint("TOPLEFT",0,-34); macroSearch:SetText(Settings().state.macroSearch or ""); self.macroSearch=macroSearch; self.macroSearchText=macroSearch:GetText()
    macroSearch:SetScript("OnTextChanged",function(box) SearchBoxTemplate_OnTextChanged(box); Spellbook.macroSearchText=box:GetText(); Settings().state.macroSearch=box:GetText(); Spellbook.macroOffset=0; Spellbook:RefreshMacroList() end)

    local list=CreateFrame("Frame",nil,view,"BackdropTemplate"); list:SetPoint("TOPLEFT",0,-64); list:SetSize(177,352); Surface(list,COLORS.surface); list:EnableMouseWheel(true)
    local macroListScroll=AUI:CreateListScroll(list,34,1,function() Spellbook:RefreshMacroList() end)
    macroListScroll:SetPoint("TOPLEFT",6,-6); macroListScroll:SetPoint("BOTTOMRIGHT",-2,6); self.macroListScroll=macroListScroll
    list:SetScript("OnMouseWheel",function(_,delta) macroListScroll:GetScript("OnMouseWheel")(macroListScroll,delta) end)
    for index=1,12 do
        local row=CreateFrame("Button",nil,macroListScroll.content,"BackdropTemplate"); row:SetSize(157,32); Surface(row,COLORS.inset)
        row:RegisterForDrag("LeftButton"); row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(24,24); row.icon:SetPoint("LEFT",4,0); row.icon:SetTexCoord(0.08,0.92,0.08,0.92)
        row.label=Label(row,"","GameFontHighlightSmall"); row.label:SetPoint("LEFT",row.icon,"RIGHT",7,0); row.label:SetPoint("RIGHT",-4,0); row.label:SetJustifyH("LEFT")
        row:SetScript("OnClick",function(button) Spellbook:SelectMacro(button.macroIndex) end)
        row:SetScript("OnDragStart",function(button) if button.macroIndex then PickupMacro(button.macroIndex) end end)
        self.macroRows[index]=row
    end

    local newButton=AUI:CreateButton(view); newButton:SetSize(72,24); newButton:SetPoint("BOTTOMLEFT",0,0); newButton:SetText("New"); newButton:SetScript("OnClick",function() Spellbook:CreateNewMacro() end); self.newMacroButton=newButton
    local templatesButton=AUI:CreateButton(view); templatesButton:SetSize(82,24); templatesButton:SetPoint("LEFT",newButton,"RIGHT",5,0); templatesButton:SetText("Templates"); templatesButton:SetScript("OnClick",function() Spellbook:ShowMacroTemplates() end)
    local backupsButton=AUI:CreateButton(view); backupsButton:SetSize(76,24); backupsButton:SetPoint("LEFT",templatesButton,"RIGHT",5,0); backupsButton:SetText("History"); backupsButton:SetScript("OnClick",function() Spellbook:ShowMacroBackups() end)

    local details=CreateFrame("Frame",nil,view); details:SetPoint("TOPLEFT",194,0); details:SetPoint("BOTTOMRIGHT"); self.macroDetails=details
    local iconButton=CreateFrame("Button",nil,details,"BackdropTemplate"); iconButton:SetSize(42,42); iconButton:SetPoint("TOPLEFT"); Surface(iconButton,COLORS.inset); iconButton:SetScript("OnClick",function() Spellbook:ShowMacroIconPicker() end)
    local icon=iconButton:CreateTexture(nil,"ARTWORK"); icon:SetPoint("TOPLEFT",3,-3); icon:SetPoint("BOTTOMRIGHT",-3,3); icon:SetTexture(134400); icon:SetTexCoord(0.08,0.92,0.08,0.92); self.macroIcon=icon
    iconButton:SetScript("OnEnter",function(self) GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:AddLine("Choose macro icon",1,1,1); GameTooltip:Show() end); iconButton:SetScript("OnLeave",GameTooltip_Hide)
    local name=CreateFrame("EditBox",nil,details,"InputBoxTemplate"); name:SetSize(342,28); name:SetPoint("LEFT",iconButton,"RIGHT",10,0); name:SetAutoFocus(false); name:SetMaxLetters(16); self.macroName=name
    name:SetScript("OnTextChanged",function() if not Spellbook.loadingMacro then Spellbook:MarkMacroDirty(); Spellbook:RefreshMacroList() end end)
    name:SetScript("OnEnterPressed",function(box) box:ClearFocus() end); name:SetScript("OnEscapePressed",function(box) box:ClearFocus() end)
    local previewIcon=details:CreateTexture(nil,"ARTWORK"); previewIcon:SetSize(16,16); previewIcon:SetPoint("TOPLEFT",name,"BOTTOMLEFT",3,-1); previewIcon:SetTexCoord(0.08,0.92,0.08,0.92); self.macroPreviewIcon=previewIcon
    local previewHit=CreateFrame("Button",nil,details); previewHit:SetAllPoints(previewIcon); previewHit:SetScript("OnEnter",function(button) if Spellbook.macroPreviewSpellID then GameTooltip:SetOwner(button,"ANCHOR_RIGHT"); GameTooltip:SetSpellByID(Spellbook.macroPreviewSpellID); GameTooltip:Show() end end); previewHit:SetScript("OnLeave",GameTooltip_Hide)
    local previewText=Label(details,"Character macro","GameFontNormalSmall"); previewText:SetPoint("LEFT",previewIcon,"RIGHT",5,0); previewText:SetTextColor(unpack(COLORS.muted)); self.macroPreviewText=previewText

    local editorBackground=CreateFrame("Frame",nil,details,"BackdropTemplate"); editorBackground:SetPoint("TOPLEFT",0,-51); editorBackground:SetSize(410,154); Surface(editorBackground,COLORS.inset)
    local editorScroll=AUI:CreateSmoothScrollFrame(editorBackground); editorScroll:SetPoint("TOPLEFT",8,-8); editorScroll:SetPoint("BOTTOMRIGHT",-4,8)
    local editor=CreateFrame("EditBox",nil,editorScroll); editor:SetMultiLine(true); editor:SetAutoFocus(false); editor:EnableMouse(true); editor:SetFontObject("ChatFontNormal"); editor:SetTextColor(unpack(COLORS.text)); editor:SetWidth(366); editor:SetHeight(138); editor:SetMaxLetters(255); editor:SetCountInvisibleLetters(true); editor:SetTextInsets(2,2,2,2); editorScroll:SetScrollChild(editor); self.macroEditor=editor
    editorScroll:EnableMouse(true); editorScroll:SetScript("OnMouseDown",function() editor:SetFocus() end)
    editor:SetScript("OnTextChanged",function(box)
        if not Spellbook.loadingMacro then Spellbook:MarkMacroDirty(); Spellbook:RefreshMacroList() end
        Spellbook:UpdateMacroSuggestions(); Spellbook:AnalyseMacro()
    end)
    AUI:ConfigureScrollingEditBox(editor,editorScroll,138)
    editor:SetAltArrowKeyMode(false)
    editor:HookScript("OnCursorChanged",function() Spellbook:UpdateMacroSuggestions() end)
    editor:SetScript("OnEscapePressed",function(box) if Spellbook.macroSuggestions:IsShown() then Spellbook.macroSuggestions:Hide() else box:ClearFocus() end end)
    editor:SetScript("OnTabPressed",function() Spellbook:AcceptSelectedMacroSuggestion() end)
    editor:SetScript("OnArrowPressed",function(_,key)
        if key=="UP" then Spellbook:MoveMacroSuggestion(-1) elseif key=="DOWN" then Spellbook:MoveMacroSuggestion(1) end
    end)
    -- Leave Enter to the native multiline editor so it always creates a new line.
    local status=Label(details,"0 / 255","GameFontNormalSmall"); status:SetPoint("TOPRIGHT",editorBackground,"BOTTOMRIGHT",0,-5); status:SetTextColor(unpack(COLORS.muted)); self.macroStatus=status

    local suggestions=CreateFrame("Frame",nil,details,"BackdropTemplate"); suggestions:SetPoint("TOPLEFT",editorBackground,"BOTTOMLEFT",0,-22); suggestions:SetSize(410,170); Surface(suggestions,COLORS.surface); suggestions:EnableMouseWheel(true); self.macroSuggestions=suggestions
    local suggestionScroll=AUI:CreateListScroll(suggestions,33,1,function() Spellbook:UpdateMacroSuggestions() end)
    suggestionScroll:SetPoint("TOPLEFT",8,-28); suggestionScroll:SetPoint("BOTTOMRIGHT",-2,8); self.suggestionScroll=suggestionScroll
    suggestions:SetScript("OnMouseWheel",function(_,delta) suggestionScroll:GetScript("OnMouseWheel")(suggestionScroll,delta) end)
    local suggestionHint=Label(details,"Type / for commands, # for directives, [ for conditions, or a spell after /cast or #showtooltip.","GameFontNormalSmall"); suggestionHint:SetPoint("TOPLEFT",editorBackground,"BOTTOMLEFT",8,-39); suggestionHint:SetWidth(390); suggestionHint:SetJustifyH("LEFT"); suggestionHint:SetTextColor(unpack(COLORS.muted)); self.suggestionHint=suggestionHint
    local suggestionTitle=Label(suggestions,"SUGGESTIONS  •  ↑↓ SELECT  •  TAB TO INSERT","GameFontNormalSmall"); suggestionTitle:SetPoint("TOPLEFT",8,-7); suggestionTitle:SetTextColor(unpack(COLORS.muted)); self.suggestionTitle=suggestionTitle
    for index=1,6 do
        local suggestionIndex=index
        local row=CreateFrame("Button",nil,suggestionScroll.content,"BackdropTemplate"); row:SetSize(388,30); Surface(row,COLORS.inset)
        row.command=Label(row,"","GameFontHighlightSmall"); row.command:SetPoint("LEFT",8,0); row.command:SetWidth(126); row.command:SetJustifyH("LEFT")
        local r,g,b=AccentColor(); row.command:SetTextColor(r,g,b,1)
        row.detail=Label(row,"","GameFontNormalSmall"); row.detail:SetPoint("LEFT",row.command,"RIGHT",8,0); row.detail:SetPoint("RIGHT",-6,0); row.detail:SetJustifyH("LEFT"); row.detail:SetTextColor(unpack(COLORS.muted))
        row:SetScript("OnClick",function(button) Spellbook.suggestionSelected=(Spellbook.suggestionOffset or 0)+suggestionIndex; Spellbook:AcceptMacroSuggestion(button.suggestion) end); self.suggestionRows[index]=row
    end
    local warning=Label(details,"No obvious syntax problems","GameFontNormalSmall"); warning:SetPoint("TOPLEFT",suggestions,"BOTTOMLEFT",4,-6); warning:SetWidth(404); warning:SetJustifyH("LEFT"); self.macroWarning=warning
    local warningHit=CreateFrame("Button",nil,details); warningHit:SetPoint("TOPLEFT",warning,"TOPLEFT",0,4); warningHit:SetSize(404,20); warningHit:SetScript("OnEnter",function(button) if #(Spellbook.macroWarnings or {})>0 then GameTooltip:SetOwner(button,"ANCHOR_RIGHT"); GameTooltip:AddLine("Macro checks",1,1,1); for _,message in ipairs(Spellbook.macroWarnings) do GameTooltip:AddLine("• "..message,1,0.55,0.25,true) end; GameTooltip:Show() end end); warningHit:SetScript("OnLeave",GameTooltip_Hide)
    local empty=Label(view,"Select a macro to edit, or create a new one.","GameFontNormal"); empty:SetPoint("TOPLEFT",214,-20); empty:SetTextColor(unpack(COLORS.muted)); self.macroEmpty=empty

    local save=AUI:CreateButton(details); save:SetSize(82,24); save:SetPoint("BOTTOMRIGHT",0,0); save:SetText("Save"); save:SetScript("OnClick",function() Spellbook:SaveMacro() end); self.saveMacroButton=save
    local delete=AUI:CreateButton(details); delete:SetSize(82,24); delete:SetPoint("RIGHT",save,"LEFT",-7,0); delete:SetText("Delete")
    delete:SetScript("OnClick",function() StaticPopup_Show("PROJECT_RUTHLESS_DELETE_MACRO") end); self.deleteMacroButton=delete
    local revert=AUI:CreateButton(details); revert:SetSize(70,24); revert:SetPoint("RIGHT",delete,"LEFT",-7,0); revert:SetText("Revert"); revert:SetScript("OnClick",function() Spellbook:RevertMacro() end); self.revertMacroButton=revert
    local duplicate=AUI:CreateButton(details); duplicate:SetSize(76,24); duplicate:SetPoint("BOTTOMLEFT",0,30); duplicate:SetText("Duplicate"); duplicate:SetScript("OnClick",function() Spellbook:DuplicateSelectedMacro() end); self.duplicateMacroButton=duplicate
    local move=AUI:CreateButton(details); move:SetSize(126,24); move:SetPoint("LEFT",duplicate,"RIGHT",6,0); move:SetText("Move to Account"); move:SetScript("OnClick",function() Spellbook:MoveSelectedMacro() end); self.moveMacroButton=move
    if not StaticPopupDialogs.PROJECT_RUTHLESS_DELETE_MACRO then
        StaticPopupDialogs.PROJECT_RUTHLESS_DELETE_MACRO={text="Delete this macro?",button1=DELETE,button2=CANCEL,OnAccept=function() Spellbook:DeleteSelectedMacro() end,timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3}
    end
    self:CreateMacroIconPicker(view)
    self:CreateMacroTemplatePanel(view); self:CreateMacroBackupPanel(view)
    self:SetMacroScope(self.macroScope)
end

function Spellbook:Create()
    if self.frame then return end
    local frame=CreateFrame("Frame","ProjectRuthlessSpellbookFrame",UIParent,"BackdropTemplate")
    frame:SetSize(700,650); frame:SetPoint("CENTER"); frame:SetFrameStrata("DIALOG"); frame:SetClampedToScreen(true); frame:SetMovable(true); frame:EnableMouse(true)
    Surface(frame,COLORS.background)
    local header=CreateFrame("Frame",nil,frame,"BackdropTemplate"); header:SetPoint("TOPLEFT",1,-1); header:SetPoint("TOPRIGHT",-1,-1); header:SetHeight(58); Surface(header,COLORS.surface,{0,0,0,0})
    header:EnableMouse(true); header:RegisterForDrag("LeftButton"); header:SetScript("OnDragStart",function() frame:StartMoving() end); header:SetScript("OnDragStop",function() frame:StopMovingOrSizing() end)
    local r,g,b=AccentColor(); local line=header:CreateTexture(nil,"ARTWORK"); line:SetColorTexture(r,g,b,1); line:SetPoint("BOTTOMLEFT"); line:SetPoint("BOTTOMRIGHT"); line:SetHeight(2)
    local mark=Label(header,"PR","GameFontNormalHuge"); mark:SetPoint("LEFT",16,0); mark:SetTextColor(r,g,b,1)
    local title=Label(header,"SPELLBOOK","GameFontNormalLarge"); title:SetPoint("LEFT",mark,"RIGHT",16,0)
    local close=CreateFrame("Button",nil,header); close:SetSize(38,38); close:SetPoint("RIGHT",-4,0); close.label=Label(close,"×","GameFontNormalHuge"); close.label:SetPoint("CENTER",0,1); close:SetScript("OnClick",function() frame:Hide() end)
    local className=UnitClass("player")
    self:CreateTab(frame,"general","General",18,90); self:CreateTab(frame,"class",className or "Class",112,110); self:CreateTab(frame,"professions","Professions",226,110); self:CreateTab(frame,"macros","Macros",340,90)
    local search=CreateFrame("EditBox",nil,frame,"SearchBoxTemplate"); search:SetSize(250,26); search:SetPoint("TOPRIGHT",-18,-73); search:SetText(Settings().state.searchText or ""); self.searchBox=search; self.searchText=search:GetText()
    search:SetScript("OnTextChanged",function(box) SearchBoxTemplate_OnTextChanged(box); Spellbook.searchText=box:GetText(); Settings().state.searchText=box:GetText(); Spellbook.scroll.targetScroll=0; Spellbook.scroll:SetVerticalScroll(0); Spellbook:Refresh() end)
    local filter=AUI:CreateButton(frame); filter:SetSize(150,24); filter:SetPoint("TOPLEFT",18,-108); filter:RegisterForClicks("LeftButtonUp","RightButtonUp"); filter:SetScript("OnClick",function(_,mouseButton) Spellbook:CycleSpellFilter(mouseButton=="RightButton" and -1 or 1) end); self.filterButton=filter; self.spellFilter=Settings().state.spellFilter or "all"
    filter:SetScript("OnEnter",function(button) GameTooltip:SetOwner(button,"ANCHOR_RIGHT"); GameTooltip:AddLine("Spell filter",1,1,1); GameTooltip:AddLine("Left-click forward, right-click backward.",0.7,0.7,0.75); GameTooltip:Show() end); filter:SetScript("OnLeave",GameTooltip_Hide)
    local pinHint=Label(frame,"Right-click a spell to pin it","GameFontNormalSmall"); pinHint:SetPoint("LEFT",filter,"RIGHT",10,0); pinHint:SetTextColor(unpack(COLORS.muted)); self.pinHint=pinHint
    local scroll=AUI:CreateSmoothScrollFrame(frame); scroll:SetPoint("TOPLEFT",18,-140); scroll:SetPoint("BOTTOMRIGHT",-18,18)
    local content=CreateFrame("Frame",nil,scroll); content:SetWidth(636); content:SetHeight(1); scroll:SetScrollChild(content)
    self.scroll,self.content=scroll,content
    self.empty=Label(frame,"No spells match this search and filter.","GameFontNormal"); self.empty:SetPoint("TOPLEFT",28,-152); self.empty:SetTextColor(unpack(COLORS.muted)); self.empty:Hide()
    self:CreateMacroView(frame)
    frame:SetScript("OnShow",function() Spellbook:Refresh(); C_Timer.After(0,function() local value=Settings().state.scroll[Spellbook.mode] or 0; Spellbook.scroll.targetScroll=value; Spellbook.scroll:SetVerticalScroll(value) end); if MultiActionBar_ShowAllGrids then MultiActionBar_ShowAllGrids(ACTION_BUTTON_SHOW_GRID_REASON_SPELLCOLLECTION) end; if ProfessionMicroButton and ProfessionMicroButton.SetPushed then ProfessionMicroButton:SetPushed() end; PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN) end)
    frame:SetScript("OnHide",function() Settings().state.scroll[Spellbook.mode]=Spellbook.scroll:GetVerticalScroll(); if MultiActionBar_HideAllGrids then MultiActionBar_HideAllGrids(ACTION_BUTTON_SHOW_GRID_REASON_SPELLCOLLECTION) end; if ProfessionMicroButton and ProfessionMicroButton.SetNormal then ProfessionMicroButton:SetNormal() end; PlaySound(SOUNDKIT.IG_ABILITY_CLOSE) end)
    tinsert(UISpecialFrames,"ProjectRuthlessSpellbookFrame")
    self.frame=frame; AUI:ApplyWindowSettings(); self:SelectMode(Settings().state.mode or "class")
end

function Spellbook:Toggle()
    self:Create(); self.frame:SetShown(not self.frame:IsShown())
end

function Spellbook:Show(mode, searchText)
    self:Create()
    if mode then self:SelectMode(mode) end
    if searchText ~= nil then self.searchBox:SetText(searchText) end
    self.frame:Show(); self.frame:Raise()
end

function Spellbook:SeparateFromTalents()
    if self.playerSpellsHooked or not PlayerSpellsFrame then return end
    self.playerSpellsHooked=true
    local function HideSpellbookTab(frame)
        if not frame.spellBookTabID or not frame.TabSystem then return end
        local separate=ProjectRuthlessDB.spellbook.separateFromTalents
        frame.TabSystem:SetTabShown(frame.spellBookTabID,not separate)
        if separate and frame:GetTab() == frame.spellBookTabID then frame:SetTab(frame.talentTabID or frame.specTabID) end
    end
    hooksecurefunc(PlayerSpellsFrame,"UpdateTabs",HideSpellbookTab); HideSpellbookTab(PlayerSpellsFrame)
end

function Spellbook:InstallMicroButton()
    if self.microButtonInstalled or not ProfessionMicroButton then return end
    self.microButtonInstalled=true
    self.originalToggleProfessionsBook=_G.ToggleProfessionsBook
    _G.ToggleProfessionsBook=function()
        if ProjectRuthlessDB.spellbook.replaceProfessions then Spellbook:Toggle()
        elseif Spellbook.originalToggleProfessionsBook then Spellbook.originalToggleProfessionsBook() end
    end
    if LoadMicroButtonTextures then LoadMicroButtonTextures(ProfessionMicroButton,"Spellbook") end
    if ProfessionMicroButton.FlashContent then pcall(ProfessionMicroButton.FlashContent.SetAtlas,ProfessionMicroButton.FlashContent,"UI-HUD-MicroMenu-Spellbook-Mouseover") end
    ProfessionMicroButton.tooltipText=MicroButtonTooltipText(SPELLBOOK_ABILITIES_BUTTON or "Spellbook", "TOGGLEPROFESSIONBOOK")
    local originalUpdate=ProfessionMicroButton.UpdateMicroButton
    ProfessionMicroButton.UpdateMicroButton=function(button)
        if Spellbook.frame and Spellbook.frame:IsShown() then button:SetPushed()
        elseif originalUpdate then originalUpdate(button) else button:SetNormal() end
    end
end

function Spellbook:InstallPlayerSpellsRedirects()
    if self.playerSpellsRedirected or not PlayerSpellsUtil then return end
    self.playerSpellsRedirected=true
    self.originalOpenToSpellBookTab=PlayerSpellsUtil.OpenToSpellBookTab
    self.originalOpenToSpellBookTabAtSpell=PlayerSpellsUtil.OpenToSpellBookTabAtSpell
    PlayerSpellsUtil.OpenToSpellBookTab=function()
        if ProjectRuthlessDB.spellbook.separateFromTalents then Spellbook:Show("class")
        elseif Spellbook.originalOpenToSpellBookTab then return Spellbook.originalOpenToSpellBookTab() end
    end
    PlayerSpellsUtil.OpenToSpellBookTabAtSpell=function(spellID)
        if not ProjectRuthlessDB.spellbook.separateFromTalents and Spellbook.originalOpenToSpellBookTabAtSpell then return Spellbook.originalOpenToSpellBookTabAtSpell(spellID) end
        local info=C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
        Spellbook:Show("class",info and info.name or "")
        return nil
    end
end

function Spellbook:ApplySettings()
    if self.frame then self:Refresh() end
    if PlayerSpellsFrame and PlayerSpellsFrame.UpdateTabs then PlayerSpellsFrame:UpdateTabs() end
    if ProfessionMicroButton and LoadMicroButtonTextures then LoadMicroButtonTextures(ProfessionMicroButton,ProjectRuthlessDB.spellbook.replaceProfessions and "Spellbook" or "Professions") end
end

function Spellbook:OnPlayerLogin()
    self:InstallMicroButton(); self:InstallPlayerSpellsRedirects(); self:SeparateFromTalents()
    local events=CreateFrame("Frame")
    for _,event in ipairs({"SPELLS_CHANGED","SKILL_LINES_CHANGED","PLAYER_SPECIALIZATION_CHANGED","UPDATE_MACROS","ACTIONBAR_SLOT_CHANGED","UPDATE_BONUS_ACTIONBAR","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED"}) do events:RegisterEvent(event) end
    events:RegisterEvent("ADDON_LOADED")
    events:SetScript("OnEvent",function(_,event,addon)
        if event == "ADDON_LOADED" then
            Spellbook.macroCommandSuggestions=nil
            if addon == "Blizzard_PlayerSpells" then Spellbook:SeparateFromTalents() end
        elseif event == "SPELLS_CHANGED" then Spellbook.spellSuggestions=nil; if Spellbook.frame and Spellbook.frame:IsShown() then C_Timer.After(0,function() Spellbook:Refresh() end) end
        elseif Spellbook.frame and Spellbook.frame:IsShown() then C_Timer.After(0,function() Spellbook:Refresh() end) end
    end)
    self.events=events
end
