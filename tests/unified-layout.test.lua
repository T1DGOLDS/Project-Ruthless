-- The actual editor and chat delegates, not substitutes for profile positioning.
ProjectRuthlessDB.general={windowScale=1,windowOpacity=1}
ProjectRuthlessDB.spellbook={pinnedSpells={}}
ProjectRuthlessCharDB={layoutEditor={elements={},layouts={}}}
for _,id in ipairs({'ForeverHUD','ForeverStyle','Spellbook','MapQuests','QuestWorkspace','LowHealthGlow'})do
 local module=AUI.modules[id];if module then module.ApplySettings=function()end end
end
function AUI:ApplyWindowSettings()end;function AUI:RefreshBackgrounds()end
assert(load(PROFILES_SOURCE))('ProjectRuthless',AUI)
assert(load(UNIFIEDPROFILES_SOURCE))('ProjectRuthless',AUI)
local unified=AUI.modules.UnifiedProfiles;unified:InitializeCharacter()
e.frame:Hide();e:Show()
local captured=e:Snapshot();assert(unified:Validate(unified:Capture()))
assert(e:Save('Unified'));ProjectRuthlessDB.general.windowScale=.8
assert(e:Load('Unified'));assert(ProjectRuthlessDB.general.windowScale==1)
e:Undo();assert(ProjectRuthlessDB.general.windowScale==.8)
assert(e:Load('Unified'));assert(ProjectRuthlessDB.general.windowScale==1)
ProjectRuthlessDB.general.windowScale=.9;e:Close(true)
assert(ProjectRuthlessDB.general.windowScale==1 and not e.frame:IsShown())
-- Remove tabs outside a complete saved set, retain temporary conversations.
local closed={};FCF_Close=function(f)closed[f.id]=true;chatInfo[f.id][7]=false;chatInfo[f.id][9]=false end
chatInfo[5]={'Extra',14,0,0,0,.2,true,false,true,false}
assert(e:RestoreChat(savedTabs));assert(closed[5]and not closed[4]and not closed[1]and not closed[2])
assert(unified:Parse(unified:Export()))
print('PASS: real Edit Mode uses unified profiles; Cancel restores complete setup; native chat closes extra permanent tabs while retaining temporary and built-in windows')
