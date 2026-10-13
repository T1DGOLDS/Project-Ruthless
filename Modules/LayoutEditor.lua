local _,AUI=...
local E={targets={},movers={},history={}}
AUI:RegisterModule("LayoutEditor",E)
local function clone(t)local o={};for k,v in pairs(t or {})do o[k]=type(v)=="table"and clone(v)or v end;return o end
local function safe(fn,...)if type(fn)~="function"then return end;local ok,v=pcall(fn,...);if ok and not(issecretvalue and issecretvalue(v))then return v end end
local function finite(n)return type(n)=="number"and n==n and math.abs(n)<10000 end
function E:AccountLayouts()
    ProjectRuthlessDB.layoutProfiles=ProjectRuthlessDB.layoutProfiles or {layouts={}}
    local account=ProjectRuthlessDB.layoutProfiles;account.layouts=account.layouts or {}
    if not account.defaultChosen then account.default=nil end
    local legacy=ProjectRuthlessCharDB.layoutEditor
    if legacy and not legacy.accountMigrated then
        for name,state in pairs(legacy.layouts or {})do
            if not account.layouts[name]then account.layouts[name]=clone(state)end
        end
        legacy.accountMigrated=true
    end
    return account
end
function E:InitializeCharacter()
    local account=self:AccountLayouts()
    if ProjectRuthlessCharDB.layoutEditor then return end
    local state=not AUI.modules.UnifiedProfiles and account.default and account.layouts[account.default]
    local elements=clone(state);elements.__chat=nil;elements.__art=nil
    ProjectRuthlessCharDB.layoutEditor={elements=elements,layouts={},active=state and account.default or nil,accountMigrated=true,blizzardArt=state and state.__art and state.__art.blizzardArt==true or false}
    ProjectRuthlessCharDB.pendingLayoutChat=state and state.__chat and clone(state.__chat)or nil
