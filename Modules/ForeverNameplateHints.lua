local _,AUI=...
local N={active={},icons=setmetatable({},{__mode="k"}),kinds={}}
AUI:RegisterModule("ForeverNameplateHints",N)
local function read(fn,...)
    if type(fn)~="function"then return end
    local ok,value=pcall(fn,...)
    if ok and not(issecretvalue and issecretvalue(value))then return value end
end
local textures={loot="Interface\\Icons\\INV_Misc_Bag_10",kill="Interface\\Icons\\INV_Sword_04",elite="Interface\\TargetingFrame\\UI-TargetingFrame-Skull"}
function N:Build()
    if InCombatLockdown()or self.resting then self.pending=true;return end
    self.pending=nil;self.kinds={}
    local locations=AUI.modules.QuestLocations;local index=locations and locations.tooltipIndex or {}
    local objectives={}
    for npc,rows in pairs(index)do
        for _,row in pairs(rows)do
            if objectives[row.id]==nil then objectives[row.id]=read(C_QuestLog.GetQuestObjectives,row.id)or {}end
            for _,objective in ipairs(objectives[row.id])do
                local objectID=read(function()return objective.objectID end)
                local finished=read(function()return objective.finished end)
                local kind=read(function()return objective.type end)
                if finished==false and objectID==(row.item or npc)then
                    if row.item and (kind==nil or kind=="item")then self.kinds[npc]="loot"
                    elseif not row.item and kind~="item"and self.kinds[npc]~="loot"then self.kinds[npc]="kill"end
                end
            end
        end
    end
    for unit,plate in pairs(self.active)do self:Draw(unit,plate)end
end
function N:Kind(unit)
    local classification=read(UnitClassification,unit)
    local elite=classification=="elite"or classification=="rareelite"or classification=="worldboss"
    local guid=read(UnitGUID,unit);local kind
    if type(guid)=="string"then
        local npc=guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")or guid:match("^Vehicle%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
        kind=npc and self.kinds[tonumber(npc)]
    end
    return kind=="loot"and "loot"or elite and "elite"or kind
end
function N:Draw(unit,plate)
    local icon=self.icons[plate]
    local kind=self:Kind(unit)
    if not kind or not ProjectRuthlessDB.questWorkspace.enabled then if icon then icon:Hide()end;return end
    local unitFrame=plate.UnitFrame
    if not unitFrame or type(unitFrame.GetObjectType)~="function"or (unitFrame.IsForbidden and unitFrame:IsForbidden())then return end
    local anchor=unitFrame.healthBar or unitFrame
    if not icon then
        icon=CreateFrame("Frame",nil,unitFrame);icon:SetSize(18,18);icon:EnableMouse(false)
        icon.texture=icon:CreateTexture(nil,"OVERLAY");icon.texture:SetAllPoints(icon)
        self.icons[plate]=icon
    elseif icon:GetParent()~=unitFrame then icon:SetParent(unitFrame)end
    icon:ClearAllPoints();icon:SetPoint("RIGHT",anchor,"LEFT",-5,0)
    local locations=AUI.modules.QuestLocations
    icon.texture:SetTexture(locations and type(locations.ObjectiveTexture)=="function"and locations:ObjectiveTexture(kind)or textures[kind]);icon.texture:SetTexCoord(0,1,0,1);icon:Show()
end
function N:OnPlayerLogin()
    if not AUI.isForever then return end
    local locations=AUI.modules.QuestLocations
    if locations then
        hooksecurefunc(locations,"UpdateTooltipIndex",function()self:Build()end)
        hooksecurefunc(locations,"SetEnabled",function()for unit,plate in pairs(self.active)do self:Draw(unit,plate)end end)
    end
    local events=CreateFrame("Frame");self.events=events
    for _,event in ipairs({"NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED","UNIT_CLASSIFICATION_CHANGED","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED"})do events:RegisterEvent(event)end
    events:SetScript("OnEvent",function(_,event,unit)
        if event=="NAME_PLATE_UNIT_ADDED"then
            local plate=read(C_NamePlate and C_NamePlate.GetNamePlateForUnit,unit)
            if plate then self.active[unit]=plate;self:Draw(unit,plate)end
        elseif event=="NAME_PLATE_UNIT_REMOVED"then
            local plate=self.active[unit];local icon=plate and self.icons[plate];if icon then icon:Hide()end;self.active[unit]=nil
        elseif event=="UNIT_CLASSIFICATION_CHANGED"then if self.active[unit]then self:Draw(unit,self.active[unit])end
        elseif event=="PLAYER_REGEN_DISABLED"then self.resting=true;self.revision=(self.revision or 0)+1
        elseif event=="PLAYER_REGEN_ENABLED"then local revision=self.revision;C_Timer.After(3,function()if revision~=self.revision or InCombatLockdown()then return end;self.resting=nil;if self.pending then self:Build()end end)end
    end)
    self:Build()
    for _,plate in ipairs(read(C_NamePlate and C_NamePlate.GetNamePlates)or {})do
        local unit=read(plate.GetUnit,plate)
        if type(unit)=="string"then self.active[unit]=plate;self:Draw(unit,plate)end
    end
end
