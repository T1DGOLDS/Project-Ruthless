local _,AUI=...
local H={registered={}}
AUI:RegisterModule("ForeverHUD",H)
local hudAddonFamilies={"Blizzard_ActionBar","Blizzard_UnitFrame","Blizzard_StatusTrackingBar","Blizzard_Minimap","Blizzard_BuffFrame","Blizzard_ChatFrame","Blizzard_CastingBar","Blizzard_AuraContainer","Blizzard_CompactRaid","ProjectRuthless_"}
function H:IsRelevantAddon(name)
    if type(name)~="string"then return true end
    for _,family in ipairs(hudAddonFamilies)do
        if name:sub(1,#family)==family then return true end
    end
    return false
end
local specs={
 {"minimap","Minimap",{"MinimapCluster"}},
 {"player","Player frame",{"PlayerFrame"}}, {"target","Target frame",{"TargetFrame"}},
 {"focus","Focus frame",{"FocusFrame"}}, {"pet","Pet frame",{"PetFrame"}},
 {"castplayer","Player cast bar",{"PlayerCastingBarFrame","CastingBarFrame"}},
 {"casttarget","Target cast bar",{"TargetFrameSpellBar"}}, {"castfocus","Focus cast bar",{"FocusFrameSpellBar"}},
 {"castpet","Pet cast bar",{"PetCastingBarFrame"}},
 {"xp","XP / reputation bars",{"MainStatusTrackingBarContainer","StatusTrackingBarManager","MainMenuExpBar"}},
 {"reputation","Reputation bar",{"SecondaryStatusTrackingBarContainer","ReputationWatchBar"}},
 {"bar1","Main action bar",{"MainActionBar","MainMenuBar"}},
 {"bar2","Bottom-left action bar",{"MultiBarBottomLeft"}}, {"bar3","Bottom-right action bar",{"MultiBarBottomRight"}},
 {"bar4","Right action bar",{"MultiBarRight"}}, {"bar5","Left action bar",{"MultiBarLeft"}},
 {"bar6","Action bar 6",{"MultiBar5"}}, {"bar7","Action bar 7",{"MultiBar6"}}, {"bar8","Action bar 8",{"MultiBar7"}},
 {"petbar","Pet action bar",{"PetActionBar","PetActionBarFrame"}}, {"stancebar","Stance bar",{"StanceBar","StanceBarFrame"}},
 {"buffs","Buffs",{"BuffFrame"}}, {"debuffs","Debuffs",{"DebuffFrame"}},
 {"raid","Raid frames",{"CompactRaidFrameContainer"}},
 {"micro","Micro menu",{"MicroMenu","MicroButtonAndBagsBar"}}, {"bags","Bag buttons",{"BagsBar","MainMenuBarBackpackButton"}},
}
specs[#specs+1]={"chat1","Chat dock",{"ChatFrame1"}}
local function real(frame)return frame and (type(frame)=="table"or type(frame)=="userdata")and type(frame.GetCenter)=="function"end
function H:Queue(id)
    if self.applying then return end
    local saved=ProjectRuthlessCharDB.layoutEditor
    if (not saved or not saved.elements or not saved.elements[id])and not (self.registered[id]and self.registered[id].ruiUnitStyled==true)then return end
    self.pending=self.pending or {};self.pending[id]=true
    if InCombatLockdown()or self.resting or self.queued then return end
    self.queued=true
    C_Timer.After(.1,function()self.queued=nil;self:Drain()end)
end
function H:Drain()
    if InCombatLockdown()or self.resting then return end
    local pending=self.pending or {};self.pending={}
    self.applying=true
    for id in pairs(pending)do
        local store=ProjectRuthlessCharDB.layoutEditor
        if store and store.elements[id]then AUI.modules.LayoutEditor:Apply(id,store.elements[id])end
        if id:match("^party%d$")and self.registered[id]then self:StylePartyMember(id,self.registered[id])
        elseif (id=="player"or id=="target")and self.registered[id]then self:StyleUnit(id,self.registered[id])end
    end
    self.applying=nil
end
function H:Register(id,label,frame)
    -- Native cast events inspect secret interruptibility values. Do not attach
    -- addon movers or restoration scripts to these frames until live-safe.
    if id:match("^cast")and not (self.castFrames and self.castFrames[id]==frame)then return end
    if self.registered[id]or not real(frame)then return end
    local editor=AUI.modules.LayoutEditor
    editor:Attach(id,label,frame)
    local target=editor.targets[id];if not target then return end
    target.preview=id=="chat1"or id=="castplayer"or id=="casttarget"or id=="castoffhand"or id=="party";target.hud=true
    self.registered[id]=frame
    if frame.SetClampedToScreen then frame:SetClampedToScreen(true)end
    -- Retain native secure buttons, casting/unit events and secret-value rendering.
    local border=CreateFrame("Frame",nil,frame,"BackdropTemplate")
    border:SetAllPoints(frame);border:SetBackdrop({edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    local r,g,b=AUI:AccentColor();border:SetBackdropBorderColor(r,g,b,.3);border:EnableMouse(false)
    -- LayoutEditor owns the temporary mover outline; native HUD bounds stay invisible.
    border:Hide()
    target.border=border
    hooksecurefunc(frame,"SetScale",function()self:Queue(id)end)
    frame:HookScript("OnShow",function()self:Queue(id)end)
    if id=="target"then frame:HookScript("OnHide",function()self:StopCast("target")end)end
    hooksecurefunc(frame,"SetPoint",function()self:Queue(id)end)
end
local function flat(bar,mask)
    if not bar then return end
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    local texture=bar:GetStatusBarTexture()
    if texture and mask and texture.RemoveMaskTexture then texture:RemoveMaskTexture(mask)end
end
local artHooks=setmetatable({},{__mode="k"})
local function removeArt(texture)
    if not texture or type(texture)=="function"or type(texture.SetTexture)~="function"then return end
    if not artHooks[texture]then
        artHooks[texture]=true
        local clearing=false
        local function clear()
            if clearing then return end
            clearing=true;texture:SetTexture(nil);clearing=false
        end
        hooksecurefunc(texture,"SetTexture",clear)
        if type(texture.SetAtlas)=="function"then hooksecurefunc(texture,"SetAtlas",clear)end
    end
    texture:SetTexture(nil)
end
local function keepFlat(bar,mask)
    flat(bar,mask)
    local texture=bar:GetStatusBarTexture()
    if texture and type(texture)~="function"and type(texture.SetAtlas)=="function"and not artHooks[texture]then
        artHooks[texture]=true
        hooksecurefunc(texture,"SetAtlas",function()flat(bar,mask)end)
    end
end
local function barLabels(parent,bar,center)
    for _,entry in ipairs({{"LeftText","LEFT",4},{"RightText","RIGHT",-4},{center,"CENTER",0}})do
        local text=parent[entry[1]]
        if text and type(text)~="function"then text:ClearAllPoints();text:SetPoint(entry[2],bar,entry[2],entry[3],0)end
    end
end
local styling=setmetatable({},{__mode="k"})
local resourceColors={MANA={.20,.43,.85},RAGE={.85,.22,.18},ENERGY={.9,.73,.20},FOCUS={.9,.48,.2},RUNIC_POWER={.15,.7,.85}}
function H:PaintUnitBars(id,frame)
    if id=="party0"then id="player"end
    local health,power=frame.ruiHealth,frame.ruiPower
    if not health or not power or frame.ruiPainting==true then return end
    frame.ruiPainting=true
    health:SetStatusBarColor(.22,.65,.30)
    local token
    if type(UnitPowerType)=="function"then
        local ok,_,value=pcall(UnitPowerType,id)
        if ok and not (issecretvalue and issecretvalue(value))and type(value)=="string"then token=value end
    end
    local color=resourceColors[token or "MANA"]or {.55,.55,.65}
    power:SetStatusBarColor(color[1],color[2],color[3])
    frame.ruiPainting=nil
end
function H:LayoutTargetAuras(frame,anchorOnly)
    if self.layingOutTargetAuras then return end
    if InCombatLockdown()then self:Queue("target");return end
    local content=frame.TargetFrameContent
    local contextual=content and content.TargetFrameContentContextual
    if not real(contextual)then return end
    local auras=contextual.Auras
    if not real(auras)then return end
    self.layingOutTargetAuras=true
    -- Anchoring can run from ApplyLayout itself. Never dirty flow settings there.
    if not anchorOnly then
    frame.buffsOnTop=true
    auras:SetFlowLayoutMirroredVertically(true)
    auras:SetFlowLayoutMaximumLineSize(frame:GetWidth()-16)
    auras:SetConstrainedFlowLayoutLineSize(frame:GetWidth()-16)
    auras:SetNumConstrainedFlowLayoutLines(0)
    end
    auras:ClearAllPoints();auras:SetPoint("BOTTOMLEFT",frame,"TOPLEFT",8,8)
    self.layingOutTargetAuras=nil
end
function H:StyleUnit(id,frame)
    if InCombatLockdown()or styling[frame]then return end
    local player=id=="player"
    local content=player and frame.PlayerFrameContent or frame.TargetFrameContent
    if not real(content)then return end
    local main=content and (player and content.PlayerFrameContentMain or content.TargetFrameContentMain)
    local container=player and frame.PlayerFrameContainer or frame.TargetFrameContainer
    local health=main and main.HealthBarsContainer and main.HealthBarsContainer.HealthBar
    local power=main and (player and main.ManaBarArea and main.ManaBarArea.ManaBar or main.ManaBar)
    local portrait=container and (player and container.PlayerPortrait or container.Portrait)
    if not health or not power or not portrait then return end
    styling[frame]=true
    frame.ruiUnitStyled=true;frame.ruiHealth=health;frame.ruiPower=power;frame:SetSize(252,64)
    local target=self.registered[id]and AUI.modules.LayoutEditor.targets[id]
    if target and target.border then target.border:Hide()end
    for _,key in ipairs({"FrameTexture","AlternatePowerFrameTexture","VehicleFrameTexture","BossPortraitFrameTexture","FrameFlash","Flash"})do removeArt(container[key])end
    removeArt(main.StatusTexture);removeArt(main.ReputationColor);removeArt(main.LevelBackgroundCircle)
    removeArt(power.Spark)
    portrait:SetAlpha(0)
    if not player then
        local saved=ProjectRuthlessCharDB.layoutEditor
        if not (saved and saved.elements and saved.elements.target)and PlayerFrame then frame:SetScale(PlayerFrame:GetScale())end
        if container.FrameTexture then container.FrameTexture:ClearAllPoints();container.FrameTexture:SetAllPoints(frame)end
        self:LayoutTargetAuras(frame)
    end
    if main.LevelBackgroundCircle then main.LevelBackgroundCircle:SetAlpha(0)end
    if main.ReputationColor then main.ReputationColor:SetAlpha(0)end
    if not frame.ruiPortrait then
    for _,bar in ipairs({health,power})do hooksecurefunc(bar,"SetStatusBarColor",function()self:PaintUnitBars(id,frame)end)end
    local background=CreateFrame("Frame",nil,frame,"BackdropTemplate");background:SetAllPoints(frame);background:SetFrameLevel(math.max(0,frame:GetFrameLevel()-1));background:EnableMouse(false)
    background:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    AUI:StyleSurface(background,"window",math.max(.72,ProjectRuthlessDB.questWorkspace.opacity or .52),id=="player"and "Player"or "Target")
    local r,g,b=AUI:AccentColor();background:SetBackdropBorderColor(r,g,b,.22)
    frame.ruiSurface=background
    local accent=background:CreateTexture(nil,"ARTWORK");accent:SetColorTexture(r,g,b,.9);accent:SetPoint("TOPLEFT",1,-1);accent:SetPoint("TOPRIGHT",-1,-1);accent:SetHeight(2)
    local portraitBox=CreateFrame("Frame",nil,frame,"BackdropTemplate");portraitBox:SetPoint("TOPLEFT",4,-6);portraitBox:SetSize(52,52);portraitBox:EnableMouse(false)
    portraitBox:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});portraitBox:SetBackdropColor(.025,.028,.035,0)
    local model=CreateFrame("PlayerModel",nil,portraitBox);model:SetPoint("TOPLEFT",1,-1);model:SetPoint("BOTTOMRIGHT",-1,1);model:EnableMouse(false)
    model.ruiUnit=id;frame.ruiPortrait=model
    model:SetScript("OnShow",function()self:RefreshPortraits(id)end)
    self:RefreshPortraits(id)
    frame.ruiPortraitBox=portraitBox
    if type(frame.Update)=="function"then hooksecurefunc(frame,"Update",function()
        portrait:SetAlpha(0)
        if InCombatLockdown()then self:Queue(id)else self:StyleUnit(id,frame)end
    end)end
    if not player then
        if type(frame.CheckClassification)=="function"then hooksecurefunc(frame,"CheckClassification",function()
            if InCombatLockdown()then self:Queue(id)else self:StyleUnit(id,frame)end
        end)end
        for _,method in ipairs({"ConfigureAuraContainer","AnchorAuraContainer"})do if type(frame[method])=="function"then hooksecurefunc(frame,method,function()self:LayoutTargetAuras(frame,method=="AnchorAuraContainer")end)end end
    end
    end
    local portraitBox=frame.ruiPortraitBox
    local bars=main.HealthBarsContainer;bars:ClearAllPoints();bars:SetPoint("TOPLEFT",frame,"TOPLEFT",64,-21);bars:SetSize(184,22)
    health:ClearAllPoints();health:SetAllPoints(bars);keepFlat(health,bars.HealthBarMask)
    power:ClearAllPoints();power:SetPoint("TOPLEFT",frame,"TOPLEFT",64,-46);power:SetSize(184,12);keepFlat(power,power.ManaBarMask)
    barLabels(bars,health,"HealthBarText");barLabels(power,power,"ManaBarText")
    for _,key in ipairs({"PlayerFrameHealthBarAnimatedLoss","PlayerFrameTempMaxHealthLoss","TempMaxHealthLoss"})do
        local loss=bars[key]
        if loss and type(loss)~="function"then
            loss:ClearAllPoints();loss:SetAllPoints(health);keepFlat(loss,bars.HealthBarMask)
        end
    end
    if main.HitIndicator and type(main.HitIndicator)~="function"then
        main.HitIndicator:ClearAllPoints();main.HitIndicator:SetAllPoints(portraitBox)
        local hit=main.HitIndicator.HitText
        if hit and type(hit)~="function"then hit:SetFontObject(GameFontNormalSmall)end
    end
    self:PaintUnitBars(id,frame)
    local contextual=player and content.PlayerFrameContentContextual or content.TargetFrameContentContextual
    if real(contextual)then
        for _,key in ipairs({"LeaderIcon","GuideIcon","RaidTargetIcon"})do
            local icon=contextual[key]
            if icon and type(icon)~="function"and type(icon.ClearAllPoints)=="function"then
                icon:ClearAllPoints();local anchor=key=="RaidTargetIcon"and "TOPRIGHT"or "TOPLEFT";icon:SetPoint(anchor,portraitBox,anchor,0,5);icon:SetSize(14,14)
            end
        end
    end
    local name=player and PlayerName or main.Name
    if name then name:ClearAllPoints();name:SetPoint("TOPLEFT",frame,"TOPLEFT",64,-4);name:SetWidth(184);name:SetJustifyH("LEFT")end
    local level=player and PlayerLevelText or main.LevelText
    if level then level:ClearAllPoints();level:SetPoint("BOTTOMRIGHT",portraitBox,"BOTTOMRIGHT",-3,3)end
    self:ContainPortrait(frame)
    styling[frame]=nil
end
-- Keep models in the same stacking group as their unit frame, clipped to
-- the portrait rectangle. No independent high-strata model surface.
function H:ContainPortrait(frame)
    local box,model=frame.ruiPortraitBox,frame.ruiPortrait
    if not real(box)or not real(model)then return end
    box:SetFixedFrameStrata(false);box:SetFrameLevel(frame:GetFrameLevel());box:SetClipsChildren(true)
    model:SetFixedFrameStrata(false);model:SetFrameLevel(frame:GetFrameLevel());model:SetFixedFrameLevel(false)
    model:SetIgnoreParentAlpha(false);model:SetIgnoreParentScale(false);model:SetModelDrawLayer("ARTWORK")
end
function H:StylePartyMember(id,frame)
    if InCombatLockdown()or self.resting or styling[frame]then self:Queue(id);return end
    local bars=frame.HealthBarContainer
    local health=real(bars)and bars.HealthBar;local power=frame.ManaBar
    if not real(health)or not real(power)then return end
    styling[frame]=true;frame.ruiUnitStyled=true;frame.ruiHealth=health;frame.ruiPower=power
    frame:SetSize(224,76)
    for _,key in ipairs({"Texture","VehicleTexture","Flash"})do removeArt(frame[key])end
    if real(frame.PartyMemberOverlay)then removeArt(frame.PartyMemberOverlay.Status)end
    if frame.Portrait and type(frame.Portrait)~="function"then removeArt(frame.Portrait);frame.Portrait:SetAlpha(0)end
    if not frame.ruiPortrait then
        local background=CreateFrame("Frame",nil,frame,"BackdropTemplate")
        background:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0);background:SetSize(224,56);background:SetFrameLevel(math.max(0,frame:GetFrameLevel()-1));background:EnableMouse(false)
        background:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
        AUI:StyleSurface(background,"window",math.max(.72,ProjectRuthlessDB.questWorkspace.opacity or .52),id=="targettarget"and "Target"or "Party")
        local r,g,b=AUI:AccentColor();background:SetBackdropBorderColor(r,g,b,.22)
        local line=background:CreateTexture(nil,"ARTWORK");line:SetColorTexture(r,g,b,.9);line:SetPoint("TOPLEFT",1,-1);line:SetPoint("TOPRIGHT",-1,-1);line:SetHeight(2)
        frame.ruiSurface=background
        local box=CreateFrame("Frame",nil,frame);box:SetPoint("TOPLEFT",4,-6);box:SetSize(44,44);box:EnableMouse(false)
        local model=CreateFrame("PlayerModel",nil,box);model:SetAllPoints(box);model:EnableMouse(false)
        frame.ruiPortraitBox=box;frame.ruiPortrait=model
        model:SetScript("OnShow",function()self:RefreshPortraits(id)end)
        for _,bar in ipairs({health,power})do hooksecurefunc(bar,"SetStatusBarColor",function()self:PaintUnitBars(id,frame)end)end

    end
    bars:ClearAllPoints();bars:SetPoint("TOPLEFT",frame,"TOPLEFT",54,-20);bars:SetSize(166,18)
    health:ClearAllPoints();health:SetAllPoints(bars);keepFlat(health,health.HealthBarMask or bars.HealthBarMask)
    power:ClearAllPoints();power:SetPoint("TOPLEFT",frame,"TOPLEFT",54,-42);power:SetSize(166,10);keepFlat(power,power.ManaBarMask)
    barLabels(health,health,"CenterText");barLabels(power,power,"CenterText")
    if real(bars.TempMaxHealthLoss)then bars.TempMaxHealthLoss:ClearAllPoints();bars.TempMaxHealthLoss:SetAllPoints(health);keepFlat(bars.TempMaxHealthLoss,bars.HealthBarMask)end
    if frame.Name and type(frame.Name)~="function"then frame.Name:ClearAllPoints();frame.Name:SetPoint("TOPLEFT",frame,"TOPLEFT",54,-4);frame.Name:SetWidth(166);frame.Name:SetFontObject(GameFontNormalSmall);frame.Name:SetJustifyH("LEFT")end
    local overlay=frame.PartyMemberOverlay
    if real(overlay)then
        for _,key in ipairs({"LeaderIcon","GuideIcon","RoleIcon","Disconnect"})do
            local icon=overlay[key]
            if icon and type(icon)~="function"then icon:ClearAllPoints();local anchor=(key=="LeaderIcon"or key=="GuideIcon")and "TOPLEFT"or "BOTTOMRIGHT";icon:SetPoint(anchor,frame.ruiPortraitBox,anchor,0,2);icon:SetSize(14,14)end
        end
    end
    if real(frame.AuraFrameContainer)then frame.AuraFrameContainer:ClearAllPoints();frame.AuraFrameContainer:SetPoint("TOPLEFT",frame,"TOPRIGHT",5,-24)end
    if real(frame.PetFrame)then frame.PetFrame:ClearAllPoints();frame.PetFrame:SetPoint("TOPLEFT",frame,"BOTTOMLEFT",64,0)end
    self:ContainPortrait(frame);self:PaintUnitBars(id,frame);self:RefreshPortraits(id);styling[frame]=nil
end
-- Blizzard's inbound aura API owns restricted aura reads, layout, countdowns
-- and tooltips. RUI initializes only public presentation; never inspects data.
function H:CreatePartyAuras(row,unit)
    if type(CustomAuraContainerGroupDefaultOptions)~="table"then return end
    local dispelTypes={Magic=true,Curse=true,Disease=true,Poison=true,Bleed=true}
    local function initialize(button,harmful,size)
        button:SetSize(size,size);button:SetFixedFrameStrata(false)
        local border=button:CreateTexture(nil,"BACKGROUND");border:SetAllPoints(button);border:SetColorTexture(harmful and .6 or .16,harmful and .2 or .17,harmful and .2 or .19,1)
        local icon=button:CreateTexture(nil,"ARTWORK");icon:SetPoint("TOPLEFT",1,-1);icon:SetPoint("BOTTOMRIGHT",-1,1);icon:SetTexCoord(.07,.93,.07,.93)
        local cooldown=CreateFrame("Cooldown",nil,button,"CooldownFrameTemplate");cooldown:SetAllPoints(button);cooldown:SetDrawEdge(false);cooldown:SetHideCountdownNumbers(false)
        local timer=cooldown:GetCountdownFontString();timer:SetFont(STANDARD_TEXT_FONT,size==28 and 10 or 8,"OUTLINE")
        local count=button:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");count:SetPoint("BOTTOMRIGHT",-1,1);count:SetFont(STANDARD_TEXT_FONT,8,"OUTLINE")
        button:SetIcon(icon);button:SetDurationCooldown(cooldown);button:SetApplicationCount(count)
        button:SetTooltipAnchorPoint("ANCHOR_RIGHT");button:SetHideTooltipInCombat(false)
    end
    row.ruiAuras={}
    local groups={
        {filter="HELPFUL",y=-4,size=16,limit=4},
        {filter="HARMFUL",y=-26,size=16,limit=4,candidates={excludeDispelTypes=dispelTypes}},
        {filter="HARMFUL",y=-48,size=28,limit=2,candidates={includeDispelTypes=dispelTypes}},
    }
    for i,group in ipairs(groups)do
        local container=CreateFrame("AuraContainer",nil,row,"CustomAuraContainerTemplate")
        container:SetFixedFrameStrata(false);container:SetPoint("TOPLEFT",row,"TOPRIGHT",6,group.y)
        container:SetFlowLayoutMaximumLineSize(72)
        container:AddAuraGroup("party",group.filter,{maxFrameCount=group.limit,candidateFilters=group.candidates,initializeFrame=function(button)initialize(button,group.filter=="HARMFUL",group.size)end,layout={elementWidth=group.size,elementHeight=group.size,elementSpacing=2}})
        container:SetUnit(unit);container:SetEnabled(true)
        row.ruiAuras[i]=container
    end
end
function H:CreatePartyPet(row,index)
    local unit=index==0 and "pet"or "partypet"..index
    local pet=CreateFrame("Button",nil,row,"SecureUnitButtonTemplate");row.ruiPet=pet
    pet:SetFixedFrameStrata(false);pet:SetPoint("TOPLEFT",row,"TOPLEFT",4,-56);pet:SetSize(48,20)
    pet:SetAttribute("unit",unit);pet:SetAttribute("type1","target");pet:SetAttribute("type2","togglemenu");pet:RegisterForClicks("AnyUp")
    local name=pet:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");name:SetPoint("TOPLEFT");name:SetWidth(48);name:SetHeight(10);name:SetJustifyH("LEFT")
    local health=CreateFrame("StatusBar",nil,pet);health:SetPoint("TOPLEFT",0,-11);health:SetSize(48,5);health:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8");health:SetStatusBarColor(.22,.65,.30)
    local power=CreateFrame("StatusBar",nil,pet);power:SetPoint("TOPLEFT",0,-17);power:SetSize(48,3);power:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8");power:SetStatusBarColor(.20,.43,.85)
    local function update()
        name:SetText(UnitName(unit));health:SetMinMaxValues(0,UnitHealthMax(unit));health:SetValue(UnitHealth(unit))
        power:SetMinMaxValues(0,UnitPowerMax(unit));power:SetValue(UnitPower(unit));self:PaintUnitBars(unit,pet)
    end
    pet.ruiHealth=health;pet.ruiPower=power;pet.ruiName=name
    for _,event in ipairs({"UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_POWER_UPDATE","UNIT_MAXPOWER","UNIT_NAME_UPDATE"})do pet:RegisterUnitEvent(event,unit)end
    pet:RegisterUnitEvent("UNIT_PET",index==0 and "player"or "party"..index);pet:RegisterEvent("GROUP_ROSTER_UPDATE");pet:RegisterEvent("PLAYER_ENTERING_WORLD")
    pet:SetScript("OnEvent",update)
    pet:SetScript("OnEnter",function()if GameTooltip then GameTooltip:SetOwner(pet,"ANCHOR_RIGHT");GameTooltip:SetUnit(unit);GameTooltip:Show()end end)
    pet:SetScript("OnLeave",function()if GameTooltip then GameTooltip:Hide()end end)
    RegisterStateDriver(pet,"visibility","[@"..unit..",exists] show; hide");update()
end
function H:UpdatePartyReady(row,unit,event)
    local icon=row.ruiReady
    if event=="READY_CHECK"then row.ruiReadyRevision=row.ruiReadyRevision+1;row.ruiReadyStatus=false end
    local status=type(GetReadyCheckStatus)=="function"and GetReadyCheckStatus(unit)
    if issecretvalue and issecretvalue(status)then icon:Hide();return end
    if event=="READY_CHECK_FINISHED"and not status then status=row.ruiReadyStatus end
    row.ruiReadyStatus=status or false
    local atlas=({ready="UI-LFG-ReadyMark-Raid",notready="UI-LFG-DeclineMark-Raid",waiting="UI-LFG-PendingMark-Raid"})[status]
    if event=="READY_CHECK_FINISHED"and status=="waiting"then atlas="UI-LFG-DeclineMark-Raid"end
    if atlas then icon:SetAtlas(atlas);icon:Show()else icon:Hide()end
    if event=="READY_CHECK_FINISHED"then
        local revision=row.ruiReadyRevision
        C_Timer.After(10,function()if revision==row.ruiReadyRevision then icon:Hide()end end)
    end
end
-- These rows never use PartyMemberFrameTemplate, UnitFrame_Initialize or aura
-- mixins. Native secret health values go directly to owned renderer widgets.
function H:CreatePartyRow(index,parent,unitOverride)
    local unit=unitOverride or (index==0 and "player"or "party"..index)
    local id=unitOverride or "party"..index
    local row=CreateFrame("Button",unitOverride and "RUITargetOfTarget"or "RUIPartyMember"..index,parent,"SecureUnitButtonTemplate")
    row:SetFixedFrameStrata(false);row.ruiPortrait=false;row:SetAttribute("unit",unit);row:SetAttribute("type1","target");row:SetAttribute("type2","togglemenu");row:RegisterForClicks("AnyUp")
    row.HealthBarContainer=CreateFrame("Frame",nil,row)
    row.HealthBarContainer.HealthBar=CreateFrame("StatusBar",nil,row.HealthBarContainer)
    row.ManaBar=CreateFrame("StatusBar",nil,row)
    row.Name=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    row.ruiReadyRevision=0;row.ruiReadyStatus=false;row.ruiReady=row:CreateTexture(nil,"OVERLAY");row.ruiReady:SetPoint("CENTER",row,"TOPLEFT",32,-34);row.ruiReady:SetSize(20,20);row.ruiReady:Hide()
    for _,bar in ipairs({row.HealthBarContainer.HealthBar,row.ManaBar})do
        bar.RightText=bar:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        bar.LeftText=bar:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    end
    local function update(event)
        local health,power=row.HealthBarContainer.HealthBar,row.ManaBar
        local full=not event or not event:match("^UNIT_")or event=="UNIT_TARGET"or event=="UNIT_CONNECTION"
        if full or event=="UNIT_NAME_UPDATE"then row.Name:SetText(UnitName(unit))end
        if full or event=="UNIT_HEALTH"or event=="UNIT_MAXHEALTH"then
        health:SetMinMaxValues(0,UnitHealthMax(unit));health:SetValue(UnitHealth(unit))
        health.RightText:SetText(UnitHealth(unit))
        if type(UnitHealthPercent)=="function"and CurveConstants and CurveConstants.ScaleTo100 then
            health.LeftText:SetFormattedText("%.0f%%",UnitHealthPercent(unit,true,CurveConstants.ScaleTo100))
        end
        end
        if full or event=="UNIT_POWER_UPDATE"or event=="UNIT_MAXPOWER"or event=="UNIT_DISPLAYPOWER"then
        power:SetMinMaxValues(0,UnitPowerMax(unit));power:SetValue(UnitPower(unit));power.RightText:SetText(UnitPower(unit))
        if type(UnitPowerPercent)=="function"and CurveConstants and CurveConstants.ScaleTo100 then
            power.LeftText:SetFormattedText("%.0f%%",UnitPowerPercent(unit,nil,false,CurveConstants.ScaleTo100))
        end
        end
        if full or event=="UNIT_DISPLAYPOWER"then self:PaintUnitBars(id,row)end
    end
    for _,event in ipairs({"UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_POWER_UPDATE","UNIT_MAXPOWER","UNIT_DISPLAYPOWER","UNIT_NAME_UPDATE","UNIT_CONNECTION"})do row:RegisterUnitEvent(event,unit)end
    row:RegisterEvent("PLAYER_ENTERING_WORLD");row:RegisterEvent("GROUP_ROSTER_UPDATE")
    if unitOverride then row:RegisterEvent("PLAYER_TARGET_CHANGED");row:RegisterUnitEvent("UNIT_TARGET","target");row:RegisterUnitEvent("UNIT_MODEL_CHANGED",unit);row:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE",unit)end
    if not unitOverride then for _,event in ipairs({"READY_CHECK","READY_CHECK_CONFIRM","READY_CHECK_FINISHED"})do row:RegisterEvent(event)end end
    row:SetScript("OnEvent",function(_,event)
        if event=="READY_CHECK"or event=="READY_CHECK_CONFIRM"or event=="READY_CHECK_FINISHED"then self:UpdatePartyReady(row,unit,event);return end
        update(event)
        if event=="GROUP_ROSTER_UPDATE"then row.ruiReadyRevision=row.ruiReadyRevision+1;row.ruiReadyStatus=false;row.ruiReady:Hide()end
        if event=="PLAYER_TARGET_CHANGED"or event=="UNIT_TARGET"or event=="UNIT_MODEL_CHANGED"or event=="UNIT_PORTRAIT_UPDATE"or event=="PLAYER_ENTERING_WORLD"or event=="GROUP_ROSTER_UPDATE"or event=="UNIT_NAME_UPDATE"then self:RefreshPortraits(unit)end
    end)
    row:SetScript("OnEnter",function()
        if GameTooltip and type(GameTooltip.SetUnit)=="function"then GameTooltip:SetOwner(row,"ANCHOR_RIGHT");GameTooltip:SetUnit(unit);GameTooltip:Show()end
    end)
    row:SetScript("OnLeave",function()if GameTooltip then GameTooltip:Hide()end end)
    self.registered[id]=row;self:StylePartyMember(id,row);row:SetHeight(unitOverride and 56 or 76);if not unitOverride then self:CreatePartyAuras(row,unit);self:CreatePartyPet(row,index)end;update()
    if unitOverride or index>0 then RegisterStateDriver(row,"visibility","[@"..unit..",exists] show; hide")end
    return row
end
function H:CreateTargetOfTarget()
    if self.targetOfTarget or InCombatLockdown()or self.resting then return end
    local row=self:CreatePartyRow(0,UIParent,"targettarget");self.targetOfTarget=row
    row:SetFrameStrata("LOW");self:ContainPortrait(row)
    row:SetPoint("TOPLEFT",TargetFrame or UIParent,"BOTTOMLEFT",0,-8)
    -- Reuse the owned secret-safe renderer, never initialize/update native ToT.
    self.registered.targettarget=nil;self:Register("targettarget","Target of target",row)
    local native=TargetFrameToT
    if real(native)then
        local clearing=false
        local function suppress()if clearing then return end;clearing=true;native:SetAlpha(0);clearing=false end
        hooksecurefunc(native,"SetAlpha",suppress);suppress()
    end
end
function H:DiscoverParty()
    if InCombatLockdown()or self.resting then self.needsDiscovery=true;return end
    -- Alpha suppresses only stock presentation; Blizzard keeps all event/pool
    -- ownership. Do not call its Layout/Setup/Update or alter native member data.
    local native=PartyFrame
    if real(native)and not self.partySuppressed then
        self.partySuppressed=true
        local clearing=false
        local function suppress()
            if clearing then return end
            clearing=true;native:SetAlpha(0);clearing=false
        end
        hooksecurefunc(native,"SetAlpha",suppress);suppress()
    end
    if not self.partyFrame then
        local parent=CreateFrame("Frame","RUIPartyFrame",UIParent,"BackdropTemplate");self.partyFrame=parent
        parent:SetSize(230,398);parent:SetPoint("TOPLEFT",UIParent,"TOPLEFT",20,-200)
        parent:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
        parent:SetFrameStrata("LOW")
        AUI:StyleSurface(parent,"window",math.max(.72,ProjectRuthlessDB.questWorkspace.opacity or .52),"Party");local r,g,b=AUI:AccentColor();parent:SetBackdropBorderColor(r,g,b,.22)
        local accent=parent:CreateTexture(nil,"ARTWORK");parent.ruiAccent=accent;accent:SetColorTexture(r,g,b,.9);accent:SetPoint("TOPLEFT",1,-1);accent:SetPoint("TOPRIGHT",-1,-1);accent:SetHeight(2)
        for i=0,4 do local row=self:CreatePartyRow(i,parent);if i==0 then self.partyPlayer=row end end
        self:LayoutParty();self:Register("party","Party frames",parent)
        RegisterStateDriver(parent,"visibility","[group:party,nogroup:raid] show; hide")
    end
    self:LayoutParty()
end
function H:LayoutParty()
    local parent=self.partyFrame;if not real(parent)then return end
    local grouped=ProjectRuthlessDB.general and ProjectRuthlessDB.general.partyGrouped==true
    local color=AUI.Theme and AUI.Theme.window or {.025,.028,.035}
    parent:SetBackdropColor(color[1],color[2],color[3],grouped and AUI:BackgroundOpacity("Party")or 0)
    local r,g,b=AUI:AccentColor();parent:SetBackdropBorderColor(r,g,b,grouped and .22 or 0)
    if parent.ruiAccent then parent.ruiAccent:SetShown(grouped)end
    for i=0,4 do
        local row=self.registered["party"..i]
        if row and real(row.ruiSurface)then row.ruiSurface:SetAlpha(grouped and 0 or 1)end
    end
    if InCombatLockdown()or self.resting then self.needsDiscovery=true;return end
    for i=0,4 do
        local row=self.registered["party"..i]
        if real(row)then
            row:ClearAllPoints();row:SetPoint("TOPLEFT",parent,"TOPLEFT",3,-3-i*79)
            if real(row.ruiSurface)then row.ruiSurface:SetAlpha(grouped and 0 or 1)end
        end
    end
    parent:SetSize(230,398)
end
function H:ApplySettings()
    if not AUI.isForever then return end
    self:LayoutParty()
end
function H:RefreshPortraits(unit)
    for _,id in ipairs({"player","target","targettarget","party0","party1","party2","party3","party4"})do
        local frame=self.registered[id];local model=frame and frame.ruiPortrait
        local token=id=="party0"and "player"or id
        if model and (not unit or unit==token)then
            -- Failed/restricted bindings retain the previous model unless cleared.
            -- Disable blending so rapid target changes cannot show the old face.
            model:ClearModel()
            if type(UnitExists)~="function"or UnitExists(token)then
                local ok,success=pcall(model.SetUnit,model,token,false)
                if ok and not (issecretvalue and issecretvalue(success))and success~=false then
                    model:SetPortraitZoom(1);model:SetCamera(0)
                end
            end
        end
    end
end
function H:Discover()
    if not AUI.isForever or InCombatLockdown()then self.needsDiscovery=true;return end
    self.needsDiscovery=nil
    for _,spec in ipairs(specs)do
        for _,name in ipairs(spec[3])do local frame=_G[name];if real(frame)then self:Register(spec[1],spec[2],frame);if spec[1]=="player"or spec[1]=="target"then self:StyleUnit(spec[1],frame)end;break end end
    end
end
function H:OnPlayerLogin()
    if not AUI.isForever then return end
    self:Discover()
    self:DiscoverParty()
    self:CreateTargetOfTarget()
    self:CreateCastBars()
    local events=CreateFrame("Frame");self.events=events
    for _,event in ipairs({"ADDON_LOADED","PLAYER_ENTERING_WORLD","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","PLAYER_TARGET_CHANGED","GROUP_ROSTER_UPDATE"})do events:RegisterEvent(event)end
    events:RegisterUnitEvent("UNIT_DISPLAYPOWER","player","target","party1","party2","party3","party4")
    events:RegisterUnitEvent("UNIT_MODEL_CHANGED","player","target","party1","party2","party3","party4");events:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE","player","target","party1","party2","party3","party4")
    events:SetScript("OnEvent",function(_,event,unit)
        if event=="ADDON_LOADED"and not self:IsRelevantAddon(unit)then return end
        if event=="UNIT_DISPLAYPOWER"then local frame=self.registered[unit];if frame and frame.ruiUnitStyled then self:PaintUnitBars(unit,frame)end;return end
        if event=="PLAYER_TARGET_CHANGED"then self:RefreshPortraits("target");local frame=self.registered.target;if frame and frame.ruiUnitStyled then self:PaintUnitBars("target",frame)end;return end
        if event=="UNIT_MODEL_CHANGED"or event=="UNIT_PORTRAIT_UPDATE"then self:RefreshPortraits(unit);return end
        if event=="PLAYER_REGEN_DISABLED"then self.resting=true;self.combatRevision=(self.combatRevision or 0)+1
        elseif event=="PLAYER_REGEN_ENABLED"then
            local revision=self.combatRevision or 0
            C_Timer.After(3,function()if revision~=(self.combatRevision or 0)or InCombatLockdown()then return end;self.resting=nil;if self.needsDiscovery then self:Discover();self:DiscoverParty();self:CreateTargetOfTarget()end;self:Drain()end)
        elseif not InCombatLockdown()and not self.resting then self:Discover();self:DiscoverParty();self:CreateTargetOfTarget()else self.needsDiscovery=true end
    end)
end

-- Separate addon-owned displays. Native casting mixins and their secret boolean
-- decisions are never called from these event handlers.
local function secret(value)return issecretvalue and issecretvalue(value)end
local castEnds={UNIT_SPELLCAST_STOP=true,UNIT_SPELLCAST_FAILED=true,UNIT_SPELLCAST_FAILED_QUIET=true,UNIT_SPELLCAST_INTERRUPTED=true,UNIT_SPELLCAST_CHANNEL_STOP=true}
-- PLAYER_SWING supplies the actual main-hand/ranged cooldown in Forever.
-- Never restart a cycle speculatively: each swing must come from the client.
function H:StopSwing()
    self.swingEnd=nil;self.swingDuration=nil;self.offSwingEnd=nil;self.offSwingDuration=nil
    local off=self.castFrames and self.castFrames.castoffhand
    if off then off.swingActive=false;off:SetScript("OnUpdate",nil);off:Hide()end
    local frame=self.castFrames and self.castFrames.castplayer
    if not frame then return end
    frame.swingActive=false;frame:SetScript("OnUpdate",nil)
    if frame.swingFill then frame.swingFill:Hide()end
    if frame.castActive~=true then frame:Hide();frame.latencyText:SetText("")end
end
function H:ShowSwing()
    local frame=self.castFrames and self.castFrames.castplayer
    if not frame or frame.castActive==true or not self.swingEnd then return end
    local remaining=self.swingEnd-GetTime()
    if remaining<=0 then
        self.swingEnd=nil;self.swingDuration=nil;frame.swingActive=false;frame:SetScript("OnUpdate",nil);frame:Hide();return
    end
    local starting=not frame.swingActive
    frame.swingActive=true;frame.icon:SetTexture("Interface\\Icons\\Ability_MeleeDamage")
    frame.label:SetText(self.swingRanged and "Auto shot"or "Auto attack")
    frame.latencyText:SetTextColor(1,.3,.3)
    frame.fill:Hide();frame.swingFill:Show()
    frame.swingFill:SetMinMaxValues(0,self.swingDuration);frame.swingFill:SetValue(self.swingDuration-remaining)
    if starting then self:UpdateCastLatency(frame,0,self.swingDuration*1000,false)end
    frame.latencyText:SetText(("%.1f s · %d ms"):format(remaining,frame.latencyMs));frame:Show()
    if starting then frame:SetScript("OnUpdate",function()self:ShowSwing()end)end
end
function H:ShowOffhandSwing()
    local frame=self.castFrames and self.castFrames.castoffhand
    if not frame or not self.offSwingEnd then return end
    local remaining=self.offSwingEnd-GetTime()
    if remaining<=0 then self.offSwingEnd=nil;frame.swingActive=false;frame:SetScript("OnUpdate",nil);frame:Hide();return end
    local starting=not frame.swingActive
    frame.swingActive=true;frame.icon:SetTexture("Interface\\Icons\\Ability_DualWield")
    frame.label:SetText("Off-hand attack");frame.fill:Hide();frame.swingFill:Show()
    frame.swingFill:SetMinMaxValues(0,self.offSwingDuration);frame.swingFill:SetValue(self.offSwingDuration-remaining)
    if starting then self:UpdateCastLatency(frame,0,self.offSwingDuration*1000,false)end
    frame.latencyText:SetText(("%.1f s · %d ms"):format(remaining,frame.latencyMs));frame:Show()
    if starting then frame:SetScript("OnUpdate",function()self:ShowOffhandSwing()end)end
end
function H:SwingEvent(event,duration,swingType)
    if event=="PLAYER_TARGET_CHANGED"or event=="PLAYER_LEAVE_COMBAT"or event=="STOP_AUTOREPEAT_SPELL"then return end
    if event~="PLAYER_SWING"then self:StopSwing();return end
    if secret(duration)or secret(swingType)or type(duration)~="number"or duration~=duration or duration<=0 or duration==math.huge then return end
    local types=Enum and Enum.PlayerSwingType
    if not types then return end
    if swingType==types.OffHand then
        self.offSwingDuration=duration;self.offSwingEnd=GetTime()+duration
        local off=self.castFrames and self.castFrames.castoffhand
        if off then off.swingActive=false end
        self:ShowOffhandSwing();return
    end
    if swingType~=types.MainHand and swingType~=types.Ranged then return end
    local frame=self.castFrames and self.castFrames.castplayer
    if frame then frame.swingActive=false end
    self.swingDuration=duration;self.swingEnd=GetTime()+duration;self.swingRanged=swingType==types.Ranged
    -- A queued/instant ability must not leave a stale cast flag covering swings.
    if frame and frame.castActive==true then self:RefreshCast("player")else self:ShowSwing()end
end
function H:StopCast(unit)
    local frame=self.castFrames and self.castFrames["cast"..unit]
    if not frame then return end
    frame.activeCastID=nil;frame.activeCastGUID=nil;frame.castActive=false;frame.swingActive=false;frame:SetScript("OnUpdate",nil)
    frame:Hide();frame.label:SetText("");frame.icon:SetTexture(nil);frame.latency:Hide()
    if unit=="player"then self:ShowSwing()end
end
function H:CastEvent(unit,event,castGUID,castID)
    local frame=self.castFrames["cast"..unit]
    if castEnds[event]then
        -- Instant and queued melee abilities have no active cast bar to stop.
        if frame.castActive~=true then return end
        -- Stop events are authoritative even if the info API still returns the
        -- cancelled cast. Public identities reject late events for older casts.
        if not secret(castID)and castID~=nil and type(frame.activeCastID)=="number"and castID~=frame.activeCastID then return end
        if not secret(castGUID)and castGUID~=nil and type(frame.activeCastGUID)=="string"and castGUID~=frame.activeCastGUID then return end
        self:StopCast(unit);return
    end
    if event=="UNIT_SPELLCAST_START"or event=="UNIT_SPELLCAST_CHANNEL_START"then
        frame.activeCastID=not secret(castID)and castID or nil
        frame.activeCastGUID=not secret(castGUID)and castGUID or nil
    elseif event=="PLAYER_TARGET_CHANGED"or event=="PLAYER_ENTERING_WORLD"then
        self:StopCast(unit)
    elseif frame.castActive~=true then return end
    self:RefreshCast(unit)
end
function H:LayoutCastLatency(frame)
    if not frame.latency then return end
    local frameWidth,iconWidth=frame:GetWidth(),frame.icon:GetWidth()
    local width
    if not secret(frameWidth)and not secret(iconWidth)and type(frameWidth)=="number"and type(iconWidth)=="number"then
        width=math.max(1,frameWidth-iconWidth-4)
    end
    local seconds=frame.castSeconds
    local band=2
    if width and not secret(seconds)and type(seconds)=="number"and seconds>0 then band=math.min(width,width*frame.latencyMs/1000/seconds)end
    frame.latency:ClearAllPoints()
    local edge=frame.castChannel and "LEFT"or "RIGHT"
    local fill=frame.swingActive and frame.swingFill or frame.fill
    frame.latency:SetPoint("TOP"..edge,fill,"TOP"..edge,0,0)
    frame.latency:SetPoint("BOTTOM"..edge,fill,"BOTTOM"..edge,0,0)
    frame.latency:SetWidth(math.max(1,band))
    frame.latency:SetShown(frame.latencyMs>0)
    frame.latencyText:SetText(("%d ms"):format(frame.latencyMs))
end
function H:UpdateCastLatency(frame,startMs,endMs,channel,duration)
    local _,_,home,world
    if type(GetNetStats)=="function"then _,_,home,world=GetNetStats()end
    local ms=not secret(world)and type(world)=="number"and world or not secret(home)and type(home)=="number"and home or 0
    frame.latencyMs=math.max(0,math.floor(ms));frame.castChannel=channel;frame.castSeconds=nil
    if not secret(startMs)and not secret(endMs)and type(startMs)=="number"and type(endMs)=="number"and endMs>startMs then
        frame.castSeconds=(endMs-startMs)/1000
    elseif not secret(duration)and duration and type(duration.GetTotalDuration)=="function"then
        local ok,total=pcall(duration.GetTotalDuration,duration)
        if ok and not secret(total)and type(total)=="number"and total>0 then frame.castSeconds=total end
    end
    -- A thin end marker plus measured ms remains honest when cast duration is
    -- restricted. Target display uses our network delay, never their latency.
    self:LayoutCastLatency(frame)
end
function H:RefreshCast(unit)
    local frame=self.castFrames and self.castFrames["cast"..unit]
    if not frame then return end
    if type(UnitExists)=="function"and not UnitExists(unit)then self:StopCast(unit);return end
    local name,_,icon,startMs,endMs=UnitCastingInfo(unit)
    local channel=false
    if not secret(name)and name==nil then
        name,_,icon,startMs,endMs=UnitChannelInfo(unit);channel=true
    end
    if not secret(name)and name==nil then self:StopCast(unit);return end
    frame.castActive=true;frame.swingActive=false;frame:SetScript("OnUpdate",nil)
    if frame.swingFill then frame.swingFill:Hide()end;frame.fill:Show()
    frame.latencyText:SetTextColor(1,.3,.3)
    frame.label:SetText(name);frame.icon:SetTexture(icon)
    local durationFn=channel and UnitChannelDuration or UnitCastingDuration
    local duration=type(durationFn)=="function"and durationFn(unit)
    local timed=false
    if (secret(duration)or duration~=nil)and type(frame.fill.SetTimerDuration)=="function"then
        timed=pcall(frame.fill.SetTimerDuration,frame.fill,duration,Enum.StatusBarInterpolation.Immediate,
            channel and Enum.StatusBarTimerDirection.RemainingTime or Enum.StatusBarTimerDirection.ElapsedTime)
    end
    if not timed then
        -- A restricted client may withhold duration. Still show the spell without
        -- calculating, comparing or formatting secret timing/interruptibility.
        frame.fill:SetMinMaxValues(0,1);frame.fill:SetValue(0)
    end
    self:UpdateCastLatency(frame,startMs,endMs,channel,duration)
    frame:Show()
end
function H:CreateCastBars()
    if self.castFrames or type(UnitCastingInfo)~="function"or type(UnitChannelInfo)~="function"then return end
    self.castFrames={}
    for _,unit in ipairs({"player","target","offhand"})do
        local id="cast"..unit
        local f=CreateFrame("Frame",nil,UIParent,"BackdropTemplate");self.castFrames[id]=f;f.swingFill=false
        f:SetSize(250,24);f:SetPoint("CENTER",UIParent,"CENTER",unit=="target"and 180 or -180,unit=="offhand"and -220 or -190)
        f:SetClampedToScreen(true);f:EnableMouse(false)
        f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
        AUI:StyleSurface(f,"window",.8,"Cast")
        local r,g,b=AUI:AccentColor();f:SetBackdropBorderColor(r,g,b,.22)
        local fill=CreateFrame("StatusBar",nil,f);fill:SetPoint("TOPLEFT",1,-1);fill:SetPoint("BOTTOMRIGHT",-1,1)
        fill:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8");fill:SetStatusBarColor(r,g,b,.7);f.fill=fill
        local icon=f:CreateTexture(nil,"OVERLAY");icon:SetPoint("TOPLEFT",1,-1);icon:SetPoint("BOTTOMLEFT",1,1);icon:SetWidth(22);f.icon=icon
        fill:ClearAllPoints();fill:SetPoint("TOPLEFT",f,"TOPLEFT",25,-1);fill:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-1,1)
        if unit~="target"then
            local swingFill=CreateFrame("StatusBar",nil,f);swingFill:SetAllPoints(fill);swingFill:SetFrameLevel(fill:GetFrameLevel())
            swingFill:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8");swingFill:SetStatusBarColor(r,g,b,.7);swingFill:Hide();f.swingFill=swingFill
        end
        local textLayer=CreateFrame("Frame",nil,f);textLayer:SetAllPoints(f);textLayer:SetFrameLevel(fill:GetFrameLevel()+2)
        local label=textLayer:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");label:SetPoint("LEFT",icon,"RIGHT",5,0);label:SetPoint("RIGHT",-5,0);label:SetJustifyH("LEFT");f.label=label
        local latency=textLayer:CreateTexture(nil,"OVERLAY",nil,1);latency:SetColorTexture(.95,.08,.08,.65);f.latency=latency
        local latencyText=textLayer:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");latencyText:SetPoint("RIGHT",-4,0);latencyText:SetTextColor(1,.3,.3);f.latencyText=latencyText
        label:ClearAllPoints();label:SetPoint("LEFT",fill,"LEFT",5,0);label:SetPoint("RIGHT",latencyText,"LEFT",-6,0)
        f.latencyMs=0
        f:SetScript("OnSizeChanged",function()
            local height=f:GetHeight()
            if not secret(height)and type(height)=="number"then
                local iconSize=math.max(10,height-2)
                icon:SetWidth(iconSize);fill:SetPoint("TOPLEFT",f,"TOPLEFT",iconSize+3,-1)
            end
            self:LayoutCastLatency(f)
        end)
        f:Hide();self:Register(id,unit=="player"and "Player cast bar"or unit=="offhand"and "Off-hand attack bar"or "Target cast bar",f)
        local target=AUI.modules.LayoutEditor.targets[id]
        target.resize={minWidth=100,maxWidth=700,minHeight=14,maxHeight=80}
        local saved=ProjectRuthlessCharDB.layoutEditor.elements[id]
        if saved then AUI.modules.LayoutEditor:Apply(id,saved)end
        if unit~="offhand"then
        for _,event in ipairs({"UNIT_SPELLCAST_START","UNIT_SPELLCAST_STOP","UNIT_SPELLCAST_FAILED","UNIT_SPELLCAST_FAILED_QUIET","UNIT_SPELLCAST_INTERRUPTED","UNIT_SPELLCAST_DELAYED","UNIT_SPELLCAST_CHANNEL_START","UNIT_SPELLCAST_CHANNEL_UPDATE","UNIT_SPELLCAST_CHANNEL_STOP"})do f:RegisterUnitEvent(event,unit)end
        if unit=="target"then f:RegisterEvent("PLAYER_TARGET_CHANGED")end
        f:RegisterEvent("PLAYER_ENTERING_WORLD")
        if unit=="player"then
            for _,event in ipairs({"PLAYER_SWING","PLAYER_LEAVE_COMBAT","STOP_AUTOREPEAT_SPELL","PLAYER_DEAD","PLAYER_TARGET_CHANGED"})do f:RegisterEvent(event)end
        end
        f:SetScript("OnEvent",function(_,event,arg1,arg2,arg3,arg4)
            if unit=="player"then
                if event=="PLAYER_SWING"or event=="PLAYER_LEAVE_COMBAT"or event=="STOP_AUTOREPEAT_SPELL"or event=="PLAYER_DEAD"or event=="PLAYER_TARGET_CHANGED"then self:SwingEvent(event,arg1,arg2);return end
                if event=="PLAYER_ENTERING_WORLD"then self:StopSwing()end
            end
            self:CastEvent(unit,event,arg2,arg4)
        end)
        end
    end
    -- Owned bars replace these displays. Alpha alone leaves hidden native cast
    -- events running through secret interruptibility on the modified unit frame.
    -- Retire duplicate event subscriptions without replacing native mixins.
    for _,native in ipairs({PlayerCastingBarFrame or CastingBarFrame,TargetFrameSpellBar or (TargetFrame and TargetFrame.spellbar)})do
        if native then
            native:UnregisterAllEvents()
            native:Hide()
            local applying=false
            local function hideArt()
                if applying then return end
                applying=true;native:SetAlpha(0);applying=false
            end
            hooksecurefunc(native,"SetAlpha",hideArt);hideArt()
        end
    end
    self:RefreshCast("player");self:RefreshCast("target")
end
