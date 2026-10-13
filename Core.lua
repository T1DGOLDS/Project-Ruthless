local addonName, AUI = ...

ProjectRuthless = AUI
AUI.name = addonName
AUI.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "dev"
AUI.modules = {}
AUI.moduleOrder = {}

local interfaceVersion = type(GetBuildInfo) == "function" and select(4, GetBuildInfo()) or 0
AUI.interfaceVersion = tonumber(interfaceVersion) or 0
AUI.isForever = AUI.interfaceVersion >= 16000 and AUI.interfaceVersion < 20000

local foreverUnsupported = {
    Character = true,
    Talents = true,
    Achievements = true,
}

function AUI:IsFeatureSupported(feature)
    return not (self.isForever and foreverUnsupported[feature])
end

function AUI:PrintFeatureUnavailable(feature)
    self:Print(("%s uses Blizzard's native window in the WoW Forever beta while its Camelot layout is being validated."):format(feature))
end

local defaults = {
    enabled = true,
    general = {
        windowScale = 1.00,
        windowOpacity = 1.00,
        partyGrouped = false,
    },
    character = {
        replaceBlizzard = false,
        showItemLevels = true,
        showProgress = true,
    },
    spellbook = {
        replaceProfessions = true,
        separateFromTalents = true,
        showOffSpec = true,
        highlightMissing = true,
        macroAutocomplete = true,
        autoUpdateRanks = true,
        pinnedSpells = {},
        macroBackups = {},
        state = {
            mode = "class",
            spellFilter = "all",
            searchText = "",
            scroll = {},
            macroScope = "character",
            macroSearch = "",
            selectedMacros = {},
            selectedMacroKeys = {},
        },
    },
    talents = {
        enabled = true,
    },
    achievements = {
        enabled = true,
    },
    mapQuests = {
        enabled = true,
        showLocalStories = true,
        showTrivial = true,
        showAccountCompleted = false,
    },
    questWorkspace = { guideSource = "RUI", autoHandIn = false, prepWestfall = false, enabled = false, showArrow = true, opacity = .52, locked = false },
    errorLog = {
        enabled = true,
        entries = {},
        maxEntries = 50,
    },
    lowHealthGlow = {
        enabled = true,
        threshold = 0.35,
        maxAlpha = 0.40,
    },
    titles = {
        favorites = {},
        firstSeen = {},
        knownAtInstall = {},
        initialized = false,
        sort = "alphabetical",
        favoritesOnly = false,
    },
}

local function ApplyDefaults(target, source)
    for key, value in pairs(source) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {}
            end
            ApplyDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

