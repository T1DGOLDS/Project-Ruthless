local _, AUI = ...
local B = {bars = {}, buttons = {}}
AUI:RegisterModule("ForeverActionBars", B)

local definitions = {
    {"bar1", "MainActionBar", "ActionButton", "ACTIONBUTTON", 1},
    {"bar2", "MultiBarBottomLeft", "MultiBarBottomLeftButton", "MULTIACTIONBAR1BUTTON", 6},
    {"bar3", "MultiBarBottomRight", "MultiBarBottomRightButton", "MULTIACTIONBAR2BUTTON", 5},
    {"bar4", "MultiBarRight", "MultiBarRightButton", "MULTIACTIONBAR3BUTTON", 3},
    {"bar5", "MultiBarLeft", "MultiBarLeftButton", "MULTIACTIONBAR4BUTTON", 4},
    {"bar6", "MultiBar5", "MultiBar5Button", "MULTIACTIONBAR5BUTTON", 13},
    {"bar7", "MultiBar6", "MultiBar6Button", "MULTIACTIONBAR6BUTTON", 14},
    {"bar8", "MultiBar7", "MultiBar7Button", "MULTIACTIONBAR7BUTTON", 15},
}
local ENABLED = 1000
local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, entry in pairs(value) do result[key] = copy(entry) end
    return result
end
local function public(value)
    return not (issecretvalue and issecretvalue(value))
