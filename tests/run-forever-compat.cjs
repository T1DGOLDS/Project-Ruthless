const fs = require('fs');
const path = require('path');
const assert = require('assert');

const root = path.resolve(process.argv[2] || path.join(__dirname, '..'));
const dependencyRoot = process.env.PR_TEST_DEPS || path.join(root, 'node_modules');
const nativeRoot = process.env.PR_WOW_FOREVER_SOURCE;
if (!nativeRoot) {
  throw new Error('Set PR_WOW_FOREVER_SOURCE to the WoW Forever Interface/AddOns source directory.');
}

const parser = require(path.join(dependencyRoot, 'luaparse'));
for (const file of fs.readdirSync(root, { recursive: true }).filter(file => file.endsWith('.lua') && !file.startsWith('tests') && !file.startsWith('native'))) {
  parser.parse(fs.readFileSync(path.join(root, file), 'utf8'), { luaVersion: '5.1' });
}
console.log('PASS: Lua 5.1 syntax');

function read(relativePath) {
  return fs.readFileSync(path.join(root, relativePath), 'utf8');
}

function native(relativePath) {
  return fs.readFileSync(path.join(nativeRoot, relativePath), 'utf8');
}

function tocFiles(source) {
  return source.split(/\r?\n/)
    .map(line => line.trim())
    .filter(line => line && !line.startsWith('##'));
}

