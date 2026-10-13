local _,AUI=...
local B={auras={},icons={}}
AUI:RegisterModule("ForeverExpiringBuffs",B)
local function public(value)return not(issecretvalue and issecretvalue(value))end
local function number(value)return public(value)and type(value)=="number"end
local function restricted()
    return InCombatLockdown() or (C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret())
end
function B:Remember(aura)
    if not public(aura)or not aura or not number(aura.auraInstanceID)then return end
    local id=aura.auraInstanceID
    self.auras[id]=nil
    if not public(aura.isHelpful)or not aura.isHelpful or not number(aura.expirationTime)or not number(aura.duration)then return end
    if aura.duration>0 and aura.expirationTime>0 then self.auras[id]=aura end
end
function B:Scan()
    if restricted()or self.resting then self.needsScan=true;return end
    if not C_UnitAuras or type(C_UnitAuras.GetAuraDataByIndex)~="function"then return end
    self.needsScan=nil;self.auras={}
    for i=1,80 do
        local ok,aura=pcall(C_UnitAuras.GetAuraDataByIndex,"player",i,"HELPFUL")
        if not ok then self.needsScan=true;break end
        if not public(aura)or not aura then break end;self:Remember(aura)
    end
    self:Queue()
end
function B:Update(info)
    -- Restricted aura access can continue outside combat. Never query updates then.
    -- Discard stale icons rather than advertise a cancelled buff from cached timing.
    if restricted()then self.needsScan=true;self.auras={};self:Queue();return end
    if self.needsScan then self:Scan();return end
    if not public(info)or not info or not public(info.isFullUpdate)or info.isFullUpdate then self:Scan();return end
    for _,aura in ipairs(info.addedAuras or {})do self:Remember(aura)end
    for _,id in ipairs(info.removedAuraInstanceIDs or {})do if number(id)then self.auras[id]=nil end end
    for _,id in ipairs(info.updatedAuraInstanceIDs or {})do
        if number(id)then
            self.auras[id]=nil
            local ok,aura=pcall(C_UnitAuras.GetAuraDataByAuraInstanceID,"player",id)
            if ok then self:Remember(aura)else self.needsScan=true end
        end
    end
    self:Queue()
end
function B:Queue()
    if self.queued then return end;self.queued=true
    C_Timer.After(.15,function()self.queued=nil;self:Render()end)
end
function B:Render()
    if not self.frame then return end
    local now=GetTime();local shown={};local nextTime
    for id,aura in pairs(self.auras)do
        local remaining=aura.expirationTime-now
        if remaining<=0 then self.auras[id]=nil
        elseif remaining<30 then shown[#shown+1]=aura;nextTime=math.min(nextTime or remaining,remaining)
        else local threshold=remaining-30+.05;nextTime=math.min(nextTime or threshold,threshold)end
    end
    table.sort(shown,function(a,b)if a.expirationTime==b.expirationTime then return a.auraInstanceID<b.auraInstanceID end;return a.expirationTime<b.expirationTime end)
    for i=1,math.min(#shown,24)do
        local icon=self.icons[i]
        if not icon then
            icon=CreateFrame("Frame",nil,self.frame,"BackdropTemplate");icon:SetSize(26,26);icon:EnableMouse(false)
            icon:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1});icon:SetBackdropColor(.055,.058,.064,.95);icon:SetBackdropBorderColor(.8,.3,.2,.8)
            icon.texture=icon:CreateTexture(nil,"ARTWORK");icon.texture:SetPoint("TOPLEFT",1,-1);icon.texture:SetPoint("BOTTOMRIGHT",-1,1);icon.texture:SetTexCoord(.07,.93,.07,.93)
            icon.cooldown=CreateFrame("Cooldown",nil,icon,"CooldownFrameTemplate");icon.cooldown:SetAllPoints(icon);icon.cooldown:SetHideCountdownNumbers(false);icon.cooldown:SetDrawEdge(false)
            self.icons[i]=icon
        end
        local aura=shown[i];icon:SetPoint("BOTTOMLEFT",self.frame,"BOTTOMLEFT",((i-1)%8)*30,math.floor((i-1)/8)*30)
        icon.texture:SetTexture(aura.icon);icon.cooldown:SetCooldown(aura.expirationTime-aura.duration,aura.duration);icon:Show()
    end
    for i=math.min(#shown,24)+1,#self.icons do self.icons[i]:Hide()end
    if self.timer and type(self.timer.Cancel)=="function"then self.timer:Cancel()end
    self.revision=(self.revision or 0)+1;local revision=self.revision
    if nextTime then local schedule=C_Timer.NewTimer or C_Timer.After;self.timer=schedule(math.max(.05,nextTime),function()if revision==self.revision then self:Render()end end)end
end
function B:OnPlayerLogin()
    if not AUI.isForever or not PlayerFrame then return end
    self.frame=CreateFrame("Frame",nil,PlayerFrame);self.frame:SetSize(240,86);self.frame:SetPoint("BOTTOMLEFT",PlayerFrame,"TOPLEFT",8,8);self.frame:EnableMouse(false)
    local events=CreateFrame("Frame");self.events=events;events:RegisterUnitEvent("UNIT_AURA","player")
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED"})do events:RegisterEvent(event)end
    events:SetScript("OnEvent",function(_,event,unit,info)
        if event=="UNIT_AURA"then self:Update(info)
        elseif event=="PLAYER_REGEN_DISABLED"then self.resting=true;self.combatRevision=(self.combatRevision or 0)+1
        elseif event=="PLAYER_REGEN_ENABLED"then local revision=self.combatRevision;C_Timer.After(3,function()if revision~=self.combatRevision or InCombatLockdown()then return end;self.resting=nil;if self.needsScan then self:Scan()end end)
        else self:Scan()end
    end)
    self:Scan()
end
