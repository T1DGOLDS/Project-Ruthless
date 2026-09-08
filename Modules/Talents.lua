local _, AUI = ...
local Talents = {}
AUI:RegisterModule("Talents", Talents)

-- Keep Blizzard's talent frame and parent relationship intact: its purchase,
-- rollback, import and load callbacks own talent changes and confirmations.
local TREE_SCALE = 0.72
local SIDE = 220
local HEADER = 72
local function Accent()
    local _, class = UnitClass("player")
    local c = RAID_CLASS_COLORS[class]
    return c and c.r or 0.5, c and c.g or 0.35, c and c.b or 0.94
end
local function Surface(frame)
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1})
    frame:SetBackdropColor(0.025,0.028,0.038,0.98)
    frame:SetBackdropBorderColor(0.16,0.17,0.21,1)
end
local function Label(parent, text, x, y, width, font)
    local label=parent:CreateFontString(nil,"OVERLAY",font or "GameFontNormalSmall")
    label:SetPoint("TOPLEFT",x,y); label:SetWidth(width); label:SetJustifyH("LEFT")
    label:SetTextColor(0.85,0.87,0.92); label:SetText(text)
    return label
end
local function Hint(widget, title, body)
    widget:HookScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(title)
        GameTooltip:AddLine(body,0.8,0.82,0.88,true); GameTooltip:Show()
    end)
    widget:HookScript("OnLeave",function() GameTooltip:Hide() end)
end

function Talents:IsEnabled()
    return ProjectRuthlessDB and ProjectRuthlessDB.enabled and ProjectRuthlessDB.talents.enabled
end

function Talents:IsEditable()
    local f=self.frame
    return f and self.active and not f:IsInspecting() and not InCombatLockdown()
        and not f.TalentsFrame:IsCommitInProgress()
        and not UnitCastingInfo("player") and not UnitChannelInfo("player")
end

