function Frame:EnableKeyboard(value)self.keyboard=value end
function Frame:SetPropagateKeyboardInput(value)self.propagate=value end
function Frame:GetValue()return self.value or 0 end
function Frame:IsEnabled()return true end
function Frame:SetFont(path,size,flags)self.fontPath=path;self.fontSize=size;self.fontFlags=flags end
assert(load(ACCESSIBILITY_SOURCE))('ProjectRuthless',AUI)
assert(load(FIRSTRUN_SOURCE))('ProjectRuthless',AUI)
local access=AUI.modules.Accessibility;local setup=AUI.modules.FirstRun
local originalChar=ProjectRuthlessCharDB
ProjectRuthlessCharDB={};ProjectRuthlessDB.profilesV2={version=2,entries={}};ProjectRuthlessDB.accessibility={highContrast=true}
setup:InitializeCharacter();assert(ProjectRuthlessCharDB.firstRun.eligible and not ProjectRuthlessCharDB.firstRun.complete and not ProjectRuthlessDB.accessibility.highContrast)
local fresh=ProjectRuthlessCharDB.firstRun;setup:InitializeCharacter();assert(ProjectRuthlessCharDB.firstRun==fresh)
ProjectRuthlessCharDB={layoutEditor={elements={player={x=77}}},welcomed=true}
setup:InitializeCharacter();assert(not ProjectRuthlessCharDB.firstRun.eligible and ProjectRuthlessCharDB.layoutEditor.elements.player.x==77)
ProjectRuthlessCharDB={};ProjectRuthlessDB.profilesV2.default='Account'
setup:InitializeCharacter();assert(not ProjectRuthlessCharDB.firstRun.eligible and ProjectRuthlessCharDB.firstRun.complete)
ProjectRuthlessCharDB=originalChar;ProjectRuthlessCharDB.firstRun={complete=false};ProjectRuthlessCharDB.layoutEditor=ProjectRuthlessCharDB.layoutEditor or {elements={}}
ProjectRuthlessDB.accessibility={textScale=1.25,reducedMotion=true,highContrast=true,animatedPortraits=true}
local font=CreateFrame('FontString');access:RegisterText(font);access:RegisterText(font);assert(font.fontSize==15)
assert(not access:AnimatedPortraits()and AUI:BackgroundOpacity('Player')>=.9)
local r,g,b=AUI:BackgroundColor('Player');assert(r==.018 and g==.020 and b==.024)
local s=AUI:CreateSmoothScrollFrame(UIParent);local content=CreateFrame('Frame');content:SetHeight(1000);s:SetHeight(100);s:SetScrollChild(content)
s:Fire('OnMouseWheel',-2);assert(s:GetVerticalScroll()==60 and not s.scripts.OnUpdate)
local base=CreateFrame('Frame');base:SetSize(920,620);UIParent:SetSize(1024,600)
assert(access:FitWindow(base,1.25)<1)
local nativeOpened;Settings={GetCategory=function(label)if label=='Native general'then return {GetID=function()return 99 end}end end,OpenToCategory=function(id)nativeOpened=id end}
assert(access:OpenNativeCategory('Native general')and nativeOpened==99);assert(not access:OpenNativeCategory(nil))
assert(load(MENU_SOURCE))('ProjectRuthless',AUI)
local accessibleMenu=AUI.modules.Menu;accessibleMenu:Create();accessibleMenu:Show('accessibility')
assert(accessibleMenu.panels.accessibility and accessibleMenu.frame.keyboard)
GetCurrentKeyBoardFocus=function()return nil end
accessibleMenu.frame:Fire('OnKeyDown','TAB');assert(access.keyboardRow and accessibleMenu.searchHighlight)
local before=ProjectRuthlessDB.accessibility.reducedMotion
accessibleMenu.frame:Fire('OnKeyDown','ENTER');assert(ProjectRuthlessDB.accessibility.reducedMotion~=before)
accessibleMenu.frame:Fire('OnKeyDown','PAGEDOWN');assert(accessibleMenu.selectedTab=='setup')
local poseBefore=ProjectRuthlessCharDB.layoutEditor and ProjectRuthlessCharDB.layoutEditor.elements
local busyBefore=InCombatLockdown;InCombatLockdown=function()return true end
assert(not setup:Finish({largeText=true}));InCombatLockdown=busyBefore
assert(setup:Finish({largeText=true,reducedMotion=true,animatedPortraits=true,highContrast=true}))
assert(ProjectRuthlessCharDB.firstRun.complete and ProjectRuthlessDB.accessibility.textScale==1.25 and not ProjectRuthlessCharDB.layoutEditor.blizzardArt)
assert(ProjectRuthlessCharDB.layoutEditor.elements==poseBefore)
local seen={};for _,d in ipairs(AUI.modules.SettingsRegistry.definitions)do local key=d.section..'.'..d.key;assert(not seen[key],key);seen[key]=true end
print('PASS: fresh/existing/default setup isolation, font scaling without compounding, native categories, instant reduced scrolling, contrast, window fitting, keyboard focus/activation and duplicate declaration audit')