end
local function read(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, value = pcall(fn, ...)
    if ok and public(value) then return value end
end
local function settingKey(name)
    return Enum.EditModeActionBarSetting[name]
end
local function number(value, fallback, minimum, maximum)
    if not public(value) or type(value) ~= "number" or value ~= value then return fallback end
    return math.max(minimum, math.min(maximum, value))
end
function B:GetBar(id)
    return self.bars[id]
end
function B:Settings(bar)
    local settings = bar.ruiSettings
    local function get(name, fallback, minimum, maximum)
        return number(settings[settingKey(name)], fallback, minimum, maximum)
    end
    return get("NumIcons", 12, 1, 12), get("NumRows", 1, 1, 12),
        get("IconSize", 100, 50, 200), get("IconPadding", 2, 0, 20),
        get("Orientation", 0, 0, 1)
end
function B:Layout(bar)
    if InCombatLockdown() then return false end
    local count, rows, size, padding, orientation = self:Settings(bar)
    count, rows = math.floor(count), math.floor(rows)
    local size = 45 * size / 100
    local stride = math.ceil(count / rows)
    local horizontal = orientation == Enum.ActionBarOrientation.Horizontal
    local columns = horizontal and stride or rows
    local height = horizontal and rows or stride
    bar:SetSize(columns * size + (columns - 1) * padding, height * size + (height - 1) * padding)
    for index, button in ipairs(bar.ruiButtons) do
        local primary = (index - 1) % stride
        local secondary = math.floor((index - 1) / stride)
        local column = horizontal and primary or secondary
        local row = horizontal and secondary or primary
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", bar, "TOPLEFT", column * (size + padding), -row * (size + padding))
        button:SetSize(size, size)
        if button.Name then
            button.Name:SetWidth(math.max(1, size - 4))
            if button.Name.SetWordWrap then button.Name:SetWordWrap(false) end
        end
        -- A secure visibility driver owns the button's shown state.
        RegisterStateDriver(button, "visibility", index <= count and "show" or "hide")
        local always = bar.ruiSettings[settingKey("AlwaysShowButtons")]
        local show = always == nil or always == true or always == 1
        if button.config.showGrid ~= show then
            local config = copy(button.config); config.showGrid = show; button:UpdateConfig(config)
        end
    end
    self:Visibility(bar)
    return true
end
function B:Visibility(bar)
    local enabled = bar.ruiSettings[ENABLED] ~= false
    local mode = bar.ruiSettings[settingKey("VisibleSetting")]
    local visibility = Enum.ActionBarVisibleSetting or {}
    local tail = "show"
    if not enabled or visibility.Hidden and mode == visibility.Hidden then tail = "hide"
    elseif visibility.InCombat and mode == visibility.InCombat then tail = "[combat] show; hide"
    elseif visibility.OutOfCombat and mode == visibility.OutOfCombat then tail = "[combat] hide; show" end
    local conditions = "[petbattle] hide; " .. tail
    -- The native override bar retains its special buttons and exit controls.
    if bar.ruiID == "bar1" then
        conditions = "[petbattle][vehicleui][overridebar][possessbar] hide; " .. tail
    end
    RegisterStateDriver(bar, "visibility", conditions)
end
function B:IsEnabled(id)
    local bar = self.bars[id]
    return bar and bar.ruiSettings[ENABLED] ~= false or false
end
function B:SetEnabled(id, enabled)
    if InCombatLockdown() then return false end
    local bar = self.bars[id]
    if not bar then return false end
    bar.ruiSettings[ENABLED] = enabled == true
    self:Visibility(bar)
    local editor = AUI.modules.LayoutEditor
    editor:Store().elements[id] = editor:Capture(bar)
    return true
end
function B:UpdateBindings()
    if InCombatLockdown() then self.bindingsPending = true; return end
    self.bindingsPending = nil
    for _, definition in ipairs(definitions) do
        local bar = self.bars[definition[1]]
        if bar then
            ClearOverrideBindings(bar)
            for index, button in ipairs(bar.ruiButtons) do
                local command = definition[4] .. index
                for _, key in ipairs({GetBindingKey(command)}) do
                    SetOverrideBindingClick(bar, false, key, button:GetName(), "LeftButton")
                end
            end
        end
    end
end
function B:ConfigurePaging(bar, page)
    for index, button in ipairs(bar.ruiButtons) do
        if bar.ruiID == "bar1" then
            for state = 1, 18 do button:SetState(state, "action", (state - 1) * 12 + index) end
        else button:SetState(page, "action", (page - 1) * 12 + index) end
    end
    bar:SetAttribute("_onstate-page", [[
        local page = tonumber(newstate)
        if newstate == "special" then
            if HasVehicleActionBar() then page = GetVehicleBarIndex()
            elseif HasOverrideActionBar() then page = GetOverrideBarIndex()
            elseif HasTempShapeshiftActionBar() then page = GetTempShapeshiftBarIndex()
            elseif HasBonusActionBar() then page = GetBonusBarIndex()
            else page = 12 end
        end
        self:SetAttribute("state", page)
        control:ChildUpdate("state", page)
    ]])
    local driver = tostring(page)
    if bar.ruiID == "bar1" then
        driver = "[overridebar][possessbar][shapeshift][bonusbar:5] special; "
            .. "[bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6; "
            .. "[bonusbar:1,stealth] 8; [bonusbar:1] 7; [bonusbar:2] 8; "
            .. "[bonusbar:3] 9; [bonusbar:4] 10; 1"
    end
    RegisterStateDriver(bar, "page", driver)
end
-- Read the gameplay toggle directly: the Settings proxy may not be registered
-- at login, and native toggles may be numeric 0/1 rather than Lua booleans.
function B:NativeEnabled(index)
    if index == 1 then return true end
    local value = read(function()
        if GetActionBarToggles then return select(index - 1, GetActionBarToggles()) end
    end)
    if value == true or value == 1 then return true end
    if value == false or value == 0 then return false end
    local option = Settings and Settings.GetSetting and Settings.GetSetting("PROXY_SHOW_ACTIONBAR_" .. index)
    value = option and read(option.GetValue, option)
    if value == true or value == 1 then return true end
    if value == false or value == 0 then return false end
end
function B:RepairVisibilityImport()
    if ProjectRuthlessCharDB.actionBarVisibilityImport == 1 then return end
    local elements = AUI.modules.LayoutEditor:Store().elements
    local backup = ProjectRuthlessCharDB.actionBarMigrationBackup
    -- beta87's failed import has a precise signature: all seven were disabled,
    -- and their pre-migration snapshots did not yet have an RUI enabled field.
    local affected = type(backup) == "table"
    for index = 2, 8 do
        local id = "bar" .. index
        local settings = elements[id] and elements[id].nativeSettings
        local previous = backup and backup[id] and backup[id].nativeSettings
        if not settings or settings[ENABLED] ~= false or previous and previous[ENABLED] ~= nil then affected = false end
    end
    if affected then
        for index = 2, 8 do
            local enabled = self:NativeEnabled(index)
            if enabled == nil then return end -- Retry when native preferences exist.
        end
        for index = 2, 8 do elements["bar" .. index].nativeSettings[ENABLED] = self:NativeEnabled(index) end
    end
    ProjectRuthlessCharDB.actionBarVisibilityImport = 1
end
function B:Create(definition, library)
    local id, nativeName, _, binding, page = unpack(definition)
    local native = _G[nativeName]
    if not native then error("Missing Forever action bar " .. nativeName) end
    local editor = AUI.modules.LayoutEditor
    local store = editor:Store()
    local saved = copy(store.elements[id] or editor:Capture(native))
    if not saved then error("Could not capture " .. nativeName) end
    local bar = CreateFrame("Frame", "RUIActionBar" .. id:sub(4), self.staging, "SecureHandlerStateTemplate")
    bar.ruiActionBar, bar.ruiID = true, id
    bar.ruiButtons, bar.ruiSettings = {}, copy(saved.nativeSettings or {})
    bar.settingDisplayInfoMap = {}
    for _, name in ipairs({"Orientation", "NumRows", "NumIcons", "IconSize", "IconPadding", "AlwaysShowButtons", "VisibleSetting"}) do
        local key = settingKey(name)
        if key then
            bar.settingDisplayInfoMap[key] = true
            if bar.ruiSettings[key] == nil then bar.ruiSettings[key] = read(native.GetSettingValue, native, key) end
        end
    end
    bar.settingDisplayInfoMap[ENABLED] = true
    if bar.ruiSettings[ENABLED] == nil then
        local index = tonumber(id:sub(4))
        local enabled = self:NativeEnabled(index)
        if enabled == nil then error("Native action bar visibility is unavailable") end
        bar.ruiSettings[ENABLED] = enabled
    end
    function bar:GetSettingValue(key) return self.ruiSettings[key] end
    function bar:ApplyLayoutSettings(settings)
        for key, value in pairs(settings or {}) do self.ruiSettings[key] = value end
        return B:Layout(self)
    end
    bar:SetFrameStrata("LOW")
    bar:SetClampedToScreen(true)
    bar:SetPoint("CENTER", UIParent, "CENTER", saved.x, saved.y)
    local locked = read(C_CVar and C_CVar.GetCVarBool, "lockActionBars")
    for index = 1, 12 do
        local button = library:CreateButton(index, "RUIActionBar" .. id:sub(4) .. "Button" .. index, bar, {
            keyBoundTarget = binding .. index, showGrid = true, actionButtonUI = true,
            text = {macro = {font = {size = 8, flags = "OUTLINE"}, color = {.72, .74, .78},
                position = {anchor = "BOTTOM", relAnchor = "BOTTOM", offsetX = 0, offsetY = 2}, justifyH = "CENTER"}},
            flyoutDirection = (page == 3 or page == 4) and "LEFT" or "UP",
        })
        button:SetAttribute("buttonlock", locked or nil)
        button:SetAttribute("checkselfcast", true)
        button:SetAttribute("checkfocuscast", true)
        button:SetAttribute("checkmouseovercast", read(C_CVar and C_CVar.GetCVarBool, "enableMouseoverCast"))
        bar.ruiButtons[index] = button
        self.buttons[#self.buttons + 1] = button
    end
    self.bars[id] = bar
    self:ConfigurePaging(bar, page)
    self:Layout(bar)
    saved.nativeSettings = copy(bar.ruiSettings)
    store.elements[id] = saved
    return bar
end
function B:IsReplacedButton(button)
    local name = button and button:GetName()
    if not name then return false end
    if name:match("^RUIActionBar%d+Button%d+$") then return true end
    if self.removingStock then
        for _, definition in ipairs(definitions) do
            if name:match("^" .. definition[3] .. "%d+$") then return true end
        end
    end
    return false
end
function B:FilterNativeButtons()
    for _, registry in ipairs({ActionBarButtonEventsFrame, ActionBarActionEventsFrame, ActionBarButtonUpdateFrame}) do
        if type(registry.frames) == "table" then
            for index, button in pairs(registry.frames) do
                if self:IsReplacedButton(button) then registry.frames[index] = nil end
            end
        end
    end
    for _, registry in ipairs({ActionBarButtonRangeCheckFrame, ActionBarButtonUsableWatcherFrame}) do
        if type(registry.actions) == "table" then
            for _, buttons in pairs(registry.actions) do
                for key, button in pairs(buttons) do
                    if self:IsReplacedButton(button) then buttons[key] = nil end
                end
            end
        end
    end
end
function B:HideStockBars()
    self.removingStock = true
    local hidden = CreateFrame("Frame", nil, UIParent)
    hidden:Hide()
    self.hidden = hidden
    for _, definition in ipairs(definitions) do
        local native = _G[definition[2]]
        native:SetParent(hidden)
        native:UnregisterAllEvents()
        for index = 1, 12 do
            local button = _G[definition[3] .. index]
            if button then
                button:UnregisterAllEvents()
                button:SetAttribute("statehidden", true)
                button:Hide()
                if ActionBarActionEventsFrame then ActionBarActionEventsFrame:UnregisterFrame(button) end
                if ActionBarButtonUpdateFrame then ActionBarButtonUpdateFrame:UnregisterFrame(button) end
                -- This registry also contains extra actions and gamepad controls.
                -- Remove replaced buttons individually, preserving those controls.
            end
        end
    end
    self:FilterNativeButtons()
end
function B:ApplySettings()
    if InCombatLockdown() then
        AUI:AfterCombat("ownedActionBars", function() self:ApplySettings() end)
        return
    end
    local style = AUI.modules.ForeverStyle
    for _, button in ipairs(self.buttons) do
        button:SetAttribute("buttonlock", read(C_CVar and C_CVar.GetCVarBool, "lockActionBars") or nil)
        button:SetAttribute("checkmouseovercast", read(C_CVar and C_CVar.GetCVarBool, "enableMouseoverCast"))
        if style then style:ActionButtonSkin(button) end
        local icon = button.icon
        if icon then icon:SetTexCoord(.07, .93, .07, .93) end
    end
end
function B:OnPlayerLogin()
    if not AUI.isForever then return end
    if InCombatLockdown() then
        AUI:AfterCombat("createOwnedActionBars", function() self:OnPlayerLogin() end)
        return
    end
    if self.initialized then return end
    local library = RUIActionBarLibStub("LibActionButton-1.0")
    if ActionBarButtonEventsFrame and type(ActionBarButtonEventsFrame.RegisterFrame) == "function" then
        hooksecurefunc(ActionBarButtonEventsFrame, "RegisterFrame", function() self:FilterNativeButtons() end)
    end
    local editor = AUI.modules.LayoutEditor
    if not ProjectRuthlessCharDB.actionBarMigrationBackup then
        ProjectRuthlessCharDB.actionBarMigrationBackup = copy(editor:Store().elements)
    end
    self:RepairVisibilityImport()
    self.staging = CreateFrame("Frame", nil, UIParent)
    self.staging:Hide()
    local before = copy(editor:Store().elements)
    local ok, problem = pcall(function()
        for _, definition in ipairs(definitions) do self:Create(definition, library) end
    end)
    if not ok then
        for _, bar in pairs(self.bars) do bar:SetParent(self.staging) end
        self.bars = {}
        editor:Store().elements = before
        AUI:Print("RUI action bar setup failed. The original bars are active.")
        geterrorhandler()(problem)
        return
    end
    -- Every replacement exists before the stock presentation is removed.
    self:HideStockBars()
    for _, bar in pairs(self.bars) do bar:SetParent(UIParent) end
    self.initialized = true
    self:UpdateBindings()
    self:ApplySettings()
    local events = CreateFrame("Frame")
    self.events = events
    for _, event in ipairs({"UPDATE_BINDINGS", "PLAYER_REGEN_ENABLED", "CVAR_UPDATE"}) do events:RegisterEvent(event) end
    events:SetScript("OnEvent", function(_, event, name)
        if event == "UPDATE_BINDINGS" or event == "PLAYER_REGEN_ENABLED" and self.bindingsPending then self:UpdateBindings()
        elseif event == "CVAR_UPDATE" and (name == "lockActionBars" or name == "enableMouseoverCast") then self:ApplySettings() end
    end)
end

function B:OpenSettings(id, anchor)
    if InCombatLockdown() then return end
    local bar = self.bars[id]
    if not bar then return end
    local editor = AUI.modules.LayoutEditor
    local panel = self.settingsPanel
    if not panel then
        panel = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        panel:SetSize(270, 310)
        panel:SetFrameStrata("FULLSCREEN_DIALOG")
        AUI:StyleSurface(panel, "window", .95, "Options")
        panel.rows = {}
        local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", 14, -14)
        title:SetText("Action bar settings")
        for index, row in ipairs({
            {"IconSize", "Icon size", 10, 50, 200},
            {"IconPadding", "Spacing", 1, 0, 20},
            {"NumRows", "Rows / columns", 1, 1, 12},
            {"NumIcons", "Buttons", 1, 1, 12},
        }) do
            local label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetPoint("TOPLEFT", 14, -46 - (index - 1) * 42)
            panel.rows[index] = {label = label, setting = row[1], name = row[2]}
            for _, direction in ipairs({-1, 1}) do
                local button = AUI:CreateButton(panel)
                button:SetPoint("TOPRIGHT", panel, "TOPRIGHT", direction < 0 and -52 or -14, -40 - (index - 1) * 42)
                button:SetSize(32, 24)
                button:SetText(direction < 0 and "−" or "+")
                button:SetScript("OnClick", function()
                    if InCombatLockdown() then return end
                    local current = self.bars[panel.barID]
                    local key = settingKey(row[1])
                    editor:Checkpoint()
                    current.ruiSettings[key] = number(current.ruiSettings[key], row[4], row[4], row[5]) + direction * row[3]
                    current.ruiSettings[key] = math.max(row[4], math.min(row[5], current.ruiSettings[key]))
                    self:Layout(current)
                    editor:Store().elements[panel.barID] = editor:Capture(current)
                    self:OpenSettings(panel.barID, anchor)
                    editor:Refresh()
                end)
            end
        end
        local orientation = AUI:CreateButton(panel)
        orientation:SetPoint("TOPLEFT", 14, -220)
        orientation:SetSize(242, 24)
        orientation:SetText("Switch horizontal / vertical")
        orientation:SetScript("OnClick", function()
            if InCombatLockdown() then return end
            local current = self.bars[panel.barID]
            editor:Checkpoint()
            local key = settingKey("Orientation")
            current.ruiSettings[key] = current.ruiSettings[key] == Enum.ActionBarOrientation.Horizontal
                and Enum.ActionBarOrientation.Vertical or Enum.ActionBarOrientation.Horizontal
            self:Layout(current)
            editor:Store().elements[panel.barID] = editor:Capture(current)
            editor:Refresh()
        end)
        local empty = AUI:CreateButton(panel)
        empty:SetPoint("TOPLEFT", 14, -252)
        empty:SetSize(242, 24)
        panel.empty = empty
        empty:SetScript("OnClick", function()
            if InCombatLockdown() then return end
            local current = self.bars[panel.barID]
            editor:Checkpoint()
            local key = settingKey("AlwaysShowButtons")
            local value = current.ruiSettings[key]
            current.ruiSettings[key] = (value == false or value == 0) and 1 or 0
            self:Layout(current)
            editor:Store().elements[panel.barID] = editor:Capture(current)
            self:OpenSettings(panel.barID, anchor)
        end)
        panel:RegisterEvent("PLAYER_REGEN_DISABLED")
        panel:SetScript("OnEvent", function() panel:Hide() end)
        self.settingsPanel = panel
    end
    panel.barID = id
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 12, 0)
    for _, row in ipairs(panel.rows) do row.label:SetText(row.name .. " · " .. tostring(bar.ruiSettings[settingKey(row.setting)])) end
    local always = bar.ruiSettings[settingKey("AlwaysShowButtons")]
    panel.empty:SetText("Empty buttons · " .. ((always == false or always == 0) and "Hidden" or "Shown"))
    panel:Show()
end