function Talents:GetEntries(query)
    local tree=self.frame.TalentsFrame
    local entries={}
    query=(query or ""):lower()
    for _,id in ipairs(tree.configIDs or {}) do
        local name=(tree.configIDToName and tree.configIDToName[id]) or "Unnamed loadout"
        if name:lower():find(query,1,true) then entries[#entries+1]={id=id,name=name} end
    end
    return entries
end

local function HideTemplateTextures(button)
    for _,key in ipairs({"Left","Middle","Right"}) do
        if button[key] then button[key]:SetAlpha(0) end
    end
    for _,getter in ipairs({"GetNormalTexture","GetPushedTexture","GetDisabledTexture","GetHighlightTexture"}) do
        if button[getter] then
            local texture=button[getter](button)
            if texture then texture:SetAlpha(0) end
        end
    end
end

function Talents:StyleRaiderButton()
    local button=_G.RaiderIO_TalentBuildsTalentFrameShortcut
    if not button or not self.sidebar then return end
    if not button.ProjectRuthlessSkin then
        button.ProjectRuthlessSkin=true
        button.ProjectRuthlessOrigin={parent=button:GetParent(),points={},scale=button:GetScale(),width=button:GetWidth(),height=button:GetHeight()}
        for i=1,button:GetNumPoints() do button.ProjectRuthlessOrigin.points[i]={button:GetPoint(i)} end
        HideTemplateTextures(button)
        local surface=CreateFrame("Frame",nil,button,"BackdropTemplate")
        surface:SetAllPoints(); surface:SetFrameLevel(math.max(0,button:GetFrameLevel()-1)); Surface(surface)
        local r,g,b=Accent(); surface:SetBackdropBorderColor(r,g,b,0.75)
        surface:EnableMouse(false); button.ProjectRuthlessSurface=surface
        if button.GetFontString and button:GetFontString() then button:GetFontString():SetTextColor(0.9,0.92,0.96) end
        button:HookScript("OnClick",function() C_Timer.After(0,function() self:SkinRaiderWindow() end) end)
    end
    if button:GetParent()~=self.sidebar then button:SetParent(self.sidebar) end
    button:ClearAllPoints(); button:SetPoint("BOTTOMLEFT",self.sidebar,"BOTTOMLEFT",12,20)
    button:SetScale(1); button:SetSize(186,30); button:SetShown(self.active)
    self.raiderButton=button
end

function Talents:RestoreRaiderButton()
    local button=self.raiderButton
    local origin=button and button.ProjectRuthlessOrigin
    if not origin then return end
    button:Hide(); button:SetParent(origin.parent); button:SetScale(origin.scale); button:SetSize(origin.width,origin.height)
    button:ClearAllPoints()
    for _,point in ipairs(origin.points) do button:SetPoint(unpack(point)) end
    if button.UpdateVisibility then button:UpdateVisibility() end
end

function Talents:StyleRaiderRows()
    local frame=_G.RaiderIO_TalentBuildsFrame
    if not frame or not frame.ScrollBox or not frame.ScrollBox.ForEachFrame then return end
    frame.ScrollBox:ForEachFrame(function(row)
        if row.SetBackdrop then
            row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
            row:SetBackdropColor(0.035,0.039,0.052,0.96)
            row:SetBackdropBorderColor(0.13,0.14,0.18,1)
        end
    end)
end

function Talents:SkinRaiderWindow()
    local frame=_G.RaiderIO_TalentBuildsFrame
    if not frame then return end
    if not frame.ProjectRuthlessSkin then
        frame.ProjectRuthlessSkin=true
        if frame.NineSlice then frame.NineSlice:Hide() end
        if frame.PortraitContainer then frame.PortraitContainer:Hide() end
        if frame.TopTileStreaks then frame.TopTileStreaks:Hide() end
        if frame.Inset then frame.Inset:Hide() end
        if frame.Bg then frame.Bg:SetColorTexture(0.025,0.028,0.038,0.98) end
        local border=CreateFrame("Frame",nil,frame,"BackdropTemplate")
        border:SetAllPoints(); border:SetFrameLevel(math.max(0,frame:GetFrameLevel()-1)); Surface(border)
        local r,g,b=Accent(); border:SetBackdropBorderColor(r,g,b,0.8)
        border:EnableMouse(false); frame.ProjectRuthlessBorder=border
        if frame.TitleContainer and frame.TitleContainer.TitleText then
            local title=frame.TitleContainer.TitleText
            title:ClearAllPoints(); title:SetPoint("TOPLEFT",frame,"TOPLEFT",16,-12)
            title:SetTextColor(r,g,b); title:SetJustifyH("LEFT")
        end
        if frame.CloseButton then
            frame.CloseButton:ClearAllPoints(); frame.CloseButton:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-7,-7)
        end
        frame:HookScript("OnShow",function()
            C_Timer.After(0,function() self:SkinRaiderWindow(); self:StyleRaiderRows() end)
        end)
        if frame.ScrollBox.RegisterCallback and frame.ScrollBox.Event and frame.ScrollBox.Event.OnUpdate then
            frame.ScrollBox:RegisterCallback(frame.ScrollBox.Event.OnUpdate,function() self:StyleRaiderRows() end,self)
        end
    end
    frame:SetSize(660,470)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER",self.frame.TalentsFrame,"CENTER",0,0)
    if frame.ScrollBox and frame.ScrollBox.ClearAllPoints then
        frame.ScrollBox:ClearAllPoints(); frame.ScrollBox:SetPoint("TOPLEFT",frame,"TOPLEFT",12,-74); frame.ScrollBox:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-28,12)
    end
    self:StyleRaiderRows()
end

function Talents:SelectLoadout(id)
    if not self:IsEditable() then return end
    local load=self.frame.TalentsFrame.LoadSystem
    if not load:IsSelectionIDValid(id) then return end
    if load.selectionEnabledCallback and not load.selectionEnabledCallback(id,true) then return end
    -- isUserInput=true is essential: this preserves Blizzard's pending-change
    -- confirmation, failed-load rollback and asynchronous selection handling.
    load:SetSelectionID(id,true)
    self:Refresh()
end