end
function E:ProfileMenu(anchor)
    if InCombatLockdown()or not MenuUtil or type(MenuUtil.CreateContextMenu)~="function"then return end
    MenuUtil.CreateContextMenu(anchor,function(_,root)
        root:CreateTitle("Account profiles")
        local account=self:AccountLayouts();local names={}
        for name in pairs(account.layouts)do names[#names+1]=name end;table.sort(names)
        for _,name in ipairs(names)do
            local key=name
            root:CreateRadio(name..(account.default==name and " · default"or ""),function()return self:Store().active==key end,function()
                if self:Load(key)then self.name:SetText(key)end
            end)
        end
        if #names==0 then root:CreateTitle("Save a layout to get started")end
    end)
end
function E:SetDefaultProfile(name)
    local account=self:AccountLayouts()
    if name and not account.layouts[name]then return false end
    account.default=name;account.defaultChosen=true
    if self.defaultProfile then self.defaultProfile:SetText(name or "None")end
    return true
end
function E:DefaultProfileMenu(anchor)
    if InCombatLockdown()or not MenuUtil or type(MenuUtil.CreateContextMenu)~="function"then return end
    MenuUtil.CreateContextMenu(anchor,function(_,root)
        root:CreateTitle("Default for new characters")
        local account=self:AccountLayouts();local names={}
        root:CreateRadio("None",function()return not account.default end,function()self:SetDefaultProfile(nil)end)
        for name in pairs(account.layouts)do names[#names+1]=name end;table.sort(names)
        for _,name in ipairs(names)do local key=name
            root:CreateRadio(key,function()return account.default==key end,function()self:SetDefaultProfile(key)end)
        end
    end)
end
-- Native saved chat subscriptions, not message history or temporary whisper tabs.
function E:CaptureChat()
    if type(FCF_GetChatWindowInfo)~="function"or type(GetChatWindowMessages)~="function"or type(GetChatWindowChannels)~="function"then return end
    local tabs={}
    local dockFrames=type(FCFDock_GetChatFrames)=="function"and GENERAL_CHAT_DOCK and FCFDock_GetChatFrames(GENERAL_CHAT_DOCK)or {}
    local selected=type(FCFDock_GetSelectedWindow)=="function"and GENERAL_CHAT_DOCK and FCFDock_GetSelectedWindow(GENERAL_CHAT_DOCK)
    local max=Constants and Constants.ChatFrameConstants and Constants.ChatFrameConstants.MaxChatWindows or 10
    for id=1,max do
        local frame=_G["ChatFrame"..id]
        local name,size,r,g,b,a,shown,locked,docked,uninteractable=FCF_GetChatWindowInfo(id)
        if frame and not frame.isTemporary and (id<=2 or shown==true or shown==1 or docked==true or docked==1)then
            local dockIndex;for index,dockedFrame in ipairs(dockFrames)do if dockedFrame==frame then dockIndex=index;break end end
            tabs[#tabs+1]={dockIndex=dockIndex,selected=selected==frame,id=id,name=name,size=size,r=r,g=g,b=b,a=a,locked=locked==true or locked==1,
                docked=docked==true or docked==1,uninteractable=uninteractable==true or uninteractable==1,
                messages={GetChatWindowMessages(id)},channels={GetChatWindowChannels(id)},position=self:Capture(frame)}
        end
    end
    return tabs
end
function E:RestoreChat(tabs)
    if not tabs then return true end
    if InCombatLockdown()or type(FCF_OpenNewWindow)~="function"or type(FCF_GetChatWindowInfo)~="function"then return false end
    local max=Constants and Constants.ChatFrameConstants and Constants.ChatFrameConstants.MaxChatWindows or 10
    local ordered=clone(tabs);local selectedFrame;local restored={}
    table.sort(ordered,function(a,b)return (a.dockIndex or 100+a.id)<(b.dockIndex or 100+b.id)end)
    for _,tab in ipairs(ordered)do
        local frame=tab.id<=2 and _G["ChatFrame"..tab.id]or nil
        if not frame then
            for id=3,max do
                local candidate=_G["ChatFrame"..id]
                local name,_,_,_,_,_,shown,_,docked=FCF_GetChatWindowInfo(id)
                if candidate and not restored[candidate]and not candidate.isTemporary and name==tab.name and (shown==true or shown==1 or docked==true or docked==1)then frame=candidate;break end
            end
        end
        if not frame then frame=FCF_OpenNewWindow(tab.name,true)end
        if not frame then return false end
        restored[frame]=true
        FCF_SetWindowName(frame,tab.name);FCF_SetWindowColor(frame,tab.r,tab.g,tab.b);FCF_SetWindowAlpha(frame,tab.a)
        FCF_SetChatWindowFontSize(nil,frame,tab.size)
        frame:RemoveAllMessageGroups();for _,group in ipairs(tab.messages or {})do frame:AddMessageGroup(group)end
        frame:RemoveAllChannels();for i=1,#(tab.channels or {}),2 do frame:AddChannel(tab.channels[i])end
        if tab.selected then selectedFrame=frame end
        if tab.docked then
            if tab.dockIndex and frame~=DEFAULT_CHAT_FRAME and frame.isDocked then FCF_UnDockFrame(frame)end
            FCF_DockFrame(frame,tab.dockIndex,false)
        else
            if frame.isDocked then FCF_UnDockFrame(frame)end
            local v=tab.position
            if v and finite(v.x)and finite(v.y)and finite(v.width)and finite(v.height)then
                frame:SetScale(v.scale or 1)
                local ratio=UIParent:GetEffectiveScale()/frame:GetEffectiveScale()
                frame:SetSize(v.width,v.height);frame:ClearAllPoints();frame:SetPoint("CENTER",UIParent,"CENTER",v.x*ratio,v.y*ratio)
                if type(FCF_SavePositionAndDimensions)=="function"then FCF_SavePositionAndDimensions(frame)end
            end
        end
        FCF_SetLocked(frame,tab.locked);FCF_SetUninteractable(frame,tab.uninteractable)
    end
    -- Complete profiles describe the permanent tabs as one setup. Temporary
    -- whisper windows and the built-in General/Combat Log frames are retained.
    if AUI.modules.UnifiedProfiles and type(FCF_Close)=="function"then
        for id=3,max do local frame=_G["ChatFrame"..id]
            local _,_,_,_,_,_,shown,_,docked=FCF_GetChatWindowInfo(id)
            if frame and not frame.isTemporary and not restored[frame]and (shown==true or shown==1 or docked==true or docked==1)then FCF_Close(frame)end
        end
    end
    if selectedFrame and selectedFrame.isDocked and GENERAL_CHAT_DOCK and type(FCFDock_SelectWindow)=="function"then FCFDock_SelectWindow(GENERAL_CHAT_DOCK,selectedFrame)end
    return true
end
function E:Store()
    ProjectRuthlessCharDB.layoutEditor=ProjectRuthlessCharDB.layoutEditor or {elements={},layouts={}}
    return ProjectRuthlessCharDB.layoutEditor
end
function E:Capture(frame)
    local scale=safe(frame.GetScale,frame);local frameScale=safe(frame.GetEffectiveScale,frame);local parentScale=safe(UIParent.GetEffectiveScale,UIParent)
    local ok,x,y=pcall(frame.GetCenter,frame)
    local width,height=safe(frame.GetWidth,frame),safe(frame.GetHeight,frame)
    if not ok or (issecretvalue and (issecretvalue(x)or issecretvalue(y)))or not finite(x)or not finite(y)or not finite(scale)or not finite(frameScale)or not finite(parentScale)or parentScale==0 or not finite(width)or not finite(height)then return end
    local effective=frameScale/parentScale
    local value={x=x*effective-UIParent:GetWidth()/2,y=y*effective-UIParent:GetHeight()/2,scale=scale,width=width,height=height}
    if AUI.isForever and type(frame.system)=="number"and type(frame.settingDisplayInfoMap)=="table"and type(frame.GetSettingValue)=="function"then
        value.nativeSettings={}
        for setting in pairs(frame.settingDisplayInfoMap)do local v=safe(frame.GetSettingValue,frame,setting);if type(v)=="number"or type(v)=="boolean"then value.nativeSettings[setting]=v end end
    end
    return value
end
function E:Apply(id,value)
    local target=self.targets[id];local frame=target and target.frame
    if not frame or InCombatLockdown()or not value or not finite(value.x)or not finite(value.y)or not finite(value.scale or 1)or target.resize and (not finite(value.width)or not finite(value.height))then return false end
    local hud=AUI.modules.ForeverHUD;local applying=hud and hud.applying;if hud then hud.applying=true end
    if AUI.isForever and type(value.nativeSettings)=="table"and EditModeManagerFrame and type(EditModeManagerFrame.OnSystemSettingChange)=="function"and type(frame.GetSettingValue)=="function"then
        for setting,v in pairs(value.nativeSettings)do
            local current=safe(frame.GetSettingValue,frame,setting)
            if current~=nil and current~=v then EditModeManagerFrame:OnSystemSettingChange(frame,setting,v)end
        end
    end
    -- Release custom positions from native managed containers before combat.
    local native=AUI.isForever and type(frame.system)=="number"and type(frame.systemInfo)=="table"
    if native and type(frame.BreakFromFrameManager)=="function"then frame:BreakFromFrameManager()end
    frame:SetScale(math.max(.55,math.min(1.5,value.scale or 1)))
    local ratio=UIParent:GetEffectiveScale()/frame:GetEffectiveScale()
    frame:ClearAllPoints();frame:SetPoint("CENTER",UIParent,"CENTER",value.x*ratio,value.y*ratio)
    if target.resize then
        local bounds=type(target.resize)=="table"and target.resize or {minWidth=780,maxWidth=2400,minHeight=460,maxHeight=1600}
        frame:SetSize(math.max(bounds.minWidth,math.min(bounds.maxWidth,value.width)),math.max(bounds.minHeight,math.min(bounds.maxHeight,value.height)))
        if id=="map"then
            ProjectRuthlessCharDB.mapScale=frame:GetScale()
            ProjectRuthlessCharDB.mapSize={width=frame:GetWidth(),height=frame:GetHeight()}
            AUI.modules.QuestWorkspace:LayoutMap()
        end
    end
    -- SetPoint alone leaves Blizzard's default-position flag/anchor unchanged.
    -- Its own recorder keeps later native layout passes at the RUI position.
    if native and EditModeManagerFrame and type(EditModeManagerFrame.UpdateSystemAnchorInfo)=="function"then
        EditModeManagerFrame:UpdateSystemAnchorInfo(frame)
    end
    if hud then hud.applying=applying end
    return true
end
function E:Attach(id,label,frame,resize)
    if not frame or self.targets[id]then return end
    self.targets[id]={label=label,frame=frame,resize=resize,default=self:Capture(frame)}
    frame:HookScript("OnShow",function()local value=self:Store().elements[id];if value then self:Apply(id,value)end end)
    local value=self:Store().elements[id];if value then self:Apply(id,value)end
    if frame.GetBackdrop and frame:GetBackdrop()then AUI:StyleSurface(frame,"window",id=="quests"and math.max(.72,ProjectRuthlessDB.questWorkspace.opacity)or nil,({quests="Quest",spells="Spellbook",map="Map"})[id]or "Options")end
end
function E:Discover()
    for _,row in ipairs({{"quests","Quest tracker","QuestWorkspace"},{"menu","Control centre","Menu"},{"character","Character","Character"},{"spells","Spellbook","Spellbook"}})do
        local module=AUI.modules[row[3]];self:Attach(row[1],row[2],module and module.frame)
    end
    if AUI.modules.QuestWorkspace and AUI.modules.QuestWorkspace.mapPanel then self:Attach("map","Map and quest log",WorldMapFrame,true)end
end
function E:Snapshot()
    local state=clone(self:Store().elements)
    for id,target in pairs(self.targets)do state[id]=self:Capture(target.frame)or state[id]end
    state.__art={blizzardArt=self:Store().blizzardArt==true}
    state.__chat=self:CaptureChat()
    return state
end
function E:Checkpoint()
    local state
    if AUI.isForever and AUI.modules.UnifiedProfiles then state={__profile=AUI.modules.UnifiedProfiles:Capture(),__name=ProjectRuthlessCharDB.activeProfile}
    else state=self:Snapshot()end
    self.history[#self.history+1]=state;if #self.history>20 then table.remove(self.history,1)end
end
function E:Restore(state)
    if InCombatLockdown()then return end
    self:Store().elements=clone(state)
    self:Store().elements.__chat=nil;self:Store().elements.__art=nil
    self:Store().blizzardArt=state.__art and state.__art.blizzardArt==true or false
    for id,value in pairs(self:Store().elements)do self:Apply(id,value)end
    local style=AUI.modules.ForeverStyle;if style then style:ApplySettings()end
    ProjectRuthlessCharDB.pendingLayoutChat=nil
    if not self:RestoreChat(state.__chat)then ProjectRuthlessCharDB.pendingLayoutChat=clone(state.__chat)end
    self:Refresh()
end
function E:Undo()
    if InCombatLockdown()then return end
    local state=table.remove(self.history)
    if state then
        if state.__profile and AUI.modules.UnifiedProfiles then AUI.modules.UnifiedProfiles:Apply(state.__profile,state.__name)
        else self:Restore(state)end
    end
end
-- Coordinates are UIParent units from screen centre, independent of element scale.
function E:Snap(id,x,y)
    if not self.snapping then return x,y end
    local own=self.targets[id];local scale=own.frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
    local w,h=own.frame:GetWidth()*scale,own.frame:GetHeight()*scale
    local xs={0,-UIParent:GetWidth()/2+w/2+8,UIParent:GetWidth()/2-w/2-8}
    local ys={0,-UIParent:GetHeight()/2+h/2+8,UIParent:GetHeight()/2-h/2-8}
    local rects={}
    local ids={};for other in pairs(self.targets)do ids[#ids+1]=other end;table.sort(ids)
    for _,other in ipairs(ids)do local target=self.targets[other]
        if other~=id and target.frame:IsShown()then
            local v=self:Capture(target.frame)
            if v then
                local ratio=target.frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
                local rw,rh=v.width*ratio,v.height*ratio
                rects[#rects+1]={x=v.x,y=v.y,w=rw,h=rh}
                -- Matching centres, both edges, and an 8-unit breathing gap.
                for _,n in ipairs({v.x,v.x-rw/2+w/2,v.x+rw/2-w/2,v.x-rw/2-w/2-8,v.x+rw/2+w/2+8})do xs[#xs+1]=n end
                for _,n in ipairs({v.y,v.y-rh/2+h/2,v.y+rh/2-h/2,v.y-rh/2-h/2-8,v.y+rh/2+h/2+8})do ys[#ys+1]=n end
            end
        end
    end
    -- Equal gaps between adjacent elements on the same row or column.
    for i=1,#rects do for j=i+1,#rects do local l,r=rects[i],rects[j]
        if math.abs(l.y-r.y)<10 and math.abs(y-l.y)<20 then
            if l.x>r.x then l,r=r,l end
            if r.x-r.w/2-(l.x+l.w/2)>=w then xs[#xs+1]=(l.x+l.w/2+r.x-r.w/2)/2 end
        end
        l,r=rects[i],rects[j]
        if math.abs(l.x-r.x)<10 and math.abs(x-l.x)<20 then
            if l.y>r.y then l,r=r,l end
            if r.y-r.h/2-(l.y+l.h/2)>=h then ys[#ys+1]=(l.y+l.h/2+r.y-r.h/2)/2 end
        end
    end end
    local function nearest(value,lines)
        local best,distance=nil,10
        for _,line in ipairs(lines)do local delta=math.abs(value-line);if delta<distance then best,distance=line,delta end end
        local grid=self.gridSize or 8
        return best or math.floor(value/grid+.5)*grid,best
    end
    local sx,gx=nearest(x,xs);local sy,gy=nearest(y,ys)
    self.snapX,self.snapY=gx,gy
    return sx,sy
end
function E:SetCoordinate(field,text)
    if InCombatLockdown()or not self.selected then return end
    local number=tonumber(text);if not finite(number)then return end
    local target=self.targets[self.selected];local value=target and self:Capture(target.frame);if not value then return end
    self:Checkpoint();value[field]=number
    if self:Apply(self.selected,value)then self:Store().elements[self.selected]=self:Capture(target.frame)end
    self:Refresh()
end
function E:Change(field,amount)
    if InCombatLockdown()or not self.selected then return end
    local target=self.targets[self.selected];local value=self:Capture(target.frame);if not value then return end
    self:Checkpoint();value[field]=(value[field]or 0)+amount
    if self:Apply(self.selected,value)then self:Store().elements[self.selected]=self:Capture(target.frame)end
    self:Refresh()
end
function E:Resize(field,direction)
    local target=self.selected and self.targets[self.selected]
    local bounds=target and type(target.resize)=="table"and target.resize
    local step=bounds and (field=="width"and 10 or 2)or 40
    self:Change(field,direction*step)
end
function E:Save(name)
    name=(name or ""):match("^%s*(.-)%s*$")
    if InCombatLockdown()or name==""or #name>32 then return false end
    local layouts=self:AccountLayouts().layouts;local count=0;for _ in pairs(layouts)do count=count+1 end
    if not layouts[name]and count>=10 then return false end
    layouts[name]=self:Snapshot();self:Store().active=name;return true
end
function E:Load(name)
    local state=self:AccountLayouts().layouts[name];if not state or InCombatLockdown()then return false end
    self:Checkpoint();self:Restore(state);self:Store().active=name;return true
end
function E:Create()
    if self.frame then return end
    self.snapping=true;self.gridSize=self:Store().gridSize or 8;self.gridVisible=true
    local f=CreateFrame("Frame","ProjectRuthlessLayoutEditor",UIParent,"BackdropTemplate");self.frame=f
    f:SetSize(306,630);f:SetPoint("TOPLEFT",24,-80);f:SetFrameStrata("FULLSCREEN_DIALOG");f:SetClampedToScreen(true)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1});AUI:StyleSurface(f,"window")
    f:SetMovable(true);f:EnableMouse(true)
    local saved=self:Store().panelPosition
    if saved and finite(saved.x)and finite(saved.y)then
        f:ClearAllPoints();f:SetPoint("CENTER",UIParent,"CENTER",saved.x,saved.y)
    end
    local header=CreateFrame("Frame",nil,f);self.dragHeader=header
    header:SetPoint("TOPLEFT",0,0);header:SetPoint("TOPRIGHT",0,0);header:SetHeight(34);header:EnableMouse(true);header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart",function()if not InCombatLockdown()then f:StartMoving()end end)
    header:SetScript("OnDragStop",function()
        f:StopMovingOrSizing()
        local position=self:Capture(f)
        if position then self:Store().panelPosition={x=position.x,y=position.y}end
    end)
    local title=f:CreateFontString(nil,"OVERLAY","GameFontNormal");title:SetPoint("TOPLEFT",14,-14);title:SetText("RUI · Edit layout");title:SetTextColor(AUI:AccentColor())
    local info=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");info:SetPoint("TOPLEFT",14,-38);info:SetWidth(278);info:SetJustifyH("LEFT");info:SetText("Drag to align edges and equal gaps. Coordinates use screen-centre UI units.");info:SetTextColor(.65,.68,.75)
    local function button(text,x,y,width,fn)local b=AUI:CreateButton(f);b:SetPoint("TOPLEFT",x,y);b:SetSize(width,24);b:SetText(text);b:SetScript("OnClick",fn);return b end
    self.selectors={};self.page=1
    for i=1,12 do
        local b=button("",14+((i-1)%2)*142,-76-math.floor((i-1)/2)*25,136)
        b:SetScript("OnClick",function()self.selected=b.id;self:Refresh()end);self.selectors[i]=b
    end
    button("Previous",14,-225,84,function()self.page=math.max(1,self.page-1);self:Refresh()end)
    button("Next",208,-225,84,function()self.page=math.min(self.pageCount or 1,self.page+1);self:Refresh()end)
    self.detail=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");self.detail:SetPoint("TOPLEFT",14,-255);self.detail:SetWidth(278);self.detail:SetJustifyH("LEFT");self.detail:SetTextColor(.82,.84,.88)
    button("Left",14,-280,42,function()self:Change("x",-1)end);button("Right",60,-280,42,function()self:Change("x",1)end)
    button("Down",108,-280,42,function()self:Change("y",-1)end);button("Up",154,-280,42,function()self:Change("y",1)end)
    button("Scale −",14,-310,84,function()self:Change("scale",-.05)end);button("Scale +",102,-310,84,function()self:Change("scale",.05)end)
    self.snapButton=button("Snap: On",190,-310,102,function()self.snapping=not self.snapping;self:Refresh()end)
    self.widthMinus=button("Width −",14,-340,66,function()self:Resize("width",-1)end);self.widthPlus=button("Width +",84,-340,66,function()self:Resize("width",1)end)
    self.heightMinus=button("Height −",154,-340,66,function()self:Resize("height",-1)end);self.heightPlus=button("Height +",224,-340,68,function()self:Resize("height",1)end)
    self.gridButton=button("Grid: 8",14,-372,136,function()
        self.gridSize=self.gridSize==8 and 16 or self.gridSize==16 and 32 or 8;self:Store().gridSize=self.gridSize;self:Refresh()
    end)
    self.gridToggle=button("Grid: On",156,-372,136,function()self.gridVisible=not self.gridVisible;self:Refresh()end)
    self.coordinates={}
    for i,field in ipairs({"x","y"})do
        local label=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");label:SetPoint("TOPLEFT",14+(i-1)*142,-408);label:SetText(field:upper());label:SetTextColor(.65,.68,.75)
        local input=CreateFrame("EditBox",nil,f,"InputBoxTemplate");input:SetSize(105,22);input:SetPoint("TOPLEFT",36+(i-1)*142,-402);input:SetAutoFocus(false);input:SetMaxLetters(12)
        input:SetScript("OnEnterPressed",function(box)self:SetCoordinate(field,box:GetText());box:ClearFocus()end)
        input:SetScript("OnEscapePressed",function(box)box:ClearFocus();self:Refresh()end)
        self.coordinates[field]=input
    end
    self:CreateSettingsButton(f,button)
    local profileDefault
    if AUI.modules.UnifiedProfiles then profileDefault=AUI.modules.UnifiedProfiles:Store().default else profileDefault=self:AccountLayouts().default end
    self.name=CreateFrame("EditBox",nil,f,"InputBoxTemplate");self.name:SetPoint("TOPLEFT",20,-466);self.name:SetSize(126,24);self.name:SetAutoFocus(false);self.name:SetMaxLetters(AUI.modules.UnifiedProfiles and 64 or 32);self.name:SetText(self:Store().active or profileDefault or "")
    button("v",150,-466,28,function(button)self:ProfileMenu(button)end)
    button("Save",190,-466,48,function()local ok,message=self:Save(self.name:GetText());if message then AUI:Print(message)elseif not ok then AUI:Print("Enter a valid profile name.")end end)
    button("Load",242,-466,50,function()local ok,message=self:Load(self.name:GetText());if message then AUI:Print(message)elseif not ok then AUI:Print("No saved profile with that name.")end end)
    local defaultLabel=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");defaultLabel:SetPoint("TOPLEFT",14,-498);defaultLabel:SetText("Default for new characters")
    self.defaultProfile=button(profileDefault or "None",14,-514,278,function(anchor)self:DefaultProfileMenu(anchor)end)
    button("Undo",14,-550,84,function()self:Undo()end)
    button("Reset selected",102,-550,190,function()if self.selected and not InCombatLockdown()then self:Checkpoint();local t=self.targets[self.selected];self:Apply(self.selected,t.default);self:Store().elements[self.selected]=clone(t.default);self:Refresh()end end)
    button("Cancel",14,-588,134,function()self:Close(true)end);button("Done",158,-588,134,function()self:Close()end)
    self.guides={}
    for i=1,2 do local line=UIParent:CreateTexture(nil,"OVERLAY");line:SetColorTexture(.65,.68,.75,.25);if i==1 then line:SetWidth(1);line:SetPoint("TOP",UIParent,"TOP");line:SetPoint("BOTTOM",UIParent,"BOTTOM")else line:SetHeight(1);line:SetPoint("LEFT",UIParent,"LEFT");line:SetPoint("RIGHT",UIParent,"RIGHT")end;line:Hide();self.guides[i]=line end
    f:SetScript("OnHide",function()f:StopMovingOrSizing();if self.gridFrame then self.gridFrame:Hide()end;if EditModeSystemSettingsDialog then EditModeSystemSettingsDialog:Hide()end;for _,m in pairs(self.movers)do m:SetScript("OnUpdate",nil);m:StopMovingOrSizing();m:Hide()end;for _,line in ipairs(self.guides)do line:Hide()end end)
    if UISpecialFrames then UISpecialFrames[#UISpecialFrames+1]="ProjectRuthlessLayoutEditor"end
    f:Hide()
end
function E:Refresh()
    if not self.frame or not self.frame:IsShown()then return end
    self:Discover()
    local ids={"quests","map","menu","spells","backpack"};if not AUI.isForever then table.insert(ids,4,"character")end;local hudIDs={}
    for id,target in pairs(self.targets)do if target.hud then hudIDs[#hudIDs+1]=id end end
    table.sort(hudIDs,function(a,b)return self.targets[a].label<self.targets[b].label end)
    for _,id in ipairs(hudIDs)do ids[#ids+1]=id end
    self.pageCount=math.max(1,math.ceil(#ids/12));self.page=math.min(self.page,self.pageCount)
    for i,button in ipairs(self.selectors)do
        local id=ids[(self.page-1)*12+i];button.id=id;button:SetShown(id~=nil)
        if id then local target=self.targets[id];button:SetEnabled(target~=nil and (target.frame:IsShown()or target.preview)==true);button:SetText(target and target.label or id.." · open first")end
    end
    for id,target in pairs(self.targets)do
        local v=self:Capture(target.frame);local visible=v and (target.frame:IsShown()or target.preview)
        if visible then
            local mover=self.movers[id]
            if not mover then
                mover=CreateFrame("Frame",nil,UIParent,"BackdropTemplate");self.movers[id]=mover
                mover:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1});mover:SetFrameStrata("FULLSCREEN");mover:SetMovable(true);mover:EnableMouse(true);mover:RegisterForDrag("LeftButton")
                local label=mover:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");label:SetPoint("TOP",0,-4);mover.label=label;label:SetText(target.label);label:SetTextColor(AUI:AccentColor())
                mover:SetScript("OnMouseDown",function()self.selected=id;self:Refresh()end)
                mover:SetScript("OnDragStart",function()if not InCombatLockdown()then self.selected=id;self:Checkpoint();mover:StartMoving()
                    mover:SetScript("OnUpdate",function()
                        local position=self:Capture(mover);if not position then return end
                        local sx,sy=self:Snap(id,position.x,position.y)
                        label:SetText(("%s\nX %.1f · Y %.1f"):format(target.label,sx,sy))
                        self:UpdateGuides()
                    end)
                end end)
                mover:SetScript("OnDragStop",function()
                    mover:StopMovingOrSizing();mover:SetScript("OnUpdate",nil);if InCombatLockdown()then return end
                    local value=self:Capture(mover);local current=self:Capture(target.frame)
                    if value and current then current.x,current.y=self:Snap(id,value.x,value.y);self:Apply(id,current);self:Store().elements[id]=self:Capture(target.frame)end
                    self:Refresh()
                end)
            end
            local ratio=target.frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
            mover:ClearAllPoints();mover:SetPoint("CENTER",UIParent,"CENTER",v.x,v.y);mover:SetSize(target.frame:GetWidth()*ratio,target.frame:GetHeight()*ratio)
            mover.label:SetText(("%s\nX %.1f · Y %.1f · %.1f × %.1f"):format(target.label,v.x,v.y,v.width*ratio,v.height*ratio))
            mover:SetBackdropColor(.065,.07,.09,.2);local r,g,b=AUI:AccentColor();mover:SetBackdropBorderColor(r,g,b,self.selected==id and 1 or .4);mover:Show()
        elseif self.movers[id]then self.movers[id]:Hide()end
    end
    local target=self.selected and self.targets[self.selected];local v=target and self:Capture(target.frame)
    self.detail:SetText(v and ("%s\nX %.1f · Y %.1f · Scale %.0f%%"):format(target.label,v.x,v.y,v.scale*100)or "Select an open panel")
    for _,button in ipairs({self.widthMinus,self.widthPlus,self.heightMinus,self.heightPlus})do button:SetShown(target and target.resize or false)end
    self.snapButton:SetText(self.snapping and "Snap: On"or "Snap: Off")
    for field,input in pairs(self.coordinates)do if v and not input:HasFocus()then input:SetText(("%.1f"):format(v[field]))end end
    self:UpdateGuides();self:UpdateGrid()
end
function E:UpdateGrid()
    if not self.gridFrame then self.gridFrame=CreateFrame("Frame",nil,UIParent);self.gridFrame:SetAllPoints(UIParent);self.gridFrame:SetFrameStrata("BACKGROUND");self.gridFrame:EnableMouse(false);self.gridLines={}end
    self.gridFrame:SetShown(self.gridVisible==true)
    if self.gridButton then self.gridButton:SetText("Grid: "..self.gridSize);self.gridToggle:SetText(self.gridVisible and "Grid: On"or "Grid: Off")end
    if not self.gridVisible then return end
    local size=self.gridSize;local width,height=UIParent:GetWidth(),UIParent:GetHeight()
    local key=size..":"..width..":"..height;if self.gridKey==key then return end;self.gridKey=key
    for _,line in ipairs(self.gridLines)do line:Hide()end
    local count=0
    local function draw(vertical,offset,major)
        count=count+1;local line=self.gridLines[count]
        if not line then line=self.gridFrame:CreateTexture(nil,"BACKGROUND");self.gridLines[count]=line end
        line:ClearAllPoints();line:SetColorTexture(.65,.68,.73,major and .15 or .055)
        if vertical then line:SetWidth(1);line:SetPoint("TOP",UIParent,"TOP",offset,0);line:SetPoint("BOTTOM",UIParent,"BOTTOM",offset,0)
        else line:SetHeight(1);line:SetPoint("LEFT",UIParent,"LEFT",0,offset);line:SetPoint("RIGHT",UIParent,"RIGHT",0,offset)end
        line:Show()
    end
    for i=-math.floor(width/2/size),math.floor(width/2/size)do draw(true,i*size,i%4==0)end
    for i=-math.floor(height/2/size),math.floor(height/2/size)do draw(false,i*size,i%4==0)end
end
function E:UpdateGuides()
    if not self.guides then return end
    for i,line in ipairs(self.guides)do
        line:ClearAllPoints()
        if i==1 then line:SetPoint("TOP",UIParent,"TOP",self.snapX or 0,0);line:SetPoint("BOTTOM",UIParent,"BOTTOM",self.snapX or 0,0)
        else line:SetPoint("LEFT",UIParent,"LEFT",0,self.snapY or 0);line:SetPoint("RIGHT",UIParent,"RIGHT",0,self.snapY or 0)end
        line:SetShown(self.snapping)
    end
end
function E:CreateSettingsButton(f,button)
    self.nativeSettingsButton=button("Element settings",156,-434,136,function()self:OpenNativeSettings()end)
    button("Action bars",14,-434,136,function()
        local menu=AUI.modules.Menu
        if menu then menu:Show("actionbars")end
    end)
end
function E:OpenNativeSettings()
    if not AUI.isForever or InCombatLockdown()then return end
    local target=self.selected and self.targets[self.selected];local frame=target and target.frame
    local dialog=EditModeSystemSettingsDialog
    if not frame or type(frame.system)~="number"or not dialog or type(dialog.AttachToSystemFrame)~="function"then AUI:Print("This element uses RUI's position and size controls.");return end
    self:Checkpoint();dialog:AttachToSystemFrame(frame)
    local style=AUI.modules.ForeverStyle;if style then style:SkinNativeDialog(dialog)end
    dialog:ClearAllPoints();dialog:SetPoint("TOPLEFT",self.frame,"TOPRIGHT",12,0)
    if not self.nativeDialogHooked then
        self.nativeDialogHooked=true
        hooksecurefunc(dialog,"OnSettingValueChanged",function()
            if not self.frame or not self.frame:IsShown()or InCombatLockdown()then return end
            local selected=dialog.attachedToSystem
            for id,t in pairs(self.targets)do if t.frame==selected then self:Store().elements[id]=self:Capture(selected);break end end
            self:Refresh()
        end)
    end
end
function E:Show()
    if InCombatLockdown()then AUI:Print("Edit layout after combat.");return end
    self:Create();if self.frame:IsShown()then self:Refresh();return end
    self:Discover();self.before=self:Snapshot();self.history={};self.frame:Show();self:Refresh()
    if AUI.isForever and AUI.modules.UnifiedProfiles then self.beforeProfile=AUI.modules.UnifiedProfiles:Capture();self.beforeProfileName=ProjectRuthlessCharDB.activeProfile end
end
function E:Close(cancel)
    if EditModeSystemSettingsDialog then EditModeSystemSettingsDialog:Hide()end
    if not InCombatLockdown()then
        if cancel then
            if self.beforeProfile and AUI.modules.UnifiedProfiles then AUI.modules.UnifiedProfiles:Apply(self.beforeProfile,self.beforeProfileName)
            else self:Restore(self.before)end
        else local state=self:Snapshot();state.__chat=nil;state.__art=nil;self:Store().elements=state end
    end
    self.beforeProfile=nil;self.beforeProfileName=nil
    self.frame:Hide()
end
function E:InstallGameMenuEntry()
    if not AUI.isForever or self.gameMenuHooked or not GameMenuFrame or type(GameMenuFrame.InitButtons)~="function"then return end
    self.gameMenuHooked=true
    hooksecurefunc(GameMenuFrame,"InitButtons",function(menu)
        if InCombatLockdown()then return end
        for _,button in ipairs(menu.buttons or {})do
            if button:GetText()==HUD_EDIT_MODE_MENU then
                button:SetText("RUI Edit Mode")
                button:SetScript("OnClick",function()if InCombatLockdown()then return end;HideUIPanel(GameMenuFrame);self:Show()end)
                break
            end
        end
    end)
end
function E:OnAddonLoaded()
    self:InstallGameMenuEntry()
    local menu=AUI.modules.Menu
    if menu and type(menu.Create)=="function"and not self.hookedMenu then self.hookedMenu=true;hooksecurefunc(menu,"Create",function()self:Discover()end)end
end
function E:OnPlayerLogin()
    self:InstallGameMenuEntry()
    local events=CreateFrame("Frame");events:RegisterEvent("PLAYER_REGEN_DISABLED")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    local function restorePendingChat()
        local tabs=ProjectRuthlessCharDB.pendingLayoutChat
        if tabs and self:RestoreChat(tabs)then ProjectRuthlessCharDB.pendingLayoutChat=nil end
    end
    events:SetScript("OnEvent",function(_,event)
        if event=="PLAYER_REGEN_ENABLED"then restorePendingChat()
        elseif self.frame and self.frame:IsShown()then self:Close()end
    end)
    C_Timer.After(0,restorePendingChat)
    self:Discover()
    for _,spec in ipairs({{"QuestWorkspace","CreateWorkspace"},{"QuestWorkspace","InstallMap"},{"Spellbook","Create"},{"Character","CreateWindow"},{"Achievements","CreateDashboard"}})do
        local module=AUI.modules[spec[1]];if module and type(module[spec[2]])=="function"then hooksecurefunc(module,spec[2],function()self:Discover()end)end
    end
end
