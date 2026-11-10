local _,AUI=...
local N={active={},icons=setmetatable({},{__mode="k"}),kinds={},styled=setmetatable({},{__mode="k"})}
AUI:RegisterModule("ForeverNameplateHints",N)
local function read(fn,...)
    if type(fn)~="function"then return end
    local ok,value=pcall(fn,...)
    if ok and not(issecretvalue and issecretvalue(value))then return value end
end
local white="Interface\\Buttons\\WHITE8X8"
local function usable(frame)
    return frame and type(frame)~="function" and type(frame.GetObjectType)=="function" and not(frame.IsForbidden and frame:IsForbidden())
end

local function styleDebuffs(list)
    if not usable(list) then return end
    for _,item in ipairs({list:GetChildren()})do
        local cooldown=usable(item) and item.Cooldown
        if usable(cooldown)then
            cooldown:SetHideCountdownNumbers(false)
            cooldown:SetCountdownFont("GameFontHighlightSmallOutline")
            cooldown:SetMinimumCountdownDuration(0)
        end
    end
end

function N:StylePlate(plate)
    if not usable(plate)then return end
    local unitFrame=plate.UnitFrame
    if not usable(unitFrame)or self.styled[unitFrame]then return end
    local bars=unitFrame.HealthBarsContainer
    local bar=usable(bars) and bars.healthBar or unitFrame.healthBar
    if not usable(bar)or not usable(bar.barTexture)then return end
    self.styled[unitFrame]=true

    local surface=CreateFrame("Frame",nil,bar,"BackdropTemplate")
    surface:SetPoint("TOPLEFT",bar,"TOPLEFT",-1,1)
    surface:SetPoint("BOTTOMRIGHT",bar,"BOTTOMRIGHT",1,-1)
    surface:SetBackdrop({edgeFile=white,edgeSize=1})
    surface:EnableMouse(false)
    local background=bar:CreateTexture(nil,"BACKGROUND")
    background:SetAllPoints(bar)
    background:SetColorTexture(.055,.06,.075,.9)
    local function selection()
        if not usable(bar)then return end
        if read(bar.IsTarget,bar)==true or read(bar.IsFocus,bar)==true then
            local r,g,b=AUI:AccentColor()
            surface:SetBackdropBorderColor(r,g,b,1)
        else
            surface:SetBackdropBorderColor(.20,.21,.25,1)
        end
    end
    local function skin()
        if not usable(bar)then return end
        bar.barTexture:SetTexture(white)
        if usable(bar.bgTexture)then bar.bgTexture:SetAlpha(0)end
        if usable(bar.selectedBorder)then bar.selectedBorder:SetAlpha(0)end
        selection()
    end
    if type(unitFrame.UpdateAnchors)=="function"then hooksecurefunc(unitFrame,"UpdateAnchors",skin)end
    if type(bar.UpdateSelectionBorder)=="function"then hooksecurefunc(bar,"UpdateSelectionBorder",selection)end
    skin()

    local auras=unitFrame.AurasFrame
    if usable(auras)and type(auras.RefreshList)=="function"then
        hooksecurefunc(auras,"RefreshList",function(_,list)
            -- The client owns aura data, source filtering and timing. Style only
            -- the cooldown widgets in its personal debuff row.
            if usable(auras)and list==auras.DebuffListFrame then styleDebuffs(list)end
        end)
        styleDebuffs(auras.DebuffListFrame)
    end
end

function N:InitializeDebuffs()
    local char=ProjectRuthlessCharDB
    if not char or char.ruiNameplateDebuffsInitialized or InCombatLockdown()or not C_CVar or not Enum then return end
    local npc,player=Enum.NamePlateEnemyNpcAuraDisplay,Enum.NamePlateEnemyPlayerAuraDisplay
    if not npc or not player then return end
    local showPersonal=read(C_CVar.GetCVarBool,"nameplateShowAllPersonalAuras")
    local npcEnabled=read(C_CVar.GetCVarBitfield,"nameplateEnemyNpcAuraDisplay",npc.Debuffs)
    local playerEnabled=read(C_CVar.GetCVarBitfield,"nameplateEnemyPlayerAuraDisplay",player.Debuffs)
    if showPersonal==false then showPersonal=read(C_CVar.SetCVar,"nameplateShowAllPersonalAuras","1")end
    if npcEnabled==false then npcEnabled=read(C_CVar.SetCVarBitfield,"nameplateEnemyNpcAuraDisplay",npc.Debuffs,true)end
    if playerEnabled==false then playerEnabled=read(C_CVar.SetCVarBitfield,"nameplateEnemyPlayerAuraDisplay",player.Debuffs,true)end
    if showPersonal and npcEnabled and playerEnabled then char.ruiNameplateDebuffsInitialized=true end
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
    self:InitializeDebuffs()
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
            if plate then self.active[unit]=plate;self:StylePlate(plate);self:Draw(unit,plate)end
        elseif event=="NAME_PLATE_UNIT_REMOVED"then
            local plate=self.active[unit];local icon=plate and self.icons[plate];if icon then icon:Hide()end;self.active[unit]=nil
        elseif event=="UNIT_CLASSIFICATION_CHANGED"then if self.active[unit]then self:Draw(unit,self.active[unit])end
        elseif event=="PLAYER_REGEN_DISABLED"then self.resting=true;self.revision=(self.revision or 0)+1
        elseif event=="PLAYER_REGEN_ENABLED"then self:InitializeDebuffs();local revision=self.revision;C_Timer.After(3,function()if revision~=self.revision or InCombatLockdown()then return end;self.resting=nil;if self.pending then self:Build()end end)end
    end)
    self:Build()
    for _,plate in ipairs(read(C_NamePlate and C_NamePlate.GetNamePlates)or {})do
        local unit=read(plate.GetUnit,plate)
        if type(unit)=="string"then self.active[unit]=plate;self:StylePlate(plate);self:Draw(unit,plate)end
    end
end