function Talents:SwitchSpec(index)
    if not self:IsEditable() or not C_SpecializationInfo.CanPlayerUseTalentSpecUI() then return end
    if type(index)~="number" or index%1~=0 or index<1 or index>GetNumSpecializations() then return end
    if index==C_SpecializationInfo.GetSpecialization() then return end
    if not C_SpecializationInfo.GetSpecializationInfo(index) then return end
    self.frame:CheckConfirmResetAction(function()
        if not self:IsEditable() then return end
        local accepted=C_SpecializationInfo.SetSpecialization(index)
        if accepted then self.status:SetText("Changing specialization...") end
    end)
end

-- Use native registered actions so new/import/export retain client restrictions.
function Talents:FindAction(text, entries)
    for _,entry in ipairs(entries or self.frame.TalentsFrame.LoadSystem.sentinelInfos or {}) do
        if entry.text==text and entry.callback then return entry end
        if entry.sentinelInfos then
            local found=self:FindAction(text,entry.sentinelInfos)
            if found then return found end
        end
    end
end

function Talents:ActionAvailable(text)
    if not self:IsEditable() then return false end
    local entry=self:FindAction(text)
    return entry and (not entry.disabledCallback or not entry.disabledCallback()) or false
end

function Talents:RunAction(text)
    if not self:ActionAvailable(text) then return end
    local load=self.frame.TalentsFrame.LoadSystem
    self:FindAction(text).callback(load:GetSelectionID(),load)
end

function Talents:EditLoadout(id)
    if not self:IsEditable() then return end
    local load=self.frame.TalentsFrame.LoadSystem
    if not id or not load:IsSelectionIDValid(id) then return end
    if load.canEditCallback and not load.canEditCallback(id) then return end
    if load.editEntryCallback then load.editEntryCallback(id) end
end

