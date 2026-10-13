-- Runs after the established UI/performance harness so real shared widgets are used.
assert(load(SETTINGSREGISTRY_SOURCE))('ProjectRuthless',AUI)
local registry=AUI.modules.SettingsRegistry
local priorMenu=AUI.modules.Menu
assert(load(MENU_SOURCE))('ProjectRuthless',AUI)
local settingsMenu=AUI.modules.Menu
AUI.isForever=true
function Frame:GetParent()return self.parent end
function Frame:SetParent(parent)self.parent=parent end
for _,method in ipairs({'SetOrientation','SetMinMaxValues','SetValueStep','SetObeyStepOnDrag','SetThumbTexture'})do Frame[method]=function()end end
function Frame:GetThumbTexture()self.thumb=self.thumb or CreateFrame('Texture',nil,self);return self.thumb end
function Frame:SetValue(value)self.value=value;self:Fire('OnValueChanged',value)end
local style=AUI.modules.ForeverStyle or {};AUI.modules.ForeverStyle=style
function style:BlizzardArtEnabled()return false end;function style:SetBlizzardArt()end
function style:BagSettings()ProjectRuthlessCharDB.ruiBags=ProjectRuthlessCharDB.ruiBags or {};return ProjectRuthlessCharDB.ruiBags end
function style:ApplySettings()end
AUI.modules.LevelHistory={Show=function()end}
settingsMenu:Create();assert(next(settingsMenu.panels)==nil)
settingsMenu:SelectTab('general');assert(settingsMenu.panels.general and not settingsMenu.panels.bags)
settingsMenu:FilterTabs('backpack');assert(settingsMenu.searchResults:IsShown())
local result=registry:Search('auto sort');assert(#result>=1 and result[1].page=='bags')
local originalCount=#registry.controls
settingsMenu:FilterTabs('auto sort');settingsMenu:FilterTabs('transparency');assert(#registry.controls==originalCount)
local rows=registry:Search('player opacity');assert(#rows>=1)
settingsMenu:OpenSearchResult(rows[1]);assert(settingsMenu.selectedTab=='backgrounds')
assert(settingsMenu.panels.backgrounds and settingsMenu.searchHighlight)
local holder=rows[1].control;local scroll=holder:GetParent():GetParent();assert(scroll:GetVerticalScroll()>0)
local highlight=settingsMenu.searchHighlight;settingsMenu:OpenSearchResult(rows[1]);assert(settingsMenu.searchHighlight==highlight)
local definitions=registry.definitions;local bagDefinition
for _,d in ipairs(definitions)do if d.page=='bags'then bagDefinition=d end end
assert(registry:Set(bagDefinition,true));assert(ProjectRuthlessCharDB.ruiBags.autoSort)
assert(not registry:Set(bagDefinition,123))
local s=ProjectRuthlessDB.general
s.colorR=.1;s.colorG=.2;s.colorB=.3
local r,g,b=AUI:BackgroundColor('Player');assert(r==.1 and g==.2 and b==.3)
s.customColorPlayer=true;s.colorRPlayer=.4;s.colorGPlayer=.5;s.colorBPlayer=.6
r,g,b=AUI:BackgroundColor('Player');assert(r==.4 and g==.5 and b==.6)
s.customColorPlayer=nil;r,g,b=AUI:BackgroundColor('Player');assert(r==.1 and g==.2 and b==.3)
-- Colour editing calls the real native contract; cancellation restores inheritance.
local callbacks
ColorPickerFrame={SetupColorPickerAndShow=function(_,info)callbacks=info;info.swatchFunc()end,GetColorRGB=function()return .7,.8,.9 end}
local colorRow=registry:Search('Player background colour')[1];assert(colorRow)
colorRow.control:Fire('OnClick');assert(callbacks and s.customColorPlayer and s.colorRPlayer==.7)
callbacks.cancelFunc();assert(s.customColorPlayer==nil and s.colorRPlayer==.4)
settingsMenu:FilterTabs('no-such-option');assert(settingsMenu.resultTitle:GetText():find('No matching',1,true))
settingsMenu:FilterTabs('');assert(not settingsMenu.searchResults:IsShown())
settingsMenu:FilterTabs('opacity');local firstPage=registry:Search('opacity');assert(#firstPage>8)
settingsMenu.searchPage=2;settingsMenu:SearchControls('opacity');assert(settingsMenu.resultRows[1].result==firstPage[9])
print('PASS: feature navigation, declarative controls, cached control search, exact destination and scroll, colour inheritance, native picker cancellation, unmatched search and no hidden feature execution')