const retailToc = read('ProjectRuthless.toc');
const foreverToc = read('ProjectRuthless_Camelot.toc');
assert.match(foreverToc, /^## Interface: 16001$/m);
assert.match(foreverToc, /^## AllowLoadGameType: camelot$/m);
const foreverFiles=tocFiles(foreverToc),hudFile='Modules\\ForeverHUD.lua';
assert(foreverFiles.includes(hudFile),'Forever HUD must load on Camelot');
assert(foreverFiles.includes('Modules\\ForeverStyle.lua') && !tocFiles(retailToc).includes('Modules\\ForeverStyle.lua'),'HUD presentation belongs only to Forever');
assert(!tocFiles(retailToc).includes(hudFile),'Forever HUD must stay out of Retail');
assert(foreverFiles.indexOf(hudFile)>foreverFiles.indexOf('Modules\\LayoutEditor.lua'),'HUD needs layout editor first');
const retailOnly=['Modules\\CharacterV2.lua','Modules\\Achievements.lua','Modules\\Titles.lua','Modules\\Talents.lua'];
for(const file of retailOnly) assert(!foreverFiles.includes(file),file+' must not load on Forever');
const skyborneFiles=['Modules\\SkyborneMapData.lua','Modules\\SkyborneMap.lua','Modules\\SkyborneMap.xml'];
for(const file of skyborneFiles)assert(foreverFiles.includes(file)&&!tocFiles(retailToc).includes(file),'Skyborne map modules belong only to Forever');
const foundationFiles=['Modules\\UnifiedProfiles.lua','Modules\\SettingsRegistry.lua','Modules\\Accessibility.lua','Modules\\FirstRun.lua','Modules\\QuestProgressionData.lua','Modules\\QuestProgression.lua','Modules\\AuraManager.lua','Modules\\QuestData.lua','Modules\\MapPins.lua','Modules\\ForeverMeters.lua','Modules\\LiveChecks.lua'];
for(const file of foundationFiles)assert(foreverFiles.includes(file)&&!tocFiles(retailToc).includes(file),'Stage 2 foundations belong only to Forever');
assert.deepStrictEqual(foreverFiles.filter(file=>!foundationFiles.includes(file)&&!skyborneFiles.includes(file)&&file!==hudFile && file!=='Modules\\Diagnostics.lua' && file!=='Modules\\LevelHistory.lua' && file!=='Modules\\ForeverStyle.lua' && file!=='Modules\\ForeverExpiringBuffs.lua' && file!=='Modules\\ForeverNameplateHints.lua'),tocFiles(retailToc).filter(file=>!retailOnly.includes(file)),'Shared production files retain their order');
assert(foreverFiles.includes('Modules\\Diagnostics.lua')&&!tocFiles(retailToc).includes('Modules\\Diagnostics.lua'),'Test recorder belongs only to Forever');
console.log('PASS: Camelot manifest and file order');

const core = read('Core.lua');
assert.match(core, /AUI\.isForever\s*=\s*AUI\.interfaceVersion\s*>=\s*16000\s*and\s*AUI\.interfaceVersion\s*<\s*20000/);
for (const feature of ['Character', 'Talents', 'Achievements']) {
  assert.match(core, new RegExp(`${feature}\\s*=\\s*true`), `${feature} must be protected on Forever`);
}

const simpleEditBoxAPI = native('Blizzard_APIDocumentationGenerated/SimpleEditBoxAPIDocumentation.lua');
const simpleFontStringAPI = native('Blizzard_APIDocumentationGenerated/SimpleFontStringAPIDocumentation.lua');
assert.doesNotMatch(simpleEditBoxAPI, /Name = "GetStringHeight"/, 'Recheck scrolling edit-box measurement: Forever now exposes GetStringHeight directly');
assert.match(simpleFontStringAPI, /Name = "GetStringHeight"/);
assert.doesNotMatch(core, /box:GetStringHeight\(\)/, 'SimpleEditBox cannot measure string height on Forever');
assert.match(core, /measurement:GetStringHeight\(\)/);
console.log('PASS: Forever scrolling edit boxes use the supported FontString measurement API');

const mapQuests = read('Modules/MapQuests.lua');
const menu = read('ProjectRuthless_Options/Menu.lua');
const questOfferProvider = native('Blizzard_SharedMapDataProviders/QuestOfferDataProvider.lua');
const worldMap = native('Blizzard_WorldMap/Blizzard_WorldMap.lua');
assert.match(worldMap, /AddDataProvider\(CreateFromMixins\(QuestOfferDataProviderMixin\)\)/);
assert.match(questOfferProvider, /QuestOfferDataProviderMixin:Init\("questPOILocalStory"\)/);
assert.match(questOfferProvider, /C_QuestLine\.GetAvailableQuestLines\(mapID\)/);
assert.match(mapQuests, /SetCVar\("questPOILocalStory",enabled and settings\.showLocalStories and "1" or "0"\)/);
assert.match(mapQuests, /SetCVar\("questPOI",enabled and "1" or "0"\)/);
assert.match(native('Blizzard_SharedMapDataProviders/QuestDataProvider.lua'), /if not GetCVarBool\("questPOI"\) then/);
assert.match(mapQuests, /Enum\.MinimapTrackingFilter\.TrivialQuests/);
assert.match(mapQuests, /Enum\.MinimapTrackingFilter\.AccountCompletedQuests/);
assert.match(mapQuests, /C_QuestLine\.RequestQuestLinesForMap\(mapID\)/);
assert.match(mapQuests, /WorldMapFrame:RefreshAllDataProviders\(\)/);
assert.doesNotMatch(mapQuests, /AcquirePin\(/, 'MapQuests should preserve Blizzard pin ownership');
assert.match(core, /mapQuests\s*=\s*{[\s\S]*?showLocalStories\s*=\s*true[\s\S]*?showTrivial\s*=\s*true[\s\S]*?showAccountCompleted\s*=\s*false/);
assert.match(menu, /CreateTab\("mapquests", "Map & quests", 6\)/);
console.log('PASS: lightweight quest map uses Forever native offers, filters, and Blizzard-owned pins');

const character = read('Modules/CharacterV2.lua');
const talents = read('Modules/Talents.lua');
const achievements = read('Modules/Achievements.lua');
assert.match(character, /function Character:OnPlayerLogin\(\)\s*\n\s*if not self:IsSupported\(\) then return end/);
assert.match(talents, /function Talents:OnPlayerLogin\(\)\s*\n\s*if not AUI:IsFeatureSupported\("Talents"\) then return end/);
assert.match(achievements, /function Achievements:OnPlayerLogin\(\)\s*\n\s*if not AUI:IsFeatureSupported\("Achievements"\) then return end/);
assert.doesNotMatch(menu, /if AUI\.isForever then[\s\S]*?ToggleCharacter\(/, 'Forever menu must not taint secret values by calling ToggleCharacter');
const unsupportedTalentsBranch = talents.match(/if not AUI:IsFeatureSupported\("Talents"\) then([\s\S]*?)\n\s*end/)[1];
assert.doesNotMatch(unsupportedTalentsBranch, /OpenToClassTalentsTab/, 'Unsupported Forever Talents must stay on the native launch path');
assert.match(menu,/if AUI.isForever then\s+self.pageBuilders.character=nil\s+self.pageBuilders.achievements=nil/);
assert.match(menu,/if not AUI.isForever then self:CreateTab\("character"/);
assert.match(menu,/if not AUI.isForever then self:CreateTab\("achievements"/);
assert.match(read('Modules/LayoutEditor.lua'),/if not AUI.isForever then table.insert\(ids,4,"character"\)end/);
console.log('PASS: Forever excludes Character, Achievements and title scans; native frames stay untouched');

const spellbook = read('Modules/Spellbook.lua');
assert.match(spellbook, /function Spellbook:InstallMicroButton\(\)[\s\S]*?if AUI\.isForever then return end/);
assert.match(spellbook, /self\.originalToggleSpellBookFrame=PlayerSpellsUtil\.ToggleSpellBookFrame/);
assert.match(spellbook, /if AUI\.isForever and self\.originalToggleSpellBookFrame then[\s\S]*?PlayerSpellsUtil\.ToggleSpellBookFrame=function/);
assert.match(spellbook, /Spellbook\.originalOpenToSpellBookTabAtSpell\(spellID,\.\.\.\)/);

const spellBookAPI = native('Blizzard_APIDocumentationGenerated/SpellBookDocumentation.lua');
assert.match(spellBookAPI, /Name = "GetSpellBookItemCooldown"[\s\S]*?SecretWhenCooldownsRestricted\s*=\s*true/);
assert.match(spellbook, /local combatRestricted=AUI\.isForever and InCombatLockdown\(\)/);
assert.match(spellbook, /if combatRestricted or item\.future then button\.cooldown:Clear\(\)/);
assert.match(spellbook, /function Spellbook:GetActionBarState\(spellID\)[\s\S]*?if AUI\.isForever and InCombatLockdown\(\) then return self\.actionBarState\[key\] end/);
assert.match(spellbook, /function Spellbook:PulseActionBarLocations\(spellID\)\s*\n\s*if AUI\.isForever then[\s\S]*?return end/);
assert.match(spellbook, /if not AUI\.isForever and MultiActionBar_ShowAllGrids/);
assert.match(spellbook, /if not AUI\.isForever and MultiActionBar_HideAllGrids/);
assert.match(spellbook, /event == "PLAYER_REGEN_DISABLED" and AUI\.isForever[\s\S]*?Spellbook:Refresh\(\)[\s\S]*?return/);
assert.match(spellbook, /AUI\.isForever and InCombatLockdown\(\) then AUI:Print\("Combat Spellbook is browse-only; use your action bars to cast\."\)/);
console.log('PASS: Forever Spellbook provides a read-only combat view without secret cooldowns or protected action-bar mutations');

assert.match(spellbook, /Label\(details,"MACRO NAME","GameFontNormalSmall"\)/);
assert.match(spellbook, /Label\(editorBackground,"MACRO BODY","GameFontNormalSmall"\)/);
assert.match(spellbook, /TYPING IN NAME/);
assert.match(spellbook, /TYPING IN BODY/);
assert.match(spellbook, /OnEditFocusGained/);
assert.match(spellbook, /local function InstallVisibleCaret\(editBox\)/);
assert.match(spellbook, /caret:SetPoint\("TOPLEFT",editBox,"TOPLEFT",caret\.cursorX\+1,caret\.cursorY\)/);
assert.match(spellbook, /local blink=caret:CreateAnimationGroup\(\);blink:SetLooping\("REPEAT"\)/);
assert.doesNotMatch(spellbook, /editBox:HookScript\("OnUpdate"/);
assert.match(spellbook, /self\.macroNameCaret=InstallVisibleCaret\(name\); self\.macroBodyCaret=InstallVisibleCaret\(editor\)/);
console.log('PASS: macro name and body expose labels, focus feedback, and explicit blinking carets');

const playerSpellsToc = native('Blizzard_PlayerSpells/Blizzard_PlayerSpells.toc');
assert.match(playerSpellsToc, /\[Game\]\/Blizzard_PlayerSpellsFrame\.lua\s+\[AllowLoadGameType camelot\]/);
assert.match(playerSpellsToc, /\[Game\]\/SpellBook\/Blizzard_SpellBookFrame\.lua\s+\[AllowLoadGameType camelot\]/);
const camelotBindings = native('Blizzard_FrameXML/Bindings_Camelot.xml');
assert.match(camelotBindings, /PlayerSpellsUtil\.ToggleSpellBookFrame\(\)/);
console.log('PASS: Forever Spellbook button and keybind redirect contract');

const foreverStyle = read('Modules/ForeverStyle.lua');
const professionsBook = native('Blizzard_ProfessionsBook/Camelot/Blizzard_ProfessionsBook.lua');
assert.match(professionsBook, /frame\.UnlearnButton:SetScript\("OnClick", function\(\)[\s\S]*?StaticPopup_Show\(popupName, name, nil, skillLine\)/,
  'Forever must retain Blizzard ownership of the unlearn confirmation');
assert.match(foreverStyle, /function S:ProfessionUnlearnButton\(button\)/);
assert.match(foreverStyle, /button\.Icon:SetAtlas\("Profession-button-red-crossmark",true\)/);
assert.match(foreverStyle, /button:HookScript\("OnShow",function\(self\)S:ProfessionUnlearnButton\(self\)end\)/);
assert.match(foreverStyle, /self:ProfessionCard\(content\.PrimaryProfession1,true\)/);
assert.match(foreverStyle, /self:ProfessionCard\(content\.PrimaryProfession2,true\)/);
assert.doesNotMatch(foreverStyle, /C_TradeSkillUI\.(?:Unlearn|Abandon)|AbandonSkill|UnlearnSkill/,
  'RUI must never bypass Blizzard profession removal and confirmation');
console.log('PASS: profession styling restores both native unlearn controls without replacing Blizzard behavior');

const achievementToc = native('Blizzard_AchievementUI/Blizzard_AchievementUI.toc');
const allowLine = achievementToc.match(/^## AllowLoadGameType:\s*(.+)$/m);
assert(allowLine && !allowLine[1].split(/\s*,\s*/).includes('camelot'), 'Recheck Achievement support: Blizzard now allows the Camelot game type');

const packageScript = read('tools/package.ps1');
assert.match(packageScript, /ProjectRuthless_Camelot\.toc/);
console.log('PASS: package includes Retail and Forever manifests');

// Native inbound aura delegates are required: addon Lua must not scan party auras.
const partyHUD=read('Modules/ForeverHUD.lua');
assert.match(foreverToc,/OptionalDeps:.*Blizzard_AuraContainer/);
const auraContainer=native('Blizzard_AuraContainer/Blizzard_CustomAuraContainer.lua');
for(const method of ['AddAuraGroup','SetAuraGroupMaxFrameCount'])assert(auraContainer.includes(':'+method+'('));
const auraButton=native('Blizzard_AuraContainer/Blizzard_CustomAuraButton.lua');
for(const method of ['SetIcon','SetDurationCooldown','SetApplicationCount'])assert(auraButton.includes(':'+method+'('));
assert.match(native('Blizzard_AuraContainer/Blizzard_CustomAuraContainer.xml'),/secureDelegates="true"/);
assert.doesNotMatch(partyHUD,/C_UnitAuras\.(GetAura|GetUnitAuras)/);
console.log('PASS: party aura presentation uses supported native secure delegates without addon aura scans');