function Talents:CreateChrome()
    if self.chrome then return end
    local f=self.frame
    local bg=CreateFrame("Frame",nil,f,"BackdropTemplate")
    bg:SetAllPoints(); bg:SetFrameLevel(f:GetFrameLevel()); Surface(bg)
    self.background=bg
    local chrome=CreateFrame("Frame",nil,f)
    chrome:SetAllPoints(); chrome:SetFrameLevel(f:GetFrameLevel()+20)
    self.chrome=chrome
    self.title=Label(chrome,"Talents",18,-16,190,"GameFontNormalLarge")
    self.title:SetTextColor(Accent())
    Label(chrome,"PROJECT RUTHLESS",18,-42,190)
    self.specButtons={}
    for i=1,4 do
        local index=i
        local b=AUI:CreateButton(chrome); b:SetSize(174,44)
        b:SetPoint("TOPLEFT",SIDE+12+(i-1)*182,-14)
        b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetSize(28,28); b.icon:SetPoint("LEFT",8,0)
        b.label:ClearAllPoints(); b.label:SetPoint("LEFT",42,0); b.label:SetPoint("RIGHT",-6,0)
        b:SetScript("OnClick",function() self:SwitchSpec(index) end)
        b:HookScript("OnEnter",function(button)
            local _,name,description=C_SpecializationInfo.GetSpecializationInfo(index)
            if not name then return end
            GameTooltip:SetOwner(button,"ANCHOR_BOTTOM"); GameTooltip:SetText(name)
            GameTooltip:AddLine(description or "",0.8,0.82,0.88,true)
            GameTooltip:AddLine("Click to activate this specialization.",0.6,0.8,0.9,true); GameTooltip:Show()
        end)
        b:HookScript("OnLeave",function() GameTooltip:Hide() end)
        self.specButtons[i]=b
    end
    local sidebar=CreateFrame("Frame",nil,chrome,"BackdropTemplate")
    sidebar:SetPoint("TOPLEFT",10,-HEADER); sidebar:SetPoint("BOTTOMLEFT",10,10)
    sidebar:SetWidth(SIDE-10); Surface(sidebar); self.sidebar=sidebar
    Label(sidebar,"LOADOUTS",12,-14,180,"GameFontNormal")
    self.status=Label(sidebar,"",12,-42,186)
    self.status:SetHeight(38)
    local list=AUI:CreateListScroll(sidebar,46,1,function() self:RefreshRows() end)
    list:SetPoint("TOPLEFT",8,-88); list:SetPoint("BOTTOMRIGHT",-8,190)
    self.list=list; self.rows={}
    self.empty=Label(sidebar,"No saved loadouts.\nSave a copy of your current build to begin.",12,-100,183)
    self.actions={}
    local actions={
        {"Save copy",TALENT_FRAME_DROP_DOWN_NEW_LOADOUT,12,139},
        {"Import",TALENT_FRAME_DROP_DOWN_IMPORT,110,139},
        {"Export",TALENT_FRAME_DROP_DOWN_EXPORT_CLIPBOARD,12,104},
    }
    for _,info in ipairs(actions) do
        local actionText=info[2]
        local button=AUI:CreateButton(sidebar); button:SetSize(88,27)
        button:SetPoint("BOTTOMLEFT",info[3],info[4]); button:SetText(info[1])
        button:SetScript("OnClick",function() self:RunAction(actionText) end)
        local actionLabel=info[1]
        button:HookScript("OnEnter",function(widget)
            GameTooltip:SetOwner(widget,"ANCHOR_RIGHT"); GameTooltip:SetText(actionLabel)
            local entry=self:FindAction(actionText)
            if entry and entry.disabledCallback then
                local disabled,_,body,warning=entry.disabledCallback()
                if disabled then GameTooltip:AddLine(warning or body or "This action is currently unavailable.",1,0.6,0.3,true) end
            end
            if actionLabel=="Save copy" then GameTooltip:AddLine("Name a new copy of the current build.",0.8,0.82,0.88,true) end
            GameTooltip:Show()
        end)
        button:HookScript("OnLeave",function() GameTooltip:Hide() end)
        self.actions[#self.actions+1]={button=button,text=actionText}
    end
    local edit=AUI:CreateButton(sidebar); edit:SetSize(88,27); edit:SetPoint("BOTTOMLEFT",110,104)
    edit:SetText("Manage"); edit:SetScript("OnClick",function() self:EditLoadout(f.TalentsFrame.LoadSystem:GetSelectionID()) end)
    self.edit=edit
    Hint(edit,"Manage loadout","Rename, delete or change action-bar options for the selected loadout.")
    local close=AUI:CreateButton(chrome); close:SetSize(28,26); close:SetPoint("TOPRIGHT",-12,-14); close:SetText("X")
    close:SetScript("OnClick",function() HideUIPanel(f) end)
end

function Talents:RefreshRows()
    if not self.active or not self.list then return end
    local tree=self.frame.TalentsFrame
    local load=tree.LoadSystem
    local selected=load:GetSelectionID()
    local offset=self.list:GetItemOffset()
    local count=math.ceil(math.max(1,self.list:GetHeight())/46)+1
    for i=1,count do
        local row=self.rows[i]
        if not row then
            row=AUI:CreateButton(self.list.content); row:SetSize(182,42)
            row.label:SetJustifyH("LEFT"); row:RegisterForClicks("LeftButtonUp","RightButtonUp")
            row:SetScript("OnClick",function(button,mouse)
                if mouse=="RightButton" then self:EditLoadout(button.configID) else self:SelectLoadout(button.configID) end
            end)
            row:HookScript("OnEnter",function(button)
                GameTooltip:SetOwner(button,"ANCHOR_RIGHT"); GameTooltip:SetText(button.fullName or "Loadout")
                GameTooltip:AddLine("Click to load. Right-click to manage.",0.8,0.82,0.88,true); GameTooltip:Show()
            end)
            row:HookScript("OnLeave",function() GameTooltip:Hide() end)
            self.rows[i]=row
        end
        local entry=(self.entries or {})[offset+i]
        row:SetShown(entry~=nil)
        if entry then
            row.configID=entry.id; row.fullName=entry.name
            row:SetText((entry.id==selected and "|cffffffff> |r" or "")..entry.name)
            local enabled=self:IsEditable() and (not load.selectionEnabledCallback or load.selectionEnabledCallback(entry.id,true))
            row:SetEnabled(not not enabled)
            if entry.id==selected then row:SetBackdropBorderColor(Accent())
            else row:SetBackdropBorderColor(0.16,0.17,0.21,1) end
            self.list:PlaceItem(row,i)
        end
    end
    for i=count+1,#self.rows do self.rows[i]:Hide() end
end

function Talents:Refresh()
    if not self.active or not self.chrome then return end
    local tree=self.frame.TalentsFrame
    local current=C_SpecializationInfo.GetSpecialization()
    local numSpecs=GetNumSpecializations()
    for i,b in ipairs(self.specButtons) do
        local id,name,description,icon
        if i<=numSpecs then id,name,description,icon=C_SpecializationInfo.GetSpecializationInfo(i) end
        b:SetShown(id~=nil)
        if id then
            b:SetText(name..(i==current and "\nActive" or "")); b.icon:SetTexture(icon)
            b:SetEnabled(self:IsEditable() and i~=current and C_SpecializationInfo.CanPlayerUseTalentSpecUI())
            if i==current then b:SetBackdropBorderColor(Accent()); b.label:SetTextColor(Accent()) else b:SetBackdropBorderColor(0.16,0.17,0.21,1) end
        end
    end
    self.entries=self:GetEntries()
    self.list:SetItemCount(#self.entries,false)
    self.empty:SetShown(#self.entries==0)
    self.empty:SetText("No saved loadouts.\nSave a copy of your current build to begin.")
    if InCombatLockdown() then self.status:SetText("In combat - changes unavailable")
    elseif tree:IsCommitInProgress() then self.status:SetText("Applying build...")
    elseif UnitCastingInfo("player") or UnitChannelInfo("player") then self.status:SetText("Casting - please wait")
    elseif tree:HasAnyConfigChanges() then self.status:SetText("Pending changes\nApply or undo below the trees")
    else self.status:SetText("Current build\n"..((tree.configIDToName or {})[tree.LoadSystem:GetSelectionID()] or "Custom talents")) end
    for _,action in ipairs(self.actions) do action.button:SetEnabled(self:ActionAvailable(action.text)) end
    local id=tree.LoadSystem:GetSelectionID()
    self.edit:SetEnabled(self:IsEditable() and id~=nil and (not tree.LoadSystem.canEditCallback or tree.LoadSystem.canEditCallback(id)))
    self:StyleRaiderButton()
    if _G.RaiderIO_TalentBuildsFrame and _G.RaiderIO_TalentBuildsFrame:IsShown() then self:SkinRaiderWindow() end
    self:RefreshRows()
end

-- Capture only objects we alter and restore before inspect/native Spellbook.
function Talents:Remember(object,restoreVisibility)
    if not object or self.saved[object] then return end
    local s={points={},scale=object.GetScale and object:GetScale(),alpha=object:GetAlpha(),shown=object:IsShown(),width=object:GetWidth(),height=object:GetHeight(),restoreVisibility=restoreVisibility}
    for i=1,object:GetNumPoints() do s.points[i]={object:GetPoint(i)} end
    self.saved[object]=s
end

function Talents:Restore()
    if not self.active then return end
    self.active=false
    for object,s in pairs(self.saved) do
        if s.scale then object:SetScale(s.scale) end
        object:SetAlpha(s.alpha); object:SetSize(s.width,s.height)
        object:ClearAllPoints()
        for _,point in ipairs(s.points) do object:SetPoint(unpack(point)) end
        -- Only chrome hidden by us is restored. Native content visibility (in
        -- particular the inspect-mode load system) belongs to Blizzard.
        if s.restoreVisibility then object:SetShown(s.shown) end
    end
    self.saved={}; self.chrome:Hide(); self.background:Hide()
    self:RestoreRaiderButton()
    self.frame:UpdateTabs()
end

function Talents:ApplyLayout()
    if self.applying or not self.frame or InCombatLockdown() then return end
    self.applying=true
    local f=self.frame
    if not self:IsEnabled() or f:IsInspecting() or not f:IsTabAvailable(f.talentTabID)
        or f:GetTab()==f.spellBookTabID then
        self:Restore(); self.applying=false; return
    end
    if f:GetTab()==f.specTabID then f:SetTab(f.talentTabID) end
    if f:GetTab()~=f.talentTabID then self:Restore(); self.applying=false; return end
    self:CreateChrome()
    if not self.active then self.saved={}; self.active=true end
    self:Remember(f); self:Remember(f.TalentsFrame)
    for _,key in ipairs({"NineSlice","PortraitContainer","TitleContainer","Bg","CloseButton","MaximizeMinimizeButton","TabSystem"}) do
        if f[key] then self:Remember(f[key],true); f[key]:Hide() end
    end
    local tree=f.TalentsFrame
    local width=SIDE+24+1612*TREE_SCALE
    local height=HEADER+12+856*TREE_SCALE
    f:SetSize(width,height)
    local prefs=ProjectRuthlessDB.general
    local fit=math.min(prefs.windowScale or 1,UIParent:GetWidth()*0.94/width,UIParent:GetHeight()*0.9/height)
    f:SetScale(fit); f:SetAlpha(prefs.windowOpacity or 1)
    tree:SetScale(TREE_SCALE); tree:ClearAllPoints()
    tree:SetPoint("TOPLEFT",f,"TOPLEFT",(SIDE+12)/TREE_SCALE,-HEADER/TREE_SCALE)
    self:Remember(tree.LoadSystem)
    tree.LoadSystem:Hide()
    self:Remember(tree.SearchBox)
    tree.SearchBox:Hide()
    self.chrome:Show(); self.background:Show(); self:Refresh()
    self.applying=false
end

function Talents:Install()
    if self.installed or not PlayerSpellsFrame then return end
    local f=PlayerSpellsFrame
    if not f.TalentsFrame or not f.TalentsFrame.LoadSystem then return end
    self.frame=f; self.installed=true; self.saved={}
    for _,method in ipairs({"SetTab","UpdateTabs","SetInspecting","SetMinimized"}) do
        if f[method] then hooksecurefunc(f,method,function() self:ApplyLayout() end) end
    end
    f:HookScript("OnShow",function() self:ApplyLayout() end)
    for _,method in ipairs({"RefreshLoadoutOptions","UpdateConfigButtonsState","UpdateInspecting"}) do
        hooksecurefunc(f.TalentsFrame,method,function() self:Refresh() end)
    end
    hooksecurefunc(f.TalentsFrame.LoadSystem,"SetSelectionID",function() self:Refresh() end)
    f.TalentsFrame.LoadSystem:HookScript("OnShow",function(widget) if self.active then widget:Hide() end end)
    f.TalentsFrame.SearchBox:HookScript("OnShow",function(widget) if self.active then widget:Hide() end end)
    self:ApplyLayout()
end

function Talents:Show()
    if InCombatLockdown() then AUI:Print("Open Talents after combat."); return end
    PlayerSpellsUtil.OpenToClassTalentsTab()
    self:Install(); self:ApplyLayout()
end

function Talents:ApplySettings()
    self:ApplyLayout()
end

function Talents:OnPlayerLogin()
    self:Install()
    local events=CreateFrame("Frame")
    for _,event in ipairs({"ADDON_LOADED","PLAYER_SPECIALIZATION_CHANGED","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","TRAIT_CONFIG_LIST_UPDATED","TRAIT_CONFIG_UPDATED","DISPLAY_SIZE_CHANGED","UI_SCALE_CHANGED","UNIT_SPELLCAST_START","UNIT_SPELLCAST_STOP","UNIT_SPELLCAST_CHANNEL_START","UNIT_SPELLCAST_CHANNEL_STOP","UNIT_SPELLCAST_FAILED","UNIT_SPELLCAST_INTERRUPTED"}) do events:RegisterEvent(event) end
    events:SetScript("OnEvent",function(_,event,addon)
        if event=="ADDON_LOADED" then
            if addon=="Blizzard_PlayerSpells" then self:Install() end
        elseif self.frame then
            if event:find("^UNIT_") and addon~="player" then return end
            if event=="PLAYER_REGEN_ENABLED" or event=="DISPLAY_SIZE_CHANGED" or event=="UI_SCALE_CHANGED" then self:ApplyLayout() end
            self:Refresh()
        end
    end)
    self.events=events
end