function AUI:RegisterModule(name, module)
    if not self.modules[name]then self.moduleOrder[#self.moduleOrder+1]=name end
    self.modules[name] = module
end

function AUI:Print(message)
    print(("|cff7f5af0Project Ruthless|r: %s"):format(message))
end

function AUI:ApplyWindowSettings(key)
    local settings=ProjectRuthlessDB and ProjectRuthlessDB.general or {}
    local scale=settings.windowScale or 1
    local alpha=settings.windowOpacity or 1
    for _,moduleName in ipairs({"Menu","Character","Spellbook"}) do
        local module=self.modules[moduleName]
        if module and module.frame then
            if key~="windowOpacity"then module.frame:SetScale(scale)end
            if key~="windowScale"then module.frame:SetAlpha(alpha)end
        end
    end
    if key~="windowOpacity"and self.modules.Talents then self.modules.Talents:ApplySettings() end
    local editor=self.modules.LayoutEditor
    if not key and editor and ProjectRuthlessCharDB and ProjectRuthlessCharDB.layoutEditor then for id,value in pairs(ProjectRuthlessCharDB.layoutEditor.elements or {})do editor:Apply(id,value)end end
end

function AUI:SettingsChanged(section,key)
    if section=="Backgrounds"then self:RefreshBackgrounds(key);return end
    if section=="General"then self:ApplyWindowSettings(key);return end
    local module=self.modules[section]
    if module and module.ApplySettings then module:ApplySettings() end
end

-- Shared action-button treatment. Rows/tabs keep their selection-specific styling.
function AUI:CreateButton(parent)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    local _,class=UnitClass("player")
    local color=class and RAID_CLASS_COLORS[class]
    local r,g,b=color and color.r or 0.5,color and color.g or 0.35,color and color.b or 0.94
    if self.isForever then self:PaintBackground(button,"Options",.035,.039,.052)else button:SetBackdropColor(0.035,0.039,0.052,0.98)end
    button:SetBackdropBorderColor(0.16,0.17,0.21,1)
    local label=button:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    label:SetPoint("LEFT",5,0); label:SetPoint("RIGHT",-5,0); label:SetJustifyH("CENTER")
    label:SetTextColor(r,g,b,1); button:SetFontString(label); button.label=label
    button:HookScript("OnEnter",function(self) if self:IsEnabled() then if AUI.isForever then AUI:PaintBackground(self,"Options",.075,.065,.09)else self:SetBackdropColor(.075,.065,.09,1)end;self:SetBackdropBorderColor(r,g,b,0.9) end end)
    button:HookScript("OnLeave",function(self)if AUI.isForever then AUI:PaintBackground(self,"Options",.035,.039,.052)else self:SetBackdropColor(.035,.039,.052,.98)end;self:SetBackdropBorderColor(0.16,0.17,0.21,1)end)
    button:HookScript("OnDisable",function() label:SetTextColor(0.40,0.42,0.48,1) end)
    button:HookScript("OnEnable",function() label:SetTextColor(r,g,b,1) end)
    return button
end

-- Demand-driven runtime helpers.
-- Shared appearance tokens keep map, tracker and options on the same palette.
AUI.Theme={window={.025,.028,.035,.98},sidebar={.035,.039,.052,.99},surface={.065,.070,.090,.96},border={.16,.17,.21,.9},text={.91,.92,.96,1},muted={.52,.55,.64,1}}
function AUI:AccentColor()
    local _,class=UnitClass("player");local c=class and RAID_CLASS_COLORS[class]
    return c and c.r or .5,c and c.g or .35,c and c.b or .94
end
-- Background-only opacity. Owned backdrops are registered once, never whole frames.
AUI.backgrounds=setmetatable({},{__mode="k"})
AUI.backgroundGroups={{"Quest","Quest tracker"},{"Player","Player frame"},{"Target","Target frame"},{"Party","Party frame"},{"Chat","Chat"},{"ActionBars","Action bars"},{"XP","XP / reputation bars"},{"Micro","Micro menu"},{"BagButtons","Bag buttons"},{"Backpack","Open bags"},{"Meters","Damage meters"},{"Map","Map and quest log"},{"Spellbook","Spellbook"},{"Cast","Cast / attack timers"},{"Options","Settings and edit mode"},{"Professions","Professions"}}
function AUI:BackgroundOpacity(key)
    local db=ProjectRuthlessDB or {};local settings=db.general or {}
    local value=key and settings["background"..key]
    if type(value)~="number"or value<0 then value=settings.backgroundOpacity end
    if type(value)~="number"then value=math.max(.72,(db.questWorkspace or {}).opacity or .52)end
    return math.max(0,math.min(1,value))
end
function AUI:PaintBackground(frame,key,r,g,b,texture)
    self.backgrounds[frame]={key=key,r=r,g=g,b=b,texture=texture}
    local alpha=self:BackgroundOpacity(key)
    if self.BackgroundColor then r,g,b=self:BackgroundColor(key,r,g,b)end
    if texture then frame:SetColorTexture(r,g,b,alpha)else frame:SetBackdropColor(r,g,b,alpha)end
end
function AUI:RefreshBackgrounds(key)
    for frame,style in pairs(self.backgrounds)do
        if not key or key==style.key then
        local alpha=self:BackgroundOpacity(style.key)
        local r,g,b=style.r,style.g,style.b
        if self.BackgroundColor then r,g,b=self:BackgroundColor(style.key,r,g,b)end
        if style.texture then frame:SetColorTexture(r,g,b,alpha)else frame:SetBackdropColor(r,g,b,alpha)end
        end
    end
    local details=Details or _detalhes
    if (not key or key=="Meters")and self.isForever and type(details)=="table"and type(details.GetAllInstances)=="function"then
        local ok,instances=pcall(details.GetAllInstances,details)
        if ok and type(instances)=="table"then for _,instance in ipairs(instances)do if type(instance.SetBackgroundAlpha)=="function"then instance:SetBackgroundAlpha(0)end end end
    end
end
function AUI:StyleSurface(frame,role,opacity,key)
    local c=self.Theme[role or "window"] or self.Theme.window
    if self.isForever then self:PaintBackground(frame,key or "Options",c[1],c[2],c[3])
    else frame:SetBackdropColor(c[1],c[2],c[3],opacity or c[4])end
end
-- One native interval timer per visible consumer; no Lua dispatch at frame rate.
function AUI:BindInterval(view,interval,callback)
    local timer
    local function stop()if timer then timer:Cancel();timer=nil end end
    local function start()
        stop()
        if not view:IsVisible() then return end
        timer=C_Timer.NewTicker(interval,function()
            if not view:IsVisible() then stop();return end
            callback()
        end)
    end
    view:HookScript("OnShow",start);view:HookScript("OnHide",stop)
    if view:IsVisible()then start()end
    return stop
end
-- Keyed render work resumes after combat, using current state rather than stale inputs.
function AUI:AfterCombat(key,callback)
    if not InCombatLockdown()then callback();return end
    self.combatWork=self.combatWork or {};self.combatWork[key]=callback
    if not self.combatEvents then
        self.combatEvents=CreateFrame("Frame")
        self.combatEvents:SetScript("OnEvent",function(frame)
            frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
            local pending=self.combatWork;self.combatWork={}
            for _,fn in pairs(pending)do xpcall(fn,geterrorhandler())end
        end)
    end
    self.combatEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
end
local function IsViewVisible(view)
    if not view then return false end
    if view.IsVisible then local visible=view:IsVisible();if visible~=nil then return visible end end
    return view:IsShown()
end
function AUI:QueueRefresh(owner,method)
    method=method or "Refresh"
    owner.refreshQueue=owner.refreshQueue or {}
    if owner.refreshQueue[method] then return end
    owner.refreshQueue[method]=true
    C_Timer.After(0,function()
        owner.refreshQueue[method]=nil
        local view=owner.panel or owner.dashboard or owner.frame
        if IsViewVisible(view)then owner[method](owner)end
    end)
end

function AUI:BindVisibleEvents(view,events,names)
    if events.boundView==view then return end
    events.boundView=view
    local function activate()
        for _,name in ipairs(names)do
            if name:match("^UNIT_") then events:RegisterUnitEvent(name,"player")else events:RegisterEvent(name)end
        end
    end
    view:HookScript("OnShow",activate)
    view:HookScript("OnHide",function()for _,name in ipairs(names)do events:UnregisterEvent(name)end end)
    if IsViewVisible(view)then activate()end
end
-- End demand-driven runtime helpers.
for _,group in ipairs(AUI.backgroundGroups)do defaults.general["background"..group[1]]=-1 end


function AUI:CreateSmoothScrollFrame(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    scroll:EnableMouseWheel(true)
    scroll.scrollStep = 30 -- Character stats baseline, shared by every view.
    scroll.targetScroll = 0

    local track = CreateFrame("Frame", nil, scroll, "BackdropTemplate")
    track:SetWidth(4)
    track:SetPoint("TOPRIGHT", -2, -2)
    track:SetPoint("BOTTOMRIGHT", -2, 2)
    track:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    track:SetBackdropColor(0.08, 0.085, 0.105, 0.72)

    local thumb = CreateFrame("Frame", nil, track, "BackdropTemplate")
    thumb:SetWidth(4)
    thumb:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    local _, class = UnitClass("player")
    local color = class and RAID_CLASS_COLORS[class]
    thumb:SetBackdropColor(color and color.r or 0.5, color and color.g or 0.35, color and color.b or 0.94, 0.95)
    thumb:EnableMouse(true)
    thumb:RegisterForDrag("LeftButton")
    thumb:SetScript("OnDragStart", function(self)
        local _,y=GetCursorPosition()
        self.dragOffset=self:GetTop()-y/self:GetEffectiveScale()
        self.dragging = true
    end)
    thumb:SetScript("OnDragStop", function(self) self.dragging = false end)
    scroll:SetScript("OnHide",function() thumb.dragging=false end)

    local function UpdateThumb()
        local range = scroll:GetVerticalScrollRange() or 0
        local trackHeight = math.max(track:GetHeight() or 1, 1)
        local viewHeight = math.max(scroll:GetHeight() or 1, 1)
        local child = scroll:GetScrollChild()
        local contentHeight = child and math.max(child:GetHeight() or viewHeight, viewHeight) or viewHeight
        local thumbHeight = math.max(28, trackHeight * viewHeight / contentHeight)
        thumbHeight = math.min(thumbHeight, trackHeight)
        thumb:SetHeight(thumbHeight)
        local travel = math.max(trackHeight - thumbHeight, 0)
        local fraction = range > 0 and scroll:GetVerticalScroll() / range or 0
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", track, "TOP", 0, -(travel * fraction))
        track:SetShown(range > 0)
    end

    local Animate
    local function StartAnimation() scroll:SetScript("OnUpdate",Animate)end
    scroll:HookScript("OnHide",function()scroll:SetScript("OnUpdate",nil)end)
    scroll:HookScript("OnShow",function()scroll:ScrollTo(scroll.targetScroll,true);scroll.UpdateThumb()end)
    thumb:HookScript("OnDragStart",StartAnimation)
    thumb:HookScript("OnDragStop",StartAnimation)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local range = self:GetVerticalScrollRange() or 0
        self.targetScroll = math.max(0, math.min(range, (self.targetScroll or self:GetVerticalScroll()) - delta * self.scrollStep))
        StartAnimation()
    end)
    Animate=function(self, elapsed)
        local range = self:GetVerticalScrollRange() or 0
        if thumb.dragging and range > 0 then
            local _, cursorY = GetCursorPosition()
            local scale = track:GetEffectiveScale()
            local trackHeight = track:GetHeight()
            local travel = math.max(trackHeight - thumb:GetHeight(), 1)
            local fraction = math.max(0, math.min(1, (track:GetTop() - cursorY / scale - (thumb.dragOffset or 0)) / travel))
            self.targetScroll = range * fraction
        end
        self.targetScroll = math.max(0, math.min(range, self.targetScroll or 0))
        local current = self:GetVerticalScroll()
        local nextValue = current + (self.targetScroll - current) * math.min(1, elapsed * 12)
        if math.abs(self.targetScroll-current)>0.05 then self:SetVerticalScroll(nextValue)
        elseif current~=self.targetScroll then self:SetVerticalScroll(self.targetScroll) end
        UpdateThumb()
        if not thumb.dragging and math.abs(self.targetScroll-self:GetVerticalScroll())<=.05 then self:SetScript("OnUpdate",nil)end
    end
    scroll:HookScript("OnSizeChanged",UpdateThumb)
    scroll:HookScript("OnScrollRangeChanged",UpdateThumb)
    scroll:HookScript("OnVerticalScroll",UpdateThumb)
    scroll.UpdateThumb = UpdateThumb
    function scroll:ScrollTo(value, immediate)
        self.targetScroll=math.max(0,math.min(self:GetVerticalScrollRange() or 0,value or 0))
        if immediate then self:SetVerticalScroll(self.targetScroll);UpdateThumb();self:SetScript("OnUpdate",nil)else StartAnimation()end
    end
    return scroll
end

-- Pixel scrolling with a small recyclable row pool (also used by icon grids).
function AUI:CreateListScroll(parent, rowHeight, columns, refresh)
    local scroll=self:CreateSmoothScrollFrame(parent)
    local content=CreateFrame("Frame",nil,scroll); content:SetSize(1,1); scroll:SetScrollChild(content)
    scroll.content=content; scroll.itemCount=0; scroll.columns=columns or 1; scroll.rowHeight=rowHeight
    scroll:HookScript("OnSizeChanged",function(self,width) content:SetWidth(math.max(1,width-8)) end)
    function scroll:GetItemOffset() return math.floor(self:GetVerticalScroll()/self.rowHeight)*self.columns end
    function scroll:SetItemCount(count,reset)
        self.itemCount=count
        local height=math.max(1,math.ceil(count/self.columns)*self.rowHeight)
        if content:GetHeight()~=height then content:SetHeight(height) end
        if reset then self:ScrollTo(0,true) end
    end
    function scroll:PlaceItem(frame,index,columnWidth)
        local absolute=self:GetItemOffset()+index-1
        frame:ClearAllPoints(); frame:SetPoint("TOPLEFT",content,"TOPLEFT",(absolute%self.columns)*(columnWidth or 0),-math.floor(absolute/self.columns)*self.rowHeight)
    end
    scroll:HookScript("OnVerticalScroll",function(self)
        local offset=self:GetItemOffset()
        if self.lastOffset~=offset and not self.refreshing then
            self.lastOffset=offset; self.refreshing=true; refresh(); self.refreshing=false
        end
    end)
    return scroll
end

function AUI:ConfigureScrollingEditBox(editBox,scroll,minimumHeight)
    editBox:EnableMouseWheel(true)
    editBox:SetScript("OnMouseWheel",function(_,delta) scroll:GetScript("OnMouseWheel")(scroll,delta) end)
    editBox:SetScript("OnCursorChanged",function(_,x,y,width,height)
        local top=-y; local current=scroll.targetScroll or scroll:GetVerticalScroll()
        if top<current then scroll:ScrollTo(top)
        elseif top+height>current+scroll:GetHeight() then scroll:ScrollTo(top+height-scroll:GetHeight()) end
    end)

    -- SimpleEditBox has no GetStringHeight method on every supported client.
    -- Measure through a FontString, which exposes the API on both Retail and
    -- Forever, and keep it invisible by leaving it unanchored.
    local measurement=editBox:CreateFontString(nil,"ARTWORK")
    local fontPath,fontHeight,fontFlags=editBox:GetFont()
    if fontPath then measurement:SetFont(fontPath,fontHeight,fontFlags) else measurement:SetFontObject(ChatFontNormal) end
    local function UpdateHeight(box)
        local left,right,top,bottom=box:GetTextInsets()
        measurement:SetWidth(math.max(1,box:GetWidth()-(left or 0)-(right or 0)))
        measurement:SetText(box:GetText() or "")
        local height=math.max(minimumHeight or 1,measurement:GetStringHeight()+(top or 0)+(bottom or 0)+4)
        if math.abs((box:GetHeight() or 0)-height)>0.5 then box:SetHeight(height) end
    end
    editBox:HookScript("OnTextChanged",UpdateHeight)
    editBox:HookScript("OnSizeChanged",function(box,width)
        if width and width~=box.measurementWidth then box.measurementWidth=width; UpdateHeight(box) end
    end)
end

function AUI:ShowStatus()
    local client = self.isForever and "WoW Forever beta" or "Retail"
    self:Print(("v%s | %s (%d) | Native UI foundations"):format(self.version,client,self.interfaceVersion))
end

function AUI:ShowPerformance()
    local profiler=C_AddOnProfiler
    local metrics=Enum and Enum.AddOnProfilerMetric
    if not profiler or not profiler.GetAddOnMetric or not metrics or profiler.IsEnabled and not profiler.IsEnabled()then self:Print("CPU metrics are unavailable in this client.");return end
    local function read(metric)
        if metric==nil then return end
        local ok,value=pcall(profiler.GetAddOnMetric,self.name,metric)
        if ok and type(value)=="number" and not (issecretvalue and issecretvalue(value))then return value end
    end
    local recent,peak=read(metrics.RecentAverageTime),read(metrics.PeakTime)
    if recent==nil or peak==nil then self:Print("CPU metrics are unavailable right now.");return end
    self:Print(("CPU · recent average %.3f ms/tick · session peak %.3f ms/tick"):format(recent,peak))
end

local function HandleSlashCommand(input)
    local command = strtrim(input or ""):lower()

    if command == "" then
        if AUI.modules.Menu then
            AUI.modules.Menu:Show("general")
        else
            AUI:ShowStatus()
        end
        return
    end

    if command=="edit"or command=="layout"then AUI.modules.LayoutEditor:Show();return end

    if (command=="leveling"or command=="levels")and AUI.modules.LevelHistory then AUI.modules.LevelHistory:Show();return end

    if command=="perf" then AUI:ShowPerformance();return end

    if command == "status" then
        AUI:ShowStatus()
        return
    end
    if AUI.modules.Diagnostics and (command=="report"or command=="record"or command:match("^record "))then AUI.modules.Diagnostics:HandleCommand(command);return end

    if command == "talents" and AUI.modules.Talents then
        AUI.modules.Talents:Show()
        return
    end

    if command == "spellbook" and AUI.modules.Spellbook then
        AUI.modules.Spellbook:Show("class")
        return
    end

    if (command == "achievements" or command == "statistics") and AUI.modules.Achievements then
        AUI.modules.Achievements:Show()
        return
    end

    if (command == "map" or command == "quests") and AUI.modules.Menu then
        AUI.modules.Menu:Show("mapquests")
        return
    end

    if command=="tooltip on"or command=="tooltip off"then
        AUI:Print("Legacy compatibility command retired. RUI does not change another addon's tooltip settings.")
        return
    end

    local errorCommand = command:match("^errors%s*(.*)$")
    if errorCommand ~= nil and AUI.modules.ErrorLog then
        AUI.modules.ErrorLog:HandleCommand(errorCommand)
        return
    end

    local healthGlowCommand = command:match("^healthglow%s*(.*)$")
    if healthGlowCommand ~= nil and AUI.modules.LowHealthGlow then
        AUI.modules.LowHealthGlow:HandleCommand(healthGlowCommand)
        return
    end

    local achievementCommand=not AUI.isForever and ", /pr achievements" or ""
    AUI:Print("Commands: /pr, /pr status, /pr perf, /pr record on|off, /pr report, /pr spellbook, /pr talents"..achievementCommand..", /pr quests, /pr errors, /pr healthglow test")
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == addonName then
        eventFrame:UnregisterEvent("ADDON_LOADED")
        ProjectRuthlessDB = ProjectRuthlessDB or {}
        ProjectRuthlessCharDB = ProjectRuthlessCharDB or {}
        ApplyDefaults(ProjectRuthlessDB, defaults)
        if AUI.isForever and ProjectRuthlessDB.general.backgroundOpacity==nil then ProjectRuthlessDB.general.backgroundOpacity=math.max(.72,ProjectRuthlessDB.questWorkspace.opacity or .52)end
        if AUI.isForever and AUI.modules.UnifiedProfiles then AUI.modules.UnifiedProfiles:InitializeCharacter()end
        if AUI.modules.LayoutEditor then AUI.modules.LayoutEditor:InitializeCharacter()end

        -- v0.11.0 restores Blizzard's Character frame for every existing
        -- installation. The experimental replacement can be enabled again
        -- explicitly from /pr after the user chooses to test it.
        if not AUI.isForever and not ProjectRuthlessDB.character.nativeReset110 then
            ProjectRuthlessDB.character.replaceBlizzard = false
            ProjectRuthlessDB.character.nativeReset110 = true
        end

        SLASH_PROJECTRUTHLESS1 = "/pr"
        SlashCmdList.PROJECTRUTHLESS = HandleSlashCommand

        if AUI.modules.ErrorLog then
            AUI.modules.ErrorLog:Install()
        end

        for _, name in ipairs(AUI.moduleOrder) do
            local module=AUI.modules[name]
            if module.OnAddonLoaded then
                module:OnAddonLoaded()
            end
        end
    elseif event == "PLAYER_LOGIN" then
        eventFrame:UnregisterEvent("PLAYER_LOGIN")
        for _, name in ipairs(AUI.moduleOrder) do
            local module=AUI.modules[name]
            if module.OnPlayerLogin then
                module:OnPlayerLogin()
            end
        end

        if not ProjectRuthlessCharDB.welcomed then
            AUI:Print(("v%s loaded. Type /pr to open the menu."):format(AUI.version))
            ProjectRuthlessCharDB.welcomed = true
        end
    end
end)
