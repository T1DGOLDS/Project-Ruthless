local addonName, AUI = ...

ProjectRuthless = AUI
AUI.name = addonName
AUI.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "dev"
AUI.modules = {}

local defaults = {
    enabled = true,
    general = {
        windowScale = 1.00,
        windowOpacity = 1.00,
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
    elvui = {
        safeTooltip = true,
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
    self.modules[name] = module
end

function AUI:Print(message)
    print(("|cff7f5af0Project Ruthless|r: %s"):format(message))
end

function AUI:ApplyWindowSettings()
    local settings=ProjectRuthlessDB and ProjectRuthlessDB.general or {}
    local scale=settings.windowScale or 1
    local alpha=settings.windowOpacity or 1
    for _,moduleName in ipairs({"Menu","Character","Spellbook"}) do
        local module=self.modules[moduleName]
        if module and module.frame then module.frame:SetScale(scale); module.frame:SetAlpha(alpha) end
    end
    if self.modules.Talents then self.modules.Talents:ApplySettings() end
end

function AUI:SettingsChanged(section)
    self:ApplyWindowSettings()
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
    button:SetBackdropColor(0.035,0.039,0.052,0.98)
    button:SetBackdropBorderColor(0.16,0.17,0.21,1)
    local label=button:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    label:SetPoint("LEFT",5,0); label:SetPoint("RIGHT",-5,0); label:SetJustifyH("CENTER")
    label:SetTextColor(r,g,b,1); button:SetFontString(label); button.label=label
    button:HookScript("OnEnter",function(self) if self:IsEnabled() then self:SetBackdropColor(0.075,0.065,0.09,1); self:SetBackdropBorderColor(r,g,b,0.9) end end)
    button:HookScript("OnLeave",function(self) self:SetBackdropColor(0.035,0.039,0.052,0.98); self:SetBackdropBorderColor(0.16,0.17,0.21,1) end)
    button:HookScript("OnDisable",function() label:SetTextColor(0.40,0.42,0.48,1) end)
    button:HookScript("OnEnable",function() label:SetTextColor(r,g,b,1) end)
    return button
end

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

    scroll:SetScript("OnMouseWheel", function(self, delta)
        local range = self:GetVerticalScrollRange() or 0
        self.targetScroll = math.max(0, math.min(range, (self.targetScroll or self:GetVerticalScroll()) - delta * self.scrollStep))
    end)
    scroll:SetScript("OnUpdate", function(self, elapsed)
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
    end)
    scroll.UpdateThumb = UpdateThumb
    function scroll:ScrollTo(value, immediate)
        self.targetScroll=math.max(0,math.min(self:GetVerticalScrollRange() or 0,value or 0))
        if immediate then self:SetVerticalScroll(self.targetScroll) end
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
    editBox:HookScript("OnTextChanged",function(box) box:SetHeight(math.max(minimumHeight or 1,box:GetStringHeight()+12)) end)
end

function AUI:GetElvUI()
    if type(_G.ElvUI) ~= "table" then
        return nil
    end

    return _G.ElvUI[1]
end

function AUI:ShowStatus()
    local E = self:GetElvUI()
    local elvVersion = E and E.version or "not loaded"
    local tooltipState = ProjectRuthlessDB.elvui.safeTooltip and "enabled" or "disabled"

    self:Print(("v%s | ElvUI: %s | safe tooltip: %s"):format(
        self.version,
        tostring(elvVersion),
        tooltipState
    ))
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

    if command == "status" then
        AUI:ShowStatus()
        return
    end

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

    if command == "tooltip on" then
        ProjectRuthlessDB.elvui.safeTooltip = true
        AUI:Print("Safe tooltip compatibility enabled. Reloading the UI.")
        ReloadUI()
        return
    end

    if command == "tooltip off" then
        ProjectRuthlessDB.elvui.safeTooltip = false
        AUI:Print("Safe tooltip compatibility disabled. This does not re-enable ElvUI tooltips automatically.")
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

    AUI:Print("Commands: /pr, /pr status, /pr spellbook, /pr talents, /pr achievements, /pr errors, /pr healthglow test, /pr tooltip on, /pr tooltip off")
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == addonName then
        ProjectRuthlessDB = ProjectRuthlessDB or {}
        ProjectRuthlessCharDB = ProjectRuthlessCharDB or {}
        ApplyDefaults(ProjectRuthlessDB, defaults)

        -- v0.11.0 restores Blizzard's Character frame for every existing
        -- installation. The experimental replacement can be enabled again
        -- explicitly from /pr after the user chooses to test it.
        if not ProjectRuthlessDB.character.nativeReset110 then
            ProjectRuthlessDB.character.replaceBlizzard = false
            ProjectRuthlessDB.character.nativeReset110 = true
        end

        SLASH_PROJECTRUTHLESS1 = "/pr"
        SlashCmdList.PROJECTRUTHLESS = HandleSlashCommand

        if AUI.modules.ErrorLog then
            AUI.modules.ErrorLog:Install()
        end

        for _, module in pairs(AUI.modules) do
            if module.OnAddonLoaded then
                module:OnAddonLoaded()
            end
        end
    elseif event == "PLAYER_LOGIN" then
        for _, module in pairs(AUI.modules) do
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
