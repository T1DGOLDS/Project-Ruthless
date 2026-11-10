unpack = table.unpack
local busy = false
local writes = 0
local frames = {}
local AUI = {modules = {}, isForever = true}
function AUI:RegisterModule(name, value) self.modules[name] = value end
function AUI:Print(message) self.message = message end
function AUI:AfterCombat(_, callback) if not busy then callback() end end
function InCombatLockdown() return busy end
function issecretvalue() return false end
function geterrorhandler() return function(message) error(message) end end
Enum = {
    EditModeActionBarSetting = {Orientation = 0, NumRows = 1, NumIcons = 2, IconSize = 3, IconPadding = 4, AlwaysShowButtons = 9, VisibleSetting = 6},
    ActionBarOrientation = {Horizontal = 0, Vertical = 1},
    ActionBarVisibleSetting = {Always = 0, InCombat = 1, OutOfCombat = 2, Hidden = 3},
}
local function frame(name, parent)
    local value = {name = name, parent = parent, events = {}, attributes = {}, hooks = {}, points = {}, shown = true}
    function value:GetName() return self.name end
    function value:GetParent() return self.parent end
    function value:SetParent(parent) assert(not busy); self.parent = parent; writes = writes + 1 end
    function value:GetSettingValue(key) return ({[0] = 0, [1] = 1, [2] = 12, [3] = 100, [4] = 2, [9] = 1})[key] end
    function value:SetAttribute(key, setting) assert(not busy); self.attributes[key] = setting end
    function value:SetPoint(...) assert(not busy); self.points = {...} end
    function value:ClearAllPoints() assert(not busy); self.points = {} end
    function value:SetSize(w, h) assert(not busy); self.width, self.height = w, h end
    function value:SetFrameStrata() end
    function value:SetClampedToScreen() end
    function value:Show() self.shown = true end
    function value:Hide() self.shown = false end
    function value:RegisterEvent(event) self.events[event] = true end
    function value:UnregisterAllEvents() self.events = {} end
    function value:SetScript(event, callback) self.hooks[event] = callback end
    frames[#frames + 1] = value
    if name then _G[name] = value end
    return value
end
UIParent = frame("UIParent")
function CreateFrame(_, name, parent) return frame(name, parent) end
local states = {}
function RegisterStateDriver(owner, state, condition)
    assert(not busy)
    states[owner] = states[owner] or {}
    states[owner][state] = condition
end
function GetBindingKey(command) return "KEY-" .. command, "ALT-" .. command end
function ClearOverrideBindings(owner) assert(not busy); owner.bindings = {} end
function SetOverrideBindingClick(owner, _, key, name)
    assert(not busy); owner.bindings[key] = name
end
function hooksecurefunc(owner, method, callback)
    local original = owner[method]
    owner[method] = function(self, ...)
        if original then original(self, ...) end
        callback(self, ...)
    end
end
C_CVar = {GetCVarBool = function() return true end}
-- Settings is load-on-demand. Exercise login with no registered proxy and
-- native numeric visibility values, matching the reported character state.
Settings = {GetSetting = function() return nil end}
function GetActionBarToggles() return 1, 1, 0, 1, 1, 1, 1 end
local nativeNames = {"MainActionBar", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight", "MultiBarLeft", "MultiBar5", "MultiBar6", "MultiBar7"}
local prefixes = {"ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button", "MultiBar7Button"}
ActionBarButtonEventsFrame = {frames = {}}
function ActionBarButtonEventsFrame:RegisterFrame(button) table.insert(self.frames, button) end
local extra = frame("ExtraActionButton1", UIParent)
ActionBarButtonEventsFrame:RegisterFrame(extra)
local removed = {}
ActionBarActionEventsFrame = {frames={[extra]=extra}, UnregisterFrame = function(self, button) removed[button] = true;self.frames[button]=nil end}
ActionBarButtonUpdateFrame = {frames={[extra]=extra}, UnregisterFrame = function(self,button)self.frames[button]=nil end}
ActionBarButtonRangeCheckFrame = {actions={[1]={[extra]=extra}}}
ActionBarButtonUsableWatcherFrame = {actions={[1]={[extra]=extra}}}
for index, name in ipairs(nativeNames) do
    frame(name, UIParent)
    for slot = 1, 12 do
        ActionBarButtonEventsFrame:RegisterFrame(frame(prefixes[index] .. slot, _G[name]))
    end
end
ProjectRuthlessCharDB = {layoutEditor = {elements = {
    bar1 = {x = 120, y = -400, scale = 1, nativeSettings = {[0] = 0, [1] = 2, [2] = 12, [3] = 90, [4] = 2, [9] = 1}},
    bar4 = {x = 900, y = 0, scale = 1, nativeSettings = {[0] = 1, [1] = 1, [2] = 12, [3] = 80, [4] = 1, [1000] = false}},
}}}
local editor = {}
function editor:Store() return ProjectRuthlessCharDB.layoutEditor end
function editor:Capture() return {x = 0, y = -200, scale = 1, nativeSettings = {[0] = 0, [1] = 1, [2] = 12, [3] = 100, [4] = 2}} end
AUI.modules.LayoutEditor = editor
AUI.modules.ForeverStyle = {ActionButtonSkin = function() end}
local failAt
local library = {}
function library:CreateButton(index, name, header, config)
    if failAt == name then error("setup rejected") end
    local button = frame(name, header)
    button.config, button.states = config, {}
    function button:SetState(state, kind, action) self.states[state] = {kind, action} end
    function button:UpdateConfig(config) self.config = config end
    ActionBarButtonEventsFrame:RegisterFrame(button)
    ActionBarActionEventsFrame.frames[button]=button
    ActionBarButtonUpdateFrame.frames[button]=button
    ActionBarButtonRangeCheckFrame.actions[1][button]=button
    ActionBarButtonUsableWatcherFrame.actions[1][button]=button
    return button
end
function RUIActionBarLibStub(name) assert(name == "LibActionButton-1.0"); return library end
assert(load(SOURCE))("ProjectRuthless", AUI)
local bars = AUI.modules.ForeverActionBars
bars:OnPlayerLogin()
assert(bars.initialized and #bars.buttons == 96)
assert(bars:GetBar("bar1").width == 253 and bars:GetBar("bar1").height == 83)
assert(bars:GetBar("bar4").width == 36 and bars:GetBar("bar4").height == 443)
assert(states[bars:GetBar("bar4")].visibility:match("hide$"))
assert(ProjectRuthlessCharDB.actionBarMigrationBackup.bar1.nativeSettings[3] == 90)
local main = bars:GetBar("bar1")
assert(main.ruiButtons[1].states[7][2] == 73)
assert(main.ruiButtons[1].config.text.macro.font.size==8)
assert(main.ruiButtons[1].config.text.macro.position.anchor=="BOTTOM")
assert(main.ruiButtons[12].states[18][2] == 216)
assert(bars:GetBar("bar2").ruiButtons[1].states[6][2] == 61)
assert(bars:GetBar("bar8").ruiButtons[12].states[15][2] == 180)
assert(main.bindings["KEY-ACTIONBUTTON1"] == "RUIActionBar1Button1")
assert(main.bindings["ALT-ACTIONBUTTON1"] == "RUIActionBar1Button1")
local kept = 0
for _, button in pairs(ActionBarButtonEventsFrame.frames) do assert(button == extra); kept = kept + 1 end
assert(kept == 1 and removed[ActionButton1])
for _,registry in ipairs({ActionBarActionEventsFrame,ActionBarButtonUpdateFrame})do
    for _,button in pairs(registry.frames)do assert(button==extra)end
    assert(registry.frames[extra]==extra)
end
for _,registry in ipairs({ActionBarButtonRangeCheckFrame,ActionBarButtonUsableWatcherFrame})do
    for _,button in pairs(registry.actions[1])do assert(button==extra)end
    assert(registry.actions[1][extra]==extra)
end
assert(MainActionBar:GetParent() == bars.hidden and main:GetParent() == UIParent)
local anchor = main.points
local width = main.width
busy = true
-- Simulate the native Edit Mode level-up reset. It has no references to RUI's frames.
for _, name in ipairs(nativeNames) do _G[name].points = {"TOPLEFT", UIParent, "TOPLEFT", 0, 0} end
assert(main.points == anchor and main.width == width)
assert(not bars:Layout(main) and not bars:SetEnabled("bar1", false))
bars:UpdateBindings()
assert(bars.bindingsPending and main.points == anchor)
busy = false
bars.events.hooks.OnEvent(nil, "PLAYER_REGEN_ENABLED")
assert(not bars.bindingsPending)
assert(bars:SetEnabled("bar4", true) and states[bars:GetBar("bar4")].visibility:match("show$"))

-- Execute the actual page snippet against a restricted-environment stand-in.
local observed
local env = {
    tonumber = tonumber, self = main, control = {ChildUpdate = function(_, name, page) assert(name == "state"); observed = page end},
    HasVehicleActionBar = function() return false end, HasOverrideActionBar = function() return false end,
    HasTempShapeshiftActionBar = function() return false end, HasBonusActionBar = function() return false end,
}
local code = main.attributes["_onstate-page"]
env.newstate = "7"
assert(load(code, "page", "t", env))()
assert(observed == 7)
env.newstate = "special"
env.HasVehicleActionBar = function() return true end
env.GetVehicleBarIndex = function() return 12 end
assert(load(code, "page", "t", env))()
assert(observed == 12)
print("PASS: RUI-owned bars retain saved bounds through native combat reset, migrate grids, preserve slots/bindings and secure paging")

-- Failed setup keeps the original presentation and settings available.
local original = ProjectRuthlessCharDB.layoutEditor.elements
ActionBarButtonEventsFrame = {frames={extra}}
function ActionBarButtonEventsFrame:RegisterFrame(button)table.insert(self.frames,button)end
for index,name in ipairs(nativeNames)do
    _G[name]:SetParent(UIParent)
    for slot=1,12 do ActionBarButtonEventsFrame:RegisterFrame(_G[prefixes[index]..slot])end
end
local oldHandler = geterrorhandler
geterrorhandler = function() return function() end end
failAt = "RUIActionBar2Button1"
local secondAUI = {modules = AUI.modules, isForever = true, RegisterModule = AUI.RegisterModule, Print = AUI.Print}
assert(load(SOURCE))("ProjectRuthless", secondAUI)
local failed = secondAUI.modules.ForeverActionBars
failed:OnPlayerLogin()
assert(not failed.initialized and next(failed.bars) == nil)
assert(MainActionBar:GetParent()==UIParent and MultiBarBottomLeft:GetParent()==UIParent)
local stockCount=0
for _,button in pairs(ActionBarButtonEventsFrame.frames)do
    assert(not button:GetName():match('^RUIActionBar'))
    stockCount=stockCount+1
end
assert(stockCount==97)
assert(ProjectRuthlessCharDB.layoutEditor.elements.bar1.nativeSettings[3] == original.bar1.nativeSettings[3])
geterrorhandler = oldHandler
print("PASS: partial button setup stays hidden and restores the previous working layout")

-- A beta87 all-disabled import is repaired once without moving any anchors.
local repair = AUI.modules.ForeverActionBars
ProjectRuthlessCharDB.actionBarVisibilityImport = nil
ProjectRuthlessCharDB.actionBarMigrationBackup = {}
for index=2,8 do
    local id="bar"..index
    ProjectRuthlessCharDB.actionBarMigrationBackup[id]={nativeSettings={}}
    ProjectRuthlessCharDB.layoutEditor.elements[id]={x=index*23,y=-index*41,scale=.9,nativeSettings={[1000]=false}}
end
repair:RepairVisibilityImport()
for index=2,8 do
    local value=ProjectRuthlessCharDB.layoutEditor.elements["bar"..index]
    assert(value.x==index*23 and value.y==-index*41 and value.scale==.9)
    assert(value.nativeSettings[1000]==(index~=4))
end
ProjectRuthlessCharDB.layoutEditor.elements.bar2.nativeSettings[1000]=false
repair:RepairVisibilityImport()
assert(ProjectRuthlessCharDB.layoutEditor.elements.bar2.nativeSettings[1000]==false)
assert(repair:NativeEnabled(2)==true and repair:NativeEnabled(4)==false)
print("PASS: unloaded Settings proxies and numeric native toggles preserve visibility; beta87 all-disabled import repairs once without moving anchors")
